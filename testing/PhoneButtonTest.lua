-- ============================================================================
-- PHONE BUTTON WIDGET TEST
-- Simple test script to demonstrate phone widget triggering ImGui window
-- ============================================================================

script_name("Phone Button Test")
script_author("OnlyDexterZ")
script_version("1.0")

local imgui = require 'mimgui'
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8

-- ============================================================================
-- VARIABLES
-- ============================================================================
local showTestWindow = imgui.new.bool(false)
local showPhoneButton = imgui.new.bool(true)

-- Phone button settings
local phoneButton = {
    posX = 50,
    posY = 300,
    size = 80,
    alpha = 0.8
}

-- Animation
local pulseAnimation = 0

-- Test window content
local testInput = imgui.new.char[256]("")
local testSlider = imgui.new.float(50)
local testCheckbox = imgui.new.bool(false)

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

function drawPhoneButton()
    local sw, sh = getScreenResolution()
    local draw = imgui.GetBackgroundDrawList()
    
    local px = phoneButton.posX
    local py = phoneButton.posY
    local ps = phoneButton.size
    local pa = phoneButton.alpha
    
    -- Update pulse animation
    pulseAnimation = (pulseAnimation + 0.05) % (math.pi * 2)
    local pulse = math.sin(pulseAnimation) * 0.15 + 1.0
    
    -- Outer glow (animated pulse)
    local radiusOuter = (ps/2) * pulse
    local glowAlpha = math.floor(pa * 100 * (1.0 - (pulse - 1.0) * 3))
    local glowColor = glowAlpha * 0x01000000 + 0x0044AAFF  -- Blue glow
    
    draw:AddCircleFilled(
        imgui.ImVec2(px + ps/2, py + ps/2),
        radiusOuter,
        glowColor,
        32
    )
    
    -- Inner circle (main button)
    local bgAlpha = math.floor(pa * 220)
    local bgColor = bgAlpha * 0x01000000 + 0x00222222  -- Dark background
    
    draw:AddCircleFilled(
        imgui.ImVec2(px + ps/2, py + ps/2),
        ps/2,
        bgColor,
        32
    )
    
    -- Border
    local borderAlpha = math.floor(pa * 255)
    local borderColor = borderAlpha * 0x01000000 + 0x0088DDFF  -- Light blue border
    
    draw:AddCircle(
        imgui.ImVec2(px + ps/2, py + ps/2),
        ps/2,
        borderColor,
        32,
        3.0
    )
    
    -- Phone icon
    local icon = "📱"
    local iconSize = imgui.CalcTextSize(icon)
    local iconAlpha = math.floor(pa * 255)
    local iconColor = iconAlpha * 0x01000000 + 0x00FFFFFF  -- White
    
    draw:AddText(
        imgui.ImVec2(px + ps/2 - iconSize.x/2, py + ps/2 - iconSize.y/2),
        iconColor,
        icon
    )
    
    -- Label below button
    local label = "MENU"
    local labelSize = imgui.CalcTextSize(label)
    local labelAlpha = math.floor(pa * 200)
    local labelColor = labelAlpha * 0x01000000 + 0x00AAAAAA
    
    draw:AddText(
        imgui.ImVec2(px + ps/2 - labelSize.x/2, py + ps + 5),
        labelColor,
        label
    )
end

-- ============================================================================
-- MAIN
-- ============================================================================
function main()
    while not isSampAvailable() do wait(100) end
    
    sampAddChatMessage("{00FFFF}[Phone Button Test] {FFFFFF}Script loaded!", -1)
    sampAddChatMessage("{00FFFF}[Phone Button Test] {FFFFFF}Tap the phone button to open test window", -1)
    sampAddChatMessage("{00FFFF}[Phone Button Test] {FFFFFF}Use {FFFF00}/ptest{FFFFFF} to toggle phone button", -1)
    
    -- Register command to toggle phone button
    sampRegisterChatCommand("ptest", function()
        showPhoneButton[0] = not showPhoneButton[0]
        sampAddChatMessage("{00FFFF}[Phone Test] {FFFFFF}Phone button: " .. 
            (showPhoneButton[0] and "{00FF00}ON" or "{FF0000}OFF"), -1)
    end)
    
    -- Main render loop
    imgui.OnFrame(
        function() return true end,
        function()
            local sw, sh = getScreenResolution()
            
            -- Draw phone button (only when test window is closed)
            if showPhoneButton[0] and not showTestWindow[0] then
                drawPhoneButton()
                
                -- Invisible button for touch detection
                local px = phoneButton.posX
                local py = phoneButton.posY
                local ps = phoneButton.size
                
                imgui.SetNextWindowPos(imgui.ImVec2(px, py), imgui.Cond.Always)
                imgui.SetNextWindowSize(imgui.ImVec2(ps, ps))
                
                imgui.Begin("##PhoneTouchArea", nil,
                    imgui.WindowFlags.NoTitleBar + 
                    imgui.WindowFlags.NoResize + 
                    imgui.WindowFlags.NoBackground +
                    imgui.WindowFlags.NoScrollbar)
                    
                    if imgui.InvisibleButton("##phone_touch", imgui.ImVec2(ps - 10, ps - 10)) then
                        showTestWindow[0] = true
                        sampAddChatMessage("{00FF00}[Phone Test] {FFFFFF}Window opened!", -1)
                    end
                    
                imgui.End()
            end
            
            -- Test window (triggered by phone button)
            if showTestWindow[0] then
                imgui.SetNextWindowPos(imgui.ImVec2(sw/2 - 200, sh/2 - 200), imgui.Cond.FirstUseEver)
                imgui.SetNextWindowSize(imgui.ImVec2(400, 400), imgui.Cond.FirstUseEver)
                
                imgui.Begin(u8"📱 Phone Menu Test", showTestWindow)
                
                imgui.TextColored(imgui.ImVec4(0, 1, 1, 1), u8"Phone Widget Triggered Successfully!")
                imgui.Spacing()
                imgui.Separator()
                imgui.Spacing()
                
                imgui.Text(u8"This window was opened by tapping the phone button")
                imgui.Spacing()
                
                -- Demo widgets
                imgui.TextColored(imgui.ImVec4(1, 1, 0, 1), u8"Test Widgets:")
                imgui.Spacing()
                
                imgui.InputText(u8"Enter text", testInput, 256)
                imgui.SliderFloat(u8"Slider", testSlider, 0, 100, "%.0f%%")
                imgui.Checkbox(u8"Enable feature", testCheckbox)
                
                imgui.Spacing()
                imgui.Separator()
                imgui.Spacing()
                
                if imgui.Button(u8"Test Button", imgui.ImVec2(180, 40)) then
                    sampAddChatMessage("{00FF00}[Phone Test] {FFFFFF}Button clicked! Value: " .. 
                        string.format("%.0f", testSlider[0]), -1)
                end
                
                imgui.SameLine()
                
                if imgui.Button(u8"Close", imgui.ImVec2(180, 40)) then
                    showTestWindow[0] = false
                    sampAddChatMessage("{FFFF00}[Phone Test] {FFFFFF}Window closed!", -1)
                end
                
                imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), 
                    u8"Tap outside or press Close to return to phone button")
                
                imgui.End()
            end
        end
    )
    
    wait(-1)
end
