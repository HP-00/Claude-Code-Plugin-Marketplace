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
│        Example: Delete all DoctorSpecialty when Doctor deleted
│
└── YES → Should the reference be preserved?
          │
          ├── YES → Use SetNull (field must be nullable!)
          │         Example: Doctor.referredByDoctorId → keep doctor, clear reference
          │
          └── NO → Should deletion be prevented?
                   │
                   ├── YES → Use Restrict
                   │         Example: Can't delete Speciality if doctors have it
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
model Doctor {
  referredByDoctorId String?  // MUST be nullable for SetNull
  referredByDoctor   Doctor?  @relation(fields: [referredByDoctorId], references: [id], onDelete: SetNull)
}
// When referring doctor deleted → this doctor remains, referredByDoctorId becomes NULL
```

### Restrict (Prevent deletion)

```prisma
model Speciality {
  doctors DoctorSpecialty[]  // Implicit Restrict
}
// Cannot delete Speciality if any DoctorSpecialty records reference it
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

## Common Patterns for IWAD

### Join Tables (Cascade both sides)

```prisma
model DoctorSpecialty {
  doctor    Doctor     @relation(fields: [doctorId], references: [id], onDelete: Cascade)
  specialty Speciality @relation(fields: [specialtyId], references: [id], onDelete: Cascade)
}
// Delete DoctorSpecialty when either Doctor OR Speciality is deleted
```

### Analytics (Cascade from Doctor)

```prisma
model DoctorAnalytics {
  doctor Doctor @relation(fields: [doctorId], references: [id], onDelete: Cascade)
}
// Delete analytics when Doctor is deleted (no orphan data)
```

### Referrals (SetNull to preserve history)

```prisma
model Doctor {
  referredByDoctorId String?
  referredByDoctor   Doctor? @relation(fields: [referredByDoctorId], references: [id], onDelete: SetNull)
}
// If referring doctor deleted, keep this doctor but clear the reference
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
