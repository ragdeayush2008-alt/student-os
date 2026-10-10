# Student OS — Admin System

> This document defines a scalable **admin control system** for the Student OS platform. It is a **blueprint only** — **nothing here is implemented.** The admin system is designed to keep the platform healthy and curated while requiring minimal manual effort.

## Overview

The admin system is a separate, privileged surface used by platform administrators (not students). It centralizes control over users, content, configuration, notifications, rewards and analytics. A key goal is **automation**: routine content (e.g., daily challenges, announcements, reminders) is generated or scheduled so admins do not need to create it manually every day.

## Roles & Access

- **Super Admin** — full control over all admin areas and other admins.
- **Content Admin** — manages notices, banners, announcements, campaigns, content.
- **Moderator** — community moderation and content review.
- **Support/User Admin** — user management and support actions.
- Access is permission-scoped; least privilege by default. All actions are audited.

## Admin Dashboard

Central landing view for admins summarizing live platform health:

- Key metrics (active users, DAU/WAU/MAU) at a glance.
- Recent activity and alerts.
- Pending moderation queue count.
- Scheduled automation status (pending/failed campaigns).
- System status of backend services.

## User Management

- Search, view and inspect student accounts (respecting privacy).
- View account lifecycle state (see [USER_SYSTEM.md](./USER_SYSTEM.md)).
- Actions: view details, deactivate/reactivate, and, where permitted, suspend accounts.
- Support against abuse while preserving student data ownership.
- Admin user management (create, assign roles/perms) for admins themselves.

## Content Management

### Global Notices
- Create, publish, schedule and expire global notices shown to students.
- Target by audience (all users, region, path, segment).

### Banners
- Manage static/promotional banners and their placement and scheduling.
- Traffic-light placement that does not overwhelm the student UI.

### Announcements
- Scheduled announcements with publish/unpublish lifecycle.
- Optional targeting and quiet-scheduling.

## Promotions & Offers

Aims to be **non-intrusive**:
- Manage promotional content (educational offers, informational calls-to-action, partner-free content).
- Placement limited and clearly non-intrusive per the vision (free, not ad-driven).
- Schedule rotation and expiry; measure impression but never via invasive tracking.

## Campaigns & Automation

The automation engine reduces manual work:

### Scheduled Campaigns
- Define recurring campaigns with a cadence (daily, weekly).
- **Auto-generate routine content**: daily challenges, daily tips, weekly recaps, motivational/revision reminders.
- Use content templates so no manual daily authoring is required.
- Dry-run/preview before publishing.

### Automation Rules
- Templates + scheduling engine + audience targeting.
- Rollout to users as in-app/notification content.
- Automation failures alert admins (visibility in dashboard and logs).

## Moderation

- Community content review queue (see [APP_MODULES.md](./APP_MODULES.md) community domain).
- Approve / reject / remove violating content.
- User-level moderation actions where policy permits.
- Moderation decisions are audited.

## Feature Control

- **Feature flags** to enable/disable features globally or by segment.
- Gradual rollout (percent-based, phased) of new modules.
- Kill-switch to disable a feature quickly if issues arise.

## Reward Management

Although the platform is free, the admin manages reward-related content:
- Manage reward definitions, points/badge catalog.
- Auto-generate daily/weekly reward challenges.
- Oversee reward issuance rules without manual daily effort.

## Analytics

- Platform-level analytics dashboards (active users, engagement, adoption of modules).
- Aggregate metrics only; no individual tracking that violates privacy.
- Insight into automation performance and content reach.

## Configuration

- Centralized platform configuration (settings surfaced to features).
- Manage roles/permissions and admin accounts.
- Manage thresholds (e.g., reward limits, moderation thresholds).

## Emergency Controls

Quick actions to protect the platform and users during incidents:
- Global disable or throttle of specific features (kill-switch).
- Suspend all admin-created campaigns/announcements at once.
- Emergency notice to all users.
- Graceful degradation paths when backend services are degraded.

## Audit Logging

- Every admin action is recorded (who, what, when, targeting, result).
- Immutable, append-only log for accountability and investigation.
- Separate from student data; log retention configurable.
- Automation-generated actions are logged with their automation source.

## Scalability & Non-Goals

- Admin UI is built to scale with many admins and high content volume via automation and scheduling.
- **Non-goals:** no advertising platform, no invasive tracking, no paid admin tiers, no implementation now.

_See [ROADMAP.md](./ROADMAP.md) for when the admin system is built (post-foundation phases)._
