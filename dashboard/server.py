#!/usr/bin/env python3
"""Read-only OpenMoHAA log dashboard.

The app intentionally uses only the Python standard library so it can run on
the server without adding a web framework dependency.
"""

from __future__ import annotations

import argparse
import html
import json
import os
import re
import threading
import time
from collections import deque
from dataclasses import asdict, dataclass
from datetime import datetime
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import unquote, urlparse

import livemap
from livemap_page import MAP_HTML
from spawns_page import SPAWNS_HTML


DEFAULT_LOG = Path.home() / ".openmohaa" / "main" / "qconsole.log"
DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = 8088
CHAT_LIMIT = 50
RECENT_EVENT_LIMIT = 30
ALERT_LIMIT = 30
STALE_AFTER_SECONDS = 300
# How long one SSE connection is held before the client is asked to reconnect.
SSE_MAX_SECONDS = 300
# Padding pushed at stream start to defeat proxy buffering (see stream_positions).
SSE_PAD_BYTES = int(os.environ.get("MOHAA_SSE_PAD", "2048"))  # preamble to nudge proxies into flushing

LOG_TS = re.compile(r"^\[(?P<ts>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) UTC[^\]]+\] (?P<body>.*)$")
CLIENT_PREFIX = re.compile(r"^\{#(?P<slot>\d+) \| [^}]+\} (?P<body>.*)$")
CHAT_LINE = re.compile(r"^(?P<name>.+?) says @(?P<channel>all|team): (?P<message>.*)$")
ENTER_LINE = re.compile(r"^(?P<name>.+?) has entered the battle$")
TEAM_LINE = re.compile(r"^(?P<name>.+?) has joined the (?P<team>Allies|Axis|Spectator)$")
LEAVE_LINE = re.compile(r'^broadcast: print "(?P<name>.+?) (?P<reason>disconnected|timed out)\\n"$')
MAP_LINE = re.compile(r"^Server: (?P<map>.+)$")
PLAIN_BOT = re.compile(r"^bot\d+$", re.IGNORECASE)
IP_LIKE = re.compile(r"\b(?:\d{1,3}\.){3}\d{1,3}(?::\d{1,5})?\b")

ALERT_PATTERNS = (
    "aimbot",
    "overflow",
    "exception",
    "signal",
    "segmentation",
    "script error",
    "script runtime",
    ".scr",
    "null",
    "stale",
)


@dataclass
class Player:
    slot: int | None
    name: str
    team: str
    joined_at: str
    last_seen: str
    kind: str


@dataclass
class ChatMessage:
    ts: str
    slot: int
    name: str
    channel: str
    message: str


@dataclass
class RecentEvent:
    ts: str
    kind: str
    name: str
    detail: str


@dataclass
class Alert:
    ts: str
    severity: str
    message: str


def parse_ts(value: str) -> datetime:
    return datetime.strptime(value, "%Y-%m-%d %H:%M:%S")


def display_ts(value: datetime) -> str:
    return value.strftime("%Y-%m-%d %H:%M:%S")


def is_bot_name(name: str) -> bool:
    return name.startswith("[BOT]") or bool(PLAIN_BOT.match(name))


def redact_ips(value: str) -> str:
    return IP_LIKE.sub("[redacted]", value)


class LogParser:
    """Incremental, thread-safe parser for the OpenMoHAA console log.

    Accumulator state (players, chat, recent events, ...) is carried between
    requests so each poll only parses bytes appended since the previous read.
    The persistent accumulators *are* the cache; rebuilding the bounded JSON
    snapshot from them on each call is cheap. A lock serialises the
    stat -> read-delta -> build-snapshot sequence because the server is
    threaded and the state is shared.
    """

    def __init__(self, log_path: Path = DEFAULT_LOG) -> None:
        self.log_path = log_path
        self._lock = threading.Lock()
        self._offset = 0
        self._partial = ""
        self._reset_state()

    def _reset_state(self) -> None:
        self.players_by_slot: dict[int, Player] = {}
        self.bots_by_name: dict[str, Player] = {}
        self.pending_team_by_name: dict[str, str] = {}
        self.chat: deque[ChatMessage] = deque(maxlen=CHAT_LIMIT)
        self.recent_events: deque[RecentEvent] = deque(maxlen=RECENT_EVENT_LIMIT)
        self.alerts: deque[Alert] = deque(maxlen=ALERT_LIMIT)
        self.current_map = "unknown"
        self.map_started_at: str | None = None
        self.last_log_ts: str | None = None
        self.total_lines = 0
        self._offset = 0
        self._partial = ""

    def snapshot(self) -> dict[str, Any]:
        with self._lock:
            if not self.log_path.exists():
                self._reset_state()
                return build_state(
                    log_path=self.log_path,
                    current_map="unknown",
                    map_started_at=None,
                    last_log_ts=None,
                    players=[],
                    bots=[],
                    chat=[],
                    recent_events=[],
                    alerts=[
                        Alert(
                            ts=display_ts(datetime.now()),
                            severity="error",
                            message=f"log file not found: {self.log_path}",
                        )
                    ],
                    total_lines=0,
                )

            size = self.log_path.stat().st_size
            # Truncation / rotation: file shrank below where we last read, so
            # the history we accumulated no longer matches. Re-parse from 0.
            if size < self._offset:
                self._reset_state()

            if size > self._offset:
                self._consume_delta(size)

            return build_state(
                log_path=self.log_path,
                current_map=self.current_map,
                map_started_at=self.map_started_at,
                last_log_ts=self.last_log_ts,
                players=sorted(
                    self.players_by_slot.values(),
                    key=lambda p: p.slot if p.slot is not None else 999,
                ),
                bots=sorted(self.bots_by_name.values(), key=lambda p: p.name.lower()),
                chat=list(self.chat),
                recent_events=list(self.recent_events),
                alerts=list(self.alerts),
                total_lines=self.total_lines,
            )

    def _consume_delta(self, size: int) -> None:
        with self.log_path.open(errors="replace") as handle:
            handle.seek(self._offset)
            data = handle.read()
            # read() returns str; advance the byte offset by the encoded length
            # so seek() lines up next time regardless of multibyte characters.
            self._offset += len(data.encode("utf-8", errors="replace"))

        data = self._partial + data
        # The final line may be half-written by the live server. Parse only up
        # to the last newline and carry the remainder until it completes.
        newline = data.rfind("\n")
        if newline == -1:
            self._partial = data
            return
        self._partial = data[newline + 1 :]
        complete = data[: newline + 1]
        for raw_line in complete.splitlines():
            self.total_lines += 1
            self._consume_line(raw_line)

    def _consume_line(self, line: str) -> None:
        match = LOG_TS.match(line)
        if not match:
            return

        ts = parse_ts(match.group("ts"))
        ts_text = display_ts(ts)
        self.last_log_ts = ts_text
        body = match.group("body")
        body = body.removeprefix("console: ")

        if map_match := MAP_LINE.match(body):
            self.current_map = map_match.group("map")
            self.map_started_at = ts_text
            self.players_by_slot.clear()
            self.bots_by_name.clear()
            self.pending_team_by_name.clear()
            self.recent_events.append(
                RecentEvent(ts=ts_text, kind="map", name=self.current_map, detail="map loaded")
            )
            return

        lower_body = body.lower()
        if any(pattern in lower_body for pattern in ALERT_PATTERNS):
            self.alerts.append(Alert(ts=ts_text, severity="warning", message=redact_ips(body)))

        if leave_match := LEAVE_LINE.match(body):
            name = leave_match.group("name")
            reason = leave_match.group("reason")
            remove_player(name, self.players_by_slot, self.bots_by_name)
            self.recent_events.append(
                RecentEvent(ts=ts_text, kind="leave", name=name, detail=reason)
            )
            if reason == "timed out":
                self.alerts.append(Alert(ts=ts_text, severity="warning", message=f"{name} timed out"))
            return

        slot: int | None = None
        line_body = body
        if client_match := CLIENT_PREFIX.match(body):
            slot = int(client_match.group("slot"))
            line_body = client_match.group("body")

        if chat_match := CHAT_LINE.match(line_body):
            if slot is not None:
                self.chat.append(
                    ChatMessage(
                        ts=ts_text,
                        slot=slot,
                        name=chat_match.group("name"),
                        channel=chat_match.group("channel"),
                        message=chat_match.group("message"),
                    )
                )
                touch_player(
                    self.players_by_slot,
                    slot,
                    chat_match.group("name"),
                    ts_text,
                    self.pending_team_by_name,
                )
            return

        if enter_match := ENTER_LINE.match(line_body):
            name = enter_match.group("name")
            if slot is None and is_bot_name(name):
                self.bots_by_name[name] = Player(
                    slot=None,
                    name=name,
                    team=self.pending_team_by_name.get(name, "unknown"),
                    joined_at=ts_text,
                    last_seen=ts_text,
                    kind="bot",
                )
            elif slot is not None:
                self.players_by_slot[slot] = Player(
                    slot=slot,
                    name=name,
                    team=self.pending_team_by_name.get(name, "unknown"),
                    joined_at=ts_text,
                    last_seen=ts_text,
                    kind="human",
                )
                self.recent_events.append(
                    RecentEvent(ts=ts_text, kind="join", name=name, detail=f"slot #{slot}")
                )
            return

        if team_match := TEAM_LINE.match(line_body):
            name = team_match.group("name")
            team = team_match.group("team").lower()
            self.pending_team_by_name[name] = team
            if slot is not None:
                player = touch_player(
                    self.players_by_slot, slot, name, ts_text, self.pending_team_by_name
                )
                player.team = team
            elif name in self.bots_by_name:
                self.bots_by_name[name].team = team
                self.bots_by_name[name].last_seen = ts_text
            elif is_bot_name(name):
                self.bots_by_name[name] = Player(
                    slot=None,
                    name=name,
                    team=team,
                    joined_at=ts_text,
                    last_seen=ts_text,
                    kind="bot",
                )
            return


def touch_player(
    players_by_slot: dict[int, Player],
    slot: int,
    name: str,
    ts_text: str,
    pending_team_by_name: dict[str, str],
) -> Player:
    player = players_by_slot.get(slot)
    if player is None or player.name != name:
        player = Player(
            slot=slot,
            name=name,
            team=pending_team_by_name.get(name, "unknown"),
            joined_at=ts_text,
            last_seen=ts_text,
            kind="human",
        )
        players_by_slot[slot] = player
    else:
        player.last_seen = ts_text
    return player


def remove_player(
    name: str,
    players_by_slot: dict[int, Player],
    bots_by_name: dict[str, Player],
) -> None:
    for slot, player in list(players_by_slot.items()):
        if player.name == name:
            del players_by_slot[slot]
    bots_by_name.pop(name, None)


def build_state(
    *,
    log_path: Path,
    current_map: str,
    map_started_at: str | None,
    last_log_ts: str | None,
    players: list[Player],
    bots: list[Player],
    chat: list[ChatMessage],
    recent_events: list[RecentEvent],
    alerts: list[Alert],
    total_lines: int,
) -> dict[str, Any]:
    now = time.time()
    log_exists = log_path.exists()
    log_mtime = log_path.stat().st_mtime if log_exists else None
    log_age_seconds = int(now - log_mtime) if log_mtime is not None else None
    stale = log_age_seconds is None or log_age_seconds >= STALE_AFTER_SECONDS
    health = "stale" if stale else "fresh"

    state = {
        "generated_at": display_ts(datetime.now()),
        "server": {
            "map": current_map,
            "map_started_at": map_started_at,
            "last_log_ts": last_log_ts,
            "log_path": str(log_path),
            "log_age_seconds": log_age_seconds,
            "health": health,
            "stale_after_seconds": STALE_AFTER_SECONDS,
            "total_lines": total_lines,
        },
        "counts": {
            "humans": len(players),
            "bots": len(bots),
            "total": len(players) + len(bots),
        },
        "players": [asdict(player) for player in players],
        "bots": [asdict(bot) for bot in bots],
        "chat": [asdict(message) for message in chat],
        "recent_events": [asdict(event) for event in recent_events],
        "alerts": [asdict(alert) for alert in alerts],
    }
    return assert_no_ip_leak(scrub_ips(state))


def scrub_ips(value: Any) -> Any:
    if isinstance(value, str):
        return redact_ips(value)
    if isinstance(value, list):
        return [scrub_ips(item) for item in value]
    if isinstance(value, dict):
        return {key: scrub_ips(item) for key, item in value.items()}
    return value


def assert_no_ip_leak(state: dict[str, Any]) -> dict[str, Any]:
    rendered = json.dumps(state, ensure_ascii=False)
    if IP_LIKE.search(rendered):
        raise ValueError("dashboard state contains an IP-like value")
    return state


HTML = """<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>MOHAA Dashboard</title>
  <style>
    :root {
      color-scheme: light;
      --bg: #f4f1ea;
      --panel: #fffdf7;
      --ink: #191816;
      --muted: #666158;
      --line: #d8d0c2;
      --accent: #8f2f2f;
      --accent-2: #2d5f63;
      --warn: #9a5a00;
      --bad: #9f1f28;
      --shadow: 0 1px 2px rgba(20, 18, 14, 0.08);
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      background: var(--bg);
      color: var(--ink);
      font: 14px/1.45 system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    }
    header {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 18px 20px 12px;
      border-bottom: 1px solid var(--line);
      background: #28231d;
      color: #f8f2e6;
    }
    h1 {
      margin: 0;
      font-size: 22px;
      font-weight: 700;
      letter-spacing: 0;
    }
    main {
      width: min(1380px, 100%);
      margin: 0 auto;
      padding: 16px 20px 28px;
    }
    .status-grid {
      display: grid;
      grid-template-columns: repeat(5, minmax(120px, 1fr));
      gap: 10px;
      margin-bottom: 16px;
    }
    .metric, .panel {
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 6px;
      box-shadow: var(--shadow);
    }
    .metric {
      padding: 10px 12px;
      min-height: 72px;
    }
    .label {
      display: block;
      color: var(--muted);
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.08em;
      white-space: nowrap;
    }
    .value {
      display: block;
      margin-top: 5px;
      font-size: 20px;
      font-weight: 700;
      overflow-wrap: anywhere;
    }
    .subtle {
      color: var(--muted);
      font-size: 12px;
      margin-top: 2px;
    }
    .fresh { color: var(--accent-2); }
    .stale { color: var(--bad); }
    .layout {
      display: grid;
      grid-template-columns: minmax(360px, 1.05fr) minmax(360px, 1.2fr);
      gap: 14px;
      align-items: start;
    }
    .panel {
      overflow: hidden;
    }
    .panel h2 {
      margin: 0;
      padding: 10px 12px;
      border-bottom: 1px solid var(--line);
      font-size: 15px;
      background: #eee7d9;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      table-layout: fixed;
    }
    th, td {
      padding: 8px 10px;
      border-bottom: 1px solid #ece5d8;
      text-align: left;
      vertical-align: top;
      overflow-wrap: anywhere;
    }
    th {
      color: var(--muted);
      font-size: 12px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.06em;
    }
    th.slot, td.slot { width: 56px; }
    th.team, td.team { width: 92px; }
    th.time, td.time { width: 172px; }
    .stack {
      display: grid;
      gap: 14px;
    }
    .feed {
      max-height: 460px;
      overflow: auto;
    }
    .feed-row {
      display: grid;
      grid-template-columns: 156px minmax(90px, 150px) 1fr;
      gap: 8px;
      padding: 8px 10px;
      border-bottom: 1px solid #ece5d8;
    }
    .feed-row time, .feed-row .meta {
      color: var(--muted);
      font-size: 12px;
    }
    .feed-row .message {
      overflow-wrap: anywhere;
    }
    .event-row {
      display: grid;
      grid-template-columns: 156px 80px 1fr;
      gap: 8px;
      padding: 8px 10px;
      border-bottom: 1px solid #ece5d8;
    }
    .badge {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-width: 58px;
      padding: 2px 6px;
      border-radius: 999px;
      background: #e5dfd1;
      color: #28231d;
      font-size: 12px;
      font-weight: 700;
    }
    .badge.join { background: #d9ebe2; color: #1d5b3f; }
    .badge.leave, .badge.warning { background: #f1dfc1; color: var(--warn); }
    .empty {
      padding: 14px 12px;
      color: var(--muted);
    }
    footer {
      color: var(--muted);
      font-size: 12px;
      margin-top: 14px;
    }
    @media (max-width: 960px) {
      .status-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
      .layout { grid-template-columns: 1fr; }
      .feed-row, .event-row { grid-template-columns: 1fr; }
      th.time, td.time { width: auto; }
    }
    @media (max-width: 560px) {
      main { padding: 12px; }
      header { padding: 14px 12px 10px; }
      .status-grid { grid-template-columns: 1fr; }
      table, thead, tbody, tr, th, td { display: block; width: 100%; }
      thead { display: none; }
      tr { border-bottom: 1px solid #ece5d8; }
      td { border-bottom: 0; padding: 4px 10px; }
      td::before {
        content: attr(data-label);
        display: block;
        color: var(--muted);
        font-size: 11px;
        text-transform: uppercase;
        letter-spacing: 0.06em;
      }
    }
  </style>
</head>
<body>
  <header>
    <h1>MOHAA Dashboard</h1>
    <a href="/map" style="margin-left:auto;font-size:13px;text-decoration:none;
       border:1px solid currentColor;border-radius:6px;padding:4px 10px;opacity:.85">
      Live map &rarr;</a>
    <a href="/spawns" style="font-size:13px;text-decoration:none;margin-left:8px;
       border:1px solid currentColor;border-radius:6px;padding:4px 10px;opacity:.85">
      Spawn review &rarr;</a>
  </header>
  <main>
    <section class="status-grid" aria-label="Server status">
      <div class="metric"><span class="label">Map</span><span id="map" class="value">...</span><div id="map-started" class="subtle"></div></div>
      <div class="metric"><span class="label">Humans</span><span id="humans" class="value">0</span><div class="subtle">connected clients</div></div>
      <div class="metric"><span class="label">Bots</span><span id="bots" class="value">0</span><div class="subtle">active AI names</div></div>
      <div class="metric"><span class="label">Log Health</span><span id="health" class="value">...</span><div id="log-age" class="subtle"></div></div>
      <div class="metric"><span class="label">Last Update</span><span id="generated" class="value">...</span><div id="last-log" class="subtle"></div></div>
    </section>

    <section class="layout">
      <div class="stack">
        <section class="panel">
          <h2>Connected Players</h2>
          <table>
            <thead>
              <tr><th class="slot">Slot</th><th>Name</th><th class="team">Team</th><th class="time">Joined</th></tr>
            </thead>
            <tbody id="players"></tbody>
          </table>
        </section>
        <section class="panel">
          <h2>Recent Activity</h2>
          <div id="events" class="feed"></div>
        </section>
      </div>

      <div class="stack">
        <section class="panel">
          <h2>Chat History</h2>
          <div id="chat" class="feed"></div>
        </section>
        <section class="panel">
          <h2>Alerts</h2>
          <div id="alerts" class="feed"></div>
        </section>
      </div>
    </section>
    <footer id="footer"></footer>
  </main>
  <script>
    const POLL_INTERVAL_MS = 10000;
    const byId = (id) => document.getElementById(id);
    const text = (value) => value === null || value === undefined || value === "" ? "unknown" : String(value);

    function setText(id, value) {
      byId(id).textContent = text(value);
    }

    function parseTimestamp(value) {
      if (!value) return null;
      const date = new Date(String(value).replace(" ", "T"));
      return Number.isNaN(date.getTime()) ? null : date;
    }

    function relativeTime(value) {
      const date = parseTimestamp(value);
      if (!date) return "unknown";
      const seconds = Math.round((Date.now() - date.getTime()) / 1000);
      const abs = Math.abs(seconds);
      const suffix = seconds >= 0 ? "ago" : "from now";
      if (abs < 5) return "just now";
      if (abs < 60) return `${abs}s ${suffix}`;
      const minutes = Math.round(abs / 60);
      if (minutes < 60) return `${minutes}m ${suffix}`;
      const hours = Math.round(minutes / 60);
      if (hours < 24) return `${hours}h ${suffix}`;
      const days = Math.round(hours / 24);
      if (days < 30) return `${days}d ${suffix}`;
      const months = Math.round(days / 30);
      if (months < 12) return `${months}mo ${suffix}`;
      return `${Math.round(months / 12)}y ${suffix}`;
    }

    function setRelativeText(id, value, prefix = "") {
      const node = byId(id);
      node.textContent = value ? `${prefix}${relativeTime(value)}` : "unknown";
      node.title = value || "";
    }

    function timeEl(value) {
      const node = el("time", relativeTime(value));
      node.dateTime = value || "";
      node.title = value || "";
      return node;
    }

    function fmtAge(seconds) {
      if (seconds === null || seconds === undefined) return "log missing";
      if (seconds < 60) return `${seconds}s old`;
      const minutes = Math.floor(seconds / 60);
      if (minutes < 60) return `${minutes}m old`;
      return `${Math.floor(minutes / 60)}h ${minutes % 60}m old`;
    }

    function renderPlayers(players) {
      const tbody = byId("players");
      tbody.textContent = "";
      if (!players.length) {
        const row = document.createElement("tr");
        const cell = document.createElement("td");
        cell.colSpan = 4;
        cell.className = "empty";
        cell.textContent = "No human players currently derived from the log.";
        row.appendChild(cell);
        tbody.appendChild(row);
        return;
      }
      for (const player of players) {
        const row = document.createElement("tr");
        const cells = [
          ["Slot", `#${player.slot}`],
          ["Name", player.name],
          ["Team", player.team],
          ["Joined", relativeTime(player.joined_at), player.joined_at],
        ];
        for (const [label, value, title] of cells) {
          const cell = document.createElement("td");
          cell.dataset.label = label;
          cell.textContent = text(value);
          if (title) cell.title = title;
          if (label === "Slot") cell.className = "slot";
          if (label === "Team") cell.className = "team";
          if (label === "Joined") cell.className = "time";
          row.appendChild(cell);
        }
        tbody.appendChild(row);
      }
    }

    function renderChat(messages) {
      const panel = byId("chat");
      panel.textContent = "";
      if (!messages.length) {
        panel.appendChild(empty("No chat lines found."));
        return;
      }
      for (const msg of [...messages].reverse()) {
        const row = document.createElement("div");
        row.className = "feed-row";
        row.appendChild(timeEl(msg.ts));
        row.appendChild(el("div", `${msg.name} @${msg.channel}`, "meta"));
        row.appendChild(el("div", msg.message, "message"));
        panel.appendChild(row);
      }
    }

    function renderEvents(events) {
      const panel = byId("events");
      panel.textContent = "";
      if (!events.length) {
        panel.appendChild(empty("No recent activity found."));
        return;
      }
      for (const event of [...events].reverse()) {
        const row = document.createElement("div");
        row.className = "event-row";
        row.appendChild(timeEl(event.ts));
        row.appendChild(el("span", event.kind, `badge ${event.kind}`));
        row.appendChild(el("div", `${event.name} ${event.detail}`, "message"));
        panel.appendChild(row);
      }
    }

    function renderAlerts(alerts) {
      const panel = byId("alerts");
      panel.textContent = "";
      if (!alerts.length) {
        panel.appendChild(empty("No alert lines in the current log window."));
        return;
      }
      for (const alert of [...alerts].reverse()) {
        const row = document.createElement("div");
        row.className = "event-row";
        row.appendChild(timeEl(alert.ts));
        row.appendChild(el("span", alert.severity, `badge ${alert.severity}`));
        row.appendChild(el("div", alert.message, "message"));
        panel.appendChild(row);
      }
    }

    function el(tag, value, className) {
      const node = document.createElement(tag);
      if (className) node.className = className;
      node.textContent = text(value);
      return node;
    }

    function empty(value) {
      return el("div", value, "empty");
    }

    async function refresh() {
      try {
        const response = await fetch("/api/state", { cache: "no-store" });
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        const state = await response.json();
        setText("map", state.server.map);
        setRelativeText("map-started", state.server.map_started_at, "started ");
        setText("humans", state.counts.humans);
        setText("bots", state.counts.bots);
        setRelativeText("generated", state.generated_at);
        setRelativeText("last-log", state.server.last_log_ts, "last log ");
        setText("log-age", fmtAge(state.server.log_age_seconds));
        const health = byId("health");
        health.textContent = state.server.health;
        health.className = `value ${state.server.health}`;
        renderPlayers(state.players);
        renderChat(state.chat);
        renderEvents(state.recent_events);
        renderAlerts(state.alerts);
        byId("footer").textContent = `${state.server.log_path} | ${state.server.total_lines} parsed lines | polling every ${POLL_INTERVAL_MS / 1000}s`;
      } catch (error) {
        const health = byId("health");
        health.textContent = "error";
        health.className = "value stale";
        byId("footer").textContent = `Dashboard refresh failed: ${error.message}`;
      }
    }

    refresh();
    setInterval(refresh, POLL_INTERVAL_MS);
  </script>
</body>
</html>
"""


class DashboardHandler(BaseHTTPRequestHandler):
    log_path: Path = DEFAULT_LOG
    parser: LogParser = LogParser(DEFAULT_LOG)
    feed: livemap.FeedReader | None = None
    maps: livemap.MapAssets | None = None

    # --- live map ----------------------------------------------------------

    def _map_name_from_route(self, route: str) -> str:
        return unquote(route[len("/api/map/"):])

    def handle_livemap_routes(self, route: str) -> bool:
        """Returns True if the route was handled here."""
        if route == "/map":
            self.send_bytes(MAP_HTML.encode("utf-8"), "text/html; charset=utf-8")
            return True

        # Static review page for tools/spawns.py output. The overlay images it
        # references are ordinary entries in dashboard/maps/, so this adds no
        # new file-serving path.
        if route == "/spawns":
            self.send_bytes(SPAWNS_HTML.encode("utf-8"), "text/html; charset=utf-8")
            return True

        if route == "/api/positions":
            snap = self.feed.latest() if self.feed else None
            body = snap.to_dict() if snap else {"tick": None, "map": None,
                                                "players": [], "stale": True}
            self.send_bytes(json.dumps(body).encode("utf-8"),
                            "application/json; charset=utf-8")
            return True

        if route == "/api/livemap/stats":
            stats = self.feed.stats() if self.feed else {}
            stats["maps_available"] = self.maps.available() if self.maps else []
            self.send_bytes(json.dumps(stats).encode("utf-8"),
                            "application/json; charset=utf-8")
            return True

        if route.startswith("/api/map/"):
            name = self._map_name_from_route(route)
            if name.endswith(".png"):
                png = self.maps.png_bytes(name[:-4]) if self.maps else None
                if png is None:
                    self.send_bytes(b"no such map image\n", "text/plain; charset=utf-8",
                                    status=HTTPStatus.NOT_FOUND)
                else:
                    # Map images are immutable per render; let the browser keep
                    # them so a map change is the only time we ship ~60KB.
                    self.send_bytes(png, "image/png", cache="public, max-age=3600")
                return True
            meta = self.maps.meta(name) if self.maps else None
            if meta is None:
                self.send_bytes(b"{}", "application/json; charset=utf-8",
                                status=HTTPStatus.NOT_FOUND)
            else:
                self.send_bytes(json.dumps(meta).encode("utf-8"),
                                "application/json; charset=utf-8")
            return True

        if route == "/events/positions":
            self.stream_positions()
            return True

        return False

    def stream_positions(self) -> None:
        """Server-Sent Events: one event per new tick.

        SSE over hand-rolled WebSocket framing because the feed is strictly
        one-directional and the browser reconnects on its own.
        """
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", "text/event-stream; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Connection", "keep-alive")
        # X-Accel-Buffering is an nginx directive; it helps behind nginx and is
        # ignored by Cloudflare. Cloudflare QUICK tunnels buffer event-streams
        # regardless (~20s to first event, measured), and padding the stream does
        # NOT reliably defeat it -- 8K/32K/64K shortened the delay while
        # 128K/256K did not, so there is no byte threshold to push past. The
        # page therefore probes the stream and falls back to polling; see the
        # transport note in livemap_page.py. A small preamble is still sent
        # because it does help ordinary reverse proxies flush early.
        self.send_header("X-Accel-Buffering", "no")
        self.end_headers()
        self.wfile.write(b": " + b"p" * SSE_PAD_BYTES + b"\n\n")
        self.wfile.flush()

        # Bounded lifetime: ThreadingHTTPServer dedicates a thread per
        # connection and this loop would otherwise hold one forever. A tab left
        # open in a background window never errors, so nothing would reclaim it.
        # Returning after SSE_MAX_SECONDS costs the client nothing -- an
        # EventSource reconnects on its own -- and guarantees threads recycle.
        deadline = time.time() + SSE_MAX_SECONDS
        last = None
        try:
            while time.time() < deadline:
                snap = self.feed.wait_for_next(last, timeout=10.0) if self.feed else None
                if snap is None:
                    # Comment frame doubles as a keep-alive through proxies.
                    self.wfile.write(b": no-data\n\n")
                    self.wfile.flush()
                    continue
                last = snap.tick
                payload = json.dumps(snap.to_dict())
                self.wfile.write(f"data: {payload}\n\n".encode("utf-8"))
                self.wfile.flush()
        except (BrokenPipeError, ConnectionResetError):
            return  # client navigated away

    def do_HEAD(self) -> None:
        route = urlparse(self.path).path
        if route == "/":
            self.send_head_headers(len(HTML.encode("utf-8")), "text/html; charset=utf-8")
            return
        if route == "/api/state":
            self.send_head_headers(0, "application/json; charset=utf-8")
            return
        # Livemap routes answer HEAD too -- proxies and Cloudflare Access probe
        # with HEAD, and a 404 there while GET returns 200 looks like an outage.
        if route == "/map":
            self.send_head_headers(len(MAP_HTML.encode("utf-8")),
                                   "text/html; charset=utf-8")
            return
        if route == "/spawns":
            self.send_head_headers(len(SPAWNS_HTML.encode("utf-8")),
                                   "text/html; charset=utf-8")
            return
        if route in ("/api/positions", "/api/livemap/stats") or route.startswith("/api/map/"):
            ctype = "image/png" if route.endswith(".png") else "application/json; charset=utf-8"
            self.send_head_headers(0, ctype)
            return
        if route == "/events/positions":
            self.send_head_headers(0, "text/event-stream; charset=utf-8")
            return
        self.send_head_headers(0, "text/plain; charset=utf-8", status=HTTPStatus.NOT_FOUND)

    def do_GET(self) -> None:
        route = urlparse(self.path).path
        if route == "/":
            self.send_bytes(HTML.encode("utf-8"), "text/html; charset=utf-8")
            return
        try:
            if self.handle_livemap_routes(route):
                return
        except (BrokenPipeError, ConnectionResetError):
            return
        except Exception as exc:  # noqa: BLE001 - keep HTTP handler resilient.
            self.send_bytes(
                json.dumps({"error": html.escape(str(exc))}).encode("utf-8"),
                "application/json; charset=utf-8",
                status=HTTPStatus.INTERNAL_SERVER_ERROR,
            )
            return
        if route == "/api/state":
            try:
                payload = json.dumps(self.parser.snapshot(), ensure_ascii=False).encode("utf-8")
                self.send_bytes(payload, "application/json; charset=utf-8")
            except Exception as exc:  # noqa: BLE001 - keep HTTP handler resilient.
                message = {"error": html.escape(str(exc))}
                self.send_bytes(
                    json.dumps(message).encode("utf-8"),
                    "application/json; charset=utf-8",
                    status=HTTPStatus.INTERNAL_SERVER_ERROR,
                )
            return
        self.send_bytes(b"not found\n", "text/plain; charset=utf-8", status=HTTPStatus.NOT_FOUND)

    def log_message(self, fmt: str, *args: Any) -> None:
        print(f"{self.address_string()} - {fmt % args}")

    def send_bytes(
        self,
        payload: bytes,
        content_type: str,
        status: HTTPStatus = HTTPStatus.OK,
        cache: str = "no-store",
    ) -> None:
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Cache-Control", cache)
        self.end_headers()
        self.wfile.write(payload)

    def send_head_headers(
        self,
        content_length: int,
        content_type: str,
        status: HTTPStatus = HTTPStatus.OK,
    ) -> None:
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(content_length))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()


def main() -> None:
    parser = argparse.ArgumentParser(description="Run the MOHAA read-only web dashboard.")
    parser.add_argument("--host", default=os.environ.get("MOHAA_DASHBOARD_HOST", DEFAULT_HOST))
    parser.add_argument(
        "--port",
        type=int,
        default=int(os.environ.get("MOHAA_DASHBOARD_PORT", DEFAULT_PORT)),
    )
    parser.add_argument(
        "--log",
        type=Path,
        default=Path(os.environ.get("MOHAA_LOG", DEFAULT_LOG)),
        help=f"path to qconsole.log (default: {DEFAULT_LOG})",
    )
    parser.add_argument(
        "--feed",
        type=Path,
        default=Path(os.environ.get("MOHAA_LIVEMAP_FEED", livemap.DEFAULT_FEED)),
        help=f"live position snapshot (default: {livemap.DEFAULT_FEED})",
    )
    parser.add_argument(
        "--maps",
        type=Path,
        default=Path(os.environ.get("MOHAA_LIVEMAP_MAPS", livemap.DEFAULT_MAPS)),
        help="directory of pre-rendered <map>.png/.json (see tools/bspmap.py)",
    )
    args = parser.parse_args()

    DashboardHandler.log_path = args.log.expanduser()
    DashboardHandler.parser = LogParser(DashboardHandler.log_path)

    DashboardHandler.feed = livemap.FeedReader(args.feed)
    DashboardHandler.feed.start()
    DashboardHandler.maps = livemap.MapAssets(args.maps)

    server = ThreadingHTTPServer((args.host, args.port), DashboardHandler)
    print(f"MOHAA dashboard listening on http://{args.host}:{args.port}")
    print(f"Reading log: {DashboardHandler.log_path}")
    print(f"Live map:    http://{args.host}:{args.port}/map")
    print(f"  feed: {args.feed}")
    print(f"  maps: {args.maps} ({len(DashboardHandler.maps.available())} rendered)")
    server.serve_forever()


if __name__ == "__main__":
    main()
