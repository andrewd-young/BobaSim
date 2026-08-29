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

Install the pinned tools:

```sh
rokit install
```

Run the local checks:

```sh
make check
```

Start Rojo for Studio sync:

```sh
make dev
```

Then connect from the Rojo plugin in Roblox Studio.

## Project Layout

- `src/shared`: shared types, configuration, and pure gameplay data.
- `src/server`: authoritative server services.
- `src/client`: input, feedback, animation, and UI presentation.
- `tests`: Lune-based tests for pure Luau modules.
- `assets`: source assets and references.
- `tools`: local scripts and generation utilities.

