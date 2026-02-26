# Sanity CMS

**Domain:** Frontend
**Loaded when:** `@sanity/client` detected in `package.json`

---

## When to Use

- Fetching content from Sanity (blog posts, landing pages, team profiles, FAQs).
- Building or modifying Sanity Studio schemas.
- Rendering Sanity images or Portable Text (rich text) in React components.

## When NOT to Use

- Static content that never changes and lives directly in the codebase (e.g., a hardcoded footer).
- Data stored in the application database (Supabase, Postgres) — that belongs to the database agent.

---

## Core Rules

1. **Use a single `sanityClient` instance** defined in `client/src/lib/sanity.ts`. Never instantiate the client inline in a component. The client holds the project ID, dataset, and API version — duplicating it creates config drift.
2. **All queries use GROQ**, Sanity's native query language. Never use the REST API directly when the GROQ client is available.
3. **Type all GROQ query responses with Zod schemas.** Define the expected shape in `client/src/schemas/` and parse the response through it. This catches schema mismatches between Sanity Studio and the frontend at runtime.
4. **Use the image URL builder** (`@sanity/image-url`) for all Sanity images. Never construct CDN URLs manually — the builder handles cropping, hotspot, and format optimization automatically.
5. **Set an explicit `apiVersion` date** on the client (e.g., `"2024-01-01"`). Without it, Sanity defaults to the latest API version, which can introduce breaking changes silently.
6. **Prefetch content at the page level, not the component level.** Fetch all CMS data a page needs in a single GROQ query, then pass it down as props. This avoids waterfall requests where nested components each fire their own query.
7. **Use `_type` and `_id` fields** as discriminators and keys. Never use array indices as React keys for CMS content — content order can change in Sanity Studio without the frontend noticing.
8. **Handle missing content gracefully.** CMS content is user-editable. A field that exists in the schema might be empty in production. Always check for `null`/`undefined` before rendering.

---

## Code Patterns

### Sanity client singleton

```tsx
// client/src/lib/sanity.ts
import { createClient } from "@sanity/client";
import imageUrlBuilder from "@sanity/image-url";

export const sanityClient = createClient({
  projectId: import.meta.env.VITE_SANITY_PROJECT_ID,
  dataset: import.meta.env.VITE_SANITY_DATASET,
  apiVersion: "2024-01-01",
  useCdn: true,
});

const builder = imageUrlBuilder(sanityClient);

export function urlFor(source: any) {
  return builder.image(source);
}
```

### GROQ query with typed response

```tsx
// client/src/lib/queries.ts
export const TEAM_QUERY = `*[_type == "teamMember"] | order(order asc) {
  _id,
  name,
  role,
  bio,
  "imageUrl": image.asset->url,
  linkedinUrl
}`;
```

```tsx
// client/src/schemas/team.ts
import { z } from "zod";

export const teamMemberSchema = z.object({
  _id: z.string(),
  name: z.string(),
  role: z.string(),
  bio: z.string().nullable(),
  imageUrl: z.string().url().nullable(),
  linkedinUrl: z.string().url().nullable(),
});

export const teamResponseSchema = z.array(teamMemberSchema);
export type TeamMember = z.infer<typeof teamMemberSchema>;
```

### Fetching at the page level

```tsx
import { useEffect, useState } from "react";
import { sanityClient } from "@/lib/sanity";
import { TEAM_QUERY } from "@/lib/queries";
import { teamResponseSchema, type TeamMember } from "@/schemas/team";

export function TeamPage() {
  const [members, setMembers] = useState<TeamMember[]>([]);

  useEffect(() => {
    sanityClient.fetch(TEAM_QUERY).then((data) => {
      const parsed = teamResponseSchema.safeParse(data);
      if (parsed.success) {
        setMembers(parsed.data);
      } else {
        console.error("Sanity response schema mismatch:", parsed.error);
      }
    });
  }, []);

  return (
    <section className="grid grid-cols-1 gap-6 md:grid-cols-3">
      {members.map((member) => (
        <TeamCard key={member._id} {...member} />
      ))}
    </section>
  );
}
```

### Sanity image with URL builder

```tsx
import { urlFor } from "@/lib/sanity";

interface SanityImageProps {
  source: any;
  alt: string;
  width?: number;
}

export function SanityImage({ source, alt, width = 400 }: SanityImageProps) {
  if (!source) return null;

  return (
    <img
      src={urlFor(source).width(width).auto("format").url()}
      alt={alt}
      loading="lazy"
    />
  );
}
```

---

## Anti-Patterns

| Do NOT do this | Do this instead | Why |
|----------------|-----------------|-----|
| `createClient({...})` inside a component | Import `sanityClient` from `client/src/lib/sanity.ts` | Creates a new client instance on every render; config can drift between components |
| GROQ query without typing the response | Parse with `z.safeParse()` using a Zod schema | Sanity Studio schema changes silently break the frontend without runtime validation |
| `<img src={\`https://cdn.sanity.io/images/...\`}>` | `<img src={urlFor(source).width(400).url()}>` | Manual URLs skip cropping, hotspot, and format optimization |
| Fetching CMS data inside every nested component | Fetch once at page level, pass data as props | Causes waterfall requests and redundant network calls |
| `key={index}` on CMS content lists | `key={item._id}` | Content order changes in Sanity Studio cause incorrect re-renders with index keys |
| Rendering `{member.bio}` without null check | `{member.bio && <p>{member.bio}</p>}` | CMS fields can be empty — renders `null` or crashes on `.length` |
| Omitting `apiVersion` on client | Always set `apiVersion: "2024-01-01"` | Without it, Sanity uses the latest API, which may introduce breaking changes |

---

## Verification Checklist

Before marking a task as done, confirm:

- [ ] A single `sanityClient` instance exists in `client/src/lib/sanity.ts`
- [ ] All GROQ responses are validated against a Zod schema in `client/src/schemas/`
- [ ] All Sanity images use the `urlFor()` builder, not manual CDN URLs
- [ ] CMS data is fetched at page level, not inside deeply nested components
- [ ] All CMS list renders use `_id` as the React key, not array index
- [ ] Nullable CMS fields have null checks before rendering
- [ ] `apiVersion` is explicitly set on the Sanity client
