-- ============================================================================
-- worldtoscreen_lib.lua
-- Library for converting 3D world coordinates to 2D screen coordinates
-- Uses manual camera projection (confirmed working on MonetLoader Android)
-- Author: OnlyDexterZ
-- Usage: local w2s = require 'lib.worldtoscreen_lib'
--        local sx, sy, visible = w2s.project(worldX, worldY, worldZ)
-- ============================================================================

local M = {}

-- ============================================================================
-- CONFIG (can be overridden by user)
-- ============================================================================
M.FOV = 70.0              -- Field of view (degrees)
M.MAX_TILT_ANGLE = 30     -- Max camera pitch before hiding (degrees, 0 = disabled)
M.SCREEN_OFFSET_X = 0     -- Pixel offset X after projection
M.SCREEN_OFFSET_Y = 0     -- Pixel offset Y after projection

-- ============================================================================
-- CORE PROJECTION FUNCTION
-- Projects a 3D world position to 2D screen coordinates
-- Returns: screenX, screenY, isVisible (boolean)
-- ============================================================================
function M.project(worldX, worldY, worldZ)
    -- Get camera position and look-at point
    local camX, camY, camZ, lookX, lookY, lookZ
    local ok1 = pcall(function()
        camX, camY, camZ = getActiveCameraCoordinates()
    end)
    local ok2 = pcall(function()
        lookX, lookY, lookZ = getActiveCameraPointAt()
    end)

    if not ok1 or not ok2 or not camX or not lookX then
        return 0, 0, false
    end

    local screenW, screenH = 800, 600
    pcall(function()
        screenW, screenH = getScreenResolution()
    end)

    -- Build camera forward vector
    local fwdX = lookX - camX
    local fwdY = lookY - camY
    local fwdZ = lookZ - camZ
    local fwdLen = math.sqrt(fwdX * fwdX + fwdY * fwdY + fwdZ * fwdZ)
    if fwdLen < 0.001 then return 0, 0, false end
    fwdX = fwdX / fwdLen
    fwdY = fwdY / fwdLen
    fwdZ = fwdZ / fwdLen

    -- Calculate camera pitch angle
    local fwdLen2D = math.sqrt(fwdX * fwdX + fwdY * fwdY)
    local camPitch = math.deg(math.atan2(fwdZ, fwdLen2D))

    -- Tilt angle limit
    if M.MAX_TILT_ANGLE > 0 and math.abs(camPitch) > M.MAX_TILT_ANGLE then
        return 0, 0, false
    end

    -- World up
    local wupX, wupY, wupZ = 0, 0, 1

    -- Right = forward x world_up (normalize)
    local rightX = fwdY * wupZ - fwdZ * wupY
    local rightY = fwdZ * wupX - fwdX * wupZ
    local rightZ = fwdX * wupY - fwdY * wupX
    local rightLen = math.sqrt(rightX * rightX + rightY * rightY + rightZ * rightZ)
    if rightLen < 0.001 then return 0, 0, false end
    rightX = rightX / rightLen
    rightY = rightY / rightLen
    rightZ = rightZ / rightLen

    -- Up = right x forward
    local upX = rightY * fwdZ - rightZ * fwdY
    local upY = rightZ * fwdX - rightX * fwdZ
    local upZ = rightX * fwdY - rightY * fwdX

    -- Vector from camera to target
    local dx = worldX - camX
    local dy = worldY - camY
    local dz = worldZ - camZ

    -- Project onto camera axes
    local dotFwd   = dx * fwdX   + dy * fwdY   + dz * fwdZ
    local dotRight = dx * rightX + dy * rightY + dz * rightZ
    local dotUp    = dx * upX    + dy * upY    + dz * upZ

    -- Behind camera check
    if dotFwd <= 0.1 then return 0, 0, false end

    -- Perspective projection
    local aspect = screenW / screenH
    local tanHalfFov = math.tan(math.rad(M.FOV * 0.5))

    local ndcX = (dotRight / dotFwd) / (tanHalfFov * aspect)
    local ndcY = (dotUp / dotFwd) / tanHalfFov

    -- NDC to screen (Y is flipped - screen Y goes down)
    local sx = (ndcX * 0.5 + 0.5) * screenW + M.SCREEN_OFFSET_X
    local sy = (-ndcY * 0.5 + 0.5) * screenH + M.SCREEN_OFFSET_Y

    -- Check if on screen (with margin)
    if sx >= -200 and sx <= screenW + 200 and sy >= -200 and sy <= screenH + 200 then
        return sx, sy, true
    end

    return 0, 0, false
end

-- ============================================================================
-- HELPER: Get distance between two 3D points
-- ============================================================================
function M.getDistance(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- ============================================================================
-- HELPER: Check if a world position is visible on screen
-- ============================================================================
function M.isVisible(worldX, worldY, worldZ)
    local _, _, visible = M.project(worldX, worldY, worldZ)
    return visible
end

-- ============================================================================
-- HELPER: Get camera pitch angle (degrees)
-- Returns pitch or nil if camera unavailable
-- ============================================================================
function M.getCameraPitch()
    local camX, camY, camZ, lookX, lookY, lookZ
    local ok1 = pcall(function()
        camX, camY, camZ = getActiveCameraCoordinates()
    end)
    local ok2 = pcall(function()
        lookX, lookY, lookZ = getActiveCameraPointAt()
    end)
    if not ok1 or not ok2 or not camX or not lookX then
        return nil
    end
    local fwdX = lookX - camX
    local fwdY = lookY - camY
    local fwdZ = lookZ - camZ
    local fwdLen2D = math.sqrt(fwdX * fwdX + fwdY * fwdY)
    return math.deg(math.atan2(fwdZ, fwdLen2D))
end

return M
