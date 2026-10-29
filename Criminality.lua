-- // ==========================================
-- // GLOCKREISHUB - CRIMINALITY MODULE
-- // ==========================================

return function(Common)
    local Fluent = Common.Fluent
    local LocalPlayer = Common.LocalPlayer
    local Players = Common.Players
    local RunService = Common.RunService
    local UserInputService = Common.UserInputService
    local TweenService = Common.TweenService
    local Teams = Common.Teams
    
    -- Config
    local DefaultConfig = {
        ESPEnabled = true,
        ShowNames = true,
        ShowDistance = true,
        ShowHealth = false,
        ShowTeam = true,
        TeamCheck = true,
        MaxDistance = 1000,
        FillColor = {R = 0, G = 255, B = 0},
        OutlineColor = {R = 0, G = 0, B = 0},
        TextColor = {R = 255, G = 255, B = 255},
        TeamColor = {R = 0, G = 150, B = 255},
        EnemyColor = {R = 255, G = 0, B = 0},
        FillTransparency = 0.5,
        OutlineTransparency = 0,
        TextSize = 14,
        TextStrokeTransparency = 0.5,
        BillboardOffset = 3,
        ToggleKey = "E"
    }
    
    local ConfigManager = Common.setupConfigManager("Criminality")
    local Config = ConfigManager.Load(DefaultConfig)
    
    -- UI
    local ui = Common.loadFluentUI("Criminality", game.PlaceId)
    local Tabs = {}
    
    Tabs.Main = ui.Window:AddTab({ Title = "ESP Main", Icon = "eye" })
    Tabs.Visuals = ui.Window:AddTab({ Title = "ESP Visuals", Icon = "palette" })
    Tabs.Info = ui.Window:AddTab({ Title = "ESP Info", Icon = "info" })
    
    -- ==========================================
    -- ESP CONFIGURATION STATE
    -- ==========================================
    local ESPConfig = {
        Enabled = Config.ESPEnabled,
        ShowNames = Config.ShowNames,
        ShowDistance = Config.ShowDistance,
        ShowHealth = Config.ShowHealth,
        ShowTeam = Config.ShowTeam,
        TeamCheck = Config.TeamCheck,
        MaxDistance = Config.MaxDistance or 1000,
        FillColor = Color3.new(Config.FillColor.R/255, Config.FillColor.G/255, Config.FillColor.B/255),
        OutlineColor = Color3.new(Config.OutlineColor.R/255, Config.OutlineColor.G/255, Config.OutlineColor.B/255),
        TextColor = Color3.new(Config.TextColor.R/255, Config.TextColor.G/255, Config.TextColor.B/255),
        TeamColor = Color3.new(Config.TeamColor.R/255, Config.TeamColor.G/255, Config.TeamColor.B/255),
        EnemyColor = Color3.new(Config.EnemyColor.R/255, Config.EnemyColor.G/255, Config.EnemyColor.B/255),
        FillTransparency = Config.FillTransparency or 0.5,
        OutlineTransparency = Config.OutlineTransparency or 0,
        TextSize = Config.TextSize or 14,
        TextStrokeTransparency = Config.TextStrokeTransparency or 0.5,
        BillboardOffset = Config.BillboardOffset or 3,
        ToggleKey = Config.ToggleKey or "E"
    }
    
    -- Storage tables
    local Highlights = {}
    local Billboards = {}
    local NameLabels = {}
    local DistanceLabels = {}
    local HealthLabels = {}
    local TeamLabels = {}
    
    -- Statistics
    local espStats = {
        ActiveHighlights = 0,
        LastUpdate = 0,
        ToggleCount = 0
    }
    
    -- ==========================================
    -- HELPER: Save Color to Config
    -- ==========================================
    local function saveColorToConfig(key, color)
        Config[key] = {
            R = math.floor(color.R * 255),
            G = math.floor(color.G * 255),
            B = math.floor(color.B * 255)
        }
        ConfigManager.Save(Config)
    end
    
    -- ==========================================
    -- CORE: Create ESP elements for a player
    -- ==========================================
    local function createESPForPlayer(player)
        if player == LocalPlayer then return end
        if not player.Character then return end
        
        -- Clean up existing ESP if any
        if Highlights[player] then
            pcall(function() Highlights[player]:Destroy() end)
            Highlights[player] = nil
        end
        if Billboards[player] then
            pcall(function() Billboards[player]:Destroy() end)
            Billboards[player] = nil
        end
        
        -- Create Highlight
        local highlight = Instance.new("Highlight")
        highlight.Name = "GlockESP_Highlight"
        highlight.FillColor = ESPConfig.FillColor
        highlight.FillTransparency = ESPConfig.FillTransparency
        highlight.OutlineColor = ESPConfig.OutlineColor
        highlight.OutlineTransparency = ESPConfig.OutlineTransparency
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = player.Character
        highlight.Parent = player.Character
        
        -- Create BillboardGui
        local getUI = gethui or function() return game:GetService("CoreGui") end
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "GlockESP_Billboard"
        billboard.Adornee = player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
        billboard.Size = UDim2.new(0, 200, 0, 80)
        billboard.StudsOffset = Vector3.new(0, ESPConfig.BillboardOffset, 0)
        billboard.AlwaysOnTop = true
        billboard.LightInfluence = 0
        billboard.ResetOnSpawn = false
        
        pcall(function() billboard.Parent = getUI() end)
        if not billboard.Parent then
            billboard.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end
        
        -- Main container frame (for layout)
        local container = Instance.new("Frame")
        container.Name = "Container"
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundTransparency = 1
        container.Parent = billboard
        
        local layout = Instance.new("UIListLayout")
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 2)
        layout.Parent = container
        
        -- Name Label
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(1, 0, 0, ESPConfig.TextSize + 4)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.DisplayName or player.Name
        nameLabel.TextColor3 = ESPConfig.TextColor
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = ESPConfig.TextSize
        nameLabel.TextStrokeTransparency = ESPConfig.TextStrokeTransparency
        nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        nameLabel.LayoutOrder = 1
        nameLabel.Parent = container
        
        -- Distance Label
        local distanceLabel = Instance.new("TextLabel")
        distanceLabel.Name = "DistanceLabel"
        distanceLabel.Size = UDim2.new(1, 0, 0, ESPConfig.TextSize + 2)
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.Text = "0m"
        distanceLabel.TextColor3 = ESPConfig.TextColor
        distanceLabel.Font = Enum.Font.Gotham
        distanceLabel.TextSize = ESPConfig.TextSize - 2
        distanceLabel.TextStrokeTransparency = ESPConfig.TextStrokeTransparency
        distanceLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        distanceLabel.LayoutOrder = 2
        distanceLabel.Parent = container
        
        -- Health Label
        local healthLabel = Instance.new("TextLabel")
        healthLabel.Name = "HealthLabel"
        healthLabel.Size = UDim2.new(1, 0, 0, ESPConfig.TextSize + 2)
        healthLabel.BackgroundTransparency = 1
        healthLabel.Text = "100/100 HP"
        healthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        healthLabel.Font = Enum.Font.Gotham
        healthLabel.TextSize = ESPConfig.TextSize - 2
        healthLabel.TextStrokeTransparency = ESPConfig.TextStrokeTransparency
        healthLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        healthLabel.LayoutOrder = 3
        healthLabel.Parent = container
        
        -- Team Label
        local teamLabel = Instance.new("TextLabel")
        teamLabel.Name = "TeamLabel"
        teamLabel.Size = UDim2.new(1, 0, 0, ESPConfig.TextSize + 2)
        teamLabel.BackgroundTransparency = 1
        teamLabel.Text = player.Team and player.Team.Name or "No Team"
        teamLabel.TextColor3 = player.TeamColor and player.TeamColor.Color or ESPConfig.TextColor
        teamLabel.Font = Enum.Font.GothamSemibold
        teamLabel.TextSize = ESPConfig.TextSize - 2
        teamLabel.TextStrokeTransparency = ESPConfig.TextStrokeTransparency
        teamLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        teamLabel.LayoutOrder = 4
        teamLabel.Parent = container
        
        -- Store references
        Highlights[player] = highlight
        Billboards[player] = billboard
        NameLabels[player] = nameLabel
        DistanceLabels[player] = distanceLabel
        HealthLabels[player] = healthLabel
        TeamLabels[player] = teamLabel
        
        -- Apply initial visibility based on config
        nameLabel.Visible = ESPConfig.ShowNames
        distanceLabel.Visible = ESPConfig.ShowDistance
        healthLabel.Visible = ESPConfig.ShowHealth
        teamLabel.Visible = ESPConfig.ShowTeam
        highlight.Enabled = ESPConfig.Enabled
        billboard.Enabled = ESPConfig.Enabled
    end
    
    -- ==========================================
    -- CORE: Remove ESP for a player
    -- ==========================================
    local function removeESPForPlayer(player)
        if Highlights[player] then
            pcall(function() Highlights[player]:Destroy() end)
            Highlights[player] = nil
        end
        if Billboards[player] then
            pcall(function() Billboards[player]:Destroy() end)
            Billboards[player] = nil
        end
        NameLabels[player] = nil
        DistanceLabels[player] = nil
        HealthLabels[player] = nil
        TeamLabels[player] = nil
    end
    
    -- ==========================================
    -- CORE: Update all ESP elements
    -- ==========================================
    local function updateESP()
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myTeam = LocalPlayer.Team
        
        local activeCount = 0
        
        for player, highlight in pairs(Highlights) do
            if not player or not player.Parent then
                removeESPForPlayer(player)
                continue
            end
            
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            
            if not (char and root and hum) then
                highlight.Enabled = false
                if Billboards[player] then Billboards[player].Enabled = false end
                continue
            end
            
            -- Check if player is dead
            if hum.Health <= 0 then
                highlight.Enabled = false
                if Billboards[player] then Billboards[player].Enabled = false end
                continue
            end
            
            -- Distance check
            local distance = 0
            if myRoot then
                distance = (myRoot.Position - root.Position).Magnitude
            end
            
            if distance > ESPConfig.MaxDistance then
                highlight.Enabled = false
                if Billboards[player] then Billboards[player].Enabled = false end
                continue
            end
            
            -- Team check
            local isSameTeam = (player.Team == myTeam) and myTeam ~= nil
            local isEnemy = not isSameTeam
            
            if ESPConfig.TeamCheck then
                if isSameTeam then
                    -- Show team members with team color
                    highlight.FillColor = ESPConfig.TeamColor
                    highlight.OutlineColor = ESPConfig.TeamColor
                    if NameLabels[player] then
                        NameLabels[player].TextColor3 = ESPConfig.TeamColor
                    end
                else
                    -- Show enemies with enemy color
                    highlight.FillColor = ESPConfig.EnemyColor
                    highlight.OutlineColor = ESPConfig.EnemyColor
                    if NameLabels[player] then
                        NameLabels[player].TextColor3 = ESPConfig.EnemyColor
                    end
                end
            else
                -- No team check, use default color
                highlight.FillColor = ESPConfig.FillColor
                highlight.OutlineColor = ESPConfig.OutlineColor
                if NameLabels[player] then
                    NameLabels[player].TextColor3 = ESPConfig.TextColor
                end
            end
            
            -- Apply transparency
            highlight.FillTransparency = ESPConfig.FillTransparency
            highlight.OutlineTransparency = ESPConfig.OutlineTransparency
            
            -- Enable ESP
            highlight.Enabled = ESPConfig.Enabled
            if Billboards[player] then
                Billboards[player].Enabled = ESPConfig.Enabled
                -- Update adornee in case character changed
                local head = char:FindFirstChild("Head")
                if head then
                    Billboards[player].Adornee = head
                end
            end
            
            -- Update name
            if NameLabels[player] and ESPConfig.ShowNames then
                NameLabels[player].Text = player.DisplayName ~= player.Name 
                    and (player.DisplayName .. " (@" .. player.Name .. ")")
                    or player.Name
            end
            
            -- Update distance
            if DistanceLabels[player] and ESPConfig.ShowDistance then
                DistanceLabels[player].Text = string.format("[%.0fm]", distance)
                -- Color based on distance (green=far, red=close)
                local distRatio = math.clamp(distance / ESPConfig.MaxDistance, 0, 1)
                DistanceLabels[player].TextColor3 = Color3.new(1 - distRatio, distRatio, 0)
            end
            
            -- Update health
            if HealthLabels[player] and ESPConfig.ShowHealth then
                local health = hum.Health
                local maxHealth = hum.MaxHealth
                local healthPercent = health / maxHealth
                HealthLabels[player].Text = string.format("%.0f/%.0f HP", health, maxHealth)
                -- Color gradient: red (0%) -> yellow (50%) -> green (100%)
                if healthPercent > 0.5 then
                    HealthLabels[player].TextColor3 = Color3.new(2 * (1 - healthPercent), 1, 0)
                else
                    HealthLabels[player].TextColor3 = Color3.new(1, 2 * healthPercent, 0)
                end
            end
            
            -- Update team
            if TeamLabels[player] and ESPConfig.ShowTeam then
                local teamName = player.Team and player.Team.Name or "Civilian"
                TeamLabels[player].Text = "[" .. teamName .. "]"
                if player.Team then
                    TeamLabels[player].TextColor3 = player.TeamColor.Color
                end
            end
            
            activeCount = activeCount + 1
        end
        
        espStats.ActiveHighlights = activeCount
        espStats.LastUpdate = tick()
    end
    
    -- ==========================================
    -- PLAYER EVENTS
    -- ==========================================
    local function onPlayerAdded(player)
        if player == LocalPlayer then return end
        
        player.CharacterAdded:Connect(function(char)
            task.wait(0.5) -- Wait for character to fully load
            createESPForPlayer(player)
        end)
        
        if player.Character then
            createESPForPlayer(player)
        end
    end
    
    local function onPlayerRemoving(player)
        removeESPForPlayer(player)
    end
    
    -- Connect events
    Players.PlayerAdded:Connect(onPlayerAdded)
    Players.PlayerRemoving:Connect(onPlayerRemoving)
    
    -- Initialize for existing players
    for _, player in ipairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end
    
    -- ==========================================
    -- KEYBIND: Toggle ESP
    -- ==========================================
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        local keyName = ESPConfig.ToggleKey
        local targetKey = Enum.KeyCode[keyName]
        
        if targetKey and input.KeyCode == targetKey then
            ESPConfig.Enabled = not ESPConfig.Enabled
            Config.ESPEnabled = ESPConfig.Enabled
            ConfigManager.Save(Config)
            espStats.ToggleCount = espStats.ToggleCount + 1
            
            Fluent:Notify({
                Title = "👁️ ESP " .. (ESPConfig.Enabled and "Enabled" or "Disabled"),
                Content = "Press " .. keyName .. " to toggle",
                Duration = 2
            })
            
            -- Update Options toggle if it exists
            if ui.Options.ESPToggle then
                ui.Options.ESPToggle.Value = ESPConfig.Enabled
            end
        end
    end)
    
    -- ==========================================
    -- RENDER LOOP: Update ESP every frame
    -- ==========================================
    RunService.RenderStepped:Connect(function()
        if ESPConfig.Enabled then
            updateESP()
        end
    end)
    
    -- ==========================================
    -- UI: MAIN TAB
    -- ==========================================
    Tabs.Main:AddParagraph({
        Title = "👁️ Criminality ESP",
        Content = "Advanced ESP system with full customization.\n\n• Real-time player tracking\n• Team-based coloring (Police vs Criminals)\n• Health bars with color gradient\n• Distance indicators\n• Toggle key: [" .. ESPConfig.ToggleKey .. "]"
    })
    
    Tabs.Main:AddToggle("ESPToggle", {
        Title = "Enable ESP",
        Description = "Master toggle for all ESP features. [" .. ESPConfig.ToggleKey .. "] to quick toggle.",
        Default = ESPConfig.Enabled
    }):OnChanged(function(v)
        ESPConfig.Enabled = v
        Config.ESPEnabled = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.Main:AddToggle("TeamCheckToggle", {
        Title = "Team Check",
        Description = "Color enemies red, teammates blue. Disable to use custom color for all.",
        Default = ESPConfig.TeamCheck
    }):OnChanged(function(v)
        ESPConfig.TeamCheck = v
        Config.TeamCheck = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.Main:AddSlider("MaxDistanceSlider", {
        Title = "Max Distance (studs)",
        Description = "Only show players within this distance.",
        Default = ESPConfig.MaxDistance,
        Min = 50, Max = 5000, Rounding = 0,
        Callback = function(v)
            ESPConfig.MaxDistance = v
            Config.MaxDistance = v
            ConfigManager.Save(Config)
        end
    })
    
    Tabs.Main:AddDropdown("ToggleKeyDropdown", {
        Title = "Toggle Key",
        Description = "Key to quickly toggle ESP on/off.",
        Values = {"E", "F", "G", "H", "X", "C", "V", "B", "Q", "R"},
        Default = ESPConfig.ToggleKey,
        Callback = function(v)
            ESPConfig.ToggleKey = v
            Config.ToggleKey = v
            ConfigManager.Save(Config)
            Fluent:Notify({Title = "Toggle Key", Content = "Set to [" .. v .. "]", Duration = 2})
        end
    })
    
    Tabs.Main:AddButton({Title = "Refresh All ESP", Callback = function()
        for player, _ in pairs(Highlights) do
            removeESPForPlayer(player)
        end
        for _, player in ipairs(Players:GetPlayers()) do
            onPlayerAdded(player)
        end
        Fluent:Notify({Title = "ESP Refreshed", Content = "Rebuilt all ESP elements", Duration = 2})
    end})
    
    Tabs.Main:AddButton({Title = "Clear All ESP", Callback = function()
        for player, _ in pairs(Highlights) do
            removeESPForPlayer(player)
        end
        Fluent:Notify({Title = "ESP Cleared", Content = "Removed all ESP elements", Duration = 2})
    end})
    
    -- ==========================================
    -- UI: VISUALS TAB (Colors & Transparency)
    -- ==========================================
    Tabs.Visuals:AddParagraph({
        Title = "🎨 ESP Visuals",
        Content = "Customize colors and transparency.\nChanges are saved automatically."
    })
    
    -- Fill Color
    Tabs.Visuals:AddColorpicker("FillColorPicker", {
        Title = "Fill Color (Default)",
        Description = "Color when Team Check is OFF.",
        Default = ESPConfig.FillColor
    }):OnChanged(function(color)
        ESPConfig.FillColor = color
        saveColorToConfig("FillColor", color)
    end)
    
    Tabs.Visuals:AddSlider("FillTransparencySlider", {
        Title = "Fill Transparency",
        Description = "0 = opaque, 1 = invisible.",
        Default = ESPConfig.FillTransparency,
        Min = 0, Max = 1, Rounding = 2,
        Callback = function(v)
            ESPConfig.FillTransparency = v
            Config.FillTransparency = v
            ConfigManager.Save(Config)
        end
    })
    
    -- Outline Color
    Tabs.Visuals:AddColorpicker("OutlineColorPicker", {
        Title = "Outline Color",
        Description = "Color of the highlight outline.",
        Default = ESPConfig.OutlineColor
    }):OnChanged(function(color)
        ESPConfig.OutlineColor = color
        saveColorToConfig("OutlineColor", color)
    end)
    
    Tabs.Visuals:AddSlider("OutlineTransparencySlider", {
        Title = "Outline Transparency",
        Description = "0 = opaque, 1 = invisible.",
        Default = ESPConfig.OutlineTransparency,
        Min = 0, Max = 1, Rounding = 2,
        Callback = function(v)
            ESPConfig.OutlineTransparency = v
            Config.OutlineTransparency = v
            ConfigManager.Save(Config)
        end
    })
    
    -- Team Colors
    Tabs.Visuals:AddColorpicker("TeamColorPicker", {
        Title = "Team Color (Friendly)",
        Description = "Color for teammates when Team Check is ON.",
        Default = ESPConfig.TeamColor
    }):OnChanged(function(color)
        ESPConfig.TeamColor = color
        saveColorToConfig("TeamColor", color)
    end)
    
    Tabs.Visuals:AddColorpicker("EnemyColorPicker", {
        Title = "Enemy Color (Hostile)",
        Description = "Color for enemies when Team Check is ON.",
        Default = ESPConfig.EnemyColor
    }):OnChanged(function(color)
        ESPConfig.EnemyColor = color
        saveColorToConfig("EnemyColor", color)
    end)
    
    -- Text Color
    Tabs.Visuals:AddColorpicker("TextColorPicker", {
        Title = "Text Color",
        Description = "Color of name/distance/health text.",
        Default = ESPConfig.TextColor
    }):OnChanged(function(color)
        ESPConfig.TextColor = color
        saveColorToConfig("TextColor", color)
    end)
    
    Tabs.Visuals:AddSlider("TextSizeSlider", {
        Title = "Text Size",
        Default = ESPConfig.TextSize,
        Min = 8, Max = 24, Rounding = 0,
        Callback = function(v)
            ESPConfig.TextSize = v
            Config.TextSize = v
            ConfigManager.Save(Config)
        end
    })
    
    Tabs.Visuals:AddSlider("TextStrokeSlider", {
        Title = "Text Stroke Transparency",
        Description = "0 = solid black stroke, 1 = no stroke.",
        Default = ESPConfig.TextStrokeTransparency,
        Min = 0, Max = 1, Rounding = 2,
        Callback = function(v)
            ESPConfig.TextStrokeTransparency = v
            Config.TextStrokeTransparency = v
            ConfigManager.Save(Config)
        end
    })
    
    Tabs.Visuals:AddSlider("BillboardOffsetSlider", {
        Title = "Billboard Offset (studs)",
        Description = "Height above player's head.",
        Default = ESPConfig.BillboardOffset,
        Min = 1, Max = 10, Rounding = 1,
        Callback = function(v)
            ESPConfig.BillboardOffset = v
            Config.BillboardOffset = v
            ConfigManager.Save(Config)
        end
    })
    
    -- Preset buttons
    Tabs.Visuals:AddButton({Title = "Preset: Default (Green)", Callback = function()
        ESPConfig.FillColor = Color3.fromRGB(0, 255, 0)
        ESPConfig.OutlineColor = Color3.fromRGB(0, 0, 0)
        ESPConfig.TextColor = Color3.fromRGB(255, 255, 255)
        ESPConfig.TeamColor = Color3.fromRGB(0, 150, 255)
        ESPConfig.EnemyColor = Color3.fromRGB(255, 0, 0)
        saveColorToConfig("FillColor", ESPConfig.FillColor)
        saveColorToConfig("OutlineColor", ESPConfig.OutlineColor)
        saveColorToConfig("TextColor", ESPConfig.TextColor)
        saveColorToConfig("TeamColor", ESPConfig.TeamColor)
        saveColorToConfig("EnemyColor", ESPConfig.EnemyColor)
        if ui.Options.FillColorPicker then ui.Options.FillColorPicker.Value = ESPConfig.FillColor end
        if ui.Options.OutlineColorPicker then ui.Options.OutlineColorPicker.Value = ESPConfig.OutlineColor end
        if ui.Options.TextColorPicker then ui.Options.TextColorPicker.Value = ESPConfig.TextColor end
        if ui.Options.TeamColorPicker then ui.Options.TeamColorPicker.Value = ESPConfig.TeamColor end
        if ui.Options.EnemyColorPicker then ui.Options.EnemyColorPicker.Value = ESPConfig.EnemyColor end
        Fluent:Notify({Title = "Preset Applied", Content = "Default green theme", Duration = 2})
    end})
    
    Tabs.Visuals:AddButton({Title = "Preset: Red Alert", Callback = function()
        ESPConfig.FillColor = Color3.fromRGB(255, 0, 0)
        ESPConfig.OutlineColor = Color3.fromRGB(255, 255, 0)
        ESPConfig.TextColor = Color3.fromRGB(255, 255, 255)
        ESPConfig.TeamColor = Color3.fromRGB(0, 255, 0)
        ESPConfig.EnemyColor = Color3.fromRGB(255, 0, 0)
        saveColorToConfig("FillColor", ESPConfig.FillColor)
        saveColorToConfig("OutlineColor", ESPConfig.OutlineColor)
        saveColorToConfig("TextColor", ESPConfig.TextColor)
        saveColorToConfig("TeamColor", ESPConfig.TeamColor)
        saveColorToConfig("EnemyColor", ESPConfig.EnemyColor)
        if ui.Options.FillColorPicker then ui.Options.FillColorPicker.Value = ESPConfig.FillColor end
        if ui.Options.OutlineColorPicker then ui.Options.OutlineColorPicker.Value = ESPConfig.OutlineColor end
        if ui.Options.TextColorPicker then ui.Options.TextColorPicker.Value = ESPConfig.TextColor end
        if ui.Options.TeamColorPicker then ui.Options.TeamColorPicker.Value = ESPConfig.TeamColor end
        if ui.Options.EnemyColorPicker then ui.Options.EnemyColorPicker.Value = ESPConfig.EnemyColor end
        Fluent:Notify({Title = "Preset Applied", Content = "Red alert theme", Duration = 2})
    end})
    
    Tabs.Visuals:AddButton({Title = "Preset: Stealth (Cyan)", Callback = function()
        ESPConfig.FillColor = Color3.fromRGB(0, 255, 255)
        ESPConfig.OutlineColor = Color3.fromRGB(0, 100, 150)
        ESPConfig.TextColor = Color3.fromRGB(200, 255, 255)
        ESPConfig.TeamColor = Color3.fromRGB(0, 200, 255)
        ESPConfig.EnemyColor = Color3.fromRGB(255, 100, 0)
        saveColorToConfig("FillColor", ESPConfig.FillColor)
        saveColorToConfig("OutlineColor", ESPConfig.OutlineColor)
        saveColorToConfig("TextColor", ESPConfig.TextColor)
        saveColorToConfig("TeamColor", ESPConfig.TeamColor)
        saveColorToConfig("EnemyColor", ESPConfig.EnemyColor)
        if ui.Options.FillColorPicker then ui.Options.FillColorPicker.Value = ESPConfig.FillColor end
        if ui.Options.OutlineColorPicker then ui.Options.OutlineColorPicker.Value = ESPConfig.OutlineColor end
        if ui.Options.TextColorPicker then ui.Options.TextColorPicker.Value = ESPConfig.TextColor end
        if ui.Options.TeamColorPicker then ui.Options.TeamColorPicker.Value = ESPConfig.TeamColor end
        if ui.Options.EnemyColorPicker then ui.Options.EnemyColorPicker.Value = ESPConfig.EnemyColor end
        Fluent:Notify({Title = "Preset Applied", Content = "Stealth cyan theme", Duration = 2})
    end})
    
    Tabs.Visuals:AddButton({Title = "Preset: Pink/Purple", Callback = function()
        ESPConfig.FillColor = Color3.fromRGB(255, 0, 255)
        ESPConfig.OutlineColor = Color3.fromRGB(128, 0, 255)
        ESPConfig.TextColor = Color3.fromRGB(255, 200, 255)
        ESPConfig.TeamColor = Color3.fromRGB(255, 100, 255)
        ESPConfig.EnemyColor = Color3.fromRGB(255, 0, 100)
        saveColorToConfig("FillColor", ESPConfig.FillColor)
        saveColorToConfig("OutlineColor", ESPConfig.OutlineColor)
        saveColorToConfig("TextColor", ESPConfig.TextColor)
        saveColorToConfig("TeamColor", ESPConfig.TeamColor)
        saveColorToConfig("EnemyColor", ESPConfig.EnemyColor)
        if ui.Options.FillColorPicker then ui.Options.FillColorPicker.Value = ESPConfig.FillColor end
        if ui.Options.OutlineColorPicker then ui.Options.OutlineColorPicker.Value = ESPConfig.OutlineColor end
        if ui.Options.TextColorPicker then ui.Options.TextColorPicker.Value = ESPConfig.TextColor end
        if ui.Options.TeamColorPicker then ui.Options.TeamColorPicker.Value = ESPConfig.TeamColor end
        if ui.Options.EnemyColorPicker then ui.Options.EnemyColorPicker.Value = ESPConfig.EnemyColor end
        Fluent:Notify({Title = "Preset Applied", Content = "Pink/purple theme", Duration = 2})
    end})
    
    -- ==========================================
    -- UI: INFO TAB (What to show)
    -- ==========================================
    Tabs.Info:AddParagraph({
        Title = "ℹ️ ESP Information",
        Content = "Choose what information to display on each player."
    })
    
    Tabs.Info:AddToggle("ShowNamesToggle", {
        Title = "Show Names",
        Description = "Display player's DisplayName and @username.",
        Default = ESPConfig.ShowNames
    }):OnChanged(function(v)
        ESPConfig.ShowNames = v
        Config.ShowNames = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.Info:AddToggle("ShowDistanceToggle", {
        Title = "Show Distance",
        Description = "Display distance in meters with color gradient.",
        Default = ESPConfig.ShowDistance
    }):OnChanged(function(v)
        ESPConfig.ShowDistance = v
        Config.ShowDistance = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.Info:AddToggle("ShowHealthToggle", {
        Title = "Show Health",
        Description = "Display current HP with color gradient (red->yellow->green).",
        Default = ESPConfig.ShowHealth
    }):OnChanged(function(v)
        ESPConfig.ShowHealth = v
        Config.ShowHealth = v
        ConfigManager.Save(Config)
    end)
    
    Tabs.Info:AddToggle("ShowTeamToggle", {
        Title = "Show Team",
        Description = "Display team name with team color.",
        Default = ESPConfig.ShowTeam
    }):OnChanged(function(v)
        ESPConfig.ShowTeam = v
        Config.ShowTeam = v
        ConfigManager.Save(Config)
    end)
    
    -- Status Display
    local ESPStatusDisplay = Tabs.Info:AddParagraph({
        Title = "ESP Status",
        Content = "Initializing..."
    })
    
    task.spawn(function()
        while true do
            local playerCount = #Players:GetPlayers() - 1
            local lastUpdateAgo = tick() - espStats.LastUpdate
            local updateStatus = lastUpdateAgo < 1 and "Active" or "Idle"
            
            ESPStatusDisplay.Content = string.format(
                "Status: %s\n\nESP Enabled: %s\nActive Highlights: %d / %d players\nTeam Check: %s\nMax Distance: %d studs\nToggle Key: [%s]\n\nLast Update: %.2fs ago\nTotal Toggles: %d\n\nVisible Info:\n• Names: %s\n• Distance: %s\n• Health: %s\n• Team: %s",
                updateStatus,
                ESPConfig.Enabled and "✅ YES" or "❌ NO",
                espStats.ActiveHighlights,
                playerCount,
                ESPConfig.TeamCheck and "✅ ON" or "❌ OFF",
                ESPConfig.MaxDistance,
                ESPConfig.ToggleKey,
                lastUpdateAgo,
                espStats.ToggleCount,
                ESPConfig.ShowNames and "✅" or "❌",
                ESPConfig.ShowDistance and "✅" or "❌",
                ESPConfig.ShowHealth and "✅" or "❌",
                ESPConfig.ShowTeam and "✅" or "❌"
            )
            task.wait(0.3)
        end
    end)
    
    -- Initial notification
    if ESPConfig.Enabled then
        Fluent:Notify({
            Title = "👁️ Criminality ESP Loaded",
            Content = "Press [" .. ESPConfig.ToggleKey .. "] to toggle. " .. (#Players:GetPlayers() - 1) .. " players tracked.",
            Duration = 5
        })
    end
    
    ui.Window:SelectTab(1)
    Fluent:Notify({
        Title = "GlockreisHub",
        Content = "Loaded: Criminality (ESP System)",
        Duration = 5
    })
end
