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

export type RecipeDefinition = {
    id: string,
    displayName: string,
    unlockLevel: number,
    baseValue: number,
    steps: { StationStep },
    ingredients: { string },
}

export type MachineDefinition = {
    id: string,
    displayName: string,
    modelName: string,
    stationStep: StationStep,
    machineType: string,
    interactionRange: number,
    inputType: string?,
    outputType: string?,
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

return Types
