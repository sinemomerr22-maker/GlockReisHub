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

local shindoInGamePlaces = {4601350214, 5447073001, 6444873399, 5255237254, 5824792748, 6341670805, 5451401540, 6602103757, 6901575446, 5451398863, 5943872934, 5451405681, 5431071837, 4601350760, 4601350656, 7923764447, 4601350394, 8472733618, 6986372023, 4601350587, 4601350809, 4601351115, 4601351332, 4616652839, 4758561453, 5003501700, 5064032128, 5084678830, 5249563214, 5405021965, 5415301824, 5431069982, 5431071837, 5447073001, 5447111963, 5943874201, 5990264023, 6351110753}
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
