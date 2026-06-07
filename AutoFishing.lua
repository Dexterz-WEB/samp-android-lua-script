-- ============================================================================
-- AUTO FISHING v1.0
-- Semi-auto fishing script untuk SA-MP Android (MonetLoader/Monet)
-- Mendeteksi prompt mancing dari server dan auto-respond dengan delay random
-- ============================================================================

script_name("AutoFishing")
script_author("OnlyDexterZ")

-- ============================================================================
-- LIBRARY IMPORTS
-- ============================================================================
local imgui = require 'mimgui'
local inicfg = require 'inicfg'
local ev = require 'lib.samp.events'

-- Optional: FontAwesome icons untuk toggle button
local fa_loaded = false
local faicons = nil
pcall(function()
    faicons = require 'fAwesome6'
    fa_loaded = true
end)

-- Optional: Notifications untuk toast notif
local notif_loaded = false
local Notifications = nil
pcall(function()
    require 'notifications'
    Notifications = _G.Notifications
    notif_loaded = true
end)

-- ============================================================================
-- KONFIGURASI (inicfg)
-- Menyimpan pengaturan script ke file .ini agar persist antar sesi
-- ============================================================================
local iniFileName = "AutoFishingConfig.ini"

local defaultConfig = {
    Settings = {
        enabled = true,           -- Status aktif/nonaktif script
        minDelay = 200,           -- Delay minimum (ms) sebelum respond
        maxDelay = 800,           -- Delay maksimum (ms) sebelum respond
        showButton = true,        -- Tampilkan floating toggle button
        buttonPosX = 50.0,        -- Posisi X toggle button
        buttonPosY = 400.0,       -- Posisi Y toggle button
        buttonSize = 70.0,        -- Ukuran toggle button
        logToChat = true,         -- Tampilkan log aktivitas ke chat
    },
    Stats = {
        totalCatch = 0,           -- Total ikan yang berhasil ditangkap
        sessionCatch = 0,         -- Ikan ditangkap sesi ini (reset tiap load)
        totalResponses = 0,       -- Total auto-response yang dikirim
    },
}

-- Load config dari file, atau buat baru jika belum ada
local iniData = inicfg.load(defaultConfig, iniFileName)
if not iniData then
    inicfg.save(defaultConfig, iniFileName)
    iniData = defaultConfig
end

-- Pastikan semua field ada (backward compatibility)
if not iniData.Settings then iniData.Settings = defaultConfig.Settings end
if not iniData.Stats then iniData.Stats = defaultConfig.Stats end
for k, v in pairs(defaultConfig.Settings) do
    if iniData.Settings[k] == nil then iniData.Settings[k] = v end
end
for k, v in pairs(defaultConfig.Stats) do
    if iniData.Stats[k] == nil then iniData.Stats[k] = v end
end

-- ============================================================================
-- STATE VARIABLES
-- Variabel state yang digunakan selama script berjalan
-- ============================================================================
local fishingActive = false         -- Apakah auto-fishing sedang aktif
local sessionCatchCount = 0         -- Counter tangkapan sesi ini
local sessionResponseCount = 0      -- Counter response sesi ini
local lastResponseTime = 0          -- Waktu terakhir auto-respond (anti-spam)
local isProcessing = false          -- Flag untuk mencegah double-response
local scriptPrefix = "{00FF88}[AutoFishing] {FFFFFF}"  -- Prefix chat message

-- ImGui state
local showToggleButton = imgui.new.bool(iniData.Settings.showButton)

-- ============================================================================
-- HELPER FUNCTIONS
-- Fungsi-fungsi pembantu yang digunakan di seluruh script
-- ============================================================================

--- saveConfig()
--- Menyimpan konfigurasi saat ini ke file .ini
--- Dipanggil setiap kali ada perubahan pengaturan
local function saveConfig()
    iniData.Stats.totalCatch = iniData.Stats.totalCatch + sessionCatchCount
    iniData.Stats.totalResponses = iniData.Stats.totalResponses + sessionResponseCount
    inicfg.save(iniData, iniFileName)
end

--- getRandomDelay()
--- Menghasilkan delay random antara minDelay dan maxDelay
--- Digunakan agar timing response tidak terlihat seperti bot
--- @return number delay dalam milidetik
local function getRandomDelay()
    local minD = iniData.Settings.minDelay or 200
    local maxD = iniData.Settings.maxDelay or 800
    return math.random(minD, maxD)
end

--- logActivity(message)
--- Menampilkan pesan log ke chat jika logging diaktifkan
--- @param message string - Pesan yang akan ditampilkan
local function logActivity(message)
    if iniData.Settings.logToChat then
        sampAddChatMessage(scriptPrefix .. message, -1)
    end
end

--- showNotification(title, message)
--- Menampilkan toast notification jika library tersedia
--- @param title string - Judul notifikasi
--- @param message string - Isi notifikasi
local function showNotification(title, message)
    if notif_loaded and Notifications then
        pcall(function()
            Notifications:Show(title, message)
        end)
    end
end

--- containsFishingPrompt(text)
--- Mengecek apakah pesan chat mengandung prompt mancing (H, Y, atau N)
--- Mendeteksi pola-pola umum yang digunakan server fishing
--- @param text string - Teks pesan dari server
--- @return string|nil - Karakter yang terdeteksi ("H", "Y", "N") atau nil
local function containsFishingPrompt(text)
    if not text or text == "" then return nil end

    -- Pola umum fishing prompt di berbagai server SA-MP:
    -- "Press H to pull the rod" / "Tekan H untuk menarik"
    -- "Press Y to reel in" / "Tekan Y untuk menarik ikan"
    -- "Press N to release" / "Type N to continue"
    -- Juga mendeteksi format: {key} dalam kurung kurawal atau bracket

    -- Pattern 1: "Press/Tekan/Type [H/Y/N]" (case insensitive check)
    local lowerText = text:lower()

    -- Deteksi prompt yang mengandung instruksi tekan tombol
    -- Cek apakah pesan berisi kata kunci fishing + tombol H/Y/N
    local fishingKeywords = {
        "fish", "ikan", "pancing", "mancing", "rod", "reel",
        "pull", "tarik", "cast", "lempar", "hook", "kail",
        "catch", "tangkap", "press", "tekan", "type", "ketik"
    }

    local hasFishingContext = false
    for _, keyword in ipairs(fishingKeywords) do
        if lowerText:find(keyword) then
            hasFishingContext = true
            break
        end
    end

    -- Jika ada konteks fishing, cari tombol yang harus ditekan
    if hasFishingContext then
        -- Cari huruf H, Y, atau N yang merupakan prompt tombol
        -- Pattern: huruf standalone atau dalam tanda kurung/bracket
        -- Contoh: "Press (H)", "tekan [Y]", "Type ~N~", "Press H"
        if text:find("[%(%[{~]H[%)%]}~]") or lowerText:find("press%s+h") or lowerText:find("tekan%s+h") or lowerText:find("type%s+h") or lowerText:find("ketik%s+h") then
            return "H"
        end
        if text:find("[%(%[{~]Y[%)%]}~]") or lowerText:find("press%s+y") or lowerText:find("tekan%s+y") or lowerText:find("type%s+y") or lowerText:find("ketik%s+y") then
            return "Y"
        end
        if text:find("[%(%[{~]N[%)%]}~]") or lowerText:find("press%s+n") or lowerText:find("tekan%s+n") or lowerText:find("type%s+n") or lowerText:find("ketik%s+n") then
            return "N"
        end
    end

    return nil
end

--- sendFishingResponse(key)
--- Mengirim response fishing ke server dengan delay random
--- Menggunakan lua_thread agar tidak blocking script utama
--- @param key string - Tombol yang akan di-respond ("H", "Y", atau "N")
local function sendFishingResponse(key)
    if isProcessing then return end
    if not fishingActive then return end

    -- Cegah spam: minimal 500ms antar response
    local currentTime = os.clock() * 1000
    if currentTime - lastResponseTime < 500 then return end

    isProcessing = true

    lua_thread.create(function()
        -- Delay random agar tidak terlihat seperti bot
        local delay = getRandomDelay()
        wait(delay)

        -- Kirim input ke server (simulasi tekan tombol)
        -- Menggunakan sampSendChat untuk mengirim karakter sebagai chat input
        -- Beberapa server menggunakan dialog response, beberapa lewat chat
        pcall(function()
            -- Coba kirim sebagai dialog response terlebih dahulu
            if sampIsDialogActive then
                local dialogActive = false
                pcall(function() dialogActive = sampIsDialogActive() end)
                if dialogActive then
                    -- Jika ada dialog aktif, respond ke dialog
                    pcall(function()
                        sampSendDialogResponse(sampGetCurrentDialogId(), 1, 0, key)
                    end)
                else
                    -- Kirim sebagai chat message (untuk server yang pakai chat input)
                    sampSendChat(key)
                end
            else
                sampSendChat(key)
            end
        end)

        -- Update counter
        sessionResponseCount = sessionResponseCount + 1
        lastResponseTime = os.clock() * 1000

        -- Log aktivitas
        logActivity("Auto-respond: {FFFF00}" .. key .. "{FFFFFF} (delay: " .. delay .. "ms) | Total: {00FFFF}" .. sessionResponseCount)

        -- Cek apakah ini tangkapan berhasil (heuristic: Y biasanya pull/catch)
        if key == "Y" or key == "H" then
            sessionCatchCount = sessionCatchCount + 1
            logActivity("Ikan tertangkap! Total sesi ini: {00FFFF}" .. sessionCatchCount .. " {FFFFFF}ekor")
            showNotification("AutoFishing", "Tangkapan #" .. sessionCatchCount .. "!")
        end

        isProcessing = false
    end)
end

-- ============================================================================
-- CHAT MESSAGE DETECTION (Events Hook)
-- Hook ke onServerMessage untuk mendeteksi prompt fishing dari server
-- Menggunakan library events.lua untuk intercept pesan masuk
-- ============================================================================

--- ev.onServerMessage(color, text)
--- Hook yang dipanggil setiap kali server mengirim pesan chat
--- Mengecek apakah pesan mengandung prompt fishing dan auto-respond
--- @param color number - Warna pesan dalam format integer
--- @param text string - Isi pesan dari server
--- @return boolean|nil - Return false untuk block pesan, nil untuk lanjut normal
function ev.onServerMessage(color, text)
    -- Jika script tidak aktif, lewati
    if not fishingActive then return end

    -- Deteksi apakah pesan mengandung prompt fishing
    local detectedKey = containsFishingPrompt(text)

    if detectedKey then
        -- Kirim response otomatis dengan delay random
        sendFishingResponse(detectedKey)
        -- Tidak block pesan, biarkan tampil di chat
    end
end

-- ============================================================================
-- IMGUI TOGGLE BUTTON RENDERING
-- Menampilkan floating toggle button di layar untuk on/off script
-- Menggunakan mimgui library untuk rendering UI
-- ============================================================================

--- renderToggleButton()
--- Fungsi untuk merender floating toggle button di layar
--- Button bisa di-tap untuk toggle on/off auto-fishing
--- Menampilkan status (ON/OFF) dan jumlah tangkapan
local function renderToggleButton()
    local sw, sh = getScreenResolution()
    local btnX = iniData.Settings.buttonPosX
    local btnY = iniData.Settings.buttonPosY
    local btnSize = iniData.Settings.buttonSize
    local draw_list = imgui.GetBackgroundDrawList()

    -- Warna button berdasarkan status
    local bgColor, textColor, statusText
    if fishingActive then
        bgColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.0, 0.7, 0.3, 0.85))
        textColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.0, 1.0, 1.0, 1.0))
        statusText = "ON"
    else
        bgColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.5, 0.1, 0.1, 0.85))
        textColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.8, 0.8, 0.8, 1.0))
        statusText = "OFF"
    end

    -- Gambar background button (lingkaran)
    local centerX = btnX + btnSize / 2
    local centerY = btnY + btnSize / 2
    local radius = btnSize / 2

    draw_list:AddCircleFilled(
        imgui.ImVec2(centerX, centerY),
        radius,
        bgColor,
        32
    )

    -- Border
    local borderColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.0, 1.0, 1.0, 0.5))
    draw_list:AddCircle(
        imgui.ImVec2(centerX, centerY),
        radius,
        borderColor,
        32,
        2.0
    )

    -- Teks icon ikan (atau FontAwesome jika tersedia)
    local iconText = "FISH"
    if fa_loaded and faicons then
        pcall(function()
            iconText = faicons.ICON_FISH or "FISH"
        end)
    end

    -- Render teks di tengah button
    local textSize = imgui.CalcTextSize(statusText)
    draw_list:AddText(
        imgui.ImVec2(centerX - textSize.x / 2, centerY - textSize.y / 2 - 6),
        textColor,
        statusText
    )

    -- Counter kecil di bawah status
    local countText = tostring(sessionCatchCount)
    local countSize = imgui.CalcTextSize(countText)
    local countColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.0, 1.0, 0.0, 1.0))
    draw_list:AddText(
        imgui.ImVec2(centerX - countSize.x / 2, centerY - countSize.y / 2 + 8),
        countColor,
        countText
    )

    -- Deteksi tap/klik pada button untuk toggle
    if imgui.IsMouseClicked(0) then
        local mousePos = imgui.GetMousePos()
        local dx = mousePos.x - centerX
        local dy = mousePos.y - centerY
        local distance = math.sqrt(dx * dx + dy * dy)

        if distance <= radius then
            -- Toggle status
            fishingActive = not fishingActive
            local statusMsg = fishingActive and "{00FF00}AKTIF" or "{FF0000}NONAKTIF"
            logActivity("Status: " .. statusMsg)
            showNotification("AutoFishing", fishingActive and "Diaktifkan!" or "Dinonaktifkan!")
        end
    end
end

-- ============================================================================
-- CHAT COMMANDS (/fishing)
-- Command handler untuk mengontrol script melalui chat
-- Usage: /fishing [on|off|status|delay|reset]
-- ============================================================================

--- handleFishingCommand(param)
--- Menghandle command /fishing dengan berbagai sub-command
--- @param param string - Parameter yang diberikan user setelah /fishing
local function handleFishingCommand(param)
    local args = {}
    for word in param:gmatch("%S+") do
        table.insert(args, word:lower())
    end

    local subCmd = args[1] or "status"

    if subCmd == "on" then
        -- Aktifkan auto-fishing
        fishingActive = true
        iniData.Settings.enabled = true
        saveConfig()
        sampAddChatMessage(scriptPrefix .. "Auto-fishing {00FF00}DIAKTIFKAN", -1)
        showNotification("AutoFishing", "Diaktifkan!")

    elseif subCmd == "off" then
        -- Nonaktifkan auto-fishing
        fishingActive = false
        iniData.Settings.enabled = false
        saveConfig()
        sampAddChatMessage(scriptPrefix .. "Auto-fishing {FF0000}DINONAKTIFKAN", -1)
        showNotification("AutoFishing", "Dinonaktifkan!")

    elseif subCmd == "status" then
        -- Tampilkan status lengkap
        local status = fishingActive and "{00FF00}AKTIF" or "{FF0000}NONAKTIF"
        sampAddChatMessage(scriptPrefix .. "=== STATUS AUTO-FISHING ===", -1)
        sampAddChatMessage(scriptPrefix .. "Status: " .. status, -1)
        sampAddChatMessage(scriptPrefix .. "Tangkapan sesi ini: {00FFFF}" .. sessionCatchCount .. " {FFFFFF}ekor", -1)
        sampAddChatMessage(scriptPrefix .. "Response sesi ini: {00FFFF}" .. sessionResponseCount, -1)
        sampAddChatMessage(scriptPrefix .. "Total tangkapan: {00FFFF}" .. (iniData.Stats.totalCatch + sessionCatchCount) .. " {FFFFFF}ekor", -1)
        sampAddChatMessage(scriptPrefix .. "Delay: {FFFF00}" .. iniData.Settings.minDelay .. "-" .. iniData.Settings.maxDelay .. "ms", -1)

    elseif subCmd == "delay" then
        -- Ubah delay: /fishing delay [min] [max]
        local minD = tonumber(args[2])
        local maxD = tonumber(args[3])
        if minD and maxD and minD > 0 and maxD > minD then
            iniData.Settings.minDelay = minD
            iniData.Settings.maxDelay = maxD
            saveConfig()
            sampAddChatMessage(scriptPrefix .. "Delay diubah: {FFFF00}" .. minD .. "-" .. maxD .. "ms", -1)
        else
            sampAddChatMessage(scriptPrefix .. "Penggunaan: /fishing delay [min] [max]", -1)
            sampAddChatMessage(scriptPrefix .. "Contoh: /fishing delay 300 1000", -1)
        end

    elseif subCmd == "reset" then
        -- Reset counter statistik
        sessionCatchCount = 0
        sessionResponseCount = 0
        iniData.Stats.totalCatch = 0
        iniData.Stats.totalResponses = 0
        saveConfig()
        sampAddChatMessage(scriptPrefix .. "Statistik di-reset!", -1)

    elseif subCmd == "button" then
        -- Toggle tampilan button: /fishing button
        iniData.Settings.showButton = not iniData.Settings.showButton
        showToggleButton[0] = iniData.Settings.showButton
        saveConfig()
        local btnStatus = iniData.Settings.showButton and "{00FF00}ditampilkan" or "{FF0000}disembunyikan"
        sampAddChatMessage(scriptPrefix .. "Toggle button " .. btnStatus, -1)

    else
        -- Tampilkan help
        sampAddChatMessage(scriptPrefix .. "=== BANTUAN AUTO-FISHING ===", -1)
        sampAddChatMessage(scriptPrefix .. "/fishing on - Aktifkan auto-fishing", -1)
        sampAddChatMessage(scriptPrefix .. "/fishing off - Nonaktifkan auto-fishing", -1)
        sampAddChatMessage(scriptPrefix .. "/fishing status - Lihat status & statistik", -1)
        sampAddChatMessage(scriptPrefix .. "/fishing delay [min] [max] - Ubah delay response", -1)
        sampAddChatMessage(scriptPrefix .. "/fishing reset - Reset statistik", -1)
        sampAddChatMessage(scriptPrefix .. "/fishing button - Toggle tampilan button", -1)
    end
end

-- ============================================================================
-- MAIN FUNCTION
-- Entry point utama script, dijalankan saat script di-load oleh MonetLoader
-- ============================================================================
function main()
    -- Tunggu sampai SA-MP tersedia sebelum inisialisasi
    while not isSampAvailable() do wait(100) end

    -- Tampilkan pesan loaded
    sampAddChatMessage(scriptPrefix .. "Script loaded! v1.0 by OnlyDexterZ", -1)
    sampAddChatMessage(scriptPrefix .. "Gunakan {FFFF00}/fishing{FFFFFF} untuk kontrol", -1)
    sampAddChatMessage(scriptPrefix .. "Tap tombol di layar untuk toggle ON/OFF", -1)

    -- Set status awal dari config
    fishingActive = iniData.Settings.enabled

    -- Tampilkan status awal
    local initialStatus = fishingActive and "{00FF00}AKTIF" or "{FF0000}NONAKTIF"
    sampAddChatMessage(scriptPrefix .. "Status awal: " .. initialStatus, -1)

    -- Register chat command /fishing
    sampRegisterChatCommand("fishing", handleFishingCommand)

    -- Seed random number generator untuk delay yang benar-benar random
    math.randomseed(os.time())

    -- Notifikasi
    showNotification("AutoFishing", "Script berhasil dimuat!")

    -- ========================================================================
    -- IMGUI RENDER FRAME
    -- Merender toggle button setiap frame jika diaktifkan
    -- ========================================================================
    imgui.OnFrame(function() return true end, function()
        -- Hanya render jika toggle button diaktifkan
        if not iniData.Settings.showButton then return end

        -- Render floating toggle button dengan pcall untuk safety
        pcall(renderToggleButton)
    end)

    -- ========================================================================
    -- AUTO-SAVE THREAD
    -- Thread background untuk auto-save statistik setiap 60 detik
    -- ========================================================================
    lua_thread.create(function()
        while true do
            wait(60000) -- Save setiap 60 detik
            pcall(saveConfig)
        end
    end)

    -- Main loop (menjaga script tetap berjalan)
    while true do
        wait(100)
    end
end

-- ============================================================================
-- SCRIPT UNLOAD HANDLER
-- Dipanggil saat script di-unload, menyimpan data terakhir
-- ============================================================================
function onScriptTerminate(scr, quitGame)
    if scr == thisScript() then
        -- Simpan statistik sebelum script dimatikan
        pcall(saveConfig)
    end
end
