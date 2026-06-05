-- ============================================================================
-- NEAREST GIVE
-- Give items to nearest player with floating button + configurable format
-- Standalone test script - can be integrated to RadialMenu later
-- ============================================================================

script_name("Nearest Give")
script_author("OnlyDexterZ")

local imgui = require 'mimgui'
local inicfg = require 'inicfg'

local MAX_RANGE = 10.0

-- ============================================================================
-- CONFIG
-- ============================================================================
local configFile = "NearestGive.ini"
local defaultCfg = {
    Settings = {
        btnX = 50.0,
        btnY = 200.0,
        btnSize = 60.0,
        cmdFormat = "/give [id] [item] [amount]",
    },
}

local cfg = inicfg.load(defaultCfg, configFile)
if not cfg then
    inicfg.save(defaultCfg, configFile)
    cfg = defaultCfg
end
if not cfg.Settings then cfg.Settings = defaultCfg.Settings end

-- ============================================================================
-- STATE
-- ============================================================================
local showGiveDialog = imgui.new.bool(false)
local showConfigDialog = imgui.new.bool(false)
local inputItem = imgui.new.char[64]("")
local inputAmount = imgui.new.char[32]("")
local inputCmdFormat = imgui.new.char[128](cfg.Settings.cmdFormat or "/give [id] [item] [amount]")
local buf_btnX = imgui.new.float(cfg.Settings.btnX or 50.0)
local buf_btnY = imgui.new.float(cfg.Settings.btnY or 200.0)
local buf_btnSize = imgui.new.float(cfg.Settings.btnSize or 60.0)

local lastNearestId = -1
local lastNearestName = "Unknown"
local lastNearestDist = 9999

-- ============================================================================
-- GET NEAREST PLAYER
-- ============================================================================
function getNearestPlayer()
    local myX, myY, myZ
    local ok1 = pcall(function()
        myX, myY, myZ = getCharCoordinates(PLAYER_PED)
    end)
    if not ok1 or not myX then return -1, 9999, "Unknown" end

    local nearestId = -1
    local nearestDist = 9999
    local nearestName = "Unknown"

    local maxId = 0
    pcall(function() maxId = sampGetMaxPlayerId() end)

    local myId = 0
    pcall(function() myId = sampGetLocalPlayerId() end)

    for i = 0, maxId do
        if i ~= myId then
            local connected = false
            pcall(function() connected = sampIsPlayerConnected(i) end)

            if connected then
                local ok2, px, py, pz = pcall(function()
                    local result, ped = sampGetCharHandleBySampPlayerId(i)
                    if result and ped then
                        local x, y, z = getCharCoordinates(ped)
                        return x, y, z
                    end
                    return nil, nil, nil
                end)

                if ok2 and px then
                    local dist = math.sqrt((px - myX)^2 + (py - myY)^2 + (pz - myZ)^2)
                    if dist < nearestDist then
                        nearestDist = dist
                        nearestId = i
                        pcall(function()
                            nearestName = sampGetPlayerNickname(i)
                        end)
                    end
                end
            end
        end
    end

    return nearestId, nearestDist, nearestName
end

-- ============================================================================
-- BUILD COMMAND FROM FORMAT
-- ============================================================================
function buildCommand(format, id, item, amount)
    local cmd = format
    cmd = cmd:gsub("%[id%]", tostring(id))
    cmd = cmd:gsub("%[item%]", tostring(item))
    cmd = cmd:gsub("%[amount%]", tostring(amount))
    return cmd
end

-- ============================================================================
-- HELPER: readCharBuffer
-- ============================================================================
function readCharBuffer(buf, maxSize)
    local r = {}
    for i = 0, maxSize - 1 do
        local c = buf[i]
        if not c or c == 0 then break end
        r[#r + 1] = string.char(c)
    end
    return table.concat(r)
end

-- ============================================================================
-- RENDER
-- ============================================================================
imgui.OnFrame(function() return true end, function()
    local spawned = false
    pcall(function() spawned = sampIsLocalPlayerSpawned() end)
    if not spawned then return end

    local sw, sh = getScreenResolution()
    local dl = imgui.GetBackgroundDrawList()

    -- ========================================================================
    -- FLOATING BUTTON (always visible, unless dialogs open)
    -- ========================================================================
    if not showGiveDialog[0] and not showConfigDialog[0] then
        local bx = buf_btnX[0]
        local by = buf_btnY[0]
        local bs = buf_btnSize[0]
        local bsHalf = bs / 2

        -- Button background
        dl:AddCircleFilled(imgui.ImVec2(bx + bsHalf, by + bsHalf), bsHalf, 0xDD222222, 16)
        -- Border
        dl:AddCircle(imgui.ImVec2(bx + bsHalf, by + bsHalf), bsHalf, 0xFF44FF44, 16, 2.0)
        -- "G" text (Give)
        local gText = "G"
        local gSize = imgui.CalcTextSize(gText)
        dl:AddText(imgui.ImVec2(bx + bsHalf - gSize.x / 2, by + bsHalf - gSize.y / 2), 0xFF44FF44, gText)
        -- "GIVE" label below
        dl:AddText(imgui.ImVec2(bx + bsHalf - 14, by + bs + 3), 0xFFAAAAAA, "GIVE")

        -- Touch handler
        imgui.SetNextWindowPos(imgui.ImVec2(bx, by), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(bs, bs))
        imgui.Begin("##GiveBtn", nil,
            imgui.WindowFlags.NoTitleBar +
            imgui.WindowFlags.NoResize +
            imgui.WindowFlags.NoBackground +
            imgui.WindowFlags.NoScrollbar)

            if imgui.InvisibleButton("##give_tap", imgui.ImVec2(bs - 5, bs - 5)) then
                -- Detect nearest player first
                lastNearestId, lastNearestDist, lastNearestName = getNearestPlayer()
                showGiveDialog[0] = true
            end

        imgui.End()
    end

    -- ========================================================================
    -- GIVE DIALOG (input item + amount)
    -- ========================================================================
    if showGiveDialog[0] then
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2 - 200, sh / 2 - 120), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(400, 240))
        imgui.Begin("Give to Nearest", showGiveDialog, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)

        -- Show nearest player info
        if lastNearestId >= 0 and lastNearestDist <= MAX_RANGE then
            imgui.TextColored(imgui.ImVec4(0, 1, 0, 1), "Nearest Player:")
            imgui.SameLine()
            imgui.TextColored(imgui.ImVec4(1, 1, 0, 1), lastNearestName .. " (ID:" .. lastNearestId .. ")")
            imgui.Text("Distance: " .. string.format("%.1f", lastNearestDist) .. "m")
        elseif lastNearestId >= 0 then
            imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), "Nearest player too far!")
            imgui.Text(lastNearestName .. " (ID:" .. lastNearestId .. ") - " .. string.format("%.1f", lastNearestDist) .. "m")
        else
            imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), "No players nearby!")
        end

        imgui.Spacing(); imgui.Separator(); imgui.Spacing()

        -- Input fields
        imgui.Text("Item:")
        imgui.SetNextItemWidth(-1)
        imgui.InputText("##item", inputItem, 64)

        imgui.Spacing()
        imgui.Text("Amount:")
        imgui.SetNextItemWidth(-1)
        imgui.InputText("##amount", inputAmount, 32)

        imgui.Spacing(); imgui.Separator(); imgui.Spacing()

        -- Buttons
        local canGive = lastNearestId >= 0 and lastNearestDist <= MAX_RANGE
        if canGive then
            if imgui.Button("GIVE", imgui.ImVec2(185, 35)) then
                local item = readCharBuffer(inputItem, 64)
                local amount = readCharBuffer(inputAmount, 32)
                local format = readCharBuffer(inputCmdFormat, 128)

                if item ~= "" and amount ~= "" then
                    local cmd = buildCommand(format, lastNearestId, item, amount)
                    sampProcessChatInput(cmd)
                    sampAddChatMessage("{00FF00}[Give] {FFFFFF}Sent: " .. cmd, -1)
                    showGiveDialog[0] = false
                    -- Clear inputs
                    for i = 0, 63 do inputItem[i] = 0 end
                    for i = 0, 31 do inputAmount[i] = 0 end
                else
                    sampAddChatMessage("{FF0000}[Give] {FFFFFF}Fill in item and amount!", -1)
                end
            end
        else
            imgui.TextColored(imgui.ImVec4(1, 0.5, 0, 1), "Cannot give - no player in range")
        end

        imgui.SameLine()
        if imgui.Button("CANCEL", imgui.ImVec2(185, 35)) then
            showGiveDialog[0] = false
        end

        imgui.End()
    end

    -- ========================================================================
    -- CONFIG DIALOG
    -- ========================================================================
    if showConfigDialog[0] then
        imgui.SetNextWindowPos(imgui.ImVec2(50, 50), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(400, 300))
        imgui.Begin("NearestGive Config", showConfigDialog)

        imgui.TextColored(imgui.ImVec4(0, 1, 1, 1), "--- BUTTON POSITION ---")
        imgui.SliderFloat("X", buf_btnX, 0, sw - 100, "%.0f")
        imgui.SliderFloat("Y", buf_btnY, 0, sh - 100, "%.0f")
        imgui.SliderFloat("Size", buf_btnSize, 40, 100, "%.0f")

        imgui.Spacing(); imgui.Separator(); imgui.Spacing()

        imgui.TextColored(imgui.ImVec4(1, 1, 0, 1), "--- COMMAND FORMAT ---")
        imgui.TextDisabled("Use [id], [item], [amount] as placeholders")
        imgui.SetNextItemWidth(-1)
        imgui.InputText("##cmdfmt", inputCmdFormat, 128)
        imgui.TextDisabled("Example: /give [id] [item] [amount]")
        imgui.TextDisabled("Example: /giveitem [id] [amount]")

        imgui.Spacing(); imgui.Separator(); imgui.Spacing()

        if imgui.Button("SAVE", imgui.ImVec2(-1, 35)) then
            cfg.Settings.btnX = buf_btnX[0]
            cfg.Settings.btnY = buf_btnY[0]
            cfg.Settings.btnSize = buf_btnSize[0]
            cfg.Settings.cmdFormat = readCharBuffer(inputCmdFormat, 128)
            inicfg.save(cfg, configFile)
            sampAddChatMessage("{00FF00}[NearestGive] {FFFFFF}Config saved!", -1)
        end

        imgui.End()
    end
end)

-- ============================================================================
-- MAIN
-- ============================================================================
function main()
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("{00FFFF}[NearestGive] {FFFFFF}Loaded! Tap the G button to give items", -1)
    sampAddChatMessage("{00FFFF}[NearestGive] {FFFFFF}Use {FFFF00}/ngcfg{FFFFFF} to configure", -1)

    sampRegisterChatCommand("ngcfg", function()
        showConfigDialog[0] = not showConfigDialog[0]
    end)

    wait(-1)
end
