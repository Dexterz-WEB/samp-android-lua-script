-- ============================================================================
-- CUSTOM HUD SCRIPT - SAMP ANDROID (MOONLOADER)
-- Created for minimalist/modern HUD with mimgui config
-- ============================================================================
local imgui  = require 'mimgui'
local inicfg = require 'inicfg'

local iniFileName = "CustomHUD.ini"

-- ============================================================================
-- DEFAULT CONFIG STRUCTURE
-- ============================================================================
local defaultConfig = {
    Main = {
        enableHUD = true,
        hideOriginalHUD = true,
    },
    Health = {
        enabled = true,
        posX = 50.0,
        posY = 50.0,
        scale = 1.0,
        colorR = 255,
        colorG = 50,
        colorB = 50,
        colorA = 255,
        showBackground = true,
        bgAlpha = 180,
    },
    Armor = {
        enabled = true,
        posX = 50.0,
        posY = 80.0,
        scale = 1.0,
        colorR = 200,
        colorG = 200,
        colorB = 200,
        colorA = 255,
        showBackground = true,
        bgAlpha = 180,
    },
    Money = {
        enabled = true,
        posX = 50.0,
        posY = 110.0,
        scale = 1.0,
        colorR = 50,
        colorG = 255,
        colorB = 50,
        colorA = 255,
    },

    Weapon = {
        enabled = true,
        posX = 50.0,
        posY = 140.0,
        scale = 1.0,
        colorR = 255,
        colorG = 200,
        colorB = 50,
        colorA = 255,
    },
    WantedLevel = {
        enabled = true,
        posX = 50.0,
        posY = 170.0,
        scale = 1.0,
        colorR = 255,
        colorG = 100,
        colorB = 100,
        colorA = 255,
    },
    Time = {
        enabled = true,
        posX = 50.0,
        posY = 200.0,
        scale = 1.0,
        colorR = 255,
        colorG = 255,
        colorB = 255,
        colorA = 255,
    },
    Location = {
        enabled = true,
        posX = 50.0,
        posY = 230.0,
        scale = 1.0,
        colorR = 100,
        colorG = 200,
        colorB = 255,
        colorA = 255,
    },
}

-- Load or create config
local cfg = inicfg.load(defaultConfig, iniFileName)
if not cfg then
    inicfg.save(defaultConfig, iniFileName)
    cfg = defaultConfig
end

-- Ensure all sections exist
for k, v in pairs(defaultConfig) do
    if not cfg[k] then cfg[k] = v end
end


-- ============================================================================
-- STATE VARIABLES & ImGui CONTROLS
-- ============================================================================
local showConfigWindow = imgui.new.bool(false)

-- Main controls
local enableHUD = imgui.new.bool(cfg.Main.enableHUD)
local hideOriginalHUD = imgui.new.bool(cfg.Main.hideOriginalHUD)

-- Health controls
local healthEnabled = imgui.new.bool(cfg.Health.enabled)
local healthPosX = imgui.new.float(cfg.Health.posX)
local healthPosY = imgui.new.float(cfg.Health.posY)
local healthScale = imgui.new.float(cfg.Health.scale)
local healthColor = imgui.new.float[4](cfg.Health.colorR/255, cfg.Health.colorG/255, cfg.Health.colorB/255, cfg.Health.colorA/255)
local healthShowBg = imgui.new.bool(cfg.Health.showBackground)
local healthBgAlpha = imgui.new.int(cfg.Health.bgAlpha)

-- Armor controls
local armorEnabled = imgui.new.bool(cfg.Armor.enabled)
local armorPosX = imgui.new.float(cfg.Armor.posX)
local armorPosY = imgui.new.float(cfg.Armor.posY)
local armorScale = imgui.new.float(cfg.Armor.scale)
local armorColor = imgui.new.float[4](cfg.Armor.colorR/255, cfg.Armor.colorG/255, cfg.Armor.colorB/255, cfg.Armor.colorA/255)
local armorShowBg = imgui.new.bool(cfg.Armor.showBackground)
local armorBgAlpha = imgui.new.int(cfg.Armor.bgAlpha)

-- Money controls
local moneyEnabled = imgui.new.bool(cfg.Money.enabled)
local moneyPosX = imgui.new.float(cfg.Money.posX)
local moneyPosY = imgui.new.float(cfg.Money.posY)
local moneyScale = imgui.new.float(cfg.Money.scale)
local moneyColor = imgui.new.float[4](cfg.Money.colorR/255, cfg.Money.colorG/255, cfg.Money.colorB/255, cfg.Money.colorA/255)

-- Weapon controls
local weaponEnabled = imgui.new.bool(cfg.Weapon.enabled)
local weaponPosX = imgui.new.float(cfg.Weapon.posX)
local weaponPosY = imgui.new.float(cfg.Weapon.posY)
local weaponScale = imgui.new.float(cfg.Weapon.scale)
local weaponColor = imgui.new.float[4](cfg.Weapon.colorR/255, cfg.Weapon.colorG/255, cfg.Weapon.colorB/255, cfg.Weapon.colorA/255)


-- Wanted Level controls
local wantedEnabled = imgui.new.bool(cfg.WantedLevel.enabled)
local wantedPosX = imgui.new.float(cfg.WantedLevel.posX)
local wantedPosY = imgui.new.float(cfg.WantedLevel.posY)
local wantedScale = imgui.new.float(cfg.WantedLevel.scale)
local wantedColor = imgui.new.float[4](cfg.WantedLevel.colorR/255, cfg.WantedLevel.colorG/255, cfg.WantedLevel.colorB/255, cfg.WantedLevel.colorA/255)

-- Time controls
local timeEnabled = imgui.new.bool(cfg.Time.enabled)
local timePosX = imgui.new.float(cfg.Time.posX)
local timePosY = imgui.new.float(cfg.Time.posY)
local timeScale = imgui.new.float(cfg.Time.scale)
local timeColor = imgui.new.float[4](cfg.Time.colorR/255, cfg.Time.colorG/255, cfg.Time.colorB/255, cfg.Time.colorA/255)

-- Location controls
local locationEnabled = imgui.new.bool(cfg.Location.enabled)
local locationPosX = imgui.new.float(cfg.Location.posX)
local locationPosY = imgui.new.float(cfg.Location.posY)
local locationScale = imgui.new.float(cfg.Location.scale)
local locationColor = imgui.new.float[4](cfg.Location.colorR/255, cfg.Location.colorG/255, cfg.Location.colorB/255, cfg.Location.colorA/255)

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================
function saveConfig()
    -- Main
    cfg.Main.enableHUD = enableHUD[0]
    cfg.Main.hideOriginalHUD = hideOriginalHUD[0]
    
    -- Health
    cfg.Health.enabled = healthEnabled[0]
    cfg.Health.posX = healthPosX[0]
    cfg.Health.posY = healthPosY[0]
    cfg.Health.scale = healthScale[0]
    cfg.Health.colorR = math.floor(healthColor[0] * 255)
    cfg.Health.colorG = math.floor(healthColor[1] * 255)
    cfg.Health.colorB = math.floor(healthColor[2] * 255)
    cfg.Health.colorA = math.floor(healthColor[3] * 255)
    cfg.Health.showBackground = healthShowBg[0]
    cfg.Health.bgAlpha = healthBgAlpha[0]

    
    -- Armor
    cfg.Armor.enabled = armorEnabled[0]
    cfg.Armor.posX = armorPosX[0]
    cfg.Armor.posY = armorPosY[0]
    cfg.Armor.scale = armorScale[0]
    cfg.Armor.colorR = math.floor(armorColor[0] * 255)
    cfg.Armor.colorG = math.floor(armorColor[1] * 255)
    cfg.Armor.colorB = math.floor(armorColor[2] * 255)
    cfg.Armor.colorA = math.floor(armorColor[3] * 255)
    cfg.Armor.showBackground = armorShowBg[0]
    cfg.Armor.bgAlpha = armorBgAlpha[0]
    
    -- Money
    cfg.Money.enabled = moneyEnabled[0]
    cfg.Money.posX = moneyPosX[0]
    cfg.Money.posY = moneyPosY[0]
    cfg.Money.scale = moneyScale[0]
    cfg.Money.colorR = math.floor(moneyColor[0] * 255)
    cfg.Money.colorG = math.floor(moneyColor[1] * 255)
    cfg.Money.colorB = math.floor(moneyColor[2] * 255)
    cfg.Money.colorA = math.floor(moneyColor[3] * 255)
    
    -- Weapon
    cfg.Weapon.enabled = weaponEnabled[0]
    cfg.Weapon.posX = weaponPosX[0]
    cfg.Weapon.posY = weaponPosY[0]
    cfg.Weapon.scale = weaponScale[0]
    cfg.Weapon.colorR = math.floor(weaponColor[0] * 255)
    cfg.Weapon.colorG = math.floor(weaponColor[1] * 255)
    cfg.Weapon.colorB = math.floor(weaponColor[2] * 255)
    cfg.Weapon.colorA = math.floor(weaponColor[3] * 255)
    
    -- Wanted Level
    cfg.WantedLevel.enabled = wantedEnabled[0]
    cfg.WantedLevel.posX = wantedPosX[0]
    cfg.WantedLevel.posY = wantedPosY[0]
    cfg.WantedLevel.scale = wantedScale[0]
    cfg.WantedLevel.colorR = math.floor(wantedColor[0] * 255)
    cfg.WantedLevel.colorG = math.floor(wantedColor[1] * 255)
    cfg.WantedLevel.colorB = math.floor(wantedColor[2] * 255)
    cfg.WantedLevel.colorA = math.floor(wantedColor[3] * 255)
    
    -- Time
    cfg.Time.enabled = timeEnabled[0]
    cfg.Time.posX = timePosX[0]
    cfg.Time.posY = timePosY[0]
    cfg.Time.scale = timeScale[0]
    cfg.Time.colorR = math.floor(timeColor[0] * 255)
    cfg.Time.colorG = math.floor(timeColor[1] * 255)
    cfg.Time.colorB = math.floor(timeColor[2] * 255)
    cfg.Time.colorA = math.floor(timeColor[3] * 255)

    
    -- Location
    cfg.Location.enabled = locationEnabled[0]
    cfg.Location.posX = locationPosX[0]
    cfg.Location.posY = locationPosY[0]
    cfg.Location.scale = locationScale[0]
    cfg.Location.colorR = math.floor(locationColor[0] * 255)
    cfg.Location.colorG = math.floor(locationColor[1] * 255)
    cfg.Location.colorB = math.floor(locationColor[2] * 255)
    cfg.Location.colorA = math.floor(locationColor[3] * 255)
    
    -- Save to file
    inicfg.save(cfg, iniFileName)
    sampAddChatMessage("{00FF00}[Custom HUD]{FFFFFF} Config saved!", -1)
end

function formatMoney(amount)
    local formatted = tostring(amount)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
        if k == 0 then break end
    end
    return "$" .. formatted
end

function getWeaponName(weaponId)
    local names = {
        [0] = "Fist", [1] = "Brass Knuckles", [2] = "Golf Club", [3] = "Nightstick",
        [4] = "Knife", [5] = "Baseball Bat", [6] = "Shovel", [7] = "Pool Cue",
        [8] = "Katana", [9] = "Chainsaw", [22] = "Colt 45", [23] = "Silenced",
        [24] = "Deagle", [25] = "Shotgun", [26] = "Sawnoff", [27] = "Combat Shotgun",
        [28] = "Micro SMG", [29] = "MP5", [30] = "AK-47", [31] = "M4",
        [32] = "Tec-9", [33] = "Rifle", [34] = "Sniper", [35] = "RPG",
        [36] = "Heat Seeker", [37] = "Flamethrower", [38] = "Minigun",
        [16] = "Grenade", [17] = "Tear Gas", [18] = "Molotov", [39] = "Satchel",
        [41] = "Spray Can", [42] = "Fire Extinguisher", [43] = "Camera",
        [10] = "Dildo", [11] = "Dildo", [12] = "Vibrator", [13] = "Vibrator",
        [14] = "Flowers", [15] = "Cane", [40] = "Detonator", [44] = "NV Goggles",
        [45] = "Thermal Goggles", [46] = "Parachute"
    }
    return names[weaponId] or "Unknown"
end


-- ============================================================================
-- DRAW HUD FUNCTIONS
-- ============================================================================
function drawHudElement(draw_list, text, x, y, scale, color, showBg, bgAlpha)
    local textSize = imgui.CalcTextSize(text)
    
    -- Draw background if enabled
    if showBg then
        local padding = 5 * scale
        local bgColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0, 0, 0, (bgAlpha or 180) / 255))
        draw_list:AddRectFilled(
            imgui.ImVec2(x - padding, y - padding),
            imgui.ImVec2(x + textSize.x + padding, y + textSize.y + padding),
            bgColor,
            3.0
        )
    end
    
    -- Draw text
    local textColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(color[0], color[1], color[2], color[3]))
    draw_list:AddText(imgui.ImVec2(x, y), textColor, text)
end

function drawProgressBar(draw_list, x, y, width, height, value, maxValue, color, bgColor)
    local percentage = math.max(0, math.min(1, value / maxValue))
    
    -- Background
    draw_list:AddRectFilled(
        imgui.ImVec2(x, y),
        imgui.ImVec2(x + width, y + height),
        bgColor,
        2.0
    )
    
    -- Fill bar
    if percentage > 0 then
        draw_list:AddRectFilled(
            imgui.ImVec2(x, y),
            imgui.ImVec2(x + (width * percentage), y + height),
            color,
            2.0
        )
    end
    
    -- Border
    draw_list:AddRect(
        imgui.ImVec2(x, y),
        imgui.ImVec2(x + width, y + height),
        0xFFFFFFFF,
        2.0,
        nil,
        1.0
    )
end


-- ============================================================================
-- MAIN SCRIPT
-- ============================================================================
function main()
    while not isSampAvailable() do wait(100) end
    
    sampAddChatMessage("{00FFFF}[Custom HUD]{FFFFFF} Script loaded successfully!", -1)
    sampAddChatMessage("{00FFFF}[Custom HUD]{FFFFFF} Command: {FFFF00}/chud {FFFFFF}to open config", -1)
    sampAddChatMessage("{00FFFF}[Custom HUD]{FFFFFF} Created by: {FFFF00}OnlyDexterZ", -1)
    
    -- Register command
    sampRegisterChatCommand("chud", function()
        showConfigWindow[0] = not showConfigWindow[0]
    end)
    
    -- Main loop
    while true do
        wait(0)
        
        -- Hide original HUD if enabled
        if hideOriginalHUD[0] then
            displayHud(false)
            displayRadar(false)
        else
            displayHud(true)
            displayRadar(true)
        end
    end
end


-- ============================================================================
-- ImGui RENDERING
-- ============================================================================
imgui.OnFrame(function() return true end, function(player)
    local sw, sh = getScreenResolution()
    local draw_list = imgui.GetBackgroundDrawList()
    
    -- Draw custom HUD
    if enableHUD[0] and not sampIsCursorActive() then
        local health = getCharHealth(PLAYER_PED)
        local armor = getCharArmour(PLAYER_PED)
        local money = getPlayerMoney(PLAYER_PED)
        local weaponId = getCurrentCharWeapon(PLAYER_PED)
        local ammo = getAmmoInCharWeapon(PLAYER_PED, weaponId)
        local wanted = getPlayerWantedLevel(PLAYER_PED)
        local hours, minutes = getTimeOfDay()
        local zoneName = getNameOfZone(getCharCoordinates(PLAYER_PED))
        
        -- Draw Health
        if healthEnabled[0] then
            local healthText = string.format("HP: %.0f", health)
            if healthShowBg[0] then
                -- Draw as progress bar
                local barWidth = 150 * healthScale[0]
                local barHeight = 20 * healthScale[0]
                local barColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(healthColor[0], healthColor[1], healthColor[2], healthColor[3]))
                local bgColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0, 0, 0, healthBgAlpha[0] / 255))
                drawProgressBar(draw_list, healthPosX[0], healthPosY[0], barWidth, barHeight, health, 100, barColor, bgColor)
                
                -- Draw text on bar
                local textSize = imgui.CalcTextSize(healthText)
                local textX = healthPosX[0] + (barWidth - textSize.x) / 2
                local textY = healthPosY[0] + (barHeight - textSize.y) / 2
                draw_list:AddText(imgui.ImVec2(textX, textY), 0xFFFFFFFF, healthText)
            else
                drawHudElement(draw_list, healthText, healthPosX[0], healthPosY[0], healthScale[0], healthColor, false, 0)
            end
        end
        
        -- Draw Armor
        if armorEnabled[0] and armor > 0 then
            local armorText = string.format("AR: %.0f", armor)
            if armorShowBg[0] then
                local barWidth = 150 * armorScale[0]
                local barHeight = 20 * armorScale[0]
                local barColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(armorColor[0], armorColor[1], armorColor[2], armorColor[3]))
                local bgColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0, 0, 0, armorBgAlpha[0] / 255))
                drawProgressBar(draw_list, armorPosX[0], armorPosY[0], barWidth, barHeight, armor, 100, barColor, bgColor)
                
                local textSize = imgui.CalcTextSize(armorText)
                local textX = armorPosX[0] + (barWidth - textSize.x) / 2
                local textY = armorPosY[0] + (barHeight - textSize.y) / 2
                draw_list:AddText(imgui.ImVec2(textX, textY), 0xFFFFFFFF, armorText)
            else
                drawHudElement(draw_list, armorText, armorPosX[0], armorPosY[0], armorScale[0], armorColor, false, 0)
            end
        end

        
        -- Draw Money
        if moneyEnabled[0] then
            local moneyText = formatMoney(money)
            drawHudElement(draw_list, moneyText, moneyPosX[0], moneyPosY[0], moneyScale[0], moneyColor, false, 0)
        end
        
        -- Draw Weapon & Ammo
        if weaponEnabled[0] and weaponId > 0 then
            local weaponText = string.format("%s [%d]", getWeaponName(weaponId), ammo)
            drawHudElement(draw_list, weaponText, weaponPosX[0], weaponPosY[0], weaponScale[0], weaponColor, false, 0)
        end
        
        -- Draw Wanted Level
        if wantedEnabled[0] and wanted > 0 then
            local stars = string.rep("★", wanted)
            drawHudElement(draw_list, stars, wantedPosX[0], wantedPosY[0], wantedScale[0], wantedColor, false, 0)
        end
        
        -- Draw Time
        if timeEnabled[0] then
            local timeText = string.format("%02d:%02d", hours, minutes)
            drawHudElement(draw_list, timeText, timePosX[0], timePosY[0], timeScale[0], timeColor, false, 0)
        end
        
        -- Draw Location
        if locationEnabled[0] then
            drawHudElement(draw_list, zoneName, locationPosX[0], locationPosY[0], locationScale[0], locationColor, false, 0)
        end
    end

    
    -- Config Window
    if showConfigWindow[0] then
        imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5 - 400, sh * 0.5 - 350), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(800, 700))
        imgui.Begin("Custom HUD Config Panel", showConfigWindow, imgui.WindowFlags.NoResize)
        
        imgui.TextColored(imgui.ImVec4(0, 1, 1, 1), "=== CUSTOM HUD CONFIGURATION ===")
        imgui.Spacing()
        
        -- Main Settings
        imgui.TextColored(imgui.ImVec4(1, 1, 0, 1), "MAIN SETTINGS")
        imgui.Checkbox("Enable Custom HUD", enableHUD)
        imgui.Checkbox("Hide Original HUD", hideOriginalHUD)
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()
        
        -- Create tabs for each HUD element
        if imgui.BeginTabBar("HudElements") then
            
            -- HEALTH TAB
            if imgui.BeginTabItem("Health") then
                imgui.Checkbox("Enable##health", healthEnabled)
                imgui.SliderFloat("Position X##health", healthPosX, 0, sw, "%.0f")
                imgui.SliderFloat("Position Y##health", healthPosY, 0, sh, "%.0f")
                imgui.SliderFloat("Scale##health", healthScale, 0.5, 2.0, "%.1f")
                imgui.ColorEdit4("Color##health", healthColor)
                imgui.Checkbox("Show Progress Bar##health", healthShowBg)
                if healthShowBg[0] then
                    imgui.SliderInt("Bar Alpha##health", healthBgAlpha, 0, 255)
                end
                imgui.EndTabItem()
            end
            
            -- ARMOR TAB
            if imgui.BeginTabItem("Armor") then
                imgui.Checkbox("Enable##armor", armorEnabled)
                imgui.SliderFloat("Position X##armor", armorPosX, 0, sw, "%.0f")
                imgui.SliderFloat("Position Y##armor", armorPosY, 0, sh, "%.0f")
                imgui.SliderFloat("Scale##armor", armorScale, 0.5, 2.0, "%.1f")
                imgui.ColorEdit4("Color##armor", armorColor)
                imgui.Checkbox("Show Progress Bar##armor", armorShowBg)
                if armorShowBg[0] then
                    imgui.SliderInt("Bar Alpha##armor", armorBgAlpha, 0, 255)
                end
                imgui.EndTabItem()
            end

            
            -- MONEY TAB
            if imgui.BeginTabItem("Money") then
                imgui.Checkbox("Enable##money", moneyEnabled)
                imgui.SliderFloat("Position X##money", moneyPosX, 0, sw, "%.0f")
                imgui.SliderFloat("Position Y##money", moneyPosY, 0, sh, "%.0f")
                imgui.SliderFloat("Scale##money", moneyScale, 0.5, 2.0, "%.1f")
                imgui.ColorEdit4("Color##money", moneyColor)
                imgui.EndTabItem()
            end
            
            -- WEAPON TAB
            if imgui.BeginTabItem("Weapon") then
                imgui.Checkbox("Enable##weapon", weaponEnabled)
                imgui.SliderFloat("Position X##weapon", weaponPosX, 0, sw, "%.0f")
                imgui.SliderFloat("Position Y##weapon", weaponPosY, 0, sh, "%.0f")
                imgui.SliderFloat("Scale##weapon", weaponScale, 0.5, 2.0, "%.1f")
                imgui.ColorEdit4("Color##weapon", weaponColor)
                imgui.EndTabItem()
            end
            
            -- WANTED LEVEL TAB
            if imgui.BeginTabItem("Wanted") then
                imgui.Checkbox("Enable##wanted", wantedEnabled)
                imgui.SliderFloat("Position X##wanted", wantedPosX, 0, sw, "%.0f")
                imgui.SliderFloat("Position Y##wanted", wantedPosY, 0, sh, "%.0f")
                imgui.SliderFloat("Scale##wanted", wantedScale, 0.5, 2.0, "%.1f")
                imgui.ColorEdit4("Color##wanted", wantedColor)
                imgui.EndTabItem()
            end
            
            -- TIME TAB
            if imgui.BeginTabItem("Time") then
                imgui.Checkbox("Enable##time", timeEnabled)
                imgui.SliderFloat("Position X##time", timePosX, 0, sw, "%.0f")
                imgui.SliderFloat("Position Y##time", timePosY, 0, sh, "%.0f")
                imgui.SliderFloat("Scale##time", timeScale, 0.5, 2.0, "%.1f")
                imgui.ColorEdit4("Color##time", timeColor)
                imgui.EndTabItem()
            end
            
            -- LOCATION TAB
            if imgui.BeginTabItem("Location") then
                imgui.Checkbox("Enable##location", locationEnabled)
                imgui.SliderFloat("Position X##location", locationPosX, 0, sw, "%.0f")
                imgui.SliderFloat("Position Y##location", locationPosY, 0, sh, "%.0f")
                imgui.SliderFloat("Scale##location", locationScale, 0.5, 2.0, "%.1f")
                imgui.ColorEdit4("Color##location", locationColor)
                imgui.EndTabItem()
            end
            
            imgui.EndTabBar()
        end

        
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()
        
        -- Save Button
        if imgui.Button("SAVE CONFIG", imgui.ImVec2(-1, 40)) then
            saveConfig()
        end
        
        imgui.Spacing()
        imgui.TextColored(imgui.ImVec4(0, 1, 0, 1), "TIP: Use sliders to adjust position in real-time!")
        imgui.TextColored(imgui.ImVec4(1, 1, 0, 1), "Config will be saved to: CustomHUD.ini")
        
        imgui.End()
    end
end).HideCursor = false
