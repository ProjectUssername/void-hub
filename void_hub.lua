--[[
╔═══════════════════════════════════════════════════╗
║                  V O I D  H U B                   ║
║           Climb & Jump Tower Edition              ║
║                  Version 2.0                      ║
╚═══════════════════════════════════════════════════╝

  HOW TO USE:
  Buka executor → Paste seluruh script ini → Execute
  Script langsung jalan, tidak perlu URL atau file.
]]

-- ═══════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")

local lp   = Players.LocalPlayer
local mouse = lp:GetMouse()

local function getChar()
    return lp.Character
end
local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- ═══════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════
local S = {
    -- toggles
    InfJump       = false,
    SpeedHack     = false,
    AntiAFK       = false,
    GodMode       = false,
    Noclip        = false,
    AutoFarm      = false,
    ESP           = false,
    AutoCoin      = false,

    -- values
    WalkSpeed     = 16,
    JumpPower     = 50,

    -- ui
    UIOpen        = true,
    ActiveTab     = "MOVEMENT",

    -- connections store
    _conns        = {},
}

local function addConn(key, conn)
    if S._conns[key] then pcall(function() S._conns[key]:Disconnect() end) end
    S._conns[key] = conn
end
local function removeConn(key)
    if S._conns[key] then pcall(function() S._conns[key]:Disconnect() end) end
    S._conns[key] = nil
end

-- ═══════════════════════════════════════════════════
-- NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════════════
local notifGui
do
    notifGui = Instance.new("ScreenGui")
    notifGui.Name = "VoidNotifs"
    notifGui.ResetOnSpawn = false
    notifGui.DisplayOrder = 999
    pcall(function() notifGui.Parent = game:GetService("CoreGui") end)
end

local notifStack = {}
local function Notify(title, body, ntype)
    ntype = ntype or "info" -- "info" | "success" | "warn" | "error"
    local colors = {
        info    = Color3.fromRGB(0, 140, 255),
        success = Color3.fromRGB(0, 210, 120),
        warn    = Color3.fromRGB(255, 170, 0),
        error   = Color3.fromRGB(255, 60, 60),
    }
    local icons = { info = "◈", success = "✓", warn = "⚠", error = "✕" }

    -- shift existing notifs down
    for _, f in ipairs(notifStack) do
        TweenService:Create(f, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
            Position = f.Position + UDim2.new(0, 0, 0, 62)
        }):Play()
    end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 260, 0, 54)
    frame.Position = UDim2.new(1, -270, 0, -60)
    frame.BackgroundColor3 = Color3.fromRGB(8, 10, 18)
    frame.BorderSizePixel = 0
    frame.Parent = notifGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 1, 0)
    accent.BackgroundColor3 = colors[ntype]
    accent.BorderSizePixel = 0
    accent.Parent = frame
    Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 3)

    local iconL = Instance.new("TextLabel")
    iconL.Size = UDim2.new(0, 28, 1, 0)
    iconL.Position = UDim2.new(0, 10, 0, 0)
    iconL.BackgroundTransparency = 1
    iconL.Text = icons[ntype]
    iconL.TextSize = 16
    iconL.Font = Enum.Font.GothamBold
    iconL.TextColor3 = colors[ntype]
    iconL.Parent = frame

    local titL = Instance.new("TextLabel")
    titL.Size = UDim2.new(1, -50, 0, 22)
    titL.Position = UDim2.new(0, 42, 0, 5)
    titL.BackgroundTransparency = 1
    titL.Text = title
    titL.TextSize = 12
    titL.Font = Enum.Font.GothamBold
    titL.TextColor3 = Color3.fromRGB(220, 235, 255)
    titL.TextXAlignment = Enum.TextXAlignment.Left
    titL.Parent = frame

    local bodyL = Instance.new("TextLabel")
    bodyL.Size = UDim2.new(1, -50, 0, 16)
    bodyL.Position = UDim2.new(0, 42, 0, 26)
    bodyL.BackgroundTransparency = 1
    bodyL.Text = body or ""
    bodyL.TextSize = 10
    bodyL.Font = Enum.Font.Gotham
    bodyL.TextColor3 = Color3.fromRGB(90, 120, 160)
    bodyL.TextXAlignment = Enum.TextXAlignment.Left
    bodyL.Parent = frame

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = colors[ntype]
    stroke.Thickness = 1
    stroke.Transparency = 0.6

    table.insert(notifStack, 1, frame)

    TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Back), {
        Position = UDim2.new(1, -270, 0, 16)
    }):Play()

    task.delay(3.5, function()
        TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
            Position = UDim2.new(1, 20, 0, frame.Position.Y.Offset)
        }):Play()
        task.delay(0.3, function()
            frame:Destroy()
            table.remove(notifStack, table.find(notifStack, frame))
        end)
    end)
end

-- ═══════════════════════════════════════════════════
-- FEATURE: INFINITE JUMP
-- ═══════════════════════════════════════════════════
local function ToggleInfJump(on)
    S.InfJump = on
    if on then
        addConn("infJump", UserInputService.JumpRequest:Connect(function()
            local h = getHum()
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end))
        Notify("Infinite Jump", "Aktif", "success")
    else
        removeConn("infJump")
        Notify("Infinite Jump", "Dimatikan", "warn")
    end
end

-- ═══════════════════════════════════════════════════
-- FEATURE: SPEED HACK
-- ═══════════════════════════════════════════════════
local function ApplySpeed()
    local h = getHum()
    if h then h.WalkSpeed = S.SpeedHack and S.WalkSpeed or 16 end
end
local function ToggleSpeed(on)
    S.SpeedHack = on
    ApplySpeed()
    Notify("Speed Hack", on and ("Speed: "..S.WalkSpeed) or "Reset ke 16", on and "success" or "warn")
end

-- ═══════════════════════════════════════════════════
-- FEATURE: JUMP POWER
-- ═══════════════════════════════════════════════════
local function ApplyJump()
    local h = getHum()
    if h then h.JumpPower = S.JumpPower end
end

-- ═══════════════════════════════════════════════════
-- FEATURE: NOCLIP
-- ═══════════════════════════════════════════════════
local function ToggleNoclip(on)
    S.Noclip = on
    if on then
        addConn("noclip", RunService.Stepped:Connect(function()
            local c = getChar()
            if not c then return end
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                    p.CanCollide = false
                end
            end
        end))
        Notify("Noclip", "Tembus semua objek", "success")
    else
        removeConn("noclip")
        local c = getChar()
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
        Notify("Noclip", "Collision normal", "warn")
    end
end

-- ═══════════════════════════════════════════════════
-- FEATURE: GOD MODE (Anti-Ragdoll + Max Health)
-- ═══════════════════════════════════════════════════
local function ToggleGodMode(on)
    S.GodMode = on
    if on then
        addConn("godMode", RunService.Heartbeat:Connect(function()
            local h = getHum()
            if not h then return end
            h.MaxHealth = math.huge
            h.Health    = math.huge
            h:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
            h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        end))
        Notify("God Mode", "HP tak terbatas aktif", "success")
    else
        removeConn("godMode")
        local h = getHum()
        if h then
            h.MaxHealth = 100
            h.Health    = 100
            h:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
            h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        end
        Notify("God Mode", "Dimatikan", "warn")
    end
end

-- ═══════════════════════════════════════════════════
-- FEATURE: ANTI AFK
-- ═══════════════════════════════════════════════════
local function ToggleAntiAFK(on)
    S.AntiAFK = on
    if on then
        -- VirtualUser method (lebih aman)
        local VU = game:GetService("VirtualUser")
        addConn("antiAFK", lp.Idled:Connect(function()
            VU:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(0.1)
            VU:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end))
        Notify("Anti-AFK", "Karakter tidak akan kick", "success")
    else
        removeConn("antiAFK")
        Notify("Anti-AFK", "Dimatikan", "warn")
    end
end

-- ═══════════════════════════════════════════════════
-- FEATURE: AUTO COLLECT COINS
-- ═══════════════════════════════════════════════════
local function ToggleAutoCoin(on)
    S.AutoCoin = on
    if on then
        addConn("autoCoin", RunService.Heartbeat:Connect(function()
            local hrp = getHRP()
            if not hrp then return end
            for _, obj in ipairs(workspace:GetDescendants()) do
                local n = obj.Name:lower()
                if obj:IsA("BasePart") and (n:find("coin") or n:find("gem") or n:find("gold") or n:find("collectible") or n:find("pickup")) then
                    if (obj.Position - hrp.Position).Magnitude < 100 then
                        hrp.CFrame = CFrame.new(obj.Position + Vector3.new(0, 3, 0))
                        task.wait(0.05)
                    end
                end
            end
        end))
        Notify("Auto Coin", "Mengumpulkan koin otomatis", "success")
    else
        removeConn("autoCoin")
        Notify("Auto Coin", "Dimatikan", "warn")
    end
end

-- ═══════════════════════════════════════════════════
-- FEATURE: AUTO FARM STAGE
-- ═══════════════════════════════════════════════════
local autoFarmRunning = false
local function StopAutoFarm()
    autoFarmRunning = false
    removeConn("autoFarm")
    S.AutoFarm = false
end

local function ToggleAutoFarm(on)
    S.AutoFarm = on
    if not on then
        StopAutoFarm()
        Notify("Auto Farm", "Dihentikan", "warn")
        return
    end

    autoFarmRunning = true
    Notify("Auto Farm", "Mencari stage/checkpoint...", "info")

    task.spawn(function()
        while autoFarmRunning and S.AutoFarm do
            local hrp = getHRP()
            if not hrp then task.wait(0.5) continue end

            -- Kumpulkan semua checkpoint/stage parts dan urutkan dari bawah ke atas
            local targets = {}
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local n = obj.Name:lower()
                    if n:find("checkpoint") or n:find("stage") or n:find("part")
                    or n:find("platform") or n:find("step") or n:find("floor")
                    or n:find("block") or n:find("finish") or n:find("end")
                    or n:find("winner") or n:find("goal") then
                        table.insert(targets, obj)
                    end
                end
            end

            -- Sort by Y position ascending (bawah ke atas)
            table.sort(targets, function(a, b)
                return a.Position.Y < b.Position.Y
            end)

            if #targets == 0 then
                -- Fallback: lompat lurus ke atas
                hrp.CFrame = hrp.CFrame + Vector3.new(0, 300, 0)
                task.wait(1)
            else
                -- Teleport per stage dari posisi kita ke atas
                local myY = hrp.Position.Y
                local advanced = false
                for _, part in ipairs(targets) do
                    if not autoFarmRunning then break end
                    if part.Position.Y > myY + 10 then
                        hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 5, 0))
                        task.wait(0.12)
                        advanced = true
                    end
                end

                if not advanced then
                    -- Sudah di atas, coba push lebih tinggi
                    hrp.CFrame = hrp.CFrame + Vector3.new(0, 500, 0)
                    task.wait(1)
                    Notify("Auto Farm", "Reached top! Restarting...", "success")
                end
            end

            task.wait(0.2)
        end
    end)
end

-- ═══════════════════════════════════════════════════
-- FEATURE: ESP / HIGHLIGHT
-- ═══════════════════════════════════════════════════
local espObjects = {}
local function ClearESP()
    for _, h in ipairs(espObjects) do pcall(function() h:Destroy() end) end
    espObjects = {}
end

local function ToggleESP(on)
    S.ESP = on
    if not on then
        ClearESP()
        Notify("ESP", "Highlight dimatikan", "warn")
        return
    end
    -- Highlight semua players lain
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            local hl = Instance.new("SelectionBox")
            hl.Adornee = p.Character
            hl.Color3 = Color3.fromRGB(0, 150, 255)
            hl.LineThickness = 0.05
            hl.SurfaceTransparency = 0.85
            hl.SurfaceColor3 = Color3.fromRGB(0, 80, 200)
            hl.Parent = game.CoreGui
            table.insert(espObjects, hl)
        end
    end
    -- ESP untuk coins/gems
    for _, obj in ipairs(workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if obj:IsA("BasePart") and (n:find("coin") or n:find("gem") or n:find("gold")) then
            local hl = Instance.new("SelectionBox")
            hl.Adornee = obj
            hl.Color3 = Color3.fromRGB(255, 210, 0)
            hl.LineThickness = 0.04
            hl.SurfaceTransparency = 0.85
            hl.SurfaceColor3 = Color3.fromRGB(255, 180, 0)
            hl.Parent = game.CoreGui
            table.insert(espObjects, hl)
        end
    end
    Notify("ESP", "Highlight "..#espObjects.." objek", "success")
end

-- ═══════════════════════════════════════════════════
-- TELEPORT
-- ═══════════════════════════════════════════════════
local function TeleportTop()
    local hrp = getHRP()
    if not hrp then return end
    local best, bestY = nil, hrp.Position.Y
    for _, obj in ipairs(workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if obj:IsA("BasePart") and (n:find("finish") or n:find("winner") or n:find("end") or n:find("top") or n:find("goal")) then
            if obj.Position.Y > bestY then bestY = obj.Position.Y; best = obj end
        end
    end
    if best then
        hrp.CFrame = CFrame.new(best.Position + Vector3.new(0, 6, 0))
        Notify("Teleport", "Sampai di "..best.Name, "success")
    else
        hrp.CFrame = hrp.CFrame + Vector3.new(0, 800, 0)
        Notify("Teleport", "Naik +800 unit!", "success")
    end
end

local function TeleportSpawn()
    local hrp = getHRP()
    if not hrp then return end
    local spawn = workspace:FindFirstChild("SpawnLocation") or workspace:FindFirstChildWhichIsA("SpawnLocation", true)
    hrp.CFrame = spawn and (spawn.CFrame + Vector3.new(0, 5, 0)) or CFrame.new(0, 10, 0)
    Notify("Teleport", "Kembali ke spawn", "info")
end

local function TeleportToPlayer()
    local hrp = getHRP()
    if not hrp then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
            if tHRP then
                hrp.CFrame = tHRP.CFrame + Vector3.new(3, 2, 0)
                Notify("Teleport", "Ke player: "..p.Name, "success")
                return
            end
        end
    end
    Notify("Teleport", "Tidak ada player lain", "error")
end

-- ═══════════════════════════════════════════════════
-- CHARACTER RESPAWN HANDLER
-- ═══════════════════════════════════════════════════
lp.CharacterAdded:Connect(function(c)
    task.wait(0.5)
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h then return end
    if S.SpeedHack then h.WalkSpeed = S.WalkSpeed end
    if S.JumpPower ~= 50 then h.JumpPower = S.JumpPower end
    if S.GodMode   then ToggleGodMode(true) end
end)

-- ═══════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════
--   U I   B U I L D E R   —   V O I D   H U B
-- ═══════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════

-- Remove old instance
local cg = game:GetService("CoreGui")
if cg:FindFirstChild("VoidHub") then cg:FindFirstChild("VoidHub"):Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VoidHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 100
ScreenGui.Parent = cg

-- ── COLORS ──────────────────────────────────────────
local C = {
    bg          = Color3.fromRGB(6, 8, 16),
    bgPanel     = Color3.fromRGB(10, 13, 24),
    bgRow       = Color3.fromRGB(14, 18, 32),
    bgRowHover  = Color3.fromRGB(18, 24, 42),
    accent      = Color3.fromRGB(0, 130, 255),
    accentBright= Color3.fromRGB(30, 160, 255),
    accentDark  = Color3.fromRGB(0, 80, 180),
    accentGlow  = Color3.fromRGB(0, 100, 220),
    tabActive   = Color3.fromRGB(0, 130, 255),
    tabInactive = Color3.fromRGB(14, 18, 32),
    border      = Color3.fromRGB(0, 70, 140),
    borderFaint = Color3.fromRGB(20, 28, 50),
    text        = Color3.fromRGB(210, 225, 255),
    textMuted   = Color3.fromRGB(80, 110, 160),
    textDim     = Color3.fromRGB(40, 60, 100),
    success     = Color3.fromRGB(0, 210, 120),
    warn        = Color3.fromRGB(255, 170, 0),
    danger      = Color3.fromRGB(255, 60, 60),
}

-- ── HELPERS ─────────────────────────────────────────
local function Corner(r, p) local c=Instance.new("UICorner",p);c.CornerRadius=UDim.new(0,r);return c end
local function Stroke(col, th, tr, p) local s=Instance.new("UIStroke",p);s.Color=col;s.Thickness=th;s.Transparency=tr or 0;return s end
local function Grad(col1, col2, rot, p)
    local g=Instance.new("UIGradient",p)
    g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,col1),ColorSequenceKeypoint.new(1,col2)})
    g.Rotation=rot or 90
    return g
end

local function MakeFrame(props)
    local f = Instance.new("Frame")
    for k,v in pairs(props) do pcall(function() f[k]=v end) end
    return f
end
local function MakeLabel(props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamSemibold
    for k,v in pairs(props) do pcall(function() l[k]=v end) end
    return l
end
local function MakeBtn(props)
    local b = Instance.new("TextButton")
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    for k,v in pairs(props) do pcall(function() b[k]=v end) end
    return b
end

-- ── MAIN WINDOW ─────────────────────────────────────
local Main = MakeFrame({
    Name = "Main",
    Size = UDim2.new(0, 360, 0, 480),
    Position = UDim2.new(0.5,-180, 0.5,-240),
    BackgroundColor3 = C.bg,
    Active = true,
    Draggable = true,
    Parent = ScreenGui,
})
Corner(14, Main)
Stroke(C.border, 1.5, 0.2, Main)
Grad(Color3.fromRGB(6,9,20), Color3.fromRGB(4,7,14), 160, Main)

-- Scanline overlay effect
local scanLine = MakeFrame({
    Size = UDim2.new(1,0,1,0),
    BackgroundTransparency = 1,
    ZIndex = 2,
    Parent = Main,
})

-- ── TITLE BAR ────────────────────────────────────────
local TBar = MakeFrame({
    Size = UDim2.new(1,0,0,52),
    BackgroundColor3 = C.bgPanel,
    Parent = Main,
    ZIndex = 3,
})
Corner(14, TBar)
Grad(Color3.fromRGB(0,80,200), Color3.fromRGB(0,40,120), 135, TBar)
-- fix bottom corners of titlebar
MakeFrame({ Size=UDim2.new(1,0,0.5,0), Position=UDim2.new(0,0,0.5,0), BackgroundColor3=Color3.fromRGB(0,55,150), BorderSizePixel=0, Parent=TBar, ZIndex=2 })
Stroke(C.border, 1, 0.3, TBar)

-- Logo / Icon area
local logoFrame = MakeFrame({
    Size = UDim2.new(0,36,0,36),
    Position = UDim2.new(0,10,0.5,-18),
    BackgroundColor3 = Color3.fromRGB(0,100,220),
    ZIndex = 4,
    Parent = TBar,
})
Corner(8, logoFrame)
Grad(Color3.fromRGB(0,140,255), Color3.fromRGB(0,60,180), 135, logoFrame)
MakeLabel({ Size=UDim2.new(1,0,1,0), Text="V", TextSize=20, Font=Enum.Font.GothamBold, TextColor3=Color3.fromRGB(255,255,255), ZIndex=5, Parent=logoFrame })

local titleL = MakeLabel({
    Size = UDim2.new(0,150,0,22),
    Position = UDim2.new(0,54,0,6),
    Text = "VOID HUB",
    TextSize = 17,
    Font = Enum.Font.GothamBold,
    TextColor3 = Color3.fromRGB(255,255,255),
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
    Parent = TBar,
})

local subtitleL = MakeLabel({
    Size = UDim2.new(0,200,0,14),
    Position = UDim2.new(0,54,0,28),
    Text = "Climb & Jump Tower  •  v2.0",
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextColor3 = Color3.fromRGB(100,160,255),
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
    Parent = TBar,
})

-- Close / Min buttons
local function TBarBtn(xOffset, col, lbl)
    local b = MakeBtn({
        Size = UDim2.new(0,26,0,26),
        Position = UDim2.new(1, xOffset, 0.5, -13),
        BackgroundColor3 = col,
        Text = lbl,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(255,255,255),
        ZIndex = 5,
        Parent = TBar,
    })
    Corner(6, b)
    return b
end

local CloseBtn = TBarBtn(-36, C.danger, "✕")
local MinBtn   = TBarBtn(-66, C.warn,   "−")

CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0,360,0,0),
        Position = Main.Position + UDim2.new(0,0,0,240),
    }):Play()
    task.delay(0.35, function() ScreenGui:Destroy() end)
end)

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Size = minimized and UDim2.new(0,360,0,52) or UDim2.new(0,360,0,480)
    }):Play()
end)

-- ── TAB BAR ──────────────────────────────────────────
local TabBar = MakeFrame({
    Size = UDim2.new(1,-20,0,32),
    Position = UDim2.new(0,10,0,58),
    BackgroundColor3 = C.bgPanel,
    ZIndex = 3,
    Parent = Main,
})
Corner(8, TabBar)
Stroke(C.borderFaint, 1, 0, TabBar)

local TabLayout = Instance.new("UIListLayout", TabBar)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0, 2)

local tabPad = Instance.new("UIPadding", TabBar)
tabPad.PaddingLeft = UDim.new(0,3)
tabPad.PaddingRight = UDim.new(0,3)
tabPad.PaddingTop = UDim.new(0,3)
tabPad.PaddingBottom = UDim.new(0,3)

local tabs = {}
local tabContents = {}

local function MakeTab(name, icon, order)
    local btn = MakeBtn({
        Size = UDim2.new(0.33,-2,1,0),
        BackgroundColor3 = C.tabInactive,
        Text = icon.." "..name,
        TextSize = 11,
        TextColor3 = C.textMuted,
        LayoutOrder = order,
        ZIndex = 4,
        Parent = TabBar,
    })
    Corner(6, btn)

    local content = MakeFrame({
        Size = UDim2.new(1,-20,1,-104),
        Position = UDim2.new(0,10,0,98),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 3,
        Parent = Main,
    })

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1,0,1,0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = C.accent
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = content

    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    local pad = Instance.new("UIPadding", scroll)
    pad.PaddingBottom = UDim.new(0,6)

    tabs[name] = { btn = btn, content = content, scroll = scroll }

    btn.MouseButton1Click:Connect(function()
        for n, t in pairs(tabs) do
            local active = (n == name)
            t.content.Visible = active
            TweenService:Create(t.btn, TweenInfo.new(0.15), {
                BackgroundColor3 = active and C.tabActive or C.tabInactive,
                TextColor3       = active and Color3.fromRGB(255,255,255) or C.textMuted,
            }):Play()
        end
        S.ActiveTab = name
    end)

    return scroll
end

local scrollMove  = MakeTab("MOVE",  "⚡", 1)
local scrollFarm  = MakeTab("FARM",  "⚙", 2)
local scrollUtil  = MakeTab("UTIL",  "◈", 3)

-- Activate first tab
tabs["MOVE"].content.Visible = true
tabs["MOVE"].btn.BackgroundColor3 = C.tabActive
tabs["MOVE"].btn.TextColor3 = Color3.fromRGB(255,255,255)

-- ── STATUS BAR ───────────────────────────────────────
local StatusBar = MakeFrame({
    Size = UDim2.new(1,-20,0,24),
    Position = UDim2.new(0,10,1,-30),
    BackgroundColor3 = C.bgPanel,
    ZIndex = 3,
    Parent = Main,
})
Corner(6, StatusBar)
Stroke(C.borderFaint, 1, 0.2, StatusBar)

local statusDot = MakeFrame({
    Size = UDim2.new(0,7,0,7),
    Position = UDim2.new(0,10,0.5,-3.5),
    BackgroundColor3 = C.success,
    ZIndex = 4,
    Parent = StatusBar,
})
Corner(4, statusDot)

local statusLbl = MakeLabel({
    Size = UDim2.new(0.5,0,1,0),
    Position = UDim2.new(0,22,0,0),
    Text = "VOID HUB AKTIF",
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    TextColor3 = C.success,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
    Parent = StatusBar,
})

local featureCountLbl = MakeLabel({
    Size = UDim2.new(0.5,0,1,0),
    Position = UDim2.new(0.5,0,0,0),
    Text = "0 fitur aktif",
    TextSize = 10,
    TextColor3 = C.textDim,
    TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 4,
    Parent = StatusBar,
})

-- Track active feature count
local activeFeatures = 0
local function updateFeatureCount(delta)
    activeFeatures = math.max(0, activeFeatures + delta)
    featureCountLbl.Text = activeFeatures.." fitur aktif"
end

-- ── ROW BUILDERS ────────────────────────────────────

-- Section label
local function SLabel(text, parent, order)
    local f = MakeFrame({ Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, LayoutOrder=order, Parent=parent })
    MakeLabel({ Size=UDim2.new(1,-4,1,0), Position=UDim2.new(0,4,0,0), Text="▸ "..text:upper(), TextSize=10, Font=Enum.Font.GothamBold, TextColor3=C.accent, TextXAlignment=Enum.TextXAlignment.Left, Parent=f })
    -- divider line
    local line = MakeFrame({ Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1), BackgroundColor3=C.border, Parent=f })
    line.BackgroundTransparency = 0.6
    return f
end

-- Toggle row
local function ToggleRow(icon, label, desc, parent, order, callback)
    local isOn = false
    local row = MakeFrame({
        Size = UDim2.new(1,0,0,48),
        BackgroundColor3 = C.bgRow,
        LayoutOrder = order,
        Parent = parent,
    })
    Corner(8, row)
    local stroke = Stroke(C.borderFaint, 1, 0, row)

    -- left accent bar
    local accentBar = MakeFrame({ Size=UDim2.new(0,3,0,28), Position=UDim2.new(0,0,0.5,-14), BackgroundColor3=C.accent, Parent=row })
    Corner(3, accentBar)
    accentBar.BackgroundTransparency = 1

    -- icon
    local iconL = MakeLabel({ Size=UDim2.new(0,32,1,0), Position=UDim2.new(0,10,0,0), Text=icon, TextSize=18, Font=Enum.Font.GothamBold, TextColor3=C.textDim, Parent=row })

    -- labels
    local mainL = MakeLabel({ Size=UDim2.new(1,-110,0,22), Position=UDim2.new(0,44,0,5), Text=label, TextSize=13, Font=Enum.Font.GothamBold, TextColor3=C.textMuted, TextXAlignment=Enum.TextXAlignment.Left, Parent=row })
    local descL = MakeLabel({ Size=UDim2.new(1,-110,0,14), Position=UDim2.new(0,44,0,27), Text=desc, TextSize=10, TextColor3=C.textDim, TextXAlignment=Enum.TextXAlignment.Left, Parent=row })

    -- pill
    local pillBg = MakeFrame({ Size=UDim2.new(0,44,0,22), Position=UDim2.new(1,-56,0.5,-11), BackgroundColor3=Color3.fromRGB(20,25,45), Parent=row })
    Corner(11, pillBg)
    Stroke(C.borderFaint, 1, 0, pillBg)
    local knob = MakeFrame({ Size=UDim2.new(0,16,0,16), Position=UDim2.new(0,3,0.5,-8), BackgroundColor3=C.textDim, Parent=pillBg })
    Corner(8, knob)

    local hitbox = MakeBtn({ Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=5, Parent=row })

    local function setVisual(on)
        TweenService:Create(pillBg, TweenInfo.new(0.2), { BackgroundColor3 = on and C.accentGlow or Color3.fromRGB(20,25,45) }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), { Position = on and UDim2.new(0,25,0.5,-8) or UDim2.new(0,3,0.5,-8), BackgroundColor3 = on and Color3.fromRGB(255,255,255) or C.textDim }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2), { Color = on and C.accent or C.borderFaint }):Play()
        TweenService:Create(accentBar, TweenInfo.new(0.2), { BackgroundTransparency = on and 0 or 1 }):Play()
        TweenService:Create(mainL, TweenInfo.new(0.2), { TextColor3 = on and Color3.fromRGB(220,235,255) or C.textMuted }):Play()
        TweenService:Create(iconL, TweenInfo.new(0.2), { TextColor3 = on and C.accentBright or C.textDim }):Play()
        TweenService:Create(row, TweenInfo.new(0.2), { BackgroundColor3 = on and C.bgRowHover or C.bgRow }):Play()
    end

    hitbox.MouseButton1Click:Connect(function()
        isOn = not isOn
        setVisual(isOn)
        updateFeatureCount(isOn and 1 or -1)
        callback(isOn)
    end)

    return row
end

-- Action button
local function ActionRow(icon, label, desc, parent, order, callback)
    local row = MakeFrame({ Size=UDim2.new(1,0,0,44), BackgroundColor3=C.bgRow, LayoutOrder=order, Parent=parent })
    Corner(8, row)
    local stroke = Stroke(C.borderFaint, 1, 0.3, row)

    MakeLabel({ Size=UDim2.new(0,32,1,0), Position=UDim2.new(0,10,0,0), Text=icon, TextSize=16, Font=Enum.Font.GothamBold, TextColor3=C.accent, Parent=row })
    MakeLabel({ Size=UDim2.new(1,-100,0,20), Position=UDim2.new(0,44,0,5), Text=label, TextSize=13, Font=Enum.Font.GothamBold, TextColor3=C.text, TextXAlignment=Enum.TextXAlignment.Left, Parent=row })
    MakeLabel({ Size=UDim2.new(1,-100,0,14), Position=UDim2.new(0,44,0,25), Text=desc, TextSize=10, TextColor3=C.textDim, TextXAlignment=Enum.TextXAlignment.Left, Parent=row })

    local execBtn = MakeBtn({ Size=UDim2.new(0,60,0,28), Position=UDim2.new(1,-68,0.5,-14), BackgroundColor3=C.accentDark, Text="RUN", TextSize=11, TextColor3=Color3.fromRGB(255,255,255), ZIndex=5, Parent=row })
    Corner(6, execBtn)
    Grad(C.accent, C.accentDark, 90, execBtn)

    execBtn.MouseButton1Click:Connect(function()
        TweenService:Create(execBtn, TweenInfo.new(0.1), { BackgroundTransparency=0.5 }):Play()
        task.delay(0.15, function() TweenService:Create(execBtn, TweenInfo.new(0.1), { BackgroundTransparency=0 }):Play() end)
        callback()
    end)

    row.MouseEnter:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.15), { Color=C.accent, Transparency=0.5 }):Play()
    end)
    row.MouseLeave:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.15), { Color=C.borderFaint, Transparency=0 }):Play()
    end)
    return row
end

-- Slider row
local function SliderRow(icon, label, parent, order, minV, maxV, defV, cb)
    local row = MakeFrame({ Size=UDim2.new(1,0,0,58), BackgroundColor3=C.bgRow, LayoutOrder=order, Parent=parent })
    Corner(8, row)
    Stroke(C.borderFaint, 1, 0, row)

    MakeLabel({ Size=UDim2.new(0,28,0,28), Position=UDim2.new(0,8,0,8), Text=icon, TextSize=16, TextColor3=C.accent, Parent=row })
    MakeLabel({ Size=UDim2.new(0.55,0,0,20), Position=UDim2.new(0,38,0,6), Text=label, TextSize=12, Font=Enum.Font.GothamBold, TextColor3=C.text, TextXAlignment=Enum.TextXAlignment.Left, Parent=row })

    local valL = MakeLabel({ Size=UDim2.new(0.4,0,0,20), Position=UDim2.new(0.6,-8,0,6), Text=tostring(defV), TextSize=13, Font=Enum.Font.GothamBold, TextColor3=C.accentBright, TextXAlignment=Enum.TextXAlignment.Right, Parent=row })

    -- track
    local track = MakeFrame({ Size=UDim2.new(1,-28,0,6), Position=UDim2.new(0,14,0,40), BackgroundColor3=Color3.fromRGB(20,28,50), Parent=row })
    Corner(3, track)
    Stroke(C.borderFaint, 1, 0.4, track)

    local pct = (defV - minV) / (maxV - minV)
    local fill = MakeFrame({ Size=UDim2.new(pct,0,1,0), BackgroundColor3=C.accent, Parent=track })
    Corner(3, fill)
    Grad(C.accentBright, C.accent, 90, fill)

    local knob = MakeFrame({ Size=UDim2.new(0,14,0,14), Position=UDim2.new(pct,-7,0.5,-7), BackgroundColor3=Color3.fromRGB(255,255,255), ZIndex=4, Parent=track })
    Corner(7, knob)
    local ks = Stroke(C.accent, 1.5, 0, knob)

    local dragging = false
    knob.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local ap = track.AbsolutePosition.X
            local as = track.AbsoluteSize.X
            local r  = math.clamp((i.Position.X - ap) / as, 0, 1)
            local v  = math.round(minV + r*(maxV-minV))
            fill.Size = UDim2.new(r,0,1,0)
            knob.Position = UDim2.new(r,-7,0.5,-7)
            valL.Text = tostring(v)
            cb(v)
        end
    end)

    return row
end

-- ── POPULATE TABS ───────────────────────────────────

-- MOVEMENT TAB
SLabel("Pergerakan",  scrollMove, 1)
ToggleRow("🚀","Infinite Jump",    "Lompat tanpa batas",           scrollMove, 2,  function(on) ToggleInfJump(on) end)
ToggleRow("⚡","Speed Hack",       "Tambah kecepatan lari",        scrollMove, 3,  function(on) ToggleSpeed(on) end)
SliderRow("🏃","Walk Speed",        scrollMove, 4,  16, 250, 16,  function(v) S.WalkSpeed=v; ApplySpeed() end)
SliderRow("↑","Jump Power",        scrollMove, 5,  50, 600, 50,  function(v) S.JumpPower=v; ApplyJump() end)
ToggleRow("👻","Noclip",           "Tembus semua platform",        scrollMove, 6,  function(on) ToggleNoclip(on) end)
ToggleRow("💀","God Mode",         "HP tak terbatas, anti-ragdoll",scrollMove, 7,  function(on) ToggleGodMode(on) end)

SLabel("Teleport", scrollMove, 8)
ActionRow("⬆","Teleport ke Atas",  "Langsung ke finish/top",       scrollMove, 9,  TeleportTop)
ActionRow("⬇","Teleport ke Spawn", "Balik ke titik awal",          scrollMove, 10, TeleportSpawn)
ActionRow("👤","Teleport ke Player","Teleport ke player terdekat",  scrollMove, 11, TeleportToPlayer)

-- FARM TAB
SLabel("Auto Farm",   scrollFarm, 1)
ToggleRow("🏆","Auto Farm Stage",  "Otomatis naik stage demi stage", scrollFarm, 2, function(on) ToggleAutoFarm(on) end)
ToggleRow("🪙","Auto Collect Coin","Kumpulkan semua koin otomatis",  scrollFarm, 3, function(on) ToggleAutoCoin(on) end)

SLabel("Tips Farm", scrollFarm, 4)
local tipFrame = MakeFrame({ Size=UDim2.new(1,0,0,80), BackgroundColor3=Color3.fromRGB(0,30,70), LayoutOrder=5, Parent=scrollFarm })
Corner(8, tipFrame)
Stroke(C.accent, 1, 0.6, tipFrame)
MakeLabel({ Size=UDim2.new(1,-16,1,0), Position=UDim2.new(0,8,0,0), Text="💡 Auto Farm akan scan semua checkpoint di workspace, lalu teleport karakter dari bawah ke atas secara bertahap.\n\nGunakan bersama God Mode agar tidak mati saat farming!", TextSize=11, TextColor3=Color3.fromRGB(100,160,255), TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, Font=Enum.Font.Gotham, Parent=tipFrame })

-- UTILITY TAB
SLabel("Utility", scrollUtil, 1)
ToggleRow("🕶","ESP / Highlight",   "Lihat player & koin lewat tembok", scrollUtil, 2, function(on) ToggleESP(on) end)
ToggleRow("🛡","Anti-AFK",          "Cegah kick karena idle",           scrollUtil, 3, function(on) ToggleAntiAFK(on) end)

SLabel("Info", scrollUtil, 4)
local infoFrame = MakeFrame({ Size=UDim2.new(1,0,0,95), BackgroundColor3=C.bgRow, LayoutOrder=5, Parent=scrollUtil })
Corner(8, infoFrame)
Stroke(C.borderFaint, 1, 0.3, infoFrame)
local infoText = MakeLabel({ Size=UDim2.new(1,-16,1,0), Position=UDim2.new(0,8,0,0), Text="", TextSize=11, TextColor3=C.textMuted, TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, Font=Enum.Font.GothamMono or Enum.Font.Gotham, Parent=infoFrame })

-- Live info updater
RunService.Heartbeat:Connect(function()
    local hrp = getHRP()
    local h   = getHum()
    if hrp and h then
        infoText.Text = string.format(
            "Player : %s\nPos     : %.1f, %.1f, %.1f\nHealth  : %.0f / %.0f\nSpeed   : %.0f  |  Jump: %.0f\nPlayers : %d di server",
            lp.Name,
            hrp.Position.X, hrp.Position.Y, hrp.Position.Z,
            h.Health, h.MaxHealth,
            h.WalkSpeed, h.JumpPower,
            #Players:GetPlayers()
        )
    end
end)

SLabel("Koneksi", scrollUtil, 6)
ActionRow("🔄","Reset Karakter",   "Respawn karakter sekarang",     scrollUtil, 7, function()
    lp:LoadCharacter()
    Notify("Reset", "Karakter di-respawn", "info")
end)
ActionRow("📋","Copy Username",    "Copy nama player ke clipboard", scrollUtil, 8, function()
    setclipboard(lp.Name)
    Notify("Clipboard", "Username disalin: "..lp.Name, "success")
end)

-- ── STATUS DOT BLINK ────────────────────────────────
task.spawn(function()
    while ScreenGui.Parent do
        TweenService:Create(statusDot, TweenInfo.new(1), { BackgroundTransparency=0.5 }):Play()
        task.wait(1)
        TweenService:Create(statusDot, TweenInfo.new(1), { BackgroundTransparency=0 }):Play()
        task.wait(1)
    end
end)

-- ── ENTRANCE ANIMATION ──────────────────────────────
Main.Position = UDim2.new(0.5,-180, 1.5,0)
Main.BackgroundTransparency = 1
TweenService:Create(Main, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Position = UDim2.new(0.5,-180, 0.5,-240),
    BackgroundTransparency = 0,
}):Play()

task.delay(0.2, function()
    Notify("VOID HUB", "Script berhasil diload! Selamat ngegame 🚀", "success")
end)

-- ═══════════════════════════════════════════════════
-- DONE — VOID HUB v2.0
-- ═══════════════════════════════════════════════════
