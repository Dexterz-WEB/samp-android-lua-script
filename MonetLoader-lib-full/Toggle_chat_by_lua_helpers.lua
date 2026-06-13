-- API for enabling/disabling a script via Script Manager
 local toggled = false
 EXPORTS = {
   canToggle = function() return true end,
   getToggle = function() return toggled end,
   toggle = function() toggled = not toggled end
 }

 -- Script variables
 local toggled_sm = false -- Especially for Lol: toggled_sm is a toggled server message
 local check_sampev, sampev = pcall(require, "samp.events")

 -- Main script function
 function main()
 if not check_sampev then
 print("[Chat OFF]: Samp Events not found!")
 else
 sampRegisterChatCommand("togchat", function()
 toggled_sm = not toggled_sm
 sampAddChatMessage("[Chat OFF]: "..(toggle and "On" or "Off"), -1)
 sampAddChatMessage("[Chat OFF]: /timestamp for "..(toggled_sm and "on" or "off").. " chat time", -1)
 end)
 sampRegisterChatCommand("cchat", function()
 for i = 1, 15 do sampAddChatMessage("", -1) end
 end)
 sampRegisterChatCommand("cinfo", function()
 sampShowDialog(1111, "Chat OFF by t.me/lua_helpers", "/togchat - On/off chat message\n/cchat - Cleans the chat\n/cinfo - This menu", "Close"  , "Close", 0)
 end)
 wait(-1)
 end
 end

 -- Checking whether the "Samp Events" library has been loaded
 if check_sampev then
 -- Function to block the display of messages in chat
 function sampev.onServerMessage(color, text)
 if toggled_sm then return false end
 end
 end

 -- Function, if the script crashes, it will reboot
 function onScriptTerminate(script, game_quit)
 if script == thisScript() and not game_quit then script():reload() end
 end