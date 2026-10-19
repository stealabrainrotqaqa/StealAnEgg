local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TextChatService = game:GetService("TextChatService")

local FIREBASE_URL = "https://stealaneggnotifier-default-rtdb.firebaseio.com/chat_logs.json"

local reportedMessages = {}

local function sendToFirebase(chatText)
    local data = {
        type = "CHAT",
        player = LocalPlayer.Name,
        message = chatText,
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
    end
end

local function processText(text)
    if not text or text == "" or reportedMessages[text] then return end
    
    -- Oyuncuların mesajlarını atla (Genelde "OyuncuAdi: mesaj" şeklinde olur)
    -- Sistem mesajları doğrudan mesaj metni olarak düşer.
    reportedMessages[text] = true
    sendToFirebase(text)
    print("[CHAT SİSTEM MESAJI] " .. text)
end

-- 1. YENİ TEXTCHATSERVICE DİNLEYİCİSİ (Sistem Kanalı)
pcall(function()
    local textChannels = TextChatService:FindFirstChild("TextChannels")
    if textChannels then
        for _, channel in ipairs(textChannels:GetChildren()) do
            channel.MessageReceived:Connect(function(msg)
                -- Eğer mesajı bir oyuncu atmadıysa (TextSource yoksa = Sistem mesajıdır)
                if not msg.TextSource then
                    processText(msg.Text)
                end
            end)
        end
    end
end)

-- 2. Chat UI / PlayerGui Taraması (Klasik Chat veya Özel Sistem Duyuruları)
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                local chat = playerGui:FindFirstChild("Chat") or playerGui:FindFirstChild("TextChatService")
                if chat then
                    for _, descendant in ipairs(chat:GetDescendants()) do
                        if descendant:IsA("TextLabel") and descendant.Text ~= "" then
                            -- Sadece sistem/duyuru mesajlarını yakala
                            processText(descendant.Text)
                        end
                    end
                end
            end
        end)
    end
end)

print("Steal an Egg - Sistem Chat Dinleyici Aktif!")
