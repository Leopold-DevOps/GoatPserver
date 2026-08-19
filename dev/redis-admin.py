#!/usr/bin/env python3
"""
Interactive admin tool for the betterSkillys Redis database.

Encodes/decodes values exactly the way Shared/database/RedisObject.cs does:
  int/uint/ushort/float/string -> UTF-8 text          ("1000")
  bool                         -> ONE raw byte        (0x01 / 0x00)
  DateTime                     -> 8 bytes, .NET ToBinary()
  ushort[] / int[]             -> packed little-endian binary
  ItemData[]                   -> JSON text

Keys:
  names               hash  UPPERCASE_IGN -> accountId
  account.<id>        hash  account fields
  char.<accId>.<cId>  hash  character fields
  nextAccId           string

IMPORTANT: the world server caches an account in memory while that player is
logged in, and overwrites Redis when it saves. Edit while the account is
logged out, then log in - or restart the servers after editing.
"""

import sys
import struct
import json
from datetime import datetime, timedelta

try:
    import redis
except ImportError:
    sys.exit("redis-py missing.  Install with:  python -m pip install redis")

HOST, PORT, DB = "127.0.0.1", 6379, 0

# ---------------------------------------------------------------- field types

BOOL_FIELDS = {
    "admin", "banned", "guest", "hidden", "nameChosen", "firstDeath",
    "dead", "hasBackpack", "completedTrialOfSouls",
}
DATETIME_FIELDS = {"regTime", "lastRecoveryTime", "createTime", "lastSeen"}
U16_ARRAY_FIELDS = {"gifts", "skins", "items"}
I32_ARRAY_FIELDS = {"ignoreList", "lockList", "marketOffers", "storedPotions", "stats"}
JSON_FIELDS = {"datas"}
# everything else that is numeric is stored as plain text
TEXT_FIELDS = {"name", "ip", "notes", "uuid", "passResetToken"}

RANKS = {
    0: "Regular", 1: "Donator", 2: "Supporter", 3: "Sponsor",
    4: "Sandbox", 5: "Moderator", 6: "Admin",
}

# account fields worth showing first, in order
ACCOUNT_SUMMARY = [
    "name", "rank", "advRank", "admin", "banned", "fame", "totalFame",
    "credits", "totalCredits", "maxCharSlot", "vaultCount", "guildId",
]

# ------------------------------------------------------------ encode / decode


def decode(field: str, raw: bytes):
    """bytes -> readable python value, mirroring RedisObject.GetValue<T>"""
    if raw is None:
        return None
    if field in BOOL_FIELDS:
        return len(raw) > 0 and raw[0] != 0
    if field in DATETIME_FIELDS:
        if len(raw) != 8:
            return f"<bad datetime {raw!r}>"
        ticks = struct.unpack("<q", raw)[0] & 0x3FFFFFFFFFFFFFFF
        try:
            return datetime(1, 1, 1) + timedelta(microseconds=ticks // 10)
        except OverflowError:
            return f"<datetime overflow {ticks}>"
    if field in U16_ARRAY_FIELDS:
        return list(struct.unpack(f"<{len(raw)//2}H", raw[: len(raw) // 2 * 2]))
    if field in I32_ARRAY_FIELDS:
        return list(struct.unpack(f"<{len(raw)//4}i", raw[: len(raw) // 4 * 4]))
    if field in JSON_FIELDS:
        try:
            return json.loads(raw.decode("utf-8"))
        except Exception:
            return f"<unparsed json, {len(raw)} bytes>"
    try:
        return raw.decode("utf-8")
    except UnicodeDecodeError:
        return f"<binary, {len(raw)} bytes>"


def encode_bool(value: bool) -> bytes:
    return b"\x01" if value else b"\x00"


def encode_int(value: int) -> bytes:
    return str(int(value)).encode("utf-8")


def encode_text(value: str) -> bytes:
    return str(value).encode("utf-8")


# ------------------------------------------------------------------- helpers


def fmt(field, value):
    if field == "rank" and value is not None:
        try:
            return f"{value} ({RANKS.get(int(value), '?')})"
        except (TypeError, ValueError):
            return str(value)
    if isinstance(value, list) and len(value) > 12:
        return f"[{len(value)} entries] {value[:12]}..."
    return str(value)


def prompt(msg, default=None):
    suffix = f" [{default}]" if default is not None else ""
    try:
        got = input(f"{msg}{suffix}: ").strip()
    except (EOFError, KeyboardInterrupt):
        print()
        return None
    return got if got else (default if default is not None else "")


def confirm(msg):
    return (prompt(f"{msg} (y/N)") or "").lower().startswith("y")


# --------------------------------------------------------------- account ops


class Admin:
    def __init__(self):
        self.r = redis.Redis(host=HOST, port=PORT, db=DB)
        self.r.ping()

    # ---- lookup

    def all_accounts(self):
        """[(name, accId)] from the 'names' index, sorted by name."""
        out = []
        for name, aid in self.r.hgetall("names").items():
            try:
                out.append((name.decode("utf-8", "replace"), int(aid)))
            except ValueError:
                continue
        return sorted(out, key=lambda t: t[0])

    def resolve(self, ign: str):
        val = self.r.hget("names", ign.upper())
        return int(val) if val else None

    def account_key(self, aid):
        return f"account.{aid}"

    def load(self, aid):
        raw = self.r.hgetall(self.account_key(aid))
        return {k.decode("utf-8", "replace"): v for k, v in raw.items()}

    # ---- display

    def show(self, aid):
        data = self.load(aid)
        if not data:
            print(f"  no account.{aid} in redis")
            return False
        print(f"\n=== account.{aid} ===")
        for f in ACCOUNT_SUMMARY:
            if f in data:
                print(f"  {f:<14} {fmt(f, decode(f, data[f]))}")
        extra = sorted(set(data) - set(ACCOUNT_SUMMARY))
        if extra:
            print("  --- other fields ---")
            for f in extra:
                print(f"  {f:<14} {fmt(f, decode(f, data[f]))}")
        return True

    def characters(self, aid):
        """character ids belonging to this account"""
        ids = []
        for key in self.r.scan_iter(match=f"char.{aid}.*", count=500):
            try:
                ids.append(int(key.decode().rsplit(".", 1)[-1]))
            except ValueError:
                continue
        return sorted(ids)

    def show_chars(self, aid):
        ids = self.characters(aid)
        if not ids:
            print("  no characters")
            return []
        print(f"\n  characters for account {aid}:")
        for cid in ids:
            raw = self.r.hgetall(f"char.{aid}.{cid}")
            d = {k.decode(): v for k, v in raw.items()}
            lvl = decode("level", d.get("level"))
            fame = decode("fame", d.get("fame"))
            exp = decode("exp", d.get("exp"))
            dead = decode("dead", d.get("dead"))
            ctype = decode("charType", d.get("charType"))
            print(f"    char {cid:<4} type={ctype:<6} lvl={lvl:<4} fame={fame:<8} exp={exp:<10} dead={dead}")
        return ids

    # ---- writes

    def set_field(self, aid, field, raw_bytes, shown):
        key = self.account_key(aid)
        if not self.r.exists(key):
            print(f"  {key} does not exist")
            return
        before = decode(field, self.r.hget(key, field))
        self.r.hset(key, field, raw_bytes)
        print(f"  {field}: {fmt(field, before)}  ->  {fmt(field, shown)}")

    def set_char_field(self, aid, cid, field, raw_bytes, shown):
        key = f"char.{aid}.{cid}"
        if not self.r.exists(key):
            print(f"  {key} does not exist")
            return
        before = decode(field, self.r.hget(key, field))
        self.r.hset(key, field, raw_bytes)
        print(f"  {field}: {fmt(field, before)}  ->  {fmt(field, shown)}")


# ------------------------------------------------------------------ the menu


BANNER = """
betterSkillys redis admin
-------------------------
 1  list accounts
 2  show account
 3  grant FULL admin      (admin=true, rank=6)
 4  revoke admin          (admin=false, rank=0)
 5  set rank
 6  set fame / credits
 7  unban / ban
 8  set max char slots / vault count
 9  characters: set level / fame / exp
10  set any field manually
 q  quit
"""


def pick_account(app):
    """returns accountId or None"""
    who = prompt("account name (or numeric id, blank to cancel)")
    if not who:
        return None
    if who.isdigit():
        return int(who)
    aid = app.resolve(who)
    if aid is None:
        print(f"  no account named '{who}'  (names are matched case-insensitively)")
        return None
    return aid


def main():
    try:
        app = Admin()
    except redis.exceptions.ConnectionError:
        sys.exit(f"cannot reach redis at {HOST}:{PORT} - is redis-server running?")

    total = app.r.get("nextAccId")
    print(f"connected to redis {HOST}:{PORT}  (nextAccId={int(total) if total else '?'})")
    print("NOTE: log the account OUT before editing, or the server may overwrite your changes.")

    while True:
        print(BANNER)
        choice = (prompt("choice") or "").lower()

        if choice in ("q", "quit", "exit"):
            return

        elif choice == "1":
            accounts = app.all_accounts()
            if not accounts:
                print("  no accounts in the 'names' index")
            for name, aid in accounts:
                data = app.load(aid)
                rank = decode("rank", data.get("rank")) or 0
                adm = decode("admin", data.get("admin"))
                fame = decode("fame", data.get("fame"))
                tag = " [ADMIN]" if adm else ""
                print(f"  {aid:<5} {name:<20} rank={rank} ({RANKS.get(int(rank or 0), '?')}) fame={fame}{tag}")

        elif choice == "2":
            aid = pick_account(app)
            if aid is not None:
                if app.show(aid):
                    app.show_chars(aid)

        elif choice == "3":
            aid = pick_account(app)
            if aid is not None and app.show(aid):
                if confirm(f"grant FULL admin to account {aid}?"):
                    app.set_field(aid, "admin", encode_bool(True), True)
                    app.set_field(aid, "rank", encode_int(6), 6)

        elif choice == "4":
            aid = pick_account(app)
            if aid is not None and app.show(aid):
                if confirm(f"revoke admin from account {aid}?"):
                    app.set_field(aid, "admin", encode_bool(False), False)
                    app.set_field(aid, "rank", encode_int(0), 0)

        elif choice == "5":
            aid = pick_account(app)
            if aid is None:
                continue
            app.show(aid)
            print("  ranks: " + ", ".join(f"{k}={v}" for k, v in RANKS.items()))
            val = prompt("new rank (0-6)")
            if val and val.isdigit() and 0 <= int(val) <= 6:
                app.set_field(aid, "rank", encode_int(val), int(val))
            else:
                print("  cancelled / invalid")

        elif choice == "6":
            aid = pick_account(app)
            if aid is None:
                continue
            app.show(aid)
            for field in ("fame", "totalFame", "credits", "totalCredits"):
                val = prompt(f"{field} (blank = leave)")
                if val:
                    try:
                        app.set_field(aid, field, encode_int(val), int(val))
                    except ValueError:
                        print("  not a number, skipped")

        elif choice == "7":
            aid = pick_account(app)
            if aid is None:
                continue
            app.show(aid)
            if confirm("set banned = TRUE? (no = unban)"):
                app.set_field(aid, "banned", encode_bool(True), True)
            else:
                app.set_field(aid, "banned", encode_bool(False), False)
                app.set_field(aid, "banLiftTime", encode_int(0), 0)

        elif choice == "8":
            aid = pick_account(app)
            if aid is None:
                continue
            app.show(aid)
            for field in ("maxCharSlot", "vaultCount"):
                val = prompt(f"{field} (blank = leave)")
                if val:
                    try:
                        app.set_field(aid, field, encode_int(val), int(val))
                    except ValueError:
                        print("  not a number, skipped")

        elif choice == "9":
            aid = pick_account(app)
            if aid is None:
                continue
            ids = app.show_chars(aid)
            if not ids:
                continue
            cid = prompt("character id")
            if not cid or not cid.isdigit() or int(cid) not in ids:
                print("  cancelled / unknown character")
                continue
            for field in ("level", "fame", "exp"):
                val = prompt(f"{field} (blank = leave)")
                if val:
                    try:
                        app.set_char_field(aid, int(cid), field, encode_int(val), int(val))
                    except ValueError:
                        print("  not a number, skipped")

        elif choice == "10":
            aid = pick_account(app)
            if aid is None:
                continue
            app.show(aid)
            field = prompt("field name (exact, case sensitive)")
            if not field:
                continue
            if field in DATETIME_FIELDS or field in U16_ARRAY_FIELDS \
                    or field in I32_ARRAY_FIELDS or field in JSON_FIELDS:
                print(f"  '{field}' is a binary/structured field - not editable here (would corrupt it)")
                continue
            if field in BOOL_FIELDS:
                newval = confirm(f"set {field} = TRUE?")
                app.set_field(aid, field, encode_bool(newval), newval)
                continue
            val = prompt("new value")
            if val == "":
                continue
            if field in TEXT_FIELDS:
                app.set_field(aid, field, encode_text(val), val)
            else:
                try:
                    app.set_field(aid, field, encode_int(val), int(val))
                except ValueError:
                    print("  that field expects a number")

        else:
            print("  unknown choice")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nbye")
