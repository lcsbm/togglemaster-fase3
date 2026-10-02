import json
from tests.conftest import client  # noqa: F401


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.get_json() == {"status": "ok"}


def test_process_message_valid(client):
    from tests.conftest import _mock_ddb, _mock_sqs
    import app as analytics_app

    message = {
        "MessageId": "msg-001",
        "ReceiptHandle": "rh-001",
        "Body": json.dumps({
            "user_id": "user-42",
            "flag_name": "dark-mode",
            "result": True,
            "timestamp": "2026-01-01T00:00:00Z",
        }),
    }

    analytics_app.process_message(message)

    _mock_ddb.put_item.assert_called_once()
    _mock_sqs.delete_message.assert_called_once_with(
        QueueUrl=analytics_app.SQS_QUEUE_URL,
        ReceiptHandle="rh-001",
    )


def test_process_message_invalid_json(client):
    from tests.conftest import _mock_ddb, _mock_sqs
    import app as analytics_app

    _mock_ddb.reset_mock()
    _mock_sqs.reset_mock()

    bad_message = {
        "MessageId": "msg-bad",
        "ReceiptHandle": "rh-bad",
        "Body": "not-json",
    }

    analytics_app.process_message(bad_message)

    _mock_ddb.put_item.assert_not_called()
    _mock_sqs.delete_message.assert_not_called()
