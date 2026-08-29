--!strict

local Workspace = game:GetService("Workspace")

local Types = require(game:GetService("ReplicatedStorage").Shared.Types)

export type StepHandler = (
    Player,
    Types.StationStep
) -> {
    accepted: boolean,
    reason: string?,
}

local StationWorld = {}

local STATIONS_FOLDER_NAME = "BobaSimStations"
local boundPrompts: { [ProximityPrompt]: boolean } = {}

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
    if typeof(step) ~= "string" then
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

return StationWorld
