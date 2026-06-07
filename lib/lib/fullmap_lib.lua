local imgui = require 'mimgui'

local fullmap = {}

-- State
local active = false
local offsetX, offsetY = 0, 0
local zoom = 1.0
local dragging = false
local lastX, lastY = 0, 0
local mapTexture = nil
local arrowTexture = nil
local texturesLoaded = false
local textureLoadAttempted = false

-- Constants
local MAP_MIN = -3000
local MAP_MAX = 3000
local MAP_RANGE = MAP_MAX - MAP_MIN -- 6000

-- API
function fullmap.show()
    active = true
    offsetX, offsetY = 0, 0
    zoom = 1.0
    dragging = false
end

function fullmap.hide()
    active = false
    dragging = false
end

function fullmap.isActive()
    return active
end

-- Helper: world coords to UV (0-1)
local function worldToUV(wx, wy)
    local u = (wx - MAP_MIN) / MAP_RANGE
    local v = 1.0 - ((wy - MAP_MIN) / MAP_RANGE) -- Y inverted
    return u, v
end

-- Helper: load textures lazily
local function loadTextures()
    if textureLoadAttempted then return end
    textureLoadAttempted = true
    
    local workDir = ''
    pcall(function()
        workDir = getWorkingDirectory()
    end)
    
    local mapPath = workDir .. '/testing/map.png'
    local arrowPath = workDir .. '/testing/arrow.png'
    
    local ok1, tex1 = pcall(imgui.CreateTextureFromFile, mapPath)
    if ok1 and tex1 then
        mapTexture = tex1
    end
    
    local ok2, tex2 = pcall(imgui.CreateTextureFromFile, arrowPath)
    if ok2 and tex2 then
        arrowTexture = tex2
    end
    
    texturesLoaded = (mapTexture ~= nil)
end

-- Self-contained OnFrame (renders independently from RadialMenu)
imgui.OnFrame(
    function() return active end,
    function(self)
        self.HideCursor = false
        self.LockPlayer = true
        
        -- Lazy load textures on first frame
        if not textureLoadAttempted then
            loadTextures()
        end
        
        local resX, resY = getScreenResolution()
        local dpi = MONET_DPI_SCALE or 1.0
        
        -- Full screen overlay
        imgui.SetNextWindowPos(imgui.ImVec2(0, 0), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(resX, resY), imgui.Cond.Always)
        imgui.Begin('##FullMapOverlay', nil, 0
            + imgui.WindowFlags.NoTitleBar
            + imgui.WindowFlags.NoResize
            + imgui.WindowFlags.NoMove
            + imgui.WindowFlags.NoScrollbar
            + imgui.WindowFlags.NoScrollWithMouse
            + imgui.WindowFlags.NoCollapse
            + imgui.WindowFlags.NoSavedSettings
        )
        
        local dl = imgui.GetWindowDrawList()
        
        -- Background
        dl:AddRectFilled(imgui.ImVec2(0, 0), imgui.ImVec2(resX, resY), imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.1, 0.1, 0.1, 0.95)))
        
        -- Map rendering area
        local mapSize = math.min(resX, resY) * 0.85 * zoom
        local centerX = resX * 0.5 + offsetX
        local centerY = resY * 0.5 + offsetY
        local mapX1 = centerX - mapSize * 0.5
        local mapY1 = centerY - mapSize * 0.5
        local mapX2 = centerX + mapSize * 0.5
        local mapY2 = centerY + mapSize * 0.5
        
        if mapTexture then
            dl:AddImage(mapTexture, imgui.ImVec2(mapX1, mapY1), imgui.ImVec2(mapX2, mapY2),
                imgui.ImVec2(0, 0), imgui.ImVec2(1, 1), 0xFFFFFFFF)
        else
            -- Fallback: draw colored rect representing the map
            dl:AddRectFilled(imgui.ImVec2(mapX1, mapY1), imgui.ImVec2(mapX2, mapY2),
                imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.15, 0.35, 0.15, 1.0)))
            dl:AddRect(imgui.ImVec2(mapX1, mapY1), imgui.ImVec2(mapX2, mapY2),
                imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.5, 0.5, 0.5, 1.0)), 0, 15, 2)
            -- Grid lines
            for i = 1, 5 do
                local frac = i / 6
                local gx = mapX1 + (mapX2 - mapX1) * frac
                local gy = mapY1 + (mapY2 - mapY1) * frac
                dl:AddLine(imgui.ImVec2(gx, mapY1), imgui.ImVec2(gx, mapY2),
                    imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.3, 0.5, 0.3, 0.5)), 1)
                dl:AddLine(imgui.ImVec2(mapX1, gy), imgui.ImVec2(mapX2, gy),
                    imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.3, 0.5, 0.3, 0.5)), 1)
            end
            -- "MAP" text in center
            local textPos = imgui.ImVec2(centerX - 20, centerY - 8)
            dl:AddText(textPos, 0xFFFFFFFF, "MAP")
        end
        
        -- Draw player position arrow
        local playerX, playerY, playerZ = 0, 0, 0
        local hasPlayer = false
        pcall(function()
            if PLAYER_PED and doesCharExist(PLAYER_PED) then
                playerX, playerY, playerZ = getCharCoordinates(PLAYER_PED)
                hasPlayer = true
            end
        end)
        
        if hasPlayer then
            local pu, pv = worldToUV(playerX, playerY)
            local px = mapX1 + (mapX2 - mapX1) * pu
            local py = mapY1 + (mapY2 - mapY1) * pv
            
            if arrowTexture then
                local arrowSize = 16 * dpi * zoom
                dl:AddImage(arrowTexture,
                    imgui.ImVec2(px - arrowSize, py - arrowSize),
                    imgui.ImVec2(px + arrowSize, py + arrowSize),
                    imgui.ImVec2(0, 0), imgui.ImVec2(1, 1), 0xFFFFFFFF)
            else
                -- Fallback: draw a triangle as arrow
                local sz = 8 * dpi * zoom
                dl:AddTriangleFilled(
                    imgui.ImVec2(px, py - sz),
                    imgui.ImVec2(px - sz * 0.6, py + sz * 0.6),
                    imgui.ImVec2(px + sz * 0.6, py + sz * 0.6),
                    imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, 1))
                )
                -- Outline
                dl:AddTriangle(
                    imgui.ImVec2(px, py - sz),
                    imgui.ImVec2(px - sz * 0.6, py + sz * 0.6),
                    imgui.ImVec2(px + sz * 0.6, py + sz * 0.6),
                    imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0, 0, 0, 1)), 2
                )
            end
        end
        
        -- Drag handling
        local mousePos = imgui.GetMousePos()
        if imgui.IsMouseClicked(0) then
            -- Check if click is on map area (not on buttons)
            if mousePos.x >= mapX1 and mousePos.x <= mapX2 and
               mousePos.y >= mapY1 and mousePos.y <= mapY2 then
                dragging = true
                lastX = mousePos.x
                lastY = mousePos.y
            end
        end
        
        if imgui.IsMouseReleased(0) then
            dragging = false
        end
        
        if dragging and imgui.IsMouseDown(0) then
            local dx = mousePos.x - lastX
            local dy = mousePos.y - lastY
            offsetX = offsetX + dx
            offsetY = offsetY + dy
            lastX = mousePos.x
            lastY = mousePos.y
            
            -- Clamp offset to prevent dragging too far
            local maxOffset = mapSize * 0.5
            if offsetX > maxOffset then offsetX = maxOffset end
            if offsetX < -maxOffset then offsetX = -maxOffset end
            if offsetY > maxOffset then offsetY = maxOffset end
            if offsetY < -maxOffset then offsetY = -maxOffset end
        end
        
        -- UI Buttons
        local btnSize = 40 * dpi
        local btnPadding = 10 * dpi
        
        -- Close button (top-right)
        imgui.SetCursorPos(imgui.ImVec2(resX - btnSize - btnPadding, btnPadding))
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8, 0.2, 0.2, 0.9))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(1.0, 0.3, 0.3, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.6, 0.1, 0.1, 1.0))
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, btnSize * 0.5)
        if imgui.Button('X##fullmap_close', imgui.ImVec2(btnSize, btnSize)) then
            fullmap.hide()
        end
        imgui.PopStyleVar()
        imgui.PopStyleColor(3)
        
        -- Zoom In button (bottom-right)
        imgui.SetCursorPos(imgui.ImVec2(resX - btnSize - btnPadding, resY - btnSize * 2 - btnPadding * 2))
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.2, 0.2, 0.9))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.3, 0.3, 0.3, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.15, 0.15, 0.15, 1.0))
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, btnSize * 0.5)
        if imgui.Button('+##fullmap_zin', imgui.ImVec2(btnSize, btnSize)) then
            zoom = zoom + 0.25
            if zoom > 4.0 then zoom = 4.0 end
        end
        imgui.PopStyleVar()
        imgui.PopStyleColor(3)
        
        -- Zoom Out button (below zoom in)
        imgui.SetCursorPos(imgui.ImVec2(resX - btnSize - btnPadding, resY - btnSize - btnPadding))
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.2, 0.2, 0.9))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.3, 0.3, 0.3, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.15, 0.15, 0.15, 1.0))
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, btnSize * 0.5)
        if imgui.Button('-##fullmap_zout', imgui.ImVec2(btnSize, btnSize)) then
            zoom = zoom - 0.25
            if zoom < 0.5 then zoom = 0.5 end
        end
        imgui.PopStyleVar()
        imgui.PopStyleColor(3)
        
        imgui.End()
    end
)

return fullmap
