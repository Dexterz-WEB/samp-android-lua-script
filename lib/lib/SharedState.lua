-- SharedState.lua
-- Shared state module for inter-script communication
-- All scripts that require this get the same table reference via package.loaded cache

local state = {
    openFullMap = false,
}

return state
