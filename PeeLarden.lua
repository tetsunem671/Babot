--!strict

--// CONFIG LOAD
local CONFIG = getgenv().CONFIG or {}

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
    AutoBuyMutation = CONFIG.AutoBuyMutation or false,
    AutoBuyNoMutation = CONFIG.AutoBuyNoMutation or false,

    SelectedEggsWithMutation = CONFIG.EggCurrentOptions_WithMutation or {},
    SelectedEggsNoMutation = CONFIG.EggCurrentOptions_NoMutation or {},

    SelectedMutations = CONFIG.MutationCurrentOptions or {},
    AllMutations = CONFIG.AllMutations
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

CONFIG.EggCurrentOptions_WithMutation = filterValid(CONFIG.EggCurrentOptions_WithMutation or {}, eggOptions)
CONFIG.EggCurrentOptions_NoMutation = filterValid(CONFIG.EggCurrentOptions_NoMutation or {}, eggOptions)

if STATE.AllMutations then
    CONFIG.MutationCurrentOptions = ModifierOptions
else
    CONFIG.MutationCurrentOptions = filterValid(CONFIG.MutationCurrentOptions or {}, ModifierOptions)
end

STATE.SelectedEggsWithMutation = CONFIG.EggCurrentOptions_WithMutation
STATE.SelectedEggsNoMutation = CONFIG.EggCurrentOptions_NoMutation
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

-- Toggles
AutoTab:CreateToggle({
    Name = "Auto Buy (With Mutation)",
    CurrentValue = STATE.AutoBuyMutation,
    Callback = function(v)
        STATE.AutoBuyMutation = v
    end
})

AutoTab:CreateToggle({
    Name = "Auto Buy (No Mutation)",
    CurrentValue = STATE.AutoBuyNoMutation,
    Callback = function(v)
        STATE.AutoBuyNoMutation = v
    end
})

-- Egg Dropdowns
local EggDropdownWithMutation = AutoTab:CreateDropdown({
    Name = "Select Eggs (With Mutation)",
    Options = eggOptions,
    MultipleOptions = true,
    CurrentOption = STATE.SelectedEggsWithMutation,
    Callback = function(selected)
        STATE.SelectedEggsWithMutation = selected
    end
})

local EggDropdownNoMutation = AutoTab:CreateDropdown({
    Name = "Select Eggs (No Mutation)",
    Options = eggOptions,
    MultipleOptions = true,
    CurrentOption = STATE.SelectedEggsNoMutation,
    Callback = function(selected)
        STATE.SelectedEggsNoMutation = selected
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
    end
})

-- Apply config visually
task.defer(function()
    EggDropdownWithMutation:Set(STATE.SelectedEggsWithMutation)
    EggDropdownNoMutation:Set(STATE.SelectedEggsNoMutation)
    MutationDropdown:Set(STATE.SelectedMutations)
end)

-- Buttons
-- Eggs With Mutation
AutoTab:CreateButton({
    Name = "Select All Eggs (With Mutation)",
    Callback = function()
        STATE.SelectedEggsWithMutation = eggOptions
        EggDropdownWithMutation:Set(eggOptions)
    end
})

AutoTab:CreateButton({
    Name = "Clear Eggs (With Mutation)",
    Callback = function()
        STATE.SelectedEggsWithMutation = {}
        EggDropdownWithMutation:Set({})
    end
})

-- Eggs No Mutation
AutoTab:CreateButton({
    Name = "Select All Eggs (No Mutation)",
    Callback = function()
        STATE.SelectedEggsNoMutation = eggOptions
        EggDropdownNoMutation:Set(eggOptions)
    end
})

AutoTab:CreateButton({
    Name = "Clear Eggs (No Mutation)",
    Callback = function()
        STATE.SelectedEggsNoMutation = {}
        EggDropdownNoMutation:Set({})
    end
})

-- Mutations
AutoTab:CreateButton({
    Name = "Select All Mutations",
    Callback = function()
        STATE.SelectedMutations = ModifierOptions
        MutationDropdown:Set(ModifierOptions)
    end
})

AutoTab:CreateButton({
    Name = "Clear Mutations",
    Callback = function()
        STATE.SelectedMutations = {}
        MutationDropdown:Set({})
    end
})

--// HELPER FUNCTIONS
local function hasSelectedMutation(eggModifiers)
    if typeof(eggModifiers) ~= "string" or eggModifiers == "" then
        return false
    end
    for mut in eggModifiers:gmatch("([^,]+)") do
        mut = mut:match("^%s*(.-)%s*$")
        if table.find(STATE.SelectedMutations, mut) then
            return true
        end
    end
    return false
end

local function isNoMutation(eggModifiers)
    return typeof(eggModifiers) ~= "string" or eggModifiers == ""
end

--// LOOP
task.spawn(function()
    while true do
        task.wait(0.2)

        for _, plot in pairs(PlotsFolder:GetChildren()) do
            if plot:FindFirstChild("Conveyor") and plot:FindFirstChild("Eggs") then
                for _, egg in pairs(plot.Eggs:GetChildren()) do
                    local eggName = egg:GetAttribute("baseName")
                    local eggModifiers = egg:GetAttribute("modifiers")
                    local canBuy = false

                    -- WITH MUTATION
                    if STATE.AutoBuyMutation 
                    and table.find(STATE.SelectedEggsWithMutation, eggName)
                    and hasSelectedMutation(eggModifiers) then
                        canBuy = true
                    end

                    -- NO MUTATION
                    if STATE.AutoBuyNoMutation 
                    and table.find(STATE.SelectedEggsNoMutation, eggName)
                    and isNoMutation(eggModifiers) then
                        canBuy = true
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
