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

    SelectedEggs = CONFIG.EggCurrentOptions or {},
    SelectedMutations = CONFIG.MutationCurrentOptions or {}
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

CONFIG.EggCurrentOptions = filterValid(CONFIG.EggCurrentOptions, eggOptions)

if STATE.AllMutations then
    CONFIG.MutationCurrentOptions = ModifierOptions
else
    CONFIG.MutationCurrentOptions = filterValid(CONFIG.MutationCurrentOptions, ModifierOptions)
end

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

-- Egg Dropdown
local EggDropdown = AutoTab:CreateDropdown({
    Name = "Select Eggs",
    Options = eggOptions,
    MultipleOptions = true,
    CurrentOption = STATE.SelectedEggs,
    Callback = function(selected)
        STATE.SelectedEggs = selected
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
    EggDropdown:Set(STATE.SelectedEggs)
    MutationDropdown:Set(STATE.SelectedMutations)
end)

-- Buttons
AutoTab:CreateButton({
    Name = "Select All Eggs",
    Callback = function()
        STATE.SelectedEggs = eggOptions
        EggDropdown:Set(eggOptions)
    end
})

AutoTab:CreateButton({
    Name = "Clear Eggs",
    Callback = function()
        STATE.SelectedEggs = {}
        EggDropdown:Set({})
    end
})

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

                    if table.find(STATE.SelectedEggs, eggName) then
                        -- WITH MUTATION
                        if STATE.AutoBuyMutation and hasSelectedMutation(eggModifiers) then
                            canBuy = true
                        end

                        -- NO MUTATION
                        if STATE.AutoBuyNoMutation and isNoMutation(eggModifiers) then
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
