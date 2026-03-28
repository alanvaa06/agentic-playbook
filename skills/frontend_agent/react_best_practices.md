# React Best Practices

**Domain:** Frontend
**Loaded when:** `react` detected in `package.json`

---

## When to Use

- Building any new React component or page.
- Refactoring existing components.
- Reviewing component architecture decisions.

## When NOT to Use

- Pure CSS/styling tasks with no component logic changes (use `tailwind_design_system.md` instead).
- Tasks that only modify Zod schemas or form wiring (use `forms_validation.md` instead).

---

## Core Rules

1. **Functional components only.** Never use class components. Every component is a function with explicit TypeScript props.
2. **One component per file.** The file name matches the component name in PascalCase (e.g., `UserCard.tsx` exports `UserCard`).
3. **Props must be typed with an interface, not `type`.** Name it `[ComponentName]Props`. Export it if the component is consumed by other modules.
4. **Destructure props in the function signature**, not in the body.
5. **Never use `any`.** Use `unknown` and narrow with type guards when the type is genuinely unknown.
6. **Use `React.FC` sparingly.** Prefer explicit return types on the function. `React.FC` hides `children` behavior and complicates generics.
7. **`useEffect` must have a cleanup function** when subscribing to events, timers, or external stores. No exceptions.
8. **`useEffect` dependency arrays must be exhaustive.** Never suppress the `react-hooks/exhaustive-deps` lint rule with `// eslint-disable`.
9. **`useMemo` and `useCallback` are for performance, not correctness.** Only use them when passing values to memoized children, R3F components, or Framer Motion.
10. **Colocate related code.** Hooks used by a single component live in the same file. Hooks shared across 2+ components live in `client/src/hooks/`.

---

## Code Patterns

### Component with typed props

```tsx
interface UserCardProps {
  name: string;
  email: string;
  avatarUrl?: string;
}

export function UserCard({ name, email, avatarUrl }: UserCardProps) {
  return (
    <div className={cn("flex items-center gap-3 rounded-lg p-4")}>
      {avatarUrl && <img src={avatarUrl} alt={name} className="h-10 w-10 rounded-full" />}
      <div>
        <p className="text-sm font-medium">{name}</p>
        <p className="text-xs text-muted-foreground">{email}</p>
      </div>
    </div>
  );
}
```

### Custom hook with cleanup

```tsx
export function useWindowResize(callback: (width: number, height: number) => void) {
  useEffect(() => {
    const handler = () => callback(window.innerWidth, window.innerHeight);
    window.addEventListener("resize", handler);
    return () => window.removeEventListener("resize", handler);
  }, [callback]);
}
```

### Conditional rendering (prefer early return)

```tsx
export function Dashboard({ data }: DashboardProps) {
  if (!data) {
    return <Skeleton className="h-64 w-full" />;
  }

  return (
    <div>
      <h1>{data.title}</h1>
      {data.items.map((item) => (
        <DashboardItem key={item.id} {...item} />
      ))}
    </div>
  );
}
```

---

## Anti-Patterns

| Do NOT do this | Do this instead | Why |
|----------------|-----------------|-----|
| `const Foo: React.FC<Props> = (props) => {}` | `function Foo({ name }: FooProps) {}` | `React.FC` implicitly includes `children`, hiding the actual API surface |
| `useEffect(() => { fetchData() }, [])` with no cleanup | Add an `AbortController` or guard flag | Stale closures and race conditions on fast navigation |
| `const [items, setItems] = useState<any[]>([])` | `useState<Item[]>([])` | `any` disables all TypeScript safety downstream |
| Inline object creation in JSX: `style={{ color: 'red' }}` | Define constants or use Tailwind classes | Creates new object references every render, breaking `React.memo` |
| `// eslint-disable-next-line react-hooks/exhaustive-deps` | Fix the dependency array properly | Suppressing this rule causes stale state bugs that are extremely hard to debug |
| Giant components (200+ lines) | Extract sub-components or custom hooks | Large components overwhelm the context window and reduce agent accuracy |

---

## Verification Checklist

Before marking a task as done, confirm:

- [ ] No `any` types in the changed files
- [ ] All `useEffect` hooks have correct dependency arrays (no suppressions)
- [ ] All `useEffect` hooks that subscribe to events include a cleanup function
- [ ] Component file names match their exported component name in PascalCase
- [ ] Props are defined with `interface`, not `type`
- [ ] No inline style objects in JSX (use Tailwind classes)
