import json
import logging
import os
import time
import uuid

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

_dynamodb = None


def _get_table():
    global _dynamodb
    if _dynamodb is None:
        _dynamodb = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])
    return _dynamodb


def _response(status_code, body, request_id):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "X-Request-Id": request_id,
        },
        "body": json.dumps(body),
    }


def _log(route, status_code, start, request_id):
    logger.info(json.dumps({
        "route": route,
        "status_code": status_code,
        "latency_ms": round((time.time() - start) * 1000, 2),
        "request_id": request_id,
    }))


def handler(event, context):
    start = time.time()
    request_id = (
        event.get("requestContext", {}).get("requestId") or str(uuid.uuid4())
    )
    method = event.get("requestContext", {}).get("http", {}).get("method", "")
    path = event.get("rawPath", "")
    path_params = event.get("pathParameters") or {}

    # GET /health
    if method == "GET" and path == "/health":
        resp = _response(200, {"status": "ok"}, request_id)
        _log("GET /health", 200, start, request_id)
        return resp

    # POST /items
    if method == "POST" and path == "/items":
        try:
            body = json.loads(event.get("body") or "{}")
        except (json.JSONDecodeError, TypeError):
            resp = _response(400, {"error": "Invalid JSON"}, request_id)
            _log("POST /items", 400, start, request_id)
            return resp

        item_id = body.get("id")
        if not item_id or not isinstance(item_id, str):
            resp = _response(400, {"error": "Missing or invalid 'id' field"}, request_id)
            _log("POST /items", 400, start, request_id)
            return resp

        _get_table().put_item(Item=body)
        resp = _response(201, {"id": item_id}, request_id)
        _log("POST /items", 201, start, request_id)
        return resp

    # GET /items/{id}
    if method == "GET" and path.startswith("/items/"):
        item_id = path_params.get("id") or path.split("/items/", 1)[-1]
        result = _get_table().get_item(Key={"id": item_id})
        item = result.get("Item")
        if item is None:
            resp = _response(404, {"error": "Item not found"}, request_id)
            _log("GET /items/{id}", 404, start, request_id)
            return resp
        resp = _response(200, item, request_id)
        _log("GET /items/{id}", 200, start, request_id)
        return resp

    # Fallback
    resp = _response(404, {"error": "Not found"}, request_id)
    _log(f"{method} {path}", 404, start, request_id)
    return resp
