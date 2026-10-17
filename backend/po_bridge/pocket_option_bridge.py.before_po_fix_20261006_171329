import os
import json
import asyncio

from pocket_option import PocketOptionClient
from pocket_option.models import (
    Asset,
    AuthorizationData,
    UpdateCloseValueItem,
)

PO_URL = os.getenv("PO_URL", "https://events-po.com").strip()
PO_AUTH_MESSAGE = os.getenv("PO_AUTH_MESSAGE", "").strip()

DEFAULT_SYMBOLS = [
    "EURUSD",
    "GBPUSD",
    "USDJPY",
    "USDCHF",
    "USDCAD",
    "AUDUSD",
    "NZDUSD",
    "AUDJPY",
]


def parse_auth_message(raw: str) -> AuthorizationData:
    if not raw:
        raise RuntimeError("PO_AUTH_MESSAGE is missing")

    raw = raw.strip()

    if raw.startswith("42"):
        raw = raw[2:]

    try:
        decoded = json.loads(raw)
    except json.JSONDecodeError:
        import re

        # Accept Chrome/JavaScript-style Socket.IO auth objects:
        # {sessionToken:"...", uid:"...", lang:"en"}
        raw = re.sub(
            r'([,{]\s*)([A-Za-z_][A-Za-z0-9_]*)(\s*:)',
            r'\1"\2"\3',
            raw,
        )

        decoded = json.loads(raw)

    if not isinstance(decoded, list) or len(decoded) < 2:
        raise RuntimeError("Invalid Pocket Option auth message")

    if decoded[0] != "auth":
        raise RuntimeError("Pocket Option message is not an auth event")

    payload = decoded[1]

    session = payload.get("session") or payload.get("sessionToken")
    if not session:
        raise RuntimeError("Pocket Option session/sessionToken missing")

    return AuthorizationData.model_validate({
        "session": session,
        "isDemo": payload.get("isDemo", 0),
        "uid": int(re.search(r"\d+", str(payload["uid"])).group()),
        "platform": int(payload.get("platform", 1)),
        "isFastHistory": bool(payload.get("isFastHistory", True)),
        "isOptimized": bool(payload.get("isOptimized", True)),
    })


class PocketOptionBridge:
    def __init__(self):
        self.client = PocketOptionClient(logger=False)
        self.queue = asyncio.Queue()
        self.authenticated = False
        self.auth_event = asyncio.Event()
        self.closed = False

        self.authorization = parse_auth_message(PO_AUTH_MESSAGE)

        configured = os.getenv("PO_SYMBOLS", "").strip()

        if configured:
            names = [
                x.strip().replace("/", "")
                for x in configured.split(",")
                if x.strip()
            ]
        else:
            names = DEFAULT_SYMBOLS

        self.assets = []

        for name in names:
            try:
                self.assets.append(Asset[name])
            except Exception:
                pass

        self._install_handlers()

    def _install_handlers(self):
        client = self.client
        bridge = self

        @client.on.connect
        async def on_connect():
            await bridge.queue.put(json.dumps({
                "event": "po_status",
                "status": "socket_connected",
                "source": "pocket_option",
            }))

            # Pocket Option browser-current auth format.
            # Bypass the SDK AuthorizationData serializer because it sends
            # "session" while the live browser protocol uses "sessionToken".
            await client.sio.emit(
                "auth",
                data={
                    "sessionToken": bridge.authorization.session,
                    "uid": str(bridge.authorization.uid),
                    "lang": "en",
                    "currentUrl": "cabinet",
                },
            )

        async def complete_auth(data=None):
            if bridge.authenticated:
                return

            bridge.authenticated = True
            bridge.auth_event.set()

            await bridge.queue.put(json.dumps({
                "event": "po_status",
                "status": "authenticated",
                "source": "pocket_option",
            }))

            # PASS_PO_CHANGE_SYMBOL
            # Set one active Pocket Option chart symbol/timeframe first.
            try:
                from pocket_option.models import ChangeAssetRequest

                active_asset = bridge.assets[0]

                print("PO ACTIVATING SYMBOL:", active_asset, "PERIOD: 60")

                await client.emit.change_asset(
                    ChangeAssetRequest(
                        asset=active_asset,
                        period=60,
                    )
                )

                print("PO ACTIVE SYMBOL SET:", active_asset)

            except Exception as e:
                print("PO CHANGE SYMBOL ERROR:", repr(e), flush=True)

            for asset in bridge.assets:
                try:
                    print("PO SUBSCRIBING:", asset)
                    await client.emit.subscribe_to_asset(asset)
                    print("PO SUBSCRIBED:", asset)

                    await bridge.queue.put(json.dumps({
                        "event": "po_subscription",
                        "status": "subscribed",
                        "asset": str(asset),
                    }))

                except Exception as e:
                    print("PO SUBSCRIPTION ERROR:", asset, repr(e))

                    await bridge.queue.put(json.dumps({
                        "event": "po_subscription",
                        "status": "error",
                        "asset": str(asset),
                        "error": repr(e),
                    }))

        # Older SDK success event
        @client.on.success_auth
        async def on_success_auth(data):
            await complete_auth(data)

        # Current Pocket Option browser success event
        client.sio.on(
            "auth/success",
            handler=complete_auth,
        )

        # PASS_PO_UPDATESTREAM_OVERRIDE
        # Direct current Pocket Option live-price listener.
        async def on_update_stream(data):
            try:
                items = data if isinstance(data, list) else [data]

                for item in items:
                    if not isinstance(item, dict):
                        continue

                    asset = item.get("asset")
                    symbol = getattr(asset, "value", asset)

                    price = item.get("value")
                    if price is None:
                        price = item.get("price")

                    timestamp = item.get("timestamp")

                    if price is None:
                        continue

                    payload = {
                        "event": "price",
                        "source": "pocket_option",
                        "symbol": str(symbol),
                        "price": float(price),
                        "timestamp": timestamp,
                    }

                    print(
                        "PO LIVE PRICE:",
                        payload["symbol"],
                        payload["price"],
                        flush=True,
                    )

                    await bridge.queue.put(
                        json.dumps(payload)
                    )

            except Exception as e:
                print(
                    "PO UPDATESTREAM ERROR:",
                    repr(e),
                    flush=True,
                )

        client.sio.on(
            "updateStream",
            handler=on_update_stream,
        )

        # PASS_PO_CATCH_ALL_EVENTS
        # Diagnostic listener: reveal the actual current Pocket Option
        # event names coming through the authenticated socket.
        async def po_catch_all(event, data):
            try:
                if event not in {
                    "connect",
                    "disconnect",
                    "auth/success",
                }:
                    text = repr(data)
                    if len(text) > 500:
                        text = text[:500] + "..."
                    print(
                        "PO RAW EVENT:",
                        event,
                        text,
                        flush=True,
                    )
            except Exception as e:
                print("PO CATCH-ALL ERROR:", repr(e), flush=True)

        client.sio.on("*", handler=po_catch_all)

        # PASS_PO_SMART_EVENT_CAPTURE
        # Capture likely market-data packets automatically.
        async def po_smart_capture(event, data):
            try:
                import json as _json
                from pathlib import Path as _Path
                import time as _time

                text = _json.dumps(data, default=str)

                keywords = (
                    "price",
                    "quote",
                    "stream",
                    "candle",
                    "asset",
                    "symbol",
                    "close",
                    "open",
                    "high",
                    "low",
                    "EURUSD",
                    "GBPUSD",
                    "USDJPY",
                )

                looks_market = any(k.lower() in text.lower() for k in keywords)
                has_numbers = sum(ch.isdigit() for ch in text) >= 6

                if looks_market and has_numbers:
                    line = _json.dumps({
                        "ts": _time.time(),
                        "event": event,
                        "data": data,
                    }, default=str)

                    capture = _Path("/tmp/po_market_capture.jsonl")
                    with capture.open("a") as f:
                        f.write(line + "\n")

                    print("PO MARKET CANDIDATE:", event, text[:300], flush=True)

            except Exception as e:
                print("PO SMART CAPTURE ERROR:", repr(e), flush=True)

        client.sio.on("*", handler=po_smart_capture)

        @client.on.update_close_value
        async def on_update_close_value(
            updates: list[UpdateCloseValueItem],
        ):
            for tick in updates:
                symbol = tick.asset.value
                price = float(tick.value)
                timestamp = float(tick.timestamp)

                await bridge.queue.put(json.dumps({
                    "event": "price",
                    "source": "pocket_option",
                    "symbol": symbol,
                    "price": price,
                    "timestamp": timestamp,
                }))

        @client.on.disconnect
        async def on_disconnect():
            bridge.authenticated = False

            await bridge.queue.put(json.dumps({
                "event": "po_status",
                "status": "disconnected",
                "source": "pocket_option",
            }))

    async def connect(self):
        if self.authenticated:
            return

        await self.client.connect(
            PO_URL,
            headers={
                "Origin": "https://pocketoption.com",
                "User-Agent": "Mozilla/5.0",
            },
        )

        try:
            await asyncio.wait_for(
                self.auth_event.wait(),
                timeout=20,
            )
        except asyncio.TimeoutError:
            raise RuntimeError(
                "Pocket Option SDK authentication timed out"
            )

        if not self.authenticated:
            raise RuntimeError(
                "Pocket Option SDK authentication failed"
            )

    async def messages(self):
        if not self.authenticated:
            await self.connect()

        while not self.closed:
            message = await self.queue.get()
            yield message

    async def close(self):
        self.closed = True

        try:
            await self.client.disconnect()
        except Exception:
            pass

        self.authenticated = False
