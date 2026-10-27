(function () {
  "use strict";

  const charts = new Map();

  const PAIRS = [
    "EURUSD",
    "EURUSD_OTC",
    "GBPUSD",
    "GBPUSD_OTC",
    "USDJPY",
    "USDJPY_OTC",
    "AUDUSD",
    "AUDUSD_OTC",
    "USDCHF",
    "USDCAD",
    "NZDUSD",
    "EURGBP"
  ];

  function normalizeSymbol(value) {
    return String(value || "")
      .toUpperCase()
      .replaceAll("/", "")
      .replaceAll(" ", "");
  }

  function symbolInfo(ticker) {
    return {
      ticker: normalizeSymbol(ticker),
      name: normalizeSymbol(ticker).replaceAll("_", " "),
      market: "999"
    };
  }

  function periodFromTimeframe(tf) {
    const value = String(tf || "M1").toUpperCase();

    const map = {
      M1:  { multiplier: 1, timespan: "minute", text: "1m" },
      M5:  { multiplier: 5, timespan: "minute", text: "5m" },
      M15: { multiplier: 15, timespan: "minute", text: "15m" },
      M30: { multiplier: 30, timespan: "minute", text: "30m" },
      M45: { multiplier: 45, timespan: "minute", text: "45m" },
      H1:  { multiplier: 1, timespan: "hour", text: "1h" },
      H2:  { multiplier: 2, timespan: "hour", text: "2h" },
      H4:  { multiplier: 4, timespan: "hour", text: "4h" },
      H8:  { multiplier: 8, timespan: "hour", text: "8h" },
      D1:  { multiplier: 1, timespan: "day", text: "1D" },
      W1:  { multiplier: 1, timespan: "week", text: "1W" },
      MN1: { multiplier: 1, timespan: "month", text: "1M" }
    };

    return map[value] || map.M1;
  }

  function periodMs(period) {
    const mult = Number(
      period && (period.multiplier || period.span) || 1
    );

    const type = String(
      period && (period.timespan || period.type) || "minute"
    ).toLowerCase();

    if (type === "minute") return mult * 60 * 1000;
    if (type === "hour") return mult * 60 * 60 * 1000;
    if (type === "day") return mult * 24 * 60 * 60 * 1000;
    if (type === "week") return mult * 7 * 24 * 60 * 60 * 1000;
    if (type === "month") return mult * 30 * 24 * 60 * 60 * 1000;

    return 60 * 1000;
  }

  function parseBars(raw) {
    let value = raw;

    if (typeof raw === "string") {
      try {
        value = JSON.parse(raw);
      } catch (_) {
        return [];
      }
    }

    if (!Array.isArray(value)) {
      return [];
    }

    return value
      .map((bar) => ({
        timestamp: Number(bar.timestamp),
        open: Number(bar.open),
        high: Number(bar.high),
        low: Number(bar.low),
        close: Number(bar.close),
        volume: Number(bar.volume || 0)
      }))
      .filter((bar) =>
        Number.isFinite(bar.timestamp) &&
        Number.isFinite(bar.open) &&
        Number.isFinite(bar.high) &&
        Number.isFinite(bar.low) &&
        Number.isFinite(bar.close) &&
        bar.open > 0 &&
        bar.high > 0 &&
        bar.low > 0 &&
        bar.close > 0
      )
      .sort((a, b) => a.timestamp - b.timestamp);
  }

  function aggregateBars(input, period) {
    const bars = parseBars(input);
    const bucketMs = periodMs(period);

    if (bucketMs <= 60000) {
      return bars;
    }

    const buckets = new Map();

    for (const bar of bars) {
      const bucket =
        Math.floor(bar.timestamp / bucketMs) * bucketMs;

      const current = buckets.get(bucket);

      if (!current) {
        buckets.set(bucket, {
          timestamp: bucket,
          open: bar.open,
          high: bar.high,
          low: bar.low,
          close: bar.close,
          volume: bar.volume || 0
        });
      } else {
        current.high = Math.max(current.high, bar.high);
        current.low = Math.min(current.low, bar.low);
        current.close = bar.close;
        current.volume += bar.volume || 0;
      }
    }

    return Array.from(buckets.values())
      .sort((a, b) => a.timestamp - b.timestamp);
  }

  async function fetchBridgeBars(ticker, period, count) {
    const symbol = normalizeSymbol(ticker);

    try {
      const response = await fetch(
        "https://bridge.sciool.net/history/" +
          encodeURIComponent(symbol) +
          "?count=" +
          String(count || 500),
        { cache: "no-store" }
      );

      if (!response.ok) {
        return [];
      }

      const payload = await response.json();
      const source = Array.isArray(payload.candles)
        ? payload.candles
        : [];

      const bars = source.map((bar) => ({
        timestamp: Number(bar.timestamp) * 1000,
        open: Number(bar.open),
        high: Number(bar.high),
        low: Number(bar.low),
        close: Number(bar.close),
        volume: Number(bar.volume || 0)
      }));

      return aggregateBars(bars, period);
    } catch (error) {
      console.warn("[999 PRO] bridge history error", error);
      return [];
    }
  }

  class Signal999Datafeed {
    constructor(id) {
      this.id = id;
      this.subscriptions = new Map();
    }

    async searchSymbols(search) {
      const query = String(search || "").toUpperCase();

      return PAIRS
        .filter((ticker) =>
          !query || ticker.includes(query)
        )
        .map(symbolInfo);
    }

    async getHistoryKLineData(symbol, period, from, to) {
      const state = charts.get(this.id);
      const ticker = normalizeSymbol(symbol && symbol.ticker);

      let bars = [];

      if (
        state &&
        ticker === normalizeSymbol(state.symbol) &&
        state.bars.length
      ) {
        bars = aggregateBars(state.bars, period);
      } else {
        bars = await fetchBridgeBars(ticker, period, 500);
      }

      let fromMs = Number(from || 0);
      let toMs = Number(to || 0);

      if (fromMs > 0 && fromMs < 1000000000000) {
        fromMs *= 1000;
      }

      if (toMs > 0 && toMs < 1000000000000) {
        toMs *= 1000;
      }

      if (fromMs > 0) {
        bars = bars.filter((bar) => bar.timestamp >= fromMs);
      }

      if (toMs > 0) {
        bars = bars.filter((bar) => bar.timestamp <= toMs);
      }

      return bars;
    }

    subscribe(symbol, period, callback) {
      const ticker = normalizeSymbol(symbol && symbol.ticker);
      const key =
        ticker +
        ":" +
        JSON.stringify(period || {});

      this.unsubscribe(symbol, period);

      let lastSignature = "";

      const pump = async () => {
        const state = charts.get(this.id);
        let bars = [];

        if (
          state &&
          ticker === normalizeSymbol(state.symbol) &&
          state.bars.length
        ) {
          bars = aggregateBars(state.bars, period);
        } else {
          bars = await fetchBridgeBars(ticker, period, 10);
        }

        if (!bars.length) {
          return;
        }

        const last = bars[bars.length - 1];

        const signature = [
          last.timestamp,
          last.open,
          last.high,
          last.low,
          last.close,
          last.volume
        ].join(":");

        if (signature === lastSignature) {
          return;
        }

        lastSignature = signature;
        callback(last);
      };

      const timer = setInterval(pump, 750);

      this.subscriptions.set(key, timer);

      pump();
    }

    unsubscribe(symbol, period) {
      const ticker = normalizeSymbol(symbol && symbol.ticker);
      const key =
        ticker +
        ":" +
        JSON.stringify(period || {});

      const timer = this.subscriptions.get(key);

      if (timer) {
        clearInterval(timer);
        this.subscriptions.delete(key);
      }
    }

    destroy() {
      for (const timer of this.subscriptions.values()) {
        clearInterval(timer);
      }

      this.subscriptions.clear();
    }
  }

  async function create(id, barsJson, symbol, timeframe) {
    const container = document.getElementById(id);

    if (!container) {
      return false;
    }

    if (!window.klinechartspro) {
      container.innerHTML =
        "<div style='padding:20px;color:#ff6b6b'>" +
        "999 chart engine did not load." +
        "</div>";
      return false;
    }

    const old = charts.get(id);

    if (old) {
      try {
        old.datafeed.destroy();
      } catch (_) {}

      try {
        if (
          old.chart &&
          typeof old.chart.dispose === "function"
        ) {
          old.chart.dispose();
        }
      } catch (_) {}

      charts.delete(id);
    }

    const state = {
      symbol: normalizeSymbol(symbol),
      timeframe: String(timeframe || "M1").toUpperCase(),
      bars: parseBars(barsJson),
      chart: null,
      datafeed: null
    };

    charts.set(id, state);

    const datafeed = new Signal999Datafeed(id);
    state.datafeed = datafeed;

    const KLineChartPro =
      window.klinechartspro.KLineChartPro;

    const chart = new KLineChartPro({
      container: container,
      symbol: symbolInfo(state.symbol),
      period: periodFromTimeframe(state.timeframe),
      datafeed: datafeed,
      theme: "dark",
      locale: "en-US",
      drawingBarVisible: true,
      mainIndicators: [],
      subIndicators: [],
      chartType: "candle_solid",
      onSettingsChange: function () {},
      onDrawingsChange: function () {},
      onLayoutClick: function () {}
    });

    state.chart = chart;

    try {
      if (typeof chart.ready === "function") {
        await chart.ready();
      }
    } catch (error) {
      console.warn("[999 PRO] ready error", error);
    }

    console.log(
      "[999 PRO] ready",
      state.symbol,
      state.timeframe,
      state.bars.length
    );

    return true;
  }

  async function sync(id, barsJson, symbol, timeframe) {
    const state = charts.get(id);

    if (!state) {
      return create(
        id,
        barsJson,
        symbol,
        timeframe
      );
    }

    const nextBars = parseBars(barsJson);
    const nextSymbol = normalizeSymbol(symbol);
    const nextTimeframe =
      String(timeframe || "M1").toUpperCase();

    state.bars = nextBars;

    if (
      nextSymbol !== state.symbol &&
      state.chart &&
      typeof state.chart.setSymbol === "function"
    ) {
      state.symbol = nextSymbol;

      await state.chart.setSymbol(
        symbolInfo(nextSymbol)
      );
    }

    if (
      nextTimeframe !== state.timeframe &&
      state.chart &&
      typeof state.chart.setPeriod === "function"
    ) {
      state.timeframe = nextTimeframe;

      await state.chart.setPeriod(
        periodFromTimeframe(nextTimeframe)
      );
    }

    return true;
  }

  function remove(id) {
    const state = charts.get(id);

    if (!state) {
      return;
    }

    try {
      state.datafeed.destroy();
    } catch (_) {}

    try {
      if (
        state.chart &&
        typeof state.chart.dispose === "function"
      ) {
        state.chart.dispose();
      }
    } catch (_) {}

    charts.delete(id);

    const container = document.getElementById(id);

    if (container) {
      container.innerHTML = "";
    }
  }

  window.Signal999ProChart = {
    create: create,
    sync: sync,
    remove: remove
  };
})();
