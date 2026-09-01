--!strict

local Types = require("./Types")
local Machines: { Types.MachineDefinition } = require("./Machines")
local Recipes: { Types.RecipeDefinition } = require("./Recipes")

type StationStep = Types.StationStep
type RecipeDefinition = Types.RecipeDefinition
type DrinkStatus = Types.DrinkStatus
type Drink = Types.Drink
type StepApplication = Types.StepApplication
type ServeResult = Types.ServeResult

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

local function hasCompletedStep(drink: Drink, step: string): boolean
    for _, completedStep in drink.completedSteps do
        if completedStep == step then
            return true
        end
    end

    return false
end

local function recipeIncludesStep(recipe: RecipeDefinition, step: StationStep): boolean
    for _, recipeStep in recipe.steps do
        if recipeStep == step then
            return true
        end
    end

    return false
end

local function findMachine(step: StationStep): Types.MachineDefinition?
    for _, machine in Machines do
        if machine.stationStep == step then
            return machine
        end
    end

    return nil
end

type ProgressionKind = "Start" | "Ingredient" | "Process" | "Finalize" | "Serve"

local progressionKinds: { ProgressionKind } =
    { "Start", "Ingredient", "Process", "Finalize", "Serve" }

local function getIncompleteStepsOfKind(
    drink: Drink,
    recipe: RecipeDefinition,
    kind: ProgressionKind
): { StationStep }
    local steps: { StationStep } = {}
    for index = 1, #recipe.steps do
        local step: StationStep = recipe.steps[index]
        local machine = findMachine(step)
        if
            machine ~= nil
            and machine.stepBehavior.kind == kind
            and not hasCompletedStep(drink, step)
        then
            table.insert(steps, step)
        end
    end
    return steps
end

function DrinkRules.getAvailableSteps(drink: Drink): { StationStep }
    if drink.status == "Served" or drink.status == "Rejected" then
        return {}
    end

    local recipe = findRecipe(drink.recipeId)
    if recipe == nil then
        return {}
    end

    for index = 1, #progressionKinds do
        local kind: ProgressionKind = progressionKinds[index]
        local incompleteSteps = getIncompleteStepsOfKind(drink, recipe, kind)
        if #incompleteSteps > 0 then
            return incompleteSteps
        end
    end

    return {}
end

local function unavailableReason(drink: Drink, recipe: RecipeDefinition, step: StationStep): string
    if not recipeIncludesStep(recipe, step) then
        return `{step} is not needed for this order`
    end

    if hasCompletedStep(drink, step) then
        return `{step} is already done`
    end

    local missingStartSteps = getIncompleteStepsOfKind(drink, recipe, "Start")
    local blockingStep: StationStep = if #missingStartSteps > 0
        then missingStartSteps[1] :: StationStep
        else step
    local blockingMachine = findMachine(blockingStep)
    return if blockingMachine ~= nil
        then blockingMachine.notReadyReason
        else `finish the drink before using {step}`
end

function DrinkRules.applyStep(drink: Drink, step: StationStep): StepApplication
    if drink.status ~= "Building" then
        return {
            accepted = false,
            drink = drink,
            reason = `drink is {drink.status}`,
        }
    end

    local machine = findMachine(step)
    if machine ~= nil and machine.stepBehavior.kind == "Serve" then
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

    local availableSteps = DrinkRules.getAvailableSteps(drink)
    local isAvailable = false
    for _, availableStep in availableSteps do
        if availableStep == step then
            isAvailable = true
            break
        end
    end

    if not isAvailable then
        return {
            accepted = false,
            drink = drink,
            reason = unavailableReason(drink, recipe, step),
        }
    end

    local status: DrinkStatus = if machine ~= nil
            and machine.stepBehavior.kind == "Finalize"
        then machine.stepBehavior.completedDrinkStatus
        else "Building"

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

    local availableSteps = DrinkRules.getAvailableSteps(drink)
    local nextMachine = if availableSteps[1] ~= nil then findMachine(availableSteps[1]) else nil
    if nextMachine == nil or nextMachine.stepBehavior.kind ~= "Serve" then
        return {
            accepted = false,
            drink = drink,
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
