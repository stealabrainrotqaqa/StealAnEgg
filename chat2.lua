local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TextChatService = game:GetService("TextChatService")

local FIREBASE_URL = "https://stealaneggnotifier-default-rtdb.firebaseio.com/chat_logs.json"

-- Eski bağlantıları kapat (Kasmayı/Donmayı önler)
if _G.ChatTrackerConnection then
    for _, conn in ipairs(_G.ChatTrackerConnection) do
        pcall(function() conn:Disconnect() end)
    end
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

local function processMessage(sender, text)
    if not text or text == "" then return end
    
    local uniqueKey = sender .. ":" .. text
    if reportedMessages[uniqueKey] then return end
    reportedMessages[uniqueKey] = true
    
    sendToFirebase(sender, text)
    print("[CHAT LOG] " .. sender .. ": " .. text)
end

-- 1. YENİ SOHBET SİSTEMİ (TextChatService)
pcall(function()
    local textChannels = TextChatService:FindFirstChild("TextChannels")
    if textChannels then
        for _, channel in ipairs(textChannels:GetChildren()) do
            local conn = channel.MessageReceived:Connect(function(msg)
                local senderName = "[SİSTEM]"
                if msg.TextSource and msg.TextSource.UserId then
                    local player = Players:GetPlayerByUserId(msg.TextSource.UserId)
                    if player then
                        senderName = player.Name
                    end
                end
                processMessage(senderName, msg.Text)
            end)
            table.insert(_G.ChatTrackerConnection, conn)
        end
    end
end)

-- 2. KLASİK SOHBET SİSTEMİ (Legacy Chat)
pcall(function()
    local conn = Players.PlayerChatted:Connect(function(chatType, player, message)
        local senderName = player and player.Name or "[SİSTEM]"
        processMessage(senderName, message)
    end)
    table.insert(_G.ChatTrackerConnection, conn)
end)

print("Steal an Egg - Sadece Sohbet (Chat) Dinleyici Aktif!")
