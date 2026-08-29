--!strict

local Types = require(script.Parent.Types)

local recipes: { Types.RecipeDefinition } = {
    {
        id = "classic_milk_tea",
        displayName = "Classic Milk Tea",
        unlockLevel = 1,
        baseValue = 8,
        steps = { "Cup", "Boba", "Tea", "Milk", "Ice", "Shake", "Seal", "Serve" },
        ingredients = { "black_tea", "milk", "boba", "ice" },
    },
    {
        id = "strawberry_milk_tea",
        displayName = "Strawberry Milk Tea",
        unlockLevel = 1,
        baseValue = 9,
        steps = { "Cup", "Boba", "Flavor", "Tea", "Milk", "Ice", "Shake", "Seal", "Serve" },
        ingredients = { "black_tea", "milk", "strawberry_syrup", "boba", "ice" },
    },
}

return recipes
