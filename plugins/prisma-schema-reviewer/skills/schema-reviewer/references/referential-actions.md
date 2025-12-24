# Referential Actions Reference

`onDelete` and `onUpdate` control what happens to related records when parent is modified.

## Action Types

| Action | Behavior | Use Case |
|--------|----------|----------|
| `Cascade` | Delete/update related records automatically | Child records that shouldn't exist without parent |
| `SetNull` | Set FK to NULL when parent deleted | Optional relationships, preserve history |
| `Restrict` | Prevent deletion if children exist | Protect important data |
| `NoAction` | Database handles (defers check in PostgreSQL) | Self-relations, complex cascades |

## Decision Tree

```
Is the child record meaningful without the parent?
│
├── NO → Use Cascade
│        Example: Delete all UserSkill when User deleted
│
└── YES → Should the reference be preserved?
          │
          ├── YES → Use SetNull (field must be nullable!)
          │         Example: User.referredByUserId → keep user, clear reference
          │
          └── NO → Should deletion be prevented?
                   │
                   ├── YES → Use Restrict
                   │         Example: Can't delete Skill if users have it
                   │
                   └── NO → Use NoAction
                            Example: Self-relations, complex cascades
```

## Code Examples

### Cascade (Delete children with parent)

```prisma
model Post {
  id       Int    @id
  author   User   @relation(fields: [authorId], references: [id], onDelete: Cascade)
  authorId Int
}
// When User deleted → all their Posts are automatically deleted
```

### SetNull (Preserve child, clear reference)

```prisma
model User {
  referredByUserId String?  // MUST be nullable for SetNull
  referredByUser   User?    @relation(fields: [referredByUserId], references: [id], onDelete: SetNull)
}
// When referring user deleted → this user remains, referredByUserId becomes NULL
```

### Restrict (Prevent deletion)

```prisma
model Skill {
  users UserSkill[]  // Implicit Restrict
}
// Cannot delete Skill if any UserSkill records reference it
```

### NoAction (Required for self-relations)

```prisma
model Employee {
  id        Int        @id
  managerId Int?
  manager   Employee?  @relation("management", fields: [managerId], references: [id], onDelete: NoAction, onUpdate: NoAction)
  managees  Employee[] @relation("management")
}
// Required to break circular dependency in self-relations
```

## Default Behaviors

If not specified, Prisma applies defaults:

| Relation Type | Default onDelete | Default onUpdate |
|---------------|------------------|------------------|
| Required (non-nullable FK) | `Restrict` | `Cascade` |
| Optional (nullable FK) | `SetNull` | `Cascade` |

**Best Practice**: Always specify explicitly to be clear about intent.

## Common Patterns

### Join Tables (Cascade both sides)

```prisma
model UserSkill {
  user  User  @relation(fields: [userId], references: [id], onDelete: Cascade)
  skill Skill @relation(fields: [skillId], references: [id], onDelete: Cascade)
}
// Delete UserSkill when either User OR Skill is deleted
```

### Analytics (Cascade from parent)

```prisma
model UserAnalytics {
  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
}
// Delete analytics when User is deleted (no orphan data)
```

### Referrals (SetNull to preserve history)

```prisma
model User {
  referredByUserId String?
  referredByUser   User? @relation(fields: [referredByUserId], references: [id], onDelete: SetNull)
}
// If referring user deleted, keep this user but clear the reference
```

## Anti-Patterns

```prisma
// BAD: SetNull on non-nullable field
model Post {
  authorId Int  // Non-nullable!
  author   User @relation(fields: [authorId], references: [id], onDelete: SetNull)
  // ERROR: Cannot SetNull on required field
}

// BAD: Missing explicit action
model Post {
  author   User @relation(fields: [authorId], references: [id])
  // Unclear intent - will use default Restrict
}

// BAD: Self-relation without NoAction
model Employee {
  manager Employee? @relation(fields: [managerId], references: [id])
  // ERROR: Self-relation requires NoAction
}
```

## Context7 Query

```
Library: /prisma/docs
Topic: referential actions onDelete Cascade SetNull Restrict NoAction
```
