# Host And Join Locally

Use this tutorial when you want a fast local smoke test with one server and one client on the same machine.

## Project Settings

Set:

```text
mimic_multiplayer/connection/transport = ENet
mimic_multiplayer/connection/editor_auto_connect = Server Then Client
mimic_multiplayer/connection/address = 127.0.0.1
mimic_multiplayer/connection/port = 15490
```

## Run Multiple Instances

In the Godot editor:

1. Open **Debug > Customize Run Instances...**.
2. Set the number of instances to `2`.
3. Run the project.

The first instance should host. The second instance should join.

## Optional Window Tiling

For easier local testing, add this script as an autoload named `MimicRunInstanceGrid`:

```text
res://addons/mimic/testing/mimic_run_instance_grid.gd
```

Disable **Game > Embedding Options > Embed Game on Next Play** so each run instance opens in a separate window. The helper arranges editor-launched game windows into a grid.
