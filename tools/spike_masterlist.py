#!/usr/bin/env python3
"""
Spike: pull the live MOHAA server list from the community master server.

Validates the single biggest untested assumption in the launcher blueprint:
that we can enumerate every public MOHAA/SH/BT server without the game running.

Protocol notes (all verified against the OpenMoHAA source at /home/feho/dev/openmohaa):
  - Legacy GameSpy masters (<gamename>.msN.gamespy.com) are NXDOMAIN and dead.
  - master.333networks.com and master.x-null.net both resolve to 81.205.81.173,
    confirming the xNULL -> 333networks redirect is live.
  - Port 28910 (MSPORT2, the SB protocol) times out. Port 28900 (classic GameSpy
    v1 master) is open and answers with a challenge: \\basic\\\\secure\\XXXXXX
  - The validate response is gs_encode(gs_encrypt(secret_key, challenge)), both
    implemented below from code/gamespy/gutil.c.
  - Secret keys are from code/gamespy/sv_gamespy.c SECRET_GS_KEYS[].
  - "list\\cmp" returns a packed binary list: 4-byte IP + 2-byte big-endian port.

Run:  python3 tools/spike_masterlist.py
"""

import socket
import base64
import struct
import sys

MASTER_HOST = "master.333networks.com"
MASTER_PORT = 28900

# code/gamespy/sv_gamespy.c: GS_GAME_NAME[] / SECRET_GS_KEYS[]
GAMES = [
    ("mohaa", "M5Fdwc", "Allied Assault"),
    ("mohaas", "h2P1c9", "Spearhead"),
    ("mohaab", "y32FDc", "Breakthrough"),
]


def gs_encrypt(key: bytes, buf: bytes) -> bytes:
    """RC4 variant from cengine_gs_encrypt() in code/gamespy/gutil.c."""
    key = bytearray(key)
    buf = bytearray(buf)
    state = bytearray(range(256))

    x = y = 0
    for counter in range(256):
        y = (key[x] + state[counter] + y) % 256
        x = (x + 1) % len(key)
        state[counter], state[y] = state[y], state[counter]

    x = y = 0
    for counter in range(len(buf)):
        x = (x + buf[counter] + 1) % 256
        y = (state[x] + y) % 256
        state[x], state[y] = state[y], state[x]
        buf[counter] ^= state[(state[x] + state[y]) % 256]
    return bytes(buf)


def gs_encode(data: bytes) -> str:
    """base64 variant from cengine_gs_encode(): zero-pads, emits no '=' padding."""
    pad = (3 - len(data) % 3) % 3
    return base64.b64encode(data + b"\0" * pad).decode().replace("=", "")


def fetch(gamename: str, secret_key: str, timeout: float = 12.0):
    sock = socket.socket()
    sock.settimeout(timeout)
    sock.connect((MASTER_HOST, MASTER_PORT))
    try:
        greeting = sock.recv(256).decode("latin-1")
        if "\\secure\\" not in greeting:
            raise RuntimeError(f"unexpected greeting: {greeting!r}")
        challenge = greeting.split("\\secure\\")[1].split("\\")[0]

        validate = gs_encode(gs_encrypt(secret_key.encode(), challenge.encode()))
        query = (
            f"\\gamename\\{gamename}\\gamever\\1\\location\\0\\validate\\{validate}"
            f"\\final\\\\queryid\\1.1\\list\\cmp\\gamename\\{gamename}\\final\\"
        )
        sock.sendall(query.encode())

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
    servers = []
    for i in range(len(body) // 6):
        rec = body[i * 6 : i * 6 + 6]
        ip = ".".join(str(b) for b in rec[:4])
        port = struct.unpack(">H", rec[4:6])[0]
        servers.append((ip, port))
    return servers


def main() -> int:
    print(f"master {MASTER_HOST}:{MASTER_PORT}\n")
    total = 0
    for gamename, key, label in GAMES:
        try:
            servers = fetch(gamename, key)
        except Exception as exc:
            print(f"{label:16} ({gamename}) -> FAILED: {type(exc).__name__}: {exc}")
            continue
        total += len(servers)
        print(f"{label:16} ({gamename}) -> {len(servers)} servers")
        for ip, port in servers[:10]:
            print(f"    {ip}:{port}")
        if len(servers) > 10:
            print(f"    ... and {len(servers) - 10} more")
        print()
    print(f"total: {total} servers")
    return 0 if total else 1


if __name__ == "__main__":
    sys.exit(main())
