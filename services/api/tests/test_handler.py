import json
import os
import sys
import unittest

import boto3
import moto

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))
import handler as handler_module
from handler import handler

TABLE_NAME = "spt-dev-items"


def _event(method, path, body=None, path_params=None):
    return {
        "requestContext": {
            "requestId": "test-request-id",
            "http": {"method": method},
        },
        "rawPath": path,
        "pathParameters": path_params or {},
        "body": json.dumps(body) if body is not None else None,
    }


@moto.mock_aws
class TestHandler(unittest.TestCase):
    def setUp(self):
        os.environ["TABLE_NAME"] = TABLE_NAME
        handler_module._dynamodb = None  # reset lazy client between tests

        dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
        dynamodb.create_table(
            TableName=TABLE_NAME,
            KeySchema=[{"AttributeName": "id", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "id", "AttributeType": "S"}],
            BillingMode="PAY_PER_REQUEST",
        )

    def test_health_returns_200(self):
        resp = handler(_event("GET", "/health"), None)
        self.assertEqual(resp["statusCode"], 200)
        self.assertEqual(json.loads(resp["body"]), {"status": "ok"})

    def test_create_item_returns_201(self):
        resp = handler(_event("POST", "/items", body={"id": "abc", "name": "demo"}), None)
        self.assertEqual(resp["statusCode"], 201)
        self.assertEqual(json.loads(resp["body"]), {"id": "abc"})

    def test_create_item_missing_id_returns_400(self):
        resp = handler(_event("POST", "/items", body={"name": "no-id"}), None)
        self.assertEqual(resp["statusCode"], 400)

    def test_create_item_invalid_json_returns_400(self):
        event = _event("POST", "/items")
        event["body"] = "not-json"
        resp = handler(event, None)
        self.assertEqual(resp["statusCode"], 400)

    def test_get_item_returns_200(self):
        handler(_event("POST", "/items", body={"id": "xyz", "name": "thing"}), None)
        handler_module._dynamodb = None  # reset so get uses same moto table
        resp = handler(_event("GET", "/items/xyz", path_params={"id": "xyz"}), None)
        self.assertEqual(resp["statusCode"], 200)
        body = json.loads(resp["body"])
        self.assertEqual(body["id"], "xyz")

    def test_get_item_not_found_returns_404(self):
        resp = handler(_event("GET", "/items/missing", path_params={"id": "missing"}), None)
        self.assertEqual(resp["statusCode"], 404)


if __name__ == "__main__":
    unittest.main()
