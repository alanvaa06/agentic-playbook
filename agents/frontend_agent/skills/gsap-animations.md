# GSAP Animations

**Domain:** Frontend
**Loaded when:** `gsap` detected in `package.json`

---

## When to Use

- Scroll-locked (pinned) sections where the user scrolls through a sequence while the section stays fixed.
- Odometer / slot counter animations that require precise `translateY` control over digit columns.
- Complex multi-step timelines with scrubbing that exceed Framer Motion's declarative model.
- Any animation that must be driven by scroll position (`ScrollTrigger`).

## When NOT to Use

- Simple entrance/exit animations or scroll reveals — use Framer Motion instead.
- Hover, focus, or toggle micro-interactions — use Tailwind `transition-*` or Framer Motion.
- 3D object animations inside `<Canvas>` — use R3F's `useFrame` or `@react-three/drei` springs.
- Layout animations — Framer Motion's `layout` prop handles these declaratively.

---

## Core Rules

1. **Register plugins at the module level**, not inside components. `gsap.registerPlugin(ScrollTrigger)` must run once at import time. Registering inside a component body runs on every render and can cause duplicate registrations.
2. **Use `gsap.context()` for all component-scoped animations.** Context scopes selectors to a ref and provides automatic cleanup via `ctx.revert()`. This is the React-idiomatic way to manage GSAP lifecycle.
3. **Kill all tweens and ScrollTriggers on unmount.** Always call `ctx.revert()` inside a `useEffect` cleanup function. Leaked ScrollTriggers keep listening to scroll events after the component unmounts.
4. **Never mix GSAP and Framer Motion on the same DOM element.** Both libraries write to `transform` and will fight, causing glitchy animations. Pick one library per element. They can coexist in the same page on different elements.
5. **Use `will-change: transform` on animated elements.** This hints the browser to promote the element to its own compositor layer, improving animation performance. Apply it via Tailwind (`will-change-transform`) or inline style.
6. **Prefer `gsap.to()` and `gsap.fromTo()` over `gsap.from()`.** `gsap.from()` sets the initial state imperatively, which conflicts with React's declarative rendering and can flash unstyled content on mount.
7. **Scope ScrollTrigger selectors to a ref**, not global CSS selectors. Global selectors break when multiple instances of the same component exist on the page.
8. **Use GSAP only for effects that Framer Motion cannot express.** Framer Motion is the primary animation library. GSAP is the specialized tool for scroll-locked timelines, scrubbing, and complex DOM manipulations like the odometer.

---

## Code Patterns

### Plugin registration (module level)

```tsx
// client/src/lib/gsap.ts
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

gsap.registerPlugin(ScrollTrigger);

export { gsap, ScrollTrigger };
```

### gsap.context() cleanup in React

```tsx
import { useEffect, useRef } from "react";
import { gsap } from "@/lib/gsap";

export function AnimatedSection() {
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const ctx = gsap.context(() => {
      gsap.to(".box", {
        x: 200,
        duration: 1,
        scrollTrigger: {
          trigger: ".box",
          start: "top 80%",
        },
      });
    }, containerRef);

    return () => ctx.revert();
  }, []);

  return (
    <div ref={containerRef}>
      <div className="box will-change-transform">Animated</div>
    </div>
  );
}
```

### ScrollTrigger pinned section

```tsx
import { useEffect, useRef } from "react";
import { gsap, ScrollTrigger } from "@/lib/gsap";

export function PinnedSection() {
  const sectionRef = useRef<HTMLElement>(null);
  const timelineRef = useRef<gsap.core.Timeline | null>(null);

  useEffect(() => {
    const ctx = gsap.context(() => {
      timelineRef.current = gsap.timeline({
        scrollTrigger: {
          trigger: sectionRef.current,
          start: "top top",
          end: "+=200%",
          pin: true,
          scrub: 1,
        },
      });

      timelineRef.current
        .fromTo(".step-1", { opacity: 0, y: 40 }, { opacity: 1, y: 0 })
        .fromTo(".step-2", { opacity: 0, y: 40 }, { opacity: 1, y: 0 })
        .fromTo(".step-3", { opacity: 0, y: 40 }, { opacity: 1, y: 0 });
    }, sectionRef);

    return () => ctx.revert();
  }, []);

  return (
    <section ref={sectionRef} className="relative h-screen">
      <div className="step-1 will-change-transform">Step 1</div>
      <div className="step-2 will-change-transform">Step 2</div>
      <div className="step-3 will-change-transform">Step 3</div>
    </section>
  );
}
```

### Odometer / slot counter

The odometer animates a vertical strip of digits (0–9) by translating the strip upward. Each digit column is an `overflow: hidden` container with a tall inner stack.

```tsx
import { useEffect, useRef } from "react";
import { gsap } from "@/lib/gsap";

interface OdometerProps {
  value: number;
  digitHeight?: number;
}

export function Odometer({ value, digitHeight = 48 }: OdometerProps) {
  const digits = String(value).padStart(2, "0").split("").map(Number);

  return (
    <div className="flex" aria-label={String(value)}>
      {digits.map((digit, i) => (
        <DigitColumn key={i} target={digit} digitHeight={digitHeight} />
      ))}
    </div>
  );
}

interface DigitColumnProps {
  target: number;
  digitHeight: number;
}

function DigitColumn({ target, digitHeight }: DigitColumnProps) {
  const stackRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!stackRef.current) return;

    const ctx = gsap.context(() => {
      gsap.to(stackRef.current, {
        y: -(target * digitHeight),
        duration: 1.2,
        ease: "power3.out",
      });
    });

    return () => ctx.revert();
  }, [target, digitHeight]);

  return (
    <div className="overflow-hidden" style={{ height: digitHeight }}>
      <div ref={stackRef} className="will-change-transform">
        {Array.from({ length: 10 }, (_, i) => (
          <div
            key={i}
            className="flex items-center justify-center font-mono font-bold"
            style={{ height: digitHeight }}
          >
            {i}
          </div>
        ))}
      </div>
    </div>
  );
}
```

### GSAP + Lenis ticker integration

When Lenis smooth scroll is active, GSAP's ScrollTrigger must use Lenis's scroll position instead of the native one.

```tsx
import { useEffect } from "react";
import { useLenis } from "lenis/react";
import { gsap, ScrollTrigger } from "@/lib/gsap";

export function useLenisGsapSync() {
  const lenis = useLenis();

  useEffect(() => {
    if (!lenis) return;

    lenis.on("scroll", ScrollTrigger.update);

    function update(time: number) {
      lenis.raf(time * 1000);
    }

    gsap.ticker.add(update);
    gsap.ticker.lagSmoothing(0);

    return () => {
      lenis.off("scroll", ScrollTrigger.update);
      gsap.ticker.remove(update);
    };
  }, [lenis]);
}
```

---

## Anti-Patterns

| Do NOT do this | Do this instead | Why |
|----------------|-----------------|-----|
| `gsap.registerPlugin(ScrollTrigger)` inside a component | Register once in `client/src/lib/gsap.ts` at module level | Runs on every render; duplicate registrations waste cycles |
| `useEffect` without `ctx.revert()` cleanup | Always call `ctx.revert()` in the cleanup function | Leaked ScrollTriggers fire on scroll after unmount, causing errors |
| `gsap.to(".box", ...)` with a global selector | Scope to a `ref` via `gsap.context(() => {}, containerRef)` | Global selectors break with multiple component instances |
| GSAP `gsap.to()` + Framer Motion `animate` on the same `div` | Pick one library per element | Both write to `transform`, causing fights and visual glitches |
| `gsap.from()` for entrance animations | Use `gsap.fromTo()` to define both start and end states | `gsap.from()` flashes the end state before animating, causing FOUC |
| Odometer without `overflow: hidden` on the column | Always set `overflow: hidden` on `.digit-column` | Exposes all 10 digits at once instead of showing only the active one |
| Simple fade-in built with GSAP | Use Framer Motion for simple reveals | GSAP is overkill for declarative animations; adds bundle size for no benefit |

---

## Verification Checklist

Before marking a task as done, confirm:

- [ ] `gsap.registerPlugin()` is called exactly once, at module level in `client/src/lib/gsap.ts`
- [ ] Every `useEffect` with GSAP animations returns `ctx.revert()` in its cleanup
- [ ] All ScrollTrigger selectors are scoped to a `ref`, not global CSS selectors
- [ ] No DOM element has both GSAP and Framer Motion animations applied
- [ ] Animated elements have `will-change-transform` (via Tailwind class or inline style)
- [ ] `gsap.fromTo()` is used instead of `gsap.from()` for entrance animations
- [ ] GSAP is only used for effects that Framer Motion cannot handle (pinning, scrubbing, odometers)
- [ ] When Lenis is active, ScrollTrigger is connected via the Lenis ticker hook
