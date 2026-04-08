local STATE = {
    AutoBuyMutation = CONFIG.AutoBuyMutation or false,
    AutoBuyNoMutation = CONFIG.AutoBuyNoMutation or false,

    SelectedEggsWithMutation = CONFIG.EggCurrentOptions_WithMutation or {},
    SelectedEggsNoMutation = CONFIG.EggCurrentOptions_NoMutation or {},

    SelectedMutations = CONFIG.MutationCurrentOptions or {},
    AllMutations = CONFIG.AllMutations
}

return STATE
