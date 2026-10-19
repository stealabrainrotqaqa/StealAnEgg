-- nega
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TextChatService = game:GetService("TextChatService")

local FIREBASE_URL = "https://stealaneggnotifier-default-rtdb.firebaseio.com/chat_logs.json"

-- VARSA ESKİ ÇALIŞAN SCRIPT'İ DURDUR (Donmayı/Kasmayı Önler)
if _G.ChatTrackerConnection then
    for _, conn in ipairs(_G.ChatTrackerConnection) do
        pcall(function() conn:Disconnect() end)
    end
end
if _G.ChatTrackerThread then
    pcall(function() task.cancel(_G.ChatTrackerThread) end)
end

_G.ChatTrackerConnection = {}
local reportedMessages = {}

local function sendToFirebase(senderName, chatText)
    local data = {
        sender = senderName,
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

local function processText(sender, text)
    if not text or text == "" then return end
    
    -- Aynı mesajın defalarca gitmesini önle
    local uniqueId = sender .. ":" .. text
    if reportedMessages[uniqueId] then return end
    reportedMessages[uniqueId] = true
    
    sendToFirebase(sender, text)
    print("[CHAT LOG] " .. sender .. ": " .. text)
end

-- 1. YENİ TEXTCHATSERVICE DİNLEYİCİSİ (Oyuncu ve Sistem Kanalı)
pcall(function()
    local textChannels = TextChatService:FindFirstChild("TextChannels")
    if textChannels then
        for _, channel in ipairs(textChannels:GetChildren()) do
            local conn = channel.MessageReceived:Connect(function(msg)
                local senderName = "SİSTEM"
                if msg.TextSource and msg.TextSource.UserId then
                    local player = Players:GetPlayerByUserId(msg.TextSource.UserId)
                    if player then
                        senderName = player.Name
                    end
                end
                processText(senderName, msg.Text)
            end)
            table.insert(_G.ChatTrackerConnection, conn)
        end
    end
end)

-- 2. DÖNGÜ (Eski Chat UI ve Ekran Bildirim Taraması)
_G.ChatTrackerThread = task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                local chat = playerGui:FindFirstChild("Chat") or playerGui:FindFirstChild("TextChatService")
                if chat then
                    for _, descendant in ipairs(chat:GetDescendants()) do
                        if descendant:IsA("TextLabel") and descendant.Text ~= "" then
                            -- Eğer "OyuncuAdi: Mesaj" şeklindeyse ismi ayır
                            local text = descendant.Text
                            local sender = "SİSTEM"
                            if text:find(":") then
                                local parts = string.split(text, ":")
                                sender = parts[1]
                                text = table.concat(parts, ":", 2)
                            end
                            processText(sender, text)
                        end
                    end
                end
            end
        end)
    end
end)

print("Steal an Egg - Canlı Chat Dinleyici Aktif!")
