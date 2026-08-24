#!/usr/bin/env python3
"""
Spike: the full Phase-2 discovery chain, end to end, against the real world.

    master server  ->  server list          (TCP 28900, GameSpy v1)
    GameSpy query  ->  hostport + basics    (UDP, the port the master gave us)
    getstatus      ->  full serverinfo      (UDP, the GAME port from hostport)

Two details this spike exists to prove, both verified 6/6 on live servers:

  1. The master returns QUERY ports (mostly 12300), not game ports. The game
     port comes from the "hostport" field in the GameSpy reply, and it is NOT a
     fixed offset -- observed 12203 on most servers but 23900 on one. Never
     compute it; always read it.

  2. getstatus needs MOHAA's five-byte out-of-band header, ff ff ff ff 02.
     The plain four-byte Quake 3 header gets silence, which looks exactly like
     a firewalled port. See fake_client.py, where this was found.

Usage:
    python3 tools/spike_pipeline.py                  # sample 40 servers
    python3 tools/spike_pipeline.py --limit 0        # survey all of them
    python3 tools/spike_pipeline.py --game mohaas    # Spearhead only
"""

import argparse
import base64
import collections
import concurrent.futures
import socket
import struct
import sys

MASTER = ("master.333networks.com", 28900)
OOB_SEND = b"\xff\xff\xff\xff\x02"

# code/gamespy/sv_gamespy.c
GAMES = {
    "mohaa": ("M5Fdwc", "Allied Assault"),
    "mohaas": ("h2P1c9", "Spearhead"),
    "mohaab": ("y32FDc", "Breakthrough"),
}


def gs_encrypt(key, buf):
    key, buf = bytearray(key), bytearray(buf)
    state = bytearray(range(256))
    x = y = 0
    for c in range(256):
        y = (key[x] + state[c] + y) % 256
        x = (x + 1) % len(key)
        state[c], state[y] = state[y], state[c]
    x = y = 0
    for c in range(len(buf)):
        x = (x + buf[c] + 1) % 256
        y = (state[x] + y) % 256
        state[x], state[y] = state[y], state[x]
        buf[c] ^= state[(state[x] + state[y]) % 256]
    return bytes(buf)


def gs_encode(data):
    pad = (3 - len(data) % 3) % 3
    return base64.b64encode(data + b"\0" * pad).decode().replace("=", "")


def master_list(gamename, key, timeout=15.0):
    sock = socket.socket()
    sock.settimeout(timeout)
    sock.connect(MASTER)
    try:
        challenge = sock.recv(256).decode("latin-1").split("\\secure\\")[1].split("\\")[0]
        validate = gs_encode(gs_encrypt(key.encode(), challenge.encode()))
        sock.sendall((
            f"\\gamename\\{gamename}\\gamever\\1\\location\\0\\validate\\{validate}"
            f"\\final\\\\queryid\\1.1\\list\\cmp\\gamename\\{gamename}\\final\\"
        ).encode())
        data = b""
        while True:
            try:
                chunk = sock.recv(8192)
            except socket.timeout:
                break
            if not chunk:
                break
            data += chunk
            if data.endswith(b"\\final\\"):
                break
    finally:
        sock.close()
    body = data.split(b"\\final\\")[0]
    return [
        (".".join(str(b) for b in body[i * 6:i * 6 + 4]),
         struct.unpack(">H", body[i * 6 + 4:i * 6 + 6])[0])
        for i in range(len(body) // 6)
    ]


def kv(text):
    parts = text.split("\\")[1:]
    return dict(zip(parts[0::2], parts[1::2]))


def gamespy_query(ip, port, timeout=2.5):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(timeout)
    try:
        sock.sendto(b"\\status\\", (ip, port))
        data, _ = sock.recvfrom(65535)
        return kv(data.decode("latin-1"))
    finally:
        sock.close()


def getstatus(ip, port, timeout=2.5):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(timeout)
    try:
        sock.sendto(OOB_SEND + b"getstatus", (ip, port))
        data, _ = sock.recvfrom(65535)
        body = data[5:].decode("latin-1", errors="replace")
        return kv(body.partition("\n")[2].split("\n")[0])
    finally:
        sock.close()


def inspect(entry):
    ip, query_port = entry
    row = {"ip": ip, "query_port": query_port, "gamespy": False, "status": False}
    try:
        info = gamespy_query(ip, query_port)
    except Exception:
        return row
    row.update(
        gamespy=True,
        gamever=info.get("gamever", "?"),
        gamename=info.get("gamename", "?"),
        humans=int(info.get("numplayers", 0) or 0),
        maxplayers=int(info.get("maxplayers", 0) or 0),
        mapname=info.get("mapname", "?"),
        hostname=info.get("hostname", "")[:44],
        game_port=int(info.get("hostport", 0) or 0),
    )
    if not row["game_port"]:
        return row
    try:
        full = getstatus(ip, row["game_port"])
    except Exception:
        return row
    row.update(
        status=True,
        keys=len(full),
        maplist=len(full.get("sv_maplist", "").split()),
        allow_download=full.get("sv_allowDownload", "?"),
        pakradar="pr_downloads" in full,
        protocol=full.get("protocol", "?"),
    )
    return row


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--game", choices=sorted(GAMES), default="mohaa")
    parser.add_argument("--limit", type=int, default=40, help="0 surveys every server")
    parser.add_argument("--workers", type=int, default=16)
    args = parser.parse_args()

    key, label = GAMES[args.game]
    print(f"master -> {label} ({args.game})")
    servers = master_list(args.game, key)
    print(f"  {len(servers)} registered")
    if args.limit:
        servers = servers[:args.limit]
    print(f"  probing {len(servers)}\n")

    rows = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        for row in pool.map(inspect, servers):
            rows.append(row)

    live = [r for r in rows if r["gamespy"]]
    full = [r for r in rows if r["status"]]

    print(f"{'server':46} {'version':16} {'players':>8}  maps  dl  pr")
    print("-" * 92)
    for row in sorted(live, key=lambda r: -r.get("humans", 0))[:25]:
        maps = str(row.get("maplist", "-")) if row["status"] else "-"
        dl = row.get("allow_download", "-") if row["status"] else "-"
        pr = ("YES" if row.get("pakradar") else "no") if row["status"] else "-"
        print(f"{row.get('hostname','?'):46.46} {row.get('gamever','?'):16.16} "
              f"{row.get('humans',0):>3}/{row.get('maxplayers',0):<4} {maps:>5}  {dl:>2}  {pr}")

    print(f"\nreachable via GameSpy : {len(live)}/{len(rows)}")
    print(f"reachable via getstatus: {len(full)}/{len(rows)}")
    print(f"total humans online    : {sum(r.get('humans', 0) for r in live)}")

    versions = collections.Counter(r.get("gamever", "?") for r in live)
    print("\nversions in the wild (this is why the launcher must be client-agnostic):")
    for version, count in versions.most_common(10):
        print(f"  {version:20} {count:>4}")

    if full:
        no_dl = sum(1 for r in full if r.get("allow_download") == "0")
        have_ml = sum(1 for r in full if r.get("maplist", 0) > 0)
        pak = sum(1 for r in full if r.get("pakradar"))
        print(f"\nsv_allowDownload=0     : {no_dl}/{len(full)}  (content must pre-exist on disk)")
        print(f"sv_maplist exposed     : {have_ml}/{len(full)}  (full rotation preflight possible)")
        print(f"PakRadar manifests     : {pak}/{len(full)}")

    ports = collections.Counter(r.get("game_port") for r in live if r.get("game_port"))
    print("\ngame ports from hostport (never assume 12203):")
    for port, count in ports.most_common(6):
        print(f"  {port:<8} {count:>4}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
