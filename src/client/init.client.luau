--!strict

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Carryables = require(ReplicatedStorage.Shared.Carryables)
local PhysicalInteractions = require(ReplicatedStorage.Shared.PhysicalInteractions)
local Types = require(ReplicatedStorage.Shared.Types)

type Snapshot = {
    recipeName: string,
    money: number,
    status: string,
    completedSteps: { Types.StationStep },
    requiredSteps: { Types.StationStep },
    availableSteps: { Types.StationStep },
    nextStep: Types.StationStep?,
    heldItemId: Types.CarryItemId?,
    heldItemName: string?,
    lastMessage: string,
}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

player.CameraMode = Enum.CameraMode.LockFirstPerson
player.CameraMinZoomDistance = 0.5
player.CameraMaxZoomDistance = 0.5

local remotesFolder = ReplicatedStorage:WaitForChild("BobaSimRemotes")
local getStateRemote = remotesFolder:WaitForChild("GetState") :: RemoteFunction
local placeHeldItemRemote = remotesFolder:WaitForChild("PlaceHeldItem") :: RemoteFunction
local stateChangedRemote = remotesFolder:WaitForChild("StateChanged") :: RemoteEvent

local checklistLabels: { TextLabel } = {}
local carryItemsFolder = Workspace:WaitForChild("BobaSimCarryItems")
local stationsFolder = Workspace:WaitForChild("BobaSimStations")
local heldVisual: Model? = nil
local heldSourceModel: Model? = nil
local hiddenSourceParts: { BasePart } = {}
local hiddenSourcePrompts: { [ProximityPrompt]: boolean } = {}
local hiddenCarryPrompts: { [ProximityPrompt]: boolean } = {}
local currentHeldItemId: Types.CarryItemId? = nil
local render: ((Snapshot) -> ())? = nil
local lastSnapshot: Snapshot? = nil
local PLACE_ACTION = "BobaSimPlaceHeldItem"
local PLACE_DISTANCE = 10
local PLACE_SURFACE_OFFSET = 0.35
local USE_TOUCH_PLACE_BUTTON = UserInputService.TouchEnabled

local function getPlaceHint(): string
    local inputType = UserInputService:GetLastInputType()
    if inputType == Enum.UserInputType.Touch then
        return "Tap Place"
    end
    if string.sub(inputType.Name, 1, 7) == "Gamepad" then
        return "X to place"
    end

    return "F to place"
end

local gui = Instance.new("ScreenGui")
gui.Name = "BobaSimHud"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "Root"
root.AnchorPoint = Vector2.new(1, 0)
root.Position = UDim2.new(1, -14, 0, 14)
root.Size = UDim2.fromOffset(230, 246)
root.BackgroundColor3 = Color3.fromRGB(29, 27, 24)
root.BackgroundTransparency = 0.18
root.BorderSizePixel = 0
root.Parent = gui

local rootCorner = Instance.new("UICorner")
rootCorner.CornerRadius = UDim.new(0, 8)
rootCorner.Parent = root

local rootPadding = Instance.new("UIPadding")
rootPadding.PaddingBottom = UDim.new(0, 12)
rootPadding.PaddingLeft = UDim.new(0, 12)
rootPadding.PaddingRight = UDim.new(0, 12)
rootPadding.PaddingTop = UDim.new(0, 8)
rootPadding.Parent = root

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.Padding = UDim.new(0, 5)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = root

local ticket = Instance.new("TextLabel")
ticket.Name = "Ticket"
ticket.LayoutOrder = 1
ticket.Size = UDim2.new(1, 0, 0, 24)
ticket.BackgroundTransparency = 1
ticket.Font = Enum.Font.GothamBold
ticket.TextColor3 = Color3.fromRGB(255, 244, 225)
ticket.TextScaled = true
ticket.TextXAlignment = Enum.TextXAlignment.Left
ticket.Parent = root

local ticketTextSize = Instance.new("UITextSizeConstraint")
ticketTextSize.MaxTextSize = 18
ticketTextSize.MinTextSize = 10
ticketTextSize.Parent = ticket

local progress = Instance.new("TextLabel")
progress.Name = "Progress"
progress.LayoutOrder = 2
progress.Size = UDim2.new(1, 0, 0, 18)
progress.BackgroundTransparency = 1
progress.Font = Enum.Font.GothamMedium
progress.TextColor3 = Color3.fromRGB(205, 232, 218)
progress.TextScaled = true
progress.TextXAlignment = Enum.TextXAlignment.Left
progress.Parent = root

local progressTextSize = Instance.new("UITextSizeConstraint")
progressTextSize.MaxTextSize = 14
progressTextSize.MinTextSize = 10
progressTextSize.Parent = progress

local heldItem = Instance.new("TextLabel")
heldItem.Name = "HeldItem"
heldItem.LayoutOrder = 3
heldItem.Size = UDim2.new(1, 0, 0, 18)
heldItem.BackgroundTransparency = 1
heldItem.Font = Enum.Font.GothamMedium
heldItem.TextColor3 = Color3.fromRGB(238, 220, 185)
heldItem.TextScaled = true
heldItem.TextXAlignment = Enum.TextXAlignment.Left
heldItem.Parent = root

local heldItemTextSize = Instance.new("UITextSizeConstraint")
heldItemTextSize.MaxTextSize = 13
heldItemTextSize.MinTextSize = 9
heldItemTextSize.Parent = heldItem

local checklist = Instance.new("Frame")
checklist.Name = "Checklist"
checklist.LayoutOrder = 4
checklist.Size = UDim2.new(1, 0, 0, 116)
checklist.BackgroundTransparency = 1
checklist.Parent = root

local checklistLayout = Instance.new("UIListLayout")
checklistLayout.FillDirection = Enum.FillDirection.Vertical
checklistLayout.Padding = UDim.new(0, 1)
checklistLayout.SortOrder = Enum.SortOrder.LayoutOrder
checklistLayout.Parent = checklist

local feedback = Instance.new("TextLabel")
feedback.Name = "Feedback"
feedback.LayoutOrder = 5
feedback.Size = UDim2.new(1, 0, 0, 28)
feedback.BackgroundTransparency = 1
feedback.Font = Enum.Font.GothamMedium
feedback.TextColor3 = Color3.fromRGB(255, 211, 128)
feedback.TextScaled = true
feedback.TextWrapped = true
feedback.TextXAlignment = Enum.TextXAlignment.Left
feedback.Parent = root

local feedbackTextSize = Instance.new("UITextSizeConstraint")
feedbackTextSize.MaxTextSize = 13
feedbackTextSize.MinTextSize = 9
feedbackTextSize.Parent = feedback

local reticle = Instance.new("Frame")
reticle.Name = "Reticle"
reticle.AnchorPoint = Vector2.new(0.5, 0.5)
reticle.Position = UDim2.fromScale(0.5, 0.5)
reticle.Size = UDim2.fromOffset(7, 7)
reticle.BackgroundColor3 = Color3.fromRGB(255, 244, 225)
reticle.BackgroundTransparency = 0.18
reticle.BorderSizePixel = 0
reticle.Parent = gui

local reticleCorner = Instance.new("UICorner")
reticleCorner.CornerRadius = UDim.new(1, 0)
reticleCorner.Parent = reticle

local function hasCompletedStep(snapshot: Snapshot, step: Types.StationStep): boolean
    for _, completedStep in snapshot.completedSteps do
        if completedStep == step then
            return true
        end
    end

    return false
end

local function isAvailableStep(snapshot: Snapshot, step: Types.StationStep): boolean
    for _, availableStep in snapshot.availableSteps do
        if availableStep == step then
            return true
        end
    end

    return false
end

local function ensureChecklistRows(snapshot: Snapshot)
    while #checklistLabels < #snapshot.requiredSteps do
        local row = Instance.new("TextLabel")
        row.Name = `Step{#checklistLabels + 1}`
        row.LayoutOrder = #checklistLabels + 1
        row.Size = UDim2.new(1, 0, 0, 12)
        row.BackgroundTransparency = 1
        row.Font = Enum.Font.GothamMedium
        row.TextScaled = true
        row.TextXAlignment = Enum.TextXAlignment.Left
        row.Parent = checklist

        local textSize = Instance.new("UITextSizeConstraint")
        textSize.MaxTextSize = 12
        textSize.MinTextSize = 8
        textSize.Parent = row

        table.insert(checklistLabels, row)
    end

    for index = #snapshot.requiredSteps + 1, #checklistLabels do
        checklistLabels[index].Visible = false
    end
end

local function findVisualTemplate(itemId: Types.CarryItemId): Instance?
    local source = Carryables.get(itemId).source
    if source.kind == "ExistingModel" then
        local model = carryItemsFolder:FindFirstChild(source.folderName)
        return if model ~= nil and model:IsA("Model") then model else nil
    end

    local station = stationsFolder:FindFirstChild(source.stationName)
    local part = if station ~= nil then station:FindFirstChild(source.partName, true) else nil
    return if part ~= nil and part:IsA("BasePart") then part else nil
end

local function setModelLocalTransparency(model: Model, transparency: number)
    for _, descendant in model:GetDescendants() do
        if descendant:IsA("BasePart") then
            descendant.LocalTransparencyModifier = transparency
            table.insert(hiddenSourceParts, descendant)
        elseif descendant:IsA("ProximityPrompt") then
            hiddenSourcePrompts[descendant] = descendant.Enabled
            descendant.Enabled = false
        end
    end
end

local function restoreSourceParts()
    for _, part in hiddenSourceParts do
        if part.Parent ~= nil then
            part.LocalTransparencyModifier = 0
        end
    end
    table.clear(hiddenSourceParts)

    for prompt, wasEnabled in hiddenSourcePrompts do
        if prompt.Parent ~= nil then
            prompt.Enabled = wasEnabled
        end
    end
    table.clear(hiddenSourcePrompts)
end

local function setCarryPromptsHidden(hidden: boolean)
    if hidden then
        for _, descendant in carryItemsFolder:GetDescendants() do
            if descendant:IsA("ProximityPrompt") and hiddenCarryPrompts[descendant] == nil then
                hiddenCarryPrompts[descendant] = descendant.Enabled
                descendant.Enabled = false
            end
        end
        return
    end

    for prompt, wasEnabled in hiddenCarryPrompts do
        if prompt.Parent ~= nil then
            prompt.Enabled = wasEnabled
        end
    end
    table.clear(hiddenCarryPrompts)
end

local function clearHeldVisual()
    if heldVisual ~= nil then
        heldVisual:Destroy()
        heldVisual = nil
    end

    restoreSourceParts()
    heldSourceModel = nil
    currentHeldItemId = nil
end

local function prepareHeldVisualPart(part: BasePart)
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Massless = true
    part.CastShadow = false
end

local function centerModelPivot(model: Model)
    local boundsCFrame = model:GetBoundingBox()
    model.WorldPivot = boundsCFrame
end

local function createHeldVisual(itemId: Types.CarryItemId)
    if currentHeldItemId == itemId and heldVisual ~= nil then
        return
    end

    clearHeldVisual()

    local carryable = Carryables.get(itemId)
    local template = findVisualTemplate(itemId)
    if template == nil then
        return
    end

    if carryable.source.kind == "ExistingModel" then
        local sourceModel = template :: Model
        setModelLocalTransparency(sourceModel, 1)
        heldSourceModel = sourceModel
    end

    local clone: Model
    if template:IsA("Model") then
        clone = template:Clone()
    else
        clone = Instance.new("Model")
        local part = template:Clone()
        part.Parent = clone
    end
    clone.Name = "HeldCarryItem"

    for _, descendant in clone:GetDescendants() do
        if descendant:IsA("ProximityPrompt") then
            descendant.Enabled = false
        elseif descendant:IsA("BasePart") then
            prepareHeldVisualPart(descendant)
        end
    end

    centerModelPivot(clone)
    clone.Parent = Workspace.CurrentCamera
    heldVisual = clone
    currentHeldItemId = itemId
end

local function syncHeldVisual(snapshot: Snapshot)
    if snapshot.heldItemId ~= nil then
        setCarryPromptsHidden(true)
        createHeldVisual(snapshot.heldItemId)
    else
        clearHeldVisual()
        -- Restore after clearing the held source so the placed item is interactable again.
        setCarryPromptsHidden(false)
    end
end

local function getHeldPlacementCFrame(): CFrame?
    local currentCamera = Workspace.CurrentCamera
    if currentCamera == nil then
        return nil
    end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local filterInstances: { Instance } = {}
    if player.Character ~= nil then
        table.insert(filterInstances, player.Character :: Model)
    end
    if heldVisual ~= nil then
        table.insert(filterInstances, heldVisual)
    end
    if heldSourceModel ~= nil then
        table.insert(filterInstances, heldSourceModel)
    end
    raycastParams.FilterDescendantsInstances = filterInstances

    local pointerPosition = currentCamera.ViewportSize / 2
    local cursorRay = currentCamera:ViewportPointToRay(pointerPosition.X, pointerPosition.Y)
    local origin = cursorRay.Origin
    local direction = cursorRay.Direction * PLACE_DISTANCE
    local result = Workspace:Raycast(origin, direction, raycastParams)
    if result == nil then
        return nil
    end

    local _, cameraYaw = currentCamera.CFrame:ToOrientation()
    local position = result.Position + (result.Normal * PLACE_SURFACE_OFFSET)
    return CFrame.new(position) * CFrame.Angles(0, cameraYaw, 0)
end

local function placeHeldItem()
    if currentHeldItemId == nil then
        return
    end

    local placementCFrame = getHeldPlacementCFrame()
    if placementCFrame == nil then
        feedback.Text = "Aim at a counter to place that."
        return
    end

    local success, updatedSnapshot = pcall(function()
        return placeHeldItemRemote:InvokeServer(placementCFrame)
    end)

    if success then
        local renderSnapshot = render
        if renderSnapshot ~= nil then
            renderSnapshot(updatedSnapshot :: Snapshot)
        end
    else
        feedback.Text = "Could not place that. Try aiming at a counter."
    end
end

local function onPlaceAction(_, inputState: Enum.UserInputState)
    if inputState ~= Enum.UserInputState.Begin then
        return Enum.ContextActionResult.Pass
    end

    if currentHeldItemId == nil then
        return Enum.ContextActionResult.Pass
    end
    placeHeldItem()
    return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction(
    PLACE_ACTION,
    onPlaceAction,
    USE_TOUCH_PLACE_BUTTON,
    Enum.KeyCode.F,
    Enum.KeyCode.ButtonX
)

if USE_TOUCH_PLACE_BUTTON then
    ContextActionService:SetTitle(PLACE_ACTION, "Place")
    ContextActionService:SetPosition(PLACE_ACTION, UDim2.fromScale(0.78, 0.72))
end

RunService.RenderStepped:Connect(function()
    local currentCamera = Workspace.CurrentCamera
    if currentCamera == nil then
        return
    end

    local heldItemId = currentHeldItemId
    if heldVisual ~= nil and heldItemId ~= nil then
        heldVisual:PivotTo(
            currentCamera.CFrame * Carryables.get(heldItemId :: Types.CarryItemId).heldOffset
        )
    end
end)

render = function(snapshot: Snapshot)
    lastSnapshot = snapshot
    ticket.Text = `{snapshot.recipeName}  ${snapshot.money}`
    local nextStepLabel = if snapshot.nextStep ~= nil
        then PhysicalInteractions.getRule(snapshot.nextStep).checklistLabel
        else "New order"
    progress.Text = `Do now: {nextStepLabel}`
    heldItem.Text = if snapshot.heldItemName ~= nil
        then `Holding: {snapshot.heldItemName} ({getPlaceHint()})`
        else "Hand: empty"
    feedback.Text = snapshot.lastMessage
    syncHeldVisual(snapshot)

    ensureChecklistRows(snapshot)

    for index = 1, #snapshot.requiredSteps do
        local step: Types.StationStep = snapshot.requiredSteps[index]
        local row = checklistLabels[index]
        local isDone = hasCompletedStep(snapshot, step)
        local isAvailable = isAvailableStep(snapshot, step)
        local isNext = snapshot.nextStep == step

        row.Visible = true
        local prefix = if isDone
            then "[done]"
            elseif isNext then "[now]"
            elseif isAvailable then "[ready]"
            else "[later]"
        row.Text = `{prefix} {PhysicalInteractions.getRule(step).checklistLabel}`
        row.TextColor3 = if isDone
            then Color3.fromRGB(148, 210, 168)
            elseif isAvailable then Color3.fromRGB(255, 244, 225)
            else Color3.fromRGB(177, 166, 151)
    end
end

UserInputService.LastInputTypeChanged:Connect(function()
    if lastSnapshot ~= nil and render ~= nil then
        render(lastSnapshot)
    end
end)

local success, snapshot = pcall(function()
    return getStateRemote:InvokeServer()
end)

if success then
    (render :: (Snapshot) -> ())(snapshot :: Snapshot)
else
    ticket.Text = "BobaSim"
    progress.Text = "Waiting for cafe server"
    heldItem.Text = "Hand: empty"
    feedback.Text = ""
end

stateChangedRemote.OnClientEvent:Connect(function(updatedSnapshot: Snapshot)
    (render :: (Snapshot) -> ())(updatedSnapshot)
end)

print("BobaSim client ready. Touch station buttons to make drinks.")
