--[[
    VeySell Hub | Bom Voli
    Key: VEYSELLKEY-<kode>   Get Key: https://getkey-veysell-hub.netlify.app
    Discord: https://discord.gg/vrTQZJVcPA
    UI: Key System custom + WindUI (Midnight)
]]
local Players  = game:GetService("Players")
local RS       = game:GetService("RunService")
local UIS      = game:GetService("UserInputService")
local TS       = game:GetService("TweenService")
local VIM      = game:GetService("VirtualInputManager")
local CoreGui  = game:GetService("CoreGui")
local Market   = game:GetService("MarketplaceService")
local LP       = Players.LocalPlayer
local Cam      = workspace.CurrentCamera

local ICON     = "rbxassetid://13026626364"
local DISCORD  = "https://discord.gg/vrTQZJVcPA"
local GETKEY   = "https://getkey-veysell-hub.netlify.app"
local KEYFILE  = "VeySellHub_BomVoli_Key.txt"
local GAMEICON = "rbxthumb://type=GameIcon&id=" .. game.GameId .. "&w=150&h=150"

local genv = (getgenv and getgenv()) or _G
if genv.VeySellVoliStop then pcall(genv.VeySellVoliStop) end

-- warna (disamakan dengan gambar: dark navy + biru)
local C = {
    bg = Color3.fromRGB(25, 26, 33), card = Color3.fromRGB(35, 36, 45), pill = Color3.fromRGB(43, 44, 54),
    blue = Color3.fromRGB(51, 88, 255), text = Color3.fromRGB(245, 246, 250), sub = Color3.fromRGB(176, 179, 192),
    green = Color3.fromRGB(70, 200, 110), orange = Color3.fromRGB(255, 170, 60),
}

-- ================= helpers =================
local function tw(o, t, p, st, dr)
    local x = TS:Create(o, TweenInfo.new(t, st or Enum.EasingStyle.Quint, dr or Enum.EasingDirection.Out), p)
    x:Play() return x
end
local function new(cl, props, par)
    local o = Instance.new(cl)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = par
    return o
end
local function corner(o, r) return new("UICorner", { CornerRadius = UDim.new(0, r) }, o) end
local function label(par, t, pos, size, sz, col, font, al)
    return new("TextLabel", { BackgroundTransparency = 1, Text = t, Position = pos, Size = size, TextSize = sz,
        TextColor3 = col or C.text, Font = font or Enum.Font.GothamMedium, TextXAlignment = al or Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd }, par)
end
local function notify(msg) print("[VeySell] " .. msg) end
local function mount()
    local ok, p = pcall(function() return (gethui and gethui()) or CoreGui end)
    return ok and p or LP:WaitForChild("PlayerGui")
end
local function copy(t) pcall(function() if setclipboard then setclipboard(t) end end) end
local function validKey(k)
    return type(k) == "string" and k:match("^VEYSELLKEY%-[%w%-_]+$") ~= nil and #k >= 17
end
local function makeDraggable(handle, target, onTap)
    local drag, ds, dp, moved
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag, ds, dp, moved = true, i.Position, target.Position, 0
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            moved = math.max(moved, d.Magnitude)
            target.Position = UDim2.new(dp.X.Scale, dp.X.Offset + d.X, dp.Y.Scale, dp.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
            drag = false
            if onTap and moved < 8 then onTap() end
        end
    end)
end

-- ================= info game =================
local gameName = game.Name
pcall(function() gameName = Market:GetProductInfo(game.PlaceId).Name end)
local gl = gameName:lower()
local supported = gl:find("voli") ~= nil or gl:find("volley") ~= nil or gl:find("bom") ~= nil or gl:find("bomb") ~= nil

-- ================= GUI root + floating icon =================
local gui = new("ScreenGui", { Name = "VeySellVoliGui", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999 })
pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) elseif protectgui then protectgui(gui) end end)
gui.Parent = mount()

local stage = "key"          -- "key" | "main"
local Window                 -- WindUI window
local keyRoot, keyVisible = nil, true

local float = new("ImageButton", { Name = "ToggleButton", Size = UDim2.fromOffset(55, 55), Position = UDim2.new(0, 15, .4, 0),
    BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = .5, Image = ICON, ScaleType = Enum.ScaleType.Fit,
    AutoButtonColor = false, ZIndex = 50 }, gui)
corner(float, 12)
new("UIStroke", { Color = C.blue, Thickness = 2.5 }, float)
local fsc = new("UIScale", { Scale = 1 }, float)

local function toggleCurrent()
    tw(fsc, .12, { Scale = .85 }).Completed:Connect(function() tw(fsc, .3, { Scale = 1 }, Enum.EasingStyle.Back) end)
    if stage == "key" and keyRoot then
        keyVisible = not keyVisible
        if keyVisible then
            keyRoot.Visible = true
            tw(keyRoot.UIScale, .45, { Scale = keyRoot:GetAttribute("fit") }, Enum.EasingStyle.Back)
        else
            tw(keyRoot.UIScale, .3, { Scale = 0 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In).Completed:Connect(function()
                if not keyVisible then keyRoot.Visible = false end
            end)
        end
    elseif Window and Window.Toggle then
        pcall(function() Window:Toggle() end)
    end
end
makeDraggable(float, float, toggleCurrent)

-- ================= logika Bom Voli =================
local S = { volley = false, smash = false, steal = false, method = "Tween", speed = 60, radius = 45, reach = 9, home = nil, dead = false }
local currentTween
local function root() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = LP.Character return c and c:FindFirstChildOfClass("Humanoid") end
local function click()
    pcall(function()
        local v = Cam.ViewportSize
        VIM:SendMouseButtonEvent(v.X / 2, v.Y / 2, 0, true, game, 0)
        VIM:SendMouseButtonEvent(v.X / 2, v.Y / 2, 0, false, game, 0)
    end)
end

local ballCache, lastB = nil, 0
local function findBall()
    if ballCache and ballCache.Parent and os.clock() - lastB < 1.5 then return ballCache end
    lastB = os.clock()
    local r, best, bd = root(), nil, math.huge
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("BasePart") and not o.Anchored then
            local n = o.Name:lower()
            if n:find("ball") or n:find("bomb") or n:find("voli") then
                local m = o:FindFirstAncestorOfClass("Model")
                if not (m and Players:GetPlayerFromCharacter(m)) then
                    local d = r and (o.Position - r.Position).Magnitude or 0
                    if d < bd then best, bd = o, d end
                end
            end
        end
    end
    ballCache = best
    return best
end
local function landing(ball, hy)
    local p, v, g = ball.Position, ball.AssemblyLinearVelocity, workspace.Gravity
    local disc = v.Y * v.Y + 2 * g * (p.Y - hy)
    if disc < 0 then return Vector3.new(p.X, hy, p.Z), 0 end
    local t = math.clamp((v.Y + math.sqrt(disc)) / g, 0, 6)
    return Vector3.new(p.X + v.X * t, hy, p.Z + v.Z * t), t
end
local function goTo(pos)
    local r, h = root(), hum()
    if not r or not h then return end
    if S.method == "TP" then
        r.CFrame = CFrame.new(pos) * (r.CFrame - r.Position)
        r.AssemblyLinearVelocity = Vector3.zero
    elseif S.method == "Walk" then
        h:MoveTo(pos)
    else
        if currentTween then currentTween:Cancel() end
        local d = (pos - r.Position).Magnitude
        currentTween = TS:Create(r, TweenInfo.new(math.max(d / S.speed, 0.03), Enum.EasingStyle.Linear),
            { CFrame = CFrame.new(pos) * (r.CFrame - r.Position) })
        currentTween:Play()
    end
end
local lastHit = 0
local function hit(ball)
    if os.clock() - lastHit < 0.15 then return end
    lastHit = os.clock()
    local r = root()
    if firetouchinterest and r then
        pcall(function() firetouchinterest(r, ball, 0) firetouchinterest(r, ball, 1) end)
    end
    local tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
    if tool then pcall(function() tool:Activate() end) end
    click()
end

task.spawn(function() -- Auto Volley + Auto Smash
    while not S.dead do
        if (S.volley or S.smash) and root() and hum() and hum().Health > 0 then
            local ball = findBall()
            local r = root()
            if ball and ball.Parent then
                S.home = S.home or r.Position
                local lp = landing(ball, r.Position.Y)
                local inCourt = (Vector3.new(lp.X, 0, lp.Z) - Vector3.new(S.home.X, 0, S.home.Z)).Magnitude <= S.radius
                local dist = (ball.Position - r.Position).Magnitude
                if S.volley and inCourt then
                    goTo(Vector3.new(lp.X, r.Position.Y, lp.Z))
                    if dist <= S.reach then hit(ball) end
                elseif S.volley and (Vector3.new(r.Position.X, 0, r.Position.Z) - Vector3.new(S.home.X, 0, S.home.Z)).Magnitude > 6 then
                    goTo(S.home) -- balik ke area voli
                end
                if S.smash then
                    local dy = ball.Position.Y - r.Position.Y
                    local dxz = (Vector3.new(ball.Position.X, 0, ball.Position.Z) - Vector3.new(r.Position.X, 0, r.Position.Z)).Magnitude
                    if dxz <= 14 and dy > 2 and dy < 14 then
                        local h = hum()
                        if h and h.FloorMaterial ~= Enum.Material.Air then h:ChangeState(Enum.HumanoidStateType.Jumping) end
                        task.wait(0.1)
                        hit(ball)
                    end
                end
            end
        end
        task.wait(0.08)
    end
end)
task.spawn(function() -- Auto FreeSteal
    while not S.dead do
        if S.steal and root() then
            local r = root()
            for _, p in ipairs(workspace:GetDescendants()) do
                if p:IsA("ProximityPrompt") then
                    local s = ((p.ActionText or "") .. " " .. (p.ObjectText or "") .. " " .. (p.Parent and p.Parent.Name or "")):lower()
                    if s:find("steal") or s:find("free") or s:find("ambil") or s:find("grab") then
                        local par = p.Parent
                        local pos = par and par:IsA("BasePart") and par.Position
                        if pos and (pos - r.Position).Magnitude <= math.max(p.MaxActivationDistance, 12) + 8 then
                            pcall(function() p.HoldDuration = 0 end)
                            if fireproximityprompt then pcall(fireproximityprompt, p) end
                        end
                    end
                end
            end
        end
        task.wait(0.35)
    end
end)
local idle = LP.Idled:Connect(function()
    pcall(function()
        local vu = game:GetService("VirtualUser")
        vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame) task.wait(1)
        vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end)

-- ================= WindUI (setelah key valid) =================
local function buildMain()
    stage = "main"
    local ok, WindUI = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    end)
    if not ok or not WindUI then warn("[VeySell] Gagal load WindUI") return end

    local function mk(theme)
        return WindUI:CreateWindow({
            Title = "VeySell Hub", Icon = "Home", Author = "VeySell / GGSIHLUH", Folder = "VeySellBomVoli",
            Size = UDim2.fromOffset(520, 360), Transparent = true, Theme = theme, Resizable = true,
            SideBarWidth = 170, User = { Enabled = true, Anonymous = false },
        })
    end
    local okw, w = pcall(mk, "Midnight")
    if not okw or not w then okw, w = pcall(mk, "Dark") end
    Window = w
    if not Window then return end

    local Tab = Window:Tab({ Title = "Volley", Icon = "volleyball" })
    Tab:Toggle({ Title = "Auto Volley", Desc = "Bola menuju kita → ke area voli & auto hit", Value = false,
        Callback = function(v) S.volley = v if v then local r = root() S.home = r and r.Position end end })
    Tab:Dropdown({ Title = "Metode", Values = { "Tween", "TP", "Walk" }, Value = "Tween",
        Callback = function(v) S.method = v end })
    Tab:Toggle({ Title = "Auto FreeSteal", Desc = "Otomatis steal / ambil bola gratis", Value = false,
        Callback = function(v) S.steal = v end })
    Tab:Toggle({ Title = "Auto Smash Volley", Desc = "Lompat & smash saat bola di atas", Value = false,
        Callback = function(v) S.smash = v if v then local r = root() S.home = S.home or (r and r.Position) end end })

    local Set = Window:Tab({ Title = "Setting", Icon = "settings" })
    Set:Slider({ Title = "Speed Tween (studs/s)", Value = { Min = 20, Max = 300, Default = 60 }, Callback = function(v) S.speed = v end })
    Set:Slider({ Title = "Radius Area Voli", Value = { Min = 15, Max = 120, Default = 45 }, Callback = function(v) S.radius = v end })
    Set:Slider({ Title = "Jarak Hit", Value = { Min = 5, Max = 20, Default = 9 }, Callback = function(v) S.reach = v end })
    Set:Button({ Title = "Set Area Voli di Posisi Ini", Callback = function()
        local r = root() if r then S.home = r.Position end
    end })
    Set:Button({ Title = "Dump Info (F9)", Callback = function()
        local b = findBall()
        print("[VeySell] Bola:", b and b:GetFullName() or "tidak ketemu", "| Area:", S.home)
    end })

    local Info = Window:Tab({ Title = "Info", Icon = "info" })
    Info:Paragraph({ Title = "VeySell Hub", Desc = "Game: " .. gameName .. "\nDev: VeySell / GGSIHLUH" })
    Info:Button({ Title = "Copy Discord", Callback = function() copy(DISCORD) end })
    pcall(function() WindUI:Notify({ Title = "VeySell Hub", Content = "Key valid. Selamat bermain!", Duration = 4 }) end)
end

-- ================= KEY SYSTEM UI =================
local function buildKey()
    keyRoot = new("Frame", { Name = "KeyRoot", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
        Size = UDim2.fromOffset(600, 320), BackgroundColor3 = C.bg, BorderSizePixel = 0 }, gui)
    corner(keyRoot, 22)
    new("UIStroke", { Color = C.pill, Thickness = 1.5 }, keyRoot)
    local fitv = math.clamp(math.min((Cam.ViewportSize.X - 16) / 600, (Cam.ViewportSize.Y - 16) / 320), .4, 1)
    keyRoot:SetAttribute("fit", fitv)
    local ks = new("UIScale", { Scale = 0 }, keyRoot)
    tw(ks, .6, { Scale = fitv }, Enum.EasingStyle.Back)

    -- drag handle + minimize
    local head = new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1 }, keyRoot)
    makeDraggable(head, keyRoot)
    new("Frame", { AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(.5, 0, 0, 8), Size = UDim2.fromOffset(46, 4),
        BackgroundColor3 = C.pill, BorderSizePixel = 0 }, head) corner(head:GetChildren()[1], 2)
    local mini = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 10), Size = UDim2.fromOffset(32, 32),
        BackgroundColor3 = C.pill, Text = "–", TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 22, AutoButtonColor = false }, keyRoot)
    corner(mini, 10)
    mini.MouseEnter:Connect(function() tw(mini, .2, { BackgroundColor3 = C.blue }) end)
    mini.MouseLeave:Connect(function() tw(mini, .2, { BackgroundColor3 = C.pill }) end)
    mini.MouseButton1Click:Connect(toggleCurrent)

    -- panel kiri
    local left = new("Frame", { Position = UDim2.fromOffset(18, 50), Size = UDim2.fromOffset(350, 252), BackgroundColor3 = C.card, BorderSizePixel = 0 }, keyRoot)
    corner(left, 18)
    local gi = new("ImageLabel", { Position = UDim2.fromOffset(16, 16), Size = UDim2.fromOffset(64, 64), BackgroundColor3 = C.pill, Image = GAMEICON }, left)
    corner(gi, 14)
    label(left, "VeySell Hub", UDim2.fromOffset(92, 16), UDim2.new(1, -104, 0, 28), 24, C.text, Enum.Font.GothamBold)
    label(left, "Key System • " .. (supported and "Bom Voli" or gameName), UDim2.fromOffset(92, 46), UDim2.new(1, -104, 0, 20), 15, C.sub)
    label(left, "Format: VEYSELLKEY-xxxxxx", UDim2.fromOffset(92, 66), UDim2.new(1, -104, 0, 16), 12, C.sub)

    local box = new("TextBox", { Position = UDim2.fromOffset(16, 96), Size = UDim2.new(1, -32, 0, 44), BackgroundColor3 = C.pill,
        Text = "", PlaceholderText = "Masukkan key...", PlaceholderColor3 = C.sub, TextColor3 = C.text, Font = Enum.Font.GothamMedium,
        TextSize = 15, ClearTextOnFocus = false }, left)
    corner(box, 12)
    local bst = new("UIStroke", { Color = C.pill, Thickness = 1.5 }, box)
    box.Focused:Connect(function() tw(bst, .25, { Color = C.blue }) end)
    box.FocusLost:Connect(function() tw(bst, .25, { Color = C.pill }) end)

    local status = label(left, "Masukkan key lalu tekan Verify.", UDim2.fromOffset(16, 148), UDim2.new(1, -32, 0, 18), 12, C.sub)

    local function btn(txt, x, w, col)
        local b = new("TextButton", { Position = UDim2.new(0, x, 0, 178), Size = UDim2.new(0, w, 0, 48), BackgroundColor3 = col,
            Text = txt, TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 16, AutoButtonColor = false }, left)
        corner(b, 14)
        local sc = new("UIScale", { Scale = 1 }, b)
        b.MouseEnter:Connect(function() tw(sc, .2, { Scale = 1.03 }) end)
        b.MouseLeave:Connect(function() tw(sc, .2, { Scale = 1 }) end)
        b.MouseButton1Down:Connect(function() tw(sc, .1, { Scale = .94 }) end)
        b.MouseButton1Up:Connect(function() tw(sc, .2, { Scale = 1.03 }, Enum.EasingStyle.Back) end)
        return b
    end
    local getB = btn("Get Key", 16, 130, C.pill)
    local verB = btn("Verify Key", 156, 178, C.blue)

    local function setStatus(t, col) status.Text = t status.TextColor3 = col or C.sub end
    getB.MouseButton1Click:Connect(function()
        copy(GETKEY)
        pcall(function() game:GetService("GuiService"):OpenBrowserWindow(GETKEY) end)
        setStatus("Link key disalin: " .. GETKEY, C.orange)
    end)
    local function finish(k)
        pcall(function() if writefile then writefile(KEYFILE, k) end end)
        setStatus("Key valid ✓", C.green)
        task.wait(.5)
        tw(ks, .35, { Scale = 0 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In).Completed:Wait()
        keyRoot:Destroy() keyRoot = nil
        buildMain()
    end
    verB.MouseButton1Click:Connect(function()
        local k = box.Text:gsub("%s", "")
        if validKey(k) then finish(k)
        else
            setStatus("Key tidak valid! Harus VEYSELLKEY-kode", Color3.fromRGB(255, 90, 90))
            local p = box.Position
            for _, dx in ipairs({ 8, -8, 5, -5, 0 }) do tw(box, .05, { Position = UDim2.new(p.X.Scale, p.X.Offset + dx, p.Y.Scale, p.Y.Offset) }) task.wait(.05) end
        end
    end)

    -- panel kanan: deteksi game + discord
    local gcard = new("Frame", { Position = UDim2.fromOffset(380, 50), Size = UDim2.fromOffset(202, 110), BackgroundColor3 = C.card, BorderSizePixel = 0 }, keyRoot)
    corner(gcard, 18)
    label(gcard, "GAME TERDETEKSI", UDim2.fromOffset(14, 10), UDim2.new(1, -28, 0, 14), 11, C.sub, Enum.Font.GothamBold)
    local gi2 = new("ImageLabel", { Position = UDim2.fromOffset(14, 32), Size = UDim2.fromOffset(46, 46), BackgroundColor3 = C.pill, Image = GAMEICON }, gcard)
    corner(gi2, 12)
    label(gcard, gameName, UDim2.fromOffset(68, 32), UDim2.new(1, -78, 0, 22), 15, C.text, Enum.Font.GothamBold)
    label(gcard, "ID: " .. game.PlaceId, UDim2.fromOffset(68, 54), UDim2.new(1, -78, 0, 16), 11, C.sub)
    local pill = new("TextLabel", { Position = UDim2.fromOffset(14, 82), Size = UDim2.new(1, -28, 0, 20), BackgroundColor3 = supported and C.green or C.orange,
        BackgroundTransparency = .75, Text = supported and "✓ Didukung" or "⚠ Game belum didukung", TextColor3 = supported and C.green or C.orange,
        Font = Enum.Font.GothamBold, TextSize = 12 }, gcard)
    corner(pill, 10)

    local dcard = new("Frame", { Position = UDim2.fromOffset(380, 168), Size = UDim2.fromOffset(202, 134), BackgroundColor3 = C.blue, BorderSizePixel = 0, ClipsDescendants = true }, keyRoot)
    corner(dcard, 18)
    new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(51, 88, 255), Color3.fromRGB(24, 30, 90)), Rotation = 35 }, dcard)
    new("ImageLabel", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 22, 1, 22), Size = UDim2.fromOffset(120, 120),
        BackgroundTransparency = 1, Image = ICON, ImageTransparency = .75, Rotation = -12 }, dcard)
    local di = new("ImageLabel", { Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(40, 40), BackgroundColor3 = C.bg, Image = ICON }, dcard)
    corner(di, 12)
    label(dcard, "Discord", UDim2.fromOffset(62, 14), UDim2.new(1, -72, 0, 22), 18, C.text, Enum.Font.GothamBold)
    label(dcard, "VeySell Hub Community", UDim2.fromOffset(62, 36), UDim2.new(1, -72, 0, 16), 11, Color3.fromRGB(215, 222, 255))
    label(dcard, DISCORD, UDim2.fromOffset(14, 66), UDim2.new(1, -28, 0, 16), 11, C.text)
    local cp = new("TextButton", { Position = UDim2.fromOffset(14, 90), Size = UDim2.new(1, -28, 0, 30), BackgroundColor3 = C.bg,
        BackgroundTransparency = .25, Text = "Copy Link Discord", TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 13, AutoButtonColor = false }, dcard)
    corner(cp, 10)
    cp.MouseButton1Click:Connect(function() copy(DISCORD) cp.Text = "Tersalin ✓" task.delay(1.5, function() cp.Text = "Copy Link Discord" end) end)

    -- auto-login kalau key tersimpan
    pcall(function()
        if isfile and isfile(KEYFILE) then
            local k = readfile(KEYFILE):gsub("%s", "")
            if validKey(k) then box.Text = k task.defer(finish, k) end
        end
    end)
end

buildKey()

genv.VeySellVoliStop = function()
    S.dead = true
    pcall(function() idle:Disconnect() end)
    pcall(function() gui:Destroy() end)
    pcall(function() if Window and Window.Destroy then Window:Destroy() end end)
end
