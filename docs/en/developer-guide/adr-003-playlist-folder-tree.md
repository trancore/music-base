# ADR-003: Playlist folder tree

## Status

Accepted

## Decision

Playlists and folders are stored as an adjacency list with an optional parent folder ID. Items without a parent appear at the top level, and recursive parent references allow folders to nest to any depth. Playlists within one level are ordered by `sortOrder`; drag operations persist both movement and reordering.

A folder can be deleted only while empty. A folder cannot be moved into itself or one of its descendants. Existing persisted playlists receive the default parent value and remain at the top level.

## Rationale

M3U represents track order, not application-specific folder hierarchy. Persisting organization as independent user-managed data avoids inferring structure from media paths and keeps playlist organization separate from source changes and library rescans.

## Consequences

- An M3U import can target the top level or an existing folder.
- Moving a playlist never moves its audio files.
- Child folders and playlists must be moved or deleted before their folder can be deleted.
