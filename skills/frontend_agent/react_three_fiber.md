# React Three Fiber

**Domain:** Frontend
**Loaded when:** `@react-three/fiber` detected in `package.json`

---

## When to Use

- Rendering 3D scenes, models, or particle effects in the browser.
- Building interactive 3D product showcases, hero backgrounds, or data visualizations.
- Integrating Three.js into a React component tree.

## When NOT to Use

- 2D animations or transitions — use Framer Motion instead.
- Simple icon animations or SVG morphing — CSS or Framer Motion is lighter.
- Pages that must work without WebGL (email clients, legacy browsers).

---

## Core Rules

1. **Every `<Canvas>` MUST be wrapped in `<React.Suspense>`** with a meaningful fallback UI (loading spinner, skeleton, or placeholder). A canvas without Suspense will throw if any child uses `useLoader` or lazy-loaded geometry.
2. **Never put `<Canvas>` inside a Framer Motion `motion.div` with layout animations.** Layout animations recalculate the DOM rect, which forces the WebGL context to resize on every frame. Place the canvas in a fixed-size container instead.
3. **Use `useFrame` sparingly.** Every `useFrame` callback runs on every frame (~60fps). Keep the callback body minimal — no state updates, no DOM reads, no allocations.
4. **Never call `setState` inside `useFrame`.** It triggers a React re-render on every frame (60 re-renders/sec). Use `useRef` to mutate Three.js objects directly.
5. **Dispose geometries, materials, and textures on unmount.** R3F does not garbage-collect Three.js resources automatically. Use `useEffect` cleanup or `@react-three/drei`'s `useGLTF.preload` to manage lifecycle.
6. **Use instancing (`<Instances>` / `<Instance>`) for repeated geometry.** Rendering 100 individual meshes creates 100 draw calls. Instancing renders them in 1 draw call.
7. **Prefer `@react-three/drei` helpers** over raw Three.js constructors. Drei provides `OrbitControls`, `Environment`, `Float`, `Text`, `useGLTF`, and other battle-tested abstractions.
8. **Set `frameloop="demand"` on `<Canvas>`** for scenes that only update on interaction (e.g., a static product viewer). This stops the render loop when nothing changes, saving significant GPU and battery.

---

## Code Patterns

### Basic scene with Suspense boundary

```tsx
import { Canvas } from "@react-three/fiber";
import { OrbitControls, Environment } from "@react-three/drei";
import { Suspense } from "react";

export function ProductViewer() {
  return (
    <div className="h-[500px] w-full">
      <Suspense fallback={<div className="flex h-full items-center justify-center">Loading 3D...</div>}>
        <Canvas camera={{ position: [0, 0, 5], fov: 45 }}>
          <Environment preset="studio" />
          <ProductModel />
          <OrbitControls enableZoom={false} />
        </Canvas>
      </Suspense>
    </div>
  );
}
```

### useFrame with ref mutation (no setState)

```tsx
import { useFrame } from "@react-three/fiber";
import { useRef } from "react";
import type { Mesh } from "three";

export function RotatingCube() {
  const meshRef = useRef<Mesh>(null);

  useFrame((_, delta) => {
    if (meshRef.current) {
      meshRef.current.rotation.y += delta * 0.5;
    }
  });

  return (
    <mesh ref={meshRef}>
      <boxGeometry args={[1, 1, 1]} />
      <meshStandardMaterial color="cyan" />
    </mesh>
  );
}
```

### Loading a GLTF model with disposal

```tsx
import { useGLTF } from "@react-three/drei";
import { useEffect } from "react";

export function HeroModel() {
  const { scene } = useGLTF("/models/hero.glb");

  useEffect(() => {
    return () => {
      scene.traverse((child) => {
        if ("geometry" in child) (child as any).geometry?.dispose();
        if ("material" in child) {
          const mat = (child as any).material;
          if (Array.isArray(mat)) mat.forEach((m: any) => m.dispose());
          else mat?.dispose();
        }
      });
    };
  }, [scene]);

  return <primitive object={scene} scale={0.5} />;
}

useGLTF.preload("/models/hero.glb");
```

### Instanced rendering for particles

```tsx
import { Instances, Instance } from "@react-three/drei";

export function ParticleField({ count = 200 }: { count?: number }) {
  const particles = useMemo(
    () =>
      Array.from({ length: count }, () => ({
        position: [
          (Math.random() - 0.5) * 10,
          (Math.random() - 0.5) * 10,
          (Math.random() - 0.5) * 10,
        ] as [number, number, number],
        scale: Math.random() * 0.1 + 0.02,
      })),
    [count]
  );

  return (
    <Instances limit={count}>
      <sphereGeometry args={[1, 8, 8]} />
      <meshBasicMaterial color="white" transparent opacity={0.6} />
      {particles.map((p, i) => (
        <Instance key={i} position={p.position} scale={p.scale} />
      ))}
    </Instances>
  );
}
```

---

## Anti-Patterns

| Do NOT do this | Do this instead | Why |
|----------------|-----------------|-----|
| `<Canvas>` without `<Suspense>` wrapper | Always wrap in `<Suspense fallback={...}>` | Throws on any async resource load (textures, models, fonts) |
| `useFrame(() => { setCount(c => c + 1) })` | Use `useRef` and mutate the Three.js object directly | `setState` in `useFrame` triggers 60 React re-renders per second |
| 100 individual `<mesh>` components with same geometry | Use `<Instances>` / `<Instance>` from Drei | 100 draw calls vs. 1 draw call — massive performance difference |
| `<Canvas>` inside `<motion.div layout>` | Use a fixed-size `<div>` container, no layout animation | Layout recalculation resizes the WebGL context every frame |
| Forgetting to dispose GLTF resources on unmount | Add `useEffect` cleanup that traverses and disposes | Three.js resources leak GPU memory without explicit disposal |
| `frameloop="always"` on a static scene | Use `frameloop="demand"` | Renders 60fps even when nothing changes, wasting GPU and battery |

---

## Verification Checklist

Before marking a task as done, confirm:

- [ ] Every `<Canvas>` is wrapped in `<React.Suspense>` with a visible fallback
- [ ] No `setState` calls inside `useFrame` — only ref mutations
- [ ] GLTF/texture resources are disposed on component unmount
- [ ] Repeated geometry uses `<Instances>` instead of individual meshes
- [ ] No `<Canvas>` is placed inside a Framer Motion `layout` animation container
- [ ] Static scenes use `frameloop="demand"`
