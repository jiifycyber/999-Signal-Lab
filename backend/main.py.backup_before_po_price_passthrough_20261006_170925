import os
import httpx
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="999 Signal Intelligence API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["GET"],
    allow_headers=["*"],
)

API_KEY = os.getenv("TWELVE_DATA_API_KEY", "")

@app.get("/")
def root():
    return {"status": "online", "service": "999 Signal Intelligence"}

@app.get("/quote/{symbol}")
async def quote(symbol: str):
    if not API_KEY:
        raise HTTPException(status_code=500, detail="TWELVE_DATA_API_KEY missing")

    pair = symbol.replace("-", "/").upper()

    async with httpx.AsyncClient(timeout=10) as client:
        response = await client.get(
            "https://api.twelvedata.com/price",
            params={"symbol": pair, "apikey": API_KEY},
        )

    data = response.json()

    if "price" not in data:
        raise HTTPException(status_code=502, detail=data)

    return {
        "symbol": pair,
        "price": float(data["price"]),
        "source": "Twelve Data",
    }


# ===== TWELVE DATA LIVE WEBSOCKET BRIDGE =====
import json
import websockets
from fastapi import WebSocket, WebSocketDisconnect

@app.websocket("/ws")
async def twelve_data_websocket_bridge(websocket: WebSocket):
    await websocket.accept()

    if not API_KEY:
        await websocket.send_json({
            "event": "error",
            "message": "TWELVE_DATA_API_KEY missing"
        })
        await websocket.close()
        return

    symbols = websocket.query_params.get("symbols", "EUR/USD")

    upstream_url = (
        "wss://ws.twelvedata.com/v1/quotes/price"
        f"?apikey={API_KEY}"
    )

    try:
        async with websockets.connect(upstream_url) as upstream:
            await upstream.send(json.dumps({
                "action": "subscribe",
                "params": {
                    "symbols": symbols
                }
            }))

            async for message in upstream:
                await websocket.send_text(message)

    except WebSocketDisconnect:
        pass

    except Exception as exc:
        try:
            await websocket.send_json({
                "event": "error",
                "message": str(exc)
            })
        except Exception:
            pass


# ===== POCKET OPTION PRIMARY BRIDGE =====
from po_bridge.pocket_option_bridge import PocketOptionBridge

@app.websocket("/ws/po")
async def pocket_option_websocket(websocket: WebSocket):
    await websocket.accept()
    bridge = PocketOptionBridge()

    try:
        await bridge.connect()

        await websocket.send_json({
            "event": "source_status",
            "source": "pocket_option",
            "status": "authenticated"
        })

        async for message in bridge.messages():
            # TEMPORARY PASS-THROUGH:
            # We will replace this with normalized price ticks once
            # the exact Pocket Option live-price event is identified.
            await websocket.send_json({
                "event": "po_raw",
                "source": "pocket_option",
                "data": message
            })

    except WebSocketDisconnect:
        pass
    except Exception as exc:
        try:
            await websocket.send_json({
                "event": "error",
                "source": "pocket_option",
                "message": str(exc)
            })
        except Exception:
            pass
    finally:
        await bridge.close()
