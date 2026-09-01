# BobaSim Agent Notes

## Project Direction

BobaSim is a cooperative, hands-on Roblox boba cafe simulator. Favor physical actions,
visible workflow problems, rush pressure, and cafe ownership over bookkeeping-heavy
restaurant management.

## Design Principles

1. Play within 10 seconds. Never make a player read before having fun.
2. Every action reacts. Use sound, motion, visual state, and UI feedback.
3. Physical before abstract. Show pearls falling rather than `+1 Boba`.
4. Readable before realistic. Exaggerate shapes, colors, and proportions.
5. Mobile first. Every core interaction works beautifully with one thumb.
6. Roblox avatars belong in the world. Keep the player's identity visible.
7. Friends make the game better. Multiplayer changes the experience rather than merely duplicating it.
8. Complexity unlocks gradually. The first drink is trivial; a 30-minute cafe shift can become chaos.
9. Upgrades change behavior. A better machine should feel different, not just provide `+15%`.
10. Reuse everything. Prefer modular models, shared textures, configurable recipes, and reusable components.
11. Server owns truth. Clients request; the server validates.
12. Client owns feel. Animation, VFX, UI, sound, and immediate feedback happen locally where appropriate.
13. Data drives content. Recipes, equipment, ingredients, and upgrades should primarily be configuration, not duplicated code.
14. Measure behavior. Instrument onboarding and progression from the beginning.
15. Prove fun before producing content. One amazing drink is worth more than 40 boring recipes.

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

## Extensible Design Requirements

Agents must solve the underlying pattern, not patch the single example discovered in
testing. When a request exposes an item-, recipe-, station-, or UI-specific branch,
inspect the whole affected flow (shared config, server authority, client presentation,
world assets, and tests) before changing code. Apply the resulting abstraction to all
existing variants in scope.

1. Model known variations as typed data, preferably a discriminated union with a
   `kind` field. Data chooses a behavior; it must not require a growing set of
   `if itemId == ...` or `if step == ...` branches across services/controllers.
2. Add a new union variant only for a genuinely new mechanic. Examples include an
   inventory-limited spawn or attaching an item to a machine; a different cup,
   syrup, tray, lid, or receipt should normally be another config entry.
3. Keep each behavior implementation generic and focused. Use modules/services as
   the object boundary: they own one responsibility and dispatch from typed config.
   Do not introduce classes merely for style; use object-oriented boundaries where
   they improve ownership, state isolation, or polymorphic behavior.
4. Centralize gameplay rules and player-facing labels with the domain definition
   that owns them. Do not duplicate item names, placement sources, prompts, step
   requirements, progression roles, offsets, or output rules in server/client code.
5. Treat a new content entry as a no-code-change test. After adding the generic
   mechanism, ask whether a future entry using an existing behavior variant can be
   added by configuration and assets alone. If not, identify and remove the leaked
   special case before considering the work complete.
6. Add or update contract tests for config completeness and behavior dispatch, not
   only a regression test for the one reported item. Verify every existing config
   entry satisfies the new contract.
7. In the final handoff, call out the abstraction added, the variants it covers,
   and any remaining hardcoded rule that is intentionally deferred to a follow-up.
8. Explicit `any` is forbidden in authored `src` and `tests` Luau. Use a concrete
   type or a discriminated union; at untrusted boundaries, accept `unknown` and
   validate it before narrowing. `make lint` enforces this rule.

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
