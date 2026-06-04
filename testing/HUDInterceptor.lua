-- ============================================================================
-- HUD INTERCEPTOR
-- Logs all memory.write and key function calls from other scripts
-- Load this BEFORE hassleHUD to capture what addresses it uses
-- ============================================================================

script_name("HUD Interceptor")
script_author("OnlyDexterZ")
script_version("1.0")

local memory = require 'memory'
local logFile = nil
local logEntries = {}

-- ============================================================================
-- INTERCEPT memory.write
-- ============================================================================
local originalMemWrite = memory.write
local originalMemRead = memory.read

memory.write = function(addr, value, size, vp)
    local entry = string.format("[WRITE] 0x%X | value=%s | size=%d | vp=%s", 
        addr, tostring(value), size or 0, tostring(vp))
    
    table.insert(logEntries, entry)
    sampAddChatMessage("{FF8800}[Intercept] {FFFFFF}" .. entry, -1)
    
    return originalMemWrite(addr, value, size, vp)
end

memory.read = function(addr, size, vp)
    local result = originalMemRead(addr, size, vp)
    
    local entry = string.format("[READ] 0x%X | size=%d | result=%s", 
        addr, size or 0, tostring(result))
    
    table.insert(logEntries, entry)
    
    return result
end

-- ============================================================================
-- INTERCEPT displayHud / displayRadar
-- ============================================================================
local originalDisplayHud = displayHud
local originalDisplayRadar = displayRadar

if originalDisplayHud then
    displayHud = function(show)
        sampAddChatMessage("{FF00FF}[Intercept] {FFFFFF}displayHud(" .. tostring(show) .. ")", -1)
        table.insert(logEntries, "[FUNC] displayHud(" .. tostring(show) .. ")")
        return originalDisplayHud(show)
    end
end

if originalDisplayRadar then
    displayRadar = function(show)
        sampAddChatMessage("{FF00FF}[Intercept] {FFFFFF}displayRadar(" .. tostring(show) .. ")", -1)
        table.insert(logEntries, "[FUNC] displayRadar(" .. tostring(show) .. ")")
        return originalDisplayRadar(show)
    end
end

-- ============================================================================
-- INTERCEPT renderDrawFunctions (for custom HUD detection)
-- ============================================================================
local originalGetCharHealth = getCharHealth
local originalGetCharArmour = getCharArmour

if originalGetCharHealth then
    getCharHealth = function(ped)
        local result = originalGetCharHealth(ped)
        -- Only log first call to avoid spam
        if not logEntries._healthLogged then
            table.insert(logEntries, "[FUNC] getCharHealth() = " .. tostring(result))
            logEntries._healthLogged = true
        end
        return result
    end
end

if originalGetCharArmour then
    getCharArmour = function(ped)
        local result = originalGetCharArmour(ped)
        if not logEntries._armourLogged then
            table.insert(logEntries, "[FUNC] getCharArmour() = " .. tostring(result))
            logEntries._armourLogged = true
        end
        return result
    end
end

-- ============================================================================
-- MAIN
-- ============================================================================
function main()
    while not isSampAvailable() do wait(100) end
    
    sampAddChatMessage("{00FF00}[HUD Interceptor] {FFFFFF}Loaded! Monitoring memory.write calls...", -1)
    sampAddChatMessage("{00FF00}[HUD Interceptor] {FFFFFF}Use {FFFF00}/hudlog{FFFFFF} to dump all captured calls", -1)
    sampAddChatMessage("{00FF00}[HUD Interceptor] {FFFFFF}Use {FFFF00}/hudclear{FFFFFF} to clear log", -1)
    sampAddChatMessage("{00FF00}[HUD Interceptor] {FFFFFF}Use {FFFF00}/hudcount{FFFFFF} to see total entries", -1)
    
    -- Dump all logged entries to chat
    sampRegisterChatCommand("hudlog", function()
        if #logEntries == 0 then
            sampAddChatMessage("{FFFF00}[HUD Log] {FFFFFF}No entries captured yet!", -1)
            return
        end
        
        sampAddChatMessage("{FFFF00}[HUD Log] {FFFFFF}Dumping " .. #logEntries .. " entries:", -1)
        for i, entry in ipairs(logEntries) do
            if type(entry) == "string" then
                sampAddChatMessage("{AAAAAA}" .. i .. ": " .. entry, -1)
            end
        end
    end)
    
    -- Clear log
    sampRegisterChatCommand("hudclear", function()
        logEntries = {}
        sampAddChatMessage("{00FF00}[HUD Log] {FFFFFF}Log cleared!", -1)
    end)
    
    -- Count entries
    sampRegisterChatCommand("hudcount", function()
        local count = 0
        for _, v in ipairs(logEntries) do
            if type(v) == "string" then count = count + 1 end
        end
        sampAddChatMessage("{00FFFF}[HUD Log] {FFFFFF}Total entries: " .. count, -1)
    end)
    
    -- Save log to file
    sampRegisterChatCommand("hudsave", function()
        local f = io.open(getWorkingDirectory() .. "/HUD_Interceptor_Log.txt", "w")
        if f then
            f:write("=== HUD Interceptor Log ===\n")
            f:write("Date: " .. os.date() .. "\n\n")
            for i, entry in ipairs(logEntries) do
                if type(entry) == "string" then
                    f:write(i .. ": " .. entry .. "\n")
                end
            end
            f:close()
            sampAddChatMessage("{00FF00}[HUD Log] {FFFFFF}Saved to HUD_Interceptor_Log.txt!", -1)
        else
            sampAddChatMessage("{FF0000}[HUD Log] {FFFFFF}Failed to save!", -1)
        end
    end)
    
    wait(-1)
end
