-- chatengine_lib.lua
-- Core library module for ChatEngine: message buffer, color parsing, category detection
-- Used by ChatEngine.lua via: local chatlib = require 'chatengine_lib'

local M = {}

-- Ring buffer configuration
local MAX_BUFFER_SIZE = 200
local buffer = {}
local bufferHead = 1
local bufferCount = 0
local insertionCount = 0 -- Monotonically-increasing counter (never resets, never caps)

-- ============================================================================
-- Timestamp formatting
-- ============================================================================

local function formatTimestamp()
    return os.date('[%H:%M]')
end

-- ============================================================================
-- Color int32 to RGBA conversion
-- SA-MP sends color as int32 in 0xAARRGGBB or 0xRRGGBB format
-- Returns r, g, b, a as floats 0-1
-- ============================================================================

function M.colorToRGBA(color)
    if color == nil then
        return 1, 1, 1, 1
    end
    -- Use bit library for safe decomposition of signed int32 values on LuaJIT.
    -- SA-MP can send colors with high bit set (e.g. 0xFF6633FF) which become
    -- negative int32 in Lua. The % operator in Lua 5.1 follows dividend sign
    -- for negative numbers, so we use bit.band/bit.rshift instead.
    local bit = require('bit')
    -- Normalize to unsigned 32-bit via bit.tobit (handles both positive and negative)
    local c = bit.tobit(color)
    -- Extract components from AARRGGBB format
    local b = bit.band(c, 0xFF)
    local g = bit.band(bit.rshift(c, 8), 0xFF)
    local r = bit.band(bit.rshift(c, 16), 0xFF)
    local a = bit.band(bit.rshift(c, 24), 0xFF)

    -- If alpha is 0, default to fully opaque (some colors lack alpha)
    if a == 0 then
        a = 255
    end

    return r / 255, g / 255, b / 255, a / 255
end

-- ============================================================================
-- SA-MP color code parser
-- Parses text with {RRGGBB} patterns into colored segments
-- Returns array of {text=string, r=float, g=float, b=float}
-- ============================================================================

function M.parseColorCodes(text, defaultColor)
    local segments = {}

    -- Get default color from the message color parameter
    local defR, defG, defB
    if defaultColor ~= nil then
        defR, defG, defB = M.colorToRGBA(defaultColor)
    else
        defR, defG, defB = 1, 1, 1
    end

    local currentR, currentG, currentB = defR, defG, defB
    local pos = 1
    local textLen = string.len(text)

    while pos <= textLen do
        -- Look for {RRGGBB} pattern
        local startPos, endPos, hexColor = string.find(text, '{(%x%x%x%x%x%x)}', pos)

        if startPos then
            -- Add text before the color code as a segment
            if startPos > pos then
                local segText = string.sub(text, pos, startPos - 1)
                if segText ~= '' then
                    segments[#segments + 1] = {
                        text = segText,
                        r = currentR,
                        g = currentG,
                        b = currentB
                    }
                end
            end

            -- Parse the hex color
            local rHex = string.sub(hexColor, 1, 2)
            local gHex = string.sub(hexColor, 3, 4)
            local bHex = string.sub(hexColor, 5, 6)

            currentR = tonumber(rHex, 16) / 255
            currentG = tonumber(gHex, 16) / 255
            currentB = tonumber(bHex, 16) / 255

            pos = endPos + 1
        else
            -- No more color codes, add remaining text
            local remaining = string.sub(text, pos)
            if remaining ~= '' then
                segments[#segments + 1] = {
                    text = remaining,
                    r = currentR,
                    g = currentG,
                    b = currentB
                }
            end
            break
        end
    end

    -- If no segments were created (empty text or only color codes), return at least empty
    if #segments == 0 and text ~= '' then
        segments[#segments + 1] = {
            text = text,
            r = defR,
            g = defG,
            b = defB
        }
    end

    return segments
end

-- ============================================================================
-- Message category detection
-- Detects: PM, OOC, Action, Ad, Server (default)
-- ============================================================================

function M.detectCategory(text)
    if text == nil or text == '' then
        return 'Server'
    end

    -- Wrap in pcall to prevent crash from unexpected text patterns
    local ok, result = pcall(function()
        -- Strip color codes first for cleaner pattern matching
        local cleanText = string.gsub(text, '{%x%x%x%x%x%x}', '')

        -- PM: contains "Message from" or starts with PM-like format
        if string.find(cleanText, 'Message from') then
            return 'PM'
        end

        -- OOC: starts with "((" or "[OOC]" or contains "((" pattern (common /b format)
        if string.sub(cleanText, 1, 2) == '((' or string.find(cleanText, '^%[OOC%]') or string.find(cleanText, '%(%(.+%)%)') then
            return 'OOC'
        end

        -- Action: starts with "* " but NOT "** "
        if string.sub(cleanText, 1, 2) == '* ' and string.sub(cleanText, 1, 3) ~= '** ' then
            return 'Action'
        end

        -- Ad: starts with "[Advertisement]" or "[AD]"
        if string.find(cleanText, '^%[Advertisement%]') or string.find(cleanText, '^%[AD%]') then
            return 'Ad'
        end

        return 'Server'
    end)

    if ok then return result end
    return 'Server'
end

    -- Default: Server
    return 'Server'
end

-- ============================================================================
-- Ring buffer operations
-- ============================================================================

function M.addMessage(text, color, explicitCategory)
    -- Safety: ensure text is a string
    if text == nil then text = "" end
    if type(text) ~= "string" then text = tostring(text) end

    local timestamp = formatTimestamp()
    -- If explicitCategory is provided, use it directly; otherwise auto-detect
    local category = explicitCategory or M.detectCategory(text)
    local parsedSegments = M.parseColorCodes(text, color)

    local entry = {
        text = text,
        color = color,
        timestamp = timestamp,
        category = category,
        parsed_segments = parsedSegments
    }

    -- Ring buffer insertion
    insertionCount = insertionCount + 1
    if bufferCount < MAX_BUFFER_SIZE then
        bufferCount = bufferCount + 1
        buffer[bufferCount] = entry
    else
        -- Buffer is full, overwrite oldest entry
        buffer[bufferHead] = entry
        bufferHead = bufferHead + 1
        if bufferHead > MAX_BUFFER_SIZE then
            bufferHead = 1
        end
    end

    return entry
end

function M.getMessages()
    local result = {}
    if bufferCount == 0 then
        return result
    end

    if bufferCount < MAX_BUFFER_SIZE then
        -- Buffer not yet full, return in order
        for i = 1, bufferCount do
            result[#result + 1] = buffer[i]
        end
    else
        -- Buffer is full, read from head to end, then wrap
        local idx = bufferHead
        for i = 1, MAX_BUFFER_SIZE do
            result[#result + 1] = buffer[idx]
            idx = idx + 1
            if idx > MAX_BUFFER_SIZE then
                idx = 1
            end
        end
    end

    return result
end

function M.getFilteredMessages(category)
    if category == nil or category == '' or category == 'All' then
        return M.getMessages()
    end

    local all = M.getMessages()
    local result = {}

    for i = 1, #all do
        if all[i].category == category then
            result[#result + 1] = all[i]
        end
    end

    return result
end

function M.clearMessages()
    buffer = {}
    bufferHead = 1
    bufferCount = 0
    -- Note: insertionCount is NOT reset here; it is monotonically increasing
end

function M.getBufferSize()
    return bufferCount
end

function M.getInsertionCount()
    return insertionCount
end

return M
