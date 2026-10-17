import os
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def root():
    return {"status": "999 Signal Intelligence 2.0 backend online"}

@app.get("/health")
async def health():
    return {"status": "ok"}


import httpx

TWELVE_DATA_API_KEY = os.environ.get("TWELVE_DATA_API_KEY", "")

@app.get("/price/{symbol}")
async def price(symbol: str):
    if not TWELVE_DATA_API_KEY:
        return {"error": "TWELVE_DATA_API_KEY is not configured"}

    clean_symbol = symbol.replace("-", "/").upper()

    url = "https://api.twelvedata.com/price"
    params = {
        "symbol": clean_symbol,
        "apikey": TWELVE_DATA_API_KEY,
    }

    async with httpx.AsyncClient(timeout=10) as client:
        response = await client.get(url, params=params)
        data = response.json()

    return data

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", "10000"))
    uvicorn.run(app, host="0.0.0.0", port=port)
