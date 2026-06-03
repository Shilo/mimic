# Mimic Multiplayer

<picture class="mimic-hero-logo">
  <source srcset="brand/logo/mimic_m_multiplayer.svg" type="image/svg+xml">
  <img src="brand/logo/mimic_m_multiplayer.png" alt="Mimic Multiplayer" width="700">
</picture>

Clone-and-play multiplayer for Godot. Drop in a `MimicSync` node and make your scenes network-aware, with high-level nodes for connection and gameplay.

Mimic Multiplayer is a Godot 4 addon for making the first steps of high-level multiplayer easier to author. Add Mimic to a project, use the `Mimic` singleton and Project Settings to host and join, and keep scene synchronization close to Godot's native `MultiplayerSynchronizer` workflow.

<div class="mimic-hero-actions">
<p>
<a class="md-button" href="installation/">Installation</a>
<a class="md-button" href="quick_start/">Quick Start</a>
<a class="md-button md-button--primary mimic-play-button" href="https://shilo.github.io/mimic/play/" title="Play Showcase" aria-label="Play Showcase" target="_blank" rel="noopener">Play Showcase</a>
<a class="md-button" href="api/">API Reference</a>
</p>
</div>

<div class="mimic-callout" markdown>
Mimic is intentionally smaller than full netcode frameworks. It helps with connection setup, project settings, and a simple component model while staying aligned with Godot's built-in high-level multiplayer API.
</div>

## What Mimic Does Now

- Manages a plugin-installed `Mimic` autoload.
- Starts and stops ENet and WebSocket server/client peers.
- Provides an offline state, stop/cancel helpers, and status helpers.
- Keeps Offline and WebRTC transport selections explicit: Offline does not start a peer, and WebRTC is reserved but unsupported.
- Exposes typed Project Settings for connection defaults.
- Supports Project Settings auto-connect for startup scenes.
- Can request optional UPnP port forwarding when hosting.
- Emits compact connection lifecycle signals.
- Reserves `MimicConnector` for future connection form UI.
- Provides `MimicSync`, a visible per-entity component that subclasses `MultiplayerSynchronizer`.

## What Mimic Does Not Do Yet

- Automatic dynamic spawn/despawn replication.
- Late-join spawn replay.
- Built-in UI controls.
- WebRTC signaling.
- Prediction, rollback, interpolation, lag compensation, matchmaking, relay services, or raw packet protocols.

## What To Read Next

- [Installation](installation.md) if Mimic is not in your project yet.
- [Quick Start](quick_start.md) to run a local host/client pair.
- <a href="https://shilo.github.io/mimic/play/" title="Play Showcase" aria-label="Play Showcase" target="_blank" rel="noopener">Play Showcase</a> to launch the web export when you want to try Mimic before opening the project.
- [MimicConnector](nodes/mimic_connector.md) if you want to track the future connection form surface.
- [MimicSync](nodes/mimic_sync.md) if you are preparing entities for synchronization.
- [Netfox](other_multiplayer_addons/netfox.md) if you are choosing between Mimic and a larger multiplayer framework.
