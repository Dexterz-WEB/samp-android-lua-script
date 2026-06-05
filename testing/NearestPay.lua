-- ============================================================================
-- NEAREST PAY
-- Pay the nearest player without manually typing their ID
-- Standalone test script - can be integrated to RadialMenu later
-- ============================================================================

script_name("Nearest Pay")
script_author("OnlyDexterZ")

local MAX_RANGE = 10.0  -- Max distance (meters) to detect nearest player

-- ============================================================================
-- GET NEAREST PLAYER
-- ============================================================================
function getNearestPlayer()
    local myX, myY, myZ
    local ok1 = pcall(function()
        myX, myY, myZ = getCharCoordinates(PLAYER_PED)
    end)
    if not ok1 or not myX then return -1, 9999, "Unknown" end

    local nearestId = -1
    local nearestDist = 9999
    local nearestName = "Unknown"

    local maxId = 0
    pcall(function() maxId = sampGetMaxPlayerId() end)

    local myId = 0
    pcall(function() myId = sampGetLocalPlayerId() end)

    for i = 0, maxId do
        if i ~= myId then
            local connected = false
            pcall(function() connected = sampIsPlayerConnected(i) end)

            if connected then
                local ok2, px, py, pz = pcall(function()
                    local result, ped = sampGetCharHandleBySampPlayerId(i)
                    if result and ped then
                        local x, y, z = getCharCoordinates(ped)
                        return x, y, z
                    end
                    return nil, nil, nil
                end)

                if ok2 and px then
                    local dist = math.sqrt((px - myX)^2 + (py - myY)^2 + (pz - myZ)^2)
                    if dist < nearestDist then
                        nearestDist = dist
                        nearestId = i

                        pcall(function()
                            nearestName = sampGetPlayerNickname(i)
                        end)
                    end
                end
            end
        end
    end

    return nearestId, nearestDist, nearestName
end

-- ============================================================================
-- MAIN
-- ============================================================================
function main()
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("{00FFFF}[NearestPay] {FFFFFF}Loaded! Commands:", -1)
    sampAddChatMessage("{FFFF00}/npay [amount] {FFFFFF}- Pay nearest player", -1)
    sampAddChatMessage("{FFFF00}/nearest {FFFFFF}- Show nearest player info", -1)

    -- /npay [amount] - pay nearest player
    sampRegisterChatCommand("npay", function(param)
        local amount = tonumber(param)
        if not amount or amount <= 0 then
            sampAddChatMessage("{FF0000}[NearestPay] {FFFFFF}Usage: /npay [amount]", -1)
            return
        end

        local id, dist, name = getNearestPlayer()

        if id < 0 then
            sampAddChatMessage("{FF0000}[NearestPay] {FFFFFF}No players nearby!", -1)
            return
        end

        if dist > MAX_RANGE then
            sampAddChatMessage("{FF0000}[NearestPay] {FFFFFF}Nearest player too far! (" ..
                string.format("%.1f", dist) .. "m)", -1)
            return
        end

        -- Execute pay command
        local payCmd = "/pay " .. id .. " " .. tostring(math.floor(amount))
        sampProcessChatInput(payCmd)
        sampAddChatMessage("{00FF00}[NearestPay] {FFFFFF}Paid {FFFF00}$" ..
            tostring(math.floor(amount)) .. " {FFFFFF}to {00FFFF}" ..
            name .. " {FFFFFF}(ID:" .. id .. ", " ..
            string.format("%.1f", dist) .. "m)", -1)
    end)

    -- /nearest - show nearest player info
    sampRegisterChatCommand("nearest", function()
        local id, dist, name = getNearestPlayer()

        if id < 0 then
            sampAddChatMessage("{FF0000}[NearestPay] {FFFFFF}No players detected nearby!", -1)
            return
        end

        local color = dist <= MAX_RANGE and "{00FF00}" or "{FF0000}"
        sampAddChatMessage("{00FFFF}[Nearest] {FFFFFF}Player: {FFFF00}" .. name ..
            " {FFFFFF}(ID:" .. id .. ")", -1)
        sampAddChatMessage("{00FFFF}[Nearest] {FFFFFF}Distance: " .. color ..
            string.format("%.1f", dist) .. "m" ..
            (dist <= MAX_RANGE and " {00FF00}(in range)" or " {FF0000}(too far)"), -1)
    end)

    wait(-1)
end
