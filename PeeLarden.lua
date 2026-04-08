--!strict

--// CONFIG LOAD
local CONFIG = getgenv().CONFIG or {}

CONFIG.EggCurrentOptions = CONFIG.EggCurrentOptions or {}
CONFIG.MutationCurrentOptions = CONFIG.MutationCurrentOptions or {}

getgenv().CONFIG = CONFIG

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

--// Modules
local SharedEggs = require(ReplicatedStorage.Modules.Gameplay.Shared_Eggs)
local SharedModifiers = require(ReplicatedStorage.Modules.Gameplay.Shared_Modifiers)

--// Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

--// STATE
local STATE = {
    AutoBuy = false,
    SelectedEggs = CONFIG.EggCurrentOptions,
    SelectedMutations = CONFIG.MutationCurrentOptions
}

--// Workspace
local PlotsFolder = workspace:WaitForChild("Core"):WaitForChild("Scriptable"):WaitForChild("Plots")

--// Extract Eggs
local function extractEggKeys(tbl, result)
    result = result or {}
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            if value.AssetName then
                table.insert(result, key)
            end
            extractEggKeys(value, result)
        end
    end
    return result
end

local eggOptions = extractEggKeys(SharedEggs)

--// Extract Mutations
local ModifierOptions = {}
for key, _ in pairs(SharedModifiers.Modifiers) do
    table.insert(ModifierOptions, key)
end

--// VALIDATE CONFIG (prevents errors)
local function filterValid(list, validOptions)
    local valid = {}
    for _, v in ipairs(list) do
        if table.find(validOptions, v) then
            table.insert(valid, v)
        end
    end
    return valid
end

CONFIG.EggCurrentOptions = filterValid(CONFIG.EggCurrentOptions, eggOptions)
CONFIG.MutationCurrentOptions = filterValid(CONFIG.MutationCurrentOptions, ModifierOptions)

STATE.SelectedEggs = CONFIG.EggCurrentOptions
STATE.SelectedMutations = CONFIG.MutationCurrentOptions

--// UI
local Window = Rayfield:CreateWindow({
    Name = "Egg Auto-Buyer",
    LoadingTitle = "Initializing...",
    LoadingSubtitle = "Rayfield UI",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local AutoTab = Window:CreateTab("Auto", 4483362458)

-- Toggle
AutoTab:CreateToggle({
    Name = "Enable Auto-Buy",
    CurrentValue = false,
    Callback = function(v)
        STATE.AutoBuy = v
    end
})

-- Egg Dropdown
local EggDropdown = AutoTab:CreateDropdown({
    Name = "Select Eggs",
    Options = eggOptions,
    MultipleOptions = true,
    CurrentOption = STATE.SelectedEggs,
    Callback = function(selected)
        STATE.SelectedEggs = selected
        CONFIG.EggCurrentOptions = selected
    end
})

-- Mutation Dropdown
local MutationDropdown = AutoTab:CreateDropdown({
    Name = "Select Mutations",
    Options = ModifierOptions,
    MultipleOptions = true,
    CurrentOption = STATE.SelectedMutations,
    Callback = function(selected)
        STATE.SelectedMutations = selected
        CONFIG.MutationCurrentOptions = selected
    end
})

-- Apply config visually
task.defer(function()
    EggDropdown:Set(CONFIG.EggCurrentOptions)
    MutationDropdown:Set(CONFIG.MutationCurrentOptions)
end)

-- Buttons
AutoTab:CreateButton({
    Name = "Select All Eggs",
    Callback = function()
        STATE.SelectedEggs = eggOptions
        CONFIG.EggCurrentOptions = eggOptions
        EggDropdown:Set(eggOptions)
    end
})

AutoTab:CreateButton({
    Name = "Clear Eggs",
    Callback = function()
        STATE.SelectedEggs = {}
        CONFIG.EggCurrentOptions = {}
        EggDropdown:Set({})
    end
})

AutoTab:CreateButton({
    Name = "Select All Mutations",
    Callback = function()
        STATE.SelectedMutations = ModifierOptions
        CONFIG.MutationCurrentOptions = ModifierOptions
        MutationDropdown:Set(ModifierOptions)
    end
})

AutoTab:CreateButton({
    Name = "Clear Mutations",
    Callback = function()
        STATE.SelectedMutations = {}
        CONFIG.MutationCurrentOptions = {}
        MutationDropdown:Set({})
    end
})

--// DEBUG: PRINT ALL OPTIONS (THIS IS WHAT YOU WANTED)
print("=== ALL EGGS ===")
for _, v in ipairs(eggOptions) do
    print(v)
end

print("=== ALL MUTATIONS ===")
for _, v in ipairs(ModifierOptions) do
    print(v)
end

--// LOOP
task.spawn(function()
    while true do
        task.wait(0.2)
        if not STATE.AutoBuy then continue end

        for _, plot in pairs(PlotsFolder:GetChildren()) do
            if plot:FindFirstChild("Conveyor") and plot:FindFirstChild("Eggs") then
                for _, egg in pairs(plot.Eggs:GetChildren()) do
                    local eggName = egg:GetAttribute("baseName")
                    local eggModifiers = egg:GetAttribute("modifiers")
                    local canBuy = false

                    if table.find(STATE.SelectedEggs, eggName) then
                        if #STATE.SelectedMutations > 0 then
                            if typeof(eggModifiers) == "string" and eggModifiers ~= "" then
                                for mut in eggModifiers:gmatch("([^,]+)") do
                                    mut = mut:match("^%s*(.-)%s*$")
                                    if table.find(STATE.SelectedMutations, mut) then
                                        canBuy = true
                                        break
                                    end
                                end
                            else
                                canBuy = true
                            end
                        else
                            canBuy = true
                        end
                    end

                    if canBuy then
                        local prompt = egg:FindFirstChildWhichIsA("ProximityPrompt")
                        if prompt and not prompt:GetAttribute("TriggeredByScript") then
                            prompt:SetAttribute("TriggeredByScript", true)

                            task.spawn(function()
                                prompt:InputHoldBegin()
                                task.wait(0.5)
                                prompt:InputHoldEnd()
                                task.wait(0.1)
                                prompt:SetAttribute("TriggeredByScript", false)
                            end)
                        end
                    end
                end
            end
        end
    end
end)
