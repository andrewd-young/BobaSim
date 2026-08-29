# BobaSim Agent Notes

## Project Direction

BobaSim is a cooperative, hands-on Roblox boba cafe simulator. Favor physical actions,
visible workflow problems, rush pressure, and cafe ownership over bookkeeping-heavy
restaurant management.

## Development Rules

1. The server owns authoritative gameplay state.
2. Never trust RemoteEvent or RemoteFunction payloads from clients.
3. Clients handle input, feedback, animation, UI, and presentation.
4. All new Luau source files use `--!strict`.
5. Recipes, machines, progression values, and other content live in shared config modules.
6. Do not hardcode recipe-specific branches inside station logic.
7. Keep services and controllers focused on one responsibility.
8. Make important state transitions explicit and testable.
9. Build Studio models around stable names, attributes, and interaction points.
10. If Studio behavior, instances, physics, animation, or UI changed, verify it in Studio.

## Commands

- `make fmt`: format Luau files.
- `make lint`: run StyLua check and Selene.
- `make typecheck`: generate a Rojo sourcemap and run Luau LSP analysis.
- `make test`: run local Lune tests.
- `make build`: build the place with Rojo.
- `make check`: run lint, typecheck, tests, and build.
- `make dev`: start the Rojo server for Studio sync.

## Current Scope

Prototype the smallest useful cafe loop first:

- One customer queue.
- Two starter recipes.
- Cup, topping, tea, milk, ice, shake, seal, and serve steps.
- Customer patience.
- Money reward.
- One meaningful upgrade.
- A short rush after several normal orders.

Delay large recipe catalogs, detailed supplier systems, employees, delivery, freshness,
and advanced management until the drink-making interaction feels good.

## Studio MCP Workflow

Use Studio MCP when the task needs real DataModel inspection, instance creation,
playtesting, physics, animation, or UI verification. Filesystem-only checks are not enough
for behavior that depends on Studio-owned objects.

