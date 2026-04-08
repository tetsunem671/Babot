local UI = {
  Init = function()
      local STATE = getgenv().STATE
    
      --// Rayfield
      local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
      
      --// UI
      local Window = Rayfield:CreateWindow({
          Name = "Farm",
          LoadingTitle = "Initializing...",
          LoadingSubtitle = "by dapz",
          ConfigurationSaving = {
            Enabled = true,
            FolderName = "dapzHub", -- Create a custom folder for your hub/game
            FileName = "dapz Hub"
          },
          KeySystem = false
      })
      
      local EggsTab = Window:CreateTab("Eggs", 4483362458)
      local EventsTab = Window:CreateTab("Events", 4483362458)
      
      -- Toggles
      EggsTab:CreateToggle({
          Name = "Auto Buy (With Mutation)",
          CurrentValue = STATE.AutoBuyMutation,
          Callback = function(v)
              STATE.AutoBuyMutation = v
          end
      })
      
      EggsTab:CreateToggle({
          Name = "Auto Buy (No Mutation)",
          CurrentValue = STATE.AutoBuyNoMutation,
          Callback = function(v)
              STATE.AutoBuyNoMutation = v
          end
      })
      
      -- Egg Dropdowns
      local EggDropdownWithMutation = EggsTab:CreateDropdown({
          Name = "Select Eggs (With Mutation)",
          Options = getgenv().eggOptions,
          MultipleOptions = true,
          CurrentOption = STATE.SelectedEggsWithMutation,
          Callback = function(selected)
              STATE.SelectedEggsWithMutation = selected
          end
      })
      
      local EggDropdownNoMutation = EggsTab:CreateDropdown({
          Name = "Select Eggs (No Mutation)",
          Options = getgenv().eggOptions,
          MultipleOptions = true,
          CurrentOption = STATE.SelectedEggsNoMutation,
          Callback = function(selected)
              STATE.SelectedEggsNoMutation = selected
          end
      })
      
      -- Mutation Dropdown
      local MutationDropdown = EggsTab:CreateDropdown({
          Name = "Select Mutations",
          Options = getgenv().ModifierOptions,
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
      EggsTab:CreateButton({
          Name = "Select All Eggs (With Mutation)",
          Callback = function()
              STATE.SelectedEggsWithMutation = getgenv.eggOptions
              EggDropdownWithMutation:Set(getgenv.eggOptions)
          end
      })
      
      EggsTab:CreateButton({
          Name = "Clear Eggs (With Mutation)",
          Callback = function()
              STATE.SelectedEggsWithMutation = {}
              EggDropdownWithMutation:Set({})
          end
      })
      
      -- Eggs No Mutation
      EggsTab:CreateButton({
          Name = "Select All Eggs (No Mutation)",
          Callback = function()
              getgenv.STATE.SelectedEggsNoMutation = getgenv.eggOptions
              EggDropdownNoMutation:Set(getgenv.eggOptions)
          end
      })
      
      EggsTab:CreateButton({
          Name = "Clear Eggs (No Mutation)",
          Callback = function()
              getgenv.STATE.SelectedEggsNoMutation = {}
              EggDropdownNoMutation:Set({})
          end
      })
      
      -- Mutations
      EggsTab:CreateButton({
          Name = "Select All Mutations",
          Callback = function()
              getgenv.STATE.SelectedMutations = getgenv.ModifierOptions
              MutationDropdown:Set(getgenv.ModifierOptions)
          end
      })
      
      EggsTab:CreateButton({
          Name = "Clear Mutations",
          Callback = function()
              getgenv.STATE.SelectedMutations = {}
              MutationDropdown:Set({})
          end
      })

      -- Toggles
      EventsTab:CreateToggle({
          Name = "Auto Easter",
          CurrentValue = STATE.AutoEaster,
          Callback = function(v)
              STATE.AutoEaster = v
          end
      })

      EventsTab:CreateToggle({
          Name = "Auto Ghost",
          CurrentValue = STATE.AutoGhost,
          Callback = function(v)
              STATE.AutoGhost = v
          end
      })

      EventsTab:CreateToggle({
          Name = "Auto Arcade",
          CurrentValue = STATE.AutoArcade,
          Callback = function(v)
              STATE.AutoArcade = v
          end
      })

      EventsTab:CreateToggle({
          Name = "Auto Meteoron Pick",
          CurrentValue = STATE.AutoMeteoron,
          Callback = function(v)
              STATE.AutoMeteoron = v
          end
      })

      EventsTab:CreateToggle({
          Name = "Auto Snowflake Pick",
          CurrentValue = STATE.AutoSnowflake,
          Callback = function(v)
              STATE.AutoSnowflake = v
          end
      })
  end)
}
