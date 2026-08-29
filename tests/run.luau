--!strict

local OrderService = require("../src/server/OrderService")

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

print("All tests passed.")
