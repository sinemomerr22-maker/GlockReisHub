-- // ==========================================
-- // GLOCKREISHUB - SHINDO LIFE MODULE (ENHANCED)
-- // AutoFarm M1 + Auto Stats + Godmode + Position Control
-- // Continuous Facing + Underground Attack + Auto Skill Spammer
-- // Mission Protection + InstaKill (M1 Spam + Local Force Kill)
-- // Travel System (All Maps + Private/Friend Teleport)
-- // Scroll Sniper (Auto Server Hop + Time-Based) + Scroll Get (Manual)
-- // LIVE TIME DISPLAY (GLOBALTIME.globalesttime)
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
    
    -- ==========================================
    -- LIVE TIME DISPLAY SYSTEM (ALWAYS VISIBLE)
    -- ==========================================
    task.spawn(function()
        if not game:IsLoaded() then game.Loaded:Wait() end
        task.wait(2)
        
        local getUI = gethui or function() return game:GetService("CoreGui") end
        local timeGui = Instance.new("ScreenGui")
        timeGui.Name = "GlockTimeDisplay"
        timeGui.ResetOnSpawn = false
        timeGui.DisplayOrder = 999
        timeGui.IgnoreGuiInset = true
        timeGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        pcall(function() timeGui.Parent = getUI() end)
        if not timeGui.Parent then
            timeGui.Parent = LocalPlayer:WaitForChild("PlayerGui", 30)
        end
        
        local mainFrame = Instance.new("Frame")
        mainFrame.Name = "TimeFrame"
        mainFrame.Size = UDim2.new(0, 280, 0, 50)
        mainFrame.Position = UDim2.new(0.5, -140, 0, 10)
        mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
        mainFrame.BackgroundTransparency = 0.15
        mainFrame.BorderSizePixel = 0
        mainFrame.Parent = timeGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = mainFrame
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(100, 180, 255)
        stroke.Thickness = 2
        stroke.Transparency = 0.3
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = mainFrame
        
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 30, 50)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30, 50, 80)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 30, 50))
        })
        gradient.Rotation = 90
        gradient.Parent = mainFrame
        
        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        layout.Padding = UDim.new(0, 8)
        layout.Parent = mainFrame
        
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Name = "Icon"
        iconLabel.Size = UDim2.new(0, 28, 0, 28)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = "⏰"
        iconLabel.TextSize = 22
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
        iconLabel.LayoutOrder = 1
        iconLabel.Parent = mainFrame
        
        local timeLabel = Instance.new("TextLabel")
        timeLabel.Name = "TimeText"
        timeLabel.Size = UDim2.new(1, -50, 1, 0)
        timeLabel.BackgroundTransparency = 1
        timeLabel.Text = "Loading time..."
        timeLabel.TextSize = 18
        timeLabel.Font = Enum.Font.GothamBold
        timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        timeLabel.TextXAlignment = Enum.TextXAlignment.Left
        timeLabel.TextYAlignment = Enum.TextYAlignment.Center
        timeLabel.LayoutOrder = 2
        timeLabel.Parent = mainFrame
        
        local textStroke = Instance.new("UIStroke")
        textStroke.Color = Color3.fromRGB(0, 0, 0)
        textStroke.Thickness = 1
        textStroke.Transparency = 0.5
        textStroke.Parent = timeLabel
        
        local dragging = false
        local dragStart = nil
        local startPos = nil
        
        mainFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = mainFrame.Position
            end
        end)
        
        mainFrame.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement 
                or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                mainFrame.Position = UDim2.new(
                    startPos.X.Scale, 
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale, 
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
        
        local function updateTime()
            pcall(function()
                local globalTime = workspace:FindFirstChild("GLOBALTIME")
                if globalTime then
                    local estTime = globalTime:FindFirstChild("globalesttime")
                    if estTime and estTime:IsA("StringValue") then
                        local timeValue = estTime.Value
                        if timeValue and timeValue ~= "" then
                            timeLabel.Text = "EST: " .. timeValue
                            
                            local hour = tonumber(string.match(timeValue, "(%d+)"))
                            if hour then
                                if hour >= 6 and hour < 12 then
                                    timeLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
                                    stroke.Color = Color3.fromRGB(255, 180, 50)
                                elseif hour >= 12 and hour < 18 then
                                    timeLabel.TextColor3 = Color3.fromRGB(100, 220, 255)
                                    stroke.Color = Color3.fromRGB(50, 180, 255)
                                elseif hour >= 18 and hour < 21 then
                                    timeLabel.TextColor3 = Color3.fromRGB(255, 150, 80)
                                    stroke.Color = Color3.fromRGB(255, 100, 50)
                                else
                                    timeLabel.TextColor3 = Color3.fromRGB(150, 130, 255)
                                    stroke.Color = Color3.fromRGB(100, 80, 200)
                                end
                            end
                        else
                            timeLabel.Text = "EST: --:--"
                        end
                    else
                        timeLabel.Text = "EST: Not found"
                    end
                else
                    timeLabel.Text = "GLOBALTIME: Missing"
                end
            end)
        end
        
        updateTime()
        
        local function hookTimeValue()
            pcall(function()
                local globalTime = workspace:WaitForChild("GLOBALTIME", 30)
                if globalTime then
                    local estTime = globalTime:WaitForChild("globalesttime", 30)
                    if estTime then
                        estTime.Changed:Connect(function()
                            updateTime()
                        end)
                    end
                end
            end)
        end
        
        hookTimeValue()
        
        task.spawn(function()
            while timeGui and timeGui.Parent do
                updateTime()
                task.wait(1)
            end
        end)
        
        task.spawn(function()
            while mainFrame and mainFrame.Parent do
                local tweenIn = TweenService:Create(stroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Transparency = 0.6
                })
                local tweenOut = TweenService:Create(stroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Transparency = 0.2
                })
                tweenIn:Play()
                tweenIn.Completed:Wait()
                tweenOut:Play()
                tweenOut.Completed:Wait()
            end
        end)
    end)
    
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
            ScrollGetEnabled = false,
            ScrollSniperEnabled = false,
            ScrollSniperSelected = {},
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
            InstaKillEnabled = false,
            InstaKillRange = 60,
            InstaKillSpeed = 0.003,
            InstaKillTargetNPCs = true,
            InstaKillTargetPlayers = true,
            InstaKillFaceTarget = true,
            InstaKillTeleportToTarget = false,
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
                
                local currentTime = "N/A"
                pcall(function()
                    local gt = workspace:FindFirstChild("GLOBALTIME")
                    if gt then
                        local est = gt:FindFirstChild("globalesttime")
                        if est and est.Value then
                            currentTime = est.Value
                        end
                    end
                end)
                
                StatusDisplay.Content = string.format(
                    "Status: %s\n\n🕐 Current Time (EST): %s\n\n%s\n\nSpins Left: %s\nTotal Spins: %d\nRejoin at: %d\nDelay: %.2fs\n\nTargets: %s", 
                    Settings.Status, 
                    currentTime,
                    table.concat(slotValues, "\n"), 
                    spinsDisplay, 
                    Settings.TotalSpinsDone, 
                    Settings.MinSpinsToRejoin, 
                    Settings.SpinDelay, 
                    targetText
                )
                task.wait(0.3)
            end
        end)
    
    -- ==========================================
    -- SHINDO LIFE IN-GAME (ENHANCED)
    -- ==========================================
    else
        Tabs.Main = ui.Window:AddTab({ Title = "AutoFarm", Icon = "target" })
        Tabs.Travel = ui.Window:AddTab({ Title = "Travel", Icon = "map" })
        Tabs.Godmode = ui.Window:AddTab({ Title = "Godmode", Icon = "shield" })
        Tabs.InstaKill = ui.Window:AddTab({ Title = "InstaKill", Icon = "crosshair" })
        Tabs.ScrollSniper = ui.Window:AddTab({ Title = "Scroll Sniper", Icon = "clock" })
        Tabs.ScrollGet = ui.Window:AddTab({ Title = "Scroll Get", Icon = "book" })
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
            ScrollGetEnabled = Config.ScrollGetEnabled,
            ScrollSniperEnabled = Config.ScrollSniperEnabled,
            ScrollSniperSelected = Config.ScrollSniperSelected or {},
            ScrollSniperStatus = "Idle",
            ScrollSniperCurrent = "",
            ScrollSniperServersHopped = 0,
            ScrollSniperScrollsClaimed = 0,
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
            InstaKillEnabled = Config.InstaKillEnabled,
            InstaKillRange = Config.InstaKillRange or 60,
            InstaKillSpeed = Config.InstaKillSpeed or 0.003,
            InstaKillTargetNPCs = Config.InstaKillTargetNPCs,
            InstaKillTargetPlayers = Config.InstaKillTargetPlayers,
            InstaKillFaceTarget = Config.InstaKillFaceTarget,
            InstaKillTeleportToTarget = Config.InstaKillTeleportToTarget,
            InstaKillKills = 0,
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
        -- TRAVEL SYSTEM (ALL MAPS)
        -- ==========================================
        Tabs.Travel:AddParagraph({
            Title = "[T] Travel System",
            Content = "Teleport to any map in Shindo Life.\n\n" ..
                "- Public Server: Join random public server\n" ..
                "- Private Server: Join with code\n" ..
                "- Join Friend: Teleport to friend's server\n" ..
                "- Create Private: Start your own server\n\n" ..
                "🆕 All 19 maps supported with instant teleport!\n" ..
                "🆕 LIVE TIME DISPLAY at top of screen (draggable)"
        })
        
        local Maps = {
            {Name = "BLAZE (New Ember)", PlaceId = 6986372023, MinLevel = 0},
            {Name = "OBELISK (Stone)", PlaceId = 4601350809, MinLevel = 0},
            {Name = "NIMBUS (Cloud)", PlaceId = 4601350656, MinLevel = 0},
            {Name = "EMBER (Leaf)", PlaceId = 4601350214, MinLevel = 0},
            {Name = "JEJUNES", PlaceId = 7923764447, MinLevel = 0},
            {Name = "DUNES (Sand)", PlaceId = 4601350394, MinLevel = 0},
            {Name = "HAZE (Mist)", PlaceId = 4601350760, MinLevel = 0},
            {Name = "VINLAND", PlaceId = 5451405681, MinLevel = 0},
            {Name = "TRAINING FIELD", PlaceId = 5431071837, MinLevel = 100},
            {Name = "FOREST OF EMBERS", PlaceId = 5447073001, MinLevel = 300},
            {Name = "OPEN WORLD", PlaceId = 5943872934, MinLevel = 0},
            {Name = "CONQUEST", PlaceId = 6341670805, MinLevel = 500},
            {Name = "TEMPEST", PlaceId = 6901575446, MinLevel = 300},
            {Name = "GREAT NARUMAKI BRIDGE", PlaceId = 5451398863, MinLevel = 0},
            {Name = "SHINDAI VALLEY", PlaceId = 5451401540, MinLevel = 800},
            {Name = "SHIKAI FOREST", PlaceId = 6602103757, MinLevel = 0},
            {Name = "MOUNT MAKI", PlaceId = 5255237254, MinLevel = 0},
            {Name = "RYUJI CAVE", PlaceId = 5824792748, MinLevel = 0},
            {Name = "ESPADA", PlaceId = 6444873399, MinLevel = 0}
        }
        
        local function getUserIdFromName(name)
            local userId = nil
            pcall(function()
                userId = Players:GetUserIdFromNameAsync(name)
            end)
            return userId
        end
        
        local function teleportToPublic(placeId, mapName)
            ui.Fluent:Notify({
                Title = "[T] Teleporting",
                Content = "Joining public server: " .. mapName,
                Duration = 3
            })
            pcall(function()
                LocalPlayer.startevent:FireServer("rpgteleport", placeId)
            end)
        end
        
        local function teleportToPrivate(placeId, privateCode, mapName)
            if not privateCode or privateCode == "" then
                ui.Fluent:Notify({
                    Title = "[!] Error",
                    Content = "Private server code is required!",
                    Duration = 3
                })
                return
            end
            
            ui.Fluent:Notify({
                Title = "[T] Teleporting",
                Content = "Joining private server: " .. mapName,
                Duration = 3
            })
            pcall(function()
                LocalPlayer.startevent:FireServer("teleporttoprivate", privateCode, placeId)
            end)
        end
        
        local function teleportToFriend(placeId, friendName, mapName)
            if not friendName or friendName == "" then
                ui.Fluent:Notify({
                    Title = "[!] Error",
                    Content = "Friend name is required!",
                    Duration = 3
                })
                return
            end
            
            local userId = getUserIdFromName(friendName)
            if not userId or userId <= 0 then
                ui.Fluent:Notify({
                    Title = "[!] Error",
                    Content = "Player not found: " .. friendName,
                    Duration = 3
                })
                return
            end
            
            ui.Fluent:Notify({
                Title = "[T] Teleporting",
                Content = "Joining friend: " .. friendName .. " in " .. mapName,
                Duration = 3
            })
            pcall(function()
                LocalPlayer.startevent:FireServer("rpgteleport", "friend", userId)
            end)
        end
        
        local function createPrivateServer(placeId, mapName)
            ui.Fluent:Notify({
                Title = "[T] Creating Server",
                Content = "Creating private server: " .. mapName,
                Duration = 3
            })
            pcall(function()
                LocalPlayer.startevent:FireServer("createprivateserver", placeId)
            end)
        end
        
        local function teleportToMenu()
            ui.Fluent:Notify({
                Title = "[T] Teleporting",
                Content = "Returning to main menu...",
                Duration = 3
            })
            pcall(function()
                LocalPlayer.startevent:FireServer("rpgteleport", 4616652839)
            end)
        end
        
        for _, map in ipairs(Maps) do
            Tabs.Travel:AddSection(map.Name)
            
            Tabs.Travel:AddButton({
                Title = "Join Public Server",
                Description = "Teleport to random public server",
                Callback = function()
                    teleportToPublic(map.PlaceId, map.Name)
                end
            })
            
            local privateCodeInput = Tabs.Travel:AddInput("PrivateCode_" .. map.Name:gsub("%s+", "_"), {
                Title = "Private Server Code",
                Placeholder = "Enter code...",
                Finished = true,
                Callback = function() end
            })
            
            Tabs.Travel:AddButton({
                Title = "Join Private Server",
                Description = "Teleport with private code",
                Callback = function()
                    local code = privateCodeInput.Value or ""
                    teleportToPrivate(map.PlaceId, code, map.Name)
                end
            })
            
            local friendNameInput = Tabs.Travel:AddInput("FriendName_" .. map.Name:gsub("%s+", "_"), {
                Title = "Friend Username",
                Placeholder = "Enter username...",
                Finished = true,
                Callback = function() end
            })
            
            Tabs.Travel:AddButton({
                Title = "Join Friend",
                Description = "Teleport to friend's server",
                Callback = function()
                    local name = friendNameInput.Value or ""
                    teleportToFriend(map.PlaceId, name, map.Name)
                end
            })
            
            Tabs.Travel:AddButton({
                Title = "Create Private Server",
                Description = "Start your own private server",
                Callback = function()
                    createPrivateServer(map.PlaceId, map.Name)
                end
            })
        end
        
        Tabs.Travel:AddSection("Navigation")
        Tabs.Travel:AddButton({
            Title = "Return to Main Menu",
            Description = "Go back to character selection",
            Callback = teleportToMenu
        })
        
        local TravelStatusDisplay = Tabs.Travel:AddParagraph({
            Title = "Travel Status",
            Content = "Initializing..."
        })
        
        task.spawn(function()
            while true do
                local currentPlace = game.PlaceId
                local currentMapName = "Unknown"
                
                for _, map in ipairs(Maps) do
                    if map.PlaceId == currentPlace then
                        currentMapName = map.Name
                        break
                    end
                end
                
                if currentPlace == 4616652839 then
                    currentMapName = "Main Menu"
                end
                
                local currentTime = "N/A"
                pcall(function()
                    local gt = workspace:FindFirstChild("GLOBALTIME")
                    if gt then
                        local est = gt:FindFirstChild("globalesttime")
                        if est and est.Value then
                            currentTime = est.Value
                        end
                    end
                end)
                
                TravelStatusDisplay.Content = string.format(
                    "Current Location: %s\n" ..
                    "🕐 Server Time (EST): %s\n" ..
                    "Place ID: %d\n" ..
                    "Job ID: %s\n\n" ..
                    "Players in Server: %d",
                    currentMapName,
                    currentTime,
                    currentPlace,
                    game.JobId or "N/A",
                    #Players:GetPlayers()
                )
                task.wait(1)
            end
        end)
        
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
                            
                            if FarmState.InstaKillTargetNPCs then
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
                            
                            table.sort(targets, function(a, b) return a.distance < b.distance end)
                            
                            for _, target in ipairs(targets) do
                                if not target.hum or not target.root.Parent then
                                    continue
                                end
                                
                                if FarmState.InstaKillTeleportToTarget then
                                    local behindOffset = -target.root.CFrame.LookVector * 3
                                    local targetCFrame = CFrame.new(target.root.Position + behindOffset)
                                    root.CFrame = targetCFrame
                                end
                                
                                if FarmState.InstaKillFaceTarget then
                                    root.CFrame = CFrame.lookAt(root.Position, target.root.Position)
                                end
                                
                                pcall(function()
                                    target.hum.Health = 0
                                    target.hum.MaxHealth = 0
                                    target.hum:ChangeState(Enum.HumanoidStateType.Dead)
                                    target.model:BreakJoints()
                                end)
                                
                                pcall(function()
                                    combat.update:FireServer("mouse1", true)
                                end)
                                
                                task.wait(FarmState.InstaKillSpeed)
                                
                                pcall(function()
                                    combat.update:FireServer("mouse1", false)
                                end)
                                
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
        -- SCROLL SNIPER (AUTO SERVER HOP + TIME-BASED)
        -- ==========================================
        Tabs.ScrollSniper:AddParagraph({
            Title = "[S] Scroll Sniper (Auto Server Hop)",
            Content = "Automatically hunts scrolls based on spawn time.\n\n" ..
                "🆕 Reads ALL scrolls from GLOBALTIME.clienttell\n" ..
                "🆕 Filters out BOSSDROP scrolls\n" ..
                "🆕 🚫 EXCLUDES: 00:00/01:00 time scrolls\n" ..
                "🆕 🚫 EXCLUDES: Location with 'drop' or 'boss'\n" ..
                "🆕 Shows location, time (HH:MM), rarity\n" ..
                "🆕 Select scrolls to hunt\n" ..
                "🆕 Auto server hops to private servers\n" ..
                "🆕 20-minute window (time to time+20min)\n" ..
                "🆕 30s wait per server, then hops\n" ..
                "🆕 Auto-claims scroll when found\n\n" ..
                "NOTE: Fill Private Server IDs table below!"
        })
        
        local ScrollServerIDs = {
            ember = {
                "72ivGo", "BqXz77", "hb4TbR", "h8UN7d", "wN6mFD", "mEjOEA", "L9D1Vq", "13Dj9p", "rojuE4", "L-AzLu",
                "LcRxLd", "atdWrW", "ufVgLu", "eIC7LA", "BPlBfp", "KFqY40", "_S7oDc", "Tg0_Au", "z5KMRG", "56fXqz",
                "xN9mN4", "sA7E2A", "de6zJf", "UppJUd", "4MrhMZ", "ywiAQh", "CHZLms", "NlNRDa", "YMJAEr", "IcSnCp",
                "L4s0py", "PM_yEk", "FfPxyL", "2M4ieq", "GPaih2", "t4n-wt", "ZKa1xh", "voFC4Z", "9gAS_H", "xiWsYq",
                "Ap1ytv", "S3ngKz", "T6f9X7", "xiZZHA", "S5Me6u", "pPn5VX", "dgagtt", "0dNJVL", "fpwGKg", "lCnqSi",
                "dc2q_T", "A6iJnw", "OPWJTw", "Zfn6nW", "GmBpOs", "xkbIMy", "u4pkQ1", "1kjoS9", "96H_n7", "yNtKe1",
                "H9PCO-", "D5thR4", "BCTeP-", "HWPCvV", "7NRGod", "eEElGM", "7_rVaj", "f-zJKQ", "uyU38u", "jW2xJD",
                "Eh_0EC", "S4Hn-M", "kDnYz6", "antObl", "9wUbJJ", "O7Fkk2", "gsU8mp", "CbMr_T", "9U8LPy", "xoDP4P",
                "GHdF4r", "sBm_se", "6rko4P", "cN73ya", "UcF4JD", "UtAZlc", "UaXCZk", "ZsFFhZ", "kRAquT", "6NoJgJ",
                "mt_O2A", "TUdAxo", "eHRHrd", "SxPxu0", "8CGAZH", "CeeBds", "FxhgFM", "BSkZ_n", "OxGgP9", "sssUE9",
                "SUVs0F", "p5HiOJ", "wLAJX0", "ungkgo", "kUVqRr", "b5ceSi", "chTNe3", "vQ9-BW", "KYG1sq", "tdqgZW",
                "jyQ3P3", "oYrUR1", "1YOVXZ", "pWnvjd", "Cvs3SS", "KBDjoX", "LAmvYt", "Zqs3Pu", "mW2FoJ", "U2vUrD",
                "MKys9H", "DEfkMX", "_EXVbM", "FUDgke", "YCePOO", "JUZVBU", "xvFoUq", "_bSq9N", "Ljvff8", "5rz1jq",
                "A-kRqJ", "8Pw1Ps", "GLPBmU", "_30BAS", "cs1gM5", "SQxoGz", "jkAYFg", "04SWhD", "c6Yfut", "7ErB6Q",
                "Mz0SYU", "B_72Ob", "vDjzXh", "8pOKv9", "uubfNm", "RceAzV", "qAw1n7", "OXMU1i", "yfmCsw", "3JfSZz",
                "WMYUAY", "1zPns-", "UQiDdq", "ozw1Mm", "vRxjZQ", "9dokXE", "uxJJdB", "kJTrGz", "FsENu0", "0d9sD5",
                "X3na7A", "4cpiq_", "LhddGz", "ZsTeKH", "ZRLUoK", "ktOuCE", "Pu-q_c", "QZU7ky", "gpea_7", "MB6SJW",
                "faXJyz", "09xhRe", "atL9hB", "7Lvj8H", "g0kiz1", "R0iyRs", "DPqYpO", "nmYVJ7", "QArKzc", "jmsbDG",
                "44puHp", "Q812zF", "M3jgMW", "5mkGoT", "WptNLd", "o9DLRZ", "tkqyBR", "P5OdyM", "h4GAdK", "WsdUgm",
                "dNsDRE", "zphst5", "SfY2sW", "4qVoLS", "bBwnVe", "2JaspW", "zE_f6v", "Ryt_Zf", "8CTs1m", "wJsLZe",
                "ACZySD", "uS9XxA", "VvPHt9", "DOrvCW", "tPWQWV", "VqkLJs", "snJvZH", "1ALgoY", "vVDOAn", "k3BAAM",
                "2FFxzR", "w6Nsno", "DALyaw", "DD7WuX", "1fbK1m", "JO4vZb", "nxAw9U", "v08r6q", "qMdBgO", "XCmrXX",
                "1bnsym", "_S-hBL", "zhOSC6", "Vp9XSm", "Trmqqm", "k7VNo2", "QYLNta", "dNe5nS", "jmTF12", "sMQC7L",
                "vSvFKS", "w9fjk1", "sDgpUW", "UrCpGJ", "_DYvBx", "HS9UPW", "BYpYRK", "DyNRsn", "dgFsS5", "eKNPDc",
                "ZZgYiT", "3gFj7D", "K9gRXl", "b7IpCK", "voL4oL", "Lbgd0H", "q3mdfL", "YM3fj0", "L1XXQa", "nRBS92",
                "D1NQVx", "wxf1h-", "u5jtbL", "sQpsNr", "KCEX_r", "83ppMG", "CRRvye", "cqkzAR", "sR_MMu", "TGqtm2",
                "byj8Y8", "GzAAyt", "Trm8CJ", "BsUdJX", "9_bkek", "bqE5im", "G60Qcs", "VopJBa", "QqwGbL", "KrFZni",
                "j3ZC7W", "LueVBN", "8vmL2y", "3soPN1", "yKMMdm",
            },
            blaze = {
                "oetXZ6", "v44Bd-", "cXXokm", "utcpPx", "kk0Ivx", "bSYHfJ", "nIvabw", "nnANqa", "5aQksY", "Vx1VH4",
                "pSgj2U", "yYqHFg", "HZ5fHS", "xk55Hb", "VWtj3x", "OF2o67", "GDxN-O", "SBiTde", "5uBjmD", "jgfTo2",
                "00VdTG", "2xUsba", "y1yXRB", "ScrPMj", "P1kfFb", "HeRPjT", "JO9afK", "Bkqnyi", "kJ66_d", "yDjqNr",
                "JC2kyC", "fvRGhV", "nFwKdO", "V8PBmA", "xEMGMw", "3kdok-", "V86iuz", "KQrgT6", "FCxzkn", "sH-925",
                "M5pJP9", "sta7Rh", "CEWQRL", "ikoOpy", "UGOgOS", "i-szVw", "0YRVhs", "iG7E81", "amSL-y", "THvUfE",
                "zYjBov", "S87mGN", "bCp3iz", "RUxSVc", "WxN0vr", "qf68tG",
            },
            obelisk = {
                "1r-1iU", "ylgHKH", "rzyQWX", "EvRA8H", "DrFQ6t", "aWs6Po", "phyKYA", "WDm6HV", "G1Hdb4", "0goLRB",
                "U6FaMn", "Z8mGSt", "dcDBR6", "bO8kvU", "mn_xGR", "eLapCt", "8KArxS", "kyM9e0", "ozFZJ6", "WWpFZJ",
                "MLmOFm", "Wd9r_h", "Ce6dEk", "vHRaZA", "p7agqj", "eMXePh", "LYE3SG", "Mx3e3s", "K4q9Jf", "Edv8uH",
                "MWrt6c", "24vKA0", "2ThCfw", "8y8Noq", "jQiHp5", "J4HuaK", "Y-yPtF", "BFIVk5", "FTEyfW", "GrdLFY",
                "8vQTVP", "18mHIn", "gXk0Kv", "_JgFUI", "3DayPA", "MFHOUg", "zUeUBj", "WEhhel", "CjdUGG", "ru4wag",
                "tpNXsS", "3c94O8", "6mCtFo", "PadPpk", "xg5IR7", "09DvCs", "ALfSDo", "uUU1-r", "5d-88a", "DsjagO",
                "f2gU8h", "oRFLRc", "uMTFU-", "mGaO6P", "KQmhGQ", "z58fM6", "UbgjOY", "97BHrm", "QVcbYR", "pu9eKj",
                "G8-EoL", "s3_Rcc", "2tZtRn", "8eR6D3", "s-EuYy", "Fgg5UL", "_JPL0e", "czVWuA", "NmH38c", "RjOXLB",
                "VRvL2O", "wdT4g5", "G5RqHA", "OAtd0C", "Bz5RQq", "xeLbYv", "OJscUo", "mHAZtS", "Ctadha", "fG4Lgo",
                "cTMZL7", "3rjpoN", "G2DE29", "4zGwwE", "e5tbEr", "9dokwY", "8ZydHf", "M5z_t0", "ETgE9X", "Muo_65",
                "yTYxDU", "Wrm89X", "KyJvee", "h23Ok_", "nhP3aF", "P4cu6X", "9C5Eq7", "Pyzx03", "RU2sTg", "us_Enc",
                "8ZV6sW", "StvooT", "h8jvmy", "Ksjtvp", "EagaGx", "9wXR-R", "aEG4S3", "Rax-zt", "yhsKA2", "BXz902",
                "gt93NS", "0nsn18", "RnOqf0", "q1gSsj", "u3TUdx", "hGKMts", "QtFx8W", "tJygcs", "4UwtAD", "XstV76",
                "n49Z8d", "v3o3tL", "YNccZg", "JatC7H", "M3aWJa", "H5CWBv", "33KzX2", "YBTh12", "BCjhP0", "8S951k",
                "OjXxdg", "NyjA1f", "66Q-qd", "40OsFu", "SrhB9W", "dSPp0F", "Ame5L_", "BoqePB", "UYBUNw", "A6Dv24",
                "tMkHqz", "LTv36K", "LMmVdB", "YEXQLa", "AgtLcn", "69p42W", "E-4_o-", "EEkmMc", "7XzwT9", "MKh9UQ",
                "nCBVFL", "yqA6di", "z8eWPA", "wFfisH", "Fh3i-k", "Uno_ha", "_ofQq6", "y65keN", "fRe_4G", "8JwEUQ",
                "Y-2W6Q", "4WQmJj", "_kHpEk", "O32yWD", "1NKOuP", "0_D_DT", "fDq2LG", "uisHy2", "qThOEp", "FWuWMN",
                "uoCyLX", "BMKuQT", "c22vBd", "VxwSf4", "DA8vsO",
            },
            nimbus = {
                "cdeLvT", "EnQsaj", "gg-K9s", "-2fmeY", "5pc1Pr", "8tr7iE", "8rE4r5", "utRdr3", "w1wF1v", "V0G5cn",
                "3yuoU_", "k1dwzw", "KrEckV", "KZR0Ta", "MTVXrF", "Rl573L", "DgEjVF", "DxvS0I", "9Hi-G4", "nbBnO0",
                "hm1-HC", "vxde84", "yTnUvM", "EuP2oj", "ASVC6V", "msvWWa", "69ebaA", "6QQuvt", "rFsoiV", "sAw7-r",
                "DU2EgD", "MGwmRc", "o4i-I9", "mQ0jKr", "-fvLt0", "W_zmtA", "-LLpIH", "hVRr3I", "jeSReA", "YrAMoG",
                "1yvI7G", "O2VD24", "9mGZDI", "c18AoA", "E91YeK", "fTVjjZ", "RUmJQU", "HH5XGe", "Y9bgra", "DaBl7T",
                "KPAWCt", "4RRCga", "Ygb1G7", "3lnkA6", "dypA5l", "Zs9SDi", "VZvcVX", "D9Y236", "6SZj5k", "h-GzXA",
                "YzX17x", "YL77hP", "ifYdRS", "AZK7Cd", "dsIW3V", "o1lWNs", "u1z_Le", "M8t44p", "ASVOku", "0SbrMF",
                "vbMnNN", "0nFNWT", "mZN9-y", "U5fGcw", "FE-JMj", "ch2B9Z", "WB6f4Z", "iFnkSi", "3KaZn-", "ZOuZ9V",
                "j6E2gX", "2a2gwJ", "Ro-Uam", "JBW_bR", "Iq9gY_", "Lm7IcV", "RXFJm-", "reGDxL", "LYZyXG", "YKtExO",
                "oMFeZc", "vENja8", "spUHJd", "srZQrF", "hBFA49", "YXo2fd", "R0Mysj", "PQTn2K", "4uN3gM", "4XZ6D8",
                "ztRqdD", "WUrew9", "tSsMoG", "arJgfw", "NMpeUF", "2f0PZt", "DBp9O0", "Z66rPO", "DDEkzo", "hOEM59",
                "Ru3bzm", "k5rDA5", "hfNMf_", "UU7fVF", "J6MeA6", "1Su91f", "SDBD4T", "woWVh_", "JbaEgu", "qdy8uR",
                "siZSB8", "Zd1ko4", "wottW_", "HJ5D3N", "emejZA", "qwPFRV", "ZD_CBn", "uPDavK", "35hwDY", "JxM5xH",
                "yEraTG", "_eYnoc", "GD-3Xv", "jrK5hZ", "Zm_QZ2", "4LTBso", "Fr9fRs", "nXQw7r", "_Zy2pU", "q3vgbD",
                "YcVgf6", "TQwd-1", "ezEMtS", "PKs_yL", "k_Bosk", "VaGUJF", "vtczSi", "VQNfsb", "jCFfPb", "pE4ojt",
                "WS7uL_", "0qA3Y2", "Qy4GvJ", "AWv4Dy", "UXfG7p", "vXHzKE", "xGVKS3", "2zGsS2", "gQPabn", "s--rOQ",
                "Pc2_ki", "uwggoU", "r0SEht", "cNhF-2", "0uhVFt", "NmuFrf", "EJT_dD", "tf6uwA", "VQqnXg", "Og9_Rw",
                "imPpVM", "t9DdHg", "p91RTC", "HAOyYs", "IcTyvU", "jEE0Kv", "BJGqU4", "kcccBn", "XXJ5GZ", "uzTYM7",
                "KEs5Mr", "B5k_LS", "VnamFH", "lGuzZy", "X5gW2c", "DXDc53", "ajZCQ4", "mXdq4s", "hlO3q-", "qXcG3Q",
                "xn_bkC", "B9Uf7K", "3fFE0a", "UokYmc", "bpRj_J", "7Jgqqj", "9xbVsU", "pHV-r8", "xCurgw", "cvXyX2",
                "p1rSoO", "90pbW5", "Tr2g-g", "2w8ksR", "wMc4CN", "JK0g7Q", "mpST_c", "mYuS6U", "LAr34x", "4Sdif2",
                "WqkFyX", "QCdHjB", "9ZDMTk", "RW8X_T", "Co9ctL", "u9oAar", "fFZj57", "8megja", "Bvq2rM", "OgMz5m",
                "nfgyQY", "RnB_qM", "1z-hQ9", "7EZvCE", "7mnvHv", "PeXZex", "O8UnJH", "xO9ga1", "hFgAqN", "Xdsv6q",
                "bdZMYD", "MaNXhQ", "Ot9_sd", "8LoCB3", "ku8-dR", "M6wtq0", "0H3j2M",
            },
            dunes = {
                "kjHLQh", "JyD9oK", "c_qb3A", "1QaPSq", "DJNZD1", "j6T2pq", "0uP7b7", "_34jSv", "bbCK0r", "BOIX9J",
                "i0np8q", "gjezo2", "DBDdn5", "KH-sCe", "PHSFUE", "GwOERh", "cK34vW", "VKft58", "cd45mY", "mK285c",
                "0oR33t", "hBBm8z", "DEsxis", "jsa_JX", "iT_pya", "tOuUav", "ytwBtB", "aHZElq", "jVlwFh", "OQzhBW",
                "8OyPal", "AJYQdj", "dZrONC", "TrAulx", "tCumNq", "ABPTGy", "LUaHAY", "979f5G", "0bH64Z", "jslyOK",
                "CItjVX", "VVqgC5", "uTKrGT", "3qIYHD", "vBgNHv", "5Nxv-u", "DfX4Ef", "td2p72", "tx1CPC", "wZKFSi",
                "v08Fl2", "iIGh28", "eKV4q3", "F2DP_d", "wEHWxx", "91WKO3", "5Qk8sk", "7tNYtC", "0258mW", "0K4i81",
                "OeR3rh", "Q4oUKN", "ApG-EZ", "PnT75N", "CJ5wLx", "tycpnO", "O4XrZk", "GqHQkM", "o-QgoF", "3zuqKX",
                "otPaBW", "ub9jMc", "ChDFGt", "UKydZv", "8y2Emi", "SeEFkV", "WC8uP7", "oLd8md", "DqSnnv", "D91x3Y",
                "5UEgCH", "QFoxbP", "_KTfgq", "MFNtd_", "z1R73g", "DMUaXm", "p2zoOC", "GDVrV5", "p3ghWd", "SLB2cK",
                "9oHBKO", "TdswV2", "h_7PW8", "Yfa2Nx", "e5AF56", "GCa3Af", "VPre3-", "O7UMcw", "EpJvb4", "JQhuPL",
                "XRhBkq", "0q3NdM", "7ewRGF", "a7Qw7w", "mw6_uH", "OFWbaY", "AWh5g-", "8U-hwz", "8mE8Cz", "muT44E",
                "mm7tmQ", "DPGfmL", "1fErxH", "7ttFkM", "0st9RX", "ArPPuu", "jSkko1", "QVb1Oy", "QDLD6T", "0LA1RZ",
                "donYFd", "pCGk_4", "pb6SHF", "dYWJ-R", "xdfqBV", "4Nr34A", "yvpQXo", "uyZdWB", "U2LmCB", "ytDCnf",
                "hJZcbH", "hqL2gD", "EQEvHi", "1Kc9Pn", "d7VxTc", "sebYXD", "PngyGi", "7f7KEn", "FiYBiH", "fVw1aa",
                "PHrYKv", "6pfjSR", "JPseGP", "pdqe6N", "rWGVZx", "hNc8oB", "0qO3s-", "P2hsW3", "oSLX-6", "AuwSb7",
                "8PRize", "dRm_jB", "daJrLD", "U2bW6B", "PMWQAo", "nbKuwg", "O1S48D", "eavk6X", "gOwUmB", "FFApKK",
                "MxMqkE", "gyRZBq", "z8Zp7X", "B3qAQu", "O_UVyp", "9OeU-o", "GqPgCG", "4Udk1k", "5J8hCv",
            },
            haze = {
                "k_EA5-", "SzpGCP", "uJHNVe", "8Qonjc", "xiteS3", "n5QW-C", "IuUYEJ", "dPwoz2", "DHLMcU", "xzDec3",
                "y3mBGn", "328q0x", "mNMYKT", "GqTBzF", "P-KW7B", "G59Mi8", "Qeq74Z", "FPvTxa", "Pgp-G2", "s5w8ZR",
                "Nwmp98", "eF6PCu", "ap-L47", "hJ8rtP", "3wF4pq", "YaFgwF", "DAsg9N", "4xuLXp", "nvL_Sb", "p1wCAt",
                "BGMbRE", "2LvuBX", "QtX2MX", "yWzxmS", "q4oR4k", "wW0pM9", "PZsLoS", "UHBVp6", "DaeRB5", "a6pHGN",
                "cjUN-W", "QXQTqS", "-gbkXx", "_WX6Qz", "zDQ3Tf", "E-zWby", "M0edch", "mLEJ4z", "81cYgo", "YGjc0k",
                "a2kDLL", "jkfLAJ", "hHJ3m7", "NcBOc8", "c_1wCP", "K2_Zxd", "oZWwbW", "WaxU6c", "rACjNC", "khQWNN",
                "JQb7HY", "RoKPkb", "zTfrwf", "ocgSvg", "2W3390", "jSmD9g", "uR9r1G", "mpUjsQ", "8Kw54_", "xXp-Zg",
                "SuuE1H", "pE_z4G", "rQ3VCJ", "yWKCc5", "ZbPeKU", "2awO1W", "548dQN", "Zp3r_B", "2iiUPR", "GD_nrU",
                "uU7-ef", "m6MuYt", "rhPhrK", "F0QD23", "3FTY2X", "Tq0Epo", "LmnOeW", "LTQqmH", "1MO_87", "XQP05R",
                "mDQuHR", "2hBUOe", "S1cR-O", "d7jacs", "4aMVh0", "CBqF8x", "NyYpLe", "etasO1", "fUvY4_", "EmgT7M",
                "9tmmWX", "OKrErt",
            },
            vinland = {
                "9PZUzn", "QRw2Rt", "mLwFTZ", "aZb1jP", "Ei_8OL", "AP8dXx", "_fVhwa", "OkJXnt", "Ot0Hrn", "VZVAcs",
                "wKGBbj", "9zew35", "4PrRoK", "_A2jSJ", "muM0gn", "chJTLM", "iaBXsj", "BVB0Zu", "ERJtrm", "QSLpW2",
                "hhAwJL", "OHSeFD", "RRWxp4", "6oCBWJ", "Ze9nyt", "MvuXNh", "hFi_Rr", "xqdqY9", "o_rM0Z", "7kV9N_",
                "saLMrG", "WFx0r5", "iSMnJm", "K26t6Y", "hRmG8p", "D8RV-a", "oHeTpn", "bGFYtg", "AmSTyi", "u8aN6U",
                "ytvDo3", "FfFT1b", "uL3XYq", "2X6oay", "Pq_4se", "qKkdJY", "ZuNMRQ", "jf9xJb", "_02gaY", "HAVpNo",
                "A5a3CL", "zJFReR", "gUn7H7", "aiy5Pv", "D1Q-PQ", "UN3zxL", "krqs6m", "SMO_Y1", "NU7gKV", "gCb62t",
                "jbWndN", "NB9Cn5", "ZTxUnk", "KF1loD", "T625xx", "6zPdQC", "46qYUA", "Ekfz2t", "tBSBuq", "XMrkBi",
                "NCbuxn", "_Uh_Kx", "W-hUcN", "_huiKB", "dCEZ42", "9U_wJr", "X_2-m6", "twPOqe", "PucpvX", "e0SPqJ",
                "8Q958-", "NDVFK_", "4ghe_6", "MTSp2E", "NUPUQF", "XQf46G", "AVDs18", "hTiOfF", "azpYV0", "3TtVZV",
                "9QCpQ1", "n1HqKD", "6n_NNu", "D0wOpL", "wOP_UD", "z4O55W", "3ypNv0", "d8JFNF", "-93yfL", "N9jyZc",
                "eUclSG", "o1SkpH", "nyjgVx", "WqcztZ", "76fBbq", "w6UKd5", "Yw5BPN", "D6yTE-", "0zJVoX", "3eFtfO",
                "NrnukE", "fycdqQ", "KIsbQ_", "mfwci-", "dgR_da", "XJa1dJ", "QBN15K", "GFZ1L-", "mcOHjs", "dHQoeu",
                "2LsOsp", "cygBio", "sRsnd8", "UplsX4", "jj-iZx", "KUAIoy", "GIdQeb", "n62GsH", "Q6tRNv", "z5MX20",
                "td7aTp", "1Gs41a", "6lbj2Z", "FpE_3e", "ozfuTQ", "YvX8z_", "gCT-4b", "qwOghd", "eYWUj_", "z4uJP-",
                "gM6PCR", "jYq0yD", "tcucju", "dHfdOU", "bYHU0h", "JW0wGk", "PwWlxK", "GS_2nI", "X0mKAW", "9mGUcb",
            },
            forest = {
                "PtyUCG", "QqeKj9", "Bp66ht", "0YjmTf", "1XjC0A", "EXgFws", "g3YHu6", "r8j0DO", "bbzc8a", "SnpGFN",
                "ZEavDD", "AtqYsx", "CpF3mt", "O_EhTf", "7uixdR", "FrOKMP", "6p4zRS", "ru-xOn", "1RxZXa", "S2Fxx-",
                "ZL0867", "NBaEpL", "KTds-P", "V58o74", "59_Tfr", "soksfX", "FVwA6c", "SGy28e", "hSCOWY", "1LzeME",
                "ErdOLV", "Z6vghd", "jpLbfk", "rPprag", "vTTSgM", "pVLc9y", "bwU1HU", "yMkhAd", "r6cNCF", "wTTuFk",
                "ZVbbA-", "RF_kWT", "pwzhUx", "X9tWQ6", "UPZjnj", "d4y2Cw", "SNLkDX", "tjS6F0", "3DLqyR", "xxKdfu",
                "A0tpTu",
            },
            valley = {
                "CwUcdw", "6WtZU5", "zQOd95", "PcYb2t", "Rik4AY", "kbWUiN", "OSX5pn", "j2xkXy", "amTKZ4", "HZ73Uz",
                "zpSPQ3", "uNmDUC", "dsbPap", "UJTkiY", "uPnGFS", "PcLWXv", "tOc6NI", "Dx5HXV", "1nhjzU", "cN47nA",
                "AFyav9", "0hd0Dq", "67hMtE", "RJ_osx", "8QTsTh", "9mbpz6", "sYe4D-", "y0q8-3", "RTzCOb", "OaMjoZ",
                "hUE_0O", "janeqc", "kLEqNP", "V8tnKf", "AH7uLs", "aoVKmH", "J0Xgau", "fwRGeC", "SUWUfO", "9S90eU",
                "9nGdRq", "rSccSk", "tjhOtv", "hR67d2", "bkarof", "X4cjq1", "cQNrYn", "GWhhBy", "NSEaBC", "s-oFTA",
                "AM_Jy-", "LKThR1", "RuqHC-", "gd52Eo", "P3hQxk", "bGC41C", "WjQs04", "_hskCQ", "nfd1S8", "V9LMdR",
                "D7ZbRe", "QtPcQm", "aKEBLs", "f-dChp", "QPTsnX", "Zf-Mne", "aCjQJ5", "pDg1xE", "Y8N7uU", "Jvu4xp",
                "zpxCLu", "LTMPm4", "GnS9f8", "7rhgEp", "vW5FEq", "G4MoPD", "_6dPxJ", "uS9Kac", "8yS6xi", "fV_0T1",
                "MoViBq", "qbqHaw", "9ShuqZ", "pU_-Q5", "k38Psn", "dQ9LGM", "FiJw2d", "a3vKxa", "xYcLVA", "meD8zx",
                "DkyGnu", "YsGbTH", "dfjBpd", "aoilqQ", "3BC5UC", "pnJA-W", "FTEdAS", "0u10_P", "aUjZOe", "rePW1z",
                "0QWfcY", "u6d1kr", "zTZrxV", "mjIuKB", "RTZSt2", "V0KbEd", "jo_twK", "_RlSEe", "1u1Qa7", "eDdDK3",
                "hM_NEl", "bnd9hg", "xs2ex8", "udrGSV", "T1qTXg", "TMmqXj", "B-Y1Ur", "nNx8to", "6aYFb9", "JcWINp",
                "IStWXT", "qa5Cm6", "n0KRPO", "Vjn2ag", "zjefKP", "W94SK0", "nLRJJT", "o9ilgb", "Li8JXA", "oo7V5e",
                "IKfA7V", "4wdOHk", "suJrjY", "qGY0lM", "Sl2QIO", "pGjgp4", "X2lDNQ", "QGrQAc", "WpcJfE", "27J2Uj",
                "lM8yje", "qonYLZ", "1eRi-N", "8nzqo-", "DdK4hQ", "K_QgsL", "ynPAha", "bIr6eA", "LSAvOb", "u_8Nsd",
                "RKwiNk", "cedsOz", "cMKfYV", "XBE9Sc", "u3yPxi", "DXgJhn", "8bX3JH", "tZaVIk", "pu3QHf", "OYJgqH",
                "MjkT5m", "yrFdl1", "BN-9og", "NPjbBb", "MuSbQT", "L1hWO6", "MFFpKK", "dXzjun", "k_3h4C", "TrX6Pr",
                "pvuTZX", "R-5ip3", "xoncEY", "q8qDYb", "66idLf", "AWGUbo", "ameY6L", "5S-2y1",
            },
            tempest = {
                "clM8Ya", "hiusw7", "mPstuG", "ajmbsg", "QeC90r", "clBYIY", "VGTIH_", "Me0N18", "hbpHqG", "ExvyLL",
                "4aTrwy", "KiiLWd", "7DLeZ5", "TGqHes", "rm3zlk", "GdLf5x", "kGzK24", "wwUl_X", "2B4cJP", "MQNZS1",
                "ovzAqp", "1WSvLV", "yMODbc", "jsKAFU", "om40he", "7K3_s2", "xXAy5T", "peWrO0", "WEe7XR", "JgjgF0",
                "tkN4P4", "nMQZrQ", "4gdXEA", "Qc-oFj", "ganq4R", "qt7y49", "D_ox7q", "fQUQYh", "OpyKRm", "76CgQ0",
                "NV3JfY", "D-hkZN", "tfr9uN", "YA1ztL", "RLV7jo", "3VG6fN", "bdh8GG", "6LNHXK", "hHVY5s", "TTuFC3",
                "RSjQsz", "vAw0Zw", "N5Wo1K", "yP4X_a", "LYjwAM", "bGKEak", "DGV7h_", "hrGhUP", "rVfAQX", "nbFJPg",
                "Vzv0ss", "xUQL1m", "dja-bC", "BhQoDg", "3msTOh", "kAK--6", "cv95dY", "Qktj0v", "Z0O9yo", "vLZVGJ",
                "2KFoRM", "PeZDYW", "Efw5xv", "f2c_k6", "gCOR-h", "tNyBrn", "E0-uHK", "C59dsV", "m-QqGR", "3x47Xw",
                "y-uWDo", "JSAtLB", "M4VHkx", "HHEZAx", "aEGYuK", "49EbRS", "ZR8dSJ", "dx0C1T", "0u5_-o", "HBUbpx",
                "UEWX7o", "29tPAh", "QnGgRk", "fd9x_9", "aCa368", "51orXp", "NVu1WG", "MfdUNo", "NbL4BB", "HOvFtr",
                "nrCCus", "Y_f9Ua", "Ynmoba", "0M84pP", "W_Qyy-", "qsNbs1", "UtNyb2", "Y1vWkX", "SxsAkP", "e4CaNV",
                "oK6UMZ", "vnej7C", "LbNFFX", "cuiD9V", "ix3HBq", "SNYywm", "W1rpn9", "iyssuo", "aH2RJf", "ctm8St",
                "Mjm-ga", "FosAre", "uzC2R7", "WBQUJ_", "08HGnz", "6zrCDv", "NBm9fA", "m18REp", "k3KLeh", "bT9aAT",
                "GRQZQB", "jQgko_", "5G4OSX", "HcJyCo", "pc7yF3", "3GtSGH", "QZZ-Xf", "07fmMt", "QxM6og", "YWZoMR",
                "2WPk9G", "mvOsPo", "nhfi2y", "z5o52L", "zDsap0", "ZXc7ys", "go-Mp4", "RTHgom", "5H9Gvo", "SndzyE",
                "k-VZLc", "XVaLcP", "2LS2yC", "ErsRpy", "SKjkgz", "dO1qwK", "7F8uYZ", "PEBYKE", "xF5dfh",
            },
            narumaki = {
                "_NeQsx", "OZNRd7", "4TaPeU", "sgdMpU", "i4QN9v", "AYYqFf", "Dbzn6u", "3L8Ygu", "eHNDMc", "jVZ3_o",
                "Qfcn9U", "d9pHeZ", "KZoWPL", "KTD-nL", "HAiPmD", "_XmpKL", "qyYZEO", "vtgHhu", "3LAHby", "3b1-cU",
                "qHbjmE", "zP6ThL", "mpHkti", "tO6cgK", "mWgRGu", "x7PKS2", "Jb0q5S", "UTzbZm", "NtPS2w", "w5sDFC",
                "ueobFe", "NBXgvz", "j7HB2h", "Kw8uXx", "kBpYSV", "RST3T9", "KoBnyr", "A8tP0x", "bgk58F", "xmZ2s4",
                "6eLfPN", "6u9Eq1", "z7BPQz", "0FuAAh", "eVdX8a", "T1V_uR", "30YSZ-", "DsSpuQ", "mCeujT", "TpppdP",
                "970EfD", "uzb6qH", "oVbO5W", "aXm_vk", "yFPoTw", "q5ka9e",
            },
            training = {
                "5doj-B", "_gDIcA", "yPDCX7", "IVGMx8", "WxUb20", "u5mJ_j", "80GFb1", "37S6b9", "-_bGsT", "JsUU-Z",
                "32a934", "55XWav", "8jovyH", "_ObYgM", "bBpOy0", "5ETvhC", "6sMurh", "azsAGY", "KGkQCx", "ZbMw-Q",
                "11r70l", "EgV2KR", "1ChuDd", "rdG19N", "G04KZw", "vGGphK", "m9kdhz", "LordQ9", "HwtTTt", "Kr_O_V",
                "4fRtk_", "8qSNkM", "ncmnVp", "VB_oMH", "ZMx-pO", "JbEVKV", "_ATBoD", "hQcQHk", "ZddHgf", "w5DxwY",
                "OgjQOC", "AyYn4h", "Gb-c1U", "eVVW8e", "X2Y7yu", "kpM4eM", "cubSgX", "r1Ynkn", "2_Z9aK", "vWrNeS",
                "VZoiZs", "TsvXp8", "mwqEsk",
            },
            conquest = {
                "bfkuxr", "HDfPFe",
            },
            maki = {
                "-6z_r7", "nA_CTN", "Kk1_HH", "dKwBq6", "vFZ8_J", "Lonn2a", "kHra48", "u_4P8C", "a9teAc", "WLPkGu",
                "mffEM2", "m7jT4j", "bFMwMB", "1Zw1RM", "vX913P", "NJUVNZ", "7xzE85", "Jn2DMW", "NxcONg", "O6fCSp",
                "e7qgBd", "xuzc29", "BquxoB", "bc1Vry", "3uEOQg", "nk_0HN", "jiuKwM", "K-26se", "Qw7T-P", "5M1ttA",
                "EynhE-", "z4LqW8", "rdGp_9", "ddt_Uf", "1SNU6P", "Z8GmqQ", "NqD0tt", "G-XTnq", "uhUNRu", "A4s2KW",
                "Eoc77j", "nRZzRq", "UQztSc", "bybUvA", "7LqcZy", "v7gWXw", "rdJSX9", "nFQS83", "exNUVp", "LOsuPF",
                "NK5sKb", "r3wdkw", "ivouM3", "M5snNQ", "b8JVqb", "0P6fnO",
            },
            ryuji = {
                "xyUudp", "AzUVp0", "t4WbZM", "yhZxnu", "pNq6X4", "LVVskV", "khvmYj", "MdcfAc", "mdREeN", "OZNEA0",
                "JmrzED", "8VXYDi", "5giQHc", "G9Hlda", "3V1iR8", "DXvnGI", "hv8T6J", "XRwYU0", "sujDw5", "fXO8Sd",
                "FAmNg5", "izLDaG", "MDF7Ve", "pX-PzQ", "mXmk7E", "ly4wOl", "SdPyK-", "oXtQHb", "Hq2nHx", "y8J_8T",
                "v3ezvl",
            },
            espada = {
                "Akww4B", "_7EWQG", "PcO0zJ", "ggCtBP",
            },
            jejunes = {
                "9KAwrP", "hWE8in", "swhYEM", "guvf30", "V40gH5", "ZDA2Ee", "21U-bv", "-qhOJe", "Ka3-c0", "eA6Co2",
                "aQiYne", "lpV0Ca", "mJ37yb", "f-fISM", "xggsbV", "mYRTjm", "ggjYUt", "atbE3T", "J3SSib", "tt19jg",
                "5EuQzD", "v7o994", "eFJ-vT", "Q8KGOE", "dfx5W7", "BnvsTw", "bEHsFn", "GXvGCO", "wfU87k", "4zSQUP",
                "3juFj7", "T-c-MK", "O4_MQv", "1gNmXv", "FFQu59", "HrghPQ", "EPg9BV", "bsaAH1", "BLJn7m", "acTm4H",
                "21H4Lh", "u1cDhu", "aMeKUb", "4-bpj_", "xN_6Wr", "Yn3EjG", "O8XLEU", "kF-eY1", "ca6KLh", "F3819t",
                "aXxUNW", "w2SUe2", "38V487", "1XxLs_", "9cr9S5", "gZzJJm", "F0rOeM", "k7uk5P", "N3NmGF", "hU1zzL",
                "1aFDnX", "XF5TTC", "2XoQXu", "UR7xs9", "nd-OFS", "vwmr6u", "rzEi3T", "i-cQvZ", "iFzeQ_", "9ic--K",
                "nZRZ8x", "hq9Zf1", "MiOP4a", "E7BHUx", "gTywSu", "dYQnDy", "4ijsJX", "16VHoD", "CkwN5P", "uAVNOv",
                "Nc4wF_", "voUue9", "8G9BhD", "sS6FGF", "YFZMBo", "8BYMU2", "ObZhka", "MGfqK0", "D58LnP", "mA9Uqo",
                "Cegy3u", "o2vM9L", "jYy894", "08itCg", "nT5ih2", "md3kKh", "bLsRt-", "H-zAz0", "6FiYqQ", "B0aBDx",
                "KP3BE1", "FT0cV0", "NRdRZ9", "MgLCEU", "RP3DR7", "b4UY5X", "030b33", "vDinuC", "L9D0ff", "FgkQU-",
                "2CA6f3", "HW_uVx", "QZKEYw", "Qb93PU", "L-uBUV", "UvJj_8", "MEQbOg", "mcMQX-", "Rv6kZ7", "8ncOQD",
                "s-w3zn", "wJgscr", "G4U81i", "gnmDPN", "0Pj2rc", "GAdz9x", "P5gH8d", "rsUCFa", "8pQYQJ", "GDX_m1",
                "OGWomV", "oArdxT", "QSHs97", "KtWESX", "_oLa_r", "ZKcMaH", "TnaiA9", "adf88e", "Ou8hrv", "_1ggv3",
                "qvQEK3", "LPreHN", "5XE7U6", "JTaaUw", "KZcWxe", "9E70VU", "zcjPPa", "qzQHeW", "GfYkfj", "pYem64",
                "Le1vGb", "rDrPpO", "SZxu67", "ero5Zg", "iy4GNM", "cu4b00", "KuYSQt", "byjjMM", "VP6k5P", "onJS7p",
                "gkUQXJ", "0uQCxK", "qwraj1", "bNOxnb", "jTgjEm", "xZAd5o", "rr8XJy", "rE9dB2", "kaqh72", "RWxiTG",
                "Vyt_Uh", "SXX26K", "Jh_xNV", "eQszqH", "9P3ao0", "gD1BQt", "duMXNl", "wmdN69", "U60ku_", "tRkCsd",
                "DWHyug", "5sOyHU", "4j5P9J", "u8ABwK", "ZUjq8T", "i6NlIw", "5uZqit", "fOROH2", "h7gQsc", "yGlmMp",
                "Vo7JBY", "C89EbW", "jqbbmd", "boLsrZ", "Ltf-c4", "g6qvMu", "6rSiB6", "DJjVXF", "_BI9VE", "m_iFMa",
                "WYkR9f", "iMFOlV", "Q0Uxr4", "Q9hN4I", "dz1cr6", "yi_qi2", "zjtfFE", "YMzTfY", "JNvakV", "0e7UAM",
                "JUStD5", "7k9v8n", "jPD_iB", "7348VJ", "wa1jK3", "iUTQYm", "jHsF-E", "3T3SvN", "0-uFaO", "v5k55H",
                "x40SVk", "H7yUV3", "fxPhVp", "Fx-T7K", "N-Yc5C", "tt2v6j", "Oynm4i", "zhpBmf", "Rg3jcN",
            },
            bridge = {
                "4bh-U_", "Obqa6S", "huxZuh", "HqUaek", "LNW1yY", "TgVMJI", "09qkoP", "bcTdUh", "mLuOOA", "DgIndz",
                "FzqC-S", "2QIsEf", "vTd6gX", "KdG-CE", "bUs0Cb", "Q-JZcl", "TQb-up", "8FQLSj", "tyRlB3", "eWe26L",
                "zfg5QC", "_VEh8a", "s7Jmna", "ZW0y8z", "WYdq58", "FMKOS5", "XAMqZD", "b_1aC-", "M7LDFT", "n6e2NQ",
                "NVnERa", "o9Hc4e", "nbn0-Y", "4ADD9y", "y_gDXn", "t1AkPJ", "y5sADH", "U12wpj", "tf6OXm", "KMoAiF",
                "H4zUzS", "jqsLgu", "rxQjcp", "0OP12A", "Fh-3N8", "GPpnZ4", "fOsAo2", "rB9_wn", "O8f-6o", "SBXMH5",
                "BkZJ-F", "y6dqnW", "1QzO9p", "LP2uzL", "3sh7aE", "t9e9WK", "58g9Uv", "hFUZGv", "g5sPE7", "mytTfS",
                "HJX7kf", "ELCBy1", "QWoQva", "0bfLDU", "UES6vd", "v3EPfM", "UmteoF", "icJY9M", "xy188e", "0XddP6",
                "6QWtzF", "eWoLig", "zNM96v", "FB3G05", "xs6RmQ", "e-BjhR", "g_YGPD", "a0wSSL", "gFK9pj", "q-3Apg",
                "zyEDRT", "0TF2Ni", "eiAHA5", "M3eCmT", "TeXpLK", "j4rQ-D", "Rz6hEt", "mQvqUE", "Oj45G-", "1SfsPh",
                "5vf4Bo", "tF1FMT", "X1vpyy", "fQdf6S", "hLR2ny", "SNf2tV", "rnUwMz", "FdLRDE", "juErdu", "9mP2zu",
                "mSrBo9", "QDzNbg", "XdzW3V", "gRymo8", "ivYdYx", "vufDPt", "m2ULd4", "g8QEe3",
            },
            shikai = {
                "NipNkN", "rHtX6r", "isCXGC", "O21tUW", "5bM1Xk", "fJ0Eke", "LvqVbo", "Au0kJj", "pjWo6j", "MFJdGA",
                "5Ukaks", "Wv8nt-", "DAtt41", "YOtRyC", "7b1meE", "NCi3aZ", "MmMO7a", "fQLUw-", "LL-nPg", "hgUdnu",
                "W8AaCq", "WnepfJ", "pif9uz", "b26SYj", "XMbEi6", "qRPHqi", "Y4w5LL", "OU0jkU", "2MSgs2", "qk0240",
                "a54Mh0", "4r112h", "tJMxzW", "94ZHEC", "Jfrjc9", "o2CjHM", "eBgFdi", "b-etw_", "9R6J0f", "Wgas3x",
                "09FT83", "eOMiL_", "wE0_CH", "7VtJs6", "BfysGh", "TBx45D", "JririF", "Y6RXtz", "xbyUuc", "dm2Cro",
                "SprZ8z", "pW_k02", "6zeMmg", "uaFSD9", "FRdNJ0", "yNtMjH", "1dxJGR", "D2BYSF", "XtNRMA", "4eLN-b",
                "rWxrPB", "NnqxmT", "8ki4lT", "BNLA4m", "2xYTPc", "3k5v_I", "RtTFct", "hWW6H_", "T-2syj", "YzgORE",
                "BlFBCL", "dlWV1Q", "LPOPko", "P4kd0N", "d9sULu", "nzb9Nn", "27QNqb", "ji_8FQ", "PfAagk", "zkGtHU",
                "1Rke3H", "2iuxyA", "0VMOIv", "jC4WDh", "FyYl_Q", "N8lPpx", "dNObrL", "uNceZz", "_lKlhY", "nlBPGT",
                "MEJYU9", "PNTvo1", "EXzgEd", "fH9dmN", "b-d4wx", "mhCQVF", "2I1sTf", "O7mE0f", "mPdb3G", "s4Z2PN",
                "m9-yvn", "vcw74g", "00H82o", "fe4a9G", "0nziFE", "mVxcTG", "RXrqhs", "B0KOgs", "A88c15",
            },
            storm = {
                "fwJkMu", "sTLf6S", "n9ObLL", "vwJCg7", "F705Ck", "Ma4a6o", "LQ8sOV", "FZTwXs", "V3LOlI", "ZvXZND",
                "ir6z3z", "94nkGc", "yZ3wL-", "OVjnP1", "bVtQKv", "cew0OJ", "qPdZda", "-NsAub", "bSFIDx", "G6Mkv5",
                "kmGafB", "v_-4fR", "t-_Ax-", "kqJuQm", "eXHpWG", "6T38-g", "9vMS00", "mNekH2", "X0DOQT", "TJZcQu",
                "UQM-vS", "BoZ66J", "GMwsbR", "ZC5xAj", "Qnk0xX", "mYXL-P", "1SpD26", "SpH1yb", "cGwfHf", "qL2AeQ",
                "6bDhAN", "QUrcoh", "onC-73", "TKyUCS", "bHVBM7", "EHx_5G", "Reggfn", "i71zcm", "W4n-As", "7-Z1zt",
                "T8paw3", "JqwQvT", "wsrkLW", "UUTJe7", "vfOjWD", "jCXkOw", "63vQuW", "saqXs_", "GsDbnu", "BiYyML",
                "JmFP12", "Zw-DNq", "dODNK7", "tLQ7U1",
            },
            shikadai = {
                "NeMHRn", "a8_4UO", "RYEDJB", "kCj8_s", "s62Ejj", "Kjhgkz", "X88Lw4", "SDHULr", "xxcT87", "DO4uWB",
                "3pJiw9", "MU3mBg", "pufxyz", "L5IBtA", "AkiZ2Z", "gy8P0Y", "CdSQDR", "IWl4PM", "LLwiLX", "Q3GBhs",
            },
            shindairengoku = {
                "dz3Ay3", "5hSD1d", "c3Rxin", "og8TkS", "jnT1mA", "GLmXHe", "bOiiFu", "M-wCtn", "FQTe-S", "JGdvtQ",
                "69h2KV", "hB1TOX", "JomUaf", "Hc-Dx3", "BFjcpw", "momu7w", "05cU6U", "7k3CZJ",
            },
        }
        
        local ScrollData = {}
        local ScrollWidgets = {}
        
        local function parseScrollTime(scroll)
            local getTime = scroll:FindFirstChild("gettime")
            if not getTime then return nil, nil end
            
            local hr = getTime:FindFirstChild("hr")
            local min = getTime:FindFirstChild("min")
            
            if not hr or not min then return nil, nil end
            
            local hour = tonumber(hr.Value)
            local minute = tonumber(min.Value)
            
            return hour, minute
        end
        
        local function formatTime(hour, minute)
            if not hour or not minute then return "??:??" end
            return string.format("%02d:%02d", hour, minute)
        end
        
        local function getScrollLocation(scroll)
            local loc = scroll:FindFirstChild("location")
            return loc and loc.Value or "Unknown"
        end
        
        local function getScrollRarity(scroll)
            local rarity = scroll:FindFirstChild("rarity")
            return rarity and rarity.Value or "?"
        end
        
        local function shouldExcludeScroll(scroll)
            local name = scroll.Name:lower()
            
            if string.find(name, "bossdrop") then
                return true
            end
            
            local hour, minute = parseScrollTime(scroll)
            if hour and minute then
                if (hour == 0 and minute == 0) or (hour == 1 and minute == 0) then
                    return true
                end
            end
            
            local location = getScrollLocation(scroll)
            local locationLower = location:lower()
            if string.find(locationLower, "drop") or string.find(locationLower, "boss") then
                return true
            end
            
            return false
        end
        
        local function refreshScrollList()
            for _, widget in pairs(ScrollWidgets) do
                pcall(function() widget:Destroy() end)
            end
            ScrollWidgets = {}
            ScrollData = {}
            
            local clientTell = workspace:FindFirstChild("GLOBALTIME")
            if not clientTell then return end
            
            clientTell = clientTell:FindFirstChild("clienttell")
            if not clientTell then return end
            
            local excludedCount = 0
            local includedCount = 0
            
            for _, scroll in pairs(clientTell:GetChildren()) do
                if scroll:IsA("StringValue") then
                    if not shouldExcludeScroll(scroll) then
                        local hour, minute = parseScrollTime(scroll)
                        local location = getScrollLocation(scroll)
                        local rarity = getScrollRarity(scroll)
                        
                        if hour and minute then
                            includedCount = includedCount + 1
                            local scrollInfo = {
                                name = scroll.Name,
                                instance = scroll,
                                hour = hour,
                                minute = minute,
                                timeStr = formatTime(hour, minute),
                                location = location,
                                rarity = rarity .. "/1",
                                selected = false
                            }
                            
                            table.insert(ScrollData, scrollInfo)
                            
                            local isSelected = table.find(FarmState.ScrollSniperSelected, scroll.Name) ~= nil
                            scrollInfo.selected = isSelected
                            
                            local widget = Tabs.ScrollSniper:AddToggle("Scroll_" .. scroll.Name, {
                                Title = scroll.Name,
                                Description = string.format("📍 %s | ⏰ %s | 💎 %s", 
                                    location, scrollInfo.timeStr, scrollInfo.rarity),
                                Default = isSelected
                            }):OnChanged(function(v)
                                scrollInfo.selected = v
                                
                                if v then
                                    if not table.find(FarmState.ScrollSniperSelected, scroll.Name) then
                                        table.insert(FarmState.ScrollSniperSelected, scroll.Name)
                                    end
                                else
                                    local idx = table.find(FarmState.ScrollSniperSelected, scroll.Name)
                                    if idx then
                                        table.remove(FarmState.ScrollSniperSelected, idx)
                                    end
                                end
                                
                                Config.ScrollSniperSelected = FarmState.ScrollSniperSelected
                                ConfigManager.Save(Config)
                            end)
                            
                            table.insert(ScrollWidgets, widget)
                        end
                    else
                        excludedCount = excludedCount + 1
                    end
                end
            end
            
            ui.Fluent:Notify({
                Title = "[S] Scroll List Refreshed",
                Content = string.format("Found %d scrolls (%d excluded: boss/drop/00:00/01:00)", 
                    includedCount, excludedCount),
                Duration = 3
            })
        end
        
        Tabs.ScrollSniper:AddButton({
            Title = "Refresh Scroll List",
            Callback = refreshScrollList
        })
        
        -- 🆕 SELECT ALL BUTTON
        Tabs.ScrollSniper:AddButton({
            Title = "✅ Select All Scrolls",
            Description = "Select all available scrolls for hunting",
            Callback = function()
                if #ScrollData == 0 then
                    ui.Fluent:Notify({
                        Title = "[!] No Scrolls",
                        Content = "No scrolls available. Click 'Refresh Scroll List' first!",
                        Duration = 3
                    })
                    return
                end
                
                FarmState.ScrollSniperSelected = {}
                
                for _, scrollInfo in ipairs(ScrollData) do
                    scrollInfo.selected = true
                    table.insert(FarmState.ScrollSniperSelected, scrollInfo.name)
                    
                    local widgetName = "Scroll_" .. scrollInfo.name
                    if Fluent.Options[widgetName] then
                        Fluent.Options[widgetName]:SetValue(true)
                    end
                end
                
                Config.ScrollSniperSelected = FarmState.ScrollSniperSelected
                ConfigManager.Save(Config)
                
                ui.Fluent:Notify({
                    Title = "[✓] All Selected",
                    Content = "Selected " .. #ScrollData .. " scrolls for hunting",
                    Duration = 3
                })
            end
        })
        
        -- 🆕 DESELECT ALL BUTTON
        Tabs.ScrollSniper:AddButton({
            Title = "❌ Deselect All Scrolls",
            Description = "Clear all scroll selections",
            Callback = function()
                FarmState.ScrollSniperSelected = {}
                
                for _, scrollInfo in ipairs(ScrollData) do
                    scrollInfo.selected = false
                    
                    local widgetName = "Scroll_" .. scrollInfo.name
                    if Fluent.Options[widgetName] then
                        Fluent.Options[widgetName]:SetValue(false)
                    end
                end
                
                Config.ScrollSniperSelected = FarmState.ScrollSniperSelected
                ConfigManager.Save(Config)
                
                ui.Fluent:Notify({
                    Title = "[✓] All Cleared",
                    Content = "Deselected all scrolls",
                    Duration = 3
                })
            end
        })
        
        Tabs.ScrollSniper:AddToggle("ScrollSniperToggle", {
            Title = "Enable Scroll Sniper",
            Description = "Auto server hop to selected scrolls at their spawn time",
            Default = Config.ScrollSniperEnabled
        }):OnChanged(function(v)
            FarmState.ScrollSniperEnabled = v
            Config.ScrollSniperEnabled = v
            ConfigManager.Save(Config)
            
            if v then
                ui.Fluent:Notify({
                    Title = "[S] Scroll Sniper Enabled",
                    Content = "Hunting " .. #FarmState.ScrollSniperSelected .. " scrolls",
                    Duration = 3
                })
            else
                FarmState.ScrollSniperStatus = "Disabled"
            end
        end)
        
        local function getCurrentGameTime()
            local globalTime = workspace:FindFirstChild("GLOBALTIME")
            if not globalTime then return nil, nil end
            
            local estTime = globalTime:FindFirstChild("globalesttime")
            if not estTime or not estTime.Value then return nil, nil end
            
            local timeStr = estTime.Value
            local hour, minute, period = string.match(timeStr, "(%d+):(%d+)%s*(%a+)")
            
            if not hour or not minute then return nil, nil end
            
            hour = tonumber(hour)
            minute = tonumber(minute)
            
            if period then
                period = period:upper()
                if period == "PM" and hour ~= 12 then
                    hour = hour + 12
                elseif period == "AM" and hour == 12 then
                    hour = 0
                end
            end
            
            return hour, minute
        end
        
        local function isTimeInWindow(scrollHour, scrollMinute, currentHour, currentMinute)
            local scrollTotal = scrollHour * 60 + scrollMinute
            local currentTotal = currentHour * 60 + currentMinute
            
            local windowEnd = scrollTotal + 20
            
            if windowEnd >= 1440 then
                windowEnd = windowEnd - 1440
                if currentTotal >= scrollTotal or currentTotal <= windowEnd then
                    return true
                end
            else
                if currentTotal >= scrollTotal and currentTotal <= windowEnd then
                    return true
                end
            end
            
            return false
        end
        
        local function getServerIDsForLocation(location)
            local locationLower = location:lower()
            
            for keyword, ids in pairs(ScrollServerIDs) do
                if string.find(locationLower, keyword:lower()) then
                    return ids
                end
            end
            
            return {}
        end
        
        local function claimScroll(scrollName)
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not root then return false end
            
            local globalTime = workspace:FindFirstChild("GLOBALTIME")
            if globalTime then
                for _, obj in pairs(globalTime:GetChildren()) do
                    if obj:IsA("Model") and obj:FindFirstChild("sh") then
                        local sh = obj.sh
                        if sh.Position.Y > -1000 and sh.Position.Y < 2000 then
                            local invoke = sh:FindFirstChild("invoke")
                            local clickDetector = sh:FindFirstChild("ClickDetector")
                            
                            if invoke and clickDetector then
                                toTarget(root.Position, sh.Position, CFrame.new(sh.Position))
                                task.wait(0.5)
                                invoke:FireServer(LocalPlayer)
                                fireclickdetector(clickDetector)
                                return true
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
                            toTarget(root.Position, sh.Position, CFrame.new(sh.Position))
                            task.wait(0.5)
                            invoke:FireServer(LocalPlayer)
                            fireclickdetector(clickDetector)
                            return true
                        end
                    end
                end
            end
            
            return false
        end
        
        task.spawn(function()
            while true do
                if FarmState.ScrollSniperEnabled then
                    pcall(function()
                        local currentHour, currentMinute = getCurrentGameTime()
                        
                        if not currentHour then
                            FarmState.ScrollSniperStatus = "Waiting for game time..."
                            task.wait(2)
                            return
                        end
                        
                        local activeScrolls = {}
                        for _, scrollInfo in ipairs(ScrollData) do
                            if scrollInfo.selected and isTimeInWindow(scrollInfo.hour, scrollInfo.minute, currentHour, currentMinute) then
                                table.insert(activeScrolls, scrollInfo)
                            end
                        end
                        
                        if #activeScrolls == 0 then
                            FarmState.ScrollSniperStatus = "No scrolls in time window"
                            FarmState.ScrollSniperCurrent = "Waiting..."
                            task.wait(5)
                            return
                        end
                        
                        for _, scrollInfo in ipairs(activeScrolls) do
                            if not FarmState.ScrollSniperEnabled then break end
                            
                            FarmState.ScrollSniperStatus = "Hunting: " .. scrollInfo.name
                            FarmState.ScrollSniperCurrent = scrollInfo.name
                            
                            local serverIDs = getServerIDsForLocation(scrollInfo.location)
                            
                            if #serverIDs == 0 then
                                ui.Fluent:Notify({
                                    Title = "[!] No Server IDs",
                                    Content = "No private servers for " .. scrollInfo.location,
                                    Duration = 3
                                })
                                continue
                            end
                            
                            for i, serverID in ipairs(serverIDs) do
                                if not FarmState.ScrollSniperEnabled then break end
                                
                                FarmState.ScrollSniperStatus = string.format("Server %d/%d: %s", 
                                    i, #serverIDs, serverID)
                                
                                pcall(function()
                                    LocalPlayer.startevent:FireServer("teleporttoprivate", serverID, game.PlaceId)
                                end)
                                
                                FarmState.ScrollSniperServersHopped = FarmState.ScrollSniperServersHopped + 1
                                
                                task.wait(10)
                                
                                local claimStart = tick()
                                local claimed = false
                                
                                while tick() - claimStart < 30 do
                                    if not FarmState.ScrollSniperEnabled then break end
                                    
                                    if claimScroll(scrollInfo.name) then
                                        claimed = true
                                        FarmState.ScrollSniperScrollsClaimed = FarmState.ScrollSniperScrollsClaimed + 1
                                        
                                        ui.Fluent:Notify({
                                            Title = "[✓] Scroll Claimed!",
                                            Content = scrollInfo.name .. " from " .. scrollInfo.location,
                                            Duration = 5
                                        })
                                        
                                        break
                                    end
                                    
                                    task.wait(2)
                                end
                                
                                if claimed then break end
                            end
                            
                            task.wait(5)
                        end
                    end)
                else
                    FarmState.ScrollSniperStatus = "Disabled"
                end
                
                task.wait(2)
            end
        end)
        
        local ScrollSniperStatusDisplay = Tabs.ScrollSniper:AddParagraph({
            Title = "Scroll Sniper Status",
            Content = "Initializing..."
        })
        
        task.spawn(function()
            while true do
                local selectedCount = 0
                for _, scrollInfo in ipairs(ScrollData) do
                    if scrollInfo.selected then selectedCount = selectedCount + 1 end
                end
                
                local currentHour, currentMinute = getCurrentGameTime()
                local gameTimeStr = currentHour and formatTime(currentHour, currentMinute) or "??:??"
                
                ScrollSniperStatusDisplay.Content = string.format(
                    "Status: %s\n\n" ..
                    "🕐 Game Time: %s EST\n" ..
                    "📜 Selected Scrolls: %d / %d\n" ..
                    "🎯 Current Target: %s\n" ..
                    "🔄 Servers Hopped: %d\n" ..
                    "✅ Scrolls Claimed: %d\n\n" ..
                    "🚫 Auto-Excluded:\n" ..
                    "- 00:00 / 01:00 time scrolls\n" ..
                    "- Location with 'drop' or 'boss'\n" ..
                    "- Name with 'bossdrop'\n\n" ..
                    "Window: Time to Time+20min\n" ..
                    "Wait: 30s per server\n\n" ..
                    "NOTE: Fill ScrollServerIDs table in code!",
                    FarmState.ScrollSniperEnabled and "[OK] ACTIVE" or "[X] INACTIVE",
                    gameTimeStr,
                    selectedCount,
                    #ScrollData,
                    FarmState.ScrollSniperCurrent ~= "" and FarmState.ScrollSniperCurrent or "None",
                    FarmState.ScrollSniperServersHopped,
                    FarmState.ScrollSniperScrollsClaimed
                )
                task.wait(1)
            end
        end)
        
        task.spawn(function()
            task.wait(5)
            refreshScrollList()
        end)
        
        -- ==========================================
        -- SCROLL GET (MANUAL - OLD SCROLL SNIPER)
        -- ==========================================
        Tabs.ScrollGet:AddParagraph({
            Title = "[S] Scroll Get (Manual)",
            Content = "Manually teleport to and claim spawned scrolls.\n\n" ..
                "- Scans workspace.GLOBALTIME and workspace\n" ..
                "- Instant teleport to scroll location\n" ..
                "- Auto-collect with click detector\n\n" ..
                "NOTE: This is the old scroll sniper (manual mode)"
        })
        
        Tabs.ScrollGet:AddToggle("ScrollGetToggle", {
            Title = "Enable Scroll Get",
            Default = Config.ScrollGetEnabled
        }):OnChanged(function(v)
            FarmState.ScrollGetEnabled = v
            Config.ScrollGetEnabled = v
            ConfigManager.Save(Config)
        end)
        
        task.spawn(function()
            while true do
                if FarmState.ScrollGetEnabled and LocalPlayer.Character then
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
            Content = "WARNING: These features are experimental and may cause:\n- Server detection / kicks\n- Visual glitches\n- Performance issues\n\nUse at your own risk in private servers!\n\nNOTE: InstaKill (M1 spam + Local Force Kill) has been moved to its own dedicated tab."
        })
        
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
                
                local activeText = #activeFeatures > 0 and table.concat(activeFeatures, ", ") or "None"
                
                ExperimentalStatusDisplay.Content = string.format(
                    "Active Features: %d / 4\n\n%s\n\nESP Stats:\n- Max Range: %d studs\n- Players Tracked: %d\n\nNote: InstaKill moved to dedicated tab",
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
            Content = "Loaded: Shindo Life In-Game (Enhanced + Scroll Sniper + Travel System + InstaKill + LIVE TIME)",
            Duration = 5
        })
    end
end
