from tests.conftest import client  # noqa: F401


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.get_json() == {"status": "ok"}


def test_create_rule_requires_auth(client):
    r = client.post("/rules", json={"flag_name": "my-flag", "rules": {"type": "PERCENTAGE", "value": 50}})
    assert r.status_code == 401


def test_get_rule_requires_auth(client):
    r = client.get("/rules/my-flag")
    assert r.status_code == 401


def test_update_rule_requires_auth(client):
    r = client.put("/rules/my-flag", json={"is_enabled": False})
    assert r.status_code == 401


def test_delete_rule_requires_auth(client):
    r = client.delete("/rules/my-flag")
    assert r.status_code == 401
