# Project Settings

Mimic registers settings under **Project > Project Settings > Mimic Multiplayer**.

Godot does not currently expose description text for custom settings added through `ProjectSettings.add_property_info()`, so this page is the user-facing reference for setting meanings.

## Setting Reference

Settings marked Advanced are hidden unless **Advanced Settings** is enabled in Project Settings.

| Setting | Default | Visibility | Meaning |
| --- | --- | --- | --- |
| `mimic_multiplayer/connection/transport` | `ENet` | Basic | Selects Offline, ENet, WebSocket, or WebRTC (Unsupported). Offline and WebRTC do not start network peers in the current MVP. |
| `mimic_multiplayer/connection/editor_auto_connect` | `Disabled` | Basic | Editor-only startup action for editor-launched runs. Values are Disabled, Server Then Client, Client, and Server. Exported builds ignore this setting. |
| `mimic_multiplayer/connection/address` | `127.0.0.1` | Basic | Default client address used by `Mimic.start_client()`. |
| `mimic_multiplayer/connection/port` | `15490` | Basic | Server/client port. Must be between `1` and `65535`. |
| `mimic_multiplayer/connection/max_clients` | `32` | Basic | Maximum ENet clients accepted by `Mimic.start_server()`. |
| `mimic_multiplayer/connection/bind_address` | `*` | Advanced | Local bind address for server sockets and ENet client local binding. |
| `mimic_multiplayer/enet/channel_count` | `0` | Advanced | ENet channel count passed to ENet server/client creation. |
| `mimic_multiplayer/enet/in_bandwidth` | `0` | Advanced | ENet incoming bandwidth limit in bytes per second. `0` means unlimited. |
| `mimic_multiplayer/enet/out_bandwidth` | `0` | Advanced | ENet outgoing bandwidth limit in bytes per second. `0` means unlimited. |
| `mimic_multiplayer/enet/client_local_port` | `0` | Advanced | Local port used by ENet clients. `0` lets Godot choose an ephemeral port. |
| `mimic_multiplayer/websocket/client_use_tls` | `false` | Basic | Builds `wss://` client URLs instead of `ws://` when the address is not already a full WebSocket URL. |
| `mimic_multiplayer/websocket/path` | empty | Advanced | Optional path appended to generated WebSocket client URLs. Ignored when the address already starts with `ws://` or `wss://`. |
| `mimic_multiplayer/websocket/handshake_timeout` | `3.0` | Advanced | WebSocket handshake timeout in seconds. |
| `mimic_multiplayer/port_forwarding/enabled` | `false` | Basic | Tries UPnP port forwarding when hosting. |
| `mimic_multiplayer/port_forwarding/delete_mapping_on_stop` | `true` | Advanced | Deletes owned UPnP mappings when networking stops. |
| `mimic_multiplayer/port_forwarding/query_external_address` | `true` | Advanced | Asks the UPnP gateway for its external address after mapping. |
| `mimic_multiplayer/port_forwarding/protocol` | `Transport Default` | Advanced | Chooses mapped protocol: UDP for ENet, TCP for WebSocket, or an explicit TCP/UDP override. |
| `mimic_multiplayer/port_forwarding/duration` | `7200` | Advanced | UPnP mapping lease duration in seconds. `0` requests a permanent mapping. |
| `mimic_multiplayer/port_forwarding/discover_timeout_ms` | `2000` | Advanced | UPnP discovery timeout in milliseconds. |
| `mimic_multiplayer/port_forwarding/discover_ttl` | `2` | Advanced | UPnP discovery time-to-live hop count. |
| `mimic_multiplayer/debug/log_level` | `Warning` | Basic | Controls Mimic log output. Values are All, Warning, Error, and None. |

## Connection

Use ENet for native local testing and native builds. Use WebSocket when browser clients need to connect. ENet is not available in web exports, and WebRTC signaling is not implemented yet.

`address` is only used by client startup. `port` is used by both server and client startup unless a method call passes an override.

## Bind Address

The bind address controls which local interface server sockets use. The default `*` lets Godot bind normally. For local-only smoke tests, pass or set `127.0.0.1`.

## WebSocket URLs

If `address` already starts with `ws://` or `wss://`, Mimic treats it as a full URL and does not append `path`.

## Port Forwarding

UPnP discovery and port mapping run in a background thread so hosting does not block the main thread. Port forwarding depends on the user's router, network, and platform. Treat it as a convenience for local testing, not a guaranteed matchmaking or NAT traversal solution.
