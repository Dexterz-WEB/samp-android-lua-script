-- ============================================================================
-- CUSTOM DIALOG v1.0
-- Replaces default SA-MP dialogs with modern, minimalist dark-themed UI
-- Style: Minimalist (matching RadialMenu aesthetic)
-- ============================================================================

script_name("CostumDialog")
script_author("OnlyDexterZ")
script_version("1.0")

-- ============================================================================
-- SAFE LIBRARY LOADING
-- ============================================================================
local imgui = require 'mimgui'
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local ffi = require 'ffi'

local ease_loaded = false
local ease = nil
pcall(function()
    ease = require 'ease'
    ease_loaded = true
end)

local fa_loaded = false
local faicons = nil
pcall(function()
    faicons = require 'fAwesome6'
    fa_loaded = true
end)

local events_loaded = false
local events = nil
pcall(function()
    events = require 'lib.samp.events'
    events_loaded = true
end)

-- ============================================================================
-- CONSTANTS
-- ============================================================================
local DIALOG_STYLE_MSGBOX           = 0
local DIALOG_STYLE_INPUT            = 1
local DIALOG_STYLE_LIST             = 2
local DIALOG_STYLE_PASSWORD         = 3
local DIALOG_STYLE_TABLIST          = 4
local DIALOG_STYLE_TABLIST_HEADERS  = 5

-- ============================================================================
-- COLOR PALETTE (matching RadialMenu)
-- ============================================================================
local COLORS = {
    bg              = imgui.ImVec4(0.08, 0.08, 0.12, 0.95),
    border          = imgui.ImVec4(0.3, 0.6, 0.9, 0.5),
    borderGlow      = imgui.ImVec4(0.3, 0.6, 0.9, 0.3),
    title           = imgui.ImVec4(0.6, 0.8, 1.0, 1.0),
    text            = imgui.ImVec4(0.9, 0.9, 0.9, 1.0),
    textDim         = imgui.ImVec4(0.6, 0.6, 0.7, 1.0),
    button          = imgui.ImVec4(0.15, 0.15, 0.25, 0.8),
    buttonHover     = imgui.ImVec4(0.25, 0.4, 0.7, 0.8),
    buttonActive    = imgui.ImVec4(0.2, 0.35, 0.65, 0.9),
    closeBtn        = imgui.ImVec4(1.0, 0.4, 0.4, 1.0),
    closeBtnHover   = imgui.ImVec4(1.0, 0.6, 0.6, 1.0),
    inputBg         = imgui.ImVec4(0.06, 0.06, 0.10, 0.9),
    inputBorder     = imgui.ImVec4(0.3, 0.5, 0.8, 0.6),
    selectedItem    = imgui.ImVec4(0.2, 0.35, 0.6, 0.6),
    headerRow       = imgui.ImVec4(0.12, 0.14, 0.22, 0.9),
    separator       = imgui.ImVec4(0.3, 0.4, 0.6, 0.3),
    scrollbar       = imgui.ImVec4(0.3, 0.5, 0.8, 0.4),
    scrollbarGrab   = imgui.ImVec4(0.4, 0.6, 0.9, 0.6),
}

-- ============================================================================
-- DIALOG STATE
-- ============================================================================
local dialogState = {
    active = false,
    dialogId = 0,
    style = 0,
    title = "",
    button1 = "",
    button2 = "",
    text = "",
    inputText = imgui.new.char[256](""),
    selectedItem = 0,
    listItems = {},
    tabHeaders = {},
    tabRows = {},
    -- Animation
    openTime = 0,
    closeTime = 0,
    closing = false,
    scale = 0,
    alpha = 0,
    -- Keyboard
    keyboardOffset = 0,
    inputFocused = false,
}

local ANIM_DURATION_OPEN = 0.25
local ANIM_DURATION_CLOSE = 0.2

-- ============================================================================
-- EASING HELPER
-- ============================================================================
local function getEase(easeFunc, x)
    if ease_loaded and ease and ease[easeFunc] then
        return ease[easeFunc](x)
    end
    -- Fallback easing
    if easeFunc == "outBack" then
        local c1 = 1.70158
        local c3 = c1 + 1
        return 1 + c3 * (x - 1)^3 + c1 * (x - 1)^2
    elseif easeFunc == "inBack" then
        local c1 = 1.70158
        local c3 = c1 + 1
        return c3 * x^3 - c1 * x^2
    end
    return x
end

local function clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

-- ============================================================================
-- SAMP COLOR CODE PARSER {RRGGBB}
-- ============================================================================
local function parseColorCodes(text)
    local segments = {}
    local currentColor = COLORS.text
    local pos = 1
    local len = #text

    while pos <= len do
        local startBrace = text:find("{", pos, true)
        if startBrace then
            -- Add text before the color code
            if startBrace > pos then
                local chunk = text:sub(pos, startBrace - 1)
                if #chunk > 0 then
                    table.insert(segments, { text = chunk, color = currentColor })
                end
            end
            -- Try to parse color code
            local colorHex = text:match("^{(%x%x%x%x%x%x)}", startBrace)
            if colorHex then
                local r = tonumber(colorHex:sub(1, 2), 16) / 255
                local g = tonumber(colorHex:sub(3, 4), 16) / 255
                local b = tonumber(colorHex:sub(5, 6), 16) / 255
                currentColor = imgui.ImVec4(r, g, b, 1.0)
                pos = startBrace + 8 -- skip {RRGGBB}
            else
                -- Not a valid color code, treat as normal text
                table.insert(segments, { text = "{", color = currentColor })
                pos = startBrace + 1
            end
        else
            -- No more color codes, add remaining text
            local remaining = text:sub(pos)
            if #remaining > 0 then
                table.insert(segments, { text = remaining, color = currentColor })
            end
            break
        end
    end

    return segments
end

local function renderColoredText(text)
    local segments = parseColorCodes(text)
    for i, seg in ipairs(segments) do
        if i > 1 then imgui.SameLine(0, 0) end
        imgui.TextColored(seg.color, seg.text)
    end
end

local function renderColoredTextWrapped(text)
    -- Split by newlines first, then render each line with color parsing
    local lines = {}
    for line in (text .. "\n"):gmatch("(.-)\n") do
        table.insert(lines, line)
    end
    for _, line in ipairs(lines) do
        if #line == 0 then
            imgui.Text("")
        else
            local segments = parseColorCodes(line)
            for i, seg in ipairs(segments) do
                if i > 1 then imgui.SameLine(0, 0) end
                imgui.PushTextWrapPos(imgui.GetContentRegionAvail().x)
                imgui.TextColored(seg.color, seg.text)
                imgui.PopTextWrapPos()
            end
        end
    end
end

-- ============================================================================
-- LIST/TABLIST PARSER
-- ============================================================================
local function parseListItems(text)
    local items = {}
    for line in (text .. "\n"):gmatch("(.-)\n") do
        table.insert(items, line)
    end
    -- Remove trailing empty items
    while #items > 0 and items[#items] == "" do
        table.remove(items)
    end
    return items
end

local function parseTabList(text, hasHeaders)
    local lines = {}
    for line in (text .. "\n"):gmatch("(.-)\n") do
        table.insert(lines, line)
    end
    -- Remove trailing empty lines
    while #lines > 0 and lines[#lines] == "" do
        table.remove(lines)
    end

    local headers = {}
    local rows = {}

    if hasHeaders and #lines > 0 then
        -- First line is headers
        for col in (lines[1] .. "\t"):gmatch("(.-)\t") do
            table.insert(headers, col)
        end
        -- Rest are rows
        for i = 2, #lines do
            local row = {}
            for col in (lines[i] .. "\t"):gmatch("(.-)\t") do
                table.insert(row, col)
            end
            table.insert(rows, row)
        end
    else
        -- All lines are rows (tab-separated)
        for _, line in ipairs(lines) do
            local row = {}
            for col in (line .. "\t"):gmatch("(.-)\t") do
                table.insert(row, col)
            end
            table.insert(rows, row)
        end
    end

    return headers, rows
end

-- ============================================================================
-- DIALOG OPEN / CLOSE
-- ============================================================================
local function openDialog(dialogId, style, title, button1, button2, text)
    -- Clear input
    for i = 0, 255 do dialogState.inputText[i] = 0 end

    dialogState.active = true
    dialogState.closing = false
    dialogState.dialogId = dialogId
    dialogState.style = style
    dialogState.title = u8(title)
    dialogState.button1 = u8(button1)
    dialogState.button2 = u8(button2)
    dialogState.text = u8(text)
    dialogState.selectedItem = 0
    dialogState.openTime = os.clock()
    dialogState.scale = 0
    dialogState.alpha = 0
    dialogState.keyboardOffset = 0
    dialogState.inputFocused = false

    -- Parse based on style
    if style == DIALOG_STYLE_LIST then
        dialogState.listItems = parseListItems(dialogState.text)
    elseif style == DIALOG_STYLE_TABLIST then
        dialogState.tabHeaders, dialogState.tabRows = parseTabList(dialogState.text, false)
        dialogState.listItems = {} -- for selection tracking
        for i = 1, #dialogState.tabRows do
            table.insert(dialogState.listItems, tostring(i))
        end
    elseif style == DIALOG_STYLE_TABLIST_HEADERS then
        dialogState.tabHeaders, dialogState.tabRows = parseTabList(dialogState.text, true)
        dialogState.listItems = {}
        for i = 1, #dialogState.tabRows do
            table.insert(dialogState.listItems, tostring(i))
        end
    else
        dialogState.listItems = {}
    end
end

local function closeDialog(button)
    if not dialogState.active or dialogState.closing then return end
    dialogState.closing = true
    dialogState.closeTime = os.clock()

    -- Capture values before async delay
    local savedDialogId = dialogState.dialogId
    local savedStyle = dialogState.style
    local savedSelectedItem = dialogState.selectedItem
    local savedListItems = dialogState.listItems

    -- Get input text immediately (before buffer might be overwritten)
    local inputText = ""
    if savedStyle == DIALOG_STYLE_INPUT or savedStyle == DIALOG_STYLE_PASSWORD then
        local rawInput = ffi.string(dialogState.inputText)
        -- Decode UTF-8 back to CP1251 for server
        pcall(function()
            inputText = u8:decode(rawInput)
        end)
        if not inputText or #inputText == 0 then
            inputText = rawInput -- fallback: send as-is
        end
    end

    local listboxId = savedSelectedItem
    if savedStyle == DIALOG_STYLE_LIST or
       savedStyle == DIALOG_STYLE_TABLIST or
       savedStyle == DIALOG_STYLE_TABLIST_HEADERS then
        if savedStyle == DIALOG_STYLE_LIST and savedListItems[listboxId + 1] then
            local rawItem = savedListItems[listboxId + 1]:gsub("{%x%x%x%x%x%x}", "")
            pcall(function()
                inputText = u8:decode(rawItem)
            end)
            if not inputText then inputText = rawItem end
        end
    end

    -- Send response after animation completes
    lua_thread.create(function()
        wait(math.floor(ANIM_DURATION_CLOSE * 1000) + 50) -- extra 50ms safety margin
        dialogState.active = false
        dialogState.closing = false

        -- Send dialog response via RPC BitStream directly
        -- RPC ID 62 = DIALOGRESPONSE
        -- Format: {dialogId = 'int16'}, {button = 'int8'}, {listboxId = 'int16'}, {input = 'string8'}
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt16(bs, savedDialogId)
        raknetBitStreamWriteInt8(bs, button)
        raknetBitStreamWriteInt16(bs, listboxId)
        raknetBitStreamWriteInt8(bs, #inputText)
        if #inputText > 0 then
            raknetBitStreamWriteString(bs, inputText)
        end
        raknetSendRpcEx(62, bs, 2, 9, 0, false) -- HIGH_PRIORITY=2, RELIABLE_ORDERED=9
        raknetDeleteBitStream(bs)
    end)
end

-- ============================================================================
-- ANIMATION UPDATE
-- ============================================================================
local function updateAnimation()
    if dialogState.closing then
        local elapsed = os.clock() - dialogState.closeTime
        local progress = clamp(elapsed / ANIM_DURATION_CLOSE, 0, 1)
        local eased = getEase("inBack", progress)
        dialogState.scale = 1.0 - eased
        dialogState.alpha = 1.0 - progress
    elseif dialogState.active then
        local elapsed = os.clock() - dialogState.openTime
        local progress = clamp(elapsed / ANIM_DURATION_OPEN, 0, 1)
        local eased = getEase("outBack", progress)
        dialogState.scale = eased
        dialogState.alpha = progress
    end
end

-- ============================================================================
-- KEYBOARD ADAPTIVE OFFSET
-- ============================================================================
local function updateKeyboardOffset(resY)
    -- When input is focused, shift dialog upward to avoid keyboard
    -- Typical mobile keyboard takes ~40% of screen height
    local targetOffset = 0
    if dialogState.inputFocused then
        targetOffset = resY * 0.2 -- shift up 20% of screen
    end

    -- Smooth interpolation
    local speed = 8.0 * (1.0 / 60.0) -- assuming ~60fps
    dialogState.keyboardOffset = dialogState.keyboardOffset + (targetOffset - dialogState.keyboardOffset) * clamp(speed, 0, 1)
end

-- ============================================================================
-- RENDER: CLOSE BUTTON
-- ============================================================================
local function renderCloseButton(dpi)
    local btnSize = 28 * dpi
    local windowWidth = imgui.GetWindowSize().x
    local padding = 8 * dpi

    imgui.SetCursorPos(imgui.ImVec2(windowWidth - btnSize - padding, padding))
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0, 0, 0, 0))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(1, 0.3, 0.3, 0.3))
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(1, 0.2, 0.2, 0.5))
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, btnSize * 0.5)

    local closeIcon = fa_loaded and faicons('XMARK') or "X"
    if imgui.Button(closeIcon .. "##dialog_close", imgui.ImVec2(btnSize, btnSize)) then
        closeDialog(0) -- button2 response (cancel/close)
    end

    imgui.PopStyleVar()
    imgui.PopStyleColor(3)
end

-- ============================================================================
-- RENDER: TITLE BAR
-- ============================================================================
local function renderTitleBar(dpi)
    local title = dialogState.title
    if #title == 0 then title = "Dialog" end

    imgui.PushStyleColor(imgui.Col.Text, COLORS.title)
    imgui.SetCursorPos(imgui.ImVec2(12 * dpi, 10 * dpi))
    imgui.Text(title)
    imgui.PopStyleColor()

    -- Separator line
    local p = imgui.GetCursorScreenPos()
    local windowWidth = imgui.GetWindowSize().x
    local dl = imgui.GetWindowDrawList()
    local sepY = p.y + 2 * dpi
    dl:AddLine(
        imgui.ImVec2(p.x, sepY),
        imgui.ImVec2(p.x + windowWidth - 24 * dpi, sepY),
        imgui.ColorConvertFloat4ToU32(COLORS.separator),
        1.0
    )
    imgui.SetCursorPosY(imgui.GetCursorPosY() + 8 * dpi)
end

-- ============================================================================
-- RENDER: BUTTONS FOOTER
-- ============================================================================
local function renderButtons(dpi)
    local btn1 = dialogState.button1
    local btn2 = dialogState.button2
    local hasBtn2 = #btn2 > 0

    -- Separator before buttons
    imgui.Spacing()
    local p = imgui.GetCursorScreenPos()
    local windowWidth = imgui.GetWindowSize().x
    local dl = imgui.GetWindowDrawList()
    dl:AddLine(
        imgui.ImVec2(p.x, p.y),
        imgui.ImVec2(p.x + windowWidth - 24 * dpi, p.y),
        imgui.ColorConvertFloat4ToU32(COLORS.separator),
        1.0
    )
    imgui.Spacing()
    imgui.Spacing()

    local btnHeight = 36 * dpi
    local btnWidth = hasBtn2 and ((windowWidth - 36 * dpi) * 0.48) or (windowWidth - 36 * dpi)
    local btnRounding = 8 * dpi

    imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, btnRounding)
    imgui.PushStyleColor(imgui.Col.Button, COLORS.button)
    imgui.PushStyleColor(imgui.Col.ButtonHovered, COLORS.buttonHover)
    imgui.PushStyleColor(imgui.Col.ButtonActive, COLORS.buttonActive)

    -- Center buttons
    local totalWidth = hasBtn2 and (btnWidth * 2 + 12 * dpi) or btnWidth
    local startX = (windowWidth - totalWidth) * 0.5
    imgui.SetCursorPosX(startX)

    -- Button 1
    if imgui.Button(btn1 .. "##dlg_btn1", imgui.ImVec2(btnWidth, btnHeight)) then
        closeDialog(1) -- button1 response
    end

    -- Button 2
    if hasBtn2 then
        imgui.SameLine(0, 12 * dpi)
        if imgui.Button(btn2 .. "##dlg_btn2", imgui.ImVec2(btnWidth, btnHeight)) then
            closeDialog(0) -- button2 response
        end
    end

    imgui.PopStyleColor(3)
    imgui.PopStyleVar()
    imgui.Spacing()
end

-- ============================================================================
-- RENDER: MSGBOX CONTENT
-- ============================================================================
local function renderMsgBox(dpi, contentHeight)
    imgui.BeginChild("##dlg_content_msgbox", imgui.ImVec2(-1, contentHeight), false, imgui.WindowFlags.NoScrollbar)
    imgui.PushStyleColor(imgui.Col.Text, COLORS.text)
    renderColoredTextWrapped(dialogState.text)
    imgui.PopStyleColor()
    imgui.EndChild()
end

-- ============================================================================
-- RENDER: INPUT CONTENT
-- ============================================================================
local function renderInput(dpi, contentHeight, isPassword)
    imgui.BeginChild("##dlg_content_input", imgui.ImVec2(-1, contentHeight), false, imgui.WindowFlags.NoScrollbar)

    -- Text content
    imgui.PushStyleColor(imgui.Col.Text, COLORS.text)
    renderColoredTextWrapped(dialogState.text)
    imgui.PopStyleColor()

    imgui.Spacing()
    imgui.Spacing()

    -- Input field
    local inputWidth = imgui.GetContentRegionAvail().x
    imgui.PushStyleColor(imgui.Col.FrameBg, COLORS.inputBg)
    imgui.PushStyleColor(imgui.Col.Border, COLORS.inputBorder)
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 6 * dpi)
    imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, imgui.ImVec2(10 * dpi, 8 * dpi))
    imgui.PushItemWidth(inputWidth)

    local flags = 0
    if isPassword then
        flags = imgui.InputTextFlags.Password
    end
    flags = flags + imgui.InputTextFlags.EnterReturnsTrue

    local entered = imgui.InputText("##dlg_input", dialogState.inputText, 256, flags)
    dialogState.inputFocused = imgui.IsItemActive()

    if entered then
        closeDialog(1) -- Enter = button1
    end

    imgui.PopItemWidth()
    imgui.PopStyleVar(2)
    imgui.PopStyleColor(2)

    imgui.EndChild()
end

-- ============================================================================
-- RENDER: LIST CONTENT
-- ============================================================================
local function renderList(dpi, contentHeight)
    imgui.BeginChild("##dlg_content_list", imgui.ImVec2(-1, contentHeight), false, 0)

    imgui.PushStyleColor(imgui.Col.Header, COLORS.selectedItem)
    imgui.PushStyleColor(imgui.Col.HeaderHovered, imgui.ImVec4(COLORS.selectedItem.x, COLORS.selectedItem.y, COLORS.selectedItem.z, 0.8))
    imgui.PushStyleColor(imgui.Col.HeaderActive, imgui.ImVec4(COLORS.selectedItem.x, COLORS.selectedItem.y, COLORS.selectedItem.z, 0.9))
    imgui.PushStyleVarFloat(imgui.StyleVar.ItemSpacing, 2 * dpi)

    for i, item in ipairs(dialogState.listItems) do
        local isSelected = (dialogState.selectedItem == i - 1)
        local label = item
        if #label == 0 then label = " " end

        -- We need unique IDs
        imgui.PushID(i)

        -- Render selectable with color codes
        if imgui.Selectable("##listitem", isSelected, 0, imgui.ImVec2(0, 22 * dpi)) then
            dialogState.selectedItem = i - 1
        end
        if imgui.IsItemHovered() and imgui.IsMouseDoubleClicked(0) then
            dialogState.selectedItem = i - 1
            closeDialog(1) -- double click = select
        end

        -- Render colored text on top
        imgui.SameLine(8 * dpi)
        local segments = parseColorCodes(label)
        for si, seg in ipairs(segments) do
            if si > 1 then imgui.SameLine(0, 0) end
            imgui.TextColored(seg.color, seg.text)
        end

        imgui.PopID()
    end

    imgui.PopStyleVar()
    imgui.PopStyleColor(3)
    imgui.EndChild()
end

-- ============================================================================
-- RENDER: TABLIST CONTENT
-- ============================================================================
local function renderTabList(dpi, contentHeight, hasHeaders)
    imgui.BeginChild("##dlg_content_tab", imgui.ImVec2(-1, contentHeight), false, 0)

    local headers = dialogState.tabHeaders
    local rows = dialogState.tabRows
    local colCount = 0

    if hasHeaders and #headers > 0 then
        colCount = #headers
    elseif #rows > 0 then
        colCount = #rows[1]
    end

    if colCount == 0 then
        imgui.Text("(empty)")
        imgui.EndChild()
        return
    end

    -- Calculate column widths
    local availWidth = imgui.GetContentRegionAvail().x
    local colWidth = availWidth / colCount

    -- Render headers
    if hasHeaders and #headers > 0 then
        local dl = imgui.GetWindowDrawList()
        local p = imgui.GetCursorScreenPos()
        dl:AddRectFilled(
            p,
            imgui.ImVec2(p.x + availWidth, p.y + 24 * dpi),
            imgui.ColorConvertFloat4ToU32(COLORS.headerRow)
        )

        for ci, col in ipairs(headers) do
            imgui.SetCursorPosX(4 * dpi + (ci - 1) * colWidth)
            imgui.PushStyleColor(imgui.Col.Text, COLORS.title)
            local segments = parseColorCodes(col)
            for si, seg in ipairs(segments) do
                if si > 1 then imgui.SameLine(0, 0) end
                imgui.TextColored(seg.color, seg.text)
            end
            imgui.PopStyleColor()
            if ci < colCount then imgui.SameLine() end
        end
        imgui.SetCursorPosY(imgui.GetCursorPosY() + 4 * dpi)

        -- Header separator
        local sp = imgui.GetCursorScreenPos()
        dl:AddLine(
            sp,
            imgui.ImVec2(sp.x + availWidth, sp.y),
            imgui.ColorConvertFloat4ToU32(COLORS.separator),
            1.0
        )
        imgui.SetCursorPosY(imgui.GetCursorPosY() + 4 * dpi)
    end

    -- Render rows
    imgui.PushStyleColor(imgui.Col.Header, COLORS.selectedItem)
    imgui.PushStyleColor(imgui.Col.HeaderHovered, imgui.ImVec4(COLORS.selectedItem.x, COLORS.selectedItem.y, COLORS.selectedItem.z, 0.8))
    imgui.PushStyleColor(imgui.Col.HeaderActive, imgui.ImVec4(COLORS.selectedItem.x, COLORS.selectedItem.y, COLORS.selectedItem.z, 0.9))

    for ri, row in ipairs(rows) do
        local isSelected = (dialogState.selectedItem == ri - 1)
        imgui.PushID(ri + 1000)

        if imgui.Selectable("##tabrow", isSelected, 0, imgui.ImVec2(0, 22 * dpi)) then
            dialogState.selectedItem = ri - 1
        end
        if imgui.IsItemHovered() and imgui.IsMouseDoubleClicked(0) then
            dialogState.selectedItem = ri - 1
            closeDialog(1)
        end

        -- Render columns
        for ci, col in ipairs(row) do
            imgui.SameLine(4 * dpi + (ci - 1) * colWidth)
            local segments = parseColorCodes(col)
            for si, seg in ipairs(segments) do
                if si > 1 then imgui.SameLine(0, 0) end
                imgui.TextColored(seg.color, seg.text)
            end
        end

        imgui.PopID()
    end

    imgui.PopStyleColor(3)
    imgui.EndChild()
end

-- ============================================================================
-- MAIN IMGUI RENDER
-- ============================================================================
imgui.OnFrame(
    function() return dialogState.active end,
    function(self)
        self.HideCursor = false
        self.LockPlayer = true

        updateAnimation()

        local resX, resY = getScreenResolution()
        local dpi = MONET_DPI_SCALE or 1.0
        local scale = dialogState.scale
        local alpha = dialogState.alpha

        if scale <= 0.01 then return end

        updateKeyboardOffset(resY)

        -- Dialog dimensions
        local dialogWidth = math.min(resX * 0.88, 420 * dpi)
        local dialogMaxHeight = resY * 0.65
        local contentHeight = dialogMaxHeight - 110 * dpi -- space for title + buttons

        -- Adjust content height based on style
        if dialogState.style == DIALOG_STYLE_INPUT or dialogState.style == DIALOG_STYLE_PASSWORD then
            contentHeight = math.min(contentHeight, 200 * dpi)
        elseif dialogState.style == DIALOG_STYLE_MSGBOX then
            contentHeight = math.min(contentHeight, 300 * dpi)
        end

        -- Position: center, adjusted for keyboard
        local posX = (resX - dialogWidth * scale) * 0.5
        local posY = (resY - dialogMaxHeight * scale) * 0.5 - dialogState.keyboardOffset

        -- Full screen overlay for dimming
        imgui.SetNextWindowPos(imgui.ImVec2(0, 0), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(resX, resY), imgui.Cond.Always)
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, alpha * 0.6)
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0.5))
        imgui.Begin("##dlg_overlay", nil, 0
            + imgui.WindowFlags.NoTitleBar
            + imgui.WindowFlags.NoResize
            + imgui.WindowFlags.NoMove
            + imgui.WindowFlags.NoScrollbar
            + imgui.WindowFlags.NoScrollWithMouse
            + imgui.WindowFlags.NoCollapse
            + imgui.WindowFlags.NoSavedSettings
            + imgui.WindowFlags.NoInputs
        )
        imgui.End()
        imgui.PopStyleColor()
        imgui.PopStyleVar()

        -- Main dialog window
        imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, alpha)
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12 * dpi)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(12 * dpi, 8 * dpi))
        imgui.PushStyleColor(imgui.Col.WindowBg, COLORS.bg)
        imgui.PushStyleColor(imgui.Col.Border, COLORS.border)
        imgui.PushStyleColor(imgui.Col.ScrollbarBg, imgui.ImVec4(0, 0, 0, 0))
        imgui.PushStyleColor(imgui.Col.ScrollbarGrab, COLORS.scrollbarGrab)

        -- Apply scale transform via position/size
        local scaledWidth = dialogWidth * scale
        local scaledMaxHeight = dialogMaxHeight * scale
        local centerX = resX * 0.5
        local centerY = resY * 0.5 - dialogState.keyboardOffset
        local winX = centerX - scaledWidth * 0.5
        local winY = centerY - scaledMaxHeight * 0.5

        imgui.SetNextWindowPos(imgui.ImVec2(winX, winY), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(scaledWidth, 0), imgui.Cond.Always) -- auto height
        imgui.SetNextWindowSizeConstraints(imgui.ImVec2(scaledWidth, 0), imgui.ImVec2(scaledWidth, scaledMaxHeight))

        imgui.Begin("##custom_dialog", nil, 0
            + imgui.WindowFlags.NoTitleBar
            + imgui.WindowFlags.NoResize
            + imgui.WindowFlags.NoMove
            + imgui.WindowFlags.NoCollapse
            + imgui.WindowFlags.NoSavedSettings
            + imgui.WindowFlags.NoScrollbar
            + imgui.WindowFlags.NoScrollWithMouse
        )

        -- Close button (X)
        renderCloseButton(dpi)

        -- Title bar
        renderTitleBar(dpi)

        -- Content based on style
        if dialogState.style == DIALOG_STYLE_MSGBOX then
            renderMsgBox(dpi, contentHeight)
        elseif dialogState.style == DIALOG_STYLE_INPUT then
            renderInput(dpi, contentHeight, false)
        elseif dialogState.style == DIALOG_STYLE_PASSWORD then
            renderInput(dpi, contentHeight, true)
        elseif dialogState.style == DIALOG_STYLE_LIST then
            renderList(dpi, contentHeight)
        elseif dialogState.style == DIALOG_STYLE_TABLIST then
            renderTabList(dpi, contentHeight, false)
        elseif dialogState.style == DIALOG_STYLE_TABLIST_HEADERS then
            renderTabList(dpi, contentHeight, true)
        end

        -- Footer buttons
        renderButtons(dpi)

        -- Draw border glow effect
        local dl = imgui.GetWindowDrawList()
        local wp = imgui.GetWindowPos()
        local ws = imgui.GetWindowSize()
        local rounding = 12 * dpi
        dl:AddRect(
            wp,
            imgui.ImVec2(wp.x + ws.x, wp.y + ws.y),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(COLORS.border.x, COLORS.border.y, COLORS.border.z, COLORS.border.w * alpha)),
            rounding,
            15,
            1.5
        )

        imgui.End()
        imgui.PopStyleColor(4)
        imgui.PopStyleVar(3)
    end
)

-- ============================================================================
-- FONT INITIALIZATION
-- ============================================================================
imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil

    -- Load FontAwesome if available
    if fa_loaded and faicons then
        local config = imgui.ImFontConfig()
        config.MergeMode = true
        config.PixelSnapH = true

        local builder = imgui.ImFontGlyphRangesBuilder()
        builder:AddText(faicons('XMARK'))
        local glyphRanges = imgui.ImVector_ImWchar()
        builder:BuildRanges(glyphRanges)
        imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(
            faicons.get_font_data_base85('solid'),
            14 * (MONET_DPI_SCALE or 1.0),
            config,
            glyphRanges[0].Data
        )
    end
end)

-- ============================================================================
-- SAMP EVENT HOOKS
-- ============================================================================
function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("{4D99E6}[CostumDialog] {FFFFFF}Custom Dialog loaded! v1.0", -1)

    -- Register command to toggle (for testing/debugging)
    sampRegisterChatCommand("cdialog", function()
        if dialogState.active then
            closeDialog(0)
            sampAddChatMessage("{4D99E6}[CostumDialog] {FFFFFF}Dialog closed.", -1)
        else
            sampAddChatMessage("{4D99E6}[CostumDialog] {FFFFFF}No active dialog.", -1)
        end
    end)

    wait(-1)
end

-- ============================================================================
-- HOOK: onShowDialog - intercept server dialogs
-- ============================================================================

-- Flag to prevent re-intercepting dialogs during response sending
local ignoreNextDialog = false

-- Method 1: Global function hook (MoonLoader/MonetLoader style)
function onShowDialog(dialogId, style, title, button1, button2, text)
    if ignoreNextDialog then
        ignoreNextDialog = false
        return false -- let it pass through to client (will be hidden anyway)
    end
    openDialog(dialogId, style, title, button1, button2, text)
    return false -- block original dialog
end

-- Method 2: SAMP.Lua events library hook (MonetLoader/SAMP.Lua style)
if events_loaded and events then
    function events.onShowDialog(dialogId, style, title, button1, button2, text)
        if ignoreNextDialog then
            ignoreNextDialog = false
            return -- don't block, let it through
        end
        openDialog(dialogId, style, title, button1, button2, text)
        return false -- block original dialog
    end
end
