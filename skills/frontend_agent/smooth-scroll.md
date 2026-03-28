# Smooth Scroll (Lenis)

**Domain:** Frontend
**Loaded when:** `lenis` detected in `package.json`

---

## When to Use

- The page requires buttery-smooth inertial scrolling across all sections.
- Scroll-triggered animations (Framer Motion or GSAP) need a consistent, predictable scroll position.
- Landing pages, portfolio sites, or marketing pages where scroll feel is a core part of the experience.

## When NOT to Use

- Admin dashboards, data tables, or CRUD interfaces where native scroll behavior is expected.
- Pages that are primarily forms — smooth scroll interferes with keyboard-driven form navigation.
- Inside `<Canvas>` (R3F) — Three.js manages its own scroll/zoom via OrbitControls or ScrollControls.

---

## Core Rules

1. **Initialize Lenis once at the app root.** Create a `SmoothScrollProvider` component that wraps the app in `App.tsx` or the top-level layout. Never instantiate Lenis inside individual page components.
2. **Add `data-lenis-prevent` to any element with its own scroll container.** Mobile nav drawers, modals, dropdown menus, and code blocks with overflow must opt out of smooth scroll. Without this attribute, Lenis intercepts their scroll events and breaks internal scrolling.
3. **Use `lenis.scrollTo()` for programmatic scrolling.** Never use `window.scrollTo()` or `element.scrollIntoView()` when Lenis is active — they bypass the smooth scroll pipeline and cause position jumps.
4. **Destroy the Lenis instance on unmount.** Always return a cleanup function from `useEffect` that calls `lenis.destroy()`. Leaked instances keep animating in the background and cause memory leaks.
5. **Connect Lenis to the animation library's ticker.** When using Framer Motion, drive Lenis from `useAnimationFrame`. When using GSAP, add Lenis to `gsap.ticker`. This synchronizes scroll position updates with animation frames, preventing visual tearing.
6. **Never nest Lenis instances.** A child route or component must not create its own Lenis. Use the single root instance via context or the `useLenis` hook from `lenis/react`.
7. **Disable Lenis on reduced-motion preference.** Check `window.matchMedia("(prefers-reduced-motion: reduce)")` and skip initialization when the user prefers reduced motion.

---

## Code Patterns

### SmoothScrollProvider (root-level)

```tsx
// client/src/components/SmoothScrollProvider.tsx
import { ReactLenis } from "lenis/react";

interface SmoothScrollProviderProps {
  children: React.ReactNode;
}

export function SmoothScrollProvider({ children }: SmoothScrollProviderProps) {
  return (
    <ReactLenis
      root
      options={{
        lerp: 0.1,
        duration: 1.2,
        smoothWheel: true,
      }}
    >
      {children}
    </ReactLenis>
  );
}
```

### Wrapping the app

```tsx
// client/src/App.tsx
import { SmoothScrollProvider } from "@/components/SmoothScrollProvider";

export function App() {
  return (
    <SmoothScrollProvider>
      <Header />
      <main>{/* routes */}</main>
      <Footer />
    </SmoothScrollProvider>
  );
}
```

### `data-lenis-prevent` on a mobile nav drawer

```tsx
export function MobileNav({ isOpen }: MobileNavProps) {
  if (!isOpen) return null;

  return (
    <nav data-lenis-prevent className="fixed inset-0 z-50 overflow-y-auto bg-background">
      <ul className="flex flex-col gap-4 p-6">
        <li><a href="#about">About</a></li>
        <li><a href="#work">Work</a></li>
        <li><a href="#contact">Contact</a></li>
      </ul>
    </nav>
  );
}
```

### Programmatic scroll-to-section

```tsx
import { useLenis } from "lenis/react";

export function ScrollToButton({ target }: { target: string }) {
  const lenis = useLenis();

  function handleClick() {
    lenis?.scrollTo(target, { offset: -80, duration: 1.5 });
  }

  return <button onClick={handleClick}>Scroll to {target}</button>;
}
```

### Lenis + GSAP ticker integration

```tsx
import { useEffect } from "react";
import { useLenis } from "lenis/react";
import gsap from "gsap";

export function useLenisGsapSync() {
  const lenis = useLenis();

  useEffect(() => {
    if (!lenis) return;

    function update(time: number) {
      lenis.raf(time * 1000);
    }

    gsap.ticker.add(update);
    lenis.stop();

    return () => {
      gsap.ticker.remove(update);
    };
  }, [lenis]);
}
```

### Lenis + Framer Motion ticker integration

```tsx
import { useEffect } from "react";
import { useLenis } from "lenis/react";
import { useAnimationFrame } from "framer-motion";

export function useLenisFramerSync() {
  const lenis = useLenis();

  useAnimationFrame((time) => {
    lenis?.raf(time);
  });
}
```

---

## Anti-Patterns

| Do NOT do this | Do this instead | Why |
|----------------|-----------------|-----|
| `new Lenis()` inside a page component | Use `SmoothScrollProvider` at the app root | Multiple instances fight over scroll control and cause erratic behavior |
| `window.scrollTo(0, 500)` with Lenis active | `lenis.scrollTo(500)` | Native scroll API bypasses the Lenis pipeline, causing position jumps |
| Modal/drawer without `data-lenis-prevent` | Add `data-lenis-prevent` to the scrollable container | Lenis intercepts the scroll events, making the modal unscrollable |
| Forgetting `lenis.destroy()` in cleanup | Return cleanup from `useEffect` | Leaked instances keep RAF loops running, causing memory leaks |
| Nesting `<ReactLenis>` inside a route component | Use a single root `<ReactLenis>` with `root` prop | Nested instances conflict and double-apply scroll transformations |
| Lenis active when `prefers-reduced-motion` is set | Check the media query and skip initialization | Smooth scroll with inertia is disorienting for users who need reduced motion |

---

## Verification Checklist

Before marking a task as done, confirm:

- [ ] Lenis is initialized exactly once, at the app root via `SmoothScrollProvider`
- [ ] All scrollable overlays (modals, drawers, dropdowns) have `data-lenis-prevent`
- [ ] No calls to `window.scrollTo()` or `element.scrollIntoView()` exist alongside Lenis
- [ ] The Lenis instance is destroyed on unmount (cleanup in `useEffect`)
- [ ] Lenis is connected to the animation library ticker (GSAP or Framer Motion)
- [ ] `prefers-reduced-motion` is respected — Lenis is skipped when the preference is set
