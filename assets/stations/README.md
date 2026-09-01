# Station Asset Pattern

Each folder in `assets/stations` is a Rojo-managed station model mounted under
`Workspace.BobaSimStations`. Stations are counter work spots, not abstract
buttons: players should usually look at a cup, machine, or counter target in
first person after carrying the relevant prop over to it.

Station models must keep this contract:

- The model has a `StationStep` attribute matching `Types.StationStep`.
- The model has an `InteractionRange` attribute for prompt distance tuning.
- A descendant `ProximityPrompt` is named `StationPrompt`.
- The prompt lives under `InteractionPad` so server feedback can flash the pad.
- Replaceable primitive visuals live under `Blockout`.
- Visual parts are named by purpose, such as `Counter`, `Sign`, or `IngredientPreview`.

The server discovers stations by this contract in `src/server/StationWorld.luau`;
station-specific behavior belongs in shared recipe/rule config, not in the model.
Only fixtures that physically occupy the shop need full counter/blockout assets.
Carry-only ingredients such as milk, tea, and syrup can keep just a small
`InteractionPad` on the center island prep mat.

Physical carry props live under `assets/carryables` and mount to
`Workspace.BobaSimCarryItems`. Their behavior is defined once in
`src/shared/Carryables.luau`, not by item-specific server or client functions.
Each carryable selects a `WorldSource` variant:

- `ExistingModel` repositions a named model in `BobaSimCarryItems`.
- `CloneStationPart` clones a named station part on placement; use it for cups
  and other disposable or container-like objects.

Add a carryable entry using one of these variants whenever possible. Introduce a
new source variant only for a genuinely new world mechanic (for example,
inventory-limited spawning or attaching an item to a machine).

Carry item models must keep this contract:

- The model has a `CarryItemId` attribute matching `Types.CarryItemId`.
- The model has an `InteractionRange` attribute for prompt distance tuning.
- A descendant `ProximityPrompt` is named `CarryPrompt`.

Step-to-item requirements, player-facing text, produced carryables, and step
progression behavior live in `src/shared/Machines.luau`. `PhysicalInteractions`
is the read-only adapter used by session and presentation code. For example, the
Milk step requires the player to pick up the milk carton first, then activate the
milk work spot to pour into the cup.

When replacing a station with final art, keep the outer station model and
`InteractionPad` in place. Replace `Blockout` with an imported model or assembled
parts using the same local footprint, then tune `InteractionPad` and
`InteractionRange` if the new model needs a different reach.
