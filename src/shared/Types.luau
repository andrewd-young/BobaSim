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

local Types = {}

return Types
