# Relations Reference

Prisma relation patterns for PostgreSQL.

## One-to-Many Relations

Standard pattern with foreign key on the "many" side:

```prisma
model User {
  id    Int    @id @default(autoincrement())
  posts Post[]
}

model Post {
  id       Int  @id @default(autoincrement())
  author   User @relation(fields: [authorId], references: [id])
  authorId Int

  @@index([authorId])  // REQUIRED: Index on FK
}
```

## Self-Referential Relations

**Critical Rule**: Self-relations MUST use `NoAction` to avoid cycles.

```prisma
// User-to-User referrals
model User {
  id               String   @id @default(cuid())
  referredByUserId String?

  // Self-relation with REQUIRED NoAction
  referredByUser   User?    @relation("UserReferrals", fields: [referredByUserId], references: [id], onDelete: SetNull)
  userReferrals    User[]   @relation("UserReferrals")

  @@index([referredByUserId])
}
```

**Error without NoAction:**
```
Error: A self-relation must have `onDelete` and `onUpdate` referential
actions set to `NoAction` in one of the @relation attributes.
```

## Many-to-Many Relations

### Implicit (Prisma-managed)

Use when you don't need metadata on the relation:

```prisma
model Post {
  id       Int        @id
  tags     Tag[]
}

model Tag {
  id       Int        @id
  posts    Post[]
}
// Prisma creates _PostToTag table automatically
```

### Explicit (with metadata)

Use when you need extra fields like `isPrimary`, `createdAt`:

```prisma
model User {
  id     String      @id @default(cuid())
  skills UserSkill[]
}

model Skill {
  id    String      @id @default(cuid())
  users UserSkill[]
}

// Explicit join table with metadata
model UserSkill {
  id        String   @id @default(cuid())
  userId    String
  skillId   String
  isPrimary Boolean  @default(false)  // Extra metadata!
  createdAt DateTime @default(now()) @db.Timestamptz(6)

  user  User  @relation(fields: [userId], references: [id], onDelete: Cascade)
  skill Skill @relation(fields: [skillId], references: [id], onDelete: Cascade)

  @@unique([userId, skillId])  // Prevent duplicates
  @@index([userId])
  @@index([skillId])
  @@index([isPrimary])
}
```

## Named Relations

Required when multiple relations exist between same models:

```prisma
model User {
  id           Int     @id
  writtenPosts Post[]  @relation("WrittenPosts")
  editedPosts  Post[]  @relation("EditedPosts")
}

model Post {
  id       Int  @id
  author   User @relation("WrittenPosts", fields: [authorId], references: [id])
  authorId Int
  editor   User? @relation("EditedPosts", fields: [editorId], references: [id])
  editorId Int?
}
```

## Relation Checklist

- [ ] All FKs have `@@index`
- [ ] All relations have explicit `onDelete`
- [ ] Self-relations use `NoAction` (or `SetNull` if FK is optional)
- [ ] Many-to-many explicit when metadata needed
- [ ] Named relations when multiple relations between same models
- [ ] `@@unique` on explicit many-to-many join table FKs

## Context7 Query

```
Library: /prisma/docs
Topic: relations self-referential many-to-many explicit implicit
```
