"""Petite API Flask déployée sur Cloud Run via un pipeline Cloud Build."""
import os
import platform
from datetime import datetime, timezone

from flask import Flask, jsonify, request

app = Flask(__name__)

# Changez APP_VERSION (v1 -> v2) pour la démo de versioning / rollback.
APP_VERSION = "v1"
COMMIT_SHA = os.environ.get("COMMIT_SHA", "local")
REVISION = os.environ.get("K_REVISION", "local")  # injecté par Cloud Run

PRODUCTS = [
    {"id": 1, "name": "Clavier mécanique", "price": 89.90},
    {"id": 2, "name": "Souris sans fil", "price": 29.90},
    {"id": 3, "name": "Écran 27 pouces", "price": 249.00},
]


@app.get("/")
def index():
    return jsonify(
        message="Hello from Cloud Run CI/CD!",
        version=APP_VERSION,
        commit=COMMIT_SHA,
        revision=REVISION,
    )


@app.get("/health")
def health():
    return jsonify(status="ok", time=datetime.now(timezone.utc).isoformat())


@app.get("/version")
def version():
    return jsonify(
        version=APP_VERSION,
        commit=COMMIT_SHA,
        revision=REVISION,
        python=platform.python_version(),
    )


@app.get("/api/products")
def list_products():
    return jsonify(PRODUCTS)


@app.get("/api/products/<int:product_id>")
def get_product(product_id: int):
    product = next((p for p in PRODUCTS if p["id"] == product_id), None)
    if product is None:
        return jsonify(error="product not found"), 404
    return jsonify(product)


@app.post("/api/cart/total")
def cart_total():
    """Calcule le total d'un panier : {"items": [{"id": 1, "qty": 2}]}."""
    data = request.get_json(silent=True) or {}
    items = data.get("items")
    if not isinstance(items, list) or not items:
        return jsonify(error="'items' must be a non-empty list"), 400

    total = 0.0
    for item in items:
        product = next((p for p in PRODUCTS if p["id"] == item.get("id")), None)
        qty = item.get("qty", 1)
        if product is None:
            return jsonify(error=f"unknown product id {item.get('id')}"), 400
        if not isinstance(qty, int) or qty <= 0:
            return jsonify(error="'qty' must be a positive integer"), 400
        total += product["price"] * qty

    return jsonify(total=round(total, 2), currency="EUR")


@app.errorhandler(404)
def not_found(_):
    return jsonify(error="not found"), 404


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
