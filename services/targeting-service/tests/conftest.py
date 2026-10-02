import os
import sys
import pytest
from unittest.mock import MagicMock, patch

os.environ["DATABASE_URL"] = "postgresql://test:test@localhost/test"
os.environ["AUTH_SERVICE_URL"] = "http://mock-auth:8001"

sys.modules.pop("app", None)

_mock_pool = MagicMock()
_patch = patch("psycopg2.pool.SimpleConnectionPool", return_value=_mock_pool)
_patch.start()

import app as _flask_app  # noqa: E402


@pytest.fixture
def client():
    _flask_app.app.config["TESTING"] = True
    with _flask_app.app.test_client() as c:
        yield c
