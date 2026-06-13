script_name("Alyn SA:MP Fixes")
script_author("Tasu K.")
script_version("0.1.0")
script_description("Various fixes on alyn SA:MP client")

-- loader
local ev = require "samp.events"
local ini = require "inicfg"

-- variable
local logFile = default
local config = ini.load({
    settings = {
        fix_maphack = true,
        fix_chatlog = true,
        fix_text = true
    },
    path = {
        chatlog = "logs/ingame.log"
    }}, "alynfix.ini"
)

-- log functions
function initLog(path)
    local f = io.open(path, "w")
    
    -- check if we got perms
    if f == nil then
        print("[ERROR]: can't start log file (PERMISSION_DENIED)")
        return nil
    end
    
    -- write intializer
    f:write(os.date("[%H:%M:%S]: Alyn SA:MP Mobile Started\n"))
    
    -- sync and close
    f:flush()
    f:close()
    
    -- open new instance (append)
    return io.open(path, "a")
end

function logWrite(text)
    if not config.settings.fix_chatlog then return false end
    if not logFile then return false end
    
    logFile:write(os.date("[%H:%M:%S]: "..text.."\n"))
    logFile:flush()
    return true
end

-- main entry
function main()
    if not isSampLoaded() then return end
    
    -- initialize logger
    logFile = initLog(config.path.chatlog)
   
    -- wait until loaded
    while not isSampAvailable() do wait(100) end

    -- fetch local ip
    local ip, port = sampGetCurrentServerAddress()
    logWrite("Connecting to "..ip..":"..port)
end

-- fetching events
function ev.onConnectionRequestAccepted(ip, port, playerId, challenge)
    logWrite("Connected. Joining the game")
end

function ev.onInitGame(playerId, hostName, settings, vehicleModels, unknown)

    if config.settings.fix_maphack then
        settings.showPlayerTags = false
        settings.playerMarkersMode = 0
    end
    
    logWrite("Connected to "..hostName)
    return { playerId, hostName, settings, vehicleModels }
end

function ev.onChatMessage(playerId, text)
    logWrite(string.format("%s%s", sampGetPlayerNickname(playerId), text))
    
    if config.settings.fix_chat then
        return { playerId, "{FFFFFF}"..text }
    end
    
    return { playerId, text }
end

function ev.onServerMessage(color, text)
    logWrite(text)
    return { color, text }
end

-- close file on quit
function onScriptTerminate(s, quitGame)
    if logWrite then
       logWrite.close()
    end
end
