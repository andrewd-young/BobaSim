--!strict

local OrderService = require(script.OrderService)

local previewOrder = OrderService.createOrder("classic_milk_tea")

print(`BobaSim server ready. First recipe: {previewOrder.recipeId}`)
