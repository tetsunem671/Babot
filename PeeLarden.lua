--!strict
-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

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
    MultiSelection = true,
    CurrentOption = {},
    Flag = "EggDropdownFlag",
    Callback = function(selected)
        STATE.SelectedEggs = selected
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
    MultiSelection = true,
    CurrentOption = {},
    Flag = "MutationDropdownFlag",
    Callback = function(selected)
        STATE.SelectedMutations = selected
    end
})

-- Auto-Buy Logic
RunService.Heartbeat:Connect(function()
    if not STATE.AutoBuy then return end

    for _, plot in pairs(PlotsFolder:GetChildren()) do
        if plot:FindFirstChild("Conveyor") and plot:FindFirstChild("Eggs") then
            for _, egg in pairs(plot.Eggs:GetChildren()) do
                local eggName = egg:GetAttribute("baseName")
                local eggModifiers = egg:GetAttribute("modifiers")
                local canBuy = false

                if table.find(STATE.SelectedEggs, eggName) then
                    if #STATE.SelectedMutations > 0 and typeof(eggModifiers) == "string" then
                        for mut in eggModifiers:gmatch("([^,]+)") do
                            mut = mut:match("^%s*(.-)%s*$")
                            if table.find(STATE.SelectedMutations, mut) then
                                canBuy = true
                                break
                            end
                        end
                    elseif #STATE.SelectedMutations == 0 then
                        canBuy = true
                    end
                end

                if canBuy then
                    pcall(function()
                        PurchaseEvent:FireServer(eggName, tonumber(plot.Name))
                    end)
                end
            end
        end
    end
end)
