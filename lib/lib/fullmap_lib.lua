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

-- Waypoint state
local waypointX = 0
local waypointY = 0
local waypointActive = false

-- Double-tap detection
local lastTapTime = 0
local lastTapX = 0
local lastTapY = 0
local DOUBLE_TAP_TIME = 0.4
local DOUBLE_TAP_DIST = 30 -- max pixel distance between two taps

-- GPS state
local gpsPath = {} -- table of {x=, y=} world coordinates
local gpsInitialized = false
local gpsAvailable = false
local gpsLastCalcX = 0
local gpsLastCalcY = 0
local gpsLastCalcZ = 0
local gpsLastTargetX = 0
local gpsLastTargetY = 0
local gpsCacheValid = false
local GPS_RECALC_DISTANCE = 50.0

-- GPS FFI objects (lazy init)
local ffi = nil
local memory = nil
local gtasa = nil
local gpsResultNodes = nil
local gpsOutCount = nil
local gpsOutDist = nil
local gpsNullNode = nil
local gpsTmpWorld = nil
local gpsGTP = nil -- function to get CPathFind ptr

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

function fullmap.setWaypoint(wx, wy)
    waypointX = wx
    waypointY = wy
    waypointActive = true
    gpsCacheValid = false -- force GPS recalculation
    -- Also set global waypoint for native GPS hook if present
    if not _G.MINIMAP_WAYPOINT then
        _G.MINIMAP_WAYPOINT = {}
    end
    _G.MINIMAP_WAYPOINT.x = wx
    _G.MINIMAP_WAYPOINT.y = wy
    _G.MINIMAP_WAYPOINT.active = true
end

function fullmap.clearWaypoint()
    waypointActive = false
    waypointX = 0
    waypointY = 0
    gpsPath = {}
    gpsCacheValid = false
    if _G.MINIMAP_WAYPOINT then
        _G.MINIMAP_WAYPOINT.active = false
    end
end

-- Helper: world coords to UV (0-1)
local function worldToUV(wx, wy)
    local u = (wx - MAP_MIN) / MAP_RANGE
    local v = 1.0 - ((wy - MAP_MIN) / MAP_RANGE) -- Y inverted
    return u, v
end

-- Helper: UV to world coords
local function uvToWorld(u, v)
    local wx = MAP_MIN + u * MAP_RANGE
    local wy = MAP_MAX - v * MAP_RANGE
    return wx, wy
end

-- Helper: screen position to world coords (in full map context)
local function screenToWorld(sx, sy, mapX1, mapY1, mapX2, mapY2)
    local u = (sx - mapX1) / (mapX2 - mapX1)
    local v = (sy - mapY1) / (mapY2 - mapY1)
    return uvToWorld(u, v)
end

-- GPS: Lazy initialization (all FFI/memory calls wrapped in pcall)
local function initGPS()
    if gpsInitialized then return gpsAvailable end
    gpsInitialized = true
    gpsAvailable = false

    local ok = pcall(function()
        ffi = require("ffi")
        memory = require("memory")

        local BASE = MONET_GTASA_BASE
        if not BASE or BASE == 0 then
            error("No MONET_GTASA_BASE")
        end

        local GOT_THEPATHS = BASE + 0x677378
        local PF_NODES = 0x804
        local PN_SIZE = 0x1C
        local PN_POS = 0x08
        local MAX_NODES = 5000

        ffi.cdef[[
            typedef struct { float x, y, z; } CVector_gps;
            typedef struct { short areaId; short nodeId; } CNodeAddress_gps;
        ]]

        gtasa = ffi.load("GTASA")

        gpsResultNodes = ffi.new("CNodeAddress_gps[?]", MAX_NODES)
        gpsOutCount = ffi.new("int16_t[1]")
        gpsOutDist = ffi.new("float[1]")
        gpsNullNode = ffi.new("CNodeAddress_gps")
        gpsTmpWorld = ffi.new("CVector_gps")

        gpsGTP = function()
            return memory.getuint32(GOT_THEPATHS)
        end

        -- Store constants for later use
        fullmap._gps_internals = {
            BASE = BASE,
            PF_NODES = PF_NODES,
            PN_SIZE = PN_SIZE,
            PN_POS = PN_POS,
            MAX_NODES = MAX_NODES,
            GOT_THEPATHS = GOT_THEPATHS,
        }

        gpsAvailable = true
    end)

    if not ok then
        gpsAvailable = false
    end
    return gpsAvailable
end

-- GPS: Calculate path from player to waypoint
local function calculateGPSPath(playerX, playerY, playerZ)
    if not gpsAvailable then return end
    if not waypointActive then
        gpsPath = {}
        return
    end

    -- Check if recalculation needed
    if gpsCacheValid then
        local dx = playerX - gpsLastCalcX
        local dy = playerY - gpsLastCalcY
        local dz = playerZ - gpsLastCalcZ
        local moved = math.sqrt(dx*dx + dy*dy + dz*dz)
        if moved < GPS_RECALC_DISTANCE then
            local tdx = waypointX - gpsLastTargetX
            local tdy = waypointY - gpsLastTargetY
            if math.abs(tdx) < 1.0 and math.abs(tdy) < 1.0 then
                return -- cache still valid
            end
        end
    end

    local ok = pcall(function()
        local internals = fullmap._gps_internals
        local pathFind = ffi.cast("void*", gpsGTP())

        local startPos = ffi.new("CVector_gps", {x = playerX, y = playerY, z = playerZ})
        local targetPos = ffi.new("CVector_gps", {x = waypointX, y = waypointY, z = 0})

        gpsOutCount[0] = 0
        gpsOutDist[0] = 0

        -- Call DoPathSearch
        local doPathSearch = gtasa._ZN9CPathFind12DoPathSearchEh7CVector12CNodeAddressS0_PS1_PsiPffS2_fbS1_bb
        doPathSearch(
            pathFind,
            0, startPos, gpsNullNode, targetPos,
            gpsResultNodes, gpsOutCount, internals.MAX_NODES,
            gpsOutDist, 999999.0, nil, 999999.0,
            false, gpsNullNode, false, false
        )

        local nodeCount = gpsOutCount[0]
        local newPath = {}

        for i = 0, nodeCount - 1 do
            local areaId = gpsResultNodes[i].areaId
            local nodeId = gpsResultNodes[i].nodeId
            local arr = memory.getuint32(gpsGTP() + internals.PF_NODES + areaId * 4)
            if arr ~= 0 then
                local nodePtr = arr + nodeId * internals.PN_SIZE
                local p = ffi.cast("int16_t*", nodePtr + internals.PN_POS)
                local nx = p[0] / 8.0
                local ny = p[1] / 8.0
                newPath[#newPath + 1] = {x = nx, y = ny}
            end
        end

        gpsPath = newPath
        gpsCacheValid = true
        gpsLastCalcX = playerX
        gpsLastCalcY = playerY
        gpsLastCalcZ = playerZ
        gpsLastTargetX = waypointX
        gpsLastTargetY = waypointY
    end)

    if not ok then
        gpsPath = {}
        gpsCacheValid = false
    end
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
        
        -- GPS: try to initialize and calculate path
        if hasPlayer and waypointActive then
            if not gpsInitialized then
                initGPS()
            end
            if gpsAvailable then
                calculateGPSPath(playerX, playerY, playerZ)
            end
            -- Auto-clear waypoint when player is within 10m
            local wdx = playerX - waypointX
            local wdy = playerY - waypointY
            local wdist = math.sqrt(wdx*wdx + wdy*wdy)
            if wdist < 10.0 then
                fullmap.clearWaypoint()
            end
        end
        
        -- Draw GPS line on map
        if waypointActive and #gpsPath > 1 then
            local gpsColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.2, 0.5, 1.0, 0.9))
            for i = 1, #gpsPath - 1 do
                local u1, v1 = worldToUV(gpsPath[i].x, gpsPath[i].y)
                local sx1 = mapX1 + (mapX2 - mapX1) * u1
                local sy1 = mapY1 + (mapY2 - mapY1) * v1
                local u2, v2 = worldToUV(gpsPath[i+1].x, gpsPath[i+1].y)
                local sx2 = mapX1 + (mapX2 - mapX1) * u2
                local sy2 = mapY1 + (mapY2 - mapY1) * v2
                dl:AddLine(imgui.ImVec2(sx1, sy1), imgui.ImVec2(sx2, sy2), gpsColor, 3.0 * dpi)
            end
        end
        
        if hasPlayer then
            local pu, pv = worldToUV(playerX, playerY)
            local px = mapX1 + (mapX2 - mapX1) * pu
            local py = mapY1 + (mapY2 - mapY1) * pv
            
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
        
        -- Draw waypoint marker (after player arrow so it's visible)
        if waypointActive then
            local wu, wv = worldToUV(waypointX, waypointY)
            local wpx = mapX1 + (mapX2 - mapX1) * wu
            local wpy = mapY1 + (mapY2 - mapY1) * wv
            local wpRadius = 10 * dpi
            -- White border
            dl:AddCircleFilled(imgui.ImVec2(wpx, wpy), wpRadius + 2 * dpi,
                imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, 1)), 16)
            -- Red circle
            dl:AddCircleFilled(imgui.ImVec2(wpx, wpy), wpRadius,
                imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 0, 0, 1)), 16)
            -- Center dot
            dl:AddCircleFilled(imgui.ImVec2(wpx, wpy), 3 * dpi,
                imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, 1)), 8)
        end
        
        -- Drag handling with double-tap detection
        local mousePos = imgui.GetMousePos()
        if imgui.IsMouseClicked(0) then
            -- Check if click is on map area (not on buttons)
            if mousePos.x >= mapX1 and mousePos.x <= mapX2 and
               mousePos.y >= mapY1 and mousePos.y <= mapY2 then
                -- Double-tap detection
                local now = os.clock()
                local tapDx = mousePos.x - lastTapX
                local tapDy = mousePos.y - lastTapY
                local tapDist = math.sqrt(tapDx*tapDx + tapDy*tapDy)
                
                if (now - lastTapTime) < DOUBLE_TAP_TIME and tapDist < DOUBLE_TAP_DIST then
                    -- Double tap detected: set waypoint
                    local wx, wy = screenToWorld(mousePos.x, mousePos.y, mapX1, mapY1, mapX2, mapY2)
                    fullmap.setWaypoint(wx, wy)
                    lastTapTime = 0 -- reset to prevent triple-tap
                else
                    -- Single tap: start dragging
                    lastTapTime = now
                    lastTapX = mousePos.x
                    lastTapY = mousePos.y
                    dragging = true
                    lastX = mousePos.x
                    lastY = mousePos.y
                end
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
