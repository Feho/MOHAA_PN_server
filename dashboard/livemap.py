"""Live position feed reader + map asset lookup for the dashboard.

Reads the snapshot written ~5x/second by main/global/feho/livemap.scr and
serves it as JSON/SSE. Stdlib only, to match dashboard/server.py.

Snapshot format (one line, no trailing newline):
    <tick>|<map>|<entnum>,<team>,<x>,<y>,<z>,<yaw>,<bot>;...

The trailing <bot> field (1 = bot, 0 = human) was added after the first
release, so a 6-field chunk is still accepted and means human. That
tolerance is what lets the reader be deployed BEFORE the .scr: the parser
rejects a whole SNAPSHOT on any malformed chunk, not just that chunk, so a
reader that demanded 7 fields would blank the entire feed for as long as
the old producer was live (until the next map change).

The producer's write is NOT atomic (it truncates then writes), so a read can
catch the file empty. Measured on the live server the window is small
(159/159 reads clean at 20Hz) but real, so every read is parsed defensively
and a bad one falls back to the last good snapshot.
"""

from __future__ import annotations

import json
import threading
import time
from dataclasses import dataclass, asdict
from pathlib import Path

DEFAULT_FEED = Path.home() / ".openmohaa" / "main" / "livemap" / "positions.txt"
DEFAULT_MAPS = Path(__file__).resolve().parent / "maps"

# A feed older than this is treated as dead (server down, map without the
# script, or livemap_enabled 0). ~25 missed ticks at 5Hz.
STALE_AFTER_SECONDS = 5.0

TEAM_NAMES = {"a": "allies", "x": "axis"}


@dataclass
class PlayerDot:
    entnum: int
    team: str
    x: int
    y: int
    z: int
    yaw: int
    bot: int = 0


@dataclass
class Snapshot:
    tick: int
    map: str
    players: list[PlayerDot]
    received_at: float

    def age(self) -> float:
        return time.time() - self.received_at

    def to_dict(self) -> dict:
        return {
            "tick": self.tick,
            "map": self.map,
            "players": [asdict(p) for p in self.players],
            "age": round(self.age(), 3),
            "stale": self.age() > STALE_AFTER_SECONDS,
        }


def parse_snapshot(text: str) -> Snapshot | None:
    """Parse one feed line. Returns None for empty/torn/malformed input.

    Deliberately strict: a partially written line must be rejected, not
    half-accepted, or dots jump to bogus coordinates.
    """
    if not text:
        return None
    parts = text.strip().split("|")
    if len(parts) != 3:
        return None
    try:
        tick = int(parts[0])
    except ValueError:
        return None
    # The engine's `mapname` cvar carries the subdirectory ("dm/mohdm3",
    # "obj/obj_team2"). Normalise to the bare stem here so it matches the
    # rendered asset names and survives being put in a URL path.
    mapname = parts[1].rsplit("/", 1)[-1].lower()

    players: list[PlayerDot] = []
    if parts[2]:
        for chunk in parts[2].split(";"):
            f = chunk.split(",")
            # 6 = pre-bot-flag producer, 7 = current. Anything else is a torn
            # tail -> reject the whole snapshot.
            if len(f) not in (6, 7):
                return None
            team = f[1]
            if team not in TEAM_NAMES:
                return None
            try:
                bot = int(f[6]) if len(f) == 7 else 0
                players.append(PlayerDot(int(f[0]), team,
                                         int(f[2]), int(f[3]), int(f[4]), int(f[5]),
                                         1 if bot else 0))
            except ValueError:
                return None
    return Snapshot(tick, mapname, players, time.time())


class FeedReader:
    """Polls the snapshot file and keeps the newest good parse in memory.

    One reader thread serves any number of HTTP clients, so N browsers do not
    become N file reads per tick.
    """

    def __init__(self, path: Path, interval: float = 0.2) -> None:
        self.path = Path(path).expanduser()
        self.interval = interval
        self._lock = threading.Lock()
        self._latest: Snapshot | None = None
        self._reads = 0
        self._discarded = 0
        self._cv = threading.Condition(self._lock)
        self._thread: threading.Thread | None = None

    def start(self) -> None:
        if self._thread is not None:
            return
        self._thread = threading.Thread(target=self._run, daemon=True,
                                        name="livemap-feed")
        self._thread.start()

    def _run(self) -> None:
        while True:
            try:
                text = self.path.read_text(errors="replace")
            except (FileNotFoundError, OSError):
                text = ""
            snap = parse_snapshot(text)
            with self._cv:
                self._reads += 1
                if snap is None:
                    self._discarded += 1     # keep the previous good snapshot
                else:
                    prev = self._latest
                    self._latest = snap
                    if prev is None or prev.tick != snap.tick:
                        self._cv.notify_all()
            time.sleep(self.interval)

    def latest(self) -> Snapshot | None:
        with self._lock:
            return self._latest

    def wait_for_next(self, last_tick: int | None, timeout: float = 10.0):
        """Block until a snapshot newer than last_tick arrives (for SSE)."""
        deadline = time.time() + timeout
        with self._cv:
            while True:
                cur = self._latest
                if cur is not None and (last_tick is None or cur.tick != last_tick):
                    return cur
                remaining = deadline - time.time()
                if remaining <= 0:
                    return cur
                self._cv.wait(remaining)

    def stats(self) -> dict:
        with self._lock:
            return {
                "reads": self._reads,
                "discarded": self._discarded,
                "discard_rate": round(self._discarded / self._reads, 4) if self._reads else 0.0,
                "path": str(self.path),
            }


class MapAssets:
    """Serves the pre-rendered <map>.png and its world->image transform."""

    def __init__(self, directory: Path) -> None:
        self.dir = Path(directory).expanduser()
        self._cache: dict[str, dict | None] = {}

    def _safe(self, mapname: str) -> str:
        # This name arrives from the /api/map/<name> URL, i.e. it IS attacker
        # controlled, and it is about to be joined onto a filesystem path.
        # Reducing to a bare basename defeats ../ traversal and absolute paths.
        return Path(mapname.lower()).name

    def meta(self, mapname: str) -> dict | None:
        key = self._safe(mapname)
        if key in self._cache:
            return self._cache[key]
        p = self.dir / f"{key}.json"
        try:
            data = json.loads(p.read_text())
        except (FileNotFoundError, OSError, json.JSONDecodeError):
            data = None
        self._cache[key] = data
        return data

    def png_bytes(self, mapname: str) -> bytes | None:
        p = self.dir / f"{self._safe(mapname)}.png"
        try:
            return p.read_bytes()
        except (FileNotFoundError, OSError):
            return None

    def available(self) -> list[str]:
        try:
            return sorted(p.stem for p in self.dir.glob("*.png"))
        except OSError:
            return []
