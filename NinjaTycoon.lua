-- // ==========================================
-- // GLOCKREISHUB - NINJA TYCOON MODULE (ENHANCED)
-- // Auto Farm + Auto Collect + Auto Upgrade + Auto Train
-- // Auto Rebirth + ESP + Godmode + Teleport System
-- // Infinite Jump + NoClip + Speed Hack
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
    
    local placeId = game.PlaceId
    
    -- Config
    local DefaultConfig = {
        -- Auto Farm
        AutoCollectEnabled = false,
        AutoCollectRange = 150,
        AutoCollectSpeed = 500,
        AutoCollectAll = true,
        
        AutoAttackEnabled = false,
        AutoAttackRange = 60,
        AutoAttackSpeed = 0.15,
        AutoAttackTarget = "Nearest",
        
        -- Auto Build
        AutoUpgradeEnabled = false,
        AutoUpgradeDelay = 0.5,
        AutoUpgradeBuildings = true,
        AutoUpgradeWeapons = true,
        
        -- Auto Train
        AutoTrainEnabled = false,
        AutoTrainArea = "Speed",
        AutoTrainSpeed = 0.3,
        
        -- Auto Rebirth
        AutoRebirthEnabled = false,
        AutoRebirthMinLevel = 100,
        AutoRebirthAutoUpgrade = true,
        
        -- Movement
        WalkSpeed = 16,
        JumpPower = 50,
        CustomWalkSpeed = false,
        CustomJumpPower = false,
        GodModeEnabled = false,
        InfiniteJump = false,
        NoClip = false,
        
        -- ESP
        ESPEnabled = false,
        ESPCoins = true,
        ESPEnemies = true,
        ESPPlayers = true,
        ESPBuildings = false,
        ESPMaxDistance = 500,
        ESPFillColor = {R = 255, G = 255, B = 0},
        ESPOutlineColor = {R = 255, G = 0, B = 255},
        
        -- Teleport
        TeleportToCoins = false,
        TeleportToEnemies = false,
        TeleportToShop = false,
        TeleportToDojo = false,
    }
    
    local ConfigManager = Common.setupConfigManager("NinjaTycoon")
    local Config = ConfigManager.Load(DefaultConfig)
    
    local gameDisplayName = "Ninja Tycoon"
    local ui = Common.loadFluentUI(gameDisplayName, placeId)
    local Tabs = {}
    
    -- Helper function for tweening
    local function toTarget(pos, targetPos, targetCFrame, speed)
        speed = speed or Config.AutoCollectSpeed or 500
        local distance = (targetPos - pos).Magnitude
        if distance < 1 then return true, nil end
        local info = TweenInfo.new(distance / speed, Enum.EasingStyle.Linear)
        local ok, err = pcall(function()
            local char = LocalPlayer.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local tween = TweenService:Create(hrp, info, {CFrame = targetCFrame})
                    tween:Play()
                    tween.Completed:Wait()
                end
            end
        end)
        return ok, err
    end
    
    -- Helper: Find Remote
    local function findRemote(names)
        for _, name in ipairs(names) do
            local remote = ReplicatedStorage:FindFirstChild(name, true)
            if remote then return remote end
        end
        return nil
    end
    
    -- Common Remote Names (oyuna göre değişebilir)
    local Remotes = {
        Collect = findRemote({"Collect", "Pickup", "Grab", "CollectCoins", "PickupItem"}),
        Attack = findRemote({"Attack", "Hit", "Damage", "Strike"}),
        Upgrade = findRemote({"Upgrade", "Buy", "Purchase", "Build"}),
        Rebirth = findRemote({"Rebirth", "Reset", "Prestige"}),
        Train = findRemote({"Train", "Training", "Dojo"}),
    }
    
    -- Farm State
    local FarmState = {
        AutoCollectEnabled = Config.AutoCollectEnabled,
        AutoCollectRange = Config.AutoCollectRange or 150,
        AutoCollectSpeed = Config.AutoCollectSpeed or 500,
        AutoCollectAll = Config.AutoCollectAll,
        
        AutoAttackEnabled = Config.AutoAttackEnabled,
        AutoAttackRange = Config.AutoAttackRange or 60,
        AutoAttackSpeed = Config.AutoAttackSpeed or 0.15,
        AutoAttackTarget = Config.AutoAttackTarget or "Nearest",
        
        AutoUpgradeEnabled = Config.AutoUpgradeEnabled,
        AutoUpgradeDelay = Config.AutoUpgradeDelay or 0.5,
        AutoUpgradeBuildings = Config.AutoUpgradeBuildings,
        AutoUpgradeWeapons = Config.AutoUpgradeWeapons,
        
        AutoTrainEnabled = Config.AutoTrainEnabled,
        AutoTrainArea = Config.AutoTrainArea or "Speed",
        AutoTrainSpeed = Config.AutoTrainSpeed or 0.3,
        
        AutoRebirthEnabled = Config.AutoRebirthEnabled,
        AutoRebirthMinLevel = Config.AutoRebirthMinLevel or 100,
        AutoRebirthAutoUpgrade = Config.AutoRebirthAutoUpgrade,
        
        WalkSpeed = Config.WalkSpeed or 16,
        JumpPower = Config.JumpPower or 50,
        CustomWalkSpeed = Config.CustomWalkSpeed,
        CustomJumpPower = Config.CustomJumpPower,
        GodModeEnabled = Config.GodModeEnabled,
        InfiniteJump = Config.InfiniteJump,
        NoClip = Config.NoClip,
        
        ESPEnabled = Config.ESPEnabled,
        ESPCoins = Config.ESPCoins,
        ESPEnemies = Config.ESPEnemies,
        ESPPlayers = Config.ESPPlayers,
        ESPBuildings = Config.ESPBuildings,
        ESPMaxDistance = Config.ESPMaxDistance or 500,
        ESPFillColor = Color3.new(
            (Config.ESPFillColor and Config.ESPFillColor.R or 255)/255,
            (Config.ESPFillColor and Config.ESPFillColor.G or 255)/255,
            (Config.ESPFillColor and Config.ESPFillColor.B or 0)/255
        ),
        ESPOutlineColor = Color3.new(
            (Config.ESPOutlineColor and Config.ESPOutlineColor.R or 255)/255,
            (Config.ESPOutlineColor and Config.ESPOutlineColor.G or 0)/255,
            (Config.ESPOutlineColor and Config.ESPOutlineColor.B or 255)/255
        ),
        
        -- Stats
        CoinsCollected = 0,
        EnemiesKilled = 0,
        UpgradesDone = 0,
        RebirthsDone = 0,
        TrainingTime = 0,
    }
    
    -- ==========================================
    -- TABS CREATION
    -- ==========================================
    Tabs.Main = ui.Window:AddTab({ Title = "Auto Farm", Icon = "target" })
    Tabs.Build = ui.Window:AddTab({ Title = "Auto Build", Icon = "hammer" })
    Tabs.Train = ui.Window:AddTab({ Title = "Auto Train", Icon = "dumbbell" })
    Tabs.Rebirth = ui.Window:AddTab({ Title = "Auto Rebirth", Icon = "refresh-cw" })
    Tabs.Movement = ui.Window:AddTab({ Title = "Movement", Icon = "navigation" })
    Tabs.ESP = ui.Window:AddTab({ Title = "ESP", Icon = "eye" })
    Tabs.Teleport = ui.Window:AddTab({ Title = "Teleport", Icon = "map-pin" })
    Tabs.Utilities = ui.Window:AddTab({ Title = "Utilities", Icon = "tool" })
    
    -- ==========================================
    -- AUTO FARM TAB
    -- ==========================================
    Tabs.Main:AddParagraph({
        Title = "[💰] Auto Farm System",
        Content = "Automatically collects coins and attacks enemies.\n\n" ..
            "- 🆕 Auto-collect coins in range\n" ..
            "- 🆕 Auto-attack nearest enemies\n" ..
            "- 🆕 Tween-based smooth movement\n" ..
            "- 🆕 Configurable range and speed\n" ..
            "- 🆕 Statistics tracking\n\n" ..
            "NOTE: Remote events are auto-detected!"
    })
    
    -- Auto Collect Section
    Tabs.Main:AddSection("💰 Auto Collect Coins")
    
    Tabs.Main:AddToggle("AutoCollectToggle", {
        Title = "Enable Auto Collect",
        Description = "Automatically collect coins/items in range",
        Default = Config.AutoCollectEnabled
    }):OnChanged(function(v)
        FarmState.AutoCollectEnabled = v
        Config.AutoCollectEnabled = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.Main:AddSlider("AutoCollectRangeSlider", {
        Title = "Collect Range (studs)",
        Description = "Maximum distance to collect coins",
        Default = Config.AutoCollectRange,
        Min = 20, Max = 500, Rounding = 0,
        Callback = function(v)
            FarmState.AutoCollectRange = v
            Config.AutoCollectRange = v
            ConfigManager.Save(Config)
        end
    })
    
    Tabs.Main:AddSlider("AutoCollectSpeedSlider", {
        Title = "Movement Speed (studs/sec)",
        Description = "How fast to move to coins",
        Default = Config.AutoCollectSpeed,
        Min = 100, Max = 2000, Rounding = 0,
        Callback = function(v)
            FarmState.AutoCollectSpeed = v
            Config.AutoCollectSpeed = v
            ConfigManager.Save(Config)
        end
    })
    
    Tabs.Main:AddToggle("AutoCollectAllToggle", {
        Title = "Collect All Types",
        Description = "Collect coins, gems, drops, items (disable for coins only)",
        Default = Config.AutoCollectAll
    }):OnChanged(function(v)
        FarmState.AutoCollectAll = v
        Config.AutoCollectAll = v
        ConfigManager.Save(Config)
    end)
    
    -- Auto Attack Section
    Tabs.Main:AddSection("⚔️ Auto Attack Enemies")
    
    Tabs.Main:AddToggle("AutoAttackToggle", {
        Title = "Enable Auto Attack",
        Description = "Automatically attack enemies in range",
        Default = Config.AutoAttackEnabled
    }):OnChanged(function(v)
        FarmState.AutoAttackEnabled = v
        Config.AutoAttackEnabled = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.Main:AddSlider("AutoAttackRangeSlider", {
        Title = "Attack Range (studs)",
        Default = Config.AutoAttackRange,
        Min = 10, Max = 200, Rounding = 0,
        Callback = function(v)
            FarmState.AutoAttackRange = v
            Config.AutoAttackRange = v
            ConfigManager.Save(Config)
        end
    })
    
    Tabs.Main:AddSlider("AutoAttackSpeedSlider", {
        Title = "Attack Speed (seconds)",
        Description = "Delay between attacks (lower = faster)",
        Default = Config.AutoAttackSpeed,
        Min = 0.05, Max = 1, Rounding = 2,
        Callback = function(v)
            FarmState.AutoAttackSpeed = v
            Config.AutoAttackSpeed = v
            ConfigManager.Save(Config)
        end
    })
    
    -- Helper: Find collectibles (coins, drops)
    local function findCollectibles()
        local items = {}
        local char = LocalPlayer.Character
        if not char then return items end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return items end
        
        -- Common folder names for coins/drops
        local folderNames = {"Coins", "Drops", "Items", "Money", "Collectibles", "Rewards", "Loot"}
        
        for _, folderName in ipairs(folderNames) do
            local folder = workspace:FindFirstChild(folderName)
            if folder then
                for _, item in pairs(folder:GetChildren()) do
                    local itemPos = nil
                    if item:IsA("BasePart") then
                        itemPos = item.Position
                    elseif item:IsA("Model") and item.PrimaryPart then
                        itemPos = item.PrimaryPart.Position
                    elseif item:FindFirstChild("Handle") then
                        itemPos = item.Handle.Position
                    elseif item:FindFirstChild("HumanoidRootPart") then
                        itemPos = item.HumanoidRootPart.Position
                    end
                    
                    if itemPos then
                        local dist = (root.Position - itemPos).Magnitude
                        if dist <= FarmState.AutoCollectRange then
                            table.insert(items, {
                                instance = item,
                                position = itemPos,
                                distance = dist,
                                type = "coin"
                            })
                        end
                    end
                end
            end
        end
        
        -- Also scan workspace root for stray items
        for _, obj in pairs(workspace:GetChildren()) do
            if obj:IsA("BasePart") or obj:IsA("Model") then
                local nameLower = obj.Name:lower()
                if string.find(nameLower, "coin") or string.find(nameLower, "drop") 
                    or string.find(nameLower, "money") or string.find(nameLower, "gem")
                    or string.find(nameLower, "reward") or string.find(nameLower, "loot") then
                    
                    local itemPos = nil
                    if obj:IsA("BasePart") then
                        itemPos = obj.Position
                    elseif obj:IsA("Model") and obj.PrimaryPart then
                        itemPos = obj.PrimaryPart.Position
                    end
                    
                    if itemPos then
                        local dist = (root.Position - itemPos).Magnitude
                        if dist <= FarmState.AutoCollectRange then
                            -- Avoid duplicates
                            local alreadyAdded = false
                            for _, existing in ipairs(items) do
                                if existing.instance == obj then
                                    alreadyAdded = true
                                    break
                                end
                            end
                            if not alreadyAdded then
                                table.insert(items, {
                                    instance = obj,
                                    position = itemPos,
                                    distance = dist,
                                    type = "coin"
                                })
                            end
                        end
                    end
                end
            end
        end
        
        -- Sort by distance
        table.sort(items, function(a, b) return a.distance < b.distance end)
        return items
    end
    
    -- Helper: Find enemies
    local function findEnemies()
        local enemies = {}
        local char = LocalPlayer.Character
        if not char then return enemies end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return enemies end
        
        local folderNames = {"Enemies", "NPCs", "Mobs", "Monsters", "Bosses", "Targets"}
        
        for _, folderName in ipairs(folderNames) do
            local folder = workspace:FindFirstChild(folderName)
            if folder then
                for _, enemy in pairs(folder:GetChildren()) do
                    if enemy:IsA("Model") then
                        local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
                        local enemyHum = enemy:FindFirstChildOfClass("Humanoid")
                        
                        if enemyRoot and enemyHum and enemyHum.Health > 0 then
                            local dist = (root.Position - enemyRoot.Position).Magnitude
                            if dist <= FarmState.AutoAttackRange then
                                table.insert(enemies, {
                                    model = enemy,
                                    root = enemyRoot,
                                    hum = enemyHum,
                                    distance = dist
                                })
                            end
                        end
                    end
                end
            end
        end
        
        table.sort(enemies, function(a, b) return a.distance < b.distance end)
        return enemies
    end
    
    -- Helper: Collect a single item
    local function collectItem(item)
        if not item or not item.instance or not item.instance.Parent then return false end
        
        local char = LocalPlayer.Character
        if not char then return false end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        
        -- Method 1: Touch the item (most common)
        pcall(function()
            toTarget(root.Position, item.position, CFrame.new(item.position))
        end)
        
        -- Method 2: Fire collect remote
        if Remotes.Collect then
            pcall(function()
                if Remotes.Collect:IsA("RemoteEvent") then
                    Remotes.Collect:FireServer(item.instance)
                elseif Remotes.Collect:IsA("RemoteFunction") then
                    Remotes.Collect:InvokeServer(item.instance)
                end
            end)
        end
        
        -- Method 3: Fire ClickDetector if exists
        pcall(function()
            local clickDetector = item.instance:FindFirstChildOfClass("ClickDetector") 
                or (item.instance:IsA("Model") and item.instance:FindFirstChildWhichIsA("ClickDetector", true))
            if clickDetector then
                fireclickdetector(clickDetector)
            end
        end)
        
        -- Method 4: ProximityPrompt
        pcall(function()
            local prompt = item.instance:FindFirstChildOfClass("ProximityPrompt")
                or (item.instance:IsA("Model") and item.instance:FindFirstChildWhichIsA("ProximityPrompt", true))
            if prompt then
                fireproximityprompt(prompt)
            end
        end)
        
        FarmState.CoinsCollected = FarmState.CoinsCollected + 1
        return true
    end
    
    -- Helper: Attack an enemy
    local function attackEnemy(enemy)
        if not enemy or not enemy.model or not enemy.model.Parent then return false end
        if not enemy.hum or enemy.hum.Health <= 0 then return false end
        
        local char = LocalPlayer.Character
        if not char then return false end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        local combat = char:FindFirstChild("combat")
        
        -- Face enemy
        pcall(function()
            root.CFrame = CFrame.lookAt(root.Position, enemy.root.Position)
        end)
        
        -- Method 1: Fire attack remote
        if Remotes.Attack then
            pcall(function()
                if Remotes.Attack:IsA("RemoteEvent") then
                    Remotes.Attack:FireServer(enemy.model)
                elseif Remotes.Attack:IsA("RemoteFunction") then
                    Remotes.Attack:InvokeServer(enemy.model)
                end
            end)
        end
        
        -- Method 2: Use combat.update (Shindo Life style)
        if combat and combat:FindFirstChild("update") then
            pcall(function()
                combat.update:FireServer("mouse1", true)
                task.wait(0.05)
                combat.update:FireServer("mouse1", false)
            end)
        end
        
        -- Method 3: Click detector on enemy
        pcall(function()
            local clickDetector = enemy.model:FindFirstChildOfClass("ClickDetector")
                or enemy.model:FindFirstChildWhichIsA("ClickDetector", true)
            if clickDetector then
                fireclickdetector(clickDetector)
            end
        end)
        
        -- Method 4: Force kill locally (if nothing else works)
        if enemy.hum.Health > 0 then
            pcall(function()
                enemy.hum.Health = 0
            end)
        end
        
        if enemy.hum.Health <= 0 then
            FarmState.EnemiesKilled = FarmState.EnemiesKilled + 1
        end
        
        return true
    end
    
    -- Auto Collect Loop
    task.spawn(function()
        while true do
            if FarmState.AutoCollectEnabled and LocalPlayer.Character then
                pcall(function()
                    local items = findCollectibles()
                    for _, item in ipairs(items) do
                        if not FarmState.AutoCollectEnabled then break end
                        collectItem(item)
                        task.wait(0.05)
                    end
                end)
            end
            task.wait(0.1)
        end
    end)
    
    -- Auto Attack Loop
    task.spawn(function()
        while true do
            if FarmState.AutoAttackEnabled and LocalPlayer.Character then
                pcall(function()
                    local enemies = findEnemies()
                    for _, enemy in ipairs(enemies) do
                        if not FarmState.AutoAttackEnabled then break end
                        attackEnemy(enemy)
                        task.wait(FarmState.AutoAttackSpeed or 0.15)
                    end
                end)
            end
            task.wait(FarmState.AutoAttackSpeed or 0.15)
        end
    end)
    
    -- Auto Farm Status
    local AutoFarmStatusDisplay = Tabs.Main:AddParagraph({
        Title = "Auto Farm Status",
        Content = "Initializing..."
    })
    
    task.spawn(function()
        while true do
            AutoFarmStatusDisplay.Content = string.format(
                "Auto Collect: %s\n" ..
                "Auto Attack: %s\n\n" ..
                "📊 Statistics:\n" ..
                "- 💰 Coins Collected: %d\n" ..
                "- ⚔️ Enemies Killed: %d\n\n" ..
                "⚙️ Settings:\n" ..
                "- Collect Range: %d studs\n" ..
                "- Attack Range: %d studs\n" ..
                "- Collect Speed: %d studs/s\n" ..
                "- Attack Speed: %.2fs",
                FarmState.AutoCollectEnabled and "[OK] ACTIVE" or "[X] INACTIVE",
                FarmState.AutoAttackEnabled and "[OK] ACTIVE" or "[X] INACTIVE",
                FarmState.CoinsCollected,
                FarmState.EnemiesKilled,
                FarmState.AutoCollectRange,
                FarmState.AutoAttackRange,
                FarmState.AutoCollectSpeed,
                FarmState.AutoAttackSpeed
            )
            task.wait(0.5)
        end
    end)
    
    -- ==========================================
    -- AUTO BUILD TAB
    -- ==========================================
    Tabs.Build:AddParagraph({
        Title = "[🔨] Auto Build System",
        Content = "Automatically upgrade buildings and weapons.\n\n" ..
            "- 🆕 Auto-upgrade tycoon buildings\n" ..
            "- 🆕 Auto-buy weapons and items\n" ..
            "- 🆕 Scans common folder names\n" ..
            "- 🆕 Uses Remote Events/Functions\n" ..
            "- 🆕 ClickDetector support"
    })
    
    Tabs.Build:AddToggle("AutoUpgradeToggle", {
        Title = "Enable Auto Upgrade",
        Default = Config.AutoUpgradeEnabled
    }):OnChanged(function(v)
        FarmState.AutoUpgradeEnabled = v
        Config.AutoUpgradeEnabled = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.Build:AddSlider("AutoUpgradeDelaySlider", {
        Title = "Upgrade Delay (seconds)",
        Default = Config.AutoUpgradeDelay,
        Min = 0.1, Max = 5, Rounding = 1,
        Callback = function(v)
            FarmState.AutoUpgradeDelay = v
            Config.AutoUpgradeDelay = v
            ConfigManager.Save(Config)
        end
    })
    
    Tabs.Build:AddToggle("AutoUpgradeBuildingsToggle", {
        Title = "Upgrade Buildings",
        Default = Config.AutoUpgradeBuildings
    }):OnChanged(function(v)
        FarmState.AutoUpgradeBuildings = v
        Config.AutoUpgradeBuildings = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.Build:AddToggle("AutoUpgradeWeaponsToggle", {
        Title = "Upgrade Weapons",
        Default = Config.AutoUpgradeWeapons
    }):OnChanged(function(v)
        FarmState.AutoUpgradeWeapons = v
        Config.AutoUpgradeWeapons = v
        ConfigManager.Save(Config)
    end)
    
    -- Helper: Find upgrade buttons
    local function findUpgradeButtons()
        local buttons = {}
        local char = LocalPlayer.Character
        if not char then return buttons end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return buttons end
        
        -- Search for buttons in PlayerGui
        pcall(function()
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                for _, gui in pairs(playerGui:GetDescendants()) do
                    if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                        local nameLower = gui.Name:lower()
                        local textLower = gui:IsA("TextButton") and (gui.Text or ""):lower() or ""
                        
                        if string.find(nameLower, "upgrade") or string.find(nameLower, "buy") 
                            or string.find(nameLower, "purchase") or string.find(nameLower, "build")
                            or string.find(textLower, "upgrade") or string.find(textLower, "buy") then
                            table.insert(buttons, {
                                instance = gui,
                                type = "button"
                            })
                        end
                    end
                end
            end
        end)
        
        -- Search for upgrade parts in workspace
        if FarmState.AutoUpgradeBuildings then
            local folderNames = {"Buildings", "Tycoon", "Upgrades", "Buttons", "BuyButtons"}
            for _, folderName in ipairs(folderNames) do
                local folder = workspace:FindFirstChild(folderName)
                if folder then
                    for _, obj in pairs(folder:GetDescendants()) do
                        local nameLower = obj.Name:lower()
                        if string.find(nameLower, "upgrade") or string.find(nameLower, "buy") 
                            or string.find(nameLower, "button") then
                            
                            if obj:IsA("BasePart") or obj:IsA("Model") then
                                table.insert(buttons, {
                                    instance = obj,
                                    type = "world"
                                })
                            end
                        end
                    end
                end
            end
        end
        
        return buttons
    end
    
    -- Helper: Click upgrade button
    local function clickUpgrade(button)
        if not button or not button.instance or not button.instance.Parent then return false end
        
        pcall(function()
            if button.type == "button" then
                -- GUI button - fire it
                if button.instance:IsA("TextButton") or button.instance:IsA("ImageButton") then
                    -- Try to fire MouseButton1Click
                    button.instance:FireServer()
                end
            elseif button.type == "world" then
                -- World button - click detector or remote
                local clickDetector = button.instance:FindFirstChildOfClass("ClickDetector")
                    or (button.instance:IsA("Model") and button.instance:FindFirstChildWhichIsA("ClickDetector", true))
                if clickDetector then
                    fireclickdetector(clickDetector)
                end
                
                local prompt = button.instance:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    fireproximityprompt(prompt)
                end
                
                -- Try upgrade remote
                if Remotes.Upgrade then
                    pcall(function()
                        if Remotes.Upgrade:IsA("RemoteEvent") then
                            Remotes.Upgrade:FireServer(button.instance)
                        elseif Remotes.Upgrade:IsA("RemoteFunction") then
                            Remotes.Upgrade:InvokeServer(button.instance)
                        end
                    end)
                end
            end
        end)
        
        FarmState.UpgradesDone = FarmState.UpgradesDone + 1
        return true
    end
    
    -- Auto Upgrade Loop
    task.spawn(function()
        while true do
            if FarmState.AutoUpgradeEnabled then
                pcall(function()
                    local buttons = findUpgradeButtons()
                    for _, button in ipairs(buttons) do
                        if not FarmState.AutoUpgradeEnabled then break end
                        clickUpgrade(button)
                        task.wait(FarmState.AutoUpgradeDelay or 0.5)
                    end
                end)
            end
            task.wait(FarmState.AutoUpgradeDelay or 0.5)
        end
    end)
    
    -- Build Status
    local BuildStatusDisplay = Tabs.Build:AddParagraph({
        Title = "Auto Build Status",
        Content = "Initializing..."
    })
    
    task.spawn(function()
        while true do
            BuildStatusDisplay.Content = string.format(
                "Status: %s\n\n" ..
                "📊 Statistics:\n" ..
                "- 🔨 Upgrades Done: %d\n\n" ..
                "⚙️ Settings:\n" ..
                "- Upgrade Delay: %.1fs\n" ..
                "- Upgrade Buildings: %s\n" ..
                "- Upgrade Weapons: %s",
                FarmState.AutoUpgradeEnabled and "[OK] ACTIVE" or "[X] INACTIVE",
                FarmState.UpgradesDone,
                FarmState.AutoUpgradeDelay,
                FarmState.AutoUpgradeBuildings and "YES" or "NO",
                FarmState.AutoUpgradeWeapons and "YES" or "NO"
            )
            task.wait(1)
        end
    end)
    
    -- ==========================================
    -- AUTO TRAIN TAB
    -- ==========================================
    Tabs.Train:AddParagraph({
        Title = "[💪] Auto Training System",
        Content = "Automatically train your ninja skills.\n\n" ..
            "- 🆕 Auto-train Speed, Strength, Agility\n" ..
            "- 🆕 Teleport to training areas\n" ..
            "- 🆕 Continuous training loop\n" ..
            "- 🆕 Tracks training time"
    })
    
    Tabs.Train:AddToggle("AutoTrainToggle", {
        Title = "Enable Auto Train",
        Default = Config.AutoTrainEnabled
    }):OnChanged(function(v)
        FarmState.AutoTrainEnabled = v
        Config.AutoTrainEnabled = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.Train:AddDropdown("AutoTrainAreaDropdown", {
        Title = "Training Area",
        Values = {"Speed", "Strength", "Agility", "Stamina", "Chakra", "Defense"},
        Default = Config.AutoTrainArea,
        Callback = function(v)
            FarmState.AutoTrainArea = v
            Config.AutoTrainArea = v
            ConfigManager.Save(Config)
        end
    })
    
    Tabs.Train:AddSlider("AutoTrainSpeedSlider", {
        Title = "Train Speed (seconds)",
        Description = "Delay between training actions",
        Default = Config.AutoTrainSpeed,
        Min = 0.1, Max = 2, Rounding = 1,
        Callback = function(v)
            FarmState.AutoTrainSpeed = v
            Config.AutoTrainSpeed = v
            ConfigManager.Save(Config)
        end
    })
    
    -- Helper: Find training areas
    local function findTrainingArea(areaType)
        local char = LocalPlayer.Character
        if not char then return nil end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        
        local areaTypeLower = areaType:lower()
        local folderNames = {"TrainingAreas", "Dojo", "Gym", "Training", "Workout"}
        
        for _, folderName in ipairs(folderNames) do
            local folder = workspace:FindFirstChild(folderName)
            if folder then
                for _, area in pairs(folder:GetChildren()) do
                    local nameLower = area.Name:lower()
                    if string.find(nameLower, areaTypeLower) then
                        local areaPos = nil
                        if area:IsA("BasePart") then
                            areaPos = area.Position
                        elseif area:IsA("Model") then
                            areaPos = (area.PrimaryPart or area:FindFirstChildWhichIsA("BasePart"))
                            if areaPos then areaPos = areaPos.Position end
                        end
                        if areaPos then
                            return {
                                instance = area,
                                position = areaPos
                            }
                        end
                    end
                end
            end
        end
        
        return nil
    end
    
    -- Auto Train Loop
    task.spawn(function()
        local trainStartTime = nil
        
        while true do
            if FarmState.AutoTrainEnabled and LocalPlayer.Character then
                if not trainStartTime then
                    trainStartTime = tick()
                end
                
                pcall(function()
                    local area = findTrainingArea(FarmState.AutoTrainArea)
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    
                    if area and root then
                        -- Teleport to training area
                        local dist = (root.Position - area.position).Magnitude
                        if dist > 10 then
                            toTarget(root.Position, area.position, CFrame.new(area.position))
                            task.wait(1)
                        end
                        
                        -- Fire train remote
                        if Remotes.Train then
                            pcall(function()
                                if Remotes.Train:IsA("RemoteEvent") then
                                    Remotes.Train:FireServer(FarmState.AutoTrainArea)
                                elseif Remotes.Train:IsA("RemoteFunction") then
                                    Remotes.Train:InvokeServer(FarmState.AutoTrainArea)
                                end
                            end)
                        end
                        
                        -- Alternative: Click training equipment
                        pcall(function()
                            if area.instance then
                                local clickDetector = area.instance:FindFirstChildOfClass("ClickDetector")
                                    or (area.instance:IsA("Model") and area.instance:FindFirstChildWhichIsA("ClickDetector", true))
                                if clickDetector then
                                    fireclickdetector(clickDetector)
                                end
                                
                                local prompt = area.instance:FindFirstChildOfClass("ProximityPrompt")
                                if prompt then
                                    fireproximityprompt(prompt)
                                end
                            end
                        end)
                    end
                end)
                
                -- Update training time
                if trainStartTime then
                    FarmState.TrainingTime = math.floor(tick() - trainStartTime)
                end
            else
                trainStartTime = nil
            end
            task.wait(FarmState.AutoTrainSpeed or 0.3)
        end
    end)
    
    -- Train Status
    local TrainStatusDisplay = Tabs.Train:AddParagraph({
        Title = "Auto Train Status",
        Content = "Initializing..."
    })
    
    task.spawn(function()
        while true do
            local hours = math.floor(FarmState.TrainingTime / 3600)
            local minutes = math.floor((FarmState.TrainingTime % 3600) / 60)
            local seconds = FarmState.TrainingTime % 60
            
            TrainStatusDisplay.Content = string.format(
                "Status: %s\n\n" ..
                "📊 Statistics:\n" ..
                "- ⏱️ Training Time: %02d:%02d:%02d\n" ..
                "- 🎯 Current Area: %s\n\n" ..
                "⚙️ Settings:\n" ..
                "- Train Speed: %.1fs",
                FarmState.AutoTrainEnabled and "[OK] ACTIVE" or "[X] INACTIVE",
                hours, minutes, seconds,
                FarmState.AutoTrainArea or "None",
                FarmState.AutoTrainSpeed
            )
            task.wait(1)
        end
    end)
    
    -- ==========================================
    -- AUTO REBIRTH TAB
    -- ==========================================
    Tabs.Rebirth:AddParagraph({
        Title = "[🔄] Auto Rebirth System",
        Content = "Automatically rebirth when reaching target level.\n\n" ..
            "- 🆕 Monitors player level\n" ..
            "- 🆕 Auto-rebirth at threshold\n" ..
            "- 🆕 Optional auto-upgrade after rebirth"
    })
    
    Tabs.Rebirth:AddToggle("AutoRebirthToggle", {
        Title = "Enable Auto Rebirth",
        Default = Config.AutoRebirthEnabled
    }):OnChanged(function(v)
        FarmState.AutoRebirthEnabled = v
        Config.AutoRebirthEnabled = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.Rebirth:AddSlider("AutoRebirthLevelSlider", {
        Title = "Minimum Level for Rebirth",
        Default = Config.AutoRebirthMinLevel,
        Min = 1, Max = 1000, Rounding = 0,
        Callback = function(v)
            FarmState.AutoRebirthMinLevel = v
            Config.AutoRebirthMinLevel = v
            ConfigManager.Save(Config)
        end
    })
    
    Tabs.Rebirth:AddToggle("AutoRebirthUpgradeToggle", {
        Title = "Auto Upgrade After Rebirth",
        Default = Config.AutoRebirthAutoUpgrade
    }):OnChanged(function(v)
        FarmState.AutoRebirthAutoUpgrade = v
        Config.AutoRebirthAutoUpgrade = v
        ConfigManager.Save(Config)
    end)
    
    -- Helper: Get player level
    local function getPlayerLevel()
        local level = 0
        
        -- Method 1: Check leaderstats
        pcall(function()
            local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
            if leaderstats then
                local levelStat = leaderstats:FindFirstChild("Level") 
                    or leaderstats:FindFirstChild("level")
                    or leaderstats:FindFirstChild("LVL")
                if levelStat and levelStat.Value then
                    level = tonumber(levelStat.Value) or 0
                end
            end
        end)
        
        -- Method 2: Check player data folder
        if level == 0 then
            pcall(function()
                local data = LocalPlayer:FindFirstChild("Data") 
                    or LocalPlayer:FindFirstChild("Stats")
                    or LocalPlayer:FindFirstChild("PlayerData")
                if data then
                    local levelStat = data:FindFirstChild("Level")
                        or data:FindFirstChild("level")
                    if levelStat and levelStat.Value then
                        level = tonumber(levelStat.Value) or 0
                    end
                end
            end)
        end
        
        return level
    end
    
    -- Helper: Perform rebirth
    local function performRebirth()
        local success = false
        
        -- Method 1: Fire rebirth remote
        if Remotes.Rebirth then
            pcall(function()
                if Remotes.Rebirth:IsA("RemoteEvent") then
                    Remotes.Rebirth:FireServer()
                    success = true
                elseif Remotes.Rebirth:IsA("RemoteFunction") then
                    Remotes.Rebirth:InvokeServer()
                    success = true
                end
            end)
        end
        
        -- Method 2: Find and click rebirth button
        if not success then
            pcall(function()
                local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                if playerGui then
                    for _, gui in pairs(playerGui:GetDescendants()) do
                        if (gui:IsA("TextButton") or gui:IsA("ImageButton")) then
                            local nameLower = gui.Name:lower()
                            local textLower = gui:IsA("TextButton") and (gui.Text or ""):lower() or ""
                            
                            if string.find(nameLower, "rebirth") or string.find(textLower, "rebirth") then
                                gui:FireServer()
                                success = true
                                break
                            end
                        end
                    end
                end
            end)
        end
        
        if success then
            FarmState.RebirthsDone = FarmState.RebirthsDone + 1
            ui.Fluent:Notify({
                Title = "[🔄] Rebirth Complete",
                Content = "Rebirth #" .. FarmState.RebirthsDone,
                Duration = 3
            })
        end
        
        return success
    end
    
    -- Auto Rebirth Loop
    task.spawn(function()
        while true do
            if FarmState.AutoRebirthEnabled then
                pcall(function()
                    local currentLevel = getPlayerLevel()
                    
                    if currentLevel >= FarmState.AutoRebirthMinLevel then
                        performRebirth()
                        
                        -- Optional: Auto-upgrade after rebirth
                        if FarmState.AutoRebirthAutoUpgrade then
                            task.wait(3)
                            FarmState.AutoUpgradeEnabled = true
                            task.wait(10)
                        end
                    end
                end)
            end
            task.wait(5)
        end
    end)
    
    -- Rebirth Status
    local RebirthStatusDisplay = Tabs.Rebirth:AddParagraph({
        Title = "Auto Rebirth Status",
        Content = "Initializing..."
    })
    
    task.spawn(function()
        while true do
            local currentLevel = getPlayerLevel()
            local progress = currentLevel >= FarmState.AutoRebirthMinLevel and 100 or math.floor((currentLevel / FarmState.AutoRebirthMinLevel) * 100)
            
            RebirthStatusDisplay.Content = string.format(
                "Status: %s\n\n" ..
                "📊 Statistics:\n" ..
                "- 🔄 Total Rebirths: %d\n" ..
                "- 📈 Current Level: %d\n" ..
                "- 🎯 Target Level: %d\n" ..
                "- 📊 Progress: %d%%\n\n" ..
                "⚙️ Settings:\n" ..
                "- Auto Upgrade After: %s",
                FarmState.AutoRebirthEnabled and "[OK] ACTIVE" or "[X] INACTIVE",
                FarmState.RebirthsDone,
                currentLevel,
                FarmState.AutoRebirthMinLevel,
                progress,
                FarmState.AutoRebirthAutoUpgrade and "YES" or "NO"
            )
            task.wait(1)
        end
    end)
    
    -- ==========================================
    -- MOVEMENT TAB
    -- ==========================================
    Tabs.Movement:AddParagraph({
        Title = "[🏃] Movement Hacks",
        Content = "Advanced movement modifications.\n\n" ..
            "- 🆕 Custom walk speed\n" ..
            "- 🆕 Custom jump power\n" ..
            "- 🆕 Infinite jump\n" ..
            "- 🆕 NoClip (walk through walls)\n" ..
            "- 🆕 Godmode (no damage)"
    })
    
    Tabs.Movement:AddToggle("CustomWalkSpeedToggle", {
        Title = "Enable Custom Walk Speed",
        Default = Config.CustomWalkSpeed
    }):OnChanged(function(v)
        FarmState.CustomWalkSpeed = v
        Config.CustomWalkSpeed = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.Movement:AddSlider("WalkSpeedSlider", {
        Title = "Walk Speed",
        Default = Config.WalkSpeed,
        Min = 16, Max = 500, Rounding = 0,
        Callback = function(v)
            FarmState.WalkSpeed = v
            Config.WalkSpeed = v
            ConfigManager.Save(Config)
        end
    })
    
    Tabs.Movement:AddToggle("CustomJumpPowerToggle", {
        Title = "Enable Custom Jump Power",
        Default = Config.CustomJumpPower
    }):OnChanged(function(v)
        FarmState.CustomJumpPower = v
        Config.CustomJumpPower = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.Movement:AddSlider("JumpPowerSlider", {
        Title = "Jump Power",
        Default = Config.JumpPower,
        Min = 50, Max = 500, Rounding = 0,
        Callback = function(v)
            FarmState.JumpPower = v
            Config.JumpPower = v
            ConfigManager.Save(Config)
        end
    })
    
    Tabs.Movement:AddToggle("InfiniteJumpToggle", {
        Title = "Infinite Jump",
        Description = "Jump multiple times in air",
        Default = Config.InfiniteJump
    }):OnChanged(function(v)
        FarmState.InfiniteJump = v
        Config.InfiniteJump = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.Movement:AddToggle("NoClipToggle", {
        Title = "NoClip",
        Description = "Walk through walls and objects",
        Default = Config.NoClip
    }):OnChanged(function(v)
        FarmState.NoClip = v
        Config.NoClip = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.Movement:AddToggle("GodModeToggle", {
        Title = "Godmode",
        Description = "Take no damage",
        Default = Config.GodModeEnabled
    }):OnChanged(function(v)
        FarmState.GodModeEnabled = v
        Config.GodModeEnabled = v
        ConfigManager.Save(Config)
    end)
    
    -- Movement loops
    -- Walk Speed / Jump Power
    RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        
        if FarmState.CustomWalkSpeed then
            hum.WalkSpeed = FarmState.WalkSpeed
        end
        
        if FarmState.CustomJumpPower then
            if hum.UseJumpPower == false then
                hum.JumpHeight = FarmState.JumpPower
            else
                hum.JumpPower = FarmState.JumpPower
            end
        end
    end)
    
    -- Infinite Jump
    UserInputService.JumpRequest:Connect(function()
        if FarmState.InfiniteJump then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end
    end)
    
    -- NoClip
    RunService.Stepped:Connect(function()
        if FarmState.NoClip then
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
    
    -- Godmode
    task.spawn(function()
        while true do
            if FarmState.GodModeEnabled then
                pcall(function()
                    local char = LocalPlayer.Character
                    if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then
                            hum.Health = hum.MaxHealth
                            hum.MaxHealth = math.huge
                            hum.Health = math.huge
                        end
                    end
                end)
            end
            task.wait(0.1)
        end
    end)
    
    -- Movement Status
    local MovementStatusDisplay = Tabs.Movement:AddParagraph({
        Title = "Movement Status",
        Content = "Initializing..."
    })
    
    task.spawn(function()
        while true do
            MovementStatusDisplay.Content = string.format(
                "Custom Walk Speed: %s (%d)\n" ..
                "Custom Jump Power: %s (%d)\n" ..
                "Infinite Jump: %s\n" ..
                "NoClip: %s\n" ..
                "Godmode: %s",
                FarmState.CustomWalkSpeed and "[OK]" or "[X]",
                FarmState.WalkSpeed,
                FarmState.CustomJumpPower and "[OK]" or "[X]",
                FarmState.JumpPower,
                FarmState.InfiniteJump and "[OK]" or "[X]",
                FarmState.NoClip and "[OK]" or "[X]",
                FarmState.GodModeEnabled and "[OK]" or "[X]"
            )
            task.wait(0.5)
        end
    end)
    
    -- ==========================================
    -- ESP TAB
    -- ==========================================
    Tabs.ESP:AddParagraph({
        Title = "[👁️] ESP System",
        Content = "See important objects through walls.\n\n" ..
            "- 🆕 Coins/Drops ESP\n" ..
            "- 🆕 Enemies ESP\n" ..
            "- 🆕 Players ESP\n" ..
            "- 🆕 Buildings ESP\n" ..
            "- 🆕 Customizable colors"
    })
    
    Tabs.ESP:AddToggle("ESPToggle", {
        Title = "Enable ESP",
        Default = Config.ESPEnabled
    }):OnChanged(function(v)
        FarmState.ESPEnabled = v
        Config.ESPEnabled = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.ESP:AddToggle("ESPCoinsToggle", {
        Title = "Show Coins/Drops",
        Default = Config.ESPCoins
    }):OnChanged(function(v)
        FarmState.ESPCoins = v
        Config.ESPCoins = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.ESP:AddToggle("ESPEnemiesToggle", {
        Title = "Show Enemies",
        Default = Config.ESPEnemies
    }):OnChanged(function(v)
        FarmState.ESPEnemies = v
        Config.ESPEnemies = v
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
    
    Tabs.ESP:AddToggle("ESPBuildingsToggle", {
        Title = "Show Buildings",
        Default = Config.ESPBuildings
    }):OnChanged(function(v)
        FarmState.ESPBuildings = v
        Config.ESPBuildings = v
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
    
    Tabs.ESP:AddColorpicker("ESPFillColorPicker", {
        Title = "Fill Color",
        Default = FarmState.ESPFillColor
    }):OnChanged(function(color)
        FarmState.ESPFillColor = color
        Config.ESPFillColor = {
            R = math.floor(color.R * 255),
            G = math.floor(color.G * 255),
            B = math.floor(color.B * 255)
        }
        ConfigManager.Save(Config)
    end)
    
    Tabs.ESP:AddColorpicker("ESPOutlineColorPicker", {
        Title = "Outline Color",
        Default = FarmState.ESPOutlineColor
    }):OnChanged(function(color)
        FarmState.ESPOutlineColor = color
        Config.ESPOutlineColor = {
            R = math.floor(color.R * 255),
            G = math.floor(color.G * 255),
            B = math.floor(color.B * 255)
        }
        ConfigManager.Save(Config)
    end)
    
    -- ESP Storage
    local ESPHighlights = {}
    
    local function addESPToObject(obj, color)
        if not obj or not obj.Parent then return end
        if ESPHighlights[obj] then return end
        
        pcall(function()
            local highlight = Instance.new("Highlight")
            highlight.Name = "GlockESP"
            highlight.FillColor = color or FarmState.ESPFillColor
            highlight.FillTransparency = 0.7
            highlight.OutlineColor = FarmState.ESPOutlineColor
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Adornee = obj
            highlight.Parent = obj
            
            ESPHighlights[obj] = highlight
        end)
    end
    
    local function removeESPFromObject(obj)
        if ESPHighlights[obj] then
            pcall(function() ESPHighlights[obj]:Destroy() end)
            ESPHighlights[obj] = nil
        end
    end
    
    -- ESP Update Loop
    task.spawn(function()
        while true do
            if FarmState.ESPEnabled then
                pcall(function()
                    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    
                    -- Coins ESP
                    if FarmState.ESPCoins then
                        local folderNames = {"Coins", "Drops", "Items", "Money", "Collectibles"}
                        for _, folderName in ipairs(folderNames) do
                            local folder = workspace:FindFirstChild(folderName)
                            if folder then
                                for _, item in pairs(folder:GetChildren()) do
                                    local itemPos = nil
                                    if item:IsA("BasePart") then
                                        itemPos = item.Position
                                    elseif item:IsA("Model") and item.PrimaryPart then
                                        itemPos = item.PrimaryPart.Position
                                    end
                                    
                                    if itemPos and myRoot then
                                        local dist = (myRoot.Position - itemPos).Magnitude
                                        if dist <= FarmState.ESPMaxDistance then
                                            addESPToObject(item, Color3.fromRGB(255, 255, 0)) -- Yellow for coins
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Enemies ESP
                    if FarmState.ESPEnemies then
                        local folderNames = {"Enemies", "NPCs", "Mobs", "Monsters", "Bosses"}
                        for _, folderName in ipairs(folderNames) do
                            local folder = workspace:FindFirstChild(folderName)
                            if folder then
                                for _, enemy in pairs(folder:GetChildren()) do
                                    if enemy:IsA("Model") then
                                        local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
                                        if enemyRoot and myRoot then
                                            local dist = (myRoot.Position - enemyRoot.Position).Magnitude
                                            if dist <= FarmState.ESPMaxDistance then
                                                addESPToObject(enemy, Color3.fromRGB(255, 0, 0)) -- Red for enemies
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Players ESP
                    if FarmState.ESPPlayers then
                        for _, player in pairs(Players:GetPlayers()) do
                            if player ~= LocalPlayer and player.Character then
                                local playerRoot = player.Character:FindFirstChild("HumanoidRootPart")
                                if playerRoot and myRoot then
                                    local dist = (myRoot.Position - playerRoot.Position).Magnitude
                                    if dist <= FarmState.ESPMaxDistance then
                                        addESPToObject(player.Character, Color3.fromRGB(0, 255, 255)) -- Cyan for players
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Buildings ESP
                    if FarmState.ESPBuildings then
                        local folderNames = {"Buildings", "Tycoon", "Structures"}
                        for _, folderName in ipairs(folderNames) do
                            local folder = workspace:FindFirstChild(folderName)
                            if folder then
                                for _, building in pairs(folder:GetChildren()) do
                                    if building:IsA("Model") then
                                        local buildingRoot = building.PrimaryPart or building:FindFirstChildWhichIsA("BasePart")
                                        if buildingRoot and myRoot then
                                            local dist = (myRoot.Position - buildingRoot.Position).Magnitude
                                            if dist <= FarmState.ESPMaxDistance then
                                                addESPToObject(building, Color3.fromRGB(0, 255, 0)) -- Green for buildings
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            else
                -- Clear all ESP
                for obj, highlight in pairs(ESPHighlights) do
                    removeESPFromObject(obj)
                end
            end
            task.wait(0.5)
        end
    end)
    
    -- Cleanup ESP when objects are removed
    task.spawn(function()
        while true do
            for obj, highlight in pairs(ESPHighlights) do
                if not obj or not obj.Parent then
                    removeESPFromObject(obj)
                end
            end
            task.wait(2)
        end
    end)
    
    -- ESP Status
    local ESPStatusDisplay = Tabs.ESP:AddParagraph({
        Title = "ESP Status",
        Content = "Initializing..."
    })
    
    task.spawn(function()
        while true do
            local coinCount, enemyCount, playerCount, buildingCount = 0, 0, 0, 0
            for obj, _ in pairs(ESPHighlights) do
                local nameLower = obj.Name:lower()
                if string.find(nameLower, "coin") or string.find(nameLower, "drop") or string.find(nameLower, "money") then
                    coinCount = coinCount + 1
                elseif string.find(nameLower, "enemy") or string.find(nameLower, "npc") or string.find(nameLower, "mob") then
                    enemyCount = enemyCount + 1
                elseif Players:GetPlayerFromCharacter(obj) then
                    playerCount = playerCount + 1
                else
                    buildingCount = buildingCount + 1
                end
            end
            
            ESPStatusDisplay.Content = string.format(
                "Status: %s\n\n" ..
                "📊 Tracked Objects:\n" ..
                "- 💰 Coins: %d\n" ..
                "- ⚔️ Enemies: %d\n" ..
                "- 👥 Players: %d\n" ..
                "- 🏠 Buildings: %d\n" ..
                "- 📦 Total: %d\n\n" ..
                "⚙️ Settings:\n" ..
                "- Max Distance: %d studs",
                FarmState.ESPEnabled and "[OK] ACTIVE" or "[X] INACTIVE",
                coinCount, enemyCount, playerCount, buildingCount,
                coinCount + enemyCount + playerCount + buildingCount,
                FarmState.ESPMaxDistance
            )
            task.wait(1)
        end
    end)
    
    -- ==========================================
    -- TELEPORT TAB
    -- ==========================================
    Tabs.Teleport:AddParagraph({
        Title = "[📍] Teleport System",
        Content = "Quick teleport to important locations.\n\n" ..
            "- 🆕 Teleport to coins area\n" ..
            "- 🆕 Teleport to enemies\n" ..
            "- 🆕 Teleport to shop\n" ..
            "- 🆕 Teleport to dojo\n" ..
            "- 🆕 Teleport to spawn"
    })
    
    -- Helper: Find locations
    local function findLocation(names)
        for _, name in ipairs(names) do
            local loc = workspace:FindFirstChild(name)
            if loc then
                local pos = nil
                if loc:IsA("BasePart") then
                    pos = loc.Position
                elseif loc:IsA("Model") then
                    local part = loc.PrimaryPart or loc:FindFirstChildWhichIsA("BasePart")
                    if part then pos = part.Position end
                end
                if pos then return pos end
            end
        end
        return nil
    end
    
    local function teleportTo(position)
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        root.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
    end
    
    Tabs.Teleport:AddButton({
        Title = "💰 Teleport to Coins",
        Callback = function()
            local items = findCollectibles()
            if #items > 0 then
                teleportTo(items[1].position)
                ui.Fluent:Notify({
                    Title = "[📍] Teleport",
                    Content = "Teleported to nearest coin",
                    Duration = 2
                })
            else
                ui.Fluent:Notify({
                    Title = "[!] No Coins",
                    Content = "No coins found in range",
                    Duration = 2
                })
            end
        end
    })
    
    Tabs.Teleport:AddButton({
        Title = "⚔️ Teleport to Enemies",
        Callback = function()
            local enemies = findEnemies()
            if #enemies > 0 then
                teleportTo(enemies[1].root.Position)
                ui.Fluent:Notify({
                    Title = "[📍] Teleport",
                    Content = "Teleported to nearest enemy",
                    Duration = 2
                })
            else
                ui.Fluent:Notify({
                    Title = "[!] No Enemies",
                    Content = "No enemies found in range",
                    Duration = 2
                })
            end
        end
    })
    
    Tabs.Teleport:AddButton({
        Title = "🛒 Teleport to Shop",
        Callback = function()
            local shopPos = findLocation({"Shop", "Store", "Market", "Marketplace"})
            if shopPos then
                teleportTo(shopPos)
                ui.Fluent:Notify({
                    Title = "[📍] Teleport",
                    Content = "Teleported to shop",
                    Duration = 2
                })
            else
                ui.Fluent:Notify({
                    Title = "[!] No Shop",
                    Content = "Shop not found",
                    Duration = 2
                })
            end
        end
    })
    
    Tabs.Teleport:AddButton({
        Title = "🥋 Teleport to Dojo",
        Callback = function()
            local dojoPos = findLocation({"Dojo", "Training", "Gym", "TrainingArea"})
            if dojoPos then
                teleportTo(dojoPos)
                ui.Fluent:Notify({
                    Title = "[📍] Teleport",
                    Content = "Teleported to dojo",
                    Duration = 2
                })
            else
                ui.Fluent:Notify({
                    Title = "[!] No Dojo",
                    Content = "Dojo not found",
                    Duration = 2
                })
            end
        end
    })
    
    Tabs.Teleport:AddButton({
        Title = "🔄 Teleport to Rebirth",
        Callback = function()
            local rebirthPos = findLocation({"Rebirth", "Reset", "Prestige"})
            if rebirthPos then
                teleportTo(rebirthPos)
                ui.Fluent:Notify({
                    Title = "[📍] Teleport",
                    Content = "Teleported to rebirth area",
                    Duration = 2
                })
            else
                ui.Fluent:Notify({
                    Title = "[!] No Rebirth",
                    Content = "Rebirth area not found",
                    Duration = 2
                })
            end
        end
    })
    
    Tabs.Teleport:AddButton({
        Title = "🏠 Teleport to Spawn",
        Callback = function()
            local spawnPos = findLocation({"Spawn", "SpawnPoint", "Start"})
            if spawnPos then
                teleportTo(spawnPos)
                ui.Fluent:Notify({
                    Title = "[📍] Teleport",
                    Content = "Teleported to spawn",
                    Duration = 2
                })
            else
                -- Fallback: spawn location from game
                pcall(function()
                    local spawnLocation = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
                    if spawnLocation then
                        teleportTo(spawnLocation.Position)
                        ui.Fluent:Notify({
                            Title = "[📍] Teleport",
                            Content = "Teleported to spawn point",
                            Duration = 2
                        })
                    end
                end)
            end
        end
    })
    
    -- ==========================================
    -- UTILITIES TAB
    -- ==========================================
    Tabs.Utilities:AddParagraph({
        Title = "[🛠️] Utilities",
        Content = "Miscellaneous tools and features.\n\n" ..
            "- 🆕 Quick rejoin server\n" ..
            "- 🆕 Server hop\n" ..
            "- 🆕 Copy JobId\n" ..
            "- 🆕 Anti-AFK"
    })
    
    Tabs.Utilities:AddButton({
        Title = "🔄 Rejoin Server",
        Callback = function()
            ui.Fluent:Notify({
                Title = "[🔄] Rejoining",
                Content = "Rejoining current server...",
                Duration = 2
            })
            task.wait(1)
            TeleportService:Teleport(placeId, LocalPlayer)
        end
    })
    
    Tabs.Utilities:AddButton({
        Title = "🔀 Server Hop",
        Callback = function()
            ui.Fluent:Notify({
                Title = "[🔀] Server Hop",
                Content = "Hopping to new server...",
                Duration = 2
            })
            task.wait(1)
            TeleportService:Teleport(placeId)
        end
    })
    
    Tabs.Utilities:AddButton({
        Title = "📋 Copy JobId",
        Callback = function()
            local jobId = game.JobId
            if jobId then
                if setclipboard then
                    setclipboard(jobId)
                    ui.Fluent:Notify({
                        Title = "[📋] Copied",
                        Content = "JobId copied to clipboard",
                        Duration = 2
                    })
                else
                    ui.Fluent:Notify({
                        Title = "[!] Error",
                        Content = "Clipboard not supported",
                        Duration = 2
                    })
                end
            end
        end
    })
    
    Tabs.Utilities:AddButton({
        Title = "📍 Copy PlaceId",
        Callback = function()
            if setclipboard then
                setclipboard(tostring(placeId))
                ui.Fluent:Notify({
                    Title = "[📋] Copied",
                    Content = "PlaceId copied to clipboard",
                    Duration = 2
                })
            end
        end
    })
    
    -- Anti-AFK (Always Active)
    local VirtualUser = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
    
    Tabs.Utilities:AddParagraph({
        Title = "Anti-AFK Status",
        Content = "✅ Anti-AFK: ALWAYS ACTIVE\n\nYou will never be kicked for being AFK."
    })
    
    -- Remote Debug
    Tabs.Utilities:AddSection("🔧 Remote Events Debug")
    
    local RemoteDebugDisplay = Tabs.Utilities:AddParagraph({
        Title = "Detected Remotes",
        Content = "Scanning..."
    })
    
    task.spawn(function()
        task.wait(3)
        while true do
            RemoteDebugDisplay.Content = string.format(
                "📡 Detected Remote Events:\n\n" ..
                "- Collect: %s\n" ..
                "- Attack: %s\n" ..
                "- Upgrade: %s\n" ..
                "- Rebirth: %s\n" ..
                "- Train: %s\n\n" ..
                "NOTE: These are auto-detected.\n" ..
                "If any show 'Not Found',\n" ..
                "the game uses different remote names.",
                Remotes.Collect and "✓ " .. Remotes.Collect.Name or "✗ Not Found",
                Remotes.Attack and "✓ " .. Remotes.Attack.Name or "✗ Not Found",
                Remotes.Upgrade and "✓ " .. Remotes.Upgrade.Name or "✗ Not Found",
                Remotes.Rebirth and "✓ " .. Remotes.Rebirth.Name or "✗ Not Found",
                Remotes.Train and "✓ " .. Remotes.Train.Name or "✗ Not Found"
            )
            task.wait(2)
        end
    end)
    
    -- ==========================================
    -- CHARACTER ADDED HANDLER
    -- ==========================================
    LocalPlayer.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart")
        task.wait(2)
        
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if FarmState.CustomWalkSpeed then
                hum.WalkSpeed = FarmState.WalkSpeed
            end
            if FarmState.CustomJumpPower then
                if hum.UseJumpPower == false then
                    hum.JumpHeight = FarmState.JumpPower
                else
                    hum.JumpPower = FarmState.JumpPower
                end
            end
            if FarmState.GodModeEnabled then
                hum.MaxHealth = math.huge
                hum.Health = math.huge
            end
        end
    end)
    
    -- ==========================================
    -- INITIAL NOTIFICATION
    -- ==========================================
    ui.Window:SelectTab(1)
    ui.Fluent:Notify({
        Title = "GlockreisHub",
        Content = "Ninja Tycoon Loaded! All features active.",
        Duration = 5
    })
    
    -- Anti-AFK notification
    task.delay(3, function()
        ui.Fluent:Notify({
            Title = "[🛡️] Anti-AFK",
            Content = "Anti-AFK is always active",
            Duration = 3
        })
    end)
end
