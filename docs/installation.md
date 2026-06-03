# Installation

Mimic is a Godot addon. Copy the addon folder into a Godot 4.6 or newer project:

```text
res://addons/mimic/
```

Enable the plugin:

1. Open **Project > Project Settings**.
2. Go to the **Plugins** tab.
3. Enable **Mimic**.

When enabled, the plugin adds the `Mimic` autoload. Your scripts can then call methods such as:

```gdscript
Mimic.start_server()
Mimic.start_client()
Mimic.stop()
```

The scene-tree nodes developers usually add to scenes live in:

```text
res://addons/mimic/nodes/
```

## Requirements

- Godot 4.6 or newer.
- A project using Godot's high-level multiplayer API.

## After Installing

Open Project Settings and search for **Mimic Multiplayer**. The default transport is ENet, auto-connect is disabled, the default address is `127.0.0.1`, and the default port is `15490`.
