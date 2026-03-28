# MercadoPago Payments

**Domain:** Payments
**Loaded when:** `mercadopago` detected in `requirements.txt` or `package.json`

---

## When to Use

- Implementing one-time payments or recurring charges via MercadoPago Checkout API.
- Writing or modifying MercadoPago IPN (Instant Payment Notification) webhook handlers.
- Debugging a payment stuck in `pending` or `in_process` status.
- Issuing refunds via the MercadoPago Refunds API.

## When NOT to Use

- The project uses Stripe or PayPal exclusively — load the appropriate skill instead.
- Client-only MercadoPago Bricks setup with no server-side logic.

---

## Core Rules

1. **Always pass `x-idempotency-key` header on every payment creation call.** Derive it from the internal order ID. Retries without this header create duplicate charges.
2. **Verify the IPN webhook `x-signature` header before processing any notification.** Use HMAC-SHA256 with `MP_WEBHOOK_SECRET` as the key and the concatenated `id` + `ts` fields as the message. Reject with `400` if verification fails.
3. **Never fulfill on `pending` or `in_process` status.** These are intermediate states. Fulfill only when the payment status returned by `GET /v1/payments/{id}` is `approved`.
4. **Always confirm payment status server-side via the MercadoPago API after receiving an IPN notification.** The IPN body contains only a `data.id` — never rely on it alone. Fetch the full payment resource to get the canonical status.
5. **Respond `200 OK` immediately from the IPN endpoint.** MercadoPago retries notifications every 15 minutes for up to 3 days if it does not receive `200`. Offload all logic to a background task.
6. **Make IPN handlers idempotent.** Store processed `payment_id` values and skip duplicates.
7. **Never hardcode country-specific URLs or credentials.** MercadoPago has different base URLs and access tokens per country. Always load `MP_ACCESS_TOKEN` from environment variables. The SDK routes to the correct country automatically based on the token.
8. **Use Checkout Bricks or Checkout Pro for card capture.** Never accept raw card numbers on your server. The browser sends a tokenized `card_token` to your server, which then calls the Payments API.

---

## Payment Status Reference

| Status | Meaning | Fulfill? |
|--------|---------|---------|
| `pending` | Awaiting payment confirmation (e.g., boleto not yet paid) | No |
| `in_process` | Under review by MercadoPago's fraud engine | No |
| `approved` | Payment confirmed and funds reserved | **Yes** |
| `rejected` | Payment declined | No — notify user |
| `cancelled` | Expired or cancelled by buyer | No |
| `refunded` | Full refund issued | No |
| `charged_back` | Chargeback filed by buyer | No — initiate dispute flow |

---

## Code Patterns

### SDK initialization

```python
# server/payments/mp_client.py
import mercadopago
from server.config import settings

def get_mp_sdk() -> mercadopago.SDK:
    return mercadopago.SDK(settings.MP_ACCESS_TOKEN)
```

### Creating a payment from a card token

```python
# server/payments/mp_client.py
import mercadopago
from server.config import settings

def create_payment(
    card_token: str,
    amount: float,
    installments: int,
    email: str,
    order_id: str,
) -> dict:
    sdk = get_mp_sdk()
    payment_data = {
        "transaction_amount": amount,
        "token": card_token,
        "installments": installments,
        "payment_method_id": "visa",  # derived from Bricks/front-end card type
        "payer": {"email": email},
        "external_reference": order_id,
        "notification_url": settings.MP_WEBHOOK_URL,
    }
    response = sdk.payment().create(
        payment_data,
        request_options=mercadopago.config.RequestOptions(
            custom_headers={"x-idempotency-key": f"order-{order_id}"}
        ),
    )
    return response["response"]
```

### Creating a Preference (Checkout Pro / redirect flow)

```python
def create_preference(
    title: str,
    unit_price: float,
    quantity: int,
    order_id: str,
    payer_email: str,
) -> dict:
    sdk = get_mp_sdk()
    preference_data = {
        "items": [
            {
                "title": title,
                "quantity": quantity,
                "unit_price": unit_price,
            }
        ],
        "payer": {"email": payer_email},
        "external_reference": order_id,
        "notification_url": settings.MP_WEBHOOK_URL,
        "back_urls": {
            "success": settings.MP_SUCCESS_URL,
            "failure": settings.MP_FAILURE_URL,
            "pending": settings.MP_PENDING_URL,
        },
        "auto_return": "approved",
    }
    response = sdk.preference().create(preference_data)
    return response["response"]
```

### IPN webhook handler with signature verification (FastAPI)

```python
# server/webhooks/mercadopago.py
import hashlib
import hmac
from fastapi import APIRouter, Request, HTTPException
from fastapi.responses import JSONResponse
from server.config import settings
from server.services.payments.fulfillment import handle_mp_payment

router = APIRouter(prefix="/webhooks", tags=["webhooks"])


def _verify_mp_signature(request: Request, body: bytes) -> bool:
    """
    MercadoPago signs webhooks using HMAC-SHA256.
    The signed message is: "id:{data.id};request-id:{x-request-id};ts:{ts};"
    All values come from the query string and headers of the IPN request.
    """
    ts = request.query_params.get("ts", "")
    data_id = request.query_params.get("data.id", "")
    request_id = request.headers.get("x-request-id", "")

    manifest = f"id:{data_id};request-id:{request_id};ts:{ts};"
    expected = hmac.new(
        settings.MP_WEBHOOK_SECRET.encode(),
        manifest.encode(),
        hashlib.sha256,
    ).hexdigest()

    received = request.headers.get("x-signature", "").split(",")
    received_hash = next(
        (part.split("=")[1] for part in received if part.strip().startswith("v1=")),
        "",
    )
    return hmac.compare_digest(expected, received_hash)


@router.post("/mercadopago")
async def mercadopago_webhook(request: Request) -> JSONResponse:
    raw_body = await request.body()

    if not _verify_mp_signature(request, raw_body):
        raise HTTPException(status_code=400, detail="Invalid MercadoPago signature")

    event = await request.json()
    topic = event.get("type")

    if topic == "payment":
        payment_id = event["data"]["id"]
        request.state.background_tasks.add_task(handle_mp_payment, payment_id)

    return JSONResponse({"status": "received"}, status_code=200)
```

### Idempotent payment handler — fetch and confirm server-side

```python
# server/services/payments/fulfillment.py
from server.payments.mp_client import get_mp_sdk
from server.db import get_pool

async def handle_mp_payment(payment_id: str) -> None:
    pool = await get_pool()

    # Idempotency check
    existing = await pool.fetchrow(
        "SELECT id FROM processed_mp_payments WHERE payment_id = $1", payment_id
    )
    if existing:
        return

    # Always fetch the full payment resource — never trust IPN body alone
    sdk = get_mp_sdk()
    response = sdk.payment().get(payment_id)
    payment = response["response"]

    status = payment.get("status")
    order_id = payment.get("external_reference")

    if status == "approved":
        await _fulfill_order(pool, order_id)
    elif status == "rejected":
        await _mark_order_failed(pool, order_id)
    # pending / in_process: do nothing, wait for next IPN

    await pool.execute(
        "INSERT INTO processed_mp_payments (payment_id, status, processed_at) "
        "VALUES ($1, $2, now())",
        payment_id,
        status,
    )
```

### Issuing a refund

```python
def issue_refund(
    payment_id: str,
    amount: float | None = None,  # None = full refund
    order_id: str = "",
) -> dict:
    sdk = get_mp_sdk()
    refund_data = {}
    if amount is not None:
        refund_data["amount"] = amount

    response = sdk.refund().create(
        payment_id,
        refund_data,
        request_options=mercadopago.config.RequestOptions(
            custom_headers={"x-idempotency-key": f"refund-{order_id}"}
        ),
    )
    return response["response"]
```

---

## Anti-Patterns

| Do NOT do this | Do this instead | Why |
|----------------|-----------------|-----|
| Fulfill the order when `payment.status == "pending"` | Fulfill only on `"approved"` | `pending` means no funds captured; boletos and transfers may never complete |
| Trust the IPN body's `status` field | Fetch `GET /v1/payments/{id}` server-side and use its `status` | IPN body is minimal and unverified; the API response is authoritative |
| Skip `x-signature` verification | Compute HMAC-SHA256 of `id + request-id + ts` and compare with `compare_digest` | Unverified IPN events can be spoofed to trigger fake fulfillment |
| Create payments without `x-idempotency-key` | Pass `x-idempotency-key: order-{order_id}` on every creation call | Without idempotency, network retries and user double-clicks cause duplicate charges |
| Fulfill synchronously inside the IPN handler | Dispatch to background task; respond `200` immediately | MercadoPago retries for 3 days on non-200 responses, causing repeated processing |
| Hardcode `MP_ACCESS_TOKEN` for a specific country | Load from `settings.MP_ACCESS_TOKEN` | Production tokens are country-specific and must never appear in source code |
| Accept raw card numbers in your API | Use MercadoPago Bricks to tokenize client-side; receive only `card_token` | Raw card data on your server is a PCI DSS Level 1 violation |
| Log the full IPN request body | Log only `payment_id` and `status` | Full IPN bodies may contain payer PII (email, CPF, address) |

---

## Verification Checklist

Before marking a task as done, confirm:

- [ ] Every payment creation call includes `x-idempotency-key` derived from the order ID
- [ ] IPN webhook verifies `x-signature` using HMAC-SHA256 and rejects on mismatch
- [ ] IPN handler responds `200 OK` immediately and dispatches processing to a background task
- [ ] Payment status is fetched via `GET /v1/payments/{id}` before any fulfillment decision
- [ ] Fulfillment only triggers on `status == "approved"` — never on `pending` or `in_process`
- [ ] IPN handler checks `processed_mp_payments` for duplicates before acting
- [ ] `MP_ACCESS_TOKEN` and `MP_WEBHOOK_SECRET` are loaded from environment variables
- [ ] Card capture uses MercadoPago Bricks — no raw card numbers reach the server
- [ ] Refunds include `x-idempotency-key` to prevent duplicate refunds on retry
- [ ] No payer PII (email, CPF, address) is logged in plaintext
