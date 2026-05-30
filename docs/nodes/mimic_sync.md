# MimicSync

`MimicSync` is the visible per-entity synchronization component for Mimic networked scenes.

It intentionally subclasses Godot's `MultiplayerSynchronizer`, so you can keep using Godot's native `SceneReplicationConfig` workflow for property replication.

## Basic Setup

1. Add `MimicSync` as a child of the node you want to sync.
2. Set or confirm its `root_path`.
3. Assign a `SceneReplicationConfig`.
4. Choose the properties Godot should replicate.

## Current Scope

Runtime property replication is still Godot's native `MultiplayerSynchronizer` behavior. Mimic does not yet replace `MultiplayerSpawner` or perform automatic dynamic spawning in the current connection MVP.

## API

See the generated [`MimicSync` API reference](../api/mimic_sync.md).
