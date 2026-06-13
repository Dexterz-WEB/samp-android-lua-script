script_name("Trail2s")
script_authors("Lolendor, braboxINC")
script_description("/trail2")

local var_0_0 = require("mimgui")
local var_0_1 = require("widgets")
local var_0_2 = require("ffi")
local var_0_3 = var_0_2.load("GTASA")
local var_0_4 = require("inicfg")
local var_0_5 = "trail2s.ini"
local var_0_6 = var_0_4.load(var_0_4.load({
	main = {
		colorr = 1,
		activated = false,
		trailalpha = 255,
		trailspeed = 1,
		position = 0,
		colorg = 1,
		waits = 30,
		rainbowc = true,
		colora = 1,
		mode = 0,
		length = 50,
		zpos = 0,
		trailoffset = 0,
		width = 3,
		colorb = 1
	}
}, var_0_5))

var_0_4.save(var_0_6, var_0_5)
var_0_2.cdef("  typedef struct RwV3d {\n    float x, y, z;\n  } RwV3d;\n  // void CPed::GetBonePosition(CPed *this, RwV3d *posn, uint32 bone, bool calledFromCam) - Mangled name\n  void _ZN4CPed15GetBonePositionER5RwV3djb(void* thiz, RwV3d* posn, uint32_t bone, bool calledFromCam);\n")

function getBonePosition(arg_1_0, arg_1_1)
	local var_1_0 = var_0_2.cast("void*", getCharPointer(arg_1_0))
	local var_1_1 = var_0_2.new("RwV3d[1]")

	var_0_3._ZN4CPed15GetBonePositionER5RwV3djb(var_1_0, var_1_1, arg_1_1, false)

	return var_1_1[0].x, var_1_1[0].y, var_1_1[0].z
end

local var_0_7 = var_0_0.new
local var_0_8 = var_0_7.bool(false)
local var_0_9 = {}
local var_0_10 = 4294967295
local var_0_11 = var_0_7.bool(var_0_6.main.activated)
local var_0_12 = var_0_7.bool(var_0_6.main.rainbowc)
local var_0_13 = var_0_7.int(var_0_6.main.width)
local var_0_14 = var_0_7.int(var_0_6.main.length)
local var_0_15 = var_0_7.int(var_0_6.main.waits)
local var_0_16 = var_0_7.int(var_0_6.main.trailoffset)
local var_0_17 = var_0_7.int(var_0_6.main.position)
local var_0_18 = var_0_7.int(var_0_6.main.mode)
local var_0_19 = var_0_7.int(var_0_6.main.trailalpha)
local var_0_20 = var_0_7.int(var_0_6.main.trailspeed)
local var_0_21 = var_0_7.float[4](var_0_6.main.colorr, var_0_6.main.colorg, var_0_6.main.colorb, var_0_6.main.colora)
local var_0_22 = var_0_7.float(var_0_6.main.zpos)
local var_0_23 = {
	"Default",
	"Static"
}
local var_0_24 = var_0_0.new["const char*"][#var_0_23](var_0_23)
local var_0_25 = {
	"CharPos",
	"Left Knee",
	"Right Knee",
	"Right Elbow",
	"Left Elbow",
	"Body",
	"Right Shoulder",
	"Left Shoulder",
	"Head",
	"Right Foot",
	"Left Foot",
	"Right Hand",
	"Left Hand"
}
local var_0_26 = var_0_0.new["const char*"][#var_0_25](var_0_25)

function fileExists(arg_2_0)
	local var_2_0 = io.open(arg_2_0, "r")

	if var_2_0 then
		io.close(var_2_0)

		return true
	else
		return false
	end
end

local var_0_27 = var_0_0.OnFrame(function()
	return var_0_8[0]
end, function(arg_4_0)
	local var_4_0, var_4_1 = getScreenResolution()

	var_0_0.SetNextWindowPos(var_0_0.ImVec2(var_4_0 / 2, var_4_1 / 2), var_0_0.Cond.FirstUseEver, var_0_0.ImVec2(0.5, 0.5))
	var_0_0.Begin("Trail2s", var_0_8, var_0_0.WindowFlags.NoScrollbar + var_0_0.WindowFlags.AlwaysAutoResize)
	var_0_0.SetWindowFontScale(0.88)

	local var_4_2 = var_0_0.GetWindowSize()

	var_0_0.Checkbox("Activated", var_0_11)
	var_0_0.PushItemWidth(230)
	var_0_0.SliderInt("Width", var_0_13, 1, 10)

	if var_0_0.SliderInt("Length", var_0_14, 1, 1000) then
		var_0_9 = {}
	end

	var_0_0.SliderInt("Wait", var_0_15, 0, 1000)
	var_0_0.Checkbox("Rainbow", var_0_12)

	if var_0_12[0] then
		var_0_0.Combo("Rainbow Mode", var_0_18, var_0_24, #var_0_23, -1)

		if var_0_18[0] == 1 then
			var_0_0.SliderInt("Offset", var_0_16, -200, 200)
		end

		var_0_0.SliderInt("Speed", var_0_20, 1, 10)
		var_0_0.SliderInt("Alpha", var_0_19, 1, 256, var_0_19[0] == 256 and "Smooth")
	elseif var_0_0.ColorEdit4("Line color", var_0_21) then
		var_0_10 = join_argb(var_0_21[3] * 255, var_0_21[0] * 255, var_0_21[1] * 255, var_0_21[2] * 255)
	end

	var_0_0.Combo("Trail Position", var_0_17, var_0_26, #var_0_25, -1)
	var_0_0.SliderFloat("Z Position", var_0_22, -1, 1, "%.1f")
	var_0_0.PopItemWidth()

	if var_0_0.Button("Save Settings") then
		var_0_6 = {
			main = {
				activated = var_0_11[0],
				rainbowc = var_0_12[0],
				width = var_0_13[0],
				length = var_0_14[0],
				waits = var_0_15[0],
				trailoffset = var_0_16[0],
				position = var_0_17[0],
				mode = var_0_18[0],
				trailalpha = var_0_19[0],
				trailspeed = var_0_20[0],
				colorr = var_0_21[0],
				colorg = var_0_21[1],
				colorb = var_0_21[2],
				colora = var_0_21[3],
				zpos = var_0_22[0]
			}
		}

		var_0_4.save(var_0_6, var_0_5)
	end

	var_0_0.SameLine(var_4_2.x - 35)
	var_0_0.PushStyleColor(var_0_0.Col.Text, var_0_0.ImVec4(0.5, 0.5, 0.5, 1))

	if var_0_0.Button("C", var_0_0.ImVec2(25, 25)) then
		openLink("https://discord.com/invite/ultragaz-mods-784556603059077171")
	end

	var_0_0.PopStyleColor()
	var_0_0.End()
end)

function main()
	local var_5_0 = getWorkingDirectory() .. "/Trail2s MOBILE.lua"
	local var_5_1 = getWorkingDirectory() .. "/Trail2s_MOBILE.lua"
	local var_5_2 = getWorkingDirectory() .. "/Trail2s MOBILE.luac"
	local var_5_3 = getWorkingDirectory() .. "/Trail2s_MOBILE.luac"

	if fileExists(var_5_0) or fileExists(var_5_1) or fileExists(var_5_2) or fileExists(var_5_3) then
		print("carregado")
	else
		print("do not rename the mod // não renomeie o mod")
		thisScript():unload()
	end

	while true do
		sampRegisterChatCommand("trail2", function()
			var_0_8[0] = not var_0_8[0]
		end)

		if var_0_11[0] and #var_0_9 > 0 then
			local var_5_4, var_5_5, var_5_6 = getPos(PLAYER_PED)

			var_0_9[#var_0_9] = {
				x = var_5_4,
				y = var_5_5,
				z = var_5_6 + var_0_22[0]
			}

			for iter_5_0 = 1, #var_0_9 do
				if var_0_9[iter_5_0] ~= nil and var_0_9[iter_5_0 + 1] ~= nil and isPointOnScreen(var_0_9[iter_5_0].x, var_0_9[iter_5_0].y, var_0_9[iter_5_0].z, 0) and isPointOnScreen(var_0_9[iter_5_0 + 1].x, var_0_9[iter_5_0 + 1].y, var_0_9[iter_5_0 + 1].z, 0) then
					local var_5_7 = var_0_10

					if var_0_12[0] then
						local var_5_8, var_5_9, var_5_10, var_5_11 = (var_0_18[0] == 0 and rainbow or rainbow_v2)(var_0_20[0], 255, (iter_5_0 + (var_0_18[0] == 1 and var_0_16[0] or 0)) / -50)
						local var_5_12 = var_0_19[0] == 256 and iter_5_0 * (255 / (#var_0_9 > 255 and 255 or #var_0_9)) or var_0_19[0]

						var_5_7 = join_argb(var_5_12 > 255 and 255 or var_5_12, var_5_8, var_5_9, var_5_10)
					end

					local var_5_13, var_5_14 = convert3DCoordsToScreen(var_0_9[iter_5_0].x, var_0_9[iter_5_0].y, var_0_9[iter_5_0].z)
					local var_5_15, var_5_16 = convert3DCoordsToScreen(var_0_9[iter_5_0 + 1].x, var_0_9[iter_5_0 + 1].y, var_0_9[iter_5_0 + 1].z)

					renderDrawLine(var_5_13, var_5_14, var_5_15, var_5_16, var_0_13[0], var_5_7)
				end
			end
		end

		wait(0)
	end
end

lua_thread.create(function()
	while true do
		wait(var_0_15[0])

		local var_7_0, var_7_1, var_7_2 = getPos(PLAYER_PED)

		var_0_9[#var_0_9 + 1] = {
			x = var_7_0,
			y = var_7_1,
			z = var_7_2 + var_0_22[0]
		}

		if #var_0_9 > var_0_14[0] then
			table.remove(var_0_9, 1)
		end
	end
end)

function GetBodyPartCoordinates(arg_8_0, arg_8_1)
	local var_8_0 = var_0_2.cast("void*", getCharPointer(arg_8_1))
	local var_8_1 = var_0_2.new("RwV3d[1]")

	var_0_3._ZN4CPed15GetBonePositionER5RwV3djb(var_8_0, var_8_1, arg_8_0, false)

	return var_8_1[0].x, var_8_1[0].y, var_8_1[0].z
end

function getPos(arg_9_0)
	if var_0_17[0] == 0 then
		local var_9_0, var_9_1, var_9_2 = getCharCoordinates(arg_9_0)

		return var_9_0, var_9_1, var_9_2
	end

	local var_9_3 = {
		42,
		52,
		23,
		33,
		3,
		22,
		32,
		8,
		54,
		44,
		25,
		35
	}
	local var_9_4, var_9_5, var_9_6 = GetBodyPartCoordinates(var_9_3[var_0_17[0]], arg_9_0)

	return var_9_4, var_9_5, var_9_6
end

function join_argb(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	local var_10_0 = arg_10_3
	local var_10_1 = bit.bor(var_10_0, bit.lshift(arg_10_2, 8))
	local var_10_2 = bit.bor(var_10_1, bit.lshift(arg_10_1, 16))

	return (bit.bor(var_10_2, bit.lshift(arg_10_0, 24)))
end

function rainbow(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = os.clock() + arg_11_2
	local var_11_1 = math.floor(math.sin(var_11_0 * arg_11_0) * 127 + 128)
	local var_11_2 = math.floor(math.sin(var_11_0 * arg_11_0 + 2) * 127 + 128)
	local var_11_3 = math.floor(math.sin(var_11_0 * arg_11_0 + 4) * 127 + 128)

	return var_11_1, var_11_2, var_11_3, arg_11_1
end

function rainbow_v2(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = math.floor(math.sin(arg_12_2 * arg_12_0) * 127 + 128)
	local var_12_1 = math.floor(math.sin(arg_12_2 * arg_12_0 + 2) * 127 + 128)
	local var_12_2 = math.floor(math.sin(arg_12_2 * arg_12_0 + 4) * 127 + 128)

	return var_12_0, var_12_1, var_12_2, arg_12_1
end

var_0_0.OnInitialize(function()
	var_0_0.DarkTheme()
end)

function var_0_0.DarkTheme()
	var_0_0.SwitchContext()

	var_0_0.GetStyle().WindowPadding = var_0_0.ImVec2(5, 5)
	var_0_0.GetStyle().FramePadding = var_0_0.ImVec2(5, 5)
	var_0_0.GetStyle().ItemSpacing = var_0_0.ImVec2(5, 5)
	var_0_0.GetStyle().ItemInnerSpacing = var_0_0.ImVec2(2, 2)
	var_0_0.GetStyle().TouchExtraPadding = var_0_0.ImVec2(0, 0)
	var_0_0.GetStyle().IndentSpacing = 0
	var_0_0.GetStyle().ScrollbarSize = 25
	var_0_0.GetStyle().GrabMinSize = 10
	var_0_0.GetStyle().WindowBorderSize = 1
	var_0_0.GetStyle().ChildBorderSize = 1
	var_0_0.GetStyle().PopupBorderSize = 1
	var_0_0.GetStyle().FrameBorderSize = 0
	var_0_0.GetStyle().TabBorderSize = 1
	var_0_0.GetStyle().WindowRounding = 5
	var_0_0.GetStyle().ChildRounding = 5
	var_0_0.GetStyle().FrameRounding = 0
	var_0_0.GetStyle().PopupRounding = 5
	var_0_0.GetStyle().ScrollbarRounding = 5
	var_0_0.GetStyle().GrabRounding = 5
	var_0_0.GetStyle().TabRounding = 5
	var_0_0.GetStyle().WindowTitleAlign = var_0_0.ImVec2(0.5, 0.5)
	var_0_0.GetStyle().ButtonTextAlign = var_0_0.ImVec2(0.5, 0.5)
	var_0_0.GetStyle().SelectableTextAlign = var_0_0.ImVec2(0.5, 0.5)
	var_0_0.GetStyle().Colors[var_0_0.Col.Text] = var_0_0.ImVec4(0.95, 0.95, 0.95, 0.95)
	var_0_0.GetStyle().Colors[var_0_0.Col.TextDisabled] = var_0_0.ImVec4(0.5, 0.5, 0.5, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.WindowBg] = var_0_0.ImVec4(0.07, 0.07, 0.07, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.ChildBg] = var_0_0.ImVec4(0.07, 0.07, 0.07, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.PopupBg] = var_0_0.ImVec4(0.07, 0.07, 0.07, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.Border] = var_0_0.ImVec4(0.25, 0.25, 0.26, 0.54)
	var_0_0.GetStyle().Colors[var_0_0.Col.BorderShadow] = var_0_0.ImVec4(0, 0, 0, 0)
	var_0_0.GetStyle().Colors[var_0_0.Col.FrameBg] = var_0_0.ImVec4(0.12, 0.12, 0.12, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.FrameBgHovered] = var_0_0.ImVec4(0.25, 0.25, 0.26, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.FrameBgActive] = var_0_0.ImVec4(0.25, 0.25, 0.26, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.TitleBg] = var_0_0.ImVec4(0.12, 0.12, 0.12, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.TitleBgActive] = var_0_0.ImVec4(0.12, 0.12, 0.12, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.TitleBgCollapsed] = var_0_0.ImVec4(0.12, 0.12, 0.12, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.MenuBarBg] = var_0_0.ImVec4(0.12, 0.12, 0.12, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.ScrollbarBg] = var_0_0.ImVec4(0.12, 0.12, 0.12, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.ScrollbarGrab] = var_0_0.ImVec4(0, 0, 0, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.ScrollbarGrabHovered] = var_0_0.ImVec4(0.41, 0.41, 0.41, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.ScrollbarGrabActive] = var_0_0.ImVec4(0.51, 0.51, 0.51, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.CheckMark] = var_0_0.ImVec4(1, 1, 1, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.SliderGrab] = var_0_0.ImVec4(0.21, 0.2, 0.2, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.SliderGrabActive] = var_0_0.ImVec4(0.21, 0.2, 0.2, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.Button] = var_0_0.ImVec4(0.12, 0.12, 0.12, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.ButtonHovered] = var_0_0.ImVec4(0.21, 0.2, 0.2, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.ButtonActive] = var_0_0.ImVec4(0.41, 0.41, 0.41, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.Header] = var_0_0.ImVec4(0.12, 0.12, 0.12, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.HeaderHovered] = var_0_0.ImVec4(0.2, 0.2, 0.2, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.HeaderActive] = var_0_0.ImVec4(0.47, 0.47, 0.47, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.Separator] = var_0_0.ImVec4(0.12, 0.12, 0.12, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.SeparatorHovered] = var_0_0.ImVec4(0.12, 0.12, 0.12, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.SeparatorActive] = var_0_0.ImVec4(0.12, 0.12, 0.12, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.ResizeGrip] = var_0_0.ImVec4(1, 1, 1, 0.25)
	var_0_0.GetStyle().Colors[var_0_0.Col.ResizeGripHovered] = var_0_0.ImVec4(1, 1, 1, 0.67)
	var_0_0.GetStyle().Colors[var_0_0.Col.ResizeGripActive] = var_0_0.ImVec4(1, 1, 1, 0.95)
	var_0_0.GetStyle().Colors[var_0_0.Col.Tab] = var_0_0.ImVec4(0.12, 0.12, 0.12, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.TabHovered] = var_0_0.ImVec4(0.28, 0.28, 0.28, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.TabActive] = var_0_0.ImVec4(0.3, 0.3, 0.3, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.TabUnfocused] = var_0_0.ImVec4(0.07, 0.1, 0.15, 0.97)
	var_0_0.GetStyle().Colors[var_0_0.Col.TabUnfocusedActive] = var_0_0.ImVec4(0.14, 0.26, 0.42, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.PlotLines] = var_0_0.ImVec4(0.61, 0.61, 0.61, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.PlotLinesHovered] = var_0_0.ImVec4(1, 0.43, 0.35, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.PlotHistogram] = var_0_0.ImVec4(0.9, 0.7, 0, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.PlotHistogramHovered] = var_0_0.ImVec4(1, 0.6, 0, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.TextSelectedBg] = var_0_0.ImVec4(1, 0, 0, 0.35)
	var_0_0.GetStyle().Colors[var_0_0.Col.DragDropTarget] = var_0_0.ImVec4(1, 1, 0, 0.9)
	var_0_0.GetStyle().Colors[var_0_0.Col.NavHighlight] = var_0_0.ImVec4(0.26, 0.59, 0.98, 1)
	var_0_0.GetStyle().Colors[var_0_0.Col.NavWindowingHighlight] = var_0_0.ImVec4(1, 1, 1, 0.7)
	var_0_0.GetStyle().Colors[var_0_0.Col.NavWindowingDimBg] = var_0_0.ImVec4(0.8, 0.8, 0.8, 0.2)
	var_0_0.GetStyle().Colors[var_0_0.Col.ModalWindowDimBg] = var_0_0.ImVec4(0, 0, 0, 0.7)
end

var_0_2.cdef("    void _Z12AND_OpenLinkPKc(const char* link);\n")

function openLink(arg_15_0)
	var_0_3._Z12AND_OpenLinkPKc(arg_15_0)
end
