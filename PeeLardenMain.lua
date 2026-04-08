getgenv().CONFIG = getgenv().CONFIG or {}

-- Shared state
getgenv().STATE = {}

-- Load modules
local UI = loadstring(game:HttpGet("YOUR_UI_URL"))()
local Logic = loadstring(game:HttpGet("YOUR_LOGIC_URL"))()

-- Init
UI.Init()
Logic.Start()
