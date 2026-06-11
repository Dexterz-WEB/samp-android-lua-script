-- ============================================================================
-- COMPASS NAV v1.0
-- PUBG-style compass bar + GPS pathfinding for SA-MP Android (MonetLoader)
-- Author: OnlyDexterZ
-- ============================================================================

script_name("CompassNav")
script_author("OnlyDexterZ")

-- ============================================================================
-- LIBRARY IMPORTS
-- ============================================================================
local imgui = require 'mimgui'
local jsoncfg = require 'jsoncfg'
local ffi = require 'ffi'
local memory = require 'memory'
local hook = require 'monethook'

local compass_lib = require 'compass_lib'
local calculateZone = require 'zones'

local ease_loaded = false
local ease = nil
pcall(function()
    ease = require 'ease'
    ease_loaded = true
end)

-- ============================================================================
-- CONSTANTS
-- ============================================================================
local DPI = MONET_DPI_SCALE or 1.0
local BASE = MONET_GTASA_BASE

-- Colors (dark theme matching RadialMenu)
local COLORS = {
    bg       = 0xCC14141F,  -- dark bg (0.08, 0.08, 0.12, 0.8)
    bgPanel  = 0xF0141420,  -- panel bg
    border   = 0xFF333344,
    text     = 0xFFCCCCCC,
    textDim  = 0xFF888899,
    cardinal = 0xFFFFFFFF,
    tick     = 0xFF666677,
    accent   = 0xFF4D99E6,  -- blue glow (0.3, 0.6, 0.9)
    accentDim= 0xAA4D99E6,
    waypoint = 0xFF4D99E6,
    zone     = 0xFFAABBDD,
    success  = 0xFF66CC66,
    warning  = 0xFFE6994D,
}

-- GPS constants (from testing/gps.lua)
local MAX_NODES  = 5000
local GPS_WIDTH  = 6.0
local GPS_COLOR  = 0xFF1818B4

local rwTRISTRIP = 4
local rwTEX_RAST = 1

local GOT_THEPATHS = BASE + 0x677378
local GOT_GMM      = BASE + 0x679CCC
local GOT_MSRT     = BASE + 0x6773CC
local GOT_RSG      = BASE + 0x67910C

local MM_TBLIP   = 0x48
local MM_ZOOM    = 0x58
local MM_DRAWMAP = 0x6C

local RT_SIZE = 0x28
local RT_POS  = 0x08
local RT_CTR  = 0x14
local RT_DISP = 0x26

local PF_NODES = 0x804
local PN_SIZE  = 0x1C
local PN_POS   = 0x08

-- ============================================================================
-- FFI DECLARATIONS
-- ============================================================================
ffi.cdef[[
typedef struct { float x, y, z; }    CVector;
typedef struct { float x, y; }       CVector2D;
typedef struct { short areaId; short nodeId; } CNodeAddress;
typedef struct { float x, y, z, rhw; uint32_t color; float u, v; } RwIm2DVertex;
typedef struct { float x, y, z, rhw; unsigned int color; float u, v; } RwOpenGLVertex;

void*   _Z13FindPlayerPedi(int n);
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

void  _ZN6CRadar32TransformRadarPointToScreenSpaceER9CVector2DRKS0_(CVector2D* scr, CVector2D* rad);
void  _ZN6CRadar35TransformRealWorldPointToRadarSpaceER9CVector2DRKS0_(CVector2D* rad, CVector* world);
void  _ZN6CRadar15LimitRadarPointER9CVector2D(CVector2D* rad);
void  _ZN6CRadar10LimitToMapEPfS0_(float* x, float* y);
float _ZN6CWorld19FindGroundZForCoordEff(float x, float y);
void  _ZN6CRadar12DrawRadarMapEv(void* thiz);

bool _Z16RwRenderStateSet13RwRenderStatePv(uint32_t state, void* value);
bool _Z28RwIm2DRenderPrimitive_BUGFIX15RwPrimitiveTypeP14RwOpenGLVertexi(uint32_t primType, RwIm2DVertex* verts, int32_t count);
]]

local gtasa = ffi.load("GTASA")

-- ============================================================================
-- GPS HELPER FUNCTIONS (from testing/gps.lua)
-- ============================================================================
local function gmm()  return memory.getuint32(GOT_GMM)      end
local function gtp()  return memory.getuint32(GOT_THEPATHS) end
local function grt()  return memory.getuint32(GOT_MSRT)     end
local function grsg() return memory.getuint32(GOT_RSG)      end

local function ValidBlipHandle(h)
    if h == 0 then return false end
    local idx = bit.band(h, 0xFFFF)
    local ctr = bit.rshift(h, 16)
    local tr  = grt() + idx * RT_SIZE
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
    local dx, dy = x1-x0, y1-y0
    local a = dx*dx + dy*dy
    if a < 1e-10 then
        return (x0*x0 + y0*y0 <= 1.0) and x0, y0, x1, y1 or nil
    end
    local b    = 2*(x0*dx + y0*dy)
    local c    = x0*x0 + y0*y0 - 1.0
    local disc = b*b - 4*a*c
    local t0, t1 = 0.0, 1.0
    if disc >= 0 then
        local sd = math.sqrt(disc)
        local ta = (-b - sd) / (2*a)
        local tb = (-b + sd) / (2*a)
        if ta > t0 then t0 = ta end
        if tb < t1 then t1 = tb end
        if t0 > t1 then return nil end
    else
        if c > 0 then return nil end
    end
    return x0+t0*dx, y0+t0*dy,
           x0+t1*dx, y0+t1*dy
end

-- ============================================================================
-- CONFIG
-- ============================================================================
local defaultConfig = {
    enabled = true,
    compassEnabled = true,
    gpsEnabled = true,
    zoneDisplay = true,
    compassWidth = 400,
    compassHeight = 36,
    compassY = 15,
    compassFov = 180,
    autoClearDistance = 10,
    gpsLineWidth = 6.0,
    gpsColor = 0xFF1818B4,
    savedLocations = {},
}

local config = jsoncfg.load(defaultConfig, "CompassNav")

-- Ensure savedLocations exists
if not config.savedLocations then
    config.savedLocations = {}
end

local function saveConfig()
    jsoncfg.save(config, "CompassNav")
end

-- ============================================================================
-- STATE
-- ============================================================================
local showConfigWindow = imgui.new.bool(false)
local configTab = 1

-- Compass state
local currentHeading = 0
local smoothHeading = 0
local currentZone = "Unknown"
local lastZoneUpdate = 0

-- Waypoint state
local waypointActive = false
local waypointX = 0
local waypointY = 0
local waypointZ = 0
local waypointDistance = 0
local waypointBearing = 0
local waypointName = ""

-- GPS state
local gpsShown = false
local gpsDistance = 0.0

-- Animation state
local compassAlpha = 0
local compassOpenTime = 0

-- Config UI buffers
local locNameBuf = imgui.new.char[64]("")
local locXBuf = imgui.new.char[16]("0")
local locYBuf = imgui.new.char[16]("0")

-- ============================================================================
-- GPS PATHFINDING BUFFERS (from testing/gps.lua)
-- ============================================================================
local resultNodes = ffi.new("CNodeAddress[?]", MAX_NODES)
local nodePoints  = ffi.new("CVector2D[?]", MAX_NODES)
local nodeRad     = ffi.new("CVector2D[?]", MAX_NODES)
local lineVerts   = ffi.new("RwIm2DVertex[?]", MAX_NODES * 4)
local nullNode    = ffi.new("CNodeAddress")
local tmpRad      = ffi.new("CVector2D")
local tmpWorld    = ffi.new("CVector")
local clipR0      = ffi.new("CVector2D")
local clipR1      = ffi.new("CVector2D")
local clipS0      = ffi.new("CVector2D")
local clipS1      = ffi.new("CVector2D")
local outCount    = ffi.new("int16_t[1]")
local outDist     = ffi.new("float[1]")

-- Cache system
local cachedNodeCount = 0
local cachedDistance  = 0.0
local lastCalcX = 0.0
local lastCalcY = 0.0
local lastCalcZ = 0.0
local lastTargetX = 0.0
local lastTargetY = 0.0
local RECALC_DISTANCE = 50.0
local cacheValid = false

local function needsRecalculation(px, py, pz, tx, ty)
    if not cacheValid then return true end
    local dx = px - lastCalcX
    local dy = py - lastCalcY
    local dz = pz - lastCalcZ
    local playerMoved = math.sqrt(dx*dx + dy*dy + dz*dz)
    if playerMoved > RECALC_DISTANCE then return true end
    if math.abs(tx - lastTargetX) > 1.0 or math.abs(ty - lastTargetY) > 1.0 then return true end
    return false
end

-- ============================================================================
-- VEHICLE CHECK
-- ============================================================================
local function isPlayerInVehicle()
    local result = false
    pcall(function()
        result = isCharInAnyCar(PLAYER_PED)
    end)
    return result
end

-- ============================================================================
-- PLAYER INFO
-- ============================================================================
local function getCameraHeading()
    local h = 0
    pcall(function()
        local camX, camY, camZ = getActiveCameraCoordinates()
        local targetX, targetY, targetZ = getActiveCameraPointAt()
        local dx = targetX - camX
        local dy = targetY - camY
        -- atan2(dx, dy) gives angle from North (Y+), clockwise
        h = math.deg(math.atan2(dx, dy))
        if h < 0 then h = h + 360 end
    end)
    return h
end

local function getPlayerHeading()
    local h = 0
    pcall(function()
        h = getCharHeading(PLAYER_PED)
    end)
    return h
end

local function getPlayerPos()
    local x, y, z = 0, 0, 0
    pcall(function()
        x, y, z = getCharCoordinates(PLAYER_PED)
    end)
    return x, y, z
end

-- ============================================================================
-- GPS DRAW HOOK (from testing/gps.lua - proven working logic)
-- ============================================================================
local addrRadar = tonumber(ffi.cast("uintptr_t", ffi.cast("void*",
    gtasa._ZN6CRadar12DrawRadarMapEv)))

assert(addrRadar ~= 0, "DrawRadarMap addr is 0!")

local mm = gmm

local hkRadar
hkRadar = hook.new("void(__cdecl*)(void*)", function(thiz)
    hkRadar(thiz)
    gpsShown = false

    if not config.gpsEnabled then return end

    -- Vehicle only for GPS line
    if not isPlayerInVehicle() then
        cacheValid = false
        return
    end

    local playa = gtasa._Z13FindPlayerPedi(0)
    if playa == nil then return end

    -- Get target coordinates
    local bx, by, bz
    local hasTarget = false

    -- Check global waypoint (from MinimapHUD or our own waypoint)
    if _G.MINIMAP_WAYPOINT and _G.MINIMAP_WAYPOINT.active then
        bx = _G.MINIMAP_WAYPOINT.x
        by = _G.MINIMAP_WAYPOINT.y
        bz = gtasa._ZN6CWorld19FindGroundZForCoordEff(bx, by)
        hasTarget = true
    end

    -- Check our own waypoint
    if not hasTarget and waypointActive then
        bx = waypointX
        by = waypointY
        bz = waypointZ
        hasTarget = true
    end

    -- Fallback: check GTA blip
    if not hasTarget then
        local mmPtr = gmm()
        local tblip = memory.getint32(mmPtr + MM_TBLIP)
        if not ValidBlipHandle(tblip) then
            cacheValid = false
            return
        end
        local idx = bit.band(tblip, 0xFFFF)
        local tr  = grt() + idx * RT_SIZE
        bx = ffi.cast("float*", tr + RT_POS)[0]
        by = ffi.cast("float*", tr + RT_POS)[1]
        bz = gtasa._ZN6CWorld19FindGroundZForCoordEff(bx, by)
        hasTarget = true
    end

    if not hasTarget then
        cacheValid = false
        return
    end

    local sc = gtasa._Z15FindPlayerCoorsi(0)

    -- Auto clear: if distance < configured threshold
    local dx = sc.x - bx
    local dy = sc.y - by
    local dz = sc.z - bz
    local distToTarget = math.sqrt(dx*dx + dy*dy + dz*dz)
    if distToTarget < config.autoClearDistance then
        cacheValid = false
        gpsShown = false
        waypointActive = false
        if _G.MINIMAP_WAYPOINT then
            _G.MINIMAP_WAYPOINT.active = false
        end
        return
    end

    -- Performance: Only recalculate path when needed
    if needsRecalculation(sc.x, sc.y, sc.z, bx, by) then
        local dc = ffi.new("CVector", {x=bx, y=by, z=bz})

        outCount[0] = 0
        outDist[0]  = 0.0

        gtasa._ZN9CPathFind12DoPathSearchEh7CVector12CNodeAddressS0_PS1_PsiPffS2_fbS1_bb(
            ffi.cast("void*", gtp()),
            0, sc, nullNode, dc,
            resultNodes, outCount, MAX_NODES,
            outDist, 999999.0, nil, 999999.0,
            false, nullNode, false, false
        )

        cachedNodeCount = outCount[0]
        cachedDistance  = outDist[0]
        lastCalcX = sc.x
        lastCalcY = sc.y
        lastCalcZ = sc.z
        lastTargetX = bx
        lastTargetY = by
        cacheValid = true
    end

    local nc = cachedNodeCount
    gpsDistance = cachedDistance
    if nc <= 0 then return end

    local mmPtr = gmm()
    local bMap = memory.getuint8(mmPtr + MM_DRAWMAP) ~= 0
    local zoom = memory.getfloat(mmPtr + MM_ZOOM)
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

    local vi  = 0
    local PI2 = math.pi * 0.5
    for i = 0, nc - 2 do
        local p0x, p0y, p1x, p1y
        if not bMap then
            local cx0, cy0, cx1, cy1 = clipSegCircle(
                nodeRad[i].x,   nodeRad[i].y,
                nodeRad[i+1].x, nodeRad[i+1].y)
            if not cx0 then goto skipSeg end
            clipR0.x = cx0; clipR0.y = cy0
            clipR1.x = cx1; clipR1.y = cy1
            gtasa._ZN6CRadar32TransformRadarPointToScreenSpaceER9CVector2DRKS0_(clipS0, clipR0)
            gtasa._ZN6CRadar32TransformRadarPointToScreenSpaceER9CVector2DRKS0_(clipS1, clipR1)
            p0x, p0y = clipS0.x, clipS0.y
            p1x, p1y = clipS1.x, clipS1.y
        else
            p0x, p0y = nodePoints[i].x,   nodePoints[i].y
            p1x, p1y = nodePoints[i+1].x, nodePoints[i+1].y
        end
        local ldx = p1x - p0x
        local ldy = p1y - p0y
        local ang = math.atan2(ldy, ldx)
        local lw  = config.gpsLineWidth or GPS_WIDTH
        if bMap then
            local mp = math.max(140.0, math.min(960.0, zoom - 140.0))
            lw = lw * (mp / 960.0 + 0.4)
        end
        local s0x = math.cos(ang - PI2) * lw
        local s0y = math.sin(ang - PI2) * lw
        Setup2dVert(lineVerts[vi+0], p0x + s0x, p0y + s0y)
        Setup2dVert(lineVerts[vi+1], p1x + s0x, p1y + s0y)
        Setup2dVert(lineVerts[vi+2], p0x - s0x, p0y - s0y)
        Setup2dVert(lineVerts[vi+3], p1x - s0x, p1y - s0y)
        vi = vi + 4
        ::skipSeg::
    end

    if vi == 0 then return end

    gtasa._Z16RwRenderStateSet13RwRenderStatePv(rwTEX_RAST, nil)
    gtasa._Z28RwIm2DRenderPrimitive_BUGFIX15RwPrimitiveTypeP14RwOpenGLVertexi(rwTRISTRIP, lineVerts, vi)

    local n0 = GetPathNode(resultNodes[0].areaId, resultNodes[0].nodeId)
    if n0 then
        local nx, ny, nz = GetNodeCoors(n0)
        local ndx, ndy, ndz = sc.x-nx, sc.y-ny, sc.z-nz
        gpsDistance = cachedDistance + math.sqrt(ndx*ndx + ndy*ndy + ndz*ndz)
    end
    gpsShown = true
end, addrRadar)

-- ============================================================================
-- COMPASS OVERLAY (imgui.OnFrame - always visible)
-- ============================================================================
imgui.OnFrame(
    function() return config.enabled and config.compassEnabled end,
    function(self)
        self.HideCursor = true

        local scale = DPI
        local screenW = imgui.GetIO().DisplaySize.x
        local barW = config.compassWidth * scale
        local barH = config.compassHeight * scale
        local barX = (screenW - barW) * 0.5
        local barY = config.compassY * scale

        -- Update heading with smooth interpolation (using CAMERA heading, not player)
        local rawHeading = getCameraHeading()
        currentHeading = rawHeading

        -- Smooth heading interpolation
        local headingDiff = currentHeading - smoothHeading
        -- Handle wrap-around
        if headingDiff > 180 then headingDiff = headingDiff - 360
        elseif headingDiff < -180 then headingDiff = headingDiff + 360 end
        smoothHeading = smoothHeading + headingDiff * 0.15
        if smoothHeading < 0 then smoothHeading = smoothHeading + 360
        elseif smoothHeading >= 360 then smoothHeading = smoothHeading - 360 end

        -- Update zone (every 0.5s for performance)
        local now = os.clock()
        if now - lastZoneUpdate > 0.5 then
            local px, py, pz = getPlayerPos()
            if px ~= 0 or py ~= 0 then
                local zone = calculateZone(px, py, pz)
                if zone and zone ~= "unknown" then
                    currentZone = zone
                end
            end
            lastZoneUpdate = now
        end

        -- Update waypoint info
        if waypointActive then
            local px, py, pz = getPlayerPos()
            waypointDistance = compass_lib.calculateDistance(px, py, waypointX, waypointY)
            waypointBearing = compass_lib.calculateBearing(px, py, waypointX, waypointY)

            -- Auto clear when close
            if waypointDistance < config.autoClearDistance then
                waypointActive = false
                waypointName = ""
            end
        end

        -- Set up invisible window
        imgui.SetNextWindowPos(imgui.ImVec2(0, 0))
        imgui.SetNextWindowSize(imgui.GetIO().DisplaySize)
        imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 0)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))

        if imgui.Begin("##CompassOverlay", nil,
            imgui.WindowFlags.NoTitleBar +
            imgui.WindowFlags.NoResize +
            imgui.WindowFlags.NoMove +
            imgui.WindowFlags.NoScrollbar +
            imgui.WindowFlags.NoInputs +
            imgui.WindowFlags.NoBackground +
            imgui.WindowFlags.NoBringToFrontOnFocus) then

            local dl = imgui.GetBackgroundDrawList()

            -- Draw compass bar
            compass_lib.drawCompassBar(dl,
                { x = barX, y = barY },
                barW, smoothHeading,
                {
                    height = config.compassHeight,
                    bgColor = COLORS.bg,
                    textColor = COLORS.text,
                    cardinalColor = COLORS.cardinal,
                    tickColor = COLORS.tick,
                    centerColor = COLORS.accent,
                    fov = config.compassFov,
                    scale = scale,
                }
            )

            -- Draw waypoint marker on compass
            if waypointActive then
                compass_lib.drawWaypointMarker(dl,
                    { x = barX, y = barY },
                    barW, smoothHeading, waypointBearing, waypointDistance,
                    {
                        fov = config.compassFov,
                        markerColor = COLORS.waypoint,
                        textColor = COLORS.waypoint,
                        scale = scale,
                        height = config.compassHeight,
                    }
                )
            end

            -- Helper: draw text with outline (shadow on 4 sides for visibility)
            local function drawTextOutlined(drawList, pos, color, text, outlineColor)
                outlineColor = outlineColor or 0xFF000000
                local ox = 1 * scale
                drawList:AddText(imgui.ImVec2(pos.x - ox, pos.y), outlineColor, text)
                drawList:AddText(imgui.ImVec2(pos.x + ox, pos.y), outlineColor, text)
                drawList:AddText(imgui.ImVec2(pos.x, pos.y - ox), outlineColor, text)
                drawList:AddText(imgui.ImVec2(pos.x, pos.y + ox), outlineColor, text)
                drawList:AddText(pos, color, text)
            end

            -- Draw zone name below compass
            if config.zoneDisplay and currentZone ~= "Unknown" then
                local zoneY = barY + barH + 6 * scale
                local zoneText = currentZone
                if waypointActive and waypointName ~= "" then
                    zoneText = zoneText .. "  |  " .. waypointName .. " " .. compass_lib.formatDistance(waypointDistance)
                elseif waypointActive then
                    zoneText = zoneText .. "  |  " .. compass_lib.formatDistance(waypointDistance)
                end
                local textW = #zoneText * 5.5 * scale
                local centerX = barX + barW * 0.5
                drawTextOutlined(dl,
                    imgui.ImVec2(centerX - textW * 0.5, zoneY),
                    0xFFFFFFFF, zoneText
                )
            end

            -- Draw GPS distance if active (below zone)
            if gpsShown and gpsDistance > 0 then
                local gpsY = barY + barH + (config.zoneDisplay and 24 or 6) * scale
                local gpsText = "GPS: " .. compass_lib.formatDistance(gpsDistance)
                local textW = #gpsText * 5.5 * scale
                local centerX = barX + barW * 0.5
                drawTextOutlined(dl,
                    imgui.ImVec2(centerX - textW * 0.5, gpsY),
                    0xFF66CCFF, gpsText
                )
            end
        end
        imgui.End()
        imgui.PopStyleVar(2)
    end
)

-- ============================================================================
-- CONFIG PANEL (imgui.OnFrame)
-- ============================================================================
imgui.OnFrame(
    function() return showConfigWindow[0] end,
    function(self)
        self.HideCursor = false

        local scale = DPI
        local screenSize = imgui.GetIO().DisplaySize
        local winW = 380 * scale
        local winH = 480 * scale

        imgui.SetNextWindowPos(imgui.ImVec2(
            (screenSize.x - winW) * 0.5,
            (screenSize.y - winH) * 0.5
        ), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(winW, winH), imgui.Cond.FirstUseEver)

        imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 8 * scale)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(12 * scale, 12 * scale))

        if imgui.Begin("CompassNav Settings##config", showConfigWindow, imgui.WindowFlags.NoResize) then

            -- Tab buttons
            if imgui.Button("General##tab1") then configTab = 1 end
            imgui.SameLine()
            if imgui.Button("Compass##tab2") then configTab = 2 end
            imgui.SameLine()
            if imgui.Button("GPS##tab3") then configTab = 3 end
            imgui.SameLine()
            if imgui.Button("Locations##tab4") then configTab = 4 end

            imgui.Separator()

            -- General Tab
            if configTab == 1 then
                imgui.Text("CompassNav v1.0")
                imgui.Separator()

                local enabledPtr = imgui.new.bool(config.enabled)
                if imgui.Checkbox("Enable CompassNav##enabled", enabledPtr) then
                    config.enabled = enabledPtr[0]
                    saveConfig()
                end

                local compassPtr = imgui.new.bool(config.compassEnabled)
                if imgui.Checkbox("Show Compass Bar##compass", compassPtr) then
                    config.compassEnabled = compassPtr[0]
                    saveConfig()
                end

                local gpsPtr = imgui.new.bool(config.gpsEnabled)
                if imgui.Checkbox("Enable GPS Line##gps", gpsPtr) then
                    config.gpsEnabled = gpsPtr[0]
                    saveConfig()
                end

                local zonePtr = imgui.new.bool(config.zoneDisplay)
                if imgui.Checkbox("Show Zone Name##zone", zonePtr) then
                    config.zoneDisplay = zonePtr[0]
                    saveConfig()
                end

                imgui.Separator()
                imgui.Text("Auto-clear distance:")
                local clearPtr = imgui.new.float(config.autoClearDistance)
                if imgui.SliderFloat("##cleardist", clearPtr, 5, 50, "%.0f m") then
                    config.autoClearDistance = clearPtr[0]
                    saveConfig()
                end

            -- Compass Tab
            elseif configTab == 2 then
                imgui.Text("Compass Bar Settings")
                imgui.Separator()

                local widthPtr = imgui.new.float(config.compassWidth)
                if imgui.SliderFloat("Width##cw", widthPtr, 200, 800, "%.0f") then
                    config.compassWidth = widthPtr[0]
                    saveConfig()
                end

                local heightPtr = imgui.new.float(config.compassHeight)
                if imgui.SliderFloat("Height##ch", heightPtr, 20, 60, "%.0f") then
                    config.compassHeight = heightPtr[0]
                    saveConfig()
                end

                local yPtr = imgui.new.float(config.compassY)
                if imgui.SliderFloat("Y Position##cy", yPtr, 0, 100, "%.0f") then
                    config.compassY = yPtr[0]
                    saveConfig()
                end

                local fovPtr = imgui.new.float(config.compassFov)
                if imgui.SliderFloat("FOV##cfov", fovPtr, 90, 360, "%.0f") then
                    config.compassFov = fovPtr[0]
                    saveConfig()
                end

            -- GPS Tab
            elseif configTab == 3 then
                imgui.Text("GPS Line Settings")
                imgui.Separator()

                local lineWPtr = imgui.new.float(config.gpsLineWidth)
                if imgui.SliderFloat("Line Width##glw", lineWPtr, 2, 12, "%.1f") then
                    config.gpsLineWidth = lineWPtr[0]
                    saveConfig()
                end

                imgui.Separator()
                imgui.Text("Status:")
                if gpsShown then
                    imgui.TextColored(imgui.ImVec4(0.4, 0.8, 0.4, 1.0), "GPS Active")
                    imgui.Text("Distance: " .. compass_lib.formatDistance(gpsDistance))
                else
                    imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1.0), "GPS Inactive")
                    imgui.Text("(Set a waypoint or enter a vehicle)")
                end

            -- Locations Tab
            elseif configTab == 4 then
                imgui.Text("Saved Locations")
                imgui.Separator()

                -- Add new location
                imgui.Text("Add Location:")
                imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(4 * scale, 4 * scale))

                imgui.InputText("Name##locname", locNameBuf, 64)
                imgui.InputText("X##locx", locXBuf, 16)
                imgui.SameLine()
                imgui.InputText("Y##locy", locYBuf, 16)

                if imgui.Button("Add Current Pos##addcur") then
                    local px, py, pz = getPlayerPos()
                    local name = ffi.string(locNameBuf)
                    if name == "" then name = "Location " .. (#config.savedLocations + 1) end
                    table.insert(config.savedLocations, {
                        name = name,
                        x = px,
                        y = py,
                    })
                    saveConfig()
                end
                imgui.SameLine()
                if imgui.Button("Add XY##addxy") then
                    local name = ffi.string(locNameBuf)
                    local x = tonumber(ffi.string(locXBuf)) or 0
                    local y = tonumber(ffi.string(locYBuf)) or 0
                    if name == "" then name = "Location " .. (#config.savedLocations + 1) end
                    table.insert(config.savedLocations, {
                        name = name,
                        x = x,
                        y = y,
                    })
                    saveConfig()
                end

                imgui.PopStyleVar()
                imgui.Separator()

                -- List saved locations
                local toRemove = nil
                for i, loc in ipairs(config.savedLocations) do
                    imgui.Text(loc.name .. " (" .. math.floor(loc.x) .. ", " .. math.floor(loc.y) .. ")")
                    imgui.SameLine()
                    if imgui.Button("Go##nav" .. tostring(i)) then
                        waypointX = loc.x
                        waypointY = loc.y
                        waypointZ = gtasa._ZN6CWorld19FindGroundZForCoordEff(loc.x, loc.y)
                        waypointActive = true
                        waypointName = loc.name
                        cacheValid = false
                        -- Also set global waypoint for GPS
                        _G.MINIMAP_WAYPOINT = _G.MINIMAP_WAYPOINT or {}
                        _G.MINIMAP_WAYPOINT.active = true
                        _G.MINIMAP_WAYPOINT.x = loc.x
                        _G.MINIMAP_WAYPOINT.y = loc.y
                    end
                    imgui.SameLine()
                    if imgui.Button("X##del" .. tostring(i)) then
                        toRemove = i
                    end
                end
                if toRemove then
                    table.remove(config.savedLocations, toRemove)
                    saveConfig()
                end
            end
        end
        imgui.End()
        imgui.PopStyleVar(2)
    end
)

-- ============================================================================
-- COMMANDS
-- ============================================================================
function main()
    -- Wait for game to load
    while not isSampAvailable() do wait(100) end

    -- Register command
    sampRegisterChatCommand("compass", function(args)
        if args == "on" then
            config.enabled = true
            saveConfig()
            sampAddChatMessage("{4D99E6}[CompassNav]{FFFFFF} Enabled", 0xFFFFFF)
        elseif args == "off" then
            config.enabled = false
            saveConfig()
            sampAddChatMessage("{4D99E6}[CompassNav]{FFFFFF} Disabled", 0xFFFFFF)
        elseif args == "gps" then
            config.gpsEnabled = not config.gpsEnabled
            saveConfig()
            local state = config.gpsEnabled and "ON" or "OFF"
            sampAddChatMessage("{4D99E6}[CompassNav]{FFFFFF} GPS Line: " .. state, 0xFFFFFF)
        elseif args == "clear" then
            waypointActive = false
            waypointName = ""
            cacheValid = false
            if _G.MINIMAP_WAYPOINT then
                _G.MINIMAP_WAYPOINT.active = false
            end
            sampAddChatMessage("{4D99E6}[CompassNav]{FFFFFF} Waypoint cleared", 0xFFFFFF)
        else
            -- Open config panel
            showConfigWindow[0] = not showConfigWindow[0]
        end
    end)

    -- Register navigate command
    sampRegisterChatCommand("nav", function(args)
        -- /nav <name> or /nav <x> <y>
        if args == "" then
            sampAddChatMessage("{4D99E6}[CompassNav]{FFFFFF} Usage: /nav <location_name> or /nav <x> <y>", 0xFFFFFF)
            return
        end

        -- Try parsing as coordinates
        local x, y = args:match("^([%-%.%d]+)%s+([%-%.%d]+)$")
        if x and y then
            x = tonumber(x)
            y = tonumber(y)
            if x and y then
                waypointX = x
                waypointY = y
                waypointZ = gtasa._ZN6CWorld19FindGroundZForCoordEff(x, y)
                waypointActive = true
                waypointName = ""
                cacheValid = false
                _G.MINIMAP_WAYPOINT = _G.MINIMAP_WAYPOINT or {}
                _G.MINIMAP_WAYPOINT.active = true
                _G.MINIMAP_WAYPOINT.x = x
                _G.MINIMAP_WAYPOINT.y = y
                sampAddChatMessage("{4D99E6}[CompassNav]{FFFFFF} Navigating to " .. math.floor(x) .. ", " .. math.floor(y), 0xFFFFFF)
                return
            end
        end

        -- Try matching saved location name
        local searchName = args:lower()
        for _, loc in ipairs(config.savedLocations) do
            if loc.name:lower():find(searchName, 1, true) then
                waypointX = loc.x
                waypointY = loc.y
                waypointZ = gtasa._ZN6CWorld19FindGroundZForCoordEff(loc.x, loc.y)
                waypointActive = true
                waypointName = loc.name
                cacheValid = false
                _G.MINIMAP_WAYPOINT = _G.MINIMAP_WAYPOINT or {}
                _G.MINIMAP_WAYPOINT.active = true
                _G.MINIMAP_WAYPOINT.x = loc.x
                _G.MINIMAP_WAYPOINT.y = loc.y
                sampAddChatMessage("{4D99E6}[CompassNav]{FFFFFF} Navigating to: " .. loc.name, 0xFFFFFF)
                return
            end
        end

        sampAddChatMessage("{4D99E6}[CompassNav]{FFFFFF} Location not found: " .. args, 0xFFFFFF)
    end)

    sampAddChatMessage("{4D99E6}[CompassNav]{FFFFFF} Loaded! Use /compass to open settings", 0xFFFFFF)

    wait(-1)
end
