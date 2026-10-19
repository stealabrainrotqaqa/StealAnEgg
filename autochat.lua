local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. TEMİZLEME MEKANİZMASI (Donmayı/Kasmayı önler)
if _G.ChatTrackerConnection then 
    for _, c in ipairs(_G.ChatTrackerConnection) do 
        pcall(function() c:Disconnect() end) 
    end 
    _G.ChatTrackerConnection = nil 
    print("[KAPATILDI] Eski ekran dinleyici durduruldu.")
end 

_G.ChatTrackerConnection = {}
local reportedTexts = {}

-- 2. HTTP 404 HATASI VERMEYEN GÜVENLİ MESAJ GÖNDERME
local function sendMessageToChat(message)
    pcall(function()
        -- Yöntem 1: Yeni TextChatService (DisplayBar üzerinden)
        local chatInputBar = TextChatService:FindFirstChild("ChatInputBarConfiguration")
        if chatInputBar and TextChatService.TextChannels:FindFirstChild("RBXGeneral") then
            TextChatService.TextChannels.RBXGeneral:SendAsync(message)
            return
        end
    end)

    pcall(function()
        -- Yöntem 2: Klasik Sohbet Event'i (En Stabil Yöntem)
        local sayMessage = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") 
            and ReplicatedStorage.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
        
        if sayMessage then
            sayMessage:FireServer(message, "All")
        end
    end)
end

-- 3. YAZI KONTROLÜ VE FİLTRELEME
local function handleNewText(descendant)
    if not descendant:IsA("TextLabel") and not descendant:IsA("TextButton") then return end
    
    local function checkContent()
        local text = descendant.Text
        if not text or text == "" then return end
        
        if reportedTexts[text] then return end
        
        local textLower = text:lower()
        
        -- Sadece Eternal veya Divine geçen cümleleri yakala
        if textLower:find("eternal") or textLower:find("divine") then
            reportedTexts[text] = true
            sendMessageToChat(text)
            print("[OTOMATİK CHAT YAZILDI] " .. text)
        end
    end
    
    -- Canlı metin değişimini izle
    local propConn = descendant:GetPropertyChangedSignal("Text"):Connect(checkContent)
    table.insert(_G.ChatTrackerConnection, propConn)
    
    checkContent()
end

-- 4. EKRAN (PLAYERGUI) TARAMASI
pcall(function()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    local conn = playerGui.DescendantAdded:Connect(handleNewText)
    table.insert(_G.ChatTrackerConnection, conn)
    
    for _, desc in ipairs(playerGui:GetDescendants()) do
        handleNewText(desc)
    end
end)

print("Steal an Egg - Ekran Taramalı Otomatik Chat Aktif! (404 Hatası Düzeltildi)")
