# Index Strategy Reference

Indexes improve query performance but have write overhead trade-offs.

## Golden Rule: Index All Foreign Keys

From Prisma docs: "Relation scalar fields like `postId` that refer to another model's primary key are not automatically indexed. Queries filtering by that field may require full table lookups."

```prisma
// REQUIRED: Every FK needs an index
model DoctorSpecialty {
  doctorId    String
  specialtyId String

  doctor    Doctor     @relation(fields: [doctorId], references: [id], onDelete: Cascade)
  specialty Speciality @relation(fields: [specialtyId], references: [id], onDelete: Cascade)

  @@index([doctorId])      // Required for JOIN on doctor
  @@index([specialtyId])   // Required for reverse lookups
}
```

## Index Decision Matrix

| Query Pattern | Index Type | Example |
|---------------|------------|---------|
| `WHERE fk = ?` | Single column | `@@index([doctorId])` |
| `WHERE a = ? AND b = ?` | Composite (selective first) | `@@index([status, date])` |
| `WHERE a = ? ORDER BY b` | Composite | `@@index([status, createdAt])` |
| `WHERE array @> ?` | GIN | `@@index([tags], type: Gin)` |
| `WHERE text ILIKE '%?%'` | Consider full-text | PostgreSQL tsvector |

## Composite Index Rules

### 1. Most Selective Field First

Put the field with most unique values first:

```prisma
// GOOD: profileStatus has few values, createdAt has many
// Query: WHERE profileStatus = 'ACTIVE' ORDER BY createdAt DESC
@@index([profileStatus, createdAt])

// BAD: Less selective field first hurts performance
@@index([createdAt, profileStatus])
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
model Condition {
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
const conditions = await prisma.condition.findMany({
  where: {
    searchTerms: {
      hasSome: ["back pain", "spine", "lower back"]
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
model Doctor {
  id                String @id @default(cuid())
  userId            String @unique
  email             String @unique
  gmcNumber         String @unique @db.VarChar(10)
  applicationStatus ApplicationStatus
  profileStatus     ProfileStatus
  referredByDoctorId String?
  createdAt         DateTime @default(now()) @db.Timestamptz(6)

  // Foreign key indexes
  @@index([referredByDoctorId])

  // Query pattern indexes
  @@index([applicationStatus])         // Filter by status
  @@index([profileStatus])             // Filter visible doctors
  @@index([email])                     // Lookup by email
  @@index([gmcNumber])                 // Lookup by GMC
  @@index([createdAt])                 // Sort by newest
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
