--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

type Snapshot = {
    recipeName: string,
    money: number,
    status: string,
    completedSteps: { string },
    requiredSteps: { string },
    nextStep: string?,
    lastMessage: string,
}

type StepResult = {
    accepted: boolean,
    snapshot: Snapshot,
    reason: string?,
}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotesFolder = ReplicatedStorage:WaitForChild("BobaSimRemotes")
local getStateRemote = remotesFolder:WaitForChild("GetState") :: RemoteFunction
local requestStepRemote = remotesFolder:WaitForChild("RequestStep") :: RemoteFunction

local stationSteps: { string } = {
    "Cup",
    "Boba",
    "Flavor",
    "Tea",
    "Milk",
    "Ice",
    "Shake",
    "Seal",
    "Serve",
}

local buttonByStep: { [string]: TextButton } = {}
local busy = false

local gui = Instance.new("ScreenGui")
gui.Name = "BobaSimHud"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "Root"
root.AnchorPoint = Vector2.new(0.5, 1)
root.Position = UDim2.fromScale(0.5, 0.98)
root.Size = UDim2.fromScale(0.94, 0.42)
root.BackgroundColor3 = Color3.fromRGB(29, 27, 24)
root.BackgroundTransparency = 0.08
root.BorderSizePixel = 0
root.Parent = gui

local rootCorner = Instance.new("UICorner")
rootCorner.CornerRadius = UDim.new(0, 8)
rootCorner.Parent = root

local rootPadding = Instance.new("UIPadding")
rootPadding.PaddingBottom = UDim.new(0, 12)
rootPadding.PaddingLeft = UDim.new(0, 12)
rootPadding.PaddingRight = UDim.new(0, 12)
rootPadding.PaddingTop = UDim.new(0, 12)
rootPadding.Parent = root

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = root

local ticket = Instance.new("TextLabel")
ticket.Name = "Ticket"
ticket.LayoutOrder = 1
ticket.Size = UDim2.new(1, 0, 0, 42)
ticket.BackgroundTransparency = 1
ticket.Font = Enum.Font.GothamBold
ticket.TextColor3 = Color3.fromRGB(255, 244, 225)
ticket.TextScaled = true
ticket.TextXAlignment = Enum.TextXAlignment.Left
ticket.Parent = root

local ticketTextSize = Instance.new("UITextSizeConstraint")
ticketTextSize.MaxTextSize = 28
ticketTextSize.MinTextSize = 14
ticketTextSize.Parent = ticket

local progress = Instance.new("TextLabel")
progress.Name = "Progress"
progress.LayoutOrder = 2
progress.Size = UDim2.new(1, 0, 0, 28)
progress.BackgroundTransparency = 1
progress.Font = Enum.Font.GothamMedium
progress.TextColor3 = Color3.fromRGB(205, 232, 218)
progress.TextScaled = true
progress.TextXAlignment = Enum.TextXAlignment.Left
progress.Parent = root

local progressTextSize = Instance.new("UITextSizeConstraint")
progressTextSize.MaxTextSize = 18
progressTextSize.MinTextSize = 10
progressTextSize.Parent = progress

local feedback = Instance.new("TextLabel")
feedback.Name = "Feedback"
feedback.LayoutOrder = 3
feedback.Size = UDim2.new(1, 0, 0, 28)
feedback.BackgroundTransparency = 1
feedback.Font = Enum.Font.GothamBold
feedback.TextColor3 = Color3.fromRGB(255, 211, 128)
feedback.TextScaled = true
feedback.TextXAlignment = Enum.TextXAlignment.Left
feedback.Parent = root

local feedbackTextSize = Instance.new("UITextSizeConstraint")
feedbackTextSize.MaxTextSize = 20
feedbackTextSize.MinTextSize = 10
feedbackTextSize.Parent = feedback

local stationGrid = Instance.new("Frame")
stationGrid.Name = "Stations"
stationGrid.LayoutOrder = 4
stationGrid.Size = UDim2.new(1, 0, 1, -122)
stationGrid.BackgroundTransparency = 1
stationGrid.Parent = root

local grid = Instance.new("UIGridLayout")
grid.CellPadding = UDim2.fromOffset(8, 8)
grid.CellSize = UDim2.new(0.333, -8, 0.333, -8)
grid.FillDirectionMaxCells = 3
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = stationGrid

local function completedStepText(snapshot: Snapshot): string
    if #snapshot.completedSteps == 0 then
        return "No steps yet"
    end

    return table.concat(snapshot.completedSteps, " > ")
end

local function flashButton(button: TextButton, color: Color3)
    local originalColor = button.BackgroundColor3
    button.BackgroundColor3 = color

    local tween = TweenService:Create(
        button,
        TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { BackgroundColor3 = originalColor }
    )
    tween:Play()
end

local function setButtonsEnabled(enabled: boolean)
    for _, button in buttonByStep do
        button.Active = enabled
        button.AutoButtonColor = enabled
        button.TextTransparency = if enabled then 0 else 0.35
    end
end

local function render(snapshot: Snapshot)
    ticket.Text = `{snapshot.recipeName}  ${snapshot.money}`
    progress.Text = `Next: {snapshot.nextStep or "New order"} | {completedStepText(snapshot)}`
    feedback.Text = snapshot.lastMessage

    for index = 1, #stationSteps do
        local step = stationSteps[index]
        local button = buttonByStep[step]
        local isNext = snapshot.nextStep == step

        button.BackgroundColor3 = if isNext
            then Color3.fromRGB(49, 132, 96)
            else Color3.fromRGB(63, 58, 51)
        button.TextColor3 = if isNext
            then Color3.fromRGB(255, 255, 245)
            else Color3.fromRGB(228, 219, 205)
    end
end

local function requestStep(step: string)
    if busy then
        return
    end

    busy = true
    setButtonsEnabled(false)

    local success, response = pcall(function()
        return requestStepRemote:InvokeServer(step)
    end)

    setButtonsEnabled(true)
    busy = false

    local button = buttonByStep[step]
    if not success then
        feedback.Text = "Could not reach the cafe server."
        flashButton(button, Color3.fromRGB(158, 62, 62))
        return
    end

    local result = response :: StepResult
    render(result.snapshot)
    flashButton(
        button,
        if result.accepted then Color3.fromRGB(92, 190, 133) else Color3.fromRGB(180, 72, 72)
    )
end

for index = 1, #stationSteps do
    local step = stationSteps[index]
    local button = Instance.new("TextButton")
    button.Name = `{step}Button`
    button.LayoutOrder = index
    button.BackgroundColor3 = Color3.fromRGB(63, 58, 51)
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamBold
    button.Text = step
    button.TextColor3 = Color3.fromRGB(228, 219, 205)
    button.TextScaled = true
    button.Parent = stationGrid

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button

    local textSize = Instance.new("UITextSizeConstraint")
    textSize.MaxTextSize = 22
    textSize.MinTextSize = 10
    textSize.Parent = button

    button.Activated:Connect(function()
        requestStep(step)
    end)

    buttonByStep[step] = button
end

local success, snapshot = pcall(function()
    return getStateRemote:InvokeServer()
end)

if success then
    render(snapshot :: Snapshot)
else
    feedback.Text = "Waiting for the cafe server..."
end

print("BobaSim client ready. Touch station buttons to make drinks.")
