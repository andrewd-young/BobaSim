--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CafeSession = require(ReplicatedStorage.Shared.CafeSession)

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

local sessionsByPlayer: { [Player]: CafeSession.CafeSession } = {}

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

requestStepRemote.OnServerInvoke = function(player: Player, step: unknown): CafeSession.StepResult
    if typeof(step) ~= "string" then
        local session = getSession(player)
        session.lastMessage = "Pick a station."
        return {
            accepted = false,
            snapshot = CafeSession.snapshot(session),
            reason = "station step must be a string",
        }
    end

    return CafeSession.applyStep(getSession(player), step :: any)
end

Players.PlayerRemoving:Connect(function(player: Player)
    sessionsByPlayer[player] = nil
end)

print("BobaSim server ready. Station loop remotes are live.")
