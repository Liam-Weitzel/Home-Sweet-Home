#!/usr/bin/env python3
"""ytchat - stream a YouTube Live chat into your terminal.

Uses the same internal endpoint the YouTube live-chat page polls, so there is
no API key and no daily quota. Standard library only.

  ./ytchat @someChannel          # resolve the channel's current live stream
  ./ytchat dQw4w9WgXcQ           # video id
  ./ytchat 'https://youtu.be/…'  # any watch / live / youtu.be url
  ./ytchat @someChannel --json | jq .   # NDJSON for piping
"""

import argparse
import html as htmllib
import json
import os
import re
import shutil
import signal
import sys
import textwrap
import time
import urllib.error
import urllib.request

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36")
HEADERS = {
    "User-Agent": UA,
    "Accept-Language": "en-US,en;q=0.9",
    "Cookie": "CONSENT=YES+cb; PREF=hl=en",
}
CHAT_URL = "https://www.youtube.com/youtubei/v1/live_chat/get_live_chat"

# ---------------------------------------------------------------- colours ---

RESET = "\033[0m"
DIM = "\033[2m"
BOLD = "\033[1m"
# Readable on both light and dark terminals; author colour is picked by hash so
# a given person keeps the same colour for the whole session.
NAME_COLORS = [
    "\033[38;5;39m", "\033[38;5;42m", "\033[38;5;214m", "\033[38;5;170m",
    "\033[38;5;79m", "\033[38;5;209m", "\033[38;5;111m", "\033[38;5;150m",
    "\033[38;5;183m", "\033[38;5;180m", "\033[38;5;117m", "\033[38;5;204m",
]

BADGES = {           # iconType -> (symbol, colour)
    "OWNER": ("★", "\033[38;5;220m"),
    "MODERATOR": ("⚔", "\033[38;5;69m"),
    "VERIFIED": ("✓", "\033[38;5;245m"),
}

USE_COLOR = True


def c(text, *codes):
    if not USE_COLOR or not codes:
        return text
    return "".join(codes) + text + RESET


def author_color(name):
    return NAME_COLORS[sum(map(ord, name)) % len(NAME_COLORS)]


def argb_bg(value):
    """YouTube gives superchat colours as a packed ARGB int."""
    if not USE_COLOR or not value:
        return "", ""
    r, g, b = (value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF
    fg = "\033[38;2;0;0;0m" if (r * 299 + g * 587 + b * 114) / 1000 > 140 else "\033[38;2;255;255;255m"
    return f"\033[48;2;{r};{g};{b}m{fg}", RESET


# ------------------------------------------------------------------ http ---

def get(url, data=None, timeout=20):
    req = urllib.request.Request(url, data=data, headers=dict(HEADERS))
    if data is not None:
        req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.read().decode("utf-8", "replace")


def die(msg, code=1):
    print(c("error: ", BOLD, "\033[31m") + msg, file=sys.stderr)
    sys.exit(code)


# ------------------------------------------------------------ bootstrap ---

VIDEO_ID_RE = re.compile(r"^[A-Za-z0-9_-]{11}$")


def resolve_video_id(target):
    """Accept a video id, any YouTube URL, or an @handle / channel URL."""
    target = target.strip()
    if VIDEO_ID_RE.match(target):
        return target

    m = re.search(r"(?:v=|/live/|youtu\.be/|/embed/|/shorts/)([A-Za-z0-9_-]{11})", target)
    if m:
        return m.group(1)

    # Treat everything else as a channel and ask for its current live stream.
    if target.startswith("@"):
        url = f"https://www.youtube.com/{target}/live"
    elif target.startswith("http"):
        url = target.rstrip("/") + "/live"
    else:
        url = f"https://www.youtube.com/@{target}/live"

    try:
        page = get(url)
    except urllib.error.HTTPError as e:
        die(f"could not load {url} ({e.code}) - is the channel name right?")

    m = re.search(r'<link rel="canonical" href="https://www\.youtube\.com/watch\?v=([A-Za-z0-9_-]{11})"', page)
    if m:
        return m.group(1)
    m = re.search(r'"videoId":"([A-Za-z0-9_-]{11})"', page)
    if m:
        return m.group(1)
    die(f"no live stream found for {target} (are they live right now?)")


def extract_initial_data(page):
    m = re.search(r'ytInitialData["\']?\]?\s*=\s*', page)
    if not m:
        return None
    try:
        data, _ = json.JSONDecoder().raw_decode(page, m.end())
        return data
    except ValueError:
        return None


def find_continuation(cont_obj):
    for key in ("invalidationContinuationData", "timedContinuationData",
                "reloadContinuationData", "liveChatReplayContinuationData"):
        if key in cont_obj:
            node = cont_obj[key]
            return node.get("continuation"), node.get("timeoutMs")
    return None, None


def bootstrap(video_id, want_all=True):
    """Return (api_key, client_version, continuation_token)."""
    page = get(f"https://www.youtube.com/live_chat?is_popout=1&v={video_id}")

    key = re.search(r'"INNERTUBE_API_KEY":\s*"([^"]+)"', page)
    ver = re.search(r'"INNERTUBE_CLIENT_VERSION":\s*"([^"]+)"', page)
    data = extract_initial_data(page)
    if not (key and ver and data):
        die("couldn't parse the live-chat page (YouTube may have changed its markup)")

    renderer = data.get("contents", {}).get("liveChatRenderer")
    if not renderer:
        die(f"video {video_id} has no live chat - it may not be live, or chat is disabled")

    cont = None
    if want_all:
        # subMenuItems[0] = "Top chat" (filtered), [1] = "Live chat" (everything).
        try:
            items = (renderer["header"]["liveChatHeaderRenderer"]["viewSelector"]
                     ["sortFilterSubMenuRenderer"]["subMenuItems"])
            if len(items) > 1:
                cont, _ = find_continuation(items[1]["continuation"])
        except (KeyError, IndexError, TypeError):
            pass
    if not cont:
        for cobj in renderer.get("continuations", []):
            cont, _ = find_continuation(cobj)
            if cont:
                break
    if not cont:
        die("no chat continuation token in the page")

    return key.group(1), ver.group(1), cont


def fetch(api_key, client_version, continuation):
    body = json.dumps({
        "context": {"client": {"clientName": "WEB", "clientVersion": client_version}},
        "continuation": continuation,
    }).encode()
    raw = get(f"{CHAT_URL}?key={api_key}&prettyPrint=false", data=body, timeout=25)
    return json.loads(raw)


# -------------------------------------------------------------- parsing ---

def runs_to_text(runs):
    out = []
    for run in runs or []:
        if "text" in run:
            out.append(run["text"])
        elif "emoji" in run:
            emoji = run["emoji"]
            if emoji.get("isCustomEmoji"):
                shortcuts = emoji.get("shortcuts") or [":emoji:"]
                out.append(shortcuts[0])
            else:
                out.append(emoji.get("emojiId", ""))
    return htmllib.unescape("".join(out))


def parse_badges(renderer):
    out = []
    member = False
    for badge in renderer.get("authorBadges", []):
        b = badge.get("liveChatAuthorBadgeRenderer", {})
        icon = b.get("icon", {}).get("iconType")
        if icon in BADGES:
            out.append(icon)
        elif "customThumbnail" in b:
            member = True
    if member:
        out.append("MEMBER")
    return out


def parse_item(item):
    """Normalise one chat item into a plain dict, or None if we don't render it."""
    for kind, renderer in item.items():
        base = {
            "kind": kind,
            "id": renderer.get("id"),
            "timestamp_usec": renderer.get("timestampUsec"),
            "author": (renderer.get("authorName") or {}).get("simpleText", "(unknown)"),
            "badges": parse_badges(renderer),
            "amount": None,
            "bg": None,
            "type": "message",
        }
        if kind == "liveChatTextMessageRenderer":
            base["text"] = runs_to_text(renderer.get("message", {}).get("runs"))
        elif kind == "liveChatPaidMessageRenderer":
            base["type"] = "superchat"
            base["amount"] = (renderer.get("purchaseAmountText") or {}).get("simpleText")
            base["bg"] = renderer.get("bodyBackgroundColor")
            base["text"] = runs_to_text(renderer.get("message", {}).get("runs"))
        elif kind == "liveChatPaidStickerRenderer":
            base["type"] = "sticker"
            base["amount"] = (renderer.get("purchaseAmountText") or {}).get("simpleText")
            base["bg"] = renderer.get("backgroundColor")
            base["text"] = "[sticker]"
        elif kind == "liveChatMembershipItemRenderer":
            base["type"] = "member"
            head = runs_to_text(renderer.get("headerSubtext", {}).get("runs"))
            msg = runs_to_text(renderer.get("message", {}).get("runs"))
            base["text"] = " - ".join(x for x in (head, msg) if x)
        elif kind == "liveChatSponsorshipsGiftPurchaseAnnouncementRenderer":
            base["type"] = "member"
            hdr = (renderer.get("header", {}).get("liveChatSponsorshipsHeaderRenderer", {}))
            base["author"] = (hdr.get("authorName") or {}).get("simpleText", base["author"])
            base["badges"] = parse_badges(hdr)
            base["text"] = runs_to_text(hdr.get("primaryText", {}).get("runs"))
        elif kind == "liveChatSponsorshipsGiftRedemptionAnnouncementRenderer":
            base["type"] = "member"
            base["text"] = runs_to_text(renderer.get("message", {}).get("runs"))
        else:
            return None
        return base
    return None


def extract_actions(payload):
    cc = payload.get("continuationContents", {}).get("liveChatContinuation", {})
    items = []
    for action in cc.get("actions", []) or []:
        add = action.get("addChatItemAction")
        if not add:
            # Replays wrap actions one level deeper.
            rep = action.get("replayChatItemAction", {})
            for sub in rep.get("actions", []) or []:
                add = sub.get("addChatItemAction")
                if add:
                    parsed = parse_item(add.get("item", {}))
                    if parsed:
                        items.append(parsed)
            continue
        parsed = parse_item(add.get("item", {}))
        if parsed:
            items.append(parsed)

    cont, timeout_ms = None, None
    for cobj in cc.get("continuations", []) or []:
        cont, timeout_ms = find_continuation(cobj)
        if cont:
            break
    return items, cont, timeout_ms


# ------------------------------------------------------------- rendering ---

def term_width():
    return shutil.get_terminal_size((100, 24)).columns


def render(msg, show_time=True):
    parts = []
    plain = []

    if show_time:
        usec = msg.get("timestamp_usec")
        ts = time.strftime("%H:%M:%S", time.localtime(int(usec) / 1e6)) if usec else time.strftime("%H:%M:%S")
        parts.append(c(ts, DIM))
        plain.append(ts)
        parts.append(" ")
        plain.append(" ")

    for badge in msg["badges"]:
        if badge == "MEMBER":
            sym, col = "♦", "\033[38;5;77m"
        else:
            sym, col = BADGES[badge]
        parts.append(c(sym, col))
        plain.append(sym)
    if msg["badges"]:
        parts.append(" ")
        plain.append(" ")

    name = msg["author"]
    parts.append(c(name, BOLD, author_color(name)))
    plain.append(name)
    parts.append(c(": ", DIM))
    plain.append(": ")

    prefix = "".join(parts)
    indent = " " * min(len(("".join(plain))), 28)

    text = msg.get("text") or ""
    if msg["type"] == "superchat" or msg["type"] == "sticker":
        on, off = argb_bg(msg.get("bg"))
        amount = msg.get("amount") or ""
        text = f"{on} {amount} {off} {text}".strip()
    elif msg["type"] == "member":
        text = c(text, "\033[38;5;77m")

    width = max(term_width(), 40)
    body_width = max(width - len(indent), 20)
    wrapped = textwrap.wrap(text, body_width) or [""]
    lines = [prefix + wrapped[0]]
    lines += [indent + line for line in wrapped[1:]]
    return "\n".join(lines)


# ------------------------------------------------------------------ main ---

def main():
    global USE_COLOR

    ap = argparse.ArgumentParser(
        prog="ytchat",
        description="Stream a YouTube Live chat into your terminal.")
    ap.add_argument("target", help="video id, YouTube URL, or @channel handle")
    ap.add_argument("--json", action="store_true",
                    help="emit one JSON object per message (NDJSON) instead of pretty output")
    ap.add_argument("--no-color", action="store_true", help="disable ANSI colour")
    ap.add_argument("--no-time", action="store_true", help="hide timestamps")
    ap.add_argument("--top-chat", action="store_true",
                    help="use YouTube's filtered 'Top chat' instead of every message")
    ap.add_argument("--interval", type=float, default=1.0, metavar="SEC",
                    help="poll interval in seconds (default 1.0). YouTube asks clients to wait "
                         "10s; we cap that. Below ~1s gains nothing - YouTube holds messages "
                         "server-side for ~2s regardless.")
    args = ap.parse_args()

    USE_COLOR = not args.no_color and not args.json and sys.stdout.isatty() \
        and os.environ.get("NO_COLOR") is None

    signal.signal(signal.SIGINT, lambda *_: sys.exit(0))
    try:
        signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    except AttributeError:
        pass

    video_id = resolve_video_id(args.target)
    if not args.json:
        print(c(f"connecting to live chat for {video_id} …", DIM), file=sys.stderr)

    api_key, client_version, continuation = bootstrap(video_id, want_all=not args.top_chat)
    if not args.json:
        print(c("connected. ctrl-c to quit.\n", DIM), file=sys.stderr)

    seen = set()
    seen_order = []
    backoff = 1.0

    while True:
        try:
            payload = fetch(api_key, client_version, continuation)
            backoff = 1.0
        except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, OSError, ValueError) as e:
            if not args.json:
                print(c(f"[reconnecting: {e}]", DIM), file=sys.stderr)
            time.sleep(backoff)
            backoff = min(backoff * 2, 30)
            if backoff > 8:  # continuation probably went stale - rebuild it
                try:
                    api_key, client_version, continuation = bootstrap(
                        video_id, want_all=not args.top_chat)
                except SystemExit:
                    raise
                except Exception:
                    pass
            continue

        messages, next_cont, timeout_ms = extract_actions(payload)

        for msg in messages:
            mid = msg.get("id")
            if mid:
                if mid in seen:
                    continue
                seen.add(mid)
                seen_order.append(mid)
                if len(seen_order) > 5000:
                    seen.discard(seen_order.pop(0))
            if args.json:
                print(json.dumps(msg, ensure_ascii=False), flush=True)
            else:
                print(render(msg, show_time=not args.no_time), flush=True)

        if not next_cont:
            if not args.json:
                print(c("\n[stream ended or chat closed]", DIM), file=sys.stderr)
            return
        continuation = next_cont

        # YouTube's suggested timeoutMs is typically 10000, which makes chat feel
        # badly delayed. Treat it as a ceiling, not an instruction.
        wait = args.interval
        if timeout_ms:
            wait = min(wait, timeout_ms / 1000.0)
        time.sleep(max(wait, 0.05))


if __name__ == "__main__":
    main()
