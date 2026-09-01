--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CafeSession = require(ReplicatedStorage.Shared.CafeSession)
local Carryables = require(ReplicatedStorage.Shared.Carryables)
local PhysicalInteractions = require(ReplicatedStorage.Shared.PhysicalInteractions)
local StationWorld = require(script.StationWorld)
local Types = require(ReplicatedStorage.Shared.Types)

local remotesFolder = ReplicatedStorage:FindFirstChild("BobaSimRemotes")
if remotesFolder == nil then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "BobaSimRemotes"
    remotesFolder.Parent = ReplicatedStorage
end

local getStateRemote = remotesFolder:FindFirstChild("GetState")
if getStateRemote == nil then
    getStateRemote = Instance.new("RemoteFunction")
    getStateRemote.Name = "GetState"
    getStateRemote.Parent = remotesFolder
end

local requestStepRemote = remotesFolder:FindFirstChild("RequestStep")
if requestStepRemote == nil then
    requestStepRemote = Instance.new("RemoteFunction")
    requestStepRemote.Name = "RequestStep"
    requestStepRemote.Parent = remotesFolder
end

local placeHeldItemRemote = remotesFolder:FindFirstChild("PlaceHeldItem")
if placeHeldItemRemote == nil then
    placeHeldItemRemote = Instance.new("RemoteFunction")
    placeHeldItemRemote.Name = "PlaceHeldItem"
    placeHeldItemRemote.Parent = remotesFolder
end

local stateChangedRemote = remotesFolder:FindFirstChild("StateChanged")
if stateChangedRemote == nil then
    stateChangedRemote = Instance.new("RemoteEvent")
    stateChangedRemote.Name = "StateChanged"
    stateChangedRemote.Parent = remotesFolder
end
local stateChangedEvent = stateChangedRemote :: RemoteEvent

local sessionsByPlayer: { [Player]: CafeSession.CafeSession } = {}
local MAX_PLACE_DISTANCE = 18

local function getSession(player: Player): CafeSession.CafeSession
    local session = sessionsByPlayer[player]
    if session == nil then
        session = CafeSession.create()
        sessionsByPlayer[player] = session
    end

    return session
end

getStateRemote.OnServerInvoke = function(player: Player): CafeSession.Snapshot
    return CafeSession.snapshot(getSession(player))
end

local function applyPlayerStep(
    player: Player,
    step: CafeSession.StationStep
): CafeSession.StepResult
    local session = getSession(player)
    local interactionRule: PhysicalInteractions.StepCarryRule = PhysicalInteractions.getRule(step)
    local producedCarryItemId = interactionRule.producedCarryItemId
    if producedCarryItemId ~= nil and session.heldItemId ~= nil then
        session.lastMessage =
            `Place {session.heldItemName or "the item"} before taking {Carryables.get(
                producedCarryItemId :: Types.CarryItemId
            ).displayName}.`
        local blockedResult = {
            accepted = false,
            reason = "place your held item before taking the station output",
            snapshot = CafeSession.snapshot(session),
        }
        stateChangedEvent:FireClient(player, blockedResult.snapshot)
        return blockedResult
    end

    local result = CafeSession.applyStep(session, step)
    if result.accepted and producedCarryItemId ~= nil then
        local carryable = Carryables.get(producedCarryItemId :: Types.CarryItemId)
        CafeSession.holdItem(session, carryable.id, carryable.displayName)
        result = {
            accepted = true,
            reason = result.reason,
            snapshot = CafeSession.snapshot(session),
        }
    end
    stateChangedEvent:FireClient(player, result.snapshot)
    return result
end

requestStepRemote.OnServerInvoke = function(player: Player, step: unknown): CafeSession.StepResult
    if not Types.isStationStep(step) then
        local session = getSession(player)
        session.lastMessage = "Pick a station."
        local result = {
            accepted = false,
            snapshot = CafeSession.snapshot(session),
            reason = "station step must be valid",
        }
        stateChangedEvent:FireClient(player, result.snapshot)
        return result
    end

    return applyPlayerStep(player, step :: CafeSession.StationStep)
end

placeHeldItemRemote.OnServerInvoke = function(
    player: Player,
    targetCFrame: unknown
): CafeSession.Snapshot
    local session = getSession(player)
    local heldItemId = session.heldItemId

    if heldItemId == nil then
        local snapshot = CafeSession.placeHeldItem(session)
        stateChangedEvent:FireClient(player, snapshot)
        return snapshot
    end

    if typeof(targetCFrame) ~= "CFrame" then
        session.lastMessage = "Aim somewhere nearby to place that."
        local blockedSnapshot = CafeSession.snapshot(session)
        stateChangedEvent:FireClient(player, blockedSnapshot)
        return blockedSnapshot
    end

    local character = player.Character
    local rootPart = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
    if rootPart == nil or not rootPart:IsA("BasePart") then
        session.lastMessage = "Wait for your character before placing that."
        local blockedSnapshot = CafeSession.snapshot(session)
        stateChangedEvent:FireClient(player, blockedSnapshot)
        return blockedSnapshot
    end

    local placementDistance = (rootPart.Position - (targetCFrame :: CFrame).Position).Magnitude
    if placementDistance > MAX_PLACE_DISTANCE then
        session.lastMessage = "Move closer to place that."
        local blockedSnapshot = CafeSession.snapshot(session)
        stateChangedEvent:FireClient(player, blockedSnapshot)
        return blockedSnapshot
    end

    local placed =
        StationWorld.placeCarryItem(player, heldItemId :: Types.CarryItemId, targetCFrame :: CFrame)
    if not placed then
        session.lastMessage = "That item could not be placed."
        local blockedSnapshot = CafeSession.snapshot(session)
        stateChangedEvent:FireClient(player, blockedSnapshot)
        return blockedSnapshot
    end

    local snapshot = CafeSession.placeHeldItem(session)
    stateChangedEvent:FireClient(player, snapshot)
    return snapshot
end

StationWorld.bindStations(function(player: Player, step: CafeSession.StationStep)
    return applyPlayerStep(player, step)
end)

StationWorld.bindCarryItems(function(player: Player, itemId: Types.CarryItemId, displayName: string)
    local session = getSession(player)
    if session.heldItemId ~= nil then
        session.lastMessage =
            `Place {session.heldItemName or "the item"} before picking up another one.`
        stateChangedEvent:FireClient(player, CafeSession.snapshot(session))
        return false
    end

    local snapshot = CafeSession.holdItem(session, itemId, displayName)
    stateChangedEvent:FireClient(player, snapshot)
    return true
end)

Players.PlayerRemoving:Connect(function(player: Player)
    sessionsByPlayer[player] = nil
    StationWorld.clearPlayerCarryables(player)
end)

print("BobaSim server ready. Station loop remotes are live.")
