"""ShutUpWesley patcher (dev tooling, stdlib only, run with the editor's or any python3).

Copies the uncooked DLC7 bark books (MWDialogueBookAsset, single-file .uasset
packages) from the Mod Editor's game content into the mod's top-level
ModOverride folder (mirrored path, package name stays /Game/...) and rewrites
every MWDialogueLine in place:

  python suw_patch.py --mode silent   # Context GameplayTag -> None (line never matches an event)
  python suw_patch.py --mode quiet    # MaxPlaysPerMission = 1 (each line at most once per mission)
  python suw_patch.py --mode verify   # report current values, no writes

  --src <folder>   originals, default <Editor>\MW5Mercs\Content\DLC7\Dialogue\Barks
  --dst <folder>   output, default <plugin>\ModOverride\DLC7\Dialogue\Barks
  (set MW5_EDITOR to point at your MechWarrior5Editor install)

Shipped books have MaxPlaysPerMission = 0 on every line, which means unlimited,
so Silent cannot use that field; it blanks the Context tag instead.

Tagged-property layout in an uncooked UE4 package (per property):
  [name: FName = int32 index + int32 number]
  [type: FName]
  [size: int32][array index: int32]
  [type-specific extras; none for IntProperty]
  [has property guid: uint8][guid: 16 bytes if set]
  [payload: size bytes]
We locate IntProperty tags whose name is MaxPlaysPerMission by scanning for the
exact 8+8 byte FName pair and validating size==4 / array index==0.
"""
import argparse, os, shutil, struct, sys

ED = os.environ.get("MW5_EDITOR", r"D:\Epic Games\Epic Games\MechWarrior5Editor") + r"\MW5Mercs"
SRC = ED + r"\Content\DLC7\Dialogue\Barks"
# Note: the running editor locks every file under the plugin folder. Patch with the
# editor closed, or write to a staging folder (--dst) and copy in afterwards.
DST = ED + r"\Plugins\ShutUpWesley\ModOverride\DLC7\Dialogue\Barks"

STORY = {"AshBarks", "BarrettBarks", "JacobBarks", "LyanaBarks", "MorganBarks",
         "NickBarks", "RachelBarks", "SamBarks", "SashaBarks"}


def read_fstring(buf, pos):
    n = struct.unpack_from("<i", buf, pos)[0]
    pos += 4
    if n == 0:
        return "", pos
    if n > 0:
        s = buf[pos:pos + n - 1].decode("ascii", "replace")
        return s, pos + n
    n = -n
    s = buf[pos:pos + n * 2 - 2].decode("utf-16-le", "replace")
    return s, pos + n * 2


def name_table(buf):
    """Return list of names from the package summary (UE4.26 layout)."""
    assert struct.unpack_from("<I", buf, 0)[0] == 0x9E2A83C1, "not a UE package"
    pos = 4
    legacy_ver = struct.unpack_from("<i", buf, pos)[0]; pos += 4
    if legacy_ver != -4:
        pos += 4  # LegacyUE3Version
    pos += 4  # FileVersionUE4
    pos += 4  # FileVersionLicenseeUE4
    # custom versions
    cnt = struct.unpack_from("<i", buf, pos)[0]; pos += 4
    pos += cnt * 20
    pos += 4  # TotalHeaderSize
    _, pos = read_fstring(buf, pos)  # FolderName
    pos += 4  # PackageFlags
    name_count, name_offset = struct.unpack_from("<ii", buf, pos)
    names = []
    p = name_offset
    for _ in range(name_count):
        s, p = read_fstring(buf, p)
        p += 4  # two uint16 hashes
        names.append(s)
    return names


def _find_tags(buf, names, prop, ptype, size_expect):
    """Yield (tag_offset, payload_offset) for every property tag prop:ptype."""
    try:
        ni, ti = names.index(prop), names.index(ptype)
    except ValueError:
        return
    tag = struct.pack("<iiii", ni, 0, ti, 0)
    start = 0
    while True:
        i = buf.find(tag, start)
        if i < 0:
            return
        start = i + 1
        size, arr = struct.unpack_from("<ii", buf, i + 16)
        if size != size_expect or arr != 0:
            continue
        p = i + 24
        if ptype == "StructProperty":
            p += 8 + 16  # struct name FName + struct guid
        has_guid = buf[p]; p += 1
        if has_guid:
            p += 16
        yield i, p


def patch_file(path, mode, write):
    """mode: 'silent' blanks Context tags; 'quiet' sets MaxPlaysPerMission=1;
    'verify' reads both. Returns dict of counts/values."""
    buf = bytearray(open(path, "rb").read())
    names = name_table(bytes(buf))
    if "MaxPlaysPerMission" not in names or "Context" not in names:
        return None
    none_idx = names.index("None")
    res = {"plays": [], "ctx": [], "plays_hits": 0, "ctx_hits": 0}
    for _, p in _find_tags(buf, names, "MaxPlaysPerMission", "IntProperty", 4):
        res["plays"].append(struct.unpack_from("<i", buf, p)[0])
        res["plays_hits"] += 1
        if write and mode == "quiet":
            struct.pack_into("<i", buf, p, 1)
    # Uncooked GameplayTag payload (41 bytes) is itself a tagged list:
    #   [TagName FName 8][NameProperty FName 8][size=8 4][arr 4][hasguid 1][value FName 8][None FName 8]
    # so the tag value starts 25 bytes into the payload.
    for _, p0 in _find_tags(buf, names, "Context", "StructProperty", 41):
        p = p0 + 25
        idx = struct.unpack_from("<i", buf, p)[0]
        res["ctx"].append(names[idx] if 0 <= idx < len(names) else "?%d" % idx)
        res["ctx_hits"] += 1
        if write and mode == "silent":
            struct.pack_into("<ii", buf, p, none_idx, 0)
    if write:
        open(path, "wb").write(buf)
    return res


def main():
    global SRC, DST
    ap = argparse.ArgumentParser()
    ap.add_argument("--mode", choices=["silent", "quiet", "verify"], required=True)
    ap.add_argument("--include-story", action="store_true")
    ap.add_argument("--src", default=SRC, help="folder of original (unpatched) books")
    ap.add_argument("--dst", default=DST, help="folder to write patched books into / verify")
    a = ap.parse_args()
    SRC, DST = a.src, a.dst
    write = a.mode != "verify"
    os.makedirs(DST, exist_ok=True)
    total = 0
    for fn in sorted(os.listdir(SRC)):
        if not fn.endswith(".uasset"):
            continue
        book = fn[:-7]
        if book in STORY and not a.include_story:
            print("skip   %-26s (story character)" % book)
            continue
        dst = os.path.join(DST, fn)
        if write:
            if os.path.exists(dst):
                os.chmod(dst, 0o666)
            shutil.copyfile(os.path.join(SRC, fn), dst)
            os.chmod(dst, 0o666)  # game content ships read-only; our copy must be writable
        target = dst if os.path.exists(dst) else os.path.join(SRC, fn)
        r = patch_file(target, a.mode, write)
        if r is None:
            print("ERROR  %-26s name table lacks MaxPlaysPerMission/Context" % book)
            sys.exit(1)
        if r["plays_hits"] != r["ctx_hits"]:
            print("ERROR  %-26s plays=%d ctx=%d mismatch" % (book, r["plays_hits"], r["ctx_hits"]))
            sys.exit(1)
        total += r["plays_hits"]
        ctx_kinds = sorted(set(c.split(".")[0] for c in r["ctx"]))
        print("%-6s %-26s %3d lines  plays=%s ctx=%s" % (a.mode, book, r["plays_hits"], sorted(set(r["plays"])), ctx_kinds))
    print("--- %d lines %s" % (total, "patched" if write else "inspected"))
    if write:
        # Read back from the written files.
        bad = 0
        for fn in sorted(os.listdir(DST)):
            if not fn.endswith(".uasset"):
                continue
            r = patch_file(os.path.join(DST, fn), "verify", False)
            ok = (a.mode == "quiet" and set(r["plays"]) == {1}) or (a.mode == "silent" and set(r["ctx"]) == {"None"})
            if not ok:
                bad += 1
                print("VERIFY FAIL %s plays=%s ctx=%s" % (fn, sorted(set(r["plays"])), sorted(set(r["ctx"]))))
        print("--- readback: %s" % ("all OK" if bad == 0 else "%d FAILED" % bad))


if __name__ == "__main__":
    main()
