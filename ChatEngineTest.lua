-- ============================================================================
-- CHAT ENGINE TEST v1.0
-- Test script for verifying chat hooks and 3D text rendering
-- Compatible with MonetLoader Android
-- ============================================================================

script_name("ChatEngineTest")
script_author("OnlyDexterZ")

-- ============================================================================
-- SAFE LIBRARY LOADING
-- ============================================================================
local imgui = require 'mimgui'

local sampev_loaded, sampev = pcall(require, "samp.events")
if not sampev_loaded then
    print("[ChatEngineTest] ERROR: samp.events not found!")
end

-- ============================================================================
-- DPI SCALE (MonetLoader Android)
-- ============================================================================
local DPI_SCALE = MONET_DPI_SCALE or 1.0

-- ============================================================================
-- STATE VARIABLES
-- ============================================================================
local chatInterceptEnabled = true   -- default ON
local render3DEnabled = false       -- default OFF

-- ============================================================================
-- SAMP EVENTS HOOK: onServerMessage
-- Intercept server messages, block from default chat, re-display with [CE] prefix
-- ============================================================================
if sampev_loaded then
    function sampev.onServerMessage(color, text)
        if chatInterceptEnabled then
            -- Re-display with [CE] prefix so user can verify the hook is working
            sampAddChatMessage("{00FFFF}[CE] {FFFFFF}" .. tostring(text), color)
            -- Block from default SA-MP chat
            return false
        end
    end
end

-- ============================================================================
-- 3D TEXT RENDERING via mimgui DrawList
-- Renders "[TEST 3D]" at nearby player positions using convert3DCoordsToScreen
-- ============================================================================
imgui.OnFrame(function()
    return render3DEnabled and sampIsLocalPlayerSpawned()
end, function()
    local draw_list = imgui.GetBackgroundDrawList()

    -- Iterate through connected players and render 3D text above nearby ones
    local myX, myY, myZ
    pcall(function()
        myX, myY, myZ = getCharCoordinates(PLAYER_PED)
    end)

    if not myX then return end

    local maxDistance = 50.0 -- only render for players within 50 units

    for playerId = 0, 999 do
        local success, result = pcall(function()
            if sampIsPlayerConnected(playerId) then
                local exists, charHandle = sampGetCharHandleBySampPlayerId(playerId)
                if exists and charHandle then
                    local px, py, pz = getCharCoordinates(charHandle)
                    if px then
                        -- Calculate distance
                        local dx = px - myX
                        local dy = py - myY
                        local dz = pz - myZ
                        local dist = math.sqrt(dx * dx + dy * dy + dz * dz)

                        if dist <= maxDistance and dist > 0 then
                            -- Convert 3D world position to screen coordinates
                            local screenX, screenY, onScreen = convert3DCoordsToScreen(px, py, pz + 1.0)
                            if onScreen then
                                local text = "[TEST 3D] ID:" .. playerId
                                local textSize = imgui.CalcTextSize(text)
                                -- Draw text centered at screen position
                                draw_list:AddText(
                                    imgui.ImVec2(screenX - textSize.x / 2, screenY - textSize.y / 2),
                                    imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.0, 1.0, 0.5, 1.0)),
                                    text
                                )
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- ============================================================================
-- MAIN FUNCTION
-- ============================================================================
function main()
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("{00FFFF}[ChatEngineTest] {FFFFFF}Loaded! Chat intercept: {00FF00}ON", -1)
    sampAddChatMessage("{00FFFF}[ChatEngineTest] {FFFFFF}Commands: {FFFF00}/cetest {FFFFFF}(toggle chat) | {FFFF00}/cetest3d {FFFFFF}(toggle 3D)", -1)

    -- Register /cetest command: toggle chat intercept on/off
    sampRegisterChatCommand("cetest", function()
        chatInterceptEnabled = not chatInterceptEnabled
        if chatInterceptEnabled then
            sampAddChatMessage("{00FFFF}[ChatEngineTest] {FFFFFF}Chat intercept: {00FF00}ON", -1)
        else
            sampAddChatMessage("{00FFFF}[ChatEngineTest] {FFFFFF}Chat intercept: {FF0000}OFF", -1)
        end
    end)

    -- Register /cetest3d command: toggle 3D text rendering on/off
    sampRegisterChatCommand("cetest3d", function()
        render3DEnabled = not render3DEnabled
        if render3DEnabled then
            sampAddChatMessage("{00FFFF}[ChatEngineTest] {FFFFFF}3D text render: {00FF00}ON", -1)
        else
            sampAddChatMessage("{00FFFF}[ChatEngineTest] {FFFFFF}3D text render: {FF0000}OFF", -1)
        end
    end)

    -- Keep script alive
    while true do wait(100) end
end
