# Mimic Networking Research

Last reviewed: 2026-05-30

Scope: default port selection, WebSocket scheme choice, and deployment guidance for Mimic users targeting browser, Android, iOS, Windows, macOS, and Linux with a dedicated server.

Public-repo note: this document is intentionally generic. Do not add real production domains, server IPs, credentials, account names, private topology details, or user-specific deployment notes.

## Findings

### Port Selection

- IANA separates port numbers into Well Known Ports (`0-1023`), User Ports (`1024-49151`), and Dynamic/Private Ports (`49152-65535`). A fixed application default should normally be an unassigned User Port.
- Mimic's previous default, `8910`, is assigned in the IANA registry to `manyone-http`, so it was a poor long-term default.
- The creative `MIMIC` mapping used for the new default is:

```text
MIMIC on a phone keypad = 64642
64642 - 49152 = 15490
```

- `15490` is inside the User Port range and had no IANA service assignment when checked.
- Local availability is never guaranteed. Users should still make the port configurable and change it when another service is already bound on their machine or server.
- ENet uses UDP and WebSocket uses TCP. TCP and UDP have separate port namespaces, so the same number can be used for different transports, but a deployed service should still document exactly which protocol is expected.

Recommendation: keep `15490` as Mimic's configurable default port. It has a project-specific derivation, avoids the previous assigned-port collision, and remains in the appropriate fixed-default range.

### WebSocket Security

- `ws://` is plaintext WebSocket. `wss://` is WebSocket over TLS.
- Browser games served from HTTPS should use `wss://` for production. Plain `ws://` from a secure page risks mixed-content blocking and is not appropriate for real player traffic.
- Native and mobile clients can often connect to `ws://`, but `wss://` is still recommended for production because it protects credentials/session data, avoids hostile network inspection, and aligns all platforms behind one public endpoint.
- Godot's WebSocket client path supports both `ws://` and `wss://`. In native builds, Godot's WebSocket implementation enables TLS for `wss://` and defaults omitted ports to `443` for WSS and `80` for WS.
- Godot Web exports use the browser WebSocket implementation. They can act as WebSocket clients, but not as WebSocket servers.
- Mimic currently builds WebSocket client URLs from `mimic_multiplayer/websocket/client_use_tls`, address, port, and path. If the address already starts with `ws://` or `wss://`, Mimic uses that full URL as-is.
- Mimic currently starts WebSocket servers without passing TLS server options, so production WSS should be handled by a reverse proxy unless Mimic explicitly adds first-class TLS server configuration later.

Recommendation: use `wss://` externally for staging and production. Use `ws://` only for localhost, local LAN testing, or a private reverse-proxy upstream.

## Recommended Dedicated Server Topology

Use TLS termination at a standard reverse proxy and keep the Godot server on a private/plain upstream:

```text
players -> wss://game.example.com -> Caddy/nginx/Traefik on TCP 443 -> ws://127.0.0.1:15490
```

Practical recommendations:

- Put the public WebSocket endpoint on `443`, not `15490`.
- Bind the Godot WebSocket server to `127.0.0.1` or a private interface when it sits behind the proxy.
- Let Caddy, nginx, or Traefik manage Let's Encrypt certificates and WebSocket upgrade forwarding on the public server.
- Keep `15490` as the internal upstream/default port unless the deployment needs a different value.
- For a dedicated WebSocket subdomain, prefer `wss://game.example.com` with no custom path. Use a path such as `/ws` only when the domain also serves other traffic.
- In Mimic clients, either set a full address such as `wss://game.example.com` or set `websocket_client_use_tls = true`, address `game.example.com`, port `443`, and an optional WebSocket path.
- Keep `ws://127.0.0.1:15490` for local development.
- If the project later offers native ENet servers separately from browser WebSocket servers, expose UDP intentionally and document it separately. Browser clients cannot use ENet directly.

## Sources

- IANA Service Name and Port Number Registry: https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml
- MDN WebSocket client applications: https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API/Writing_WebSocket_client_applications
- MDN mixed content: https://developer.mozilla.org/en-US/docs/Web/Security/Defenses/Mixed_content
- Godot WebSocket source reference: `modules/websocket/` in the Godot engine source tree.
- Mimic default setting: `addons/mimic/settings/mimic_project_settings.gd`
- Mimic WebSocket URL construction: `addons/mimic/mimic.gd`
