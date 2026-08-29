--!strict

local OrderService = require("../src/server/OrderService")
local DrinkRules = require("../src/shared/DrinkRules")
local Types = require("../src/shared/Types")

local function assertEqual<T>(actual: T, expected: T, message: string)
    if actual ~= expected then
        error(`{message}: expected {tostring(expected)}, got {tostring(actual)}`)
    end
end

local order = OrderService.createOrder("classic_milk_tea", 10)

assertEqual(order.recipeId, "classic_milk_tea", "order recipe id")
assertEqual(order.status, "Queued", "new order status")
assertEqual(OrderService.getRemainingPatience(order, 25), 45, "remaining patience")
assertEqual(OrderService.getRemainingPatience(order, 1000), 0, "patience floor")

local inProgress = OrderService.markInProgress(order)

assertEqual(inProgress.status, "InProgress", "in-progress status")
assertEqual(order.status, "Queued", "original order stays immutable")

local drink = DrinkRules.createDrink(order.id, order.recipeId)

assertEqual(drink.orderId, order.id, "drink order id")
assertEqual(drink.recipeId, "classic_milk_tea", "drink recipe id")
assertEqual(drink.status, "Building", "new drink status")

local cupStep = DrinkRules.applyStep(drink, "Cup")
assertEqual(cupStep.accepted, true, "cup step accepted")
assertEqual(cupStep.drink.status, "Building", "cup keeps drink building")
assertEqual(#cupStep.drink.completedSteps, 1, "cup step recorded")
assertEqual(#drink.completedSteps, 0, "original drink stays immutable")

local duplicateCup = DrinkRules.applyStep(cupStep.drink, "Cup")
assertEqual(duplicateCup.accepted, false, "duplicate cup rejected")
assertEqual(duplicateCup.reason, "expected Boba, got Cup", "duplicate cup reason")

local earlyServe = DrinkRules.serveDrink(cupStep.drink)
assertEqual(earlyServe.accepted, false, "early serve rejected")
assertEqual(earlyServe.payout, 0, "early serve payout")
assertEqual(earlyServe.drink.status, "Rejected", "early serve rejected status")

local function applyAcceptedStep(
    currentDrink: Types.Drink,
    step: Types.StationStep,
    message: string
): Types.Drink
    local result = DrinkRules.applyStep(currentDrink, step)
    assertEqual(result.accepted, true, `{step} step accepted`)
    assertEqual(result.reason, nil, message)
    return result.drink
end

local currentDrink = cupStep.drink
currentDrink = applyAcceptedStep(currentDrink, "Boba", "boba has no failure reason")
currentDrink = applyAcceptedStep(currentDrink, "Tea", "tea has no failure reason")
currentDrink = applyAcceptedStep(currentDrink, "Milk", "milk has no failure reason")
currentDrink = applyAcceptedStep(currentDrink, "Ice", "ice has no failure reason")
currentDrink = applyAcceptedStep(currentDrink, "Shake", "shake has no failure reason")
currentDrink = applyAcceptedStep(currentDrink, "Seal", "seal has no failure reason")

assertEqual(currentDrink.status, "Sealed", "sealed drink status")

local served = DrinkRules.serveDrink(currentDrink)
assertEqual(served.accepted, true, "finished drink accepted")
assertEqual(served.payout, 8, "finished drink payout")
assertEqual(served.drink.status, "Served", "served drink status")
assertEqual(
    served.drink.completedSteps[#served.drink.completedSteps],
    "Serve",
    "serve step recorded"
)

local sealedAgain = DrinkRules.applyStep(served.drink, "Seal")
assertEqual(sealedAgain.accepted, false, "served drink cannot be changed")

local strawberryDrink = DrinkRules.createDrink("strawberry-order", "strawberry_milk_tea")
local strawberryCurrent = strawberryDrink
strawberryCurrent =
    applyAcceptedStep(strawberryCurrent, "Cup", "strawberry cup has no failure reason")
strawberryCurrent =
    applyAcceptedStep(strawberryCurrent, "Boba", "strawberry boba has no failure reason")
strawberryCurrent =
    applyAcceptedStep(strawberryCurrent, "Flavor", "strawberry flavor has no failure reason")
strawberryCurrent =
    applyAcceptedStep(strawberryCurrent, "Tea", "strawberry tea has no failure reason")
strawberryCurrent =
    applyAcceptedStep(strawberryCurrent, "Milk", "strawberry milk has no failure reason")
strawberryCurrent =
    applyAcceptedStep(strawberryCurrent, "Ice", "strawberry ice has no failure reason")
strawberryCurrent =
    applyAcceptedStep(strawberryCurrent, "Shake", "strawberry shake has no failure reason")
strawberryCurrent =
    applyAcceptedStep(strawberryCurrent, "Seal", "strawberry seal has no failure reason")

local strawberryServed = DrinkRules.serveDrink(strawberryCurrent)
assertEqual(strawberryServed.accepted, true, "strawberry drink accepted")
assertEqual(strawberryServed.payout, 9, "strawberry payout")

print("All tests passed.")
