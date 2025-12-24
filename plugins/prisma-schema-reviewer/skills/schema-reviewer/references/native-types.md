# PostgreSQL Native Types Reference

Use `@db.*` attributes to specify exact database column types for optimal storage and performance.

## String Types

| Native Type | Storage | Use Case | Example |
|-------------|---------|----------|---------|
| `@db.VarChar(n)` | Variable up to n | Names, titles, slugs (known max) | `name String @db.VarChar(150)` |
| `@db.Char(n)` | Fixed n bytes | Fixed-length codes (ISO, country) | `countryCode String @db.Char(2)` |
| `@db.Text` | Unlimited | Descriptions, content, markdown | `bio String? @db.Text` |

**Best Practice**: Use `@db.VarChar(n)` when you know the maximum length. It saves storage compared to unlimited TEXT.

## Numeric Types

| Native Type | Range | Use Case | Example |
|-------------|-------|----------|---------|
| `@db.SmallInt` | -32K to 32K | Small counters, age | `displayOrder Int @db.SmallInt` |
| `@db.Integer` | -2B to 2B | Standard IDs, counts | `loginCount Int` |
| `@db.BigInt` | ±9 quintillion | Large sequences | `viewCount BigInt` |
| `@db.Decimal(p,s)` | Exact precision | **Money, financial** | `price Decimal @db.Decimal(10,2)` |
| `@db.DoublePrecision` | Approximate | Scientific, coordinates | `latitude Float` |

**Critical**: Never use `@db.Money` for currency - it has precision issues. Use `@db.Decimal(p,s)` instead.

## DateTime Types

| Native Type | Storage | Use Case | Example |
|-------------|---------|----------|---------|
| `@db.Timestamptz(6)` | 8 bytes | Events, audit logs (with TZ) | `createdAt DateTime @db.Timestamptz(6)` |
| `@db.Timestamp(6)` | 8 bytes | Local time (no TZ) | Rarely used |
| `@db.Date` | 4 bytes | Birthdays, due dates | `dateOfBirth DateTime? @db.Date` |
| `@db.Time` | 8 bytes | Daily schedules | `openingTime DateTime @db.Time` |

**Best Practice**: Always use `@db.Timestamptz(6)` for timestamps - it stores in UTC and handles timezone conversion.

## JSON Types

| Native Type | Indexable | Use Case |
|-------------|-----------|----------|
| `@db.Json` | No | Rarely queried, preserve whitespace |
| `@db.JsonB` | **Yes** | **Always prefer** - binary, indexable, faster |

**Always use `@db.JsonB`**:
```prisma
// GOOD
metadata Json? @db.JsonB

// BAD
metadata Json
```

## Code Examples

### Complete Model with Proper Native Types

```prisma
model User {
  id              String   @id @default(cuid())

  // Strings with known max length
  name            String?  @db.VarChar(150)
  email           String   @unique @db.VarChar(255)
  username        String   @unique @db.VarChar(50)

  // Unlimited text content
  bio             String?  @db.Text
  avatarUrl       String?  @db.Text

  // Timestamps with timezone
  createdAt       DateTime @default(now()) @db.Timestamptz(6)
  updatedAt       DateTime @updatedAt @db.Timestamptz(6)
  emailVerifiedAt DateTime? @db.Timestamptz(6)

  // Date-only fields (no time component)
  dateOfBirth     DateTime? @db.Date
  subscriptionEndsAt DateTime? @db.Date

  // JSON binary format
  preferences     Json?    @db.JsonB

  // Arrays
  interests       String[]
}
```

### Anti-Patterns to Avoid

```prisma
// BAD: Missing native types
model BadExample {
  name      String    // Unlimited TEXT when max is known
  createdAt DateTime  // timestamp(3) without timezone
  metadata  Json      // JSON text format, not indexable
  price     Decimal @db.Money  // Money type has precision issues
}

// GOOD: Explicit native types
model GoodExample {
  name      String   @db.VarChar(100)
  createdAt DateTime @db.Timestamptz(6)
  metadata  Json     @db.JsonB
  price     Decimal  @db.Decimal(10, 2)
}
```

## Context7 Query

To fetch latest Prisma native types documentation:
```
Library: /prisma/docs
Topic: PostgreSQL native types @db VarChar Timestamptz JsonB
```
