# Mimic Vs Netfox

Mimic and Netfox are both Godot multiplayer projects, but they are designed for different levels of networking ambition.

## Prefer Mimic When

- You want a small helper around Godot's built-in high-level multiplayer API.
- You want basic connection setup through Project Settings.
- You want a lightweight host/join/stop workflow.
- You want to stay close to `MultiplayerSynchronizer` and `SceneReplicationConfig`.
- You are prototyping and want fewer systems to learn before testing multiplayer flow.

## Prefer Netfox When

- You need a fuller networking framework.
- You need rollback.
- You need client-side prediction.
- You need server reconciliation.
- You need interpolation helpers.
- You need lag compensation.
- You need Noray integration.
- You are ready to adopt Netfox's network timing and supporting node model.

Netfox is the better fit when your game needs advanced netcode features. Mimic is intentionally smaller and aims to make common Godot multiplayer setup easier rather than replacing a full-featured framework.

## Links

- [Netfox repository](https://github.com/foxssake/netfox)
- [Netfox documentation](https://foxssake.github.io/netfox/)
