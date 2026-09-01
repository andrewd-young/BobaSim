--!strict

local Types = require("./Types")
local Machines = require("./Machines")

export type StepCarryRule = {
    step: Types.StationStep,
    requiredCarryItemId: Types.CarryItemId?,
    producedCarryItemId: Types.CarryItemId?,
    stepBehavior: Types.StepBehavior,
    promptHint: string,
    checklistLabel: string,
}

local PhysicalInteractions = {}

function PhysicalInteractions.getRule(step: Types.StationStep): StepCarryRule
    for _, machine in Machines do
        if machine.stationStep == step then
            return {
                step = step,
                requiredCarryItemId = machine.requiredCarryItemId,
                producedCarryItemId = machine.producedCarryItemId,
                stepBehavior = machine.stepBehavior,
                promptHint = machine.promptHint,
                checklistLabel = machine.checklistLabel,
            }
        end
    end
    error(`missing machine config for {step}`)
end

function PhysicalInteractions.tryGetRule(step: Types.StationStep): StepCarryRule?
    for _, machine in Machines do
        if machine.stationStep == step then
            return PhysicalInteractions.getRule(step)
        end
    end
    return nil
end

function PhysicalInteractions.canUseStep(
    step: Types.StationStep,
    heldItemId: Types.CarryItemId?
): (boolean, string?)
    local rule = PhysicalInteractions.tryGetRule(step)
    if rule == nil then
        return false, "pick a valid station"
    end

    local requiredCarryItemId = rule.requiredCarryItemId
    if requiredCarryItemId == nil or heldItemId == requiredCarryItemId then
        return true, nil
    end

    return false, `pick up {string.gsub(requiredCarryItemId, "_", " ")} first`
end

return PhysicalInteractions
