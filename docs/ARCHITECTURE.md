# Student OS — Architecture

> This document describes the **intended** architecture for a scalable Flutter application. It is a specification only. **The architecture is not implemented yet.**

## Goals

- Scale gracefully from a small, free app to a larger multi-student platform.
- Keep the app free by using free-tier services (Supabase and other free tiers where appropriate).
- Enable modular, maintainable, testable code.

## High-Level Overview

Student OS is a Flutter application with a client-heavy architecture backed by a managed backend. Most business logic lives in the Flutter app (feature modules), while the backend provides authentication, data persistence, and realtime capabilities.

```
┌─────────────────────────────┐
│        Flutter App          │
│  ┌───────┐ ┌───────┐  ...   │
│  │Feature│ │Feature│        │
│  │Module │ │Module │        │
│  └───┬───┘ └───┬───┘        │
│      └────┬────┘            │
│      Core / Shared         │
└───────────┬────────────────┘
            │ (HTTPS / realtime)
     ┌──────┴──────┐
     │   Supabase   │  (Postgres + Auth + Storage + Realtime)
     └──────────────┘
```

## Key Components

### Feature Modules
The application is organized into independent, modular feature areas (e.g., productivity, preparation, achievement, planning, milestones). Each feature owns its UI, its domain models, and its data-access logic. Features communicate only through clear interfaces, not by reaching into each other's internals.

### Core / Shared Layer
A shared layer provides cross-cutting utilities used by all features:
- Routing / navigation
- Theming & design system
- Common widgets
- Networking / API client
- Error handling and state management primitives
- Environment configuration

### Backend Services
Selected free-tier services to use where available:

- **Supabase** — recommended primary backend:
  - **PostgreSQL** database (relational storage)
  - **Auth** (email, OAuth/social login)
  - **Storage** (file/asset storage)
  - **Realtime** (live sync / subscriptions)
  - **Edge Functions** (server-side logic when needed)
- Other free/open-source services may be adopted on a case-by-case basis where they clearly fit and remain within free tiers.

## Data & State

- **Local state / UI state** — managed per feature within the app.
- **Server persistence** — Supabase (Postgres). Data is synced between client and server.
- **Offline support** — where feasible, cache locally and sync when connectivity returns.

## Scalability Considerations

- Modular boundaries keep the codebase understandable as it grows.
- Feature-first organization allows teams to scale without global rewrites.
- Relational data model in Postgres allows rich queries as features evolve.
- Realtime and storage capabilities can be added incrementally without re-architecting.

## Security & Privacy

- All secrets (API keys, credentials) are held in secure environment configuration — never committed or hard-coded.
- Authentication is handled by the backend provider; the app never stores raw passwords.
- Access control (Row Level Security in Postgres) scopes users to their own data.

## Implementation Plan (Future)

The architecture will be implemented in later phases, in alignment with the milestones in [CURRENT_PHASE.md](./CURRENT_PHASE.md) and governed by the rules in [DEVELOPMENT_RULES.md](./DEVELOPMENT_RULES.md).

_This document intentionally contains no implementation code._
