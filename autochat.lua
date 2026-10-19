local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. SENİN İSTEDİĞİN TAM KAPATMA/TEMİZLEME KODU (Kasmayı/Donmayı önler)
if _G.ChatTrackerConnection then 
    for _, c in ipairs(_G.ChatTrackerConnection) do 
        pcall(function() c:Disconnect() end) 
    end 
    _G.ChatTrackerConnection = nil 
    print("[KAPATILDI] Eski ekran dinleyici durduruldu.")
end 

-- Yeni dinleyiciler ve yakalanan mesajların hafızası
_G.ChatTrackerConnection = {}
local reportedTexts = {}

-- 2. MESAJI CHAT'E GÖNDERME FONKSİYONU
local function sendMessageToChat(message)
    -- Yeni TextChatService sistemi (Donma yapmaz, daha güvenlidir)
    pcall(function()
        if TextChatService and TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral then
            TextChatService.TextChannels.RBXGeneral:SendAsync(message)
        else
            -- Klasik sohbet sistemi (Eğer TextChatService kapalıysa)
            if ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") and ReplicatedStorage.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest") then
                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")
            end
        end
    end)
end

-- 3. YAZIYI KONTROL ETME VE CHAT'E ATMA FONKSİYONU
local function handleNewText(descendant)
    if not descendant:IsA("TextLabel") and not descendant:IsA("TextButton") then return end
    
    -- Yazı güncellendiğinde veya ilk oluştuğunda çalışacak kontrol fonksiyonu
    local function checkContent()
        local text = descendant.Text
        if not text or text == "" then return end
        
        -- Aynı cümleyi defalarca chat'e atmaması için yerel kontrol
        if reportedTexts[text] then return end
        reportedTexts[text] = true
        
        local textLower = text:lower()
        
        -- ÖNEMLİ FİLTRE: İçinde Eternal veya Divine geçiyor mu?
        if textLower:find("eternal") or textLower:find("divine") then
            sendMessageToChat(text)
            print("[OTOMATİK CHAT] Ekranda bulundu ve yazıldı: " .. text)
        end
    end
    
    -- 4. CANLI TAKİP: Yazı içeriği değişirse anında yakala
    local propConn = descendant:GetPropertyChangedSignal("Text"):Connect(checkContent)
    table.insert(_G.ChatTrackerConnection, propConn)
    
    -- İlk oluştuğunda da bir defa kontrol et
    checkContent()
end

-- 5. PlayerGui (EKRAN) ÜZERİNDEKİ HER YENİ YAZIYI VE MEVCUT YAZILARI DİNLEME
pcall(function()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Ekrana eklenen HER YENİ nesneyi anında yakala
    local conn = playerGui.DescendantAdded:Connect(handleNewText)
    table.insert(_G.ChatTrackerConnection, conn)
    
    -- Ekranda zaten var olan yazıları bir defalık tara
    for _, desc in ipairs(playerGui:GetDescendants()) do
        handleNewText(desc)
    end
end)

print("Steal an Egg - Ekran Taramalı Otomatik Chat Aktif!")
print("[DİKKAT] Ekranda 'Eternal' veya 'Divine' içeren yazı belirirse senin adına chat'e yazar.")
