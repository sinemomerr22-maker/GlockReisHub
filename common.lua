-- // ==========================================
-- // GLOCKREISHUB - COMMON UTILITIES
-- // ==========================================

local Common = {}

-- Services
Common.Players = game:GetService("Players")
Common.RunService = game:GetService("RunService")
Common.TweenService = game:GetService("TweenService")
Common.TeleportService = game:GetService("TeleportService")
Common.ReplicatedStorage = game:GetService("ReplicatedStorage")
Common.UserInputService = game:GetService("UserInputService")
Common.HttpService = game:GetService("HttpService")
Common.MarketplaceService = game:GetService("MarketplaceService")
Common.VirtualInputManager = game:GetService("VirtualInputManager")
Common.Teams = game:GetService("Teams")

Common.LocalPlayer = Common.Players.LocalPlayer

-- Anti-AFK (12h+ proof)
function Common.setupAntiAFK()
    local VirtualUser = game:GetService("VirtualUser")
    Common.LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

-- Anti-TP (CCoff bypass)
function Common.setupAntiTP()
    if workspace:FindFirstChild("CCoff") then workspace.CCoff:Destroy() end
    workspace.ChildAdded:Connect(function(c) 
        if c.Name == "CCoff" then c:Destroy() end 
    end)
    
    task.spawn(function()
        while true do
            local char = Common.LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
                pcall(function()
                    local root = char.HumanoidRootPart
                    local originalCFrame = root.CFrame
                    root.CFrame = originalCFrame * CFrame.new(0, 0.1, 0)
                    task.wait(0.1)
                    root.CFrame = originalCFrame
                end)
            end
            task.wait(60)
        end
    end)
end

-- Config Manager
function Common.setupConfigManager(gameName)
    local ConfigFolder = "GlockreisHub"
    local ConfigFile = ConfigFolder .. "/" .. gameName .. "_settings.json"
    
    local function LoadConfig(defaultConfig)
        if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
        if isfile(ConfigFile) then
            local ok, data = pcall(function() 
                return Common.HttpService:JSONDecode(readfile(ConfigFile)) 
            end)
            if ok and data and type(data) == "table" then
                for k, v in pairs(defaultConfig) do 
                    if data[k] == nil then data[k] = v end 
                end
                return data
            end
        end
        return defaultConfig
    end
    
    local function SaveConfig(data)
        pcall(function() 
            writefile(ConfigFile, Common.HttpService:JSONEncode(data)) 
        end)
    end
    
    return {
        Load = LoadConfig,
        Save = SaveConfig
    }
end

-- Fluent UI Loader
function Common.loadFluentUI(gameDisplayName, placeId)
    local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
    
    local Window = Fluent:CreateWindow({
        Title = "GlockreisHub | " .. gameDisplayName,
        SubTitle = "Detected: " .. gameDisplayName .. " (PlaceId: " .. placeId .. ")",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = true,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.LeftControl
    })
    
    return {
        Fluent = Fluent,
        Window = Window,
        SaveManager = SaveManager,
        InterfaceManager = InterfaceManager,
        Options = Fluent.Options
    }
end

-- Custom Cursor
function Common.setupCustomCursor()
    task.spawn(function()
        pcall(function() Common.UserInputService.MouseIconEnabled = false end)
        local getUI = gethui or function() return game:GetService("CoreGui") end
        local cursorGui = Instance.new("ScreenGui")
        cursorGui.Name = "GlockCursor"
        cursorGui.DisplayOrder = 999
        cursorGui.IgnoreGuiInset = false
        cursorGui.ResetOnSpawn = false
        pcall(function() cursorGui.Parent = getUI() end)
        if not cursorGui.Parent then 
            cursorGui.Parent = Common.LocalPlayer:WaitForChild("PlayerGui") 
        end
        
        local mainCursor = Instance.new("Frame")
        mainCursor.Name = "MainCursor"
        mainCursor.Size = UDim2.fromOffset(6, 6)
        mainCursor.AnchorPoint = Vector2.new(0.5, 0.5)
        mainCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        mainCursor.BorderSizePixel = 0
        mainCursor.ZIndex = 1000
        mainCursor.Parent = cursorGui
        Instance.new("UICorner", mainCursor).CornerRadius = UDim.new(1, 0)
        
        local mainGlow = Instance.new("UIStroke")
        mainGlow.Thickness = 2
        mainGlow.Transparency = 0.2
        mainGlow.Color = Color3.fromRGB(0, 0, 0)
        mainGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        mainGlow.Parent = mainCursor
        
        Common.RunService.RenderStepped:Connect(function(dt)
            local mouse = Common.UserInputService:GetMouseLocation()
            local mousePos = Vector2.new(mouse.X - 1, mouse.Y - 57)
            mainCursor.Position = UDim2.fromOffset(mousePos.X, mousePos.Y)
        end)
    end)
end

-- Universal Mode (unsupported games)
function Common.setupUniversalMode()
    Common.setupAntiAFK()
    Common.setupAntiTP()
    Common.setupCustomCursor()
    
    local ui = Common.loadFluentUI("Universal Mode", game.PlaceId)
    local Tabs = {}
    
    Tabs.Main = ui.Window:AddTab({ Title = "Universal", Icon = "shield" })
    Tabs.Main:AddParagraph({
        Title = "Universal Safe Mode", 
        Content = "Game not specifically supported.\nOnly safe, universal features are active:\n\n✅ Anti-AFK: ACTIVE (12h+ proof)\n✅ Anti-TP: ACTIVE (CCoff bypass)\n✅ Custom Cursor: ACTIVE\n\n⚠️ No fly, speed, or game-specific exploits."
    })
    
    local gameInfoLabel = Tabs.Main:AddParagraph({
        Title = "Current Game Info", 
        Content = "PlaceId: " .. game.PlaceId .. "\nGame: Loading..."
    })
    
    task.spawn(function()
        local ok, gameInfo = pcall(function()
            return Common.MarketplaceService:GetProductInfo(game.PlaceId)
        end)
        if ok and gameInfo and gameInfo.Name then
            gameInfoLabel.Content = "PlaceId: " .. game.PlaceId .. "\nGame: " .. gameInfo.Name
        else
            gameInfoLabel.Content = "PlaceId: " .. game.PlaceId .. "\nGame: Unknown (API error)"
        end
    end)
    
    ui.Window:SelectTab(1)
    ui.Fluent:Notify({
        Title = "GlockreisHub",
        Content = "Loaded in Universal Mode",
        Duration = 5
    })
end

-- Initialize common features
Common.setupAntiAFK()
Common.setupAntiTP()
Common.setupCustomCursor()

return Common
