-- // ==========================================
-- // GLOCKREISHUB - SHINDO LIFE MODULE (ENHANCED)
-- // AutoFarm M1 + Auto Stats + Godmode + Position Control
-- // Continuous Facing + Underground Attack + Auto Skill Spammer
-- // Mission Protection + KillAura (ULTRA FAST) + AutoFarm Boss (NPC CYCLE)
-- // Experimental: AntiRagdoll, AntiKnockback, ESP, StunImmunity
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
            AutoFarmAttackDistance = -8,
            AutoFarmAttackBehind = 0,
            ScrollSniperEnabled = false,
            WarFarmEnabled = false, WarAutoReset = true,
            AutoChakraEnabled = false, AutoChakraThreshold = 100000,
            AutoRankEnabled = false,
            AutoStatsEnabled = false,
            AutoStatsNinEnabled = true,
            AutoStatsTaiEnabled = false,
            AutoStatsChiEnabled = false,
            AutoStatsHpEnabled = false,
            AutoStatsInterval = 2,
            AutoStatsMinPoints = 5,
            GodModeEnabled = false,
            FakeHealthValue = 999999,
            -- Auto Skill Spammer Config
            AutoSkillREnabled = false,
            AutoSkillTEnabled = false,
            AutoSkillYEnabled = false,
            AutoSkillFEnabled = false,
            AutoSkillGEnabled = false,
            AutoSkillHEnabled = false,
            AutoSkillVEnabled = false,
            AutoSkillBEnabled = false,
            AutoSkillNEnabled = false,
            AutoSkillQEnabled = false,
            AutoSkillEEnabled = false,
            AutoSkillSpamSpeed = 0.2,
            -- AutoFarm Boss Config
            AutoFarmBossEnabled = false,
            AutoFarmBossSelected = {},
            AutoFarmBossSpeed = 800,
            AutoFarmBossTimeout = 15,
            -- Experimental Config
            KillAuraEnabled = false,
            KillAuraRange = 500,
            KillAuraSpeed = 0.01,
            KillAuraTargetNPCs = true,
            KillAuraTargetPlayers = true,
            KillAuraForceKill = true,
            AntiRagdollEnabled = false,
            AntiKnockbackEnabled = false,
            ESPEnabled = false,
            ESPShowNames = true,
            ESPShowDistance = true,
            ESPShowHealth = true,
            ESPMaxDistance = 500,
            ESPFillColor = {R = 255, G = 0, B = 0},
            ESPOutlineColor = {R = 255, G = 255, B = 0},
            StunGrabImmunityEnabled = false
        }
    end
    
    local ConfigManager = Common.setupConfigManager(isShindoMenu and "ShindoLife_Menu" or "ShindoLife_InGame")
    local Config = ConfigManager.Load(DefaultConfig)
    
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
    
    -- Shared state: current target for continuous facing
    local currentTargetNPC = nil
    
    -- M1 Attack Helper
    local lastM1Time = 0
    local function attackM1(targetHRP)
        local char = LocalPlayer.Character
        if not char then return false end
        local root = char:FindFirstChild("HumanoidRootPart")
        local combat = char:FindFirstChild("combat")
        if not root or not combat then return false end
        local now = tick()
        if now - lastM1Time < (Config.AutoFarmM1Cooldown or 0.3) then return false end
        if targetHRP then
            local targetPos = targetHRP.Position
            root.CFrame = CFrame.lookAt(root.Position, targetPos)
        end
        local ok = pcall(function() combat.update:FireServer("mouse1", true) end)
        if ok then
            lastM1Time = now
            task.delay(0.05, function()
                pcall(function() combat.update:FireServer("mouse1", false) end)
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
        Tabs.BossFarm = ui.Window:AddTab({ Title = "Boss Farm", Icon = "crown" })
        Tabs.Godmode = ui.Window:AddTab({ Title = "Godmode", Icon = "shield" })
        Tabs.Scroll = ui.Window:AddTab({ Title = "Scroll Sniper", Icon = "book" })
        Tabs.War = ui.Window:AddTab({ Title = "War Farm", Icon = "shield" })
        Tabs.Quests = ui.Window:AddTab({ Title = "Quest Maker", Icon = "list" })
        Tabs.Stats = ui.Window:AddTab({ Title = "Auto Stats", Icon = "trending-up" })
        Tabs.Skills = ui.Window:AddTab({ Title = "Oto Skill", Icon = "zap" })
        Tabs.Chakra = ui.Window:AddTab({ Title = "Auto Chakra", Icon = "activity" })
        Tabs.Experimental = ui.Window:AddTab({ Title = "Experimental", Icon = "flask-conical" })
        Tabs.Utilities = ui.Window:AddTab({ Title = "Utilities", Icon = "tool" })
        
        local FarmState = {
            AutoFarmEnabled = Config.AutoFarmEnabled,
            AutoFarmUseM1 = Config.AutoFarmUseM1,
            AutoFarmAttackDistance = Config.AutoFarmAttackDistance or -8,
            AutoFarmAttackBehind = Config.AutoFarmAttackBehind or 0,
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
            -- Auto Skill Spammer State
            AutoSkillREnabled = Config.AutoSkillREnabled,
            AutoSkillTEnabled = Config.AutoSkillTEnabled,
            AutoSkillYEnabled = Config.AutoSkillYEnabled,
            AutoSkillFEnabled = Config.AutoSkillFEnabled,
            AutoSkillGEnabled = Config.AutoSkillGEnabled,
            AutoSkillHEnabled = Config.AutoSkillHEnabled,
            AutoSkillVEnabled = Config.AutoSkillVEnabled,
            AutoSkillBEnabled = Config.AutoSkillBEnabled,
            AutoSkillNEnabled = Config.AutoSkillNEnabled,
            AutoSkillQEnabled = Config.AutoSkillQEnabled,
            AutoSkillEEnabled = Config.AutoSkillEEnabled,
            AutoSkillSpamSpeed = Config.AutoSkillSpamSpeed or 0.2,
            -- Boss Farm State
            AutoFarmBossEnabled = Config.AutoFarmBossEnabled,
            AutoFarmBossSelected = Config.AutoFarmBossSelected or {},
            AutoFarmBossSpeed = Config.AutoFarmBossSpeed or 800,
            AutoFarmBossTimeout = Config.AutoFarmBossTimeout or 15,
            BossFarmStatus = "Idle",
            BossFarmCurrent = "",
            BossFarmCompleted = 0,
            -- Experimental State
            KillAuraEnabled = Config.KillAuraEnabled,
            KillAuraRange = Config.KillAuraRange or 500,
            KillAuraSpeed = Config.KillAuraSpeed or 0.01,
            KillAuraTargetNPCs = Config.KillAuraTargetNPCs,
            KillAuraTargetPlayers = Config.KillAuraTargetPlayers,
            KillAuraForceKill = Config.KillAuraForceKill,
            AntiRagdollEnabled = Config.AntiRagdollEnabled,
            AntiKnockbackEnabled = Config.AntiKnockbackEnabled,
            ESPEnabled = Config.ESPEnabled,
            ESPShowNames = Config.ESPShowNames,
            ESPShowDistance = Config.ESPShowDistance,
            ESPShowHealth = Config.ESPShowHealth,
            ESPMaxDistance = Config.ESPMaxDistance or 500,
            ESPFillColor = Color3.new(
                (Config.ESPFillColor and Config.ESPFillColor.R or 255)/255,
                (Config.ESPFillColor and Config.ESPFillColor.G or 0)/255,
                (Config.ESPFillColor and Config.ESPFillColor.B or 0)/255
            ),
            ESPOutlineColor = Color3.new(
                (Config.ESPOutlineColor and Config.ESPOutlineColor.R or 255)/255,
                (Config.ESPOutlineColor and Config.ESPOutlineColor.G or 255)/255,
                (Config.ESPOutlineColor and Config.ESPOutlineColor.B or 0)/255
            ),
            StunGrabImmunityEnabled = Config.StunGrabImmunityEnabled,
            -- Stats
            WarCount = 0,
            ChakraThreshold = Config.AutoChakraThreshold,
            StatsAdded = {ninjutsu = 0, taijutsu = 0, chakra = 0, health = 0},
            SkillStats = {r = 0, t = 0, y = 0, f = 0, g = 0, h = 0, v = 0, b = 0, n = 0, q = 0, e = 0},
            KillAuraKills = 0
        }
        
        -- ==========================================
        -- CONTINUOUS FACING LOOP
        -- ==========================================
        RunService.RenderStepped:Connect(function()
            if not FarmState.AutoFarmEnabled then
                currentTargetNPC = nil
                return
            end
            local char = LocalPlayer.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            if currentTargetNPC and currentTargetNPC.Parent then
                local npcRoot = currentTargetNPC:FindFirstChild("HumanoidRootPart")
                local npcHum = currentTargetNPC:FindFirstChild("Humanoid")
                if npcRoot and npcHum and npcHum.Health > 0 then
                    local targetPos = npcRoot.Position
                    root.CFrame = CFrame.lookAt(root.Position, targetPos)
                else
                    currentTargetNPC = nil
                end
            end
        end)
        
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
                ui.Fluent:Notify({Title = "[G] Godmode Enabled", Content = "You are now invincible!", Duration = 3})
            else
                ui.Fluent:Notify({Title = "[G] Godmode Disabled", Content = "Normal health restored", Duration = 3})
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
        
        task.spawn(function()
            while true do
                if FarmState.GodModeEnabled and LocalPlayer.Character then
                    pcall(function()
                        local char = LocalPlayer.Character
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then
                            hum.Health = hum.MaxHealth
                            local fakehealth = char:FindFirstChild("fakehealth")
                            if fakehealth then fakehealth.Value = FarmState.FakeHealthValue end
                        end
                    end)
                end
                task.wait(0.1)
            end
        end)
        
        local GodmodeStatusDisplay = Tabs.Godmode:AddParagraph({Title = "Godmode Status", Content = "Initializing..."})
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
                if fakehealth then fakeHealthStr = tostring(fakehealth.Value) end
                GodmodeStatusDisplay.Content = string.format(
                    "Status: %s\n\nHealth: %s / %s\nfakehealth Value: %s\nTarget fakehealth: %d\n\nGodmode: %s",
                    FarmState.GodModeEnabled and "[OK] ACTIVE" or "[X] INACTIVE",
                    healthStr, maxHealthStr, fakeHealthStr, FarmState.FakeHealthValue,
                    FarmState.GodModeEnabled and "ENABLED" or "DISABLED"
                )
                task.wait(0.5)
            end
        end)
        
        -- ==========================================
        -- AUTOFARM (MISSION-BASED) WITH MISSION PROTECTION
        -- ==========================================
        Tabs.Main:AddParagraph({
            Title = "[*] AutoFarm System (FIXED + M1 + UNDERGROUND + PROTECTION)",
            Content = "Automatically accepts and completes missions.\n\n- Uses currentmission.Value (primary check)\n- Falls back to MissionStory.Visible (secondary)\n- Level-aware mission selection (699 / 700+)\n- Only kills npctype NPCs (filters out players/bosses)\n- NEW: M1 melee attacks from UNDERGROUND\n- NEW: Continuous facing toward target (RenderStepped)\n- NEW: Player looks UP at NPC from below ground\n- NEW: MISSION PROTECTION - Auto-cancels non-green missions\n- Waits 1s after accepting mission for server sync\n- Polls every 0.5s for fast response"
        })
        
        Tabs.Main:AddToggle("AutoFarmToggle", {
            Title = "Enable AutoFarm",
            Description = "Auto-accept and complete missions",
            Default = Config.AutoFarmEnabled
        }):OnChanged(function(v)
            FarmState.AutoFarmEnabled = v
            Config.AutoFarmEnabled = v
            ConfigManager.Save(Config)
            if not v then currentTargetNPC = nil end
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
        
        Tabs.Main:AddSlider("AutoFarmAttackDistanceSlider", {
            Title = "Attack Distance (Y offset)",
            Description = "How many studs BELOW the NPC to position. Negative = below, 0 = same height. Default: -8",
            Default = Config.AutoFarmAttackDistance,
            Min = -20, Max = 0, Rounding = 0,
            Callback = function(v)
                FarmState.AutoFarmAttackDistance = v
                Config.AutoFarmAttackDistance = v
                ConfigManager.Save(Config)
            end
        })
        
        Tabs.Main:AddSlider("AutoFarmAttackBehindSlider", {
            Title = "Attack Behind (Z offset)",
            Description = "How many studs BEHIND the NPC to position. Positive = behind, negative = in front. Default: 0",
            Default = Config.AutoFarmAttackBehind,
            Min = -10, Max = 10, Rounding = 0,
            Callback = function(v)
                FarmState.AutoFarmAttackBehind = v
                Config.AutoFarmAttackBehind = v
                ConfigManager.Save(Config)
            end
        })
        
        Tabs.Main:AddParagraph({
            Title = "Underground Attack Info",
            Content = "Player positions UNDER the NPC (Y offset) and looks UP at them.\nM1 attacks are fired while facing upward.\nRenderStepped loop keeps player facing target at all times.\n\nRecommended: Y=-8, Z=0 for most NPCs"
        })
        
        Tabs.Main:AddParagraph({
            Title = "Mission Protection",
            Content = "If a non-green mission is accidentally accepted,\nthe script will automatically send '!cancel'\nto the chat to abort the mission.\n\nThis prevents getting stuck on red/other color missions."
        })
        
        -- AutoFarm logic with mission protection
        task.spawn(function()
            while true do
                if FarmState.AutoFarmEnabled and LocalPlayer.Character then
                    pcall(function()
                        local char = LocalPlayer.Character
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        local root = char:FindFirstChild("HumanoidRootPart")
                        
                        if hum and root and hum.Health > 0 then
                            hum:ChangeState(11)
                            
                            local currentmission = LocalPlayer:FindFirstChild("currentmission")
                            local hasMission = currentmission and currentmission.Value ~= nil and currentmission.Value ~= ""
                            
                            local missionGui = LocalPlayer.PlayerGui:FindFirstChild("Main") 
                                and LocalPlayer.PlayerGui.Main:FindFirstChild("ingame")
                                and LocalPlayer.PlayerGui.Main.ingame:FindFirstChild("MissionStory")
                            
                            if missionGui and missionGui.Visible then hasMission = true end
                            
                            if not hasMission then
                                currentTargetNPC = nil
                                local missionGivers = workspace:FindFirstChild("missiongivers")
                                if missionGivers then
                                    local lvl = LocalPlayer:FindFirstChild("statz") 
                                        and LocalPlayer.statz:FindFirstChild("lvl")
                                        and LocalPlayer.statz.lvl:FindFirstChild("lvl")
                                        and LocalPlayer.statz.lvl.lvl.Value or 0
                                    
                                    local green = "http://www.roblox.com/asset/?id=5459241648"
                                    
                                    for _, giver in pairs(missionGivers:GetChildren()) do
                                        if giver:FindFirstChild("Head") 
                                            and giver.Head:FindFirstChild("givemission")
                                            and giver.Head.givemission.Enabled then
                                            
                                            local talk = giver:FindFirstChild("Talk")
                                            local shouldAccept = false
                                            
                                            if lvl <= 699 then
                                                if talk and talk:FindFirstChild("typ") 
                                                    and talk.typ.Value == "defeat"
                                                    and giver.Head.givemission:FindFirstChild("color")
                                                    and giver.Head.givemission.color.Visible
                                                    and giver.Head.givemission.color.Image == green then
                                                    shouldAccept = true
                                                end
                                            else
                                                if talk and talk:FindFirstChild("typ") 
                                                    and talk.typ.Value == "defeat"
                                                    and giver.Head.givemission:FindFirstChild("color")
                                                    and giver.Head.givemission.color.Visible
                                                    and giver.Head.givemission.color.Image == green then
                                                    shouldAccept = true
                                                end
                                            end
                                            
                                            if shouldAccept then
                                                local clientTalk = giver:FindFirstChild("CLIENTTALK")
                                                local giverRoot = giver:FindFirstChild("HumanoidRootPart")
                                                
                                                if clientTalk and giverRoot then
                                                    local offsetVector = Vector3.new(0, FarmState.AutoFarmAttackDistance, FarmState.AutoFarmAttackBehind)
                                                    toTarget(root.Position, giverRoot.Position, 
                                                        CFrame.new(giverRoot.Position + offsetVector))
                                                    task.wait(0.5)
                                                    
                                                    local dist = (root.Position - giverRoot.Position).Magnitude
                                                    if dist < 10 then
                                                        clientTalk:FireServer()
                                                        task.wait(0.3)
                                                        clientTalk:FireServer("accept")
                                                        
                                                        -- MISSION PROTECTION
                                                        task.wait(0.5)
                                                        local acceptedMission = LocalPlayer:FindFirstChild("currentmission")
                                                        if acceptedMission and acceptedMission.Value ~= nil and acceptedMission.Value ~= "" then
                                                            local currentColor = nil
                                                            if giver:FindFirstChild("Head") 
                                                                and giver.Head:FindFirstChild("givemission")
                                                                and giver.Head.givemission:FindFirstChild("color") then
                                                                currentColor = giver.Head.givemission.color.Image
                                                            end
                                                            
                                                            if currentColor and currentColor ~= green then
                                                                ui.Fluent:Notify({
                                                                    Title = "[!] Mission Protection",
                                                                    Content = "Non-green mission detected! Cancelling...",
                                                                    Duration = 3
                                                                })
                                                                pcall(function()
                                                                    local TextChatService = game:GetService("TextChatService")
                                                                    if TextChatService then
                                                                        local channel = TextChatService:WaitForChild("TextChannels", 2)
                                                                        if channel then
                                                                            local rbxGeneral = channel:FindFirstChild("RBXGeneral")
                                                                            if rbxGeneral then rbxGeneral:SendAsync("!cancel") end
                                                                        end
                                                                    end
                                                                end)
                                                                pcall(function()
                                                                    local vc = workspace:FindFirstChild("VC")
                                                                    if vc then
                                                                        local remote = vc:FindFirstChild("RemoteEvent")
                                                                        if remote then remote:FireServer("!cancel") end
                                                                    end
                                                                end)
                                                                task.wait(1)
                                                            end
                                                        end
                                                        task.wait(1)
                                                    end
                                                end
                                                break
                                            end
                                        end
                                    end
                                end
                            else
                                local npcs = workspace:FindFirstChild("npc")
                                if npcs then
                                    local killed = false
                                    for _, npc in pairs(npcs:GetChildren()) do
                                        if npc:IsA("Model") 
                                            and npc:FindFirstChild("HumanoidRootPart")
                                            and npc:FindFirstChild("Humanoid")
                                            and npc.Humanoid.Health > 0
                                            and npc:FindFirstChild("npctype")
                                            and string.find(npc.Name, "npc")
                                            and npc.Head.CFrame.Y > -1000 then
                                            
                                            local npcRoot = npc.HumanoidRootPart
                                            currentTargetNPC = npc
                                            
                                            local offsetVector = Vector3.new(0, FarmState.AutoFarmAttackDistance, FarmState.AutoFarmAttackBehind)
                                            toTarget(root.Position, npcRoot.Position,
                                                CFrame.new(npcRoot.Position + offsetVector))
                                            task.wait(0.3)
                                            
                                            local dist = (root.Position - npcRoot.Position).Magnitude
                                            
                                            if dist < 15 then
                                                if FarmState.AutoFarmUseM1 then
                                                    local attackCount = 0
                                                    local maxAttacks = 10
                                                    while npc.Humanoid.Health > 0 and attackCount < maxAttacks do
                                                        attackM1(npcRoot)
                                                        attackCount = attackCount + 1
                                                        task.wait(Config.AutoFarmM1Cooldown or 0.3)
                                                        if not npc.Parent or npc.Humanoid.Health <= 0 then break end
                                                    end
                                                    if npc.Humanoid.Health <= 0 then killed = true end
                                                else
                                                    npc.Humanoid.Health = 0
                                                    killed = true
                                                end
                                            end
                                            break
                                        end
                                    end
                                    if not killed then
                                        currentTargetNPC = nil
                                        task.wait(0.5)
                                    end
                                end
                            end
                        end
                    end)
                else
                    currentTargetNPC = nil
                end
                task.wait(0.5)
            end
        end)
        
-- ==========================================
-- AUTOFARM BOSS (ENHANCED - ANTI-FALL + REAR TELEPORT)
-- ==========================================
Tabs.BossFarm:AddParagraph({
    Title = "[B] AutoFarm Boss System (ANTI-FALL)",
    Content = "Automatically farm boss drop missions.\n\n" ..
        "- Scans workspace.bossdropmission.missions\n" ..
        "- Cycles through selected bosses in order\n" ..
        "- Teleports BEHIND & ABOVE missiongiver (safe position)\n" ..
        "- Waits 15 seconds for quest acceptance\n" ..
        "- NEW: ANTI-FALL - Auto-cancels if you fall below map\n" ..
        "- NEW: Finds ALL NPCs with 'npc' in name\n" ..
        "- NEW: Teleports to each NPC's HumanoidRootPart\n" ..
        "- NEW: Kills NPCs one by one until mission completes\n" ..
        "- Moves to next boss after all NPCs killed\n\n" ..
        "NOTE: Disable regular AutoFarm while using Boss Farm!"
})

-- Get available bosses from workspace
local function getAvailableBosses()
    local bosses = {}
    local missionsFolder = workspace:FindFirstChild("bossdropmission")
    if missionsFolder then
        local missionsSubFolder = missionsFolder:FindFirstChild("missions")
        if missionsSubFolder then
            for _, folder in pairs(missionsSubFolder:GetChildren()) do
                if folder:IsA("Folder") or folder:IsA("Model") then
                    table.insert(bosses, folder.Name)
                end
            end
        end
    end
    table.sort(bosses)
    return bosses
end

local availableBosses = getAvailableBosses()
if #availableBosses == 0 then
    availableBosses = {"(No bosses found - check workspace.bossdropmission.missions)"}
end

-- Validate selected bosses
local validBosses = {}
for _, v in ipairs(FarmState.AutoFarmBossSelected) do
    if table.find(availableBosses, v) then
        table.insert(validBosses, v)
    end
end

local defaultBossDict = {}
for _, v in ipairs(validBosses) do defaultBossDict[v] = true end

Tabs.BossFarm:AddToggle("AutoFarmBossToggle", {
    Title = "Enable AutoFarm Boss",
    Description = "Automatically cycle through selected bosses and farm them",
    Default = Config.AutoFarmBossEnabled
}):OnChanged(function(v)
    FarmState.AutoFarmBossEnabled = v
    Config.AutoFarmBossEnabled = v
    ConfigManager.Save(Config)
    if v then
        ui.Fluent:Notify({
            Title = "[B] Boss Farm Enabled",
            Content = "Starting boss cycle...",
            Duration = 3
        })
    else
        FarmState.BossFarmStatus = "Idle"
        FarmState.BossFarmCurrent = ""
    end
end)

local BossDropdown = Tabs.BossFarm:AddDropdown("BossSelectionDropdown", {
    Title = "Select Bosses to Farm",
    Description = "Choose which bosses to cycle through (multi-select)",
    Values = availableBosses,
    Multi = true,
    Default = defaultBossDict,
    Flag = "BossSelectionFlag"
})

BossDropdown:OnChanged(function(Value)
    local parsed = {}
    if type(Value) == "table" then
        for k, v in pairs(Value) do
            if type(k) == "string" and v == true then
                table.insert(parsed, k)
            elseif type(k) == "number" and type(v) == "string" then
                table.insert(parsed, v)
            end
        end
    end
    table.sort(parsed)
    FarmState.AutoFarmBossSelected = parsed
    Config.AutoFarmBossSelected = parsed
    ConfigManager.Save(Config)
    ui.Fluent:Notify({
        Title = "[B] Boss List Updated",
        Content = "Selected: " .. (#parsed > 0 and table.concat(parsed, ", ") or "NONE"),
        Duration = 3
    })
end)

Tabs.BossFarm:AddSlider("AutoFarmBossSpeedSlider", {
    Title = "Boss Tween Speed (studs/sec)",
    Description = "Speed when traveling to boss missiongiver and NPCs",
    Default = Config.AutoFarmBossSpeed,
    Min = 200, Max = 2500, Rounding = 0,
    Callback = function(v)
        FarmState.AutoFarmBossSpeed = v
        Config.AutoFarmBossSpeed = v
        ConfigManager.Save(Config)
    end
})

Tabs.BossFarm:AddSlider("AutoFarmBossTimeoutSlider", {
    Title = "Quest Accept Timeout (seconds)",
    Description = "How long to wait for quest acceptance before skipping",
    Default = Config.AutoFarmBossTimeout,
    Min = 5, Max = 60, Rounding = 0,
    Callback = function(v)
        FarmState.AutoFarmBossTimeout = v
        Config.AutoFarmBossTimeout = v
        ConfigManager.Save(Config)
    end
})

Tabs.BossFarm:AddButton({
    Title = "Refresh Boss List",
    Callback = function()
        availableBosses = getAvailableBosses()
        if #availableBosses == 0 then
            availableBosses = {"(No bosses found)"}
        end
        ui.Fluent:Notify({
            Title = "[B] Boss List Refreshed",
            Content = "Found " .. #availableBosses .. " boss(es)",
            Duration = 3
        })
    end
})

Tabs.BossFarm:AddParagraph({
    Title = "Anti-Fall Protection",
    Content = "If you fall below Y=-500 (under the map):\n" ..
        "1. Auto-sends '!cancel' to chat\n" ..
        "2. Teleports you to safe spawn position\n" ..
        "3. Skips current boss and moves to next\n\n" ..
        "This prevents getting stuck under the map!"
})

Tabs.BossFarm:AddParagraph({
    Title = "Boss Farm Cycle Info",
    Content = "1. Select bosses from dropdown above\n" ..
        "2. Enable AutoFarm Boss toggle\n" ..
        "3. Script will cycle: Boss1 -> Boss2 -> Boss3 -> Boss1...\n" ..
        "4. For each boss:\n" ..
        "   - Teleport BEHIND & ABOVE missiongiver (safe)\n" ..
        "   - Try to accept quest (15s timeout)\n" ..
        "   - If accepted: find ALL NPCs with 'npc' in name\n" ..
        "   - Teleport to each NPC and kill them one by one\n" ..
        "   - Wait for mission completion\n" ..
        "   - Move to next boss\n" ..
        "5. Disable regular AutoFarm to avoid conflicts"
})

-- ==========================================
-- ANTI-FALL SYSTEM (ALWAYS ACTIVE)
-- ==========================================
local antiFallActive = false
local lastSafePosition = nil

-- Anti-Fall Logic - Runs continuously
task.spawn(function()
    while true do
        if LocalPlayer.Character then
            pcall(function()
                local char = LocalPlayer.Character
                local root = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChildOfClass("Humanoid")
                
                if root and hum and hum.Health > 0 then
                    local yPos = root.Position.Y
                    
                    -- Save safe position if above ground
                    if yPos > -200 then
                        lastSafePosition = root.CFrame
                    end
                    
                    -- ANTI-FALL: Check if fallen below map
                    if yPos < -500 then
                        if not antiFallActive then
                            antiFallActive = true
                            
                            ui.Fluent:Notify({
                                Title = "[!] ANTI-FALL ACTIVATED",
                                Content = "Fell below map! Cancelling mission...",
                                Duration = 3
                            })
                            
                            -- Send !cancel to chat
                            pcall(function()
                                local TextChatService = game:GetService("TextChatService")
                                if TextChatService then
                                    local channel = TextChatService:WaitForChild("TextChannels", 2)
                                    if channel then
                                        local rbxGeneral = channel:FindFirstChild("RBXGeneral")
                                        if rbxGeneral then
                                            rbxGeneral:SendAsync("!cancel")
                                        end
                                    end
                                end
                            end)
                            
                            -- Fallback: try workspace.VC remote
                            pcall(function()
                                local vc = workspace:FindFirstChild("VC")
                                if vc then
                                    local remote = vc:FindFirstChild("RemoteEvent")
                                    if remote then
                                        remote:FireServer("!cancel")
                                    end
                                end
                            end)
                            
                            -- Teleport to safe position or spawn
                            task.wait(0.5)
                            if lastSafePosition then
                                root.CFrame = lastSafePosition
                            else
                                -- Fallback to spawn
                                local spawn = workspace:FindFirstChild("spawn") or workspace:FindFirstChild("Spawn")
                                if spawn and spawn:FindFirstChild("HumanoidRootPart") then
                                    root.CFrame = spawn.HumanoidRootPart.CFrame + Vector3.new(0, 5, 0)
                                end
                            end
                            
                            -- Reset anti-fall flag after recovery
                            task.wait(2)
                            antiFallActive = false
                        end
                    end
                end
            end)
        end
        task.wait(0.1) -- Check every 100ms
    end
end)

-- Boss Farm Logic - ENHANCED WITH REAR TELEPORT + ANTI-FALL
task.spawn(function()
    local currentBossIndex = 1
    
    while true do
        if FarmState.AutoFarmBossEnabled and LocalPlayer.Character then
            local selectedBosses = FarmState.AutoFarmBossSelected
            if #selectedBosses == 0 then
                FarmState.BossFarmStatus = "No bosses selected"
                task.wait(1)
                continue
            end
            
            -- Cycle through bosses
            if currentBossIndex > #selectedBosses then
                currentBossIndex = 1
            end
            
            local bossName = selectedBosses[currentBossIndex]
            FarmState.BossFarmCurrent = bossName
            FarmState.BossFarmStatus = "Traveling to " .. bossName
            
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                
                if not root or not hum or hum.Health <= 0 then
                    task.wait(1)
                    return
                end
                
                -- Find boss mission folder
                local missionsFolder = workspace:FindFirstChild("bossdropmission")
                if not missionsFolder then
                    FarmState.BossFarmStatus = "bossdropmission folder not found"
                    task.wait(2)
                    return
                end
                
                local missionsSubFolder = missionsFolder:FindFirstChild("missions")
                if not missionsSubFolder then
                    FarmState.BossFarmStatus = "missions subfolder not found"
                    task.wait(2)
                    return
                end
                
                local bossFolder = missionsSubFolder:FindFirstChild(bossName)
                if not bossFolder then
                    FarmState.BossFarmStatus = "Boss folder not found: " .. bossName
                    currentBossIndex = currentBossIndex + 1
                    task.wait(2)
                    return
                end
                
                -- Find missiongiver model inside boss folder
                local missiongiver = bossFolder:FindFirstChild("missiongiver")
                if not missiongiver then
                    -- Try to find any model with HumanoidRootPart
                    for _, child in pairs(bossFolder:GetChildren()) do
                        if child:IsA("Model") and child:FindFirstChild("HumanoidRootPart") then
                            missiongiver = child
                            break
                        end
                    end
                end
                
                if not missiongiver then
                    FarmState.BossFarmStatus = "missiongiver not found in " .. bossName
                    currentBossIndex = currentBossIndex + 1
                    task.wait(2)
                    return
                end
                
                local giverRoot = missiongiver:FindFirstChild("HumanoidRootPart")
                if not giverRoot then
                    FarmState.BossFarmStatus = "HumanoidRootPart not found in missiongiver"
                    currentBossIndex = currentBossIndex + 1
                    task.wait(2)
                    return
                end
                
                -- FIXED: Teleport BEHIND & ABOVE missiongiver (not below)
                FarmState.BossFarmStatus = "Teleporting to " .. bossName .. " (safe position)"
                
                -- Calculate safe position: behind and above the giver
                local behindOffset = giverRoot.CFrame.LookVector * -8  -- 8 studs behind
                local upOffset = Vector3.new(0, 5, 0)  -- 5 studs above
                local safePosition = giverRoot.Position + behindOffset + upOffset
                local targetCFrame = CFrame.new(safePosition)
                
                local info = TweenInfo.new(
                    (safePosition - root.Position).Magnitude / FarmState.AutoFarmBossSpeed,
                    Enum.EasingStyle.Linear
                )
                local tween = TweenService:Create(root, info, {CFrame = targetCFrame})
                tween:Play()
                tween.Completed:Wait()
                
                task.wait(1)
                
                -- Try to accept quest (15 second timeout)
                FarmState.BossFarmStatus = "Trying to accept " .. bossName .. " quest..."
                local clientTalk = missiongiver:FindFirstChild("CLIENTTALK")
                local questAccepted = false
                local startTime = tick()
                
                while tick() - startTime < FarmState.AutoFarmBossTimeout do
                    if not FarmState.AutoFarmBossEnabled then break end
                    
                    -- Check if already have mission
                    local currentmission = LocalPlayer:FindFirstChild("currentmission")
                    if currentmission and currentmission.Value ~= nil and currentmission.Value ~= "" then
                        questAccepted = true
                        break
                    end
                    
                    -- Try to accept
                    if clientTalk then
                        pcall(function()
                            clientTalk:FireServer()
                            task.wait(0.3)
                            clientTalk:FireServer("accept")
                        end)
                    end
                    
                    task.wait(1)
                end
                
                if not questAccepted then
                    -- Check one more time
                    local currentmission = LocalPlayer:FindFirstChild("currentmission")
                    if currentmission and currentmission.Value ~= nil and currentmission.Value ~= "" then
                        questAccepted = true
                    end
                end
                
                if not questAccepted then
                    FarmState.BossFarmStatus = "Failed to accept " .. bossName .. " quest (timeout)"
                    currentBossIndex = currentBossIndex + 1
                    task.wait(2)
                    return
                end
                
                FarmState.BossFarmStatus = "Quest accepted! Finding NPCs..."
                task.wait(1)
                
                -- NEW LOGIC: Find ALL NPCs with "npc" in name
                local npcsFolder = workspace:FindFirstChild("npc")
                if not npcsFolder then
                    FarmState.BossFarmStatus = "npc folder not found"
                    currentBossIndex = currentBossIndex + 1
                    task.wait(2)
                    return
                end
                
                -- Collect all valid NPCs
                local npcList = {}
                for _, npc in pairs(npcsFolder:GetChildren()) do
                    if npc:IsA("Model") and string.find(npc.Name:lower(), "npc") then
                        local npcRoot = npc:FindFirstChild("HumanoidRootPart")
                        local npcHum = npc:FindFirstChild("Humanoid")
                        
                        if npcRoot and npcHum and npcHum.Health > 0 then
                            table.insert(npcList, npc)
                        end
                    end
                end
                
                if #npcList == 0 then
                    FarmState.BossFarmStatus = "No NPCs found with 'npc' in name"
                    currentBossIndex = currentBossIndex + 1
                    task.wait(2)
                    return
                end
                
                FarmState.BossFarmStatus = "Found " .. #npcList .. " NPCs. Starting kill cycle..."
                
                -- Kill each NPC in order
                for i, npc in ipairs(npcList) do
                    -- Check if boss farm is still enabled
                    if not FarmState.AutoFarmBossEnabled then break end
                    
                    -- Check if mission is still active
                    local currentmission = LocalPlayer:FindFirstChild("currentmission")
                    if not currentmission or currentmission.Value == nil or currentmission.Value == "" then
                        -- Mission completed!
                        break
                    end
                    
                    -- Check if character is still alive
                    local char2 = LocalPlayer.Character
                    local hum2 = char2 and char2:FindFirstChildOfClass("Humanoid")
                    if not hum2 or hum2.Health <= 0 then
                        break
                    end
                    
                    -- ANTI-FALL CHECK: If fell below map, skip to next boss
                    if antiFallActive then
                        FarmState.BossFarmStatus = "Anti-fall triggered! Skipping to next boss..."
                        currentBossIndex = currentBossIndex + 1
                        break
                    end
                    
                    local npcRoot = npc:FindFirstChild("HumanoidRootPart")
                    local npcHum = npc:FindFirstChild("Humanoid")
                    
                    if npcRoot and npcHum and npcHum.Health > 0 then
                        FarmState.BossFarmStatus = "Killing NPC " .. i .. "/" .. #npcList .. " (" .. npc.Name .. ")"
                        
                        -- Get current root position
                        local currentRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if not currentRoot then break end
                        
                        -- Teleport to NPC (behind and above for safety)
                        local behindNPC = npcRoot.CFrame.LookVector * -5
                        local upNPC = Vector3.new(0, 3, 0)
                        local safeNPCPos = npcRoot.Position + behindNPC + upNPC
                        local targetCF = CFrame.new(safeNPCPos)
                        
                        local info2 = TweenInfo.new(
                            (safeNPCPos - currentRoot.Position).Magnitude / FarmState.AutoFarmBossSpeed,
                            Enum.EasingStyle.Linear
                        )
                        local tween2 = TweenService:Create(currentRoot, info2, {CFrame = targetCF})
                        tween2:Play()
                        tween2.Completed:Wait()
                        
                        task.wait(0.5)
                        
                        -- Wait until NPC dies or mission completes
                        local killStartTime = tick()
                        while npcHum.Health > 0 and FarmState.AutoFarmBossEnabled do
                            -- Check if mission is still active
                            local currentmission = LocalPlayer:FindFirstChild("currentmission")
                            if not currentmission or currentmission.Value == nil or currentmission.Value == "" then
                                break -- Mission completed
                            end
                            
                            -- Check if character is still alive
                            local char3 = LocalPlayer.Character
                            local hum3 = char3 and char3:FindFirstChildOfClass("Humanoid")
                            if not hum3 or hum3.Health <= 0 then
                                break
                            end
                            
                            -- ANTI-FALL CHECK during kill loop
                            if antiFallActive then
                                break
                            end
                            
                            -- Keep teleporting to NPC (in case they move)
                            local currentRoot2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if currentRoot2 and npcRoot.Parent then
                                local behindNPC2 = npcRoot.CFrame.LookVector * -5
                                local upNPC2 = Vector3.new(0, 3, 0)
                                currentRoot2.CFrame = CFrame.new(npcRoot.Position + behindNPC2 + upNPC2)
                            end
                            
                            -- Try to kill NPC (force kill)
                            if npcHum.Health > 0 then
                                npcHum.Health = 0
                            end
                            
                            task.wait(0.5)
                            
                            -- Timeout after 30 seconds per NPC
                            if tick() - killStartTime > 30 then
                                break
                            end
                        end
                        
                        task.wait(1) -- Wait before moving to next NPC
                    end
                end
                
                -- If anti-fall was triggered, skip to next boss
                if antiFallActive then
                    currentBossIndex = currentBossIndex + 1
                    task.wait(2)
                    continue
                end
                
                -- Wait for mission to fully complete
                FarmState.BossFarmStatus = "Waiting for " .. bossName .. " mission completion..."
                local completionWait = 0
                while FarmState.AutoFarmBossEnabled and completionWait < 10 do
                    local currentmission = LocalPlayer:FindFirstChild("currentmission")
                    if not currentmission or currentmission.Value == nil or currentmission.Value == "" then
                        -- Mission completed!
                        break
                    end
                    task.wait(1)
                    completionWait = completionWait + 1
                end
                
                if FarmState.AutoFarmBossEnabled then
                    FarmState.BossFarmStatus = bossName .. " mission completed!"
                    FarmState.BossFarmCompleted = FarmState.BossFarmCompleted + 1
                    ui.Fluent:Notify({
                        Title = "[B] Boss Completed",
                        Content = bossName .. " mission finished!",
                        Duration = 3
                    })
                    task.wait(2)
                end
                
                currentBossIndex = currentBossIndex + 1
            end)
        else
            FarmState.BossFarmStatus = "Disabled"
            currentBossIndex = 1
        end
        
        task.wait(0.5)
    end
end)

-- Boss Farm Status Display
local BossStatusDisplay = Tabs.BossFarm:AddParagraph({
    Title = "Boss Farm Status",
    Content = "Initializing..."
})

task.spawn(function()
    while true do
        local selectedText = #FarmState.AutoFarmBossSelected > 0 
            and table.concat(FarmState.AutoFarmBossSelected, ", ") 
            or "None"
        
        local yPos = "N/A"
        pcall(function()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                yPos = string.format("%.0f", root.Position.Y)
            end
        end)
        
        BossStatusDisplay.Content = string.format(
            "Status: %s\n\n" ..
            "Current Boss: %s\n" ..
            "Missions Completed: %d\n" ..
            "Player Y Position: %s\n" ..
            "Anti-Fall: %s\n\n" ..
            "Selected Bosses (%d):\n%s\n\n" ..
            "Settings:\n" ..
            "- Tween Speed: %d studs/s\n" ..
            "- Timeout: %d seconds\n\n" ..
            "Note: Disable regular AutoFarm to avoid conflicts!",
            FarmState.AutoFarmBossEnabled and "[OK] ACTIVE" or "[X] INACTIVE",
            FarmState.BossFarmCurrent ~= "" and FarmState.BossFarmCurrent or "None",
            FarmState.BossFarmCompleted,
            yPos,
            antiFallActive and "[!] TRIGGERED" or "[OK] SAFE",
            #FarmState.AutoFarmBossSelected,
            selectedText,
            FarmState.AutoFarmBossSpeed,
            FarmState.AutoFarmBossTimeout
        )
        task.wait(0.5)
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
        
        task.spawn(function()
            while true do
                if FarmState.ScrollSniperEnabled and LocalPlayer.Character then
                    pcall(function()
                        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if not root then return end
                        
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
                                            task.wait(0.1)
                                            invoke:FireServer(LocalPlayer)
                                            fireclickdetector(clickDetector)
                                        end
                                    end
                                end
                            end
                        end
                        
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
                                        task.wait(0.1)
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
                                hum:ChangeState(11)
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
                                                toTarget(root.Position, npc.HumanoidRootPart.Position,
                                                    CFrame.new(npc.HumanoidRootPart.Position))
                                                task.wait(0.5)
                                                npc.Humanoid.Health = 0
                                            else
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
        -- AUTO STATS DISTRIBUTION
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
        
        Tabs.Stats:AddToggle("AutoStatsNinToggle", {Title = "Auto NIN (Ninjutsu)", Default = Config.AutoStatsNinEnabled}):OnChanged(function(v)
            FarmState.AutoStatsNinEnabled = v; Config.AutoStatsNinEnabled = v; ConfigManager.Save(Config)
        end)
        
        Tabs.Stats:AddToggle("AutoStatsTaiToggle", {Title = "Auto TAI (Taijutsu)", Default = Config.AutoStatsTaiEnabled}):OnChanged(function(v)
            FarmState.AutoStatsTaiEnabled = v; Config.AutoStatsTaiEnabled = v; ConfigManager.Save(Config)
        end)
        
        Tabs.Stats:AddToggle("AutoStatsChiToggle", {Title = "Auto CHI (Chakra)", Default = Config.AutoStatsChiEnabled}):OnChanged(function(v)
            FarmState.AutoStatsChiEnabled = v; Config.AutoStatsChiEnabled = v; ConfigManager.Save(Config)
        end)
        
        Tabs.Stats:AddToggle("AutoStatsHpToggle", {Title = "Auto HP (Health)", Default = Config.AutoStatsHpEnabled}):OnChanged(function(v)
            FarmState.AutoStatsHpEnabled = v; Config.AutoStatsHpEnabled = v; ConfigManager.Save(Config)
        end)
        
        Tabs.Stats:AddSlider("AutoStatsIntervalSlider", {
            Title = "Check Interval (seconds)", Default = Config.AutoStatsInterval,
            Min = 1, Max = 10, Rounding = 0,
            Callback = function(v) Config.AutoStatsInterval = v; ConfigManager.Save(Config) end
        })
        
        Tabs.Stats:AddSlider("AutoStatsMinPointsSlider", {
            Title = "Minimum Points to Spend", Default = Config.AutoStatsMinPoints,
            Min = 1, Max = 50, Rounding = 0,
            Callback = function(v) Config.AutoStatsMinPoints = v; ConfigManager.Save(Config) end
        })
        
        Tabs.Stats:AddButton({Title = "Add All Points to NIN", Callback = function()
            local points = getStatPoints()
            if points > 0 then
                local ok = addStat("ninjutsu", points)
                ui.Fluent:Notify({Title = ok and "[OK]" or "[X]", Content = ok and "Added " .. points .. " to NIN" or "Failed", Duration = 3})
            else
                ui.Fluent:Notify({Title = "[!]", Content = "No points", Duration = 2})
            end
        end})
        
        Tabs.Stats:AddButton({Title = "Add All Points to TAI", Callback = function()
            local points = getStatPoints()
            if points > 0 then
                local ok = addStat("taijutsu", points)
                ui.Fluent:Notify({Title = ok and "[OK]" or "[X]", Content = ok and "Added " .. points .. " to TAI" or "Failed", Duration = 3})
            end
        end})
        
        Tabs.Stats:AddButton({Title = "Add All Points to CHI", Callback = function()
            local points = getStatPoints()
            if points > 0 then
                local ok = addStat("chakra", points)
                ui.Fluent:Notify({Title = ok and "[OK]" or "[X]", Content = ok and "Added " .. points .. " to CHI" or "Failed", Duration = 3})
            end
        end})
        
        Tabs.Stats:AddButton({Title = "Add All Points to HP", Callback = function()
            local points = getStatPoints()
            if points > 0 then
                local ok = addStat("health", points)
                ui.Fluent:Notify({Title = ok and "[OK]" or "[X]", Content = ok and "Added " .. points .. " to HP" or "Failed", Duration = 3})
            end
        end})
        
        task.spawn(function()
            while true do
                if FarmState.AutoStatsEnabled then
                    pcall(function()
                        local points = getStatPoints()
                        if points >= (Config.AutoStatsMinPoints or 5) then
                            local statsToDistribute = {}
                            if FarmState.AutoStatsNinEnabled then table.insert(statsToDistribute, "ninjutsu") end
                            if FarmState.AutoStatsTaiEnabled then table.insert(statsToDistribute, "taijutsu") end
                            if FarmState.AutoStatsChiEnabled then table.insert(statsToDistribute, "chakra") end
                            if FarmState.AutoStatsHpEnabled then table.insert(statsToDistribute, "health") end
                            
                            if #statsToDistribute > 0 then
                                local pointsPerStat = math.floor(points / #statsToDistribute)
                                for _, statName in ipairs(statsToDistribute) do
                                    if pointsPerStat > 0 then
                                        local ok = addStat(statName, pointsPerStat)
                                        if ok then
                                            FarmState.StatsAdded[statName] = (FarmState.StatsAdded[statName] or 0) + pointsPerStat
                                        end
                                        task.wait(0.2)
                                    end
                                end
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
        
        local StatsStatusDisplay = Tabs.Stats:AddParagraph({Title = "Stats Status", Content = "Initializing..."})
        task.spawn(function()
            while true do
                local points = getStatPoints()
                local ninLvl = getStatLevel("ninjutsu")
                local taiLvl = getStatLevel("taijutsu")
                local chiLvl = getStatLevel("chakra")
                local hpLvl = getStatLevel("health")
                
                StatsStatusDisplay.Content = string.format(
                    "Status: %s\n\nAvailable Points: %d\nMin to Spend: %d\nCheck Interval: %ds\n\nCurrent Levels:\n- NIN: %d (+%d)\n- TAI: %d (+%d)\n- CHI: %d (+%d)\n- HP: %d (+%d)\n\nEnabled: NIN:%s TAI:%s CHI:%s HP:%s",
                    FarmState.AutoStatsEnabled and "[OK]" or "[X]",
                    points, Config.AutoStatsMinPoints, Config.AutoStatsInterval,
                    ninLvl, FarmState.StatsAdded.ninjutsu or 0,
                    taiLvl, FarmState.StatsAdded.taijutsu or 0,
                    chiLvl, FarmState.StatsAdded.chakra or 0,
                    hpLvl, FarmState.StatsAdded.health or 0,
                    FarmState.AutoStatsNinEnabled and "Y" or "N",
                    FarmState.AutoStatsTaiEnabled and "Y" or "N",
                    FarmState.AutoStatsChiEnabled and "Y" or "N",
                    FarmState.AutoStatsHpEnabled and "Y" or "N"
                )
                task.wait(1)
            end
        end)
        
        -- ==========================================
        -- AUTO SKILL SPAMMER
        -- ==========================================
        Tabs.Skills:AddParagraph({
            Title = "[K] Auto Skill Spammer",
            Content = "Automatically spam skill keys (R,T,Y,F,G,H,V,B,N,Q,E).\n\n- Each key can be enabled/disabled independently\n- Adjustable spam speed (cooldown between presses)\n- Fires 'key' then 'keyend' to simulate hold+release\n- Useful for spamming jutsu/moves repeatedly"
        })
        
        Tabs.Skills:AddSlider("AutoSkillSpamSpeedSlider", {
            Title = "Spam Speed (seconds)", Default = Config.AutoSkillSpamSpeed,
            Min = 0.05, Max = 2.0, Rounding = 2,
            Callback = function(v) FarmState.AutoSkillSpamSpeed = v; Config.AutoSkillSpamSpeed = v; ConfigManager.Save(Config) end
        })
        
        local function createSkillToggle(keyName, upperKey)
            local toggleName = "AutoSkill" .. upperKey .. "Toggle"
            Tabs.Skills:AddToggle(toggleName, {
                Title = "Spam " .. upperKey .. " Key",
                Default = Config[toggleName:gsub("Toggle", "Enabled")]
            }):OnChanged(function(v)
                FarmState[toggleName:gsub("Toggle", "Enabled")] = v
                Config[toggleName:gsub("Toggle", "Enabled")] = v
                ConfigManager.Save(Config)
            end)
        end
        
        createSkillToggle("r", "R"); createSkillToggle("t", "T"); createSkillToggle("y", "Y")
        createSkillToggle("f", "F"); createSkillToggle("g", "G"); createSkillToggle("h", "H")
        createSkillToggle("v", "V"); createSkillToggle("b", "B"); createSkillToggle("n", "N")
        createSkillToggle("q", "Q"); createSkillToggle("e", "E")
        
        Tabs.Skills:AddButton({Title = "Enable All Skills", Callback = function()
            local keys = {"R", "T", "Y", "F", "G", "H", "V", "B", "N", "Q", "E"}
            for _, key in ipairs(keys) do
                FarmState["AutoSkill" .. key .. "Enabled"] = true
                Config["AutoSkill" .. key .. "Enabled"] = true
            end
            ConfigManager.Save(Config)
            ui.Fluent:Notify({Title = "[K] All Skills Enabled", Content = "All activated", Duration = 2})
        end})
        
        Tabs.Skills:AddButton({Title = "Disable All Skills", Callback = function()
            local keys = {"R", "T", "Y", "F", "G", "H", "V", "B", "N", "Q", "E"}
            for _, key in ipairs(keys) do
                FarmState["AutoSkill" .. key .. "Enabled"] = false
                Config["AutoSkill" .. key .. "Enabled"] = false
            end
            ConfigManager.Save(Config)
            ui.Fluent:Notify({Title = "[K] All Skills Disabled", Content = "All deactivated", Duration = 2})
        end})
        
        local function createSkillSpammer(keyName, upperKey)
            task.spawn(function()
                while true do
                    if FarmState["AutoSkill" .. upperKey .. "Enabled"] and LocalPlayer.Character then
                        pcall(function()
                            local char = LocalPlayer.Character
                            local combat = char:FindFirstChild("combat")
                            if combat then
                                combat.update:FireServer("key", keyName)
                                task.wait(FarmState.AutoSkillSpamSpeed or 0.2)
                                combat.update:FireServer("key", keyName .. "end")
                                FarmState.SkillStats[keyName] = (FarmState.SkillStats[keyName] or 0) + 1
                            end
                        end)
                    end
                    task.wait(FarmState.AutoSkillSpamSpeed or 0.2)
                end
            end)
        end
        
        createSkillSpammer("r", "R"); createSkillSpammer("t", "T"); createSkillSpammer("y", "Y")
        createSkillSpammer("f", "F"); createSkillSpammer("g", "G"); createSkillSpammer("h", "H")
        createSkillSpammer("v", "V"); createSkillSpammer("b", "B"); createSkillSpammer("n", "N")
        createSkillSpammer("q", "Q"); createSkillSpammer("e", "E")
        
        local SkillStatusDisplay = Tabs.Skills:AddParagraph({Title = "Skill Spammer Status", Content = "Initializing..."})
        task.spawn(function()
            while true do
                local activeSkills = {}
                local keys = {"r", "t", "y", "f", "g", "h", "v", "b", "n", "q", "e"}
                local upperKeys = {"R", "T", "Y", "F", "G", "H", "V", "B", "N", "Q", "E"}
                for i, key in ipairs(keys) do
                    if FarmState["AutoSkill" .. upperKeys[i] .. "Enabled"] then
                        table.insert(activeSkills, upperKeys[i] .. ":" .. (FarmState.SkillStats[key] or 0))
                    end
                end
                local activeText = #activeSkills > 0 and table.concat(activeSkills, ", ") or "None"
                SkillStatusDisplay.Content = string.format(
                    "Status: %s\n\nSpam Speed: %.2fs\nActive: %d / 11\n\n%s",
                    #activeSkills > 0 and "[OK]" or "[X]",
                    FarmState.AutoSkillSpamSpeed, #activeSkills, activeText
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
            Title = "Enable Auto Chakra", Default = Config.AutoChakraEnabled
        }):OnChanged(function(v)
            FarmState.AutoChakraEnabled = v; Config.AutoChakraEnabled = v; ConfigManager.Save(Config)
        end)
        
        Tabs.Chakra:AddSlider("ChakraThresholdSlider", {
            Title = "Charge Threshold", Default = Config.AutoChakraThreshold,
            Min = 30000, Max = 250000, Rounding = 0,
            Callback = function(v) FarmState.ChakraThreshold = v; Config.AutoChakraThreshold = v; ConfigManager.Save(Config) end
        })
        
        task.spawn(function()
            while true do
                if FarmState.AutoChakraEnabled and LocalPlayer.Character then
                    pcall(function()
                        local char = LocalPlayer.Character
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then
                            local chakraGui = LocalPlayer.PlayerGui:FindFirstChild("Main") 
                                and LocalPlayer.PlayerGui.Main:FindFirstChild("ingamearena")
                                and LocalPlayer.PlayerGui.Main.ingamearena:FindFirstChild("Bar")
                                and LocalPlayer.PlayerGui.Main.ingamearena.Bar:FindFirstChild("cha")
                            
                            if chakraGui and chakraGui.Text then
                                local chakraText = chakraGui.Text
                                local chakraValue = tonumber(string.match(chakraText, "CHA: (%d+)"))
                                if chakraValue then
                                    if chakraValue < FarmState.ChakraThreshold then
                                        char.combat.update:FireServer("key", "c")
                                    else
                                        char.combat.update:FireServer("key", "cend")
                                    end
                                end
                            end
                            if hum.WalkSpeed == 0 then hum.WalkSpeed = 50 end
                        end
                    end)
                end
                task.wait(0.5)
            end
        end)
        
        -- ==========================================
        -- EXPERIMENTAL FEATURES
        -- ==========================================
        Tabs.Experimental:AddParagraph({
            Title = "[X] EXPERIMENTAL FEATURES",
            Content = "WARNING: These features are experimental and may cause:\n- Server detection / kicks\n- Visual glitches\n- Performance issues\n\nUse at your own risk in private servers!"
        })
        
        -- KILL AURA SECTION - ULTRA FAST FORCE KILL
        Tabs.Experimental:AddSection("KillAura (ULTRA FAST FORCE KILL)")
        
        Tabs.Experimental:AddToggle("KillAuraToggle", {
            Title = "Enable KillAura",
            Description = "ULTRA FAST: Instantly sets Health=0 on ALL nearby Humanoids",
            Default = Config.KillAuraEnabled
        }):OnChanged(function(v)
            FarmState.KillAuraEnabled = v
            Config.KillAuraEnabled = v
            ConfigManager.Save(Config)
            if v then
                ui.Fluent:Notify({
                    Title = "[X] KillAura ACTIVATED",
                    Content = "Ultra-fast force-kill mode enabled!",
                    Duration = 3
                })
            end
        end)
        
        Tabs.Experimental:AddSlider("KillAuraRangeSlider", {
            Title = "KillAura Range (studs)",
            Description = "Maximum distance to target enemies (default: 500)",
            Default = Config.KillAuraRange,
            Min = 50, Max = 1000, Rounding = 0,
            Callback = function(v)
                FarmState.KillAuraRange = v
                Config.KillAuraRange = v
                ConfigManager.Save(Config)
            end
        })
        
        Tabs.Experimental:AddSlider("KillAuraSpeedSlider", {
            Title = "KillAura Speed (seconds)",
            Description = "Time between kill cycles. Lower = more aggressive (min: 0.01s)",
            Default = Config.KillAuraSpeed,
            Min = 0.01, Max = 0.5, Rounding = 2,
            Callback = function(v)
                FarmState.KillAuraSpeed = v
                Config.KillAuraSpeed = v
                ConfigManager.Save(Config)
            end
        })
        
        Tabs.Experimental:AddToggle("KillAuraNPCToggle", {
            Title = "Target ALL NPCs",
            Description = "Kill all NPCs in range (missions, bosses, training)",
            Default = Config.KillAuraTargetNPCs
        }):OnChanged(function(v)
            FarmState.KillAuraTargetNPCs = v
            Config.KillAuraTargetNPCs = v
            ConfigManager.Save(Config)
        end)
        
        Tabs.Experimental:AddToggle("KillAuraPlayerToggle", {
            Title = "Target Players (PVP)",
            Description = "Kill other players in range",
            Default = Config.KillAuraTargetPlayers
        }):OnChanged(function(v)
            FarmState.KillAuraTargetPlayers = v
            Config.KillAuraTargetPlayers = v
            ConfigManager.Save(Config)
        end)
        
        Tabs.Experimental:AddToggle("KillAuraForceKillToggle", {
            Title = "Force Kill Mode (REQUIRED)",
            Description = "Directly set Health=0 (bypasses combat system)",
            Default = Config.KillAuraForceKill
        }):OnChanged(function(v)
            FarmState.KillAuraForceKill = v
            Config.KillAuraForceKill = v
            ConfigManager.Save(Config)
        end)
        
        Tabs.Experimental:AddParagraph({
            Title = "KillAura Info",
            Content = "ULTRA FAST MODE:\n- Scans ALL Humanoids in workspace (not just npc folder)\n- 0.01 second cycle (100 kills/sec potential)\n- 500 stud default range\n- Force kill sets Health=0 directly\n- No M1 attacks, no cooldowns\n\nWARNING: Very detectable! Use only in private servers!"
        })
        
        -- KILL AURA LOGIC - ULTRA FAST AGGRESSIVE FORCE KILL
        task.spawn(function()
            while true do
                if FarmState.KillAuraEnabled and LocalPlayer.Character then
                    pcall(function()
                        local char = LocalPlayer.Character
                        local root = char:FindFirstChild("HumanoidRootPart")
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        
                        if root and hum and hum.Health > 0 then
                            local killCount = 0
                            
                            -- SCAN ALL HUMANOIDs IN WORKSPACE (not just npc folder)
                            if FarmState.KillAuraTargetNPCs then
                                -- Scan workspace.npc folder
                                local npcs = workspace:FindFirstChild("npc")
                                if npcs then
                                    for _, npc in pairs(npcs:GetChildren()) do
                                        if npc:IsA("Model") then
                                            local npcRoot = npc:FindFirstChild("HumanoidRootPart")
                                            local npcHum = npc:FindFirstChildOfClass("Humanoid")
                                            
                                            if npcRoot and npcHum and npcHum.Health > 0 then
                                                local dist = (root.Position - npcRoot.Position).Magnitude
                                                
                                                if dist <= FarmState.KillAuraRange then
                                                    if FarmState.KillAuraForceKill then
                                                        npcHum.Health = 0
                                                        killCount = killCount + 1
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                                
                                -- Also scan workspace.bossdropmission for bosses
                                local bossFolder = workspace:FindFirstChild("bossdropmission")
                                if bossFolder then
                                    for _, descendant in pairs(bossFolder:GetDescendants()) do
                                        if descendant:IsA("Humanoid") and descendant.Health > 0 then
                                            local model = descendant.Parent
                                            if model and model:IsA("Model") then
                                                local modelRoot = model:FindFirstChild("HumanoidRootPart")
                                                if modelRoot then
                                                    local dist = (root.Position - modelRoot.Position).Magnitude
                                                    if dist <= FarmState.KillAuraRange then
                                                        if FarmState.KillAuraForceKill then
                                                            descendant.Health = 0
                                                            killCount = killCount + 1
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                                
                                -- Scan workspace for any stray Humanoids
                                for _, obj in pairs(workspace:GetChildren()) do
                                    if obj:IsA("Model") and obj ~= char then
                                        local objRoot = obj:FindFirstChild("HumanoidRootPart")
                                        local objHum = obj:FindFirstChildOfClass("Humanoid")
                                        
                                        if objRoot and objHum and objHum.Health > 0 then
                                            -- Skip players if not targeting them
                                            local isPlayer = Players:GetPlayerFromCharacter(obj) ~= nil
                                            if not isPlayer then
                                                local dist = (root.Position - objRoot.Position).Magnitude
                                                if dist <= FarmState.KillAuraRange then
                                                    if FarmState.KillAuraForceKill then
                                                        objHum.Health = 0
                                                        killCount = killCount + 1
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            
                            -- KILL ALL PLAYERS IN RANGE
                            if FarmState.KillAuraTargetPlayers then
                                for _, player in pairs(Players:GetPlayers()) do
                                    if player ~= LocalPlayer and player.Character then
                                        local playerRoot = player.Character:FindFirstChild("HumanoidRootPart")
                                        local playerHum = player.Character:FindFirstChildOfClass("Humanoid")
                                        
                                        if playerRoot and playerHum and playerHum.Health > 0 then
                                            local dist = (root.Position - playerRoot.Position).Magnitude
                                            
                                            if dist <= FarmState.KillAuraRange then
                                                if FarmState.KillAuraForceKill then
                                                    playerHum.Health = 0
                                                    killCount = killCount + 1
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            
                            FarmState.KillAuraKills = FarmState.KillAuraKills + killCount
                        end
                    end)
                end
                task.wait(FarmState.KillAuraSpeed or 0.01)
            end
        end)
        
        -- ANTI RAGDOLL SECTION
        Tabs.Experimental:AddSection("Anti Ragdoll")
        
        Tabs.Experimental:AddToggle("AntiRagdollToggle", {
            Title = "Enable Anti Ragdoll",
            Description = "Prevents character from going into ragdoll state",
            Default = Config.AntiRagdollEnabled
        }):OnChanged(function(v)
            FarmState.AntiRagdollEnabled = v
            Config.AntiRagdollEnabled = v
            ConfigManager.Save(Config)
        end)
        
        task.spawn(function()
            while true do
                if FarmState.AntiRagdollEnabled and LocalPlayer.Character then
                    pcall(function()
                        local char = LocalPlayer.Character
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then
                            local state = hum:GetState()
                            if state == Enum.HumanoidStateType.Physics 
                                or state == Enum.HumanoidStateType.Ragdoll
                                or state == Enum.HumanoidStateType.FallingDown then
                                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                                task.wait(0.1)
                                hum:ChangeState(Enum.HumanoidStateType.Running)
                            end
                            local ragdoll = char:GetAttribute("Ragdoll")
                            if ragdoll and ragdoll ~= 0 then
                                char:SetAttribute("Ragdoll", 0)
                            end
                        end
                    end)
                end
                task.wait(0.1)
            end
        end)
        
        -- ANTI KNOCKBACK SECTION
        Tabs.Experimental:AddSection("Anti Knockback")
        
        Tabs.Experimental:AddToggle("AntiKnockbackToggle", {
            Title = "Enable Anti Knockback",
            Description = "Prevents character from being pushed/knocked back",
            Default = Config.AntiKnockbackEnabled
        }):OnChanged(function(v)
            FarmState.AntiKnockbackEnabled = v
            Config.AntiKnockbackEnabled = v
            ConfigManager.Save(Config)
        end)
        
        task.spawn(function()
            while true do
                if FarmState.AntiKnockbackEnabled and LocalPlayer.Character then
                    pcall(function()
                        local char = LocalPlayer.Character
                        local root = char:FindFirstChild("HumanoidRootPart")
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        
                        if root and hum and hum.Health > 0 then
                            for _, v in pairs(char:GetDescendants()) do
                                if v:IsA("BodyVelocity") and v.Name ~= "AntiKB" then
                                    pcall(function() v:Destroy() end)
                                elseif v:IsA("BodyForce") then
                                    pcall(function() v:Destroy() end)
                                elseif v:IsA("BodyThrust") then
                                    pcall(function() v:Destroy() end)
                                end
                            end
                            
                            local vel = root.AssemblyLinearVelocity
                            if vel.Magnitude > 100 then
                                root.AssemblyLinearVelocity = Vector3.new(vel.X * 0.1, vel.Y, vel.Z * 0.1)
                            end
                        end
                    end)
                end
                task.wait(0.05)
            end
        end)
        
        -- ESP SECTION
        Tabs.Experimental:AddSection("ESP (Extra Sensory Perception)")
        
        Tabs.Experimental:AddToggle("ESPToggle", {
            Title = "Enable ESP", Default = Config.ESPEnabled
        }):OnChanged(function(v)
            FarmState.ESPEnabled = v; Config.ESPEnabled = v; ConfigManager.Save(Config)
        end)
        
        Tabs.Experimental:AddToggle("ESPNamesToggle", {
            Title = "Show Names", Default = Config.ESPShowNames
        }):OnChanged(function(v)
            FarmState.ESPShowNames = v; Config.ESPShowNames = v; ConfigManager.Save(Config)
        end)
        
        Tabs.Experimental:AddToggle("ESPDistanceToggle", {
            Title = "Show Distance", Default = Config.ESPShowDistance
        }):OnChanged(function(v)
            FarmState.ESPShowDistance = v; Config.ESPShowDistance = v; ConfigManager.Save(Config)
        end)
        
        Tabs.Experimental:AddToggle("ESPHealthToggle", {
            Title = "Show Health", Default = Config.ESPShowHealth
        }):OnChanged(function(v)
            FarmState.ESPShowHealth = v; Config.ESPShowHealth = v; ConfigManager.Save(Config)
        end)
        
        Tabs.Experimental:AddSlider("ESPRangeSlider", {
            Title = "ESP Max Distance (studs)", Default = Config.ESPMaxDistance,
            Min = 50, Max = 2000, Rounding = 0,
            Callback = function(v) FarmState.ESPMaxDistance = v; Config.ESPMaxDistance = v; ConfigManager.Save(Config) end
        })
        
        Tabs.Experimental:AddColorpicker("ESPFillColorPicker", {
            Title = "ESP Fill Color", Default = FarmState.ESPFillColor
        }):OnChanged(function(color)
            FarmState.ESPFillColor = color
            Config.ESPFillColor = {R = math.floor(color.R * 255), G = math.floor(color.G * 255), B = math.floor(color.B * 255)}
            ConfigManager.Save(Config)
        end)
        
        Tabs.Experimental:AddColorpicker("ESPOutlineColorPicker", {
            Title = "ESP Outline Color", Default = FarmState.ESPOutlineColor
        }):OnChanged(function(color)
            FarmState.ESPOutlineColor = color
            Config.ESPOutlineColor = {R = math.floor(color.R * 255), G = math.floor(color.G * 255), B = math.floor(color.B * 255)}
            ConfigManager.Save(Config)
        end)
        
        -- ESP Storage
        local ESPHighlights = {}
        local ESPBillboards = {}
        
        local function createESPForPlayer(player)
            if player == LocalPlayer then return end
            if not player.Character then return end
            
            if ESPHighlights[player] then
                pcall(function() ESPHighlights[player]:Destroy() end)
                ESPHighlights[player] = nil
            end
            if ESPBillboards[player] then
                pcall(function() ESPBillboards[player]:Destroy() end)
                ESPBillboards[player] = nil
            end
            
            local highlight = Instance.new("Highlight")
            highlight.Name = "GlockESP"
            highlight.FillColor = FarmState.ESPFillColor
            highlight.FillTransparency = 0.7
            highlight.OutlineColor = FarmState.ESPOutlineColor
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Adornee = player.Character
            highlight.Parent = player.Character
            
            local getUI = gethui or function() return game:GetService("CoreGui") end
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "GlockESP_Billboard"
            billboard.Adornee = player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
            billboard.Size = UDim2.new(0, 200, 0, 80)
            billboard.StudsOffset = Vector3.new(0, 3, 0)
            billboard.AlwaysOnTop = true
            billboard.LightInfluence = 0
            billboard.ResetOnSpawn = false
            
            pcall(function() billboard.Parent = getUI() end)
            if not billboard.Parent then
                billboard.Parent = LocalPlayer:WaitForChild("PlayerGui")
            end
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "NameLabel"
            nameLabel.Size = UDim2.new(1, 0, 0, 20)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = player.DisplayName or player.Name
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 14
            nameLabel.TextStrokeTransparency = 0
            nameLabel.Parent = billboard
            
            local distLabel = Instance.new("TextLabel")
            distLabel.Name = "DistLabel"
            distLabel.Size = UDim2.new(1, 0, 0, 16)
            distLabel.Position = UDim2.new(0, 0, 0, 20)
            distLabel.BackgroundTransparency = 1
            distLabel.Text = "0m"
            distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            distLabel.Font = Enum.Font.Gotham
            distLabel.TextSize = 12
            distLabel.TextStrokeTransparency = 0
            distLabel.Parent = billboard
            
            local healthLabel = Instance.new("TextLabel")
            healthLabel.Name = "HealthLabel"
            healthLabel.Size = UDim2.new(1, 0, 0, 16)
            healthLabel.Position = UDim2.new(0, 0, 0, 36)
            healthLabel.BackgroundTransparency = 1
            healthLabel.Text = "100 HP"
            healthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            healthLabel.Font = Enum.Font.Gotham
            healthLabel.TextSize = 12
            healthLabel.TextStrokeTransparency = 0
            healthLabel.Parent = billboard
            
            ESPHighlights[player] = highlight
            ESPBillboards[player] = billboard
            
            highlight.Enabled = FarmState.ESPEnabled
            billboard.Enabled = FarmState.ESPEnabled
            nameLabel.Visible = FarmState.ESPShowNames
            distLabel.Visible = FarmState.ESPShowDistance
            healthLabel.Visible = FarmState.ESPShowHealth
        end
        
        local function removeESPForPlayer(player)
            if ESPHighlights[player] then
                pcall(function() ESPHighlights[player]:Destroy() end)
                ESPHighlights[player] = nil
            end
            if ESPBillboards[player] then
                pcall(function() ESPBillboards[player]:Destroy() end)
                ESPBillboards[player] = nil
            end
        end
        
        task.spawn(function()
            while true do
                if FarmState.ESPEnabled then
                    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    
                    for player, highlight in pairs(ESPHighlights) do
                        if not player or not player.Parent then
                            removeESPForPlayer(player)
                        else
                            local char = player.Character
                            local root = char and char:FindFirstChild("HumanoidRootPart")
                            local hum = char and char:FindFirstChildOfClass("Humanoid")
                            local billboard = ESPBillboards[player]
                            
                            if char and root and hum then
                                local distance = myRoot and (myRoot.Position - root.Position).Magnitude or 0
                                
                                highlight.Enabled = distance <= FarmState.ESPMaxDistance
                                if billboard then
                                    billboard.Enabled = distance <= FarmState.ESPMaxDistance
                                    
                                    local nameLabel = billboard:FindFirstChild("NameLabel")
                                    local distLabel = billboard:FindFirstChild("DistLabel")
                                    local healthLabel = billboard:FindFirstChild("HealthLabel")
                                    
                                    if nameLabel then
                                        nameLabel.Visible = FarmState.ESPShowNames
                                        nameLabel.Text = player.DisplayName or player.Name
                                    end
                                    if distLabel then
                                        distLabel.Visible = FarmState.ESPShowDistance
                                        distLabel.Text = string.format("[%.0fm]", distance)
                                    end
                                    if healthLabel then
                                        healthLabel.Visible = FarmState.ESPShowHealth
                                        healthLabel.Text = string.format("%.0f/%.0f HP", hum.Health, hum.MaxHealth)
                                        
                                        local healthPercent = hum.Health / hum.MaxHealth
                                        if healthPercent > 0.5 then
                                            healthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                                        elseif healthPercent > 0.25 then
                                            healthLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                                        else
                                            healthLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                                        end
                                    end
                                end
                                
                                highlight.FillColor = FarmState.ESPFillColor
                                highlight.OutlineColor = FarmState.ESPOutlineColor
                            else
                                highlight.Enabled = false
                                if billboard then billboard.Enabled = false end
                            end
                        end
                    end
                else
                    for player, highlight in pairs(ESPHighlights) do
                        highlight.Enabled = false
                        local billboard = ESPBillboards[player]
                        if billboard then billboard.Enabled = false end
                    end
                end
                task.wait(0.1)
            end
        end)
        
        Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function()
                task.wait(0.5)
                if FarmState.ESPEnabled then createESPForPlayer(player) end
            end)
            if player.Character and FarmState.ESPEnabled then createESPForPlayer(player) end
        end)
        
        Players.PlayerRemoving:Connect(function(player) removeESPForPlayer(player) end)
        
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character and FarmState.ESPEnabled then createESPForPlayer(player) end
        end
        
        -- STUN/GRAB IMMUNITY SECTION
        Tabs.Experimental:AddSection("Stun/Grab Immunity")
        
        Tabs.Experimental:AddToggle("StunGrabImmunityToggle", {
            Title = "Enable Stun/Grab Immunity",
            Description = "Prevents being stunned, grabbed, or held by enemies",
            Default = Config.StunGrabImmunityEnabled
        }):OnChanged(function(v)
            FarmState.StunGrabImmunityEnabled = v
            Config.StunGrabImmunityEnabled = v
            ConfigManager.Save(Config)
        end)
        
        task.spawn(function()
            while true do
                if FarmState.StunGrabImmunityEnabled and LocalPlayer.Character then
                    pcall(function()
                        local char = LocalPlayer.Character
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        local root = char:FindFirstChild("HumanoidRootPart")
                        
                        if char and hum and root and hum.Health > 0 then
                            local stunObjects = {"Stun", "Grab", "Grabbed", "Hold", "Carry", "Knockback", "Ragdoll"}
                            for _, objName in ipairs(stunObjects) do
                                local obj = char:FindFirstChild(objName)
                                if obj then pcall(function() obj:Destroy() end) end
                            end
                            
                            local stunAttrs = {"Stunned", "Grabbed", "Held", "Ragdoll", "Knockback"}
                            for _, attrName in ipairs(stunAttrs) do
                                local val = char:GetAttribute(attrName)
                                if val and val ~= 0 and val ~= false then
                                    char:SetAttribute(attrName, 0)
                                end
                            end
                            
                            local state = hum:GetState()
                            if state == Enum.HumanoidStateType.Physics 
                                or state == Enum.HumanoidStateType.Ragdoll
                                or state == Enum.HumanoidStateType.FallingDown
                                or state == Enum.HumanoidStateType.PlatformStanding then
                                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                                task.wait(0.05)
                                hum:ChangeState(Enum.HumanoidStateType.Running)
                            end
                            
                            if not hum.AutoRotate then hum.AutoRotate = true end
                            
                            for _, v in pairs(char:GetDescendants()) do
                                if v:IsA("Weld") or v:IsA("WeldConstraint") then
                                    local p0, p1 = v.Part0, v.Part1
                                    if p0 and p1 then
                                        local p0Char = p0:FindFirstAncestorOfClass("Model")
                                        local p1Char = p1:FindFirstAncestorOfClass("Model")
                                        if p0Char ~= char and p1Char ~= char then
                                            pcall(function() v:Destroy() end)
                                        end
                                    end
                                end
                            end
                        end
                    end)
                end
                task.wait(0.05)
            end
        end)
        
        -- EXPERIMENTAL STATUS DISPLAY
        local ExperimentalStatusDisplay = Tabs.Experimental:AddParagraph({
            Title = "Experimental Features Status",
            Content = "Initializing..."
        })
        
        task.spawn(function()
            while true do
                local activeFeatures = {}
                if FarmState.KillAuraEnabled then table.insert(activeFeatures, "KillAura") end
                if FarmState.AntiRagdollEnabled then table.insert(activeFeatures, "AntiRagdoll") end
                if FarmState.AntiKnockbackEnabled then table.insert(activeFeatures, "AntiKnockback") end
                if FarmState.ESPEnabled then table.insert(activeFeatures, "ESP") end
                if FarmState.StunGrabImmunityEnabled then table.insert(activeFeatures, "StunImmunity") end
                
                local activeText = #activeFeatures > 0 and table.concat(activeFeatures, ", ") or "None"
                
                ExperimentalStatusDisplay.Content = string.format(
                    "Active Features: %d / 5\n\n%s\n\nKillAura Stats:\n- Range: %d studs\n- Speed: %.2fs\n- Kills: %d\n- Force Kill: %s\n- Target NPCs: %s\n- Target Players: %s\n\nESP Stats:\n- Max Range: %d studs\n- Players Tracked: %d",
                    #activeFeatures, activeText,
                    FarmState.KillAuraRange, FarmState.KillAuraSpeed, FarmState.KillAuraKills,
                    FarmState.KillAuraForceKill and "YES" or "NO",
                    FarmState.KillAuraTargetNPCs and "YES" or "NO",
                    FarmState.KillAuraTargetPlayers and "YES" or "NO",
                    FarmState.ESPMaxDistance,
                    (function() local count = 0; for _ in pairs(ESPHighlights) do count = count + 1 end; return count end)()
                )
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
        
        LocalPlayer.CharacterAdded:Connect(function(char)
            char:WaitForChild("HumanoidRootPart")
            task.wait(3)
            if char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = Config.WalkSpeed
                char.Humanoid.JumpHeight = Config.JumpHeight
                char.Humanoid.UseJumpPower = false
                
                if FarmState.GodModeEnabled then
                    char.Humanoid.Health = char.Humanoid.MaxHealth
                    local fakehealth = char:FindFirstChild("fakehealth")
                    if fakehealth then fakehealth.Value = FarmState.FakeHealthValue end
                end
            end
            currentTargetNPC = nil
            
            if FarmState.ESPEnabled then
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        createESPForPlayer(player)
                    end
                end
            end
        end)
        
        ui.Window:SelectTab(1)
        ui.Fluent:Notify({
            Title = "GlockreisHub",
            Content = "Loaded: Shindo Life In-Game (Enhanced + Boss NPC Cycle + Ultra KillAura)",
            Duration = 5
        })
    end
end
