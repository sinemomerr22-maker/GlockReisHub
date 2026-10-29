-- // ==========================================
-- // GLOCKREISHUB - BUILD A BOAT FOR TREASURE
-- // ==========================================

return function(Common)
    local Fluent = Common.Fluent
    local LocalPlayer = Common.LocalPlayer
    
    -- Config
    local DefaultConfig = {
        AutoFarm = false, FarmMode = "River", CheckpointWait = 2.5, EndRouteWait = 12.5,
        HoldPosition = true, AutoClaim = true, AutoResetCave = true, AutoBuyPine = false,
        PineQty = 1, WalkOnWater = false, WaterHeight = 6, NoVelocity = false,
        WaterVelocity = 25, TickTreat = false, WalkSpeed = 16, JumpHeight = 7, InfJump = false
    }
    
    local ConfigManager = Common.setupConfigManager("BuildABoat")
    local Config = ConfigManager.Load(DefaultConfig)
    
    -- UI
    local ui = Common.loadFluentUI("Build A Boat For Treasure", game.PlaceId)
    local Tabs = {}
    
    Tabs.Main = ui.Window:AddTab({ Title = "Auto Farm", Icon = "anchor" })
    Tabs.Water = ui.Window:AddTab({ Title = "Water Mods", Icon = "droplet" })
    Tabs.Quests = ui.Window:AddTab({ Title = "Auto Quests", Icon = "map" })
    Tabs.Player = ui.Window:AddTab({ Title = "Player", Icon = "user" })
    Tabs.Teleports = ui.Window:AddTab({ Title = "Teleports", Icon = "map-pin" })
    Tabs.Events = ui.Window:AddTab({ Title = "Events & Trolls", Icon = "gift" })
    
    local FarmSettings = {
Enabled = Config.AutoFarm, Mode = Config.FarmMode, CheckpointWait = Config.CheckpointWait,
EndRouteWait = Config.EndRouteWait, HoldPosition = Config.HoldPosition, AutoClaim = Config.AutoClaim,
AutoResetCave = Config.AutoResetCave, AutoBuyPine = Config.AutoBuyPine, PineQty = Config.PineQty
}
local basePart = nil
local riverPoints = {
Vector3.new(50, 60, 1376), Vector3.new(50, 60, 2127), Vector3.new(50, 60, 2898),
Vector3.new(50, 60, 3667), Vector3.new(50, 60, 4433), Vector3.new(50, 60, 5982),
Vector3.new(50, 60, 6749), Vector3.new(50, 60, 7516), Vector3.new(-60, -362, 9490)
}
Tabs.Main:AddDropdown("FarmModeDropdown", {
Title = "Farm Mode", Values = {"River", "Cave", "Both"}, Default = Config.FarmMode,
Callback = function(v) FarmSettings.Mode = v; Config.FarmMode = v; SaveConfig(Config) end
})
Tabs.Main:AddToggle("AutoFarmToggle", {Title = "Enable Auto Farm", Default = Config.AutoFarm}):OnChanged(function(v)
FarmSettings.Enabled = v; Config.AutoFarm = v; SaveConfig(Config)
if not v and basePart then pcall(function() basePart:Destroy() end); basePart = nil end
end)
Tabs.Main:AddSlider("CheckpointWaitSlider", {
Title = "Checkpoint Wait Time (s)", Default = Config.CheckpointWait, Min = 0.5, Max = 10, Rounding = 1,
Callback = function(v) FarmSettings.CheckpointWait = v; Config.CheckpointWait = v; SaveConfig(Config) end
})
Tabs.Main:AddSlider("EndRouteWaitSlider", {
Title = "End Route Wait Time (s)", Default = Config.EndRouteWait, Min = 1, Max = 30, Rounding = 1,
Callback = function(v) FarmSettings.EndRouteWait = v; Config.EndRouteWait = v; SaveConfig(Config) end
})
Tabs.Main:AddToggle("HoldPositionToggle", {Title = "Hold Position (Anti-Knockback)", Default = Config.HoldPosition}):OnChanged(function(v)
FarmSettings.HoldPosition = v; Config.HoldPosition = v; SaveConfig(Config)
end)
Tabs.Main:AddToggle("AutoClaimToggle", {Title = "Auto Claim Gold", Default = Config.AutoClaim}):OnChanged(function(v)
FarmSettings.AutoClaim = v; Config.AutoClaim = v; SaveConfig(Config)
end)
Tabs.Main:AddToggle("AutoResetCaveToggle", {Title = "Auto Reset After Cave", Default = Config.AutoResetCave}):OnChanged(function(v)
FarmSettings.AutoResetCave = v; Config.AutoResetCave = v; SaveConfig(Config)
end)
Tabs.Main:AddToggle("AutoBuyPineToggle", {Title = "Auto Buy Pine Trees", Default = Config.AutoBuyPine}):OnChanged(function(v)
FarmSettings.AutoBuyPine = v; Config.AutoBuyPine = v; SaveConfig(Config)
end)
Tabs.Main:AddSlider("PineQtySlider", {
Title = "Pine Tree Quantity", Default = Config.PineQty, Min = 1, Max = 100, Rounding = 0,
Callback = function(v) FarmSettings.PineQty = v; Config.PineQty = v; SaveConfig(Config) end
})
local OtherData = LocalPlayer:FindFirstChild("OtherData") or LocalPlayer:WaitForChild("OtherData", 10)
local ClaimRemote = workspace:FindFirstChild("ClaimRiverResultsGold")
local function CollectStage(StageNumber)
local Stages = workspace:FindFirstChild("BoatStages") and workspace.BoatStages:FindFirstChild("NormalStages")
if not Stages then return end
local Stage = Stages:FindFirstChild("CaveStage" .. StageNumber)
if not Stage then return end
local Collect = Stage:FindFirstChild("DarknessPart")
if not Collect then return end
local StageData = OtherData and OtherData:FindFirstChild("Stage" .. (StageNumber - 1))
local Char = LocalPlayer.Character
if not Char then return end
local Hum = Char:FindFirstChildOfClass("Humanoid")
local root = Char:FindFirstChild("HumanoidRootPart")
if not Hum or not root then return end
repeat
task.wait()
if not Char or not root or not Hum or Hum.Health <= 0 then break end
root.CFrame = Collect.CFrame * CFrame.new(0, 0, -20)
for _, BodyPart in pairs(Char:GetChildren()) do
if BodyPart:IsA("BasePart") then
BodyPart.AssemblyLinearVelocity = Vector3.zero
BodyPart.AssemblyAngularVelocity = Vector3.zero
end
end
until (StageData and StageData.Value ~= "") or not Char or not Hum or Hum.Health <= 0
end
local function TouchChest()
local Stages = workspace:FindFirstChild("BoatStages") and workspace.BoatStages:FindFirstChild("NormalStages")
local ChestTrigger = Stages and Stages:FindFirstChild("TheEnd") and Stages.TheEnd:FindFirstChild("GoldenChest") and Stages.TheEnd.GoldenChest:FindFirstChild("Trigger")
if not ChestTrigger then return end
task.spawn(function()
local Char = LocalPlayer.Character
if not Char then return end
local Hum = Char:FindFirstChildOfClass("Humanoid")
local root = Char:FindFirstChild("HumanoidRootPart")
if not Hum or not root then return end
local OtherDataEnd = OtherData and OtherData:FindFirstChild("End")
repeat
if not Char or not root or not Hum or Hum.Health <= 0 then break end
local Old = ChestTrigger.CFrame
ChestTrigger.CFrame = root.CFrame
task.wait()
ChestTrigger.CFrame = Old
until (OtherDataEnd and OtherDataEnd.Value ~= "") or not Char or not Hum or Hum.Health <= 0
end)
end
task.spawn(function()
while true do
if FarmSettings.Enabled then
pcall(function()
local char = LocalPlayer.Character
local root = char and char:FindFirstChild("HumanoidRootPart")
local hum = char and char:FindFirstChild("Humanoid")
if root and hum and hum.Health > 0 then
if FarmSettings.Mode == "River" or FarmSettings.Mode == "Both" then
for i, position in ipairs(riverPoints) do
if not FarmSettings.Enabled then break end
local isFinal = (i == #riverPoints)
local waitTime = isFinal and FarmSettings.EndRouteWait or FarmSettings.CheckpointWait
root.CFrame = CFrame.new(position)
local bv = nil
if FarmSettings.HoldPosition then
pcall(function()
bv = Instance.new("BodyVelocity")
bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
bv.Velocity = Vector3.zero
bv.Parent = root
end)
end
local startTime = os.clock()
while FarmSettings.Enabled and (os.clock() - startTime < waitTime) do
root.CFrame = CFrame.new(position)
task.wait()
end
if bv then pcall(function() bv:Destroy() end) end
end
if FarmSettings.AutoClaim and ClaimRemote then pcall(function() ClaimRemote:FireServer() end) end
if FarmSettings.AutoBuyPine then
local ShopEvent = workspace:FindFirstChild("ItemBoughtFromShop")
if ShopEvent then
for i = 1, FarmSettings.PineQty do
pcall(function() ShopEvent:InvokeServer("PineTree", 1) end)
task.wait(0.2)
end
end
end
end
if FarmSettings.Mode == "Cave" or FarmSettings.Mode == "Both" then
for StageNumber = 2, 10 do
if not FarmSettings.Enabled then break end
CollectStage(StageNumber)
if StageNumber ~= 2 then
if FarmSettings.AutoClaim and ClaimRemote then pcall(function() ClaimRemote:FireServer() end) end
else TouchChest() end
end
if FarmSettings.AutoResetCave and char then pcall(function() char:BreakJoints() end) end
end
end
end)
end
task.wait(1)
end
end)
LocalPlayer.CharacterAdded:Connect(function(char)
char:WaitForChild("HumanoidRootPart")
task.wait(3)
if char:FindFirstChild("Humanoid") then
char.Humanoid.WalkSpeed = Config.WalkSpeed
char.Humanoid.JumpHeight = Config.JumpHeight
char.Humanoid.UseJumpPower = false
end
end)
local water = workspace:FindFirstChild("Water")
local sand = workspace:FindFirstChild("Sand")
local walkWater = Config.WalkOnWater
local noVelocity = Config.NoVelocity
local waterVelo = Config.WaterVelocity
local sandOriginalPos = sand and sand.Position or Vector3.new(0,0,0)
Tabs.Water:AddToggle("WalkOnWaterToggle", {Title = "Walk on Water", Default = Config.WalkOnWater}):OnChanged(function(v)
walkWater = v; Config.WalkOnWater = v; SaveConfig(Config)
if not v and sand then pcall(function() sand.Position = sandOriginalPos; sand.CanCollide = false end) end
end)
Tabs.Water:AddSlider("WaterHeightSlider", {Title = "Water/Sand Height", Default = Config.WaterHeight, Min = 1, Max = 50, Rounding = 0,
Callback = function(v) Config.WaterHeight = v; SaveConfig(Config); if sand then pcall(function() sand.Size = Vector3.new(sand.Size.X, v, sand.Size.Z) end) end end})
Tabs.Water:AddToggle("NoVelocityToggle", {Title = "No Water Velocity", Default = Config.NoVelocity}):OnChanged(function(v)
noVelocity = v; Config.NoVelocity = v; SaveConfig(Config)
if sand then pcall(function() sand.AssemblyLinearVelocity = v and Vector3.new(0, 0, 0) or Vector3.new(0, 0, waterVelo) end) end
end)
Tabs.Water:AddSlider("VelocitySlider", {Title = "Set Water Velocity", Default = Config.WaterVelocity, Min = 0, Max = 100, Rounding = 0,
Callback = function(v) waterVelo = v; Config.WaterVelocity = v; SaveConfig(Config); if sand and not noVelocity then pcall(function() sand.AssemblyLinearVelocity = Vector3.new(0, 0, v) end) end end})
task.spawn(function()
while true do
if walkWater and sand and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
pcall(function()
local root = LocalPlayer.Character.HumanoidRootPart
sand.CanCollide = true
if water then water.CanTouch = false end
if root.Position.Z >= 8623 then sand.CanCollide = false end
sand.Position = Vector3.new(-53.5, sand.Position.Y, root.Position.Z)
end)
end
task.wait(0.1)
end
end)
local function GetZone()
local teamColor = LocalPlayer.TeamColor
if teamColor then return workspace:FindFirstChild(teamColor.Name .. "Zone") end
return nil
end
local function doQuest(q)
pcall(function()
local StartQuest = workspace:FindFirstChild("QuestMakerEvent")
if not StartQuest then return Fluent:Notify({Title = "Error", Content = "QuestMakerEvent not found", Duration = 3}) end
local Zone = GetZone()
if Zone and Zone:FindFirstChild("Quest") then
StartQuest:FireServer(0)
repeat task.wait() until not Zone:FindFirstChild("Quest")
task.wait(1)
end
StartQuest:FireServer(q)
task.wait(1)
Zone = GetZone()
local Quest = Zone and Zone:FindFirstChild("Quest")
local Char = LocalPlayer.Character
if not Char or not Quest then return end
if q == 1 then
local Part1 = Quest:FindFirstChild("Cloud") and Quest.Cloud:FindFirstChild("Part1")
if Part1 then Part1.CFrame = Char:GetPivot() end
elseif q == 2 then
local Target = Quest:FindFirstChild("Target")
if Target then
for _, Part in pairs(Target:GetChildren()) do
if Part.Name == "Part" and Part:FindFirstChildOfClass("Script") then Part.CFrame = Char:GetPivot(); break end
end
end
elseif q == 3 then
local Ramp = Quest:FindFirstChild("Ramp")
if Ramp then
for _, Part in pairs(Ramp:GetChildren()) do
if Part.Name == "Part" and Part:FindFirstChildOfClass("TouchTransmitter") then Part.CFrame = Char:GetPivot(); break end
end
end
elseif q == 4 then
local Butter = Quest:FindFirstChild("Butter")
local PPart = Butter and Butter:FindFirstChild("PPart")
local Click = PPart and PPart:FindFirstChildOfClass("ClickDetector")
if Click then repeat fireclickdetector(Click); task.wait(0.5) until not Zone:FindFirstChild("Quest") end
elseif q == 9 then
CollectStage(1)
local Stages = workspace:FindFirstChild("BoatStages") and workspace.BoatStages:FindFirstChild("NormalStages")
local ChestTrigger = Stages and Stages.TheEnd.GoldenChest.Trigger
if ChestTrigger then Char:PivotTo(ChestTrigger.CFrame) end
end
repeat task.wait() until not Zone:FindFirstChild("Quest")
Fluent:Notify({Title = "Quest", Content = "Quest " .. q .. " completed!", Duration = 2})
end)
end
Tabs.Quests:AddButton({Title = "Cloud Quest (1)", Callback = function() doQuest(1) end})
Tabs.Quests:AddButton({Title = "Target Quest (2)", Callback = function() doQuest(2) end})
Tabs.Quests:AddButton({Title = "Ramp Quest (3)", Callback = function() doQuest(3) end})
Tabs.Quests:AddButton({Title = "Butter Quest (4)", Callback = function() doQuest(4) end})
Tabs.Quests:AddButton({Title = "Thin Ice Quest (9)", Callback = function() doQuest(9) end})
local infJump = Config.InfJump
Tabs.Player:AddSlider("WalkSpeedSlider", {Title = "Walk Speed", Default = Config.WalkSpeed, Min = 16, Max = 500, Rounding = 0,
Callback = function(v) Config.WalkSpeed = v; SaveConfig(Config); pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = v end) end})
Tabs.Player:AddSlider("JumpHeightSlider", {Title = "Jump Height", Default = Config.JumpHeight, Min = 7, Max = 500, Rounding = 0,
Callback = function(v) Config.JumpHeight = v; SaveConfig(Config); pcall(function() LocalPlayer.Character.Humanoid.UseJumpPower = false; LocalPlayer.Character.Humanoid.JumpHeight = v end) end})
Tabs.Player:AddToggle("InfJumpToggle", {Title = "Infinite Jump", Default = Config.InfJump}):OnChanged(function(v)
infJump = v; Config.InfJump = v; SaveConfig(Config)
end)
UserInputService.JumpRequest:Connect(function()
if infJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
end
end)
local wayPos = nil
Tabs.Player:AddButton({Title = "Set Waypoint", Callback = function()
pcall(function() wayPos = LocalPlayer.Character.HumanoidRootPart.CFrame end)
Fluent:Notify({Title = "Waypoint", Content = "Position saved.", Duration = 2})
end})
Tabs.Player:AddButton({Title = "Teleport to Waypoint", Callback = function()
if wayPos then pcall(function() LocalPlayer.Character.HumanoidRootPart.CFrame = wayPos end) end
end})
local function findPlayer(name)
name = string.lower(name or "")
for _, plr in pairs(Players:GetPlayers()) do
if plr ~= LocalPlayer then
if string.find(string.lower(plr.Name), name) or string.find(string.lower(plr.DisplayName), name) then return plr end
end
end
return nil
end
local tpTarget = ""
local loopTP = false
local spectating = false
Tabs.Teleports:AddInput("PlayerNameInput", {Title = "Target Player Name", Placeholder = "Enter name...", Finished = true, Callback = function(t) tpTarget = t end})
Tabs.Teleports:AddButton({Title = "Teleport to Player", Callback = function()
local plr = findPlayer(tpTarget)
if plr and plr.Character then pcall(function() LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame end)
else Fluent:Notify({Title = "Error", Content = "Player not found.", Duration = 3}) end
end})
Tabs.Teleports:AddToggle("LoopTPToggle", {Title = "Loop Teleport to Player", Default = false}):OnChanged(function(v)
loopTP = v
if v then task.spawn(function() while loopTP do local plr = findPlayer(tpTarget); if plr and plr.Character and LocalPlayer.Character then pcall(function() LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(0,0,3) end) end; task.wait(0.1) end end) end
end)
Tabs.Teleports:AddToggle("SpectateToggle", {Title = "Spectate Player", Default = false}):OnChanged(function(v)
spectating = v
if v then local plr = findPlayer(tpTarget); if plr and plr.Character then workspace.CurrentCamera.CameraSubject = plr.Character:FindFirstChild("Humanoid") end
else workspace.CurrentCamera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") end
end)
Tabs.Teleports:AddButton({Title = "Remove Target's Base Lock", Callback = function()
local plr = findPlayer(tpTarget)
if plr then
local dict = {black = "BlackZone", blue = "Really blueZone", green = "CamoZone", magenta = "MagentaZone", red = "Really redZone", white = "WhiteZone", yellow = "New YellerZone"}
for _, team in pairs(Teams:GetChildren()) do
if team:FindFirstChild("TeamLeader") and team.TeamLeader.Value == plr.Name then
local zoneName = dict[team.Name] or team.Name
local zone = workspace:FindFirstChild(zoneName)
if zone and zone:FindFirstChild("Lock") then zone.Lock:Destroy(); Fluent:Notify({Title = "Success", Content = "Base lock removed for " .. plr.Name, Duration = 3}) end
break
end
end
end
end})
local tickTreat = Config.TickTreat
Tabs.Events:AddToggle("TickTreatToggle", {Title = "Auto Tick or Treat (Halloween)", Default = Config.TickTreat}):OnChanged(function(v)
tickTreat = v; Config.TickTreat = v; SaveConfig(Config)
end)
task.spawn(function()
while true do
if tickTreat then
pcall(function()
local eventPath = workspace:FindFirstChild("Houses")
if eventPath then
for _, house in pairs(eventPath:GetChildren()) do
if not tickTreat then break end
local carpet = house:FindFirstChild("Carpet")
if carpet and #carpet:GetChildren() >= 7 then
LocalPlayer.Character.HumanoidRootPart.CFrame = carpet:GetChildren()[7].CFrame + Vector3.new(0,0,math.random(0,6))
task.wait(1.5)
end
end
end
if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.Health = 0 end
end)
end
task.wait(2)
end
end)
local pineQtyShop = 1
Tabs.Events:AddInput("PineQtyInput", {Title = "Manual Pine Tree Quantity", Placeholder = "Amount to buy", Default = 1, Finished = true, Callback = function(v) pineQtyShop = tonumber(v) or 1 end})
Tabs.Events:AddButton({Title = "Buy Pine Trees (80 Gold Each)", Callback = function()
pcall(function()
local Event = workspace:FindFirstChild("ItemBoughtFromShop")
if Event then Event:InvokeServer("PineTree", pineQtyShop); Fluent:Notify({Title = "Shop", Content = "Bought " .. pineQtyShop .. " Pine Trees.", Duration = 3}) end
end)
end})
Tabs.Events:AddButton({Title = "Click Others Blocks (Troll)", Callback = function()
task.spawn(function()
local Blocks = workspace:FindFirstChild("Blocks")
if not Blocks then return end
for _, Folder in pairs(Blocks:GetChildren()) do
if Folder.Name ~= LocalPlayer.Name then
for _, Block in pairs(Folder:GetChildren()) do
if Block.Name ~= "CameraDome" then
local Click = Block:FindFirstChildOfClass("ClickDetector")
if Click then pcall(function() fireclickdetector(Click) end); task.wait() end
end
end
end
end
Fluent:Notify({Title = "Success", Content = "Clicked all other players' blocks.", Duration = 3})
end)
end})
Tabs.Events:AddButton({Title = "Crash Server (Spam Team Change)", Callback = function()
task.spawn(function()
local ChangeTeam = workspace:FindFirstChild("ChangeTeam")
if not ChangeTeam then return end
local TeamList = {}
for _, T in pairs(Teams:GetChildren()) do if T:IsA("Team") then table.insert(TeamList, T) end end
Fluent:Notify({Title = "Crashing", Content = "Spamming team change...", Duration = 3})
for _ = 1, 1000 do
for _, Team in pairs(TeamList) do pcall(function() ChangeTeam:FireServer(Team) end) end
task.wait()
end
end)
end})
pcall(function()
if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
LocalPlayer.Character.Humanoid.WalkSpeed = Config.WalkSpeed
LocalPlayer.Character.Humanoid.UseJumpPower = false
LocalPlayer.Character.Humanoid.JumpHeight = Config.JumpHeight
end
if sand then
sand.Size = Vector3.new(sand.Size.X, Config.WaterHeight, sand.Size.Z)
sand.AssemblyLinearVelocity = Config.NoVelocity and Vector3.new(0,0,0) or Vector3.new(0,0,Config.WaterVelocity)
end
end)
    
    ui.Window:SelectTab(1)
    ui.Fluent:Notify({
        Title = "GlockreisHub",
        Content = "Loaded for: Build A Boat For Treasure",
        Duration = 5
    })
end
