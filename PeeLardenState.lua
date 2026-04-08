local CONFIG = getgenv().CONFIG or {}

local STATE = {
    AutoBuyMutation = CONFIG.AutoBuyMutation or false,
    AutoBuyNoMutation = CONFIG.AutoBuyNoMutation or false,

    SelectedEggsWithMutation = CONFIG.EggCurrentOptions_WithMutation or {},
    SelectedEggsNoMutation = CONFIG.EggCurrentOptions_NoMutation or {},

    SelectedMutations = CONFIG.MutationCurrentOptions or {},
    AllMutations = CONFIG.AllMutations
    Init = function()
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
        
        getgenv().eggOptions = extractEggKeys(SharedEggs)
        
        --// Extract Mutations
        getgenv().ModifierOptions = {}
        for key, _ in pairs(SharedModifiers.Modifiers) do
            table.insert(getgenv().ModifierOptions, key)
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
        
        CONFIG.EggCurrentOptions_WithMutation = filterValid(CONFIG.EggCurrentOptions_WithMutation or {}, getgenv().eggOptions)
        CONFIG.EggCurrentOptions_NoMutation = filterValid(CONFIG.EggCurrentOptions_NoMutation or {}, getgenv().eggOptions)
        
        if STATE.AllMutations then
            CONFIG.MutationCurrentOptions = getgenv().ModifierOptions
        else
            CONFIG.MutationCurrentOptions = filterValid(CONFIG.MutationCurrentOptions or {}, getgenv().ModifierOptions)
        end
        
        STATE.SelectedEggsWithMutation = CONFIG.EggCurrentOptions_WithMutation
        STATE.SelectedEggsNoMutation = CONFIG.EggCurrentOptions_NoMutation
        STATE.SelectedMutations = CONFIG.MutationCurrentOptions
    end)
}

return STATE
