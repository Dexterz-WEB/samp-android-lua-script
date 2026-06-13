-- ============================================================================
-- COMPASS LIBRARY v1.0
-- Compass bar rendering, bearing/distance utilities for MonetLoader/mimgui
-- Author: OnlyDexterZ
-- ============================================================================

local imgui = require 'mimgui'

local compass_lib = {}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

--- Calculate bearing from point A to point B (in degrees, 0=North, clockwise)
-- @param fromX number - source X coordinate
-- @param fromY number - source Y coordinate
-- @param toX number - target X coordinate
-- @param toY number - target Y coordinate
-- @return number - bearing in degrees (0-360)
function compass_lib.calculateBearing(fromX, fromY, toX, toY)
    local dx = toX - fromX
    local dy = toY - fromY
    local angle = math.deg(math.atan2(dx, dy))
    if angle < 0 then angle = angle + 360 end
    return angle
end

--- Calculate distance between two 2D points
-- @param fromX number - source X coordinate
-- @param fromY number - source Y coordinate
-- @param toX number - target X coordinate
-- @param toY number - target Y coordinate
-- @return number - distance in game units (meters)
function compass_lib.calculateDistance(fromX, fromY, toX, toY)
    local dx = toX - fromX
    local dy = toY - fromY
    return math.sqrt(dx * dx + dy * dy)
end

--- Format distance for display
-- @param meters number - distance in meters
-- @return string - formatted distance string
function compass_lib.formatDistance(meters)
    if meters >= 1000 then
        return string.format("%.1fkm", meters / 1000)
    else
        return string.format("%dm", math.floor(meters))
    end
end

-- ============================================================================
-- COMPASS RENDERING
-- ============================================================================

-- Cardinal/intercardinal direction definitions
local DIRECTIONS = {
    { deg = 0,   label = "N" },
    { deg = 45,  label = "NE" },
    { deg = 90,  label = "E" },
    { deg = 135, label = "SE" },
    { deg = 180, label = "S" },
    { deg = 225, label = "SW" },
    { deg = 270, label = "W" },
    { deg = 315, label = "NW" },
}

--- Normalize angle to 0-360 range
local function normalizeAngle(angle)
    angle = angle % 360
    if angle < 0 then angle = angle + 360 end
    return angle
end

--- Get the shortest angular difference between two angles
local function angleDiff(a, b)
    local diff = normalizeAngle(b - a)
    if diff > 180 then diff = diff - 360 end
    return diff
end

--- Draw the compass bar overlay
-- @param dl - ImGui DrawList
-- @param pos table - {x, y} top-left position of the compass bar
-- @param width number - width of the compass bar in pixels
-- @param heading number - player heading in degrees (GTA heading: 0=North, clockwise)
-- @param opts table - options: height, bgColor, textColor, cardinalColor, tickColor, centerColor, scale
function compass_lib.drawCompassBar(dl, pos, width, heading, opts)
    opts = opts or {}
    local height = opts.height or 40
    local bgColor = opts.bgColor or 0xCC141420
    local textColor = opts.textColor or 0xFFCCCCCC
    local cardinalColor = opts.cardinalColor or 0xFFFFFFFF
    local tickColor = opts.tickColor or 0xFF666666
    local centerColor = opts.centerColor or 0xFF4D99E6
    local scale = opts.scale or 1.0

    height = height * scale
    local barX = pos.x
    local barY = pos.y
    local barW = width
    local barH = height

    -- Draw background
    local rounding = 6 * scale
    dl:AddRectFilled(
        imgui.ImVec2(barX, barY),
        imgui.ImVec2(barX + barW, barY + barH),
        bgColor, rounding
    )

    -- Draw border
    dl:AddRect(
        imgui.ImVec2(barX, barY),
        imgui.ImVec2(barX + barW, barY + barH),
        0xFF333344, rounding
    )

    -- Center marker (small triangle/line)
    local centerX = barX + barW * 0.5
    dl:AddTriangleFilled(
        imgui.ImVec2(centerX - 4 * scale, barY),
        imgui.ImVec2(centerX + 4 * scale, barY),
        imgui.ImVec2(centerX, barY + 6 * scale),
        centerColor
    )

    -- Compass field of view (degrees visible across the bar)
    local fov = opts.fov or 180

    -- Clip region
    dl:PushClipRect(
        imgui.ImVec2(barX + 2, barY),
        imgui.ImVec2(barX + barW - 2, barY + barH),
        true
    )

    -- Draw degree ticks and labels
    local halfFov = fov * 0.5
    local normalizedHeading = normalizeAngle(heading)

    -- Draw tick marks every 15 degrees
    for deg = 0, 359, 15 do
        local diff = angleDiff(normalizedHeading, deg)
        if math.abs(diff) <= halfFov then
            local ratio = (diff + halfFov) / fov
            local tickX = barX + ratio * barW
            local isMajor = (deg % 90 == 0)
            local isMinor45 = (deg % 45 == 0)

            if isMajor then
                dl:AddLine(
                    imgui.ImVec2(tickX, barY + barH * 0.2),
                    imgui.ImVec2(tickX, barY + barH * 0.45),
                    cardinalColor, 2 * scale
                )
            elseif isMinor45 then
                dl:AddLine(
                    imgui.ImVec2(tickX, barY + barH * 0.3),
                    imgui.ImVec2(tickX, barY + barH * 0.45),
                    tickColor, 1.5 * scale
                )
            else
                dl:AddLine(
                    imgui.ImVec2(tickX, barY + barH * 0.35),
                    imgui.ImVec2(tickX, barY + barH * 0.45),
                    tickColor, 1 * scale
                )
            end
        end
    end

    -- Draw direction labels
    for _, dir in ipairs(DIRECTIONS) do
        local diff = angleDiff(normalizedHeading, dir.deg)
        if math.abs(diff) <= halfFov then
            local ratio = (diff + halfFov) / fov
            local labelX = barX + ratio * barW
            local isCardinal = (dir.deg % 90 == 0)
            local color = isCardinal and cardinalColor or textColor
            local fontSize = isCardinal and (14 * scale) or (11 * scale)

            -- Calculate text size for centering
            local textW = #dir.label * fontSize * 0.5
            dl:AddText(
                imgui.ImVec2(labelX - textW * 0.5, barY + barH * 0.5),
                color, dir.label
            )
        end
    end

    -- Draw degree text at center
    local degText = tostring(math.floor(normalizedHeading)) .. "\xC2\xB0"
    local degTextW = #degText * 5 * scale
    dl:AddText(
        imgui.ImVec2(centerX - degTextW * 0.5, barY + barH * 0.72),
        centerColor, degText
    )

    dl:PopClipRect()
end

--- Draw a waypoint marker on the compass bar
-- @param dl - ImGui DrawList
-- @param compassPos table - {x, y} top-left of compass bar
-- @param compassWidth number - width of compass bar
-- @param playerHeading number - player heading in degrees
-- @param waypointBearing number - bearing to waypoint in degrees
-- @param distance number - distance to waypoint in meters
-- @param opts table - options: fov, markerColor, textColor, scale, height
function compass_lib.drawWaypointMarker(dl, compassPos, compassWidth, playerHeading, waypointBearing, distance, opts)
    opts = opts or {}
    local fov = opts.fov or 180
    local markerColor = opts.markerColor or 0xFF4D99E6
    local textColor = opts.textColor or 0xFF4D99E6
    local scale = opts.scale or 1.0
    local height = (opts.height or 40) * scale

    local halfFov = fov * 0.5
    local diff = angleDiff(normalizeAngle(playerHeading), normalizeAngle(waypointBearing))

    -- Clamp to edges if out of FOV
    local ratio
    local isOnScreen = math.abs(diff) <= halfFov
    if isOnScreen then
        ratio = (diff + halfFov) / fov
    elseif diff > 0 then
        ratio = 0.97 -- right edge
    else
        ratio = 0.03 -- left edge
    end

    local markerX = compassPos.x + ratio * compassWidth
    local markerY = compassPos.y

    -- Draw diamond marker
    local diamondSize = 6 * scale
    dl:AddQuadFilled(
        imgui.ImVec2(markerX, markerY + 2 * scale),
        imgui.ImVec2(markerX + diamondSize, markerY + diamondSize + 2 * scale),
        imgui.ImVec2(markerX, markerY + diamondSize * 2 + 2 * scale),
        imgui.ImVec2(markerX - diamondSize, markerY + diamondSize + 2 * scale),
        markerColor
    )

    -- Draw distance text below marker if on screen
    if isOnScreen then
        local distText = compass_lib.formatDistance(distance)
        local textW = #distText * 5 * scale
        dl:AddText(
            imgui.ImVec2(markerX - textW * 0.5, markerY + height + 2 * scale),
            textColor, distText
        )
    end
end

--- Draw a direction arrow indicator
-- @param dl - ImGui DrawList
-- @param pos table - {x, y} center position
-- @param angle number - angle in degrees (relative to screen up)
-- @param opts table - options: size, color, thickness, scale
function compass_lib.drawDirectionArrow(dl, pos, angle, opts)
    opts = opts or {}
    local size = (opts.size or 12) * (opts.scale or 1.0)
    local color = opts.color or 0xFF4D99E6
    local thickness = (opts.thickness or 2) * (opts.scale or 1.0)

    local rad = math.rad(angle - 90) -- convert to screen coords (0=up)
    local tipX = pos.x + math.cos(rad) * size
    local tipY = pos.y + math.sin(rad) * size
    local baseL_X = pos.x + math.cos(rad + 2.5) * size * 0.5
    local baseL_Y = pos.y + math.sin(rad + 2.5) * size * 0.5
    local baseR_X = pos.x + math.cos(rad - 2.5) * size * 0.5
    local baseR_Y = pos.y + math.sin(rad - 2.5) * size * 0.5

    dl:AddTriangleFilled(
        imgui.ImVec2(tipX, tipY),
        imgui.ImVec2(baseL_X, baseL_Y),
        imgui.ImVec2(baseR_X, baseR_Y),
        color
    )
end

return compass_lib
