#!/usr/bin/env python3
"""net-list.sh -- emit the Wi-Fi scan as a JSON array for the eww network panel.

Each element:
    ssid       network name
    esc        shell-quoted ssid (safe to interpolate into an :onclick command)
    signal     strength 0-100
    pct        "NN%"
    glyph      Nerd Font wifi glyph for the strength
    lock       lock glyph when secured, "" otherwise
    connected  bool
    check      check glyph when this is the active network, "" otherwise
    secure     bool
"""
import json
import os
import shlex
import subprocess
import sys

env = dict(os.environ)
env["LC_ALL"] = "C"


def scan():
    try:
        r = subprocess.run(
            ["nmcli", "-m", "multiline",
             "-f", "IN-USE,SSID,SIGNAL,SECURITY",
             "device", "wifi", "list", "--rescan", "no"],
            capture_output=True, text=True, env=env, timeout=6)
        return r.stdout
    except Exception:
        return ""


recs, cur = [], {}
for line in scan().splitlines():
    if ":" not in line:
        continue
    key, val = line.split(":", 1)
    key, val = key.strip(), val.strip()
    if key == "IN-USE":
        cur = {"in_use": val == "*"}
    elif key == "SSID":
        cur["ssid"] = val
    elif key == "SIGNAL":
        try:
            cur["signal"] = int(val)
        except ValueError:
            cur["signal"] = 0
    elif key == "SECURITY":
        cur["security"] = val
        # nmcli prints "--" for hidden/unknown SSIDs -- skip those.
        if cur.get("ssid") and cur["ssid"] != "--":
            recs.append(cur)
        cur = {}

# Deduplicate by SSID, keeping the strongest signal and any connected flag.
best = {}
for r in recs:
    s = r["ssid"]
    if s not in best:
        best[s] = r
    else:
        if r.get("in_use"):
            best[s]["in_use"] = True
        if r["signal"] > best[s]["signal"]:
            best[s]["signal"] = r["signal"]

WIFI = {4: "\U000f0928", 3: "\U000f0925", 2: "\U000f0922", 1: "\U000f091f"}
LOCK = "\uf023"
CHECK = "\uf00c"


def level(sig):
    return 4 if sig >= 75 else 3 if sig >= 50 else 2 if sig >= 25 else 1


ordered = sorted(best.values(),
                 key=lambda r: (not r.get("in_use"), -r["signal"], r["ssid"].lower()))

out = []
for r in ordered:
    sig = r["signal"]
    secure = r["security"] not in ("", "--")
    connected = bool(r.get("in_use"))
    out.append({
        "ssid": r["ssid"],
        "esc": shlex.quote(r["ssid"]),
        "signal": sig,
        "pct": "{}%".format(sig),
        "glyph": WIFI[level(sig)],
        "lock": LOCK if secure else "",
        "connected": connected,
        "check": CHECK if connected else "",
        "secure": secure,
    })

sys.stdout.write(json.dumps(out, ensure_ascii=False))
