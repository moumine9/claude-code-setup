#!/usr/bin/env bash
# Reports Claude Code usage statistics from the three places that record it.
#
#   plugin-usage.sh [--days N] [--top N] [--no-skills]
#
# Each source answers a different question, and none of them answers all three:
#   ~/.claude.json           -> pluginUsage counters (authoritative, per plugin)
#   ~/.claude/history.jsonl  -> prompts you typed (catches user-invoked commands)
#   projects/**/*.jsonl      -> Skill tool calls (catches model-invoked skills)
#
# Counting a skill's *name* in transcripts does not work: every session lists all
# available skills in its system prompt, so every skill scores identically. The
# transcript pass below counts "skill":"<name>" tool invocations for that reason.

set -euo pipefail

DAYS=30
TOP=25
SCAN_SKILLS=1

while [ $# -gt 0 ]; do
  case "$1" in
    --days) [ $# -ge 2 ] || { echo "--days needs a value" >&2; exit 1; }
            DAYS="$2"; shift 2 ;;
    --top)  [ $# -ge 2 ] || { echo "--top needs a value" >&2; exit 1; }
            TOP="$2"; shift 2 ;;
    --no-skills) SCAN_SKILLS=0; shift ;;
    -h|--help) sed -n '2,14p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

for n in "$DAYS" "$TOP"; do
  case "$n" in (*[!0-9]*|"") echo "--days/--top expect a positive integer, got: $n" >&2; exit 1 ;; esac
done

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CONFIG_JSON="$HOME/.claude.json"

export PU_DAYS="$DAYS" PU_TOP="$TOP" PU_DIR="$CLAUDE_DIR" PU_CONFIG="$CONFIG_JSON"
export PU_SKIP_SKILLS=$( [ "$SCAN_SKILLS" = "0" ] && echo 1 || echo 0 )

python - <<'PY'
import json, os, re, glob, datetime, collections, sys

days   = int(os.environ["PU_DAYS"])
top    = int(os.environ["PU_TOP"])
cdir   = os.environ["PU_DIR"]
config = os.environ["PU_CONFIG"]

def rule(title):
    print("\n" + title)
    print("=" * max(58, len(title)))

def load(path):
    try:
        with open(path, encoding="utf-8", errors="ignore") as fh:
            return json.load(fh)
    except Exception as exc:
        print(f"  (could not read {path}: {exc})")
        return None

# ── 1. Plugin activations ─────────────────────────────────────────────────────
rule("PLUGIN USAGE  -  ~/.claude.json : pluginUsage")
cfg = load(config) or {}
pu = cfg.get("pluginUsage", {})
if not pu:
    print("  (no pluginUsage recorded)")
else:
    startups = cfg.get("numStartups")
    rows = []
    for name, v in pu.items():
        ts = v.get("lastUsedAt", 0)
        rows.append((
            v.get("usageCount", 0),
            name,
            datetime.datetime.fromtimestamp(ts / 1000).strftime("%Y-%m-%d") if ts else "-",
            v.get("lastUsedNumStartups", "-"),
        ))
    rows.sort(reverse=True)
    print(f"  {'uses':>6}  {'last used':<12} {'session':>8}  plugin")
    print("  " + "-" * 56)
    for c, name, dt, ns in rows:
        flag = "  <- unused" if c == 0 else ""
        print(f"  {c:6}  {dt:<12} {ns:>8}  {name}{flag}")
    if startups:
        print(f"\n  current session count: {startups}")
    print("\n  Note: counters are per plugin, not per skill, and do not carry across")
    print("  a rename - a repackaged plugin starts a fresh count under its new name.")

# ── 2. Slash commands you typed ───────────────────────────────────────────────
rule(f"COMMANDS YOU TYPED  -  history.jsonl (last {days} days)")
cutoff = (datetime.datetime.now() - datetime.timedelta(days=days)).timestamp() * 1000
counts, total, oldest = collections.Counter(), 0, None
hist = os.path.join(cdir, "history.jsonl")
try:
    with open(hist, encoding="utf-8", errors="ignore") as fh:
        for line in fh:
            try:
                e = json.loads(line)
            except Exception:
                continue
            ts = e.get("timestamp", 0)
            oldest = ts if oldest is None else min(oldest, ts)
            if ts < cutoff:
                continue
            total += 1
            m = re.match(r"/([a-zA-Z0-9:_-]+)", e.get("display", "") or "")
            if m:
                counts[m.group(1)] += 1
except FileNotFoundError:
    print(f"  (no history at {hist})")

if counts:
    for name, c in counts.most_common(top):
        print(f"  {c:6}  /{name}")
    print(f"\n  {sum(counts.values())} command invocations out of {total} prompts")
    if oldest:
        span = datetime.datetime.fromtimestamp(oldest / 1000).strftime("%Y-%m-%d")
        print(f"  (history goes back to {span}; use --days to widen this window)")
elif total:
    print(f"  (no slash commands in the last {days} days, out of {total} prompts)")

# ── 3. Skills the model invoked ───────────────────────────────────────────────
if os.environ.get("PU_SKIP_SKILLS") != "1":
    rule("SKILLS THE MODEL INVOKED  -  Skill tool calls in transcripts")
    pat = re.compile(r'"skill":"([a-zA-Z0-9:_-]+)"')
    skills = collections.Counter()
    files = glob.glob(os.path.join(cdir, "projects", "**", "*.jsonl"), recursive=True)
    for path in files:
        try:
            with open(path, encoding="utf-8", errors="ignore") as fh:
                for line in fh:
                    if '"skill"' in line:
                        skills.update(pat.findall(line))
        except Exception:
            continue
    if skills:
        for name, c in skills.most_common(top):
            print(f"  {c:6}  {name}")
    else:
        print("  (no Skill invocations found)")
    print(f"\n  scanned {len(files)} transcript file(s)")
    print("  Counts real invocations. Do NOT count skill *names* in transcripts -")
    print("  every session's prompt lists them all, so each would score the same.")

# ── 4. Activity trend ─────────────────────────────────────────────────────────
rule("ACTIVITY  -  stats-cache.json")
stats = load(os.path.join(cdir, "stats-cache.json"))
if stats:
    daily = stats.get("dailyActivity", [])
    recent = daily[-14:]
    if recent:
        peak = max(d.get("messageCount", 0) for d in recent) or 1
        for d in recent:
            msgs = d.get("messageCount", 0)
            bar = "#" * max(1, int(msgs / peak * 32)) if msgs else ""
            print(f"  {d.get('date','?')}  {msgs:5} msgs  {d.get('sessionCount',0):3} sess  {bar}")
        tm = sum(d.get("messageCount", 0) for d in daily)
        ts_ = sum(d.get("sessionCount", 0) for d in daily)
        print(f"\n  all time: {tm} messages across {ts_} sessions, {len(daily)} active days")
        print(f"  last computed: {stats.get('lastComputedDate','?')}")
print()
PY
