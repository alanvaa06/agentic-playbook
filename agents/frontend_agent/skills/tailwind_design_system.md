# Tailwind Design System

**Domain:** Frontend
**Loaded when:** `tailwindcss` detected in `package.json`

---

## When to Use

- Creating or modifying any component that has visual styling.
- Adding new colors, spacing, or typography tokens.
- Implementing responsive layouts or dark mode support.

## When NOT to Use

- Pure logic changes with no visual impact (e.g., refactoring a custom hook).
- 3D rendering inside `<Canvas>` — Three.js handles its own materials, not Tailwind.

---

## Core Rules

1. **`client/src/index.css` is the single source of truth** for all design tokens. All `@theme` overrides, CSS variables, and base styles live here.
2. **Colors use `oklch()` color space** defined as CSS variables. Reference them via Tailwind's variable syntax (e.g., `bg-primary`, `text-muted-foreground`). NEVER hardcode `hex`, `rgb()`, `hsl()`, or raw `oklch()` values in component files.
3. **Dark mode is the default.** The project uses a dark-first approach ("Deep dark" background with Blue/Cyan gradients). NEVER add `dark:` variants unless the component explicitly supports a light mode toggle feature.
4. **Use `cn()` for all dynamic class merging.** The `cn()` utility combines `clsx` (conditional classes) with `tailwind-merge` (conflict resolution). It lives in `client/src/lib/utils.ts`.
5. **Use CVA (`class-variance-authority`) for component variants.** Any component with more than one visual state (size, color, variant) must define variants via CVA, not ternary expressions in `className`.
6. **Typography uses `Inter` as the primary font**, loaded via CSS variables. Use the project's font stack variable, not `font-sans` directly.
7. **Tailwind v4 uses CSS-first configuration.** Configuration happens in `index.css` via `@theme`, not in a `tailwind.config.js` file. Do not create or modify `tailwind.config.js`.
8. **Responsive design uses mobile-first breakpoints** (`sm:`, `md:`, `lg:`, `xl:`, `2xl:`). Write base styles for mobile, then layer up.
9. **All `@keyframes` use `oklch()` values** and are defined in `client/src/index.css`. Expose them to Tailwind via `@utility` so they are usable as classes. Never define keyframes in component files or use `hex`/`rgb` inside keyframe blocks.
10. **Use `clamp()` for hero and display typography** that must scale fluidly between mobile and desktop. Never use fixed pixel values for headings. The pattern is `clamp(min, preferred, max)` where `preferred` is a viewport-relative unit.

---

## Code Patterns

### The `cn()` utility

```tsx
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

### CVA component with variants

```tsx
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const badgeVariants = cva(
  "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold transition-colors",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground",
        secondary: "bg-secondary text-secondary-foreground",
        destructive: "bg-destructive text-destructive-foreground",
        outline: "border border-input bg-background",
      },
    },
    defaultVariants: {
      variant: "default",
    },
  }
);

interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {}

export function Badge({ className, variant, ...props }: BadgeProps) {
  return <div className={cn(badgeVariants({ variant }), className)} {...props} />;
}
```

### Using design tokens from CSS variables

```tsx
// Correct — references the design system
<div className="bg-background text-foreground border-border">
  <p className="text-muted-foreground">Secondary text</p>
</div>
```

### Responsive layout (mobile-first)

```tsx
<div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
  {items.map((item) => (
    <Card key={item.id} {...item} />
  ))}
</div>
```

### Keyframe color animations in `index.css`

Define scroll-triggered or entrance color animations as `@keyframes` in the CSS source of truth, using `oklch()` values. Expose them via `@utility` for use as Tailwind classes.

```css
/* client/src/index.css — below @theme block */
@keyframes color-transition {
  0%   { color: oklch(0.90 0 0) }
  30%  { color: oklch(0.92 0.30 128) }
  100% { color: oklch(0.22 0.04 180) }
}

@utility animate-color-transition {
  animation: color-transition 0.5s ease-out forwards;
}
```

Usage in a component:

```tsx
<strong className="animate-color-transition">$2.4M saved</strong>
```

### Fluid typography with `clamp()`

Use `clamp()` for display and hero headings so they scale smoothly without breakpoint jumps. Define fluid sizes as CSS variables in `@theme` or apply them directly.

```css
/* client/src/index.css — inside @theme */
@theme {
  --font-size-display: clamp(2.5rem, 5vw + 1rem, 5rem);
  --font-size-heading: clamp(1.75rem, 3vw + 0.5rem, 3rem);
}
```

Usage in a component:

```tsx
<h1 className="text-[length:var(--font-size-display)] font-bold leading-tight">
  Ship faster
</h1>
```

For one-off cases where a CSS variable is not warranted:

```tsx
<h2 style={{ fontSize: "clamp(1.5rem, 2.5vw + 0.5rem, 2.5rem)" }}>
  Section title
</h2>
```

---

## Anti-Patterns

| Do NOT do this | Do this instead | Why |
|----------------|-----------------|-----|
| `className="text-[#1a1a2e]"` | `className="text-foreground"` | Hardcoded colors bypass the design system and break theme consistency |
| `className={active ? "bg-blue-500" : "bg-gray-500"}` | Use CVA with a `variant` prop | Ternaries in className grow unreadable and conflict with tailwind-merge |
| `className={"px-4 " + "py-2 " + extraClass}` | `className={cn("px-4 py-2", extraClass)}` | String concatenation cannot resolve Tailwind conflicts (e.g., `px-4` vs `px-6`) |
| `dark:bg-gray-900` on every component | Omit it — dark is the default | Adds visual noise and breaks if the theme strategy changes |
| Creating `tailwind.config.js` | Use `@theme` in `index.css` | Tailwind v4 uses CSS-first configuration; a JS config creates a parallel source of truth |
| `style={{ fontFamily: 'Inter' }}` | Use the CSS variable font stack via classes | Inline styles bypass the design system and don't respond to theme changes |
| `@keyframes` with `color: #abff02` | Use `color: oklch(0.92 0.30 128)` | Hex/rgb in keyframes breaks the oklch-only color convention |
| `@keyframes` defined in a component `.module.css` | Define in `client/src/index.css` | Keyframes must live in the single source of truth alongside `@theme` |
| `className="text-6xl"` for a hero heading | Use `clamp()` via CSS variable or inline style | Fixed sizes cause text to overflow on mobile or look tiny on large screens |

---

## Verification Checklist

Before marking a task as done, confirm:

- [ ] No hardcoded color values (`hex`, `rgb`, `hsl`, `oklch`) in any component file
- [ ] All dynamic classes use `cn()` — no string concatenation or template literals in `className`
- [ ] Components with multiple visual states use CVA, not conditional ternaries
- [ ] No `dark:` variants unless the component explicitly implements a light/dark toggle
- [ ] No `tailwind.config.js` was created or modified — all config is in `index.css`
- [ ] All `@keyframes` are defined in `client/src/index.css` using `oklch()` values only
- [ ] Hero/display headings use `clamp()` for fluid sizing, not fixed Tailwind size classes
- [ ] Responsive styles follow mobile-first breakpoint ordering
