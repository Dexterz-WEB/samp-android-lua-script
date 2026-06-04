-- ============================================================================
-- SYSTEM DEPENDENCIES & INI CONFIG
-- ============================================================================
local imgui  = require 'mimgui'
local inicfg = require 'inicfg'

local iniFileName = "RadialMenuConfig.ini"

-- ============================================================================
-- DEFAULT STRUCTURE: Configure via /rcmdf (single command with tabs)
-- ============================================================================
local defaultStructure = {
    ButtonSettings = { posX = 1100.0, posY = 140.0 },
    Sector1 = { name = "VEHICLE", cmd = "" },
    Sector2 = { name = "-",       cmd = "" },
    Sector3 = { name = "ANIM",    cmd = "" },
    Sector4 = { name = "-",       cmd = "" },
    CatSector1 = { name = "" }, CatSector2 = { name = "" },
    CatSector3 = { name = "" }, CatSector4 = { name = "" },
    VehCatSector1 = { name = "" }, VehCatSector2 = { name = "" },
    VehCatSector3 = { name = "" }, VehCatSector4 = { name = "" },
}
for i = 1, 21 do
    defaultStructure["Anim"..i] = { label = "", cmd = "", category = "" }
    defaultStructure["Veh"..i]  = { label = "", cmd = "", category = "" }
end

local iniData = inicfg.load(defaultStructure, iniFileName)
if not iniData then
    inicfg.save(defaultStructure, iniFileName)
    iniData = defaultStructure
end
for k, v in pairs(defaultStructure) do
    if not iniData[k] then iniData[k] = v end
end

-- ============================================================================
-- STATE VARIABLES
-- ============================================================================
local showRadialMenu   = imgui.new.bool(false)
local showConfigWindow = imgui.new.bool(false)
local showCatRadial    = imgui.new.bool(false)
local showAnimRadial   = imgui.new.bool(false)
local showVehCatRadial = imgui.new.bool(false)
local showVehRadial    = imgui.new.bool(false)

-- Config Window Tab State (1=Main, 2=Anim, 3=Vehicle)
local configTab = 1

local currentCategory    = ""
local animRadialPage     = 1
local animRadialList     = {}
local currentVehCategory = ""
local vehRadialPage      = 1
local vehRadialList      = {}

-- toggle state: key=category (lower), true=ON/OPEN aktif, false/nil=OFF/CLOSE
local toggleState = {}

-- Label yang dianggap tombol "ON" (aktifkan)
local ON_LABELS  = { on=true, open=true, hidup=true, nyala=true, start=true, buka=true }
-- Label yang dianggap tombol "OFF" (nonaktifkan)
local OFF_LABELS = { off=true, close=true, mati=true, stop=true, tutup=true }

function isOnLabel(lbl)
    if not lbl or lbl == "" then return false end
    return ON_LABELS[lbl:lower()] == true
end

function isOffLabel(lbl)
    if not lbl or lbl == "" then return false end
    return OFF_LABELS[lbl:lower()] == true
end

function isDummySlot(slot)
    if not slot then return true end
    local lbl = slot.label or ""
    local cmd = slot.cmd   or ""
    return lbl == "" or lbl == "-" or cmd == ""
end



local btnSliderX = imgui.new.float(iniData.ButtonSettings.posX or 1100.0)
local btnSliderY = imgui.new.float(iniData.ButtonSettings.posY or 140.0)

local editName = {
    imgui.new.char[32](iniData.Sector1.name or "VEHICLE"),
    imgui.new.char[32](iniData.Sector2.name or "HEAL"),
    imgui.new.char[32](iniData.Sector3.name or "ANIM"),
    imgui.new.char[32](iniData.Sector4.name or "LOCK"),
}
local editCmd = {
    imgui.new.char[64](iniData.Sector1.cmd or ""),
    imgui.new.char[64](iniData.Sector2.cmd or "/heal"),
    imgui.new.char[64](iniData.Sector3.cmd or "/anim"),
    imgui.new.char[64](iniData.Sector4.cmd or "/lock"),
}
local editCatName = {
    imgui.new.char[32](iniData.CatSector1.name or "Dance"),
    imgui.new.char[32](iniData.CatSector2.name or "Action"),
    imgui.new.char[32](iniData.CatSector3.name or "Gangs"),
    imgui.new.char[32](iniData.CatSector4.name or "Misc"),
}
local editVehCatName = {
    imgui.new.char[32](iniData.VehCatSector1.name or "Car"),
    imgui.new.char[32](iniData.VehCatSector2.name or "Bike"),
    imgui.new.char[32](iniData.VehCatSector3.name or "Boat"),
    imgui.new.char[32](iniData.VehCatSector4.name or "Air"),
}

local MAX_ANIM_SLOTS = 21
local animEditLabel, animEditCmd, animEditCategory = {}, {}, {}
for i = 1, MAX_ANIM_SLOTS do
    local s = iniData["Anim"..i] or { label="", cmd="", category="" }
    animEditLabel[i]    = imgui.new.char[64](s.label    or "")
    animEditCmd[i]      = imgui.new.char[128](s.cmd     or "")
    animEditCategory[i] = imgui.new.char[32](s.category or "")
end

local MAX_VEH_SLOTS = 21
local vehEditLabel, vehEditCmd, vehEditCategory = {}, {}, {}
for i = 1, MAX_VEH_SLOTS do
    local s = iniData["Veh"..i] or { label="", cmd="", category="" }
    vehEditLabel[i]    = imgui.new.char[64](s.label    or "")
    vehEditCmd[i]      = imgui.new.char[128](s.cmd     or "")
    vehEditCategory[i] = imgui.new.char[32](s.category or "")
end

-- ============================================================================
-- HELPERS
-- ============================================================================
function readCharBuffer(buf, maxSize)
    local r = {}
    for i = 0, maxSize-1 do
        local c = buf[i]
        if not c or c == 0 then break end
        r[#r+1] = string.char(c)
    end
    return table.concat(r)
end

local animList = {}
function rebuildAnimList()
    animList = {}
    for i = 1, MAX_ANIM_SLOTS do
        local e = iniData["Anim"..i]
        if e and e.label ~= "" and e.category ~= "" then
            animList[#animList+1] = { label=e.label, cmd=e.cmd or "", category=e.category }
        end
    end
end
rebuildAnimList()

function loadAnimForCategory(cat)
    animRadialList = {}
    for _, a in ipairs(animList) do
        if a.category:lower() == cat:lower() then animRadialList[#animRadialList+1] = a end
    end
    animRadialPage = 1
end

function getAnimPage(page)
    local s, r = (page-1)*4+1, {}
    for i = 0, 3 do r[i+1] = animRadialList[s+i] end
    return r
end

function totalAnimPages() return math.max(1, math.ceil(#animRadialList / 4)) end

local vehList = {}
function rebuildVehList()
    vehList = {}
    for i = 1, MAX_VEH_SLOTS do
        local e = iniData["Veh"..i]
        if e and e.label ~= "" and e.category ~= "" then
            vehList[#vehList+1] = { label=e.label, cmd=e.cmd or "", category=e.category }
        end
    end
end
rebuildVehList()

function loadVehForCategory(cat)
    vehRadialList = {}
    for _, v in ipairs(vehList) do
        if v.category:lower() == cat:lower() then vehRadialList[#vehRadialList+1] = v end
    end
    vehRadialPage = 1
end

function getVehPage(page)
    local s, r = (page-1)*4+1, {}
    for i = 0, 3 do r[i+1] = vehRadialList[s+i] end
    return r
end

function totalVehPages() return math.max(1, math.ceil(#vehRadialList / 4)) end

function closeAllRadial()
    showRadialMenu[0]   = false
    showCatRadial[0]    = false
    showAnimRadial[0]   = false
    showVehCatRadial[0] = false
    showVehRadial[0]    = false
end

function executeCommand(cmd)
    if cmd and cmd ~= "" and type(cmd) == "string" then 
        sampProcessChatInput(cmd)
        return true
    end
    return false
end

-- ============================================================================
-- SAVE
-- ============================================================================
function saveAllConfig()
    iniData.ButtonSettings.posX = btnSliderX[0]
    iniData.ButtonSettings.posY = btnSliderY[0]
    
    -- Save sectors & categories
    for i = 1, 4 do
        iniData["Sector"..i].name       = readCharBuffer(editName[i], 32)
        iniData["Sector"..i].cmd        = readCharBuffer(editCmd[i], 64)
        iniData["CatSector"..i].name    = readCharBuffer(editCatName[i], 32)
        iniData["VehCatSector"..i].name = readCharBuffer(editVehCatName[i], 32)
    end
    
    -- Save animations (only rebuild if changed)
    local animChanged = false
    for i = 1, MAX_ANIM_SLOTS do
        if not iniData["Anim"..i] then iniData["Anim"..i] = {} end
        local newLabel = readCharBuffer(animEditLabel[i], 64)
        local newCmd = readCharBuffer(animEditCmd[i], 128)
        local newCat = readCharBuffer(animEditCategory[i], 32)
        
        if iniData["Anim"..i].label ~= newLabel or 
           iniData["Anim"..i].cmd ~= newCmd or 
           iniData["Anim"..i].category ~= newCat then
            animChanged = true
        end
        
        iniData["Anim"..i].label = newLabel
        iniData["Anim"..i].cmd = newCmd
        iniData["Anim"..i].category = newCat
    end
    
    -- Save vehicles (only rebuild if changed)
    local vehChanged = false
    for i = 1, MAX_VEH_SLOTS do
        if not iniData["Veh"..i] then iniData["Veh"..i] = {} end
        local newLabel = readCharBuffer(vehEditLabel[i], 64)
        local newCmd = readCharBuffer(vehEditCmd[i], 128)
        local newCat = readCharBuffer(vehEditCategory[i], 32)
        
        if iniData["Veh"..i].label ~= newLabel or 
           iniData["Veh"..i].cmd ~= newCmd or 
           iniData["Veh"..i].category ~= newCat then
            vehChanged = true
        end
        
        iniData["Veh"..i].label = newLabel
        iniData["Veh"..i].cmd = newCmd
        iniData["Veh"..i].category = newCat
    end
    
    -- Save to file
    if inicfg.save(iniData, iniFileName) then
        if animChanged then rebuildAnimList() end
        if vehChanged then rebuildVehList() end
        sampAddChatMessage("{00FF00}[Radial Menu] {FFFFFF}Configuration saved!", -1)
        return true
    else
        sampAddChatMessage("{FF0000}[Radial Menu] {FFFFFF}Failed to save config!", -1)
        return false
    end
end

-- ============================================================================
-- DRAW RADIAL — label auto-center & auto-wrap
-- ============================================================================
local SECTOR_CENTERS = {
    { x =   0, y = -92 },
    { x =  92, y =   0 },
    { x =   0, y =  92 },
    { x = -92, y =   0 },
}

function drawLabelCentered(draw_list, text, cx, cy, color)
    local maxW = 78
    if not text or text == "" then text = "---"; color = 0x55FFFFFF end
    local ts = imgui.CalcTextSize(text)
    if ts.x <= maxW then
        draw_list:AddText(imgui.ImVec2(cx - ts.x * 0.5, cy - ts.y * 0.5), color, text)
    else
        local mid = math.floor(#text / 2)
        local split = mid
        for d = 0, mid do
            if text:sub(mid-d, mid-d) == " " then split = mid-d; break end
            if text:sub(mid+d, mid+d) == " " then split = mid+d; break end
        end
        local l1 = text:sub(1, split):match("^%s*(.-)%s*$")
        local l2 = text:sub(split+1):match("^%s*(.-)%s*$")
        local t1 = imgui.CalcTextSize(l1)
        local t2 = imgui.CalcTextSize(l2)
        draw_list:AddText(imgui.ImVec2(cx - t1.x*0.5, cy - t1.y), color, l1)
        draw_list:AddText(imgui.ImVec2(cx - t2.x*0.5, cy        ), color, l2)
    end
end

function drawRadialMenu(draw_list, centerX, centerY, labels, centerLabel, centerColor, winId, labelColors)
    local rO = 135
    local rI = 50
    draw_list:AddCircleFilled(imgui.ImVec2(centerX, centerY), rO, 0xDD151515, 64)
    draw_list:AddCircleFilled(imgui.ImVec2(centerX, centerY), rI, 0xFF222222, 64)

    local oi, oo = rI * 0.7071, rO * 0.7071
    draw_list:AddLine(imgui.ImVec2(centerX+oi, centerY-oi), imgui.ImVec2(centerX+oo, centerY-oo), 0x55FFFFFF, 1.0)
    draw_list:AddLine(imgui.ImVec2(centerX+oi, centerY+oi), imgui.ImVec2(centerX+oo, centerY+oo), 0x55FFFFFF, 1.0)
    draw_list:AddLine(imgui.ImVec2(centerX-oi, centerY+oi), imgui.ImVec2(centerX-oo, centerY+oo), 0x55FFFFFF, 1.0)
    draw_list:AddLine(imgui.ImVec2(centerX-oi, centerY-oi), imgui.ImVec2(centerX-oo, centerY-oo), 0x55FFFFFF, 1.0)

    for i, lbl in ipairs(labels) do
        local sc    = SECTOR_CENTERS[i]
        local color = (labelColors and labelColors[i]) or 0xFFFFFFFF
        drawLabelCentered(draw_list, lbl, centerX + sc.x, centerY + sc.y, color)
    end

    local cl  = centerLabel or ""
    local cts = imgui.CalcTextSize(cl)
    draw_list:AddText(imgui.ImVec2(centerX - cts.x*0.5, centerY - cts.y*0.5), centerColor or 0xFFFFFF00, cl)

    local pressed = nil
    imgui.SetCursorPos(imgui.ImVec2(110,  20)); if imgui.InvisibleButton("##top_"..winId,    imgui.ImVec2(120, 70)) then pressed = 1 end
    imgui.SetCursorPos(imgui.ImVec2( 20, 135)); if imgui.InvisibleButton("##left_"..winId,   imgui.ImVec2( 85, 70)) then pressed = 4 end
    imgui.SetCursorPos(imgui.ImVec2(125, 135)); if imgui.InvisibleButton("##center_"..winId, imgui.ImVec2( 90, 70)) then pressed = 5 end
    imgui.SetCursorPos(imgui.ImVec2(235, 135)); if imgui.InvisibleButton("##right_"..winId,  imgui.ImVec2( 85, 70)) then pressed = 2 end
    imgui.SetCursorPos(imgui.ImVec2(110, 250)); if imgui.InvisibleButton("##bottom_"..winId, imgui.ImVec2(120, 70)) then pressed = 3 end
    return pressed
end

-- ============================================================================
-- MAIN
-- ============================================================================
function main()
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Script loaded successfully!", -1)
    sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Use {FFFF00}/rcmdf{FFFFFF} to configure", -1)
    sampAddChatMessage("{00FFFF}[Radial Menu] {FFFFFF}Created by: {FFFF00}OnlyDexterZ", -1)

    -- Single command with optional tab parameter
    sampRegisterChatCommand("rcmdf", function(param)
        showConfigWindow[0] = not showConfigWindow[0]
        if param == "anim" or param == "2" then
            configTab = 2
        elseif param == "veh" or param == "vehicle" or param == "3" then
            configTab = 3
        else
            configTab = 1
        end
    end)

    imgui.OnFrame(function() return true end, function()
        local sw, sh    = getScreenResolution()
        local draw_list = imgui.GetBackgroundDrawList()
        local menuSize  = 340
        local cx        = sw / 2
        local cy        = sh / 2

        -- CONFIG PANEL WITH TABS
        if showConfigWindow[0] then
            imgui.SetNextWindowPos(imgui.ImVec2(50, sh/4), imgui.Cond.FirstUseEver)
            imgui.SetNextWindowSize(imgui.ImVec2(700, 580))
            imgui.Begin("Radial Menu Config", showConfigWindow)
            
            -- Tab Buttons
            if imgui.Button("1. MAIN", imgui.ImVec2(220, 35)) then configTab = 1 end
            imgui.SameLine()
            if imgui.Button("2. ANIM", imgui.ImVec2(220, 35)) then configTab = 2 end
            imgui.SameLine()
            if imgui.Button("3. VEHICLE", imgui.ImVec2(220, 35)) then configTab = 3 end
            
            imgui.Spacing(); imgui.Separator(); imgui.Spacing()
            
            -- TAB 1: MAIN CONFIG
            if configTab == 1 then
                imgui.TextColored(imgui.ImVec4(0,1,0,1), "--- BUTTON POSITION ---")
                if imgui.SliderFloat("X", btnSliderX, 0, sw-120, "%.0f")
                or imgui.SliderFloat("Y", btnSliderY, 0, sh-50,  "%.0f") then saveAllConfig() end

                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0,1,1,1), "--- MAIN SECTORS ---")
                for i = 1, 4 do
                    imgui.Text("Sector "..i..":"); imgui.SameLine()
                    imgui.SetNextItemWidth(120); imgui.InputText("Name##n"..i, editName[i], 32); imgui.SameLine()
                    if i == 1 or i == 3 then 
                        imgui.TextDisabled(i == 1 and "(vehicle menu)" or "(anim menu)")
                    else 
                        imgui.SetNextItemWidth(180); imgui.InputText("Cmd##c"..i, editCmd[i], 64) 
                    end
                end

                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(1,0.5,0,1), "--- ANIM CATEGORIES ---")
                for i = 1, 4 do
                    imgui.Text("Cat "..i..":"); imgui.SameLine()
                    imgui.SetNextItemWidth(200); imgui.InputText("##ca"..i, editCatName[i], 32)
                end

                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.3,0.8,1,1), "--- VEHICLE CATEGORIES ---")
                for i = 1, 4 do
                    imgui.Text("Cat "..i..":"); imgui.SameLine()
                    imgui.SetNextItemWidth(200); imgui.InputText("##cv"..i, editVehCatName[i], 32)
                end
            
            -- TAB 2: ANIMATIONS
            elseif configTab == 2 then
                imgui.TextColored(imgui.ImVec4(1,1,0,1), "Edit animations")
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                imgui.BeginChild("##animscroll", imgui.ImVec2(-1,-50), true)
                    for i = 1, MAX_ANIM_SLOTS do
                        imgui.Text(string.format("Slot%2d|", i)); imgui.SameLine()
                        imgui.SetNextItemWidth(110); imgui.InputText("Lbl##al"..i, animEditLabel[i], 64); imgui.SameLine()
                        imgui.SetNextItemWidth(240); imgui.InputText("Cmd##ac"..i, animEditCmd[i], 128); imgui.SameLine()
                        imgui.SetNextItemWidth(100); imgui.InputText("Cat##ak"..i, animEditCategory[i], 32)
                    end
                imgui.EndChild()
            
            -- TAB 3: VEHICLES
            elseif configTab == 3 then
                imgui.TextColored(imgui.ImVec4(0.3,0.8,1,1), "Edit vehicles")
                imgui.Spacing(); imgui.Separator(); imgui.Spacing()
                imgui.BeginChild("##vehscroll", imgui.ImVec2(-1,-50), true)
                    for i = 1, MAX_VEH_SLOTS do
                        imgui.Text(string.format("Slot%2d|", i)); imgui.SameLine()
                        imgui.SetNextItemWidth(110); imgui.InputText("Lbl##vl"..i, vehEditLabel[i], 64); imgui.SameLine()
                        imgui.SetNextItemWidth(240); imgui.InputText("Cmd##vc"..i, vehEditCmd[i], 128); imgui.SameLine()
                        imgui.SetNextItemWidth(100); imgui.InputText("Cat##vk"..i, vehEditCategory[i], 32)
                    end
                imgui.EndChild()
            end
            
            imgui.Spacing(); imgui.Separator(); imgui.Spacing()
            if imgui.Button("SAVE ALL", imgui.ImVec2(-1, 35)) then
                saveAllConfig()
            end
            
            imgui.End()
        end

        -- TOMBOL MENU
        imgui.SetNextWindowPos(imgui.ImVec2(btnSliderX[0], btnSliderY[0]), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(120, 60))
        imgui.Begin("RadialBtn", nil,
            imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoBackground)
            if imgui.Button("MENU", imgui.ImVec2(100, 40)) then
                local anyOpen = showRadialMenu[0] or showCatRadial[0] or showAnimRadial[0]
                              or showVehCatRadial[0] or showVehRadial[0]
                if anyOpen then
                    closeAllRadial()
                else
                    showRadialMenu[0] = true
                end
            end
        imgui.End()

        -- Helper: render radial tanpa animasi
        local function renderWithScale(key, showFlag)
            if not showFlag or not showFlag[0] then return false end
            imgui.SetNextWindowPos(imgui.ImVec2(cx - menuSize/2, cy - menuSize/2), imgui.Cond.Always)
            imgui.SetNextWindowSize(imgui.ImVec2(menuSize, menuSize))
            return true, 1
        end

        -- LEVEL 1: RADIAL UTAMA
        do
            local s
            local ok; ok, s = renderWithScale("main", showRadialMenu)
            if ok then
                imgui.Begin("RadialMain", nil,
                    imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoBackground)
                    if s > 0.3 then  -- jangan register klik saat animasi belum keliatan
                        local lbls = {
                            tostring(iniData.Sector1.name), tostring(iniData.Sector2.name),
                            tostring(iniData.Sector3.name), tostring(iniData.Sector4.name),
                        }
                        local p = drawRadialMenu(draw_list, cx, cy, lbls, "CLOSE", 0xFFFFFF00, "main")
                        if     p == 1 then showRadialMenu[0] = false; showVehCatRadial[0] = true
                        elseif p == 2 then 
                            local cmd = tostring(iniData.Sector2.cmd or "")
                            if executeCommand(cmd) then closeAllRadial() end
                        elseif p == 3 then showRadialMenu[0] = false; showCatRadial[0] = true
                        elseif p == 4 then 
                            local cmd = tostring(iniData.Sector4.cmd or "")
                            if executeCommand(cmd) then closeAllRadial() end
                        elseif p == 5 then showRadialMenu[0] = false end
                    end
                imgui.End()
            end
        end

        -- LEVEL 2a: CATEGORY ANIM
        do
            local s
            local ok; ok, s = renderWithScale("cat", showCatRadial)
            if ok then
                imgui.Begin("RadialCat", nil,
                    imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoBackground)
                    if s > 0.3 then
                        local cats = {
                            tostring(iniData.CatSector1.name), tostring(iniData.CatSector2.name),
                            tostring(iniData.CatSector3.name), tostring(iniData.CatSector4.name),
                        }
                        local p = drawRadialMenu(draw_list, cx, cy, cats, "BACK", 0xFF00FFFF, "cat")
                        if p and p >= 1 and p <= 4 then
                            local sectorName = tostring(lbls[p] or "")
                            if sectorName ~= "" and sectorName ~= "-" then
                                loadAnimForCategory(sectorName)
                                if #animRadialList > 0 then
                                    currentCategory = sectorName
                                    showCatRadial[0] = false
                                    showAnimRadial[0] = true
                                else
                                    sampAddChatMessage("{FF8800}[Radial] {FFFFFF}No animations found. Use /rcmdf to configure: "..sectorName, -1)
                                end
                            end
                        elseif p == 5 then
                            showCatRadial[0] = false
                            showRadialMenu[0] = true
                        end
                    end
                imgui.End()
            end
        end

        -- LEVEL 3a: ANIM
        do
            local s
            local ok; ok, s = renderWithScale("anim", showAnimRadial)
            if ok then
                imgui.Begin("RadialAnim", nil,
                    imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoBackground)
                    if s > 0.3 then
                        local tp  = totalAnimPages()
                        local pga = getAnimPage(animRadialPage)
                        local al  = {}
                        for i = 1, 4 do al[i] = pga[i] and pga[i].label or nil end
                        local cl, cc = "BACK", 0xFF00FFFF
                        if tp > 1 then cl = animRadialPage < tp and "NEXT" or "PREV"; cc = 0xFF00FF88 end
                        draw_list:AddText(imgui.ImVec2(cx-30, cy+110), 0xAAFFFFFF, string.format("Hal %d/%d", animRadialPage, tp))
                        draw_list:AddText(imgui.ImVec2(cx-40, cy-120), 0xFF00FFFF, "["..currentCategory.."]")
                        local p = drawRadialMenu(draw_list, cx, cy, al, cl, cc, "anim")
                        for i = 1, 4 do
                            if p == i and pga[i] then executeCommand(pga[i].cmd); closeAllRadial() end
                        end
                        if p == 5 then
                            if tp <= 1 then
                                showAnimRadial[0] = false
                                showCatRadial[0] = true
                            elseif animRadialPage < tp then animRadialPage = animRadialPage + 1
                            else animRadialPage = animRadialPage - 1 end
                        end
                    end
                imgui.End()
            end
        end

        -- LEVEL 2b: CATEGORY VEHICLE
        do
            local s
            local ok; ok, s = renderWithScale("vehcat", showVehCatRadial)
            if ok then
                imgui.Begin("RadialVehCat", nil,
                    imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoBackground)
                    if s > 0.3 then
                        local vcats = {
                            tostring(iniData.VehCatSector1.name), tostring(iniData.VehCatSector2.name),
                            tostring(iniData.VehCatSector3.name), tostring(iniData.VehCatSector4.name),
                        }
                        draw_list:AddText(imgui.ImVec2(cx-40, cy-120), 0xFF88DDFF, "[VEHICLE]")
                        local p = drawRadialMenu(draw_list, cx, cy, vcats, "BACK", 0xFF88DDFF, "vehcat")
                        if p and p >= 1 and p <= 4 then
                            local sectorName = tostring(vcats[p] or "")
                            if sectorName ~= "" and sectorName ~= "-" then
                                loadVehForCategory(sectorName)
                                if #vehRadialList > 0 then
                                    currentVehCategory = sectorName
                                    showVehCatRadial[0] = false
                                    showVehRadial[0] = true
                                else
                                    sampAddChatMessage("{FF8800}[Radial] {FFFFFF}No vehicles found. Use /rcmdf to configure: "..sectorName, -1)
                                end
                            end
                        elseif p == 5 then
                            showVehCatRadial[0] = false
                            showRadialMenu[0] = true
                        end
                    end
                imgui.End()
            end
        end

        -- LEVEL 3b: VEHICLE
        do
            local s
            local ok; ok, s = renderWithScale("veh", showVehRadial)
            if ok then
                imgui.Begin("RadialVeh", nil,
                    imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoBackground)
                    if s > 0.3 then
                local tp  = totalVehPages()
                local pgv = getVehPage(vehRadialPage)
                local cl, cc = "BACK", 0xFF88DDFF
                if tp > 1 then cl = vehRadialPage < tp and "NEXT" or "PREV"; cc = 0xFF44BBFF end
                draw_list:AddText(imgui.ImVec2(cx-30, cy+110), 0xAAFFFFFF, string.format("Hal %d/%d", vehRadialPage, tp))
                draw_list:AddText(imgui.ImVec2(cx-40, cy-120), 0xFF88DDFF, "["..currentVehCategory.."]")

                -- Hitung warna & disabled state tiap slot
                local vlColors   = {}
                local vlDisabled = {}  -- true = beneran disabled, ga bisa dipencet
                for i = 1, 4 do
                    local slot = pgv[i]
                    if isDummySlot(slot) then
                        vlColors[i]   = 0x33FFFFFF
                        vlDisabled[i] = true
                    else
                        local cat   = (slot.category or ""):lower()
                        local lbl   = slot.label or ""
                        local isOn  = toggleState[cat]  -- true = kondisi aktif/ON

                        if isOnLabel(lbl) then
                            -- Tombol ON: disabled kalau state sudah ON
                            if isOn then
                                vlColors[i]   = 0x33FFFFFF  -- grey
                                vlDisabled[i] = true
                            else
                                vlColors[i]   = 0xFF44FF44  -- hijau = bisa dipencet
                                vlDisabled[i] = false
                            end
                        elseif isOffLabel(lbl) then
                            -- Tombol OFF: disabled kalau state masih OFF
                            if not isOn then
                                vlColors[i]   = 0x33FFFFFF  -- grey
                                vlDisabled[i] = true
                            else
                                vlColors[i]   = 0xFFFF4444  -- merah = bisa dipencet
                                vlDisabled[i] = false
                            end
                        else
                            -- Slot biasa (bukan ON/OFF pair) — selalu bisa dipencet
                            vlColors[i]   = 0xFFFFFFFF
                            vlDisabled[i] = false
                        end
                    end
                end

                -- Gambar label
                local vl = {}
                for i = 1, 4 do vl[i] = pgv[i] and not isDummySlot(pgv[i]) and pgv[i].label or nil end

                -- Gambar radial (tanpa invisible button dulu)
                local rO = 135
                local rI = 50
                draw_list:AddCircleFilled(imgui.ImVec2(cx, cy), rO, 0xDD151515, 64)
                draw_list:AddCircleFilled(imgui.ImVec2(cx, cy), rI, 0xFF222222, 64)
                local oi, oo = rI * 0.7071, rO * 0.7071
                draw_list:AddLine(imgui.ImVec2(cx+oi, cy-oi), imgui.ImVec2(cx+oo, cy-oo), 0x55FFFFFF, 1.0)
                draw_list:AddLine(imgui.ImVec2(cx+oi, cy+oi), imgui.ImVec2(cx+oo, cy+oo), 0x55FFFFFF, 1.0)
                draw_list:AddLine(imgui.ImVec2(cx-oi, cy+oi), imgui.ImVec2(cx-oo, cy+oo), 0x55FFFFFF, 1.0)
                draw_list:AddLine(imgui.ImVec2(cx-oi, cy-oi), imgui.ImVec2(cx-oo, cy-oo), 0x55FFFFFF, 1.0)

                for i = 1, 4 do
                    local sc  = SECTOR_CENTERS[i]
                    local lbl = vl[i]
                    drawLabelCentered(draw_list, lbl, cx + sc.x, cy + sc.y, vlColors[i])
                end

                -- Center label (BACK/NEXT/PREV)
                local cts = imgui.CalcTextSize(cl)
                draw_list:AddText(imgui.ImVec2(cx - cts.x*0.5, cy - cts.y*0.5), cc, cl)

                -- Invisible buttons — skip kalau disabled
                local sectorPos = {
                    { x=110, y= 20,  w=120, h=70 },  -- 1 atas
                    { x=235, y=135,  w= 85, h=70 },  -- 2 kanan
                    { x=110, y=250,  w=120, h=70 },  -- 3 bawah
                    { x= 20, y=135,  w= 85, h=70 },  -- 4 kiri
                }
                local pressed = nil
                for i = 1, 4 do
                    imgui.SetCursorPos(imgui.ImVec2(sectorPos[i].x, sectorPos[i].y))
                    if not vlDisabled[i] then
                        if imgui.InvisibleButton("##vs"..i.."_veh", imgui.ImVec2(sectorPos[i].w, sectorPos[i].h)) then
                            pressed = i
                        end
                    else
                        -- render dummy area (tidak clickable)
                        imgui.Dummy(imgui.ImVec2(sectorPos[i].w, sectorPos[i].h))
                    end
                end
                -- center button
                imgui.SetCursorPos(imgui.ImVec2(125, 135))
                if imgui.InvisibleButton("##vcenter_veh", imgui.ImVec2(90, 70)) then pressed = 5 end

                -- Handle klik
                for i = 1, 4 do
                    if pressed == i and pgv[i] and not vlDisabled[i] then
                        local slot = pgv[i]
                        local cat  = (slot.category or ""):lower()
                        local lbl  = slot.label or ""

                        executeCommand(slot.cmd)

                        if isOnLabel(lbl) then
                            toggleState[cat] = true
                        elseif isOffLabel(lbl) then
                            toggleState[cat] = false
                        end
                        closeAllRadial()
                    end
                end
                if pressed == 5 then
                    if tp <= 1 then
                        showVehRadial[0] = false
                        showVehCatRadial[0] = true
                    elseif vehRadialPage < tp then vehRadialPage = vehRadialPage + 1
                    else vehRadialPage = vehRadialPage - 1 end
                end
                    end  -- if s > 0.3
                imgui.End()
            end  -- if ok
        end  -- do

    end)

    while true do wait(100) end
end
