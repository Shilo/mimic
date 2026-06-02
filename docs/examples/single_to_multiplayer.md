# Single To Multiplayer Example

The `examples/single_to_multiplayer/` scene is the current sample for adapting a simple single-player scene toward Mimic networking.

Open:

```text
res://examples/single_to_multiplayer/single_to_multiplayer.tscn
```

The example is intentionally small. It exists to show the current connection and component flow, not to demonstrate prediction, rollback, interpolation, matchmaking, or production networking.

The startup scene contains a `MimicConnector` with `auto_connect_mode` set to `Server If First Else Client`, then logs Mimic connection signals from its scene script. The folder also includes a tiny movable player scene as single-player material to adapt later; it is not a complete networked gameplay scene yet.

## Playable Web Build

The GitHub Pages workflow exports this example as a single-threaded Godot Web build through `tools/export_web_example.ps1` and the `Docs Web Example` export preset.

When published, it is part of the single playable example hub at:

```text
play/
```

The Web build is a static browser client. It cannot host a multiplayer server on GitHub Pages.
