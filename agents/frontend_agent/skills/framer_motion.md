# Framer Motion

**Domain:** Frontend
**Loaded when:** `framer-motion` detected in `package.json`

---

## When to Use

- Adding entrance, exit, or layout animations to components.
- Building scroll-triggered reveal effects.
- Implementing page transitions.
- Animating SVG paths or complex multi-step sequences.

## When NOT to Use

- Simple hover/focus effects achievable with Tailwind's `transition-*` utilities or `tailwindcss-animate`.
- 3D object animations inside `<Canvas>` — use R3F's `useFrame` or `useSpring` from `@react-three/drei` instead.

---

## Core Rules

1. **Define `variants` objects outside the component function.** Declaring them inline creates a new object reference every render, which defeats Framer Motion's internal diffing and can trigger unnecessary re-animations.
2. **Use `AnimatePresence` for exit animations.** Components that unmount (conditionally rendered, route changes) need to be wrapped in `<AnimatePresence>` for their `exit` variant to fire.
3. **Set `mode="wait"` on `AnimatePresence`** when animating between two elements that swap (e.g., page transitions). Without it, the entering and exiting elements animate simultaneously, causing layout jumps.
4. **Use `useInView` for scroll-triggered reveals**, not `IntersectionObserver` directly. It integrates cleanly with Framer Motion's animation lifecycle.
5. **Prefer `transform` properties** (`x`, `y`, `scale`, `rotate`) over layout properties (`width`, `height`, `top`, `left`). Transform animations run on the compositor thread and are significantly more performant.
6. **Never animate `layout` on lists with 20+ items.** Layout animations recalculate positions for every sibling, causing frame drops on large lists. Use explicit `x`/`y` transforms instead.
7. **Use `whileInView` with `viewport={{ once: true }}`** for one-shot scroll reveals. Without `once: true`, the animation replays every time the element enters the viewport, which feels janky on scroll-heavy pages.
8. **Keep animation durations under 0.5s for UI interactions** (buttons, toggles, modals). Standard scroll reveals and page transitions can be 0.5–0.8s. Cinematic section-level reveals (hero entrances, full-viewport scroll sequences) may use 0.8–1.2s with springy easing.
9. **Use the named `EASING` constants** (see Easing Reference below) instead of string presets like `"easeOut"` for cinematic animations. Named constants make the animation language consistent across the project and are easier to tune globally.

---

## Code Patterns

### Fade-in on mount with variants defined outside

```tsx
const fadeIn = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.4 } },
};

export function FeatureCard({ title, description }: FeatureCardProps) {
  return (
    <motion.div variants={fadeIn} initial="hidden" animate="visible">
      <h3>{title}</h3>
      <p>{description}</p>
    </motion.div>
  );
}
```

### Scroll-triggered reveal (one-shot)

```tsx
const revealVariants = {
  hidden: { opacity: 0, y: 40 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.6, ease: "easeOut" } },
};

export function Section({ children }: SectionProps) {
  return (
    <motion.section
      variants={revealVariants}
      initial="hidden"
      whileInView="visible"
      viewport={{ once: true, margin: "-100px" }}
    >
      {children}
    </motion.section>
  );
}
```

### Page transition with AnimatePresence

```tsx
const pageTransition = {
  initial: { opacity: 0, x: -20 },
  animate: { opacity: 1, x: 0, transition: { duration: 0.3 } },
  exit: { opacity: 0, x: 20, transition: { duration: 0.2 } },
};

export function AnimatedPage({ children }: AnimatedPageProps) {
  return (
    <AnimatePresence mode="wait">
      <motion.div
        key={location.pathname}
        variants={pageTransition}
        initial="initial"
        animate="animate"
        exit="exit"
      >
        {children}
      </motion.div>
    </AnimatePresence>
  );
}
```

### Staggered children

```tsx
const container = {
  hidden: {},
  visible: { transition: { staggerChildren: 0.08 } },
};

const item = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0 },
};

export function FeatureGrid({ features }: FeatureGridProps) {
  return (
    <motion.div variants={container} initial="hidden" animate="visible" className="grid grid-cols-3 gap-4">
      {features.map((f) => (
        <motion.div key={f.id} variants={item}>
          <FeatureCard {...f} />
        </motion.div>
      ))}
    </motion.div>
  );
}
```

---

## Easing Reference

Define these constants in a shared file (e.g., `client/src/lib/motion.ts`) and import them wherever animations are declared. Never hardcode cubic-bezier arrays inline.

```tsx
export const EASING = {
  cinematic: [0.19, 1, 0.22, 1],     // springy overshoot — section reveals, hero entrances
  smooth: [0.85, 0, 0.15, 1],        // symmetric ease-in-out — page transitions, modals
  snappy: [0, 0, 0.58, 1],           // fast start, smooth stop — UI interactions
} as const;
```

| Name | Curve | Feel | Use for |
|------|-------|------|---------|
| `cinematic` | `[0.19, 1, 0.22, 1]` | Springy overshoot, slow settle | Full-section scroll reveals, hero text entrances |
| `smooth` | `[0.85, 0, 0.15, 1]` | Symmetric, no overshoot | Page transitions, modal open/close |
| `snappy` | `[0, 0, 0.58, 1]` | Fast start, smooth deceleration | Buttons, toggles, tooltips, dropdowns |

---

## Cinematic Scroll Reveals

Use cinematic easing for full-section scroll reveals that need a premium, editorial feel. These are slower and springier than standard UI animations.

### Cinematic section reveal

```tsx
import { EASING } from "@/lib/motion";

const cinematicReveal = {
  hidden: { opacity: 0, y: 60 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { ease: EASING.cinematic, duration: 1.2 },
  },
};

export function HeroSection({ children }: HeroSectionProps) {
  return (
    <motion.section
      variants={cinematicReveal}
      initial="hidden"
      whileInView="visible"
      viewport={{ once: true, margin: "-15%" }}
    >
      {children}
    </motion.section>
  );
}
```

### Snappy UI interaction (contrast example)

```tsx
import { EASING } from "@/lib/motion";

const snappyReveal = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { ease: EASING.snappy, duration: 0.4 },
  },
};
```

### Staggered cinematic reveal

```tsx
import { EASING } from "@/lib/motion";

const cinematicContainer = {
  hidden: {},
  visible: { transition: { staggerChildren: 0.15 } },
};

const cinematicItem = {
  hidden: { opacity: 0, y: 60 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { ease: EASING.cinematic, duration: 1.0 },
  },
};
```

---

## Anti-Patterns

| Do NOT do this | Do this instead | Why |
|----------------|-----------------|-----|
| Variants defined inside the component body | Define variants as `const` outside the function | Creates new object reference every render, causing re-animation |
| `<AnimatePresence>` without `mode="wait"` on page swaps | Add `mode="wait"` | Enter and exit animations overlap, causing layout jumps |
| `whileInView` without `viewport={{ once: true }}` for reveals | Add `once: true` | Animation replays on every scroll, feels unpolished |
| Animating `width` or `height` directly | Use `scale` or `clipPath` | Layout property animations trigger expensive reflows |
| `layout` prop on a list with 50+ items | Use explicit `x`/`y` transforms | Layout animation recalculates all sibling positions, causing frame drops |
| Animation duration > 0.5s on button/toggle interactions | Keep UI interactions at 0.2–0.4s | Slow micro-interactions make the app feel sluggish |
| Hardcoded `ease: [0.19, 1, 0.22, 1]` inline | Import `EASING.cinematic` from `@/lib/motion` | Inline arrays are unreadable and impossible to tune globally |
| Cinematic easing on a button hover | Use `EASING.snappy` for micro-interactions | Springy overshoot on small elements feels broken, not premium |

---

## Verification Checklist

Before marking a task as done, confirm:

- [ ] All `variants` objects are defined outside component functions
- [ ] Exit animations use `<AnimatePresence>` — no unmounting animations are silently skipped
- [ ] Scroll reveals use `viewport={{ once: true }}` unless replay is explicitly intended
- [ ] No layout property animations (`width`, `height`) on performance-critical paths
- [ ] UI interaction durations are under 0.5s
- [ ] Cinematic section reveals use `EASING.cinematic` from `@/lib/motion`, not inline arrays
- [ ] No cinematic easing (`duration > 0.8s`) on micro-interactions (buttons, toggles, tooltips)
- [ ] `mode="wait"` is set on `AnimatePresence` when swapping between elements
