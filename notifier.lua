local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Senin Firebase URL'in
local FIREBASE_URL = "https://stealaneggnotifier-default-rtdb.firebaseio.com/eggs_logs.json"

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
    
    if lowerStr:find("eternal") then
        reportedObjects[sourceObj] = true
        sendToFirebase("Eternal", str, sourceObj.Name)
        print("[TESPİT - PART] Eternal bulundu: " .. sourceObj:GetFullName())
    elseif lowerStr:find("divine") then
        reportedObjects[sourceObj] = true
        sendToFirebase("Divine", str, sourceObj.Name)
        print("[TESPİT - PART] Divine bulundu: " .. sourceObj:GetFullName())
    end
end

-- Sadece Workspace'teki 3D Part ve Part İçi Nesneleri Tarayan Fonksiyon
local function scanPhysicalParts()
    for _, obj in ipairs(workspace:GetDescendants()) do
        -- Sadece BasePart (Part, MeshPart, UnionOperation vb.) olan veya direkt bir Part'ın içinde olan öğeleri tara
        if obj:IsA("BasePart") then
            -- 1. Part'ın kendi ismini kontrol et
            checkText(obj.Name, obj)
            
            -- 2. Part'ın üzerine yapıştırılmış SurfaceGui, BillboardGui veya 3D yazıları kontrol et
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

-- Saniyede bir 3D Part taraması yap
task.spawn(function()
    while task.wait(1) do
        pcall(scanPhysicalParts)
    end
end)

print("Steal an Egg - Sadece 3D Part Taraması Aktif!")
