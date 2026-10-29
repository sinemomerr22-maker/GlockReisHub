-- // ==========================================
-- // GLOCKREISHUB - BLOX FRUITS MODULE
-- // ==========================================

return function(Common)
    local Fluent = Common.Fluent
    local LocalPlayer = Common.LocalPlayer
    local TweenService = Common.TweenService
    local RunService = Common.RunService
    local TeleportService = Common.TeleportService
    local ReplicatedStorage = Common.ReplicatedStorage
    local UserInputService = Common.UserInputService
    local HttpService = Common.HttpService
    local MarketplaceService = Common.MarketplaceService
    
    local BLOX_FRUITS_FIRST_SEA_PLACEID = 2753915549
    
    -- Config
    local DefaultConfig = {
        FruitSniper = false, SmartHop = true, Team = "Pirates", TweenSpeed = 250,
        ScanDelay = 0.5, ScanTimeBeforeHop = 5, AutoStore = true, WebhookURL = "",
        StartupDelay = 3,
        TargetFruits = {"Buddha", "Portal", "Lightning", "Pain", "Blizzard", "Gravity", "Mammoth", "T-Rex", "Dough", "Shadow", "Venom", "Control", "Spirit", "Gas", "Dragon", "Leopard", "Yeti", "Kitsune"},
        ChestFarm = false, ChestTweenSpeed = 200, ChestScanDelay = 0.5,
        ChestScanTimeBeforeHop = 10, ChestAutoHop = true, CollectMoney = true,
        CollectExpOrbs = true, ChestHopDelay = 3, TargetChests = {"Silver", "Gold", "Diamond"}
    }
    
    local ConfigManager = Common.setupConfigManager("BloxFruits")
    local Config = ConfigManager.Load(DefaultConfig)
    
    -- UI
    local ui = Common.loadFluentUI("Blox Fruits", game.PlaceId)
    local Window = ui.Window
    local Options = ui.Options
    
    -- Shared Infrastructure
    local SharedInfra = {
        BlacklistedServers = {},
        isHopping = false,
        SharedState = {
            Character = nil,
            HRP = nil,
            CommF = nil,
            Ready = false,
            DelayComplete = false,
            DelaySecondsRemaining = Config.StartupDelay or 3
        },
        VisitedChests = {}
    }
    
    -- Stats
    local FruitStats = { ServersHopped = 0, FruitsStored = 0 }
    local ChestStats = { ServersHopped = 0, ChestsOpened = 0, MoneyCollected = 0 }
    
    -- Webhook
    local function SendWebhook(title, description, color)
        local url = Config.WebhookURL
        if not url or url == "" then return end
        pcall(function()
            local req = (syn and syn.request) or (http and http.request) or request
            if req then
                req({
                    Url = url,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode({
                        embeds = {{
                            title = title,
                            description = description,
                            color = color,
                            footer = {text = "GLOCKREIS FRUIT SNIPER"},
                            timestamp = DateTime.now():ToIsoDate()
                        }}
                    })
                })
            end
        end)
    end
    
    -- HTTP Get
    local function httpGet(url)
        local req = (syn and syn.request) or (http and http.request) or request or (http_request)
        if req then
            local ok, res = pcall(function()
                return req({Url = url, Method = "GET"})
            end)
            if ok and res and res.Body and res.StatusCode and res.StatusCode < 400 then
                return res.Body
            end
        end
        local ok2, body = pcall(function() return game:HttpGet(url) end)
        if ok2 and body and type(body) == "string" and #body > 10 then return body end
        return nil
    end
    
    -- Get Servers
    local function GetServers()
        local proxyUrls = {
            string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", BLOX_FRUITS_FIRST_SEA_PLACEID),
            string.format("https://games.roproxy.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", BLOX_FRUITS_FIRST_SEA_PLACEID),
            string.format("https://games.roproxy.cc/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", BLOX_FRUITS_FIRST_SEA_PLACEID),
            string.format("https://games.rprxy.xyz/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", BLOX_FRUITS_FIRST_SEA_PLACEID),
        }
        for _, url in ipairs(proxyUrls) do
            local body = httpGet(url)
            if body then
                local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
                if ok and data and type(data) == "table" and data.data and type(data.data) == "table" and #data.data > 0 then
                    return data
                end
            end
        end
        return nil
    end
    
    -- Server Hop
    local function ServerHop(reason)
        if SharedInfra.isHopping then return end
        SharedInfra.isHopping = true
        SharedInfra.VisitedChests = {}
        local smartHopEnabled = (Config.SmartHop or Config.ChestAutoHop)
        local statusPrefix = reason or "Hop"
        FruitConfig_Status_Global = "🔍 " .. statusPrefix .. " - Finding Server..."
        
        if smartHopEnabled then
            local data = GetServers()
            if data and data.data then
                local servers = data.data
                for i = #servers, 2, -1 do
                    local j = math.random(i)
                    servers[i], servers[j] = servers[j], servers[i]
                end
                
                for _, server in ipairs(servers) do
                    local sid = tostring(server.id)
                    if not SharedInfra.BlacklistedServers[sid] 
                       and server.playing and server.maxPlayers
                       and server.playing < server.maxPlayers
                       and (not server.accessCode or server.accessCode == "")
                    then
                        FruitConfig_Status_Global = "🚀 Hopping (" .. server.playing .. "/" .. server.maxPlayers .. ")"
                        
                        local ok, err = pcall(function()
                            TeleportService:TeleportToPlaceInstance(BLOX_FRUITS_FIRST_SEA_PLACEID, server.id, LocalPlayer)
                        end)
                        
                        if ok then
                            if FruitStats then FruitStats.ServersHopped = FruitStats.ServersHopped + 1 end
                            if ChestStats then ChestStats.ServersHopped = ChestStats.ServersHopped + 1 end
                            Fluent:Notify({Title = "Server Hop", Content = "First Sea: " .. server.playing .. "/" .. server.maxPlayers, Duration = 3})
                            task.wait(10)
                            SharedInfra.isHopping = false
                            return true
                        else
                            SharedInfra.BlacklistedServers[sid] = true
                            task.wait(0.5)
                        end
                    end
                end
            end
        end
        
        FruitConfig_Status_Global = "🎲 Random Hop..."
        local ok = pcall(function()
            TeleportService:Teleport(BLOX_FRUITS_FIRST_SEA_PLACEID, LocalPlayer)
        end)
        if ok then
            if FruitStats then FruitStats.ServersHopped = FruitStats.ServersHopped + 1 end
            if ChestStats then ChestStats.ServersHopped = ChestStats.ServersHopped + 1 end
            Fluent:Notify({Title = "Server Hop", Content = "Random First Sea teleport", Duration = 3})
            task.wait(10)
        end
        SharedInfra.isHopping = false
        return ok
    end
    
    -- Teleport Failed Handler
    TeleportService.TeleportInitFailed:Connect(function(player, result, message)
        if player == LocalPlayer then
            if game.JobId and game.JobId ~= "" then
                SharedInfra.BlacklistedServers[game.JobId] = true
            end
            SharedInfra.isHopping = false
            task.wait(2)
            if (FruitConfig_Enabled or ChestConfig_Enabled) and SharedInfra.SharedState.DelayComplete then
                ServerHop("Teleport Failed")
            end
        end
    end)
    
    -- Global Status Variables
    FruitConfig_Status_Global = "Initializing..."
    FruitConfig_Enabled = false
    ChestConfig_Enabled = false
    
    -- Character Initialization
    task.spawn(function()
        FruitConfig_Status_Global = "⏳ Waiting for character..."
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
        if not remotes then
            FruitConfig_Status_Global = "❌ Remotes not found (30s timeout)"
            Fluent:Notify({Title = "Error", Content = "Remotes folder not found.", Duration = 5})
            return
        end
        
        SharedInfra.SharedState.CommF = remotes:WaitForChild("CommF_", 30)
        if not SharedInfra.SharedState.CommF then
            FruitConfig_Status_Global = "❌ CommF_ not found"
            return
        end
        
        if not LocalPlayer.Character then
            FruitConfig_Status_Global = "🎭 Auto-selecting team: " .. (Config.Team or "Pirates") .. "..."
            Fluent:Notify({
                Title = "Auto Team Select",
                Content = "Selecting " .. (Config.Team or "Pirates") .. " automatically.",
                Duration = 4
            })
            pcall(function()
                SharedInfra.SharedState.CommF:InvokeServer("SetTeam", Config.Team or "Pirates")
            end)
        end
        
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        SharedInfra.SharedState.Character = char
        local hrp = char:WaitForChild("HumanoidRootPart", 30)
        if not hrp then
            FruitConfig_Status_Global = "❌ HumanoidRootPart not found"
            return
        end
        SharedInfra.SharedState.HRP = hrp
        
        LocalPlayer.CharacterAdded:Connect(function(newChar)
            SharedInfra.SharedState.Character = newChar
            local newHRP = newChar:WaitForChild("HumanoidRootPart", 10)
            if newHRP then
                SharedInfra.SharedState.HRP = newHRP
            end
        end)
        
        SharedInfra.SharedState.Ready = true
        Fluent:Notify({
            Title = "✅ Character Spawned",
            Content = "Starting " .. (Config.StartupDelay or 3) .. "s anti-detection delay...",
            Duration = 3
        })
        
        SharedInfra.SharedState.DelaySecondsRemaining = Config.StartupDelay or 3
        for i = Config.StartupDelay or 3, 1, -1 do
            SharedInfra.SharedState.DelaySecondsRemaining = i
            FruitConfig_Status_Global = string.format("⏳ Startup delay: %ds remaining...", i)
            Fluent:Notify({
                Title = "⏱️ Anti-Detection Delay",
                Content = "Scripts armed in " .. i .. " second(s)...",
                Duration = 1.5
            })
            task.wait(1)
        end
        
        SharedInfra.SharedState.DelayComplete = true
        SharedInfra.SharedState.DelaySecondsRemaining = 0
        FruitConfig_Status_Global = "🟢️ Ready"
        Fluent:Notify({
            Title = "🚀 GlockreisHub Armed",
            Content = "Fruit Sniper & Chest Farm ready!",
            Duration = 4
        })
        SendWebhook("✅ Script Armed", "**Startup delay:** " .. (Config.StartupDelay or 3) .. "s complete\n**Server:** " .. (game.JobId or "Unknown"), 3066993)
    end)
    
    -- UI Tabs
    local Tabs = {}
    Tabs.Sniper = Window:AddTab({ Title = "Fruit Sniper", Icon = "target" })
    Tabs.Fruits = Window:AddTab({ Title = "Target Fruits", Icon = "apple" })
    Tabs.Chest = Window:AddTab({ Title = "Chest Farm", Icon = "box" })
    Tabs.Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
    
    -- Fruit Sniper Configuration
    local FruitConfig = {
        Enabled = Config.FruitSniper,
        SmartHop = Config.SmartHop,
        Team = Config.Team,
        TweenSpeed = Config.TweenSpeed,
        ScanDelay = Config.ScanDelay or 0.5,
        ScanTimeBeforeHop = Config.ScanTimeBeforeHop or 5,
        AutoStore = Config.AutoStore,
        WebhookURL = Config.WebhookURL,
        StartupDelay = Config.StartupDelay or 3,
        TargetFruits = Config.TargetFruits or {},
        Status = "Initializing...",
        Stats = FruitStats
    }
    FruitConfig_Enabled = FruitConfig.Enabled
    
    local notifiedNotFound = false
    local scanStartTime = 0
    
    -- Fruit Lists
    local FruitList = {
        "Rocket", "Spin", "Blade", "Spring", "Bomb", "Smoke", "Spike", "Flame", "Ice", "Sand",
        "Dark", "Falcon", "Diamond", "Ghost", "Light", "Rubber", "Magma", "Quake", "Buddha", "Love",
        "Spider", "Sound", "Phoenix", "Portal", "Lightning", "Pain", "Blizzard", "Gravity", "Mammoth",
        "T-Rex", "Dough", "Shadow", "Venom", "Control", "Spirit", "Gas", "Dragon", "Leopard", "Yeti", "Kitsune"
    }
    
    local FruitAliases = {
        Buddha = {"Buddha", "Buddah"},
        Phoenix = {"Phoenix", "Pheonix"},
        ["T-Rex"] = {"T-Rex", "TRex", "T Rex"},
        Spirit = {"Spirit", "Soul"},
        Gravity = {"Gravity", "Magnet"},
        Falcon = {"Falcon", "Eagle"},
        Ghost = {"Ghost", "Revive"},
        Blade = {"Blade", "Chop"},
        Yeti = {"Yeti", "Tiki"}
    }
    
    -- Get Target Fruit
    local function GetTargetFruit()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
                local objNameLower = string.lower(obj.Name)
                for _, fruitName in ipairs(FruitConfig.TargetFruits) do
                    local aliases = FruitAliases[fruitName] or {fruitName}
                    for _, alias in ipairs(aliases) do
                        if string.find(objNameLower, string.lower(alias), 1, true) then
                            return obj, fruitName
                        end
                    end
                end
            end
        end
        return nil
    end
    
    -- Acquire Fruit
    local function AcquireFruit(target, fruitName)
        local HRP = SharedInfra.SharedState.HRP
        local Character = SharedInfra.SharedState.Character
        if not HRP or not HRP.Parent then return false end
        if not target or not target.Parent then return false end
        local handle = target:FindFirstChild("Handle")
        if not handle then return false end
        
        FruitConfig.Status = "🏃 Tweening to " .. fruitName .. "..."
        local dist = (HRP.Position - handle.Position).Magnitude
        local tweenTime = math.max(dist / FruitConfig.TweenSpeed, 0.1)
        local tween = TweenService:Create(HRP, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {CFrame = handle.CFrame})
        tween:Play()
        
        local tweenDone = false
        tween.Completed:Connect(function() tweenDone = true end)
        while not tweenDone do
            task.wait(0.05)
            if not target or not target.Parent or not handle.Parent then
                tween:Cancel()
                FruitConfig.Status = "⚠️ " .. fruitName .. " stolen!"
                Fluent:Notify({Title = "Stolen!", Content = fruitName .. " taken by someone else.", Duration = 3})
                return false
            end
        end
        
        FruitConfig.Status = "⏳ Waiting for " .. fruitName .. " pickup..."
        local pickupStart = tick()
        local PICKUP_TIMEOUT = 10
        while target and target.Parent and target.Parent == workspace do
            if tick() - pickupStart > PICKUP_TIMEOUT then
                FruitConfig.Status = "⚠️ Pickup timeout for " .. fruitName
                return false
            end
            if handle and handle.Parent then
                pcall(function() HRP.CFrame = handle.CFrame end)
            end
            pcall(function()
                local hum = Character and Character:FindFirstChild("Humanoid")
                if hum and target and target.Parent then hum:EquipTool(target) end
            end)
            task.wait(0.1)
        end
        
        local pickedUpByUs = false
        if target and target.Parent then
            if target.Parent == Character or target.Parent == LocalPlayer:FindFirstChild("Backpack") then
                pickedUpByUs = true
            end
        end
        if not pickedUpByUs then
            FruitConfig.Status = "⚠️ " .. fruitName .. " stolen!"
            return false
        end
        
        FruitConfig.Status = "🔒 Holding " .. fruitName .. " for 2s..."
        local holdStart = tick()
        local holdPos = HRP.CFrame
        while tick() - holdStart < 2 do
            pcall(function()
                HRP.CFrame = holdPos
                for _, part in pairs(Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.AssemblyLinearVelocity = Vector3.zero
                        part.AssemblyAngularVelocity = Vector3.zero
                    end
                end
            end)
            task.wait(0.05)
        end
        return true
    end
    
    -- Store Fruit
    local function StoreFruitWithRetry(target, fruitName)
        if not FruitConfig.AutoStore then return false end
        local CommF = SharedInfra.SharedState.CommF
        if not CommF then return false end
        
        FruitConfig.Status = "📦 Storing " .. fruitName .. "..."
        local originalName = target:GetAttribute("OriginalName") or target.Name
        local storeStart = tick()
        local STORE_TIMEOUT = 5
        local stored = false
        
        while tick() - storeStart < STORE_TIMEOUT do
            if not target or not target.Parent then break end
            local Character = SharedInfra.SharedState.Character
            if target.Parent ~= Character and target.Parent ~= LocalPlayer:FindFirstChild("Backpack") then
                break
            end
            local ok, result = pcall(function()
                return CommF:InvokeServer("StoreFruit", originalName, target)
            end)
            if ok and result == true then
                stored = true
                break
            end
            pcall(function() CommF:FireServer("StoreFruit", originalName, target) end)
            task.wait(0.3)
        end
        
        if stored then
            FruitConfig.Stats.FruitsStored = FruitConfig.Stats.FruitsStored + 1
            SendWebhook("🚨 FRUIT SECURED!", "**Fruit:** " .. fruitName .. "\n**Server:** " .. (game.JobId or "Unknown"), 3066993)
            Fluent:Notify({Title = "✅ Fruit Stored", Content = fruitName .. " stored!", Duration = 3})
            FruitConfig.Status = "✅ " .. fruitName .. " stored!"
            return true
        else
            Fluent:Notify({Title = "⚠️ Store Failed", Content = fruitName .. " store failed", Duration = 3})
            FruitConfig.Status = "⚠️ Store failed for " .. fruitName
            return false
        end
    end
    
    -- Fruit Sniper Main Loop
    task.spawn(function()
        while not (SharedInfra.SharedState.Ready and SharedInfra.SharedState.DelayComplete) do
            task.wait(0.5)
        end
        
        while true do
            if FruitConfig.Enabled and SharedInfra.SharedState.Ready and SharedInfra.SharedState.DelayComplete then
                FruitConfig_Enabled = true
                local HRP = SharedInfra.SharedState.HRP
                if not HRP or not HRP.Parent or not SharedInfra.SharedState.Character then
                    FruitConfig.Status = "⏳ Waiting for respawn..."
                    task.wait(1)
                    continue
                end
                
                if scanStartTime == 0 then scanStartTime = tick() end
                local elapsed = tick() - scanStartTime
                FruitConfig.Status = string.format("👁️ Scanning (%.1fs / %.1fs)", elapsed, FruitConfig.ScanTimeBeforeHop)
                FruitConfig_Status_Global = FruitConfig.Status
                
                local target, fruitName = GetTargetFruit()
                if target and target.Parent and target:FindFirstChild("Handle") then
                    FruitConfig.Status = "🎯 FOUND: " .. fruitName .. "!"
                    notifiedNotFound = false
                    scanStartTime = 0
                    Fluent:Notify({Title = "🎯 TARGET FOUND", Content = fruitName .. " | Acquiring...", Duration = 5})
                    SendWebhook("🎯 Fruit Detected", "**Fruit:** " .. fruitName, 3066993)
                    
                    local acquired = AcquireFruit(target, fruitName)
                    if acquired then
                        local stored = StoreFruitWithRetry(target, fruitName)
                        task.wait(1)
                        if FruitConfig.SmartHop then
                            FruitConfig.Status = "🚀 Post-store hop..."
                            ServerHop("Post-Store")
                        end
                    else
                        FruitConfig.Status = "🔄 Rescanning..."
                        task.wait(1)
                    end
                else
                    if not notifiedNotFound then
                        notifiedNotFound = true
                        Fluent:Notify({Title = "🔍 Scanning", Content = "No targets. " .. FruitConfig.ScanTimeBeforeHop .. "s...", Duration = 2})
                    end
                    if FruitConfig.SmartHop and elapsed >= FruitConfig.ScanTimeBeforeHop then
                        FruitConfig.Status = "⏱️ Time's up, hopping..."
                        scanStartTime = 0
                        notifiedNotFound = false
                        ServerHop("No Fruits")
                    end
                end
            else
                FruitConfig_Enabled = false
                if not SharedInfra.SharedState.Ready then
                    FruitConfig.Status = "⏳ Initializing..."
                elseif not SharedInfra.SharedState.DelayComplete then
                    FruitConfig.Status = string.format("⏳ Startup delay: %ds", SharedInfra.SharedState.DelaySecondsRemaining)
                else
                    FruitConfig.Status = "⏸️ Idle"
                end
                scanStartTime = 0
                notifiedNotFound = false
            end
            FruitConfig_Status_Global = FruitConfig.Status
            task.wait(FruitConfig.ScanDelay)
        end
    end)
    
    -- Fruit Sniper UI
    Tabs.Sniper:AddToggle("SniperToggle", {
        Title = "Enable Fruit Sniper",
        Description = "Auto-scan, tween, and store target fruits.",
        Default = Config.FruitSniper
    }):OnChanged(function(v)
        FruitConfig.Enabled = v
        FruitConfig_Enabled = v
        Config.FruitSniper = v
        ConfigManager.Save(Config)
        scanStartTime = 0
        notifiedNotFound = false
        if v then
            if SharedInfra.SharedState.DelayComplete then
                Fluent:Notify({Title = "Sniper Active", Content = "Guaranteed pickup mode", Duration = 3})
            else
                Fluent:Notify({Title = "Sniper Queued", Content = "Waiting for startup delay", Duration = 3})
            end
        end
    end)
    
    Tabs.Sniper:AddToggle("SmartHopToggle", {
        Title = "Smart Server Hop",
        Description = "Auto-hop AFTER fruit is stored.",
        Default = Config.SmartHop
    }):OnChanged(function(v)
        FruitConfig.SmartHop = v
        Config.SmartHop = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.Sniper:AddSlider("ScanDelaySlider", {
        Title = "Scan Speed (seconds)", Default = FruitConfig.ScanDelay, Min = 0.1, Max = 5, Rounding = 1,
        Callback = function(v) FruitConfig.ScanDelay = v; Config.ScanDelay = v; ConfigManager.Save(Config) end
    })
    
    Tabs.Sniper:AddSlider("ScanTimeBeforeHopSlider", {
        Title = "Time Before Hop (seconds)", Default = FruitConfig.ScanTimeBeforeHop, Min = 2, Max = 60, Rounding = 0,
        Callback = function(v) FruitConfig.ScanTimeBeforeHop = v; Config.ScanTimeBeforeHop = v; ConfigManager.Save(Config) end
    })
    
    Tabs.Sniper:AddSlider("TweenSpeedSlider", {
        Title = "Tween Speed (studs/sec)", Default = Config.TweenSpeed, Min = 50, Max = 400, Rounding = 0,
        Callback = function(v) FruitConfig.TweenSpeed = v; Config.TweenSpeed = v; ConfigManager.Save(Config) end
    })
    
    Tabs.Sniper:AddToggle("AutoStoreToggle", {
        Title = "Auto-Store Fruits", Default = Config.AutoStore
    }):OnChanged(function(v) FruitConfig.AutoStore = v; Config.AutoStore = v; ConfigManager.Save(Config) end)
    
    local FruitStatusDisplay = Tabs.Sniper:AddParagraph({Title = "Sniper Status", Content = "Initializing..."})
    task.spawn(function()
        while true do
            local delayInfo = ""
            if not SharedInfra.SharedState.DelayComplete then
                delayInfo = string.format("\n⏳ Startup Delay: %ds remaining", SharedInfra.SharedState.DelaySecondsRemaining)
            else
                delayInfo = string.format("\n✅ Armed (delay was %ds)", FruitConfig.StartupDelay)
            end
            FruitStatusDisplay.Content = string.format(
                "Status: %s\nServers Hopped: %d\nFruits Stored: %d\nTeam: %s\nSmart Hop: %s\nScan Delay: %.1fs\nHop After: %ds%s",
                FruitConfig.Status, FruitStats.ServersHopped, FruitStats.FruitsStored,
                FruitConfig.Team, FruitConfig.SmartHop and "Enabled" or "Disabled",
                FruitConfig.ScanDelay, FruitConfig.ScanTimeBeforeHop, delayInfo
            )
            task.wait(0.3)
        end
    end)
    
    -- Target Fruits UI
    local validFruits = {}
    for _, v in ipairs(FruitConfig.TargetFruits) do
        if table.find(FruitList, v) then table.insert(validFruits, v) end
    end
    local defaultFruitsDict = {}
    for _, v in ipairs(validFruits) do defaultFruitsDict[v] = true end
    
    local FruitDropdown = Tabs.Fruits:AddDropdown("FruitDropdown", {
        Title = "Target Fruits", Values = FruitList, Multi = true, Default = defaultFruitsDict, Flag = "FruitsFlag"
    })
    
    FruitDropdown:OnChanged(function(Value)
        local parsed = {}
        if type(Value) == "table" then
            for k, v in pairs(Value) do
                if type(k) == "string" and v == true then table.insert(parsed, k)
                elseif type(k) == "number" and type(v) == "string" then table.insert(parsed, v) end
            end
        end
        FruitConfig.TargetFruits = parsed
        Config.TargetFruits = parsed
        ConfigManager.Save(Config)
        notifiedNotFound = false
    end)
    
    Tabs.Fruits:AddButton({Title = "Select All Mythical/Legendary", Callback = function()
        local mythical = {"Buddha", "Portal", "Lightning", "Pain", "Blizzard", "Gravity", "Mammoth", "T-Rex", "Dough", "Shadow", "Venom", "Control", "Spirit", "Gas", "Dragon", "Leopard", "Yeti", "Kitsune"}
        FruitConfig.TargetFruits = mythical
        Config.TargetFruits = mythical
        ConfigManager.Save(Config)
        if Options.FruitsFlag then
            local dict = {}
            for _, v in ipairs(mythical) do dict[v] = true end
            Options.FruitsFlag.Value = dict
        end
    end})
    
    Tabs.Fruits:AddButton({Title = "Clear All", Callback = function()
        FruitConfig.TargetFruits = {}
        Config.TargetFruits = {}
        ConfigManager.Save(Config)
        if Options.FruitsFlag then Options.FruitsFlag.Value = {} end
    end})
    
    -- Chest Farm Configuration
    local ChestConfig = {
        Enabled = Config.ChestFarm,
        TweenSpeed = Config.ChestTweenSpeed or 200,
        ScanDelay = Config.ChestScanDelay or 0.5,
        ScanTimeBeforeHop = Config.ChestScanTimeBeforeHop or 10,
        AutoHop = Config.ChestAutoHop,
        CollectMoney = Config.CollectMoney,
        CollectExpOrbs = Config.CollectExpOrbs,
        HopDelay = Config.ChestHopDelay or 3,
        TargetChests = Config.TargetChests or {"Silver", "Gold", "Diamond"},
        Status = "Idle",
        Stats = ChestStats
    }
    ChestConfig_Enabled = ChestConfig.Enabled
    
    local chestScanStartTime = 0
    local chestNotifiedNotFound = false
    local ChestModelsFolder = nil
    
    task.spawn(function()
        ChestModelsFolder = workspace:FindFirstChild("ChestModels")
            or workspace:WaitForChild("ChestModels", 60)
        if ChestModelsFolder then
            Fluent:Notify({
                Title = "✅ ChestModels Ready",
                Content = "Found " .. #ChestModelsFolder:GetChildren() .. " chest models.",
                Duration = 3
            })
        else
            Fluent:Notify({
                Title = "❌ ChestModels Missing",
                Content = "Folder not found in 60s. Chest Farm disabled.",
                Duration = 10
            })
        end
    end)
    
    -- Get Target Chest
    local function GetTargetChest()
        local HRP = SharedInfra.SharedState.HRP
        if not HRP or not HRP.Parent then return nil, nil, nil end
        
        if not ChestModelsFolder or not ChestModelsFolder.Parent then
            ChestModelsFolder = workspace:FindFirstChild("ChestModels")
            if not ChestModelsFolder then return nil, nil, nil end
        end
        
        local bestChest, bestDist, bestType, bestTargetPart = nil, math.huge, nil, nil
        for _, obj in ipairs(ChestModelsFolder:GetChildren()) do
            if SharedInfra.VisitedChests[obj] then continue end
            if not (obj:IsA("Model") or obj:IsA("BasePart")) then continue end
            
            local name = string.lower(obj.Name)
            local chestType
            if string.find(name, "diamond") then chestType = "Diamond"
            elseif string.find(name, "gold") then chestType = "Gold"
            elseif string.find(name, "silver") then chestType = "Silver"
            else chestType = "Chest" end
            
            if not table.find(ChestConfig.TargetChests, chestType) then continue end
            
            local isOpened = false
            for _, attr in ipairs({"Opened", "Claimed", "Used", "Collected", "looted"}) do
                if obj:GetAttribute(attr) then isOpened = true; break end
                if obj:FindFirstChild(attr) then isOpened = true; break end
            end
            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt and prompt.Enabled == false then isOpened = true end
            if isOpened then
                SharedInfra.VisitedChests[obj] = true
                continue
            end
            
            local targetPart = obj:FindFirstChild("RootPart", true)
                or obj:FindFirstChild("Hitbox", true)
                or obj:FindFirstChild("HumanoidRootPart", true)
                or (obj:IsA("Model") and obj.PrimaryPart)
                or obj:FindFirstChildWhichIsA("BasePart", true)
                or (obj:IsA("BasePart") and obj)
            if not targetPart or not targetPart.Parent then continue end
            
            local dist = (HRP.Position - targetPart.Position).Magnitude
            if dist < bestDist then
                bestDist = dist
                bestChest = obj
                bestTargetPart = targetPart
                bestType = chestType
            end
        end
        return bestChest, bestType, bestTargetPart
    end
    
    -- Collect Money and Orbs
    local function CollectMoneyAndOrbs()
        local HRP = SharedInfra.SharedState.HRP
        local Character = SharedInfra.SharedState.Character
        if not HRP or not Character then return 0 end
        local collected = 0
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local name = string.lower(obj.Name)
                local shouldCollect = false
                if ChestConfig.CollectMoney and (string.match(name, "money") or string.match(name, "beli") or string.match(name, "coin")) then
                    shouldCollect = true
                elseif ChestConfig.CollectExpOrbs and (string.match(name, "exp") or string.match(name, "experience") or string.match(name, "orb")) then
                    shouldCollect = true
                end
                if shouldCollect and obj.Parent then
                    pcall(function()
                        obj.CFrame = HRP.CFrame
                        collected = collected + 1
                    end)
                end
            end
        end
        return collected
    end
    
    -- Acquire Chest
    local function AcquireChest(chest, chestType, targetPart)
        local HRP = SharedInfra.SharedState.HRP
        local Character = SharedInfra.SharedState.Character
        local CommF = SharedInfra.SharedState.CommF
        if not HRP or not HRP.Parent then return false end
        if not chest or not chest.Parent then return false end
        if not targetPart then return false end
        
        SharedInfra.VisitedChests[chest] = true
        ChestConfig.Status = "🏃 Tweening to " .. chestType .. " Chest..."
        local dist = (HRP.Position - targetPart.Position).Magnitude
        local tweenTime = math.max(dist / ChestConfig.TweenSpeed, 0.1)
        local targetCFrame = targetPart.CFrame + Vector3.new(0, 2, 0)
        local tween = TweenService:Create(HRP, TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCFrame})
        tween:Play()
        
        local tweenDone = false
        tween.Completed:Connect(function() tweenDone = true end)
        while not tweenDone do
            task.wait(0.05)
            if not chest or not chest.Parent or not targetPart.Parent then
                tween:Cancel()
                ChestConfig.Status = "⚠️ " .. chestType .. " Chest disappeared!"
                return false
            end
        end
        
        ChestConfig.Status = "🔓 Opening " .. chestType .. " Chest..."
        local opened = false
        
        if CommF then
            pcall(function()
                CommF:InvokeServer("OpenChest", chest.Name, chest)
                opened = true
            end)
            if not opened then
                pcall(function()
                    CommF:FireServer("OpenChest", chest.Name, chest)
                    opened = true
                end)
            end
            if opened then task.wait(0.8) end
        end
        
        if not opened then
            local prompt = chest:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                pcall(function() fireproximityprompt(prompt) end)
                opened = true
                task.wait(0.8)
            end
        end
        
        if not opened then
            local click = chest:FindFirstChildWhichIsA("ClickDetector", true)
            if click then
                pcall(function() fireclickdetector(click) end)
                opened = true
                task.wait(0.8)
            end
        end
        
        if not opened then
            ChestConfig.Status = "🦶 Touching " .. chestType .. " Chest..."
            local touchStart = tick()
            while tick() - touchStart < ChestConfig.HopDelay do
                if not chest or not chest.Parent then break end
                pcall(function()
                    HRP.CFrame = targetCFrame
                    for _, part in pairs(Character:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.AssemblyLinearVelocity = Vector3.zero
                            part.AssemblyAngularVelocity = Vector3.zero
                        end
                    end
                end)
                task.wait(0.1)
            end
            opened = true
            task.wait(0.5)
        end
        
        if opened then
            ChestConfig.Stats.ChestsOpened = ChestConfig.Stats.ChestsOpened + 1
            SendWebhook("📦 Chest Opened", "**Type:** " .. chestType .. " Chest\n**Server:** " .. (game.JobId or "Unknown"), 16776960)
            Fluent:Notify({Title = "✅ " .. chestType .. " Chest Opened", Content = "Loot collected!", Duration = 2})
            ChestConfig.Status = "✅ " .. chestType .. " Chest opened!"
            task.wait(1.5)
            return true
        end
        
        ChestConfig.Status = "⚠️ Could not open " .. chestType .. " Chest"
        return false
    end
    
    -- Chest Farm Main Loop
    task.spawn(function()
        while not (SharedInfra.SharedState.Ready and SharedInfra.SharedState.DelayComplete) do
            task.wait(0.5)
        end
        
        while true do
            if ChestConfig.Enabled and SharedInfra.SharedState.Ready and SharedInfra.SharedState.DelayComplete then
                ChestConfig_Enabled = true
                local HRP = SharedInfra.SharedState.HRP
                if not HRP or not HRP.Parent or not SharedInfra.SharedState.Character then
                    ChestConfig.Status = "⏳ Waiting for respawn..."
                    task.wait(1)
                    continue
                end
                
                if ChestConfig.CollectMoney or ChestConfig.CollectExpOrbs then
                    local collected = CollectMoneyAndOrbs()
                    if collected > 0 then
                        ChestConfig.Stats.MoneyCollected = ChestConfig.Stats.MoneyCollected + collected
                    end
                end
                
                if chestScanStartTime == 0 then chestScanStartTime = tick() end
                local elapsed = tick() - chestScanStartTime
                
                local visitedCount = 0
                for _ in pairs(SharedInfra.VisitedChests) do visitedCount = visitedCount + 1 end
                
                ChestConfig.Status = string.format("👁️ Scanning (%.1fs / %.1fs) [%d visited]",
                    elapsed, ChestConfig.ScanTimeBeforeHop, visitedCount)
                
                local targetChest, chestType, targetPart = GetTargetChest()
                if targetChest and targetChest.Parent then
                    ChestConfig.Status = "🎯 FOUND: " .. chestType .. " Chest!"
                    chestNotifiedNotFound = false
                    chestScanStartTime = 0
                    Fluent:Notify({Title = "🎯 Chest Found", Content = chestType .. " Chest | Opening...", Duration = 3})
                    
                    local opened = AcquireChest(targetChest, chestType, targetPart)
                    if opened then
                        task.wait(0.5)
                    else
                        ChestConfig.Status = "🔄 Trying next chest..."
                        task.wait(0.5)
                    end
                else
                    if not chestNotifiedNotFound then
                        chestNotifiedNotFound = true
                        local targetsText = #ChestConfig.TargetChests > 0 and table.concat(ChestConfig.TargetChests, "/") or "None"
                        Fluent:Notify({
                            Title = "🔍 No Matching Chests",
                            Content = "Looking for: " .. targetsText .. ". " .. ChestConfig.ScanTimeBeforeHop .. "s...",
                            Duration = 3
                        })
                    end
                    ChestConfig.Status = string.format("🔍 No chests (%.1fs / %.1fs)", elapsed, ChestConfig.ScanTimeBeforeHop)
                    if ChestConfig.AutoHop and elapsed >= ChestConfig.ScanTimeBeforeHop then
                        ChestConfig.Status = "⏱️ Hopping to new server..."
                        chestScanStartTime = 0
                        chestNotifiedNotFound = false
                        ServerHop("No Chests")
                    end
                end
            else
                ChestConfig_Enabled = false
                if not SharedInfra.SharedState.Ready then
                    ChestConfig.Status = "⏳ Initializing..."
                elseif not SharedInfra.SharedState.DelayComplete then
                    ChestConfig.Status = string.format("⏳ Startup: %ds", SharedInfra.SharedState.DelaySecondsRemaining)
                else
                    ChestConfig.Status = "⏸️ Idle"
                end
                chestScanStartTime = 0
                chestNotifiedNotFound = false
            end
            task.wait(ChestConfig.ScanDelay)
        end
    end)
    
    -- Chest Farm UI
    Tabs.Chest:AddParagraph({Title = "Chest Farm Info", Content = "Tweens to chests and opens them.\n✅ Targets workspace.ChestModels\n✅ Finds RootPart/PrimaryPart\n✅ Uses OpenChest remote\n✅ Filter by chest type (Silver/Gold/Diamond)\n✅ Server hop when empty"})
    
    Tabs.Chest:AddToggle("ChestFarmToggle", {
        Title = "Enable Chest Farm",
        Description = "Auto-tween to chests and open them.",
        Default = Config.ChestFarm
    }):OnChanged(function(v)
        ChestConfig.Enabled = v
        ChestConfig_Enabled = v
        Config.ChestFarm = v
        ConfigManager.Save(Config)
        chestScanStartTime = 0
        chestNotifiedNotFound = false
        if v then
            Fluent:Notify({Title = "Chest Farm Active", Content = "Searching...", Duration = 3})
        end
    end)
    
    Tabs.Chest:AddToggle("ChestAutoHopToggle", {
        Title = "Auto Hop (No Chests)",
        Default = Config.ChestAutoHop
    }):OnChanged(function(v)
        ChestConfig.AutoHop = v
        Config.ChestAutoHop = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.Chest:AddToggle("CollectMoneyToggle", {
        Title = "Collect Money/Beli",
        Default = Config.CollectMoney
    }):OnChanged(function(v)
        ChestConfig.CollectMoney = v
        Config.CollectMoney = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.Chest:AddToggle("CollectExpToggle", {
        Title = "Collect Exp Orbs",
        Default = Config.CollectExpOrbs
    }):OnChanged(function(v)
        ChestConfig.CollectExpOrbs = v
        Config.CollectExpOrbs = v
        ConfigManager.Save(Config)
    end)
    
    -- Chest Types Dropdown
    local ChestTypesList = {"Silver", "Gold", "Diamond"}
    local validChestTypes = {}
    for _, v in ipairs(ChestConfig.TargetChests) do
        if table.find(ChestTypesList, v) then table.insert(validChestTypes, v) end
    end
    if #validChestTypes == 0 then
        validChestTypes = {"Silver", "Gold", "Diamond"}
    end
    local defaultChestTypesDict = {}
    for _, v in ipairs(validChestTypes) do defaultChestTypesDict[v] = true end
    
    local ChestTypeDropdown = Tabs.Chest:AddDropdown("ChestTypeDropdown", {
        Title = "Target Chest Types",
        Description = "Select which chest types to collect (multi-select).",
        Values = ChestTypesList,
        Multi = true,
        Default = defaultChestTypesDict,
        Flag = "ChestTypesFlag"
    })
    
    ChestTypeDropdown:OnChanged(function(Value)
        local parsed = {}
        if type(Value) == "table" then
            for k, v in pairs(Value) do
                if type(k) == "string" and v == true then table.insert(parsed, k)
                elseif type(k) == "number" and type(v) == "string" then table.insert(parsed, v) end
            end
        end
        ChestConfig.TargetChests = parsed
        Config.TargetChests = parsed
        ConfigManager.Save(Config)
        chestNotifiedNotFound = false
        Fluent:Notify({
            Title = "Chest Types Updated",
            Content = "Hunting: " .. (#parsed > 0 and table.concat(parsed, ", ") or "NONE"),
            Duration = 2
        })
    end)
    
    Tabs.Chest:AddButton({Title = "Select All Types", Callback = function()
        ChestConfig.TargetChests = {"Silver", "Gold", "Diamond"}
        Config.TargetChests = {"Silver", "Gold", "Diamond"}
        ConfigManager.Save(Config)
        if Options.ChestTypesFlag then
            Options.ChestTypesFlag.Value = {Silver = true, Gold = true, Diamond = true}
        end
        Fluent:Notify({Title = "All Types", Content = "Hunting Silver, Gold, Diamond", Duration = 2})
    end})
    
    Tabs.Chest:AddButton({Title = "Diamond Only (Best Loot)", Callback = function()
        ChestConfig.TargetChests = {"Diamond"}
        Config.TargetChests = {"Diamond"}
        ConfigManager.Save(Config)
        if Options.ChestTypesFlag then
            Options.ChestTypesFlag.Value = {Diamond = true}
        end
        Fluent:Notify({Title = "Diamond Only", Content = "Hunting only Diamond chests", Duration = 2})
    end})
    
    Tabs.Chest:AddButton({Title = "Gold + Diamond", Callback = function()
        ChestConfig.TargetChests = {"Gold", "Diamond"}
        Config.TargetChests = {"Gold", "Diamond"}
        ConfigManager.Save(Config)
        if Options.ChestTypesFlag then
            Options.ChestTypesFlag.Value = {Gold = true, Diamond = true}
        end
        Fluent:Notify({Title = "Gold + Diamond", Content = "Hunting Gold and Diamond", Duration = 2})
    end})
    
    Tabs.Chest:AddSlider("ChestTweenSpeedSlider", {
        Title = "Tween Speed (studs/sec)",
        Description = "Max capped at 400 for stability.",
        Default = Config.ChestTweenSpeed or 200, Min = 50, Max = 400, Rounding = 0,
        Callback = function(v) ChestConfig.TweenSpeed = v; Config.ChestTweenSpeed = v; ConfigManager.Save(Config) end
    })
    
    Tabs.Chest:AddSlider("ChestScanDelaySlider", {
        Title = "Scan Delay (s)",
        Default = Config.ChestScanDelay or 0.5, Min = 0.1, Max = 3, Rounding = 1,
        Callback = function(v) ChestConfig.ScanDelay = v; Config.ChestScanDelay = v; ConfigManager.Save(Config) end
    })
    
    Tabs.Chest:AddSlider("ChestScanTimeSlider", {
        Title = "Time Before Hop (s)",
        Default = Config.ChestScanTimeBeforeHop or 10, Min = 3, Max = 60, Rounding = 0,
        Callback = function(v) ChestConfig.ScanTimeBeforeHop = v; Config.ChestScanTimeBeforeHop = v; ConfigManager.Save(Config) end
    })
    
    Tabs.Chest:AddSlider("ChestHopDelaySlider", {
        Title = "Chest Open Wait (s)",
        Default = Config.ChestHopDelay or 3, Min = 1, Max = 10, Rounding = 0,
        Callback = function(v) ChestConfig.HopDelay = v; Config.ChestHopDelay = v; ConfigManager.Save(Config) end
    })
    
    Tabs.Chest:AddButton({Title = "Clear Visited Chests", Callback = function()
        SharedInfra.VisitedChests = {}
        Fluent:Notify({Title = "Cleared", Content = "Will revisit all chests.", Duration = 3})
    end})
    
    local ChestStatusDisplay = Tabs.Chest:AddParagraph({Title = "Chest Farm Status", Content = "Idle"})
    task.spawn(function()
        while true do
            local visitedCount = 0
            for _ in pairs(SharedInfra.VisitedChests) do visitedCount = visitedCount + 1 end
            local targetsText = #ChestConfig.TargetChests > 0 and table.concat(ChestConfig.TargetChests, ", ") or "None"
            ChestStatusDisplay.Content = string.format(
                "Status: %s\nServers Hopped: %d\nChests Opened: %d\nMoney Collected: %d\nVisited: %d\nTween: %d studs/s (max 400)\nScan: %.1fs\nHop After: %ds\nTargets: %s\nAuto Hop: %s\nMoney: %s\nExp: %s",
                ChestConfig.Status,
                ChestStats.ServersHopped, ChestStats.ChestsOpened, ChestStats.MoneyCollected,
                visitedCount,
                ChestConfig.TweenSpeed, ChestConfig.ScanDelay, ChestConfig.ScanTimeBeforeHop,
                targetsText,
                ChestConfig.AutoHop and "ON" or "OFF",
                ChestConfig.CollectMoney and "ON" or "OFF",
                ChestConfig.CollectExpOrbs and "ON" or "OFF"
            )
            task.wait(0.3)
        end
    end)
    
    -- Settings UI
    Tabs.Settings:AddSlider("StartupDelaySlider", {
        Title = "Startup Delay (seconds)",
        Default = Config.StartupDelay or 3, Min = 1, Max = 10, Rounding = 0,
        Callback = function(v) Config.StartupDelay = v; FruitConfig.StartupDelay = v; ConfigManager.Save(Config) end
    })
    
    Tabs.Settings:AddDropdown("TeamDropdown", {
        Title = "Team Selection", Values = {"Pirates", "Marines"}, Default = Config.Team,
        Callback = function(v)
            FruitConfig.Team = v; Config.Team = v; ConfigManager.Save(Config)
            if SharedInfra.SharedState.CommF then
                pcall(function() SharedInfra.SharedState.CommF:InvokeServer("SetTeam", v) end)
            end
        end
    })
    
    Tabs.Settings:AddInput("WebhookInput", {
        Title = "Discord Webhook URL",
        Placeholder = "https://discord.com/api/webhooks/...",
        Default = Config.WebhookURL,
        Finished = true,
        Callback = function(v)
            FruitConfig.WebhookURL = v; Config.WebhookURL = v; ConfigManager.Save(Config)
            if v ~= "" then
                SendWebhook("✅ Webhook Connected", "GlockreisHub active!", 3066993)
            end
        end
    })
    
    Tabs.Settings:AddButton({Title = "Test Webhook", Callback = function()
        if FruitConfig.WebhookURL == "" then
            Fluent:Notify({Title = "Error", Content = "Webhook URL is empty", Duration = 3})
        else
            SendWebhook("🧪 Test", "Connection successful!", 3066993)
        end
    end})
    
    Tabs.Settings:AddButton({Title = "Manual Server Hop", Callback = function()
        if not SharedInfra.SharedState.DelayComplete then
            Fluent:Notify({Title = "Blocked", Content = "Wait for startup delay!", Duration = 3})
            return
        end
        task.spawn(function() ServerHop("Manual") end)
    end})
    
    Tabs.Settings:AddButton({Title = "Clear Server Blacklist", Callback = function()
        SharedInfra.BlacklistedServers = {}
        Fluent:Notify({Title = "Blacklist", Content = "Cleared", Duration = 2})
    end})
    
    Tabs.Settings:AddButton({Title = "Skip Startup Delay", Callback = function()
        if SharedInfra.SharedState.DelayComplete then
            Fluent:Notify({Title = "Info", Content = "Already complete", Duration = 2})
        else
            SharedInfra.SharedState.DelayComplete = true
            SharedInfra.SharedState.DelaySecondsRemaining = 0
            Fluent:Notify({Title = "Skipped", Content = "Armed immediately", Duration = 3})
        end
    end})
    
    -- Finalize
    Window:SelectTab(1)
    Fluent:Notify({
        Title = "GlockreisHub",
        Content = "Loaded: Blox Fruits (Fruit Sniper + Chest Farm)",
        Duration = 5
    })
end
