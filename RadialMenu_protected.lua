-- Protected by OnlyDexterZ v1.0
-- Do not modify or redistribute

script_name("Radial Menu")
script_author("OnlyDexterZ")

local imgui = require 'mimgui'
local inicfg = require 'inicfg'

local _114a7f = false
local ease = nil
pcall(function()
    ease = require 'ease'
    _114a7f = true
end)

local _47af6e = false
local _6b11d3 = nil
pcall(function()
    _6b11d3 = require 'fAwesome6'
    _47af6e = true
end)

local _b485bf = false
local _b15d1c = nil
pcall(function()
    require 'notifications'
    _b15d1c = _G._b15d1c
    _b485bf = true
end)

local _0a998a = "RadialMenuConfig.ini"
local _687f44 = "RadialMenuProfiles.ini"

local _cf8b8c = inicfg.load({
    Settings = {
        _bfba46 = "default",
        _0cf751 = true,
    },
    ServerMapping = {},
}, _687f44)

if not _cf8b8c then

    inicfg.save({
        Settings = { _bfba46 = "default", _0cf751 = true },
        ServerMapping = {},
    }, _687f44)
    _cf8b8c = { Settings = { _bfba46 = "default", _0cf751 = true }, ServerMapping = {} }
end

local _bfba46 = _cf8b8c.Settings._bfba46 or "default"
local _0cf751 = _cf8b8c.Settings._0cf751 or true

local _55941f = {
    ButtonSettings = { posX = 1100.0, posY = 140.0 },
    HamburgerButton = { enabled = true, posX = 50.0, posY = 300.0, size = 80.0, alpha = 0.8 },
    CtxVeh1 = { _06b88e = "ENGINE", onCmd = "/engine", offCmd = "/engine" },
    CtxVeh2 = { _06b88e = "LOCK", onCmd = "/lock", offCmd = "/unlock" },
    CtxVeh3 = { _06b88e = "LIGHT", onCmd = "/lights", offCmd = "/lights" },
    CtxVeh4 = { _06b88e = "-", onCmd = "", offCmd = "" },
    CtxVeh5 = { _06b88e = "-", onCmd = "", offCmd = "" },
    CtxVeh6 = { _06b88e = "-", onCmd = "", offCmd = "" },
    CtxVeh7 = { _06b88e = "-", onCmd = "", offCmd = "" },
    CtxVeh8 = { _06b88e = "-", onCmd = "", offCmd = "" },
    CtxVeh9 = { _06b88e = "-", onCmd = "", offCmd = "" },
    CtxVeh10 = { _06b88e = "-", onCmd = "", offCmd = "" },
    CtxFoot1 = { _06b88e = "LOCK", onCmd = "/lock", offCmd = "/unlock" },
    CtxFoot2 = { _06b88e = "TRUNK", onCmd = "/trunk", offCmd = "/trunk" },
    CtxFoot3 = { _06b88e = "HOOD", onCmd = "/hood", offCmd = "/hood" },
    CtxFoot4 = { _06b88e = "-", onCmd = "", offCmd = "" },
    CtxFoot5 = { _06b88e = "-", onCmd = "", offCmd = "" },
    CtxFoot6 = { _06b88e = "-", onCmd = "", offCmd = "" },
    CtxFoot7 = { _06b88e = "-", onCmd = "", offCmd = "" },
    CtxFoot8 = { _06b88e = "-", onCmd = "", offCmd = "" },
    CtxFoot9 = { _06b88e = "-", onCmd = "", offCmd = "" },
    CtxFoot10 = { _06b88e = "-", onCmd = "", offCmd = "" },
    Sector1 = { _06b88e = "VEHICLE", cmd = "" },
    Sector2 = { _06b88e = "MAP",     cmd = "" },
    Sector3 = { _06b88e = "ANIM",    cmd = "" },
    Sector4 = { _06b88e = "-",       cmd = "" },
    CatSector1 = { _06b88e = "" }, CatSector2 = { _06b88e = "" },
    CatSector3 = { _06b88e = "" }, CatSector4 = { _06b88e = "" },
    VehCatSector1 = { _06b88e = "" }, VehCatSector2 = { _06b88e = "" },
    VehCatSector3 = { _06b88e = "" }, VehCatSector4 = { _06b88e = "" },
}
for i = 1, 21 do
    _55941f["Anim"..i] = { _ef82b4 = "", cmd = "", category = "" }
    _55941f["Veh"..i]  = { _ef82b4 = "", cmd = "", category = "" }
end

local _a63521 = inicfg.load(_55941f, _0a998a)
if not _a63521 then
    inicfg.save(_55941f, _0a998a)
    _a63521 = _55941f
end
for k, v in pairs(_55941f) do
    if not _a63521[k] then _a63521[k] = v end
end

local _dc3998   = imgui.new.bool(false)
local _33efa4 = imgui.new.bool(false)
local _8b5290    = imgui.new.bool(false)
local _f34dd4   = imgui.new.bool(false)
local _8452e2 = imgui.new.bool(false)
local _3dc961    = imgui.new.bool(false)
local _5844eb = imgui.new.bool(false)
local _076de0 = imgui.new.bool(false)

local _92bdec = 0
local _368e88 = 0.2  -- 200ms cooldown between clicks

local _f6e0cb = 0
local _b578d6 = 0
local _bdebd2 = nil  -- track which menu is open for animation

local _f6bbec = 1

local _557666 = imgui.new.char[32](_bfba46)
local _4e61ac = imgui.new.bool(_0cf751)
local _01856b = {}
local _eb57c8 = ""
local _c1857a = ""

local _0cf716 = imgui.new.bool(false)
local _6a596b = { ip = "", _06b88e = "", suggestedProfileName = "" }
local _2c14a3 = imgui.new.char[64]("")

local _a458f3    = ""
local _841d29     = 1
local _6ee295     = {}
local _d9a966 = ""
local _61f402      = 1
local _e54e32      = {}

local _f89f49 = {}

local _aad948 = { _06b88e = "", onCmd = "", offCmd = "" }

local _688bb1 = {}

local _50a4e9 = imgui.new.float(_a63521.ButtonSettings.posX or 1100.0)
local _b60fb8 = imgui.new.float(_a63521.ButtonSettings.posY or 140.0)

local _c9cba7 = imgui.new.bool(_a63521.HamburgerButton and _a63521.HamburgerButton.enabled or true)
local _0bb570 = imgui.new.float(_a63521.HamburgerButton and _a63521.HamburgerButton.posX or 50.0)
local _1a36f1 = imgui.new.float(_a63521.HamburgerButton and _a63521.HamburgerButton.posY or 300.0)

local _1fd47c = imgui.new.float(_a63521.HamburgerButton and _a63521.HamburgerButton.size or 80.0)
local _39c580 = imgui.new.float(_a63521.HamburgerButton and _a63521.HamburgerButton.alpha or 0.8)
local _c1d95b = 0

local _9f29ad = {}
local _c21ff1 = {}
local _3b9ab8 = {}
local _2d4646 = {}
for i = 1, 4 do
    _9f29ad[i] = imgui.new.char[32](_a63521["Sector"..i]._06b88e or "")
    _c21ff1[i] = imgui.new.char[64](_a63521["Sector"..i].cmd or "")
    _3b9ab8[i] = imgui.new.char[32](_a63521["CatSector"..i]._06b88e or "")
    _2d4646[i] = imgui.new.char[32](_a63521["VehCatSector"..i]._06b88e or "")
end

local _a166b4 = 21
local animEditLabel, animEditCmd, animEditCategory = {}, {}, {}
for i = 1, _a166b4 do
    local s = _a63521["Anim"..i] or { _ef82b4="", cmd="", category="" }
    animEditLabel[i]    = imgui.new.char[64](s._ef82b4    or "")
    animEditCmd[i]      = imgui.new.char[128](s.cmd     or "")
    animEditCategory[i] = imgui.new.char[32](s.category or "")
end

local _cad91d = 21
local vehEditLabel, vehEditCmd, vehEditCategory = {}, {}, {}
for i = 1, _cad91d do
    local s = _a63521["Veh"..i] or { _ef82b4="", cmd="", category="" }
    vehEditLabel[i]    = imgui.new.char[64](s._ef82b4    or "")
    vehEditCmd[i]      = imgui.new.char[128](s.cmd     or "")
    vehEditCategory[i] = imgui.new.char[32](s.category or "")
end

local ctxVehName, ctxVehOn, ctxVehOff = {}, {}, {}
for i = 1, 10 do
    local s = _a63521["CtxVeh"..i] or { _06b88e = "", onCmd = "", offCmd = "" }
    ctxVehName[i] = imgui.new.char[32](s._06b88e or "")
    ctxVehOn[i] = imgui.new.char[64](s.onCmd or "")
    ctxVehOff[i] = imgui.new.char[64](s.offCmd or "")
end

local ctxFootName, ctxFootOn, ctxFootOff = {}, {}, {}
for i = 1, 10 do
    local s = _a63521["CtxFoot"..i] or { _06b88e = "", onCmd = "", offCmd = "" }
    ctxFootName[i] = imgui.new.char[32](s._06b88e or "")
    ctxFootOn[i] = imgui.new.char[64](s.onCmd or "")
    ctxFootOff[i] = imgui.new.char[64](s.offCmd or "")
end

local function getEase(easeFunc, x)
    if _114a7f and ease and ease[easeFunc] then
        return ease[easeFunc](x)
    end
    return x  -- Fallback: linear
end

local function clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

function readCharBuffer(buf, maxSize)
    local r = {}
    for i = 0, maxSize-1 do
        local c = buf[i]
        if not c or c == 0 then break end
        r[#r+1] = string.char(c)
    end
    return table.concat(r)
end

function closeAllRadial()
    _dc3998[0]   = false
    _8b5290[0]    = false
    _f34dd4[0]   = false
    _8452e2[0] = false
    _3dc961[0]    = false
    _5844eb[0] = false
    _076de0[0] = false
    _f6e0cb = os.clock()
end

function executeCommand(cmd)
    if cmd and cmd ~= "" and type(cmd) == "string" then 
        sampProcessChatInput(cmd)
        return true
    end
    return false
end

function getProfileFileName(_ad30f4)
    return "RadialMenu_" .. _ad30f4:gsub("[^%w_-]", "_") .. ".ini"
end

function sanitizeProfileName(serverName)
    local _06b88e = serverName
    _06b88e = _06b88e:gsub("[^%w%s_-]", "")
    _06b88e = _06b88e:gsub("%s+", "_")
    _06b88e = _06b88e:gsub("^_+", ""):gsub("_+$", "")

    local _5e9fa4 = {}
    for word in _06b88e:gmatch("[^_%s]+") do
        table.insert(_5e9fa4, word)
        if #_5e9fa4 >= 2 then break end
    end
    if #_5e9fa4 > 0 then _06b88e = table.concat(_5e9fa4, "_") end
    if #_06b88e > 32 then _06b88e = _06b88e:sub(1, 32) end
    if _06b88e == "" then _06b88e = "server_" .. os.time() end
    return _06b88e
end

function isServerMapped(serverIP)
    if not serverIP or serverIP == "" then return false end
    return _cf8b8c.ServerMapping[serverIP] ~= nil and _cf8b8c.ServerMapping[serverIP] ~= ""
end

function showNewServerDetectionDialog(serverIP, serverName)
    _6a596b.ip = serverIP
    _6a596b._06b88e = serverName
    _6a596b.suggestedProfileName = sanitizeProfileName(serverName)
    local _034311 = _6a596b.suggestedProfileName
    for i = 0, 63 do _2c14a3[i] = 0 end
    for i = 1, #_034311 do _2c14a3[i-1] = string.byte(_034311, i) end
    _0cf716[0] = true
end

function loadProfile(_ad30f4)
    if not _ad30f4 or _ad30f4 == "" then _ad30f4 = "default" end
    local _0b9ead = getProfileFileName(_ad30f4)
    local _c77dfa = inicfg.load(_55941f, _0b9ead)
    if not _c77dfa then
        inicfg.save(_55941f, _0b9ead)
        _c77dfa = _55941f
    end
    for k, v in pairs(_55941f) do
        if not _c77dfa[k] then _c77dfa[k] = v end
    end
    _a63521 = _c77dfa
    _bfba46 = _ad30f4
    _cf8b8c.Settings._bfba46 = _ad30f4
    inicfg.save(_cf8b8c, _687f44)
    reloadEditBuffers()
    sampAddChatMessage("{00FF00}[Radial Menu] {FFFFFF}Profile loaded: {FFFF00}" .. _ad30f4, -1)
    return true
end

function saveProfile(_ad30f4)
    if not _ad30f4 or _ad30f4 == "" then _ad30f4 = _bfba46 end
    local _0b9ead = getProfileFileName(_ad30f4)
    if inicfg.save(_a63521, _0b9ead) then
        sampAddChatMessage("{00FF00}[Radial Menu] {FFFFFF}Profile saved: {FFFF00}" .. _ad30f4, -1)
        return true
    end
    return false
end

function listProfiles()
    local _9df5a2 = {"default"}
    for k, v in pairs(_cf8b8c.ServerMapping or {}) do
        if v and v ~= "" and v ~= "default" then
            local _1f5cc0 = false
            for _, p in ipairs(_9df5a2) do
                if p == v then _1f5cc0 = true; break end
            end
            if not _1f5cc0 then table.insert(_9df5a2, v) end
        end
    end
    return _9df5a2
end

function getServerInfo()
    if not sampIsLocalPlayerSpawned() then return nil, nil end
    local ip, port = sampGetCurrentServerAddress()
    if ip and port then
        return ip .. ":" .. port, sampGetCurrentServerName()
    end
    return nil, nil
end

function autoLoadProfileForServer()
    if not _0cf751 then return false end
    local serverIP, serverName = getServerInfo()
    if not serverIP then return false end
    local _605641 = _cf8b8c.ServerMapping[serverIP]
    if _605641 and _605641 ~= "" and _605641 ~= _bfba46 then
        sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Auto-detected server: {FFFF00}" .. (serverName or serverIP), -1)
        return loadProfile(_605641)
    elseif not _605641 or _605641 == "" then
        sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}New server detected!", -1)
        showNewServerDetectionDialog(serverIP, serverName or serverIP)
        return true
    end
    return false
end

function mapServerToProfile(serverIP, _ad30f4)
    if not serverIP or serverIP == "" then return false end
    if not _ad30f4 or _ad30f4 == "" then _ad30f4 = _bfba46 end
    _cf8b8c.ServerMapping[serverIP] = _ad30f4
    inicfg.save(_cf8b8c, _687f44)
    sampAddChatMessage("{00FF00}[Radial Menu] {FFFFFF}Server {FFFF00}" .. serverIP .. "{FFFFFF} mapped to profile: {FFFF00}" .. _ad30f4, -1)
    return true
end

function reloadEditBuffers()
    _50a4e9[0] = _a63521.ButtonSettings.posX or 1100.0
    _b60fb8[0] = _a63521.ButtonSettings.posY or 140.0
    if _a63521.HamburgerButton then
        _c9cba7[0] = _a63521.HamburgerButton.enabled or true
        _0bb570[0] = _a63521.HamburgerButton.posX or 50.0
        _1a36f1[0] = _a63521.HamburgerButton.posY or 300.0

        _1fd47c[0] = _a63521.HamburgerButton.size or 80.0
        _39c580[0] = _a63521.HamburgerButton.alpha or 0.8
    end
    for i = 1, 4 do
        local _06b88e = _a63521["Sector"..i]._06b88e or ""
        local cmd = _a63521["Sector"..i].cmd or ""
        for j = 0, 31 do _9f29ad[i][j] = 0 end
        for j = 0, 63 do _c21ff1[i][j] = 0 end
        for j = 1, #_06b88e do _9f29ad[i][j-1] = string.byte(_06b88e, j) end
        for j = 1, #cmd do _c21ff1[i][j-1] = string.byte(cmd, j) end
    end
    for i = 1, 4 do
        local _5748df = _a63521["CatSector"..i]._06b88e or ""
        local _f59851 = _a63521["VehCatSector"..i]._06b88e or ""
        for j = 0, 31 do _3b9ab8[i][j] = 0; _2d4646[i][j] = 0 end
        for j = 1, #_5748df do _3b9ab8[i][j-1] = string.byte(_5748df, j) end
        for j = 1, #_f59851 do _2d4646[i][j-1] = string.byte(_f59851, j) end
    end
    for i = 1, _a166b4 do
        local s = _a63521["Anim"..i] or { _ef82b4="", cmd="", category="" }
        for j = 0, 63 do animEditLabel[i][j] = 0 end
        for j = 0, 127 do animEditCmd[i][j] = 0 end
        for j = 0, 31 do animEditCategory[i][j] = 0 end
        for j = 1, #(s._ef82b4 or "") do animEditLabel[i][j-1] = string.byte(s._ef82b4, j) end
        for j = 1, #(s.cmd or "") do animEditCmd[i][j-1] = string.byte(s.cmd, j) end
        for j = 1, #(s.category or "") do animEditCategory[i][j-1] = string.byte(s.category, j) end
    end
    for i = 1, _cad91d do
        local s = _a63521["Veh"..i] or { _ef82b4="", cmd="", category="" }
        for j = 0, 63 do vehEditLabel[i][j] = 0 end
        for j = 0, 127 do vehEditCmd[i][j] = 0 end
        for j = 0, 31 do vehEditCategory[i][j] = 0 end
        for j = 1, #(s._ef82b4 or "") do vehEditLabel[i][j-1] = string.byte(s._ef82b4, j) end
        for j = 1, #(s.cmd or "") do vehEditCmd[i][j-1] = string.byte(s.cmd, j) end
        for j = 1, #(s.category or "") do vehEditCategory[i][j-1] = string.byte(s.category, j) end
    end
    for i = 1, 10 do
        local s = _a63521["CtxVeh"..i] or { _06b88e = "", onCmd = "", offCmd = "" }
        for j = 0, 31 do ctxVehName[i][j] = 0 end
        for j = 0, 63 do ctxVehOn[i][j] = 0; ctxVehOff[i][j] = 0 end
        for j = 1, #(s._06b88e or "") do ctxVehName[i][j-1] = string.byte(s._06b88e, j) end
        for j = 1, #(s.onCmd or "") do ctxVehOn[i][j-1] = string.byte(s.onCmd, j) end
        for j = 1, #(s.offCmd or "") do ctxVehOff[i][j-1] = string.byte(s.offCmd, j) end
    end
    for i = 1, 10 do
        local s = _a63521["CtxFoot"..i] or { _06b88e = "", onCmd = "", offCmd = "" }
        for j = 0, 31 do ctxFootName[i][j] = 0 end
        for j = 0, 63 do ctxFootOn[i][j] = 0; ctxFootOff[i][j] = 0 end
        for j = 1, #(s._06b88e or "") do ctxFootName[i][j-1] = string.byte(s._06b88e, j) end
        for j = 1, #(s.onCmd or "") do ctxFootOn[i][j-1] = string.byte(s.onCmd, j) end
        for j = 1, #(s.offCmd or "") do ctxFootOff[i][j-1] = string.byte(s.offCmd, j) end
    end
    rebuildAnimList()
    rebuildVehList()
end

local _2be728 = {}
function rebuildAnimList()
    _2be728 = {}
    for i = 1, _a166b4 do
        local e = _a63521["Anim"..i]
        if e and e._ef82b4 ~= "" and e.category ~= "" then
            _2be728[#_2be728+1] = { _ef82b4=e._ef82b4, cmd=e.cmd or "", category=e.category }
        end
    end
end
rebuildAnimList()

function loadAnimForCategory(cat)
    _6ee295 = {}
    for _, a in ipairs(_2be728) do
        if a.category:lower() == cat:lower() then _6ee295[#_6ee295+1] = a end
    end
    _841d29 = 1
end

function getAnimPage(page)
    local s, r = (page-1)*4+1, {}
    for i = 0, 3 do r[i+1] = _6ee295[s+i] end
    return r
end

function totalAnimPages() return math.max(1, math.ceil(#_6ee295 / 4)) end

local _88a375 = {}
function rebuildVehList()
    _88a375 = {}
    for i = 1, _cad91d do
        local e = _a63521["Veh"..i]
        if e and e._ef82b4 ~= "" and e.category ~= "" then
            _88a375[#_88a375+1] = { _ef82b4=e._ef82b4, cmd=e.cmd or "", category=e.category }
        end
    end
end
rebuildVehList()

function loadVehForCategory(cat)
    _e54e32 = {}
    for _, v in ipairs(_88a375) do
        if v.category:lower() == cat:lower() then _e54e32[#_e54e32+1] = v end
    end
    _61f402 = 1
end

function getVehPage(page)
    local s, r = (page-1)*4+1, {}
    for i = 0, 3 do r[i+1] = _e54e32[s+i] end
    return r
end

function totalVehPages() return math.max(1, math.ceil(#_e54e32 / 4)) end

function getOnFootCommands()
    local _a862e7 = {}
    for i = 1, 10 do
        local s = _a63521["CtxFoot"..i] or { _06b88e = "-", onCmd = "", offCmd = "" }
        _a862e7[i] = { _06b88e = s._06b88e or "-", onCmd = s.onCmd or "", offCmd = s.offCmd or "" }
    end
    return _a862e7
end

function getInVehicleCommands()
    local _a862e7 = {}
    for i = 1, 10 do
        local s = _a63521["CtxVeh"..i] or { _06b88e = "-", onCmd = "", offCmd = "" }
        _a862e7[i] = { _06b88e = s._06b88e or "-", onCmd = s.onCmd or "", offCmd = s.offCmd or "" }
    end
    return _a862e7
end

function saveAllConfig()
    _a63521.ButtonSettings.posX = _50a4e9[0]
    _a63521.ButtonSettings.posY = _b60fb8[0]
    if not _a63521.HamburgerButton then _a63521.HamburgerButton = {} end
    _a63521.HamburgerButton.enabled = _c9cba7[0]
    _a63521.HamburgerButton.posX = _0bb570[0]
    _a63521.HamburgerButton.posY = _1a36f1[0]
    _a63521.HamburgerButton.size = _1fd47c[0]
    _a63521.HamburgerButton.alpha = _39c580[0]
    for i = 1, 4 do
        _a63521["Sector"..i]._06b88e       = readCharBuffer(_9f29ad[i], 32)
        _a63521["Sector"..i].cmd        = readCharBuffer(_c21ff1[i], 64)
        _a63521["CatSector"..i]._06b88e    = readCharBuffer(_3b9ab8[i], 32)
        _a63521["VehCatSector"..i]._06b88e = readCharBuffer(_2d4646[i], 32)
    end
    local _9aa08d = false
    for i = 1, _a166b4 do
        if not _a63521["Anim"..i] then _a63521["Anim"..i] = {} end
        local _c3656a = readCharBuffer(animEditLabel[i], 64)
        local _85cfc3 = readCharBuffer(animEditCmd[i], 128)
        local _1d15e8 = readCharBuffer(animEditCategory[i], 32)
        if _a63521["Anim"..i]._ef82b4 ~= _c3656a or _a63521["Anim"..i].cmd ~= _85cfc3 or _a63521["Anim"..i].category ~= _1d15e8 then _9aa08d = true end

        _a63521["Anim"..i]._ef82b4 = _c3656a
        _a63521["Anim"..i].cmd = _85cfc3
        _a63521["Anim"..i].category = _1d15e8
    end
    local _b0fade = false
    for i = 1, _cad91d do
        if not _a63521["Veh"..i] then _a63521["Veh"..i] = {} end
        local _c3656a = readCharBuffer(vehEditLabel[i], 64)
        local _85cfc3 = readCharBuffer(vehEditCmd[i], 128)
        local _1d15e8 = readCharBuffer(vehEditCategory[i], 32)
        if _a63521["Veh"..i]._ef82b4 ~= _c3656a or _a63521["Veh"..i].cmd ~= _85cfc3 or _a63521["Veh"..i].category ~= _1d15e8 then _b0fade = true end
        _a63521["Veh"..i]._ef82b4 = _c3656a
        _a63521["Veh"..i].cmd = _85cfc3
        _a63521["Veh"..i].category = _1d15e8
    end
    for i = 1, 10 do
        if not _a63521["CtxVeh"..i] then _a63521["CtxVeh"..i] = {} end
        _a63521["CtxVeh"..i]._06b88e = readCharBuffer(ctxVehName[i], 32)
        _a63521["CtxVeh"..i].onCmd = readCharBuffer(ctxVehOn[i], 64)
        _a63521["CtxVeh"..i].offCmd = readCharBuffer(ctxVehOff[i], 64)
    end
    for i = 1, 10 do
        if not _a63521["CtxFoot"..i] then _a63521["CtxFoot"..i] = {} end
        _a63521["CtxFoot"..i]._06b88e = readCharBuffer(ctxFootName[i], 32)
        _a63521["CtxFoot"..i].onCmd = readCharBuffer(ctxFootOn[i], 64)
        _a63521["CtxFoot"..i].offCmd = readCharBuffer(ctxFootOff[i], 64)
    end
    if inicfg.save(_a63521, _0a998a) then
        if _9aa08d then rebuildAnimList() end
        if _b0fade then rebuildVehList() end
        sampAddChatMessage("{00FF00}[Radial Menu] {FFFFFF}Configuration saved!", -1)
        _33efa4[0] = false
        return true
    else
        sampAddChatMessage("{FF0000}[Radial Menu] {FFFFFF}Failed to save config!", -1)
        return false
    end
end

function drawPieMenuBackground(_50b3ca, centerX, centerY, radius, scale)
    local _9bfa6e = 0.85 * scale
    _50b3ca:AddCircleFilled(
        imgui.ImVec2(centerX, centerY),
        radius + 40,
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.08, 0.08, 0.12, _9bfa6e)),
        64
    )
    _50b3ca:AddCircle(
        imgui.ImVec2(centerX, centerY),
        radius + 42,
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.3, 0.6, 0.9, 0.5 * scale)),
        64,
        2
    )
end

function drawPieSector(_50b3ca, centerX, centerY, _e147b6, _1ba2d2, _affbb8, _f979c0, color, alpha, scale)
    local _cd559e = 20
    for seg = 0, _cd559e - 1 do
        local a1 = _e147b6 + (_1ba2d2 - _e147b6) * seg / _cd559e
        local a2 = _e147b6 + (_1ba2d2 - _e147b6) * (seg + 1) / _cd559e
        local p1 = imgui.ImVec2(centerX + math.cos(a1) * _affbb8, centerY + math.sin(a1) * _affbb8)
        local p2 = imgui.ImVec2(centerX + math.cos(a1) * _f979c0, centerY + math.sin(a1) * _f979c0)
        local p3 = imgui.ImVec2(centerX + math.cos(a2) * _f979c0, centerY + math.sin(a2) * _f979c0)
        local p4 = imgui.ImVec2(centerX + math.cos(a2) * _affbb8, centerY + math.sin(a2) * _affbb8)
        local _794d0b = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(color[1], color[2], color[3], alpha * scale))
        _50b3ca:AddQuadFilled(p1, p2, p3, p4, _794d0b)
    end
end

function drawSectorDivider(_50b3ca, centerX, centerY, angle, _affbb8, _f979c0, scale)
    local _bcdd80 = imgui.ImVec2(centerX + math.cos(angle) * _affbb8, centerY + math.sin(angle) * _affbb8)
    local _f20590 = imgui.ImVec2(centerX + math.cos(angle) * _f979c0, centerY + math.sin(angle) * _f979c0)
    _50b3ca:AddLine(_bcdd80, _f20590,
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.5, 0.5, 0.6, 0.4 * scale)),
        1.5
    )
end

function drawCenterButton(_50b3ca, centerX, centerY, _7524d6, centerHovered, scale, _f3130d, labelColor)
    local _d78b20 = centerHovered and (0.9 * scale) or (0.6 * scale)
    _50b3ca:AddCircleFilled(
        imgui.ImVec2(centerX, centerY),
        _7524d6,
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.15, 0.15, 0.22, _d78b20)),
        32
    )
    _50b3ca:AddCircle(
        imgui.ImVec2(centerX, centerY),
        _7524d6,
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.6, 0.6, 0.8, 0.5 * scale)),
        32,
        1.5
    )
    local _6a384b = _47af6e and _6b11d3('XMARK') or _f3130d
    local _a12407 = imgui.CalcTextSize(_6a384b)
    _50b3ca:AddText(
        imgui.ImVec2(centerX - _a12407.x / 2, centerY - _a12407.y / 2),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(labelColor[1], labelColor[2], labelColor[3], scale)),
        _6a384b
    )
end

function detectHoveredSector(_e078f1, centerX, centerY, _6fd5ab, _3fe08e, _91bd07, scale)

    local dx = _e078f1.x - centerX
    local dy = _e078f1.y - centerY
    local _835462 = math.sqrt(dx * dx + dy * dy)
    local _f145f0 = (2 * math.pi) / _3fe08e
    if _835462 > 30 * scale and _835462 < (_6fd5ab + 50) * scale then
        local _11b296 = math.atan2(dy, dx)
        local _d85942 = _11b296 - _91bd07
        if _d85942 < 0 then _d85942 = _d85942 + 2 * math.pi end
        local _d4c91d = math.floor(_d85942 / _f145f0) + 1
        if _d4c91d > _3fe08e then _d4c91d = 1 end
        return _d4c91d, _835462 < 30 * scale
    end
    return -1, _835462 < 30 * scale
end

function drawPieMenu(_50b3ca, centerX, centerY, items, scale, _37cc72, titleColor)
    local _6fd5ab = 120 * scale
    local _3fe08e = #items
    local _f145f0 = (2 * math.pi) / _3fe08e
    local _91bd07 = -math.pi * 3/4
    local _e078f1 = imgui.GetIO().MousePos
    local hoveredSector, centerHovered = detectHoveredSector(_e078f1, centerX, centerY, _6fd5ab, _3fe08e, _91bd07, scale)
    
    drawPieMenuBackground(_50b3ca, centerX, centerY, _6fd5ab, scale)
    
    for i = 1, _3fe08e do
        if items[i] then
            local _e147b6 = _91bd07 + (i - 1) * _f145f0
            local _1ba2d2 = _91bd07 + i * _f145f0
            local _50bd84 = (_e147b6 + _1ba2d2) / 2
            local _4563a5 = (hoveredSector == i)
            local _23c64e = _4563a5 and 0.6 or 0.2
            local col = items[i].color or { 0.4, 0.4, 0.6 }
            local _affbb8 = 35 * scale
            local _f979c0 = (_6fd5ab + 35) * scale
            
            drawPieSector(_50b3ca, centerX, centerY, _e147b6, _1ba2d2, _affbb8, _f979c0, col, _23c64e, scale)
            drawSectorDivider(_50b3ca, centerX, centerY, _e147b6, _affbb8, _f979c0, scale)
            
            local _86e15f = (_affbb8 + _f979c0) / 2
            local _fce941 = centerX + math.cos(_50bd84) * _86e15f
            local _96e507 = centerY + math.sin(_50bd84) * _86e15f
            local _f3130d = items[i]._ef82b4 or "---"
            local _b49587 = imgui.CalcTextSize(_f3130d)
            local _d91278 = _4563a5 and scale or (0.7 * scale)
            local _7fd3f5 = items[i].labelColor or imgui.ImVec4(0.9, 0.9, 0.9, _d91278)
            if type(_7fd3f5) == "number" then
                _50b3ca:AddText(
                    imgui.ImVec2(_fce941 - _b49587.x / 2, _96e507 - _b49587.y / 2),
                    _7fd3f5,
                    _f3130d
                )
            else
                _50b3ca:AddText(
                    imgui.ImVec2(_fce941 - _b49587.x / 2, _96e507 - _b49587.y / 2),
                    imgui.ColorConvertFloat4ToU32(_7fd3f5),
                    _f3130d
                )
            end
        end
    end

    local _7524d6 = 30 * scale
    drawCenterButton(_50b3ca, centerX, centerY, _7524d6, centerHovered, scale, "X", titleColor or {1, 0.4, 0.4})
    
    if _37cc72 and _37cc72 ~= "" then
        local _0e2723 = imgui.CalcTextSize(_37cc72)
        _50b3ca:AddText(
            imgui.ImVec2(centerX - _0e2723.x / 2, centerY - _6fd5ab - 50),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.6, 0.8, 1.0, 0.8 * scale)),
            _37cc72
        )
    end
    
    return hoveredSector, centerHovered
end

function main()
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Script loaded successfully!", -1)
    sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Use {FFFF00}/rcmdf{FFFFFF} to configure", -1)
    sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Current profile: {FFFF00}" .. _bfba46, -1)
    sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Created by: {FFFF00}OnlyDexterZ", -1)

    sampRegisterChatCommand("rcmdf", function(param)
        _33efa4[0] = not _33efa4[0]
        if param == "anim" or param == "2" then
            _f6bbec = 2
        elseif param == "veh" or param == "vehicle" or param == "3" then
            _f6bbec = 3
        elseif param == "profile" or param == "4" then
            _f6bbec = 4
        else
            _f6bbec = 1
        end
    end)
    
    sampRegisterChatCommand("animdebug", function()
        sampAddChatMessage("{00FFFF}=== ANIMATION DEBUG ==={FFFFFF}", -1)
        sampAddChatMessage("{FFFF00}Categories:{FFFFFF}", -1)
        for i = 1, 4 do
            local _5748df = _a63521["CatSector"..i]._06b88e or ""
            sampAddChatMessage(string.format("  Cat%d: '%s'", i, _5748df), -1)
        end
        sampAddChatMessage("{FFFF00}Animation Slots:{FFFFFF}", -1)
        local _dcc6b0 = 0
        for i = 1, _a166b4 do
            local e = _a63521["Anim"..i]
            if e and e._ef82b4 ~= "" and e.category ~= "" then
                _dcc6b0 = _dcc6b0 + 1
                sampAddChatMessage(string.format("  Anim%d: Cat='%s' Lbl='%s' Cmd='%s'", i, e.category, e._ef82b4, e.cmd), -1)
            end
        end
        sampAddChatMessage(string.format("{00FF00}Total valid anims: %d{FFFFFF}", _dcc6b0), -1)
        sampAddChatMessage(string.format("{00FF00}_2be728 size: %d{FFFFFF}", #_2be728), -1)
    end)
    
    sampRegisterChatCommand("rprofile", function(param)
        local _31611c = {}
        for word in param:gmatch("%S+") do table.insert(_31611c, word) end
        if #_31611c == 0 or _31611c[1] == "list" then
            local _9df5a2 = listProfiles()
            sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Available _9df5a2:", -1)
            for _, p in ipairs(_9df5a2) do
                local _d8f70f = (p == _bfba46) and "{00FF00}[ACTIVE]" or ""
                sampAddChatMessage("{FFFF00}" .. p .. " {FFFFFF}" .. _d8f70f, -1)
            end
        elseif _31611c[1] == "load" and _31611c[2] then
            loadProfile(_31611c[2])
        elseif _31611c[1] == "save" and _31611c[2] then
            saveProfile(_31611c[2])

        elseif _31611c[1] == "create" and _31611c[2] then
            loadProfile(_31611c[2])
        elseif _31611c[1] == "map" and _31611c[2] then
            local serverIP, serverName = getServerInfo()
            if serverIP then
                mapServerToProfile(serverIP, _31611c[2])
            else
                sampAddChatMessage("{FF0000}[Radial Menu] {FFFFFF}Not connected to server!", -1)
            end
        elseif _31611c[1] == "current" then
            sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Current profile: {FFFF00}" .. _bfba46, -1)
            local serverIP, serverName = getServerInfo()
            if serverIP then
                sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Server: {FFFF00}" .. (serverName or serverIP), -1)
            end
        else
            sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Profile Commands:", -1)
            sampAddChatMessage("{FFFF00}/rprofile list {FFFFFF}- List all _9df5a2", -1)
            sampAddChatMessage("{FFFF00}/rprofile load <_06b88e> {FFFFFF}- Load profile", -1)
            sampAddChatMessage("{FFFF00}/rprofile save <_06b88e> {FFFFFF}- Save to profile", -1)
            sampAddChatMessage("{FFFF00}/rprofile create <_06b88e> {FFFFFF}- Create new profile", -1)
            sampAddChatMessage("{FFFF00}/rprofile map <_06b88e> {FFFFFF}- Map current server to profile", -1)
            sampAddChatMessage("{FFFF00}/rprofile current {FFFFFF}- Show current profile", -1)
        end
    end)
    
    lua_thread.create(function()
        local _9243c4 = ""
        while true do
            wait(1000)
            if sampIsLocalPlayerSpawned() then
                local serverIP, serverName = getServerInfo()
                if serverIP and serverIP ~= _9243c4 then
                    _9243c4 = serverIP
                    _eb57c8 = serverIP
                    _c1857a = serverName or serverIP
                    if _0cf751 then
                        autoLoadProfileForServer()
                    end
                end
            end
        end
    end)

    imgui.OnFrame(function() return true end, function()
        local sw, sh = getScreenResolution()
        local _50b3ca = imgui.GetBackgroundDrawList()
        local cx, cy = sw / 2, sh / 2

        local _b1c29c = false
        pcall(function() _b1c29c = sampIsDialogActive() end)
        if _b1c29c then
            if _dc3998[0] or _8b5290[0] or _f34dd4[0] or _8452e2[0] or _3dc961[0] or _5844eb[0] or _076de0[0] then
                closeAllRadial()
            end
        end

        if _0cf716[0] then
            imgui.SetNextWindowPos(imgui.ImVec2(sw/2 - 250, sh/2 - 150), imgui.Cond.Always)
            imgui.SetNextWindowSize(imgui.ImVec2(500, 300))
            imgui.Begin("New Server Detected", _0cf716, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
            imgui.TextColored(imgui.ImVec4(0, 1, 1, 1), "NEW SERVER DETECTED!")
            imgui.Spacing(); imgui.Separator(); imgui.Spacing()
            imgui.Text("Server:"); imgui.SameLine()
            imgui.TextColored(imgui.ImVec4(1, 1, 0, 1), _6a596b._06b88e)
            imgui.Text("IP:"); imgui.SameLine()
            imgui.TextDisabled(_6a596b.ip)
            imgui.Spacing(); imgui.Separator(); imgui.Spacing()
            imgui.TextColored(imgui.ImVec4(0, 1, 0, 1), "Create profile for this server?")
            imgui.Spacing()
            imgui.Text("Profile _06b88e:")
            imgui.SetNextItemWidth(-1)
            imgui.InputText("##newprofilename", _2c14a3, 64)
            imgui.TextDisabled("(You can edit the _06b88e before creating)")
            imgui.Spacing(); imgui.Separator(); imgui.Spacing()
            if imgui.Button("CREATE & MAP", imgui.ImVec2(230, 40)) then
                local _ad30f4 = readCharBuffer(_2c14a3, 64)
                if _ad30f4 ~= "" then
                    loadProfile(_ad30f4)
                    mapServerToProfile(_6a596b.ip, _ad30f4)
                    saveProfile(_ad30f4)
                    _0cf716[0] = false
                    sampAddChatMessage("{00FF00}[Radial Menu] {FFFFFF}Profile created & mapped: {FFFF00}" .. _ad30f4, -1)
                end
            end
            imgui.SameLine()
            if imgui.Button("USE DEFAULT", imgui.ImVec2(230, 40)) then
                _0cf716[0] = false
                sampAddChatMessage("{FFFF00}[Radial Menu] {FFFFFF}Using current profile: {FFFF00}" .. _bfba46, -1)
            end
            imgui.Spacing()
            imgui.TextColored(imgui.ImVec4(1, 0.5, 0, 1), "INFO:")
            imgui.TextDisabled("Creating a profile will auto-load it next time")
            imgui.TextDisabled("you connect to this server.")
            imgui.End()
        end

        if _33efa4[0] then
            local _9b4258 = 500
            local _9506cc = 350
            if _f6bbec == 2 then _9506cc = 520 end
            if _f6bbec == 3 then _9506cc = 500 end
            if _f6bbec == 4 then _9506cc = 350 end
            
            imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12)
            imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(15, 12))
            imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 6)
            imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(8, 6))
            imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.08, 0.08, 0.1, 0.95))
            imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.15, 0.15, 0.2, 1.0))
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.2, 0.3, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.3, 0.3, 0.5, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.15, 0.4, 0.8, 1.0))
            
            imgui.SetNextWindowPos(imgui.ImVec2((sw - _9b4258) / 2, (sh - _9506cc) / 2), imgui.Cond.Always)
            imgui.SetNextWindowSize(imgui.ImVec2(_9b4258, _9506cc))
            imgui.Begin("Radial Menu Config v2", _33efa4, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar)
            
            local _fb3cbc = (_9b4258 - 30) / 4
            local _fae277 = 30
            local _1b5d24 = {"1.MAIN", "2.ANIM", "3.VEH", "4.PROF"}
            for t = 1, 4 do
                local _ef82b4 = _1b5d24[t]
                if _f6bbec == t then _ef82b4 = "> " .. _ef82b4 .. " <" end
                if imgui.Button(_ef82b4, imgui.ImVec2(_fb3cbc, _fae277)) then _f6bbec = t end
                if t < 4 then imgui.SameLine() end
            end
            imgui.Spacing(); imgui.Separator(); imgui.Spacing()
            
            if _f6bbec == 1 then
                imgui.TextColored(imgui.ImVec4(0.2, 0.9, 0.4, 1), "HAMBURGER BUTTON")
                imgui.Spacing()
                imgui.Text("Position X:"); imgui.SetNextItemWidth(-1)
                imgui.SliderFloat("##posX", _0bb570, 0, sw - 100, "%.0f")
                imgui.Text("Position Y:"); imgui.SetNextItemWidth(-1)
                imgui.SliderFloat("##posY", _1a36f1, 0, sh - 100, "%.0f")
                imgui.Spacing()
                imgui.Text("Size:"); imgui.SetNextItemWidth(-1)
                imgui.SliderFloat("##size", _1fd47c, 50, 150, "%.0f")
                imgui.Text("Opacity:"); imgui.SetNextItemWidth(-1)
                imgui.SliderFloat("##opacity", _39c580, 0.3, 1.0, "%.2f")
                
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.9, 0.5, 0.2, 1), "MAIN SECTORS")
                imgui.Spacing()
                for i = 1, 4 do
                    imgui.Text("Sector "..i..":"); imgui.SameLine()
                    imgui.SetNextItemWidth(120); imgui.InputText("Name##n"..i, _9f29ad[i], 32); imgui.SameLine()
                    if i == 1 or i == 3 then 
                        imgui.TextDisabled(i == 1 and "(vehicle menu)" or "(anim menu)")
                    else 
                        imgui.SetNextItemWidth(-1); imgui.InputText("Cmd##c"..i, _c21ff1[i], 64) 
                    end
                end
                
            elseif _f6bbec == 2 then
                imgui.TextColored(imgui.ImVec4(0.9, 0.7, 0.1, 1), "ANIM CATEGORIES")
                imgui.Spacing()
                for i = 1, 4 do
                    imgui.Text("Cat "..i..":"); imgui.SameLine()
                    imgui.SetNextItemWidth(80); imgui.InputText("##ca"..i, _3b9ab8[i], 32)
                    if i < 4 then imgui.SameLine() end
                end
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.9, 0.7, 0.1, 1), "ANIMATION COMMANDS")
                imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Category"); imgui.SameLine(130)
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Label"); imgui.SameLine(260)
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Command")
                imgui.Separator(); imgui.Spacing()
                imgui.BeginChild("##animscroll", imgui.ImVec2(-1, -50), true)
                for i = 1, _a166b4 do
                    imgui.PushItemWidth(100); imgui.InputText("##animcat"..i, animEditCategory[i], 32); imgui.PopItemWidth()
                    imgui.SameLine(130)
                    imgui.PushItemWidth(100); imgui.InputText("##animlbl"..i, animEditLabel[i], 64); imgui.PopItemWidth()
                    imgui.SameLine(260)
                    imgui.PushItemWidth(-1); imgui.InputText("##animcmd"..i, animEditCmd[i], 128); imgui.PopItemWidth()
                end
                imgui.EndChild()
            elseif _f6bbec == 3 then
                imgui.TextColored(imgui.ImVec4(0.2, 0.6, 1.0, 1), "IN-VEHICLE COMMANDS")
                imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Category"); imgui.SameLine(130)
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "ON Cmd"); imgui.SameLine(310)
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "OFF Cmd")
                imgui.Separator(); imgui.Spacing()
                for i = 1, 10 do
                    imgui.PushItemWidth(100); imgui.InputText("##vn"..i, ctxVehName[i], 32); imgui.PopItemWidth()
                    imgui.SameLine(130)
                    imgui.PushItemWidth(150); imgui.InputText("##vo"..i, ctxVehOn[i], 64); imgui.PopItemWidth()
                    imgui.SameLine(310)
                    imgui.PushItemWidth(-1); imgui.InputText("##vf"..i, ctxVehOff[i], 64); imgui.PopItemWidth()
                end
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.2, 0.6, 1.0, 1), "ON-FOOT COMMANDS")
                imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Category"); imgui.SameLine(130)
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "ON Cmd"); imgui.SameLine(310)
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "OFF Cmd")
                imgui.Separator(); imgui.Spacing()
                for i = 1, 10 do
                    imgui.PushItemWidth(100); imgui.InputText("##fn"..i, ctxFootName[i], 32); imgui.PopItemWidth()
                    imgui.SameLine(130)
                    imgui.PushItemWidth(150); imgui.InputText("##fo"..i, ctxFootOn[i], 64); imgui.PopItemWidth()
                    imgui.SameLine(310)
                    imgui.PushItemWidth(-1); imgui.InputText("##ff"..i, ctxFootOff[i], 64); imgui.PopItemWidth()
                end
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.2, 0.8, 0.4, 1), "VEHICLE COMMANDS")
                imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Category"); imgui.SameLine(130)
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Label"); imgui.SameLine(260)
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Command")
                imgui.Separator(); imgui.Spacing()
                imgui.BeginChild("##vehscroll", imgui.ImVec2(-1, -50), true)
                for i = 1, _cad91d do
                    imgui.PushItemWidth(100); imgui.InputText("##vc"..i, vehEditCategory[i], 32); imgui.PopItemWidth()
                    imgui.SameLine(130)
                    imgui.PushItemWidth(100); imgui.InputText("##vl"..i, vehEditLabel[i], 64); imgui.PopItemWidth()
                    imgui.SameLine(260)
                    imgui.PushItemWidth(-1); imgui.InputText("##vcmd"..i, vehEditCmd[i], 128); imgui.PopItemWidth()
                end
                imgui.EndChild()

            elseif _f6bbec == 4 then
                imgui.TextColored(imgui.ImVec4(0.8, 0.3, 0.8, 1), "PROFILE MANAGEMENT")
                imgui.Spacing()
                imgui.Text("Current Profile:"); imgui.SameLine()
                imgui.TextColored(imgui.ImVec4(1, 1, 0, 1), _bfba46)
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                
                if _eb57c8 ~= "" then
                    imgui.TextColored(imgui.ImVec4(0, 1, 1, 1), "Current Server:")
                    imgui.Text(_c1857a)
                    imgui.TextDisabled(_eb57c8)
                    local _605641 = _cf8b8c.ServerMapping[_eb57c8] or "none"
                    imgui.Text("Mapped to: " .. _605641)
                else
                    imgui.TextColored(imgui.ImVec4(1, 0.5, 0, 1), "Not connected to server")
                end
                
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                
                if imgui.Checkbox("Auto-detect server and load profile", _4e61ac) then
                    _0cf751 = _4e61ac[0]
                    _cf8b8c.Settings._0cf751 = _0cf751
                    inicfg.save(_cf8b8c, _687f44)
                end
                imgui.TextDisabled("Automatically load profile when connecting")
                
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0, 1, 1, 1), "CREATE NEW PROFILE:")
                imgui.SetNextItemWidth(300)
                imgui.InputText("##profilename", _557666, 32)
                imgui.SameLine()
                if imgui.Button("Create", imgui.ImVec2(80, 25)) then
                    local _361fe6 = readCharBuffer(_557666, 32)
                    if _361fe6 ~= "" then
                        loadProfile(_361fe6)
                        sampAddChatMessage("{00FF00}[Radial Menu] {FFFFFF}Profile created: " .. _361fe6, -1)
                    end
                end
                
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0, 1, 0, 1), "LOAD PROFILE:")
                _01856b = listProfiles()
                imgui.SetNextItemWidth(300)
                if imgui.BeginCombo("##loadprofile", _bfba46) then
                    for _, _361fe6 in ipairs(_01856b) do
                        local _c3c1bf = (_361fe6 == _bfba46)
                        if imgui.Selectable(_361fe6, _c3c1bf) then
                            loadProfile(_361fe6)
                        end
                        if _c3c1bf then imgui.SetItemDefaultFocus() end
                    end
                    imgui.EndCombo()
                end
                imgui.SameLine()
                if imgui.Button("Load", imgui.ImVec2(80, 25)) then
                    sampAddChatMessage("{00FF00}[Radial Menu] {FFFFFF}Profile active: {FFFF00}" .. _bfba46, -1)
                end
            end
            
            imgui.Spacing()
            if imgui.Button("SAVE ALL", imgui.ImVec2(-1, 40)) then
                saveAllConfig()
            end
            
            imgui.End()
            imgui.PopStyleColor(5)
            imgui.PopStyleVar(4)
        end
        
        if not _33efa4[0] then
            local hbx = _0bb570[0]
            local hby = _1a36f1[0]
            local hbs = _1fd47c[0]
            local hba = _39c580[0]
            local _e516c7 = hbs / 2
            local _9275a0 = hbx + _e516c7
            local _0613c2 = hby + _e516c7
            local _3ea78b = imgui.ImVec2(_9275a0, _0613c2)
            
            _c1d95b = (_c1d95b + 0.05) % (math.pi * 2)
            local _b48e8a = math.sin(_c1d95b) * 0.15 + 1.0
            local _fd66a1 = math.floor(hba * 100 * (1.0 - (_b48e8a - 1.0) * 3))
            local _304a5e = _fd66a1 * 0x01000000 + 0x0044AAFF
            _50b3ca:AddCircleFilled(_3ea78b, _e516c7 * _b48e8a, _304a5e, 16)
            
            local _b6a895 = math.floor(hba * 220)
            _50b3ca:AddCircleFilled(_3ea78b, _e516c7, _b6a895 * 0x01000000 + 0x00222222, 32)
            
            local _8fbace = math.floor(hba * 255)
            _50b3ca:AddCircle(_3ea78b, _e516c7, _8fbace * 0x01000000 + 0x0088DDFF, 32, 3.0)
            
            local _346ce3 = hbs * 0.4
            local _89e2ee = math.floor(hba * 255)
            local _914af3 = _89e2ee * 0x01000000 + 0x00FFFFFF
            local _942b42 = _346ce3 * 0.8
            local _905f40 = _346ce3 * 0.12
            local _5ab329 = _346ce3 * 0.25
            local _282bd0 = _942b42 / 2
            local _8e5f0b = _905f40 / 2
            
            _50b3ca:AddRectFilled(imgui.ImVec2(_9275a0 - _282bd0, _0613c2 - _5ab329 - _8e5f0b), imgui.ImVec2(_9275a0 + _282bd0, _0613c2 - _5ab329 + _8e5f0b), _914af3, _8e5f0b)
            _50b3ca:AddRectFilled(imgui.ImVec2(_9275a0 - _282bd0, _0613c2 - _8e5f0b), imgui.ImVec2(_9275a0 + _282bd0, _0613c2 + _8e5f0b), _914af3, _8e5f0b)
            _50b3ca:AddRectFilled(imgui.ImVec2(_9275a0 - _282bd0, _0613c2 + _5ab329 - _8e5f0b), imgui.ImVec2(_9275a0 + _282bd0, _0613c2 + _5ab329 + _8e5f0b), _914af3, _8e5f0b)

            imgui.SetNextWindowPos(imgui.ImVec2(hbx, hby), imgui.Cond.Always)
            imgui.SetNextWindowSize(imgui.ImVec2(hbs, hbs))
            imgui.Begin("RadialBtn", nil,
                imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoBackground + imgui.WindowFlags.NoScrollbar)
                if imgui.InvisibleButton("##hamburger_main", imgui.ImVec2(hbs - 10, hbs - 10)) then
                    local _24e005 = _dc3998[0] or _8b5290[0] or _f34dd4[0] or _8452e2[0] or _3dc961[0] or _5844eb[0] or _076de0[0]
                    if _24e005 then
                        closeAllRadial()
                    else
                        _dc3998[0] = true
                        _f6e0cb = os.clock()
                    end
                end
            imgui.End()
        end
        
        local _633c67 = _dc3998[0] or _8b5290[0] or _f34dd4[0] or _8452e2[0] or _3dc961[0] or _5844eb[0] or _076de0[0]
        if _633c67 then
            local _958831 = os.clock() - _f6e0cb
            local _eaf225 = 0.3
            local t = clamp(_958831 / _eaf225, 0, 1.0)
            _b578d6 = getEase('outCubic', t)
        else
            if _b578d6 > 0 then
                local _958831 = os.clock() - _f6e0cb
                local _eaf225 = 0.3
                local t = clamp(_958831 / _eaf225, 0, 1.0)
                _b578d6 = 1.0 - getEase('inCubic', t)
            end
        end
        _b578d6 = clamp(_b578d6, 0, 1.0)
        
        if _b578d6 > 0.01 then
            imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 0)
            imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
            imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0.4 * _b578d6))
            imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0, 0, 0, 0))
            
            imgui.SetNextWindowPos(imgui.ImVec2(0, 0), imgui.Cond.Always)
            imgui.SetNextWindowSize(imgui.ImVec2(sw, sh), imgui.Cond.Always)
            imgui.Begin('##PieOverlay', nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoSavedSettings)

            if _dc3998[0] then
                local _0a2fae = false
                pcall(function() _0a2fae = isCharInAnyCar(PLAYER_PED) end)
                
                local _debc26 = {
                    { _ef82b4 = _a63521.Sector1._06b88e or "VEHICLE", color = {0.26, 0.71, 0.81}, labelColor = 0xFFFFFFFF },
                    { _ef82b4 = _a63521.Sector2._06b88e or "-", color = {0.91, 0.30, 0.40}, labelColor = 0xFFFFFFFF },
                    { _ef82b4 = _a63521.Sector3._06b88e or "ANIM", color = {0.54, 0.36, 0.76}, labelColor = _0a2fae and 0x55FFFFFF or 0xFFFFFFFF },
                    { _ef82b4 = _a63521.Sector4._06b88e or "-", color = {0.26, 0.81, 0.46}, labelColor = 0xFFFFFFFF },
                }
                
                local hoveredSector, centerHovered = drawPieMenu(_50b3ca, cx, cy, _debc26, _b578d6, "[MAIN]", {1, 1, 0})
                
                local _feea06 = os.clock()
                if imgui.IsMouseClicked(0) and (_feea06 - _92bdec) > _368e88 then
                    _92bdec = _feea06
                    if centerHovered then
                        closeAllRadial()
                    elseif hoveredSector == 1 then
                        if _0a2fae then
                            _f89f49 = getInVehicleCommands()
                        else
                            _f89f49 = getOnFootCommands()
                        end
                        _dc3998[0] = false
                        _5844eb[0] = true
                        _f6e0cb = os.clock()
                    elseif hoveredSector == 2 then
                        closeAllRadial()
                        sampProcessChatInput("/openmap")
                    elseif hoveredSector == 3 then
                        if not _0a2fae then
                            _dc3998[0] = false
                            _8b5290[0] = true
                            _f6e0cb = os.clock()
                        end
                    elseif hoveredSector == 4 then
                        local cmd = _a63521.Sector4.cmd or ""
                        if executeCommand(cmd) then closeAllRadial() end
                    end
                end
            end

            if _5844eb[0] then
                local _debc26 = {}
                for i = 1, 4 do
                    local cmd = _f89f49[i]
                    _debc26[i] = { 
                        _ef82b4 = cmd and cmd._06b88e or "---", 
                        color = {0.26, 0.71, 0.81},
                        labelColor = (cmd and cmd._06b88e and cmd._06b88e ~= "-") and 0xFFFFFFFF or 0x55FFFFFF
                    }
                end
                
                local hoveredSector, centerHovered = drawPieMenu(_50b3ca, cx, cy, _debc26, _b578d6, "[QUICK VEH]", {0.53, 0.86, 1.0})
                
                local _feea06 = os.clock()
                if imgui.IsMouseClicked(0) and (_feea06 - _92bdec) > _368e88 then
                    _92bdec = _feea06
                    if centerHovered then
                        _5844eb[0] = false
                        _dc3998[0] = true
                        _f6e0cb = os.clock()
                    elseif hoveredSector >= 1 and hoveredSector <= 4 then
                        local _060b4a = _f89f49[hoveredSector]
                        if _060b4a and _060b4a._06b88e and _060b4a._06b88e ~= "-" and _060b4a._06b88e ~= "" then
                            if (_060b4a.onCmd and _060b4a.onCmd ~= "") or (_060b4a.offCmd and _060b4a.offCmd ~= "") then
                                _aad948 = { _06b88e = _060b4a._06b88e, onCmd = _060b4a.onCmd or "", offCmd = _060b4a.offCmd or "" }
                                _5844eb[0] = false
                                _076de0[0] = true
                                _f6e0cb = os.clock()
                            end
                        end
                    end
                end
            end
            
            if _076de0[0] then
                local _499ceb = _aad948
                local cat = (_499ceb._06b88e or ""):lower()
                local _274008 = _688bb1[cat]
                
                local onLabel, offLabel = "ON", "OFF"
                if cat == "lock" then
                    onLabel, offLabel = "LOCK", "UNLOCK"
                elseif cat == "trunk" or cat == "hood" then
                    onLabel, offLabel = "OPEN", "CLOSE"
                elseif cat == "engine" or cat == "light" or cat == "lights" then
                    onLabel, offLabel = "ON", "OFF"
                end
                
                local _f36a7a = _274008 and 0x55FFFFFF or 0xFF44FF44
                local _7b6c70 = _274008 and 0xFFFF4444 or 0x55FFFFFF
                
                local _debc26 = {
                    { _ef82b4 = onLabel, color = {0.26, 0.81, 0.46}, labelColor = _f36a7a },
                    { _ef82b4 = "-", color = {0.4, 0.4, 0.4}, labelColor = 0x55FFFFFF },
                    { _ef82b4 = offLabel, color = {0.91, 0.30, 0.40}, labelColor = _7b6c70 },
                    { _ef82b4 = "-", color = {0.4, 0.4, 0.4}, labelColor = 0x55FFFFFF },
                }
                
                local hoveredSector, centerHovered = drawPieMenu(_50b3ca, cx, cy, _debc26, _b578d6, "[" .. _499ceb._06b88e .. "]", {0, 1, 1})

                local _feea06 = os.clock()
                if imgui.IsMouseClicked(0) and (_feea06 - _92bdec) > _368e88 then
                    _92bdec = _feea06
                    if centerHovered then
                        _076de0[0] = false
                        _5844eb[0] = true
                        _f6e0cb = os.clock()
                    elseif hoveredSector == 1 and not _274008 then
                        executeCommand(_499ceb.onCmd)
                        _688bb1[cat] = true
                        closeAllRadial()
                    elseif hoveredSector == 3 and _274008 then
                        executeCommand(_499ceb.offCmd)
                        _688bb1[cat] = false
                        closeAllRadial()
                    end
                end
            end
            
            if _8b5290[0] then
                local _debc26 = {}
                for i = 1, 4 do
                    local _5748df = _a63521["CatSector"..i]._06b88e or ""
                    _debc26[i] = { 
                        _ef82b4 = _5748df ~= "" and _5748df or "-", 
                        color = {0.54, 0.36, 0.76},
                        labelColor = _5748df ~= "" and 0xFFFFFFFF or 0x55FFFFFF
                    }
                end
                
                local hoveredSector, centerHovered = drawPieMenu(_50b3ca, cx, cy, _debc26, _b578d6, "[ANIM]", {0, 1, 1})
                
                local _feea06 = os.clock()
                if imgui.IsMouseClicked(0) and (_feea06 - _92bdec) > _368e88 then
                    _92bdec = _feea06
                    if centerHovered then
                        _8b5290[0] = false
                        _dc3998[0] = true
                        _f6e0cb = os.clock()
                    elseif hoveredSector >= 1 and hoveredSector <= 4 then
                        local _187cc0 = _a63521["CatSector"..hoveredSector]._06b88e or ""
                        if _187cc0 ~= "" and _187cc0 ~= "-" then
                            loadAnimForCategory(_187cc0)
                            if #_6ee295 > 0 then
                                _a458f3 = _187cc0
                                _8b5290[0] = false
                                _f34dd4[0] = true
                                _f6e0cb = os.clock()
                            else
                                sampAddChatMessage("{FF8800}[Radial] {FFFFFF}No animations _1f5cc0. Use /rcmdf to configure: ".._187cc0, -1)
                            end
                        end
                    end
                end
            end

            if _f34dd4[0] then
                local tp = totalAnimPages()
                local pga = getAnimPage(_841d29)
                local _debc26 = {}
                for i = 1, 4 do
                    if pga[i] then
                        _debc26[i] = { _ef82b4 = pga[i]._ef82b4, color = {0.54, 0.36, 0.76}, labelColor = 0xFFFFFFFF }
                    else
                        _debc26[i] = { _ef82b4 = "-", color = {0.4, 0.4, 0.4}, labelColor = 0x55FFFFFF }
                    end
                end
                
                local _37cc72 = "[" .. _a458f3 .. "]"
                local hoveredSector, centerHovered = drawPieMenu(_50b3ca, cx, cy, _debc26, _b578d6, _37cc72, {0, 1, 1})
                
                if tp > 1 then
                    local _ac3ac5 = 60
                    local _8db603 = 200  -- Distance from center
                    local _68f1b9 = 0.8
                    
                    local _77772f = cx - _8db603
                    local _a9ecbf = cy
                    local _a06f7e = _841d29 > 1
                    local _d83b0a = _a06f7e and (_68f1b9 * 220) or (_68f1b9 * 100)
                    local _f1c609 = _a06f7e and (_68f1b9 * 255) or (_68f1b9 * 80)
                    
                    _50b3ca:AddCircleFilled(
                        imgui.ImVec2(_77772f, _a9ecbf),
                        _ac3ac5 / 2,
                        math.floor(_d83b0a) * 0x01000000 + 0x00222222,
                        32
                    )
                    _50b3ca:AddCircle(
                        imgui.ImVec2(_77772f, _a9ecbf),
                        _ac3ac5 / 2,
                        math.floor(_f1c609) * 0x01000000 + 0x0088DDFF,
                        32,
                        2.5
                    )
                    
                    local _7cfef8 = _ac3ac5 * 0.3
                    local _79ea79 = math.floor(_f1c609) * 0x01000000 + 0x00FFFFFF
                    _50b3ca:AddTriangleFilled(
                        imgui.ImVec2(_77772f - _7cfef8/2, _a9ecbf),
                        imgui.ImVec2(_77772f + _7cfef8/2, _a9ecbf - _7cfef8/2),
                        imgui.ImVec2(_77772f + _7cfef8/2, _a9ecbf + _7cfef8/2),
                        _79ea79
                    )
                    
                    local _43b8d1 = cx + _8db603
                    local _587b7b = cy
                    local _8f8ad6 = _841d29 < tp
                    local _c0abe2 = _8f8ad6 and (_68f1b9 * 220) or (_68f1b9 * 100)
                    local _c10fc3 = _8f8ad6 and (_68f1b9 * 255) or (_68f1b9 * 80)
                    
                    _50b3ca:AddCircleFilled(
                        imgui.ImVec2(_43b8d1, _587b7b),
                        _ac3ac5 / 2,
                        math.floor(_c0abe2) * 0x01000000 + 0x00222222,
                        32
                    )
                    _50b3ca:AddCircle(
                        imgui.ImVec2(_43b8d1, _587b7b),
                        _ac3ac5 / 2,
                        math.floor(_c10fc3) * 0x01000000 + 0x0088DDFF,
                        32,
                        2.5
                    )
                    
                    local _9a73a6 = math.floor(_c10fc3) * 0x01000000 + 0x00FFFFFF
                    _50b3ca:AddTriangleFilled(
                        imgui.ImVec2(_43b8d1 + _7cfef8/2, _587b7b),
                        imgui.ImVec2(_43b8d1 - _7cfef8/2, _587b7b - _7cfef8/2),
                        imgui.ImVec2(_43b8d1 - _7cfef8/2, _587b7b + _7cfef8/2),
                        _9a73a6
                    )
                    
                    local _f0d81c = "Page " .. _841d29 .. "/" .. tp
                    local _057ea4 = imgui.CalcTextSize(_f0d81c)
                    _50b3ca:AddText(
                        imgui.ImVec2(cx - _057ea4.x/2, cy + 170),
                        0xFFFFFFFF,
                        _f0d81c
                    )
                end
                
                local _feea06 = os.clock()
                if imgui.IsMouseClicked(0) and (_feea06 - _92bdec) > _368e88 then
                    _92bdec = _feea06
                    if centerHovered then
                        closeAllRadial()
                    elseif hoveredSector >= 1 and hoveredSector <= 4 and pga[hoveredSector] then
                        executeCommand(pga[hoveredSector].cmd)
                        closeAllRadial()
                    else
                        if tp > 1 then
                            local mouseX, mouseY = imgui.GetMousePos().x, imgui.GetMousePos().y
                            local _ac3ac5 = 60
                            local _8db603 = 200
                            local _77772f = cx - _8db603
                            local _a9ecbf = cy
                            local _43b8d1 = cx + _8db603
                            local _587b7b = cy
                            
                            local _e6903f = math.sqrt((mouseX - _77772f)^2 + (mouseY - _a9ecbf)^2)
                            if _e6903f < _ac3ac5/2 and _841d29 > 1 then
                                _841d29 = _841d29 - 1
                            end
                            
                            local _514c2d = math.sqrt((mouseX - _43b8d1)^2 + (mouseY - _587b7b)^2)
                            if _514c2d < _ac3ac5/2 and _841d29 < tp then
                                _841d29 = _841d29 + 1
                            end
                        end
                    end
                end
            end
            
            imgui.End()
            imgui.PopStyleColor(2)
            imgui.PopStyleVar(2)
        end
    end)

    while true do wait(100) end
end
