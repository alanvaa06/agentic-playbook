# Forms & Validation

**Domain:** Frontend
**Loaded when:** `react-hook-form` and `zod` detected in `package.json`

---

## When to Use

- Building any form (login, signup, settings, checkout, filters).
- Adding client-side validation to user inputs.
- Handling form submission (sync or async).

## When NOT to Use

- Search bars or single-input interactions that don't require validation — a simple `useState` is acceptable here.
- Server-side validation logic (that belongs to the backend agent).

---

## Core Rules

1. **All forms use React Hook Form.** Never manage form field values with individual `useState` calls. React Hook Form provides uncontrolled inputs by default, which avoids unnecessary re-renders.
2. **All validation schemas use Zod.** Connect them via `@hookform/resolvers/zod` using `zodResolver`.
3. **Zod schemas live in `client/src/schemas/`.** One file per domain (e.g., `auth.ts`, `checkout.ts`, `settings.ts`). Never define schemas inline inside component files.
4. **Infer TypeScript types from Zod schemas** using `z.infer<typeof schema>`. Never duplicate the type manually — the schema is the single source of truth.
5. **Use `FormField` + `FormItem` + `FormMessage` from Shadcn** when available. These components wire up `react-hook-form`'s `Controller` with accessible labels and error display.
6. **Always handle the loading state during async submission.** Disable the submit button and show a spinner while the request is in flight to prevent double-submission.
7. **Display field-level errors, not just form-level toasts.** Users need to see which specific field failed validation and why.
8. **Use `mode: "onBlur"` or `mode: "onTouched"`** for validation timing. The default `mode: "onSubmit"` only shows errors after the first submit, which feels unresponsive.

---

## Code Patterns

### Zod schema in a dedicated file

```tsx
// client/src/schemas/auth.ts
import { z } from "zod";

export const loginSchema = z.object({
  email: z.string().email("Please enter a valid email address"),
  password: z.string().min(8, "Password must be at least 8 characters"),
});

export type LoginFormData = z.infer<typeof loginSchema>;
```

### Form component with React Hook Form + Zod

```tsx
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { loginSchema, type LoginFormData } from "@/schemas/auth";

export function LoginForm() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginFormData>({
    resolver: zodResolver(loginSchema),
    mode: "onBlur",
  });

  async function onSubmit(data: LoginFormData) {
    await axios.post("/api/auth/login", data);
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="flex flex-col gap-4">
      <div>
        <label htmlFor="email">Email</label>
        <input id="email" type="email" {...register("email")} />
        {errors.email && <p className="text-sm text-destructive">{errors.email.message}</p>}
      </div>

      <div>
        <label htmlFor="password">Password</label>
        <input id="password" type="password" {...register("password")} />
        {errors.password && <p className="text-sm text-destructive">{errors.password.message}</p>}
      </div>

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? "Signing in..." : "Sign In"}
      </button>
    </form>
  );
}
```

### Complex schema with conditional fields

```tsx
// client/src/schemas/checkout.ts
import { z } from "zod";

export const checkoutSchema = z.object({
  paymentMethod: z.enum(["card", "paypal"]),
  cardNumber: z.string().optional(),
  cardExpiry: z.string().optional(),
}).refine(
  (data) => {
    if (data.paymentMethod === "card") {
      return !!data.cardNumber && !!data.cardExpiry;
    }
    return true;
  },
  { message: "Card details are required for card payment", path: ["cardNumber"] }
);

export type CheckoutFormData = z.infer<typeof checkoutSchema>;
```

### Async validation (e.g., checking username availability)

```tsx
const signupSchema = z.object({
  username: z
    .string()
    .min(3, "Username must be at least 3 characters")
    .regex(/^[a-z0-9_]+$/, "Only lowercase letters, numbers, and underscores"),
  email: z.string().email(),
  password: z.string().min(8),
});
```

```tsx
export function SignupForm() {
  const form = useForm<z.infer<typeof signupSchema>>({
    resolver: zodResolver(signupSchema),
    mode: "onBlur",
  });

  async function onSubmit(data: z.infer<typeof signupSchema>) {
    try {
      await axios.post("/api/auth/signup", data);
    } catch (error) {
      if (axios.isAxiosError(error) && error.response?.status === 409) {
        form.setError("username", { message: "Username is already taken" });
      }
    }
  }

  return <form onSubmit={form.handleSubmit(onSubmit)}>{/* fields */}</form>;
}
```

---

## Anti-Patterns

| Do NOT do this | Do this instead | Why |
|----------------|-----------------|-----|
| `const [email, setEmail] = useState("")` for form fields | `useForm` + `register("email")` | useState per field causes re-renders on every keystroke and loses RHF's built-in error handling |
| Inline Zod schema inside the component | Define in `client/src/schemas/` and import | Schemas are reusable (e.g., shared between form and API route); inline schemas bloat components |
| `type FormData = { email: string; password: string }` | `type FormData = z.infer<typeof schema>` | Manual types drift from the schema, creating silent type mismatches |
| Submit button without `disabled={isSubmitting}` | Always disable during submission | Users double-click submit, causing duplicate API calls |
| Toast-only error display (no field-level errors) | Show error under each invalid field | Users cannot tell which field failed without scrolling or re-reading the toast |
| `mode: "onSubmit"` (default) | `mode: "onBlur"` or `mode: "onTouched"` | Validation only triggers after first submit, which feels unresponsive |

---

## Verification Checklist

Before marking a task as done, confirm:

- [ ] All forms use `useForm` from `react-hook-form` — no `useState` for field values
- [ ] All schemas live in `client/src/schemas/`, not inline
- [ ] TypeScript types are inferred from Zod (`z.infer<typeof schema>`) — no manual duplicates
- [ ] Submit button is disabled while `isSubmitting` is true
- [ ] Field-level error messages are visible next to their input
- [ ] Validation mode is `onBlur` or `onTouched`, not the default `onSubmit`
