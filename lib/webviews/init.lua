-- ============================================================================
-- WebViews Library for MonetLoader (SA-MP Android)
-- Provides WebView creation and management via JNI bridge
-- Author: OnlyDexterZ
-- ============================================================================

local ffi = require("ffi")
local JNI = require("android")

-- ============================================================================
-- MODULE TABLE
-- ============================================================================
local M = {}

-- Active browser instances: [id] = { ref, visible, clickable, x, y, w, h, url }
local browsers = {}

-- Window manager reference (cached as global ref)
local windowManager = nil

-- ============================================================================
-- INTERNAL HELPERS
-- ============================================================================

-- Get the game Activity (same pattern as android.lua internal)
local gta = ffi.load("GTASA")
local function getActivity()
    return gta._Z27NVEventGetPlatformAppHandlev()
end

-- Create a new Java object via constructor
-- class: JNI class path (e.g. "android/webkit/WebView")
-- sig: constructor signature (e.g. "(Landroid/content/Context;)V")
-- ...: constructor arguments
local function newObject(class, sig, ...)
    local clazz = JNI:findClass(class)
    local methodID = JNI.env[0].GetMethodID(JNI.env, clazz, "<init>", sig)
    if methodID == nil then
        JNI:checkForJNIException(true)
        return nil
    end
    local obj = JNI.env[0].NewObject(JNI.env, clazz, methodID, ...)
    if obj == nil then
        JNI:checkForJNIException(true)
        return nil
    end
    return obj
end

-- Get the WindowManager service from activity
local function getWindowManager()
    if windowManager ~= nil then
        return windowManager
    end
    local activity = getActivity()
    local wm = JNI:callObjectMethod(activity, "getWindowManager", "()Landroid/view/WindowManager;")
    if wm ~= nil then
        windowManager = JNI.env[0].NewGlobalRef(JNI.env, wm)
        JNI.env[0].DeleteLocalRef(JNI.env, wm)
    end
    return windowManager
end

-- Create WindowManager.LayoutParams for overlay
-- Type 2002 = TYPE_SYSTEM_ALERT (works on older Android)
-- Type 2038 = TYPE_APPLICATION_OVERLAY (Android 8+)
-- Flag 8 = FLAG_NOT_FOCUSABLE (default, non-focusable)
-- Flag 0 = focusable (for clickable webview)
local function createLayoutParams(x, y, w, h, clickable)
    -- WindowManager.LayoutParams(int w, int h, int type, int flags, int format)
    -- type: TYPE_APPLICATION_OVERLAY = 2038, TYPE_PHONE = 2002
    -- flags: FLAG_NOT_FOCUSABLE = 8, FLAG_NOT_TOUCH_MODAL = 32
    -- format: PixelFormat.TRANSLUCENT = -3
    local flags = 8 + 32 -- FLAG_NOT_FOCUSABLE + FLAG_NOT_TOUCH_MODAL
    if clickable then
        flags = 32 -- FLAG_NOT_TOUCH_MODAL only (allows focus/touch)
    end

    -- Try TYPE_APPLICATION_OVERLAY first (Android 8+), fallback to TYPE_PHONE
    local layoutType = 2038

    local params = newObject(
        "android/view/WindowManager$LayoutParams",
        "(IIIII)V",
        ffi.cast("jint", w),
        ffi.cast("jint", h),
        ffi.cast("jint", layoutType),
        ffi.cast("jint", flags),
        ffi.cast("jint", -3) -- PixelFormat.TRANSLUCENT
    )

    if params == nil then
        -- Fallback to TYPE_PHONE for older Android versions
        layoutType = 2002
        params = newObject(
            "android/view/WindowManager$LayoutParams",
            "(IIIII)V",
            ffi.cast("jint", w),
            ffi.cast("jint", h),
            ffi.cast("jint", layoutType),
            ffi.cast("jint", flags),
            ffi.cast("jint", -3)
        )
    end

    if params == nil then
        return nil
    end

    -- Set gravity to TOP|LEFT (48 + 3 = 51) so x,y are absolute
    local gravityField = JNI.env[0].GetFieldID(
        JNI.env,
        JNI:findClass("android/view/WindowManager$LayoutParams"),
        "gravity",
        "I"
    )
    JNI.env[0].SetIntField(JNI.env, params, gravityField, 51)

    -- Set x position
    local xField = JNI.env[0].GetFieldID(
        JNI.env,
        JNI:findClass("android/view/WindowManager$LayoutParams"),
        "x",
        "I"
    )
    JNI.env[0].SetIntField(JNI.env, params, xField, x)

    -- Set y position
    local yField = JNI.env[0].GetFieldID(
        JNI.env,
        JNI:findClass("android/view/WindowManager$LayoutParams"),
        "y",
        "I"
    )
    JNI.env[0].SetIntField(JNI.env, params, yField, y)

    return params
end

-- Update existing LayoutParams with new values
local function updateLayoutParams(params, x, y, w, h, clickable)
    local paramsClass = JNI:findClass("android/view/WindowManager$LayoutParams")

    -- Update width
    local widthField = JNI.env[0].GetFieldID(JNI.env, paramsClass, "width", "I")
    JNI.env[0].SetIntField(JNI.env, params, widthField, w)

    -- Update height
    local heightField = JNI.env[0].GetFieldID(JNI.env, paramsClass, "height", "I")
    JNI.env[0].SetIntField(JNI.env, params, heightField, h)

    -- Update x
    local xField = JNI.env[0].GetFieldID(JNI.env, paramsClass, "x", "I")
    JNI.env[0].SetIntField(JNI.env, params, xField, x)

    -- Update y
    local yField = JNI.env[0].GetFieldID(JNI.env, paramsClass, "y", "I")
    JNI.env[0].SetIntField(JNI.env, params, yField, y)

    -- Update flags for clickable state
    local flags = 8 + 32 -- FLAG_NOT_FOCUSABLE + FLAG_NOT_TOUCH_MODAL
    if clickable then
        flags = 32 -- FLAG_NOT_TOUCH_MODAL only
    end
    local flagsField = JNI.env[0].GetFieldID(JNI.env, paramsClass, "flags", "I")
    JNI.env[0].SetIntField(JNI.env, params, flagsField, flags)
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--- Create and show a WebView with the given URL
--- @param id string Unique identifier for this browser instance
--- @param url string URL to load
function M.create(id, url)
    -- Destroy existing instance with same id if any
    if browsers[id] then
        M.destroy(id)
    end

    -- Ensure looper is prepared (required for UI operations)
    JNI:looperPrepare()

    -- Refresh JNI env
    JNI.env = gta._Z24NVThreadGetCurrentJNIEnvv()

    local activity = getActivity()

    -- Create WebView instance (requires Context)
    local webview = newObject("android/webkit/WebView", "(Landroid/content/Context;)V", activity)
    if webview == nil then
        print("[WebViews] Failed to create WebView for id: " .. tostring(id))
        return false
    end

    -- Enable JavaScript
    local settings = JNI:callObjectMethod(webview, "getSettings", "()Landroid/webkit/WebSettings;")
    if settings ~= nil then
        JNI:callVoidMethod(settings, "setJavaScriptEnabled", "(Z)V", ffi.cast("jboolean", 1))
        JNI:callVoidMethod(settings, "setDomStorageEnabled", "(Z)V", ffi.cast("jboolean", 1))
        JNI:callVoidMethod(settings, "setBuiltInZoomControls", "(Z)V", ffi.cast("jboolean", 1))
        JNI:callVoidMethod(settings, "setDisplayZoomControls", "(Z)V", ffi.cast("jboolean", 0))
        JNI.env[0].DeleteLocalRef(JNI.env, settings)
    end

    -- Set background color to white
    JNI:callVoidMethod(webview, "setBackgroundColor", "(I)V", ffi.cast("jint", 0xFFFFFFFF))

    -- Default dimensions
    local defaultW = 550
    local defaultH = 450
    local defaultX = 50
    local defaultY = 100

    -- Create LayoutParams for WindowManager overlay
    local params = createLayoutParams(defaultX, defaultY, defaultW, defaultH, true)
    if params == nil then
        print("[WebViews] Failed to create LayoutParams for id: " .. tostring(id))
        JNI.env[0].DeleteLocalRef(JNI.env, webview)
        return false
    end

    -- Add WebView to WindowManager
    local wm = getWindowManager()
    if wm ~= nil then
        JNI:callVoidMethod(wm, "addView", "(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V", webview, params)
        JNI:checkForJNIException(true)
    end

    -- Store as global refs to prevent GC
    local webviewRef = JNI.env[0].NewGlobalRef(JNI.env, webview)
    local paramsRef = JNI.env[0].NewGlobalRef(JNI.env, params)
    JNI.env[0].DeleteLocalRef(JNI.env, webview)
    JNI.env[0].DeleteLocalRef(JNI.env, params)

    -- Store browser state
    browsers[id] = {
        ref = webviewRef,
        params = paramsRef,
        visible = true,
        clickable = true,
        x = defaultX,
        y = defaultY,
        w = defaultW,
        h = defaultH,
        url = url or "",
    }

    -- Load initial URL
    if url and url ~= "" then
        M.setUrl(id, url)
    end

    return true
end

--- Destroy a WebView instance
--- @param id string Browser instance identifier
function M.destroy(id)
    local browser = browsers[id]
    if not browser then return end

    -- Remove from WindowManager
    local wm = getWindowManager()
    if wm ~= nil and browser.ref ~= nil then
        JNI:callVoidMethod(wm, "removeView", "(Landroid/view/View;)V", browser.ref)
        JNI:checkForJNIException(true)
    end

    -- Delete global refs
    if browser.ref ~= nil then
        JNI.env[0].DeleteGlobalRef(JNI.env, browser.ref)
    end
    if browser.params ~= nil then
        JNI.env[0].DeleteGlobalRef(JNI.env, browser.params)
    end

    browsers[id] = nil
end

--- Navigate to a URL
--- @param id string Browser instance identifier
--- @param url string URL to navigate to
function M.setUrl(id, url)
    local browser = browsers[id]
    if not browser or not browser.ref then return end

    browser.url = url
    local jurl = JNI:to_javastring(url)
    JNI:callVoidMethod(browser.ref, "loadUrl", "(Ljava/lang/String;)V", jurl)
    JNI.env[0].DeleteLocalRef(JNI.env, jurl)
    JNI:checkForJNIException(true)
end

--- Show or hide the WebView
--- @param id string Browser instance identifier
--- @param visible boolean true to show, false to hide
function M.setVisible(id, visible)
    local browser = browsers[id]
    if not browser or not browser.ref then return end

    browser.visible = visible
    -- View.VISIBLE = 0, View.GONE = 8
    local visibility = visible and 0 or 8
    JNI:callVoidMethod(browser.ref, "setVisibility", "(I)V", ffi.cast("jint", visibility))
    JNI:checkForJNIException(true)
end

--- Set WebView position
--- @param id string Browser instance identifier
--- @param x number X position (pixels from left)
--- @param y number Y position (pixels from top)
function M.setPosition(id, x, y)
    local browser = browsers[id]
    if not browser or not browser.ref then return end

    browser.x = x
    browser.y = y

    -- Update layout params and refresh view layout
    if browser.params ~= nil then
        updateLayoutParams(browser.params, x, y, browser.w, browser.h, browser.clickable)
        local wm = getWindowManager()
        if wm ~= nil then
            JNI:callVoidMethod(wm, "updateViewLayout", "(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V", browser.ref, browser.params)
            JNI:checkForJNIException(true)
        end
    end
end

--- Set WebView size
--- @param id string Browser instance identifier
--- @param w number Width in pixels
--- @param h number Height in pixels
function M.setSize(id, w, h)
    local browser = browsers[id]
    if not browser or not browser.ref then return end

    browser.w = w
    browser.h = h

    -- Update layout params and refresh view layout
    if browser.params ~= nil then
        updateLayoutParams(browser.params, browser.x, browser.y, w, h, browser.clickable)
        local wm = getWindowManager()
        if wm ~= nil then
            JNI:callVoidMethod(wm, "updateViewLayout", "(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V", browser.ref, browser.params)
            JNI:checkForJNIException(true)
        end
    end
end

--- Enable or disable touch interaction
--- @param id string Browser instance identifier
--- @param clickable boolean true to enable touch, false to disable
function M.setClickable(id, clickable)
    local browser = browsers[id]
    if not browser or not browser.ref then return end

    browser.clickable = clickable

    -- Set view clickable and focusable
    JNI:callVoidMethod(browser.ref, "setClickable", "(Z)V", ffi.cast("jboolean", clickable and 1 or 0))
    JNI:callVoidMethod(browser.ref, "setFocusable", "(Z)V", ffi.cast("jboolean", clickable and 1 or 0))
    JNI:checkForJNIException(true)

    -- Update layout params flags for touch passthrough
    if browser.params ~= nil then
        updateLayoutParams(browser.params, browser.x, browser.y, browser.w, browser.h, clickable)
        local wm = getWindowManager()
        if wm ~= nil then
            JNI:callVoidMethod(wm, "updateViewLayout", "(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V", browser.ref, browser.params)
            JNI:checkForJNIException(true)
        end
    end
end

--- Navigate back in history
--- @param id string Browser instance identifier
function M.goBack(id)
    local browser = browsers[id]
    if not browser or not browser.ref then return end

    JNI:callVoidMethod(browser.ref, "goBack", "()V")
    JNI:checkForJNIException(true)
end

--- Navigate forward in history
--- @param id string Browser instance identifier
function M.goForward(id)
    local browser = browsers[id]
    if not browser or not browser.ref then return end

    JNI:callVoidMethod(browser.ref, "goForward", "()V")
    JNI:checkForJNIException(true)
end

--- Reload current page
--- @param id string Browser instance identifier
function M.reload(id)
    local browser = browsers[id]
    if not browser or not browser.ref then return end

    JNI:callVoidMethod(browser.ref, "reload", "()V")
    JNI:checkForJNIException(true)
end

--- Get list of active browser IDs
--- @return table Array of active browser ID strings
function M.getList()
    local list = {}
    for id, _ in pairs(browsers) do
        list[#list + 1] = id
    end
    return list
end

return M
