# BobaSim

Roblox boba cafe simulator prototype.

## Tech Stack

- Rojo for syncing filesystem code into Roblox Studio.
- Rokit for pinning local Roblox development tools.
- Luau Language Server for type checking and editor intelligence.
- StyLua for formatting.
- Selene for linting.
- Wally for packages when a dependency is clearly worth adding.
- Lune for local Luau scripts and lightweight tests.

## Getting Started

### 1. Install Roblox Studio

Install Roblox Studio from the Roblox Creator site, then open `BobaSim.rbxl`.

Keep the Explorer and Properties panels visible:

- Explorer shows the game object tree.
- Properties lets you edit selected parts, prompts, attributes, colors, size, and position.

### 2. Install Rojo Studio Plugin

Install the Rojo plugin in Roblox Studio. This lets Studio receive files from this repo while `make dev` is running.

After installing it, open the Rojo plugin panel in Studio. You will use it to connect to the local Rojo server.

### 3. Install Local Tools

In the terminal with the BobaSim directory open, install Rokit, then install the pinned project tools:

```sh
rokit install
```

Rokit installs the exact versions listed in `rokit.toml`, including Rojo, StyLua, Selene, Lune, Wally, and Luau LSP.

### 4. Run Local Checks

```sh
make check
```

This formats/lints/typechecks/tests the project and builds `build/BobaSim.rbxl`.

### 5. Start Studio Sync

```sh
make dev
```

Then connect from the Rojo plugin panel in Roblox Studio.

Once connected, filesystem changes under `src/` and `assets/` should sync into the open place. Press Play in Studio to test the game.

## Editing Assets

Prototype assets live under `assets`.

For now, prefer simple Roblox primitives: blocks, cylinders, wedges, spheres, colors, materials, and clear labels. This keeps the MVP easy to change before we commit to polished meshes.

Station behavior should be connected through stable Studio-visible contracts such as model names, attributes, tags, prompts, attachments, or consistently named child instances. Server code should bind to those contracts instead of constructing artist-editable geometry at runtime.

Important workflow note:

- Code and reviewable asset definitions live in the repo.
- Studio is the visual editor.
- If you edit a Rojo-managed object in Studio, copy the intended change back into `assets/` or it may be overwritten by Rojo sync.
- If you intentionally save Studio-only changes, `BobaSim.rbxl` may become modified. Avoid committing the binary place file unless the team decides that `.rbxl` is part of the asset source of truth.

## Rojo Troubleshooting

You usually do not need to restart `make dev` for normal edits to existing files.

Restart `make dev` or reconnect the Rojo plugin when:

- `default.project.json` changes.
- A brand new top-level mapped folder is added.
- Studio does not show a newly added asset file.
- The Rojo plugin disconnects.
- Studio is connected to the wrong Rojo project.
- Port `34872` is already occupied by a stale Rojo server.

If sync is stale:

1. Stop Play mode.
2. Disconnect and reconnect the Rojo plugin.
3. Restart `make dev`.
4. Reopen `BobaSim.rbxl` if Studio still shows old objects.

## Project Layout

- `src/shared`: shared types, configuration, and pure gameplay data.
- `src/server`: authoritative server services.
- `src/client`: input, feedback, animation, and UI presentation.
- `tests`: Lune-based tests for pure Luau modules.
- `assets`: source assets and references.
- `tools`: local scripts and generation utilities.
