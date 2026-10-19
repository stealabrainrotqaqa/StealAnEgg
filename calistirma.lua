local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local FIREBASE_URL = "https://stealaneggnotifier-default-rtdb.firebaseio.com/test_logs.json"

local function sendTestNotification()
    local data = {
        type = "TEST",
        player = LocalPlayer.Name,
        message = "Script basariyla calistirildi!",
        timestamp = os.time()
    }
    
    local jsonData = HttpService:JSONEncode(data)
    local requestFunc = (syn and syn.request) or (http and http.request) or request or http_request
    
    if requestFunc then
        pcall(function()
            requestFunc({
                Url = FIREBASE_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = jsonData
            })
        end)
        print("[BAŞARILI] Script çalıştırma bildirimi gönderildi: " .. LocalPlayer.Name)
    end
end

-- Sadece çalıştırıldığında 1 defa tetiklenir
sendTestNotification()
