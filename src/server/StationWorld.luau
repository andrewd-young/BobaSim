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
local CUP_STATION_NAME = "CupStation"

local function createPart(
    name: string,
    size: Vector3,
    cframe: CFrame,
    color: Color3,
    material: Enum.Material,
    parent: Instance
): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = material
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

local function createStationLabel(text: string, adornee: BasePart, parent: Instance)
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = "StationLabel"
    surfaceGui.Adornee = adornee
    surfaceGui.Face = Enum.NormalId.Front
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 48
    surfaceGui.Parent = parent

    local label = Instance.new("TextLabel")
    label.Name = "Text"
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Size = UDim2.fromScale(1, 1)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 244, 225)
    label.TextScaled = true
    label.Parent = surfaceGui
end

local function flashPad(pad: Part, accepted: boolean)
    local originalColor = pad.Color
    pad.Color = if accepted then Color3.fromRGB(90, 210, 135) else Color3.fromRGB(215, 80, 80)

    task.delay(0.2, function()
        if pad.Parent ~= nil then
            pad.Color = originalColor
        end
    end)
end

function StationWorld.ensureCupStation(onStep: StepHandler)
    local stationsFolder = Workspace:FindFirstChild(STATIONS_FOLDER_NAME)
    if stationsFolder == nil then
        stationsFolder = Instance.new("Folder")
        stationsFolder.Name = STATIONS_FOLDER_NAME
        stationsFolder.Parent = Workspace
    end

    local existingStation = stationsFolder:FindFirstChild(CUP_STATION_NAME)
    if existingStation ~= nil then
        existingStation:Destroy()
    end

    local station = Instance.new("Model")
    station.Name = CUP_STATION_NAME
    station:SetAttribute("StationStep", "Cup")
    station:SetAttribute("DisplayName", "Cup Station")
    station:SetAttribute("InteractionRange", 8)
    station.Parent = stationsFolder

    local base = createPart(
        "Counter",
        Vector3.new(6, 1, 3),
        CFrame.new(0, 2.5, -8),
        Color3.fromRGB(91, 73, 56),
        Enum.Material.Wood,
        station
    )

    local sign = createPart(
        "Sign",
        Vector3.new(4.4, 1.4, 0.2),
        CFrame.new(0, 4.1, -9.35),
        Color3.fromRGB(45, 41, 36),
        Enum.Material.SmoothPlastic,
        station
    )
    createStationLabel("CUP", sign, station)

    local pad = createPart(
        "InteractionPad",
        Vector3.new(2, 0.18, 1.4),
        CFrame.new(0, 3.1, -7.8),
        Color3.fromRGB(46, 132, 106),
        Enum.Material.Neon,
        station
    )

    local cup = createPart(
        "CupPreview",
        Vector3.new(1, 1.3, 1),
        CFrame.new(0, 3.95, -8),
        Color3.fromRGB(255, 246, 218),
        Enum.Material.SmoothPlastic,
        station
    )
    cup.Shape = Enum.PartType.Cylinder
    cup.Orientation = Vector3.new(0, 0, 90)

    station.PrimaryPart = base

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "StationPrompt"
    prompt.ActionText = "Take Cup"
    prompt.ObjectText = "Cup Station"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 8
    prompt.RequiresLineOfSight = false
    prompt.Parent = pad

    prompt.Triggered:Connect(function(player: Player)
        local result = onStep(player, "Cup")
        flashPad(pad, result.accepted)
    end)
end

return StationWorld
