# BobaSim MVP

This file is the source of truth for the first playable BobaSim prototype. Keep it small, update checkboxes as work lands, and add new scope only when it directly helps prove the core drink-making loop.

## MVP Goal

Prove that making and serving one boba drink is immediately understandable, tactile, and fun enough to build the rest of the cafe around.

Success means a new player can join, make a correct starter drink, serve it, earn money, and understand the next thing to do without reading a long tutorial.

## Scope Rules

- Build the smallest useful cafe loop first.
- Favor physical actions, visible feedback, and rush pressure over management menus.
- Keep recipes, machines, ingredients, progression, and upgrades data-driven.
- Server owns gameplay truth; client owns feel and presentation.
- Do not add large content catalogs before the first drink feels good.

## Phase 0: Workflow Proof

- [x] Rojo project is set up.
- [x] StyLua, Selene, Luau LSP, Lune, and build commands are configured.
- [x] `make check` runs formatting, linting, typechecking, tests, and Rojo build.
- [x] Initial shared recipe and machine config modules exist.
- [x] Initial order service and pure Luau test exist.
- [ ] Roblox Studio opens the built place successfully.
- [ ] Rojo sync works from filesystem changes into Studio.
- [x] Studio MCP is connected and can inspect or modify the DataModel. Verified read-only inspection against the open `BobaSim` Studio instance.
- [x] One simple Part-based machine exists in Studio with stable names/attributes. Runtime `CupStation` blockout verified in Play mode through Studio MCP.
- [x] One machine interaction can be tested in Studio. `CupStation` exposes a ProximityPrompt wired to the authoritative step flow.

## Phase 1: Drink-Making Vertical Slice

- [x] Define the authoritative cup/drink state model. Initial pure rules live in `src/shared/DrinkRules.luau` for server use and local tests.
- [x] Implement server-side step application for cup, boba, tea, milk, flavor, ice, shake, seal, and serve. The server will call the shared rule module when Studio interactions are wired.
- [x] Validate station interactions on the server. Initial validation rejects wrong, duplicate, or post-completion steps.
- [x] Validate completed drinks against recipe definitions.
- [x] Add tests for correct drink completion.
- [x] Add tests for missing, duplicate, or out-of-order steps.
- [x] Add a basic money reward for a correctly served drink.
- [x] Add a basic rejection or remake result for an incorrect drink.
- [x] Create minimal client feedback for each successful action. Initial HUD station loop flashes accepted steps and updates order progress.
- [x] Create minimal client feedback for invalid actions. Initial HUD station loop flashes rejected steps and shows the server rejection reason.
- [ ] Playtest one complete order in Studio.

## Phase 2: Customer Pressure

- [ ] Spawn one customer with one visible order.
- [ ] Display a readable order ticket.
- [ ] Add customer patience decay.
- [ ] Add abandonment when patience reaches zero.
- [ ] Add a simple queue with multiple customers.
- [ ] Add a short rush after several normal orders.
- [ ] Add tests for patience and abandonment behavior.
- [ ] Playtest whether pressure feels exciting rather than confusing.

## Phase 3: First Progression Hook

- [ ] Add one meaningful upgrade that changes player behavior.
- [ ] Make the upgrade purchasable with earned money.
- [ ] Make the upgraded machine visibly different.
- [ ] Verify the upgrade changes the workflow, not just a hidden number.
- [ ] Add tests for purchase validation and upgrade state.

## Phase 4: First Multiplayer Pass

- [ ] Ensure two players can contribute to the same order flow.
- [ ] Prevent duplicate or conflicting server state changes.
- [ ] Make the shared order/cup state visible enough for cooperation.
- [ ] Playtest a small rush with two players.
- [ ] Note whether roles emerge naturally.

## Phase 5: MVP Playtest Gate

- [ ] A new player can start playing within 10 seconds.
- [ ] A new player can complete the first drink without a text tutorial.
- [ ] Every core action has sound, motion, visual state, or UI feedback.
- [ ] Mobile controls support the full core loop with one thumb.
- [ ] The first reward or upgrade appears within 3-5 minutes.
- [ ] A short rush creates pressure using already-known mechanics.
- [ ] One playtester describes the drink-making as satisfying.
- [ ] One playtester understands what they want to improve next.

## Not In MVP

- Large recipe catalog.
- Employees.
- Delivery orders.
- Detailed suppliers.
- Freshness or waste economics.
- Full cafe decoration catalog.
- Advanced layout editor.
- Equipment breakdowns.
- Detailed accounting menus.

## Current Decisions

- Starter recipes: Classic Milk Tea and Strawberry Milk Tea.
- Initial stations: cup, boba, tea, milk, flavor, ice, shaker, sealer, serve counter.
- Initial pressure system: customer patience and a short rush.
- First upgrade should physically change workflow or bottleneck behavior.
- Recipes and machines stay in shared config modules.

## Completion Notes

When marking work complete, include the PR, commit, or short note beside the checkbox when helpful. If a task is discovered to be unnecessary, replace the checkbox with a short decision note instead of silently deleting it.
