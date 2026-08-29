--!strict

local Recipes = if script ~= nil then require(script.Parent.Recipes) else require("./Recipes")

type StationStep = "Cup" | "Boba" | "Tea" | "Milk" | "Flavor" | "Ice" | "Shake" | "Seal" | "Serve"

type RecipeDefinition = {
    id: string,
    displayName: string,
    unlockLevel: number,
    baseValue: number,
    steps: { StationStep },
    ingredients: { string },
}

type DrinkStatus = "Building" | "Sealed" | "Served" | "Rejected"

type Drink = {
    id: string,
    orderId: string,
    recipeId: string,
    completedSteps: { StationStep },
    status: DrinkStatus,
}

type StepApplication = {
    accepted: boolean,
    drink: Drink,
    reason: string?,
}

type ServeResult = {
    accepted: boolean,
    drink: Drink,
    payout: number,
    reason: string?,
}

local DrinkRules = {}

local function copySteps(steps: { StationStep }): { StationStep }
    return table.clone(steps)
end

local function findRecipe(recipeId: string): RecipeDefinition?
    for _, recipe in Recipes do
        if recipe.id == recipeId then
            return recipe
        end
    end

    return nil
end

local function expectedStep(drink: Drink, recipe: RecipeDefinition): StationStep?
    return recipe.steps[#drink.completedSteps + 1]
end

local function cloneDrinkWithStep(drink: Drink, step: StationStep, status: DrinkStatus): Drink
    local completedSteps = copySteps(drink.completedSteps)
    table.insert(completedSteps, step)

    return {
        id = drink.id,
        orderId = drink.orderId,
        recipeId = drink.recipeId,
        completedSteps = completedSteps,
        status = status,
    }
end

local function cloneDrinkWithStatus(drink: Drink, status: DrinkStatus): Drink
    return {
        id = drink.id,
        orderId = drink.orderId,
        recipeId = drink.recipeId,
        completedSteps = copySteps(drink.completedSteps),
        status = status,
    }
end

function DrinkRules.createDrink(orderId: string, recipeId: string): Drink
    assert(orderId ~= "", "orderId must not be empty")
    assert(recipeId ~= "", "recipeId must not be empty")
    assert(findRecipe(recipeId) ~= nil, `unknown recipeId: {recipeId}`)

    return {
        id = `drink-{orderId}`,
        orderId = orderId,
        recipeId = recipeId,
        completedSteps = {},
        status = "Building",
    }
end

function DrinkRules.applyStep(drink: Drink, step: StationStep): StepApplication
    if drink.status ~= "Building" then
        return {
            accepted = false,
            drink = drink,
            reason = `drink is {drink.status}`,
        }
    end

    if step == "Serve" then
        return {
            accepted = false,
            drink = drink,
            reason = "use serveDrink to serve drinks",
        }
    end

    local recipe = findRecipe(drink.recipeId)
    if recipe == nil then
        return {
            accepted = false,
            drink = drink,
            reason = `unknown recipeId: {drink.recipeId}`,
        }
    end

    local nextStep = expectedStep(drink, recipe)
    if nextStep ~= step then
        return {
            accepted = false,
            drink = drink,
            reason = `expected {tostring(nextStep)}, got {step}`,
        }
    end

    local status: DrinkStatus = if step == "Seal" then "Sealed" else "Building"

    return {
        accepted = true,
        drink = cloneDrinkWithStep(drink, step, status),
        reason = nil,
    }
end

function DrinkRules.serveDrink(drink: Drink): ServeResult
    local recipe = findRecipe(drink.recipeId)
    if recipe == nil then
        return {
            accepted = false,
            drink = cloneDrinkWithStatus(drink, "Rejected"),
            payout = 0,
            reason = `unknown recipeId: {drink.recipeId}`,
        }
    end

    local nextStep = expectedStep(drink, recipe)
    if nextStep ~= "Serve" or drink.status ~= "Sealed" then
        return {
            accepted = false,
            drink = cloneDrinkWithStatus(drink, "Rejected"),
            payout = 0,
            reason = "drink is not ready to serve",
        }
    end

    return {
        accepted = true,
        drink = cloneDrinkWithStep(drink, "Serve", "Served"),
        payout = recipe.baseValue,
        reason = nil,
    }
end

return DrinkRules
