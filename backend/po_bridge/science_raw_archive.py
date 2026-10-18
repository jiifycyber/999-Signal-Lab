import base64
import hashlib
import json
import os
import time
from pathlib import Path

ARCHIVE_DIR = Path(__file__).resolve().parents[1] / "data" / "raw_market_frames"
MAX_BYTES = 100 * 1024 * 1024
MAX_FILES = 20

def archive_frame(frame, url):
    try:
        raw = frame.encode("utf-8") if isinstance(frame, str) else bytes(frame)
        lower = raw[:512].lower()
        if any(term in lower for term in (b"authorization", b"access_token", b"refresh_token", b"sessionid", b"bearer ", b"password", b"\"auth\"", b"\"login\"")):
            return
        ARCHIVE_DIR.mkdir(parents=True, exist_ok=True)
        os.chmod(ARCHIVE_DIR, 0o700)
        path = ARCHIVE_DIR / "market_frames.jsonl"
        if path.exists() and path.stat().st_size >= MAX_BYTES:
            for i in range(MAX_FILES - 1, 0, -1):
                old = ARCHIVE_DIR / ("market_frames.jsonl." + str(i))
                new = ARCHIVE_DIR / ("market_frames.jsonl." + str(i + 1))
                if old.exists():
                    if i + 1 >= MAX_FILES: old.unlink()
                    else: old.replace(new)
            path.replace(ARCHIVE_DIR / "market_frames.jsonl.1")
        record = dict(received_timestamp=time.time(), server=url.split("/")[2].split("?")[0], sha256=hashlib.sha256(raw).hexdigest(), binary=not isinstance(frame, str), payload=base64.b64encode(raw).decode("ascii"))
        with path.open("a") as f:
            os.chmod(path, 0o600)
            f.write(json.dumps(record, separators=(",", ":")) + "\n")
    except Exception as exc:
        print("RAW ARCHIVE ERROR:", type(exc).__name__, flush=True)
