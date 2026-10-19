local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Firebase Realtime Database URL'in
local FIREBASE_URL = "https://stealaneggnotifier-default-rtdb.firebaseio.com/egag_logs.json"

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
    if reportedObjects[sourceObj] then return end
    
    local lowerStr = str:lower()
    
    -- ÖNEMLİ FİLTRE: Metnin veya nesnenin içinde mutlaka "egg" kelimesi geçmeli!
    if lowerStr:find("egg") or sourceObj.Name:lower():find("egg") then
        if lowerStr:find("eternal") then
            reportedObjects[sourceObj] = true
            sendToFirebase("Eternal", str, sourceObj.Name)
            print("[TESPİT - YUMURTA] Eternal Egg bulundu: " .. sourceObj:GetFullName())
        elseif lowerStr:find("divine") then
            reportedObjects[sourceObj] = true
            sendToFirebase("Divine", str, sourceObj.Name)
            print("[TESPİT - YUMURTA] Divine Egg bulundu: " .. sourceObj:GetFullName())
        end
    end
end

-- Sadece 3D Part ve İçindeki Yumurtaları Tarayan Fonksiyon
local function scanPhysicalParts()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            -- Part'ın kendi adını kontrol et
            checkText(obj.Name, obj)
            
            -- Part'ın üzerindeki tabela veya yazıları kontrol et
            for _, child in ipairs(obj:GetDescendants()) do
                if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                    checkText(child.Text, child)
                elseif child:IsA("StringValue") then
                    checkText(child.Value, child)
                end
            end
        end
    end
end

-- Saniyede bir tarama yap
task.spawn(function()
    while task.wait(1) do
        pcall(scanPhysicalParts)
    end
end)

print("Steal an Egg - Sadece 'Egg' Filtreli Taramalar Aktif!")
