import sqlite3
import time
from pathlib import Path
from typing import Any, Optional

DB_PATH = Path(__file__).resolve().parents[1] / "data" / "999_signal_lab_ticks.sqlite3"
DB_PATH.parent.mkdir(parents=True, exist_ok=True)


class ScienceTickStore:
    def __init__(self, path: Path = DB_PATH):
        self.path = path
        self._init_db()

    def _connect(self):
        connection = sqlite3.connect(self.path, timeout=30)
        connection.execute("PRAGMA journal_mode=WAL")
        connection.execute("PRAGMA synchronous=NORMAL")
        return connection

    def _init_db(self):
        with self._connect() as db:
            db.execute(
                '''
                CREATE TABLE IF NOT EXISTS science_ticks (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    symbol TEXT NOT NULL,
                    price REAL NOT NULL,
                    source_timestamp REAL NOT NULL,
                    received_timestamp REAL NOT NULL,
                    is_otc INTEGER NOT NULL,
                    source TEXT NOT NULL,
                    UNIQUE(symbol, price, source_timestamp)
                )
                '''
            )
            db.execute(
                '''
                CREATE INDEX IF NOT EXISTS idx_science_ticks_symbol_time
                ON science_ticks(symbol, source_timestamp)
                '''
            )

    @staticmethod
    def _normalize_timestamp(value: Any, fallback: float) -> float:
        try:
            ts = float(value)
            if ts > 10_000_000_000:
                ts /= 1000.0
            if ts <= 0:
                return fallback
            # Never allow an impossible future source timestamp to distort
            # the rolling Science timeline. Use local receipt time instead.
            if ts > fallback + 2.0:
                return fallback
            return ts
        except Exception:
            return fallback

    def record(self, symbol: str, price: float, timestamp: Any = None) -> bool:
        received = time.time()
        source_ts = self._normalize_timestamp(timestamp, received)

        with self._connect() as db:
            cursor = db.execute(
                '''
                INSERT OR IGNORE INTO science_ticks
                (symbol, price, source_timestamp, received_timestamp, is_otc, source)
                VALUES (?, ?, ?, ?, ?, ?)
                ''',
                (
                    symbol,
                    float(price),
                    source_ts,
                    received,
                    1 if symbol.upper().endswith("_OTC") else 0,
                    "pocket_option_browser",
                ),
            )
            return cursor.rowcount > 0

    def count_24h(self, symbol: Optional[str] = None) -> int:
        cutoff = time.time() - 86400
        with self._connect() as db:
            if symbol:
                row = db.execute(
                    "SELECT COUNT(*) FROM science_ticks WHERE symbol=? AND source_timestamp>=?",
                    (symbol, cutoff),
                ).fetchone()
            else:
                row = db.execute(
                    "SELECT COUNT(*) FROM science_ticks WHERE source_timestamp>=?",
                    (cutoff,),
                ).fetchone()
        return int(row[0] if row else 0)

    def latest(self, symbol: str):
        with self._connect() as db:
            row = db.execute("SELECT symbol,price,source_timestamp,received_timestamp,is_otc,source FROM science_ticks WHERE symbol=? ORDER BY source_timestamp DESC,id DESC LIMIT 1",(symbol,)).fetchone()
        return row

    def history_24h(self, symbol: str, limit: int = 5000):
        cutoff = time.time() - 86400
        limit = max(1, min(int(limit), 50000))
        with self._connect() as db:
            rows = db.execute("SELECT symbol,price,source_timestamp,received_timestamp,is_otc,source FROM (SELECT id,symbol,price,source_timestamp,received_timestamp,is_otc,source FROM science_ticks WHERE symbol=? AND source_timestamp>=? ORDER BY source_timestamp DESC,id DESC LIMIT ?) ORDER BY source_timestamp ASC,id ASC",(symbol,cutoff,limit)).fetchall()
        return rows

    def symbol_counts_24h(self):
        cutoff = time.time() - 86400
        with self._connect() as db:
            rows = db.execute("SELECT symbol,COUNT(*) AS n FROM science_ticks WHERE source_timestamp>=? GROUP BY symbol ORDER BY n DESC,symbol ASC",(cutoff,)).fetchall()
        return rows

    def archive_count(self) -> int:
        cutoff = time.time() - 86400
        with self._connect() as db:
            row = db.execute("SELECT COUNT(*) FROM science_ticks WHERE source_timestamp<?",(cutoff,)).fetchone()
        return int(row[0] if row else 0)

    def total_count(self) -> int:
        with self._connect() as db:
            row = db.execute("SELECT COUNT(*) FROM science_ticks").fetchone()
        return int(row[0] if row else 0)


science_tick_store = ScienceTickStore()
