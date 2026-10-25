#!/usr/bin/env python3
"""Validate the lab references on the wiki's pages against tracks/.

Usage: tools/lint-wiki.sh [wiki-dir]   (no argument: shallow-clone the repo's wiki)

Findings (exit 1): a lab id that exists in no track / not in the track the
reference names, and a stated description sharing no content word with the real
title. Wiki tables paraphrase on purpose, so titles are not matched exactly:
"Channels (`mpsc`)" against "Channels" shares a word and passes; "reading
obfuscated shell" against "Severity and priority" shares none and fails.

A reference with no track context (a cross-track page, no track word before the
id) is counted and skipped, never guessed.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TRACK_WORDS = {"rust": "rust", "bash": "bash", "soc": "soc", "powershell": "ps", "ps": "ps"}
STOP = set("the and for with from into what how why not are its one two use via per all any can that this".split())
# "<optional track word> L<phase>.<n>[–<n>]" then whatever describes it.
REF = re.compile(r"(?:(?P<track>[A-Za-z]+)\s+)?\bL(?P<a>\d+)\.(?P<b>\d+)(?:\s*[–-]\s*(?:L?\d+\.)?(?P<c>\d+))?")


def catalog():
    cat = {}
    for meta in ROOT.glob("tracks/*/phases/*/L*/meta.json"):
        track = meta.relative_to(ROOT).parts[1]
        if track == "demo":
            continue
        m = json.loads(meta.read_text())
        cat.setdefault(track, {})[m["id"]] = m.get("title", "")
    return cat


def words(text):
    out = set()
    for w in re.findall(r"[a-z0-9]+", text.lower()):
        w = w[:-1] if w.endswith("s") and len(w) > 3 else w
        if len(w) >= 3 and w not in STOP:
            out.add(w)
    return out


def overlap(desc, title):
    for a in words(desc):
        for b in words(title):
            if a == b or (len(a) >= 5 and len(b) >= 5 and a[:5] == b[:5]):
                return True
    return False


def page_track(path):
    name = path.stem.lower()
    hits = {t for k, t in TRACK_WORDS.items() if k in re.split(r"[^a-z]+", name)}
    return hits.pop() if len(hits) == 1 else None


def description(line, end):
    """The title-like text the page gives for the id that ends at `end`, or "" when
    the page gives none. Only two shapes count: the next table cell (the id sits
    alone in its cell), and "<id> - description" with an explicit dash. A lab id
    mentioned mid-sentence has no description to compare, so it is only checked
    for existence."""
    rest = line[end:]
    if re.match(r"\s*\|", rest):
        cells = [c.strip() for c in re.split(r"(?<!\\)\|", rest)[1:]]
        return next((c for c in cells if c), "")
    dash = re.match(r"\s*[—–]\s*|\s+-\s+", rest)
    if not dash:
        return ""
    return re.split(r"(?<!\\)\||\*\*|→", rest[dash.end():])[0].strip()


def main():
    wiki = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    if wiki is None or not wiki.is_dir():
        print("usage: lint_wiki.py <wiki-dir>", file=sys.stderr)
        return 2
    cat, errors, skipped, checked = catalog(), [], 0, 0
    for page in sorted(wiki.glob("*.md")):
        default = page_track(page)
        for n, line in enumerate(page.read_text().splitlines(), 1):
            for m in REF.finditer(line):
                word = (m.group("track") or "").lower()
                track = TRACK_WORDS.get(word) or default
                if track is None:
                    skipped += 1
                    continue
                ids = [f"L{m['a']}.{m['b']}"]
                if m.group("c"):
                    ids.append(f"L{m['a']}.{m['c']}")
                where = f"{page.name}:{n}"
                for lab in ids:
                    checked += 1
                    if lab not in cat.get(track, {}):
                        errors.append(f"{where}: {track} {lab} does not exist")
                        continue
                    desc = description(line, m.end())
                    if len(ids) == 1 and words(desc) and not overlap(desc, cat[track][lab]):
                        errors.append(
                            f"{where}: {track} {lab} is \"{cat[track][lab]}\" but the page says \"{desc[:60]}\"")
    for e in errors:
        print(e)
    print(f"lint-wiki: {checked} references checked, {skipped} skipped (no track context), "
          f"{len(errors)} problem(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
