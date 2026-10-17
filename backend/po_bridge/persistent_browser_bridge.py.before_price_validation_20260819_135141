import asyncio
import base64
import json
import re
import time
from pathlib import Path
from typing import Any, Optional

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from playwright.async_api import async_playwright


PROJECT_ROOT = Path(__file__).resolve().parents[2]

PROFILE_DIR = (
    PROJECT_ROOT
    / ".private"
    / "pocket_option_browser_profile"
)

PROFILE_DIR.mkdir(
    parents=True,
    exist_ok=True,
)

PO_URL = "https://m.pocketoption.com/en/login/"

app = FastAPI(
    title="999 Signal Intelligent Pro - Pocket Option Browser Bridge"
)


class State:
    def __init__(self):
        self.playwright = None
        self.context = None
        self.page = None

        self.browser_ready = False
        self.clients = set()

        self.latest_prices = {}
        self.symbol_activity = {}
        self.symbol_last_seen = {}

        self.frames_seen = 0
        self.prices_seen = 0

        self.last_frame_time = None
        self.last_price_time = None

        self.last_emitted = {}


state = State()


# ------------------------------------------------------------
# NORMALIZATION
# ------------------------------------------------------------

def normalize_symbol(value: Any) -> Optional[str]:
    if value is None:
        return None

    raw = str(value).upper().strip()

    # Detect OTC BEFORE cleaning the symbol.
    is_otc = "OTC" in raw

    cleaned = raw
    cleaned = cleaned.replace("/", "")
    cleaned = cleaned.replace("-", "")
    cleaned = cleaned.replace(" ", "")
    cleaned = cleaned.replace("_OTC", "")
    cleaned = cleaned.replace("OTC_", "")
    cleaned = cleaned.replace("OTC", "")

    match = re.search(r"([A-Z]{6})", cleaned)

    if not match:
        return None

    symbol = match.group(1)

    if is_otc:
        symbol = f"{symbol}_OTC"

    return symbol


def as_price(value: Any) -> Optional[float]:
    if isinstance(value, bool):
        return None

    try:
        number = float(value)

        if number <= 0:
            return None

        # Avoid treating obvious timestamps/IDs as prices.
        if number > 10_000_000:
            return None

        return number

    except Exception:
        return None


async def broadcast(payload: dict):
    if not state.clients:
        return

    text = json.dumps(
        payload,
        default=str,
    )

    dead = []

    for client in list(state.clients):
        try:
            await client.send_text(text)
        except Exception:
            dead.append(client)

    for client in dead:
        state.clients.discard(client)


async def emit_price(
    symbol: str,
    price: float,
    timestamp: Any = None,
):
    now = time.time()

    symbol = normalize_symbol(symbol)

    if not symbol:
        return

    price = as_price(price)

    if price is None:
        return

    # Prevent identical duplicate packets flooding the scanner.
    previous = state.last_emitted.get(symbol)

    if previous:
        previous_price, previous_time = previous

        if (
            previous_price == price
            and now - previous_time < 0.10
        ):
            return

    state.last_emitted[symbol] = (
        price,
        now,
    )

    state.latest_prices[symbol] = price
    state.prices_seen += 1
    state.last_price_time = now

    state.symbol_activity[symbol] = (
        state.symbol_activity.get(symbol, 0) + 1
    )

    state.symbol_last_seen[symbol] = now

    payload = {
        "event": "price",
        "source": "pocket_option_browser",
        "symbol": symbol,
        "price": price,
        "timestamp": timestamp or now,
    }

    print(
        "PO PRICE:",
        symbol,
        price,
        flush=True,
    )

    await broadcast(payload)


# ------------------------------------------------------------
# GENERIC POCKET OPTION PACKET PARSER
# ------------------------------------------------------------

async def walk(
    obj: Any,
    inherited_symbol: Optional[str] = None,
):
    if isinstance(obj, dict):

        symbol = (
            normalize_symbol(obj.get("asset"))
            or normalize_symbol(obj.get("symbol"))
            or normalize_symbol(obj.get("pair"))
            or normalize_symbol(obj.get("instrument"))
            or normalize_symbol(obj.get("ticker"))
            or inherited_symbol
        )

        price = None

        for key in (
            "price",
            "value",
            "close",
            "last",
            "lastPrice",
            "rate",
            "quote",
        ):
            if key in obj:
                price = as_price(obj.get(key))

                if price is not None:
                    break

        timestamp = (
            obj.get("timestamp")
            or obj.get("time")
            or obj.get("ts")
        )

        if symbol and price is not None:
            await emit_price(
                symbol,
                price,
                timestamp,
            )

        for value in obj.values():
            await walk(
                value,
                symbol,
            )

        return

    if isinstance(obj, list):

        # Common stream shapes sometimes look roughly like:
        # [symbol, timestamp, price]
        # [symbol, price]
        if len(obj) >= 2:

            possible_symbol = normalize_symbol(obj[0])

            if possible_symbol:

                # Prefer last numeric item as potential price.
                for item in reversed(obj[1:]):
                    possible_price = as_price(item)

                    if possible_price is not None:
                        await emit_price(
                            possible_symbol,
                            possible_price,
                        )
                        break

        for value in obj:
            await walk(
                value,
                inherited_symbol,
            )


def json_candidates(text: str):
    candidates = [text]

    stripped = text.strip()

    # Socket.IO event:
    # 42["event",{...}]
    if stripped.startswith("42"):
        candidates.append(
            stripped[2:]
        )

    # Socket.IO namespace packet variants.
    match = re.search(
        r"(\[.*\]|\{.*\})",
        stripped,
        re.S,
    )

    if match:
        candidates.append(
            match.group(1)
        )

    return candidates


async def process_frame(frame: Any, ws_url: str):
    state.frames_seen += 1
    state.last_frame_time = time.time()

    if isinstance(frame, bytes):
        try:
            text = frame.decode(
                "utf-8",
                errors="ignore",
            )
        except Exception:
            text = ""

        if not text:
            await broadcast({
                "event": "po_binary",
                "source": "pocket_option_browser",
                "url": ws_url,
                "data": base64.b64encode(frame).decode(),
                "timestamp": time.time(),
            })

            return

    else:
        text = str(frame)

    # Forward a limited raw diagnostic copy.
    await broadcast({
        "event": "po_raw",
        "source": "pocket_option_browser",
        "url": ws_url,
        "data": text[:12000],
        "timestamp": time.time(),
    })

    for candidate in json_candidates(text):

        try:
            decoded = json.loads(candidate)

        except Exception:
            continue

        # Socket.IO form:
        # ["event", payload]
        if (
            isinstance(decoded, list)
            and len(decoded) >= 2
            and isinstance(decoded[0], str)
        ):
            await walk(
                decoded[1]
            )

        else:
            await walk(
                decoded
            )


# ------------------------------------------------------------
# BROWSER WEBSOCKET CAPTURE
# ------------------------------------------------------------

async def attach_page(page):
    state.page = page
    state.browser_ready = True

    print(
        "PO PAGE:",
        page.url,
        flush=True,
    )

    def page_websocket(ws):

        print(
            "PO WEBSOCKET:",
            ws.url,
            flush=True,
        )

        asyncio.create_task(
            broadcast({
                "event": "source_status",
                "source": "pocket_option",
                "status": "browser_websocket_connected",
                "url": ws.url,
            })
        )

        def received(frame):
            asyncio.create_task(
                process_frame(
                    frame,
                    ws.url,
                )
            )

        ws.on(
            "framereceived",
            received,
        )

    page.on(
        "websocket",
        page_websocket,
    )


async def start_browser():
    if state.context is not None:
        return

    print()
    print("999 PRO POCKET OPTION BRIDGE STARTING")
    print("Opening persistent Pocket Option browser...")
    print()

    state.playwright = await async_playwright().start()

    state.context = (
        await state.playwright.chromium.launch_persistent_context(
            user_data_dir=str(PROFILE_DIR),
            headless=False,
            viewport=None,
            args=[
                "--start-maximized",
            ],
        )
    )

    pages = state.context.pages

    if pages:
        page = pages[0]
    else:
        page = await state.context.new_page()

    for existing_page in state.context.pages:
        await attach_page(existing_page)

    state.context.on(
        "page",
        lambda new_page: asyncio.create_task(
            attach_page(new_page)
        ),
    )

    await page.goto(
        PO_URL,
        wait_until="domcontentloaded",
        timeout=60000,
    )

    print()
    print("POCKET OPTION BROWSER READY")
    print("Log in normally if needed.")
    print("Leave this browser open.")
    print()


# ------------------------------------------------------------
# FASTAPI
# ------------------------------------------------------------

@app.on_event("startup")
async def startup():
    asyncio.create_task(
        start_browser()
    )


@app.get("/")
async def root():
    return {
        "status": "999 Pro Pocket Option bridge online",
        "browser_ready": state.browser_ready,
        "frames_seen": state.frames_seen,
        "prices_seen": state.prices_seen,
        "symbols": sorted(
            state.latest_prices.keys()
        ),
    }


@app.get("/health")
async def health():
    now = time.time()

    frame_age = None

    if state.last_frame_time:
        frame_age = round(
            now - state.last_frame_time,
            2,
        )

    price_age = None

    if state.last_price_time:
        price_age = round(
            now - state.last_price_time,
            2,
        )

    return {
        "status": "ok",
        "browser_ready": state.browser_ready,
        "scanner_clients": len(state.clients),
        "frames_seen": state.frames_seen,
        "prices_seen": state.prices_seen,
        "last_frame_age_seconds": frame_age,
        "last_price_age_seconds": price_age,
        "latest_prices": state.latest_prices,
    }



def classify_symbol(symbol: str) -> str:
    value = symbol.upper()

    if value.endswith("_OTC"):
        return "OTC"

    crypto_tokens = (
        "BTC", "ETH", "LTC", "XRP", "DOGE", "SOL",
        "ADA", "BNB", "DOT", "TRX", "TON",
    )

    if any(token in value for token in crypto_tokens):
        return "CRYPTO"

    fiat = {
        "USD", "EUR", "GBP", "JPY", "CHF",
        "CAD", "AUD", "NZD",
    }

    if len(value) == 6:
        left = value[:3]
        right = value[3:]

        if left in fiat and right in fiat:
            return "FOREX"

    return "OTHER"


def asset_rows():
    now = time.time()
    rows = []

    for symbol, price in state.latest_prices.items():
        last_seen = state.symbol_last_seen.get(symbol, 0.0)
        activity = state.symbol_activity.get(symbol, 0)

        age = (
            round(now - last_seen, 3)
            if last_seen
            else None
        )

        rows.append({
            "symbol": symbol,
            "price": price,
            "category": classify_symbol(symbol),
            "activity": activity,
            "last_seen": last_seen,
            "age_seconds": age,
            "live": bool(
                last_seen and (now - last_seen) <= 5.0
            ),
        })

    return rows


@app.get("/symbols")
async def symbols():
    rows = asset_rows()

    rows.sort(
        key=lambda x: x["symbol"]
    )

    return {
        "source": "pocket_option_browser",
        "count": len(rows),
        "symbols": rows,
    }


@app.get("/top40")
async def top40():
    rows = asset_rows()

    # Live instruments first, then activity.
    rows.sort(
        key=lambda x: (
            1 if x["live"] else 0,
            x["activity"],
            x["last_seen"],
        ),
        reverse=True,
    )

    return {
        "source": "pocket_option_browser",
        "count": min(40, len(rows)),
        "symbols": rows[:40],
    }


@app.get("/category/{category}")
async def category(category: str):
    wanted = category.upper()

    rows = [
        row
        for row in asset_rows()
        if row["category"] == wanted
    ]

    rows.sort(
        key=lambda x: (
            x["activity"],
            x["last_seen"],
        ),
        reverse=True,
    )

    return {
        "source": "pocket_option_browser",
        "category": wanted,
        "count": len(rows),
        "symbols": rows,
    }


@app.get("/prices")
async def prices():
    return {
        "source": "pocket_option_browser",
        "prices": state.latest_prices,
    }


@app.websocket("/ws/po")
async def pocket_option_websocket(
    websocket: WebSocket,
):
    await websocket.accept()

    state.clients.add(
        websocket
    )

    print(
        "PRO SCANNER CONNECTED TO PO BRIDGE",
        flush=True,
    )

    await websocket.send_text(
        json.dumps({
            "event": "source_status",
            "source": "pocket_option",
            "status": (
                "browser_connected"
                if state.browser_ready
                else "browser_starting"
            ),
        })
    )

    # Send latest known prices immediately.
    for symbol, price in state.latest_prices.items():

        await websocket.send_text(
            json.dumps({
                "event": "price",
                "source": "pocket_option_browser",
                "symbol": symbol,
                "price": price,
                "timestamp": time.time(),
            })
        )

    try:
        while True:
            # This keeps the socket alive.
            await websocket.receive_text()

    except WebSocketDisconnect:
        pass

    except Exception:
        pass

    finally:
        state.clients.discard(
            websocket
        )

        print(
            "PRO SCANNER DISCONNECTED FROM PO BRIDGE",
            flush=True,
        )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        app,
        host="127.0.0.1",
        port=8000,
        log_level="info",
    )
