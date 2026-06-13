
local colors = {
    COLOR_WHITE = 0xFFFFFFFF,
    COLOR_BLACK = 0x000000FF,
    COLOR_RED   = 0xFF0000FF,
    COLOR_GREEN = 0x00FF00FF,
    COLOR_BLUE  = 0x0000FFFF,
    WHITE = "{FFFFFF}", 
    BLACK = "{000000}",
    RED   = "{FF0000}",
    GREEN = "{00FF00}",
    BLUE  = "{0000FF}"
}

for k, v in pairs(colors) do
	_G[k] = v
end

return colors