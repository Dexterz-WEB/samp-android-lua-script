local package = 
{
    FULL_NAME = 'LUA-FUNCS SAMP',
    VERSION = '0.1',
    DESC = 'Package wtih some functions to mode \'SAMP\''
}



function package.sampGetPlayerNicknameFixed(iplayerId)
    if sampIsPlayerConnected(iplayerId) then 
        return sampGetPlayerNickname(iplayerId) 
    end
end

return package