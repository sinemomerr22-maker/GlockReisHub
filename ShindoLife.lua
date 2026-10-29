-- // ==========================================
-- // GLOCKREISHUB - SHINDO LIFE MODULE (ENHANCED)
-- // AutoFarm M1 Attack + Auto Stats + Godmode
-- // ==========================================

return function(Common)
    local Fluent = Common.Fluent
    local LocalPlayer = Common.LocalPlayer
    local ReplicatedStorage = Common.ReplicatedStorage
    local TeleportService = Common.TeleportService
    local TweenService = Common.TweenService
    local RunService = Common.RunService
    local UserInputService = Common.UserInputService
    
    local placeId = game.PlaceId
    local isShindoMenu = (placeId == 4616652839)
    local isShindoInGame = not isShindoMenu
    
    -- Config
    local DefaultConfig
    if isShindoMenu then
        DefaultConfig = {
            Enabled = false, TargetBloodlines = {}, ActiveSlots = {"kg1", "kg2"},
            MinSpinsToRejoin = 30, SpinDelay = 0.1
        }
    else
        DefaultConfig = {
            WalkSpeed = 16, JumpHeight = 7,
            AutoFarmEnabled = false, AutoFarmSpeed = 500,
            AutoFarmUseM1 = true,
            AutoFarmM1Cooldown = 0.3,
            ScrollSniperEnabled = false,
            WarFarmEnabled = false, WarAutoReset = true,
            AutoChakraEnabled = false, AutoChakraThreshold = 100000,
            AutoRankEnabled = false,
            -- Stats Config
            AutoStatsEnabled = false,
            AutoStatsNinEnabled = true,
            AutoStatsTaiEnabled = false,
            AutoStatsChiEnabled = false,
            AutoStatsHpEnabled = false,
            AutoStatsInterval = 2,
            AutoStatsMinPoints = 5,
            -- Godmode Config
            GodModeEnabled = false,
            FakeHealthValue = 999999
        }
    end
    
    local ConfigManager = Common.setupConfigManager(isShindoMenu and "ShindoLife_Menu" or "ShindoLife_InGame")
    local Config = ConfigManager.Load(DefaultConfig)
    
    -- UI
    local gameDisplayName = isShindoMenu and "Shindo Life (Menu)" or "Shindo Life (In-Game)"
    local ui = Common.loadFluentUI(gameDisplayName, placeId)
    local Tabs = {}
    
    -- Helper function for tweening
    local function toTarget(pos, targetPos, targetCFrame, speed)
        speed = speed or Config.AutoFarmSpeed or 500
        local info = TweenInfo.new((targetPos - pos).Magnitude / speed, Enum.EasingStyle.Linear)
        local ok, err = pcall(function()
            local char = LocalPlayer.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local tween = TweenService:Create(hrp, info, {CFrame = targetCFrame})
                    tween:Play()
                end
            end
        end)
        return ok, err
    end
    
    -- M1 Attack Helper
    local lastM1Time = 0
    local function attackM1(targetHRP)
        local char = LocalPlayer.Character
        if not char then return false end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        local combat = char:FindFirstChild("combat")
        if not root or not combat then return false end
        
        -- Check cooldown
        local now = tick()
        if now - lastM1Time < (Config.AutoFarmM1Cooldown or 0.3) then
            return false
        end
        
        -- Face target
        if targetHRP then
            local dir = (targetHRP.Position - root.Position) * Vector3.new(1, 12, 1)
            if dir.Magnitude > 0.1 then
                root.CFrame = CFrame.lookAt(root.Position, root.Position + dir.Unit)
            end
        end
        
        -- Fire M1
        local ok = pcall(function()
            combat.update:FireServer("mouse1", true)
        end)
        
        if ok then
            lastM1Time = now
            task.delay(0.05, function()
                pcall(function()
                    combat.update:FireServer("mouse1", false)
                end)
            end)
        end
        
        return ok
    end
    
    -- Stats Helper
    local function getStatPoints()
        local statz = LocalPlayer:FindFirstChild("statz")
        if not statz then return 0 end
        local mastery = statz:FindFirstChild("mastery")
        if not mastery then return 0 end
        local points = mastery:FindFirstChild("points")
        if not points then return 0 end
        return points.Value or 0
    end
    
    local function addStat(statName, amount)
        local ok, err = pcall(function()
            LocalPlayer.startevent:FireServer("addstat", statName, amount)
        end)
        return ok, err
    end
    
    local function getStatLevel(statName)
        local statz = LocalPlayer:FindFirstChild("statz")
        if not statz then return 0 end
        local lvl = statz:FindFirstChild("lvl")
        if not lvl then return 0 end
        
        if statName == "ninjutsu" then
            local nin = lvl:FindFirstChild("nin")
            return nin and nin.Value or 0
        elseif statName == "taijutsu" then
            local tai = lvl:FindFirstChild("tai")
            return tai and tai.Value or 0
        elseif statName == "chakra" then
            local cha = lvl:FindFirstChild("cha")
            return cha and cha.Value or 0
        elseif statName == "health" then
            local hp = lvl:FindFirstChild("health")
            return hp and hp.Value or 0
        end
        return 0
    end
    
    -- ==========================================
    -- SHINDO LIFE MENU (GENKAI SNIPER ONLY)
    -- ==========================================
    if isShindoMenu then
        Tabs.Main = ui.Window:AddTab({ Title = "Genkai Sniper", Icon = "target" })
        Tabs.Status = ui.Window:AddTab({ Title = "Status", Icon = "activity" })
        
        Tabs.Main:AddParagraph({
            Title = "System Status",
            Content = "Config: PERSISTENT (Auto-Save)\nAnti-AFK: 12h+ Proof\nDynamic Updates: POLLING-BASED\nTarget Match: CASE-INSENSITIVE\nDropdown State: HARDENED"
        })
        
        local Settings = {
            Enabled = Config.Enabled, TargetBloodlines = {}, ActiveSlots = {},
            MinSpinsToRejoin = Config.MinSpinsToRejoin, SpinDelay = Config.SpinDelay,
            Status = "Idle", CurrentSpins = -1, TotalSpinsDone = 0, SessionStartTime = tick()
        }
        
        local function getGenkaiNames()
            local kgs = {}
            local alljutsu = ReplicatedStorage:FindFirstChild("alljutsu")
            if alljutsu then
                for _, v in pairs(alljutsu:GetChildren()) do
                    if v:FindFirstChild("KG") then table.insert(kgs, v.Name) end
                end
            end
            if #kgs == 0 then kgs = {"RELL", "AKUMA", "sharingan", "itachisharingan", "sasukesharingan", "obitosharingan", "madarasharingan", "rinnegan", "byakugan", "tenseigan", "gelel", "shisuisharingan", "kaguya", "ashura", "indra", "tengansharingan", "kaleidoscapesharingan"} end
            return kgs
        end
        
        local function checkTargetFound(element)
            if type(element) ~= "string" then return false end
            local cleanElement = string.lower(string.gsub(element, "%s+", ""))
            if #Settings.TargetBloodlines == 0 then return false end
            for _, target in pairs(Settings.TargetBloodlines) do
                if type(target) == "string" then
                    local cleanTarget = string.lower(string.gsub(target, "%s+", ""))
                    if cleanElement == cleanTarget then return true end
                end
            end
            return false
        end
        
        local function instantTargetCheck()
            if Settings.Enabled and LocalPlayer:FindFirstChild("statz") and LocalPlayer.statz:FindFirstChild("main") then
                local statz = LocalPlayer.statz
                for _, slot in pairs(Settings.ActiveSlots) do
                    local currentElement = statz.main[slot] and statz.main[slot].Value
                    if currentElement and checkTargetFound(currentElement) then
                        Settings.Status = "[!] TARGET FOUND! LOCKING..."
                        Fluent:Notify({Title = "[!] TARGET FOUND", Content = "Found " .. currentElement .. " in " .. slot:upper() .. "!", Duration = 10})
                        pcall(function() LocalPlayer.startevent:FireServer("band", "Eye") end)
                        task.wait(1)
                        LocalPlayer:Kick("[!] Hedef Bulundu: " .. currentElement)
                        return true
                    end
                end
            end
            return false
        end
        
        task.spawn(function()
            local statz = LocalPlayer:WaitForChild("statz")
            local main = statz:WaitForChild("main")
            for _, slotName in pairs({"kg1", "kg2", "kg3", "kg4"}) do
                local slot = main:FindFirstChild(slotName)
                if slot then
                    slot.ChildAdded:Connect(function(child)
                        if child.Name == "dontspin" then
                            task.wait(0.05)
                            pcall(function() child:Destroy() end)
                        end
                    end)
                end
            end
        end)
        
        task.spawn(function()
            repeat task.wait() until game:IsLoaded()
            repeat task.wait() until LocalPlayer:FindFirstChild("startevent")
            local statz = LocalPlayer:WaitForChild("statz")
            local spinsObj = statz:WaitForChild("spins", 30)
            if not spinsObj then Fluent:Notify({Title = "Error", Content = "spins object not found after 30s", Duration = 5}); return end
            local startevent = LocalPlayer.startevent
            pcall(function() startevent:FireServer("band", "\128") end)
            pcall(function()
                local alljutsu = ReplicatedStorage:FindFirstChild("alljutsu")
                if alljutsu then
                    for _, v in pairs(alljutsu:GetChildren()) do
                        if v:FindFirstChild("KG") and not LocalPlayer.statz.genkailevel:FindFirstChild(v.Name) then
                            local a = Instance.new("StringValue")
                            a.Name = v.Name
                            a.Parent = LocalPlayer.statz.genkailevel
                        end
                    end
                end
            end)
            task.wait(5)
            Settings.SessionStartTime = tick()
            
            while true do
                local readSpins = nil
                pcall(function() if spinsObj and spinsObj.Parent then readSpins = tonumber(spinsObj.Value) end end)
                if readSpins ~= nil then Settings.CurrentSpins = readSpins else Settings.CurrentSpins = -1 end
                if Settings.Enabled then
                    Settings.Status = "Spinning..."
                    for _, slot in pairs(Settings.ActiveSlots) do
                        pcall(function() startevent:FireServer("spin", slot) end)
                        Settings.TotalSpinsDone = Settings.TotalSpinsDone + 1
                        local minDelay = Settings.SpinDelay * 0.90
                        local maxDelay = Settings.SpinDelay * 1.10
                        task.wait(math.random(minDelay * 1000, maxDelay * 1000) / 1000)
                    end
                    if instantTargetCheck() then return end
                    local sessionAge = tick() - Settings.SessionStartTime
                    if Settings.CurrentSpins >= 0 and Settings.CurrentSpins <= Settings.MinSpinsToRejoin and sessionAge >= 15 then
                        Settings.Status = "[!] Spins depleted. Rejoining..."
                        Fluent:Notify({Title = "Spins Depleted", Content = "Spins: " .. Settings.CurrentSpins .. " | Rejoining...", Duration = 3})
                        task.wait(2)
                        TeleportService:Teleport(game.PlaceId, LocalPlayer)
                    elseif Settings.CurrentSpins == -1 then Settings.Status = "[...] Waiting for spin data..." end
                else Settings.Status = "Idle" end
                task.wait(0.1)
            end
        end)
        
        local function parseMultiDropdown(Value)
            local t = {}
            local seen = {}
            if not Value then return t end
            if type(Value) == "string" then if Value ~= "" then table.insert(t, Value) end; return t end
            if type(Value) ~= "table" then return t end
            local isDict = false
            for k, _ in pairs(Value) do if type(k) == "string" then isDict = true; break end end
            if isDict then
                for k, v in pairs(Value) do if v == true and type(k) == "string" and k ~= "" and not seen[k] then table.insert(t, k); seen[k] = true end end
            else
                for _, v in pairs(Value) do if type(v) == "string" and v ~= "" and not seen[v] then table.insert(t, v); seen[v] = true end end
            end
            return t
        end
        
        local function arraysEqual(a, b)
            if #a ~= #b then return false end
            for i, v in ipairs(a) do if v ~= b[i] then return false end end
            return true
        end
        
        local function arrayToDict(arr)
            local dict = {}
            for _, v in ipairs(arr) do dict[v] = true end
            return dict
        end
        
        local availableGenkais = getGenkaiNames()
        local allSlots = {"kg1", "kg2", "kg3", "kg4"}
        
        local validBloodlines = {}
        for _, v in ipairs(Config.TargetBloodlines) do if table.find(availableGenkais, v) then table.insert(validBloodlines, v) end end
        local validSlots = {}
        for _, v in ipairs(Config.ActiveSlots) do if table.find(allSlots, v) then table.insert(validSlots, v) end end
        
        local defaultBloodlinesDict = arrayToDict(validBloodlines)
        local defaultSlotsDict = arrayToDict(validSlots)
        
        Settings.TargetBloodlines = validBloodlines
        Settings.ActiveSlots = validSlots
        
        local BloodlineDropdown = Tabs.Main:AddDropdown("BloodlineDropdown", {
            Title = "Target Bloodlines", Values = availableGenkais, Multi = true, Default = defaultBloodlinesDict, Flag = "BloodlinesFlag"
        })
        
        local SlotDropdown = Tabs.Main:AddDropdown("SlotDropdown", {
            Title = "Active Slots", Values = allSlots, Multi = true, Default = defaultSlotsDict, Flag = "SlotsFlag"
        })
        
        BloodlineDropdown:OnChanged(function(Value)
            local parsed = parseMultiDropdown(Value)
            if #parsed == 0 and #validBloodlines > 0 then
                task.defer(function() if Fluent.Options.BloodlinesFlag then Fluent.Options.BloodlinesFlag.Value = defaultBloodlinesDict end end)
                return
            end
        end)
        
        SlotDropdown:OnChanged(function(Value)
            local parsed = parseMultiDropdown(Value)
            if #parsed == 0 and #validSlots > 0 then
                task.defer(function() if Fluent.Options.SlotsFlag then Fluent.Options.SlotsFlag.Value = defaultSlotsDict end end)
                return
            end
        end)
        
        task.spawn(function()
            task.wait(1.5)
            if Fluent.Options.BloodlinesFlag then Fluent.Options.BloodlinesFlag.Value = defaultBloodlinesDict; Settings.TargetBloodlines = validBloodlines end
            if Fluent.Options.SlotsFlag then Fluent.Options.SlotsFlag.Value = defaultSlotsDict; Settings.ActiveSlots = validSlots end
            local warmupEnd = tick() + 3
            Fluent:Notify({
                Title = "Config Loaded", 
                Content = "Targets: " .. (#validBloodlines > 0 and table.concat(validBloodlines, ", ") or "None") .. " | Slots: " .. (#validSlots > 0 and table.concat(validSlots, ", ") or "None"),
                Duration = 5
            })
            while true do
                local inWarmup = tick() < warmupEnd
                local rawBloodlines = nil
                if Fluent.Options.BloodlinesFlag and Fluent.Options.BloodlinesFlag.Value then rawBloodlines = Fluent.Options.BloodlinesFlag.Value
                elseif BloodlineDropdown and BloodlineDropdown.Value then rawBloodlines = BloodlineDropdown.Value end
                if rawBloodlines then
                    local newTargets = parseMultiDropdown(rawBloodlines)
                    if inWarmup and #newTargets == 0 and #validBloodlines > 0 then
                        newTargets = validBloodlines
                        if Fluent.Options.BloodlinesFlag then Fluent.Options.BloodlinesFlag.Value = defaultBloodlinesDict end
                    end
                    if not arraysEqual(newTargets, Settings.TargetBloodlines) then
                        Settings.TargetBloodlines = newTargets
                        Config.TargetBloodlines = newTargets
                        ConfigManager.Save(Config)
                        Fluent:Notify({
                            Title = "Targets Updated", 
                            Content = "Hunting " .. #newTargets .. " bloodline(s): " .. (#newTargets > 0 and table.concat(newTargets, ", ") or "NONE"), 
                            Duration = 3
                        })
                        if #newTargets > 0 and Settings.Enabled then instantTargetCheck() end
                    end
                end
                local rawSlots = nil
                if Fluent.Options.SlotsFlag and Fluent.Options.SlotsFlag.Value then rawSlots = Fluent.Options.SlotsFlag.Value
                elseif SlotDropdown and SlotDropdown.Value then rawSlots = SlotDropdown.Value end
                if rawSlots then
                    local newSlots = parseMultiDropdown(rawSlots)
                    if inWarmup and #newSlots == 0 and #validSlots > 0 then
                        newSlots = validSlots
                        if Fluent.Options.SlotsFlag then Fluent.Options.SlotsFlag.Value = defaultSlotsDict end
                    end
                    if not arraysEqual(newSlots, Settings.ActiveSlots) then
                        Settings.ActiveSlots = newSlots
                        Config.ActiveSlots = newSlots
                        ConfigManager.Save(Config)
                        Fluent:Notify({
                            Title = "Slots Updated", 
                            Content = "Active: " .. (#newSlots > 0 and table.concat(newSlots, ", ") or "NONE"), 
                            Duration = 2
                        })
                    end
                end
                task.wait(0.3)
            end
        end)
        
        Tabs.Main:AddToggle("MainToggle", {Title = "Enable Auto-Sniper", Default = Config.Enabled}):OnChanged(function(v)
            Settings.Enabled = v; Config.Enabled = v; ConfigManager.Save(Config)
            if v then Fluent:Notify({Title = "Auto-Sniper Active", Content = "Hunting...", Duration = 3}) end
        end)
        
        Tabs.Main:AddSlider("SpinsSlider", {
            Title = "Rejoin Threshold", Default = Config.MinSpinsToRejoin, Min = 5, Max = 480, Rounding = 0,
            Callback = function(Value) 
                Settings.MinSpinsToRejoin = Value; Config.MinSpinsToRejoin = Value; ConfigManager.Save(Config)
                if Settings.Enabled and Settings.CurrentSpins >= 0 and Settings.CurrentSpins <= Value then
                    Settings.Status = "[!] Threshold dropped! Rejoining..."
                    Fluent:Notify({Title = "Threshold Changed", Content = "Spins: " .. Settings.CurrentSpins .. " | Rejoining...", Duration = 3})
                    task.wait(1)
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end
            end
        })
        
        Tabs.Main:AddSlider("DelaySlider", {
            Title = "Spin Delay (seconds)", Default = Config.SpinDelay, Min = 0.05, Max = 1, Rounding = 2,
            Callback = function(Value) Settings.SpinDelay = Value; Config.SpinDelay = Value; ConfigManager.Save(Config) end
        })
        
        local StatusDisplay = Tabs.Status:AddParagraph({Title = "Current Status", Content = "Idle"})
        task.spawn(function()
            while true do
                local targetText = #Settings.TargetBloodlines > 0 and table.concat(Settings.TargetBloodlines, ", ") or "None"
                local slotValues = {}
                if LocalPlayer:FindFirstChild("statz") and LocalPlayer.statz:FindFirstChild("main") then
                    for _, slot in pairs({"kg1", "kg2", "kg3", "kg4"}) do
                        local val = LocalPlayer.statz.main:FindFirstChild(slot)
                        table.insert(slotValues, slot:upper() .. ": " .. (val and val.Value or "None"))
                    end
                end
                local spinsDisplay = Settings.CurrentSpins >= 0 and tostring(Settings.CurrentSpins) or "Loading..."
                StatusDisplay.Content = string.format("Status: %s\n\n%s\n\nSpins Left: %s\nTotal Spins: %d\nRejoin at: %d\nDelay: %.2fs\n\nTargets: %s", Settings.Status, table.concat(slotValues, "\n"), spinsDisplay, Settings.TotalSpinsDone, Settings.MinSpinsToRejoin, Settings.SpinDelay, targetText)
                task.wait(0.3)
            end
        end)
    
    -- ==========================================
    -- SHINDO LIFE IN-GAME (ENHANCED)
    -- ==========================================
    else
        Tabs.Main = ui.Window:AddTab({ Title = "AutoFarm", Icon = "target" })
        Tabs.Godmode = ui.Window:AddTab({ Title = "Godmode", Icon = "shield" })
        Tabs.Scroll = ui.Window:AddTab({ Title = "Scroll Sniper", Icon = "book" })
        Tabs.War = ui.Window:AddTab({ Title = "War Farm", Icon = "shield" })
        Tabs.Quests = ui.Window:AddTab({ Title = "Quest Maker", Icon = "list" })
        Tabs.Stats = ui.Window:AddTab({ Title = "Auto Stats", Icon = "trending-up" })
        Tabs.Chakra = ui.Window:AddTab({ Title = "Auto Chakra", Icon = "zap" })
        Tabs.Utilities = ui.Window:AddTab({ Title = "Utilities", Icon = "tool" })
        
        -- State variables
        local FarmState = {
            AutoFarmEnabled = Config.AutoFarmEnabled,
            AutoFarmUseM1 = Config.AutoFarmUseM1,
            ScrollSniperEnabled = Config.ScrollSniperEnabled,
            WarFarmEnabled = Config.WarFarmEnabled,
            AutoChakraEnabled = Config.AutoChakraEnabled,
            AutoRankEnabled = Config.AutoRankEnabled,
            AutoStatsEnabled = Config.AutoStatsEnabled,
            AutoStatsNinEnabled = Config.AutoStatsNinEnabled,
            AutoStatsTaiEnabled = Config.AutoStatsTaiEnabled,
            AutoStatsChiEnabled = Config.AutoStatsChiEnabled,
            AutoStatsHpEnabled = Config.AutoStatsHpEnabled,
            GodModeEnabled = Config.GodModeEnabled,
            FakeHealthValue = Config.FakeHealthValue or 999999,
            WarCount = 0,
            ChakraThreshold = Config.AutoChakraThreshold,
            StatsAdded = {ninjutsu = 0, taijutsu = 0, chakra = 0, health = 0}
        }
        
        -- ==========================================
        -- GODMODE SYSTEM
        -- ==========================================
        Tabs.Godmode:AddParagraph({
            Title = "[G] Godmode System",
            Content = "Makes your character invincible.\n\n- Health never drops below max\n- fakehealth value set to " .. FarmState.FakeHealthValue .. "\n- Persists through respawn\n- Anti-kick protection included"
        })
        
        Tabs.Godmode:AddToggle("GodModeToggle", {
            Title = "Enable Godmode",
            Description = "Never die - health always at maximum",
            Default = Config.GodModeEnabled
        }):OnChanged(function(v)
            FarmState.GodModeEnabled = v
            Config.GodModeEnabled = v
            ConfigManager.Save(Config)
            if v then
                ui.Fluent:Notify({
                    Title = "[G] Godmode Enabled",
                    Content = "You are now invincible!",
                    Duration = 3
                })
            else
                ui.Fluent:Notify({
                    Title = "[G] Godmode Disabled",
                    Content = "Normal health restored",
                    Duration = 3
                })
            end
        end)
        
        Tabs.Godmode:AddSlider("FakeHealthSlider", {
            Title = "Fake Health Value",
            Description = "Value to set fakehealth to (default: 999999)",
            Default = Config.FakeHealthValue,
            Min = 100000, Max = 9999999, Rounding = 0,
            Callback = function(v)
                FarmState.FakeHealthValue = v
                Config.FakeHealthValue = v
                ConfigManager.Save(Config)
            end
        })
        
        -- Godmode logic - runs every frame
        task.spawn(function()
            while true do
                if FarmState.GodModeEnabled and LocalPlayer.Character then
                    pcall(function()
                        local char = LocalPlayer.Character
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        
                        if hum and hum.Health > 0 then
                            -- Keep health at max
                            hum.Health = hum.MaxHealth
                            
                            -- Update fakehealth value
                            local fakehealth = char:FindFirstChild("fakehealth")
                            if fakehealth then
                                fakehealth.Value = FarmState.FakeHealthValue
                            end
                        end
                    end)
                end
                task.wait(0.1) -- Check every 100ms for responsiveness
            end
        end)
        
        -- Godmode status display
        local GodmodeStatusDisplay = Tabs.Godmode:AddParagraph({
            Title = "Godmode Status",
            Content = "Initializing..."
        })
        
        task.spawn(function()
            while true do
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local fakehealth = char and char:FindFirstChild("fakehealth")
                
                local healthStr = "N/A"
                local maxHealthStr = "N/A"
                local fakeHealthStr = "N/A"
                
                if hum then
                    healthStr = tostring(math.floor(hum.Health))
                    maxHealthStr = tostring(math.floor(hum.MaxHealth))
                end
                
                if fakehealth then
                    fakeHealthStr = tostring(fakehealth.Value)
                end
                
                GodmodeStatusDisplay.Content = string.format(
                    "Status: %s\n\nHealth: %s / %s\nfakehealth Value: %s\nTarget fakehealth: %d\n\nGodmode: %s\n\nNote: Godmode prevents death by keeping\nhealth at max and fakehealth at %d",
                    FarmState.GodModeEnabled and "[OK] ACTIVE" or "[X] INACTIVE",
                    healthStr,
                    maxHealthStr,
                    fakeHealthStr,
                    FarmState.FakeHealthValue,
                    FarmState.GodModeEnabled and "ENABLED" or "DISABLED",
                    FarmState.FakeHealthValue
                )
                task.wait(0.5)
            end
        end)
        
        -- ==========================================
        -- AUTOFARM (MISSION-BASED) - WITH M1 ATTACK
        -- ==========================================
        Tabs.Main:AddParagraph({
            Title = "[*] AutoFarm System (FIXED + M1)",
            Content = "Automatically accepts and completes missions.\n\n- Uses currentmission.Value (primary check)\n- Falls back to MissionStory.Visible (secondary)\n- Level-aware mission selection (699 / 700+)\n- Only kills npctype NPCs (filters out players/bosses)\n- NEW: M1 melee attacks instead of Health=0\n- Waits 1s after accepting mission for server sync\n- Polls every 0.5s for fast response"
        })
        
        Tabs.Main:AddToggle("AutoFarmToggle", {
            Title = "Enable AutoFarm",
            Description = "Auto-accept and complete missions",
            Default = Config.AutoFarmEnabled
        }):OnChanged(function(v)
            FarmState.AutoFarmEnabled = v
            Config.AutoFarmEnabled = v
            ConfigManager.Save(Config)
        end)
        
        Tabs.Main:AddToggle("AutoFarmUseM1Toggle", {
            Title = "Use M1 Attacks",
            Description = "Attack NPCs with melee instead of setting Health=0. More reliable, less detectable.",
            Default = Config.AutoFarmUseM1
        }):OnChanged(function(v)
            FarmState.AutoFarmUseM1 = v
            Config.AutoFarmUseM1 = v
            ConfigManager.Save(Config)
        end)
        
        Tabs.Main:AddSlider("AutoFarmSpeedSlider", {
            Title = "Tween Speed (studs/sec)",
            Default = Config.AutoFarmSpeed,
            Min = 100, Max = 2500, Rounding = 0,
            Callback = function(v)
                Config.AutoFarmSpeed = v
                ConfigManager.Save(Config)
            end
        })
        
        Tabs.Main:AddSlider("AutoFarmM1CooldownSlider", {
            Title = "M1 Cooldown (seconds)",
            Description = "Time between M1 attacks. Lower = faster kills but more detectable.",
            Default = Config.AutoFarmM1Cooldown,
            Min = 0.1, Max = 1.0, Rounding = 2,
            Callback = function(v)
                Config.AutoFarmM1Cooldown = v
                ConfigManager.Save(Config)
            end
        })
        
        -- AutoFarm logic with M1
        task.spawn(function()
            while true do
                if FarmState.AutoFarmEnabled and LocalPlayer.Character then
                    pcall(function()
                        local char = LocalPlayer.Character
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        local root = char:FindFirstChild("HumanoidRootPart")
                        
                        if hum and root and hum.Health > 0 then
                            -- Anti-kick
                            hum:ChangeState(11)
                            
                            -- PRIMARY CHECK: currentmission value (most reliable)
                            local currentmission = LocalPlayer:FindFirstChild("currentmission")
                            local hasMission = currentmission and currentmission.Value ~= nil and currentmission.Value ~= ""
                            
                            -- SECONDARY CHECK: MissionStory GUI visible
                            local missionGui = LocalPlayer.PlayerGui:FindFirstChild("Main") 
                                and LocalPlayer.PlayerGui.Main:FindFirstChild("ingame")
                                and LocalPlayer.PlayerGui.Main.ingame:FindFirstChild("MissionStory")
                            
                            if missionGui and missionGui.Visible then
                                hasMission = true
                            end
                            
                            if not hasMission then
                                -- No mission - find mission giver
                                local missionGivers = workspace:FindFirstChild("missiongivers")
                                if missionGivers then
                                    local lvl = LocalPlayer:FindFirstChild("statz") 
                                        and LocalPlayer.statz:FindFirstChild("lvl")
                                        and LocalPlayer.statz.lvl:FindFirstChild("lvl")
                                        and LocalPlayer.statz.lvl.lvl.Value or 0
                                    
                                    local green = "http://www.roblox.com/asset/?id=5459241648"
                                    local red = "http://www.roblox.com/asset/?id=5459241799"
                                    
                                    for _, giver in pairs(missionGivers:GetChildren()) do
                                        if giver:FindFirstChild("Head") 
                                            and giver.Head:FindFirstChild("givemission")
                                            and giver.Head.givemission.Enabled then
                                            
                                            local talk = giver:FindFirstChild("Talk")
                                            local shouldAccept = false
                                            
                                            if lvl <= 699 then
                                                -- Low level: only green missions
                                                if talk and talk:FindFirstChild("typ") 
                                                    and talk.typ.Value == "defeat"
                                                    and giver.Head.givemission:FindFirstChild("color")
                                                    and giver.Head.givemission.color.Visible
                                                    and giver.Head.givemission.color.Image == green then
                                                    shouldAccept = true
                                                end
                                            else
                                                -- High level: green or red missions
                                                if talk and talk:FindFirstChild("typ") 
                                                    and talk.typ.Value == "defeat"
                                                    and giver.Head.givemission:FindFirstChild("color")
                                                    and giver.Head.givemission.color.Visible
                                                    and (giver.Head.givemission.color.Image == green or giver.Head.givemission.color.Image == red) then
                                                    shouldAccept = true
                                                end
                                            end
                                            
                                            if shouldAccept then
                                                local clientTalk = giver:FindFirstChild("CLIENTTALK")
                                                local giverRoot = giver:FindFirstChild("HumanoidRootPart")
                                                
                                                if clientTalk and giverRoot then
                                                    toTarget(root.Position, giverRoot.Position, 
                                                        CFrame.new(giverRoot.Position + Vector3.new(0, -8, 0)))
                                                    task.wait(0.5)
                                                    
                                                    local dist = (root.Position - giverRoot.Position).Magnitude
                                                    if dist < 10 then
                                                        clientTalk:FireServer()
                                                        task.wait(0.3)
                                                        clientTalk:FireServer("accept")
                                                        task.wait(1) -- Wait for mission to register on server
                                                    end
                                                end
                                                break -- Only accept one mission at a time
                                            end
                                        end
                                    end
                                end
                            else
                                -- Have mission - kill NPCs with M1 or Health=0
                                local npcs = workspace:FindFirstChild("npc")
                                if npcs then
                                    local killed = false
                                    
                                    for _, npc in pairs(npcs:GetChildren()) do
                                        -- Filter: only kill mission NPCs (have npctype attribute and "npc" in name)
                                        if npc:IsA("Model") 
                                            and npc:FindFirstChild("HumanoidRootPart")
                                            and npc:FindFirstChild("Humanoid")
                                            and npc.Humanoid.Health > 0
                                            and npc:FindFirstChild("npctype") -- Must be a mission NPC
                                            and string.find(npc.Name, "npc") -- Name contains "npc"
                                            and npc.Head.CFrame.Y > -1000 then -- Not fallen off map
                                            
                                            local npcRoot = npc.HumanoidRootPart
                                            
                                            -- Move to NPC
                                            toTarget(root.Position, npcRoot.Position,
                                                CFrame.new(npcRoot.Position + Vector3.new(0, -8, 0)))
                                            task.wait(0.3)
                                            
                                            local dist = (root.Position - npcRoot.Position).Magnitude
                                            
                                            if dist < 15 then
                                                if FarmState.AutoFarmUseM1 then
                                                    -- Use M1 attack
                                                    local attackCount = 0
                                                    local maxAttacks = 10
                                                    
                                                    while npc.Humanoid.Health > 0 and attackCount < maxAttacks do
                                                        attackM1(npcRoot)
                                                        attackCount = attackCount + 1
                                                        task.wait(Config.AutoFarmM1Cooldown or 0.3)
                                                        
                                                        -- Check if NPC is still valid
                                                        if not npc.Parent or npc.Humanoid.Health <= 0 then
                                                            break
                                                        end
                                                    end
                                                    
                                                    if npc.Humanoid.Health <= 0 then
                                                        killed = true
                                                    end
                                                else
                                                    -- Old method: set Health = 0
                                                    npc.Humanoid.Health = 0
                                                    killed = true
                                                end
                                            end
                                            break -- Kill one NPC at a time, then re-check mission status
                                        end
                                    end
                                    
                                    if not killed then
                                        -- No NPCs found, wait a bit before trying again
                                        task.wait(0.5)
                                    end
                                end
                            end
                        end
                    end)
                end
                task.wait(0.5) -- Faster polling (was 1s, now 0.5s)
            end
        end)
        
        -- ==========================================
        -- SCROLL SNIPER
        -- ==========================================
        Tabs.Scroll:AddParagraph({
            Title = "[S] Scroll Sniper",
            Content = "Automatically detects and collects spawned scrolls.\n\n- Scans workspace.GLOBALTIME and workspace\n- Instant teleport to scroll location\n- Auto-collect with click detector"
        })
        
        Tabs.Scroll:AddToggle("ScrollSniperToggle", {
            Title = "Enable Scroll Sniper",
            Default = Config.ScrollSniperEnabled
        }):OnChanged(function(v)
            FarmState.ScrollSniperEnabled = v
            Config.ScrollSniperEnabled = v
            ConfigManager.Save(Config)
        end)
        
        -- Scroll Sniper logic
        task.spawn(function()
            while true do
                if FarmState.ScrollSniperEnabled and LocalPlayer.Character then
                    pcall(function()
                        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if not root then return end
                        
                        -- Check workspace.GLOBALTIME
                        local globalTime = workspace:FindFirstChild("GLOBALTIME")
                        if globalTime then
                            for _, obj in pairs(globalTime:GetChildren()) do
                                if obj:IsA("Model") and obj:FindFirstChild("sh") then
                                    local sh = obj.sh
                                    if sh.Position.Y > -1000 and sh.Position.Y < 2000 then
                                        local invoke = sh:FindFirstChild("invoke")
                                        local clickDetector = sh:FindFirstChild("ClickDetector")
                                        
                                        if invoke and clickDetector then
                                            ui.Fluent:Notify({
                                                Title = "[S] Scroll Detected!",
                                                Content = "Teleporting to scroll...",
                                                Duration = 2
                                            })
                                            
                                            toTarget(root.Position, sh.Position, CFrame.new(sh.Position))
                                            task.wait(0.5)
                                            
                                            invoke:FireServer(LocalPlayer)
                                            fireclickdetector(clickDetector)
                                        end
                                    end
                                end
                            end
                        end
                        
                        -- Check workspace directly
                        for _, obj in pairs(workspace:GetChildren()) do
                            if obj:IsA("Model") and obj:FindFirstChild("sh") then
                                local sh = obj.sh
                                if sh.Position.Y > -1000 and sh.Position.Y < 2000 then
                                    local invoke = sh:FindFirstChild("invoke")
                                    local clickDetector = sh:FindFirstChild("ClickDetector")
                                    
                                    if invoke and clickDetector then
                                        ui.Fluent:Notify({
                                            Title = "[S] Scroll Detected!",
                                            Content = "Teleporting to scroll...",
                                            Duration = 2
                                        })
                                        
                                        toTarget(root.Position, sh.Position, CFrame.new(sh.Position))
                                        task.wait(0.5)
                                        
                                        invoke:FireServer(LocalPlayer)
                                        fireclickdetector(clickDetector)
                                    end
                                end
                            end
                        end
                    end)
                end
                task.wait(2)
            end
        end)
        
        -- ==========================================
        -- WAR FARM
        -- ==========================================
        Tabs.War:AddParagraph({
            Title = "[W] War Farm",
            Content = "Automatically participates in war mode.\n\n- Detects warmode activation\n- Auto-kill NPCs and mega bosses\n- Round counter and statistics\n- Auto-reset after round 21 (optional)"
        })
        
        Tabs.War:AddToggle("WarFarmToggle", {
            Title = "Enable War Farm",
            Default = Config.WarFarmEnabled
        }):OnChanged(function(v)
            FarmState.WarFarmEnabled = v
            Config.WarFarmEnabled = v
            ConfigManager.Save(Config)
        end)
        
        Tabs.War:AddToggle("WarAutoResetToggle", {
            Title = "Auto Reset After Round 21",
            Default = Config.WarAutoReset
        }):OnChanged(function(v)
            Config.WarAutoReset = v
            ConfigManager.Save(Config)
        end)
        
        -- War Farm logic
        task.spawn(function()
            while true do
                if FarmState.WarFarmEnabled and LocalPlayer.Character then
                    pcall(function()
                        local warmode = workspace:FindFirstChild("warmode")
                        local warserver = workspace:FindFirstChild("warserver")
                        
                        if warmode and warserver then
                            local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                            
                            if root and hum and hum.Health > 0 then
                                -- Anti-kick
                                hum:ChangeState(11)
                                
                                -- Kill NPCs
                                local npcs = workspace:FindFirstChild("npc")
                                if npcs then
                                    local zetsu = warserver:FindFirstChild("zetsu")
                                    local round = warserver:FindFirstChild("round")
                                    
                                    for _, npc in pairs(npcs:GetChildren()) do
                                        if npc:IsA("Model") 
                                            and npc:FindFirstChild("HumanoidRootPart")
                                            and npc:FindFirstChild("Humanoid")
                                            and npc.Humanoid.Health > 0 then
                                            
                                            local isMegaBoss = npc:FindFirstChild("megaboss") ~= nil
                                            
                                            if isMegaBoss then
                                                -- Mega boss - teleport and kill
                                                toTarget(root.Position, npc.HumanoidRootPart.Position,
                                                    CFrame.new(npc.HumanoidRootPart.Position))
                                                task.wait(0.5)
                                                npc.Humanoid.Health = 0
                                            else
                                                -- Normal NPC - instant kill if zetsu active
                                                if zetsu and zetsu.Value > 0 then
                                                    npc.Humanoid.Health = 0
                                                else
                                                    toTarget(root.Position, npc.HumanoidRootPart.Position,
                                                        CFrame.new(npc.HumanoidRootPart.Position + Vector3.new(0, -12, 0)))
                                                    task.wait(0.3)
                                                    npc.Humanoid.Health = 0
                                                end
                                            end
                                        end
                                    end
                                    
                                    -- Auto-reset after round 21
                                    if Config.WarAutoReset and round and round.Value > 20 then
                                        task.wait(5)
                                        LocalPlayer.Character:BreakJoints()
                                        FarmState.WarCount = FarmState.WarCount + 1
                                    end
                                end
                            end
                        end
                    end)
                end
                task.wait(1)
            end
        end)
        
        -- ==========================================
        -- QUEST MAKER
        -- ==========================================
        Tabs.Quests:AddParagraph({
            Title = "[Q] Quest Maker",
            Content = "Instantly complete quest requirements.\n\n- Rushes (300x)\n- Jumps (300x)\n- Chakra Charges (500x)\n- Punches (999x)"
        })
        
        Tabs.Quests:AddButton({Title = "Complete Rushes (300x)", Callback = function()
            task.spawn(function()
                for i = 1, 300 do
                    pcall(function()
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("combat") then
                            LocalPlayer.Character.combat.update:FireServer("rushw")
                        end
                    end)
                    task.wait(0.25)
                end
                ui.Fluent:Notify({Title = "[OK] Quest", Content = "300 Rushes completed!", Duration = 2})
            end)
        end})
        
        Tabs.Quests:AddButton({Title = "Complete Jumps (300x)", Callback = function()
            task.spawn(function()
                for i = 1, 300 do
                    pcall(function()
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("combat") then
                            LocalPlayer.Character.combat.update:FireServer("takemovement2")
                        end
                    end)
                    task.wait(0.25)
                end
                ui.Fluent:Notify({Title = "[OK] Quest", Content = "300 Jumps completed!", Duration = 2})
            end)
        end})
        
        Tabs.Quests:AddButton({Title = "Complete Chakra Charges (500x)", Callback = function()
            task.spawn(function()
                for i = 1, 500 do
                    pcall(function()
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("combat") then
                            LocalPlayer.Character.combat.update:FireServer("key", "c")
                            task.wait(0.1)
                            LocalPlayer.Character.combat.update:FireServer("key", "cend")
                        end
                    end)
                    task.wait(0.5)
                end
                ui.Fluent:Notify({Title = "[OK] Quest", Content = "500 Chakra Charges completed!", Duration = 2})
            end)
        end})
        
        Tabs.Quests:AddButton({Title = "Complete Punches (999x)", Callback = function()
            task.spawn(function()
                for i = 1, 999 do
                    pcall(function()
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("combat") then
                            LocalPlayer.Character.combat.update:FireServer("mouse1", true)
                        end
                    end)
                    task.wait(0.3)
                end
                ui.Fluent:Notify({Title = "[OK] Quest", Content = "999 Punches completed!", Duration = 2})
            end)
        end})
        
        -- ==========================================
        -- AUTO STATS DISTRIBUTION (NEW!)
        -- ==========================================
        Tabs.Stats:AddParagraph({
            Title = "[S] Auto Stats Distribution",
            Content = "Automatically distribute stat points when you level up.\n\n- NIN (Ninjutsu): Increases jutsu damage\n- TAI (Taijutsu): Increases melee damage\n- CHI (Chakra): Increases chakra pool\n- HP (Health): Increases max health\n\nEnable individual stats or all at once.\nCurrent Points: " .. getStatPoints()
        })
        
        Tabs.Stats:AddToggle("AutoStatsToggle", {
            Title = "Enable Auto Stats",
            Description = "Automatically spend available stat points",
            Default = Config.AutoStatsEnabled
        }):OnChanged(function(v)
            FarmState.AutoStatsEnabled = v
            Config.AutoStatsEnabled = v
            ConfigManager.Save(Config)
            if v then
                ui.Fluent:Notify({
                    Title = "[S] Auto Stats Enabled",
                    Content = "Will distribute points every " .. Config.AutoStatsInterval .. "s",
                    Duration = 3
                })
            end
        end)
        
        Tabs.Stats:AddToggle("AutoStatsNinToggle", {
            Title = "Auto NIN (Ninjutsu)",
            Description = "Add points to Ninjutsu stat",
            Default = Config.AutoStatsNinEnabled
        }):OnChanged(function(v)
            FarmState.AutoStatsNinEnabled = v
            Config.AutoStatsNinEnabled = v
            ConfigManager.Save(Config)
        end)
        
        Tabs.Stats:AddToggle("AutoStatsTaiToggle", {
            Title = "Auto TAI (Taijutsu)",
            Description = "Add points to Taijutsu stat",
            Default = Config.AutoStatsTaiEnabled
        }):OnChanged(function(v)
            FarmState.AutoStatsTaiEnabled = v
            Config.AutoStatsTaiEnabled = v
            ConfigManager.Save(Config)
        end)
        
        Tabs.Stats:AddToggle("AutoStatsChiToggle", {
            Title = "Auto CHI (Chakra)",
            Description = "Add points to Chakra stat",
            Default = Config.AutoStatsChiEnabled
        }):OnChanged(function(v)
            FarmState.AutoStatsChiEnabled = v
            Config.AutoStatsChiEnabled = v
            ConfigManager.Save(Config)
        end)
        
        Tabs.Stats:AddToggle("AutoStatsHpToggle", {
            Title = "Auto HP (Health)",
            Description = "Add points to Health stat",
            Default = Config.AutoStatsHpEnabled
        }):OnChanged(function(v)
            FarmState.AutoStatsHpEnabled = v
            Config.AutoStatsHpEnabled = v
            ConfigManager.Save(Config)
        end)
        
        Tabs.Stats:AddSlider("AutoStatsIntervalSlider", {
            Title = "Check Interval (seconds)",
            Description = "How often to check for available points",
            Default = Config.AutoStatsInterval,
            Min = 1, Max = 10, Rounding = 0,
            Callback = function(v)
                Config.AutoStatsInterval = v
                ConfigManager.Save(Config)
            end
        })
        
        Tabs.Stats:AddSlider("AutoStatsMinPointsSlider", {
            Title = "Minimum Points to Spend",
            Description = "Only spend points when you have at least this many",
            Default = Config.AutoStatsMinPoints,
            Min = 1, Max = 50, Rounding = 0,
            Callback = function(v)
                Config.AutoStatsMinPoints = v
                ConfigManager.Save(Config)
            end
        })
        
        Tabs.Stats:AddButton({Title = "Add All Available Points to NIN", Callback = function()
            local points = getStatPoints()
            if points > 0 then
                local ok = addStat("ninjutsu", points)
                if ok then
                    ui.Fluent:Notify({Title = "[OK] Stats", Content = "Added " .. points .. " points to NIN", Duration = 3})
                else
                    ui.Fluent:Notify({Title = "[X] Error", Content = "Failed to add points", Duration = 3})
                end
            else
                ui.Fluent:Notify({Title = "[!] Info", Content = "No points available", Duration = 2})
            end
        end})
        
        Tabs.Stats:AddButton({Title = "Add All Available Points to TAI", Callback = function()
            local points = getStatPoints()
            if points > 0 then
                local ok = addStat("taijutsu", points)
                if ok then
                    ui.Fluent:Notify({Title = "[OK] Stats", Content = "Added " .. points .. " points to TAI", Duration = 3})
                else
                    ui.Fluent:Notify({Title = "[X] Error", Content = "Failed to add points", Duration = 3})
                end
            else
                ui.Fluent:Notify({Title = "[!] Info", Content = "No points available", Duration = 2})
            end
        end})
        
        Tabs.Stats:AddButton({Title = "Add All Available Points to CHI", Callback = function()
            local points = getStatPoints()
            if points > 0 then
                local ok = addStat("chakra", points)
                if ok then
                    ui.Fluent:Notify({Title = "[OK] Stats", Content = "Added " .. points .. " points to CHI", Duration = 3})
                else
                    ui.Fluent:Notify({Title = "[X] Error", Content = "Failed to add points", Duration = 3})
                end
            else
                ui.Fluent:Notify({Title = "[!] Info", Content = "No points available", Duration = 2})
            end
        end})
        
        Tabs.Stats:AddButton({Title = "Add All Available Points to HP", Callback = function()
            local points = getStatPoints()
            if points > 0 then
                local ok = addStat("health", points)
                if ok then
                    ui.Fluent:Notify({Title = "[OK] Stats", Content = "Added " .. points .. " points to HP", Duration = 3})
                else
                    ui.Fluent:Notify({Title = "[X] Error", Content = "Failed to add points", Duration = 3})
                end
            else
                ui.Fluent:Notify({Title = "[!] Info", Content = "No points available", Duration = 2})
            end
        end})
        
        -- Auto Stats Loop
        task.spawn(function()
            while true do
                if FarmState.AutoStatsEnabled then
                    pcall(function()
                        local points = getStatPoints()
                        
                        if points >= (Config.AutoStatsMinPoints or 5) then
                            -- Distribute points in priority order
                            local statsToDistribute = {}
                            
                            if FarmState.AutoStatsNinEnabled then
                                table.insert(statsToDistribute, "ninjutsu")
                            end
                            if FarmState.AutoStatsTaiEnabled then
                                table.insert(statsToDistribute, "taijutsu")
                            end
                            if FarmState.AutoStatsChiEnabled then
                                table.insert(statsToDistribute, "chakra")
                            end
                            if FarmState.AutoStatsHpEnabled then
                                table.insert(statsToDistribute, "health")
                            end
                            
                            if #statsToDistribute > 0 then
                                -- Distribute evenly or to first enabled
                                local pointsPerStat = math.floor(points / #statsToDistribute)
                                
                                for _, statName in ipairs(statsToDistribute) do
                                    if pointsPerStat > 0 then
                                        local ok = addStat(statName, pointsPerStat)
                                        if ok then
                                            FarmState.StatsAdded[statName] = (FarmState.StatsAdded[statName] or 0) + pointsPerStat
                                        end
                                        task.wait(0.2) -- Small delay between stat additions
                                    end
                                end
                                
                                -- Add any remaining points to first enabled stat
                                local remaining = points - (pointsPerStat * #statsToDistribute)
                                if remaining > 0 and #statsToDistribute > 0 then
                                    addStat(statsToDistribute[1], remaining)
                                    FarmState.StatsAdded[statsToDistribute[1]] = (FarmState.StatsAdded[statsToDistribute[1]] or 0) + remaining
                                end
                                
                                ui.Fluent:Notify({
                                    Title = "[S] Stats Distributed",
                                    Content = "Spent " .. points .. " points across " .. #statsToDistribute .. " stats",
                                    Duration = 2
                                })
                            end
                        end
                    end)
                end
                task.wait(Config.AutoStatsInterval or 2)
            end
        end)
        
        -- Stats Status Display
        local StatsStatusDisplay = Tabs.Stats:AddParagraph({
            Title = "Stats Status",
            Content = "Initializing..."
        })
        
        task.spawn(function()
            while true do
                local points = getStatPoints()
                local ninLvl = getStatLevel("ninjutsu")
                local taiLvl = getStatLevel("taijutsu")
                local chiLvl = getStatLevel("chakra")
                local hpLvl = getStatLevel("health")
                
                StatsStatusDisplay.Content = string.format(
                    "Status: %s\n\nAvailable Points: %d\nMin to Spend: %d\nCheck Interval: %ds\n\nCurrent Levels:\n- NIN: %d (+%d added)\n- TAI: %d (+%d added)\n- CHI: %d (+%d added)\n- HP: %d (+%d added)\n\nEnabled Stats:\n- NIN: %s\n- TAI: %s\n- CHI: %s\n- HP: %s",
                    FarmState.AutoStatsEnabled and "[OK] ACTIVE" or "[X] INACTIVE",
                    points,
                    Config.AutoStatsMinPoints,
                    Config.AutoStatsInterval,
                    ninLvl, FarmState.StatsAdded.ninjutsu or 0,
                    taiLvl, FarmState.StatsAdded.taijutsu or 0,
                    chiLvl, FarmState.StatsAdded.chakra or 0,
                    hpLvl, FarmState.StatsAdded.health or 0,
                    FarmState.AutoStatsNinEnabled and "[OK]" or "[X]",
                    FarmState.AutoStatsTaiEnabled and "[OK]" or "[X]",
                    FarmState.AutoStatsChiEnabled and "[OK]" or "[X]",
                    FarmState.AutoStatsHpEnabled and "[OK]" or "[X]"
                )
                task.wait(1)
            end
        end)
        
        -- ==========================================
        -- AUTO CHAKRA
        -- ==========================================
        Tabs.Chakra:AddParagraph({
            Title = "[C] Auto Chakra Management",
            Content = "Automatically charges chakra when below threshold."
        })
        
        Tabs.Chakra:AddToggle("AutoChakraToggle", {
            Title = "Enable Auto Chakra",
            Default = Config.AutoChakraEnabled
        }):OnChanged(function(v)
            FarmState.AutoChakraEnabled = v
            Config.AutoChakraEnabled = v
            ConfigManager.Save(Config)
        end)
        
        Tabs.Chakra:AddSlider("ChakraThresholdSlider", {
            Title = "Charge Threshold",
            Description = "Start charging when chakra drops below this value",
            Default = Config.AutoChakraThreshold,
            Min = 30000, Max = 250000, Rounding = 0,
            Callback = function(v)
                FarmState.ChakraThreshold = v
                Config.AutoChakraThreshold = v
                ConfigManager.Save(Config)
            end
        })
        
        -- Auto Chakra logic
        task.spawn(function()
            while true do
                if FarmState.AutoChakraEnabled and LocalPlayer.Character then
                    pcall(function()
                        local char = LocalPlayer.Character
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        
                        if hum and hum.Health > 0 then
                            -- Read chakra from GUI
                            local chakraGui = LocalPlayer.PlayerGui:FindFirstChild("Main") 
                                and LocalPlayer.PlayerGui.Main:FindFirstChild("ingamearena")
                                and LocalPlayer.PlayerGui.Main.ingamearena:FindFirstChild("Bar")
                                and LocalPlayer.PlayerGui.Main.ingamearena.Bar:FindFirstChild("cha")
                            
                            if chakraGui and chakraGui.Text then
                                local chakraText = chakraGui.Text
                                local chakraValue = tonumber(string.match(chakraText, "CHA: (%d+)"))
                                
                                if chakraValue then
                                    if chakraValue < FarmState.ChakraThreshold then
                                        -- Charge chakra
                                        char.combat.update:FireServer("key", "c")
                                    else
                                        -- Release chakra
                                        char.combat.update:FireServer("key", "cend")
                                    end
                                end
                            end
                            
                            -- Keep moving while charging
                            if hum.WalkSpeed == 0 then
                                hum.WalkSpeed = 50
                            end
                        end
                    end)
                end
                task.wait(0.5)
            end
        end)
        
        -- ==========================================
        -- UTILITIES
        -- ==========================================
        Tabs.Utilities:AddParagraph({
            Title = "[U] Utilities",
            Content = "Teleport and miscellaneous features."
        })
        
        Tabs.Utilities:AddButton({Title = "Teleport to Training Log", Callback = function()
            pcall(function()
                local npc = workspace:FindFirstChild("npc")
                if npc then
                    local log = npc:FindFirstChild("logtraining")
                    if log and log:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = log.HumanoidRootPart.CFrame
                        ui.Fluent:Notify({Title = "[OK] Teleport", Content = "Teleported to Training Log", Duration = 2})
                    end
                end
            end)
        end})
        
        Tabs.Utilities:AddButton({Title = "Teleport to Spawn", Callback = function()
            pcall(function()
                local spawn = workspace:FindFirstChild("spawn") or workspace:FindFirstChild("Spawn")
                if spawn and spawn:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = spawn.HumanoidRootPart.CFrame
                    ui.Fluent:Notify({Title = "[OK] Teleport", Content = "Teleported to Spawn", Duration = 2})
                end
            end)
        end})
        
        Tabs.Utilities:AddToggle("AutoRankToggle", {
            Title = "Auto Rank Up (Level 1000)",
            Description = "Automatically rank up when reaching level 1000",
            Default = Config.AutoRankEnabled
        }):OnChanged(function(v)
            FarmState.AutoRankEnabled = v
            Config.AutoRankEnabled = v
            ConfigManager.Save(Config)
        end)
        
        -- Auto Rank logic
        task.spawn(function()
            while true do
                if FarmState.AutoRankEnabled then
                    pcall(function()
                        local lvl = LocalPlayer:FindFirstChild("statz") 
                            and LocalPlayer.statz:FindFirstChild("lvl")
                            and LocalPlayer.statz.lvl:FindFirstChild("lvl")
                        
                        if lvl and lvl.Value == 1000 then
                            LocalPlayer.startevent:FireServer("rankup")
                            ui.Fluent:Notify({Title = "[!] Rank Up!", Content = "Attempting to rank up...", Duration = 3})
                        end
                    end)
                end
                task.wait(2)
            end
        end)
        
        -- CharacterAdded handler for WalkSpeed/JumpHeight + Godmode persistence
        LocalPlayer.CharacterAdded:Connect(function(char)
            char:WaitForChild("HumanoidRootPart")
            task.wait(3)
            if char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = Config.WalkSpeed
                char.Humanoid.JumpHeight = Config.JumpHeight
                char.Humanoid.UseJumpPower = false
                
                -- Re-apply godmode if enabled
                if FarmState.GodModeEnabled then
                    char.Humanoid.Health = char.Humanoid.MaxHealth
                    local fakehealth = char:FindFirstChild("fakehealth")
                    if fakehealth then
                        fakehealth.Value = FarmState.FakeHealthValue
                    end
                end
            end
        end)
        
        ui.Window:SelectTab(1)
        ui.Fluent:Notify({
            Title = "GlockreisHub",
            Content = "Loaded: Shindo Life In-Game (Enhanced + M1 + Stats + Godmode)",
            Duration = 5
        })
    end
end
