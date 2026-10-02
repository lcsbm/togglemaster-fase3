from tests.conftest import client  # noqa: F401 — importado para registro do fixture


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.get_json() == {"status": "ok"}


def test_list_flags_requires_auth(client):
    r = client.get("/flags")
    assert r.status_code == 401


def test_create_flag_requires_auth(client):
    r = client.post("/flags", json={"name": "my-feature"})
    assert r.status_code == 401


def test_get_flag_by_name_requires_auth(client):
    r = client.get("/flags/my-feature")
    assert r.status_code == 401


def test_update_flag_requires_auth(client):
    r = client.put("/flags/my-feature", json={"is_enabled": True})
    assert r.status_code == 401


def test_delete_flag_requires_auth(client):
    r = client.delete("/flags/my-feature")
    assert r.status_code == 401
