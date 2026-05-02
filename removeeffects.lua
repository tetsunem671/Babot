--// SERVICES
local workspace = game:GetService("Workspace")

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
    handleVFX(v)
end)

--==================================================
-- FAILSAFE LOOP (ANTI-REENABLE / FAST EMIT)
--==================================================
task.spawn(function()
    while true do
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") then
                v.Enabled = false
                v.Rate = 0
            elseif v:IsA("Trail") or v:IsA("Beam") then
                v.Enabled = false
            end
        end
        task.wait(0.5) -- adjust (lower = stronger, higher = lighter)
    end
end)
