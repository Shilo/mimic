# Project Settings

Mimic registers settings under **Project > Project Settings > Mimic Multiplayer**.

Godot does not currently expose description text for custom settings added through `ProjectSettings.add_property_info()`, so this page is the user-facing reference for setting meanings.

## Connection

```text
mimic_multiplayer/connection/transport
mimic_multiplayer/connection/address
mimic_multiplayer/connection/port
mimic_multiplayer/connection/max_clients
```

`transport` selects Offline, ENet, WebSocket, or WebRTC. WebRTC is reserved but unsupported in the current MVP.

`address` is the default client address. For local testing, use `127.0.0.1`.

`port` is the server/client port. Mimic defaults to `15490`.

`max_clients` is passed to ENet server creation.

## Advanced Connection

```text
mimic_multiplayer/connection/bind_address
```

The bind address controls which local interface server sockets use. The default `*` lets Godot bind normally.

## ENet

```text
mimic_multiplayer/enet/channel_count
mimic_multiplayer/enet/in_bandwidth
mimic_multiplayer/enet/out_bandwidth
mimic_multiplayer/enet/client_local_port
```

Use these only when you need ENet-specific tuning. `0` means the default or unlimited value for the matching Godot API.

## WebSocket

```text
mimic_multiplayer/websocket/client_use_tls
mimic_multiplayer/websocket/path
mimic_multiplayer/websocket/handshake_timeout
```

Use `client_use_tls` for `wss://` client URLs when joining production WebSocket servers.

If `address` already starts with `ws://` or `wss://`, Mimic treats it as a full URL and does not append `path`.

## Port Forwarding

```text
mimic_multiplayer/port_forwarding/enabled
mimic_multiplayer/port_forwarding/delete_mapping_on_stop
mimic_multiplayer/port_forwarding/query_external_address
mimic_multiplayer/port_forwarding/protocol
mimic_multiplayer/port_forwarding/duration
mimic_multiplayer/port_forwarding/discover_timeout_ms
mimic_multiplayer/port_forwarding/discover_ttl
```

UPnP discovery and port mapping run in a background thread so hosting does not block the main thread. Port forwarding depends on the user's router, network, and platform. Treat it as a convenience for local testing, not a guaranteed matchmaking or NAT traversal solution.

## Debug

```text
mimic_multiplayer/debug/log_level
```

Controls Mimic connection logging. Values are All, Warning, Error, and None.
