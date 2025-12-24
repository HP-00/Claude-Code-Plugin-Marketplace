# Index Strategy Reference

Indexes improve query performance but have write overhead trade-offs.

## Golden Rule: Index All Foreign Keys

From Prisma docs: "Relation scalar fields like `postId` that refer to another model's primary key are not automatically indexed. Queries filtering by that field may require full table lookups."

```prisma
// REQUIRED: Every FK needs an index
model PostTag {
  postId    String
  tagId     String

  post      Post @relation(fields: [postId], references: [id], onDelete: Cascade)
  tag       Tag  @relation(fields: [tagId], references: [id], onDelete: Cascade)

  @@index([postId])      // Required for JOIN on post
  @@index([tagId])       // Required for reverse lookups
}
```

## Index Decision Matrix

| Query Pattern | Index Type | Example |
|---------------|------------|---------|
| `WHERE fk = ?` | Single column | `@@index([authorId])` |
| `WHERE a = ? AND b = ?` | Composite (selective first) | `@@index([status, date])` |
| `WHERE a = ? ORDER BY b` | Composite | `@@index([status, createdAt])` |
| `WHERE array @> ?` | GIN | `@@index([tags], type: Gin)` |
| `WHERE text ILIKE '%?%'` | Consider full-text | PostgreSQL tsvector |

## Composite Index Rules

### 1. Most Selective Field First

Put the field with most unique values first:

```prisma
// GOOD: status has few values, createdAt has many
// Query: WHERE status = 'ACTIVE' ORDER BY createdAt DESC
@@index([status, createdAt])

// BAD: Less selective field first hurts performance
@@index([createdAt, status])
```

### 2. Match Query Patterns

Index fields in the order they appear in WHERE clauses:

```prisma
// Query: WHERE isActive = true AND displayOrder > 0
@@index([isActive, displayOrder])

// Query: WHERE city = ? AND region = ?
@@index([city, region])
```

## GIN Index for Arrays

PostgreSQL GIN (Generalized Inverted Index) enables efficient array operations:

```prisma
model Article {
  searchTerms String[] @default([])

  @@index([searchTerms], type: Gin)
}
```

**Supported Operations with GIN:**
- `hasSome` - Array overlaps
- `hasEvery` - Array contains all
- `has` - Array contains value

```typescript
// Efficient with GIN index
const articles = await prisma.article.findMany({
  where: {
    searchTerms: {
      hasSome: ["typescript", "prisma", "postgresql"]
    }
  }
})
```

## Index Trade-offs

| More Indexes | Fewer Indexes |
|--------------|---------------|
| Faster reads | Faster writes |
| More storage | Less storage |
| Slower INSERT/UPDATE | Slower SELECT |

**Guidelines:**
- Index columns used in WHERE, JOIN, ORDER BY
- Avoid indexing columns with low cardinality (few unique values) alone
- Each index adds ~10-30% write overhead
- Storage: ~10-20% of table size per index

## Complete Example

```prisma
model User {
  id              String @id @default(cuid())
  organizationId  String
  email           String @unique
  username        String @unique @db.VarChar(50)
  status          UserStatus
  role            UserRole
  referredByUserId String?
  createdAt       DateTime @default(now()) @db.Timestamptz(6)

  // Foreign key indexes
  @@index([organizationId])
  @@index([referredByUserId])

  // Query pattern indexes
  @@index([status])              // Filter by status
  @@index([role])                // Filter by role
  @@index([email])               // Lookup by email
  @@index([createdAt])           // Sort by newest
}
```

## Anti-Patterns

```prisma
// BAD: Missing FK index
model Post {
  authorId Int
  author   User @relation(fields: [authorId], references: [id])
  // Missing: @@index([authorId])
}

// BAD: Indexing low-cardinality column alone
@@index([isActive])  // Only true/false - not selective

// GOOD: Composite with selective column
@@index([isActive, displayOrder])  // isActive filters, then sorts
```

## Context7 Query

```
Library: /prisma/docs
Topic: index strategy @@index GIN composite foreign key
```
