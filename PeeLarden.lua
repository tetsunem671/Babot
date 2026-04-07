--!strict
-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
print("69")
-- Events & Modules
local PurchaseEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("PurchaseConveyorEgg")
local SharedEggs = require(ReplicatedStorage.Modules.Gameplay.Shared_Eggs)
local SharedModifiers = require(ReplicatedStorage.Modules.Gameplay.Shared_Modifiers)

-- Rayfield UI (fixed 404)
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- State
local STATE = {
    AutoBuy = false,
    SelectedEggs = {},
    SelectedMutations = {}
}

-- Wait for Plots folder
local PlotsFolder = workspace:WaitForChild("Core"):WaitForChild("Scriptable"):WaitForChild("Plots")

-- Create Window
local Window = Rayfield:CreateWindow({
    Name = "Egg Auto-Buyer",
    LoadingTitle = "Initializing...",
    LoadingSubtitle = "Rayfield UI",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "EggAutoBuyer",
        FileName = "Config"
    },
    Discord = { Enabled = false },
    KeySystem = false
})

-- Create a Tab
local MainTab = Window:CreateTab("Main", 4483362458)
local AutoTab = Window:CreateTab("Auto", 4483362458)

-- Auto-Buy Toggle
local AutoBuyToggle = AutoTab:CreateToggle({
    Name = "Enable Auto-Buy",
    CurrentValue = false,
    Flag = "AutoBuyFlag",
    Callback = function(value)
        STATE.AutoBuy = value
    end
})

-- Recursively extract all egg keys (exact names used in Workspace)
local function extractEggKeys(tbl, result)
    result = result or {}
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            -- if table has AssetName, we consider this a leaf egg table
            if value.AssetName then
                table.insert(result, key) -- use the exact key instead of AssetName
            end
            -- recurse deeper in case of nested tables
            extractEggKeys(value, result)
        end
    end
    return result
end

local eggOptions = extractEggKeys(SharedEggs)

local EggDropdown = AutoTab:CreateDropdown({
    Name = "Select Eggs",
    Options = eggOptions,
    MultipleOptions = true,
    CurrentOption = {},
    Flag = "EggDropdownFlag",
    Callback = function(selected)
        STATE.SelectedEggs = selected
    end
})

local SearchBox = AutoTab:CreateInput({
    Name = "Search Eggs",
    PlaceholderText = "Type egg name...",
    Flag = "SearchEggFlag",
    Callback = function(text)
        -- Always ensure text is a string
        text = tostring(text or "")

        local filtered = {}
        for _, egg in ipairs(eggOptions) do
            if egg:lower():find(text:lower()) then
                table.insert(filtered, egg)
            end
        end

        -- If nothing matches, just show an empty table to avoid errors
        EggDropdown:Refresh(filtered or {})
    end
})


AutoTab:CreateButton({
    Name = "Select All Eggs",
    Flag = "SelectAllEggsFlag",
        
    Callback = function()
        STATE.SelectedEggs = eggOptions
        EggDropdown:Set(eggOptions) -- selects all eggs
    end
})

AutoTab:CreateButton({
    Name = "Clear Eggs",
    Flag = "ClearEggsFlag",
    Callback = function()
        STATE.SelectedEggs = {}
        EggDropdown:Set({}) -- clears all selections
    end
})

local ModifierOptions = {}
for key, _ in pairs(SharedModifiers.Modifiers) do
    table.insert(ModifierOptions, key)
end

-- Mutation Multi-Select Dropdown
local MutationDropdown = AutoTab:CreateDropdown({
    Name = "Select Mutations",
    Options = ModifierOptions, -- Replace with your mutations
    MultipleOptions = true,
    CurrentOption = {},
    Flag = "MutationDropdownFlag",
    Callback = function(selected)
        STATE.SelectedMutations = selected
    end
})

local SearchMutations = AutoTab:CreateInput({
    Name = "Search Mutations",
    PlaceholderText = "Type Mutation name...",
    Flag = "SearchMutationFlag",
    Callback = function(text)
        text = tostring(text or "")
        local filtered = {}
        for _, mutation in ipairs(ModifierOptions) do
            if mutation:lower():find(text:lower()) then
                table.insert(filtered, mutation)
            end
        end
        MutationDropdown:Refresh(filtered or {})
    end
})

AutoTab:CreateButton({
    Name = "Select All Mutations",
    Flag = "SelectAllMutationsFlag",
    Callback = function()
        STATE.SelectedMutations = ModifierOptions
        MutationDropdown:Set(ModifierOptions)
    end
})

AutoTab:CreateButton({
    Name = "Clear Mutations",
    Flag = "CleanAllMutationsFlag",
    Callback = function()
        STATE.SelectedMutations = {}
        MutationDropdown:Set({})
    end
})

task.spawn(function()
    while true do
        task.wait(0.2)
        if not STATE.AutoBuy then continue end  -- just skip this tick, don’t exit the loop

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
                        if prompt then
                            -- only trigger if not already bought / in progress
                            if not prompt:GetAttribute("TriggeredByScript") then
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
    end
end)
