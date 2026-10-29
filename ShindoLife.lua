-- // ==========================================
-- // GLOCKREISHUB - SHINDO LIFE MODULE (ENHANCED)
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
            ScrollSniperEnabled = false,
            WarFarmEnabled = false, WarAutoReset = true,
            AutoChakraEnabled = false, AutoChakraThreshold = 100000,
            AutoRankEnabled = false
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
                        Settings.Status = "🎯 TARGET FOUND! LOCKING..."
                        Fluent:Notify({Title = "🎯 TARGET FOUND", Content = "Found " .. currentElement .. " in " .. slot:upper() .. "!", Duration = 10})
                        pcall(function() LocalPlayer.startevent:FireServer("band", "Eye") end)
                        task.wait(1)
                        LocalPlayer:Kick("🎯 Hedef Bulundu: " .. currentElement)
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
                        Settings.Status = "⚠️ Spins depleted. Rejoining..."
                        Fluent:Notify({Title = "Spins Depleted", Content = "Spins: " .. Settings.CurrentSpins .. " | Rejoining...", Duration = 3})
                        task.wait(2)
                        TeleportService:Teleport(game.PlaceId, LocalPlayer)
                    elseif Settings.CurrentSpins == -1 then Settings.Status = "⏳ Waiting for spin data..." end
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
                    Settings.Status = "⚠️ Threshold dropped! Rejoining..."
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
        Tabs.Scroll = ui.Window:AddTab({ Title = "Scroll Sniper", Icon = "book" })
        Tabs.War = ui.Window:AddTab({ Title = "War Farm", Icon = "shield" })
        Tabs.Quests = ui.Window:AddTab({ Title = "Quest Maker", Icon = "list" })
        Tabs.Chakra = ui.Window:AddTab({ Title = "Auto Chakra", Icon = "zap" })
        Tabs.Utilities = ui.Window:AddTab({ Title = "Utilities", Icon = "tool" })
        
        -- State variables
        local FarmState = {
            AutoFarmEnabled = Config.AutoFarmEnabled,
            ScrollSniperEnabled = Config.ScrollSniperEnabled,
            WarFarmEnabled = Config.WarFarmEnabled,
            AutoChakraEnabled = Config.AutoChakraEnabled,
            AutoRankEnabled = Config.AutoRankEnabled,
            WarCount = 0,
            ChakraThreshold = Config.AutoChakraThreshold
        }
        
        -- ==========================================
        -- AUTOFARM (MISSION-BASED)
        -- ==========================================
        Tabs.Main:AddParagraph({
            Title = "[*] AutoFarm System",
            Content = "Automatically accepts and completes missions.\n\n- Level-aware mission selection (699 / 700+)\n- Auto-kill NPCs for defeat missions\n- Smart mission giver detection\n- Anti-kick protection"
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
        
        Tabs.Main:AddSlider("AutoFarmSpeedSlider", {
            Title = "Tween Speed (studs/sec)",
            Default = Config.AutoFarmSpeed,
            Min = 100, Max = 2500, Rounding = 0,
            Callback = function(v)
                Config.AutoFarmSpeed = v
                ConfigManager.Save(Config)
            end
        })
        
        -- AutoFarm logic
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
                            
                            -- Check if we have a mission
                            local missionGui = LocalPlayer.PlayerGui:FindFirstChild("Main")
                                and LocalPlayer.PlayerGui.Main:FindFirstChild("ingame")
                                and LocalPlayer.PlayerGui.Main.ingame:FindFirstChild("MissionStory")
                            
                            if not missionGui or not missionGui.Visible then
                                -- No mission - find mission giver
                                local missionGivers = workspace:FindFirstChild("missiongivers")
                                if missionGivers then
                                    local lvl = LocalPlayer:FindFirstChild("statz")
                                        and LocalPlayer.statz:FindFirstChild("lvl")
                                        and LocalPlayer.statz.lvl:FindFirstChild("lvl")
                                        and LocalPlayer.statz.lvl.lvl.Value or 0
                                    
                                    for _, giver in pairs(missionGivers:GetChildren()) do
                                        if giver:FindFirstChild("Head")
                                            and giver.Head:FindFirstChild("givemission")
                                            and giver.Head.givemission.Enabled then
                                            
                                            local talk = giver:FindFirstChild("Talk")
                                            if talk and talk:FindFirstChild("typ")
                                                and talk.typ.Value == "defeat" then
                                                
                                                -- Accept mission
                                                local clientTalk = giver:FindFirstChild("CLIENTTALK")
                                                if clientTalk then
                                                    toTarget(root.Position, giver.HumanoidRootPart.Position,
                                                        CFrame.new(giver.HumanoidRootPart.Position + Vector3.new(0, -8, 0)))
                                                    task.wait(0.5)
                                                    
                                                    local dist = (root.Position - giver.HumanoidRootPart.Position).Magnitude
                                                    if dist < 10 then
                                                        clientTalk:FireServer()
                                                        task.wait(0.3)
                                                        clientTalk:FireServer("accept")
                                                    end
                                                end
                                                break
                                            end
                                        end
                                    end
                                end
                            else
                                -- Have mission - kill NPCs
                                local npcs = workspace:FindFirstChild("npc")
                                if npcs then
                                    for _, npc in pairs(npcs:GetChildren()) do
                                        if npc:IsA("Model")
                                            and npc:FindFirstChild("HumanoidRootPart")
                                            and npc:FindFirstChild("Humanoid")
                                            and npc.Humanoid.Health > 0 then
                                            
                                            toTarget(root.Position, npc.HumanoidRootPart.Position,
                                                CFrame.new(npc.HumanoidRootPart.Position + Vector3.new(0, -8, 0)))
                                            task.wait(0.3)
                                            
                                            local dist = (root.Position - npc.HumanoidRootPart.Position).Magnitude
                                            if dist < 15 then
                                                npc.Humanoid.Health = 0
                                            end
                                            break
                                        end
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
        
        -- CharacterAdded handler for WalkSpeed/JumpHeight
        LocalPlayer.CharacterAdded:Connect(function(char)
            char:WaitForChild("HumanoidRootPart")
            task.wait(3)
            if char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = Config.WalkSpeed
                char.Humanoid.JumpHeight = Config.JumpHeight
                char.Humanoid.UseJumpPower = false
            end
        end)
        
        ui.Window:SelectTab(1)
        ui.Fluent:Notify({
            Title = "GlockreisHub",
            Content = "Loaded: Shindo Life In-Game (Enhanced)",
            Duration = 5
        })
    end
end
