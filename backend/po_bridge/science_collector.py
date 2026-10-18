import asyncio
import json
import time
import websockets

from science_tick_store import science_tick_store

BRIDGE_URL = "wss://bridge.sciool.net/ws/po"


async def run():
    print("999 SIGNAL LAB SCIENCE COLLECTOR STARTING", flush=True)
    print("SOURCE:", BRIDGE_URL, flush=True)

    while True:
        try:
            async with websockets.connect(
                BRIDGE_URL,
                ping_interval=20,
                ping_timeout=20,
                close_timeout=10,
            ) as ws:
                print("SCIENCE COLLECTOR CONNECTED", flush=True)

                async for raw in ws:
                    try:
                        data = json.loads(raw)
                    except Exception:
                        continue

                    if not isinstance(data, dict):
                        continue

                    if data.get("event") != "price":
                        continue

                    symbol = str(data.get("symbol") or "").strip()
                    price = data.get("price")
                    timestamp = data.get("timestamp")

                    if not symbol or not isinstance(price, (int, float)):
                        continue

                    stored = science_tick_store.record(
                        symbol,
                        float(price),
                        timestamp,
                    )

                    if stored:
                        print(
                            "SCIENCE REMOTE STORED:",
                            symbol,
                            price,
                            "24h=",
                            science_tick_store.count_24h(symbol),
                            "total=",
                            science_tick_store.total_count(),
                            flush=True,
                        )

        except Exception as exc:
            print(
                "SCIENCE COLLECTOR RECONNECT:",
                repr(exc),
                flush=True,
            )
            await asyncio.sleep(3)


if __name__ == "__main__":
    asyncio.run(run())
