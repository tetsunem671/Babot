--// SERVICES
local workspace = game:GetService("Workspace")

_G.__VFX_STOP = function()
    _G.__VFX_DISABLED = true
end

_G.__VFX_DISABLED = false

--==================================================
-- CORE HANDLER
--==================================================
local function handleVFX(obj)

    --==============================
    -- PARTICLE EMITTER (main problem)
    --==============================
    if obj:IsA("ParticleEmitter") then
        obj.Enabled = false
        obj.Rate = 0
        obj.Speed = NumberRange.new(0)
        obj.Lifetime = NumberRange.new(0)
        obj:Clear()

        -- lock it permanently
        obj:GetPropertyChangedSignal("Enabled"):Connect(function()
            if obj.Enabled then obj.Enabled = false end
        end)

        obj:GetPropertyChangedSignal("Rate"):Connect(function()
            if obj.Rate ~= 0 then obj.Rate = 0 end
        end)

        return
    end

    --==============================
    -- TRAILS / BEAMS
    --==============================
    if obj:IsA("Trail") or obj:IsA("Beam") then
        obj.Enabled = false

        obj:GetPropertyChangedSignal("Enabled"):Connect(function()
            if obj.Enabled then obj.Enabled = false end
        end)

        return
    end

    --==============================
    -- SIMPLE EFFECTS
    --==============================
    if obj:IsA("Smoke")
    or obj:IsA("Fire")
    or obj:IsA("Sparkles") then

        obj.Enabled = false

        obj:GetPropertyChangedSignal("Enabled"):Connect(function()
            if obj.Enabled then obj.Enabled = false end
        end)

        return
    end

    --==============================
    -- EXPLOSIONS
    --==============================
    if obj:IsA("Explosion") then
        obj.Visible = false
        return
    end

    --==============================
    -- HIGHLIGHTS
    --==============================
    if obj:IsA("Highlight") then
        obj.Enabled = false

        obj:GetPropertyChangedSignal("Enabled"):Connect(function()
            if obj.Enabled then obj.Enabled = false end
        end)

        return
    end
end

--==================================================
-- INITIAL SWEEP
--==================================================
for _, v in ipairs(workspace:GetDescendants()) do
    handleVFX(v)
end

--==================================================
-- REAL-TIME HOOK (CRITICAL)
--==================================================
workspace.DescendantAdded:Connect(function(v)
    if _G.__VFX_DISABLED then return end
    handleVFX(v)
end)
