-- // ==========================================
-- // GLOCKREISHUB - UNIVERSAL LOADER
-- // ==========================================

-- GitHub repo URL'lerini buraya yaz (kendi repo'na göre güncelle)
local REPO_BASE = "https://raw.githubusercontent.com/sinemomerr22-maker/GlockReisHub/refs/heads/main"

local tick = tostring(os.time())
local placeId = game.PlaceId
local commonUrl = REPO_BASE .. "/common.lua?t=" .. tick

-- Ortak modülü yükle
local commonLoaded, common = pcall(function()
    return loadstring(game:HttpGet(commonUrl))()
end)

if not commonLoaded then
    warn("[GlockreisHub] Failed to load common module: " .. tostring(common))
    return
end

-- Oyun tespiti
local currentGame = "Universal"
local shindoInGamePlaces = {5447073001, 5084678830, 5431071837, 5431069982, 5943874201, 4601350214}
local bloxFruitsPlaces = {2753915549, 4442272183, 7449423635, 85211729168715, 79091703265657, 100117331123089}
local criminalityPlaces = {4588604953, 8343259840}

local moduleUrl = nil

if placeId == 537413528 then
    currentGame = "BuildABoat"
    moduleUrl = REPO_BASE .. "/BuildABoat.lua"
elseif placeId == 4616652839 or table.find(shindoInGamePlaces, placeId) then
    currentGame = "ShindoLife"
    moduleUrl = REPO_BASE .. "/ShindoLife.lua"
elseif table.find(bloxFruitsPlaces, placeId) then
    currentGame = "BloxFruits"
    moduleUrl = REPO_BASE .. "/BloxFruits.lua"
elseif table.find(criminalityPlaces, placeId) then
    currentGame = "Criminality"
    moduleUrl = REPO_BASE .. "/Criminality.lua"
else
    currentGame = "Universal"
end

-- Modülü yükle ve çalıştır
if moduleUrl then
    local moduleLoaded, module = pcall(function()
        return loadstring(game:HttpGet(moduleUrl))()
    end)
    
    if moduleLoaded and type(module) == "function" then
        module(common)
    else
        warn("[GlockreisHub] Failed to load " .. currentGame .. " module: " .. tostring(module))
    end
else
    -- Universal mode - sadece common utilities
    common.setupUniversalMode()
end
