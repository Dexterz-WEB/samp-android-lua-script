-- ============================================================================
-- CONFIG WINDOW REDESIGN (TEST)
-- Clean redesign of /rcmdf config window for Android
-- Standalone test - NOT modifying RadialMenu.lua
-- If this works, can be merged into RadialMenu later
-- ============================================================================

script_name("Config Window Redesign")
script_author("OnlyDexterZ")

local imgui = require 'mimgui'

-- ============================================================================
-- STATE
-- ============================================================================
local showWindow = imgui.new.bool(false)
local currentTab = 1

local buf_posX = imgui.new.float(100)
local buf_posY = imgui.new.float(300)
local buf_size = imgui.new.float(80)
local buf_opacity = imgui.new.float(0.8)

-- Vehicle context buffers
local vehNames, vehOn, vehOff = {}, {}, {}
for i = 1, 4 do
    vehNames[i] = imgui.new.char[32](i == 1 and "ENGINE" or (i == 2 and "LOCK" or (i == 3 and "LIGHT" or "-")))
    vehOn[i] = imgui.new.char[64](i == 1 and "/engine" or (i == 2 and "/lock" or (i == 3 and "/lights" or "")))
    vehOff[i] = imgui.new.char[64](i == 1 and "/engine" or (i == 2 and "/unlock" or (i == 3 and "/lights" or "")))
end

-- Foot context buffers
local footNames, footOn, footOff = {}, {}, {}
for i = 1, 4 do
    footNames[i] = imgui.new.char[32](i == 1 and "LOCK" or (i == 2 and "TRUNK" or (i == 3 and "HOOD" or "-")))
    footOn[i] = imgui.new.char[64](i == 1 and "/lock" or (i == 2 and "/trunk" or (i == 3 and "/hood" or "")))
    footOff[i] = imgui.new.char[64](i == 1 and "/unlock" or (i == 2 and "/trunk" or (i == 3 and "/hood" or "")))
end

-- Anim buffers
local animCat, animCmd, animLbl = {}, {}, {}
for i = 1, 8 do
    animCat[i] = imgui.new.char[32]("")
    animCmd[i] = imgui.new.char[64]("")
    animLbl[i] = imgui.new.char[32]("")
end

-- ============================================================================
-- RENDER
-- ============================================================================
imgui.OnFrame(function() return showWindow[0] end, function()
    local sw, sh = getScreenResolution()

    -- Adaptive window size per tab
    local winW = 500
    local winH = 250  -- default for MAIN tab
    if currentTab == 2 then winH = 380 end  -- ANIM (more rows)
    if currentTab == 3 then winH = 400 end  -- VEHICLE (2 sections)
    if currentTab == 4 then winH = 280 end  -- PROFILE
    
    -- Clean modern styling (CORRECT function names for MonetLoader mimgui!)
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12)
    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(15, 12))
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 6)
    imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(8, 6))
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.08, 0.08, 0.1, 0.95))
    imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.15, 0.15, 0.2, 1.0))
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.2, 0.3, 1.0))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.3, 0.3, 0.5, 1.0))
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.15, 0.4, 0.8, 1.0))
    
    imgui.SetNextWindowPos(imgui.ImVec2((sw - winW) / 2, (sh - winH) / 2), imgui.Cond.Always)
    imgui.SetNextWindowSize(imgui.ImVec2(winW, winH))
    imgui.Begin("Radial Menu Config v2", showWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar)

    -- ========================================================================
    -- TAB BAR (compact buttons)
    -- ========================================================================
    local tabW = (winW - 30) / 4
    local tabH = 30

    local tabLabels = {"1.MAIN", "2.ANIM", "3.VEH", "4.PROF"}
    for t = 1, 4 do
        local label = tabLabels[t]
        if currentTab == t then label = "> " .. label .. " <" end
        if imgui.Button(label, imgui.ImVec2(tabW, tabH)) then currentTab = t end
        if t < 4 then imgui.SameLine() end
    end

    imgui.Spacing(); imgui.Separator(); imgui.Spacing()

    -- ========================================================================
    -- TAB CONTENT (no scroll - compact fit)
    -- ========================================================================

    -- ====================================================================
    -- TAB 1: MAIN
    -- ====================================================================
    if currentTab == 1 then
        imgui.TextColored(imgui.ImVec4(0.2, 0.9, 0.4, 1), "HAMBURGER BUTTON")
        imgui.Spacing()
        imgui.Text("Position X:"); imgui.SetNextItemWidth(-1)
        imgui.SliderFloat("##posX", buf_posX, 0, sw - 100, "%.0f")
        imgui.Text("Position Y:"); imgui.SetNextItemWidth(-1)
        imgui.SliderFloat("##posY", buf_posY, 0, sh - 100, "%.0f")
        imgui.Spacing()
        imgui.Text("Size:"); imgui.SetNextItemWidth(-1)
        imgui.SliderFloat("##size", buf_size, 50, 150, "%.0f")
        imgui.Text("Opacity:"); imgui.SetNextItemWidth(-1)
        imgui.SliderFloat("##opacity", buf_opacity, 0.3, 1.0, "%.2f")

    -- ====================================================================
    -- TAB 2: ANIM
    -- ====================================================================
    elseif currentTab == 2 then
        imgui.TextColored(imgui.ImVec4(0.9, 0.7, 0.1, 1), "ANIMATION COMMANDS")
        imgui.Spacing()
        -- Header (locked)
        imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Category"); imgui.SameLine(130)
        imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Label"); imgui.SameLine(260)
        imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Command")
        imgui.Separator(); imgui.Spacing()
        -- Rows (configurable)
        for i = 1, 8 do
            imgui.PushItemWidth(100); imgui.InputText("##ac"..i, animCat[i], 32); imgui.PopItemWidth()
            imgui.SameLine(130)
            imgui.PushItemWidth(100); imgui.InputText("##al"..i, animLbl[i], 32); imgui.PopItemWidth()
            imgui.SameLine(260)
            imgui.PushItemWidth(-1); imgui.InputText("##acmd"..i, animCmd[i], 64); imgui.PopItemWidth()
        end

    -- ====================================================================
    -- TAB 3: VEHICLE
    -- ====================================================================
    elseif currentTab == 3 then
        -- IN-VEHICLE
        imgui.TextColored(imgui.ImVec4(0.2, 0.6, 1.0, 1), "IN-VEHICLE COMMANDS")
        imgui.Spacing()
        imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Category"); imgui.SameLine(130)
        imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "ON Cmd"); imgui.SameLine(310)
        imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "OFF Cmd")
        imgui.Separator(); imgui.Spacing()
        for i = 1, 4 do
            imgui.PushItemWidth(100); imgui.InputText("##vn"..i, vehNames[i], 32); imgui.PopItemWidth()
            imgui.SameLine(130)
            imgui.PushItemWidth(150); imgui.InputText("##vo"..i, vehOn[i], 64); imgui.PopItemWidth()
            imgui.SameLine(310)
            imgui.PushItemWidth(-1); imgui.InputText("##vf"..i, vehOff[i], 64); imgui.PopItemWidth()
        end

        imgui.Spacing(); imgui.Separator(); imgui.Spacing()

        -- ON-FOOT
        imgui.TextColored(imgui.ImVec4(0.2, 0.6, 1.0, 1), "ON-FOOT COMMANDS")
        imgui.Spacing()
        imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Category"); imgui.SameLine(130)
        imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "ON Cmd"); imgui.SameLine(310)
        imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "OFF Cmd")
        imgui.Separator(); imgui.Spacing()
        for i = 1, 4 do
            imgui.PushItemWidth(100); imgui.InputText("##fn"..i, footNames[i], 32); imgui.PopItemWidth()
            imgui.SameLine(130)
            imgui.PushItemWidth(150); imgui.InputText("##fo"..i, footOn[i], 64); imgui.PopItemWidth()
            imgui.SameLine(310)
            imgui.PushItemWidth(-1); imgui.InputText("##ff"..i, footOff[i], 64); imgui.PopItemWidth()
        end

    -- ====================================================================
    -- TAB 4: PROFILE
    -- ====================================================================
    elseif currentTab == 4 then
        imgui.TextColored(imgui.ImVec4(0.8, 0.3, 0.8, 1), "PROFILE MANAGEMENT")
        imgui.Spacing()
        imgui.Text("Current Profile:"); imgui.SameLine()
        imgui.TextColored(imgui.ImVec4(1, 1, 0, 1), "default")
        imgui.Spacing(); imgui.Separator(); imgui.Spacing()
        imgui.TextDisabled("Profile management features here...")
    end

    -- ========================================================================
    -- BOTTOM: Save button
    -- ========================================================================
    imgui.Spacing()
    if imgui.Button("SAVE ALL", imgui.ImVec2(-1, 40)) then
        sampAddChatMessage("{00FF00}[Config] {FFFFFF}Settings saved!", -1)
    end

    imgui.End()
    imgui.PopStyleColor(5)
    imgui.PopStyleVar(4)
end)

-- ============================================================================
-- MAIN
-- ============================================================================
function main()
    while not isSampAvailable() do wait(100) end
    sampAddChatMessage("{00FFFF}[Config Redesign] {FFFFFF}Loaded! Use {FFFF00}/rcfg{FFFFFF} to open", -1)
    sampRegisterChatCommand("rcfg", function()
        showWindow[0] = not showWindow[0]
    end)
    wait(-1)
end
