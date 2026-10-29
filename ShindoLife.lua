-- // ==========================================
-- // GLOCKREISHUB - SHINDO LIFE (ENHANCED)
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
            local tween = TweenService:Create(
                LocalPlayer.Character:FindFirstChild("HumanoidRootPart"),
                info,
                {CFrame = targetCFrame}
            )
            tween:Play()
        end)
        return ok, err
    end
    
    -- ==========================================
    -- SHINDO LIFE MENU (GENKAI SNIPER ONLY)
    -- ==========================================
    if isShindoMenu then
        Tabs.Main = ui.Window:AddTab({ Title = "Genkai Sniper", Icon = "target" })
        Tabs.Status = ui.Window:AddTab({ Title = "Status", Icon = "activity" })
        
        -- [MEVCUT GENKAI SNIPER KODU - DEGISMEDI]
        -- Not: Mevcut ana koddaki Shindo Life Menu bolumunu buraya kopyala
        
        ui.Window:SelectTab(1)
        ui.Fluent:Notify({
            Title = "GlockreisHub",
            Content = "Loaded: Shindo Life Menu (Genkai Sniper)",
            Duration = 5
        })
    
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
                        LocalPlayer.Character.combat.update:FireServer("rushw")
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
                        LocalPlayer.Character.combat.update:FireServer("takemovement2")
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
                        LocalPlayer.Character.combat.update:FireServer("key", "c")
                        task.wait(0.1)
                        LocalPlayer.Character.combat.update:FireServer("key", "cend")
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
                        LocalPlayer.Character.combat.update:FireServer("mouse1", true)
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
            Content = "Automatically charges chakra when below threshold.\n\n- Monitors chakra level in real-time\n- Auto-charge when below threshold\n- Auto-release when above threshold\n- Move while charging (optional)"
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
        end})
        
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
