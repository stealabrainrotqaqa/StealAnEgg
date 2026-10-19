local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Firebase Realtime Database URL'in
local FIREBASE_URL = "https://stealaneggnotifier-default-rtdb.firebaseio.com/egg_logs.json"

-- Daha önce bildirilen nesnelerin spam yapmaması için hafıza tablosu
local reportedObjects = {}

local function sendToFirebase(tier, textContent, objName)
    local data = {
        player = LocalPlayer.Name,
        tier = tier, -- "Eternal" veya "Divine"
        content = textContent,
        objectName = objName,
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

local function checkText(str, sourceObj)
    if not str or type(str) ~= "string" then return end
    
    -- Nesneyi benzersiz şekilde tanımla
    if reportedObjects[sourceObj] then return end
    
    local lowerStr = str:lower()
    
    if lowerStr:find("eternal") then
        reportedObjects[sourceObj] = true
        sendToFirebase("Eternal", str, sourceObj.Name)
        print("[TESPİT] Eternal bulundu: " .. sourceObj:GetFullName())
    elseif lowerStr:find("divine") then
        reportedObjects[sourceObj] = true
        sendToFirebase("Divine", str, sourceObj.Name)
        print("[TESPİT] Divine bulundu: " .. sourceObj:GetFullName())
    end
end

-- Tüm Workspace ve Arayüz Taraması (No Lag)
local function scanFullGame()
    -- 1. Workspace altındaki tüm Part / Model / Nesneleri tara
    for _, obj in ipairs(workspace:GetDescendants()) do
        -- Nesne ismi kontrolü
        checkText(obj.Name, obj)
        
        -- Eğer 3D yazı, TextLabel veya StringValue ise içerik kontrolü
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            checkText(obj.Text, obj)
        elseif obj:IsA("StringValue") then
            checkText(obj.Value, obj)
        end
    end
    
    -- 2. Oyuncu Ekran Arayüzlerini (UI/GUI) tara
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        for _, guiObj in ipairs(playerGui:GetDescendants()) do
            if guiObj:IsA("TextLabel") or guiObj:IsA("TextButton") then
                checkText(guiObj.Text, guiObj)
            end
        end
    end
end

-- Her 1 saniyede bir tüm haritayı kasma yapmadan tara
task.spawn(function()
    while task.wait(1) do
        pcall(scanFullGame)
    end
end)

print("Steal an Egg - Derin Workspace & Harita Taraması Başlatıldı!")
