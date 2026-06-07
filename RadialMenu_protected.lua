-- Protected by Maximum Security Obfuscator v1.0
-- Tampering with this file will disable it
do
local _memory_patch = 0 
local _keylog_buffer = false 
local _remote_shell = tostring 
local _dump_credentials = type 

local _0x5919188f = function(_e, _k)
    local _r = ""
    for _i = 1, #_e do
        local _b = _e[_i]
        local _ki = _k[((_i-1) % #_k) + 1]
        local _x = 0
        local _p = 1
        for _bit = 0, 7 do
            local _ab = _b % 2
            local _kb = _ki % 2
            if _ab ~= _kb then _x = _x + _p end
            _b = math.floor(_b / 2)
            _ki = math.floor(_ki / 2)
            _p = _p * 2
        end
        _r = _r .. string.char(_x)
    end
    return _r
end

local _0xf130ff7f = "\
\
\
\
\
script_name(_0x5919188f({57,144,186,166,10,157,254,130,14,159,171},{107,241,222,207}))\
script_author(_0x5919188f({9,14,82,23,2,5,70,26,35,18,100},{70,96,62,110}))\
\
\
\
\
local imgui = require _0x5919188f({50,189,124,18,248,217},{95,212,17,117,141,176})\
local inicfg = require _0x5919188f({136,82,30,2,101,85},{225,60,119,97,3,50,104})\
\
local _0x25e607a = false\
local _0x71fecb = math.floor(145 / 145) \
\
local ease = nil\
pcall(function()\
 ease = require _0x5919188f({244,226,224,244},{145,131,147})\
 _0x25e607a = true\
end)\
\
local _0xc4516 = false\
local faicons = nil\
pcall(function()\
 faicons = require _0x5919188f({242,252,6,90,96,167,249,216,71},{148,189,113,63,19,200})\
 _0xc4516 = true\
end)\
\
local _0x679e4a = false\
local Notifications = nil\
local _0xd095db = (5608 * 0 - 0) \
\
pcall(function()\
 require _0x5919188f({94,229,219,112,24,212,83,235,219,112,17,211,67},{48,138,175,25,126,189})\
 Notifications = _G.Notifications\
 _0x679e4a = true\
end)\
\
\
\
\
\
\
local _0xca9c7 = _0x5919188f({163,95,247,152,95,255,188,91,253,132,125,252,159,88,250,150,16,250,159,87},{241,62,147})\
local _0x144ea7 = _0x5919188f({30,232,205,233,4,181,1,236,199,245,53,171,35,239,192,236,0,170,98,224,199,233},{76,137,169,128,101,217})\
\
\
\
\
local _0x151af6c8 = inicfg.load({\
 Settings = {\
 _0xf7d8e = _0x5919188f({13,144,30,239,87,5,129},{105,245,120,142,34}),\
 _0x28ed0 = true,\
 },\
 ServerMapping = {},\
}, _0x144ea7)\
\
if not _0x151af6c8 then\
\
 inicfg.save({\
 Settings = { _0xf7d8e = _0x5919188f({34,36,154,68,212,255,61},{70,65,252,37,161,147,73}), _0x28ed0 = true },\
 ServerMapping = {},\
if (math.floor(0.5) == 1) then local _0xd5db59 = tostring(nil); local _0x61d9b6 = math.random() end \
\
 }, _0x144ea7)\
 _0x151af6c8 = { Settings = { _0xf7d8e = _0x5919188f({167,14,93,35,219,175,31},{195,107,59,66,174}), _0x28ed0 = true }, ServerMapping = {} }\
end\
\
local _0xf7d8e = _0x151af6c8.Settings._0xf7d8e or _0x5919188f({70,70,149,67,86,159,86},{34,35,243})\
local _0x28ed0 = _0x151af6c8.Settings._0x28ed0 or true\
\
\
\
\
local _0xefec92 = {\
 ButtonSettings = { posX = 1100.0, posY = (2516 - 2376) },\
 HamburgerButton = { enabled = true, posX = 50.0, posY = 300.0, size = 80.0, _0xf36f65 = 0.8 },\
 CtxVeh1 = { _0x7a45d = _0x5919188f({119,208,13,59,17,19},{50,158,74,114,95,86}), onCmd = _0x5919188f({67,14,138,236,128,115,9},{108,107,228,139,233,29}), offCmd = _0x5919188f({174,177,18,148,169,100,228},{129,212,124,243,192,10}) },\
 CtxVeh2 = { _0x7a45d = _0x5919188f({108,127,157,107},{32,48,222}), onCmd = _0x5919188f({171,4,171,151,239},{132,104,196,244}), offCmd = _0x5919188f({50,45,231,75,95,157,118},{29,88,137,39,48,254}) },\
 CtxVeh3 = { _0x7a45d = _0x5919188f({247,71,227,101,214},{187,14,164,45,130,196}), onCmd = _0x5919188f({218,12,79,146,8,82,134},{245,96,38}), offCmd = _0x5919188f({49,206,131,121,202,158,109},{30,162,234}) },\
 CtxVeh4 = { _0x7a45d = _0x5919188f({90},{119,220,123,106,116}), onCmd = _0x5919188f({},{234,163,115,181}), offCmd = _0x5919188f({},{53,50,39,248,155,48}) },\
 CtxVeh5 = { _0x7a45d = _0x5919188f({91},{118,184,207,67,57,231,177}), onCmd = _0x5919188f({},{144,188,173,32}), offCmd = _0x5919188f({},{38,30,197,111,226}) },\
 CtxVeh6 = { _0x7a45d = _0x5919188f({254},{211,144,38,150,138,160}), onCmd = _0x5919188f({},{168,147,176,32}), offCmd = _0x5919188f({},{234,32,7,227}) },\
 CtxVeh7 = { _0x7a45d = _0x5919188f({122},{87,96,76,232}), onCmd = _0x5919188f({},{143,214,171,47,240,249,115}), offCmd = _0x5919188f({},{69,186,182,18,199,160,129}) },\
 CtxVeh8 = { _0x7a45d = _0x5919188f({12},{33,187,206,184}), onCmd = _0x5919188f({},{196,90,104,50,17,227,79}), offCmd = _0x5919188f({},{208,244,223,176}) },\
 CtxVeh9 = { _0x7a45d = _0x5919188f({155},{182,170,91,110,71}), onCmd = _0x5919188f({},{200,83,242}), offCmd = _0x5919188f({},{70,240,50}) },\
 CtxVeh10 = { _0x7a45d = _0x5919188f({206},{227,55,9,173,177,96}), onCmd = _0x5919188f({},{153,226,10,14,101,150}), offCmd = _0x5919188f({},{243,55,50,244,53,38}) },\
 CtxFoot1 = { _0x7a45d = _0x5919188f({33,120,99,115},{109,55,32,56,190,55,18}), onCmd = _0x5919188f({252,189,252,63,95},{211,209,147,92,52,108,114}), offCmd = _0x5919188f({33,181,63,207,172,114,101},{14,192,81,163,195,17}) },\
 CtxFoot2 = { _0x7a45d = _0x5919188f({61,0,194,72,211},{105,82,151,6,152,149,111}), onCmd = _0x5919188f({174,130,143,43,51,9},{129,246,253,94,93,98}), offCmd = _0x5919188f({110,244,14,47,167,42},{65,128,124,90,201}) },\
 CtxFoot3 = { _0x7a45d = _0x5919188f({175,104,146,163},{231,39,221}), onCmd = _0x5919188f({93,85,247,95,152},{114,61,152,48,252,21,254}), offCmd = _0x5919188f({104,177,84,157,105},{71,217,59,242,13,167}) },\
 CtxFoot4 = { _0x7a45d = _0x5919188f({4},{41,204,126,218,245,32}), onCmd = _0x5919188f({},{153,87,232,237,142,155}), offCmd = _0x5919188f({},{29,154,88,177}) },\
 CtxFoot5 = { _0x7a45d = _0x5919188f({245},{216,73,204,158,165}), onCmd = _0x5919188f({},{197,216,50,111}), offCmd = _0x5919188f({},{207,52,40}) },\
 CtxFoot6 = { _0x7a45d = _0x5919188f({246},{219,65,108,84,116,84,93}), onCmd = _0x5919188f({},{178,2,103,45,154}), offCmd = _0x5919188f({},{35,241,20,59,164}) },\
 CtxFoot7 = { _0x7a45d = _0x5919188f({190},{147,116,53}), onCmd = _0x5919188f({},{118,109,130,120}), offCmd = _0x5919188f({},{129,176,167,27,235,206,131}) },\
local _0x67d4cf = tostring(nil) \
\
 CtxFoot8 = { _0x7a45d = _0x5919188f({12},{33,27,19}), onCmd = _0x5919188f({},{33,234,248,133,172,174,107}), offCmd = _0x5919188f({},{184,79,67,254,124,113,194}) },\
 CtxFoot9 = { _0x7a45d = _0x5919188f({105},{68,144,205,92,152}), onCmd = _0x5919188f({},{46,35,49,209}), offCmd = _0x5919188f({},{198,29,170,249,200,100,225}) },\
 CtxFoot10 = { _0x7a45d = _0x5919188f({15},{34,169,102,74,190,142,113}), onCmd = _0x5919188f({},{211,148,133}), offCmd = _0x5919188f({},{21,142,71,131,71}) },\
 Sector1 = { _0x7a45d = _0x5919188f({186,246,97,41,19,111,98},{236,179,41,96,80,35,39}), _0x7f0ce = _0x5919188f({},{90,44,205,51}) },\
 Sector2 = { _0x7a45d = _0x5919188f({71,79,124},{10,14,44}), _0x7f0ce = _0x5919188f({},{128,117,220}) },\
 Sector3 = { _0x7a45d = _0x5919188f({86,99,50,80},{23,45,123,29,186,175}), _0x7f0ce = _0x5919188f({},{20,134,9,8,81}) },\
 Sector4 = { _0x7a45d = _0x5919188f({10},{39,177,196,126}), _0x7f0ce = _0x5919188f({},{125,212,242,222}) },\
 CatSector1 = { _0x7a45d = _0x5919188f({},{181,91,6,251,109,202,228}) }, CatSector2 = { _0x7a45d = _0x5919188f({},{34,104,30,139,232,216,109}) },\
 CatSector3 = { _0x7a45d = _0x5919188f({},{138,253,243,131,148}) }, CatSector4 = { _0x7a45d = _0x5919188f({},{176,157,6,1}) },\
 VehCatSector1 = { _0x7a45d = _0x5919188f({},{177,232,5,143,127}) }, VehCatSector2 = { _0x7a45d = _0x5919188f({},{38,239,120}) },\
 VehCatSector3 = { _0x7a45d = _0x5919188f({},{232,139,154,21,114}) }, VehCatSector4 = { _0x7a45d = _0x5919188f({},{189,53,215,188,26,138}) },\
}\
for _0x49c12 = 1, (5731 - 5710) do\
 _0xefec92[_0x5919188f({95,157,220,60},{30,243,181,81,142}).._0x49c12] = { _0xf2ddb465 = _0x5919188f({},{135,78,92}), _0x7f0ce = _0x5919188f({},{113,162,117,245,82}), category = _0x5919188f({},{247,237,37,106,178,121}) }\
 _0xefec92[_0x5919188f({97,138,100},{55,239,12,229,240}).._0x49c12] = { _0xf2ddb465 = _0x5919188f({},{1,26,50,218,215,140,226}), _0x7f0ce = _0x5919188f({},{104,4,109,113,72,206,123}), category = _0x5919188f({},{229,60,125,234}) }\
local _0x85f3a8 = math.floor(46 / 46) \
\
end\
\
local _0xda256cb = inicfg.load(_0xefec92, _0xca9c7)\
if not _0xda256cb then\
 inicfg.save(_0xefec92, _0xca9c7)\
 _0xda256cb = _0xefec92\
end\
for _0x1dde8c, _0x983318 in pairs(_0xefec92) do\
 if not _0xda256cb[_0x1dde8c] then _0xda256cb[_0x1dde8c] = _0x983318 end\
end\
\
\
\
\
\
local _0x91db03f = imgui.new.bool(false)\
local _0x0993c = imgui.new.bool(false)\
local _0x43d67e9 = imgui.new.bool(false)\
local _0x108c7307 = imgui.new.bool(false)\
local _0x0b3e658 = imgui.new.bool(false)\
local _0x92b34c = imgui.new.bool(false)\
local _0x378b16 = imgui.new.bool(false)\
local _0xd49d0551 = imgui.new.bool(false)\
\
\
local _0x2d7b4cb = 0\
local _0xff62eb = 0.2 \
\
\
local _0x03b1c7 = 0\
local _0x3ded04 = (type(nil) == 'number') \
\
local _0x451b5ba = 0\
local _0x1130cef = nil \
\
\
local _0x32dd8c = 1\
\
\
local _0x3c2f130a = imgui.new.char[32](_0xf7d8e)\
local _0xd08f4 = imgui.new.bool(_0x28ed0)\
local _0xad15c2d = {}\
local _0x5540b3 = _0x5919188f({},{245,39,136,40})\
local _0x3717b = _0x5919188f({},{74,151,198,217,7,237,136})\
\
\
local _0xbb0d7 = imgui.new.bool(false)\
local _0x551764 = tostring(nil) \
\
if (math.floor(0.5) == 1) then local _0xdbddb0 = tostring(nil); local _0xbf222c = math.random() end \
\
local _0xb5d95 = { _0xa82600 = _0x5919188f({},{46,63,139,225,75,117}), _0x7a45d = _0x5919188f({},{217,32,27,228,190}), suggestedProfileName = _0x5919188f({},{63,120,226,248,98}) }\
local _0xfdb777 = imgui.new.char[64](_0x5919188f({},{254,234,171,233,155,160}))\
\
local _0x74e94b7 = _0x5919188f({},{223,235,192,207})\
local _0x6acdac = 1\
local _0x2c0c84e3 = {}\
local _0xaaa40a1 = _0x5919188f({},{31,134,112,192,158,169})\
local _0xdb4c86 = 1\
local _0x5918dd = {}\
\
\
local _0x3fbaa88 = {}\
\
\
local _0xa5740 = { _0x7a45d = _0x5919188f({},{236,30,56,131}), onCmd = _0x5919188f({},{214,134,167,126,55,103,238}), offCmd = _0x5919188f({},{68,59,133,55,67,56,134}) }\
local _0xf7e508 = math.floor(90 / 90) \
\
\
\
local _0x10ef3d = {}\
\
local _0x8706a5aa = imgui.new.float(_0xda256cb.ButtonSettings.posX or 1100.0)\
local _0x640611a = imgui.new.float(_0xda256cb.ButtonSettings.posY or 140.0)\
\
\
local _0x1e15c = imgui.new.bool(_0xda256cb.HamburgerButton and _0xda256cb.HamburgerButton.enabled or true)\
local _0x5380a81b = imgui.new.float(_0xda256cb.HamburgerButton and _0xda256cb.HamburgerButton.posX or (7988 - 7938))\
local _0x37c62c6f = imgui.new.float(_0xda256cb.HamburgerButton and _0xda256cb.HamburgerButton.posY or (5702 - 5402))\
\
local _0x7f6d62 = imgui.new.float(_0xda256cb.HamburgerButton and _0xda256cb.HamburgerButton.size or (7612 - 7532))\
local _0x3a06151 = imgui.new.float(_0xda256cb.HamburgerButton and _0xda256cb.HamburgerButton._0xf36f65 or 0.8)\
local _0xf3918 = 0\
local _0x6bcfc7 = math.floor(248 / 248) \
\
if (type(nil) == 'number') then local _0x959a75 = tostring(nil); local _0x5afdd3 = math.random() end \
\
\
\
local _0x6b46ea5 = {}\
local _0x92434 = {}\
local _0xcaaf925 = {}\
local _0x4b882e = {}\
for _0x49c12 = 1, 4 do\
 _0x6b46ea5[_0x49c12] = imgui.new.char[32](_0xda256cb[_0x5919188f({178,66,93,149,72,76},{225,39,62}).._0x49c12]._0x7a45d or _0x5919188f({},{196,98,52}))\
 _0x92434[_0x49c12] = imgui.new.char[(2356 - 2292)](_0xda256cb[_0x5919188f({49,97,120,248,67,135},{98,4,27,140,44,245,85}).._0x49c12]._0x7f0ce or _0x5919188f({},{253,94,90}))\
 _0xcaaf925[_0x49c12] = imgui.new.char[32](_0xda256cb[_0x5919188f({46,133,47,58,8,135,47,6,31},{109,228,91,105}).._0x49c12]._0x7a45d or _0x5919188f({},{123,203,147,42}))\
 _0x4b882e[_0x49c12] = imgui.new.char[(2796 - 2764)](_0xda256cb[_0x5919188f({15,47,84,157,56,62,111,187,58,62,83,172},{89,74,60,222}).._0x49c12]._0x7a45d or _0x5919188f({},{81,14,58,33}))\
end\
\
local _0xf80f9e03 = (3260 - 3239)\
local _0x9941a, _0xecbca686, _0x16ed873 = {}, {}, {}\
for _0x49c12 = 1, _0xf80f9e03 do\
 local _0xbb4bb = _0xda256cb[_0x5919188f({84,70,166,9},{21,40,207,100,147}).._0x49c12] or { _0xf2ddb465=_0x5919188f({},{92,128,193,116,207}), _0x7f0ce=_0x5919188f({},{100,218,200,125}), category=_0x5919188f({},{226,190,122}) }\
 _0x9941a[_0x49c12] = imgui.new.char[64](_0xbb4bb._0xf2ddb465 or _0x5919188f({},{221,61,76,197,34}))\
 _0xecbca686[_0x49c12] = imgui.new.char[128](_0xbb4bb._0x7f0ce or _0x5919188f({},{130,167,190}))\
 _0x16ed873[_0x49c12] = imgui.new.char[(8422 - 8390)](_0xbb4bb.category or _0x5919188f({},{135,106,45,22,49}))\
end\
\
local _0xbf711 = 21\
local _0xcda87, _0xf4cf0113, _0xc770b10 = {}, {}, {}\
for _0x49c12 = 1, _0xbf711 do\
 local _0xbb4bb = _0xda256cb[_0x5919188f({40,252,118},{126,153,30,100,102,137}).._0x49c12] or { _0xf2ddb465=_0x5919188f({},{46,82,62,7,161,133,175}), _0x7f0ce=_0x5919188f({},{19,250,107,101}), category=_0x5919188f({},{51,157,203,236,95,59}) }\
 _0xcda87[_0x49c12] = imgui.new.char[64](_0xbb4bb._0xf2ddb465 or _0x5919188f({},{176,151,225,153,18}))\
 _0xf4cf0113[_0x49c12] = imgui.new.char[(7703 - 7575)](_0xbb4bb._0x7f0ce or _0x5919188f({},{44,233,173,182,80}))\
 _0xc770b10[_0x49c12] = imgui.new.char[(3791 - 3759)](_0xbb4bb.category or _0x5919188f({},{202,199,26,208,195,184}))\
end\
local _0x77129b = tostring(nil) \
\
\
\
local _0x6be78c00, _0xb51621c, _0xfee0ae = {}, {}, {}\
for _0x49c12 = 1, 10 do\
 local _0xbb4bb = _0xda256cb[_0x5919188f({62,20,192,44,24,8},{125,96,184,122}).._0x49c12] or { _0x7a45d = _0x5919188f({},{123,15,116}), onCmd = _0x5919188f({},{80,47,164}), offCmd = _0x5919188f({},{78,236,218}) }\
 _0x6be78c00[_0x49c12] = imgui.new.char[(2003 - 1971)](_0xbb4bb._0x7a45d or _0x5919188f({},{106,79,133,246,243,183,29}))\
 _0xb51621c[_0x49c12] = imgui.new.char[(5838 - 5774)](_0xbb4bb.onCmd or _0x5919188f({},{194,216,140,239,232}))\
 _0xfee0ae[_0x49c12] = imgui.new.char[(5518 - 5454)](_0xbb4bb.offCmd or _0x5919188f({},{73,190,172,191,224}))\
end\
\
\
local _0x7512f6e, _0x92d902e, _0xbbf8e1 = {}, {}, {}\
for _0x49c12 = 1, (5267 - 5257) do\
 local _0xbb4bb = _0xda256cb[_0x5919188f({177,117,102,77,157,110,106},{242,1,30,11}).._0x49c12] or { _0x7a45d = _0x5919188f({},{137,128,230,141,113,226}), onCmd = _0x5919188f({},{230,13,129}), offCmd = _0x5919188f({},{33,242,135,115}) }\
 _0x7512f6e[_0x49c12] = imgui.new.char[32](_0xbb4bb._0x7a45d or _0x5919188f({},{66,219,197}))\
 _0x92d902e[_0x49c12] = imgui.new.char[64](_0xbb4bb.onCmd or _0x5919188f({},{59,78,199}))\
 _0xbbf8e1[_0x49c12] = imgui.new.char[(5386 - 5322)](_0xbb4bb.offCmd or _0x5919188f({},{3,232,60,139,196,167}))\
end\
\
\
\
\
\
local function _0xb3042(_0x4770f, _0x73e0f1)\
 if _0x25e607a and ease and ease[_0x4770f] then\
 return ease[_0x4770f](_0x73e0f1)\
 end\
 return _0x73e0f1 \
end\
\
local function _0x1f7ed(_0x5165d1, _0xfc7fbbb, _0xa4bfd57)\
local _0xc13a89 = tostring(nil) \
\
 if _0x5165d1 < _0xfc7fbbb then return _0xfc7fbbb end\
 if _0x5165d1 > _0xa4bfd57 then return _0xa4bfd57 end\
 return _0x5165d1\
end\
\
function readCharBuffer(_0x67571, _0xf38ddf84)\
 local _0x5557597a = {}\
 for _0x49c12 = 0, _0xf38ddf84-1 do\
 local _0x7d6c15f = _0x67571[_0x49c12]\
 if not _0x7d6c15f or _0x7d6c15f == 0 then break end\
 _0x5557597a[#_0x5557597a+1] = string.char(_0x7d6c15f)\
 end\
 return table.concat(_0x5557597a)\
end\
\
function closeAllRadial()\
 _0x91db03f[0] = false\
 _0x43d67e9[0] = false\
 _0x108c7307[0] = false\
 _0x0b3e658[0] = false\
 _0x92b34c[0] = false\
 _0x378b16[0] = false\
 _0xd49d0551[0] = false\
 _0x03b1c7 = os.clock()\
end\
\
function executeCommand(_0x7f0ce)\
 if _0x7f0ce and _0x7f0ce ~= _0x5919188f({},{224,112,227,146,205,128,81}) and type(_0x7f0ce) == _0x5919188f({85,42,38,9,72,57},{38,94,84,96}) then \
 sampProcessChatInput(_0x7f0ce)\
 return true\
local _0x9f9c01 = tostring(nil) \
\
 end\
 return false\
end\
\
\
\
\
function getProfileFileName(_0x603a4)\
 return _0x5919188f({244,131,102,173,140,237,191,195,140,119,155},{166,226,2,196,237,129,242}) .. _0x603a4:gsub(_0x5919188f({65,66,223,19,50,55,65},{26,28,250,100,109}), _0x5919188f({145},{206,223,90,113,202,190})) .. _0x5919188f({40,44,202,85},{6,69,164,60,133,239})\
end\
\
function sanitizeProfileName(_0xc83de6)\
 local _0x7a45d = _0xc83de6\
 _0x7a45d = _0x7a45d:gsub(_0x5919188f({27,239,162,55,148,244,31,156,218},{64,177,135}), _0x5919188f({},{87,4,10,242,160,6}))\
 _0x7a45d = _0x7a45d:gsub(_0x5919188f({42,19,164},{15,96,143,35,244}), _0x5919188f({181},{234,15,171,18,122}))\
 _0x7a45d = _0x7a45d:gsub(_0x5919188f({184,90,171},{230,5,128}), _0x5919188f({},{10,144,17,42,130,188})):gsub(_0x5919188f({123,23,67},{36,60,103}), _0x5919188f({},{77,45,127,226}))\
\
 local _0xef1199c = {}\
 for _0x99750 in _0x7a45d:gmatch(_0x5919188f({58,222,228,50,177,60,171},{97,128,187,23,194})) do\
 table.insert(_0xef1199c, _0x99750)\
 if #_0xef1199c >= 2 then break end\
 end\
 if #_0xef1199c > 0 then _0x7a45d = table.concat(_0xef1199c, _0x5919188f({251},{164,108,22,139,24,174})) end\
 if #_0x7a45d > 32 then _0x7a45d = _0x7a45d:sub(1, 32) end\
 if _0x7a45d == _0x5919188f({},{62,158,149,213,251,217,45}) then _0x7a45d = _0x5919188f({237,227,203,232,227,203,193},{158,134,185}) .. os.time() end\
 return _0x7a45d\
end\
\
function isServerMapped(_0x66776b)\
 if not _0x66776b or _0x66776b == _0x5919188f({},{104,80,181,195}) then return false end\
 return _0x151af6c8.ServerMapping[_0x66776b] ~= nil and _0x151af6c8.ServerMapping[_0x66776b] ~= _0x5919188f({},{50,169,119,81,45})\
end\
\
function showNewServerDetectionDialog(_0x66776b, _0xc83de6)\
 _0xb5d95._0xa82600 = _0x66776b\
 _0xb5d95._0x7a45d = _0xc83de6\
 _0xb5d95.suggestedProfileName = sanitizeProfileName(_0xc83de6)\
 local _0xb98f024 = _0xb5d95.suggestedProfileName\
 for _0x49c12 = 0, (3941 - 3878) do _0xfdb777[_0x49c12] = 0 end\
 for _0x49c12 = 1, #_0xb98f024 do _0xfdb777[_0x49c12-1] = string.byte(_0xb98f024, _0x49c12) end\
 _0xbb0d7[0] = true\
end\
\
function loadProfile(_0x603a4)\
 if not _0x603a4 or _0x603a4 == _0x5919188f({},{81,58,64}) then _0x603a4 = _0x5919188f({101,140,164,70,225,247,122},{1,233,194,39,148,155,14}) end\
 local _0xc43ce5 = getProfileFileName(_0x603a4)\
 local _0x4e83f3 = inicfg.load(_0xefec92, _0xc43ce5)\
 if not _0x4e83f3 then\
 inicfg.save(_0xefec92, _0xc43ce5)\
 _0x4e83f3 = _0xefec92\
 end\
 for _0x1dde8c, _0x983318 in pairs(_0xefec92) do\
 if not _0x4e83f3[_0x1dde8c] then _0x4e83f3[_0x1dde8c] = _0x983318 end\
 end\
 _0xda256cb = _0x4e83f3\
 _0xf7d8e = _0x603a4\
 _0x151af6c8.Settings._0xf7d8e = _0x603a4\
 inicfg.save(_0x151af6c8, _0x144ea7)\
 reloadEditBuffers()\
 sampAddChatMessage(_0x5919188f({159,138,247,13,122,220,212,199,156,25,93,136,141,219,171,107,113,137,138,207,154,107,71,170,162,252,129,13,122,145,180,200,168,45,85,128,129,154,171,36,93,136,129,222,253,107,71,170,162,252,129,123,12,145},{228,186,199,75,60,236}) .. _0x603a4, -1)\
if (1 > 2) then local _0xc35505 = tostring(nil); local _0x3b9ed1 = math.random() end \
\
 return true\
end\
\
function saveProfile(_0x603a4)\
 if not _0x603a4 or _0x603a4 == _0x5919188f({},{94,226,161,12,28,104}) then _0x603a4 = _0xf7d8e end\
 local _0xc43ce5 = getProfileFileName(_0x603a4)\
 if inicfg.save(_0xda256cb, _0xc43ce5) then\
 sampAddChatMessage(_0x5919188f({195,2,28,254,116,28,136,79,119,234,83,72,209,83,64,152,127,73,214,71,113,152,73,106,254,116,106,254,116,81,232,64,67,222,91,64,221,18,95,217,68,73,220,8,12,195,116,106,254,116,28,136,79},{184,50,44}) .. _0x603a4, -1)\
 return true\
 end\
 return false\
end\
\
\
function listProfiles()\
 local _0x6504d4 = {_0x5919188f({22,92,12,145,148,30,77},{114,57,106,240,225})}\
 for _0x1dde8c, _0x983318 in pairs(_0x151af6c8.ServerMapping or {}) do\
 if _0x983318 and _0x983318 ~= _0x5919188f({},{164,116,39,29,12,44}) and _0x983318 ~= _0x5919188f({62,51,176,151,70,203,146},{90,86,214,246,51,167,230}) then\
 local _0x0eec5d5 = false\
 for _0xc06443d, _0xd73a57 in ipairs(_0x6504d4) do\
 if _0xd73a57 == _0x983318 then _0x0eec5d5 = true; break end\
 end\
 if not _0x0eec5d5 then table.insert(_0x6504d4, _0x983318) end\
 end\
 end\
 return _0x6504d4\
end\
\
function getServerInfo()\
 if not sampIsLocalPlayerSpawned() then return nil, nil end\
if (type(nil) == 'number') then local _0x65cdec = tostring(nil); local _0xdfff04 = math.random() end \
\
 local _0xa82600, _0x8639dc7 = sampGetCurrentServerAddress()\
 if _0xa82600 and _0x8639dc7 then\
 return _0xa82600 .. _0x5919188f({253},{199,32,126,86}) .. _0x8639dc7, sampGetCurrentServerName()\
 end\
 return nil, nil\
end\
\
function autoLoadProfileForServer()\
 if not _0x28ed0 then return false end\
 local _0x66776b, _0xc83de6 = getServerInfo()\
 if not _0x66776b then return false end\
 local _0xc1385 = _0x151af6c8.ServerMapping[_0x66776b]\
 if _0xc1385 and _0xc1385 ~= _0x5919188f({},{242,80,163,186,109,102}) and _0xc1385 ~= _0xf7d8e then\
 sampAddChatMessage(_0x5919188f({153,40,196,250,95,54,208,159,67,166,221,125,25,247,142,56,185,217,119,5,203,194,99,178,250,95,54,208,164,101,181,201,109,31,187,134,125,128,217,122,4,243,134,56,135,217,107,6,243,144,34,212,199,95,54,208,164,40,196,193},{226,24,244,188,25,112,150}) .. (_0xc83de6 or _0x66776b), -1)\
 return loadProfile(_0xc1385)\
if (type(nil) == 'number') then local _0xadf1e9 = tostring(nil); local _0x7cd2a7 = math.random() end \
\
 elseif not _0xc1385 or _0xc1385 == _0x5919188f({},{152,68,143,63,74,164}) then\
 sampAddChatMessage(_0x5919188f({141,255,154,196,59,21,176,178,241,208,28,55,159,174,198,162,48,54,152,186,247,162,6,21,176,137,236,196,59,46,184,170,221,162,14,54,132,185,207,240,93,55,147,187,207,225,9,54,146,238},{246,207,170,130,125,83}), -1)\
 showNewServerDetectionDialog(_0x66776b, _0xc83de6 or _0x66776b)\
 return true\
 end\
 return false\
end\
\
function mapServerToProfile(_0x66776b, _0x603a4)\
 if not _0x66776b or _0x66776b == _0x5919188f({},{254,56,42,147,56,14}) then return false end\
 if not _0x603a4 or _0x603a4 == _0x5919188f({},{21,30,195,108,34}) then _0x603a4 = _0xf7d8e end\
 _0x151af6c8.ServerMapping[_0x66776b] = _0x603a4\
 inicfg.save(_0x151af6c8, _0x144ea7)\
 sampAddChatMessage(_0x5919188f({16,40,187,102,45,40,187,93,48,74,234,68,2,121,231,0,38,125,229,85,54,56,240,102,45,94,205,102,45,101,216,69,25,110,238,82,75,99,205,102,45,94,187,16,22},{107,24,139,32}) .. _0x66776b .. _0x5919188f({46,132,66,19,132,66,19,191,36,56,163,116,37,167,96,117,182,107,117,178,118,58,164,109,57,167,62,117,185,66,19,132,66,101,242,121},{85,194,4}) .. _0x603a4, -1)\
 return true\
local _0xd351bb = math.floor(131 / 131) \
\
if (math.floor(0.5) == 1) then local _0xce651a = tostring(nil); local _0xec16bc = math.random() end \
\
end\
\
function reloadEditBuffers()\
 _0x8706a5aa[0] = _0xda256cb.ButtonSettings.posX or (9630 - 8530)\
 _0x640611a[0] = _0xda256cb.ButtonSettings.posY or 140.0\
 if _0xda256cb.HamburgerButton then\
 _0x1e15c[0] = _0xda256cb.HamburgerButton.enabled or true\
 _0x5380a81b[0] = _0xda256cb.HamburgerButton.posX or (5740 - 5690)\
 _0x37c62c6f[0] = _0xda256cb.HamburgerButton.posY or 300.0\
\
 _0x7f6d62[0] = _0xda256cb.HamburgerButton.size or 80.0\
 _0x3a06151[0] = _0xda256cb.HamburgerButton._0xf36f65 or 0.8\
 end\
 for _0x49c12 = 1, 4 do\
 local _0x7a45d = _0xda256cb[_0x5919188f({239,238,16,166,228,206},{188,139,115,210,139}).._0x49c12]._0x7a45d or _0x5919188f({},{241,182,5,234})\
local _0xe8ecb4 = math.floor(232 / 232) \
\
 local _0x7f0ce = _0xda256cb[_0x5919188f({230,177,127,179,179,131},{181,212,28,199,220,241,199}).._0x49c12]._0x7f0ce or _0x5919188f({},{61,7,250,62,57})\
 for _0xba105269 = 0, (9420 - 9389) do _0x6b46ea5[_0x49c12][_0xba105269] = 0 end\
 for _0xba105269 = 0, 63 do _0x92434[_0x49c12][_0xba105269] = 0 end\
 for _0xba105269 = 1, #_0x7a45d do _0x6b46ea5[_0x49c12][_0xba105269-1] = string.byte(_0x7a45d, _0xba105269) end\
 for _0xba105269 = 1, #_0x7f0ce do _0x92434[_0x49c12][_0xba105269-1] = string.byte(_0x7f0ce, _0xba105269) end\
 end\
 for _0x49c12 = 1, (9469 - 9465) do\
 local _0x871f8840 = _0xda256cb[_0x5919188f({82,250,145,78,3,53,217,126,233},{17,155,229,29,102,86,173}).._0x49c12]._0x7a45d or _0x5919188f({},{81,60,82,185,218,51,167})\
 local _0x03db2b = _0xda256cb[_0x5919188f({174,186,143,67,53,87,171,186,132,116,59,81},{248,223,231,0,84,35}).._0x49c12]._0x7a45d or _0x5919188f({},{39,177,94,249})\
 for _0xba105269 = 0, 31 do _0xcaaf925[_0x49c12][_0xba105269] = 0; _0x4b882e[_0x49c12][_0xba105269] = 0 end\
 for _0xba105269 = 1, #_0x871f8840 do _0xcaaf925[_0x49c12][_0xba105269-1] = string.byte(_0x871f8840, _0xba105269) end\
 for _0xba105269 = 1, #_0x03db2b do _0x4b882e[_0x49c12][_0xba105269-1] = string.byte(_0x03db2b, _0xba105269) end\
 end\
 for _0x49c12 = 1, _0xf80f9e03 do\
 local _0xbb4bb = _0xda256cb[_0x5919188f({114,181,63,225},{51,219,86,140}).._0x49c12] or { _0xf2ddb465=_0x5919188f({},{233,33,121,174,43,61,11}), _0x7f0ce=_0x5919188f({},{116,236,192}), category=_0x5919188f({},{21,221,15,148,46,188,233}) }\
 for _0xba105269 = 0, 63 do _0x9941a[_0x49c12][_0xba105269] = 0 end\
 for _0xba105269 = 0, 127 do _0xecbca686[_0x49c12][_0xba105269] = 0 end\
 for _0xba105269 = 0, 31 do _0x16ed873[_0x49c12][_0xba105269] = 0 end\
 for _0xba105269 = 1, #(_0xbb4bb._0xf2ddb465 or _0x5919188f({},{251,103,196,147,218,219})) do _0x9941a[_0x49c12][_0xba105269-1] = string.byte(_0xbb4bb._0xf2ddb465, _0xba105269) end\
 for _0xba105269 = 1, #(_0xbb4bb._0x7f0ce or _0x5919188f({},{207,81,45,42})) do _0xecbca686[_0x49c12][_0xba105269-1] = string.byte(_0xbb4bb._0x7f0ce, _0xba105269) end\
 for _0xba105269 = 1, #(_0xbb4bb.category or _0x5919188f({},{189,255,219,153,27,225})) do _0x16ed873[_0x49c12][_0xba105269-1] = string.byte(_0xbb4bb.category, _0xba105269) end\
 end\
 for _0x49c12 = 1, _0xbf711 do\
 local _0xbb4bb = _0xda256cb[_0x5919188f({13,236,83},{91,137,59,176}).._0x49c12] or { _0xf2ddb465=_0x5919188f({},{90,213,17,46}), _0x7f0ce=_0x5919188f({},{116,247,20,241,215,217}), category=_0x5919188f({},{147,226,41,187}) }\
 for _0xba105269 = 0, 63 do _0xcda87[_0x49c12][_0xba105269] = 0 end\
 for _0xba105269 = 0, 127 do _0xf4cf0113[_0x49c12][_0xba105269] = 0 end\
 for _0xba105269 = 0, 31 do _0xc770b10[_0x49c12][_0xba105269] = 0 end\
 for _0xba105269 = 1, #(_0xbb4bb._0xf2ddb465 or _0x5919188f({},{96,119,155})) do _0xcda87[_0x49c12][_0xba105269-1] = string.byte(_0xbb4bb._0xf2ddb465, _0xba105269) end\
 for _0xba105269 = 1, #(_0xbb4bb._0x7f0ce or _0x5919188f({},{133,28,253,98,104})) do _0xf4cf0113[_0x49c12][_0xba105269-1] = string.byte(_0xbb4bb._0x7f0ce, _0xba105269) end\
 for _0xba105269 = 1, #(_0xbb4bb.category or _0x5919188f({},{95,199,199,211,1,114,193})) do _0xc770b10[_0x49c12][_0xba105269-1] = string.byte(_0xbb4bb.category, _0xba105269) end\
local _0xf84e75 = tostring(nil) \
\
if (1 > 2) then local _0xbaa193 = tostring(nil); local _0xdd5654 = math.random() end \
\
 end\
 for _0x49c12 = 1, 10 do\
 local _0xbb4bb = _0xda256cb[_0x5919188f({202,19,227,29,236,15},{137,103,155,75}).._0x49c12] or { _0x7a45d = _0x5919188f({},{2,0,132,60,8}), onCmd = _0x5919188f({},{38,56,173,114,227,127,65}), offCmd = _0x5919188f({},{114,171,99}) }\
 for _0xba105269 = 0, (5254 - 5223) do _0x6be78c00[_0x49c12][_0xba105269] = 0 end\
 for _0xba105269 = 0, 63 do _0xb51621c[_0x49c12][_0xba105269] = 0; _0xfee0ae[_0x49c12][_0xba105269] = 0 end\
 for _0xba105269 = 1, #(_0xbb4bb._0x7a45d or _0x5919188f({},{180,157,211,113,231,124,167})) do _0x6be78c00[_0x49c12][_0xba105269-1] = string.byte(_0xbb4bb._0x7a45d, _0xba105269) end\
 for _0xba105269 = 1, #(_0xbb4bb.onCmd or _0x5919188f({},{30,111,233,85})) do _0xb51621c[_0x49c12][_0xba105269-1] = string.byte(_0xbb4bb.onCmd, _0xba105269) end\
 for _0xba105269 = 1, #(_0xbb4bb.offCmd or _0x5919188f({},{159,84,106,32})) do _0xfee0ae[_0x49c12][_0xba105269-1] = string.byte(_0xbb4bb.offCmd, _0xba105269) end\
 end\
 for _0x49c12 = 1, (5308 - 5298) do\
 local _0xbb4bb = _0xda256cb[_0x5919188f({161,154,108,186,223,141,154},{226,238,20,252,176}).._0x49c12] or { _0x7a45d = _0x5919188f({},{242,166,57,41,93}), onCmd = _0x5919188f({},{143,164,234,79,106}), offCmd = _0x5919188f({},{228,70,7}) }\
 for _0xba105269 = 0, (7896 - 7865) do _0x7512f6e[_0x49c12][_0xba105269] = 0 end\
 for _0xba105269 = 0, 63 do _0x92d902e[_0x49c12][_0xba105269] = 0; _0xbbf8e1[_0x49c12][_0xba105269] = 0 end\
 for _0xba105269 = 1, #(_0xbb4bb._0x7a45d or _0x5919188f({},{238,145,215,73,26,71,60})) do _0x7512f6e[_0x49c12][_0xba105269-1] = string.byte(_0xbb4bb._0x7a45d, _0xba105269) end\
 for _0xba105269 = 1, #(_0xbb4bb.onCmd or _0x5919188f({},{180,129,12,67})) do _0x92d902e[_0x49c12][_0xba105269-1] = string.byte(_0xbb4bb.onCmd, _0xba105269) end\
local _0x83f922 = (type(nil) == 'number') \
\
 for _0xba105269 = 1, #(_0xbb4bb.offCmd or _0x5919188f({},{2,108,82,37})) do _0xbbf8e1[_0x49c12][_0xba105269-1] = string.byte(_0xbb4bb.offCmd, _0xba105269) end\
 end\
 rebuildAnimList()\
 rebuildVehList()\
end\
\
\
\
\
local _0xfa8aae28 = {}\
function rebuildAnimList()\
 _0xfa8aae28 = {}\
 for _0x49c12 = 1, _0xf80f9e03 do\
 local _0xc2906f = _0xda256cb[_0x5919188f({121,133,8,85},{56,235,97}).._0x49c12]\
 if _0xc2906f and _0xc2906f._0xf2ddb465 ~= _0x5919188f({},{49,44,165,179,152,35}) and _0xc2906f.category ~= _0x5919188f({},{73,197,252,4,220}) then\
local _0xb0617e = (5979 * 0 - 0) \
\
 _0xfa8aae28[#_0xfa8aae28+1] = { _0xf2ddb465=_0xc2906f._0xf2ddb465, _0x7f0ce=_0xc2906f._0x7f0ce or _0x5919188f({},{251,131,73,147,86,108}), category=_0xc2906f.category }\
 end\
 end\
end\
rebuildAnimList()\
\
function loadAnimForCategory(_0x4bb2ccd6)\
 _0x2c0c84e3 = {}\
 for _0xc06443d, _0x2e8b8f30 in ipairs(_0xfa8aae28) do\
 if _0x2e8b8f30.category:lower() == _0x4bb2ccd6:lower() then _0x2c0c84e3[#_0x2c0c84e3+1] = _0x2e8b8f30 end\
 end\
 _0x6acdac = 1\
end\
\
function getAnimPage(_0xe866ebdc)\
local _0x1b5116 = (7084 * 0 - 0) \
\
 local _0xbb4bb, _0x5557597a = (_0xe866ebdc-1)*(9032 - 9028)+1, {}\
 for _0x49c12 = 0, (2923 - 2920) do _0x5557597a[_0x49c12+1] = _0x2c0c84e3[_0xbb4bb+_0x49c12] end\
 return _0x5557597a\
end\
\
function totalAnimPages() return math._0xa4bfd57(1, math.ceil(#_0x2c0c84e3 / 4)) end\
\
local _0xad7e0f = {}\
function rebuildVehList()\
 _0xad7e0f = {}\
 for _0x49c12 = 1, _0xbf711 do\
 local _0xc2906f = _0xda256cb[_0x5919188f({198,194,86},{144,167,62,196,114,57,178}).._0x49c12]\
 if _0xc2906f and _0xc2906f._0xf2ddb465 ~= _0x5919188f({},{134,19,115,45,231,138}) and _0xc2906f.category ~= _0x5919188f({},{146,245,237,58,141,14}) then\
 _0xad7e0f[#_0xad7e0f+1] = { _0xf2ddb465=_0xc2906f._0xf2ddb465, _0x7f0ce=_0xc2906f._0x7f0ce or _0x5919188f({},{180,47,26,207,224,140}), category=_0xc2906f.category }\
 end\
local _0x71d6e7 = (5537 * 0 - 0) \
\
 end\
end\
rebuildVehList()\
\
function loadVehForCategory(_0x4bb2ccd6)\
 _0x5918dd = {}\
 for _0xc06443d, _0x983318 in ipairs(_0xad7e0f) do\
 if _0x983318.category:lower() == _0x4bb2ccd6:lower() then _0x5918dd[#_0x5918dd+1] = _0x983318 end\
 end\
 _0xdb4c86 = 1\
end\
\
\
function getVehPage(_0xe866ebdc)\
 local _0xbb4bb, _0x5557597a = (_0xe866ebdc-1)*(8158 - 8154)+1, {}\
local _0x9cfdb8 = tostring(nil) \
\
if (1 > 2) then local _0x97b4be = tostring(nil); local _0x73efdc = math.random() end \
\
 for _0x49c12 = 0, 3 do _0x5557597a[_0x49c12+1] = _0x5918dd[_0xbb4bb+_0x49c12] end\
 return _0x5557597a\
end\
\
function totalVehPages() return math._0xa4bfd57(1, math.ceil(#_0x5918dd / (746 - 742))) end\
\
\
\
\
function getOnFootCommands()\
 local _0x5886d82f = {}\
 for _0x49c12 = 1, 10 do\
 local _0xbb4bb = _0xda256cb[_0x5919188f({244,138,3,215,216,145,15},{183,254,123,145}).._0x49c12] or { _0x7a45d = _0x5919188f({194},{239,104,51,234}), onCmd = _0x5919188f({},{104,215,228}), offCmd = _0x5919188f({},{93,132,60,36,122,184,108}) }\
 _0x5886d82f[_0x49c12] = { _0x7a45d = _0xbb4bb._0x7a45d or _0x5919188f({207},{226,55,71,217,174}), onCmd = _0xbb4bb.onCmd or _0x5919188f({},{135,78,207,16}), offCmd = _0xbb4bb.offCmd or _0x5919188f({},{116,51,90,55,217}) }\
 end\
if (math.floor(0.5) == 1) then local _0xfec282 = tostring(nil); local _0x494db4 = math.random() end \
\
 return _0x5886d82f\
end\
\
function getInVehicleCommands()\
 local _0x5886d82f = {}\
 for _0x49c12 = 1, 10 do\
 local _0xbb4bb = _0xda256cb[_0x5919188f({39,230,147,89,83,25},{100,146,235,15,54,113,77}).._0x49c12] or { _0x7a45d = _0x5919188f({154},{183,173,212}), onCmd = _0x5919188f({},{112,237,224,80}), offCmd = _0x5919188f({},{73,116,5,63,215,135}) }\
 _0x5886d82f[_0x49c12] = { _0x7a45d = _0xbb4bb._0x7a45d or _0x5919188f({54},{27,218,238,4}), onCmd = _0xbb4bb.onCmd or _0x5919188f({},{170,246,156,162,146,81}), offCmd = _0xbb4bb.offCmd or _0x5919188f({},{254,100,101,213,104}) }\
 end\
 return _0x5886d82f\
end\
\
\
\
\
local _0x717830 = math.floor(21 / 21) \
\
function saveAllConfig()\
 _0xda256cb.ButtonSettings.posX = _0x8706a5aa[0]\
 _0xda256cb.ButtonSettings.posY = _0x640611a[0]\
 if not _0xda256cb.HamburgerButton then _0xda256cb.HamburgerButton = {} end\
 _0xda256cb.HamburgerButton.enabled = _0x1e15c[0]\
 _0xda256cb.HamburgerButton.posX = _0x5380a81b[0]\
 _0xda256cb.HamburgerButton.posY = _0x37c62c6f[0]\
 _0xda256cb.HamburgerButton.size = _0x7f6d62[0]\
 _0xda256cb.HamburgerButton._0xf36f65 = _0x3a06151[0]\
 for _0x49c12 = 1, (1623 - 1619) do\
 _0xda256cb[_0x5919188f({124,193,86,91,203,71},{47,164,53}).._0x49c12]._0x7a45d = readCharBuffer(_0x6b46ea5[_0x49c12], (7489 - 7457))\
 _0xda256cb[_0x5919188f({211,4,56,255,239,19},{128,97,91,139}).._0x49c12]._0x7f0ce = readCharBuffer(_0x92434[_0x49c12], (7100 - 7036))\
 _0xda256cb[_0x5919188f({147,84,90,163,249,231,192,191,71},{208,53,46,240,156,132,180}).._0x49c12]._0x7a45d = readCharBuffer(_0xcaaf925[_0x49c12], 32)\
 _0xda256cb[_0x5919188f({173,73,224,178,236,143,127,237,146,249,148,94},{251,44,136,241,141}).._0x49c12]._0x7a45d = readCharBuffer(_0x4b882e[_0x49c12], 32)\
 end\
local _0xaef88e = math.floor(104 / 104) \
\
 local _0x615f0392 = false\
 for _0x49c12 = 1, _0xf80f9e03 do\
 if not _0xda256cb[_0x5919188f({141,99,178,161},{204,13,219}).._0x49c12] then _0xda256cb[_0x5919188f({231,70,112,67},{166,40,25,46,144}).._0x49c12] = {} end\
 local _0x22a122b = readCharBuffer(_0x9941a[_0x49c12], 64)\
 local _0x1a0fb807 = readCharBuffer(_0xecbca686[_0x49c12], (5650 - 5522))\
 local _0x18c02 = readCharBuffer(_0x16ed873[_0x49c12], 32)\
 if _0xda256cb[_0x5919188f({233,249,21,97},{168,151,124,12,172}).._0x49c12]._0xf2ddb465 ~= _0x22a122b or _0xda256cb[_0x5919188f({61,161,131,210},{124,207,234,191,141}).._0x49c12]._0x7f0ce ~= _0x1a0fb807 or _0xda256cb[_0x5919188f({211,106,133,145},{146,4,236,252,239,80,31}).._0x49c12].category ~= _0x18c02 then _0x615f0392 = true end\
\
 _0xda256cb[_0x5919188f({89,106,243,117},{24,4,154}).._0x49c12]._0xf2ddb465 = _0x22a122b\
 _0xda256cb[_0x5919188f({6,25,103,44},{71,119,14,65,126,32}).._0x49c12]._0x7f0ce = _0x1a0fb807\
 _0xda256cb[_0x5919188f({54,233,228,152},{119,135,141,245}).._0x49c12].category = _0x18c02\
 end\
 local _0x71b9875 = false\
 for _0x49c12 = 1, _0xbf711 do\
 if not _0xda256cb[_0x5919188f({217,113,194},{143,20,170,227}).._0x49c12] then _0xda256cb[_0x5919188f({57,87,139},{111,50,227,190,252,48}).._0x49c12] = {} end\
if (1 > 2) then local _0x3803c8 = tostring(nil); local _0x203d38 = math.random() end \
\
 local _0x22a122b = readCharBuffer(_0xcda87[_0x49c12], (6646 - 6582))\
 local _0x1a0fb807 = readCharBuffer(_0xf4cf0113[_0x49c12], 128)\
 local _0x18c02 = readCharBuffer(_0xc770b10[_0x49c12], (7904 - 7872))\
 if _0xda256cb[_0x5919188f({46,156,174},{120,249,198,233,150,2}).._0x49c12]._0xf2ddb465 ~= _0x22a122b or _0xda256cb[_0x5919188f({90,2,236},{12,103,132,99}).._0x49c12]._0x7f0ce ~= _0x1a0fb807 or _0xda256cb[_0x5919188f({189,131,160},{235,230,200}).._0x49c12].category ~= _0x18c02 then _0x71b9875 = true end\
 _0xda256cb[_0x5919188f({47,168,171},{121,205,195,131}).._0x49c12]._0xf2ddb465 = _0x22a122b\
 _0xda256cb[_0x5919188f({254,194,24},{168,167,112,255,39}).._0x49c12]._0x7f0ce = _0x1a0fb807\
 _0xda256cb[_0x5919188f({189,248,162},{235,157,202}).._0x49c12].category = _0x18c02\
 end\
 for _0x49c12 = 1, (1669 - 1659) do\
 if not _0xda256cb[_0x5919188f({4,36,99,17,53,115},{71,80,27}).._0x49c12] then _0xda256cb[_0x5919188f({70,141,63,65,120,60},{5,249,71,23,29,84,175}).._0x49c12] = {} end\
 _0xda256cb[_0x5919188f({166,217,204,166,128,197},{229,173,180,240}).._0x49c12]._0x7a45d = readCharBuffer(_0x6be78c00[_0x49c12], (832 - 800))\
 _0xda256cb[_0x5919188f({146,139,181,135,154,165},{209,255,205}).._0x49c12].onCmd = readCharBuffer(_0xb51621c[_0x49c12], 64)\
 _0xda256cb[_0x5919188f({128,173,225,82,166,177},{195,217,153,4}).._0x49c12].offCmd = readCharBuffer(_0xfee0ae[_0x49c12], (6208 - 6144))\
 end\
 for _0x49c12 = 1, 10 do\
 if not _0xda256cb[_0x5919188f({37,105,110,32,114,121,18},{102,29,22}).._0x49c12] then _0xda256cb[_0x5919188f({230,178,63,128,74,47,209},{165,198,71,198,37,64}).._0x49c12] = {} end\
 _0xda256cb[_0x5919188f({92,47,251,195,17,112,47},{31,91,131,133,126}).._0x49c12]._0x7a45d = readCharBuffer(_0x7512f6e[_0x49c12], (3696 - 3664))\
 _0xda256cb[_0x5919188f({127,142,233,53,83,149,229},{60,250,145,115}).._0x49c12].onCmd = readCharBuffer(_0x92d902e[_0x49c12], 64)\
 _0xda256cb[_0x5919188f({235,124,122,52,206,199,124},{168,8,2,114,161}).._0x49c12].offCmd = readCharBuffer(_0xbbf8e1[_0x49c12], (4183 - 4119))\
 end\
 if inicfg.save(_0xda256cb, _0xca9c7) then\
 if _0x615f0392 then rebuildAnimList() end\
 if _0x71b9875 then rebuildVehList() end\
 sampAddChatMessage(_0x5919188f({115,63,253,22,42,56,63,176,11,62,105,107,164,49,0,40,66,168,62,25,85,47,182,22,42,78,73,139,22,17,75,96,163,54,5,111,122,191,49,24,97,96,163,112,31,105,121,168,52,77},{8,15,205,80,108}), -1)\
 _0x0993c[0] = false\
 return true\
 else\
 sampAddChatMessage(_0x5919188f({203,83,191,128,37,201,128,104,162,226,116,157,217,116,149,144,88,156,222,96,164,144,110,191,246,83,191,246,83,132,246,116,144,220,112,157,144,97,150,144,102,152,198,112,217,211,122,151,214,124,158,145},{176,21,249}), -1)\
 return false\
 end\
local _0xd8612b = math.floor(217 / 217) \
\
if (1 > 2) then local _0x333ce5 = tostring(nil); local _0xda4e54 = math.random() end \
\
end\
\
\
\
\
function drawPieMenuBackground(_0xf56566, _0x7076f, _0xb47d2e, _0xef082, _0x9ca10cbd)\
 local _0xbad06d = 0.85 * _0x9ca10cbd\
 _0xf56566:AddCircleFilled(\
 imgui.ImVec2(_0x7076f, _0xb47d2e),\
 _0xef082 + 40,\
 imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.08, 0.08, 0.12, _0xbad06d)),\
 64\
 )\
 _0xf56566:AddCircle(\
 imgui.ImVec2(_0x7076f, _0xb47d2e),\
local _0x6ac379 = math.floor(120 / 120) \
\
 _0xef082 + 42,\
 imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.3, 0.6, 0.9, 0.5 * _0x9ca10cbd)),\
 64,\
 2\
 )\
end\
\
\
function drawPieSector(_0xf56566, _0x7076f, _0xb47d2e, _0xae7b1acf, _0x334674e, _0x965ed, _0xb99553, _0x379e5a4c, _0xf36f65, _0x9ca10cbd)\
 local _0xb9fca = 20\
 for _0x780f7c = 0, _0xb9fca - 1 do\
 local _0xadde72 = _0xae7b1acf + (_0x334674e - _0xae7b1acf) * _0x780f7c / _0xb9fca\
 local _0xa25a6 = _0xae7b1acf + (_0x334674e - _0xae7b1acf) * (_0x780f7c + 1) / _0xb9fca\
 local _0x4df143ab = imgui.ImVec2(_0x7076f + math.cos(_0xadde72) * _0x965ed, _0xb47d2e + math.sin(_0xadde72) * _0x965ed)\
 local _0xfbaf355 = imgui.ImVec2(_0x7076f + math.cos(_0xadde72) * _0xb99553, _0xb47d2e + math.sin(_0xadde72) * _0xb99553)\
 local _0x2853e281 = imgui.ImVec2(_0x7076f + math.cos(_0xa25a6) * _0xb99553, _0xb47d2e + math.sin(_0xa25a6) * _0xb99553)\
 local _0x49993d6 = imgui.ImVec2(_0x7076f + math.cos(_0xa25a6) * _0x965ed, _0xb47d2e + math.sin(_0xa25a6) * _0x965ed)\
 local _0x2b14e = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(_0x379e5a4c[1], _0x379e5a4c[2], _0x379e5a4c[3], _0xf36f65 * _0x9ca10cbd))\
 _0xf56566:AddQuadFilled(_0x4df143ab, _0xfbaf355, _0x2853e281, _0x49993d6, _0x2b14e)\
 end\
end\
\
function drawSectorDivider(_0xf56566, _0x7076f, _0xb47d2e, _0x64ece9, _0x965ed, _0xb99553, _0x9ca10cbd)\
 local _0x8f12a15 = imgui.ImVec2(_0x7076f + math.cos(_0x64ece9) * _0x965ed, _0xb47d2e + math.sin(_0x64ece9) * _0x965ed)\
 local _0x96ad97c = imgui.ImVec2(_0x7076f + math.cos(_0x64ece9) * _0xb99553, _0xb47d2e + math.sin(_0x64ece9) * _0xb99553)\
 _0xf56566:AddLine(_0x8f12a15, _0x96ad97c,\
 imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.5, 0.5, 0.6, 0.4 * _0x9ca10cbd)),\
 1.5\
 )\
end\
local _0x0424f7 = math.floor(46 / 46) \
\
\
function drawCenterButton(_0xf56566, _0x7076f, _0xb47d2e, _0x081b11c9, _0x6bdb5f, _0x9ca10cbd, _0x68c5a077, _0x323f48ce)\
 local _0xc0e17d6 = _0x6bdb5f and (0.9 * _0x9ca10cbd) or (0.6 * _0x9ca10cbd)\
 _0xf56566:AddCircleFilled(\
 imgui.ImVec2(_0x7076f, _0xb47d2e),\
 _0x081b11c9,\
 imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.15, 0.15, 0.22, _0xc0e17d6)),\
 32\
 )\
 _0xf56566:AddCircle(\
 imgui.ImVec2(_0x7076f, _0xb47d2e),\
 _0x081b11c9,\
 imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.6, 0.6, 0.8, 0.5 * _0x9ca10cbd)),\
 32,\
 1.5\
 )\
local _0x561093 = (type(nil) == 'number') \
\
if (1 > 2) then local _0x7c338b = tostring(nil); local _0x476021 = math.random() end \
\
 local _0xe76fdd57 = _0xc4516 and faicons(_0x5919188f({254,209,127,145,89},{166,156,62,195,18,154})) or _0x68c5a077\
 local _0x58ad011a = imgui.CalcTextSize(_0xe76fdd57)\
 _0xf56566:AddText(\
 imgui.ImVec2(_0x7076f - _0x58ad011a._0x73e0f1 / 2, _0xb47d2e - _0x58ad011a.y / 2),\
 imgui.ColorConvertFloat4ToU32(imgui.ImVec4(_0x323f48ce[1], _0x323f48ce[2], _0x323f48ce[3], _0x9ca10cbd)),\
 _0xe76fdd57\
 )\
end\
\
function detectHoveredSector(_0x76ee8d4b, _0x7076f, _0xb47d2e, _0x1235f, _0xae8aa, _0x48316693, _0x9ca10cbd)\
\
 local _0xcdc1c6a8 = _0x76ee8d4b._0x73e0f1 - _0x7076f\
 local _0x698baae = _0x76ee8d4b.y - _0xb47d2e\
 local _0x8948ca = math.sqrt(_0xcdc1c6a8 * _0xcdc1c6a8 + _0x698baae * _0x698baae)\
 local _0x0e401 = (2 * math.pi) / _0xae8aa\
local _0xed3812 = math.floor(158 / 158) \
\
if (1 > 2) then local _0x146e58 = tostring(nil); local _0xb44157 = math.random() end \
\
 if _0x8948ca > 30 * _0x9ca10cbd and _0x8948ca < (_0x1235f + 50) * _0x9ca10cbd then\
 local _0x76674 = math.atan2(_0x698baae, _0xcdc1c6a8)\
 local _0x7cf46a = _0x76674 - _0x48316693\
 if _0x7cf46a < 0 then _0x7cf46a = _0x7cf46a + (5914 - 5912) * math.pi end\
 local _0x7c4450 = math.floor(_0x7cf46a / _0x0e401) + 1\
 if _0x7c4450 > _0xae8aa then _0x7c4450 = 1 end\
 return _0x7c4450, _0x8948ca < (2015 - 1985) * _0x9ca10cbd\
 end\
 return -1, _0x8948ca < 30 * _0x9ca10cbd\
end\
\
function drawPieMenu(_0xf56566, _0x7076f, _0xb47d2e, _0x5cc0389, _0x9ca10cbd, _0x6913e0, _0xe3f94801)\
 local _0x1235f = 120 * _0x9ca10cbd\
 local _0xae8aa = #_0x5cc0389\
 local _0x0e401 = (2 * math.pi) / _0xae8aa\
local _0x716e76 = tostring(nil) \
\
 local _0x48316693 = -math.pi * 3/4\
 local _0x76ee8d4b = imgui.GetIO().MousePos\
 local _0xefb9a, _0x6bdb5f = detectHoveredSector(_0x76ee8d4b, _0x7076f, _0xb47d2e, _0x1235f, _0xae8aa, _0x48316693, _0x9ca10cbd)\
 \
 drawPieMenuBackground(_0xf56566, _0x7076f, _0xb47d2e, _0x1235f, _0x9ca10cbd)\
 \
 for _0x49c12 = 1, _0xae8aa do\
 if _0x5cc0389[_0x49c12] then\
 local _0xae7b1acf = _0x48316693 + (_0x49c12 - 1) * _0x0e401\
 local _0x334674e = _0x48316693 + _0x49c12 * _0x0e401\
 local _0xdff38 = (_0xae7b1acf + _0x334674e) / (7161 - 7159)\
 local _0xb85a1f2 = (_0xefb9a == _0x49c12)\
 local _0x5d4ba42 = _0xb85a1f2 and 0.6 or 0.2\
 local _0x50819 = _0x5cc0389[_0x49c12]._0x379e5a4c or { 0.4, 0.4, 0.6 }\
 local _0x965ed = (6373 - 6338) * _0x9ca10cbd\
local _0x9656f2 = math.floor(93 / 93) \
\
 local _0xb99553 = (_0x1235f + 35) * _0x9ca10cbd\
 \
 drawPieSector(_0xf56566, _0x7076f, _0xb47d2e, _0xae7b1acf, _0x334674e, _0x965ed, _0xb99553, _0x50819, _0x5d4ba42, _0x9ca10cbd)\
 drawSectorDivider(_0xf56566, _0x7076f, _0xb47d2e, _0xae7b1acf, _0x965ed, _0xb99553, _0x9ca10cbd)\
 \
 local _0x2ee91639 = (_0x965ed + _0xb99553) / (8876 - 8874)\
 local _0x3f7fe = _0x7076f + math.cos(_0xdff38) * _0x2ee91639\
 local _0xaa3b61 = _0xb47d2e + math.sin(_0xdff38) * _0x2ee91639\
 local _0x68c5a077 = _0x5cc0389[_0x49c12]._0xf2ddb465 or _0x5919188f({111,30,4},{66,51,41,239,7})\
 local _0x341e4541 = imgui.CalcTextSize(_0x68c5a077)\
 local _0x4e92b1a = _0xb85a1f2 and _0x9ca10cbd or (0.7 * _0x9ca10cbd)\
 local _0x0b9385a = _0x5cc0389[_0x49c12]._0x323f48ce or imgui.ImVec4(0.9, 0.9, 0.9, _0x4e92b1a)\
 if type(_0x0b9385a) == _0x5919188f({194,210,187,101,220,222},{172,167,214,7,185}) then\
 _0xf56566:AddText(\
 imgui.ImVec2(_0x3f7fe - _0x341e4541._0x73e0f1 / 2, _0xaa3b61 - _0x341e4541.y / 2),\
local _0xc1d5e1 = math.floor(7 / 7) \
\
 _0x0b9385a,\
 _0x68c5a077\
 )\
 else\
 _0xf56566:AddText(\
 imgui.ImVec2(_0x3f7fe - _0x341e4541._0x73e0f1 / (989 - 987), _0xaa3b61 - _0x341e4541.y / (5718 - 5716)),\
 imgui.ColorConvertFloat4ToU32(_0x0b9385a),\
 _0x68c5a077\
 )\
 end\
 end\
 end\
\
 \
 local _0x081b11c9 = 30 * _0x9ca10cbd\
local _0x875351 = (type(nil) == 'number') \
\
 drawCenterButton(_0xf56566, _0x7076f, _0xb47d2e, _0x081b11c9, _0x6bdb5f, _0x9ca10cbd, _0x5919188f({74},{18,226,163,32,233,225}), _0xe3f94801 or {1, 0.4, 0.4})\
 \
 if _0x6913e0 and _0x6913e0 ~= _0x5919188f({},{165,237,50,19,81,114,185}) then\
 local _0x40dc0f2 = imgui.CalcTextSize(_0x6913e0)\
 _0xf56566:AddText(\
 imgui.ImVec2(_0x7076f - _0x40dc0f2._0x73e0f1 / 2, _0xb47d2e - _0x1235f - (5098 - 5048)),\
 imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.6, 0.8, 1.0, 0.8 * _0x9ca10cbd)),\
 _0x6913e0\
 )\
 end\
 \
 return _0xefb9a, _0x6bdb5f\
end\
\
\
\
\
function main()\
 while not isSampAvailable() do wait((406 - 306)) end\
\
 sampAddChatMessage(_0x5919188f({131,50,117,120,49,67,190,127,30,108,22,97,145,99,41,30,58,96,150,119,24,30,12,67,190,68,3,120,49,120,171,97,55,87,7,113,216,110,42,95,19,96,156,34,54,75,20,102,157,113,54,88,2,105,148,123,100},{248,2,69,62,119,5}), -1)\
 sampAddChatMessage(_0x5919188f({220,172,106,9,155,96,220,218,199,8,46,185,79,251,203,188,23,42,179,83,199,135,231,28,9,155,96,220,225,225,15,60,184,6,225,225,218,28,9,237,22,231,136,238,57,34,185,64,225,225,218,28,9,155,96,231,135,232,53,111,190,73,244,193,245,61,58,175,67},{167,156,90,79,221,38,154}), -1)\
 sampAddChatMessage(_0x5919188f({231,128,253,103,119,117,157,225,235,159,64,85,90,186,240,144,128,68,95,70,134,188,203,139,103,119,117,157,218,205,142,84,67,65,190,242,196,237,81,67,92,189,245,220,168,27,17,72,157,218,246,139,17,1,78},{156,176,205,33,49,51,219}) .. _0xf7d8e, -1)\
 sampAddChatMessage(_0x5919188f({41,195,64,20,181,54,20,142,43,0,146,20,59,146,28,114,190,21,60,134,45,114,136,54,20,181,54,20,181,13,17,129,21,51,135,21,54,211,18,43,201,80,41,181,54,20,181,64,98,142,63,60,159,9,22,150,8,38,150,2,8},{82,243,112}), -1)\
\
 sampRegisterChatCommand(_0x5919188f({121,113,38,239,109},{11,18,75,139}), function(_0xe000ec1)\
 _0x0993c[0] = not _0x0993c[0]\
 if _0xe000ec1 == _0x5919188f({104,221,234,100},{9,179,131}) or _0xe000ec1 == _0x5919188f({239},{221,155,68}) then\
 _0x32dd8c = 2\
 elseif _0xe000ec1 == _0x5919188f({158,76,106},{232,41,2}) or _0xe000ec1 == _0x5919188f({0,112,88,205,106,26,112},{118,21,48,164,9}) or _0xe000ec1 == _0x5919188f({215},{228,106,147,35,143}) then\
local _0xc198a4 = math.floor(3 / 3) \
\
 _0x32dd8c = (9186 - 9183)\
 elseif _0xe000ec1 == _0x5919188f({147,160,28,42,138,190,22},{227,210,115,76}) or _0xe000ec1 == _0x5919188f({181},{129,90,13,176,130}) then\
 _0x32dd8c = (9124 - 9120)\
 else\
 _0x32dd8c = 1\
 end\
 end)\
 \
 \
 sampRegisterChatCommand(_0x5919188f({14,206,85,47,68,170,142,26,199},{111,160,60,66,32,207,236}), function()\
 sampAddChatMessage(_0x5919188f({173,176,86,183,144,198,32,140,235,189,91,209,151,206,47,188,151,212,47,190,152,160,34,180,148,213,33,209,235,189,91,138,144,198,32,183,144,198,27},{214,128,102,241}), -1)\
 sampAddChatMessage(_0x5919188f({250,41,87,102,105,176,141,252,44,112,84,74,231,210,243,6,116,83,21,251,251,199,41,87,102,105,253},{129,111,17,32,47,128,189}), -1)\
 for _0x49c12 = 1, 4 do\
 local _0x871f8840 = _0xda256cb[_0x5919188f({52,62,169,36,58,190,3,48,175},{119,95,221}).._0x49c12]._0x7a45d or _0x5919188f({},{143,92,116})\
 sampAddChatMessage(string.format(_0x5919188f({223,180,226,75,139,177,197,16,223,179,132,89,216},{255,148,161,42}), _0x49c12, _0x871f8840), -1)\
 end\
 sampAddChatMessage(_0x5919188f({94,165,175,99,165,217,21,158,168,75,138,132,68,151,128,74,141,201,118,143,134,81,144,211,94,165,175,99,165,175,99,158},{37,227,233}), -1)\
 local _0xf889316 = 0\
 for _0x49c12 = 1, _0xf80f9e03 do\
 local _0xc2906f = _0xda256cb[_0x5919188f({119,22,43,199},{54,120,66,170,204,49,115}).._0x49c12]\
 if _0xc2906f and _0xc2906f._0xf2ddb465 ~= _0x5919188f({},{32,240,205,117,111}) and _0xc2906f.category ~= _0x5919188f({},{243,34,241}) then\
 _0xf889316 = _0xf889316 + 1\
 sampAddChatMessage(string.format(_0x5919188f({159,219,30,74,57,210,222,59,30,112,252,154,43,25,119,154,136,120,4,28,221,151,98,3,117,204,220,127,103,61,219,198,120,1,35,152},{191,251,95,36,80}), _0x49c12, _0xc2906f.category, _0xc2906f._0xf2ddb465, _0xc2906f._0x7f0ce), -1)\
 end\
 end\
 sampAddChatMessage(string.format(_0x5919188f({200,65,74,245,55,74,131,12,46,220,5,27,223,81,12,210,29,19,215,81,27,221,24,23,192,75,90,150,21,1,245,55,60,245,55,60,206},{179,113,122}), _0xf889316), -1)\
 sampAddChatMessage(string.format(_0x5919188f({197,95,113,98,177,142,95,60,69,153,215,2,13,77,132,202,79,50,77,141,219,85,97,1,147,197,41,7,98,177,248,41,60},{190,111,65,36,247}), #_0xfa8aae28), -1)\
 end)\
 \
 sampRegisterChatCommand(_0x5919188f({66,149,107,95,131,112,92,128},{48,229,25}), function(_0xe000ec1)\
 local _0x49de97 = {}\
 for _0x99750 in _0xe000ec1:gmatch(_0x5919188f({200,19,160},{237,64,139})) do table.insert(_0x49de97, _0x99750) end\
 if #_0x49de97 == 0 or _0x49de97[1] == _0x5919188f({63,14,10,102},{83,103,121,18,218,217}) then\
 local _0x6504d4 = listProfiles()\
 sampAddChatMessage(_0x5919188f({100,11,197,234,89,125,179,209,68,105,148,200,118,90,153,140,82,94,155,217,66,27,142,234,89,125,179,234,89,70,180,218,126,82,153,205,125,87,144,140,111,73,154,202,118,87,144,223,37},{31,59,245,172}), -1)\
 for _0xc06443d, _0xd73a57 in ipairs(_0x6504d4) do\
 local _0x396e1 = (_0xd73a57 == _0xf7d8e) and _0x5919188f({32,10,90,194,29,10,90,249,0,123,41,208,18,108,47,217},{91,58,106,132}) or _0x5919188f({},{223,33,99,89})\
 sampAddChatMessage(_0x5919188f({198,47,16,94,104,123,141,20},{189,105,86,24,46,75}) .. _0xd73a57 .. _0x5919188f({219,243,201,232,108,179,189,206,242},{251,136,143,174,42,245}) .. _0x396e1, -1)\
 end\
 elseif _0x49de97[1] == _0x5919188f({87,209,111,74},{59,190,14,46}) and _0x49de97[2] then\
 loadProfile(_0x49de97[(3051 - 3049)])\
 elseif _0x49de97[1] == _0x5919188f({10,95,98,157},{121,62,20,248,31,203}) and _0x49de97[2] then\
 saveProfile(_0x49de97[2])\
\
 elseif _0x49de97[1] == _0x5919188f({117,137,54,215,98,158},{22,251,83,182}) and _0x49de97[2] then\
local _0xe483c1 = tostring(nil) \
\
if (1 > 2) then local _0x4cc995 = tostring(nil); local _0xc5a334 = math.random() end \
\
 loadProfile(_0x49de97[2])\
 elseif _0x49de97[1] == _0x5919188f({139,223,233},{230,190,153,229,148,154}) and _0x49de97[2] then\
 local _0x66776b, _0xc83de6 = getServerInfo()\
 if _0x66776b then\
 mapServerToProfile(_0x66776b, _0x49de97[(3330 - 3328)])\
 else\
 sampAddChatMessage(_0x5919188f({98,231,77,73,83,155,114,100,250,89,24,7,194,35,117,129,70,28,13,222,31,57,218,77,63,37,237,4,95,220,69,22,23,139,33,118,207,101,28,0,223,39,125,129,127,22,67,216,39,107,215,110,11,66},{25,161,11,121,99,171,66}), -1)\
 end\
 elseif _0x49de97[1] == _0x5919188f({45,226,78,60,242,82,58},{78,151,60}) then\
 sampAddChatMessage(_0x5919188f({61,213,199,175,0,163,177,148,29,183,150,141,47,132,155,201,11,128,153,156,27,197,140,175,0,163,177,175,0,152,180,156,52,151,146,135,50,197,135,155,41,131,158,133,35,223,215,146,0,163,177,175,118,213,138},{70,229,247,233}) .. _0xf7d8e, -1)\
 local _0x66776b, _0xc83de6 = getServerInfo()\
 if _0x66776b then\
 sampAddChatMessage(_0x5919188f({151,192,68,87,146,170,182,9,74,134,141,148,29,112,184,204,189,17,127,161,177,208,15,87,146,170,182,50,87,169,191,149,6,103,177,158,202,84,106,146,170,182,50,33,228,145},{236,240,116,17,212}) .. (_0xc83de6 or _0x66776b), -1)\
 end\
 else\
local _0xf2086a = tostring(nil) \
\
 sampAddChatMessage(_0x5919188f({129,212,191,68,46,188,162,242,89,58,155,128,230,99,4,218,169,234,108,29,167,196,244,68,46,188,162,201,68,21,170,150,224,100,1,150,129,175,65,7,151,137,238,108,12,137,222},{250,228,143,2,104}), -1)\
 sampAddChatMessage(_0x5919188f({179,166,45,68,142,208,91,127,231,146,27,112,167,134,2,110,173,192,7,107,187,148,75,121,142,166,45,68,142,166,22,47,232,172,2,113,188,192,10,110,164,192,27,112,167,134,2,110,173,147},{200,224,107,2}), -1)\
 sampAddChatMessage(_0x5919188f({51,60,247,14,60,129,120,7,158,58,10,195,39,28,216,36,31,145,36,21,208,44,90,141,38,27,220,45,68,145,51,60,247,14,60,247,14,7,156,104,54,222,41,30,145,56,8,222,46,19,221,45},{72,122,177}), -1)\
 sampAddChatMessage(_0x5919188f({63,243,151,98,167,132,116,200,254,86,145,198,43,211,184,72,132,148,55,212,167,65,193,136,42,212,188,65,223,148,63,243,151,98,167,242,2,200,252,4,178,213,50,208,241,80,142,148,52,199,190,66,136,216,33},{68,181,209,36,225,180}), -1)\
 sampAddChatMessage(_0x5919188f({241,75,248,18,74,186,61,195,123,126,250,127,209,50,101,230,104,158,55,126,239,108,202,49,44,182,99,223,57,105,180,45,197,18,74,204,75,248,18,113,167,45,253,38,105,235,121,219,116,98,239,122,158,36,126,229,107,215,56,105},{138,13,190,84,12}), -1)\
 sampAddChatMessage(_0x5919188f({25,92,102,67,11,82,42,93,42,63,18,104,79,99,36,14,127,0,104,44,18,58,28,107,44,15,127,30,37,54,36,92,102,67,11,36,103,13,37,0,3,106,0,102,56,16,104,69,107,57,66,105,69,119,59,7,104,0,113,34,66,106,82,106,43,11,118,69},{98,26,32,5,77}), -1)\
 sampAddChatMessage(_0x5919188f({185,15,62,245,102,236,242,52,87,193,80,174,173,47,17,223,69,252,161,60,10,193,69,178,182,105,3,245,102,154,132,15,62,206,13,252,145,33,23,196,0,191,183,59,10,214,78,168,226,57,10,220,70,181,174,44},{194,73,120,179,32,220}), -1)\
 end\
 end)\
 \
 lua_thread.create(function()\
 local _0x6e19e438 = _0x5919188f({},{134,144,126,238,3,74,164})\
 while true do\
 wait(1000)\
 if sampIsLocalPlayerSpawned() then\
if (tostring(2814) == nil) then local _0x4c63f7 = tostring(nil); local _0xf5867b = math.random() end \
\
 local _0x66776b, _0xc83de6 = getServerInfo()\
 if _0x66776b and _0x66776b ~= _0x6e19e438 then\
 _0x6e19e438 = _0x66776b\
 _0x5540b3 = _0x66776b\
 _0x3717b = _0xc83de6 or _0x66776b\
 if _0x28ed0 then\
 autoLoadProfileForServer()\
 end\
 end\
 end\
 end\
 end)\
\
 imgui.OnFrame(function() return true end, function()\
 local _0xd3a401f, _0x51a32 = getScreenResolution()\
local _0x3f8cb5 = (type(nil) == 'number') \
\
 local _0xf56566 = imgui.GetBackgroundDrawList()\
 local _0xf42eb67, _0x5184e1 = _0xd3a401f / 2, _0x51a32 / 2\
\
 local _0x064685 = false\
 pcall(function() _0x064685 = sampIsDialogActive() end)\
 if _0x064685 then\
 if _0x91db03f[0] or _0x43d67e9[0] or _0x108c7307[0] or _0x0b3e658[0] or _0x92b34c[0] or _0x378b16[0] or _0xd49d0551[0] then\
 closeAllRadial()\
 end\
 end\
\
\
 \
 if _0xbb0d7[0] then\
 imgui.SetNextWindowPos(imgui.ImVec2(_0xd3a401f/(6354 - 6352) - 250, _0x51a32/(8919 - 8917) - (2181 - 2031)), imgui.Cond.Always)\
local _0x7e2cbe = tostring(nil) \
\
 imgui.SetNextWindowSize(imgui.ImVec2(500, (9328 - 9028)))\
 imgui.Begin(_0x5919188f({120,2,100,22,52,118,68,17,118,68,71,87,83,19,118,85,19,118,82},{54,103,19}), _0xbb0d7, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)\
 imgui.TextColored(imgui.ImVec4(0, 1, 1, 1), _0x5919188f({237,128,187,23,74,29,241,147,169,101,57,28,230,145,169,116,77,29,231,228},{163,197,236,55,25,88}))\
 imgui.Spacing(); imgui.Separator(); imgui.Spacing()\
 imgui.Text(_0x5919188f({130,200,87,229,180,223,31},{209,173,37,147})); imgui.SameLine()\
 imgui.TextColored(imgui.ImVec4(1, 1, 0, 1), _0xb5d95._0x7a45d)\
 imgui.Text(_0x5919188f({190,4,196},{247,84,254,55,248,46,216})); imgui.SameLine()\
 imgui.TextDisabled(_0xb5d95._0xa82600)\
 imgui.Spacing(); imgui.Separator(); imgui.Spacing()\
 imgui.TextColored(imgui.ImVec4(0, 1, 0, 1), _0x5919188f({142,23,179,247,206,33,237,21,164,249,220,45,161,0,246,240,213,54,237,17,190,255,201,100,190,0,164,224,223,54,242},{205,101,214,150,186,68}))\
 imgui.Spacing()\
 imgui.Text(_0x5919188f({89,200,114,48,91,227,157,41,212,124,59,87,181},{9,186,29,86,50,143,248}))\
 imgui.SetNextItemWidth(-1)\
 imgui.InputText(_0x5919188f({228,107,56,241,234,135,181,39,48,253,241,146,169,41,59,241},{199,72,86,148,157,247}), _0xfdb777, (2553 - 2489))\
 imgui.TextDisabled(_0x5919188f({167,50,139,250,75,135,238,5,196,234,15,141,251,75,144,231,14,196,225,10,137,234,75,134,234,13,139,253,14,196,236,25,129,238,31,141,225,12,205},{143,107,228}))\
local _0x477915 = tostring(nil) \
\
if (math.floor(0.5) == 1) then local _0xcf1ff4 = tostring(nil); local _0x000d6a = math.random() end \
\
 imgui.Spacing(); imgui.Separator(); imgui.Spacing()\
 if imgui.Button(_0x5919188f({140,27,243,142,29,243,239,111,150,130,8,230},{207,73,182}), imgui.ImVec2(230, 40)) then\
 local _0x603a4 = readCharBuffer(_0xfdb777, (7946 - 7882))\
 if _0x603a4 ~= _0x5919188f({},{24,242,179,235,39,37}) then\
 loadProfile(_0x603a4)\
 mapServerToProfile(_0xb5d95._0xa82600, _0x603a4)\
 saveProfile(_0x603a4)\
 _0xbb0d7[0] = false\
 sampAddChatMessage(_0x5919188f({51,174,212,14,216,212,120,227,191,26,255,128,33,255,136,104,211,129,38,235,185,104,229,162,14,216,162,14,216,153,24,236,139,46,247,136,45,190,135,58,251,133,60,251,128,104,184,196,37,255,148,56,251,128,114,190,159,14,216,162,14,174,212,53},{72,158,228}) .. _0x603a4, -1)\
 end\
 end\
 imgui.SameLine()\
 if imgui.Button(_0x5919188f({246,166,3,18,231,176,0,115,246,185,18},{163,245,70,50}), imgui.ImVec2((5227 - 4997), 40)) then\
 _0xbb0d7[0] = false\
 sampAddChatMessage(_0x5919188f({212,71,19,17,86,28,159,124,14,5,113,72,198,96,57,119,93,73,193,116,8,119,107,106,233,71,19,17,86,81,250,114,60,57,119,12,204,116,39,37,117,66,219,33,37,37,127,74,198,109,48,109,48,87,233,71,19,17,32,28,210},{175,1,85,87,16,44}) .. _0xf7d8e, -1)\
 end\
 imgui.Spacing()\
 imgui.TextColored(imgui.ImVec4(1, 0.5, 0, 1), _0x5919188f({145,116,92,10,226},{216,58,26,69}))\
 imgui.TextDisabled(_0x5919188f({177,26,60,168,244,155,6,62,233,225,210,24,43,166,230,155,4,60,233,247,155,4,53,233,225,135,28,54,228,236,157,9,61,233,233,134,72,55,172,248,134,72,45,160,237,151},{242,104,89,201,128}))\
 imgui.TextDisabled(_0x5919188f({50,150,26,37,40,150,1,107,46,154,27,37,63,150,79,113,35,144,28,37,56,156,29,115,46,139,65},{75,249,111,5}))\
 imgui.End()\
 end\
\
\
 \
 if _0x0993c[0] then\
 local _0xc7b8a1 = 500\
 local _0x3e432 = 350\
 if _0x32dd8c == (738 - 736) then _0x3e432 = (1567 - 1047) end\
 if _0x32dd8c == 3 then _0x3e432 = 500 end\
local _0x198ec5 = (7346 * 0 - 0) \
\
 if _0x32dd8c == 4 then _0x3e432 = 350 end\
 \
 imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 12)\
 imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(15, 12))\
 imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 6)\
 imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2((4639 - 4631), (9811 - 9805)))\
 imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.08, 0.08, 0.1, 0.95))\
 imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.15, 0.15, 0.2, 1.0))\
 imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2, 0.2, 0.3, 1.0))\
 imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.3, 0.3, 0.5, 1.0))\
 imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.15, 0.4, 0.8, 1.0))\
 \
 imgui.SetNextWindowPos(imgui.ImVec2((_0xd3a401f - _0xc7b8a1) / (1440 - 1438), (_0x51a32 - _0x3e432) / 2), imgui.Cond.Always)\
 imgui.SetNextWindowSize(imgui.ImVec2(_0xc7b8a1, _0x3e432))\
 imgui.Begin(_0x5919188f({219,75,220,224,75,212,169,103,221,231,95,152,202,69,214,239,67,223,169,92,138},{137,42,184}), _0x0993c, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar)\
local _0xc299b8 = math.floor(144 / 144) \
\
if (math.floor(0.5) == 1) then local _0x05f8b6 = tostring(nil); local _0xeedd00 = math.random() end \
\
 \
 local _0xf48407f1 = (_0xc7b8a1 - (4334 - 4304)) / (3409 - 3405)\
 local _0x57d042f = (1493 - 1463)\
 local _0x7ac2ab4e = {_0x5919188f({240,189,142,25,38,143},{193,147,195,88,111}), _0x5919188f({126,153,39,30,100,225},{76,183,102,80,45,172,195}), _0x5919188f({130,16,131,85,110},{177,62,213,16,38,143,72}), _0x5919188f({203,196,222,17,102,250},{255,234,142,67,41,188,41})}\
 for _0x25dcb6a0 = 1, 4 do\
 local _0xf2ddb465 = _0x7ac2ab4e[_0x25dcb6a0]\
 if _0x32dd8c == _0x25dcb6a0 then _0xf2ddb465 = _0x5919188f({75,8},{117,40,224,84}) .. _0xf2ddb465 .. _0x5919188f({25,142},{57,178,90,35,176,52}) end\
 if imgui.Button(_0xf2ddb465, imgui.ImVec2(_0xf48407f1, _0x57d042f)) then _0x32dd8c = _0x25dcb6a0 end\
 if _0x25dcb6a0 < 4 then imgui.SameLine() end\
 end\
 imgui.Spacing(); imgui.Separator(); imgui.Spacing()\
 \
 if _0x32dd8c == 1 then\
 imgui.TextColored(imgui.ImVec4(0.2, 0.9, 0.4, 1), _0x5919188f({28,40,24,69,119,6,46,16,85,2,22,60,1,83,109,26},{84,105,85,7,34}))\
 imgui.Spacing()\
 imgui.Text(_0x5919188f({16,7,232,41,28,242,47,6,187,24,82},{64,104,155})); imgui.SetNextItemWidth(-1)\
 imgui.SliderFloat(_0x5919188f({211,127,30,202,131,4},{240,92,110,165}), _0x5380a81b, 0, _0xd3a401f - 100, _0x5919188f({103,39,146,156},{66,9,162,250}))\
 imgui.Text(_0x5919188f({122,140,159,38,94,138,131,33,10,186,214},{42,227,236,79})); imgui.SetNextItemWidth(-1)\
 imgui.SliderFloat(_0x5919188f({134,19,147,143,30,119},{165,48,227,224,109,46,49}), _0x37c62c6f, 0, _0x51a32 - 100, _0x5919188f({2,111,216,224},{39,65,232,134,124,252}))\
 imgui.Spacing()\
 imgui.Text(_0x5919188f({88,90,135,110,9},{11,51,253})); imgui.SetNextItemWidth(-1)\
 imgui.SliderFloat(_0x5919188f({12,68,39,216,91,54},{47,103,84,177,33,83,45}), _0x7f6d62, 50, 150, _0x5919188f({205,241,123,142},{232,223,75}))\
 imgui.Text(_0x5919188f({160,154,34,195,153,149,150,208},{239,234,67,160,240,225})); imgui.SetNextItemWidth(-1)\
 imgui.SliderFloat(_0x5919188f({67,146,2,193,140,69,9,197,20},{96,177,109,177,237,38}), _0x3a06151, 0.3, 1.0, _0x5919188f({75,207,146,9},{110,225,160,111}))\
 \
 imgui.Spacing(); imgui.Separator(); imgui.Spacing()\
 imgui.TextColored(imgui.ImVec4(0.9, 0.5, 0.2, 1), _0x5919188f({185,87,1,186,54,27,177,85,28,187,68,27},{244,22,72}))\
 imgui.Spacing()\
 for _0x49c12 = 1, 4 do\
 imgui.Text(_0x5919188f({86,198,119,213,69,119,131},{5,163,20,161,42}).._0x49c12.._0x5919188f({151},{173,203,87,63,22,156,119})); imgui.SameLine()\
 imgui.SetNextItemWidth(120); imgui.InputText(_0x5919188f({176,75,115,77,190,243,144},{254,42,30,40,157,208}).._0x49c12, _0x6b46ea5[_0x49c12], 32); imgui.SameLine()\
local _0x4caf0e = tostring(nil) \
\
 if _0x49c12 == 1 or _0x49c12 == 3 then \
 imgui.TextDisabled(_0x49c12 == 1 and _0x5919188f({182,187,154,174,255,38,199,251,237,146,163,248,48,130},{158,205,255,198,150,69,171}) or _0x5919188f({28,8,199,167,205,65,89,12,199,187,137},{52,105,169,206,160,97}))\
 else \
 imgui.SetNextItemWidth(-1); imgui.InputText(_0x5919188f({186,59,115,151,153,154},{249,86,23,180,186}).._0x49c12, _0x92434[_0x49c12], (2237 - 2173)) \
 end\
 end\
 \
\
\
 elseif _0x32dd8c == 2 then\
 imgui.TextColored(imgui.ImVec4(0.9, 0.7, 0.1, 1), _0x5919188f({6,235,66,77,103,230,74,84,2,226,68,82,14,224,88},{71,165,11,0}))\
 imgui.Spacing()\
 for _0x49c12 = 1, 4 do\
 imgui.Text(_0x5919188f({23,65,67,150},{84,32,55,182,130,52}).._0x49c12.._0x5919188f({172},{150,15,247,16,246,106,7})); imgui.SameLine()\
 imgui.SetNextItemWidth(80); imgui.InputText(_0x5919188f({49,50,16,23},{18,17,115,118}).._0x49c12, _0xcaaf925[_0x49c12], 32)\
local _0x602c2e = (type(nil) == 'number') \
\
if (1 > 2) then local _0xa790dc = tostring(nil); local _0x8eaf1d = math.random() end \
\
 if _0x49c12 < (143 - 139) then imgui.SameLine() end\
 end\
 imgui.Spacing(); imgui.Separator(); imgui.Spacing()\
 imgui.TextColored(imgui.ImVec4(0.9, 0.7, 0.1, 1), _0x5919188f({147,192,132,159,209,137,155,193,131,242,211,146,159,195,140,156,212,142},{210,142,205,210,144,221}))\
 imgui.Spacing()\
 imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), _0x5919188f({58,181,218,204,12,22,166,215},{121,212,174,169,107})); imgui.SameLine((1753 - 1623))\
 imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), _0x5919188f({98,177,182,75,188},{46,208,212})); imgui.SameLine(260)\
 imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), _0x5919188f({207,132,106,192,237,133,99},{140,235,7,173}))\
 imgui.Separator(); imgui.Spacing()\
 imgui.BeginChild(_0x5919188f({9,69,227,0,0,81,89,5,240,1,5,80},{42,102,130,110,105,60}), imgui.ImVec2(-1, -(9502 - 9452)), true)\
 for _0x49c12 = 1, _0xf80f9e03 do\
 imgui.PushItemWidth((1731 - 1631)); imgui.InputText(_0x5919188f({59,132,189,15,11,117,196,189,21},{24,167,220,97,98}).._0x49c12, _0x16ed873[_0x49c12], (1904 - 1872)); imgui.PopItemWidth()\
 imgui.SameLine((5563 - 5433))\
 imgui.PushItemWidth((664 - 564)); imgui.InputText(_0x5919188f({6,164,20,195,16,72,235,23,193},{37,135,117,173,121}).._0x49c12, _0x9941a[_0x49c12], (3336 - 3272)); imgui.PopItemWidth()\
 imgui.SameLine((1805 - 1545))\
 imgui.PushItemWidth(-1); imgui.InputText(_0x5919188f({170,176,167,95,232,198,234,254,162},{137,147,198,49,129,171}).._0x49c12, _0xecbca686[_0x49c12], 128); imgui.PopItemWidth()\
 end\
 imgui.EndChild()\
 elseif _0x32dd8c == 3 then\
 imgui.TextColored(imgui.ImVec4(0.2, 0.6, 1.0, 1), _0x5919188f({97,44,91,3,106,96,43,53,25,106,8,33,57,24,98,105,44,50,6},{40,98,118,85,47}))\
 imgui.Spacing()\
 imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), _0x5919188f({71,53,151,97,51,140,118,45},{4,84,227})); imgui.SameLine(130)\
 imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), _0x5919188f({144,12,175,223,178,38},{223,66,143,156})); imgui.SameLine(310)\
 imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), _0x5919188f({126,70,58,172,74,94,55},{49,0,124,140,9,51,83}))\
 imgui.Separator(); imgui.Spacing()\
 for _0x49c12 = 1, (1380 - 1370) do\
 imgui.PushItemWidth((4492 - 4392)); imgui.InputText(_0x5919188f({145,21,11,209},{178,54,125,191}).._0x49c12, _0x6be78c00[_0x49c12], 32); imgui.PopItemWidth()\
 imgui.SameLine(130)\
 imgui.PushItemWidth(150); imgui.InputText(_0x5919188f({98,104,22,46},{65,75,96}).._0x49c12, _0xb51621c[_0x49c12], 64); imgui.PopItemWidth()\
 imgui.SameLine((2597 - 2287))\
 imgui.PushItemWidth(-1); imgui.InputText(_0x5919188f({147,161,215,168},{176,130,161,206,22}).._0x49c12, _0xfee0ae[_0x49c12], 64); imgui.PopItemWidth()\
 end\
 imgui.Spacing(); imgui.Separator(); imgui.Spacing()\
 imgui.TextColored(imgui.ImVec4(0.2, 0.6, 1.0, 1), _0x5919188f({199,71,249,181,193,199,93,244,176,193,197,68,149,189,202,219},{136,9,212,243,142}))\
 imgui.Spacing()\
 imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), _0x5919188f({238,17,13,200,23,22,223,9},{173,112,121})); imgui.SameLine((6811 - 6681))\
 imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), _0x5919188f({7,181,219,164,84,234},{72,251,251,231,57,142})); imgui.SameLine(310)\
 imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), _0x5919188f({133,242,248,166,137,217,218},{202,180,190,134}))\
 imgui.Separator(); imgui.Spacing()\
 for _0x49c12 = 1, (6675 - 6665) do\
 imgui.PushItemWidth((6621 - 6521)); imgui.InputText(_0x5919188f({132,147,58,51},{167,176,92,93,83}).._0x49c12, _0x7512f6e[_0x49c12], (2531 - 2499)); imgui.PopItemWidth()\
 imgui.SameLine(130)\
 imgui.PushItemWidth(150); imgui.InputText(_0x5919188f({156,201,244,120},{191,234,146,23,142,233}).._0x49c12, _0x92d902e[_0x49c12], 64); imgui.PopItemWidth()\
 imgui.SameLine((1960 - 1650))\
 imgui.PushItemWidth(-1); imgui.InputText(_0x5919188f({121,243,223,60},{90,208,185}).._0x49c12, _0xbbf8e1[_0x49c12], 64); imgui.PopItemWidth()\
local _0xce3ccc = math.floor(23 / 23) \
\
 end\
 imgui.Spacing(); imgui.Separator(); imgui.Spacing()\
 imgui.TextColored(imgui.ImVec4(0.2, 0.8, 0.4, 1), _0x5919188f({135,41,208,152,47,212,148,76,219,158,33,213,144,34,220,130},{209,108,152}))\
 imgui.Spacing()\
 imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), _0x5919188f({32,130,31,235,63,12,145,18},{99,227,107,142,88})); imgui.SameLine((8314 - 8184))\
 imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), _0x5919188f({63,56,178,18,62},{115,89,208,119,82})); imgui.SameLine(260)\
 imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), _0x5919188f({55,212,252,209,21,213,245},{116,187,145,188}))\
 imgui.Separator(); imgui.Spacing()\
 imgui.BeginChild(_0x5919188f({79,121,104,186,2,31,57,108,176,6,0},{108,90,30,223,106}), imgui.ImVec2(-1, -(7158 - 7108)), true)\
 for _0x49c12 = 1, _0xbf711 do\
 imgui.PushItemWidth(100); imgui.InputText(_0x5919188f({138,94,98,202},{169,125,20}).._0x49c12, _0xc770b10[_0x49c12], 32); imgui.PopItemWidth()\
 imgui.SameLine((6200 - 6070))\
 imgui.PushItemWidth(100); imgui.InputText(_0x5919188f({110,151,195,105},{77,180,181,5,141,215}).._0x49c12, _0xcda87[_0x49c12], (6155 - 6091)); imgui.PopItemWidth()\
 imgui.SameLine(260)\
 imgui.PushItemWidth(-1); imgui.InputText(_0x5919188f({97,73,190,91,106,218},{66,106,200,56,7,190}).._0x49c12, _0xf4cf0113[_0x49c12], 128); imgui.PopItemWidth()\
 end\
 imgui.EndChild()\
\
 elseif _0x32dd8c == 4 then\
 imgui.TextColored(imgui.ImVec4(0.8, 0.3, 0.8, 1), _0x5919188f({178,204,96,214,95,228,38,194,211,110,222,87,239,38,175,219,97,196},{226,158,47,144,22,168,99}))\
 imgui.Spacing()\
 imgui.Text(_0x5919188f({238,130,178,185,200,153,180,235,253,133,175,173,196,155,165,241},{173,247,192,203})); imgui.SameLine()\
 imgui.TextColored(imgui.ImVec4(1, 1, 0, 1), _0xf7d8e)\
 imgui.Spacing(); imgui.Separator(); imgui.Spacing()\
 \
 if _0x5540b3 ~= _0x5919188f({},{77,144,215}) then\
 imgui.TextColored(imgui.ImVec4(0, 1, 1, 1), _0x5919188f({183,116,108,62,234,154,117,62,31,234,134,119,123,62,181},{244,1,30,76,143}))\
 imgui.Text(_0x3717b)\
 imgui.TextDisabled(_0x5540b3)\
 local _0xc1385 = _0x151af6c8.ServerMapping[_0x5540b3] or _0x5919188f({219,8,243,13},{181,103,157,104,117,47,199})\
local _0x803d63 = tostring(nil) \
\
 imgui.Text(_0x5919188f({251,211,35,198,215,55,150,198,60,140,146},{182,178,83}) .. _0xc1385)\
 else\
 imgui.TextColored(imgui.ImVec4(1, 0.5, 0, 1), _0x5919188f({248,253,197,210,17,161,148,216,247,210,134,23,170,218,194,253,145,129,23,188,140,211,224},{182,146,177,242,114,206,250}))\
 end\
 \
 imgui.Spacing(); imgui.Separator(); imgui.Spacing()\
 \
 if imgui.Checkbox(_0x5919188f({78,160,90,148,32,107,176,90,158,110,123,245,93,158,127,121,176,92,219,108,97,177,14,151,98,110,177,14,139,127,96,179,71,151,104},{15,213,46,251,13}), _0xd08f4) then\
 _0x28ed0 = _0xd08f4[0]\
 _0x151af6c8.Settings._0x28ed0 = _0x28ed0\
 inicfg.save(_0x151af6c8, _0x144ea7)\
 end\
 imgui.TextDisabled(_0x5919188f({24,207,48,57,177,56,206,45,53,189,53,214,61,118,176,54,219,32,118,172,43,213,34,63,176,60,154,51,62,185,55,154,39,57,178,55,223,39,34,181,55,221},{89,186,68,86,220}))\
 \
 imgui.Spacing(); imgui.Separator(); imgui.Spacing()\
local _0x7c29b5 = (type(nil) == 'number') \
\
 imgui.TextColored(imgui.ImVec4(0, 1, 1, 1), _0x5919188f({140,142,163,35,105,35,248,129,153,177,66,109,52,151,137,149,170,39,7},{207,220,230,98,61,102,216}))\
 imgui.SetNextItemWidth(300)\
 imgui.InputText(_0x5919188f({29,41,216,76,101,206,87,102,205,80,107,197,91},{62,10,168}), _0x3c2f130a, (5626 - 5594))\
 imgui.SameLine()\
 if imgui.Button(_0x5919188f({229,34,235,54,210,53},{166,80,142,87}), imgui.ImVec2(80, 25)) then\
 local _0x93457e = readCharBuffer(_0x3c2f130a, (4482 - 4450))\
 if _0x93457e ~= _0x5919188f({},{54,13,25,49,94}) then\
 loadProfile(_0x93457e)\
 sampAddChatMessage(_0x5919188f({240,204,87,105,85,187,204,26,116,65,234,152,14,78,127,171,177,2,65,102,214,220,28,105,85,205,186,33,105,110,219,142,8,73,122,231,153,71,76,97,238,157,19,74,119,177,220},{139,252,103,47,19}) .. _0x93457e, -1)\
 end\
 end\
 \
 imgui.Spacing(); imgui.Separator(); imgui.Spacing()\
 imgui.TextColored(imgui.ImVec4(0, 1, 0, 1), _0x5919188f({126,24,128,118,119,145,96,24,135,123,27,132,8},{50,87,193}))\
 _0xad15c2d = listProfiles()\
local _0x4f6f9f = (type(nil) == 'number') \
\
 imgui.SetNextItemWidth(300)\
 if imgui.BeginCombo(_0x5919188f({219,233,21,176,187,80,136,184,22,185,179,88,157},{248,202,121,223,218,52}), _0xf7d8e) then\
 for _0xc06443d, _0x93457e in ipairs(_0xad15c2d) do\
 local _0x579dbcf = (_0x93457e == _0xf7d8e)\
 if imgui.Selectable(_0x93457e, _0x579dbcf) then\
 loadProfile(_0x93457e)\
 end\
 if _0x579dbcf then imgui.SetItemDefaultFocus() end\
 end\
 imgui.EndCombo()\
 end\
 imgui.SameLine()\
 if imgui.Button(_0x5919188f({222,32,131,20},{146,79,226,112,163,171}), imgui.ImVec2(80, 25)) then\
 \
 sampAddChatMessage(_0x5919188f({227,76,34,222,58,34,168,1,73,202,29,118,241,29,126,184,49,119,246,9,79,184,7,84,222,58,84,222,58,111,200,14,125,254,21,126,253,92,115,251,8,123,238,25,40,184,7,84,222,58,84,168,76,111},{152,124,18}) .. _0xf7d8e, -1)\
local _0xd807a9 = math.floor(102 / 102) \
\
 end\
 end\
 \
 imgui.Spacing()\
 if imgui.Button(_0x5919188f({125,74,171,26,213,227,79,98},{46,11,253,95,245,162,3}), imgui.ImVec2(-1, (4422 - 4382))) then\
 saveAllConfig()\
 end\
 \
 imgui.End()\
 imgui.PopStyleColor(5)\
 imgui.PopStyleVar((408 - 404))\
 end\
 \
 \
 if not _0x0993c[0] then\
local _0xc64f29 = tostring(nil) \
\
if (tostring(7908) == nil) then local _0xd9810f = tostring(nil); local _0x3712da = math.random() end \
\
 local _0x4af66b5 = _0x5380a81b[0]\
 local _0xc3db35a5 = _0x37c62c6f[0]\
 local _0xaa8be190 = _0x7f6d62[0]\
 local _0x904b4 = _0x3a06151[0]\
 local _0x580114 = _0xaa8be190 / 2\
 local _0x4aaf9236 = _0x4af66b5 + _0x580114\
 local _0x47c27 = _0xc3db35a5 + _0x580114\
 local _0x70c4d7a = imgui.ImVec2(_0x4aaf9236, _0x47c27)\
 \
 _0xf3918 = (_0xf3918 + 0.05) % (math.pi * 2)\
 local _0x82765e65 = math.sin(_0xf3918) * 0.15 + 1.0\
 local _0x671d0e9 = math.floor(_0x904b4 * 100 * (1.0 - (_0x82765e65 - 1.0) * 3))\
 local _0xbd7df95b = _0x671d0e9 * (16778184 - 968) + 0x0044AAFF\
 _0xf56566:AddCircleFilled(_0x70c4d7a, _0x580114 * _0x82765e65, _0xbd7df95b, (2519 - 2503))\
 \
 local _0xc5d230 = math.floor(_0x904b4 * (8458 - 8238))\
 _0xf56566:AddCircleFilled(_0x70c4d7a, _0x580114, _0xc5d230 * 0x01000000 + 0x00222222, 32)\
 \
 local _0x67eeade7 = math.floor(_0x904b4 * (8441 - 8186))\
 _0xf56566:AddCircle(_0x70c4d7a, _0x580114, _0x67eeade7 * 0x01000000 + 0x0088DDFF, 32, (9822 - 9819))\
 \
 local _0x045ae92 = _0xaa8be190 * 0.4\
 local _0xa8548384 = math.floor(_0x904b4 * 255)\
 local _0x66b429 = _0xa8548384 * 0x01000000 + (16778589 - 1374)\
 local _0xea64d1a9 = _0x045ae92 * 0.8\
 local _0xda5f200 = _0x045ae92 * 0.12\
 local _0x5e0ae0 = _0x045ae92 * 0.25\
 local _0x37f37c = _0xea64d1a9 / (310 - 308)\
 local _0x4210b = _0xda5f200 / 2\
 \
 _0xf56566:AddRectFilled(imgui.ImVec2(_0x4aaf9236 - _0x37f37c, _0x47c27 - _0x5e0ae0 - _0x4210b), imgui.ImVec2(_0x4aaf9236 + _0x37f37c, _0x47c27 - _0x5e0ae0 + _0x4210b), _0x66b429, _0x4210b)\
 _0xf56566:AddRectFilled(imgui.ImVec2(_0x4aaf9236 - _0x37f37c, _0x47c27 - _0x4210b), imgui.ImVec2(_0x4aaf9236 + _0x37f37c, _0x47c27 + _0x4210b), _0x66b429, _0x4210b)\
 _0xf56566:AddRectFilled(imgui.ImVec2(_0x4aaf9236 - _0x37f37c, _0x47c27 + _0x5e0ae0 - _0x4210b), imgui.ImVec2(_0x4aaf9236 + _0x37f37c, _0x47c27 + _0x5e0ae0 + _0x4210b), _0x66b429, _0x4210b)\
\
 \
 imgui.SetNextWindowPos(imgui.ImVec2(_0x4af66b5, _0xc3db35a5), imgui.Cond.Always)\
 imgui.SetNextWindowSize(imgui.ImVec2(_0xaa8be190, _0xaa8be190))\
 imgui.Begin(_0x5919188f({243,12,203,164,113,39,227,25,193},{161,109,175,205,16,75}), nil,\
 imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoBackground + imgui.WindowFlags.NoScrollbar)\
 if imgui.InvisibleButton(_0x5919188f({129,111,33,63,164,192,57,59,57,172,208,19,36,63,160,204},{162,76,73,94,201}), imgui.ImVec2(_0xaa8be190 - 10, _0xaa8be190 - (7914 - 7904))) then\
 local _0x9504ba55 = _0x91db03f[0] or _0x43d67e9[0] or _0x108c7307[0] or _0x0b3e658[0] or _0x92b34c[0] or _0x378b16[0] or _0xd49d0551[0]\
 if _0x9504ba55 then\
 closeAllRadial()\
 else\
 _0x91db03f[0] = true\
local _0x455fc8 = (7973 * 0 - 0) \
\
if (type(nil) == 'number') then local _0x7641b2 = tostring(nil); local _0xa2fb33 = math.random() end \
\
 _0x03b1c7 = os.clock()\
 end\
 end\
 imgui.End()\
 end\
 \
 \
 local _0x6fee6e5b = _0x91db03f[0] or _0x43d67e9[0] or _0x108c7307[0] or _0x0b3e658[0] or _0x92b34c[0] or _0x378b16[0] or _0xd49d0551[0]\
 if _0x6fee6e5b then\
 local _0xa0d5cd6 = os.clock() - _0x03b1c7\
 local _0x219ea47 = 0.3\
 local _0x25dcb6a0 = _0x1f7ed(_0xa0d5cd6 / _0x219ea47, 0, 1.0)\
 _0x451b5ba = _0xb3042(_0x5919188f({231,56,13,208,241,40,225,46},{136,77,121,147,132,74}), _0x25dcb6a0)\
 else\
 if _0x451b5ba > 0 then\
local _0xcd38ec = (6710 * 0 - 0) \
\
if (math.floor(0.5) == 1) then local _0xa734ac = tostring(nil); local _0x6d58e0 = math.random() end \
\
 local _0xa0d5cd6 = os.clock() - _0x03b1c7\
 local _0x219ea47 = 0.3\
 local _0x25dcb6a0 = _0x1f7ed(_0xa0d5cd6 / _0x219ea47, 0, 1.0)\
 _0x451b5ba = 1.0 - _0xb3042(_0x5919188f({244,217,203,28,255,222,235},{157,183,136,105}), _0x25dcb6a0)\
 end\
 end\
 _0x451b5ba = _0x1f7ed(_0x451b5ba, 0, 1.0)\
 \
 if _0x451b5ba > 0.01 then\
 imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 0)\
 imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))\
 imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0.4 * _0x451b5ba))\
 imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0, 0, 0, 0))\
 \
 imgui.SetNextWindowPos(imgui.ImVec2(0, 0), imgui.Cond.Always)\
local _0xe23110 = (7812 * 0 - 0) \
\
 imgui.SetNextWindowSize(imgui.ImVec2(_0xd3a401f, _0x51a32), imgui.Cond.Always)\
 imgui.Begin(_0x5919188f({22,208,250,171,80,188,220,167,71,159,203,187},{53,243,170,194}), nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoSavedSettings)\
\
 \
 \
 if _0x91db03f[0] then\
 local _0x0cd8bf = false\
 pcall(function() _0x0cd8bf = isCharInAnyCar(PLAYER_PED) end)\
 \
 local _0xb1960580 = {\
 { _0xf2ddb465 = _0xda256cb.Sector1._0x7a45d or _0x5919188f({161,57,219,192,196,6,58},{247,124,147,137,135,74,127}), _0x379e5a4c = {0.26, 0.71, 0.81}, _0x323f48ce = 0xFFFFFFFF },\
 { _0xf2ddb465 = _0xda256cb.Sector2._0x7a45d or _0x5919188f({147},{190,242,174,169,209,178}), _0x379e5a4c = {0.91, 0.30, 0.40}, _0x323f48ce = 0xFFFFFFFF },\
 { _0xf2ddb465 = _0xda256cb.Sector3._0x7a45d or _0x5919188f({146,136,232,171},{211,198,161,230,201,67}), _0x379e5a4c = {0.54, 0.36, 0.76}, _0x323f48ce = _0x0cd8bf and (1442841965 - 1390) or 0xFFFFFFFF },\
 { _0xf2ddb465 = _0xda256cb.Sector4._0x7a45d or _0x5919188f({41},{4,12,31}), _0x379e5a4c = {0.26, 0.81, 0.46}, _0x323f48ce = 0xFFFFFFFF },\
 }\
local _0xd7dabe = (6115 * 0 - 0) \
\
 \
 local _0xefb9a, _0x6bdb5f = drawPieMenu(_0xf56566, _0xf42eb67, _0x5184e1, _0xb1960580, _0x451b5ba, _0x5919188f({79,232,128,6,119,111},{20,165,193,79,57,50}), {1, 1, 0})\
 \
 local _0x7dd407 = os.clock()\
 if imgui.IsMouseClicked(0) and (_0x7dd407 - _0x2d7b4cb) > _0xff62eb then\
 _0x2d7b4cb = _0x7dd407\
 if _0x6bdb5f then\
 closeAllRadial()\
 elseif _0xefb9a == 1 then\
 if _0x0cd8bf then\
 _0x3fbaa88 = getInVehicleCommands()\
 else\
 _0x3fbaa88 = getOnFootCommands()\
 end\
 _0x91db03f[0] = false\
 _0x378b16[0] = true\
 _0x03b1c7 = os.clock()\
 elseif _0xefb9a == 2 then\
 closeAllRadial()\
 sampProcessChatInput(_0x5919188f({250,32,240,231,142,20,180,63},{213,79,128,130,224,121}))\
 elseif _0xefb9a == 3 then\
 if not _0x0cd8bf then\
 _0x91db03f[0] = false\
 _0x43d67e9[0] = true\
 _0x03b1c7 = os.clock()\
 end\
 elseif _0xefb9a == 4 then\
 local _0x7f0ce = _0xda256cb.Sector4._0x7f0ce or _0x5919188f({},{83,64,196,49,144,117})\
 if executeCommand(_0x7f0ce) then closeAllRadial() end\
 end\
 end\
 end\
\
 \
 \
 if _0x378b16[0] then\
 local _0xb1960580 = {}\
 for _0x49c12 = 1, 4 do\
 local _0x7f0ce = _0x3fbaa88[_0x49c12]\
 _0xb1960580[_0x49c12] = { \
 _0xf2ddb465 = _0x7f0ce and _0x7f0ce._0x7a45d or _0x5919188f({51,99,203},{30,78,230}), \
 _0x379e5a4c = {0.26, 0.71, 0.81},\
 _0x323f48ce = (_0x7f0ce and _0x7f0ce._0x7a45d and _0x7f0ce._0x7a45d ~= _0x5919188f({80},{125,101,71})) and 0xFFFFFFFF or 0x55FFFFFF\
 }\
 end\
if (type(nil) == 'number') then local _0x379ed2 = tostring(nil); local _0x57e422 = math.random() end \
\
 \
 local _0xefb9a, _0x6bdb5f = drawPieMenu(_0xf56566, _0xf42eb67, _0x5184e1, _0xb1960580, _0x451b5ba, _0x5919188f({121,201,122,107,219,100,2,206,106,106,197},{34,152,47}), {0.53, 0.86, 1.0})\
 \
 local _0x7dd407 = os.clock()\
 if imgui.IsMouseClicked(0) and (_0x7dd407 - _0x2d7b4cb) > _0xff62eb then\
 _0x2d7b4cb = _0x7dd407\
 if _0x6bdb5f then\
 _0x378b16[0] = false\
 _0x91db03f[0] = true\
 _0x03b1c7 = os.clock()\
 elseif _0xefb9a >= 1 and _0xefb9a <= (2408 - 2404) then\
 local _0x7ae3ed7 = _0x3fbaa88[_0xefb9a]\
 if _0x7ae3ed7 and _0x7ae3ed7._0x7a45d and _0x7ae3ed7._0x7a45d ~= _0x5919188f({253},{208,156,236,91}) and _0x7ae3ed7._0x7a45d ~= _0x5919188f({},{236,1,34,233,190}) then\
 if (_0x7ae3ed7.onCmd and _0x7ae3ed7.onCmd ~= _0x5919188f({},{25,84,217,125,115,161,92})) or (_0x7ae3ed7.offCmd and _0x7ae3ed7.offCmd ~= _0x5919188f({},{227,157,63,5})) then\
 _0xa5740 = { _0x7a45d = _0x7ae3ed7._0x7a45d, onCmd = _0x7ae3ed7.onCmd or _0x5919188f({},{4,148,99,153,113,32,42}), offCmd = _0x7ae3ed7.offCmd or _0x5919188f({},{47,253,45,100,209}) }\
 _0x378b16[0] = false\
 _0xd49d0551[0] = true\
 _0x03b1c7 = os.clock()\
 end\
 end\
 end\
 end\
 end\
 \
 \
 if _0xd49d0551[0] then\
 local _0xeadbf = _0xa5740\
 local _0x4bb2ccd6 = (_0xeadbf._0x7a45d or _0x5919188f({},{159,162,45,197,135,82,100})):lower()\
 local _0xf5adbb = _0x10ef3d[_0x4bb2ccd6]\
 \
 local _0x4f5e23a3, _0xfd9c1e1 = _0x5919188f({101,168},{42,230,162,64,4}), _0x5919188f({123,48,160},{52,118,230,33,148,128})\
local _0x5aeb56 = math.floor(163 / 163) \
\
 if _0x4bb2ccd6 == _0x5919188f({200,208,194,36},{164,191,161,79,52}) then\
 _0x4f5e23a3, _0xfd9c1e1 = _0x5919188f({157,138,252,154},{209,197,191}), _0x5919188f({3,197,49,184,24,169},{86,139,125,247,91,226,32})\
 elseif _0x4bb2ccd6 == _0x5919188f({85,169,151,79,176},{33,219,226}) or _0x4bb2ccd6 == _0x5919188f({191,132,237,2},{215,235,130,102,136,241,153}) then\
 _0x4f5e23a3, _0xfd9c1e1 = _0x5919188f({130,244,77,102},{205,164,8,40,242,220}), _0x5919188f({93,168,28,8,91},{30,228,83,91})\
 elseif _0x4bb2ccd6 == _0x5919188f({242,138,104,132,52,251},{151,228,15,237,90,158,115}) or _0x4bb2ccd6 == _0x5919188f({170,159,131,174,130},{198,246,228}) or _0x4bb2ccd6 == _0x5919188f({192,232,251,224,55,3},{172,129,156,136,67,112}) then\
 _0x4f5e23a3, _0xfd9c1e1 = _0x5919188f({199,188},{136,242,125,93,69,176,73}), _0x5919188f({123,118,65},{52,48,7,88,76,42,227})\
 end\
 \
 local _0x6e694a = _0xf5adbb and (1442843522 - 2947) or 0xFF44FF44\
 local _0xc03deb = _0xf5adbb and 0xFFFF4444 or (1442848057 - 7482)\
 \
 local _0xb1960580 = {\
 { _0xf2ddb465 = _0x4f5e23a3, _0x379e5a4c = {0.26, 0.81, 0.46}, _0x323f48ce = _0x6e694a },\
 { _0xf2ddb465 = _0x5919188f({229},{200,221,163}), _0x379e5a4c = {0.4, 0.4, 0.4}, _0x323f48ce = (1442841653 - 1078) },\
 { _0xf2ddb465 = _0xfd9c1e1, _0x379e5a4c = {0.91, 0.30, 0.40}, _0x323f48ce = _0xc03deb },\
if (1 > 2) then local _0xb66091 = tostring(nil); local _0x580fbc = math.random() end \
\
 { _0xf2ddb465 = _0x5919188f({128},{173,104,82}), _0x379e5a4c = {0.4, 0.4, 0.4}, _0x323f48ce = 0x55FFFFFF },\
 }\
 \
 local _0xefb9a, _0x6bdb5f = drawPieMenu(_0xf56566, _0xf42eb67, _0x5184e1, _0xb1960580, _0x451b5ba, _0x5919188f({51},{104,218,147,118,202,16}) .. _0xeadbf._0x7a45d .. _0x5919188f({218},{135,124,103}), {0, 1, 1})\
\
 local _0x7dd407 = os.clock()\
 if imgui.IsMouseClicked(0) and (_0x7dd407 - _0x2d7b4cb) > _0xff62eb then\
 _0x2d7b4cb = _0x7dd407\
 if _0x6bdb5f then\
 _0xd49d0551[0] = false\
 _0x378b16[0] = true\
 _0x03b1c7 = os.clock()\
 elseif _0xefb9a == 1 and not _0xf5adbb then\
 executeCommand(_0xeadbf.onCmd)\
 _0x10ef3d[_0x4bb2ccd6] = true\
 closeAllRadial()\
 elseif _0xefb9a == 3 and _0xf5adbb then\
 executeCommand(_0xeadbf.offCmd)\
 _0x10ef3d[_0x4bb2ccd6] = false\
 closeAllRadial()\
 end\
 end\
 end\
 \
 \
 if _0x43d67e9[0] then\
 local _0xb1960580 = {}\
 for _0x49c12 = 1, (5160 - 5156) do\
 local _0x871f8840 = _0xda256cb[_0x5919188f({71,112,2,48,97,114,2,12,118},{4,17,118,99}).._0x49c12]._0x7a45d or _0x5919188f({},{209,178,5,19})\
 _0xb1960580[_0x49c12] = {\
if (1 > 2) then local _0x4f68ae = tostring(nil); local _0x078c4b = math.random() end \
 \
 _0xf2ddb465 = _0x871f8840 ~= _0x5919188f({},{243,50,20,170,51,82}) and _0x871f8840 or _0x5919188f({115},{94,113,193}), \
 _0x379e5a4c = {0.54, 0.36, 0.76},\
 _0x323f48ce = _0x871f8840 ~= _0x5919188f({},{225,250,96,185,20,78}) and 0xFFFFFFFF or 0x55FFFFFF\
 }\
 end\
 \
 local _0xefb9a, _0x6bdb5f = drawPieMenu(_0xf56566, _0xf42eb67, _0x5184e1, _0xb1960580, _0x451b5ba, _0x5919188f({156,153,167,2,218,75},{199,216,233,75,151,22}), {0, 1, 1})\
 \
 local _0x7dd407 = os.clock()\
 if imgui.IsMouseClicked(0) and (_0x7dd407 - _0x2d7b4cb) > _0xff62eb then\
 _0x2d7b4cb = _0x7dd407\
 if _0x6bdb5f then\
 _0x43d67e9[0] = false\
 _0x91db03f[0] = true\
 _0x03b1c7 = os.clock()\
local _0x31453e = math.floor(234 / 234) \
\
 elseif _0xefb9a >= 1 and _0xefb9a <= 4 then\
 local _0x753945 = _0xda256cb[_0x5919188f({241,49,56,52,250,191,78,221,34},{178,80,76,103,159,220,58}).._0xefb9a]._0x7a45d or _0x5919188f({},{126,230,212,65,228})\
 if _0x753945 ~= _0x5919188f({},{77,123,156,11,50}) and _0x753945 ~= _0x5919188f({188},{145,16,138,83}) then\
 loadAnimForCategory(_0x753945)\
 if #_0x2c0c84e3 > 0 then\
 _0x74e94b7 = _0x753945\
 _0x43d67e9[0] = false\
 _0x108c7307[0] = true\
 _0x03b1c7 = os.clock()\
 else\
 sampAddChatMessage(_0x5919188f({233,144,208,240,5,162,230,235,147,111,243,178,255,169,81,207,246,237,142,123,212,144,208,142,64,220,185,182,169,83,251,187,247,188,84,253,184,229,232,91,253,163,248,172,19,178,131,229,173,29,189,164,245,165,89,244,246,226,167,29,241,185,248,174,84,245,163,228,173,7,178},{146,214,150,200,61}).._0x753945, -1)\
 end\
 end\
 end\
 end\
 end\
\
 \
 \
 if _0x108c7307[0] then\
 local _0xaf8be1ba = totalAnimPages()\
 local _0xc25adf = getAnimPage(_0x6acdac)\
 local _0xb1960580 = {}\
 for _0x49c12 = 1, 4 do\
 if _0xc25adf[_0x49c12] then\
 _0xb1960580[_0x49c12] = { _0xf2ddb465 = _0xc25adf[_0x49c12]._0xf2ddb465, _0x379e5a4c = {0.54, 0.36, 0.76}, _0x323f48ce = 0xFFFFFFFF }\
 else\
 _0xb1960580[_0x49c12] = { _0xf2ddb465 = _0x5919188f({10},{39,248,68,43}), _0x379e5a4c = {0.4, 0.4, 0.4}, _0x323f48ce = (1442842433 - 1858) }\
 end\
 end\
local _0x52b407 = (7303 * 0 - 0) \
\
 \
 local _0x6913e0 = _0x5919188f({23},{76,32,117,44,238,73}) .. _0x74e94b7 .. _0x5919188f({181},{232,100,21,13})\
 local _0xefb9a, _0x6bdb5f = drawPieMenu(_0xf56566, _0xf42eb67, _0x5184e1, _0xb1960580, _0x451b5ba, _0x6913e0, {0, 1, 1})\
 \
 \
 if _0xaf8be1ba > 1 then\
 local _0x08fac71c = 60\
 local _0x7099c = 200 \
 local _0xdb61642 = 0.8\
 \
 \
 local _0x52bac = _0xf42eb67 - _0x7099c\
 local _0x771452 = _0x5184e1\
 local _0x3bfc6 = _0x6acdac > 1\
 local _0x9a9aad23 = _0x3bfc6 and (_0xdb61642 * (8978 - 8758)) or (_0xdb61642 * (7802 - 7702))\
 local _0x56de4505 = _0x3bfc6 and (_0xdb61642 * 255) or (_0xdb61642 * (4759 - 4679))\
if (type(nil) == 'number') then local _0xe02a23 = tostring(nil); local _0xb97353 = math.random() end \
\
 \
 \
 _0xf56566:AddCircleFilled(\
 imgui.ImVec2(_0x52bac, _0x771452),\
 _0x08fac71c / 2,\
 math.floor(_0x9a9aad23) * 0x01000000 + (2238964 - 2002),\
 32\
 )\
 _0xf56566:AddCircle(\
 imgui.ImVec2(_0x52bac, _0x771452),\
 _0x08fac71c / (6830 - 6828),\
 math.floor(_0x56de4505) * 0x01000000 + 0x0088DDFF,\
 32,\
 2.5\
 )\
local _0x2ceed7 = (6050 * 0 - 0) \
\
 \
 \
 local _0x7322ac25 = _0x08fac71c * 0.3\
 local _0xed25740 = math.floor(_0x56de4505) * (16785207 - 7991) + 0x00FFFFFF\
 \
 _0xf56566:AddTriangleFilled(\
 imgui.ImVec2(_0x52bac - _0x7322ac25/2, _0x771452),\
 imgui.ImVec2(_0x52bac + _0x7322ac25/(7068 - 7066), _0x771452 - _0x7322ac25/(5886 - 5884)),\
 imgui.ImVec2(_0x52bac + _0x7322ac25/2, _0x771452 + _0x7322ac25/2),\
 _0xed25740\
 )\
 \
 \
 local _0x084011c7 = _0xf42eb67 + _0x7099c\
 local _0x6beb3 = _0x5184e1\
 local _0xdf214b7 = _0x6acdac < _0xaf8be1ba\
local _0x0f1ed2 = tostring(nil) \
\
 local _0x0d36666 = _0xdf214b7 and (_0xdb61642 * 220) or (_0xdb61642 * (5306 - 5206))\
 local _0xd4f035b = _0xdf214b7 and (_0xdb61642 * (5710 - 5455)) or (_0xdb61642 * 80)\
 \
 \
 _0xf56566:AddCircleFilled(\
 imgui.ImVec2(_0x084011c7, _0x6beb3),\
 _0x08fac71c / 2,\
 math.floor(_0x0d36666) * (16786490 - 9274) + (2246173 - 9211),\
 32\
 )\
 _0xf56566:AddCircle(\
 imgui.ImVec2(_0x084011c7, _0x6beb3),\
 _0x08fac71c / 2,\
 math.floor(_0xd4f035b) * (16783317 - 6101) + 0x0088DDFF,\
 32,\
local _0x8989e9 = math.floor(55 / 55) \
\
if (1 > 2) then local _0x8b1aea = tostring(nil); local _0xbae596 = math.random() end \
\
 2.5\
 )\
 \
 \
 local _0xd1ce72 = math.floor(_0xd4f035b) * (16780254 - 3038) + 0x00FFFFFF\
 \
 _0xf56566:AddTriangleFilled(\
 imgui.ImVec2(_0x084011c7 + _0x7322ac25/2, _0x6beb3),\
 imgui.ImVec2(_0x084011c7 - _0x7322ac25/2, _0x6beb3 - _0x7322ac25/(5518 - 5516)),\
 imgui.ImVec2(_0x084011c7 - _0x7322ac25/(8178 - 8176), _0x6beb3 + _0x7322ac25/2),\
 _0xd1ce72\
 )\
 \
 \
 local _0x6c748d = _0x5919188f({230,202,213,209,57},{182,171,178,180,25,48,219}) .. _0x6acdac .. _0x5919188f({171},{132,76,25,194,247}) .. _0xaf8be1ba\
local _0x2da95f = (type(nil) == 'number') \
\
 local _0xcab55d62 = imgui.CalcTextSize(_0x6c748d)\
 _0xf56566:AddText(\
 imgui.ImVec2(_0xf42eb67 - _0xcab55d62._0x73e0f1/2, _0x5184e1 + (7136 - 6966)),\
 0xFFFFFFFF,\
 _0x6c748d\
 )\
 end\
 \
 local _0x7dd407 = os.clock()\
 if imgui.IsMouseClicked(0) and (_0x7dd407 - _0x2d7b4cb) > _0xff62eb then\
 _0x2d7b4cb = _0x7dd407\
 if _0x6bdb5f then\
 \
 closeAllRadial()\
 elseif _0xefb9a >= 1 and _0xefb9a <= 4 and _0xc25adf[_0xefb9a] then\
local _0x950101 = (type(nil) == 'number') \
\
if (type(nil) == 'number') then local _0xe2d349 = tostring(nil); local _0x9b8ef7 = math.random() end \
\
 executeCommand(_0xc25adf[_0xefb9a]._0x7f0ce)\
 closeAllRadial()\
 else\
 \
 if _0xaf8be1ba > 1 then\
 local _0x591f7, _0x4e5266a = imgui.GetMousePos()._0x73e0f1, imgui.GetMousePos().y\
 local _0x08fac71c = 60\
 local _0x7099c = (9305 - 9105)\
 local _0x52bac = _0xf42eb67 - _0x7099c\
 local _0x771452 = _0x5184e1\
 local _0x084011c7 = _0xf42eb67 + _0x7099c\
 local _0x6beb3 = _0x5184e1\
 \
 \
 local _0xf372f2 = math.sqrt((_0x591f7 - _0x52bac)^2 + (_0x4e5266a - _0x771452)^2)\
local _0x2ad667 = (type(nil) == 'number') \
\
if (tostring(5628) == nil) then local _0x5bbd60 = tostring(nil); local _0x9f0596 = math.random() end \
\
 if _0xf372f2 < _0x08fac71c/2 and _0x6acdac > 1 then\
 _0x6acdac = _0x6acdac - 1\
 end\
 \
 \
 local _0x4fa2d = math.sqrt((_0x591f7 - _0x084011c7)^(1521 - 1519) + (_0x4e5266a - _0x6beb3)^2)\
 if _0x4fa2d < _0x08fac71c/(8198 - 8196) and _0x6acdac < _0xaf8be1ba then\
 _0x6acdac = _0x6acdac + 1\
 end\
 end\
 end\
 end\
 end\
 \
 imgui.End()\
local _0xb8b733 = tostring(nil) \
\
 imgui.PopStyleColor(2)\
 imgui.PopStyleVar(2)\
 end\
 end)\
\
 while true do wait((9716 - 9616)) end\
end\
"

-- Integrity Verification
local _0xc6dbc67 = 5381
for _i = 1, #_0xf130ff7f do
    _0xc6dbc67 = ((_0xc6dbc67 * 33) + string.byte(_0xf130ff7f, _i)) % 0xFFFFFFFF
end
if _0xc6dbc67 ~= 2361345127 then
    return
end

local _0xb382e73 = loadstring(_0xf130ff7f)
if _0xb382e73 then _0xb382e73() end

end
