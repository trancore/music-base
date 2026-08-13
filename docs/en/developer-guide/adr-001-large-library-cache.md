# ADR 001: Large-library cache

## Decision

Use SQLite as the canonical list, search, and playback-order cache for libraries of up to 100,000 tracks. Lists use 200-row keyset pages, search uses FTS5 word-prefix matching, and artwork is SHA-256 deduplicated and loaded on demand.

Rescans parse metadata only when path, modification time, or size changes. Scan results are applied in one transaction only after the complete traversal succeeds. Local traversal and synchronous metadata parsing run in a dedicated isolate. The UI retains its pre-scan page while a rescan runs and reloads it after completion. A failed scan also preserves the displayed cache. SMB failures temporarily fall back to the most recently selected local source.

## Rationale

Materializing every track and image, sorting every row in memory, and building every row widget scale linearly with the library. Moving search, ordering, and image management into the database lets the UI and playback service fetch only the required working set.
