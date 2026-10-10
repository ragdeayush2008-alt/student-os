# Sync Architecture — Phase 25

## Model
- Local-first: controllers write to StorageService (user-scoped keys: `uos_${userId}_`)
- Offline mutations queued in SyncQueue (persistent via StorageService)
- SyncEngine flushes queue to Supabase when network available
- Conflict: last write wins (queue collapses same record mutations)

## Conflict Strategy
- Queue removes earlier mutations for same (table, recordId) before adding new
- Retry count incremented on failure; permanent failure after retries
- Server state authoritative for XP, rewards, entitlements
- User-scoped RLS enforced on all mutations

## Account Isolation
- All repository queries use `user_id = auth.user.id`
- SyncQueue uses `AuthService.instance.user?.id ?? 'demo'`
- StorageService prefixes all keys with user id
- No cross-account data leakage possible

## Safety
- Failed mutations preserved in queue after restart
- No infinite retry loops (retryCount tracked)
- Offline creates work; online reconciles
- No client-side privilege escalation for Premium/entitlements
