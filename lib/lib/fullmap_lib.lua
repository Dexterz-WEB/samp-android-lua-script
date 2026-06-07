local imgui = require 'mimgui'

local fullmap = {}

-- State
local active = false
local viewCenterU = 0.5  -- UV center position (0-1)
local viewCenterV = 0.5
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
    viewCenterU = 0.5
    viewCenterV = 0.5
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
        
        -- Map display area = FIXED size (not multiplied by zoom)
        local mapDisplaySize = math.min(resX, resY) * 0.85
        local centerX = resX * 0.5
        local centerY = resY * 0.5
        local mapX1 = centerX - mapDisplaySize * 0.5
        local mapY1 = centerY - mapDisplaySize * 0.5
        local mapX2 = centerX + mapDisplaySize * 0.5
        local mapY2 = centerY + mapDisplaySize * 0.5
        
        -- Calculate UV viewport based on zoom + viewCenter
        local uvSize = 1.0 / zoom
        local uvX1 = viewCenterU - uvSize * 0.5
        local uvY1 = viewCenterV - uvSize * 0.5
        local uvX2 = viewCenterU + uvSize * 0.5
        local uvY2 = viewCenterV + uvSize * 0.5
        
        -- Clamp so UV stays within [0, 1]
        if uvX1 < 0 then viewCenterU = uvSize * 0.5; uvX1 = 0; uvX2 = uvSize end
        if uvY1 < 0 then viewCenterV = uvSize * 0.5; uvY1 = 0; uvY2 = uvSize end
        if uvX2 > 1 then viewCenterU = 1.0 - uvSize * 0.5; uvX1 = 1.0 - uvSize; uvX2 = 1.0 end
        if uvY2 > 1 then viewCenterV = 1.0 - uvSize * 0.5; uvY1 = 1.0 - uvSize; uvY2 = 1.0 end
        
        if mapTexture then
            dl:AddImage(mapTexture, imgui.ImVec2(mapX1, mapY1), imgui.ImVec2(mapX2, mapY2),
                imgui.ImVec2(uvX1, uvY1), imgui.ImVec2(uvX2, uvY2), 0xFFFFFFFF)
        else
            -- Fallback: draw colored rect representing the map with UV-based grid
            dl:AddRectFilled(imgui.ImVec2(mapX1, mapY1), imgui.ImVec2(mapX2, mapY2),
                imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.15, 0.35, 0.15, 1.0)))
            dl:AddRect(imgui.ImVec2(mapX1, mapY1), imgui.ImVec2(mapX2, mapY2),
                imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.5, 0.5, 0.5, 1.0)), 0, 15, 2)
            -- Grid lines (UV-aware)
            for i = 1, 5 do
                local frac = i / 6
                -- Only draw grid line if it falls within the UV viewport
                if frac >= uvX1 and frac <= uvX2 then
                    local gx = mapX1 + ((frac - uvX1) / (uvX2 - uvX1)) * mapDisplaySize
                    dl:AddLine(imgui.ImVec2(gx, mapY1), imgui.ImVec2(gx, mapY2),
                        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.3, 0.5, 0.3, 0.5)), 1)
                end
                if frac >= uvY1 and frac <= uvY2 then
                    local gy = mapY1 + ((frac - uvY1) / (uvY2 - uvY1)) * mapDisplaySize
                    dl:AddLine(imgui.ImVec2(mapX1, gy), imgui.ImVec2(mapX2, gy),
                        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.3, 0.5, 0.3, 0.5)), 1)
                end
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
            -- Only draw if player is within the visible UV viewport
            if pu >= uvX1 and pu <= uvX2 and pv >= uvY1 and pv <= uvY2 then
                local px = mapX1 + ((pu - uvX1) / (uvX2 - uvX1)) * mapDisplaySize
                local py = mapY1 + ((pv - uvY1) / (uvY2 - uvY1)) * mapDisplaySize
                
                if arrowTexture then
                    local arrowSize = 16 * dpi
                    dl:AddImage(arrowTexture,
                        imgui.ImVec2(px - arrowSize, py - arrowSize),
                        imgui.ImVec2(px + arrowSize, py + arrowSize),
                        imgui.ImVec2(0, 0), imgui.ImVec2(1, 1), 0xFFFFFFFF)
                else
                    -- Fallback: draw a triangle as arrow
                    local sz = 8 * dpi
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
            -- Convert pixel movement to UV movement
            local uvPerPixel = uvSize / mapDisplaySize
            viewCenterU = viewCenterU - dx * uvPerPixel
            viewCenterV = viewCenterV - dy * uvPerPixel
            -- Clamp center so viewport stays in bounds
            viewCenterU = math.max(uvSize * 0.5, math.min(1.0 - uvSize * 0.5, viewCenterU))
            viewCenterV = math.max(uvSize * 0.5, math.min(1.0 - uvSize * 0.5, viewCenterV))
            lastX = mousePos.x
            lastY = mousePos.y
        end
        
        -- UI Buttons
        local btnSize = 70 * dpi
        local btnPadding = 20 * dpi
        local btnGap = 20 * dpi
        
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
        
        -- Zoom In button (bottom-right, above zoom out with gap)
        imgui.SetCursorPos(imgui.ImVec2(resX - btnSize - btnPadding, resY - btnSize * 2 - btnPadding - btnGap))
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
        
        -- Zoom Out button (bottom-right, below zoom in)
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
