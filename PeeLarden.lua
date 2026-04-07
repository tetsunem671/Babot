--// =========================
--// LOAD RAYFIELD
--// =========================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Egg Hub",
    LoadingTitle = "Egg Auto Buy",
    LoadingSubtitle = "by You",
    ConfigurationSaving = { Enabled = false }
})

--// =========================
--// TAB
--// =========================
local EggTab = Window:CreateTab("Eggs", 4483362458)

--// =========================
--// SERVICES
--// =========================
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// =========================
--// STATE
--// =========================
local STATE = {
    AutoBuy = false,
    SelectedEgg = nil,
    SelectedMutation = "None"
}

--// =========================
--// GET EGG NAMES
--// =========================
local EggNames = {}
pcall(function()
    local EggsModule = require(ReplicatedStorage.Modules.Gameplay.Shared_Eggs)

    for name,_ in pairs(EggsModule.AssetName) do
        table.insert(EggNames, name)
    end
end)

table.sort(EggNames)

-- fallback if empty
if #EggNames == 0 then
    EggNames = {"Unknown Egg"}
end

STATE.SelectedEgg = EggNames[1]

--// =========================
--// GET MUTATIONS (AUTO)
--// =========================
local Mutations = {"None"}

local success, ModModule = pcall(function()
    return require(ReplicatedStorage.Modules.Gameplay.Shared_Modifiers)
end)

if success and ModModule then
    -- case 2: nested
    if ModModule.Modifiers then
        for k,_ in pairs(ModModule.Modifiers) do
            table.insert(Mutations, k)
        end
    end
end

-- fallback scan workspace if empty
if #Mutations <= 1 then
    local Seen = {}

    pcall(function()
        for _,v in pairs(workspace:GetDescendants()) do
            if v:IsA("Model") then
                local mods = v:GetAttribute("modifiers")
                if mods then
                    for m in mods:gmatch("([^,]+)") do
                        Seen[m] = true
                    end
                end
            end
        end
    end)

    for m,_ in pairs(Seen) do
        table.insert(Mutations, m)
    end
end

table.sort(Mutations)

--// =========================
--// UI ELEMENTS
--// =========================

-- Egg Dropdown
EggTab:CreateDropdown({
    Name = "Select Egg",
    Options = EggNames,
    CurrentOption = STATE.SelectedEgg,
    Callback = function(option)
        local selected = typeof(option) == "table" and option[1] or option
        STATE.SelectedEgg = selected
        print("Egg:", selected)
    end
})

-- Mutation Dropdown
EggTab:CreateDropdown({
    Name = "Select Mutation",
    Options = Mutations,
    CurrentOption = STATE.SelectedMutation,
    Callback = function(option)
        local selected = typeof(option) == "table" and option[1] or option
        STATE.SelectedMutation = selected
        print("Mutation:", selected)
    end
})

-- Toggle
EggTab:CreateToggle({
    Name = "Auto Buy Egg",
    CurrentValue = false,
    Callback = function(val)
        STATE.AutoBuy = val
        print("AutoBuy:", val)
    end
})

--// =========================
--// AUTO BUY LOOP
--// =========================
task.spawn(function()
    while true do
        task.wait(0.5)

        if STATE.AutoBuy and STATE.SelectedEgg then
            local Events = ReplicatedStorage:FindFirstChild("Events")
            local PurchaseEvent = Events and Events:FindFirstChild("PurchaseConveyorEgg")

            if PurchaseEvent then
                -- some games ignore mutation, some use it
                pcall(function()
                    PurchaseEvent:FireServer(
                        STATE.SelectedEgg,
                        STATE.SelectedMutation
                    )
                end)
            end
        end
    end
end)
