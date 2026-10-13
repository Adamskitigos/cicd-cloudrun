import pytest

from app.main import APP_VERSION, app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as c:
        yield c


def test_index(client):
    r = client.get("/")
    assert r.status_code == 200
    assert r.get_json()["version"] == APP_VERSION


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.get_json()["status"] == "ok"


def test_version(client):
    body = client.get("/version").get_json()
    assert {"version", "commit", "revision", "python"} <= body.keys()


def test_list_products(client):
    r = client.get("/api/products")
    assert r.status_code == 200
    assert len(r.get_json()) == 3


def test_get_product_ok(client):
    assert client.get("/api/products/1").get_json()["id"] == 1


def test_get_product_not_found(client):
    assert client.get("/api/products/999").status_code == 404


def test_cart_total(client):
    r = client.post("/api/cart/total", json={"items": [{"id": 1, "qty": 2}, {"id": 2}]})
    assert r.status_code == 200
    assert r.get_json()["total"] == 209.70


@pytest.mark.parametrize(
    "payload",
    [{}, {"items": []}, {"items": [{"id": 42}]}, {"items": [{"id": 1, "qty": 0}]}],
)
def test_cart_total_invalid(client, payload):
    assert client.post("/api/cart/total", json=payload).status_code == 400


def test_unknown_route(client):
    assert client.get("/nope").get_json()["error"] == "not found"
