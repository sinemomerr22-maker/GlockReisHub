-- // ==========================================
-- // GLOCKREISHUB - SHINDO LIFE MODULE (ENHANCED)
-- // AutoFarm M1 + Auto Stats + Godmode + Position Control
-- // Continuous Facing + Underground Attack + Auto Skill Spammer
-- // Mission Protection + InstaKill (M1 Spam + Local Force Kill) 
-- // Travel (All Maps) + Experimental (No Dash CD, Auto QTE, Nanami Ratio)
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
    local VIM = game:GetService("VirtualInputManager")
    
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
            AutoSkillREnabled = false, AutoSkillTEnabled = false,
            AutoSkillYEnabled = false, AutoSkillFEnabled = false,
            AutoSkillGEnabled = false, AutoSkillHEnabled = false,
            AutoSkillVEnabled = false, AutoSkillBEnabled = false,
            AutoSkillNEnabled = false, AutoSkillQEnabled = false,
            AutoSkillEEnabled = false, AutoSkillSpamSpeed = 0.2,
            -- InstaKill Config
            InstaKillEnabled = false,
            InstaKillRange = 60,
            InstaKillSpeed = 0.003,
            InstaKillTargetNPCs = true,
            InstaKillTargetPlayers = true,
            InstaKillFaceTarget = true,
            InstaKillTeleportToTarget = false,
            -- Experimental Config
            AntiRagdollEnabled = false,
            AntiKnockbackEnabled = false,
            ESPEnabled = false,
            ESPShowNames = true,
            ESPShowDistance = true,
            ESPShowHealth = true,
            ESPMaxDistance = 500,
            ESPFillColor = {R = 255, G = 0, B = 0},
            ESPOutlineColor = {R = 255, G = 255, B = 0},
            StunGrabImmunityEnabled = false,
            NoDashCooldownEnabled = false,
            AutoQTEEnabled = false,
            AutoNanamiEnabled = false
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
        Tabs.Godmode = ui.Window:AddTab({ Title = "Godmode", Icon = "shield" })
        Tabs.InstaKill = ui.Window:AddTab({ Title = "InstaKill", Icon = "crosshair" })
        Tabs.Scroll = ui.Window:AddTab({ Title = "Scroll Sniper", Icon = "book" })
        Tabs.War = ui.Window:AddTab({ Title = "War Farm", Icon = "shield" })
        Tabs.Quests = ui.Window:AddTab({ Title = "Quest Maker", Icon = "list" })
        Tabs.Stats = ui.Window:AddTab({ Title = "Auto Stats", Icon = "trending-up" })
        Tabs.Skills = ui.Window:AddTab({ Title = "Oto Skill", Icon = "zap" })
        Tabs.Chakra = ui.Window:AddTab({ Title = "Auto Chakra", Icon = "activity" })
        Tabs.Travel = ui.Window:AddTab({ Title = "Travel", Icon = "map" })
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
            -- InstaKill State
            InstaKillEnabled = Config.InstaKillEnabled,
            InstaKillRange = Config.InstaKillRange or 60,
            InstaKillSpeed = Config.InstaKillSpeed or 0.003,
            InstaKillTargetNPCs = Config.InstaKillTargetNPCs,
            InstaKillTargetPlayers = Config.InstaKillTargetPlayers,
            InstaKillFaceTarget = Config.InstaKillFaceTarget,
            InstaKillTeleportToTarget = Config.InstaKillTeleportToTarget,
            InstaKillKills = 0,
            -- Experimental State
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
            NoDashCooldown = Config.NoDashCooldownEnabled or false,
            AutoQTE = Config.AutoQTEEnabled or false,
            AutoNanami = Config.AutoNanamiEnabled or false,
            WarCount = 0,
            ChakraThreshold = Config.AutoChakraThreshold,
            StatsAdded = {ninjutsu = 0, taijutsu = 0, chakra = 0, health = 0},
            SkillStats = {r = 0, t = 0, y = 0, f = 0, g = 0, h = 0, v = 0, b = 0, n = 0, q = 0, e = 0}
        }
        
        -- !cancel command helper
        local function sendCancelCommand()
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
            pcall(function()
                local vc = workspace:FindFirstChild("VC")
                if vc then
                    local remote = vc:FindFirstChild("RemoteEvent")
                    if remote then
                        remote:FireServer("!cancel")
                    end
                end
            end)
        end
        
        -- ==========================================
        -- EXPERIMENTAL FUNCTIONS (Extracted from Decompiled MainScript)
        -- ==========================================
        
        -- NO DASH COOLDOWN
        local noDashConn = nil
        local function enableNoDashCooldown()
            if noDashConn then return end
            pcall(function()
                local ok, movCtrl = pcall(function() return require(LocalPlayer.PlayerScripts.Controllers.Character.MovementController) end)
                if not ok or not movCtrl then return end
                local dashFn = movCtrl.DashRequest
                if not dashFn then return end
                noDashConn = RunService.RenderStepped:Connect(function()
                    pcall(function()
                        debug.setupvalue(dashFn, 4, 0)
                        debug.setupvalue(dashFn, 6, 999)
                    end)
                end)
            end)
        end
        local function disableNoDashCooldown()
            if noDashConn then noDashConn:Disconnect() noDashConn = nil end
        end

        -- AUTO QTE
        local qteConn = nil
        local lastQtePress = 0
        local function handleQTE(qteGui)
            task.spawn(function()
                while qteGui.Parent and FarmState.AutoQTE do
                    local delayInterval = 1 / 15
                    if tick() - lastQtePress < delayInterval then task.wait() continue end
                    local pc = qteGui:FindFirstChild("QTE_PC", true)
                    local mob = qteGui:FindFirstChild("QTE_MOBILE", true)
                    if pc and pc.Text:match("^%a$") then
                        local kc = Enum.KeyCode[pc.Text]
                        if kc then
                            lastQtePress = tick()
                            VIM:SendKeyEvent(true, kc, false, game)
                            task.delay(0.02, function() VIM:SendKeyEvent(false, kc, false, game) end)
                        end
                    elseif mob then
                        lastQtePress = tick()
                        local pos = mob.AbsolutePosition + mob.AbsoluteSize * 0.5
                        VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
                        task.delay(0.02, function() VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0) end)
                    end
                    task.wait(0.05)
                end
            end)
        end
        local function startAutoQTE()
            if qteConn then return end
            local pg = LocalPlayer:WaitForChild("PlayerGui")
            qteConn = pg.ChildAdded:Connect(function(c)
                if c.Name == "QTE" and FarmState.AutoQTE then handleQTE(c) end
            end)
            for _, c in ipairs(pg:GetChildren()) do
                if c.Name == "QTE" and FarmState.AutoQTE then handleQTE(c) end
            end
        end
        local function stopAutoQTE()
            if qteConn then qteConn:Disconnect() qteConn = nil end
        end

        -- AUTO NANAMI RATIO
        local nanamiConn = nil
        local function startNanami()
            if nanamiConn then return end
            pcall(function()
                local Effects = ReplicatedStorage:WaitForChild("Knit"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("NanamiService"):WaitForChild("RE"):WaitForChild("Effects")
                nanamiConn = Effects.OnClientEvent:Connect(function(...)
                    if not FarmState.AutoNanami then return end
                    local args = {...}
                    if args[1] == "SpawnRatio" then
                        local attacker, target, billboard, hitFlag, duration, spawnTime = args[2], args[3], args[4], args[5], args[6], args[7]
                        if attacker == LocalPlayer and type(duration) == "number" and type(spawnTime) == "number" then
                            task.spawn(function()
                                local HIT_Y = 0.30
                                local lead = math.clamp(LocalPlayer:GetNetworkPing(), 0, 0.12)
                                local fireLocalT = spawnTime + (1 - HIT_Y) * duration - lead
                                while FarmState.AutoNanami do
                                    if hitFlag and hitFlag.Value == true then return end
                                    if billboard and billboard.Parent == nil then return end
                                    local now = workspace:GetServerTimeNow()
                                    if now > spawnTime + duration then return end
                                    if now >= fireLocalT then break end
                                    RunService.Heartbeat:Wait()
                                end
                                if not FarmState.AutoNanami then return end
                                if hitFlag and hitFlag.Value == true then return end
                                pcall(function()
                                    local RightActivated = ReplicatedStorage.Knit.Knit.Services.NanamiService.RE.RightActivated
                                    RightActivated:FireServer(target)
                                end)
                            end)
                        end
                    end
                end)
            end)
        end
        local function stopNanami()
            if nanamiConn then nanamiConn:Disconnect() nanamiConn = nil end
        end
        
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
                                                                sendCancelCommand()
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
        -- INSTAKILL SYSTEM (M1 SPAM + LOCAL FORCE KILL)
        -- ==========================================
        Tabs.InstaKill:AddParagraph({
            Title = "[X] InstaKill - M1 Spam + Local Force Kill",
            Content = "Ultra-fast melee attack spam + stubborn local health reset.\n\n" ..
                "- Fires M1 (mouse1) hundreds of times per second\n" ..
                "- 🆕 FORCE LOCAL KILL: Sets Health=0, MaxHealth=0, State=Dead, BreakJoints\n" ..
                "- Bypasses health checks via rapid server requests\n" ..
                "- Auto-faces target for maximum hit registration\n" ..
                "- Optional teleport to target for close-range combat\n" ..
                "- Works on NPCs and/or Players\n\n" ..
                "WARNING: Extremely detectable! Use only in private servers."
        })
        
        Tabs.InstaKill:AddToggle("InstaKillToggle", {
            Title = "Enable InstaKill",
            Description = "Spam M1 attacks + Force Local Kill on all targets in range",
            Default = Config.InstaKillEnabled
        }):OnChanged(function(v)
            FarmState.InstaKillEnabled = v
            Config.InstaKillEnabled = v
            ConfigManager.Save(Config)
            if v then
                ui.Fluent:Notify({
                    Title = "[X] InstaKill ACTIVATED",
                    Content = "M1 Spam + Local Force Kill online! " .. math.floor(1/FarmState.InstaKillSpeed) .. " attacks/sec",
                    Duration = 3
                })
            end
        end)
        
        Tabs.InstaKill:AddSlider("InstaKillRangeSlider", {
            Title = "InstaKill Range (studs)",
            Description = "Maximum distance to target enemies (default: 60)",
            Default = Config.InstaKillRange,
            Min = 10, Max = 500, Rounding = 0,
            Callback = function(v)
                FarmState.InstaKillRange = v
                Config.InstaKillRange = v
                ConfigManager.Save(Config)
            end
        })
        
        Tabs.InstaKill:AddSlider("InstaKillSpeedSlider", {
            Title = "M1 Spam Speed (seconds)",
            Description = "Delay between M1 attacks. Lower = faster (min: 0.001s = 1000 atk/s)",
            Default = Config.InstaKillSpeed,
            Min = 0.001, Max = 0.1, Rounding = 3,
            Callback = function(v)
                FarmState.InstaKillSpeed = v
                Config.InstaKillSpeed = v
                ConfigManager.Save(Config)
            end
        })
        
        Tabs.InstaKill:AddToggle("InstaKillNPCToggle", {
            Title = "Target NPCs",
            Description = "Attack all NPCs in range (missions, bosses, training)",
            Default = Config.InstaKillTargetNPCs
        }):OnChanged(function(v)
            FarmState.InstaKillTargetNPCs = v
            Config.InstaKillTargetNPCs = v
            ConfigManager.Save(Config)
        end)
        
        Tabs.InstaKill:AddToggle("InstaKillPlayerToggle", {
            Title = "Target Players (PVP)",
            Description = "Attack other players in range",
            Default = Config.InstaKillTargetPlayers
        }):OnChanged(function(v)
            FarmState.InstaKillTargetPlayers = v
            Config.InstaKillTargetPlayers = v
            ConfigManager.Save(Config)
        end)
        
        Tabs.InstaKill:AddToggle("InstaKillFaceToggle", {
            Title = "Auto-Face Target",
            Description = "Automatically rotate to face the target (required for M1 hits)",
            Default = Config.InstaKillFaceTarget
        }):OnChanged(function(v)
            FarmState.InstaKillFaceTarget = v
            Config.InstaKillFaceTarget = v
            ConfigManager.Save(Config)
        end)
        
        Tabs.InstaKill:AddToggle("InstaKillTeleportToggle", {
            Title = "Teleport to Target",
            Description = "Instantly teleport behind target before attacking",
            Default = Config.InstaKillTeleportToTarget
        }):OnChanged(function(v)
            FarmState.InstaKillTeleportToTarget = v
            Config.InstaKillTeleportToTarget = v
            ConfigManager.Save(Config)
        end)
        
        Tabs.InstaKill:AddParagraph({
            Title = "InstaKill Mechanics",
            Content = "How it works:\n\n" ..
                "1. Scans all Humanoids in workspace\n" ..
                "2. Filters by range and target type (NPC/Player)\n" ..
                "3. Teleports behind target (if enabled)\n" ..
                "4. Faces target using CFrame.lookAt\n" ..
                "5. 🆕 FORCE LOCAL KILL: Sets Health=0, MaxHealth=0, State=Dead, BreakJoints\n" ..
                "6. Fires combat.update:FireServer('mouse1', true)\n" ..
                "7. Waits minimal delay (0.001-0.1s)\n" ..
                "8. Fires combat.update:FireServer('mouse1', false)\n" ..
                "9. Repeats at extreme speed\n\n" ..
                "This overwhelms the server with M1 requests AND locally destroys the target's humanoid."
        })
        
        -- INSTAKILL LOGIC - M1 SPAM ENGINE + LOCAL FORCE KILL
        task.spawn(function()
            while true do
                if FarmState.InstaKillEnabled and LocalPlayer.Character then
                    pcall(function()
                        local char = LocalPlayer.Character
                        local root = char:FindFirstChild("HumanoidRootPart")
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        local combat = char:FindFirstChild("combat")
                        
                        if root and hum and combat and hum.Health > 0 then
                            local killCount = 0
                            local targets = {}
                            
                            -- Collect all valid targets
                            if FarmState.InstaKillTargetNPCs then
                                -- Scan workspace.npc folder
                                local npcs = workspace:FindFirstChild("npc")
                                if npcs then
                                    for _, npc in pairs(npcs:GetChildren()) do
                                        if npc:IsA("Model") then
                                            local npcRoot = npc:FindFirstChild("HumanoidRootPart")
                                            local npcHum = npc:FindFirstChildOfClass("Humanoid")
                                            
                                            if npcRoot and npcHum and npcHum.Health > 0 then
                                                local dist = (root.Position - npcRoot.Position).Magnitude
                                                
                                                if dist <= FarmState.InstaKillRange then
                                                    table.insert(targets, {
                                                        model = npc,
                                                        root = npcRoot,
                                                        hum = npcHum,
                                                        name = npc.Name,
                                                        distance = dist
                                                    })
                                                end
                                            end
                                        end
                                    end
                                end
                                
                                -- Scan workspace for any other NPCs
                                for _, obj in pairs(workspace:GetChildren()) do
                                    if obj:IsA("Model") and obj ~= char then
                                        local objRoot = obj:FindFirstChild("HumanoidRootPart")
                                        local objHum = obj:FindFirstChildOfClass("Humanoid")
                                        
                                        if objRoot and objHum and objHum.Health > 0 then
                                            local isPlayer = Players:GetPlayerFromCharacter(obj) ~= nil
                                            if not isPlayer then
                                                local dist = (root.Position - objRoot.Position).Magnitude
                                                if dist <= FarmState.InstaKillRange then
                                                    table.insert(targets, {
                                                        model = obj,
                                                        root = objRoot,
                                                        hum = objHum,
                                                        name = obj.Name,
                                                        distance = dist
                                                    })
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            
                            -- Add players if targeting enabled
                            if FarmState.InstaKillTargetPlayers then
                                for _, player in pairs(Players:GetPlayers()) do
                                    if player ~= LocalPlayer and player.Character then
                                        local playerRoot = player.Character:FindFirstChild("HumanoidRootPart")
                                        local playerHum = player.Character:FindFirstChildOfClass("Humanoid")
                                        
                                        if playerRoot and playerHum and playerHum.Health > 0 then
                                            local dist = (root.Position - playerRoot.Position).Magnitude
                                            
                                            if dist <= FarmState.InstaKillRange then
                                                table.insert(targets, {
                                                    model = player.Character,
                                                    root = playerRoot,
                                                    hum = playerHum,
                                                    name = player.Name,
                                                    distance = dist
                                                })
                                            end
                                        end
                                    end
                                end
                            end
                            
                            -- Sort by distance (closest first)
                            table.sort(targets, function(a, b) return a.distance < b.distance end)
                            
                            -- Attack all targets with M1 spam + Local Force Kill
                            for _, target in ipairs(targets) do
                                if not target.hum or not target.root.Parent then
                                    continue
                                end
                                
                                -- Teleport to target if enabled
                                if FarmState.InstaKillTeleportToTarget then
                                    local behindOffset = -target.root.CFrame.LookVector * 3
                                    local targetCFrame = CFrame.new(target.root.Position + behindOffset)
                                    root.CFrame = targetCFrame
                                end
                                
                                -- Face the target
                                if FarmState.InstaKillFaceTarget then
                                    root.CFrame = CFrame.lookAt(root.Position, target.root.Position)
                                end
                                
                                -- 🆕 FORCE LOCAL KILL (Stubborn Health & Humanoid Reset)
                                pcall(function()
                                    target.hum.Health = 0
                                    target.hum.MaxHealth = 0
                                    target.hum:ChangeState(Enum.HumanoidStateType.Dead)
                                    target.model:BreakJoints()
                                end)
                                
                                -- SPAM M1 ATTACK
                                -- Fire mouse1 true (start attack)
                                pcall(function()
                                    combat.update:FireServer("mouse1", true)
                                end)
                                
                                -- Minimal delay
                                task.wait(FarmState.InstaKillSpeed)
                                
                                -- Fire mouse1 false (end attack)
                                pcall(function()
                                    combat.update:FireServer("mouse1", false)
                                end)
                                
                                -- Check if target died
                                if target.hum.Health <= 0 or not target.model.Parent then
                                    killCount = killCount + 1
                                end
                            end
                            
                            FarmState.InstaKillKills = FarmState.InstaKillKills + killCount
                        end
                    end)
                end
                task.wait(FarmState.InstaKillSpeed or 0.003)
            end
        end)
        
        -- InstaKill Status Display
        local InstaKillStatusDisplay = Tabs.InstaKill:AddParagraph({
            Title = "InstaKill Status",
            Content = "Initializing..."
        })
        
        task.spawn(function()
            while true do
                local attacksPerSec = math.floor(1 / (FarmState.InstaKillSpeed or 0.003))
                
                InstaKillStatusDisplay.Content = string.format(
                    "Status: %s\n\n" ..
                    "Attack Speed: %d attacks/sec\n" ..
                    "Range: %d studs\n" ..
                    "Total Kills: %d\n\n" ..
                    "Settings:\n" ..
                    "- Target NPCs: %s\n" ..
                    "- Target Players: %s\n" ..
                    "- Auto-Face: %s\n" ..
                    "- Teleport: %s\n\n" ..
                    "Active: %s",
                    FarmState.InstaKillEnabled and "[OK] ACTIVE" or "[X] INACTIVE",
                    attacksPerSec,
                    FarmState.InstaKillRange,
                    FarmState.InstaKillKills,
                    FarmState.InstaKillTargetNPCs and "YES" or "NO",
                    FarmState.InstaKillTargetPlayers and "YES" or "NO",
                    FarmState.InstaKillFaceTarget and "YES" or "NO",
                    FarmState.InstaKillTeleportToTarget and "YES" or "NO",
                    FarmState.InstaKillEnabled and "M1 SPAM + LOCAL FORCE KILL RUNNING" or "DISABLED"
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
        -- TRAVEL (MAP TELEPORTER)
        -- ==========================================
        Tabs.Travel:AddParagraph({
            Title = "[T] Map Teleporter",
            Content = "Teleport to any RPG map or game mode in Shindo Life.\nUses the game's native rpgteleport remote.\n\nNote: Some maps require a minimum level to enter."
        })
        
        local mapList = {
            {Name = "Main Menu (Spawn)", PlaceId = 4616652839, Req = 0},
            {Name = "Training Fields", PlaceId = 5431071837, Req = 100},
            {Name = "Storm Village", PlaceId = 5084678830, Req = 200},
            {Name = "Forest of Embers", PlaceId = 5447073001, Req = 300},
            {Name = "Tempest Village", PlaceId = 6901575446, Req = 300},
            {Name = "Shinobi World (All Villages)", PlaceId = 5943872934, Req = 300},
            {Name = "Dawn Hideout (Akatsuki)", PlaceId = 5431069982, Req = 1000},
            {Name = "Shindai Valley", PlaceId = 5451401540, Req = 800},
            {Name = "World X (Hardcore)", PlaceId = 5943874201, Req = 0},
            {Name = "War Mode", PlaceId = 5824792748, Req = 400},
            {Name = "Conquest", PlaceId = 6341670805, Req = 500},
            {Name = "Dungeon", PlaceId = 7524809704, Req = 300},
            {Name = "Arena X", PlaceId = 5743370338, Req = 600},
            {Name = "Arena (Comp)", PlaceId = 5664805984, Req = 600},
            {Name = "Pro Arena", PlaceId = 5664803952, Req = 1000},
            {Name = "Arena 2", PlaceId = 5307141034, Req = 0},
            {Name = "Free / Rewards", PlaceId = 5451410109, Req = 0}
        }
        
        Tabs.Travel:AddSection("RPG Maps & Game Modes")
        for _, map in ipairs(mapList) do
            Tabs.Travel:AddButton({
                Title = map.Name .. (map.Req > 0 and " (Lvl " .. map.Req .. "+)" or ""),
                Callback = function()
                    pcall(function()
                        LocalPlayer.startevent:FireServer("rpgteleport", map.PlaceId)
                        ui.Fluent:Notify({Title = "[T] Travel", Content = "Teleporting to " .. map.Name, Duration = 2})
                    end)
                end
            })
        end
        
        Tabs.Travel:AddSection("Private Servers")
        local psCode = ""
        Tabs.Travel:AddInput("PSCodeInput", {
            Title = "Private Server Code",
            Placeholder = "Enter code...",
            Finished = true,
            Callback = function(v) psCode = v end
        })
        
        Tabs.Travel:AddButton({
            Title = "Join Private Server",
            Callback = function()
                if psCode and psCode ~= "" then
                    pcall(function()
                        LocalPlayer.startevent:FireServer("teleporttoprivate", psCode, nil)
                        ui.Fluent:Notify({Title = "[T] PS Join", Content = "Joining private server...", Duration = 2})
                    end)
                else
                    ui.Fluent:Notify({Title = "[T] Error", Content = "Enter a valid code", Duration = 2})
                end
            end
        })
        
        Tabs.Travel:AddButton({
            Title = "Create Private Server (Current Map)",
            Callback = function()
                pcall(function()
                    LocalPlayer.startevent:FireServer("createprivateserver", game.PlaceId)
                    ui.Fluent:Notify({Title = "[T] PS Create", Content = "Creating private server...", Duration = 2})
                end)
            end
        })
        
        -- ==========================================
        -- EXPERIMENTAL FEATURES (NO KILLAURA - MOVED TO INSTAKILL TAB)
        -- ==========================================
        Tabs.Experimental:AddParagraph({
            Title = "[X] EXPERIMENTAL FEATURES",
            Content = "WARNING: These features are experimental and may cause:\n- Server detection / kicks\n- Visual glitches\n- Performance issues\n\nUse at your own risk in private servers!\n\nNOTE: InstaKill (M1 spam + Local Force Kill) has been moved to its own dedicated tab."
        })
        
        Tabs.Experimental:AddSection("Advanced Combat Mods")
        
        Tabs.Experimental:AddToggle("NoDashCooldownToggle", {
            Title = "No Dash Cooldown",
            Description = "Removes the cooldown between dashes (hooks MovementController)",
            Default = Config.NoDashCooldownEnabled
        }):OnChanged(function(v)
            FarmState.NoDashCooldown = v
            Config.NoDashCooldownEnabled = v
            ConfigManager.Save(Config)
            if v then enableNoDashCooldown() else disableNoDashCooldown() end
        end)
        
        Tabs.Experimental:AddToggle("AutoQTEToggle", {
            Title = "Auto QTE",
            Description = "Automatically presses the correct keys during QTE events",
            Default = Config.AutoQTEEnabled
        }):OnChanged(function(v)
            FarmState.AutoQTE = v
            Config.AutoQTEEnabled = v
            ConfigManager.Save(Config)
            if v then startAutoQTE() else stopAutoQTE() end
        end)
        
        Tabs.Experimental:AddToggle("AutoNanamiToggle", {
            Title = "Auto Nanami Ratio",
            Description = "Automatically hits the perfect ratio timing for Nanami",
            Default = Config.AutoNanamiEnabled
        }):OnChanged(function(v)
            FarmState.AutoNanami = v
            Config.AutoNanamiEnabled = v
            ConfigManager.Save(Config)
            if v then startNanami() else stopNanami() end
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
                if FarmState.AntiRagdollEnabled then table.insert(activeFeatures, "AntiRagdoll") end
                if FarmState.AntiKnockbackEnabled then table.insert(activeFeatures, "AntiKnockback") end
                if FarmState.ESPEnabled then table.insert(activeFeatures, "ESP") end
                if FarmState.StunGrabImmunityEnabled then table.insert(activeFeatures, "StunImmunity") end
                if FarmState.NoDashCooldown then table.insert(activeFeatures, "NoDashCD") end
                if FarmState.AutoQTE then table.insert(activeFeatures, "AutoQTE") end
                if FarmState.AutoNanami then table.insert(activeFeatures, "AutoNanami") end
                
                local activeText = #activeFeatures > 0 and table.concat(activeFeatures, ", ") or "None"
                
                ExperimentalStatusDisplay.Content = string.format(
                    "Active Features: %d / 7\n\n%s\n\nESP Stats:\n- Max Range: %d studs\n- Players Tracked: %d\n\nNote: InstaKill moved to dedicated tab",
                    #activeFeatures, activeText,
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
            Content = "Loaded: Shindo Life In-Game (Enhanced + Travel + Combat Mods)",
            Duration = 5
        })
    end
end
