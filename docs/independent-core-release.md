# Independent Windows core releases

The core executable is **FlClashCore.exe**, built from the host adapter at
`core/cmd/core` in a pinned FlClashZ source commit and a pinned Mihomo gitlink.
The stock Mihomo CLI cannot replace it. Keep one Go module graph and the
existing core build flags; do not introduce a second copy of the adapter.

## Release identity and compatibility

Use an independent version `v<major>.<minor>.<patch>-z.<revision>`, where the
first three numbers identify the upstream Mihomo version and the final number
is a positive core release revision. Use release tags `flclashz-core-<version>`
to avoid triggering the upstream Mihomo v* release workflow. Version and SHA
are independent of the Flutter application version.

`FlClashCore.exe --core-info` prints a single JSON object and exits without
starting the IPC server. It reports product, version, mihomoVersion,
engineRevision, hostRevision, ipcRevision, os and arch. Standalone release
builds inject version and both SHAs at link time. IPC revision 1 is the
candidate baseline, not evidence of verified backwards compatibility.
Increment it for breaking changes; additive changes require contract tests.

## Update trust and transaction

Use a distinct signed core manifest domain; sign version, engine and host
SHAs, IPC revision, target, asset name, size and SHA-256. Pin the signing public
key in the trusted client/Helper. The application uses the default signed
release source; there is no local import or manual source selector in the UI. Reject unsigned or incompatible executables before
execution, including before probing --core-info. Refuse downgrade unless a
previous trusted local version is explicitly restored.

A core updater must coordinate exclusively with the existing lifecycle owner.
Verify bytes before stopping the active core, stage safely and retain immutable verified releases, then switch the selection
as a journaled transaction and check initialization/config/listeners/IPC on
restart. Restore the previous selection on failure. The privileged Helper
verifies the signed identity and hash before launch; the protected store
rejects reparse points and non-SYSTEM/Admin ACLs. A user-writable selection
file never authorizes an unsigned executable. Pending journals always name
the previous committed core, so interrupted trials recover at startup.
The bundled executable and its embedded Helper hash remain untouched.

Default source: https://github.com/geliopat/Clash.Meta/releases/latest/download/core-manifest.json
(actual availability begins only after the first independently approved release).
Automatic checks share the application's update check and preference. One
manual check button opens the update confirmation; no automatic installation
and no manual rollback control. Failed activation still restores the previous
working release. No arbitrary URL executable.

## Progress

- Core metadata command and contract test implemented; not compiled.
- Independent workflow, signer and guarded patch replay are implemented in the core repository (`FlClashZ` branch). The core repository default branch is now `FlClashZ` (verified 2026-11-28). No independent build is confirmed.
- Client-side signed manifest parsing, compatibility checks, numeric version ordering and staged binary hashing are implemented with regression fixtures. The retrieval/staging implementation exists in `core_release_updater.dart`; activation and rollback use the selection store and existing restart owner. End-to-end execution remains unverified. The signing key must be provisioned before publication.
- Helper independently verifies Ed25519 manifests and exact executable bytes. New `/core/stage` and `/core/start` endpoints store and start only authenticated, content-addressed releases in an ACL-protected directory adjacent to the Helper. One upload is admitted at a time, with bounded size. Existing bundled hash/launch remains separate.
- The existing downloader is reused for the default HTTPS manifest. Staging is routed through Helper before changing the active version.
- Durable selection journal and rollback worker implemented; a failed candidate restores the last committed selection and reuses the original CoreAction restart worker. CoreAction checks IPC connection, initialized state, actual Mihomo version and configuration/listener restoration, with a short crash observation window. Watchdog does not compete with an active trial. The update UI uses one check action and confirmation, shared by automatic and manual checks.
- Core public key is injected into both Dart and Rust, and included in Helper cache identity.
- Remaining gates: validate the manually reconciled Cargo.lock (registry checksums and dependency metadata were checked; Cargo was unavailable), run formatting/static analysis and Windows security/IPC regression tests after authorization; verify the signing key/variables are provisioned and match (the default branch has already been configured). Do not claim the feature accepted or publish a release before these gates.

