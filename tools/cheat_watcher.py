#!/usr/bin/env python3
"""
cheat_watcher2.py - persistent external anticheat watcher.

Rule:
  VPN/datacenter IP AND ([KMFLAG] above threshold OR [AIMBOT] PUNISH)
  -> persist suspect IP and nerf current slot.

Persistence:
  Confirmed suspect IPs are stored in suspects.json. On every later
  "has entered the battle" line, the watcher re-issues the nerf for that IP's
  current slot. It intentionally ignores "is preparing for deployment" because
  the player entity may not exist yet.
"""

import argparse
import ipaddress
import json
import os
import re
import subprocess
import time
import urllib.request
from datetime import datetime, timezone


LOG_PATH = os.environ.get("MOHAA_LOG", os.path.expanduser("~/.openmohaa/main/qconsole.log"))
AUDIT_PATH = os.environ.get(
    "WATCHER_AUDIT",
    os.path.expanduser("~/.openmohaa/main/anticheat/watcher2_audit.log"),
)
SUSPECTS_PATH = os.environ.get(
    "WATCHER_SUSPECTS",
    os.path.expanduser("~/.openmohaa/main/anticheat/suspects.json"),
)
VPN_CACHE_PATH = os.environ.get(
    "WATCHER_VPN_CACHE",
    os.path.expanduser("~/.openmohaa/main/anticheat/vpn_cache.json"),
)
SCREEN_SESSION = os.environ.get("MOHAA_SCREEN", "mohaa_server")
NERF_CMD_TEMPLATE = os.environ.get("WATCHER_NERF_CMD", "set ac_nerf_slot {slot}")

WHITELIST_IPS = {"92.154.80.194", "192.168.1.11", "127.0.0.1"}
KM_MIN_KILLS = int(os.environ.get("WATCHER_KM_MIN_KILLS", "40"))
KM_MIN_RATE = float(os.environ.get("WATCHER_KM_MIN_RATE", "7"))

IPAPI_URL = "http://ip-api.com/json/{ip}?fields=status,query,country,isp,org,as,hosting,proxy,mobile"

RE_KMFLAG = re.compile(
    r"\[KMFLAG\]\s+slot=(?P<slot>\d+)\s+"
    r"ip=(?P<ip>\d+\.\d+\.\d+\.\d+)(?::\d+)?\s+"
    r"(?:kills=(?P<kills>\d+)\s+)?"
    r"km=(?P<km>[\d.]+)\s+name=(?P<name>.+)$"
)
RE_AIMBOT_PUNISH = re.compile(
    r"\[AIMBOT\]\s+PUNISH\s+slot=(?P<slot>\d+)\s+"
    r"ip=(?P<ip>\d+\.\d+\.\d+\.\d+)(?::\d+)?\s+"
    r"name=(?P<name>.+?)\s+\|"
)
RE_ENTER = re.compile(
    r"\{#(?P<slot>\d+) \| (?P<ip>\d+\.\d+\.\d+\.\d+):\d+\}\s+"
    r"(?P<name>.+?) has entered the battle$"
)
RE_MAPCHANGE = re.compile(r"\]\s*Server:\s+\S+\s*$")

vpn_cache = {}
suspects = {}
nerfed_this_map = set()


def now_iso():
    return datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds")


def audit(msg):
    line = f"[{now_iso()}] {msg}"
    print(line, flush=True)
    try:
        os.makedirs(os.path.dirname(AUDIT_PATH), exist_ok=True)
        with open(AUDIT_PATH, "a") as f:
            f.write(line + "\n")
    except OSError as e:
        print(f"[{now_iso()}] AUDIT-WRITE-FAILED: {e}", flush=True)


def load_json(path, default):
    try:
        with open(path) as f:
            data = json.load(f)
    except (OSError, json.JSONDecodeError):
        return default
    return data if isinstance(data, type(default)) else default


def save_json(path, data):
    try:
        directory = os.path.dirname(path)
        os.makedirs(directory, exist_ok=True)
        tmp_path = path + ".tmp"
        with open(tmp_path, "w") as f:
            json.dump(data, f, indent=2, sort_keys=True)
            f.write("\n")
        os.replace(tmp_path, path)
    except OSError as e:
        audit(f"SAVE-FAILED path={path!r} err={e}")


def load_state():
    global vpn_cache, suspects
    vpn_cache = load_json(VPN_CACHE_PATH, {})
    suspects = load_json(SUSPECTS_PATH, {})
    if not isinstance(suspects, dict):
        suspects = {}


def save_vpn_cache():
    save_json(VPN_CACHE_PATH, {k: v for k, v in vpn_cache.items() if v is not None})


def save_suspects():
    save_json(SUSPECTS_PATH, suspects)


def is_whitelisted(ip):
    return ip in WHITELIST_IPS


def is_private_ip(ip):
    try:
        addr = ipaddress.ip_address(ip)
    except ValueError:
        return False
    return addr.is_private or addr.is_loopback


def lookup_vpn(ip):
    if ip in vpn_cache:
        return vpn_cache[ip]

    if is_whitelisted(ip) or is_private_ip(ip):
        vpn_cache[ip] = {"proxy": False, "hosting": False, "org": "private/whitelist"}
        return vpn_cache[ip]

    try:
        with urllib.request.urlopen(IPAPI_URL.format(ip=ip), timeout=10) as r:
            data = json.load(r)
        if data.get("status") != "success":
            vpn_cache[ip] = None
            return None
        vpn_cache[ip] = data
        save_vpn_cache()
        return data
    except Exception as e:
        audit(f"VPN-LOOKUP-FAILED ip={ip} err={e}")
        vpn_cache[ip] = None
        return None


def is_vpn(info):
    return bool(info) and (info.get("proxy") or info.get("hosting"))


def send_console(cmd):
    try:
        subprocess.run(
            ["screen", "-S", SCREEN_SESSION, "-p", "0", "-X", "stuff", cmd + "\n"],
            check=True,
            capture_output=True,
            timeout=5,
        )
        return True
    except Exception as e:
        audit(f"CONSOLE-SEND-FAILED cmd={cmd!r} err={e}")
        return False


def issue_nerf(slot, name, ip, reason, armed, latch=True):
    if latch and ip in nerfed_this_map:
        audit(f"NERF-SKIPPED slot={slot} name={name!r} ip={ip} | already nerfed this map | {reason}")
        return

    if not armed or not NERF_CMD_TEMPLATE:
        nerfed_this_map.add(ip)
        audit(f"WOULD NERF slot={slot} name={name!r} ip={ip} | {reason}")
        return

    cmd = NERF_CMD_TEMPLATE.format(slot=slot, name=name, ip=ip)
    if send_console(cmd):
        nerfed_this_map.add(ip)
        audit(f"NERFED slot={slot} name={name!r} ip={ip} | {reason} | cmd={cmd!r}")
    else:
        audit(f"NERF-FAILED slot={slot} name={name!r} ip={ip} | {reason}")


def remember_suspect(ip, name, info, reason, signal, km=None, kills=None):
    now = now_iso()
    entry = suspects.get(ip, {})
    names = entry.get("names", [])
    if name and name not in names:
        names.append(name)

    entry.update(
        {
            "ip": ip,
            "first_seen": entry.get("first_seen", now),
            "last_seen": now,
            "last_name": name,
            "last_km": km,
            "last_kills": kills,
            "last_signal": signal,
            "reason": reason,
            "org": (info or {}).get("org", "?"),
            "isp": (info or {}).get("isp", "?"),
            "as": (info or {}).get("as", "?"),
            "country": (info or {}).get("country", "?"),
            "proxy": bool((info or {}).get("proxy")),
            "hosting": bool((info or {}).get("hosting")),
            "names": names[-20:],
        }
    )
    suspects[ip] = entry
    save_suspects()


def handle_kmflag(slot, ip, kills, km, name, armed):
    if is_whitelisted(ip):
        audit(f"KMFLAG whitelist ignored name={name!r} ip={ip} kills={kills} km={km}")
        return

    if kills is None:
        audit(f"KMFLAG missing-kills ignored name={name!r} ip={ip} km={km}")
        return

    try:
        kills_i = int(kills)
        km_f = float(km)
    except ValueError:
        audit(f"KMFLAG bad-values ignored name={name!r} ip={ip} kills={kills!r} km={km!r}")
        return

    if kills_i < KM_MIN_KILLS or km_f < KM_MIN_RATE:
        audit(
            f"KMFLAG below-threshold ignored name={name!r} ip={ip} "
            f"kills={kills_i}/{KM_MIN_KILLS} km={km_f}/{KM_MIN_RATE}"
        )
        return

    info = lookup_vpn(ip)
    if not is_vpn(info):
        audit(f"KMFLAG not-vpn ignored name={name!r} ip={ip} kills={kills_i} km={km_f} org={(info or {}).get('org', '?')!r}")
        return

    reason = f"VPN + kills={kills_i} + km={km_f}"
    remember_suspect(ip, name, info, reason, "kmflag", km=km_f, kills=kills_i)
    issue_nerf(slot, name, ip, reason, armed)


def handle_aimbot_punish(slot, ip, name, armed):
    if is_whitelisted(ip):
        audit(f"AIMBOT-PUNISH whitelist ignored name={name!r} ip={ip}")
        return

    info = lookup_vpn(ip)
    if not is_vpn(info):
        audit(f"AIMBOT-PUNISH not-vpn ignored name={name!r} ip={ip} org={(info or {}).get('org', '?')!r}")
        return

    reason = "VPN + AIMBOT PUNISH"
    remember_suspect(ip, name, info, reason, "aimbot_punish")
    issue_nerf(slot, name, ip, reason, armed)


def handle_enter(slot, ip, name, armed):
    if is_whitelisted(ip):
        return

    if ip in suspects:
        suspects[ip]["last_seen"] = now_iso()
        suspects[ip]["last_name"] = name
        if name and name not in suspects[ip].get("names", []):
            suspects[ip].setdefault("names", []).append(name)
            suspects[ip]["names"] = suspects[ip]["names"][-20:]
        save_suspects()
        issue_nerf(slot, name, ip, "known suspect re-entered battle", armed, latch=False)
        return

    info = lookup_vpn(ip)
    if is_vpn(info):
        audit(f"CONNECT vpn-only name={name!r} ip={ip} org={(info or {}).get('org', '?')!r}")


def handle_mapchange():
    nerfed_this_map.clear()


def process(line, armed):
    m = RE_KMFLAG.search(line)
    if m:
        handle_kmflag(
            m.group("slot"),
            m.group("ip"),
            m.group("kills"),
            m.group("km"),
            m.group("name").strip(),
            armed,
        )
        return

    m = RE_AIMBOT_PUNISH.search(line)
    if m:
        handle_aimbot_punish(m.group("slot"), m.group("ip"), m.group("name").strip(), armed)
        return

    m = RE_ENTER.search(line)
    if m:
        handle_enter(m.group("slot"), m.group("ip"), m.group("name").strip(), armed)
        return

    if RE_MAPCHANGE.search(line):
        handle_mapchange()


def tail(path):
    while not os.path.exists(path):
        time.sleep(1)

    f = open(path, "r", errors="replace")
    f.seek(0, os.SEEK_END)
    inode = os.fstat(f.fileno()).st_ino

    while True:
        line = f.readline()
        if line:
            yield line.rstrip("\n")
            continue

        time.sleep(0.25)
        try:
            if os.stat(path).st_ino != inode:
                f.close()
                f = open(path, "r", errors="replace")
                inode = os.fstat(f.fileno()).st_ino
        except FileNotFoundError:
            time.sleep(1)


def main():
    ap = argparse.ArgumentParser(description="MoHAA persistent cheat watcher ([KMFLAG] + VPN -> nerf).")
    ap.add_argument("--arm", action="store_true", help="Actually issue nerfs. Default is dry-run.")
    ap.add_argument("--log", default=LOG_PATH, help="Path to qconsole.log.")
    ap.add_argument("--from-start", action="store_true", help="Process the existing log before following.")
    ap.add_argument("--backfill-only", action="store_true", help="Process the existing log and exit.")
    args = ap.parse_args()

    load_state()
    mode = "ARMED" if args.arm and NERF_CMD_TEMPLATE else "DRY-RUN"
    if args.arm and not NERF_CMD_TEMPLATE:
        mode = "DRY-RUN (--arm ignored: WATCHER_NERF_CMD is empty)"
    audit(
        f"cheat_watcher2 start | mode={mode} | log={args.log} | session={SCREEN_SESSION} "
        f"| suspects={SUSPECTS_PATH} | loaded={len(suspects)} "
        f"| rule: VPN AND ((kills>={KM_MIN_KILLS} AND km>={KM_MIN_RATE}) OR AIMBOT PUNISH)"
    )

    if (args.from_start or args.backfill_only) and os.path.exists(args.log):
        with open(args.log, "r", errors="replace") as f:
            for line in f:
                process(line.rstrip("\n"), args.arm)

    if args.backfill_only:
        audit("backfill-only complete; exiting")
        return

    try:
        for line in tail(args.log):
            process(line, args.arm)
    except KeyboardInterrupt:
        audit("cheat_watcher2 stopped")


if __name__ == "__main__":
    main()
