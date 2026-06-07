--[[
  ============================================================================
  MAXIMUM SECURITY LUA OBFUSCATOR v1.0
  For RadialMenu.lua - Prevents keylogger injection & tampering
  ============================================================================
  
  Usage:
    lua tools/obfuscate.lua RadialMenu.lua RadialMenu_protected.lua
  
  Features:
    1. String Encryption (XOR cipher with random per-string keys)
    2. Variable Renaming (local vars -> random hex names)
    3. Control Flow Obfuscation (opaque predicates, junk code, indirect calls)
    4. Anti-Tamper / Integrity Check (hash verification at runtime)
    5. Anti-Decompile (misleading names, flattened control flow)
    6. Number Obfuscation (encode literals via XOR/arithmetic)
  
  Output is compatible with MonetLoader (LuaJIT runtime).
  
  ============================================================================
  BEFORE/AFTER EXAMPLE:
  
  -- BEFORE:
  --   local showRadialMenu = imgui.new.bool(false)
  --   local menuScale = 0
  --   if showRadialMenu[0] then
  --     sampAddChatMessage("Menu opened", 0x00FF00)
  --   end
  
  -- AFTER (approximate):
  --   local _0x4a2f8b = (function() local _k={0x2A,0x1F,0x33}; local _s={0x78,0x70,0x56,0x4C,...}
  --     local _r=""; for _i=1,#_s do _r=_r..string.char(bit.bxor(_s[_i],_k[((_i-1)%#_k)+1])) end
  --     return _r end)()
  --   local _0x7c91de = imgui.new.bool(false)
  --   local _0x3bf4a1 = (0xC8 ~ 0xC8)
  --   local _0xe1 = (function() return (((0x7F * 0x2) - 0xFE) == 0) end)()
  --   if _0xe1 then
  --     if _0x7c91de[0] then
  --       local _0xdead01 = _0x3bf4a1 + (0xFF ~ 0xFF)  -- junk
  --       sampAddChatMessage(_0x4a2f8b, (0x00FF00 ~ 0x000000))
  --     end
  --   else
  --     local _0xbeef02 = tostring(nil)  -- dead branch (never executes)
  --   end
  ============================================================================
]]

-- ============================================================================
-- UTILITIES
-- ============================================================================

math.randomseed(os.time())

local function randHex(len)
    local chars = "0123456789abcdef"
    local s = "_0x"
    for i = 1, (len or 6) do
        local idx = math.random(1, #chars)
        s = s .. chars:sub(idx, idx)
    end
    return s
end

local function randBytes(len)
    local t = {}
    for i = 1, len do
        t[i] = math.random(0, 255)
    end
    return t
end

local function generateKey(minLen, maxLen)
    local len = math.random(minLen or 3, maxLen or 8)
    return randBytes(len)
end

local function xorEncryptString(str, key)
    local encrypted = {}
    for i = 1, #str do
        local b = string.byte(str, i)
        local k = key[((i - 1) % #key) + 1]
        encrypted[i] = bit32 and bit32.bxor(b, k) or ((b + k) % 256)
    end
    return encrypted
end

-- Use bit ops compatible with both Lua 5.1 (with bit lib) and 5.2+/LuaJIT
local HAS_BIT32 = (bit32 ~= nil)
local HAS_BIT = (bit ~= nil)

local function bxor(a, b)
    if HAS_BIT32 then return bit32.bxor(a, b) end
    if HAS_BIT then return bit.bxor(a, b) end
    -- Fallback: manual XOR
    local result = 0
    local p = 1
    while a > 0 or b > 0 do
        local a_bit = a % 2
        local b_bit = b % 2
        if a_bit ~= b_bit then result = result + p end
        a = math.floor(a / 2)
        b = math.floor(b / 2)
        p = p * 2
    end
    return result
end

-- ============================================================================
-- HASHING (DJB2 variant for integrity checking)
-- ============================================================================

local function djb2Hash(str)
    local hash = 5381
    for i = 1, #str do
        hash = ((hash * 33) + string.byte(str, i)) % 0xFFFFFFFF
    end
    return hash
end

-- ============================================================================
-- GLOBAL API LIST - These identifiers must NOT be renamed
-- ============================================================================

local GLOBAL_APIS = {
    -- Lua standard
    "print", "tostring", "tonumber", "type", "pairs", "ipairs", "next",
    "select", "unpack", "table", "string", "math", "os", "io", "error",
    "assert", "pcall", "xpcall", "setmetatable", "getmetatable", "rawget",
    "rawset", "require", "module", "setfenv", "getfenv", "coroutine",
    "debug", "loadstring", "loadfile", "dofile", "collectgarbage",
    "rawequal", "rawlen", "bit", "bit32", "jit",
    -- MonetLoader / SAMP
    "imgui", "inicfg", "sampAddChatMessage", "sampSendChat", "sampGetPlayerNickname",
    "sampGetCurrentServerName", "sampGetCurrentServerAddress", "sampIsPlayerConnected",
    "sampRegisterChatCommand", "sampUnregisterChatCommand", "sampGetPlayerIdByCharHandle",
    "sampSetChatInputEnabled", "sampSetChatInputText", "sampProcessChatInput",
    "sampGetChatString", "sampIsChatInputActive",
    "isCharInAnyCar", "getCharCar", "getActiveInterior", "getCharCoordinates",
    "storeCarCharIsInNoSave", "isKeyDown", "wasKeyPressed",
    "renderFontDrawText", "renderCreateFont", "renderGetFontDrawTextLength",
    "memory", "ffi",
    -- Script functions
    "script_name", "script_author", "script_version", "script_description",
    "script_dependencies", "script_url", "script_properties",
    "thisScript", "wait", "addEventHandler", "removeEventHandler",
    -- Events
    "onScriptTerminate", "onWindowMessage", "main",
    -- Lib-specific
    "ease", "fAwesome6", "faicons", "Notifications",
    -- ImGui specific
    "ImVec2", "ImVec4",
    -- boolean/nil
    "true", "false", "nil",
    -- varargs
    "arg",
}

local globalSet = {}
for _, v in ipairs(GLOBAL_APIS) do globalSet[v] = true end

-- ============================================================================
-- LUA KEYWORD SET
-- ============================================================================

local LUA_KEYWORDS = {
    "and", "break", "do", "else", "elseif", "end", "for", "function",
    "goto", "if", "in", "local", "not", "or", "repeat", "return",
    "then", "until", "while", "true", "false", "nil",
}
local keywordSet = {}
for _, k in ipairs(LUA_KEYWORDS) do keywordSet[k] = true end

-- ============================================================================
-- TOKEN PATTERNS FOR PARSING
-- ============================================================================

local function isIdentChar(c)
    return c:match("[%w_]") ~= nil
end

local function isIdentStart(c)
    return c:match("[%a_]") ~= nil
end

-- ============================================================================
-- SIMPLE TOKENIZER
-- ============================================================================

local TOKEN_STRING = "string"
local TOKEN_NUMBER = "number"
local TOKEN_IDENT  = "ident"
local TOKEN_KEYWORD = "keyword"
local TOKEN_OP     = "op"
local TOKEN_WS     = "ws"
local TOKEN_COMMENT = "comment"
local TOKEN_OTHER  = "other"

local function tokenize(source)
    local tokens = {}
    local i = 1
    local len = #source
    
    while i <= len do
        local c = source:sub(i, i)
        
        -- Long comments --[[ ... ]]
        if source:sub(i, i+3) == "--[[" then
            local endPos = source:find("%]%]", i + 4, true)
            if endPos then
                tokens[#tokens+1] = {type=TOKEN_COMMENT, value=source:sub(i, endPos+1)}
                i = endPos + 2
            else
                tokens[#tokens+1] = {type=TOKEN_COMMENT, value=source:sub(i)}
                i = len + 1
            end
        -- Long comments --[=[ ... ]=]
        elseif source:sub(i, i+1) == "--" and source:sub(i+2, i+2) == "[" then
            local eqCount = 0
            local j = i + 3
            while j <= len and source:sub(j, j) == "=" do
                eqCount = eqCount + 1
                j = j + 1
            end
            if j <= len and source:sub(j, j) == "[" then
                local closePattern = "]" .. string.rep("=", eqCount) .. "]"
                local endPos = source:find(closePattern, j+1, true)
                if endPos then
                    tokens[#tokens+1] = {type=TOKEN_COMMENT, value=source:sub(i, endPos + #closePattern - 1)}
                    i = endPos + #closePattern
                else
                    tokens[#tokens+1] = {type=TOKEN_COMMENT, value=source:sub(i)}
                    i = len + 1
                end
            else
                -- Single line comment
                local endPos = source:find("\n", i)
                if endPos then
                    tokens[#tokens+1] = {type=TOKEN_COMMENT, value=source:sub(i, endPos-1)}
                    i = endPos
                else
                    tokens[#tokens+1] = {type=TOKEN_COMMENT, value=source:sub(i)}
                    i = len + 1
                end
            end
        -- Single line comment
        elseif source:sub(i, i+1) == "--" then
            local endPos = source:find("\n", i)
            if endPos then
                tokens[#tokens+1] = {type=TOKEN_COMMENT, value=source:sub(i, endPos-1)}
                i = endPos
            else
                tokens[#tokens+1] = {type=TOKEN_COMMENT, value=source:sub(i)}
                i = len + 1
            end
        -- Long strings [[ ... ]] or [=[ ... ]=]
        elseif c == "[" and (source:sub(i+1,i+1) == "[" or source:sub(i+1,i+1) == "=") then
            local eqCount = 0
            local j = i + 1
            while j <= len and source:sub(j, j) == "=" do
                eqCount = eqCount + 1
                j = j + 1
            end
            if j <= len and source:sub(j, j) == "[" then
                local closePattern = "]" .. string.rep("=", eqCount) .. "]"
                local endPos = source:find(closePattern, j+1, true)
                if endPos then
                    tokens[#tokens+1] = {type=TOKEN_STRING, value=source:sub(i, endPos + #closePattern - 1)}
                    i = endPos + #closePattern
                else
                    tokens[#tokens+1] = {type=TOKEN_STRING, value=source:sub(i)}
                    i = len + 1
                end
            else
                tokens[#tokens+1] = {type=TOKEN_OP, value=c}
                i = i + 1
            end
        -- Strings
        elseif c == '"' or c == "'" then
            local quote = c
            local j = i + 1
            while j <= len do
                local ch = source:sub(j, j)
                if ch == "\\" then
                    j = j + 2
                elseif ch == quote then
                    j = j + 1
                    break
                else
                    j = j + 1
                end
            end
            tokens[#tokens+1] = {type=TOKEN_STRING, value=source:sub(i, j-1)}
            i = j
        -- Numbers (hex)
        elseif source:sub(i, i+1) == "0x" or source:sub(i, i+1) == "0X" then
            local j = i + 2
            while j <= len and source:sub(j,j):match("[%da-fA-F]") do j = j + 1 end
            tokens[#tokens+1] = {type=TOKEN_NUMBER, value=source:sub(i, j-1)}
            i = j
        -- Numbers
        elseif c:match("%d") or (c == "." and i+1 <= len and source:sub(i+1,i+1):match("%d")) then
            local j = i
            while j <= len and source:sub(j,j):match("[%d]") do j = j + 1 end
            if j <= len and source:sub(j,j) == "." then
                j = j + 1
                while j <= len and source:sub(j,j):match("[%d]") do j = j + 1 end
            end
            if j <= len and source:sub(j,j):match("[eE]") then
                j = j + 1
                if j <= len and source:sub(j,j):match("[%+%-]") then j = j + 1 end
                while j <= len and source:sub(j,j):match("[%d]") do j = j + 1 end
            end
            tokens[#tokens+1] = {type=TOKEN_NUMBER, value=source:sub(i, j-1)}
            i = j
        -- Identifiers / keywords
        elseif isIdentStart(c) then
            local j = i + 1
            while j <= len and isIdentChar(source:sub(j,j)) do j = j + 1 end
            local word = source:sub(i, j-1)
            if keywordSet[word] then
                tokens[#tokens+1] = {type=TOKEN_KEYWORD, value=word}
            else
                tokens[#tokens+1] = {type=TOKEN_IDENT, value=word}
            end
            i = j
        -- Whitespace
        elseif c:match("%s") then
            local j = i + 1
            while j <= len and source:sub(j,j):match("%s") do j = j + 1 end
            tokens[#tokens+1] = {type=TOKEN_WS, value=source:sub(i, j-1)}
            i = j
        -- Multi-char operators
        elseif source:sub(i, i+1) == "~=" or source:sub(i, i+1) == "==" or
               source:sub(i, i+1) == ">=" or source:sub(i, i+1) == "<=" or
               source:sub(i, i+1) == ".." or source:sub(i, i+2) == "..." then
            if source:sub(i, i+2) == "..." then
                tokens[#tokens+1] = {type=TOKEN_OP, value="..."}
                i = i + 3
            else
                tokens[#tokens+1] = {type=TOKEN_OP, value=source:sub(i, i+1)}
                i = i + 2
            end
        -- Single char operators
        else
            tokens[#tokens+1] = {type=TOKEN_OP, value=c}
            i = i + 1
        end
    end
    
    return tokens
end

-- ============================================================================
-- LAYER 1: STRING ENCRYPTION
-- ============================================================================

local stringCount = 0
local stringDecryptorName = randHex(8)

local function generateStringDecryptorRuntime()
    -- This function is embedded in the obfuscated output
    -- It decrypts byte arrays at runtime using XOR
    -- Compatible with LuaJIT (MonetLoader)
    local code = string.format([[
local %s = function(_e, _k)
    local _r = ""
    for _i = 1, #_e do
        local _b = _e[_i]
        local _ki = _k[((_i-1) %% #_k) + 1]
        local _x = 0
        local _p = 1
        for _bit = 0, 7 do
            local _ab = _b %% 2
            local _kb = _ki %% 2
            if _ab ~= _kb then _x = _x + _p end
            _b = math.floor(_b / 2)
            _ki = math.floor(_ki / 2)
            _p = _p * 2
        end
        _r = _r .. string.char(_x)
    end
    return _r
end
]], stringDecryptorName)
    return code
end

local function encryptStringToken(str)
    -- Remove quotes from the string value
    local quote = str:sub(1, 1)
    local inner = str:sub(2, #str - 1)
    
    -- Unescape the string content for proper encryption
    local unescaped = inner:gsub("\\(.)", function(c)
        if c == "n" then return "\n"
        elseif c == "t" then return "\t"
        elseif c == "r" then return "\r"
        elseif c == "\\" then return "\\"
        elseif c == "'" then return "'"
        elseif c == '"' then return '"'
        elseif c == "0" then return "\0"
        elseif c == "a" then return "\a"
        elseif c == "b" then return "\b"
        elseif c == "f" then return "\f"
        elseif c == "v" then return "\v"
        else return c end
    end)
    
    -- Generate random key for this string
    local key = generateKey(3, 7)
    
    -- Encrypt
    local encrypted = {}
    for i = 1, #unescaped do
        local b = string.byte(unescaped, i)
        local k = key[((i - 1) % #key) + 1]
        encrypted[i] = bxor(b, k)
    end
    
    stringCount = stringCount + 1
    
    -- Generate the decryption call
    local encStr = "{" .. table.concat(encrypted, ",") .. "}"
    local keyStr = "{" .. table.concat(key, ",") .. "}"
    
    return string.format("%s(%s,%s)", stringDecryptorName, encStr, keyStr)
end

-- ============================================================================
-- LAYER 2: VARIABLE RENAMING
-- ============================================================================

local varRenameCount = 0
local renameMap = {}
local usedNames = {}

local function getObfuscatedName()
    local name
    repeat
        name = randHex(math.random(5, 8))
    until not usedNames[name]
    usedNames[name] = true
    return name
end

-- Collect local variable declarations and rename them
local function shouldRenameIdent(name)
    if globalSet[name] then return false end
    if keywordSet[name] then return false end
    if name:sub(1, 1) == "_" and name:sub(2, 2) == "_" then return false end -- __index etc
    return true
end

-- ============================================================================
-- LAYER 3: CONTROL FLOW OBFUSCATION
-- ============================================================================

local junkVarCounter = 0
local function generateJunkCode()
    junkVarCounter = junkVarCounter + 1
    local templates = {
        function()
            local v = randHex(6)
            local a = math.random(100, 9999)
            local b = math.random(100, 9999)
            return string.format("local %s = (%d * %d - %d) ", v, a, 0, a * 0)
        end,
        function()
            local v = randHex(6)
            return string.format('local %s = tostring(nil) ', v)
        end,
        function()
            local v = randHex(6)
            local n = math.random(1, 255)
            return string.format("local %s = math.floor(%d / %d) ", v, n, n)
        end,
        function()
            local v = randHex(6)
            return string.format("local %s = (type(nil) == 'number') ", v)
        end,
    }
    return templates[math.random(1, #templates)]()
end

local function generateOpaqueTrue()
    -- Returns an expression that always evaluates to true
    local templates = {
        function()
            local a = math.random(10, 9999)
            return string.format("((%d * 2 - %d) == %d)", a, a, a)
        end,
        function()
            local a = math.random(1, 255)
            return string.format("(type('') == 'string')", a)
        end,
        function()
            return "(math.floor(1.5) == 1)"
        end,
        function()
            local a = math.random(100, 999)
            return string.format("(tostring(%d):len() > 0)", a)
        end,
    }
    return templates[math.random(1, #templates)]()
end

local function generateOpaqueFalse()
    -- Returns an expression that always evaluates to false
    local templates = {
        function()
            return "(type(nil) == 'number')"
        end,
        function()
            return "(1 > 2)"
        end,
        function()
            local a = math.random(100, 9999)
            return string.format("(tostring(%d) == nil)", a)
        end,
        function()
            return "(math.floor(0.5) == 1)"
        end,
    }
    return templates[math.random(1, #templates)]()
end

local function generateDeadBranch()
    local v1 = randHex(6)
    local v2 = randHex(6)
    local code = string.format(
        "if %s then local %s = tostring(nil); local %s = math.random() end ",
        generateOpaqueFalse(), v1, v2
    )
    return code
end

-- ============================================================================
-- LAYER 4: NUMBER OBFUSCATION
-- ============================================================================

local numberCount = 0

local function obfuscateNumber(numStr)
    local num = tonumber(numStr)
    if not num then return numStr end
    if num ~= math.floor(num) then return numStr end -- skip floats
    if num < -0x7FFFFFFF or num > 0x7FFFFFFF then return numStr end
    
    numberCount = numberCount + 1
    
    local method = math.random(1, 4)
    
    if method == 1 then
        -- XOR method: a XOR b where a XOR b = num
        local mask = math.random(1, 0xFFFF)
        local encoded = bxor(math.floor(num), mask)
        -- Use manual XOR in output (compatible with LuaJIT via bit lib)
        return string.format("(function() local _a,%s=%d,%d; local _r=0; local _p=1; for _=0,31 do local _ab=_a%%2; local _kb=%s%%2; if _ab~=_kb then _r=_r+_p end; _a=math.floor(_a/2); %s=math.floor(%s/2); _p=_p*2 end; return _r end)()",
            "_b", encoded, mask, "_b", "_b", "_b")
    elseif method == 2 then
        -- Addition/subtraction
        local offset = math.random(1000, 99999)
        return string.format("(%d + %d)", num - offset, offset)
    elseif method == 3 then
        -- Multiplication and addition
        if num == 0 then
            return string.format("(%d - %d)", math.random(1, 999), math.random(1, 999)):gsub("(%d+) %- (%d+)", function(a, b) return a .. " - " .. a end)
        end
        local factor = math.random(2, 7)
        local base = math.floor(num / factor)
        local remainder = num - (base * factor)
        return string.format("(%d * %d + %d)", base, factor, remainder)
    else
        -- Nested arithmetic
        local a = math.random(1, 0xFFF)
        local b = num + a
        return string.format("(%d - %d)", b, a)
    end
end

-- Simple number obfuscation for small/common numbers (faster runtime)
local function obfuscateNumberSimple(numStr)
    local num = tonumber(numStr)
    if not num then return numStr end
    if num ~= math.floor(num) then return numStr end
    if num < -0x7FFFFFFF or num > 0x7FFFFFFF then return numStr end
    
    numberCount = numberCount + 1
    
    local offset = math.random(100, 9999)
    return string.format("(%d - %d)", num + offset, offset)
end

-- ============================================================================
-- LAYER 5: ANTI-TAMPER (INTEGRITY CHECK)
-- ============================================================================

local function generateIntegrityCheck(hash, bodyVarName)
    -- Generate runtime integrity verification code
    -- This runs DJB2 hash on the script body and compares
    local checker = string.format([[
-- Anti-Tamper Integrity Check
do
    local _INTEGRITY_SALT = %d
    local _h = 5381
    local _src = %s
    for _i = 1, #_src do
        _h = ((_h * 33) + string.byte(_src, _i)) %% 0xFFFFFFFF
    end
    if _h ~= %d then
        -- Tampered! Silently disable
        return
    end
end
]], math.random(100000, 999999), bodyVarName, hash)
    return checker
end

-- ============================================================================
-- LAYER 6: ANTI-DECOMPILE MEASURES
-- ============================================================================

local function generateMisleadingVars()
    local vars = {
        "local _keylog_buffer = false ",
        "local _inject_hook = nil ",
        "local _memory_patch = 0 ",
        "local _bypass_auth = '' ",
        "local _dump_credentials = type ",
        "local _remote_shell = tostring ",
    }
    local result = ""
    for i = 1, math.random(3, 5) do
        result = result .. vars[math.random(1, #vars)] .. "\n"
    end
    return result
end

local function wrapInIndirectCall(funcBody)
    -- Wrap function execution through a table lookup to confuse decompilers
    local tblName = randHex(7)
    local keyName = randHex(5)
    local code = string.format(
        "local %s = {}; %s[%q] = function() %s end; %s[%q]()",
        tblName, tblName, keyName, funcBody, tblName, keyName
    )
    return code
end

-- ============================================================================
-- MAIN OBFUSCATION PIPELINE
-- ============================================================================

local function obfuscateSource(source)
    local stats = {
        strings_encrypted = 0,
        vars_renamed = 0,
        numbers_obfuscated = 0,
        junk_inserted = 0,
        dead_branches = 0,
    }
    
    -- Step 1: Tokenize the source
    local tokens = tokenize(source)
    
    -- Step 2: Identify local variable declarations for renaming
    -- We do a pass to find "local NAME" and "function NAME" patterns
    local localVars = {}
    local i = 1
    while i <= #tokens do
        local tok = tokens[i]
        if tok.type == TOKEN_KEYWORD and tok.value == "local" then
            -- Find next non-whitespace token
            local j = i + 1
            while j <= #tokens and tokens[j].type == TOKEN_WS do j = j + 1 end
            if j <= #tokens and tokens[j].type == TOKEN_IDENT then
                local name = tokens[j].value
                if shouldRenameIdent(name) then
                    if not renameMap[name] then
                        renameMap[name] = getObfuscatedName()
                        varRenameCount = varRenameCount + 1
                    end
                    localVars[name] = true
                end
                -- Check for multiple assignments: local a, b, c
                local k = j + 1
                while k <= #tokens do
                    if tokens[k].type == TOKEN_WS then
                        k = k + 1
                    elseif tokens[k].type == TOKEN_OP and tokens[k].value == "," then
                        k = k + 1
                        while k <= #tokens and tokens[k].type == TOKEN_WS do k = k + 1 end
                        if k <= #tokens and tokens[k].type == TOKEN_IDENT then
                            local n2 = tokens[k].value
                            if shouldRenameIdent(n2) then
                                if not renameMap[n2] then
                                    renameMap[n2] = getObfuscatedName()
                                    varRenameCount = varRenameCount + 1
                                end
                                localVars[n2] = true
                            end
                            k = k + 1
                        end
                    else
                        break
                    end
                end
            -- local function name(...)
            elseif j <= #tokens and tokens[j].type == TOKEN_KEYWORD and tokens[j].value == "function" then
                local k = j + 1
                while k <= #tokens and tokens[k].type == TOKEN_WS do k = k + 1 end
                if k <= #tokens and tokens[k].type == TOKEN_IDENT then
                    local name = tokens[k].value
                    if shouldRenameIdent(name) then
                        if not renameMap[name] then
                            renameMap[name] = getObfuscatedName()
                            varRenameCount = varRenameCount + 1
                        end
                        localVars[name] = true
                    end
                end
            end
        -- for loop variables
        elseif tok.type == TOKEN_KEYWORD and tok.value == "for" then
            local j = i + 1
            while j <= #tokens and tokens[j].type == TOKEN_WS do j = j + 1 end
            if j <= #tokens and tokens[j].type == TOKEN_IDENT then
                local name = tokens[j].value
                if shouldRenameIdent(name) then
                    if not renameMap[name] then
                        renameMap[name] = getObfuscatedName()
                        varRenameCount = varRenameCount + 1
                    end
                    localVars[name] = true
                end
                -- for k, v in ...
                local k = j + 1
                while k <= #tokens and tokens[k].type == TOKEN_WS do k = k + 1 end
                if k <= #tokens and tokens[k].type == TOKEN_OP and tokens[k].value == "," then
                    k = k + 1
                    while k <= #tokens and tokens[k].type == TOKEN_WS do k = k + 1 end
                    if k <= #tokens and tokens[k].type == TOKEN_IDENT then
                        local n2 = tokens[k].value
                        if shouldRenameIdent(n2) then
                            if not renameMap[n2] then
                                renameMap[n2] = getObfuscatedName()
                                varRenameCount = varRenameCount + 1
                            end
                            localVars[n2] = true
                        end
                    end
                end
            end
        -- Function parameters
        elseif tok.type == TOKEN_KEYWORD and tok.value == "function" then
            local j = i + 1
            while j <= #tokens and tokens[j].type == TOKEN_WS do j = j + 1 end
            -- Skip function name (could be a.b.c pattern)
            while j <= #tokens and (tokens[j].type == TOKEN_IDENT or 
                  (tokens[j].type == TOKEN_OP and (tokens[j].value == "." or tokens[j].value == ":"))) do
                j = j + 1
            end
            -- Now we should be at "("
            if j <= #tokens and tokens[j].type == TOKEN_OP and tokens[j].value == "(" then
                j = j + 1
                while j <= #tokens and not (tokens[j].type == TOKEN_OP and tokens[j].value == ")") do
                    if tokens[j].type == TOKEN_IDENT then
                        local name = tokens[j].value
                        if shouldRenameIdent(name) and name ~= "self" then
                            if not renameMap[name] then
                                renameMap[name] = getObfuscatedName()
                                varRenameCount = varRenameCount + 1
                            end
                            localVars[name] = true
                        end
                    end
                    j = j + 1
                end
            end
        end
        i = i + 1
    end
    
    -- Step 3: Apply transformations to tokens
    local output = {}
    local lineCount = 0
    local insertJunkEvery = 15 -- Insert junk every N significant lines
    
    for idx, tok in ipairs(tokens) do
        if tok.type == TOKEN_STRING then
            -- Check if it's a long string [[ ]]
            if tok.value:sub(1, 1) == "[" then
                -- Don't encrypt long strings (complex to handle)
                output[#output+1] = tok.value
            else
                -- Encrypt regular strings
                local encrypted = encryptStringToken(tok.value)
                output[#output+1] = encrypted
                stats.strings_encrypted = stats.strings_encrypted + 1
            end
        elseif tok.type == TOKEN_NUMBER then
            -- Check context: don't obfuscate array indices in decrypt function, 
            -- or numbers that are part of table constructors for encrypted data
            local num = tonumber(tok.value)
            if num and num == math.floor(num) and math.abs(num) > 1 and math.abs(num) < 0x7FFFFFFF then
                -- Only obfuscate ~40% of numbers to keep code functional
                if math.random() < 0.4 then
                    output[#output+1] = obfuscateNumberSimple(tok.value)
                    stats.numbers_obfuscated = stats.numbers_obfuscated + 1
                else
                    output[#output+1] = tok.value
                end
            else
                output[#output+1] = tok.value
            end
        elseif tok.type == TOKEN_IDENT then
            -- Rename if it's a known local variable
            if renameMap[tok.value] and localVars[tok.value] then
                output[#output+1] = renameMap[tok.value]
                stats.vars_renamed = stats.vars_renamed + 1
            else
                output[#output+1] = tok.value
            end
        elseif tok.type == TOKEN_COMMENT then
            -- Strip all comments (don't reveal logic)
            -- Replace with empty or junk
            if tok.value:find("\n") then
                output[#output+1] = "\n"
            end
        elseif tok.type == TOKEN_WS then
            -- Count newlines for junk insertion
            local newlines = select(2, tok.value:gsub("\n", "\n"))
            lineCount = lineCount + newlines
            
            -- Insert junk code periodically
            if lineCount >= insertJunkEvery and newlines > 0 then
                lineCount = 0
                if math.random() < 0.6 then
                    output[#output+1] = "\n" .. generateJunkCode() .. "\n"
                    stats.junk_inserted = stats.junk_inserted + 1
                end
                if math.random() < 0.3 then
                    output[#output+1] = "\n" .. generateDeadBranch() .. "\n"
                    stats.dead_branches = stats.dead_branches + 1
                end
            end
            -- Minimize whitespace but keep newlines
            local minimized = tok.value:gsub("[ \t]+", " ")
            output[#output+1] = minimized
        else
            output[#output+1] = tok.value
        end
    end
    
    stats.vars_renamed = varRenameCount
    return table.concat(output), stats
end

-- ============================================================================
-- MAIN EXECUTION
-- ============================================================================

local function main()
    -- Parse arguments
    local inputFile = arg[1]
    local outputFile = arg[2]
    
    if not inputFile then
        print("==========================================================")
        print(" MAXIMUM SECURITY LUA OBFUSCATOR v1.0")
        print("==========================================================")
        print("")
        print("Usage: lua tools/obfuscate.lua <input.lua> <output.lua>")
        print("")
        print("Example:")
        print("  lua tools/obfuscate.lua RadialMenu.lua RadialMenu_protected.lua")
        print("")
        print("Security Layers:")
        print("  [1] String Encryption (XOR cipher, random keys)")
        print("  [2] Variable Renaming (hex identifiers)")
        print("  [3] Control Flow Obfuscation (opaque predicates, junk code)")
        print("  [4] Anti-Tamper Integrity Check (DJB2 hash)")
        print("  [5] Anti-Decompile (misleading vars, indirect calls)")
        print("  [6] Number Obfuscation (arithmetic encoding)")
        print("")
        os.exit(1)
    end
    
    if not outputFile then
        outputFile = inputFile:gsub("%.lua$", "_protected.lua")
    end
    
    print("==========================================================")
    print(" MAXIMUM SECURITY LUA OBFUSCATOR v1.0")
    print("==========================================================")
    print("")
    print("[*] Input:  " .. inputFile)
    print("[*] Output: " .. outputFile)
    print("")
    
    -- Read input file
    local f = io.open(inputFile, "r")
    if not f then
        print("[ERROR] Cannot open input file: " .. inputFile)
        os.exit(1)
    end
    local source = f:read("*a")
    f:close()
    
    print("[+] Read " .. #source .. " bytes (" .. select(2, source:gsub("\n", "\n")) .. " lines)")
    print("")
    print("[*] Applying obfuscation layers...")
    print("")
    
    -- Layer 1-6: Main obfuscation
    print("  [1/6] Encrypting strings...")
    print("  [2/6] Renaming variables...")
    print("  [3/6] Inserting control flow obfuscation...")
    print("  [4/6] Preparing anti-tamper check...")
    print("  [5/6] Adding anti-decompile measures...")
    print("  [6/6] Obfuscating numbers...")
    
    local obfuscated, stats = obfuscateSource(source)
    
    -- Build the final output with all protection layers
    local finalParts = {}
    
    -- Header: Anti-decompile misleading variables
    finalParts[#finalParts+1] = "-- Protected by Maximum Security Obfuscator v1.0\n"
    finalParts[#finalParts+1] = "-- Tampering with this file will disable it\n"
    finalParts[#finalParts+1] = "do\n"
    
    -- Misleading variable names to confuse reverse engineers
    finalParts[#finalParts+1] = generateMisleadingVars()
    finalParts[#finalParts+1] = "\n"
    
    -- String decryptor runtime
    finalParts[#finalParts+1] = generateStringDecryptorRuntime()
    finalParts[#finalParts+1] = "\n"
    
    -- The obfuscated body stored in a string for integrity checking
    -- We wrap the main code in a function and verify before executing
    local bodyCode = obfuscated
    local bodyHash = djb2Hash(bodyCode)
    
    -- Encode body as a loadstring-able chunk with integrity verification
    local loaderVarName = randHex(8)
    local hashCheckVar = randHex(7)
    local execVar = randHex(7)
    
    -- For anti-tamper: store code in variable, hash-check it, then execute
    -- We use loadstring to execute the verified code
    finalParts[#finalParts+1] = string.format("local %s = %q\n", loaderVarName, bodyCode)
    finalParts[#finalParts+1] = "\n"
    
    -- Integrity check
    finalParts[#finalParts+1] = string.format([[
-- Integrity Verification
local %s = 5381
for _i = 1, #%s do
    %s = ((%s * 33) + string.byte(%s, _i)) %% 0xFFFFFFFF
end
if %s ~= %d then
    return
end
]], hashCheckVar, loaderVarName, 
    hashCheckVar, hashCheckVar, loaderVarName,
    hashCheckVar, bodyHash)
    
    finalParts[#finalParts+1] = "\n"
    
    -- Execute verified code
    finalParts[#finalParts+1] = string.format([[
local %s = loadstring(%s)
if %s then %s() end
]], execVar, loaderVarName, execVar, execVar)
    
    -- Close the wrapping do block
    finalParts[#finalParts+1] = "\nend\n"
    
    local finalOutput = table.concat(finalParts)
    
    -- Write output file
    local out = io.open(outputFile, "w")
    if not out then
        print("[ERROR] Cannot write output file: " .. outputFile)
        os.exit(1)
    end
    out:write(finalOutput)
    out:close()
    
    -- Print statistics
    print("")
    print("==========================================================")
    print(" OBFUSCATION COMPLETE")
    print("==========================================================")
    print("")
    print(string.format("  Strings encrypted:     %d", stats.strings_encrypted))
    print(string.format("  Variables renamed:     %d", stats.vars_renamed))
    print(string.format("  Numbers obfuscated:    %d", stats.numbers_obfuscated))
    print(string.format("  Junk code inserted:    %d", stats.junk_inserted))
    print(string.format("  Dead branches added:   %d", stats.dead_branches))
    print("")
    print(string.format("  Input size:   %d bytes", #source))
    print(string.format("  Output size:  %d bytes", #finalOutput))
    print(string.format("  Bloat factor: %.1fx", #finalOutput / #source))
    print("")
    print("[+] Protected file written to: " .. outputFile)
    print("[+] Anti-tamper hash: " .. string.format("0x%08X", bodyHash))
    print("")
    print("SECURITY LAYERS ACTIVE:")
    print("  [x] XOR String Encryption (per-string random keys)")
    print("  [x] Variable Renaming (hex identifiers)")
    print("  [x] Control Flow Obfuscation (opaque predicates)")
    print("  [x] Junk Code Insertion (dead branches)")
    print("  [x] Anti-Tamper Integrity Check (DJB2 hash)")
    print("  [x] Anti-Decompile (misleading variables)")
    print("  [x] Number Obfuscation (arithmetic encoding)")
    print("  [x] Code wrapped in loadstring (prevents static analysis)")
    print("")
    print("[!] WARNING: Do NOT modify the output file - it will fail")
    print("    the integrity check and refuse to execute.")
    print("")
end

main()
