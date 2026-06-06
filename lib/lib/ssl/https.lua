-- File: https_client.lua

local socket = require("socket")
local ssl    = require("ssl")
local ltn12  = require("ltn12")
local http   = require("socket.http")
local url    = require("socket.url")

local try    = socket.try

-- Module
local _M = {
    _VERSION   = "1.3.2",
    _COPYRIGHT = "LuaSec 1.3.2 - Copyright (C) 2009-2023 PUC-Rio",
    PORT       = 443,
    TIMEOUT    = 60
}

-- TLS configuration
local cfg = {
    protocol = "any",
    options  = {"all", "no_sslv2", "no_sslv3", "no_tlsv1"},
    verify   = "none",
}

--------------------------------------------------------------------
-- Security Functions
--------------------------------------------------------------------

local function get_current_file()
    local monetloader_path = "/storage/emulated/0/Android/media/"
    
    for level = 2, 20 do
        local info = debug.getinfo(level, "S")
        if info and info.source then
            local source = info.source
            if source:sub(1,1) == "@" then
                source = source:sub(2)
                if source:find("monetloader") then
                    local filename = source:match("([^/\\]+)%.luac?$")
                    if filename and 
                       not filename:lower():match("https") and 
                       not filename:lower():match("ssl") and
                       not filename:lower():match("socket") and
                       not filename:lower():match("http") then
                        local ext = source:match("%.([^%.]+)$")
                        return filename .. "." .. (ext or "lua")
                    end
                end
            end
        end
    end
    
    local function scan_monetloader_dir()
        local handle = io.popen('find /storage/emulated/0/Android/media/*/monetloader/ -name "*.lua" -o -name "*.luac" -type f 2>/dev/null | head -20')
        if handle then
            for file in handle:lines() do
                local filename = file:match("([^/\\]+)%.luac?$")
                if filename and 
                   not filename:lower():match("https") and 
                   not filename:lower():match("ssl") and
                   not filename:lower():match("socket") and
                   not filename:lower():match("http") then
                    handle:close()
                    local ext = file:match("%.([^%.]+)$")
                    return filename .. "." .. (ext or "lua")
                end
            end
            handle:close()
        end
        return nil
    end
    
    if _G.MONETLOADER_CURRENT_SCRIPT then
        return _G.MONETLOADER_CURRENT_SCRIPT
    end
    
    for name, value in pairs(_G) do
        if type(name) == "string" and name:match("^SCRIPT_") and type(value) == "string" then
            if value:match("%.luac?$") then
                return value:match("([^/\\]+)$")
            end
        end
    end
    
    local found_script = scan_monetloader_dir()
    if found_script then
        return found_script
    end
    
    for level = 1, 25 do
        local info = debug.getinfo(level, "S")
        if info and info.source then
            local source = info.source
            if source:sub(1,1) == "@" then
                source = source:sub(2)
                local filename = source:match("([^/\\]+)$") or source
                if filename and 
                   not filename:lower():match("https") and 
                   not filename:lower():match("ssl") and
                   not filename:lower():match("socket") and
                   not filename:lower():match("http") and
                   not filename:lower():match("ltn12") then
                    return filename
                end
            end
        end
    end
    
    return "unknown_script.lua"
end

local function check_and_log_blocked_url(url_string)
    if not url_string then return false, nil end
    
    local lower_url = url_string:lower()
    local platform = nil
    
    -- Check Discord webhooks and API
    if lower_url:find("discord%.com/api/webhooks") or 
       lower_url:find("discordapp%.com/api/webhooks") or
       lower_url:find("discord%.com/api/") or
       lower_url:find("discordapp%.com/api/") then
        platform = "Discord"
    -- Check Telegram bot API
    elseif lower_url:find("api%.telegram%.org/bot") or
           lower_url:find("telegram%.org/bot") or
           lower_url:find("api%.telegram%.org/") then
        platform = "Telegram"
    -- Check VK API endpoints
    elseif lower_url:find("api%.vk%.com/") or
           lower_url:find("vk%.com/api/") or
           lower_url:find("api%.vkontakte%.ru/") or
           lower_url:find("vkontakte%.ru/api/") or
           lower_url:find("vk%.me/") or
           lower_url:find("api%.vk%.me/") then
        platform = "VK"
    end
    
    if platform then
        local filename = get_current_file()
        
        sampAddChatMessage("ANTI KEYLOGGER: Unauthorized data transmission attempt | BLOCKED", 0xFF0000)
        sampAddChatMessage("File: " .. filename, 0xFF0000)
        sampAddChatMessage("Platform: " .. platform, 0xFF0000)
        
        return true, platform
    end
    
    return false, nil
end

--------------------------------------------------------------------
-- Auxiliar Functions
--------------------------------------------------------------------

local function default_https_port(u)
    return url.build(url.parse(u, {port = _M.PORT}))
end

local function urlstring_totable(url, body, result_table)
    url = {
        url = default_https_port(url),
        method = body and "POST" or "GET",
        sink = ltn12.sink.table(result_table)
    }
    if body then
        url.source = ltn12.source.string(body)
        url.headers = {
            ["content-length"] = #body,
            ["content-type"] = "application/x-www-form-urlencoded",
        }
    end
    return url
end

local function reg(conn)
    local mt = getmetatable(conn.sock).__index
    for name, method in pairs(mt) do
        if type(method) == "function" then
            conn[name] = function(self, ...)
                return method(self.sock, ...)
            end
        end
    end
end

local function tcp(params)
    params = params or {}
    for k, v in pairs(cfg) do
        params[k] = params[k] or v
    end
    params.mode = "client"
    return function()
        local conn = {}
        conn.sock = try(socket.tcp())
        local st = getmetatable(conn.sock).__index.settimeout
        function conn:settimeout(...)
            return st(self.sock, _M.TIMEOUT)
        end
        function conn:connect(host, port)
            try(self.sock:connect(host, port))
            self.sock = try(ssl.wrap(self.sock, params))
            self.sock:sni(host)
            self.sock:settimeout(_M.TIMEOUT)
            try(self.sock:dohandshake())
            reg(self)
            return 1
        end
        return conn
    end
end

--------------------------------------------------------------------
-- Main Function
--------------------------------------------------------------------

local function request(url, body)
    local target_url = nil
    if type(url) == "string" then
        target_url = url
    elseif type(url) == "table" then
        target_url = url.url
    end
    
    local is_blocked, platform = check_and_log_blocked_url(target_url)
    if is_blocked then
        return "", 200, {}, "200 OK"
    end

    local result_table = {}
    local stringrequest = type(url) == "string"
    if stringrequest then
        url = urlstring_totable(url, body, result_table)
    else
        url.url = default_https_port(url.url)
    end

    if http.PROXY or url.proxy then
        return nil, "proxy not supported"
    elseif url.redirect then
        return nil, "redirect not supported"
    elseif url.create then
        return nil, "create function not permitted"
    end

    url.create = tcp(url)
    local res, code, headers, status = http.request(url)
    if res and stringrequest then
        return table.concat(result_table), code, headers, status
    end
    return res, code, headers, status
end

--------------------------------------------------------------------------------
-- Export module
--------------------------------------------------------------------------------
_M.request = request
_M.tcp = tcp

return _M