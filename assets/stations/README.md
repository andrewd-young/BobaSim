# Station Asset Pattern

Each folder in `assets/stations` is a Rojo-managed station model mounted under
`Workspace.BobaSimStations`.

Station models must keep this contract:

- The model has a `StationStep` attribute matching `Types.StationStep`.
- The model has an `InteractionRange` attribute for prompt distance tuning.
- A descendant `ProximityPrompt` is named `StationPrompt`.
- The prompt lives under `InteractionPad` so server feedback can flash the pad.
- Visual parts are named by purpose, such as `Counter`, `Sign`, or `IngredientPreview`.

The server discovers stations by this contract in `src/server/StationWorld.luau`;
station-specific behavior belongs in shared recipe/rule config, not in the model.
