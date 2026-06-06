-- ============================================================================
-- MINIMAP GPS v1.0
-- Custom minimap + GPS pathfinding combined into one standalone script
-- Created by OnlyDexterZ
-- ============================================================================

script_name("MinimapGPS")
script_author("OnlyDexterZ")

-- ============================================================================
-- SAFE LIBRARY LOADING
-- ============================================================================
local imgui = require 'mimgui'
local inicfg = require 'inicfg'
local ffi = require("ffi")
local memory = require("memory")
local hook = require("monethook")

local BASE = MONET_GTASA_BASE

-- ============================================================================
-- GPS CONSTANTS
-- ============================================================================
local MAX_NODES = 7000
local GPS_WIDTH = 6.0
local GPS_COLOR = 0xFF1818B4

local rwTRISTRIP = 4
local rwTEX_RAST = 1

local GOT_THEPATHS = BASE + 0x677378
local GOT_GMM = BASE + 0x679CCC
local GOT_MSRT = BASE + 0x6773CC
local GOT_RSG = BASE + 0x67910C

local MM_TBLIP = 0x48
local MM_ZOOM = 0x58
local MM_DRAWMAP = 0x6C

local RT_SIZE = 0x28
local RT_POS = 0x08
local RT_CTR = 0x14
local RT_DISP = 0x26

local PF_NODES = 0x804
local PN_SIZE = 0x1C
local PN_POS = 0x08

-- ============================================================================
-- FFI DECLARATIONS
-- ============================================================================
ffi.cdef[[
typedef struct { float x, y, z; } CVector;
typedef struct { float x, y; } CVector2D;
typedef struct { short areaId; short nodeId; } CNodeAddress;
typedef struct { float x, y, z, rhw; uint32_t color; float u, v; } RwIm2DVertex;
typedef struct { float x, y, z, rhw; unsigned int color; float u, v; } RwOpenGLVertex;

void* _Z13FindPlayerPedi(int n);
CVector _Z15FindPlayerCoorsi(int n);

void _ZN9CPathFind12DoPathSearchEh7CVector12CNodeAddressS0_PS1_PsiPffS2_fbS1_bb(
    void* thiz, uint8_t graphType,
    CVector startCoors, CNodeAddress startNode,
    CVector targetCoors, CNodeAddress* pNodeList,
    int16_t* pNumNodes, int32_t numReq,
    float* pDist, float cutoff,
    CNodeAddress* pGivenTarget, float maxDist,
    bool noWrongWay, CNodeAddress avoid,
    bool amphibious, bool boat
);

void _ZN6CRadar32TransformRadarPointToScreenSpaceER9CVector2DRKS0_(CVector2D* scr, CVector2D* rad);
void _ZN6CRadar35TransformRealWorldPointToRadarSpaceER9CVector2DRKS0_(CVector2D* rad, CVector* world);
void _ZN6CRadar15LimitRadarPointER9CVector2D(CVector2D* rad);
void _ZN6CRadar10LimitToMapEPfS0_(float* x, float* y);
float _ZN6CWorld19FindGroundZForCoordEff(float x, float y);
void _ZN6CRadar12DrawRadarMapEv(void* thiz);

bool _Z16RwRenderStateSet13RwRenderStatePv(uint32_t state, void* value);
bool _Z28RwIm2DRenderPrimitive_BUGFIX15RwPrimitiveTypeP14RwOpenGLVertexi(uint32_t primType, RwIm2DVertex* verts, int32_t count);
]]

local gtasa = ffi.load("GTASA")

-- ============================================================================
-- CONFIG
-- ============================================================================
local iniFileName = "MinimapGPSConfig.ini"

local defaultConfig = {
    Settings = {
        minimapEnabled = true,
        radarDisabled = true,
        posX = 20.0,
        posY = 500.0,
        size = 200.0,
        opacity = 0.85,
        arrowSize = 24.0,
        zoomLevel = 0.05,
        gpsLineColor = 0xFF1818B4,
    },
}

local iniData = inicfg.load(defaultConfig, iniFileName)
if not iniData then
    inicfg.save(defaultConfig, iniFileName)
    iniData = defaultConfig
end
if not iniData.Settings then iniData.Settings = defaultConfig.Settings end
for k, v in pairs(defaultConfig.Settings) do
    if iniData.Settings[k] == nil then iniData.Settings[k] = v end
end

-- ============================================================================
-- STATE VARIABLES
-- ============================================================================
local showConfigWindow = imgui.new.bool(false)
local fullMapMode = false

-- Textures
local mapTexture = nil
local arrowTexture = nil

-- Config sliders
local cfgEnabled = imgui.new.bool(iniData.Settings.minimapEnabled)
local cfgRadarOff = imgui.new.bool(iniData.Settings.radarDisabled)
local cfgPosX = imgui.new.float(iniData.Settings.posX)
local cfgPosY = imgui.new.float(iniData.Settings.posY)
local cfgSize = imgui.new.float(iniData.Settings.size)
local cfgOpacity = imgui.new.float(iniData.Settings.opacity)
local cfgArrowSize = imgui.new.float(iniData.Settings.arrowSize)
local cfgZoom = imgui.new.float(iniData.Settings.zoomLevel)

-- Full map state
local fullMapOffsetX = 0
local fullMapOffsetY = 0
local fullMapZoom = 1.0
local fullMapDragging = false
local fullMapLastX = 0
local fullMapLastY = 0
local fullMapOpenTime = 0

-- Waypoint system
local waypointActive = false
local waypointX = 0.0
local waypointY = 0.0
local waypointZ = 0.0
local lastTapTime = 0
local DOUBLE_TAP_INTERVAL = 0.4
local lastTapX = 0
local lastTapY = 0

-- Player cached data
local cachedPlayerX = 0
local cachedPlayerY = 0
local cachedPlayerZ = 0
local cachedHeading = 0

-- ============================================================================
-- GPS PATHFINDING STATE
-- ============================================================================
local cachedNodeCount = 0
local cachedDistance = 0.0
local lastCalcX = 0.0
local lastCalcY = 0.0
local lastCalcZ = 0.0
local lastTargetX = 0.0
local lastTargetY = 0.0
local RECALC_DISTANCE = 30.0
local cacheValid = false

local resultNodes = ffi.new("CNodeAddress[?]", MAX_NODES)
local nodePoints = ffi.new("CVector2D[?]", MAX_NODES)
local nodeRad = ffi.new("CVector2D[?]", MAX_NODES)
local lineVerts = ffi.new("RwIm2DVertex[?]", MAX_NODES * 4)
local nullNode = ffi.new("CNodeAddress")
local tmpRad = ffi.new("CVector2D")
local tmpWorld = ffi.new("CVector")
local clipR0 = ffi.new("CVector2D")
local clipR1 = ffi.new("CVector2D")
local clipS0 = ffi.new("CVector2D")
local clipS1 = ffi.new("CVector2D")
local outCount = ffi.new("int16_t[1]")
local outDist = ffi.new("float[1]")

local gpsShown = false
local gpsDistance = 0.0

-- Cached path world coordinates for drawing on custom minimap/full map
local cachedPathWorldCoords = {}

-- ============================================================================
-- TEXTURE LOADING
-- ============================================================================
imgui.OnInitialize(function()
    pcall(function()
        mapTexture = imgui.CreateTextureFromFile("testing/map.png")
    end)
    pcall(function()
        arrowTexture = imgui.CreateTextureFromFile("testing/arrow.png")
    end)
end)

-- ============================================================================
-- GPS HELPER FUNCTIONS
-- ============================================================================
local function gmm() return memory.getuint32(GOT_GMM) end
local function gtp() return memory.getuint32(GOT_THEPATHS) end
local function grt() return memory.getuint32(GOT_MSRT) end
local function grsg() return memory.getuint32(GOT_RSG) end

local function ValidBlipHandle(h)
    if h == 0 then return false end
    local idx = bit.band(h, 0xFFFF)
    local ctr = bit.rshift(h, 16)
    local tr = grt() + idx * RT_SIZE
    return memory.getuint16(tr + RT_CTR) == ctr
       and bit.band(memory.getuint8(tr + RT_DISP), 0x3) ~= 0
end

local function GetPathNode(areaId, nodeId)
    local arr = memory.getuint32(gtp() + PF_NODES + areaId * 4)
    return arr ~= 0 and (arr + nodeId * PN_SIZE) or nil
end

local function GetNodeCoors(np)
    local p = ffi.cast("int16_t*", np + PN_POS)
    return p[0] / 8.0, p[1] / 8.0, p[2] / 8.0
end

local function Setup2dVert(v, x, y)
    v.x = x; v.y = y; v.z = 0.0001; v.rhw = 1.0
    v.color = GPS_COLOR; v.u = 0.0; v.v = 0.0
end

local function clipSegCircle(x0, y0, x1, y1)
    local dx, dy = x1 - x0, y1 - y0
    local a = dx * dx + dy * dy
    if a < 1e-10 then
        return (x0 * x0 + y0 * y0 <= 1.0) and x0, y0, x1, y1 or nil
    end
    local b = 2 * (x0 * dx + y0 * dy)
    local c = x0 * x0 + y0 * y0 - 1.0
    local disc = b * b - 4 * a * c
    local t0, t1 = 0.0, 1.0
    if disc >= 0 then
        local sd = math.sqrt(disc)
        local ta = (-b - sd) / (2 * a)
        local tb = (-b + sd) / (2 * a)
        if ta > t0 then t0 = ta end
        if tb < t1 then t1 = tb end
        if t0 > t1 then return nil end
    else
        if c > 0 then return nil end
    end
    return x0 + t0 * dx, y0 + t0 * dy,
           x0 + t1 * dx, y0 + t1 * dy
end

local function needsRecalculation(px, py, pz, tx, ty)
    if not cacheValid then return true end
    local dx = px - lastCalcX
    local dy = py - lastCalcY
    local dz = pz - lastCalcZ
    local playerMoved = math.sqrt(dx * dx + dy * dy + dz * dz)
    if playerMoved > RECALC_DISTANCE then return true end
    if math.abs(tx - lastTargetX) > 1.0 or math.abs(ty - lastTargetY) > 1.0 then return true end
    return false
end

local function isPlayerInVehicle()
    local result = false
    pcall(function()
        result = isCharInAnyCar(PLAYER_PED)
    end)
    return result
end

local function getDistanceToTarget(px, py, pz, tx, ty, tz)
    local dx = px - tx
    local dy = py - ty
    local dz = pz - tz
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- ============================================================================
-- MINIMAP HELPER FUNCTIONS
-- ============================================================================
local function clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

local function getPlayerData()
    local ok, x, y, z = pcall(getCharCoordinates, PLAYER_PED)
    if ok and x then
        cachedPlayerX = x
        cachedPlayerY = y
        cachedPlayerZ = z
    end
    local ok2, h = pcall(getCharHeading, PLAYER_PED)
    if ok2 and h then
        cachedHeading = h
    end
end

local function worldToUV(wx, wy)
    local uvx = (wx + 3000) / 6000
    local uvy = 1.0 - (wy + 3000) / 6000
    return uvx, uvy
end

local function uvToWorld(uvx, uvy)
    local wx = uvx * 6000 - 3000
    local wy = (1.0 - uvy) * 6000 - 3000
    return wx, wy
end

local function drawRotatedImage(draw_list, texture, cx, cy, size, angle, color)
    local adjustedAngle = angle - math.pi / 2
    local cos_a = math.cos(adjustedAngle)
    local sin_a = math.sin(adjustedAngle)
    local half = size / 2
    local p1 = imgui.ImVec2(cx + (-half * cos_a - (-half) * sin_a), cy + (-half * sin_a + (-half) * cos_a))
    local p2 = imgui.ImVec2(cx + (half * cos_a - (-half) * sin_a), cy + (half * sin_a + (-half) * cos_a))
    local p3 = imgui.ImVec2(cx + (half * cos_a - half * sin_a), cy + (half * sin_a + half * cos_a))
    local p4 = imgui.ImVec2(cx + (-half * cos_a - half * sin_a), cy + (-half * sin_a + half * cos_a))
    draw_list:AddImageQuad(texture, p1, p2, p3, p4,
        imgui.ImVec2(0, 0), imgui.ImVec2(1, 0), imgui.ImVec2(1, 1), imgui.ImVec2(0, 1), color)
end

local function isPointInCircle(px, py, cx, cy, r)
    local dx = px - cx
    local dy = py - cy
    return (dx * dx + dy * dy) <= (r * r)
end

local function getDistanceTo(tx, ty)
    local dx = cachedPlayerX - tx
    local dy = cachedPlayerY - ty
    return math.sqrt(dx * dx + dy * dy)
end

local function setGPSWaypoint(wx, wy)
    _G.MINIMAP_WAYPOINT = { x = wx, y = wy, active = true }
end

local function removeGPSWaypoint()
    _G.MINIMAP_WAYPOINT = { x = 0, y = 0, active = false }
end

local function saveConfig()
    iniData.Settings.minimapEnabled = cfgEnabled[0]
    iniData.Settings.radarDisabled = cfgRadarOff[0]
    iniData.Settings.posX = cfgPosX[0]
    iniData.Settings.posY = cfgPosY[0]
    iniData.Settings.size = cfgSize[0]
    iniData.Settings.opacity = cfgOpacity[0]
    iniData.Settings.arrowSize = cfgArrowSize[0]
    iniData.Settings.zoomLevel = cfgZoom[0]
    if inicfg.save(iniData, iniFileName) then
        sampAddChatMessage("{00FF00}[MinimapGPS] {FFFFFF}Configuration saved!", -1)
    else
        sampAddChatMessage("{FF0000}[MinimapGPS] {FFFFFF}Failed to save config!", -1)
    end
end

-- ============================================================================
-- GPS LINE DRAWING ON CUSTOM MAP
-- ============================================================================
local function drawGPSLineOnMinimap(draw_list, posX, posY, mapSize, uvMinX, uvMinY, uvMaxX, uvMaxY, opacity)
    if not gpsShown or #cachedPathWorldCoords < 2 then return end

    local lineColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.1, 0.1, 0.7, 0.8 * opacity))
    local radius = mapSize / 2
    local centerX = posX + radius
    local centerY = posY + radius

    for i = 1, #cachedPathWorldCoords - 1 do
        local n0 = cachedPathWorldCoords[i]
        local n1 = cachedPathWorldCoords[i + 1]

        local uv0x, uv0y = worldToUV(n0.x, n0.y)
        local uv1x, uv1y = worldToUV(n1.x, n1.y)

        -- Check if segment is within visible UV area
        local inBounds0 = uv0x >= uvMinX and uv0x <= uvMaxX and uv0y >= uvMinY and uv0y <= uvMaxY
        local inBounds1 = uv1x >= uvMinX and uv1x <= uvMaxX and uv1y >= uvMinY and uv1y <= uvMaxY

        if inBounds0 or inBounds1 then
            -- Convert UV to screen position within minimap
            local sx0 = posX + ((uv0x - uvMinX) / (uvMaxX - uvMinX)) * mapSize
            local sy0 = posY + ((uv0y - uvMinY) / (uvMaxY - uvMinY)) * mapSize
            local sx1 = posX + ((uv1x - uvMinX) / (uvMaxX - uvMinX)) * mapSize
            local sy1 = posY + ((uv1y - uvMinY) / (uvMaxY - uvMinY)) * mapSize

            -- Clip to circular minimap (simple distance check from center)
            local d0 = math.sqrt((sx0 - centerX)^2 + (sy0 - centerY)^2)
            local d1 = math.sqrt((sx1 - centerX)^2 + (sy1 - centerY)^2)

            if d0 <= radius or d1 <= radius then
                draw_list:AddLine(
                    imgui.ImVec2(sx0, sy0),
                    imgui.ImVec2(sx1, sy1),
                    lineColor, 2.0
                )
            end
        end
    end
end

local function drawGPSLineOnFullMap(draw_list, mapX, mapY, mapDisplaySize)
    if not gpsShown or #cachedPathWorldCoords < 2 then return end

    local lineColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.1, 0.1, 0.7, 0.8))

    for i = 1, #cachedPathWorldCoords - 1 do
        local n0 = cachedPathWorldCoords[i]
        local n1 = cachedPathWorldCoords[i + 1]

        local uv0x, uv0y = worldToUV(n0.x, n0.y)
        local uv1x, uv1y = worldToUV(n1.x, n1.y)

        local sx0 = mapX + uv0x * mapDisplaySize
        local sy0 = mapY + uv0y * mapDisplaySize
        local sx1 = mapX + uv1x * mapDisplaySize
        local sy1 = mapY + uv1y * mapDisplaySize

        draw_list:AddLine(
            imgui.ImVec2(sx0, sy0),
            imgui.ImVec2(sx1, sy1),
            lineColor, 3.0
        )
    end
end

-- ============================================================================
-- MINIMAP RENDERING
-- ============================================================================
local function drawMinimap(draw_list)
    if not mapTexture then return end
    if not cfgEnabled[0] then return end

    local spawned = false
    pcall(function() spawned = sampIsLocalPlayerSpawned() end)
    if not spawned then return end

    getPlayerData()

    local mapSize = cfgSize[0]
    local posX = cfgPosX[0]
    local posY = cfgPosY[0]
    local opacity = cfgOpacity[0]
    local zoom = cfgZoom[0]
    local arrowSz = cfgArrowSize[0]

    local centerX = posX + mapSize / 2
    local centerY = posY + mapSize / 2
    local radius = mapSize / 2

    -- Calculate UV based on player position
    local uvCenterX, uvCenterY = worldToUV(cachedPlayerX, cachedPlayerY)

    -- UV crop area
    local uvHalf = zoom
    local uvMinX = clamp(uvCenterX - uvHalf, 0, 1)
    local uvMinY = clamp(uvCenterY - uvHalf, 0, 1)
    local uvMaxX = clamp(uvCenterX + uvHalf, 0, 1)
    local uvMaxY = clamp(uvCenterY + uvHalf, 0, 1)

    -- Draw circular minimap using AddImageRounded
    local colorU32 = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, opacity))
    local pMin = imgui.ImVec2(posX, posY)
    local pMax = imgui.ImVec2(posX + mapSize, posY + mapSize)
    local uvMin = imgui.ImVec2(uvMinX, uvMinY)
    local uvMax = imgui.ImVec2(uvMaxX, uvMaxY)

    draw_list:AddImageRounded(mapTexture, pMin, pMax, uvMin, uvMax, colorU32, radius, 15)

    -- Draw GPS line on minimap
    drawGPSLineOnMinimap(draw_list, posX, posY, mapSize, uvMinX, uvMinY, uvMaxX, uvMaxY, opacity)

    -- Draw waypoint on minimap
    if waypointActive then
        local wpUVX, wpUVY = worldToUV(waypointX, waypointY)
        if wpUVX >= uvMinX and wpUVX <= uvMaxX and wpUVY >= uvMinY and wpUVY <= uvMaxY then
            local wpLocalX = posX + ((wpUVX - uvMinX) / (uvMaxX - uvMinX)) * mapSize
            local wpLocalY = posY + ((wpUVY - uvMinY) / (uvMaxY - uvMinY)) * mapSize
            -- Check inside circle
            if isPointInCircle(wpLocalX, wpLocalY, centerX, centerY, radius) then
                draw_list:AddCircleFilled(imgui.ImVec2(wpLocalX, wpLocalY), 6,
                    imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.0, 0.2, 0.2, opacity)), 12)
                draw_list:AddCircle(imgui.ImVec2(wpLocalX, wpLocalY), 6,
                    imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, opacity)), 12, 2)
            end
        end

        -- Auto clear if < 10m
        local dist = getDistanceTo(waypointX, waypointY)
        if dist < 10.0 then
            waypointActive = false
            removeGPSWaypoint()
        end
    end

    -- Draw player arrow in center (rotated by heading)
    if arrowTexture then
        local headingRad = -math.rad(cachedHeading)
        local arrowColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, opacity))
        drawRotatedImage(draw_list, arrowTexture, centerX, centerY, arrowSz, headingRad, arrowColor)
    end

    -- Tap detection for opening full map
    local io = imgui.GetIO()
    if imgui.IsMouseClicked(0) then
        local mx = io.MousePos.x
        local my = io.MousePos.y
        if isPointInCircle(mx, my, centerX, centerY, radius) then
            fullMapMode = true
            fullMapOffsetX = 0
            fullMapOffsetY = 0
            fullMapZoom = 1.0
            fullMapDragging = false
            fullMapOpenTime = os.clock()
        end
    end
end

-- ============================================================================
-- FULL MAP RENDERING
-- ============================================================================
local function drawFullMap(draw_list)
    if not mapTexture then return end

    local sw, sh = 0, 0
    pcall(function() sw, sh = getScreenResolution() end)
    if sw == 0 or sh == 0 then sw, sh = 1280, 720 end

    -- Lock player control to prevent camera movement during full map
    pcall(function() lockPlayerControl(true) end)

    local io = imgui.GetIO()
    local mx = io.MousePos.x
    local my = io.MousePos.y

    -- Background overlay
    draw_list:AddRectFilled(
        imgui.ImVec2(0, 0),
        imgui.ImVec2(sw, sh),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0, 0, 0, 0.7))
    )

    -- Get player UV position for centering zoom on player
    getPlayerData()
    local playerUVX, playerUVY = worldToUV(cachedPlayerX, cachedPlayerY)

    -- Calculate map display area (zoom centered on player position)
    local baseSize = math.min(sw, sh) * 0.9
    local mapDisplaySize = baseSize * fullMapZoom

    -- Center map so that player is at screen center, then apply drag offset
    local playerScreenX = sw / 2
    local playerScreenY = sh / 2
    local mapX = playerScreenX - (playerUVX * mapDisplaySize) + fullMapOffsetX
    local mapY = playerScreenY - (playerUVY * mapDisplaySize) + fullMapOffsetY

    -- Draw the full map
    local pMin = imgui.ImVec2(mapX, mapY)
    local pMax = imgui.ImVec2(mapX + mapDisplaySize, mapY + mapDisplaySize)
    local colorU32 = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, 0.95))
    draw_list:AddImage(mapTexture, pMin, pMax, imgui.ImVec2(0, 0), imgui.ImVec2(1, 1), colorU32)

    -- Draw GPS line on full map
    drawGPSLineOnFullMap(draw_list, mapX, mapY, mapDisplaySize)

    -- Draw waypoint pin on full map
    if waypointActive then
        local wpUVX, wpUVY = worldToUV(waypointX, waypointY)
        local wpScreenX = mapX + wpUVX * mapDisplaySize
        local wpScreenY = mapY + wpUVY * mapDisplaySize

        -- Pin shape (triangle + circle)
        local pinColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.0, 0.2, 0.2, 1.0))
        local pinOutline = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.0, 1.0, 1.0, 1.0))

        -- Pin circle (top)
        draw_list:AddCircleFilled(imgui.ImVec2(wpScreenX, wpScreenY - 20), 10, pinColor, 16)
        draw_list:AddCircle(imgui.ImVec2(wpScreenX, wpScreenY - 20), 10, pinOutline, 16, 2)

        -- Pin triangle (bottom point)
        draw_list:AddTriangleFilled(
            imgui.ImVec2(wpScreenX - 7, wpScreenY - 14),
            imgui.ImVec2(wpScreenX + 7, wpScreenY - 14),
            imgui.ImVec2(wpScreenX, wpScreenY),
            pinColor
        )

        -- Inner white dot
        draw_list:AddCircleFilled(imgui.ImVec2(wpScreenX, wpScreenY - 20), 4, pinOutline, 12)

        -- Distance text
        local dist = getDistanceTo(waypointX, waypointY)
        local distText = string.format("%.0fm", dist)
        local distSize = imgui.CalcTextSize(distText)
        draw_list:AddText(
            imgui.ImVec2(wpScreenX - distSize.x / 2, wpScreenY + 5),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, 1)),
            distText
        )

        -- Auto clear if < 10m
        if dist < 10.0 then
            waypointActive = false
            removeGPSWaypoint()
        end
    end

    -- Draw player arrow on full map
    if arrowTexture then
        local playerMapX = mapX + playerUVX * mapDisplaySize
        local playerMapY = mapY + playerUVY * mapDisplaySize
        local headingRad = -math.rad(cachedHeading)
        local arrowSz = 28
        local arrowColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, 1))
        drawRotatedImage(draw_list, arrowTexture, playerMapX, playerMapY, arrowSz, headingRad, arrowColor)
    end

    -- Handle drag (touch hold and move)
    if imgui.IsMouseDown(0) then
        if not fullMapDragging then
            fullMapDragging = true
            fullMapLastX = mx
            fullMapLastY = my
        else
            local dx = mx - fullMapLastX
            local dy = my - fullMapLastY
            fullMapOffsetX = fullMapOffsetX + dx
            fullMapOffsetY = fullMapOffsetY + dy
            fullMapLastX = mx
            fullMapLastY = my
        end
    else
        fullMapDragging = false
    end

    -- Clamp drag so map edge stays visible on screen
    local maxOffsetX = math.max(0, (mapDisplaySize - sw) / 2 + sw / 2)
    local maxOffsetY = math.max(0, (mapDisplaySize - sh) / 2 + sh / 2)
    fullMapOffsetX = clamp(fullMapOffsetX, -maxOffsetX, maxOffsetX)
    fullMapOffsetY = clamp(fullMapOffsetY, -maxOffsetY, maxOffsetY)

    -- Zoom controls (draw +/- buttons)
    local btnSize = 50
    local zoomInPos = imgui.ImVec2(sw - btnSize - 20, sh / 2 - btnSize - 10)
    local zoomOutPos = imgui.ImVec2(sw - btnSize - 20, sh / 2 + 10)

    -- Zoom In button
    draw_list:AddRectFilled(zoomInPos, imgui.ImVec2(zoomInPos.x + btnSize, zoomInPos.y + btnSize),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.2, 0.2, 0.3, 0.9)), 8)
    local plusSize = imgui.CalcTextSize("+")
    draw_list:AddText(imgui.ImVec2(zoomInPos.x + (btnSize - plusSize.x) / 2, zoomInPos.y + (btnSize - plusSize.y) / 2),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, 1)), "+")

    -- Zoom Out button
    draw_list:AddRectFilled(zoomOutPos, imgui.ImVec2(zoomOutPos.x + btnSize, zoomOutPos.y + btnSize),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.2, 0.2, 0.3, 0.9)), 8)
    local minusSize = imgui.CalcTextSize("-")
    draw_list:AddText(imgui.ImVec2(zoomOutPos.x + (btnSize - minusSize.x) / 2, zoomOutPos.y + (btnSize - minusSize.y) / 2),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, 1)), "-")

    -- Close button (top-right)
    local closeBtnPos = imgui.ImVec2(sw - btnSize - 20, 20)
    draw_list:AddRectFilled(closeBtnPos, imgui.ImVec2(closeBtnPos.x + btnSize, closeBtnPos.y + btnSize),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.6, 0.1, 0.1, 0.9)), 8)
    local xSize = imgui.CalcTextSize("X")
    draw_list:AddText(imgui.ImVec2(closeBtnPos.x + (btnSize - xSize.x) / 2, closeBtnPos.y + (btnSize - xSize.y) / 2),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, 1)), "X")

    -- Handle tap for buttons (X button and zoom only)
    local mapCooldown = (os.clock() - fullMapOpenTime) > 0.3
    if imgui.IsMouseClicked(0) and mapCooldown then
        -- Zoom In
        if mx >= zoomInPos.x and mx <= zoomInPos.x + btnSize and my >= zoomInPos.y and my <= zoomInPos.y + btnSize then
            fullMapZoom = clamp(fullMapZoom + 0.3, 0.5, 5.0)
            return
        end
        -- Zoom Out
        if mx >= zoomOutPos.x and mx <= zoomOutPos.x + btnSize and my >= zoomOutPos.y and my <= zoomOutPos.y + btnSize then
            fullMapZoom = clamp(fullMapZoom - 0.3, 0.5, 5.0)
            return
        end
        -- Close button
        if mx >= closeBtnPos.x and mx <= closeBtnPos.x + btnSize and my >= closeBtnPos.y and my <= closeBtnPos.y + btnSize then
            fullMapMode = false
            pcall(function() lockPlayerControl(false) end)
            return
        end

        -- Double tap detection for waypoint (on map area only)
        if mx >= mapX and mx <= mapX + mapDisplaySize and my >= mapY and my <= mapY + mapDisplaySize then
            local now = os.clock()
            local tapDist = math.sqrt((mx - lastTapX)^2 + (my - lastTapY)^2)
            if (now - lastTapTime) < DOUBLE_TAP_INTERVAL and tapDist < 50 then
                -- DOUBLE TAP DETECTED
                if waypointActive then
                    -- Remove waypoint
                    waypointActive = false
                    removeGPSWaypoint()
                    cacheValid = false
                else
                    -- Set waypoint: convert screen tap to world coords
                    local tapUVX = (mx - mapX) / mapDisplaySize
                    local tapUVY = (my - mapY) / mapDisplaySize
                    local wx, wy = uvToWorld(tapUVX, tapUVY)
                    waypointX = wx
                    waypointY = wy
                    waypointZ = 0
                    waypointActive = true
                    setGPSWaypoint(wx, wy)
                    cacheValid = false
                end
                lastTapTime = 0
            else
                lastTapTime = now
                lastTapX = mx
                lastTapY = my
            end
        end
    end
end

-- ============================================================================
-- CONFIG WINDOW
-- ============================================================================
local function drawConfigWindow()
    if not showConfigWindow[0] then return end

    local sw, sh = 0, 0
    pcall(function() sw, sh = getScreenResolution() end)
    if sw == 0 or sh == 0 then sw, sh = 1280, 720 end

    local winW = 450
    local winH = 420

    imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12)
    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(15, 12))
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 6)
    imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(8, 6))
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.08, 0.08, 0.1, 0.95))
    imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.15, 0.15, 0.2, 1.0))
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.2, 0.3, 1.0))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.3, 0.3, 0.5, 1.0))
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.15, 0.4, 0.8, 1.0))
    imgui.PushStyleColor(imgui.Col.SliderGrab, imgui.ImVec4(0.3, 0.6, 0.9, 1.0))
    imgui.PushStyleColor(imgui.Col.CheckMark, imgui.ImVec4(0.3, 0.8, 0.4, 1.0))

    imgui.SetNextWindowPos(imgui.ImVec2((sw - winW) / 2, (sh - winH) / 2), imgui.Cond.Always)
    imgui.SetNextWindowSize(imgui.ImVec2(winW, winH))
    imgui.Begin("MinimapGPS Config", showConfigWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar)

    -- Title
    imgui.TextColored(imgui.ImVec4(0.3, 0.8, 1.0, 1.0), "MINIMAP GPS CONFIG")
    imgui.Spacing()
    imgui.Separator()
    imgui.Spacing()

    -- Toggles
    imgui.TextColored(imgui.ImVec4(0.2, 0.9, 0.4, 1), "TOGGLES")
    imgui.Spacing()
    imgui.Checkbox("Enable Minimap", cfgEnabled)
    imgui.Checkbox("Disable Built-in Radar", cfgRadarOff)
    imgui.Spacing()
    imgui.Separator()
    imgui.Spacing()

    -- Position
    imgui.TextColored(imgui.ImVec4(0.2, 0.9, 0.4, 1), "POSITION")
    imgui.Spacing()
    imgui.Text("Position X:")
    imgui.SetNextItemWidth(-1)
    imgui.SliderFloat("##posX", cfgPosX, 0, sw - cfgSize[0], "%.0f")
    imgui.Text("Position Y:")
    imgui.SetNextItemWidth(-1)
    imgui.SliderFloat("##posY", cfgPosY, 0, sh - cfgSize[0], "%.0f")
    imgui.Spacing()
    imgui.Separator()
    imgui.Spacing()

    -- Appearance
    imgui.TextColored(imgui.ImVec4(0.2, 0.9, 0.4, 1), "APPEARANCE")
    imgui.Spacing()
    imgui.Text("Minimap Size:")
    imgui.SetNextItemWidth(-1)
    imgui.SliderFloat("##size", cfgSize, 100, 400, "%.0f")
    imgui.Text("Opacity:")
    imgui.SetNextItemWidth(-1)
    imgui.SliderFloat("##opacity", cfgOpacity, 0.2, 1.0, "%.2f")
    imgui.Text("Arrow Size:")
    imgui.SetNextItemWidth(-1)
    imgui.SliderFloat("##arrowSize", cfgArrowSize, 12, 64, "%.0f")
    imgui.Text("Zoom Level:")
    imgui.SetNextItemWidth(-1)
    imgui.SliderFloat("##zoom", cfgZoom, 0.01, 0.2, "%.3f")
    imgui.Spacing()
    imgui.Separator()
    imgui.Spacing()

    -- Buttons
    if imgui.Button("SAVE", imgui.ImVec2((winW - 40) / 2, 35)) then
        saveConfig()
        showConfigWindow[0] = false
    end
    imgui.SameLine()
    if imgui.Button("CLOSE", imgui.ImVec2((winW - 40) / 2, 35)) then
        showConfigWindow[0] = false
    end

    imgui.End()

    imgui.PopStyleColor(7)
    imgui.PopStyleVar(4)
end

-- ============================================================================
-- GPS PATHFINDING HOOK (CRadar::DrawRadarMap)
-- ============================================================================
local addrRadar = tonumber(ffi.cast("uintptr_t", ffi.cast("void*",
    gtasa._ZN6CRadar12DrawRadarMapEv)))

assert(addrRadar ~= 0, "DrawRadarMap addr is 0!")

local hkRadar
hkRadar = hook.new("void(__cdecl*)(void*)", function(thiz)
    hkRadar(thiz)
    gpsShown = false

    -- Vehicle only: GPS line only when in vehicle
    if not isPlayerInVehicle() then
        cacheValid = false
        cachedPathWorldCoords = {}
        return
    end

    local playa = gtasa._Z13FindPlayerPedi(0)
    if playa == nil then return end

    -- Get target from waypoint system
    local bx, by, bz
    local hasTarget = false

    if waypointActive then
        bx = waypointX
        by = waypointY
        bz = gtasa._ZN6CWorld19FindGroundZForCoordEff(bx, by)
        hasTarget = true
    end

    -- Fallback: check _G.MINIMAP_WAYPOINT (for compatibility)
    if not hasTarget and _G.MINIMAP_WAYPOINT and _G.MINIMAP_WAYPOINT.active then
        bx = _G.MINIMAP_WAYPOINT.x
        by = _G.MINIMAP_WAYPOINT.y
        bz = gtasa._ZN6CWorld19FindGroundZForCoordEff(bx, by)
        hasTarget = true
    end

    -- Fallback: check GTA blip
    if not hasTarget then
        local mm = gmm()
        local tblip = memory.getint32(mm + MM_TBLIP)
        if not ValidBlipHandle(tblip) then
            cacheValid = false
            cachedPathWorldCoords = {}
            return
        end
        local idx = bit.band(tblip, 0xFFFF)
        local tr = grt() + idx * RT_SIZE
        bx = ffi.cast("float*", tr + RT_POS)[0]
        by = ffi.cast("float*", tr + RT_POS)[1]
        bz = gtasa._ZN6CWorld19FindGroundZForCoordEff(bx, by)
        hasTarget = true
    end

    if not hasTarget then
        cacheValid = false
        cachedPathWorldCoords = {}
        return
    end

    local sc = gtasa._Z15FindPlayerCoorsi(0)

    -- Auto clear: if distance < 10m, don't draw and invalidate cache
    local distToTarget = getDistanceToTarget(sc.x, sc.y, sc.z, bx, by, bz)
    if distToTarget < 10.0 then
        cacheValid = false
        gpsShown = false
        cachedPathWorldCoords = {}
        if waypointActive then
            waypointActive = false
            removeGPSWaypoint()
        end
        return
    end

    -- Performance: Only recalculate path when needed
    if needsRecalculation(sc.x, sc.y, sc.z, bx, by) then
        local dc = ffi.new("CVector", {x = bx, y = by, z = bz})

        outCount[0] = 0
        outDist[0] = 0.0

        gtasa._ZN9CPathFind12DoPathSearchEh7CVector12CNodeAddressS0_PS1_PsiPffS2_fbS1_bb(
            ffi.cast("void*", gtp()),
            0, sc, nullNode, dc,
            resultNodes, outCount, MAX_NODES,
            outDist, 999999.0, nil, 999999.0,
            false, nullNode, false, false
        )

        cachedNodeCount = outCount[0]
        cachedDistance = outDist[0]
        lastCalcX = sc.x
        lastCalcY = sc.y
        lastCalcZ = sc.z
        lastTargetX = bx
        lastTargetY = by
        cacheValid = true

        -- Cache world coordinates for custom minimap/full map drawing
        cachedPathWorldCoords = {}
        for i = 0, cachedNodeCount - 1 do
            local np = GetPathNode(resultNodes[i].areaId, resultNodes[i].nodeId)
            if np then
                local nx, ny, nz = GetNodeCoors(np)
                cachedPathWorldCoords[#cachedPathWorldCoords + 1] = { x = nx, y = ny, z = nz }
            end
        end
    end

    local nc = cachedNodeCount
    gpsDistance = cachedDistance
    if nc <= 0 then return end

    local mm = gmm()
    local bMap = memory.getuint8(mm + MM_DRAWMAP) ~= 0
    local zoom = memory.getfloat(mm + MM_ZOOM)
    local scrH = memory.getint32(grsg() + 8)

    for i = 0, nc - 1 do
        local np = GetPathNode(resultNodes[i].areaId, resultNodes[i].nodeId)
        if np then
            local nx, ny = GetNodeCoors(np)
            tmpWorld.x = nx; tmpWorld.y = ny; tmpWorld.z = 0.0
            gtasa._ZN6CRadar35TransformRealWorldPointToRadarSpaceER9CVector2DRKS0_(tmpRad, tmpWorld)
            nodeRad[i].x = tmpRad.x
            nodeRad[i].y = tmpRad.y
            if not bMap then
                gtasa._ZN6CRadar32TransformRadarPointToScreenSpaceER9CVector2DRKS0_(nodePoints + i, tmpRad)
            else
                gtasa._ZN6CRadar15LimitRadarPointER9CVector2D(tmpRad)
                gtasa._ZN6CRadar32TransformRadarPointToScreenSpaceER9CVector2DRKS0_(nodePoints + i, tmpRad)
                nodePoints[i].x = nodePoints[i].x * scrH / 448.0
                nodePoints[i].y = nodePoints[i].y * scrH / 448.0
                local px = ffi.cast("float*", nodePoints + i)
                gtasa._ZN6CRadar10LimitToMapEPfS0_(px, px + 1)
            end
        end
    end

    local vi = 0
    local PI2 = math.pi * 0.5
    for i = 0, nc - 2 do
        local p0x, p0y, p1x, p1y
        if not bMap then
            local cx0, cy0, cx1, cy1 = clipSegCircle(
                nodeRad[i].x, nodeRad[i].y,
                nodeRad[i + 1].x, nodeRad[i + 1].y)
            if not cx0 then goto skipSeg end
            clipR0.x = cx0; clipR0.y = cy0
            clipR1.x = cx1; clipR1.y = cy1
            gtasa._ZN6CRadar32TransformRadarPointToScreenSpaceER9CVector2DRKS0_(clipS0, clipR0)
            gtasa._ZN6CRadar32TransformRadarPointToScreenSpaceER9CVector2DRKS0_(clipS1, clipR1)
            p0x, p0y = clipS0.x, clipS0.y
            p1x, p1y = clipS1.x, clipS1.y
        else
            p0x, p0y = nodePoints[i].x, nodePoints[i].y
            p1x, p1y = nodePoints[i + 1].x, nodePoints[i + 1].y
        end
        local dx = p1x - p0x
        local dy = p1y - p0y
        local ang = math.atan2(dy, dx)
        local lw = GPS_WIDTH
        if bMap then
            local mp = math.max(140.0, math.min(960.0, zoom - 140.0))
            lw = lw * (mp / 960.0 + 0.4)
        end
        local s0x = math.cos(ang - PI2) * lw
        local s0y = math.sin(ang - PI2) * lw
        Setup2dVert(lineVerts[vi + 0], p0x + s0x, p0y + s0y)
        Setup2dVert(lineVerts[vi + 1], p1x + s0x, p1y + s0y)
        Setup2dVert(lineVerts[vi + 2], p0x - s0x, p0y - s0y)
        Setup2dVert(lineVerts[vi + 3], p1x - s0x, p1y - s0y)
        vi = vi + 4
        ::skipSeg::
    end

    if vi == 0 then return end

    gtasa._Z16RwRenderStateSet13RwRenderStatePv(rwTEX_RAST, nil)
    gtasa._Z28RwIm2DRenderPrimitive_BUGFIX15RwPrimitiveTypeP14RwOpenGLVertexi(rwTRISTRIP, lineVerts, vi)

    local n0 = GetPathNode(resultNodes[0].areaId, resultNodes[0].nodeId)
    if n0 then
        local nx, ny, nz = GetNodeCoors(n0)
        local dx, dy, dz = sc.x - nx, sc.y - ny, sc.z - nz
        gpsDistance = cachedDistance + math.sqrt(dx * dx + dy * dy + dz * dz)
    end
    gpsShown = true
end, addrRadar)

-- ============================================================================
-- MAIN FUNCTION
-- ============================================================================
function main()
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("{00FFFF}[MinimapGPS] {FFFFFF}Script loaded successfully!", -1)
    sampAddChatMessage("{00FFFF}[MinimapGPS] {FFFFFF}Use {FFFF00}/mapcfg{FFFFFF} to configure", -1)
    sampAddChatMessage("{00FFFF}[MinimapGPS] {FFFFFF}Created by: {FFFF00}OnlyDexterZ", -1)

    -- Register config command
    sampRegisterChatCommand("mapcfg", function()
        showConfigWindow[0] = not showConfigWindow[0]
    end)

    -- Radar stays rendered so GPS hook (DrawRadarMap) keeps working
    -- Custom minimap overlays on top of radar visually

    -- Main rendering frame
    imgui.OnFrame(function() return true end, function()
        local draw_list = imgui.GetBackgroundDrawList()

        -- Radar stays rendered (GPS hook needs DrawRadarMap to be called)
        -- Custom minimap overlays on top of radar visually

        -- Render based on mode
        if fullMapMode then
            drawFullMap(draw_list)
        else
            drawMinimap(draw_list)
        end

        -- Config window
        drawConfigWindow()
    end)

    -- Keep script alive
    while true do
        wait(1000)
    end
end
