package = 
{
    FULL_NAME = 'LUA-FUNCS GAME',
    VERSION = '0.1',
    DESC = 'Package wtih some functions to mode \'GAME\'',
    PEDSELF = {},
    CARSELF = {},
    WORLD = {}
}

-- LIBRARYS
local ffi = require ('ffi')
getBonePosition = ffi.cast("int (__thiscall*)(void*, float*, int, bool)", 0x5E4280)
-- don't touch, bitch

-- ************************** GLOBAL FUNCTIONS **************************

-- PEDSELF

function package.PEDSELF.GetLocalPlayerId()
    local result, id = sampGetPlayerIdByCharHandle(playerPed)
    if result then
        return id
    end
end

function package.PEDSELF.Teleport(x, y, z) -- aka PEDSELF->Teleport();
    setCharCoordinates(playerPed, x, y, z) 
end

function package.PEDSELF.SetCharMoneyFixed(iMoney, bAddToCurrentMoney)
    if bAddToCurrentMoney then 
        writeMemory(0xB7CE50, 4, readMemory(0xB7CE50, 4, true) + iMoney, true)
    else
        writeMemory(0xB7CE50, 4, iMoney, true)
    end
end

function package.PEDSELF.GetBonePosition(iBone) -- return vector x2
    if iBone:len() > 0 then 
        return GetBodyPartCoordinates(iBone, playerPed)
    else return nil, nil, nil
    end
end

-- CARSELF
function package.CARSELF.Teleport(x, y, z) -- aka something
    if isCharInAnyCar(playerPed) then setCarCoordinates(storeCarCharIsInNoSave(playerPed), x, y, z) end
end

-- WORLD
function package.WORLD.GetCharBonePosition(ped, iBone) -- return vector
    if doesCharExist(ped) and iBone:len() > 0 then
        return GetBodyPartCoordinates(iBone, ped)
    else return nil, nil, nil
    end
end


function GetBodyPartCoordinates(id, handle)
    local pedptr = getCharPointer(handle)
    local vec = ffi.new("float[3]")
    getBonePosition(ffi.cast("void*", pedptr), vec, id, true)
    return vec[0], vec[1], vec[2]
end

-- ************************** LOCAL FUNCTIONS **************************

return package

