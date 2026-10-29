-- // ==========================================
-- // GLOCKREISHUB - UNIVERSAL LOADER (DEBUG MODE)
-- // ==========================================

local REPO_BASE = "https://raw.githubusercontent.com/sinemomerr22-maker/GlockReisHub/refs/heads/main"
local cacheBuster = "?t=" .. tostring(os.time()) -- GitHub cache sorununu önler

local function notify(msg)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "GlockreisHub Hata",
            Text = msg,
            Duration = 15
        })
    end)
    warn("[GlockreisHub] " .. msg)
end

local function loadModule(url, moduleName)
    local success, source = pcall(game.HttpGet, game, url)
    if not success or type(source) ~= "string" or #source < 50 then
        notify("İndirme başarısız: " .. moduleName)
        return nil
    end
    
    -- Hata tam olarak burada yakalanır
    local compiledFn, syntaxError = loadstring(source, moduleName)
    if not compiledFn then
        notify("Syntax Hatası (" .. moduleName .. "): " .. tostring(syntaxError))
        return nil
    end
    
    local execSuccess, execResult = pcall(compiledFn)
    if not execSuccess then
        notify("Çalıştırma Hatası (" .. moduleName .. "): " .. tostring(execResult))
        return nil
    end
    
    return execResult
end

-- 1. Common Modülünü Yükle
local commonUrl = REPO_BASE .. "/common.lua" .. cacheBuster
local common = loadModule(commonUrl, "common.lua")
if not common then return end

-- 2. Oyunu Tespit Et
local placeId = game.PlaceId
local currentGame = "Universal"
local moduleUrl = nil

local shindoInGamePlaces = {5447073001, 5084678830, 5431071837, 5431069982, 5943874201, 4601350214}
local bloxFruitsPlaces = {2753915549, 4442272183, 7449423635, 85211729168715, 79091703265657, 100117331123089}
local criminalityPlaces = {4588604953, 8343259840}

if placeId == 537413528 then
    currentGame = "BuildABoat"
    moduleUrl = REPO_BASE .. "/BuildABoat.lua" .. cacheBuster
elseif placeId == 4616652839 or table.find(shindoInGamePlaces, placeId) then
    currentGame = "ShindoLife"
    moduleUrl = REPO_BASE .. "/ShindoLife.lua" .. cacheBuster
elseif table.find(bloxFruitsPlaces, placeId) then
    currentGame = "BloxFruits"
    moduleUrl = REPO_BASE .. "/BloxFruits.lua" .. cacheBuster
elseif table.find(criminalityPlaces, placeId) then
    currentGame = "Criminality"
    moduleUrl = REPO_BASE .. "/Criminality.lua" .. cacheBuster
end

-- 3. Oyun Modülünü Yükle
if moduleUrl then
    local module = loadModule(moduleUrl, currentGame .. ".lua")
    if module and type(module) == "function" then
        local callSuccess, callErr = pcall(module, common)
        if not callSuccess then
            notify("Modül Hatası: " .. tostring(callErr))
        end
    end
else
    if common.setupUniversalMode then
        common.setupUniversalMode()
    end
end
