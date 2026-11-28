# Native Mihomo integration: v1.1.5

Status: pinned core candidate; independent core release infrastructure is the current stage. Previously started integration is preserved. No build or validation workflow may run until agreed implementation and static review are complete.

Checkpoint: `archive/v1.1.5-before-core-integration` at `64b3a6a1f8285f32822eceb5eac192eb0e9a381f`. Keep this branch unchanged for rollback.

Core repository: https://github.com/geliopat/Clash.Meta
- Clean Mihomo v1.19.34: `mihomo-upstream`, `0455d0d28c4526937380505153e65a843d8612e8`
- Original FlClash fork reference: `FlClash`, `fea29264f541cba170bb8b7dda84697aa1dbcc3b`
- FlClashZ candidate: `FlClashZ`, `2732d34e4b32d5b5d1f8d36223d77b4813babaa7`
- Provenance and replay guide: https://github.com/geliopat/Clash.Meta/blob/5a55a1bb96d9b62a73c5463f333c5afb1f8b3762/docs/flclashz-patch-stack.md

## Mandatory development order (user-approved)

1. Independent core infrastructure: pristine upstream reference, reviewable patch replay, pinned independent Windows core build, signed releases, compatibility contract and safe replacement/rollback infrastructure. No automatic installation. Default release source is geliopat/Clash.Meta; allow a manual HTTPS manifest URL and a signed local package. No validation/build dispatch without explicit approval.
2. Core: complete the remaining native integration, review, optimize, minimize patches, and preserve IPC compatibility.
3. Client: integrate core features and independently review all existing implementations in FlClash, FlClashX and FlClashZ. Identify semantic duplicates, competing timers, caches, IPC requests and lifecycle owners. Select or combine the best implementation by correctness, security, performance and maintainability. Remove superseded code only after equivalent behavior is verified. Preserve the agreed design, Remnawave, Helper, Zapret2 and settings ownership. Complete update UI and all v1.1.5 acceptance items.
4. Full validation/build only on explicit authorization; no stable publication without explicit approval.

Do not advance to the next stage until the previous stage's implementation and static review are complete. Runtime validation remains a separate authorized gate. Do not ask again for the order.

## Permanent development principles — obsolete functionality (user-approved)

- For every update of the core, adapter, Helper, Zapret2 or upstream client, compare supported functionality and parameters against the exact pinned source revision and actual Windows behavior. Do not retain obsolete, removed, ignored, superseded, redundant or unsupported platform-specific controls as available features.
- Prefer the current native implementation. Remove obsolete UI, settings entries, duplicated execution paths, unused IPC, timers, wrappers and tests for retired behavior. Replace superseded implementations with the current equivalent; do not keep two active implementations for compatibility.
- Preserve existing user data and original subscription/resource files. If legacy input has a current equivalent, translate it at the import/configuration boundary, preserving its semantics; prefer one-way migration of stored local settings when safe. Keep only the minimal compatibility reader needed for existing data. Do not expose obsolete controls again. If conversion is ambiguous or impossible, explicitly document the limitation and avoid silently inventing a new meaning or discarding supported user settings.
- Add every new supported user-facing core feature in its appropriate existing UI section, with accurate availability/limits and no duplicate navigation. Native internal mechanisms do not require artificial controls.
- Verify actual effective configuration, IPC, persistence, migration and UI behavior against the selected core. Tests must cover modern and legacy inputs and confirm that removed features cannot be reintroduced by normal UI actions. Do not roll back the selected core to retain obsolete client behavior.
- Apply this principle during each review/refactoring and upstream sync, not only v1.1.5. It does not authorize removal of still-supported features, data loss, workflow dispatch, compilation or release without the agreed approval.

## Detailed implementation tasks (within the stages above)

1. Review candidate patch dependencies and compile compatibility statically; complete remaining selected core fixes. Do not copy unrelated platform, TLS or listener changes.
2. Pin a core revision by commit, using upstream sing-tun without a local replacement. Prefer a pinned Git submodule/local Go module replacement; update only the checkout/build inputs that need it. Do not update production releases.
3. Replace host-side duplicate accounting with native counters and request events, preserving early inbound closure and probe-route settlement. Move DNS and URL-test notifications into hooks, with the same bounded queues and inactive-host behavior. Use native route resolution and network resets, preserve route epoch checks and held picks. Do not count bytes twice or run two health/geo schedulers. Keep existing IPC messages compatible; version new fields explicitly and preserve unknown ones. Add contract regressions.
4. Adapt the FlClash connection log, typed numeric samples, incremental rows and filters to the existing FlClashZ UI. One lifecycle-aware publisher for traffic and active connection statistics; controls, sidebar, dashboard and details use projections from the same state.
5. Merge optional general overrides with the existing per-key ownership, inheritance, explicit values, resource URLs/paths, protected TUN settings and managed Remnawave locks. Retain old migration and recovery compatibility.
6. Complete the rest of docs/next-release-acceptance.md, static review, and only then user-authorized Windows testing. No stable release without explicit approval.

Preserve all existing FlClashZ features, UI, Helper security, Zapret2 strategy and recovery behavior. Source-code work is not equivalent to acceptance. Client now pins the candidate as a Git submodule at core/third_party/mihomo. Run git submodule update --init after checkout. The macOS-only sing-tun patch and local replacement were removed; use the version selected by Mihomo and the root Go module. Native integration and acceptance are not complete.

## Client integration progress

- Pinned local Mihomo module, with the upstream sing-tun dependency and manual validation submodule checkout.
- Native tracker counters, new-request hook, early pending inbound ownership, native DNS record and ClearAll, route matcher and synchronized proxy/provider snapshots. Native provider mapping replaces approximate override replay while retaining path/membership checks.
- Native delay events include proxy identity and history timestamp; old results are rejected, bounded overflow reconciles histories. No periodic full-history scan remains.
- Native failed dials use the existing request message with optional failure and closedAt fields. Old payloads remain readable. UI marks the failure and avoids claiming a successful egress. Generated model files were updated alongside source; code-generation and compatibility still need verification.
- Actual connection leaf type distinguishes same-name DIRECT and proxied outbounds. Network-change resets include provider-owned transports.
- Native regression packages are included in the manual-only validation workflow. No build, test execution or workflow dispatch yet.
- Still open: host-wide configurable health-check timeout, end-to-end IPC/load and race review, indexed connection/history storage and typed samples, shared statistics publisher, compound filtering and DNS-to-connection association, general override ownership and remaining release acceptance.
