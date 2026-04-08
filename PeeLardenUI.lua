local UI = {
  Init = function()
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
          CurrentValue = getgenv().STATE.AutoBuyMutation,
          Callback = function(v)
              getgenv().STATE.AutoBuyMutation = v
          end
      })
      
      EggsTab:CreateToggle({
          Name = "Auto Buy (No Mutation)",
          CurrentValue = getgenv().STATE.AutoBuyNoMutation,
          Callback = function(v)
              getgenv().STATE.AutoBuyNoMutation = v
          end
      })
      
      -- Egg Dropdowns
      local EggDropdownWithMutation = EggsTab:CreateDropdown({
          Name = "Select Eggs (With Mutation)",
          Options = getgenv().eggOptions,
          MultipleOptions = true,
          CurrentOption = getgenv().STATE.SelectedEggsWithMutation,
          Callback = function(selected)
              getgenv().STATE.SelectedEggsWithMutation = selected
          end
      })
      
      local EggDropdownNoMutation = EggsTab:CreateDropdown({
          Name = "Select Eggs (No Mutation)",
          Options = getgenv().eggOptions,
          MultipleOptions = true,
          CurrentOption = getgenv().STATE.SelectedEggsNoMutation,
          Callback = function(selected)
              getgenv().STATE.SelectedEggsNoMutation = selected
          end
      })
      
      -- Mutation Dropdown
      local MutationDropdown = EggsTab:CreateDropdown({
          Name = "Select Mutations",
          Options = getgenv().ModifierOptions,
          MultipleOptions = true,
          CurrentOption = getgenv().STATE.SelectedMutations,
          Callback = function(selected)
              getgenv().STATE.SelectedMutations = selected
          end
      })
      
      -- Apply config visually
      task.defer(function()
          EggDropdownWithMutation:Set(getgenv().STATE.SelectedEggsWithMutation)
          EggDropdownNoMutation:Set(getgenv().STATE.SelectedEggsNoMutation)
          MutationDropdown:Set(getgenv().STATE.SelectedMutations)
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
          CurrentValue = getgenv().STATE.AutoEaster,
          Callback = function(v)
              getgenv().STATE.AutoEaster = v
          end
      })

      EventsTab:CreateToggle({
          Name = "Auto Ghost",
          CurrentValue = getgenv().STATE.AutoGhost,
          Callback = function(v)
              getgenv().STATE.AutoGhost = v
          end
      })

      EventsTab:CreateToggle({
          Name = "Auto Arcade",
          CurrentValue = getgenv().STATE.AutoArcade,
          Callback = function(v)
              getgenv().STATE.AutoArcade = v
          end
      })

      EventsTab:CreateToggle({
          Name = "Auto Meteoron Pick",
          CurrentValue = getgenv().STATE.AutoMeteoron,
          Callback = function(v)
              getgenv().STATE.AutoMeteoron = v
          end
      })

      EventsTab:CreateToggle({
          Name = "Auto Snowflake Pick",
          CurrentValue = getgenv().STATE.AutoSnowflake,
          Callback = function(v)
              getgenv().STATE.AutoSnowflake = v
          end
      })
  end)
}
