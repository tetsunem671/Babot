-- Shared state
getgenv().STATE = loadstring(game:HttpGet("YOUR_UI_URL"))()


-- Load modules
local UI = loadstring(game:HttpGet("YOUR_UI_URL"))()
local EggBuyer = loadstring(game:HttpGet("PeeLardenBuyer"))()

local Events = loadstring(game:HttpGet("YOUR_EVENT_MODULE_URL"))()

-- Init
getgenv().STATE.Init()
UI.Init()
Logic.Start()
