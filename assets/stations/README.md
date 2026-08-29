# Station Asset Pattern

Each folder in `assets/stations` is a Rojo-managed station model mounted under
`Workspace.BobaSimStations`.

Station models must keep this contract:

- The model has a `StationStep` attribute matching `Types.StationStep`.
- The model has an `InteractionRange` attribute for prompt distance tuning.
- A descendant `ProximityPrompt` is named `StationPrompt`.
- The prompt lives under `InteractionPad` so server feedback can flash the pad.
- Replaceable primitive visuals live under `Blockout`.
- Visual parts are named by purpose, such as `Counter`, `Sign`, or `IngredientPreview`.

The server discovers stations by this contract in `src/server/StationWorld.luau`;
station-specific behavior belongs in shared recipe/rule config, not in the model.

When replacing a station with final art, keep the outer station model and
`InteractionPad` in place. Replace `Blockout` with an imported model or assembled
parts using the same local footprint, then tune `InteractionPad` and
`InteractionRange` if the new model needs a different reach.
