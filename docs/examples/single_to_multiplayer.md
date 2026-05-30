# Single To Multiplayer Example

The `examples/single_to_multiplayer/` scene is the current sample for adapting a simple single-player scene toward Mimic networking.

Open:

```text
res://examples/single_to_multiplayer/single_to_multiplayer.tscn
```

The example is intentionally small. It exists to show the current connection and component flow, not to demonstrate prediction, rollback, interpolation, matchmaking, or production networking.

## Playable Web Build

The GitHub Pages workflow is expected to export this example as a single-threaded Godot Web build.

When published, it is part of the single playable example hub at:

```text
play/
```

The Web build is a static browser client. It cannot host a multiplayer server on GitHub Pages.
