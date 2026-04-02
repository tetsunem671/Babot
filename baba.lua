-- ============================================================
--  Roblox Private Server Auto-Rejoin
--  LocalScript → StarterPlayerScripts
--  Link and timer are set from the in-game GUI
-- ============================================================

local Players          = game:GetService("Players")
local TeleportService  = game:GetService("TeleportService")

local LocalPlayer      = Players.LocalPlayer
local PlayerGui        = LocalPlayer:WaitForChild("PlayerGui")

-- ── State ────────────────────────────────────────────────────
local countdownActive  = false
local countdownThread  = nil
local autoRepeat       = true

-- ============================================================
--  GUI BUILD
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "AutoRejoinGUI"
ScreenGui.ResetOnSpawn   = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = PlayerGui

-- ── Panel ────────────────────────────────────────────────────
local Panel = Instance.new("Frame")
Panel.Name               = "Panel"
Panel.Size               = UDim2.new(0, 300, 0, 350)
Panel.Position           = UDim2.new(0, 16, 0.5, -175)
Panel.BackgroundColor3   = Color3.fromRGB(18, 18, 18)
Panel.BorderSizePixel    = 0
Panel.Active             = true
Panel.Draggable          = true
Panel.Parent             = ScreenGui

Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 10)

local PanelStroke        = Instance.new("UIStroke", Panel)
PanelStroke.Color        = Color3.fromRGB(55, 55, 55)
PanelStroke.Thickness    = 1

-- ── Title Bar ────────────────────────────────────────────────
local TitleBar = Instance.new("Frame", Panel)
TitleBar.Size            = UDim2.new(1, 0, 0, 38)
TitleBar.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
TitleBar.BorderSizePixel = 0

Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

-- Patch bottom corners of title bar
local TFill = Instance.new("Frame", TitleBar)
TFill.Size               = UDim2.new(1, 0, 0, 10)
TFill.Position           = UDim2.new(0, 0, 1, -10)
TFill.BackgroundColor3   = Color3.fromRGB(26, 26, 26)
TFill.BorderSizePixel    = 0

local TitleLbl = Instance.new("TextLabel", TitleBar)
TitleLbl.Size            = UDim2.new(1, -44, 1, 0)
TitleLbl.Position        = UDim2.new(0, 12, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text            = "AUTO-REJOIN"
TitleLbl.TextColor3      = Color3.fromRGB(210, 210, 210)
TitleLbl.TextSize        = 12
TitleLbl.Font            = Enum.Font.GothamBold
TitleLbl.TextXAlignment  = Enum.TextXAlignment.Left

local CollapseBtn = Instance.new("TextButton", TitleBar)
CollapseBtn.Size         = UDim2.new(0, 28, 0, 28)
CollapseBtn.Position     = UDim2.new(1, -33, 0.5, -14)
CollapseBtn.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
CollapseBtn.BorderSizePixel = 0
CollapseBtn.Text         = "—"
CollapseBtn.TextColor3   = Color3.fromRGB(160, 160, 160)
CollapseBtn.TextSize     = 13
CollapseBtn.Font         = Enum.Font.GothamBold

Instance.new("UICorner", CollapseBtn).CornerRadius = UDim.new(0, 6)

-- ── Content ──────────────────────────────────────────────────
local Content = Instance.new("Frame", Panel)
Content.Size             = UDim2.new(1, 0, 1, -38)
Content.Position         = UDim2.new(0, 0, 0, 38)
Content.BackgroundTransparency = 1

local CPad = Instance.new("UIPadding", Content)
CPad.PaddingLeft   = UDim.new(0, 14)
CPad.PaddingRight  = UDim.new(0, 14)
CPad.PaddingTop    = UDim.new(0, 12)
CPad.PaddingBottom = UDim.new(0, 12)

local CList = Instance.new("UIListLayout", Content)
CList.SortOrder    = Enum.SortOrder.LayoutOrder
CList.Padding      = UDim.new(0, 8)

-- ── Util functions ───────────────────────────────────────────
local function sectionLabel(text, order)
    local l = Instance.new("TextLabel", Content)
    l.Size               = UDim2.new(1, 0, 0, 13)
    l.BackgroundTransparency = 1
    l.Text               = text
    l.TextColor3         = Color3.fromRGB(100, 100, 100)
    l.TextSize           = 10
    l.Font               = Enum.Font.GothamBold
    l.TextXAlignment     = Enum.TextXAlignment.Left
    l.LayoutOrder        = order
    return l
end

local function makeInput(placeholder, order)
    local box = Instance.new("TextBox", Content)
    box.Size             = UDim2.new(1, 0, 0, 34)
    box.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    box.BorderSizePixel  = 0
    box.Text             = ""
    box.PlaceholderText  = placeholder
    box.PlaceholderColor3 = Color3.fromRGB(72, 72, 72)
    box.TextColor3       = Color3.fromRGB(210, 210, 210)
    box.TextSize         = 11
    box.Font             = Enum.Font.Code
    box.ClearTextOnFocus = false
    box.TextXAlignment   = Enum.TextXAlignment.Left
    box.TextTruncate     = Enum.TextTruncate.AtEnd
    box.LayoutOrder      = order

    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
    local pad = Instance.new("UIPadding", box)
    pad.PaddingLeft  = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", box)
    stroke.Color   = Color3.fromRGB(48, 48, 48)
    stroke.Thickness = 1
    box.Focused:Connect(function()  stroke.Color = Color3.fromRGB(100,100,100) end)
    box.FocusLost:Connect(function() stroke.Color = Color3.fromRGB(48,48,48)  end)
    return box
end

-- ── Link field ───────────────────────────────────────────────
sectionLabel("PRIVATE SERVER LINK", 1)
local LinkBox = makeInput("https://www.roblox.com/games/.../...?privateServerLinkCode=...", 2)

-- ── Timer HH MM SS ───────────────────────────────────────────
sectionLabel("TIMER  ( HH : MM : SS )", 3)

local TimerRow = Instance.new("Frame", Content)
TimerRow.Size            = UDim2.new(1, 0, 0, 36)
TimerRow.BackgroundTransparency = 1
TimerRow.LayoutOrder     = 4

local TRList = Instance.new("UIListLayout", TimerRow)
TRList.FillDirection     = Enum.FillDirection.Horizontal
TRList.SortOrder         = Enum.SortOrder.LayoutOrder
TRList.Padding           = UDim.new(0, 4)
TRList.VerticalAlignment = Enum.VerticalAlignment.Center

local function timeBox(default, order)
    local b = Instance.new("TextBox", TimerRow)
    b.Size               = UDim2.new(0, 62, 1, 0)
    b.BackgroundColor3   = Color3.fromRGB(28, 28, 28)
    b.BorderSizePixel    = 0
    b.Text               = default
    b.TextColor3         = Color3.fromRGB(215, 215, 215)
    b.TextSize           = 20
    b.Font               = Enum.Font.GothamBold
    b.TextXAlignment     = Enum.TextXAlignment.Center
    b.ClearTextOnFocus   = false
    b.LayoutOrder        = order

    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke", b)
    s.Color              = Color3.fromRGB(48, 48, 48)
    s.Thickness          = 1
    b.Focused:Connect(function()  s.Color = Color3.fromRGB(100,100,100) end)
    b.FocusLost:Connect(function() s.Color = Color3.fromRGB(48,48,48)  end)
    return b
end

local function sep(order)
    local l = Instance.new("TextLabel", TimerRow)
    l.Size               = UDim2.new(0, 12, 1, 0)
    l.BackgroundTransparency = 1
    l.Text               = ":"
    l.TextColor3         = Color3.fromRGB(90, 90, 90)
    l.TextSize           = 20
    l.Font               = Enum.Font.GothamBold
    l.TextXAlignment     = Enum.TextXAlignment.Center
    l.LayoutOrder        = order
end

local HBox = timeBox("00", 1)  sep(2)
local MBox = timeBox("05", 3)  sep(4)
local SBox = timeBox("00", 5)

-- ── Presets ──────────────────────────────────────────────────
sectionLabel("PRESETS", 5)

local PresetRow = Instance.new("Frame", Content)
PresetRow.Size           = UDim2.new(1, 0, 0, 26)
PresetRow.BackgroundTransparency = 1
PresetRow.LayoutOrder    = 6

local PRList = Instance.new("UIListLayout", PresetRow)
PRList.FillDirection     = Enum.FillDirection.Horizontal
PRList.SortOrder         = Enum.SortOrder.LayoutOrder
PRList.Padding           = UDim.new(0, 4)

local presets = {{"5m",0,5,0},{"15m",0,15,0},{"30m",0,30,0},{"1h",1,0,0},{"2h",2,0,0},{"3h",3,0,0}}
local presetBtns = {}

for i, p in ipairs(presets) do
    local btn = Instance.new("TextButton", PresetRow)
    btn.Size             = UDim2.new(0, 40, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.BorderSizePixel  = 0
    btn.Text             = p[1]
    btn.TextColor3       = Color3.fromRGB(140, 140, 140)
    btn.TextSize         = 11
    btn.Font             = Enum.Font.GothamBold
    btn.LayoutOrder      = i

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local h, m, s = p[2], p[3], p[4]
    btn.MouseButton1Click:Connect(function()
        HBox.Text = string.format("%02d", h)
        MBox.Text = string.format("%02d", m)
        SBox.Text = string.format("%02d", s)
        for _, b in presetBtns do
            b.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            b.TextColor3       = Color3.fromRGB(140, 140, 140)
        end
        btn.BackgroundColor3 = Color3.fromRGB(58, 58, 58)
        btn.TextColor3       = Color3.fromRGB(225, 225, 225)
    end)
    table.insert(presetBtns, btn)
end

-- ── Auto-repeat toggle ───────────────────────────────────────
local RepeatRow = Instance.new("Frame", Content)
RepeatRow.Size           = UDim2.new(1, 0, 0, 26)
RepeatRow.BackgroundTransparency = 1
RepeatRow.LayoutOrder    = 7

local RepLbl = Instance.new("TextLabel", RepeatRow)
RepLbl.Size              = UDim2.new(1, -50, 1, 0)
RepLbl.BackgroundTransparency = 1
RepLbl.Text              = "Auto-repeat after join"
RepLbl.TextColor3        = Color3.fromRGB(140, 140, 140)
RepLbl.TextSize          = 12
RepLbl.Font              = Enum.Font.Gotham
RepLbl.TextXAlignment    = Enum.TextXAlignment.Left

local Track = Instance.new("Frame", RepeatRow)
Track.Size               = UDim2.new(0, 40, 0, 20)
Track.Position           = UDim2.new(1, -40, 0.5, -10)
Track.BackgroundColor3   = Color3.fromRGB(50, 50, 50)
Track.BorderSizePixel    = 0
Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

local Thumb = Instance.new("Frame", Track)
Thumb.Size               = UDim2.new(0, 14, 0, 14)
Thumb.Position           = UDim2.new(0, 3, 0.5, -7)
Thumb.BackgroundColor3   = Color3.fromRGB(120, 120, 120)
Thumb.BorderSizePixel    = 0
Instance.new("UICorner", Thumb).CornerRadius = UDim.new(1, 0)

local function setRepeat(val)
    autoRepeat = val
    if val then
        Track.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
        Thumb.Position         = UDim2.new(0, 23, 0.5, -7)
        Thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    else
        Track.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        Thumb.Position         = UDim2.new(0, 3, 0.5, -7)
        Thumb.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
    end
end
setRepeat(true)

Track.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        setRepeat(not autoRepeat)
    end
end)

-- ── Countdown display ────────────────────────────────────────
local CDLbl = Instance.new("TextLabel", Content)
CDLbl.Size               = UDim2.new(1, 0, 0, 36)
CDLbl.BackgroundTransparency = 1
CDLbl.Text               = "00:05:00"
CDLbl.TextColor3         = Color3.fromRGB(255, 255, 255)
CDLbl.TextSize           = 28
CDLbl.Font               = Enum.Font.GothamBold
CDLbl.TextXAlignment     = Enum.TextXAlignment.Center
CDLbl.LayoutOrder        = 8

local StatusLbl = Instance.new("TextLabel", Content)
StatusLbl.Size           = UDim2.new(1, 0, 0, 14)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Text           = "Paste a link and press Start"
StatusLbl.TextColor3     = Color3.fromRGB(95, 95, 95)
StatusLbl.TextSize       = 11
StatusLbl.Font           = Enum.Font.Gotham
StatusLbl.TextXAlignment = Enum.TextXAlignment.Center
StatusLbl.LayoutOrder    = 9

-- ── Start / Stop button ──────────────────────────────────────
local StartBtn = Instance.new("TextButton", Content)
StartBtn.Size            = UDim2.new(1, 0, 0, 36)
StartBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
StartBtn.BorderSizePixel = 0
StartBtn.Text            = "▶   START TIMER"
StartBtn.TextColor3      = Color3.fromRGB(10, 10, 10)
StartBtn.TextSize        = 13
StartBtn.Font            = Enum.Font.GothamBold
StartBtn.LayoutOrder     = 10

Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 6)

-- ============================================================
--  Logic
-- ============================================================
local function fmt(secs)
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    local s = secs % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end

local function setStatus(msg, color)
    StatusLbl.Text      = msg
    StatusLbl.TextColor3 = color or Color3.fromRGB(95, 95, 95)
    print("[AutoRejoin] " .. msg)
end

local function parseLink(link)
    local placeId = link:match("/games/(%d+)")
    local code    = link:match("[?&]privateServerLinkCode=([^&]+)")
    return tonumber(placeId), code
end

local function getTimerSecs()
    local h = math.clamp(tonumber(HBox.Text) or 0, 0, 23)
    local m = math.clamp(tonumber(MBox.Text) or 0, 0, 59)
    local s = math.clamp(tonumber(SBox.Text) or 0, 0, 59)
    return h * 3600 + m * 60 + s
end

local function syncDisplay()
    if not countdownActive then
        CDLbl.Text = fmt(getTimerSecs())
    end
end

for _, b in {HBox, MBox, SBox} do
    b.FocusLost:Connect(syncDisplay)
end

local function stopTimer()
    countdownActive = false
    if countdownThread then task.cancel(countdownThread) countdownThread = nil end
    StartBtn.Text            = "▶   START TIMER"
    StartBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
    StartBtn.TextColor3      = Color3.fromRGB(10, 10, 10)
    setStatus("Stopped.")
    syncDisplay()
end

local function doRejoin(placeId, code)
    setStatus("Teleporting...", Color3.fromRGB(250, 200, 60))
    task.wait(1)
    local ok, err = pcall(function()
        TeleportService:TeleportToPrivateServer(placeId, code, {LocalPlayer})
    end)
    if not ok then
        warn("[AutoRejoin] Teleport failed: " .. tostring(err))
        setStatus("Failed — retrying in 5s...", Color3.fromRGB(220, 70, 70))
        task.wait(5)
        pcall(function()
            TeleportService:TeleportToPrivateServer(placeId, code, {LocalPlayer})
        end)
    end
end

local function startTimer()
    local link = LinkBox.Text
    if link == "" then
        setStatus("Paste your server link first!", Color3.fromRGB(220, 70, 70)) return
    end
    local placeId, code = parseLink(link)
    if not placeId or not code then
        setStatus("Invalid link format!", Color3.fromRGB(220, 70, 70)) return
    end
    local total = getTimerSecs()
    if total <= 0 then
        setStatus("Set a time greater than 0", Color3.fromRGB(220, 70, 70)) return
    end

    countdownActive = true
    StartBtn.Text            = "■   STOP"
    StartBtn.BackgroundColor3 = Color3.fromRGB(200, 55, 55)
    StartBtn.TextColor3      = Color3.fromRGB(255, 255, 255)

    countdownThread = task.spawn(function()
        local rem = total
        while rem > 0 and countdownActive do
            CDLbl.Text = fmt(rem)
            if rem <= 10 then
                setStatus("Joining in " .. rem .. "s...", Color3.fromRGB(250, 200, 60))
            else
                setStatus("Counting down...", Color3.fromRGB(95, 95, 95))
            end
            task.wait(1)
            rem -= 1
        end
        if not countdownActive then return end
        doRejoin(placeId, code)
        if autoRepeat then
            task.wait(2)
            if countdownActive then
                setStatus("Restarting...", Color3.fromRGB(95, 95, 95))
                startTimer()
            end
        else
            stopTimer()
        end
    end)
end

StartBtn.MouseButton1Click:Connect(function()
    if countdownActive then stopTimer() else startTimer() end
end)

TeleportService.TeleportInitFailed:Connect(function(player, _, errMsg)
    if player ~= LocalPlayer then return end
    warn("[AutoRejoin] TeleportInitFailed: " .. tostring(errMsg))
    setStatus("Teleport init failed — check link", Color3.fromRGB(220, 70, 70))
end)

-- ── Collapse toggle ──────────────────────────────────────────
local collapsed = false
CollapseBtn.MouseButton1Click:Connect(function()
    collapsed = not collapsed
    Content.Visible  = not collapsed
    CollapseBtn.Text = collapsed and "+" or "—"
    Panel.Size       = collapsed and UDim2.new(0, 300, 0, 38) or UDim2.new(0, 300, 0, 350)
end)

syncDisplay()
