--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

type Snapshot = {
    recipeName: string,
    money: number,
    status: string,
    completedSteps: { string },
    requiredSteps: { string },
    nextStep: string?,
    lastMessage: string,
}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotesFolder = ReplicatedStorage:WaitForChild("BobaSimRemotes")
local getStateRemote = remotesFolder:WaitForChild("GetState") :: RemoteFunction
local stateChangedRemote = remotesFolder:WaitForChild("StateChanged") :: RemoteEvent

local checklistLabels: { TextLabel } = {}

local gui = Instance.new("ScreenGui")
gui.Name = "BobaSimHud"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "Root"
root.AnchorPoint = Vector2.new(1, 0)
root.Position = UDim2.new(1, -14, 0, 14)
root.Size = UDim2.fromOffset(230, 224)
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

local checklist = Instance.new("Frame")
checklist.Name = "Checklist"
checklist.LayoutOrder = 3
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
feedback.LayoutOrder = 4
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

local function hasCompletedStep(snapshot: Snapshot, step: string): boolean
    for _, completedStep in snapshot.completedSteps do
        if completedStep == step then
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

local function render(snapshot: Snapshot)
    ticket.Text = `{snapshot.recipeName}  ${snapshot.money}`
    progress.Text = `Next: {snapshot.nextStep or "New order"}`
    feedback.Text = snapshot.lastMessage

    ensureChecklistRows(snapshot)

    for index, step in snapshot.requiredSteps do
        local row = checklistLabels[index]
        local isDone = hasCompletedStep(snapshot, step)
        local isNext = snapshot.nextStep == step

        row.Visible = true
        row.Text = `{if isDone then "[x]" elseif isNext then ">" else "-"} {step}`
        row.TextColor3 = if isDone
            then Color3.fromRGB(148, 210, 168)
            elseif isNext then Color3.fromRGB(255, 244, 225)
            else Color3.fromRGB(177, 166, 151)
    end
end

local success, snapshot = pcall(function()
    return getStateRemote:InvokeServer()
end)

if success then
    render(snapshot :: Snapshot)
else
    ticket.Text = "BobaSim"
    progress.Text = "Waiting for cafe server"
    feedback.Text = ""
end

stateChangedRemote.OnClientEvent:Connect(function(updatedSnapshot: Snapshot)
    render(updatedSnapshot)
end)

print("BobaSim client ready. Touch station buttons to make drinks.")
