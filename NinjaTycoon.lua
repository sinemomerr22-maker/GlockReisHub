-- // ==========================================
-- // GLOCKREISHUB - NINJA TYCOON MODULE
-- // Auto Farm + Auto Upgrade + Auto Rebirth + Auto Train
-- // Auto Collect + Teleport + ESP + Infinite Jump
-- // Anti-AFK + Godmode + Speed/Jump
-- // ==========================================

return function(Common)
    local Fluent = Common.Fluent
    local LocalPlayer = Common.LocalPlayer
    local ReplicatedStorage = Common.ReplicatedStorage
    local TeleportService = Common.TeleportService
    local TweenService = Common.TweenService
    local RunService = Common.RunService
    local UserInputService = Common.UserInputService
    local Players = Common.Players
    local Workspace = game:GetService("Workspace")
    local HttpService = game:GetService("HttpService")
    local VirtualUser = game:GetService("VirtualUser")
    
    local placeId = game.PlaceId
    
    -- ==========================================
    -- CONFIG SYSTEM
    -- ==========================================
    local DefaultConfig = {
        -- Main Settings
        WalkSpeed = 16,
        JumpPower = 50,
        
        -- Auto Farm
        AutoCollectEnabled = false,
        AutoCollectRange = 100,
        AutoCollectSpeed = 500,
        AutoCollectOnlyOwnTycoon = true,
        
        -- Auto Buttons
        AutoButtonsEnabled = false,
        AutoButtonsInterval = 0.5,
        
        -- Auto Upgrade
        AutoUpgradeEnabled = false,
        AutoUpgradeInterval = 1,
        
        -- Auto Rebirth
        AutoRebirthEnabled = false,
        AutoRebirthAmount = 1,
        
        -- Auto Train
        AutoTrainEnabled = false,
        AutoTrainInterval = 0.1,
        
        -- Combat
        GodModeEnabled = false,
        InfiniteJumpEnabled = false,
        NoclipEnabled = false,
        
        -- Teleport
        TeleportSpeed = 300,
        
        -- ESP
        ESPEnabled = false,
        ESPPlayers = true,
        ESPCoins = true,
        ESPButtons = true,
        ESPMaxDistance = 500,
        ESPColor = {R = 255, G = 0, B = 0},
        
        -- Anti-AFK
        AntiAFKEnabled = true,
    }
    
    local ConfigManager = Common.setupConfigManager("NinjaTycoon_Config")
    local Config = ConfigManager.Load(DefaultConfig)
    
    local ui = Common.loadFluentUI("Ninja Tycoon", placeId)
    local Tabs = {}
    
    -- ==========================================
    -- FARM STATE
    -- ==========================================
    local FarmState = {
        AutoCollectEnabled = Config.AutoCollectEnabled,
        AutoCollectRange = Config.AutoCollectRange or 100,
        AutoCollectSpeed = Config.AutoCollectSpeed or 500,
        AutoCollectOnlyOwnTycoon = Config.AutoCollectOnlyOwnTycoon,
        
        AutoButtonsEnabled = Config.AutoButtonsEnabled,
        AutoButtonsInterval = Config.AutoButtonsInterval or 0.5,
        
        AutoUpgradeEnabled = Config.AutoUpgradeEnabled,
        AutoUpgradeInterval = Config.AutoUpgradeInterval or 1,
        
        AutoRebirthEnabled = Config.AutoRebirthEnabled,
        AutoRebirthAmount = Config.AutoRebirthAmount or 1,
        
        AutoTrainEnabled = Config.AutoTrainEnabled,
        AutoTrainInterval = Config.AutoTrainInterval or 0.1,
        
        GodModeEnabled = Config.GodModeEnabled,
        InfiniteJumpEnabled = Config.InfiniteJumpEnabled,
        NoclipEnabled = Config.NoclipEnabled,
        
        ESPEnabled = Config.ESPEnabled,
        ESPPlayers = Config.ESPPlayers,
        ESPCoins = Config.ESPCoins,
        ESPButtons = Config.ESPButtons,
        ESPMaxDistance = Config.ESPMaxDistance or 500,
        ESPColor = Color3.new(
            (Config.ESPColor and Config.ESPColor.R or 255)/255,
            (Config.ESPColor and Config.ESPColor.G or 0)/255,
            (Config.ESPColor and Config.ESPColor.B or 0)/255
        ),
        
        AntiAFKEnabled = Config.AntiAFKEnabled,
        
        -- Stats
        CoinsCollected = 0,
        ButtonsClicked = 0,
        UpgradesBought = 0,
        RebirthsDone = 0,
        TrainingsDone = 0,
    }
    
    -- ==========================================
    -- HELPER FUNCTIONS
    -- ==========================================
    
    -- Find player's tycoon
    local function getOwnTycoon()
        local tycoons = Workspace:FindFirstChild("Tycoons") or Workspace:FindFirstChild("tycoons")
        if not tycoons then return nil end
        
        for _, tycoon in pairs(tycoons:GetChildren()) do
            local owner = tycoon:FindFirstChild("Owner") or tycoon:FindFirstChild("owner")
            if owner then
                if owner:IsA("ObjectValue") and owner.Value == LocalPlayer then
                    return tycoon
                elseif owner:IsA("StringValue") and owner.Value == LocalPlayer.Name then
                    return tycoon
                end
            end
            
            -- Check tycoon name
            if tycoon.Name:find(LocalPlayer.Name, 1, true) then
                return tycoon
            end
        end
        
        return nil
    end
    
    -- Get all tycoons
    local function getAllTycoons()
        local result = {}
        local tycoons = Workspace:FindFirstChild("Tycoons") or Workspace:FindFirstChild("tycoons")
        if tycoons then
            for _, tycoon in pairs(tycoons:GetChildren()) do
                table.insert(result, tycoon)
            end
        end
        return result
    end
    
    -- Tween helper
    local function tweenTo(pos, speed)
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        speed = speed or FarmState.AutoCollectSpeed
        local distance = (hrp.Position - pos).Magnitude
        local info = TweenInfo.new(distance / speed, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(hrp, info, {CFrame = CFrame.new(pos)})
        tween:Play()
        return tween
    end
    
    -- Find remotes
    local function findRemotes()
        local remotes = {
            Events = {},
            Functions = {}
        }
        
        local function searchFolder(folder, path)
            for _, child in pairs(folder:GetChildren()) do
                if child:IsA("RemoteEvent") then
                    remotes.Events[child.Name] = child
                elseif child:IsA("RemoteFunction") then
                    remotes.Functions[child.Name] = child
                elseif child:IsA("Folder") then
                    searchFolder(child, path .. "/" .. child.Name)
                end
            end
        end
        
        pcall(function()
            if ReplicatedStorage then
                searchFolder(ReplicatedStorage, "RS")
            end
        end)
        
        return remotes
    end
    
    local Remotes = findRemotes()
    
    -- Fire remote safely
    local function fireRemote(name, ...)
        local event = Remotes.Events[name]
        if event then
            pcall(function()
                event:FireServer(...)
            end)
            return true
        end
        return false
    end
    
    local function invokeRemote(name, ...)
        local func = Remotes.Functions[name]
        if func then
            local ok, result = pcall(function()
                return func:InvokeServer(...)
            end)
            if ok then return result end
        end
        return nil
    end
    
    -- ==========================================
    -- TABS
    -- ==========================================
    Tabs.Main = ui.Window:AddTab({ Title = "Main", Icon = "home" })
    Tabs.AutoFarm = ui.Window:AddTab({ Title = "Auto Farm", Icon = "coins" })
    Tabs.AutoUpgrade = ui.Window:AddTab({ Title = "Upgrades", Icon = "trending-up" })
    Tabs.Combat = ui.Window:AddTab({ Title = "Combat", Icon = "shield" })
    Tabs.Teleport = ui.Window:AddTab({ Title = "Teleport", Icon = "map" })
    Tabs.ESP = ui.Window:AddTab({ Title = "ESP", Icon = "eye" })
    Tabs.Settings = ui.Window:AddTab({ Title = "Settings", Icon = "settings" })
    
    -- ==========================================
    -- MAIN TAB
    -- ==========================================
    Tabs.Main:AddParagraph({
        Title = "🥷 Ninja Tycoon Hub",
        Content = "GlockreisHub - Ultimate Ninja Tycoon Cheat\n\n" ..
            "✅ Auto Collect Coins\n" ..
            "✅ Auto Click Buttons\n" ..
            "✅ Auto Upgrade\n" ..
            "✅ Auto Rebirth\n" ..
            "✅ Auto Train\n" ..
            "✅ Godmode + Infinite Jump + Noclip\n" ..
            "✅ ESP (Players/Coins/Buttons)\n" ..
            "✅ Teleport System\n" ..
            "✅ Anti-AFK (Always On)\n\n" ..
            "⚠️ Use in private servers for safety!"
    })
    
    -- Status display
    local StatusDisplay = Tabs.Main:AddParagraph({
        Title = "Status",
        Content = "Initializing..."
    })
    
    task.spawn(function()
        while true do
            local ownTycoon = getOwnTycoon()
            local tycoonName = ownTycoon and ownTycoon.Name or "Not Found"
            
            StatusDisplay.Content = string.format(
                "📊 Session Stats:\n\n" ..
                "🪙 Coins Collected: %d\n" ..
                "🔘 Buttons Clicked: %d\n" ..
                "⬆️ Upgrades Bought: %d\n" ..
                "🔄 Rebirths Done: %d\n" ..
                "🥷 Trainings Done: %d\n\n" ..
                "🏯 Your Tycoon: %s\n" ..
                "📡 Remotes Found: %d Events, %d Functions",
                FarmState.CoinsCollected,
                FarmState.ButtonsClicked,
                FarmState.UpgradesBought,
                FarmState.RebirthsDone,
                FarmState.TrainingsDone,
                tycoonName,
                #Remotes.Events or 0,
                #Remotes.Functions or 0
            )
            task.wait(1)
        end
    end)
    
    -- ==========================================
    -- AUTO FARM TAB
    -- ==========================================
    Tabs.AutoFarm:AddParagraph({
        Title = "💰 Auto Farm System",
        Content = "Automatically collects coins and clicks buttons.\n\n" ..
            "🪙 Auto Collect: Teleport to coins and collect them\n" ..
            "🔘 Auto Buttons: Click all tycoon buttons automatically\n" ..
            "⚡ Auto Train: Spam train button for XP"
    })
    
    -- Auto Collect Section
    Tabs.AutoFarm:AddSection("Coin Collection")
    
    Tabs.AutoFarm:AddToggle("AutoCollectToggle", {
        Title = "Enable Auto Collect",
        Description = "Teleport to and collect all nearby coins",
        Default = Config.AutoCollectEnabled
    }):OnChanged(function(v)
        FarmState.AutoCollectEnabled = v
        Config.AutoCollectEnabled = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.AutoFarm:AddSlider("AutoCollectRangeSlider", {
        Title = "Collect Range (studs)",
        Default = Config.AutoCollectRange,
        Min = 10, Max = 1000, Rounding = 0,
        Callback = function(v)
            FarmState.AutoCollectRange = v
            Config.AutoCollectRange = v
            ConfigManager.Save(Config)
        end
    })
    
    Tabs.AutoFarm:AddSlider("AutoCollectSpeedSlider", {
        Title = "Collect Speed (studs/s)",
        Default = Config.AutoCollectSpeed,
        Min = 100, Max = 5000, Rounding = 0,
        Callback = function(v)
            FarmState.AutoCollectSpeed = v
            Config.AutoCollectSpeed = v
            ConfigManager.Save(Config)
        end
    })
    
    Tabs.AutoFarm:AddToggle("AutoCollectOwnOnlyToggle", {
        Title = "Only Own Tycoon",
        Description = "Only collect coins from your own tycoon",
        Default = Config.AutoCollectOnlyOwnTycoon
    }):OnChanged(function(v)
        FarmState.AutoCollectOnlyOwnTycoon = v
        Config.AutoCollectOnlyOwnTycoon = v
        ConfigManager.Save(Config)
    end)
    
    -- Auto Collect Logic
    task.spawn(function()
        while true do
            if FarmState.AutoCollectEnabled and LocalPlayer.Character then
                pcall(function()
                    local char = LocalPlayer.Character
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    
                    local coins = {}
                    
                    -- Find all coin objects
                    local function findCoins(folder)
                        for _, obj in pairs(folder:GetDescendants()) do
                            local nameLower = obj.Name:lower()
                            if (obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("Model")) and
                               (nameLower:find("coin") or nameLower:find("cash") or nameLower:find("money") or nameLower:find("drop")) then
                                
                                local pos = obj:IsA("Model") and obj.PrimaryPart and obj.PrimaryPart.Position or obj.Position
                                if pos then
                                    local dist = (hrp.Position - pos).Magnitude
                                    if dist <= FarmState.AutoCollectRange then
                                        table.insert(coins, {obj = obj, pos = pos, dist = dist})
                                    end
                                end
                            end
                        end
                    end
                    
                    if FarmState.AutoCollectOnlyOwnTycoon then
                        local ownTycoon = getOwnTycoon()
                        if ownTycoon then
                            findCoins(ownTycoon)
                        end
                    else
                        findCoins(Workspace)
                    end
                    
                    -- Sort by distance
                    table.sort(coins, function(a, b) return a.dist < b.dist end)
                    
                    -- Collect closest coin
                    if #coins > 0 then
                        local coin = coins[1]
                        
                        -- Move to coin
                        hrp.CFrame = CFrame.new(coin.pos)
                        
                        -- Try to collect via remote
                        pcall(function()
                            fireRemote("CollectCoin", coin.obj)
                            fireRemote("Collect", coin.obj)
                            fireRemote("Pickup", coin.obj)
                        end)
                        
                        -- Try click detector
                        local clickDetector = coin.obj:FindFirstChildOfClass("ClickDetector")
                        if clickDetector then
                            pcall(function()
                                fireclickdetector(clickDetector)
                            end)
                        end
                        
                        -- Try touching
                        pcall(function()
                            firetouchinterest(hrp, coin.obj, 0)
                            task.wait(0.05)
                            firetouchinterest(hrp, coin.obj, 1)
                        end)
                        
                        FarmState.CoinsCollected = FarmState.CoinsCollected + 1
                    end
                end)
            end
            task.wait(0.1)
        end
    end)
    
    -- Auto Buttons Section
    Tabs.AutoFarm:AddSection("Auto Buttons")
    
    Tabs.AutoFarm:AddToggle("AutoButtonsToggle", {
        Title = "Enable Auto Buttons",
        Description = "Automatically click all tycoon buttons (upgrades, droppers, etc.)",
        Default = Config.AutoButtonsEnabled
    }):OnChanged(function(v)
        FarmState.AutoButtonsEnabled = v
        Config.AutoButtonsEnabled = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.AutoFarm:AddSlider("AutoButtonsIntervalSlider", {
        Title = "Button Click Interval (s)",
        Default = Config.AutoButtonsInterval,
        Min = 0.1, Max = 5, Rounding = 1,
        Callback = function(v)
            FarmState.AutoButtonsInterval = v
            Config.AutoButtonsInterval = v
            ConfigManager.Save(Config)
        end
    })
    
    -- Auto Buttons Logic
    task.spawn(function()
        while true do
            if FarmState.AutoButtonsEnabled and LocalPlayer.Character then
                pcall(function()
                    local char = LocalPlayer.Character
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    
                    local ownTycoon = getOwnTycoon()
                    if not ownTycoon then return end
                    
                    -- Find all buttons
                    for _, obj in pairs(ownTycoon:GetDescendants()) do
                        local nameLower = obj.Name:lower()
                        if (nameLower:find("button") or nameLower:find("buy") or nameLower:find("upgrade")) and
                           (obj:IsA("Part") or obj:IsA("MeshPart")) then
                            
                            -- Click detector
                            local clickDetector = obj:FindFirstChildOfClass("ClickDetector")
                            if clickDetector then
                                pcall(function()
                                    fireclickdetector(clickDetector)
                                    FarmState.ButtonsClicked = FarmState.ButtonsClicked + 1
                                end)
                            end
                            
                            -- Proximity prompt
                            local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                            if prompt then
                                pcall(function()
                                    fireproximityprompt(prompt)
                                    FarmState.ButtonsClicked = FarmState.ButtonsClicked + 1
                                end)
                            end
                            
                            -- Touch
                            pcall(function()
                                firetouchinterest(hrp, obj, 0)
                                task.wait(0.05)
                                firetouchinterest(hrp, obj, 1)
                            end)
                        end
                    end
                end)
            end
            task.wait(FarmState.AutoButtonsInterval or 0.5)
        end
    end)
    
    -- Auto Train Section
    Tabs.AutoFarm:AddSection("Auto Training")
    
    Tabs.AutoFarm:AddToggle("AutoTrainToggle", {
        Title = "Enable Auto Train",
        Description = "Automatically spam train button for XP/strength",
        Default = Config.AutoTrainEnabled
    }):OnChanged(function(v)
        FarmState.AutoTrainEnabled = v
        Config.AutoTrainEnabled = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.AutoFarm:AddSlider("AutoTrainIntervalSlider", {
        Title = "Train Interval (s)",
        Default = Config.AutoTrainInterval,
        Min = 0.05, Max = 2, Rounding = 2,
        Callback = function(v)
            FarmState.AutoTrainInterval = v
            Config.AutoTrainInterval = v
            ConfigManager.Save(Config)
        end
    })
    
    -- Auto Train Logic
    task.spawn(function()
        while true do
            if FarmState.AutoTrainEnabled and LocalPlayer.Character then
                pcall(function()
                    local char = LocalPlayer.Character
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    
                    local ownTycoon = getOwnTycoon()
                    if not ownTycoon then return end
                    
                    -- Find training areas/buttons
                    for _, obj in pairs(ownTycoon:GetDescendants()) do
                        local nameLower = obj.Name:lower()
                        if (nameLower:find("train") or nameLower:find("punch") or nameLower:find("kick") or nameLower:find("bag")) and
                           (obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("Model")) then
                            
                            local targetPart = obj:IsA("Model") and obj.PrimaryPart or obj
                            if targetPart and targetPart.Position then
                                -- Teleport to training area
                                hrp.CFrame = CFrame.new(targetPart.Position + Vector3.new(0, 3, 0))
                                
                                -- Click
                                local clickDetector = targetPart:FindFirstChildOfClass("ClickDetector") or obj:FindFirstChildOfClass("ClickDetector")
                                if clickDetector then
                                    pcall(function()
                                        fireclickdetector(clickDetector)
                                        FarmState.TrainingsDone = FarmState.TrainingsDone + 1
                                    end)
                                end
                                
                                -- Touch
                                pcall(function()
                                    firetouchinterest(hrp, targetPart, 0)
                                    task.wait(0.05)
                                    firetouchinterest(hrp, targetPart, 1)
                                end)
                                
                                -- Remote
                                pcall(function()
                                    fireRemote("Train", obj)
                                    fireRemote("Punch", obj)
                                    fireRemote("Hit", obj)
                                end)
                            end
                        end
                    end
                end)
            end
            task.wait(FarmState.AutoTrainInterval or 0.1)
        end
    end)
    
    -- ==========================================
    -- AUTO UPGRADE TAB
    -- ==========================================
    Tabs.AutoUpgrade:AddParagraph({
        Title = "⬆️ Auto Upgrade System",
        Content = "Automatically buy upgrades, weapons, and rebirths.\n\n" ..
            "⚡ Auto Upgrade: Buy all available upgrades\n" ..
            "🔄 Auto Rebirth: Rebirth when possible\n" ..
            "⚔️ Auto Buy Weapons: Buy best weapons"
    })
    
    Tabs.AutoUpgrade:AddToggle("AutoUpgradeToggle", {
        Title = "Enable Auto Upgrade",
        Description = "Automatically buy all available tycoon upgrades",
        Default = Config.AutoUpgradeEnabled
    }):OnChanged(function(v)
        FarmState.AutoUpgradeEnabled = v
        Config.AutoUpgradeEnabled = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.AutoUpgrade:AddSlider("AutoUpgradeIntervalSlider", {
        Title = "Upgrade Interval (s)",
        Default = Config.AutoUpgradeInterval,
        Min = 0.5, Max = 10, Rounding = 1,
        Callback = function(v)
            FarmState.AutoUpgradeInterval = v
            Config.AutoUpgradeInterval = v
            ConfigManager.Save(Config)
        end
    })
    
    -- Auto Upgrade Logic
    task.spawn(function()
        while true do
            if FarmState.AutoUpgradeEnabled and LocalPlayer.Character then
                pcall(function()
                    local ownTycoon = getOwnTycoon()
                    if not ownTycoon then return end
                    
                    -- Find upgrade buttons
                    for _, obj in pairs(ownTycoon:GetDescendants()) do
                        local nameLower = obj.Name:lower()
                        if (nameLower:find("upgrade") or nameLower:find("buy") or nameLower:find("purchase")) and
                           (obj:IsA("Part") or obj:IsA("MeshPart")) then
                            
                            local clickDetector = obj:FindFirstChildOfClass("ClickDetector")
                            if clickDetector then
                                pcall(function()
                                    fireclickdetector(clickDetector)
                                    FarmState.UpgradesBought = FarmState.UpgradesBought + 1
                                end)
                            end
                        end
                    end
                    
                    -- Try remote upgrade
                    pcall(function()
                        fireRemote("BuyUpgrade")
                        fireRemote("Upgrade")
                        fireRemote("Purchase")
                    end)
                end)
            end
            task.wait(FarmState.AutoUpgradeInterval or 1)
        end
    end)
    
    Tabs.AutoUpgrade:AddSection("Auto Rebirth")
    
    Tabs.AutoUpgrade:AddToggle("AutoRebirthToggle", {
        Title = "Enable Auto Rebirth",
        Description = "Automatically rebirth when possible",
        Default = Config.AutoRebirthEnabled
    }):OnChanged(function(v)
        FarmState.AutoRebirthEnabled = v
        Config.AutoRebirthEnabled = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.AutoUpgrade:AddSlider("AutoRebirthAmountSlider", {
        Title = "Rebirth Amount (per cycle)",
        Default = Config.AutoRebirthAmount,
        Min = 1, Max = 100, Rounding = 0,
        Callback = function(v)
            FarmState.AutoRebirthAmount = v
            Config.AutoRebirthAmount = v
            ConfigManager.Save(Config)
        end
    })
    
    -- Auto Rebirth Logic
    task.spawn(function()
        while true do
            if FarmState.AutoRebirthEnabled and LocalPlayer.Character then
                pcall(function()
                    -- Find rebirth button
                    local rebirthFound = false
                    
                    for _, obj in pairs(Workspace:GetDescendants()) do
                        local nameLower = obj.Name:lower()
                        if nameLower:find("rebirth") and (obj:IsA("Part") or obj:IsA("MeshPart")) then
                            local clickDetector = obj:FindFirstChildOfClass("ClickDetector")
                            if clickDetector then
                                for i = 1, FarmState.AutoRebirthAmount do
                                    pcall(function()
                                        fireclickdetector(clickDetector)
                                        FarmState.RebirthsDone = FarmState.RebirthsDone + 1
                                    end)
                                    task.wait(0.1)
                                end
                                rebirthFound = true
                                break
                            end
                        end
                    end
                    
                    -- Try remote rebirth
                    if not rebirthFound then
                        pcall(function()
                            for i = 1, FarmState.AutoRebirthAmount do
                                if fireRemote("Rebirth") then
                                    FarmState.RebirthsDone = FarmState.RebirthsDone + 1
                                end
                                task.wait(0.1)
                            end
                        end)
                    end
                end)
            end
            task.wait(5)
        end
    end)
    
    -- ==========================================
    -- COMBAT TAB
    -- ==========================================
    Tabs.Combat:AddParagraph({
        Title = "⚔️ Combat Features",
        Content = "Survival and movement cheats.\n\n" ..
            "🛡️ Godmode: Infinite health\n" ..
            "🦘 Infinite Jump: Jump in air\n" ..
            "👻 Noclip: Walk through walls\n" ..
            "⚡ Speed/Jump: Custom values"
    })
    
    Tabs.Combat:AddToggle("GodModeToggle", {
        Title = "Enable Godmode",
        Description = "Never die - infinite health",
        Default = Config.GodModeEnabled
    }):OnChanged(function(v)
        FarmState.GodModeEnabled = v
        Config.GodModeEnabled = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.Combat:AddToggle("InfiniteJumpToggle", {
        Title = "Enable Infinite Jump",
        Description = "Jump multiple times in air",
        Default = Config.InfiniteJumpEnabled
    }):OnChanged(function(v)
        FarmState.InfiniteJumpEnabled = v
        Config.InfiniteJumpEnabled = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.Combat:AddToggle("NoclipToggle", {
        Title = "Enable Noclip",
        Description = "Walk through walls",
        Default = Config.NoclipEnabled
    }):OnChanged(function(v)
        FarmState.NoclipEnabled = v
        Config.NoclipEnabled = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.Combat:AddSlider("WalkSpeedSlider", {
        Title = "Walk Speed",
        Default = Config.WalkSpeed,
        Min = 16, Max = 500, Rounding = 0,
        Callback = function(v)
            Config.WalkSpeed = v
            ConfigManager.Save(Config)
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then hum.WalkSpeed = v end
                end
            end)
        end
    })
    
    Tabs.Combat:AddSlider("JumpPowerSlider", {
        Title = "Jump Power",
        Default = Config.JumpPower,
        Min = 50, Max = 1000, Rounding = 0,
        Callback = function(v)
            Config.JumpPower = v
            ConfigManager.Save(Config)
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum.JumpPower = v
                        hum.JumpHeight = v * 0.35
                    end
                end
            end)
        end
    })
    
    -- Godmode Logic
    task.spawn(function()
        while true do
            if FarmState.GodModeEnabled and LocalPlayer.Character then
                pcall(function()
                    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum.Health = hum.MaxHealth
                        hum.MaxHealth = math.huge
                    end
                end)
            end
            task.wait(0.1)
        end
    end)
    
    -- Infinite Jump Logic
    local jumpConnection
    UserInputService.JumpRequest:Connect(function()
        if FarmState.InfiniteJumpEnabled and LocalPlayer.Character then
            pcall(function()
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end
    end)
    
    -- Noclip Logic
    RunService.Stepped:Connect(function()
        if FarmState.NoclipEnabled and LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
    
    -- Apply walk speed/jump on character spawn
    LocalPlayer.CharacterAdded:Connect(function(char)
        char:WaitForChild("Humanoid")
        task.wait(0.5)
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = Config.WalkSpeed
            hum.JumpPower = Config.JumpPower
            hum.JumpHeight = Config.JumpPower * 0.35
        end
    end)
    
    -- ==========================================
    -- TELEPORT TAB
    -- ==========================================
    Tabs.Teleport:AddParagraph({
        Title = "🗺️ Teleport System",
        Content = "Teleport to important locations."
    })
    
    Tabs.Teleport:AddSlider("TeleportSpeedSlider", {
        Title = "Teleport Speed (studs/s)",
        Default = Config.TeleportSpeed,
        Min = 100, Max = 5000, Rounding = 0,
        Callback = function(v)
            Config.TeleportSpeed = v
            ConfigManager.Save(Config)
        end
    })
    
    Tabs.Teleport:AddButton({
        Title = "🏯 Teleport to Own Tycoon",
        Callback = function()
            local tycoon = getOwnTycoon()
            if tycoon then
                local primaryPart = tycoon.PrimaryPart or tycoon:FindFirstChildWhichIsA("BasePart", true)
                if primaryPart then
                    tweenTo(primaryPart.Position, Config.TeleportSpeed)
                    ui.Fluent:Notify({
                        Title = "[TP] Success",
                        Content = "Teleported to your tycoon",
                        Duration = 2
                    })
                end
            else
                ui.Fluent:Notify({
                    Title = "[TP] Error",
                    Content = "Your tycoon not found",
                    Duration = 2
                })
            end
        end
    })
    
    Tabs.Teleport:AddButton({
        Title = "🛒 Teleport to Shop",
        Callback = function()
            local shop = Workspace:FindFirstChild("Shop") or 
                        Workspace:FindFirstChild("shop") or
                        Workspace:FindFirstChild("Store")
            if shop then
                local pos = shop:IsA("Model") and shop.PrimaryPart and shop.PrimaryPart.Position or shop.Position
                if pos then
                    tweenTo(pos, Config.TeleportSpeed)
                end
            else
                -- Search for shop
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj.Name:lower():find("shop") and obj:IsA("Model") then
                        if obj.PrimaryPart then
                            tweenTo(obj.PrimaryPart.Position, Config.TeleportSpeed)
                            break
                        end
                    end
                end
            end
        end
    })
    
    Tabs.Teleport:AddButton({
        Title = "🥷 Teleport to Training Area",
        Callback = function()
            for _, obj in pairs(Workspace:GetDescendants()) do
                local nameLower = obj.Name:lower()
                if (nameLower:find("training") or nameLower:find("dojo")) and obj:IsA("Model") then
                    if obj.PrimaryPart then
                        tweenTo(obj.PrimaryPart.Position, Config.TeleportSpeed)
                        break
                    end
                end
            end
        end
    })
    
    Tabs.Teleport:AddButton({
        Title = "🎁 Teleport to Rebirth Area",
        Callback = function()
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj.Name:lower():find("rebirth") and obj:IsA("Model") then
                    if obj.PrimaryPart then
                        tweenTo(obj.PrimaryPart.Position, Config.TeleportSpeed)
                        break
                    end
                end
            end
        end
    })
    
    Tabs.Teleport:AddButton({
        Title = "🎲 Teleport to Spawn",
        Callback = function()
            local spawn = Workspace:FindFirstChild("Spawn") or
                         Workspace:FindFirstChild("spawn") or
                         Workspace:FindFirstChild("SpawnLocation")
            if spawn then
                local pos = spawn:IsA("Model") and spawn.PrimaryPart and spawn.PrimaryPart.Position or spawn.Position
                if pos then
                    tweenTo(pos, Config.TeleportSpeed)
                end
            end
        end
    })
    
    -- Teleport to other players
    Tabs.Teleport:AddSection("Teleport to Players")
    
    local playerDropdown = Tabs.Teleport:AddDropdown("PlayerDropdown", {
        Title = "Select Player",
        Values = {},
        Multi = false,
        Default = 1,
    })
    
    -- Update player list
    task.spawn(function()
        while true do
            local playerNames = {}
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    table.insert(playerNames, player.Name)
                end
            end
            pcall(function()
                playerDropdown:SetValues(playerNames)
            end)
            task.wait(5)
        end
    end)
    
    Tabs.Teleport:AddButton({
        Title = "🎯 Teleport to Selected Player",
        Callback = function()
            local selected = Fluent.Options.PlayerDropdown and Fluent.Options.PlayerDropdown.Value
            if selected then
                local targetPlayer = Players:FindFirstChild(selected)
                if targetPlayer and targetPlayer.Character then
                    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if targetHRP then
                        tweenTo(targetHRP.Position, Config.TeleportSpeed)
                    end
                end
            end
        end
    })
    
    -- ==========================================
    -- ESP TAB
    -- ==========================================
    Tabs.ESP:AddParagraph({
        Title = "👁️ ESP System",
        Content = "See players, coins, and buttons through walls."
    })
    
    Tabs.ESP:AddToggle("ESPToggle", {
        Title = "Enable ESP",
        Default = Config.ESPEnabled
    }):OnChanged(function(v)
        FarmState.ESPEnabled = v
        Config.ESPEnabled = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.ESP:AddToggle("ESPPlayersToggle", {
        Title = "Show Players",
        Default = Config.ESPPlayers
    }):OnChanged(function(v)
        FarmState.ESPPlayers = v
        Config.ESPPlayers = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.ESP:AddToggle("ESPCoinsToggle", {
        Title = "Show Coins",
        Default = Config.ESPCoins
    }):OnChanged(function(v)
        FarmState.ESPCoins = v
        Config.ESPCoins = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.ESP:AddToggle("ESPButtonsToggle", {
        Title = "Show Buttons",
        Default = Config.ESPButtons
    }):OnChanged(function(v)
        FarmState.ESPButtons = v
        Config.ESPButtons = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.ESP:AddSlider("ESPRangeSlider", {
        Title = "ESP Max Distance",
        Default = Config.ESPMaxDistance,
        Min = 50, Max = 2000, Rounding = 0,
        Callback = function(v)
            FarmState.ESPMaxDistance = v
            Config.ESPMaxDistance = v
            ConfigManager.Save(Config)
        end
    })
    
    Tabs.ESP:AddColorpicker("ESPColorPicker", {
        Title = "ESP Color",
        Default = FarmState.ESPColor
    }):OnChanged(function(color)
        FarmState.ESPColor = color
        Config.ESPColor = {
            R = math.floor(color.R * 255),
            G = math.floor(color.G * 255),
            B = math.floor(color.B * 255)
        }
        ConfigManager.Save(Config)
    end)
    
    -- ESP Logic
    local ESPHighlights = {}
    
    local function createESP(obj, color, name)
        if ESPHighlights[obj] then
            pcall(function() ESPHighlights[obj]:Destroy() end)
        end
        
        local highlight = Instance.new("Highlight")
        highlight.Name = "GlockESP_" .. (name or obj.Name)
        highlight.FillColor = color or FarmState.ESPColor
        highlight.FillTransparency = 0.7
        highlight.OutlineColor = color or FarmState.ESPColor
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = obj
        highlight.Parent = obj
        
        ESPHighlights[obj] = highlight
        return highlight
    end
    
    local function removeESP(obj)
        if ESPHighlights[obj] then
            pcall(function() ESPHighlights[obj]:Destroy() end)
            ESPHighlights[obj] = nil
        end
    end
    
    -- Update ESP
    task.spawn(function()
        while true do
            if FarmState.ESPEnabled then
                -- Players
                if FarmState.ESPPlayers then
                    for _, player in pairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character then
                            if not ESPHighlights[player.Character] then
                                createESP(player.Character, Color3.fromRGB(255, 0, 0), "Player_" .. player.Name)
                            end
                        end
                    end
                end
                
                -- Coins
                if FarmState.ESPCoins then
                    pcall(function()
                        for _, obj in pairs(Workspace:GetDescendants()) do
                            local nameLower = obj.Name:lower()
                            if (obj:IsA("Part") or obj:IsA("MeshPart")) and
                               (nameLower:find("coin") or nameLower:find("cash")) then
                                if not ESPHighlights[obj] then
                                    createESP(obj, Color3.fromRGB(255, 215, 0), "Coin")
                                end
                            end
                        end
                    end)
                end
                
                -- Buttons
                if FarmState.ESPButtons then
                    pcall(function()
                        local ownTycoon = getOwnTycoon()
                        if ownTycoon then
                            for _, obj in pairs(ownTycoon:GetDescendants()) do
                                local nameLower = obj.Name:lower()
                                if (obj:IsA("Part") or obj:IsA("MeshPart")) and
                                   (nameLower:find("button") or nameLower:find("upgrade")) then
                                    if not ESPHighlights[obj] then
                                        createESP(obj, Color3.fromRGB(0, 255, 0), "Button")
                                    end
                                end
                            end
                        end
                    end)
                end
                
                -- Remove ESP from destroyed objects
                for obj, highlight in pairs(ESPHighlights) do
                    if not obj or not obj.Parent then
                        removeESP(obj)
                    else
                        -- Update distance visibility
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp and obj:IsA("BasePart") then
                            local dist = (hrp.Position - obj.Position).Magnitude
                            highlight.Enabled = dist <= FarmState.ESPMaxDistance
                        elseif hrp and obj:IsA("Model") and obj.PrimaryPart then
                            local dist = (hrp.Position - obj.PrimaryPart.Position).Magnitude
                            highlight.Enabled = dist <= FarmState.ESPMaxDistance
                        end
                    end
                end
            else
                -- Remove all ESP
                for obj, _ in pairs(ESPHighlights) do
                    removeESP(obj)
                end
            end
            task.wait(1)
        end
    end)
    
    -- Clean up ESP when players leave
    Players.PlayerRemoving:Connect(function(player)
        if player.Character then
            removeESP(player.Character)
        end
    end)
    
    -- ==========================================
    -- SETTINGS TAB
    -- ==========================================
    Tabs.Settings:AddParagraph({
        Title = "⚙️ Settings",
        Content = "Global settings and utilities."
    })
    
    -- Anti-AFK (Always active)
    Tabs.Settings:AddToggle("AntiAFKToggle", {
        Title = "Anti-AFK (Always Active)",
        Description = "Prevents being kicked for inactivity",
        Default = Config.AntiAFKEnabled
    }):OnChanged(function(v)
        FarmState.AntiAFKEnabled = v
        Config.AntiAFKEnabled = v
        ConfigManager.Save(Config)
    end)
    
    -- Anti-AFK Logic (always running)
    task.spawn(function()
        while true do
            if FarmState.AntiAFKEnabled then
                pcall(function()
                    LocalPlayer.Idled:Connect(function()
                        VirtualUser:CaptureController()
                        VirtualUser:ClickButton2(Vector2.new())
                    end)
                end)
            end
            task.wait(60)
        end
    end)
    
    -- Rejoin button
    Tabs.Settings:AddButton({
        Title = "🔄 Rejoin Server",
        Callback = function()
            pcall(function()
                TeleportService:Teleport(placeId, LocalPlayer)
            end)
        end
    })
    
    -- Server hop
    Tabs.Settings:AddButton({
        Title = "🎲 Server Hop",
        Callback = function()
            pcall(function()
                local servers = {}
                local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", placeId)
                -- Simplified hop - just rejoin
                TeleportService:Teleport(placeId, LocalPlayer)
            end)
        end
    })
    
    -- Reset config
    Tabs.Settings:AddButton({
        Title = "🗑️ Reset Config",
        Callback = function()
            ConfigManager.Save(DefaultConfig)
            ui.Fluent:Notify({
                Title = "[OK]",
                Content = "Config reset to default",
                Duration = 2
            })
        end
    })
    
    -- Debug: Print remotes
    Tabs.Settings:AddButton({
        Title = "🔍 List Remotes (Console)",
        Callback = function()
            print("=== REMOTE EVENTS ===")
            for name, remote in pairs(Remotes.Events) do
                print(name, remote:GetFullName())
            end
            print("=== REMOTE FUNCTIONS ===")
            for name, remote in pairs(Remotes.Functions) do
                print(name, remote:GetFullName())
            end
            ui.Fluent:Notify({
                Title = "[DEBUG]",
                Content = "Remotes printed to console (F9)",
                Duration = 2
            })
        end
    })
    
    -- Debug: Print tycoon info
    Tabs.Settings:AddButton({
        Title = "🏯 Show Tycoon Info",
        Callback = function()
            local tycoon = getOwnTycoon()
            if tycoon then
                print("=== YOUR TYCOON ===")
                print("Name:", tycoon.Name)
                print("Children:")
                for _, child in pairs(tycoon:GetChildren()) do
                    print("  -", child.Name, child.ClassName)
                end
                ui.Fluent:Notify({
                    Title = "[INFO]",
                    Content = "Tycoon: " .. tycoon.Name .. " (see console F9)",
                    Duration = 3
                })
            else
                ui.Fluent:Notify({
                    Title = "[ERROR]",
                    Content = "Your tycoon not found",
                    Duration = 3
                })
            end
        end
    })
    
    -- ==========================================
    -- ANTI-AFK ALWAYS ON
    -- ==========================================
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
    
    -- ==========================================
    -- FINALIZE
    -- ==========================================
    ui.Window:SelectTab(1)
    ui.Fluent:Notify({
        Title = "🥷 GlockreisHub",
        Content = "Ninja Tycoon loaded! Auto Farm + ESP + Teleport ready",
        Duration = 5
    })
end
