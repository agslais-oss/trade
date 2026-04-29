import requests
import json

BASE = "https://paper-api.alpaca.markets/v2"
HEADERS = {
    "APCA-API-KEY-ID":     "PK3FGWFX4S6WAR5KGXMJ6KXQ6I",
    "APCA-API-SECRET-KEY": "FtotUvj5Ee9ZTeG7HCzE1mKhDGXHAcfJx2cGZUr6DyQ2",
    "Content-Type":        "application/json",
}
ORDER = {
    "symbol":        "AAPL",
    "qty":           "1",
    "side":          "buy",
    "type":          "market",
    "time_in_force": "day",
}

resp = requests.post(f"{BASE}/orders", headers=HEADERS, json=ORDER)
print(json.dumps(resp.json(), indent=2))
