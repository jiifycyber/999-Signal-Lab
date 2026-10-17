from __future__ import annotations

import asyncio
import csv
import json
import re
import time
from collections import defaultdict, deque
from datetime import datetime
from pathlib import Path
from typing import Any, Optional

import websockets

from duke_super_brain import DukeSuperBrain


BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"
LOG_DIR = BASE_DIR / "logs"

DATA_DIR.mkdir(exist_ok=True)
LOG_DIR.mkdir(exist_ok=True)

# Existing Pocket Option bridge
WS_URL = "ws://127.0.0.1:8000/ws/po"

# Keep enough live prices for short-term analysis.
MAX_HISTORY = 600

# Don't run the advanced analysis until we have some real history.
MIN_HISTORY = 30

# Throttle console analysis so thousands of ticks don't flood Terminal.
ANALYZE_EVERY_SECONDS = 1.0

# Save every valid incoming tick.
TICK_FILE = DATA_DIR / "live_ticks.csv"

# Save Super Brain forecasts for later training/evaluation.
FORECAST_FILE = DATA_DIR / "duke_live_forecasts.csv"


brain = DukeSuperBrain()

histories: dict[str, deque[float]] = defaultdict(
    lambda: deque(maxlen=MAX_HISTORY)
)

last_analysis_time: dict[str, float] = {}

last_prices: dict[str, float] = {}


def normalize_symbol(value: str) -> str:
    value = str(value).strip().upper()

    value = value.replace("/", "")
    value = value.replace("-", "")
    value = value.replace(" ", "_")

    return value


def safe_float(value: Any) -> Optional[float]:
    try:
        number = float(value)

        if number <= 0:
            return None

        return number

    except Exception:
        return None


def ensure_csv_headers() -> None:
    if not TICK_FILE.exists():
        with TICK_FILE.open("w", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(
                [
                    "timestamp",
                    "symbol",
                    "price",
                ]
            )

    if not FORECAST_FILE.exists():
        with FORECAST_FILE.open("w", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(
                [
                    "timestamp",
                    "symbol",
                    "decision",
                    "confidence",
                    "current_price",
                    "support",
                    "resistance",
                    "min_entry_price",
                    "max_entry_price",
                    "entry_status",
                    "regime",
                    "structure",
                    "momentum",
                    "rsi",
                    "velocity",
                    "acceleration",
                    "volatility",
                    "bullish_score",
                    "bearish_score",
                    "higher_high",
                    "higher_low",
                    "lower_high",
                    "lower_low",
                    "breakout_up",
                    "breakout_down",
                ]
            )


def save_tick(
    timestamp: str,
    symbol: str,
    price: float,
) -> None:
    with TICK_FILE.open("a", newline="") as f:
        writer = csv.writer(f)

        writer.writerow(
            [
                timestamp,
                symbol,
                price,
            ]
        )


def save_forecast(
    timestamp: str,
    result,
) -> None:
    with FORECAST_FILE.open("a", newline="") as f:
        writer = csv.writer(f)

        writer.writerow(
            [
                timestamp,
                result.symbol,
                result.decision,
                result.confidence,
                result.current_price,
                result.support,
                result.resistance,
                result.min_entry_price,
                result.max_entry_price,
                result.entry_status,
                result.market_regime,
                result.structure,
                result.momentum,
                result.rsi,
                result.velocity,
                result.acceleration,
                result.volatility,
                result.bullish_score,
                result.bearish_score,
                result.higher_high,
                result.higher_low,
                result.lower_high,
                result.lower_low,
                result.breakout_up,
                result.breakout_down,
            ]
        )


def candidate_from_dict(
    obj: dict,
) -> list[tuple[str, float]]:
    results: list[tuple[str, float]] = []

    symbol_keys = [
        "symbol",
        "asset",
        "pair",
        "instrument",
        "ticker",
        "name",
    ]

    price_keys = [
        "price",
        "close",
        "value",
        "rate",
        "quote",
        "last",
        "current_price",
    ]

    symbol = None
    price = None

    for key in symbol_keys:
        if key in obj and isinstance(obj[key], (str, int)):
            symbol = normalize_symbol(obj[key])
            break

    for key in price_keys:
        if key in obj:
            price = safe_float(obj[key])

            if price is not None:
                break

    if symbol and price:
        # Filter obvious status/event strings.
        if any(
            word in symbol
            for word in [
                "STATUS",
                "CONNECTED",
                "AUTH",
                "SUBSCRIB",
                "SOURCE",
            ]
        ):
            pass
        else:
            results.append((symbol, price))

    # Some APIs use:
    # {"EURUSD": 1.16425}
    for key, value in obj.items():
        if isinstance(value, (int, float)):
            maybe_price = safe_float(value)

            if maybe_price is None:
                continue

            maybe_symbol = normalize_symbol(key)

            # Currency/OTC style names.
            if re.fullmatch(
                r"[A-Z]{6}(?:_OTC)?",
                maybe_symbol,
            ):
                results.append(
                    (
                        maybe_symbol,
                        maybe_price,
                    )
                )

    return results


def extract_quotes(
    payload: Any,
) -> list[tuple[str, float]]:
    """
    Recursively search common Pocket Option / WebSocket payload
    shapes for symbol + live price pairs.
    """

    found: list[tuple[str, float]] = []

    if payload is None:
        return found

    if isinstance(payload, dict):
        found.extend(
            candidate_from_dict(payload)
        )

        for value in payload.values():
            if isinstance(
                value,
                (dict, list, tuple, str),
            ):
                found.extend(
                    extract_quotes(value)
                )

    elif isinstance(payload, (list, tuple)):
        # Common compact quote forms:
        # ["EURUSD", 1.16422]
        if len(payload) >= 2:
            if isinstance(payload[0], str):
                price = safe_float(payload[1])

                if price is not None:
                    found.append(
                        (
                            normalize_symbol(payload[0]),
                            price,
                        )
                    )

        for item in payload:
            if isinstance(
                item,
                (dict, list, tuple, str),
            ):
                found.extend(
                    extract_quotes(item)
                )

    elif isinstance(payload, str):
        text = payload.strip()

        # Raw Socket.IO often starts with numbers such as:
        # 42["event",{...}]
        if text.startswith("42"):
            text = text[2:]

        # Try JSON.
        try:
            decoded = json.loads(text)

            return extract_quotes(decoded)

        except Exception:
            pass

        # Last-resort common pattern:
        # EURUSD ... 1.16422
        matches = re.findall(
            r"\b([A-Z]{6}(?:[_\-\s]?OTC)?)\b"
            r".{0,80}?"
            r"(\d+(?:\.\d+)?)",
            text.upper(),
        )

        for symbol, raw_price in matches:
            price = safe_float(raw_price)

            if price is not None:
                found.append(
                    (
                        normalize_symbol(symbol),
                        price,
                    )
                )

    # Deduplicate while retaining order.
    unique = []
    seen = set()

    for symbol, price in found:
        key = (
            symbol,
            round(price, 10),
        )

        if key in seen:
            continue

        seen.add(key)
        unique.append(
            (
                symbol,
                price,
            )
        )

    return unique


def print_analysis(result) -> None:
    arrow = "▲" if result.decision == "BUY" else "▼"

    print()
    print(
        "═" * 88
    )

    print(
        f"DUKE SUPER LIVE  {result.symbol}  "
        f"{arrow} {result.decision}  "
        f"CONF {result.confidence:.1f}%"
    )

    print(
        f"PRICE {result.current_price:.6f}  |  "
        f"ENTRY {result.min_entry_price:.6f}"
        f" → {result.max_entry_price:.6f}"
    )

    print(
        f"SUPPORT {result.support:.6f}  |  "
        f"RESISTANCE {result.resistance:.6f}"
    )

    print(
        f"REGIME: {result.market_regime}  |  "
        f"STRUCTURE: {result.structure}"
    )

    print(
        f"STATUS: {result.entry_status}"
    )

    print(
        f"BULL {result.bullish_score:.1f}  |  "
        f"BEAR {result.bearish_score:.1f}  |  "
        f"RSI {result.rsi:.1f}"
    )

    # Show Duke's strongest reasoning evidence.
    for reason in result.reasoning[:6]:
        print(
            f"  • {reason}"
        )

    print(
        "═" * 88
    )


async def process_quote(
    symbol: str,
    price: float,
) -> None:
    now = datetime.now()
    timestamp = now.isoformat(
        timespec="milliseconds"
    )

    history = histories[symbol]
    history.append(price)

    previous = last_prices.get(symbol)
    last_prices[symbol] = price

    save_tick(
        timestamp,
        symbol,
        price,
    )

    if previous is not None:
        direction = (
            "↑"
            if price > previous
            else "↓"
            if price < previous
            else "·"
        )
    else:
        direction = "·"

    print(
        f"LIVE {timestamp}  "
        f"{symbol:<14} "
        f"{price:<14.7f} {direction} "
        f"HISTORY={len(history)}"
    )

    if len(history) < MIN_HISTORY:
        return

    current_time = time.monotonic()

    previous_analysis = last_analysis_time.get(
        symbol,
        0.0,
    )

    if (
        current_time - previous_analysis
        < ANALYZE_EVERY_SECONDS
    ):
        return

    last_analysis_time[symbol] = current_time

    try:
        result = brain.analyze(
            symbol=symbol,
            prices=list(history),
        )

    except Exception as exc:
        print(
            f"DUKE ANALYSIS ERROR "
            f"{symbol}: {exc}"
        )

        return

    save_forecast(
        timestamp,
        result,
    )

    print_analysis(result)


async def run_live() -> None:
    ensure_csv_headers()

    print()
    print(
        "999 SIGNAL INTELLIGENCE"
    )
    print(
        "DUKE SUPER BRAIN — LIVE MARKET CONNECTOR"
    )
    print()

    print(
        f"Connecting to: {WS_URL}"
    )

    print(
        "The connector will automatically retry "
        "if the backend is temporarily unavailable."
    )

    print()

    while True:
        try:
            async with websockets.connect(
                WS_URL,
                ping_interval=20,
                ping_timeout=20,
                close_timeout=5,
                max_size=None,
            ) as websocket:

                print()
                print(
                    "✓ CONNECTED TO LIVE POCKET OPTION BRIDGE"
                )
                print()

                async for message in websocket:
                    try:
                        payload = json.loads(
                            message
                        )
                    except Exception:
                        payload = message

                    quotes = extract_quotes(
                        payload
                    )

                    if not quotes:
                        # Keep status messages visible,
                        # but don't dump enormous blobs.
                        text = str(payload)

                        if len(text) > 300:
                            text = (
                                text[:300]
                                + "..."
                            )

                        print(
                            "BRIDGE EVENT:",
                            text,
                        )

                        continue

                    for symbol, price in quotes:
                        await process_quote(
                            symbol,
                            price,
                        )

        except KeyboardInterrupt:
            raise

        except Exception as exc:
            print()
            print(
                f"⚠ LIVE BRIDGE CONNECTION ERROR: {exc}"
            )

            print(
                "Retrying in 3 seconds..."
            )

            await asyncio.sleep(3)


if __name__ == "__main__":
    try:
        asyncio.run(
            run_live()
        )

    except KeyboardInterrupt:
        print()
        print()
        print(
            "DUKE SUPER LIVE SCANNER STOPPED"
        )
