local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TextChatService = game:GetService("TextChatService")

local FIREBASE_URL = "https://stealaneggnotifier-default-rtdb.firebaseio.com/chat_logs.json"

-- SENİN İSTEDİĞİN TAM KAPATMA/TEMİZLEME KODU (EN BAŞTA ÇALIŞIR)
if _G.ChatTrackerConnection then 
    for _, c in ipairs(_G.ChatTrackerConnection) do 
        pcall(function() c:Disconnect() end) 
    end 
    _G.ChatTrackerConnection = nil 
    print("[KAPATILDI] Eski Chat dinleyici durduruldu.")
end 

-- Yeni dinleyiciler için tabloyu oluşturuyoruz
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

local function handleText(text)
    if not text or text == "" or reportedMessages[text] then return end
    reportedMessages[text] = true
    
    local sender = "[SİSTEM / CHAT]"
    local cleanedText = text
    
    -- Eğer "OyuncuAdi: Mesaj" şeklindeyse gönderen adını ayır
    if text:find(":") then
        local parts = string.split(text, ":")
        sender = parts[1]
        cleanedText = table.concat(parts, ":", 2)
    end
    
    sendToFirebase(sender, cleanedText)
    print("[CHAT YAKALANDI] " .. sender .. ": " .. cleanedText)
end

-- 1. YENİ TEXTCHATSERVICE DİNLEMESİ
pcall(function()
    local textChannels = TextChatService:FindFirstChild("TextChannels")
    if textChannels then
        for _, channel in ipairs(textChannels:GetChildren()) do
            local conn = channel.MessageReceived:Connect(function(msg)
                local senderName = msg.TextSource and Players:GetPlayerByUserId(msg.TextSource.UserId) and Players:GetPlayerByUserId(msg.TextSource.UserId).Name or "[SİSTEM]"
                handleText(senderName .. ": " .. msg.Text)
            end)
            table.insert(_G.ChatTrackerConnection, conn)
        end
    end
end)

-- 2. SOHBET PENCERESİNDEKİ (GUI) HER YENİ MESAJI VE YAZIYI CANLI İZLEME
pcall(function()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local chatGui = playerGui:FindFirstChild("Chat") or playerGui:FindFirstChild("TextChatService")
    
    if chatGui then
        -- Sohbet alanına eklenen HER YENİ TextLabel nesnesini anında yakala
        local conn = chatGui.DescendantAdded:Connect(function(descendant)
            if descendant:IsA("TextLabel") then
                if descendant.Text ~= "" then
                    handleText(descendant.Text)
                end
                local textConn = descendant:GetPropertyChangedSignal("Text"):Connect(function()
                    if descendant.Text ~= "" then
                        handleText(descendant.Text)
                    end
                end)
                table.insert(_G.ChatTrackerConnection, textConn)
            end
        end)
        table.insert(_G.ChatTrackerConnection, conn)
        
        -- Mevcut chat kutusunda zaten var olan yazıları bir defalık tara
        for _, desc in ipairs(chatGui:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Text ~= "" then
                handleText(desc.Text)
            end
        end
    end
end)

print("Steal an Egg - Canlı Sohbet (Chat) Dinleyici Aktif!")
