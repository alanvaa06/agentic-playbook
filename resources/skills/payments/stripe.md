# Stripe Payments

**Domain:** Payments
**Loaded when:** `stripe` detected in `requirements.txt` or `package.json`

---

## When to Use

- Implementing one-time payments, subscriptions, or refunds via Stripe.
- Writing or modifying Stripe webhook handlers.
- Debugging a failed PaymentIntent or unexpected payment state.
- Setting up Stripe checkout sessions or Payment Element integrations.

## When NOT to Use

- The project uses PayPal or MercadoPago exclusively — load the appropriate skill instead.
- Purely frontend Stripe Elements setup with no server-side logic involved.

---

## Core Rules

1. **Always pass an `idempotency_key` on every PaymentIntent creation call.** Derive it from the internal order ID (e.g., `f"order-{order_id}"`). Network retries and user double-clicks must produce the same intent, not a duplicate charge.
2. **Verify the webhook signature before reading or acting on any payload.** Use `stripe.Webhook.construct_event(raw_body, sig_header, settings.STRIPE_WEBHOOK_SECRET)`. Reject with `400` if it raises `stripe.error.SignatureVerificationError`.
3. **Read the raw request body before any JSON parsing.** FastAPI's `await request.body()` must be called before any middleware or dependency deserializes the payload — signature verification requires the original byte sequence.
4. **Respond `200 OK` within 5 seconds.** Dispatch all business logic (fulfillment, emails, database writes) to a background task immediately. Never block the webhook response on slow operations.
5. **Make webhook handlers idempotent.** Check whether `event.id` has already been processed in your database before acting. Stripe may deliver the same event multiple times.
6. **Handle all PaymentIntent states explicitly.** Do not assume `succeeded` — write explicit branches for `requires_action` (3DS), `requires_payment_method`, `processing`, `canceled`, and `payment_failed`.
7. **Confirm payment status server-side before fulfilling.** After the client reports success, call `stripe.PaymentIntent.retrieve(payment_intent_id)` and check `status == "succeeded"`. Never trust the client-side result alone.
8. **Never store raw card data.** Use Stripe Elements or Payment Links for card capture. Store only the `PaymentIntent.id` or `Customer.id` in your database.

---

## PaymentIntent Lifecycle

```
requires_payment_method → requires_confirmation → requires_action → processing → succeeded
                                                                               → payment_failed
                                                                               → canceled
```

- `requires_action` means the customer must complete 3D Secure — surface the `next_action` URL to the client.
- `processing` means the payment is async (e.g., bank transfer) — do not fulfill yet; wait for the `payment_intent.succeeded` webhook.
- `canceled` and `payment_failed` are terminal — do not retry without creating a new PaymentIntent.

---

## Code Patterns

### Creating a PaymentIntent with idempotency key

```python
# server/payments/stripe_client.py
import stripe
from server.config import settings

stripe.api_key = settings.STRIPE_SECRET_KEY

def create_payment_intent(
    amount_cents: int,
    currency: str,
    order_id: str,
    customer_id: str | None = None,
) -> stripe.PaymentIntent:
    return stripe.PaymentIntent.create(
        amount=amount_cents,
        currency=currency.lower(),
        customer=customer_id,
        metadata={"order_id": order_id},
        idempotency_key=f"order-{order_id}",  # deterministic, not random
    )
```

### Webhook handler (FastAPI)

```python
# server/webhooks/stripe.py
import stripe
from fastapi import APIRouter, Request, HTTPException
from fastapi.responses import JSONResponse
from server.config import settings
from server.services.payments.fulfillment import handle_stripe_event

router = APIRouter(prefix="/webhooks", tags=["webhooks"])

@router.post("/stripe")
async def stripe_webhook(request: Request) -> JSONResponse:
    raw_body = await request.body()   # MUST be read before any parsing
    sig_header = request.headers.get("stripe-signature")

    try:
        event = stripe.Webhook.construct_event(
            payload=raw_body,
            sig_header=sig_header,
            secret=settings.STRIPE_WEBHOOK_SECRET,
        )
    except stripe.error.SignatureVerificationError:
        raise HTTPException(status_code=400, detail="Invalid Stripe signature")

    # Respond immediately; handle event in background
    request.state.background_tasks.add_task(handle_stripe_event, event)
    return JSONResponse({"status": "received"}, status_code=200)
```

### Idempotent event handler

```python
# server/services/payments/fulfillment.py
import stripe
from server.db import get_pool

async def handle_stripe_event(event: stripe.Event) -> None:
    pool = await get_pool()

    # Idempotency check — skip if already processed
    existing = await pool.fetchrow(
        "SELECT id FROM processed_stripe_events WHERE event_id = $1",
        event.id,
    )
    if existing:
        return

    if event.type == "payment_intent.succeeded":
        payment_intent = event.data.object
        await _fulfill_order(pool, payment_intent.metadata["order_id"])

    elif event.type == "payment_intent.payment_failed":
        payment_intent = event.data.object
        await _mark_order_failed(pool, payment_intent.metadata["order_id"])

    # Record as processed
    await pool.execute(
        "INSERT INTO processed_stripe_events (event_id, processed_at) VALUES ($1, now())",
        event.id,
    )
```

### Server-side payment confirmation

```python
# server/services/payments/stripe_client.py

async def confirm_payment_succeeded(payment_intent_id: str) -> bool:
    intent = stripe.PaymentIntent.retrieve(payment_intent_id)
    return intent.status == "succeeded"
```

### Refund

```python
def issue_refund(
    payment_intent_id: str,
    amount_cents: int | None = None,  # None = full refund
    order_id: str = "",
) -> stripe.Refund:
    return stripe.Refund.create(
        payment_intent=payment_intent_id,
        amount=amount_cents,
        idempotency_key=f"refund-{order_id}",
    )
```

### Local webhook testing

```bash
# Install Stripe CLI, then forward events to your local server
stripe listen --forward-to localhost:8000/webhooks/stripe

# Trigger a specific event for manual testing
stripe trigger payment_intent.succeeded
```

---

## Anti-Patterns

| Do NOT do this | Do this instead | Why |
|----------------|-----------------|-----|
| `stripe.PaymentIntent.create(amount=..., currency=...)` with no `idempotency_key` | Pass `idempotency_key=f"order-{order_id}"` | Network retries or user double-clicks create duplicate charges |
| Parse `await request.json()` before verifying the signature | Call `await request.body()` first, then verify | JSON parsing consumes the raw body; signature verification will fail with a cryptic error |
| Fulfill the order inside the webhook handler synchronously | Use `background_tasks.add_task(handle_stripe_event, event)` | Slow handlers time out; Stripe retries the event, causing double fulfillment |
| Check `if event.type == "payment_intent.succeeded"` without an idempotency check | Query `processed_stripe_events` first | Stripe delivers the same event multiple times on retry; orders get fulfilled twice |
| Trust the client's `paymentIntent.status == "succeeded"` | Call `stripe.PaymentIntent.retrieve()` server-side | Client-side state is unverified and can be spoofed |
| Handle only `payment_intent.succeeded` | Write branches for `requires_action`, `processing`, and `payment_failed` | Missing `requires_action` silently abandons 3DS-required payments |
| Return `stripe.error.StripeError` details in the HTTP response | Log server-side; return `{"error": "payment_failed", "detail": "..."}` | Raw Stripe errors expose internal payment details and decline codes |

---

## Verification Checklist

Before marking a task as done, confirm:

- [ ] Every `PaymentIntent.create()` call includes a deterministic `idempotency_key`
- [ ] Webhook handler reads raw body with `await request.body()` before any JSON parsing
- [ ] `stripe.Webhook.construct_event()` is called and raises are caught with a `400` response
- [ ] Webhook handler responds `200 OK` immediately and dispatches processing to a background task
- [ ] Event handler checks `processed_stripe_events` before acting (idempotency)
- [ ] All PaymentIntent states are handled explicitly (including `requires_action` and `payment_failed`)
- [ ] Payment status is confirmed server-side via `PaymentIntent.retrieve()` before fulfillment
- [ ] No raw card data is stored — only `payment_intent_id` or `customer_id`
- [ ] `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET` are loaded from environment variables
- [ ] Webhook tested locally with `stripe listen` and `stripe trigger`
