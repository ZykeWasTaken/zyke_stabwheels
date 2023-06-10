z = exports["zyke_lib"]:Fetch()

-- This is just to fetch the zyke_gangs functionalities, will only fetch if you have this setting enabled
if (Config.Settings.zykeGangs.enabled) then
    GangFuncs = exports["zyke_gangs"]:Fetch()
end

local closeVehicles = {}
local closestVehicle = nil
local closestWheel = nil
local timers = {} -- Hoisting

local bones = {"wheel_lf", "wheel_rf", "wheel_lm1", "wheel_rm1", "wheel_lr", "wheel_rr"}
local indexes = {["wheel_lf"] = 0, ["wheel_rf"] = 1, ["wheel_lm1"] = 2, ["wheel_rm1"] = 3, ["wheel_lr"] = 4, ["wheel_rr"] = 5, ["wheel_lm2"] = 45, ["wheel_lm3"] = 46, ["wheel_rm2"] = 47, ["wheel_rm3"] = 48}

local function IsVehicleBlacklisted(vehicle)
    local model = GetEntityModel(vehicle)
    local isBlacklisted = false

    for _, vehicle in pairs(Config.Settings.disabledVehicles) do
        if (joaat(vehicle) == model) then
            isBlacklisted = true
        end
    end

    return isBlacklisted
end

local function GetClosestWheelFromVehicle()
    local ply = PlayerPedId()
    local plyPos = GetEntityCoords(ply)
    local closestWheel = nil
    local minDst = 1

    for _, bone in pairs(bones) do
        local bonePos = GetWorldPositionOfEntityBone(closestVehicle.vehicle, GetEntityBoneIndexByName(closestVehicle.vehicle, bone))
        local dst = #(plyPos - bonePos)
        local bursted = IsVehicleTyreBurst(closestVehicle.vehicle, indexes[bone], false)

        if ((dst < minDst) and (dst < (closestWheel?.dst or 999))) then
            closestWheel = {
                bone = bone, -- Name of the bone
                dst = dst, -- Distance from the player to the wheel
                index = indexes[bone], -- Index of the wheel
                pos = bonePos, -- Position of the wheel
                bursted = bursted, -- Is the wheel already bursted?
            }
        end
    end

    return closestWheel
end

local isHoldingSlashWeapon = false
local minDst = 1
local meetsRequirements = false
local function MeetsRequirements()
    local zykeGangSettings = Config.Settings.zykeGangs
    local ply = PlayerPedId()
    local plyPos = GetEntityCoords(ply)

    if (closestVehicle?.isBlacklisted) then return false end -- Make sure the vehicle is not blacklisted
    if (not isHoldingSlashWeapon) then return false end -- Is player holding the correct weapon?
    if (closestWheel?.bursted) then return false end -- Is the wheel already bursted?
    if ((closestWheel?.dst or minDst + 10) > minDst) then return false end -- Make sure the player is close enough to the wheel
    if (GetVehiclePedIsIn(ply, false) ~= 0) then return false end -- Make sure the player is not in a vehicle

    local vehicleSpeed = GetEntitySpeed(closestVehicle?.vehicle) or 0
    if (vehicleSpeed > 0.5) then return false end -- Make sure the vehicle is not moving

    -- NOTE! That you can not use zyke_gangs functionalities if you do not have the script installed
    if (zykeGangSettings.enabled == true) then -- Make sure you want to use zyke_gangs functionalities
        if (zykeGangSettings.hasToBeInGang) then
            local playerGang = GangFuncs.GetPlayerGang()

            if (not playerGang) then return false end -- Make sure the player is in a gang
        end

        if (zykeGangSettings.hasToBeInGrid) then
            local grid = GangFuncs.GetGridData(plyPos)

            if (grid.id == "empty") then return false end -- Make sure the player is in a marked grid
        end
    end

    return true
end

-- Triggers after a wheel has been stabbed, hence why we check if more than 1 wheel is bursted
local function AreAllWheelsIntact()
    local bursted = 0

    for _, bone in pairs(bones) do
        local isBursted = IsVehicleTyreBurst(closestVehicle.vehicle, indexes[bone], false)

        if (isBursted) then
            bursted += 1
        end
    end

    return bursted < 2
end

-- Simple function to check if the player is holding a weapon that can be used to stab wheels
local function IsHoldingSlashWeapon()
    local ply = PlayerPedId()
    local plyWeapon = GetSelectedPedWeapon(ply)

    for weapon, state in pairs(Config.Settings.weapons) do
        if (joaat(weapon) == plyWeapon) then
            return state
        end
    end

    return false
end

-- Function to gather all nearby vehicles and put them into a table that will then be iterated much quicker, instead of iterating through the entire game pool
-- Simply to improve performance
local function FetchCloseVehicles()
    local plyPos = GetEntityCoords(PlayerPedId())
    local _closeVehicles = {}

    local pool = GetGamePool("CVehicle")
    for _, vehicle in pairs(pool) do
        local dst = #(plyPos - GetEntityCoords(vehicle))

        if (dst < 100) then
            table.insert(_closeVehicles, vehicle)
        end
    end

    return _closeVehicles
end

-- Function to fetch the closest vehicle from the closeVehicles table
local function FetchClosestVehicle()
    local plyPos = GetEntityCoords(PlayerPedId())
    local _closestVehicle = nil
    local minDst = 3

    for _, vehicle in pairs(closeVehicles) do
        local dst = #(plyPos - GetEntityCoords(vehicle))

        if ((dst < minDst) and (dst < (_closestVehicle?.dst or 999))) then
            _closestVehicle = {
                vehicle = vehicle,
                dst = dst,
                isBlacklisted = IsVehicleBlacklisted(vehicle),
            }
        end
    end

    return _closestVehicle
end

-- Function to handle loyalty removal, this will only be triggered if you have zyke_gangs enabled
local function HandleLoyaltyRemoval()
    if (Config.Settings.zykeGangs.enabled == false) then return end -- Make sure you have zyke_gangs enabled

    local ply = PlayerPedId()
    local plyPos = GetEntityCoords(ply)

    if (not AreAllWheelsIntact()) then return end -- Make sure all wheels are intact, meaning you can only vandalize cars in "perfect" condition

    z.Notify(Config.Strings.vandalizedCar.msg, Config.Strings.vandalizedCar.type)
    TriggerServerEvent("zyke_gangs:HandleWheelStab", GetToken(), plyPos) -- This is just for loyalty removal, which is handled inside of zyke_gangs
end

-- Handle the stabbing of the wheel and the animation
local function StabWheel()
    if (closestVehicle?.vehicle == nil) then return end
    if (not MeetsRequirements()) then return end

    local ply = PlayerPedId()

    z.PlayAnim(ply, "melee@knife@streamed_core_fps", "ground_attack_on_spot", 8.0, -9.0, 1.8, 15, 1.0, 0, 0, 0)
    Wait(550)

    closestWheel.bursted = true
    z.Notify(Config.Strings.wheelBursted.msg, Config.Strings.wheelBursted.type)
    SetVehicleTyreBurst(closestVehicle.vehicle, closestWheel.index, false, 100.0)

    Wait(750)
    ClearPedTasks(ply)

    HandleLoyaltyRemoval()
end

timers = {
    ["isHoldingSlashWeapon"] = {
        delay = 100,
        func = function()
            isHoldingSlashWeapon = IsHoldingSlashWeapon()
        end
    },
    ["fetchCloseVehiclesTimer"] = {
        delay = 2500,
        func = function()
            closeVehicles = FetchCloseVehicles()
        end
    },
    ["fetchClosestVehicleTimer"] = {
        delay = 500,
        func = function()
            closestVehicle = FetchClosestVehicle()
        end
    },
    ["fetchClosestWheelTimer"] = {
        delay = 250,
        func = function()
            if (closestVehicle) then
                closestWheel = GetClosestWheelFromVehicle()
            end
        end
    },
    ["meetsRequirements"] = {
        delay = 100,
        func = function()
            meetsRequirements = MeetsRequirements()
        end
    },
}

-- Handles all of the requirements, caching etc, used to improve performance and reduce the amount of copy paste code
local function HandleTimers()
    for _, timer in pairs(timers) do
        if ((timer.timer or 0) < GetGameTimer()) then
            timer.timer = GetGameTimer() + timer.delay

            if (timer.func) then
                timer.func()
            end
        end
    end
end

CreateThread(function()
    while true do
        local sleep = 250

        HandleTimers()

        if (meetsRequirements) then
            sleep = 3

            if (closestWheel) then
                z.Draw3DText(closestWheel.pos, Config.Strings.stabWheel, 0.3)

                if (IsControlJustReleased(0, 38)) then
                    StabWheel()
                end
            end
        end

        Wait(sleep)
    end
end)

-- Don't touch, this is used to fetch a valid token to authorize requests sent to zyke_gangs' server side
if (Config.Settings.zykeGangs.enabled) then
    function GetToken()
        local p = promise.new()
        z.Callback("zyke_gangs:GetToken", function(res)
            p:resolve(res)
        end)

        return Citizen.Await(p)
    end
end