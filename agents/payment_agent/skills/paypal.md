# PayPal Payments

**Domain:** Payments
**Loaded when:** `paypalrestsdk`, `paypal-server-sdk`, or `@paypal/checkout-server-sdk` detected in `requirements.txt` or `package.json`

---

## When to Use

- Implementing one-time payments or subscriptions via PayPal Orders API v2.
- Writing or modifying PayPal webhook handlers (IPN or REST webhooks).
- Debugging an order that is stuck in `APPROVED` and never captured.
- Issuing refunds against a completed PayPal capture.

## When NOT to Use

- The project uses Stripe or MercadoPago exclusively — load the appropriate skill instead.
- Legacy NVP/SOAP API work — do not use the classic NVP API for new integrations. Use Orders API v2.

---

## Core Rules

1. **Follow the order lifecycle strictly: `CREATED` → `APPROVED` → `COMPLETED`.** Never fulfill before the status is `COMPLETED`. An `APPROVED` order has buyer intent but no captured funds.
2. **Always pass `PayPal-Request-Id` header on order creation.** Use a stable UUID derived from the internal order ID. This is PayPal's idempotency mechanism — the same request ID returns the existing order instead of creating a duplicate.
3. **Verify webhook authenticity before processing any event.** Call PayPal's `/v1/notifications/verify-webhook-signature` endpoint. Reject with `400` if the response `verification_status` is not `SUCCESS`.
4. **Capture must happen server-side.** After the buyer approves the order in the PayPal UI, your server calls `POST /v2/checkout/orders/{order_id}/capture`. Never rely on the client's redirect signal as confirmation of capture.
5. **Respond `200 OK` within 5 seconds from the webhook endpoint.** Offload all business logic to a background task.
6. **Make webhook handlers idempotent.** Store processed `event_id` values and skip duplicate deliveries.
7. **Use Sandbox credentials in every non-production environment.** Never let live PayPal credentials touch a development or staging database. Separate `.env` files per environment.
8. **Access tokens expire — never cache them beyond their `expires_in` window.** Always fetch a fresh token or use a cached token with expiry tracking. A stale token produces `401` errors silently.

---

## Order Lifecycle

```
CREATED (order created server-side)
  → APPROVED (buyer completes PayPal UI / login)
  → COMPLETED (server captures the funds)  ← Only fulfill here
  → VOIDED (order canceled before capture)
```

- `APPROVED` means the buyer consented — funds are NOT yet captured.
- `COMPLETED` means the capture succeeded and funds are reserved.
- Never fulfill on `APPROVED`. Always call capture and confirm `COMPLETED`.

---

## Code Patterns

### Access token helper (Python / httpx)

```python
# server/payments/paypal_client.py
import httpx
import time
from server.config import settings

_token_cache: dict = {"access_token": None, "expires_at": 0.0}

async def get_access_token() -> str:
    if _token_cache["access_token"] and time.time() < _token_cache["expires_at"] - 60:
        return _token_cache["access_token"]

    async with httpx.AsyncClient() as client:
        resp = await client.post(
            f"{settings.PAYPAL_BASE_URL}/v1/oauth2/token",
            data={"grant_type": "client_credentials"},
            auth=(settings.PAYPAL_CLIENT_ID, settings.PAYPAL_CLIENT_SECRET),
        )
        resp.raise_for_status()
        data = resp.json()
        _token_cache["access_token"] = data["access_token"]
        _token_cache["expires_at"] = time.time() + data["expires_in"]
        return data["access_token"]
```

### Creating an order

```python
import httpx
import uuid
from server.payments.paypal_client import get_access_token
from server.config import settings

async def create_order(
    amount_usd: str,  # e.g., "19.99"
    order_id: str,
) -> dict:
    token = await get_access_token()
    async with httpx.AsyncClient() as client:
        resp = await client.post(
            f"{settings.PAYPAL_BASE_URL}/v2/checkout/orders",
            json={
                "intent": "CAPTURE",
                "purchase_units": [
                    {
                        "reference_id": order_id,
                        "amount": {"currency_code": "USD", "value": amount_usd},
                    }
                ],
            },
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
                "PayPal-Request-Id": str(uuid.uuid5(uuid.NAMESPACE_DNS, order_id)),
            },
        )
        resp.raise_for_status()
        return resp.json()
```

### Capturing an approved order

```python
async def capture_order(paypal_order_id: str) -> dict:
    token = await get_access_token()
    async with httpx.AsyncClient() as client:
        resp = await client.post(
            f"{settings.PAYPAL_BASE_URL}/v2/checkout/orders/{paypal_order_id}/capture",
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
            },
        )
        resp.raise_for_status()
        data = resp.json()
        if data.get("status") != "COMPLETED":
            raise ValueError(f"Capture not COMPLETED: {data.get('status')}")
        return data
```

### Webhook handler with signature verification (FastAPI)

```python
# server/webhooks/paypal.py
import httpx
from fastapi import APIRouter, Request, HTTPException
from fastapi.responses import JSONResponse
from server.config import settings
from server.payments.paypal_client import get_access_token
from server.services.payments.fulfillment import handle_paypal_event

router = APIRouter(prefix="/webhooks", tags=["webhooks"])

async def _verify_paypal_webhook(request: Request, raw_body: bytes) -> bool:
    token = await get_access_token()
    headers = request.headers
    payload = {
        "auth_algo": headers.get("paypal-auth-algo"),
        "cert_url": headers.get("paypal-cert-url"),
        "transmission_id": headers.get("paypal-transmission-id"),
        "transmission_sig": headers.get("paypal-transmission-sig"),
        "transmission_time": headers.get("paypal-transmission-time"),
        "webhook_id": settings.PAYPAL_WEBHOOK_ID,
        "webhook_event": raw_body.decode("utf-8"),
    }
    async with httpx.AsyncClient() as client:
        resp = await client.post(
            f"{settings.PAYPAL_BASE_URL}/v1/notifications/verify-webhook-signature",
            json=payload,
            headers={"Authorization": f"Bearer {token}"},
        )
        data = resp.json()
        return data.get("verification_status") == "SUCCESS"


@router.post("/paypal")
async def paypal_webhook(request: Request) -> JSONResponse:
    raw_body = await request.body()

    if not await _verify_paypal_webhook(request, raw_body):
        raise HTTPException(status_code=400, detail="Invalid PayPal webhook signature")

    event = await request.json()
    request.state.background_tasks.add_task(handle_paypal_event, event)
    return JSONResponse({"status": "received"}, status_code=200)
```

### Idempotent event handler

```python
# server/services/payments/fulfillment.py
from server.db import get_pool

async def handle_paypal_event(event: dict) -> None:
    pool = await get_pool()
    event_id = event.get("id")

    existing = await pool.fetchrow(
        "SELECT id FROM processed_paypal_events WHERE event_id = $1", event_id
    )
    if existing:
        return

    event_type = event.get("event_type")
    if event_type == "PAYMENT.CAPTURE.COMPLETED":
        order_ref = event["resource"]["purchase_units"][0]["reference_id"]
        await _fulfill_order(pool, order_ref)

    elif event_type == "PAYMENT.CAPTURE.DENIED":
        order_ref = event["resource"]["purchase_units"][0]["reference_id"]
        await _mark_order_failed(pool, order_ref)

    await pool.execute(
        "INSERT INTO processed_paypal_events (event_id, processed_at) VALUES ($1, now())",
        event_id,
    )
```

### Issuing a refund

```python
async def refund_capture(
    capture_id: str,
    amount_usd: str | None = None,  # None = full refund
    order_id: str = "",
) -> dict:
    token = await get_access_token()
    body = {}
    if amount_usd:
        body = {"amount": {"currency_code": "USD", "value": amount_usd}}

    async with httpx.AsyncClient() as client:
        resp = await client.post(
            f"{settings.PAYPAL_BASE_URL}/v2/payments/captures/{capture_id}/refund",
            json=body,
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
                "PayPal-Request-Id": f"refund-{order_id}",
            },
        )
        resp.raise_for_status()
        return resp.json()
```

---

## Anti-Patterns

| Do NOT do this | Do this instead | Why |
|----------------|-----------------|-----|
| Fulfill the order when status is `APPROVED` | Call capture; fulfill only when status is `COMPLETED` | `APPROVED` means buyer intent only — no funds have been captured yet |
| Skip webhook signature verification | Call `/v1/notifications/verify-webhook-signature` and reject on `!= SUCCESS` | Unverified webhooks can be spoofed to trigger fake fulfillment |
| Trust the client-side redirect after PayPal approval | Call `GET /v2/checkout/orders/{id}` server-side to confirm `COMPLETED` | Redirect parameters can be tampered with; server state is authoritative |
| Create a new random `PayPal-Request-Id` on every call | Derive from order ID: `uuid5(NAMESPACE_DNS, order_id)` | Random IDs defeat idempotency — retries create duplicate orders |
| Cache access tokens indefinitely | Track `expires_in` and refresh 60 seconds before expiry | Stale tokens produce `401` errors that silently drop legitimate requests |
| Use live PayPal credentials in dev/test | Use Sandbox credentials; keep `.env.sandbox` separate | Live credentials in non-production environments risk real charges |
| Fulfill inside the webhook handler synchronously | Dispatch to a background task; respond `200` immediately | PayPal retries webhooks that don't receive `200` within 5 seconds, causing double fulfillment |

---

## Verification Checklist

Before marking a task as done, confirm:

- [ ] Orders are created with a deterministic `PayPal-Request-Id` header
- [ ] Capture is called server-side after approval — client redirect is not used as confirmation
- [ ] Order status is `COMPLETED` before triggering fulfillment
- [ ] Webhook handler calls `/v1/notifications/verify-webhook-signature` and rejects on failure
- [ ] Webhook handler responds `200 OK` immediately and dispatches to a background task
- [ ] Event handler checks `processed_paypal_events` before acting (idempotency)
- [ ] Access token caching respects `expires_in` with a 60-second safety buffer
- [ ] Sandbox credentials are used in all non-production environments
- [ ] `PAYPAL_CLIENT_ID`, `PAYPAL_CLIENT_SECRET`, and `PAYPAL_WEBHOOK_ID` are loaded from environment variables
- [ ] No PayPal credentials, order IDs, or payer details are logged in plaintext
