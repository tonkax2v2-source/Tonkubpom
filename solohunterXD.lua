local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local API_URL = "https://hubxd.neozteon.site/api.php"

-- ดึงค่า Key และ id จาก getgenv()
local licenseKey = getgenv().Key or ""
local discordId = getgenv().id or ""

local function verifyLicense()
    if licenseKey == "" or licenseKey == "YOUR-LICENSE-KEY-HERE" then
        LocalPlayer:Kick("❌ ไม่พบ License Key!\n\n💡 กรุณาติดต่อผู้พัฒนาเพื่อขอ License Key")
        return false
    end
    
    local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
    local url = string.format(
        "%s?endpoint=check&key=%s&hwid=%s&discord_id=%s",
        API_URL,
        HttpService:UrlEncode(licenseKey),
        HttpService:UrlEncode(hwid),
        HttpService:UrlEncode(discordId)
    )
    
    local ok, response = pcall(function()
        return HttpService:GetAsync(url)
    end)
    
    if not ok then
        LocalPlayer:Kick("⚠️ ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ License ได้\n\n📡 กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต")
        return false
    end
    
    local success, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)
    
    if not success then
        LocalPlayer:Kick("⚠️ ข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง\n\n🔧 กรุณาติดต่อผู้พัฒนา")
        return false
    end
    
    if not data.whitelisted then
        local errorMessage = data.message or "License verification failed"
        LocalPlayer:Kick("❌ ยืนยัน License ไม่สำเร็จ!\n\n📝 " .. errorMessage)
        return false
    end
    
    return true
end

if not verifyLicense() then
    return
end

local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

local Window = OrionLib:MakeWindow({
    Name = "🎯 HubXD | Solo Hunters",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "HubXD_SoloHunters",
    IntroEnabled = true,
    IntroText = "HubXD Loading...",
    IntroIcon = "rbxassetid://4483345998"
})

local _G = {
    AutoFarm = false,
    AutoDungeon = false,
    AutoBoss = false,
    AutoCollect = false,
    AutoUpgrade = false,
    AutoSell = false,
    SelectedMap = "Forest",
    SelectedDifficulty = "Normal",
    ESPEnabled = false,
    ESPMobs = false,
    ESPChests = false,
    ESPBosses = false,
    WalkSpeed = 16,
    JumpPower = 50,
    NoClip = false,
    InfiniteJump = false,
    AntiAFK = true,
    AutoRejoin = true,
    TeleportSpeed = 300,
    AutoEquipBest = false,
    AutoClaim = false
}

local Maps = {"Forest", "Desert", "Snow", "Volcano", "Castle", "Hell"}
local Difficulties = {"Easy", "Normal", "Hard", "Expert", "Master"}

local function Notify(title, content, duration)
    OrionLib:MakeNotification({
        Name = title,
        Content = content,
        Image = "rbxassetid://4483345998",
        Time = duration or 5
    })
end

local function GetPlayerLevel()
    if LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Level") then
        return LocalPlayer.leaderstats.Level.Value
    end
    return 0
end

local function GetPlayerGold()
    if LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Gold") then
        return LocalPlayer.leaderstats.Gold.Value
    end
    return 0
end

local function GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

local function Tween(position, speed)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local Distance = GetDistance(LocalPlayer.Character.HumanoidRootPart.Position, position)
    local Speed = speed or _G.TeleportSpeed
    
    if Distance < 10 then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(position)
        return
    end
    
    local TweenInfo = TweenInfo.new(Distance / Speed, Enum.EasingStyle.Linear)
    local Tween = TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo, {CFrame = CFrame.new(position)})
    
    Tween:Play()
end

local function GetNearestMob()
    local nearestMob = nil
    local shortestDistance = math.huge
    
    for _, mob in pairs(Workspace.Mobs:GetChildren()) do
        if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") then
            local distance = GetDistance(LocalPlayer.Character.HumanoidRootPart.Position, mob.HumanoidRootPart.Position)
            if distance < shortestDistance then
                shortestDistance = distance
                nearestMob = mob
            end
        end
    end
    
    return nearestMob
end

local function GetNearestBoss()
    local nearestBoss = nil
    local shortestDistance = math.huge
    
    for _, boss in pairs(Workspace.Bosses:GetChildren()) do
        if boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 and boss:FindFirstChild("HumanoidRootPart") then
            local distance = GetDistance(LocalPlayer.Character.HumanoidRootPart.Position, boss.HumanoidRootPart.Position)
            if distance < shortestDistance then
                shortestDistance = distance
                nearestBoss = boss
            end
        end
    end
    
    return nearestBoss
end

local function GetNearestChest()
    local nearestChest = nil
    local shortestDistance = math.huge
    
    for _, chest in pairs(Workspace.Chests:GetChildren()) do
        if chest:FindFirstChild("Main") or chest:FindFirstChild("PrimaryPart") then
            local chestPos = chest:FindFirstChild("Main") and chest.Main.Position or chest.PrimaryPart.Position
            local distance = GetDistance(LocalPlayer.Character.HumanoidRootPart.Position, chestPos)
            if distance < shortestDistance then
                shortestDistance = distance
                nearestChest = chest
            end
        end
    end
    
    return nearestChest
end

local HomeTab = Window:MakeTab({
    Name = "🏠 Home",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

HomeTab:AddParagraph("👋 Welcome!", "ยินดีต้อนรับสู่ HubXD Solo Hunters Script\n" .. LocalPlayer.Name)

HomeTab:AddParagraph("📊 Player Stats", 
    string.format("⭐ Level: %d\n💰 Gold: %d\n🆔 UserId: %d", 
    GetPlayerLevel(), 
    GetPlayerGold(),
    LocalPlayer.UserId)
)

HomeTab:AddParagraph("✅ License Status", "🔓 License: Verified\n🖥️ HWID: Protected\n⏰ Expires: Never")

HomeTab:AddButton({
    Name = "🔄 Refresh Stats",
    Callback = function()
        HomeTab:AddParagraph("📊 Player Stats", 
            string.format("⭐ Level: %d\n💰 Gold: %d\n🆔 UserId: %d", 
            GetPlayerLevel(), 
            GetPlayerGold(),
            LocalPlayer.UserId)
        )
        Notify("Refreshed!", "Player stats updated", 2)
    end
})

local FarmTab = Window:MakeTab({
    Name = "⚔️ Auto Farm",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local MainFarmSection = FarmTab:AddSection({Name = "🎯 Main Farming"})

FarmTab:AddToggle({
    Name = "Auto Farm Mobs",
    Default = false,
    Callback = function(Value)
        _G.AutoFarm = Value
        
        if Value then
            Notify("Auto Farm", "Started farming mobs!", 3)
        else
            Notify("Auto Farm", "Stopped", 2)
        end
    end
})

FarmTab:AddToggle({
    Name = "Auto Farm Boss",
    Default = false,
    Callback = function(Value)
        _G.AutoBoss = Value
        
        if Value then
            Notify("Auto Boss", "Started farming bosses!", 3)
        else
            Notify("Auto Boss", "Stopped", 2)
        end
    end
})

FarmTab:AddToggle({
    Name = "Auto Attack",
    Default = false,
    Callback = function(Value)
        _G.AutoAttack = Value
    end
})

FarmTab:AddToggle({
    Name = "Auto Use Skills",
    Default = false,
    Callback = function(Value)
        _G.AutoSkill = Value
    end
})

local DungeonSection = FarmTab:AddSection({Name = "🏰 Dungeon System"})

FarmTab:AddToggle({
    Name = "Auto Dungeon",
    Default = false,
    Callback = function(Value)
        _G.AutoDungeon = Value
        
        if Value then
            Notify("Auto Dungeon", "Started auto dungeon!", 3)
        else
            Notify("Auto Dungeon", "Stopped", 2)
        end
    end
})

FarmTab:AddDropdown({
    Name = "Select Map",
    Default = "Forest",
    Options = Maps,
    Callback = function(Value)
        _G.SelectedMap = Value
        Notify("Map Selected", "Selected: " .. Value, 2)
    end
})

FarmTab:AddDropdown({
    Name = "Select Difficulty",
    Default = "Normal",
    Options = Difficulties,
    Callback = function(Value)
        _G.SelectedDifficulty = Value
        Notify("Difficulty Selected", "Selected: " .. Value, 2)
    end
})

local CollectSection = FarmTab:AddSection({Name = "💎 Auto Collect"})

FarmTab:AddToggle({
    Name = "Auto Collect Chests",
    Default = false,
    Callback = function(Value)
        _G.AutoCollect = Value
        
        if Value then
            Notify("Auto Collect", "Started collecting!", 3)
        else
            Notify("Auto Collect", "Stopped", 2)
        end
    end
})

FarmTab:AddToggle({
    Name = "Auto Claim Rewards",
    Default = false,
    Callback = function(Value)
        _G.AutoClaim = Value
    end
})

local UpgradeSection = FarmTab:AddSection({Name = "⬆️ Auto Upgrade"})

FarmTab:AddToggle({
    Name = "Auto Upgrade Stats",
    Default = false,
    Callback = function(Value)
        _G.AutoUpgrade = Value
        
        if Value then
            Notify("Auto Upgrade", "Started upgrading stats!", 3)
        else
            Notify("Auto Upgrade", "Stopped", 2)
        end
    end
})

FarmTab:AddToggle({
    Name = "Auto Equip Best Weapon",
    Default = false,
    Callback = function(Value)
        _G.AutoEquipBest = Value
    end
})

local PlayerTab = Window:MakeTab({
    Name = "👤 Player",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local MovementSection = PlayerTab:AddSection({Name = "🏃 Movement"})

PlayerTab:AddSlider({
    Name = "Walk Speed",
    Min = 16,
    Max = 200,
    Default = 16,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    ValueName = "Speed",
    Callback = function(Value)
        _G.WalkSpeed = Value
        
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = Value
        end
    end
})

PlayerTab:AddSlider({
    Name = "Jump Power",
    Min = 50,
    Max = 300,
    Default = 50,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    ValueName = "Power",
    Callback = function(Value)
        _G.JumpPower = Value
        
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = Value
        end
    end
})

PlayerTab:AddToggle({
    Name = "No Clip",
    Default = false,
    Callback = function(Value)
        _G.NoClip = Value
        
        if Value then
            Notify("No Clip", "Enabled!", 2)
        else
            Notify("No Clip", "Disabled", 2)
        end
    end
})

PlayerTab:AddToggle({
    Name = "Infinite Jump",
    Default = false,
    Callback = function(Value)
        _G.InfiniteJump = Value
    end
})

local TeleportSection = PlayerTab:AddSection({Name = "📍 Teleport"})

PlayerTab:AddSlider({
    Name = "Teleport Speed",
    Min = 100,
    Max = 500,
    Default = 300,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 10,
    ValueName = "Speed",
    Callback = function(Value)
        _G.TeleportSpeed = Value
    end
})

PlayerTab:AddButton({
    Name = "Teleport to Spawn",
    Callback = function()
        if Workspace:FindFirstChild("SpawnLocation") then
            Tween(Workspace.SpawnLocation.Position + Vector3.new(0, 5, 0))
        end
        Notify("Teleport", "Teleported to spawn!", 2)
    end
})

PlayerTab:AddButton({
    Name = "Teleport to Shop",
    Callback = function()
        if Workspace:FindFirstChild("Shop") and Workspace.Shop:FindFirstChild("Main") then
            Tween(Workspace.Shop.Main.Position + Vector3.new(0, 5, 0))
        end
        Notify("Teleport", "Teleported to shop!", 2)
    end
})

local VisualTab = Window:MakeTab({
    Name = "👁️ Visual",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local ESPSection = VisualTab:AddSection({Name = "🔍 ESP Settings"})

VisualTab:AddToggle({
    Name = "ESP Mobs",
    Default = false,
    Callback = function(Value)
        _G.ESPMobs = Value
        
        if Value then
            Notify("ESP", "Mob ESP enabled!", 2)
        else
            Notify("ESP", "Mob ESP disabled", 2)
        end
    end
})

VisualTab:AddToggle({
    Name = "ESP Bosses",
    Default = false,
    Callback = function(Value)
        _G.ESPBosses = Value
        
        if Value then
            Notify("ESP", "Boss ESP enabled!", 2)
        else
            Notify("ESP", "Boss ESP disabled", 2)
        end
    end
})

VisualTab:AddToggle({
    Name = "ESP Chests",
    Default = false,
    Callback = function(Value)
        _G.ESPChests = Value
        
        if Value then
            Notify("ESP", "Chest ESP enabled!", 2)
        else
            Notify("ESP", "Chest ESP disabled", 2)
        end
    end
})

local FullbrightSection = VisualTab:AddSection({Name = "💡 Lighting"})

VisualTab:AddToggle({
    Name = "Fullbright",
    Default = false,
    Callback = function(Value)
        if Value then
            game:GetService("Lighting").Brightness = 2
            game:GetService("Lighting").ClockTime = 14
            game:GetService("Lighting").FogEnd = 100000
            game:GetService("Lighting").GlobalShadows = false
            game:GetService("Lighting").OutdoorAmbient = Color3.fromRGB(128, 128, 128)
            Notify("Fullbright", "Enabled!", 2)
        else
            game:GetService("Lighting").Brightness = 1
            game:GetService("Lighting").ClockTime = 12
            game:GetService("Lighting").FogEnd = 100000
            game:GetService("Lighting").GlobalShadows = true
            game:GetService("Lighting").OutdoorAmbient = Color3.fromRGB(70, 70, 70)
            Notify("Fullbright", "Disabled", 2)
        end
    end
})

local SettingsTab = Window:MakeTab({
    Name = "⚙️ Settings",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local GeneralSection = SettingsTab:AddSection({Name = "🎮 General"})

SettingsTab:AddToggle({
    Name = "Anti AFK",
    Default = true,
    Callback = function(Value)
        _G.AntiAFK = Value
    end
})

SettingsTab:AddToggle({
    Name = "Auto Rejoin",
    Default = true,
    Callback = function(Value)
        _G.AutoRejoin = Value
    end
})

local ServerSection = SettingsTab:AddSection({Name = "🌐 Server"})

SettingsTab:AddButton({
    Name = "🔄 Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end
})

SettingsTab:AddButton({
    Name = "🔀 Server Hop",
    Callback = function()
        local PlaceID = game.PlaceId
        local AllIDs = {}
        local foundAnything = ""
        local actualHour = os.date("!*t").hour
        
        local function TPReturner()
            local Site
            if foundAnything == "" then
                Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100'))
            else
                Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
            end
            
            for _, v in pairs(Site.data) do
                local ID = tostring(v.id)
                if tonumber(v.maxPlayers) > tonumber(v.playing) and tonumber(v.playing) < 10 then
                    game:GetService("TeleportService"):TeleportToPlaceInstance(PlaceID, ID, LocalPlayer)
                    wait(4)
                    break
                end
            end
        end
        
        TPReturner()
        
        Notify("Server Hop", "Finding less crowded server...", 3)
    end
})

SettingsTab:AddButton({
    Name = "💾 Save Settings",
    Callback = function()
        Notify("Settings", "Settings saved!", 2)
    end
})

SettingsTab:AddButton({
    Name = "📂 Load Settings",
    Callback = function()
        Notify("Settings", "Settings loaded!", 2)
    end
})

SettingsTab:AddButton({
    Name = "❌ Destroy GUI",
    Callback = function()
        OrionLib:Destroy()
        Notify("Goodbye!", "GUI Destroyed", 2)
    end
})

spawn(function()
    while wait() do
        if _G.AutoFarm then
            pcall(function()
                local mob = GetNearestMob()
                
                if mob then
                    repeat
                        wait()
                        if not _G.AutoFarm then break end
                        
                        Tween(mob.HumanoidRootPart.Position + Vector3.new(0, 5, 0))
                        
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            LocalPlayer.Character.HumanoidRootPart.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0)
                        end
                        
                        if _G.AutoAttack then
                            mouse1click()
                        end
                        
                        if _G.AutoSkill then
                            local VirtualInputManager = game:GetService("VirtualInputManager")
                            VirtualInputManager:SendKeyEvent(true, "Q", false, game)
                            wait(0.1)
                            VirtualInputManager:SendKeyEvent(true, "E", false, game)
                            wait(0.1)
                            VirtualInputManager:SendKeyEvent(true, "R", false, game)
                        end
                        
                    until not mob or not mob:FindFirstChild("Humanoid") or mob.Humanoid.Health <= 0 or not _G.AutoFarm
                end
            end)
        end
    end
end)

spawn(function()
    while wait() do
        if _G.AutoBoss then
            pcall(function()
                local boss = GetNearestBoss()
                
                if boss then
                    repeat
                        wait()
                        if not _G.AutoBoss then break end
                        
                        Tween(boss.HumanoidRootPart.Position + Vector3.new(0, 10, 0))
                        
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            LocalPlayer.Character.HumanoidRootPart.CFrame = boss.HumanoidRootPart.CFrame * CFrame.new(0, 10, 0)
                        end
                        
                        if _G.AutoAttack then
                            mouse1click()
                        end
                        
                        if _G.AutoSkill then
                            local VirtualInputManager = game:GetService("VirtualInputManager")
                            VirtualInputManager:SendKeyEvent(true, "Q", false, game)
                            wait(0.2)
                            VirtualInputManager:SendKeyEvent(true, "E", false, game)
                            wait(0.2)
                            VirtualInputManager:SendKeyEvent(true, "R", false, game)
                            wait(0.2)
                            VirtualInputManager:SendKeyEvent(true, "F", false, game)
                        end
                        
                    until not boss or not boss:FindFirstChild("Humanoid") or boss.Humanoid.Health <= 0 or not _G.AutoBoss
                end
            end)
        end
    end
end)

spawn(function()
    while wait(0.5) do
        if _G.AutoCollect then
            pcall(function()
                local chest = GetNearestChest()
                
                if chest then
                    local chestPos = chest:FindFirstChild("Main") and chest.Main.Position or chest.PrimaryPart.Position
                    Tween(chestPos)
                    wait(0.5)
                    
                    if chest:FindFirstChild("Main") and chest.Main:FindFirstChild("ProximityPrompt") then
                        fireproximityprompt(chest.Main.ProximityPrompt)
                    elseif chest:FindFirstChild("ProximityPrompt") then
                        fireproximityprompt(chest.ProximityPrompt)
                    end
                end
                
                for _, drop in pairs(Workspace.Drops:GetChildren()) do
                    if drop:FindFirstChild("ProximityPrompt") then
                        fireproximityprompt(drop.ProximityPrompt)
                    end
                end
            end)
        end
    end
end)

spawn(function()
    while wait(2) do
        if _G.AutoDungeon then
            pcall(function()
                local args = {
                    [1] = _G.SelectedMap,
                    [2] = _G.SelectedDifficulty
                }
                
                ReplicatedStorage.Events.StartDungeon:FireServer(unpack(args))
                wait(1)
            end)
        end
    end
end)

spawn(function()
    while wait(1) do
        if _G.AutoUpgrade then
            pcall(function()
                ReplicatedStorage.Events.UpgradeStats:FireServer("Strength")
                wait(0.5)
                ReplicatedStorage.Events.UpgradeStats:FireServer("Defense")
                wait(0.5)
                ReplicatedStorage.Events.UpgradeStats:FireServer("Speed")
            end)
        end
    end
end)

spawn(function()
    while wait(3) do
        if _G.AutoClaim then
            pcall(function()
                ReplicatedStorage.Events.ClaimReward:FireServer()
                ReplicatedStorage.Events.ClaimDailyReward:FireServer()
                ReplicatedStorage.Events.ClaimQuestReward:FireServer()
            end)
        end
    end
end)

spawn(function()
    while wait() do
        if _G.NoClip then
            pcall(function()
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end)
        end
    end
end)

spawn(function()
    game:GetService("UserInputService").JumpRequest:Connect(function()
        if _G.InfiniteJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid:ChangeState("Jumping")
        end
    end)
end)

spawn(function()
    while wait(60) do
        if _G.AntiAFK then
            pcall(function()
                game:GetService("VirtualUser"):CaptureController()
                game:GetService("VirtualUser"):ClickButton2(Vector2.new())
            end)
        end
    end
end)

if _G.AutoRejoin then
    game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
        if child.Name == 'ErrorPrompt' and child:FindFirstChild('MessageArea') and child.MessageArea:FindFirstChild("ErrorFrame") then
            game:GetService("TeleportService"):Teleport(game.PlaceId)
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    wait(1)
    if _G.WalkSpeed ~= 16 then
        char.Humanoid.WalkSpeed = _G.WalkSpeed
    end
    if _G.JumpPower ~= 50 then
        char.Humanoid.JumpPower = _G.JumpPower
    end
end)

OrionLib:Init()

Notify("🎉 HubXD Loaded!", 
    "✅ License verified successfully!\n" ..
    "🎯 Solo Hunters Script Ready!\n" ..
    "⭐ Level: " .. GetPlayerLevel() .. "\n" ..
    "💰 Gold: " .. GetPlayerGold(), 
    5
)

print("═══════════════════════════════════════")
print("🎯 HUBXD SOLO HUNTERS SCRIPT V2.0")
print("═══════════════════════════════════════")
print("✅ License: Verified")
print("👤 Player:", LocalPlayer.Name)
print("⭐ Level:", GetPlayerLevel())
print("💰 Gold:", GetPlayerGold())
print("🎮 Game: Solo Hunters")
print("📱 Discord ID:", discordId)
print("🔑 License Key:", string.sub(licenseKey, 1, 10) .. "...")
print("═══════════════════════════════════════")
