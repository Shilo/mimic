# Mimic Multiplayer

Clone-and-play multiplayer for Godot. Drop in a `MimicSync` node and make your scenes network-aware, with high-level nodes for connection and gameplay.

Mimic Multiplayer is a Godot 4 addon for making the first steps of high-level multiplayer easier to author. Add Mimic to a project, use the `Mimic` singleton or `MimicConnector` to host and join, and keep scene synchronization close to Godot's native `MultiplayerSynchronizer` workflow.

<div class="mimic-hero-actions">
<p>
<a class="md-button md-button--primary mimic-play-button" href="play/" title="Play Showcase" aria-label="Play Showcase" target="_blank" rel="noopener">Play Showcase</a>
<a class="md-button" href="quick_start/">Quick Start</a>
<a class="md-button" href="installation/">Installation</a>
<a class="md-button" href="api/">API Reference</a>
</p>
</div>

<div class="mimic-callout" markdown>
Mimic is intentionally smaller than full netcode frameworks. It helps with connection setup, project settings, and a simple component model while staying aligned with Godot's built-in high-level multiplayer API.
</div>

## What Mimic Does Now

- Manages a plugin-installed `Mimic` autoload.
- Starts and stops ENet and WebSocket server/client peers.
- Provides an offline state placeholder and a reserved WebRTC transport option.
- Exposes typed Project Settings for connection defaults.
- Emits compact connection lifecycle signals.
- Provides `MimicConnector` for simple host/join/stop entry points.
- Provides `MimicSync`, a visible per-entity component that subclasses `MultiplayerSynchronizer`.

## What Mimic Does Not Do Yet

- Automatic dynamic spawn/despawn replication.
- Late-join spawn replay.
- Built-in UI controls.
- Prediction, rollback, interpolation, lag compensation, matchmaking, relay, or raw packet protocols.

## What To Read Next

- [Installation](installation.md) if Mimic is not in your project yet.
- [Quick Start](quick_start.md) to run a local host/client pair.
- <a href="play/" title="Play Showcase" aria-label="Play Showcase" target="_blank" rel="noopener">Play Example</a> to launch the web export when you want to try Mimic before opening the project.
- [MimicConnector](nodes/mimic_connector.md) if you want scene-driven connection startup.
- [MimicSync](nodes/mimic_sync.md) if you are preparing entities for synchronization.
- [Netfox](other_multiplayer_addons/netfox.md) if you are choosing between Mimic and a larger multiplayer framework.
