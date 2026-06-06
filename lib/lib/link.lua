local mimgui = require('mimgui')

function mimgui.Link(link)
    if status_hovered then
        local p = mimgui.GetCursorScreenPos()
        mimgui.TextColored(mimgui.ImVec4(0, 0.5, 1, 1), u8'by Naito')
        mimgui.GetWindowDrawList():AddLine(mimgui.ImVec2(p.x, p.y + mimgui.CalcTextSize(u8'MST Community').y), mimgui.ImVec2(p.x + mimgui.CalcTextSize(u8'traducido y adaptado por ollydbg#6383').x, p.y + mimgui.CalcTextSize(u8'traducido y adaptado por ollydbg#6383').y), mimgui.GetColorU32(mimgui.ImVec4(0, 0.5, 1, 1)))
    else
        mimgui.TextColored(mimgui.ImVec4(0, 0.3, 0.8, 1), u8'By Naito')
    end
    if mimgui.IsItemClicked() then 
        os.execute('explorer '..'https://discord.gg/mst-community-1257189867020881962')
    elseif mimgui.IsItemHovered() then
        status_hovered = true 
    else 
        status_hovered = false
    end
end