import bisect
import math
import statistics
from typing import Any

from science_feature_engine import Tick, candle_summary, load_ticks, momentum_bps


def _volatility_bps(ticks: list[Tick]) -> float:
    returns = []
    for i in range(1, len(ticks)):
        a = ticks[i - 1].price
        b = ticks[i].price
        if a > 0 and b > 0:
            returns.append(math.log(b / a) * 10000.0)
    return statistics.pstdev(returns) if len(returns) >= 2 else 0.0


def _percentile(values: list[float], q: float) -> float:
    if not values:
        return 0.0
    rows = sorted(values)
    if len(rows) == 1:
        return rows[0]
    pos = (len(rows) - 1) * q
    lo = int(math.floor(pos))
    hi = int(math.ceil(pos))
    if lo == hi:
        return rows[lo]
    weight = pos - lo
    return rows[lo] * (1.0 - weight) + rows[hi] * weight


def analyze_regime_24h(symbol: str) -> dict[str, Any]:
    ticks = load_ticks(symbol, limit=100000)
    if len(ticks) < 30:
        return {
            "symbol": symbol,
            "status": "insufficient_data",
            "tick_count_24h": len(ticks),
            "samples": 0,
            "percentages": {},
        }

    timestamps = [tick.ts for tick in ticks]
    end_ts = ticks[-1].ts
    start_ts = max(ticks[0].ts + 900.0, end_ts - 86400.0)
    anchor = math.ceil(start_ts / 60.0) * 60.0
    snapshots = []

    while anchor <= end_ts:
        left = bisect.bisect_left(timestamps, anchor - 900.0)
        right = bisect.bisect_right(timestamps, anchor)
        window = ticks[left:right]
        if len(window) >= 30:
            m1 = candle_summary(window, 60)
            m5 = candle_summary(window, 300)
            m15 = candle_summary(window, 900)
            votes = {"bullish": 1.0, "neutral": 0.0, "bearish": -1.0}
            trend_names = [
                item["trend"]
                for item in (m1, m5, m15)
                if item["trend"] != "insufficient"
            ]
            trend_votes = [votes[name] for name in trend_names]
            alignment = statistics.fmean(trend_votes) if trend_votes else 0.0
            snapshots.append({
                "ts": anchor,
                "volatility_bps": _volatility_bps(window),
                "alignment": alignment,
                "momentum_60s": momentum_bps(window, 60),
                "momentum_300s": momentum_bps(window, 300),
                "trends": trend_names,
            })
        anchor += 60.0

    if not snapshots:
        return {
            "symbol": symbol,
            "status": "insufficient_data",
            "tick_count_24h": len(ticks),
            "samples": 0,
            "percentages": {},
        }

    high_vol_threshold = _percentile(
        [float(row["volatility_bps"]) for row in snapshots], 0.75
    )
    counts = {
        "bullish_trend": 0,
        "bearish_trend": 0,
        "range": 0,
        "high_volatility": 0,
        "transition": 0,
    }

    for row in snapshots:
        trends = row["trends"]
        alignment = float(row["alignment"])
        m60 = float(row["momentum_60s"])
        m300 = float(row["momentum_300s"])
        vol = float(row["volatility_bps"])
        disagreement = "bullish" in trends and "bearish" in trends

        if high_vol_threshold > 0 and vol >= high_vol_threshold:
            bucket = "high_volatility"
        elif alignment >= 0.34 and m300 > 0.25:
            bucket = "bullish_trend"
        elif alignment <= -0.34 and m300 < -0.25:
            bucket = "bearish_trend"
        elif disagreement or (abs(alignment) < 0.34 and abs(m60) >= 0.25):
            bucket = "transition"
        else:
            bucket = "range"
        counts[bucket] += 1

    total = sum(counts.values())
    percentages = {
        key: round((value / total) * 100.0, 1) if total else 0.0
        for key, value in counts.items()
    }

    return {
        "symbol": symbol,
        "status": "ready",
        "window_hours": 24,
        "tick_count_24h": len(ticks),
        "samples": total,
        "sample_interval_seconds": 60,
        "lookback_seconds_per_sample": 900,
        "high_volatility_threshold_bps": round(high_vol_threshold, 6),
        "counts": counts,
        "percentages": percentages,
        "percentage_total": round(sum(percentages.values()), 1),
    }
