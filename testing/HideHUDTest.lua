-- ============================================================================
-- HIDE HUD TEST
-- Test all possible opcodes/methods to hide GTA SA HUD elements
-- This is a standalone test - does NOT modify RadialMenu.lua
-- ============================================================================

script_name("Hide HUD Test")
script_author("OnlyDexterZ")
script_version("1.0")

-- ============================================================================
-- STATE
-- ============================================================================
local hudHidden = false
local radarHidden = false

-- ============================================================================
-- MAIN
-- ============================================================================
function main()
    while not isSampAvailable() do wait(100) end
    
    sampAddChatMessage("{00FFFF}[HUD Test] {FFFFFF}Script loaded!", -1)
    sampAddChatMessage("{00FFFF}[HUD Test] {FFFFFF}Commands:", -1)
    sampAddChatMessage("{FFFF00}/hidehud {FFFFFF}- Hide all HUD", -1)
    sampAddChatMessage("{FFFF00}/showhud {FFFFFF}- Show all HUD", -1)
    sampAddChatMessage("{FFFF00}/hideradar {FFFFFF}- Hide radar/minimap only", -1)
    sampAddChatMessage("{FFFF00}/showradar {FFFFFF}- Show radar/minimap", -1)
    sampAddChatMessage("{FFFF00}/togglehud {FFFFFF}- Toggle HUD on/off", -1)
    sampAddChatMessage("{FFFF00}/hudstatus {FFFFFF}- Show current status", -1)
    
    -- ========================================================================
    -- COMMAND: Hide all HUD
    -- ========================================================================
    sampRegisterChatCommand("hidehud", function()
        local ok, err = pcall(function()
            displayHud(false)
        end)
        
        if ok then
            hudHidden = true
            sampAddChatMessage("{00FF00}[HUD Test] {FFFFFF}displayHud(false) - executed!", -1)
        else
            sampAddChatMessage("{FF0000}[HUD Test] {FFFFFF}displayHud(false) FAILED: " .. tostring(err), -1)
        end
    end)
    
    -- ========================================================================
    -- COMMAND: Show all HUD
    -- ========================================================================
    sampRegisterChatCommand("showhud", function()
        local ok, err = pcall(function()
            displayHud(true)
        end)
        
        if ok then
            hudHidden = false
            sampAddChatMessage("{00FF00}[HUD Test] {FFFFFF}displayHud(true) - executed!", -1)
        else
            sampAddChatMessage("{FF0000}[HUD Test] {FFFFFF}displayHud(true) FAILED: " .. tostring(err), -1)
        end
    end)
    
    -- ========================================================================
    -- COMMAND: Hide radar only
    -- ========================================================================
    sampRegisterChatCommand("hideradar", function()
        local ok, err = pcall(function()
            displayRadar(false)
        end)
        
        if ok then
            radarHidden = true
            sampAddChatMessage("{00FF00}[HUD Test] {FFFFFF}displayRadar(false) - executed!", -1)
        else
            sampAddChatMessage("{FF0000}[HUD Test] {FFFFFF}displayRadar(false) FAILED: " .. tostring(err), -1)
        end
    end)
    
    -- ========================================================================
    -- COMMAND: Show radar
    -- ========================================================================
    sampRegisterChatCommand("showradar", function()
        local ok, err = pcall(function()
            displayRadar(true)
        end)
        
        if ok then
            radarHidden = false
            sampAddChatMessage("{00FF00}[HUD Test] {FFFFFF}displayRadar(true) - executed!", -1)
        else
            sampAddChatMessage("{FF0000}[HUD Test] {FFFFFF}displayRadar(true) FAILED: " .. tostring(err), -1)
        end
    end)
    
    -- ========================================================================
    -- COMMAND: Toggle HUD
    -- ========================================================================
    sampRegisterChatCommand("togglehud", function()
        hudHidden = not hudHidden
        local ok, err = pcall(function()
            displayHud(not hudHidden)
        end)
        
        if ok then
            sampAddChatMessage("{00FF00}[HUD Test] {FFFFFF}HUD: " .. 
                (hudHidden and "{FF0000}HIDDEN" or "{00FF00}VISIBLE"), -1)
        else
            sampAddChatMessage("{FF0000}[HUD Test] {FFFFFF}Toggle FAILED: " .. tostring(err), -1)
        end
    end)
    
    -- ========================================================================
    -- COMMAND: Status
    -- ========================================================================
    sampRegisterChatCommand("hudstatus", function()
        sampAddChatMessage("{00FFFF}[HUD Status] {FFFFFF}--- Current State ---", -1)
        sampAddChatMessage("{FFFFFF}HUD hidden: " .. tostring(hudHidden), -1)
        sampAddChatMessage("{FFFFFF}Radar hidden: " .. tostring(radarHidden), -1)
        
        -- Test if functions exist
        sampAddChatMessage("{FFFFFF}displayHud exists: " .. tostring(type(displayHud) == "function"), -1)
        sampAddChatMessage("{FFFFFF}displayRadar exists: " .. tostring(type(displayRadar) == "function"), -1)
    end)
    
    wait(-1)
end
