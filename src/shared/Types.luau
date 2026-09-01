--!strict

export type StationStep =
    "Cup"
    | "Boba"
    | "Tea"
    | "Milk"
    | "Flavor"
    | "Ice"
    | "Shake"
    | "Seal"
    | "Serve"

export type CarryItemId =
    "cup"
    | "boba_scoop"
    | "tea_kettle"
    | "milk_carton"
    | "strawberry_syrup_bottle"
    | "ice_scoop"
    | "shaker_tin"

export type ExistingModelWorldSource = {
    kind: "ExistingModel",
    folderName: string,
}

export type CloneStationPartWorldSource = {
    kind: "CloneStationPart",
    stationName: string,
    partName: string,
}

export type WorldSource = ExistingModelWorldSource | CloneStationPartWorldSource

export type CarryableDefinition = {
    id: CarryItemId,
    displayName: string,
    heldOffset: CFrame,
    placementOffset: CFrame,
    source: WorldSource,
}

export type RecipeDefinition = {
    id: string,
    displayName: string,
    unlockLevel: number,
    baseValue: number,
    steps: { StationStep },
    ingredients: { string },
}

export type StartStepBehavior = { kind: "Start" }
export type IngredientStepBehavior = { kind: "Ingredient" }
export type ProcessStepBehavior = { kind: "Process" }
export type FinalizeStepBehavior = {
    kind: "Finalize",
    completedDrinkStatus: "Sealed",
}
export type ServeStepBehavior = { kind: "Serve" }
export type StepBehavior =
    StartStepBehavior
    | IngredientStepBehavior
    | ProcessStepBehavior
    | FinalizeStepBehavior
    | ServeStepBehavior

export type MachineDefinition = {
    id: string,
    displayName: string,
    modelName: string,
    stationStep: StationStep,
    machineType: string,
    stepBehavior: StepBehavior,
    interactionRange: number,
    inputType: string?,
    outputType: string?,
    producedCarryItemId: CarryItemId?,
    requiredCarryItemId: CarryItemId?,
    promptHint: string,
    checklistLabel: string,
    notReadyReason: string,
    animationNames: { string },
}

export type OrderStatus = "Queued" | "InProgress" | "Completed" | "Abandoned"

export type Order = {
    id: string,
    recipeId: string,
    createdAt: number,
    patience: number,
    status: OrderStatus,
}

export type DrinkStatus = "Building" | "Sealed" | "Served" | "Rejected"

export type Drink = {
    id: string,
    orderId: string,
    recipeId: string,
    completedSteps: { StationStep },
    status: DrinkStatus,
}

export type StepApplication = {
    accepted: boolean,
    drink: Drink,
    reason: string?,
}

export type ServeResult = {
    accepted: boolean,
    drink: Drink,
    payout: number,
    reason: string?,
}

local Types = {}

local stationSteps: { [string]: boolean } = {
    Cup = true,
    Boba = true,
    Tea = true,
    Milk = true,
    Flavor = true,
    Ice = true,
    Shake = true,
    Seal = true,
    Serve = true,
}

local carryItemIds: { [string]: boolean } = {
    cup = true,
    boba_scoop = true,
    tea_kettle = true,
    milk_carton = true,
    strawberry_syrup_bottle = true,
    ice_scoop = true,
    shaker_tin = true,
}

function Types.isStationStep(value: unknown): boolean
    return typeof(value) == "string" and stationSteps[value] == true
end

function Types.isCarryItemId(value: unknown): boolean
    return typeof(value) == "string" and carryItemIds[value] == true
end

return Types
