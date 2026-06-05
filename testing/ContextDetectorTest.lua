-- ============================================================================
-- CONTEXT DETECTOR TEST
-- Test script to verify SAMemory can detect player state on MonetLoader 2.00
-- This is a standalone test - does NOT modify RadialMenu.lua
-- ============================================================================

script_name("Context Detector Test")
script_author("OnlyDexterZ")
script_version("1.0")

-- ============================================================================
-- SAFE LOADING - Try to load SAMemory, fallback if not available
-- ============================================================================
local SAMemory_loaded = false
local SAMemory = nil
local ffi = require 'ffi'

local function trySAMemory()
    local ok, lib = pcall(require, 'SAMemory')
    if ok then
        SAMemory = lib
        SAMemory_loaded = true
        return true
    end
    return false
end

-- ============================================================================
-- CONTEXT STATES
-- ============================================================================
local CONTEXT = {
    UNKNOWN    = "UNKNOWN",
    ON_FOOT    = "ON_FOOT",
    IN_VEHICLE = "IN_VEHICLE",
    DEAD       = "DEAD",
}

local currentContext = CONTEXT.UNKNOWN
local previousContext = CONTEXT.UNKNOWN
local contextChangeCount = 0

-- ============================================================================
-- DETECTION METHODS
-- ============================================================================

-- Method 1: SAMemory (direct memory read)
local function detectViaSAMemory()
    if not SAMemory_loaded then return nil end
    
    local ok, result = pcall(function()
        local ped = SAMemory.player_ped[0]
        local vehicle = SAMemory.player_vehicle[0]
        
        -- Check dead
        if ped ~= SAMemory.nullptr then
            local health = ped.fHealth
            if health <= 0 then
                return CONTEXT.DEAD
            end
        end
        
        -- Check in vehicle
        if vehicle ~= SAMemory.nullptr then
            return CONTEXT.IN_VEHICLE
        end
        
        return CONTEXT.ON_FOOT
    end)
    
    if ok then return result end
    return nil
end

-- Method 2: Opcodes (traditional moonloader approach)
local function detectViaOpcodes()
    local ok, result = pcall(function()
        -- Check if player is in any vehicle
        if isCharInAnyCar(PLAYER_PED) then
            return CONTEXT.IN_VEHICLE
        end
        
        -- Check health
        local health = getCharHealth(PLAYER_PED)
        if health <= 0 then
            return CONTEXT.DEAD
        end
        
        return CONTEXT.ON_FOOT
    end)
    
    if ok then return result end
    return nil
end

-- Method 3: SAMP functions
local function detectViaSAMP()
    local ok, result = pcall(function()
        if not sampIsLocalPlayerSpawned() then
            return CONTEXT.DEAD
        end
        
        -- Try isCharInAnyCar
        if isCharInAnyCar(PLAYER_PED) then
            return CONTEXT.IN_VEHICLE
        end
        
        return CONTEXT.ON_FOOT
    end)
    
    if ok then return result end
    return nil
end

-- ============================================================================
-- MAIN DETECTION FUNCTION
-- Tries multiple methods, uses first that works
-- ============================================================================
local activeMethod = "none"

local function detectContext()
    -- Try Method 1: SAMemory
    local result = detectViaSAMemory()
    if result then
        activeMethod = "SAMemory"
        return result
    end
    
    -- Try Method 2: Opcodes
    result = detectViaOpcodes()
    if result then
        activeMethod = "Opcodes"
        return result
    end
    
    -- Try Method 3: SAMP
    result = detectViaSAMP()
    if result then
        activeMethod = "SAMP"
        return result
    end
    
    activeMethod = "none"
    return CONTEXT.UNKNOWN
end

-- ============================================================================
-- MAIN
-- ============================================================================
function main()
    while not isSampAvailable() do wait(100) end
    
    -- Try loading SAMemory
    trySAMemory()
    
    sampAddChatMessage("{00FFFF}[Context Test] {FFFFFF}Script loaded!", -1)
    sampAddChatMessage("{00FFFF}[Context Test] {FFFFFF}SAMemory: " .. 
        (SAMemory_loaded and "{00FF00}LOADED" or "{FF0000}NOT AVAILABLE"), -1)
    sampAddChatMessage("{00FFFF}[Context Test] {FFFFFF}Commands: {FFFF00}/ctx {FFFFFF}| {FFFF00}/ctxinfo {FFFFFF}| {FFFF00}/ctxstop", -1)
    
    -- Detection active flag
    local detecting = true
    
    -- Command: show current context
    sampRegisterChatCommand("ctx", function()
        local ctx = detectContext()
        sampAddChatMessage(string.format(
            "{00FFFF}[Context] {FFFFFF}State: {FFFF00}%s {FFFFFF}| Method: {00FF00}%s {FFFFFF}| Changes: %d",
            ctx, activeMethod, contextChangeCount
        ), -1)
    end)
    
    -- Command: show detailed info
    sampRegisterChatCommand("ctxinfo", function()
        sampAddChatMessage("{00FFFF}[Context Info] {FFFFFF}--- Detection Status ---", -1)
        sampAddChatMessage("{FFFFFF}SAMemory loaded: " .. tostring(SAMemory_loaded), -1)
        sampAddChatMessage("{FFFFFF}Active method: " .. activeMethod, -1)
        sampAddChatMessage("{FFFFFF}Current context: " .. currentContext, -1)
        sampAddChatMessage("{FFFFFF}Previous context: " .. previousContext, -1)
        sampAddChatMessage("{FFFFFF}Total changes: " .. contextChangeCount, -1)
        
        -- Try reading specific values
        if SAMemory_loaded then
            local ok, info = pcall(function()
                local ped = SAMemory.player_ped[0]
                local vehicle = SAMemory.player_vehicle[0]
                sampAddChatMessage("{FFFFFF}Ped ptr: " .. tostring(ped), -1)
                sampAddChatMessage("{FFFFFF}Vehicle ptr: " .. tostring(vehicle), -1)
                if ped ~= SAMemory.nullptr then
                    sampAddChatMessage("{FFFFFF}Health: " .. tostring(ped.fHealth), -1)
                end
            end)
            if not ok then
                sampAddChatMessage("{FF0000}SAMemory read error: " .. tostring(info), -1)
            end
        end
        
        -- Try opcode method
        local ok2, info2 = pcall(function()
            local hp = getCharHealth(PLAYER_PED)
            local inCar = isCharInAnyCar(PLAYER_PED)
            sampAddChatMessage("{FFFFFF}[Opcode] HP: " .. tostring(hp), -1)
            sampAddChatMessage("{FFFFFF}[Opcode] InCar: " .. tostring(inCar), -1)
        end)
        if not ok2 then
            sampAddChatMessage("{FF0000}Opcode error: " .. tostring(info2), -1)
        end
    end)
    
    -- Command: toggle detection
    sampRegisterChatCommand("ctxstop", function()
        detecting = not detecting
        sampAddChatMessage("{00FFFF}[Context] {FFFFFF}Detection: " .. 
            (detecting and "{00FF00}ON" or "{FF0000}OFF"), -1)
    end)
    
    -- Main detection loop
    while true do
        wait(500)  -- Check every 500ms (not too frequent)
        
        if detecting and sampIsLocalPlayerSpawned() then
            previousContext = currentContext
            currentContext = detectContext()
            
            -- Announce context change
            if currentContext ~= previousContext and previousContext ~= CONTEXT.UNKNOWN then
                contextChangeCount = contextChangeCount + 1
                
                local color = "{FFFFFF}"
                if currentContext == CONTEXT.ON_FOOT then color = "{00FF00}" end
                if currentContext == CONTEXT.IN_VEHICLE then color = "{00FFFF}" end
                if currentContext == CONTEXT.DEAD then color = "{FF0000}" end
                
                sampAddChatMessage(string.format(
                    "{FFFF00}[Context Changed] %s%s {FFFFFF}(method: %s)",
                    color, currentContext, activeMethod
                ), -1)
            end
        end
    end
end
