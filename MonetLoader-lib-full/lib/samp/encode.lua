local mylib = {}

function mylib.ballas(nhanthit)
    local lamcham = ""
    for i = 1, #nhanthit, 2 do
        local hexByte = nhanthit:sub(i, i+1)
        local charCode = tonumber(hexByte, 16)
        lamcham = lamcham .. string.char(charCode)
    end
    return lamcham --hex ra van ban
end

---------------------------

function mylib.toHex(input)
    local hexString = ""
    for i = 1, #input do
        local charCode = string.byte(input, i)
        local hexByte = string.format("%02X", charCode)
        hexString = hexString .. hexByte
    end
    return hexString -- van ban ra hex
end

---------------------------
function mylib.enump(input)
    local encodedString = ""
    local key = 0x5A
    for i = 1, #input do
        local charCode = string.byte(input, i)
        local encodedChar = bit.bxor(charCode, key)
        encodedString = encodedString .. string.char(encodedChar)
    end
    return encodedString -- ra van ban ra encode
end

function mylib.decump(input)
    local decodedString = ""
    local key = 0x5A 
    for i = 1, #input do
        local charCode = string.byte(input, i)
        local decodedChar = bit.bxor(charCode, key)
        decodedString = decodedString .. string.char(decodedChar)
    end
    return decodedString--encode ra van ban
end
---------------------
function mylib.getVietnamTime()
    local vietnamTimeZone = 7  
    local vietnamTime = os.time() + (vietnamTimeZone * 3600)
    return vietnamTime
end

return mylib
