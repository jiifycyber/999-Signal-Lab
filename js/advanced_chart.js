(() => {
  const charts = new Map();

  function normalizeTime(value) {
    if (typeof value === 'number') {
      return Math.floor(value);
    }

    const parsed = Number(value);

    if (Number.isFinite(parsed)) {
      return Math.floor(parsed);
    }

    return Math.floor(Date.now() / 1000);
  }

  function getRecord(id) {
    return charts.get(id);
  }

  window.Signal999Chart = {
    create(id) {
      const container = document.getElementById(id);

      if (!container) {
        console.warn('[999 CHART] container missing:', id);
        return false;
      }

      const existing = charts.get(id);

      if (existing) {
        try {
          existing.chart.remove();
        } catch (_) {}

        charts.delete(id);
      }

      const chart = LightweightCharts.createChart(container, {
        autoSize: true,

        layout: {
          background: {
            type: 'solid',
            color: '#030B13',
          },
          textColor: '#8394A7',
          attributionLogo: true,
        },

        grid: {
          vertLines: {
            color: 'rgba(255,255,255,0.045)',
          },
          horzLines: {
            color: 'rgba(255,255,255,0.045)',
          },
        },

        crosshair: {
          mode: LightweightCharts.CrosshairMode.Normal,
        },

        rightPriceScale: {
          visible: true,
          borderColor: 'rgba(0,229,255,0.18)',
          autoScale: true,
          scaleMargins: {
            top: 0.12,
            bottom: 0.12,
          },
        },

        timeScale: {
          borderColor: 'rgba(0,229,255,0.18)',
          timeVisible: true,
          secondsVisible: false,
          rightOffset: 6,
          barSpacing: 9,
          minBarSpacing: 2,
          fixLeftEdge: false,
          fixRightEdge: false,
          lockVisibleTimeRangeOnResize: true,
        },

        handleScroll: {
          mouseWheel: true,
          pressedMouseMove: true,
          horzTouchDrag: true,
          vertTouchDrag: false,
        },

        handleScale: {
          axisPressedMouseMove: {
            time: true,
            price: true,
          },
          mouseWheel: true,
          pinch: true,
        },
      });

      const series = chart.addSeries(
        LightweightCharts.CandlestickSeries,
        {
          upColor: '#27FF88',
          downColor: '#FF4057',
          wickUpColor: '#27FF88',
          wickDownColor: '#FF4057',
          borderVisible: false,

          priceFormat: {
            type: 'price',
            precision: 5,
            minMove: 0.00001,
          },
        },
      );

      charts.set(id, {
        chart,
        series,
      });

      console.log('[999 CHART] created:', id);

      return true;
    },

    setCandles(id, rawCandles) {
      const record = getRecord(id);

      if (!record) {
        return false;
      }

      let input = rawCandles;

      if (typeof rawCandles === 'string') {
        try {
          input = JSON.parse(rawCandles);
        } catch (error) {
          console.error('[999 CHART] invalid candle JSON', error);
          return false;
        }
      }

      if (!Array.isArray(input)) {
        return false;
      }

      const candles = input
        .map((c) => ({
          time: normalizeTime(c.time),
          open: Number(c.open),
          high: Number(c.high),
          low: Number(c.low),
          close: Number(c.close),
        }))
        .filter((c) =>
          Number.isFinite(c.time) &&
          Number.isFinite(c.open) &&
          Number.isFinite(c.high) &&
          Number.isFinite(c.low) &&
          Number.isFinite(c.close) &&
          c.open > 0 &&
          c.high > 0 &&
          c.low > 0 &&
          c.close > 0
        )
        .sort((a, b) => a.time - b.time);

      record.series.setData(candles);

      return true;
    },

    updateCandle(id, rawCandle) {
      const record = getRecord(id);

      if (!record || !rawCandle) {
        return false;
      }

      const c = rawCandle;

      record.series.update({
        time: normalizeTime(c.time),
        open: Number(c.open),
        high: Number(c.high),
        low: Number(c.low),
        close: Number(c.close),
      });

      return true;
    },

    fitContent(id) {
      const record = getRecord(id);

      if (!record) {
        return false;
      }

      record.chart.timeScale().fitContent();
      record.chart.priceScale('right').setAutoScale(true);

      return true;
    },

    scrollToLive(id) {
      const record = getRecord(id);

      if (!record) {
        return false;
      }

      record.chart.timeScale().scrollToRealTime();

      return true;
    },

    zoomIn(id) {
      const record = getRecord(id);

      if (!record) {
        return false;
      }

      const scale = record.chart.timeScale();
      const options = scale.options();
      const current = options.barSpacing || 9;

      scale.applyOptions({
        barSpacing: Math.min(40, current * 1.20),
      });

      return true;
    },

    zoomOut(id) {
      const record = getRecord(id);

      if (!record) {
        return false;
      }

      const scale = record.chart.timeScale();
      const options = scale.options();
      const current = options.barSpacing || 9;

      scale.applyOptions({
        barSpacing: Math.max(2, current / 1.20),
      });

      return true;
    },

    setGrid(id, visible) {
      const record = getRecord(id);

      if (!record) {
        return false;
      }

      record.chart.applyOptions({
        grid: {
          vertLines: {
            visible: !!visible,
          },
          horzLines: {
            visible: !!visible,
          },
        },
      });

      return true;
    },

    remove(id) {
      const record = getRecord(id);

      if (!record) {
        return;
      }

      try {
        record.chart.remove();
      } catch (_) {}

      charts.delete(id);
    },
  };
})();
