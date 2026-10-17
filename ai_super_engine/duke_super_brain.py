from __future__ import annotations

import json
import math
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import List, Optional

import joblib
import numpy as np
import pandas as pd
import torch

try:
    import xgboost as xgb
except Exception:
    xgb = None

try:
    import lightgbm as lgb
except Exception:
    lgb = None


BASE_DIR = Path(__file__).resolve().parent
MODEL_DIR = BASE_DIR / "models"
DATA_DIR = BASE_DIR / "data"
LOG_DIR = BASE_DIR / "logs"

MODEL_DIR.mkdir(exist_ok=True)
DATA_DIR.mkdir(exist_ok=True)
LOG_DIR.mkdir(exist_ok=True)


@dataclass
class DukeAnalysis:
    symbol: str

    decision: str
    confidence: float

    market_regime: str
    structure: str
    momentum: str

    current_price: float
    support: float
    resistance: float

    min_entry_price: float
    max_entry_price: float

    entry_status: str

    bullish_score: float
    bearish_score: float

    volatility: float
    rsi: float

    fast_ema: float
    slow_ema: float
    long_ema: float

    velocity: float
    acceleration: float

    higher_high: bool
    higher_low: bool
    lower_high: bool
    lower_low: bool

    breakout_up: bool
    breakout_down: bool

    reasoning: List[str]


class DukeSuperBrain:
    """
    999 SIGNAL INTELLIGENCE
    DUKE SUPER BRAIN V1

    This is the advanced reasoning/feature layer.

    It does NOT claim a trained ML edge yet.
    XGBoost / LightGBM models are loaded only if trained model
    files are present inside ai_super_engine/models.
    """

    def __init__(self):
        self.xgb_model = None
        self.lgb_model = None
        self.scaler = None

        self._load_models()

    # ==========================================================
    # MODEL LOADING
    # ==========================================================

    def _load_models(self):
        xgb_path = MODEL_DIR / "duke_xgb.json"
        lgb_path = MODEL_DIR / "duke_lgb.txt"
        scaler_path = MODEL_DIR / "duke_scaler.joblib"

        if scaler_path.exists():
            try:
                self.scaler = joblib.load(scaler_path)
            except Exception:
                self.scaler = None

        if xgb is not None and xgb_path.exists():
            try:
                model = xgb.XGBClassifier()
                model.load_model(str(xgb_path))
                self.xgb_model = model
            except Exception:
                self.xgb_model = None

        if lgb is not None and lgb_path.exists():
            try:
                self.lgb_model = lgb.Booster(
                    model_file=str(lgb_path)
                )
            except Exception:
                self.lgb_model = None

    # ==========================================================
    # TECHNICAL FUNCTIONS
    # ==========================================================

    @staticmethod
    def _ema(values: np.ndarray, period: int) -> float:
        if len(values) == 0:
            return 0.0

        series = pd.Series(values)

        return float(
            series.ewm(
                span=period,
                adjust=False,
            ).mean().iloc[-1]
        )

    @staticmethod
    def _rsi(values: np.ndarray, period: int = 14) -> float:
        if len(values) < 2:
            return 50.0

        series = pd.Series(values)
        delta = series.diff()

        gains = delta.clip(lower=0)
        losses = -delta.clip(upper=0)

        avg_gain = gains.rolling(period).mean().iloc[-1]
        avg_loss = losses.rolling(period).mean().iloc[-1]

        if pd.isna(avg_gain):
            avg_gain = gains.mean()

        if pd.isna(avg_loss):
            avg_loss = losses.mean()

        if avg_loss == 0:
            if avg_gain > 0:
                return 100.0
            return 50.0

        rs = avg_gain / avg_loss

        return float(
            100 - (100 / (1 + rs))
        )

    @staticmethod
    def _safe_pct_change(a: float, b: float) -> float:
        if b == 0:
            return 0.0

        return (a - b) / abs(b)

    # ==========================================================
    # STRUCTURE ENGINE
    # ==========================================================

    def _market_structure(
        self,
        prices: np.ndarray,
    ):
        if len(prices) < 12:
            current = float(prices[-1])

            return {
                "support": float(np.min(prices)),
                "resistance": float(np.max(prices)),
                "higher_high": False,
                "higher_low": False,
                "lower_high": False,
                "lower_low": False,
                "breakout_up": False,
                "breakout_down": False,
                "structure": "BUILDING HISTORY",
                "previous_high": current,
                "previous_low": current,
            }

        lookback = min(60, len(prices))
        recent = prices[-lookback:]

        half = max(4, lookback // 2)

        previous = recent[:-half]
        newest = recent[-half:]

        previous_high = float(np.max(previous))
        previous_low = float(np.min(previous))

        newest_high = float(np.max(newest))
        newest_low = float(np.min(newest))

        current = float(prices[-1])

        higher_high = newest_high > previous_high
        higher_low = newest_low > previous_low

        lower_high = newest_high < previous_high
        lower_low = newest_low < previous_low

        breakout_up = current > previous_high
        breakout_down = current < previous_low

        # Robust support/resistance.
        # Quantiles reduce the effect of a single strange tick.
        support = float(
            np.quantile(recent, 0.10)
        )

        resistance = float(
            np.quantile(recent, 0.90)
        )

        if higher_high and higher_low:
            structure = "BULLISH HH/HL"

        elif lower_high and lower_low:
            structure = "BEARISH LH/LL"

        elif breakout_up:
            structure = "BULLISH BREAKOUT"

        elif breakout_down:
            structure = "BEARISH BREAKOUT"

        else:
            structure = "RANGE / MIXED"

        return {
            "support": support,
            "resistance": resistance,
            "higher_high": higher_high,
            "higher_low": higher_low,
            "lower_high": lower_high,
            "lower_low": lower_low,
            "breakout_up": breakout_up,
            "breakout_down": breakout_down,
            "structure": structure,
            "previous_high": previous_high,
            "previous_low": previous_low,
        }

    # ==========================================================
    # MARKET REGIME ENGINE
    # ==========================================================

    def _market_regime(
        self,
        prices: np.ndarray,
        fast: float,
        slow: float,
        long_ema: float,
        volatility: float,
    ) -> str:

        current = float(prices[-1])

        if current == 0:
            return "UNKNOWN"

        fast_gap = abs(fast - slow) / abs(current)
        trend_gap = abs(slow - long_ema) / abs(current)

        if volatility > 0.0015:
            return "HIGH VOLATILITY"

        if fast > slow > long_ema:
            if fast_gap > 0.00010:
                return "BULLISH TREND"
            return "WEAK BULLISH TREND"

        if fast < slow < long_ema:
            if fast_gap > 0.00010:
                return "BEARISH TREND"
            return "WEAK BEARISH TREND"

        if trend_gap < 0.00005:
            return "RANGING"

        return "TRANSITION"

    # ==========================================================
    # ENTRY ZONE ENGINE
    # ==========================================================

    def _entry_zone(
        self,
        decision: str,
        current: float,
        support: float,
        resistance: float,
    ):
        range_size = resistance - support

        if range_size <= 0:
            fallback = abs(current) * 0.00010

            return (
                current - fallback,
                current + fallback,
            )

        if decision == "BUY":
            # Prefer lower/middle area of the range.
            min_entry = support + range_size * 0.18
            max_entry = support + range_size * 0.48

        else:
            # Prefer upper/middle area for SELL.
            min_entry = resistance - range_size * 0.48
            max_entry = resistance - range_size * 0.18

        if min_entry > max_entry:
            min_entry, max_entry = max_entry, min_entry

        return (
            float(min_entry),
            float(max_entry),
        )

    # ==========================================================
    # MAIN SUPER ANALYSIS
    # ==========================================================

    def analyze(
        self,
        symbol: str,
        prices: List[float],
    ) -> DukeAnalysis:

        values = np.asarray(
            prices,
            dtype=np.float64,
        )

        values = values[
            np.isfinite(values)
        ]

        if len(values) < 5:
            raise ValueError(
                "Duke Super Brain needs at least 5 valid prices."
            )

        current = float(values[-1])

        fast = self._ema(values, 9)
        slow = self._ema(values, 21)
        long_ema = self._ema(values, 50)

        rsi = self._rsi(values, 14)

        returns = np.diff(values) / np.maximum(
            np.abs(values[:-1]),
            1e-12,
        )

        volatility = float(
            np.std(returns[-30:])
        ) if len(returns) else 0.0

        velocity = 0.0
        acceleration = 0.0

        if len(values) >= 4:
            velocity = self._safe_pct_change(
                values[-1],
                values[-4],
            )

        if len(values) >= 3:
            newest_move = values[-1] - values[-2]
            previous_move = values[-2] - values[-3]

            acceleration = (
                newest_move - previous_move
            ) / max(abs(current), 1e-12)

        structure = self._market_structure(
            values
        )

        regime = self._market_regime(
            values,
            fast,
            slow,
            long_ema,
            volatility,
        )

        bullish = 0.0
        bearish = 0.0

        reasons = []

        # ======================================================
        # TREND BRAIN
        # ======================================================

        if fast > slow:
            bullish += 18
            reasons.append(
                "Fast EMA is above slow EMA."
            )
        elif fast < slow:
            bearish += 18
            reasons.append(
                "Fast EMA is below slow EMA."
            )

        if slow > long_ema:
            bullish += 13
            reasons.append(
                "Intermediate trend is above long trend."
            )
        elif slow < long_ema:
            bearish += 13
            reasons.append(
                "Intermediate trend is below long trend."
            )

        # ======================================================
        # STRUCTURE BRAIN
        # ======================================================

        if structure["higher_high"]:
            bullish += 13
            reasons.append(
                "Recent structure produced a higher high."
            )

        if structure["higher_low"]:
            bullish += 13
            reasons.append(
                "Recent structure produced a higher low."
            )

        if structure["lower_high"]:
            bearish += 13
            reasons.append(
                "Recent structure produced a lower high."
            )

        if structure["lower_low"]:
            bearish += 13
            reasons.append(
                "Recent structure produced a lower low."
            )

        # ======================================================
        # BREAKOUT BRAIN
        # ======================================================

        if structure["breakout_up"]:
            bullish += 18
            reasons.append(
                "Current price broke above the prior swing high."
            )

        if structure["breakout_down"]:
            bearish += 18
            reasons.append(
                "Current price broke below the prior swing low."
            )

        # ======================================================
        # MOMENTUM BRAIN
        # ======================================================

        if rsi > 52:
            amount = min(
                12.0,
                (rsi - 50) * 0.55,
            )

            bullish += amount

            reasons.append(
                f"RSI favors buyers at {rsi:.1f}."
            )

        elif rsi < 48:
            amount = min(
                12.0,
                (50 - rsi) * 0.55,
            )

            bearish += amount

            reasons.append(
                f"RSI favors sellers at {rsi:.1f}."
            )

        if velocity > 0:
            bullish += 10
            reasons.append(
                "Recent price velocity is positive."
            )

        elif velocity < 0:
            bearish += 10
            reasons.append(
                "Recent price velocity is negative."
            )

        if acceleration > 0:
            bullish += 7
            reasons.append(
                "Short-term momentum is accelerating upward."
            )

        elif acceleration < 0:
            bearish += 7
            reasons.append(
                "Short-term momentum is accelerating downward."
            )

        # ======================================================
        # PRICE LOCATION BRAIN
        # ======================================================

        range_size = (
            structure["resistance"]
            - structure["support"]
        )

        if range_size > 0:
            position = (
                current
                - structure["support"]
            ) / range_size

            if position <= 0.25:
                bullish += 5
                reasons.append(
                    "Price is near recent support."
                )

            elif position >= 0.75:
                bearish += 5
                reasons.append(
                    "Price is near recent resistance."
                )

        # ======================================================
        # REGIME BRAIN
        # ======================================================

        if regime == "BULLISH TREND":
            bullish += 12
            reasons.append(
                "Market regime is bullish trend."
            )

        elif regime == "BEARISH TREND":
            bearish += 12
            reasons.append(
                "Market regime is bearish trend."
            )

        # ======================================================
        # FINAL DIRECTION
        # ======================================================

        if bullish >= bearish:
            decision = "BUY"
        else:
            decision = "SELL"

        total = max(
            bullish + bearish,
            1.0,
        )

        edge = abs(
            bullish - bearish
        ) / total

        confidence = float(
            np.clip(
                50.0 + edge * 45.0,
                50.0,
                95.0,
            )
        )

        min_entry, max_entry = (
            self._entry_zone(
                decision,
                current,
                structure["support"],
                structure["resistance"],
            )
        )

        if min_entry <= current <= max_entry:
            entry_status = "ENTRY ZONE"

        elif decision == "BUY":
            if current > max_entry:
                entry_status = (
                    "WAIT FOR BUY PULLBACK"
                )
            else:
                entry_status = (
                    "WAIT FOR PRICE TO RISE"
                )

        else:
            if current < min_entry:
                entry_status = (
                    "WAIT FOR SELL RETRACEMENT"
                )
            else:
                entry_status = (
                    "WAIT FOR PRICE TO DROP"
                )

        momentum = (
            "BULLISH"
            if velocity > 0
            else "BEARISH"
            if velocity < 0
            else "NEUTRAL"
        )

        return DukeAnalysis(
            symbol=symbol,
            decision=decision,
            confidence=confidence,

            market_regime=regime,
            structure=structure["structure"],
            momentum=momentum,

            current_price=current,
            support=structure["support"],
            resistance=structure["resistance"],

            min_entry_price=min_entry,
            max_entry_price=max_entry,

            entry_status=entry_status,

            bullish_score=float(bullish),
            bearish_score=float(bearish),

            volatility=volatility,
            rsi=float(rsi),

            fast_ema=float(fast),
            slow_ema=float(slow),
            long_ema=float(long_ema),

            velocity=float(velocity),
            acceleration=float(acceleration),

            higher_high=bool(
                structure["higher_high"]
            ),

            higher_low=bool(
                structure["higher_low"]
            ),

            lower_high=bool(
                structure["lower_high"]
            ),

            lower_low=bool(
                structure["lower_low"]
            ),

            breakout_up=bool(
                structure["breakout_up"]
            ),

            breakout_down=bool(
                structure["breakout_down"]
            ),

            reasoning=reasons,
        )


def pretty_print(result: DukeAnalysis):
    print()
    print("=" * 68)
    print("999 SIGNAL INTELLIGENCE — DUKE SUPER BRAIN")
    print("=" * 68)

    print(f"SYMBOL:           {result.symbol}")
    print(f"DECISION:         {result.decision}")
    print(f"CONFIDENCE:       {result.confidence:.1f}%")

    print()
    print(f"REGIME:           {result.market_regime}")
    print(f"STRUCTURE:        {result.structure}")
    print(f"MOMENTUM:         {result.momentum}")

    print()
    print(f"CURRENT PRICE:    {result.current_price:.6f}")
    print(f"SUPPORT:          {result.support:.6f}")
    print(f"RESISTANCE:       {result.resistance:.6f}")

    print()
    print(f"MIN ENTRY:        {result.min_entry_price:.6f}")
    print(f"MAX ENTRY:        {result.max_entry_price:.6f}")
    print(f"ENTRY STATUS:     {result.entry_status}")

    print()
    print(f"BULL SCORE:       {result.bullish_score:.2f}")
    print(f"BEAR SCORE:       {result.bearish_score:.2f}")

    print()
    print(f"RSI:              {result.rsi:.2f}")
    print(f"VELOCITY:         {result.velocity:.8f}")
    print(f"ACCELERATION:     {result.acceleration:.8f}")
    print(f"VOLATILITY:       {result.volatility:.8f}")

    print()
    print("DUKE REASONING:")

    for i, reason in enumerate(
        result.reasoning,
        start=1,
    ):
        print(f"  {i}. {reason}")

    print("=" * 68)


if __name__ == "__main__":

    # ==========================================================
    # SELF TEST
    #
    # Synthetic data only verifies that the engine runs.
    # It is NOT training data and NOT proof of trading accuracy.
    # ==========================================================

    np.random.seed(999)

    base = 1.16400

    trend = np.linspace(
        0,
        0.0010,
        120,
    )

    noise = np.random.normal(
        0,
        0.00006,
        120,
    )

    test_prices = (
        base
        + trend
        + noise
    ).tolist()

    brain = DukeSuperBrain()

    result = brain.analyze(
        symbol="EURUSD_TEST",
        prices=test_prices,
    )

    pretty_print(result)

    print()
    print(
        json.dumps(
            asdict(result),
            indent=2,
        )
    )

    print()
    print(
        "APPLE GPU / MPS:",
        torch.backends.mps.is_available(),
    )

    print()
    print(
        "999 DUKE SUPER BRAIN V1: PASS"
    )
