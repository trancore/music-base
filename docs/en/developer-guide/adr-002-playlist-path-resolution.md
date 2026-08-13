# ADR-002: Playlist path resolution

## Status

Accepted

## Decision

Manual playlists and M3U imports store source paths and resolve them through an index combining the library database's `source_key` with a normalized comparison path. Only Windows drive paths normalize separators and case; POSIX and SMB path case is preserved.

When an M3U source root differs from the active source, the app offers only root replacements that resolve to tracks present in the current cache. Confirmed matches are stored using the database's actual source paths, while unresolved paths retain their original order.

## Rationale

The visible library has pagination and filters, so using it for playlist resolution makes results depend on UI state. Treating the database index as the lookup source provides stable results for large libraries without loading the entire cache into memory. Retaining unresolved paths also allows recovery after reconnecting a drive or SMB share.
