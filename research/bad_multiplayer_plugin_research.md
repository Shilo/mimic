# BAD Multiplayer Plugin Research

Source reviewed: `C:\Programming_Files\Godot\bad-multiplayer-plugin-main`

Date reviewed: 2026-06-03

License note: the reviewed project is MIT licensed. This research should guide Mimic design decisions; never copy code directly. Use references only as design inspiration.

## Summary

BAD Multiplayer has a similar high-level goal to Mimic: reduce the repetitive setup around hosting, joining, peer creation, connection state, and common multiplayer scene flow. Its implementation is more opinionated than Mimic's current direction. BAD is shaped around match-based games with a main menu, loading scene, game scene, player spawner, match-action handler, and optional Noray client-host P2P integration.

The most useful lessons for Mimic are not the match framework itself. The useful parts are the authoring observations:

- Developers benefit from one obvious host/join entry point.
- Network lifecycle events should be normalized and easy to connect to.
- Available transports should be discoverable from UI code.
- Connection UI wants a simple data object or equivalent parameter bundle.
- Dedicated-server startup and local host/client testing should be first-class.
- Scene and gameplay assumptions should stay outside Mimic's core unless explicitly added later.

Mimic already covers several of BAD's strongest connection-layer ideas in a smaller and cleaner way: one public `Mimic` singleton, typed Project Settings, ENet and WebSocket startup, host/client/stop/cancel helpers, lifecycle signals, editor auto-connect, logging, and test automation. BAD reinforces that this connection MVP is a good foundation.

## Reviewed Scope

I reviewed the source-bearing project files, addon files, and examples:

- Root README, addon README, plugin manifests, project settings, and MIT license files.
- `addons/bad.multiplayer/` editor plugin, autoloads, network wrappers, config resource, and match-action scripts.
- `addons/bad.noray/` companion plugin, async helper, and Noray network wrapper.
- `examples/getting_started/` scripts and scene wiring.
- `examples/basic_multiplayer/` scripts and scene wiring.

Binary art assets and `.import` metadata were not analyzed beyond confirming that they support the examples rather than plugin behavior.

## What BAD Multiplayer Provides

BAD's public authoring model is:

- Enable the plugin.
- BAD adds multiple autoloads:
  - `BADMultiplayerManager`
  - `BADNetworkManager`
  - `BADNetworkEvents`
  - `BADSceneManager`
  - `BADMP`
- Game code calls `BADMP.host_game(configs)` or `BADMP.join_game(configs)`.
- Scenes register fixed roles through `BADMP.add_scene(BADSceneManager.MAIN, path)`, `GAME`, and `LOADING`.
- BAD changes scenes during connection startup.
- A `BADMatchActionHandler` node in the game scene listens for normalized network events, spawns players, despawns players, tracks active players, and routes custom match actions.
- Examples still use Godot's native `MultiplayerSpawner`, `MultiplayerSynchronizer`, and `SceneReplicationConfig` manually.

Supported or planned networks:

- Offline through `OfflineMultiplayerPeer`.
- ENet local or dedicated server.
- Noray relay/NAT flow through a separate companion plugin and Netfox/Noray dependencies.
- Steam is listed as a future idea.

## Architecture Notes

### Plugin And Settings

`addons/bad.multiplayer/bad_multiplayer.gd` registers a small settings list and adds five autoloads. Settings include:

- `bad.multiplayer/general/clear_settings`
- `bad.multiplayer/networks/enet`
- `bad.multiplayer/networks/offline`

The companion Noray plugin registers `bad.multiplayer/networks/noray` and enables it only if Netfox's Noray plugin is enabled.

The checked-out `project.godot` also contains a malformed-looking custom settings fragment for the Noray setting. I did not trace whether that came from the current code or an earlier revision, but it is a useful warning: custom Project Settings should stay centralized, typed, and covered by tests.

Mimic relevance:

- Mimic's Project Settings helper is more complete and typed.
- BAD's transport-enabled flags are useful as a UI concept, but Mimic should avoid splitting transport availability across multiple autoloads or companion plugins right now.
- If Mimic later supports optional transport packages, model availability cleanly through `MimicProjectSettings` or a small transport registry, not through global mutable dictionaries.

### Public Singleton

`BADMP` is the preferred public API. It forwards to the other managers, stores `available_networks`, exposes host/join methods, scene registration, match-state helpers, game ID helpers, and manager override hooks.

Mimic relevance:

- Mimic already uses the better version of this idea: one visible `Mimic` singleton instead of a public facade over several autoloads.
- Manager override hooks are not needed for Mimic's current scope and would make the public API harder to stabilize.
- A future `Mimic.get_available_transports()` or `Mimic.get_transport_status()` could help connection UI without exposing implementation managers.

### Network Creation

BAD has a base `BADNetwork` node with transport-specific subclasses:

- `enet_network.gd` creates an `ENetMultiplayerPeer` server or client.
- `offline_network.gd` installs an `OfflineMultiplayerPeer`.
- `noray_network.gd` registers with Noray, handles relay or NAT callback signals, then creates ENet peers.

`BADNetworkManager` dynamically instantiates the selected network script, adds it to the tree, awaits peer creation, and emits either `server_peer_created` or `client_peer_created`.

Mimic relevance:

- BAD's transport-node abstraction is useful if Mimic grows beyond ENet and WebSocket.
- Mimic should not add that abstraction until current transport branching becomes hard to maintain.
- BAD's ENet implementation always returns `OK` after `create_server()` or `create_client()` instead of propagating the returned error. Mimic already handles errors more carefully.
- BAD uses port `8080`; Mimic's dedicated setting and validation are better.

### Network Events

`BADNetworkEvents` normalizes Godot `MultiplayerAPI` events into:

- `on_multiplayer_change`
- `on_server_start`
- `on_server_stop`
- `on_client_start`
- `on_client_stop`
- `on_peer_join`
- `on_peer_leave`

It watches for `multiplayer` changes in `_process()`, reconnects signal handlers when the active `MultiplayerAPI` changes, and tracks server start/stop by polling connection status and `multiplayer.is_server()`.

Mimic relevance:

- Mimic already re-emits peer, client, server, failure, stop, and state-change signals.
- BAD's explicit `server_stop` concept is worth considering. Mimic has `stopped`, `server_disconnected`, and `state_changed`; it may not need a new signal yet, but the research suggests UI code often wants a direct server/client lifecycle vocabulary.
- BAD's `on_multiplayer_change` is a useful future consideration if Mimic supports custom `MultiplayerAPI` instances or per-subtree multiplayer.
- Polling every frame is probably unnecessary for Mimic's current global-autoload model.

### Scene Flow

`BADSceneManager` stores scene names and paths, then calls `change_scene_to_packed` for main menu, loading, and game scenes. `BADMultiplayerManager` shows the loading scene before hosting/joining and loads the game scene after peer creation.

`BADNetworkManager` also has a code comment calling out a race: if the client connection signal and game scene load happen in the wrong order, the server may receive `peer_connected` before the client has loaded the spawn target scene. That is exactly the kind of timing edge Mimic should be careful about if it later reduces spawn/despawn boilerplate.

Mimic relevance:

- Do not copy this into Mimic core.
- Scene switching is game-specific and conflicts with Mimic's goal of being a small helper around Godot's high-level multiplayer API.
- The useful part is the UX insight: users need a simple connector UI and status state. That belongs in `MimicConnector`, not in automatic scene changes.

### Match Actions And Player Spawning

`BADMatchActionHandler` is a gameplay node meant to live in the game scene. It:

- Registers itself with `BADMP`.
- Connects to network lifecycle events.
- Spawns host and peer player scenes.
- Names player nodes by peer ID.
- Sets server authority on player nodes.
- Tracks `_players_in_game`.
- Despawns peers on disconnect.
- Provides overridable `ready_player()` and `get_spawn_point()`.
- Registers child `BADMatchAction` nodes and routes `BADMatchActionInfo` objects to them.

The example match actions implement player-killed and player-respawned behavior, including score and game-over UI state.

Mimic relevance:

- This is mostly outside current Mimic scope.
- Player spawning and spawn point selection are relevant to Mimic's long-term "one MimicSync per entity" goal, but BAD still requires explicit `MultiplayerSpawner`, fixed spawn path, spawnable scenes, player naming, and authority code.
- The match-action router is not a good fit for core Mimic because scoring, respawn, ready states, game over, player reset, and spawn point policy are game-specific.
- A much narrower future Mimic feature could expose lifecycle hooks around peer join/leave and entity registration, without providing match semantics.

### Examples

The getting-started example shows a minimal host/join menu:

- Register main/loading/game scenes.
- Host with `BADNetworkConnectionConfigs.new(BADMP.AvailableNetworks.ENET, "localhost")`.
- Join with `BADNetworkConnectionConfigs.new(BADMP.AvailableNetworks.ENET, "localhost", 8080)`.

The example still configures:

- `MultiplayerSpawner` in `game.tscn`.
- `spawn_path` pointing at `PlayerSpawnPoint`.
- Two `MultiplayerSynchronizer` nodes in `player.tscn`.
- `SceneReplicationConfig` properties for player position, selected ship, and input.
- Manual authority setup using peer IDs.

The larger example adds:

- Host and join option panels that show/hide transport choices based on `BADMP.available_networks`.
- Dedicated server startup from the menu scene using `OS.has_feature("dedicated_server")`.
- Game property synchronization for score, match UI visibility, labels, and match state.
- Player health/death/respawn behavior.
- Projectile spawning under a `Projectiles` node.

Mimic relevance:

- BAD's examples are helpful for user-story discovery: connection menu, host options, join options, local/offline mode, dedicated server start, peer-based input authority, and simple score sync.
- They also show the exact Godot boilerplate Mimic eventually wants to reduce: spawner placement, spawn paths, spawnable scenes, synchronizer placement, replication config property selection, authority naming, and spawn timing.

## Useful Ideas For Mimic

### 1. Transport Availability For UI

BAD's `available_networks` dictionary lets menu code hide unsupported choices. Mimic could expose a small, typed query such as:

```gdscript
var transports := Mimic.get_available_transports()
```

or:

```gdscript
Mimic.is_transport_available(Mimic.TransportType.ENET)
Mimic.get_transport_display_name(Mimic.TransportType.WEBSOCKET)
```

This would help `MimicConnector` render the correct controls without hardcoding platform rules in user scripts.

Keep it narrow:

- ENet unavailable on web.
- WebSocket available where Godot supports it.
- Offline is a state or local testing mode, not a peer-starting transport in the current Mimic model.
- WebRTC remains unsupported until signaling exists.

### 2. Connection Options Object

BAD passes a `BADNetworkConnectionConfigs` resource into host/join. Mimic currently uses Project Settings plus optional method arguments. That is simpler for the MVP.

Potential future:

- `MimicConnectionOptions` resource only if `MimicConnector` or saved connection profiles need it.
- Do not replace simple `Mimic.start_server(port_override, bind_address_override)` and `Mimic.start_client(address_override, port_override)`.
- A resource could help UI scenes save profiles, but it should not become required boilerplate.

### 3. Connector UI Shape

BAD's host/join option panels suggest natural connector controls:

- Host button.
- Join button.
- Stop/cancel button.
- Address input.
- Port input.
- Transport selector.
- Dedicated or local test affordance.
- Status text based on lifecycle signals.

MimicConnector should avoid changing scenes. It should emit or call connection helpers and let the game decide where UI lives.

### 4. Dedicated Server Convenience

BAD's larger example starts an ENet server automatically for dedicated-server builds. Mimic currently skips server-then-client fallback on `dedicated_server` and `server` feature tags, but does not provide a dedicated-server startup setting.

Potential future:

- Add an exported-build startup mode only if explicitly desired.
- Keep editor auto-connect separate from export behavior.
- Prefer a documented helper like `if OS.has_feature("dedicated_server"): Mimic.start_server()` before adding automatic exported-build networking.

### 5. Server/Client Lifecycle Vocabulary

BAD's events use clear terms like server start/stop, client start/stop, peer join/leave. Mimic already has most of this, but docs and UI can make the vocabulary more explicit.

Potential future:

- Consider whether `server_stopped` and `client_stopped` signals would reduce ambiguity.
- Alternatively, keep `state_changed` as the canonical source and document common state transitions.

### 6. Peer Join Spawn Hook Research

BAD's player spawning code is not a direct fit, but the user story is important:

- On server start, spawn the host player unless dedicated server.
- On peer join, spawn a player for that peer.
- On peer leave, remove that player's node.
- Name or identify the spawned node stably by peer ID.
- Set input authority to the peer and gameplay authority to server.

This is close to the future Mimic entity-authoring problem, but implementation should stay aligned with Godot's `MultiplayerSpawner` and `MultiplayerSynchronizer`, not a custom match manager.

## Ideas To Avoid Or Defer

### Avoid Multiple Core Autoloads

BAD splits behavior across five autoloads. Mimic should keep one stable `Mimic` autoload unless the core becomes genuinely unmanageable.

### Avoid Built-In Scene Switching

BAD assumes main menu, loading, and game scenes. Mimic should not own game scene transitions. This is too opinionated for an addon meant to drop into many game structures.

### Avoid Match Framework In Core

BAD includes match state, player readying, spawn points, respawn, score examples, and game-over helpers. These are useful examples, not core Mimic behavior.

### Avoid Manager Override API

BAD exposes setter/getter hooks for replacing internal managers. Mimic should not add public manager replacement until there is a clear extension API design.

### Avoid Transport Plugin Complexity For Now

Noray support is interesting, but it adds external service/signaling concepts and Netfox dependency assumptions. Mimic's current boundary explicitly avoids relay services and raw protocol complexity.

### Avoid Returning `OK` Without Checking Peer Creation Errors

BAD's ENet network methods do not propagate `create_server()` or `create_client()` errors. Mimic should continue treating Godot peer creation errors as first-class results.

## Possible Mimic Backlog Items

These are research-derived ideas, not implementation commitments.

### Short-Term Fit

- Add a documentation page comparing Mimic and BAD Multiplayer, similar to the Netfox page.
- Use BAD's examples as inspiration for `MimicConnector` controls when that node becomes functional.
- Add docs examples for host/join UI that do not require scene switching.
- Add a simple `Mimic.get_transport_name(type)` public helper if UI code needs labels.
- Consider a public transport availability query for platform-aware connector UI.

### Medium-Term Fit

- Add direct lifecycle docs that map `state_changed` values to user-facing statuses.
- Consider `server_stopped` or `client_stopped` only if UI code becomes awkward with `state_changed` and `stopped`.
- Explore an optional `MimicConnectionOptions` resource for saved connector profiles.
- Add dedicated-server documentation using `OS.has_feature("dedicated_server")`.

### Long-Term Fit

- Research a narrow spawn helper centered on `MimicSync`, peer IDs, and Godot-native `MultiplayerSpawner` behavior.
- Explore whether Mimic can infer or validate common replication config mistakes, such as missing spawn properties or wrong synchronizer root path.
- Explore a lightweight peer-entity registry that helps find the node associated with each peer without becoming a match framework.

## Open Questions

- Should `Offline` remain only a transport selection that intentionally does not start a peer, or should Mimic eventually support `OfflineMultiplayerPeer` as a local game mode?
- Should `MimicConnector` call `Mimic.start_server_or_client()` for local test mode, or should that remain an explicit code/project setting workflow?
- How much should Mimic know about peer-owned input nodes versus server-owned gameplay nodes?
- Can Mimic reduce `MultiplayerSpawner` boilerplate without hiding too much of Godot's native spawn contract?
- Should transport availability be public API now, or wait until `MimicConnector` needs it?

## Bottom Line

BAD validates Mimic's direction around connection setup, lifecycle events, and UI-facing simplification. It also shows where the product can become too opinionated: scene switching, match flow, score/respawn state, and global manager replacement.

For Mimic, the strongest next moves are still connection-layer polish and authoring clarity:

- Keep the one-autoload model.
- Make connector UI easy without owning scenes.
- Keep lifecycle signals explicit.
- Keep transport settings typed and stable.
- Reduce native Godot spawner/synchronizer boilerplate later through `MimicSync`, not through a match-game framework.
