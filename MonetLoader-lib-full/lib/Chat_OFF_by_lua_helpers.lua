-- API для включения/выключения скрипта через Script Manager
local toggled = false
EXPORTS = {
  canToggle = function() return true end,
  getToggle = function() return toggled end,
  toggle = function() toggled = not toggled end
}

-- Переменные скрипта
local toggled_sm = false -- Специально для Lol: toggled_sm - это toggled server message
local check_sampev, sampev = pcall(require, "samp.events")

-- Основная функция скрипта
function main()
	if not check_sampev then
		print("[Chat OFF]: Samp Events not found!")
	else
		sampRegisterChatCommand("chatt", function()
			toggled_sm = not toggled_sm
			for i = 1, 15 do sampAddChatMessage("", -1) end
		end)
		wait(-1)
	end
end

-- Проверка на то, загрузилась ли библиотека "Samp Events"
if check_sampev then
	-- Функция на запрет показа сообщений в чате
	function sampev.onServerMessage(color, text)
		if toggled_sm then return false end
	end
end

-- Функция, если скрипт крашится - он перезагрузится
function onScriptTerminate(script, game_quit)
	if script == thisScript() and not game_quit then script():reload() end
end