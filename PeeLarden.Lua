

--// =========================
--// LOAD RAYFIELD
--// =========================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

--// =========================
--// WINDOW
--// =========================
local Window = Rayfield:CreateWindow({
    Name = "Your Hub Name",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "by You",
    ConfigurationSaving = {
        Enabled = false
    }
})

--// =========================
--// TABS
--// =========================
local MainTab = Window:CreateTab("Main", 4483362458)
local SecondTab = Window:CreateTab("Second", 4483362458)
local ThirdTab = Window:CreateTab("Misc", 4483362458)

--// =========================
--// TOGGLE
--// =========================
MainTab:CreateToggle({
    Name = "Toggle Example",
    CurrentValue = false,
    Callback = function(val)
        print("Toggle:", val)
    end
})

--// =========================
--// BUTTON
--// =========================
MainTab:CreateButton({
    Name = "Button Example",
    Callback = function()
        print("Button clicked")
    end
})

--// =========================
--// SLIDER
--// =========================
MainTab:CreateSlider({
    Name = "Slider Example",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = 50,
    Callback = function(val)
        print("Slider:", val)
    end
})

--// =========================
--// DROPDOWN
--// =========================
MainTab:CreateDropdown({
    Name = "Dropdown Example",
    Options = {"Option 1", "Option 2", "Option 3"},
    CurrentOption = "Option 1",
    Callback = function(option)
        print("Selected:", option)
    end
})

--// =========================
--// INPUT (TEXTBOX)
--// =========================
MainTab:CreateInput({
    Name = "Input Example",
    PlaceholderText = "Type here...",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        print("Input:", text)
    end
})

--// =========================
--// KEYBIND
--// =========================
MainTab:CreateKeybind({
    Name = "Keybind Example",
    CurrentKeybind = "F",
    HoldToInteract = false,
    Callback = function()
        print("Key pressed")
    end
})

--// =========================
--// LABEL
--// =========================
MainTab:CreateLabel("This is a label")

--// =========================
--// PARAGRAPH
--// =========================
MainTab:CreateParagraph({
    Title = "Paragraph Title",
    Content = "This is a paragraph description."
})

--// =========================
--// NOTIFICATION
--// =========================
Rayfield:Notify({
    Title = "Notification",
    Content = "Hello from Rayfield",
    Duration = 3
})
