# WebSockets

Mimic can start WebSocket server and client peers through Godot's high-level multiplayer API.

## Local Development

Use plain WebSocket locally:

```text
ws://127.0.0.1:15490
```

Set:

```text
mimic_multiplayer/connection/transport = WebSocket
mimic_multiplayer/connection/address = 127.0.0.1
mimic_multiplayer/connection/port = 15490
mimic_multiplayer/websocket/client_use_tls = false
```

## Production

Use `wss://` for production browser traffic.

Recommended topology:

```text
players -> wss://game.example.com -> reverse proxy on TCP 443 -> ws://127.0.0.1:15490
```

Mimic currently starts WebSocket servers without first-class TLS server options, so terminate TLS at a reverse proxy such as Caddy, nginx, or Traefik.

For public deployments, prefer a normal HTTPS/WSS port such as `443` on the outside and keep Mimic's default `15490` as a private upstream port:

```text
public:  wss://game.example.com
private: ws://127.0.0.1:15490
```

You can set a full WebSocket URL as the Mimic client address, such as `wss://game.example.com`. If the address already starts with `ws://` or `wss://`, Mimic uses it as the full URL.

## Browser Notes

ENet is not available in Godot web exports, so browser clients should use WebSocket.

Browser exports can use WebSocket clients, but GitHub Pages cannot host a Godot multiplayer server. A playable Web export hosted in the docs can run offline/local behavior or connect out to an external `wss://` server.

Avoid connecting from an HTTPS docs page to `ws://` production endpoints. Browsers may block mixed content, and real player traffic should be encrypted.

Native and mobile builds can often connect to `ws://`, but `wss://` is still the better production default because it avoids network inspection and keeps every platform on the same public endpoint.
