--!strict

local Types = require("./Types")

export type Carryable = Types.CarryableDefinition

local standardOffset = CFrame.new(0, -0.75, -2.1) * CFrame.Angles(math.rad(-12), 0, 0)

local definitions: { [Types.CarryItemId]: Carryable } = {
    cup = {
        id = "cup",
        displayName = "Cup",
        heldOffset = CFrame.new(0, -0.9, -1.85) * CFrame.Angles(0, 0, math.rad(90)),
        placementOffset = CFrame.Angles(0, 0, math.rad(90)),
        source = {
            kind = "CloneStationPart",
            stationName = "CupStation",
            partName = "CupPreview",
        },
    },
    boba_scoop = {
        id = "boba_scoop",
        displayName = "Boba Scoop",
        heldOffset = standardOffset,
        placementOffset = CFrame.new(),
        source = { kind = "ExistingModel", folderName = "BobaScoop" },
    },
    tea_kettle = {
        id = "tea_kettle",
        displayName = "Tea Kettle",
        heldOffset = standardOffset,
        placementOffset = CFrame.new(),
        source = { kind = "ExistingModel", folderName = "TeaKettle" },
    },
    milk_carton = {
        id = "milk_carton",
        displayName = "Milk Carton",
        heldOffset = standardOffset,
        placementOffset = CFrame.new(),
        source = { kind = "ExistingModel", folderName = "MilkCarton" },
    },
    strawberry_syrup_bottle = {
        id = "strawberry_syrup_bottle",
        displayName = "Strawberry Syrup Bottle",
        heldOffset = standardOffset,
        placementOffset = CFrame.new(),
        source = { kind = "ExistingModel", folderName = "StrawberrySyrupBottle" },
    },
    ice_scoop = {
        id = "ice_scoop",
        displayName = "Ice Scoop",
        heldOffset = standardOffset,
        placementOffset = CFrame.new(),
        source = { kind = "ExistingModel", folderName = "IceScoop" },
    },
    shaker_tin = {
        id = "shaker_tin",
        displayName = "Shaker Tin",
        heldOffset = standardOffset,
        placementOffset = CFrame.new(),
        source = { kind = "ExistingModel", folderName = "ShakerTin" },
    },
}

local Carryables = {}

function Carryables.get(id: Types.CarryItemId): Carryable
    return definitions[id]
end

return Carryables
