-- ============================================================================
-- TEXTURE LOAD TEST
-- Test if we can load PNG/JPG textures in ImGui on MonetLoader Android
-- This is a standalone test - does NOT modify any other scripts
-- ============================================================================

script_name("Texture Load Test")
script_author("OnlyDexterZ")
script_version("1.0")

local imgui = require 'mimgui'
local ffi = require 'ffi'

-- ============================================================================
-- VARIABLES
-- ============================================================================
local showTestWindow = imgui.new.bool(false)
local textureLoaded = false
local textureError = ""
local texture = nil

-- Test methods results
local methods = {
    { name = "CreateTextureFromFile", status = "NOT TESTED", result = nil },
    { name = "LoadTextureFromFile", status = "NOT TESTED", result = nil },
    { name = "ImGui Image (ffi)", status = "NOT TESTED", result = nil },
}

-- ============================================================================
-- TRY LOADING TEXTURE - Multiple methods
-- ============================================================================

-- Method 1: imgui.CreateTextureFromFile (common in MoonLoader PC)
local function tryMethod1(path)
    local ok, result = pcall(function()
        if imgui.CreateTextureFromFile then
            local tex = imgui.CreateTextureFromFile(path)
            if tex then
                methods[1].status = "SUCCESS"
                methods[1].result = tex
                return tex
            else
                methods[1].status = "RETURNED NIL"
            end
        else
            methods[1].status = "FUNCTION NOT FOUND"
        end
        return nil
    end)
    
    if not ok then
        methods[1].status = "ERROR: " .. tostring(result)
    end
    return methods[1].result
end

-- Method 2: imgui.LoadTextureFromFile (alternative name)
local function tryMethod2(path)
    local ok, result = pcall(function()
        if imgui.LoadTextureFromFile then
            local tex = imgui.LoadTextureFromFile(path)
            if tex then
                methods[2].status = "SUCCESS"
                methods[2].result = tex
                return tex
            else
                methods[2].status = "RETURNED NIL"
            end
        else
            methods[2].status = "FUNCTION NOT FOUND"
        end
        return nil
    end)
    
    if not ok then
        methods[2].status = "ERROR: " .. tostring(result)
    end
    return methods[2].result
end

-- Method 3: Direct FFI approach
local function tryMethod3(path)
    local ok, result = pcall(function()
        -- Try loading via imgui internal functions
        if imgui.GetIO then
            local io = imgui.GetIO()
            -- Check if Fonts:AddFontFromFileTTF exists (indicates file loading works)
            if io and io.Fonts then
                methods[3].status = "IO ACCESS OK (texture method TBD)"
            else
                methods[3].status = "IO ACCESS FAILED"
            end
        else
            methods[3].status = "GetIO NOT FOUND"
        end
        return nil
    end)
    
    if not ok then
        methods[3].status = "ERROR: " .. tostring(result)
    end
    return nil
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
local texturePath = ""

imgui.OnInitialize(function()
    texturePath = getWorkingDirectory() .. "/testing/test_icon.png"
    
    -- Try all methods
    texture = tryMethod1(texturePath)
    if not texture then
        texture = tryMethod2(texturePath)
    end
    tryMethod3(texturePath)
    
    if texture then
        textureLoaded = true
    end
end)

-- ============================================================================
-- RENDER
-- ============================================================================
imgui.OnFrame(
    function() return showTestWindow[0] end,
    function()
        local sw, sh = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(sw/2 - 250, sh/2 - 200), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(500, 400), imgui.Cond.FirstUseEver)
        
        imgui.Begin("Texture Load Test", showTestWindow)
        
        imgui.TextColored(imgui.ImVec4(0, 1, 1, 1), "=== TEXTURE LOADING TEST ===")
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()
        
        -- Show results for each method
        imgui.TextColored(imgui.ImVec4(1, 1, 0, 1), "Test Results:")
        imgui.Spacing()
        
        for i, method in ipairs(methods) do
            local color = imgui.ImVec4(1, 1, 1, 1) -- white default
            if method.status:find("SUCCESS") then
                color = imgui.ImVec4(0, 1, 0, 1) -- green
            elseif method.status:find("ERROR") or method.status:find("FAILED") then
                color = imgui.ImVec4(1, 0, 0, 1) -- red
            elseif method.status:find("NOT FOUND") then
                color = imgui.ImVec4(1, 0.5, 0, 1) -- orange
            end
            
            imgui.Text("Method " .. i .. ": " .. method.name)
            imgui.SameLine(300)
            imgui.TextColored(color, method.status)
        end
        
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()
        
        -- Show texture if loaded
        if textureLoaded and texture then
            imgui.TextColored(imgui.ImVec4(0, 1, 0, 1), "TEXTURE LOADED SUCCESSFULLY!")
            imgui.Spacing()
            
            imgui.Text("Render at different sizes:")
            imgui.Spacing()
            
            -- Render texture at different sizes
            local ok, err = pcall(function()
                imgui.Text("64x64:")
                imgui.Image(texture, imgui.ImVec2(64, 64))
                
                imgui.SameLine()
                
                imgui.Text("32x32:")
                imgui.Image(texture, imgui.ImVec2(32, 32))
                
                imgui.SameLine()
                
                imgui.Text("128x128:")
                imgui.Image(texture, imgui.ImVec2(128, 128))
            end)
            
            if not ok then
                imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), "Image render error: " .. tostring(err))
            end
            
            imgui.Spacing()
            
            -- Test with tint color
            local ok2, err2 = pcall(function()
                imgui.Text("With color tint (red, green, blue):")
                imgui.Image(texture, imgui.ImVec2(48, 48), imgui.ImVec2(0,0), imgui.ImVec2(1,1), imgui.ImVec4(1,0.5,0.5,1))
                imgui.SameLine()
                imgui.Image(texture, imgui.ImVec2(48, 48), imgui.ImVec2(0,0), imgui.ImVec2(1,1), imgui.ImVec4(0.5,1,0.5,1))
                imgui.SameLine()
                imgui.Image(texture, imgui.ImVec2(48, 48), imgui.ImVec2(0,0), imgui.ImVec2(1,1), imgui.ImVec4(0.5,0.5,1,1))
            end)
            
            if not ok2 then
                imgui.TextColored(imgui.ImVec4(1, 0.5, 0, 1), "Tint not supported: " .. tostring(err2))
            end
            
            imgui.Spacing()
            
            -- Test ImageButton
            local ok3, err3 = pcall(function()
                imgui.Text("As button (clickable):")
                if imgui.ImageButton(texture, imgui.ImVec2(64, 64)) then
                    sampAddChatMessage("{00FF00}[Texture Test] {FFFFFF}Image button clicked!", -1)
                end
            end)
            
            if not ok3 then
                imgui.TextColored(imgui.ImVec4(1, 0.5, 0, 1), "ImageButton not supported: " .. tostring(err3))
            end
        else
            imgui.TextColored(imgui.ImVec4(1, 0.5, 0, 1), "No texture loaded yet")
            imgui.Spacing()
            imgui.TextDisabled("Make sure test_icon.png exists in testing/ folder")
            imgui.TextDisabled("Path: " .. (getWorkingDirectory() or "?") .. "/testing/test_icon.png")
        end
        
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()
        
        -- Available functions check
        imgui.TextColored(imgui.ImVec4(1, 1, 0, 1), "Available ImGui Functions:")
        imgui.Spacing()
        
        local funcsToCheck = {
            "CreateTextureFromFile",
            "LoadTextureFromFile",
            "CreateTextureFromMemory",
            "Image",
            "ImageButton",
            "GetIO",
        }
        
        for _, funcName in ipairs(funcsToCheck) do
            local exists = imgui[funcName] ~= nil
            local color = exists and imgui.ImVec4(0, 1, 0, 1) or imgui.ImVec4(1, 0, 0, 1)
            imgui.Text("imgui." .. funcName)
            imgui.SameLine(300)
            imgui.TextColored(color, exists and "EXISTS" or "NOT FOUND")
        end
        
        imgui.End()
    end
)

-- ============================================================================
-- MAIN
-- ============================================================================
function main()
    while not isSampAvailable() do wait(100) end
    
    sampAddChatMessage("{00FFFF}[Texture Test] {FFFFFF}Script loaded!", -1)
    sampAddChatMessage("{00FFFF}[Texture Test] {FFFFFF}Use {FFFF00}/textest{FFFFFF} to open test window", -1)
    sampAddChatMessage("{00FFFF}[Texture Test] {FFFFFF}Use {FFFF00}/texinfo{FFFFFF} to see results in chat", -1)
    
    -- Command: open test window
    sampRegisterChatCommand("textest", function()
        showTestWindow[0] = not showTestWindow[0]
    end)
    
    -- Command: show results in chat
    sampRegisterChatCommand("texinfo", function()
        sampAddChatMessage("{00FFFF}[Texture Test] {FFFFFF}--- Results ---", -1)
        for i, method in ipairs(methods) do
            local color = "{FFFFFF}"
            if method.status:find("SUCCESS") then color = "{00FF00}" end
            if method.status:find("ERROR") or method.status:find("FAILED") then color = "{FF0000}" end
            if method.status:find("NOT FOUND") then color = "{FF8800}" end
            
            sampAddChatMessage(string.format("{FFFF00}Method %d: {FFFFFF}%s = %s%s", 
                i, method.name, color, method.status), -1)
        end
        sampAddChatMessage("{FFFFFF}Texture loaded: " .. tostring(textureLoaded), -1)
        
        -- Check available functions
        sampAddChatMessage("{00FFFF}[Functions] {FFFFFF}CreateTextureFromFile: " .. 
            tostring(imgui.CreateTextureFromFile ~= nil), -1)
        sampAddChatMessage("{00FFFF}[Functions] {FFFFFF}LoadTextureFromFile: " .. 
            tostring(imgui.LoadTextureFromFile ~= nil), -1)
        sampAddChatMessage("{00FFFF}[Functions] {FFFFFF}Image: " .. 
            tostring(imgui.Image ~= nil), -1)
    end)
    
    wait(-1)
end
