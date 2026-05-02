--// SERVICES
local workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local VFX = {}

--==================================================
-- SETTINGS
--==================================================
VFX.Enabled = true
VFX.Auto = false -- auto-disable on low FPS

local TARGET_NAMES = {
    "Effect",
    "VFX",
    "Particle",
    "Trail",
    "Beam"
}

--==================================================
-- INTERNAL
--==================================================
local cache = {}
local connections = {}
local loopRunning = false

local function isEntityVFX(obj)
    -- filter: ignore UI / keep only world effects
    if obj:IsDescendantOf(game.Players.LocalPlayer.PlayerGui) then
        return false
    end

    for _,name in ipairs(TARGET_NAMES) do
        if string.find(obj.Name, name) then
            return true
        end
    end

    return obj:IsA("ParticleEmitter")
        or obj:IsA("Trail")
        or obj:IsA("Beam")
end

local function cacheProp(obj, prop, val)
    cache[obj] = cache[obj] or {}
    if cache[obj][prop] == nil then
        cache[obj][prop] = val
    end
end

local function restoreAll()
    for obj,data in pairs(cache) do
        for prop,val in pairs(data) do
            pcall(function()
                obj[prop] = val
            end)
        end
    end
end

local function handle(obj)
    if VFX.Enabled then return end
    if not isEntityVFX(obj) then return end

    if obj:IsA("ParticleEmitter") then
        cacheProp(obj,"Enabled",obj.Enabled)
        cacheProp(obj,"Rate",obj.Rate)

        obj.Enabled = false
        obj.Rate = 0
        obj.Speed = NumberRange.new(0)
        obj.Lifetime = NumberRange.new(0)
        obj:Clear()
    elseif obj:IsA("Trail") or obj:IsA("Beam") then
        cacheProp(obj,"Enabled",obj.Enabled)
        obj.Enabled = false
    end
end

--==================================================
-- CORE API
--==================================================
function VFX:Set(state)
    self.Enabled = state

    if state then
        -- restore
        restoreAll()
    else
        -- disable
        for _,v in ipairs(workspace:GetDescendants()) do
            handle(v)
        end
    end
end

function VFX:Start()
    workspace.DescendantAdded:Connect(function(v)
        handle(v)
    end)

    if loopRunning then return end
    loopRunning = true

    task.spawn(function()
        while loopRunning do
            if not self.Enabled then
                for _,v in ipairs(workspace:GetDescendants()) do
                    handle(v)
                end
            end
            task.wait(0.5)
        end
    end)
end

--==================================================
-- FPS SYSTEM
--==================================================
local fps = 60
RunService.RenderStepped:Connect(function(dt)
    fps = math.floor(1/dt)
end)

function VFX:GetFPS()
    return fps
end

function VFX:SetAuto(state)
    self.Auto = state

    if state then
        task.spawn(function()
            while self.Auto do
                if fps < 30 then
                    self:Set(false) -- disable VFX
                else
                    self:Set(true) -- enable VFX
                end
                task.wait(2)
            end
        end)
    end
end

return VFX
