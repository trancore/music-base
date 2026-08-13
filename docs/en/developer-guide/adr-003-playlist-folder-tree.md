# ADR-003: Playlist folder tree

## Status

Accepted

## Decision

Playlists and folders are stored as an adjacency list with an optional parent folder ID. Items without a parent appear at the top level, and recursive parent references allow folders to nest to any depth. Playlists within one level are ordered by `sortOrder`; drag operations persist both movement and reordering.

A folder can be deleted only while empty. A folder cannot be moved into itself or one of its descendants. Existing persisted playlists receive the default parent value and remain at the top level.

## Rationale

M3U and MusicBee MBP represent track order, but not this application's folder hierarchy. Persisting organization as independent user-managed data avoids inferring structure from imported media paths and keeps playlist organization separate from source changes and library rescans.

## Consequences

- A playlist-file import can target the top level or an existing folder.
- Moving a playlist never moves its audio files.
- Child folders and playlists must be moved or deleted before their folder can be deleted.
