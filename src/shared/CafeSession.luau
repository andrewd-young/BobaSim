--!strict

local DrinkRules = require("./DrinkRules")
local Recipes = require("./Recipes")
local Types = require("./Types")

type OrderStatus = "Queued" | "InProgress" | "Completed" | "Abandoned"

type Order = {
    id: string,
    recipeId: string,
    createdAt: number,
    patience: number,
    status: OrderStatus,
}

export type CafeSession = {
    activeOrder: Order,
    activeDrink: Types.Drink,
    money: number,
    servedDrinks: number,
    lastMessage: string,
}

export type Snapshot = {
    orderId: string,
    recipeId: string,
    recipeName: string,
    money: number,
    status: Types.DrinkStatus,
    completedSteps: { Types.StationStep },
    requiredSteps: { Types.StationStep },
    nextStep: Types.StationStep?,
    lastMessage: string,
}

export type StepResult = {
    accepted: boolean,
    snapshot: Snapshot,
    reason: string?,
}

local DEFAULT_PATIENCE_SECONDS = 60

local CafeSession = {}

local nextOrderNumber = 0
local recipeRotation = { "classic_milk_tea", "strawberry_milk_tea" }

local function copySteps(steps: { Types.StationStep }): { Types.StationStep }
    return table.clone(steps)
end

local function findRecipe(recipeId: string): Types.RecipeDefinition
    for _, recipe in Recipes do
        if recipe.id == recipeId then
            return recipe
        end
    end

    error(`unknown recipeId: {recipeId}`)
end

local function nextRecipeId(servedDrinks: number): string
    return recipeRotation[(servedDrinks % #recipeRotation) + 1]
end

local function createOrder(recipeId: string, now: number?): Order
    local createdAt = now or os.clock()
    nextOrderNumber += 1

    return {
        id = `order-{math.floor(createdAt * 1000)}-{nextOrderNumber}`,
        recipeId = recipeId,
        createdAt = createdAt,
        patience = DEFAULT_PATIENCE_SECONDS,
        status = "Queued",
    }
end

local function createOrderAndDrink(recipeId: string, now: number?): (Order, Types.Drink)
    local order = createOrder(recipeId, now)
    return order, DrinkRules.createDrink(order.id, order.recipeId)
end

function CafeSession.create(now: number?): CafeSession
    local order, drink = createOrderAndDrink(nextRecipeId(0), now)

    return {
        activeOrder = order,
        activeDrink = drink,
        money = 0,
        servedDrinks = 0,
        lastMessage = "Make the order.",
    }
end

function CafeSession.snapshot(session: CafeSession): Snapshot
    local recipe = findRecipe(session.activeOrder.recipeId)
    local nextStep: Types.StationStep? =
        recipe.steps[#session.activeDrink.completedSteps + 1] :: any

    return {
        orderId = session.activeOrder.id,
        recipeId = recipe.id,
        recipeName = recipe.displayName,
        money = session.money,
        status = session.activeDrink.status,
        completedSteps = copySteps(session.activeDrink.completedSteps),
        requiredSteps = copySteps(recipe.steps),
        nextStep = nextStep,
        lastMessage = session.lastMessage,
    }
end

function CafeSession.applyStep(
    session: CafeSession,
    step: Types.StationStep,
    now: number?
): StepResult
    if session.activeDrink.status == "Served" or session.activeDrink.status == "Rejected" then
        local recipeId = nextRecipeId(session.servedDrinks)
        local order, drink = createOrderAndDrink(recipeId, now)
        session.activeOrder = order
        session.activeDrink = drink
        session.lastMessage = "New order is ready."
    end

    if session.activeOrder.status == "Queued" then
        session.activeOrder.status = "InProgress"
    end

    if step == "Serve" then
        local serveResult = DrinkRules.serveDrink(session.activeDrink)
        session.activeDrink = serveResult.drink

        if serveResult.accepted then
            session.activeOrder.status = "Completed"
            session.money += serveResult.payout
            session.servedDrinks += 1
            session.lastMessage = `Served! +${serveResult.payout}`

            return {
                accepted = true,
                snapshot = CafeSession.snapshot(session),
                reason = nil,
            }
        end

        session.lastMessage = serveResult.reason or "That drink needs a remake."

        return {
            accepted = false,
            snapshot = CafeSession.snapshot(session),
            reason = serveResult.reason,
        }
    end

    local stepResult = DrinkRules.applyStep(session.activeDrink, step)
    session.activeDrink = stepResult.drink

    if stepResult.accepted then
        session.lastMessage = `{step} done.`
    else
        session.lastMessage = stepResult.reason or "Try another station."
    end

    return {
        accepted = stepResult.accepted,
        snapshot = CafeSession.snapshot(session),
        reason = stepResult.reason,
    }
end

return CafeSession
