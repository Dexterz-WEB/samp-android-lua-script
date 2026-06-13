script_author("OSPx")
script_name("MoreSettings")
script_description("An additional settings menu. Currently sensitivity and aspect ratio.")
script_version("1.0")

local memory = require 'memory'
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local ffi = require 'ffi'
local hook = require('monethook')
local imgui = require 'mimgui'

local cf = (function ()local a='/'if MONET_VERSION==nil then a='\\'end;local function b(c,d)d=d or{}if c==nil then return nil end;if d[c]then return d[c]end;local e;if type(c)=='table'then e={}d[c]=e;for f,g in next,c,nil do e[b(f,d)]=b(g,d)end;setmetatable(e,b(getmetatable(c),d))else e=c end;return e end;local function h(i,j)for f,g in next,j,nil do if i[f]==nil then i[b(f)]=b(g)else if type(g)=='table'and type(i[f])=='table'then h(i[f],g)end end end end;local function k(l,m,n)local l=l or{}local n=n or'.json'local m=m or script.this.filename..n;m:gsub('\\',a)if MONET_VERSION~=nil then m:gsub('moonloader/','monetloader/')end;local o=getWorkingDirectory()..a..'config'..a..m..n;local p=getWorkingDirectory()..a..'config'..a..m;local q=m;local r=io.open(o,'r')if not r then r=io.open(p,'r')end;if not r then r=io.open(q,'r')end;if r then local s=r:read('*a')if#s==0 then r:close()return b(l)end;local t,u=pcall(decodeJson,s)r:close()if not t or not u then if not t then print('jsoncfg: failed to decode json, error:',u)end;return b(l)end;h(u,l)return u else return b(l)end end;local function v(w,m,n)local n=n or'.json'local m=m or script.this.filename..n;m:gsub('\\',a)if MONET_VERSION~=nil then m:gsub('moonloader/','monetloader/')end;local x=getWorkingDirectory()..a..'config'..a;if m:find(a,1,true)~=nil then local y=m:match('.*'..a)createDirectory(y)x=m elseif m:match('%'..n..'$')~=nil then createDirectory(x)x=x..m else createDirectory(x)x=x..m..n end;local r,z=io.open(x,'w')if r then local t,A=pcall(encodeJson,w)if t then r:write(A)else print('jsoncfg: failed to encode json, error:',A)end;r:close()return t else print('jsoncfg: failed to open file, error:',z)return false end end;return{load=k,save=v}end)()

local sens_addr = MONET_GTASA_BASE + 0x6A9F30
local function getSensitivity()
    return memory.getfloat(sens_addr)
end

---@type table
local cfg = cf.load({
    locale = getWorkingDirectory():find("com.arizona.game") and "ru" or "en",
    sensitivity = getSensitivity(),
    aspectratio = 0
}, "MoreSettings")
cfg.sensitivity = cfg.sensitivity / 1000000

local function save()
    cfg.sensitivity = cfg.sensitivity * 1000000
    cf.save(cfg, "MoreSettings")
    cfg.sensitivity = cfg.sensitivity / 1000000
end

local locales = {
    en = {
        language_switch = "Сменить язык (ru)",
        save_settings = "Save settings",
        auto = "Auto",
        sensitivity = "Sensitivity",
        aspectratio = "Aspect Ratio",
    },
    ru = {
        language_switch = "Language switch (en)",
        save_settings = "Сохранить настройки",
        auto = "Автоматически",
        sensitivity = "Чувствительность",
        aspectratio = "Соотношение сторон экрана",
    },
}

local shared = require 'SAMemory.shared'
shared.require 'RenderWare'
ffi.cdef[[
    typedef struct RwRect RwRect;
    typedef struct RwCamera RwCamera;

    void _Z10CameraSizeP8RwCameraP6RwRectff(RwCamera *camera, RwRect *rect, float unk, float aspect);
]]
local gta = ffi.load('GTASA')

local function setSensitivity(value)
    memory.setfloat(sens_addr, 0.001 + value / 3000.0)
end

local MDS = MONET_DPI_SCALE
local window = imgui.new.bool(false)
local m_sens = imgui.new.float(cfg.sensitivity)

local m_aspectratio = imgui.new.int(cfg.aspectratio)
local aspectratio_list = {
    u8(locales[cfg.locale].auto),
    "3:2",
    "4:3",
    "5:4",
    "16:9",
    "16:10",
    "21:9",
    "32:9",
}
local aspectratio_nums = {
    0.0,
    3.0 / 2.0,
    4.0 / 3.0,
    5.0 / 4.0,
    16.0 / 9.0,
    16.0 / 10.0,
    21.0 / 9.0,
    32.0 / 9.0,
}
local m_aspectratio_list = imgui.new['const char*'][#aspectratio_list](aspectratio_list)

function aspectHook(camera, rect, unk, aspect)
    if cfg.aspectratio == nil or cfg.aspectratio == 0 then
        return aspectHook(camera, rect, unk, aspect)
    end

    return aspectHook(camera, rect, unk, aspectratio_nums[cfg.aspectratio+1])
end

aspectHook = hook.new('void(*)(RwCamera *camera, RwRect *rect, float unk, float aspect)', aspectHook, ffi.cast('uintptr_t', ffi.cast('void*', gta._Z10CameraSizeP8RwCameraP6RwRectff)))

imgui.OnInitialize(function()
	imgui.GetIO().IniFilename = nil
	imgui.GetStyle():ScaleAllSizes(MDS)
end)

imgui.OnFrame(function ()
    return window[0]
end, function()
    local resX, resY = getScreenResolution()

    imgui.SetNextWindowPos(imgui.ImVec2(resX/2, resY/2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(250 * MDS, 150 * MDS), imgui.Cond.FirstUseEver)
    imgui.Begin("More Settings by OSPx", window)

    imgui.Text(u8(locales[cfg.locale].sensitivity))
    imgui.SameLine()
    imgui.SetNextItemWidth(imgui.GetWindowWidth() - imgui.GetCursorPosX() - imgui.GetStyle().FramePadding.x * 2)
    imgui.SliderFloat("##sens", m_sens, 0.0, 100.0)

    imgui.Text(u8(locales[cfg.locale].aspectratio))
    imgui.SameLine()
    imgui.SetNextItemWidth(imgui.GetWindowWidth() - imgui.GetCursorPosX() - imgui.GetStyle().FramePadding.x * 2)
    imgui.Combo("##aspect", m_aspectratio, m_aspectratio_list, #aspectratio_list)

    if imgui.Button(u8(locales[cfg.locale].language_switch), imgui.ImVec2(GetMiddleButtonX(2), 23 * MDS)) then
        if cfg.locale == "en" then
            cfg.locale = "ru"
        else
            cfg.locale = "en"
        end
    end
    imgui.SameLine()
    if imgui.Button(u8(locales[cfg.locale].save_settings), imgui.ImVec2(GetMiddleButtonX(2), 23 * MDS)) then
        save()
    end

    if m_sens[0] ~= cfg.sensitivity then
        cfg.sensitivity = m_sens[0]
        setSensitivity(cfg.sensitivity)
    end

    if m_aspectratio[0] ~= cfg.aspectratio then
        cfg.aspectratio = m_aspectratio[0]
    end

    imgui.End()

end)

sampRegisterChatCommand("ms", function()
    window[0] = not window[0]
end)

function GetMiddleButtonX(count)
	local width = imgui.GetWindowContentRegionWidth()
	local space = imgui.GetStyle().ItemSpacing.x
	return count == 1 and width or width / count - ((space * (count - 1)) / count)
end

function main()
    if cfg.sensitivity ~= 0 then setSensitivity(cfg.sensitivity) end

    wait(-1)
end

function onScriptTerminate(script, quitGame)
	if script == thisScript() then
		save()
	end
end
