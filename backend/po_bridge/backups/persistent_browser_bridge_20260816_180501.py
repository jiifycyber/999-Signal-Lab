import asyncio
import json
import time
from pathlib import Path

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from playwright.async_api import async_playwright

PROJECT_ROOT = Path(__file__).resolve().parents[2]
PROFILE_DIR = PROJECT_ROOT / ".private" / "pocket_option_browser_profile"
PROFILE_DIR.mkdir(parents=True, exist_ok=True)

PO_URL = "https://pocketoption.com/"

app = FastAPI(title="999 Pro Pocket Option Browser Bridge")

clients = set()
latest_prices = {}
browser_context = None
browser_page = None


async def broadcast(payload):
    if not clients:
        return

    text = json.dumps(payload, default=str)
    dead = []

    for ws in list(clients):
        try:
            await ws.send_text(text)
        except Exception:
            dead.append(ws)

    for ws in dead:
        clients.discard(ws)


async def process_frame(frame):
    text = str(frame)

    await broadcast({
        "event": "po_raw",
        "source": "pocket_option_browser",
        "data": text[:10000],
        "timestamp": time.time(),
    })


async def attach_page(page):
    global browser_page
    browser_page = page

    print("PO PAGE:", page.url, flush=True)

    async def on_websocket(ws):
        print("PO WEBSOCKET:", ws.url, flush=True)

        await broadcast({
            "event": "source_status",
            "source": "pocket_option",
            "status": "browser_websocket_connected",
            "url": ws.url,
        })

        ws.on(
            "framereceived",
            lambda frame: asyncio.create_task(process_frame(frame)),
        )

    page.on(
        "websocket",
        lambda ws: asyncio.create_task(on_websocket(ws)),
    )


async def start_browser():
    global browser_context

    playwright = await async_playwright().start()

    browser_context = await playwright.chromium.launch_persistent_context(
        user_data_dir=str(PROFILE_DIR),
        headless=False,
        viewport=None,
        args=["--start-maximized"],
    )

    if browser_context.pages:
        page = browser_context.pages[0]
    else:
        page = await browser_context.new_page()

    for existing in browser_context.pages:
        await attach_page(existing)

    browser_context.on(
        "page",
        lambda p: asyncio.create_task(attach_page(p)),
    )

    await page.goto(
        PO_URL,
        wait_until="domcontentloaded",
        timeout=60000,
    )

    print()
    print("Pocket Option browser opened.")
    print("Log in normally and leave this browser open.")
    print()


@app.on_event("startup")
async def startup():
    asyncio.create_task(start_browser())


@app.get("/health")
async def health():
    return {
        "status": "ok",
        "browser_open": browser_page is not None,
        "clients": len(clients),
        "latest_prices": latest_prices,
    }


@app.websocket("/ws/po")
async def po_socket(websocket: WebSocket):
    await websocket.accept()
    clients.add(websocket)

    await websocket.send_text(json.dumps({
        "event": "source_status",
        "source": "pocket_option",
        "status": "browser_connected",
    }))

    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        pass
    finally:
        clients.discard(websocket)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        app,
        host="127.0.0.1",
        port=8000,
        log_level="info",
    )
