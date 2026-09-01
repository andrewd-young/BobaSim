--!strict

local Workspace = game:GetService("Workspace")

local Types = require(game:GetService("ReplicatedStorage").Shared.Types)
local Carryables = require(game:GetService("ReplicatedStorage").Shared.Carryables)

export type StepHandler = (
    Player,
    Types.StationStep
) -> {
    accepted: boolean,
    reason: string?,
}

local StationWorld = {}

local STATIONS_FOLDER_NAME = "BobaSimStations"
local CARRY_ITEMS_FOLDER_NAME = "BobaSimCarryItems"
local boundPrompts: { [ProximityPrompt]: boolean } = {}
local boundCarryPrompts: { [ProximityPrompt]: boolean } = {}
local placedClones: { [Player]: { [Types.CarryItemId]: BasePart? } } = {}
local carryItemHandler: ((Player, Types.CarryItemId, string) -> boolean)? = nil

export type CarryItemHandler = (Player, Types.CarryItemId, string) -> boolean

local function flashPad(pad: Part, accepted: boolean)
    local originalColor = pad.Color
    pad.Color = if accepted then Color3.fromRGB(90, 210, 135) else Color3.fromRGB(215, 80, 80)

    task.delay(0.2, function()
        if pad.Parent ~= nil then
            pad.Color = originalColor
        end
    end)
end

local function bindStation(station: Instance, onStep: StepHandler)
    local step = station:GetAttribute("StationStep")
    if not Types.isStationStep(step) then
        warn(`BobaSim station {station:GetFullName()} is missing a StationStep attribute.`)
        return
    end

    local prompt = station:FindFirstChild("StationPrompt", true)
    if prompt == nil or not prompt:IsA("ProximityPrompt") then
        warn(`BobaSim station {station:GetFullName()} is missing a StationPrompt.`)
        return
    end
    if boundPrompts[prompt] then
        return
    end
    boundPrompts[prompt] = true
    -- Clickable prompts release mouse lock in first person and prevent looking around.
    -- Interactions are intentionally keyboard/gamepad driven for this prototype.
    prompt.ClickablePrompt = false

    local interactionRange = station:GetAttribute("InteractionRange")
    if typeof(interactionRange) == "number" then
        prompt.MaxActivationDistance = interactionRange
    end

    prompt.Triggered:Connect(function(player: Player)
        local result = onStep(player, step :: Types.StationStep)
        local parent = prompt.Parent
        if parent ~= nil and parent:IsA("Part") then
            flashPad(parent, result.accepted)
        end
    end)
end

function StationWorld.bindStations(onStep: StepHandler)
    local stationsFolder = Workspace:FindFirstChild(STATIONS_FOLDER_NAME)
    if stationsFolder == nil then
        warn(`BobaSim stations folder {STATIONS_FOLDER_NAME} was not found in Workspace.`)
        return
    end

    for _, station in stationsFolder:GetChildren() do
        bindStation(station, onStep)
    end

    stationsFolder.ChildAdded:Connect(function(station: Instance)
        bindStation(station, onStep)
    end)
end

local function bindCarryItem(carryItem: Instance, onCarryItem: CarryItemHandler)
    local itemId = carryItem:GetAttribute("CarryItemId")
    if not Types.isCarryItemId(itemId) then
        warn(`BobaSim carry item {carryItem:GetFullName()} is missing a CarryItemId attribute.`)
        return
    end

    local prompt = carryItem:FindFirstChild("CarryPrompt", true)
    if prompt == nil or not prompt:IsA("ProximityPrompt") then
        warn(`BobaSim carry item {carryItem:GetFullName()} is missing a CarryPrompt.`)
        return
    end
    if boundCarryPrompts[prompt] then
        return
    end
    boundCarryPrompts[prompt] = true
    -- Keep first-person camera control while a pickup prompt is visible.
    prompt.ClickablePrompt = false

    local interactionRange = carryItem:GetAttribute("InteractionRange")
    if typeof(interactionRange) == "number" then
        prompt.MaxActivationDistance = interactionRange
    end

    local itemName = Carryables.get(itemId :: Types.CarryItemId).displayName

    prompt.Triggered:Connect(function(player: Player)
        onCarryItem(player, itemId :: Types.CarryItemId, itemName)
    end)
end

function StationWorld.bindCarryItems(onCarryItem: CarryItemHandler)
    carryItemHandler = onCarryItem
    local carryItemsFolder = Workspace:FindFirstChild(CARRY_ITEMS_FOLDER_NAME)
    if carryItemsFolder == nil then
        warn(`BobaSim carry items folder {CARRY_ITEMS_FOLDER_NAME} was not found in Workspace.`)
        return
    end

    for _, carryItem in carryItemsFolder:GetChildren() do
        bindCarryItem(carryItem, onCarryItem)
    end

    carryItemsFolder.ChildAdded:Connect(function(carryItem: Instance)
        bindCarryItem(carryItem, onCarryItem)
    end)
end

function StationWorld.placeCarryItem(
    player: Player,
    itemId: Types.CarryItemId,
    targetCFrame: CFrame
): boolean
    local carryable = Carryables.get(itemId)
    local source = carryable.source

    if source.kind == "ExistingModel" then
        local carryItemsFolder = Workspace:FindFirstChild(CARRY_ITEMS_FOLDER_NAME)
        local existingModel = if carryItemsFolder ~= nil
            then carryItemsFolder:FindFirstChild(source.folderName)
            else nil
        if existingModel == nil or not existingModel:IsA("Model") then
            return false
        end

        existingModel:PivotTo(targetCFrame * carryable.placementOffset)
        return true
    end

    local stationsFolder = Workspace:FindFirstChild(STATIONS_FOLDER_NAME)
    local station = if stationsFolder ~= nil
        then stationsFolder:FindFirstChild(source.stationName)
        else nil
    local template = if station ~= nil then station:FindFirstChild(source.partName, true) else nil
    if template == nil or not template:IsA("BasePart") then
        return false
    end

    local playerClones = placedClones[player]
    if playerClones == nil then
        playerClones = {}
        placedClones[player] = playerClones
    end
    local previousClone = playerClones[itemId]
    if previousClone ~= nil then
        previousClone:Destroy()
    end

    local placedClone = template:Clone()
    placedClone.Name = `Placed{carryable.id}`
    placedClone.CFrame = targetCFrame * carryable.placementOffset
    placedClone.CanCollide = false
    placedClone.Parent = Workspace
    playerClones[itemId] = placedClone

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Pick Up"
    prompt.ObjectText = carryable.displayName
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.MaxActivationDistance = 8
    prompt.RequiresLineOfSight = false
    prompt.ClickablePrompt = false
    prompt.Parent = placedClone
    prompt.Triggered:Connect(function(triggeringPlayer: Player)
        if triggeringPlayer == player and carryItemHandler ~= nil then
            playerClones[itemId] = nil
            placedClone:Destroy()
            carryItemHandler(triggeringPlayer, itemId, carryable.displayName)
        end
    end)
    return true
end

function StationWorld.clearPlayerCarryables(player: Player)
    local playerClones = placedClones[player]
    if playerClones ~= nil then
        for _, placedClone in playerClones do
            if placedClone ~= nil then
                placedClone:Destroy()
            end
        end
    end
    placedClones[player] = nil
end

return StationWorld
