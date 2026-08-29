--!strict

export type OrderStatus = "Queued" | "InProgress" | "Completed" | "Abandoned"

export type Order = {
    id: string,
    recipeId: string,
    createdAt: number,
    patience: number,
    status: OrderStatus,
}

local DEFAULT_PATIENCE_SECONDS = 60

local OrderService = {}

local nextOrderNumber = 0

local function createOrderId(createdAt: number): string
    nextOrderNumber += 1
    return `order-{math.floor(createdAt * 1000)}-{nextOrderNumber}`
end

function OrderService.createOrder(recipeId: string, createdAt: number?): Order
    assert(recipeId ~= "", "recipeId must not be empty")

    local orderCreatedAt = createdAt or os.clock()

    return {
        id = createOrderId(orderCreatedAt),
        recipeId = recipeId,
        createdAt = orderCreatedAt,
        patience = DEFAULT_PATIENCE_SECONDS,
        status = "Queued",
    }
end

function OrderService.getRemainingPatience(order: Order, now: number): number
    local elapsed = math.max(0, now - order.createdAt)
    return math.max(0, order.patience - elapsed)
end

function OrderService.markInProgress(order: Order): Order
    return {
        id = order.id,
        recipeId = order.recipeId,
        createdAt = order.createdAt,
        patience = order.patience,
        status = "InProgress",
    }
end

return OrderService
