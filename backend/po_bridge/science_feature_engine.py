import math
import statistics
import sys
from dataclasses import dataclass
from typing import Any

from science_tick_store import science_tick_store


@dataclass
class Tick:
    symbol: str
    price: float
    ts: float


def clamp(value: float, low: float = -1.0, high: float = 1.0) -> float:
    return max(low, min(high, value))


def load_ticks(symbol: str, limit: int = 5000) -> list[Tick]:
    rows = science_tick_store.history_24h(symbol, limit=limit)
    ticks = [
        Tick(symbol=row[0], price=float(row[1]), ts=float(row[2]))
        for row in rows
        if row[1] is not None and row[2] is not None
    ]
    ticks.sort(key=lambda tick: tick.ts)
    return ticks


def price_at_or_before(ticks: list[Tick], cutoff: float) -> float:
    for tick in reversed(ticks):
        if tick.ts <= cutoff:
            return tick.price
    return ticks[0].price


def momentum_bps(ticks: list[Tick], seconds: int) -> float:
    if len(ticks) < 2:
        return 0.0
    last = ticks[-1]
    base = price_at_or_before(ticks, last.ts - seconds)
    if base == 0:
        return 0.0
    return ((last.price - base) / base) * 10000.0


def velocity_bps_per_second(ticks: list[Tick]) -> float:
    if len(ticks) < 2:
        return 0.0
    first = ticks[0]
    last = ticks[-1]
    dt = max(last.ts - first.ts, 1e-9)
    if first.price == 0:
        return 0.0
    return (((last.price - first.price) / first.price) * 10000.0) / dt


def recent_window(ticks: list[Tick], seconds: int) -> list[Tick]:
    if not ticks:
        return []
    cutoff = ticks[-1].ts - seconds
    rows = [tick for tick in ticks if tick.ts >= cutoff]
    return rows if len(rows) >= 2 else ticks[-min(len(ticks), 2):]


def build_candles(ticks: list[Tick], timeframe_seconds: int) -> list[dict[str, Any]]:
    buckets: dict[int, list[Tick]] = {}
    for tick in ticks:
        bucket = int(tick.ts // timeframe_seconds) * timeframe_seconds
        buckets.setdefault(bucket, []).append(tick)

    candles = []
    for bucket in sorted(buckets):
        group = sorted(buckets[bucket], key=lambda tick: tick.ts)
        prices = [tick.price for tick in group]
        candles.append({
            "timestamp": bucket,
            "open": prices[0],
            "high": max(prices),
            "low": min(prices),
            "close": prices[-1],
            "ticks": len(prices),
        })
    return candles


def candle_summary(ticks: list[Tick], timeframe_seconds: int) -> dict[str, Any]:
    candles = build_candles(ticks, timeframe_seconds)
    if not candles:
        return {"candles": 0, "trend": "insufficient", "change_bps": 0.0}

    usable = candles[-min(3, len(candles)):]
    first_open = usable[0]["open"]
    last_close = usable[-1]["close"]
    change_bps = (((last_close - first_open) / first_open) * 10000.0 if first_open else 0.0)

    if len(candles) < 2:
        trend = "insufficient"
    elif change_bps > 0.25:
        trend = "bullish"
    elif change_bps < -0.25:
        trend = "bearish"
    else:
        trend = "neutral"

    return {
        "candles": len(candles),
        "trend": trend,
        "change_bps": round(change_bps, 4),
        "latest": candles[-1],
    }


def analyze(symbol: str, minimum_ticks: int = 30) -> dict[str, Any]:
    ticks = load_ticks(symbol)
    if len(ticks) < minimum_ticks:
        return {
            "symbol": symbol,
            "status": "insufficient_data",
            "tick_count": len(ticks),
            "minimum_ticks": minimum_ticks,
        }

    work = recent_window(ticks, 300)
    prices = [tick.price for tick in work]

    deltas = [work[i].price - work[i - 1].price for i in range(1, len(work))]
    up = sum(delta > 0 for delta in deltas)
    down = sum(delta < 0 for delta in deltas)
    flat = sum(delta == 0 for delta in deltas)
    directional = up + down
    tick_pressure = (up - down) / directional if directional else 0.0

    returns = []
    for i in range(1, len(work)):
        a = work[i - 1].price
        b = work[i].price
        if a > 0 and b > 0:
            returns.append(math.log(b / a) * 10000.0)

    volatility_bps = statistics.pstdev(returns) if len(returns) >= 2 else 0.0

    low = min(prices)
    high = max(prices)
    last_price = prices[-1]
    range_position = (last_price - low) / (high - low) if high > low else 0.5

    mean_price = statistics.fmean(prices)
    price_std = statistics.pstdev(prices) if len(prices) >= 2 else 0.0
    mean_reversion_z = (last_price - mean_price) / price_std if price_std > 0 else 0.0
    reversal_pressure = clamp(abs(mean_reversion_z) / 3.0, 0.0, 1.0)

    full_velocity = velocity_bps_per_second(work)
    midpoint = max(2, len(work ) // 2)
    previous = work[:midpoint]
    recent = work[midpoint - 1:]
    acceleration = velocity_bps_per_second(recent) - velocity_bps_per_second(previous) if len(previous) >= 2 and len(recent) >= 2 else 0.0

    m10 = momentum_bps(work, 10)
    m30 = momentum_bps(work, 30)
    m60 = momentum_bps(work, 60)

    m1 = candle_summary(ticks, 60)
    m5 = candle_summary(ticks, 300)
    m15 = candle_summary(ticks, 900)

    trend_votes = {"bullish": 1.0, "neutral": 0.0, "bearish": -1.0, "insufficient": 0.0}
    available_trends = [trend_votes[item["trend"]] for item in (m1, m5, m15) if item["trend"] != "insufficient"]
    trend_alignment = statistics.fmean(available_trends) if available_trends else 0.0

    fingerprint = {
        "velocity": round(clamp(full_velocity / 0.5), 4),
        "acceleration": round(clamp(acceleration / 0.5), 4),
        "tick_pressure": round(clamp(tick_pressure), 4),
        "momentum_10s": round(clamp(m10 / 5.0), 4),
        "momentum_30s": round(clamp(m30 / 10.0), 4),
        "momentum_60s": round(clamp(m60 / 15.0), 4),
        "volatility": round(clamp(volatility_bps / 2.0, 0.0, 1.0), 4),
        "range_position": round((range_position * 2.0) - 1.0, 4),
        "mean_reversion": round(clamp(-mean_reversion_z / 3.0), 4),
        "trend_alignment": round(clamp(trend_alignment), 4),
    }

    return {
        "symbol": symbol,
        "status": "ready",
        "tick_count_24h": len(ticks),
        "analysis_ticks": len(work),
        "analysis_seconds": round(work[-1].ts - work[0].ts, 3),
        "current_price": last_price,
        "velocity_bps_per_sec": round(full_velocity, 6),
        "acceleration_bps_per_sec2_proxy": round(acceleration, 6),
        "tick_pressure": round(tick_pressure, 6),
        "up_ticks": up,
        "down_ticks": down,
        "flat_ticks": flat,
        "momentum_bps": {"10s": round(m10, 4), "30s": round(m30, 4), "60s": round(m60, 4)},
        "volatility_bps": round(volatility_bps, 6),
        "range": {"low": low, "high": high, "position_0_to_1": round(range_position, 6)},
        "mean_reversion": {"z_score": round(mean_reversion_z, 6), "pressure_0_to_1": round(reversal_pressure, 6)},
        "timeframes": {"M1": m1, "M5": m5, "M15": m15},
        "trend_alignment": round(trend_alignment, 6),
        "fingerprint": fingerprint,
    }


if __name__ == "__main__":
    symbols = sys.argv[1:] or ["AUDCAD_OTC", "EURCHF_OTC"]
    import json

    for symbol in symbols:
        print(json.dumps(analyze(symbol), indent=2, sort_keys=False))
