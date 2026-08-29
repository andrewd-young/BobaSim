--!strict

local Types = require("./Types")

local machines: { Types.MachineDefinition } = {
    {
        id = "boba_dispenser",
        displayName = "Boba Dispenser",
        modelName = "BobaDispenser",
        machineType = "Ingredient",
        interactionRange = 8,
        inputType = nil,
        outputType = "boba",
        animationNames = { "Dispense" },
    },
    {
        id = "tea_dispenser",
        displayName = "Tea Dispenser",
        modelName = "TeaDispenser",
        machineType = "Ingredient",
        interactionRange = 8,
        inputType = nil,
        outputType = "black_tea",
        animationNames = { "Pour" },
    },
    {
        id = "cup_sealer",
        displayName = "Cup Sealer",
        modelName = "CupSealer",
        machineType = "Finisher",
        interactionRange = 8,
        inputType = "unsealed_drink",
        outputType = "sealed_drink",
        animationNames = { "Seal" },
    },
}

return machines
