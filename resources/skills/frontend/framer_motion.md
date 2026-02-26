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
8. **Keep animation durations under 0.5s for UI interactions** (buttons, toggles, modals). Scroll reveals and page transitions can be longer (0.5–0.8s).

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

## Anti-Patterns

| Do NOT do this | Do this instead | Why |
|----------------|-----------------|-----|
| Variants defined inside the component body | Define variants as `const` outside the function | Creates new object reference every render, causing re-animation |
| `<AnimatePresence>` without `mode="wait"` on page swaps | Add `mode="wait"` | Enter and exit animations overlap, causing layout jumps |
| `whileInView` without `viewport={{ once: true }}` for reveals | Add `once: true` | Animation replays on every scroll, feels unpolished |
| Animating `width` or `height` directly | Use `scale` or `clipPath` | Layout property animations trigger expensive reflows |
| `layout` prop on a list with 50+ items | Use explicit `x`/`y` transforms | Layout animation recalculates all sibling positions, causing frame drops |
| Animation duration > 0.5s on button/toggle interactions | Keep UI interactions at 0.2–0.4s | Slow micro-interactions make the app feel sluggish |

---

## Verification Checklist

Before marking a task as done, confirm:

- [ ] All `variants` objects are defined outside component functions
- [ ] Exit animations use `<AnimatePresence>` — no unmounting animations are silently skipped
- [ ] Scroll reveals use `viewport={{ once: true }}` unless replay is explicitly intended
- [ ] No layout property animations (`width`, `height`) on performance-critical paths
- [ ] UI interaction durations are under 0.5s
- [ ] `mode="wait"` is set on `AnimatePresence` when swapping between elements
