import os
import sys
import pytest
from unittest.mock import MagicMock, patch

os.environ["AWS_REGION"] = "us-east-1"
os.environ["AWS_SQS_URL"] = "https://sqs.us-east-1.amazonaws.com/123456789/test-queue"
os.environ["AWS_DYNAMODB_TABLE"] = "test-events"

sys.modules.pop("app", None)

_mock_sqs = MagicMock()
_mock_ddb = MagicMock()
_mock_session = MagicMock()
_mock_session.client.side_effect = lambda svc, **kw: _mock_sqs if svc == "sqs" else _mock_ddb
_mock_sqs.receive_message.return_value = {"Messages": []}

_patch_session = patch("boto3.Session", return_value=_mock_session)
_patch_thread = patch("threading.Thread")
_patch_session.start()
_patch_thread.start()

import app as _analytics_app  # noqa: E402


@pytest.fixture
def client():
    _analytics_app.app.config["TESTING"] = True
    with _analytics_app.app.test_client() as c:
        yield c
