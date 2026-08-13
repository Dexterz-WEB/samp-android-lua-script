-- ============================================================================
-- vehiclehud_lib.lua
-- Reusable gauge rendering library for VehicleHUD
-- Drawing functions, vehicle database, vehicle type detection
-- Author: OnlyDexterZ
-- Usage: local vhud = require 'vehiclehud_lib'
-- ============================================================================

local imgui = require 'mimgui'
local memory = require 'memory'

local M = {}

-- ============================================================================
-- VEHICLE DATABASE
-- All SA-MP vehicles (model IDs 400-611)
-- Fields: name (string), maxSpeed (km/h), type (string)
-- Types: Car, Bike, Boat, Plane, Helicopter, Bicycle, Trailer
-- ============================================================================

M.VEHICLE_DATABASE = {
    [400] = { name = "Landstalker", maxSpeed = 160, type = "Car" },
    [401] = { name = "Bravura", maxSpeed = 150, type = "Car" },
    [402] = { name = "Buffalo", maxSpeed = 200, type = "Car" },
    [403] = { name = "Linerunner", maxSpeed = 110, type = "Car" },
    [404] = { name = "Perennial", maxSpeed = 140, type = "Car" },
    [405] = { name = "Sentinel", maxSpeed = 165, type = "Car" },
    [406] = { name = "Dumper", maxSpeed = 110, type = "Car" },
    [407] = { name = "Firetruck", maxSpeed = 150, type = "Car" },
    [408] = { name = "Trashmaster", maxSpeed = 110, type = "Car" },
    [409] = { name = "Stretch", maxSpeed = 160, type = "Car" },
    [410] = { name = "Manana", maxSpeed = 140, type = "Car" },
    [411] = { name = "Infernus", maxSpeed = 240, type = "Car" },
    [412] = { name = "Voodoo", maxSpeed = 165, type = "Car" },
    [413] = { name = "Pony", maxSpeed = 130, type = "Car" },
    [414] = { name = "Mule", maxSpeed = 120, type = "Car" },
    [415] = { name = "Cheetah", maxSpeed = 230, type = "Car" },
    [416] = { name = "Ambulance", maxSpeed = 155, type = "Car" },
    [417] = { name = "Leviathan", maxSpeed = 180, type = "Helicopter" },
    [418] = { name = "Moonbeam", maxSpeed = 140, type = "Car" },
    [419] = { name = "Esperanto", maxSpeed = 150, type = "Car" },
    [420] = { name = "Taxi", maxSpeed = 155, type = "Car" },
    [421] = { name = "Washington", maxSpeed = 160, type = "Car" },
    [422] = { name = "Bobcat", maxSpeed = 150, type = "Car" },
    [423] = { name = "Mr Whoopee", maxSpeed = 110, type = "Car" },
    [424] = { name = "BF Injection", maxSpeed = 150, type = "Car" },
    [425] = { name = "Hunter", maxSpeed = 200, type = "Helicopter" },
    [426] = { name = "Premier", maxSpeed = 175, type = "Car" },
    [427] = { name = "Enforcer", maxSpeed = 155, type = "Car" },
    [428] = { name = "Securicar", maxSpeed = 150, type = "Car" },
    [429] = { name = "Banshee", maxSpeed = 220, type = "Car" },
    [430] = { name = "Predator", maxSpeed = 90, type = "Boat" },
    [431] = { name = "Bus", maxSpeed = 130, type = "Car" },
    [432] = { name = "Rhino", maxSpeed = 90, type = "Car" },
    [433] = { name = "Barracks", maxSpeed = 130, type = "Car" },
    [434] = { name = "Hotknife", maxSpeed = 180, type = "Car" },
    [435] = { name = "Trailer 1", maxSpeed = 0, type = "Trailer" },
    [436] = { name = "Previon", maxSpeed = 155, type = "Car" },
    [437] = { name = "Coach", maxSpeed = 140, type = "Car" },
    [438] = { name = "Cabbie", maxSpeed = 155, type = "Car" },
    [439] = { name = "Stallion", maxSpeed = 170, type = "Car" },
    [440] = { name = "Rumpo", maxSpeed = 140, type = "Car" },
    [441] = { name = "RC Bandit", maxSpeed = 75, type = "Car" },
    [442] = { name = "Romero", maxSpeed = 140, type = "Car" },
    [443] = { name = "Packer", maxSpeed = 130, type = "Car" },
    [444] = { name = "Monster", maxSpeed = 110, type = "Car" },
    [445] = { name = "Admiral", maxSpeed = 165, type = "Car" },
    [446] = { name = "Squalo", maxSpeed = 100, type = "Boat" },
    [447] = { name = "Seasparrow", maxSpeed = 170, type = "Helicopter" },
    [448] = { name = "Pizzaboy", maxSpeed = 100, type = "Bike" },
    [449] = { name = "Tram", maxSpeed = 80, type = "Car" },
    [450] = { name = "Trailer 2", maxSpeed = 0, type = "Trailer" },
    [451] = { name = "Turismo", maxSpeed = 230, type = "Car" },
    [452] = { name = "Speeder", maxSpeed = 100, type = "Boat" },
    [453] = { name = "Reefer", maxSpeed = 60, type = "Boat" },
    [454] = { name = "Tropic", maxSpeed = 80, type = "Boat" },
    [455] = { name = "Flatbed", maxSpeed = 130, type = "Car" },
    [456] = { name = "Yankee", maxSpeed = 120, type = "Car" },
    [457] = { name = "Caddy", maxSpeed = 70, type = "Car" },
    [458] = { name = "Solair", maxSpeed = 155, type = "Car" },
    [459] = { name = "Berkley's RC Van", maxSpeed = 130, type = "Car" },
    [460] = { name = "Skimmer", maxSpeed = 160, type = "Plane" },
    [461] = { name = "PCJ-600", maxSpeed = 180, type = "Bike" },
    [462] = { name = "Faggio", maxSpeed = 90, type = "Bike" },
    [463] = { name = "Freeway", maxSpeed = 160, type = "Bike" },
    [464] = { name = "RC Baron", maxSpeed = 75, type = "Plane" },
    [465] = { name = "RC Raider", maxSpeed = 75, type = "Helicopter" },
    [466] = { name = "Glendale", maxSpeed = 150, type = "Car" },
    [467] = { name = "Oceanic", maxSpeed = 145, type = "Car" },
    [468] = { name = "Sanchez", maxSpeed = 160, type = "Bike" },
    [469] = { name = "Sparrow", maxSpeed = 160, type = "Helicopter" },
    [470] = { name = "Patriot", maxSpeed = 160, type = "Car" },
    [471] = { name = "Quad", maxSpeed = 120, type = "Bike" },
    [472] = { name = "Coastguard", maxSpeed = 80, type = "Boat" },
    [473] = { name = "Dinghy", maxSpeed = 70, type = "Boat" },
    [474] = { name = "Hermes", maxSpeed = 155, type = "Car" },
    [475] = { name = "Sabre", maxSpeed = 175, type = "Car" },
    [476] = { name = "Rustler", maxSpeed = 250, type = "Plane" },
    [477] = { name = "ZR-350", maxSpeed = 210, type = "Car" },
    [478] = { name = "Walton", maxSpeed = 130, type = "Car" },
    [479] = { name = "Regina", maxSpeed = 140, type = "Car" },
    [480] = { name = "Comet", maxSpeed = 210, type = "Car" },
    [481] = { name = "BMX", maxSpeed = 45, type = "Bicycle" },
    [482] = { name = "Burrito", maxSpeed = 150, type = "Car" },
    [483] = { name = "Camper", maxSpeed = 130, type = "Car" },
    [484] = { name = "Marquis", maxSpeed = 60, type = "Boat" },
    [485] = { name = "Baggage", maxSpeed = 80, type = "Car" },
    [486] = { name = "Dozer", maxSpeed = 70, type = "Car" },
    [487] = { name = "Maverick", maxSpeed = 180, type = "Helicopter" },
    [488] = { name = "News Chopper", maxSpeed = 170, type = "Helicopter" },
    [489] = { name = "Rancher", maxSpeed = 155, type = "Car" },
    [490] = { name = "FBI Rancher", maxSpeed = 170, type = "Car" },
    [491] = { name = "Virgo", maxSpeed = 155, type = "Car" },
    [492] = { name = "Greenwood", maxSpeed = 150, type = "Car" },
    [493] = { name = "Jetmax", maxSpeed = 110, type = "Boat" },
    [494] = { name = "Hotring Racer", maxSpeed = 230, type = "Car" },
    [495] = { name = "Sandking", maxSpeed = 170, type = "Car" },
    [496] = { name = "Blista Compact", maxSpeed = 175, type = "Car" },
    [497] = { name = "Police Maverick", maxSpeed = 180, type = "Helicopter" },
    [498] = { name = "Boxville", maxSpeed = 120, type = "Car" },
    [499] = { name = "Benson", maxSpeed = 120, type = "Car" },
    [500] = { name = "Mesa", maxSpeed = 150, type = "Car" },
    [501] = { name = "RC Goblin", maxSpeed = 75, type = "Helicopter" },
    [502] = { name = "Hotring Racer A", maxSpeed = 230, type = "Car" },
    [503] = { name = "Hotring Racer B", maxSpeed = 230, type = "Car" },
    [504] = { name = "Bloodring Banger", maxSpeed = 170, type = "Car" },
    [505] = { name = "Rancher", maxSpeed = 155, type = "Car" },
    [506] = { name = "Super GT", maxSpeed = 220, type = "Car" },
    [507] = { name = "Elegant", maxSpeed = 175, type = "Car" },
    [508] = { name = "Journey", maxSpeed = 120, type = "Car" },
    [509] = { name = "Bike", maxSpeed = 45, type = "Bicycle" },
    [510] = { name = "Mountain Bike", maxSpeed = 50, type = "Bicycle" },
    [511] = { name = "Beagle", maxSpeed = 180, type = "Plane" },
    [512] = { name = "Cropduster", maxSpeed = 160, type = "Plane" },
    [513] = { name = "Stuntplane", maxSpeed = 200, type = "Plane" },
    [514] = { name = "Petrol Tanker", maxSpeed = 120, type = "Car" },
    [515] = { name = "Roadtrain", maxSpeed = 130, type = "Car" },
    [516] = { name = "Nebula", maxSpeed = 165, type = "Car" },
    [517] = { name = "Majestic", maxSpeed = 160, type = "Car" },
    [518] = { name = "Buccaneer", maxSpeed = 165, type = "Car" },
    [519] = { name = "Shamal", maxSpeed = 250, type = "Plane" },
    [520] = { name = "Hydra", maxSpeed = 300, type = "Plane" },
    [521] = { name = "FCR-900", maxSpeed = 190, type = "Bike" },
    [522] = { name = "NRG-500", maxSpeed = 220, type = "Bike" },
    [523] = { name = "HPV1000", maxSpeed = 180, type = "Bike" },
    [524] = { name = "Cement Truck", maxSpeed = 120, type = "Car" },
    [525] = { name = "Tow Truck", maxSpeed = 140, type = "Car" },
    [526] = { name = "Fortune", maxSpeed = 165, type = "Car" },
    [527] = { name = "Cadrona", maxSpeed = 155, type = "Car" },
    [528] = { name = "FBI Truck", maxSpeed = 160, type = "Car" },
    [529] = { name = "Willard", maxSpeed = 150, type = "Car" },
    [530] = { name = "Forklift", maxSpeed = 50, type = "Car" },
    [531] = { name = "Tractor", maxSpeed = 50, type = "Car" },
    [532] = { name = "Combine Harvester", maxSpeed = 70, type = "Car" },
    [533] = { name = "Feltzer", maxSpeed = 180, type = "Car" },
    [534] = { name = "Remington", maxSpeed = 165, type = "Car" },
    [535] = { name = "Slamvan", maxSpeed = 160, type = "Car" },
    [536] = { name = "Blade", maxSpeed = 170, type = "Car" },
    [537] = { name = "Freight", maxSpeed = 80, type = "Car" },
    [538] = { name = "Streak", maxSpeed = 80, type = "Car" },
    [539] = { name = "Vortex", maxSpeed = 80, type = "Boat" },
    [540] = { name = "Vincent", maxSpeed = 155, type = "Car" },
    [541] = { name = "Bullet", maxSpeed = 230, type = "Car" },
    [542] = { name = "Clover", maxSpeed = 165, type = "Car" },
    [543] = { name = "Sadler", maxSpeed = 150, type = "Car" },
    [544] = { name = "Firetruck LA", maxSpeed = 150, type = "Car" },
    [545] = { name = "Hustler", maxSpeed = 155, type = "Car" },
    [546] = { name = "Intruder", maxSpeed = 155, type = "Car" },
    [547] = { name = "Primo", maxSpeed = 155, type = "Car" },
    [548] = { name = "Cargobob", maxSpeed = 180, type = "Helicopter" },
    [549] = { name = "Tampa", maxSpeed = 160, type = "Car" },
    [550] = { name = "Sunrise", maxSpeed = 155, type = "Car" },
    [551] = { name = "Merit", maxSpeed = 165, type = "Car" },
    [552] = { name = "Utility Van", maxSpeed = 130, type = "Car" },
    [553] = { name = "Nevada", maxSpeed = 220, type = "Plane" },
    [554] = { name = "Yosemite", maxSpeed = 150, type = "Car" },
    [555] = { name = "Windsor", maxSpeed = 170, type = "Car" },
    [556] = { name = "Monster A", maxSpeed = 110, type = "Car" },
    [557] = { name = "Monster B", maxSpeed = 110, type = "Car" },
    [558] = { name = "Uranus", maxSpeed = 180, type = "Car" },
    [559] = { name = "Jester", maxSpeed = 200, type = "Car" },
    [560] = { name = "Sultan", maxSpeed = 200, type = "Car" },
    [561] = { name = "Stratum", maxSpeed = 165, type = "Car" },
    [562] = { name = "Elegy", maxSpeed = 200, type = "Car" },
    [563] = { name = "Raindance", maxSpeed = 170, type = "Helicopter" },
    [564] = { name = "RC Tiger", maxSpeed = 75, type = "Car" },
    [565] = { name = "Flash", maxSpeed = 175, type = "Car" },
    [566] = { name = "Tahoma", maxSpeed = 160, type = "Car" },
    [567] = { name = "Savanna", maxSpeed = 165, type = "Car" },
    [568] = { name = "Bandito", maxSpeed = 160, type = "Car" },
    [569] = { name = "Freight Flat", maxSpeed = 80, type = "Car" },
    [570] = { name = "Streak Carriage", maxSpeed = 80, type = "Car" },
    [571] = { name = "Kart", maxSpeed = 90, type = "Car" },
    [572] = { name = "Mower", maxSpeed = 50, type = "Car" },
    [573] = { name = "Dune", maxSpeed = 130, type = "Car" },
    [574] = { name = "Sweeper", maxSpeed = 60, type = "Car" },
    [575] = { name = "Broadway", maxSpeed = 155, type = "Car" },
    [576] = { name = "Tornado", maxSpeed = 155, type = "Car" },
    [577] = { name = "AT-400", maxSpeed = 300, type = "Plane" },
    [578] = { name = "DFT-30", maxSpeed = 130, type = "Car" },
    [579] = { name = "Huntley", maxSpeed = 165, type = "Car" },
    [580] = { name = "Stafford", maxSpeed = 160, type = "Car" },
    [581] = { name = "BF-400", maxSpeed = 170, type = "Bike" },
    [582] = { name = "Newsvan", maxSpeed = 140, type = "Car" },
    [583] = { name = "Tug", maxSpeed = 60, type = "Car" },
    [584] = { name = "Trailer 3", maxSpeed = 0, type = "Trailer" },
    [585] = { name = "Emperor", maxSpeed = 155, type = "Car" },
    [586] = { name = "Wayfarer", maxSpeed = 150, type = "Bike" },
    [587] = { name = "Euros", maxSpeed = 190, type = "Car" },
    [588] = { name = "Hotdog", maxSpeed = 120, type = "Car" },
    [589] = { name = "Club", maxSpeed = 165, type = "Car" },
    [590] = { name = "Freight Carriage", maxSpeed = 80, type = "Car" },
    [591] = { name = "Trailer 3", maxSpeed = 0, type = "Trailer" },
    [592] = { name = "Andromada", maxSpeed = 250, type = "Plane" },
    [593] = { name = "Dodo", maxSpeed = 180, type = "Plane" },
    [594] = { name = "RC Cam", maxSpeed = 50, type = "Car" },
    [595] = { name = "Launch", maxSpeed = 80, type = "Boat" },
    [596] = { name = "Police Car (LSPD)", maxSpeed = 175, type = "Car" },
    [597] = { name = "Police Car (SFPD)", maxSpeed = 175, type = "Car" },
    [598] = { name = "Police Car (LVPD)", maxSpeed = 175, type = "Car" },
    [599] = { name = "Police Ranger", maxSpeed = 160, type = "Car" },
    [600] = { name = "Picador", maxSpeed = 155, type = "Car" },
    [601] = { name = "S.W.A.T.", maxSpeed = 140, type = "Car" },
    [602] = { name = "Alpha", maxSpeed = 175, type = "Car" },
    [603] = { name = "Phoenix", maxSpeed = 190, type = "Car" },
    [604] = { name = "Glendale", maxSpeed = 150, type = "Car" },
    [605] = { name = "Sadler", maxSpeed = 150, type = "Car" },
    [606] = { name = "Luggage Trailer A", maxSpeed = 0, type = "Trailer" },
    [607] = { name = "Luggage Trailer B", maxSpeed = 0, type = "Trailer" },
    [608] = { name = "Stair Trailer", maxSpeed = 0, type = "Trailer" },
    [609] = { name = "Boxville", maxSpeed = 120, type = "Car" },
    [610] = { name = "Farm Plow", maxSpeed = 0, type = "Trailer" },
    [611] = { name = "Utility Trailer", maxSpeed = 0, type = "Trailer" },
}

-- ============================================================================
-- VEHICLE LOOKUP FUNCTIONS
-- ============================================================================

--- Get vehicle name from model ID
-- @param modelId number - SA-MP vehicle model ID (400-611)
-- @return string - vehicle name or 'Unknown'
function M.getVehicleName(modelId)
    local entry = M.VEHICLE_DATABASE[modelId]
    if entry then
        return entry.name
    end
    return "Unknown"
end

--- Get vehicle type from model ID
-- @param modelId number - SA-MP vehicle model ID (400-611)
-- @return string - vehicle type or 'Car' as default
function M.getVehicleType(modelId)
    local entry = M.VEHICLE_DATABASE[modelId]
    if entry then
        return entry.type
    end
    return "Car"
end

--- Get max speed for gauge scaling
-- @param modelId number - SA-MP vehicle model ID (400-611)
-- @return number - max speed in km/h (minimum 180 for safe gauge scaling)
function M.getMaxSpeed(modelId)
    local entry = M.VEHICLE_DATABASE[modelId]
    if entry and entry.maxSpeed > 0 then
        return entry.maxSpeed
    end
    return 180  -- safe default
end

-- ============================================================================
-- SMOOTH VALUE INTERPOLATION
-- ============================================================================

--- Smooth value interpolation (lerp helper for needle animation)
-- @param current number - current value
-- @param target number - target value
-- @param speed number - interpolation speed (0.0 to 1.0)
-- @return number - interpolated value
function M.smoothValue(current, target, speed)
    return current + (target - current) * speed
end

-- ============================================================================
-- ANGLE / ARC UTILITIES
-- ============================================================================

--- Convert a value to the corresponding angle on an arc gauge
-- @param value number - current value (e.g. speed)
-- @param maxValue number - maximum value for the gauge
-- @param minAngle number - start angle of the arc (radians)
-- @param maxAngle number - end angle of the arc (radians)
-- @return number - angle in radians corresponding to the value
function M.angleForValue(value, maxValue, minAngle, maxAngle)
    if maxValue <= 0 then return minAngle end
    local t = value / maxValue
    if t < 0 then t = 0 end
    if t > 1 then t = 1 end
    return minAngle + (maxAngle - minAngle) * t
end

-- ============================================================================
-- DRAWING FUNCTIONS
-- All drawing functions use dl:AddLine and dl:AddText (ImGui DrawList methods)
-- NO pcall inside any drawing function (MonetLoader constraint)
-- All angles are in radians for math.sin/math.cos
-- Colors are passed as uint32 values (already converted by caller)
-- ============================================================================

-- Default arc angles: 180-degree semicircle sweep (classic SA-style)
local DEFAULT_MIN_ANGLE = math.rad(-180)
local DEFAULT_MAX_ANGLE = math.rad(0)

--- Draw a filled semicircle background using horizontal rect strips
-- Creates a dark backdrop matching the gauge arc shape
-- Uses AddRectFilled for MonetLoader compatibility (AddTriangleFilled not available)
-- @param dl - ImGui DrawList
-- @param cx number - center X position
-- @param cy number - center Y position
-- @param radius number - radius of the semicircle
-- @param color number - fill color (uint32)
-- @param segments number - number of horizontal strips (higher = smoother)
function M.drawSemicircleBackground(dl, cx, cy, radius, color, segments)
    -- Approximate semicircle using a series of horizontal filled rects
    -- from top of semicircle down to center line
    segments = segments or 60
    local step = radius / segments

    for i = 0, segments - 1 do
        local yOff = -radius + step * i
        -- Width at this Y level using circle equation: x = sqrt(r^2 - y^2)
        local halfWidth = math.sqrt(radius * radius - yOff * yOff)

        dl:AddRectFilled(
            imgui.ImVec2(cx - halfWidth, cy + yOff),
            imgui.ImVec2(cx + halfWidth, cy + yOff + step),
            color
        )
    end
end

--- Draw tick marks along the arc
-- @param dl - ImGui DrawList
-- @param cx number - center X position
-- @param cy number - center Y position
-- @param radius number - radius of the arc
-- @param count number - number of tick marks
-- @param options table - {minAngle, maxAngle, innerRadius, outerRadius, color, majorEvery, thickness, redZoneColor, redZoneStart}
function M.drawTickMarks(dl, cx, cy, radius, count, options)
    options = options or {}
    local minAngle = options.minAngle or DEFAULT_MIN_ANGLE
    local maxAngle = options.maxAngle or DEFAULT_MAX_ANGLE
    local innerRadius = options.innerRadius or (radius * 0.85)
    local outerRadius = options.outerRadius or radius
    local defaultColor = options.color or 0xFFDDDDDD
    local majorEvery = options.majorEvery or 5
    local thickness = options.thickness or 1.5
    local redZoneColor = options.redZoneColor or defaultColor
    local redZoneStart = options.redZoneStart or 0.82

    local angleRange = maxAngle - minAngle

    for i = 0, count - 1 do
        local t = i / (count - 1)
        local angle = minAngle + angleRange * t
        local isMajor = (i % majorEvery == 0)

        -- Determine tick color
        local tickColor = defaultColor
        if t >= redZoneStart then
            tickColor = redZoneColor
        end

        -- Major ticks are longer
        local inner = isMajor and (innerRadius * 0.9) or innerRadius
        local thick = isMajor and (thickness * 1.5) or thickness

        local x1 = cx + inner * math.cos(angle)
        local y1 = cy + inner * math.sin(angle)
        local x2 = cx + outerRadius * math.cos(angle)
        local y2 = cy + outerRadius * math.sin(angle)

        dl:AddLine(imgui.ImVec2(x1, y1), imgui.ImVec2(x2, y2), tickColor, thick)
    end
end

--- Draw speed number labels along the arc
-- @param dl - ImGui DrawList
-- @param cx number - center X position
-- @param cy number - center Y position
-- @param radius number - radius for text placement
-- @param maxSpeed number - maximum speed value
-- @param interval number - speed interval between labels
-- @param options table - {minAngle, maxAngle, color, offset}
function M.drawSpeedNumbers(dl, cx, cy, radius, maxSpeed, interval, options)
    options = options or {}
    local minAngle = options.minAngle or DEFAULT_MIN_ANGLE
    local maxAngle = options.maxAngle or DEFAULT_MAX_ANGLE
    local color = options.color or 0xFFDDDDDD
    local offset = options.offset or 0

    local textRadius = radius + offset

    if maxSpeed <= 0 or interval <= 0 then return end

    local angleRange = maxAngle - minAngle

    for speed = 0, maxSpeed, interval do
        local t = speed / maxSpeed
        local angle = minAngle + angleRange * t

        local x = cx + textRadius * math.cos(angle)
        local y = cy + textRadius * math.sin(angle)

        -- Center-approximate the text
        local text = tostring(speed)
        local textOffsetX = #text * 3.0
        local textOffsetY = 6.0

        dl:AddText(
            imgui.ImVec2(x - textOffsetX, y - textOffsetY),
            color,
            text
        )
    end
end

--- Draw a needle line from center to arc edge at given angle
-- @param dl - ImGui DrawList
-- @param cx number - center X position
-- @param cy number - center Y position
-- @param length number - length of needle
-- @param angle number - angle in radians
-- @param options table - {color, thickness}
function M.drawNeedle(dl, cx, cy, length, angle, options)
    options = options or {}
    local color = options.color or 0xFFFF3333
    local thickness = options.thickness or 2.0

    local endX = cx + length * math.cos(angle)
    local endY = cy + length * math.sin(angle)

    dl:AddLine(imgui.ImVec2(cx, cy), imgui.ImVec2(endX, endY), color, thickness)
end

--- Draw a horizontal health bar
-- @param dl - ImGui DrawList
-- @param x number - top-left X position
-- @param y number - top-left Y position
-- @param width number - bar width
-- @param height number - bar height
-- @param percent number - fill percentage (0.0 to 1.0)
-- @param options table - {bgColor, fillColor, borderColor, rounding}
function M.drawHealthBar(dl, x, y, width, height, percent, options)
    options = options or {}
    local bgColor = options.bgColor or 0x66000000
    local fillColor = options.fillColor or 0xFF44CC44
    local borderColor = options.borderColor
    local rounding = options.rounding or 2.0

    -- Clamp percent
    if percent < 0 then percent = 0 end
    if percent > 1 then percent = 1 end

    -- Draw background
    dl:AddRectFilled(
        imgui.ImVec2(x, y),
        imgui.ImVec2(x + width, y + height),
        bgColor, rounding
    )

    -- Draw fill
    local fillWidth = width * percent
    if fillWidth > 0 then
        dl:AddRectFilled(
            imgui.ImVec2(x, y),
            imgui.ImVec2(x + fillWidth, y + height),
            fillColor, rounding
        )
    end

    -- Draw border if provided
    if borderColor then
        dl:AddLine(imgui.ImVec2(x, y), imgui.ImVec2(x + width, y), borderColor, 1.0)
        dl:AddLine(imgui.ImVec2(x, y + height), imgui.ImVec2(x + width, y + height), borderColor, 1.0)
        dl:AddLine(imgui.ImVec2(x, y), imgui.ImVec2(x, y + height), borderColor, 1.0)
        dl:AddLine(imgui.ImVec2(x + width, y), imgui.ImVec2(x + width, y + height), borderColor, 1.0)
    end
end

-- ============================================================================
-- GEAR AND HEADING UTILITIES
-- ============================================================================

--- Get vehicle RPM and Gear data directly from memory
-- @param veh number - vehicle handle
-- @param carPtr number - vehicle memory pointer
-- @param engineOn boolean - engine status
-- @param speedKmh number - current speed in km/h
-- @return number, number - rpmInt (0-7000), gear (1-6)
function M.getVehicleData(veh, carPtr, engineOn, speedKmh)
    local rpmInt = 0
    local gear = 1

    if not engineOn or not carPtr or carPtr == 0 then
        return 0, 1
    end

    -- Read native RPM from memory (offset 0x420)
    pcall(function()
        local fRpm = memory.getfloat(carPtr + 0x420, true)
        if fRpm then
            -- GTA RPM is 0.0 to 1.0+, we scale it to 0-7000 for the gauge
            rpmInt = math.floor(fRpm * 7000)
            if rpmInt < 0 then rpmInt = 0 end
        end
    end)

    -- Read native Gear from memory (offset 0x48B)
    -- m_nCurrentGear: 0 = Reverse, 1 = 1st, etc. (Neutral isn't a dedicated state here)
    pcall(function()
        local mGear = memory.getuint8(carPtr + 0x48B, true)
        if mGear then
            gear = mGear
        end
    end)

    -- Fallback for gear if memory read is unusual (optional)
    if gear > 6 then
        gear = M.getGearFromSpeed(speedKmh, M.getVehicleType(getCarModel(veh)))
    end

    return rpmInt, gear
end

--- Get a display-friendly label for the current gear
-- @param gear number - current gear (0=Reverse, 1=1st, etc.)
-- @param engineOn boolean - engine status
-- @param speedKmh number - current speed in km/h
-- @return string - gear label (e.g. "R", "N", "1", "2")
function M.getGearLabel(gear, engineOn, speedKmh)
    if not engineOn then return "N" end
    
    -- Gear 0 is Reverse in GTA memory
    if gear == 0 then return "R" end
    
    -- If speed is near zero and gear is 1, show Neutral
    if speedKmh < 1.0 and gear == 1 then
        return "N"
    end
    
    return tostring(gear)
end

--- Estimate gear (1-6) from speed and vehicle type
-- @param speedKmh number - current speed in km/h
-- @param vehicleType string - vehicle type (Car, Bike, Bicycle, etc.)
-- @return number - estimated gear (1-6)
function M.getGearFromSpeed(speedKmh, vehicleType)
    if speedKmh <= 0 then return 1 end

    -- Bicycles only have 1 gear conceptually
    if vehicleType == "Bicycle" then
        return 1
    end

    -- Boats and aircraft do not have traditional gears
    if vehicleType == "Boat" or vehicleType == "Plane" or vehicleType == "Helicopter" then
        if speedKmh < 30 then return 1 end
        if speedKmh < 60 then return 2 end
        if speedKmh < 100 then return 3 end
        return 4
    end

    -- Bikes use 6-gear estimation
    if vehicleType == "Bike" then
        if speedKmh < 30 then return 1 end
        if speedKmh < 60 then return 2 end
        if speedKmh < 100 then return 3 end
        if speedKmh < 140 then return 4 end
        if speedKmh < 180 then return 5 end
        return 6
    end

    -- Default: Car gear thresholds
    if speedKmh < 20 then return 1 end
    if speedKmh < 45 then return 2 end
    if speedKmh < 75 then return 3 end
    if speedKmh < 110 then return 4 end
    if speedKmh < 150 then return 5 end
    return 6
end

--- Convert heading degrees (0-360) to cardinal direction string
-- @param heading number - heading in degrees (0=North, clockwise)
-- @return string - cardinal direction (N, NE, E, SE, S, SW, W, NW)
function M.getHeadingDirection(heading)
    -- Normalize to 0-360
    heading = heading % 360
    if heading < 0 then heading = heading + 360 end

    -- 8 directions, each covers 45 degrees
    if heading >= 337.5 or heading < 22.5 then
        return "N"
    elseif heading >= 22.5 and heading < 67.5 then
        return "NE"
    elseif heading >= 67.5 and heading < 112.5 then
        return "E"
    elseif heading >= 112.5 and heading < 157.5 then
        return "SE"
    elseif heading >= 157.5 and heading < 202.5 then
        return "S"
    elseif heading >= 202.5 and heading < 247.5 then
        return "SW"
    elseif heading >= 247.5 and heading < 292.5 then
        return "W"
    else
        return "NW"
    end
end

return M
