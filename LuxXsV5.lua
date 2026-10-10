--[[
    luxxs v5 — by DrHub
    Иконка LX (перетаскивается) / RightShift — открыть и закрыть
    Превью справа: серый 2D манекен с косметикой
    Profile: аватарка и ник
    Visuals: крылья, китайская шляпа, трейл, скелет (палитра по оттенкам + радужный)
    Character: Third Person, Spin (до 1000), FOV камеры
    Weapons: скины для ножа и пистолета (виден только вам)
    Shaders / Settings: пресеты, конфиги, прозрачность меню
    Все значения лежат в таблице Flags, например Flags["Visuals/Крылья"]
]]

local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local PURPLE = Color3.fromRGB(150, 80, 255)
local BG = Color3.fromRGB(18, 16, 26)
local BG2 = Color3.fromRGB(26, 23, 38)
local BG3 = Color3.fromRGB(36, 32, 52)
local WHITE = Color3.fromRGB(255, 255, 255)
local GRAY = Color3.fromRGB(160, 155, 180)
local BODY_GRAY = Color3.fromRGB(150, 150, 156)

-- ===== Палитра =====
local PALETTE = {
    ["Фиолетовый"] = Color3.fromRGB(150, 80, 255),
    ["Красный"] = Color3.fromRGB(255, 60, 60),
    ["Оранжевый"] = Color3.fromRGB(255, 150, 40),
    ["Жёлтый"] = Color3.fromRGB(255, 225, 60),
    ["Зелёный"] = Color3.fromRGB(70, 230, 110),
    ["Голубой"] = Color3.fromRGB(70, 200, 255),
    ["Синий"] = Color3.fromRGB(70, 100, 255),
    ["Розовый"] = Color3.fromRGB(255, 110, 200),
    ["Белый"] = Color3.fromRGB(255, 255, 255),
    ["Золотой"] = Color3.fromRGB(255, 200, 80),
}
local COLOR_NAMES = { "Радужный", "Фиолетовый", "Красный", "Оранжевый", "Жёлтый", "Зелёный", "Голубой", "Синий", "Розовый", "Белый", "Золотой" }
local WING_COLORS = { "Белый", "Золотой", "Радужный", "Фиолетовый", "Голубой", "Розовый", "Красный" }

local function getColor(name, t, off)
    if type(name) == "table" then
        return Color3.fromHSV(name[1], name[2], name[3])
    end
    if name == "Радужный" then
        return Color3.fromHSV((((t or 0) * 0.2) + (off or 0)) % 1, 0.85, 1)
    end
    return PALETTE[name] or PURPLE
end

-- ===== Хелперы =====
local connections = {}
local function track(c)
    connections[#connections + 1] = c
    return c
end

local function tween(obj, time, props, style, dir)
    local t = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function corner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = obj
    return c
end

local function stroke(obj, color, thick, trans)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thick or 1
    s.Transparency = trans or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = obj
    return s
end

-- ===== Реестр значений (для конфигов) =====
local Flags, Setters, Defaults = {}, {}, {}
local function register(key, default, setter)
    Flags[key] = default
    Defaults[key] = default
    Setters[key] = setter
end

-- ===== ScreenGui =====
local gui = Instance.new("ScreenGui")
gui.Name = "luxxs"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true

local okParent, parent = pcall(function()
    return (gethui and gethui()) or game:GetService("CoreGui")
end)
if not okParent or not parent then
    parent = LocalPlayer:WaitForChild("PlayerGui")
end
if parent:FindFirstChild("luxxs") then
    parent.luxxs:Destroy()
end
gui.Parent = parent

-- ===== Уведомления =====
local function notify(text)
    local f = Instance.new("Frame")
    f.AnchorPoint = Vector2.new(1, 1)
    f.Size = UDim2.new(0, 260, 0, 40)
    f.Position = UDim2.new(1, 290, 1, -24)
    f.BackgroundColor3 = BG2
    f.ZIndex = 20
    f.Parent = gui
    corner(f, 10)
    stroke(f, PURPLE, 1.5, 0.3)

    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Size = UDim2.new(1, -20, 1, 0)
    l.Position = UDim2.new(0, 12, 0, 0)
    l.RichText = true
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 13
    l.TextColor3 = WHITE
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = '<b>lu<font color="rgb(150,80,255)">xxs</font></b>   ' .. text
    l.ZIndex = 21
    l.Parent = f

    tween(f, 0.45, { Position = UDim2.new(1, -24, 1, -24) }, Enum.EasingStyle.Back)
    task.delay(2.6, function()
        tween(f, 0.35, { Position = UDim2.new(1, 290, 1, -24) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.delay(0.4, function() f:Destroy() end)
    end)
end

-- ===== Перетаскивание =====
local function makeDraggable(handle, target, onClick)
    local dragging, startPos, startInput, moved = false, nil, nil, false

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            startInput = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if not moved and onClick then
                        onClick()
                    end
                end
            end)
        end
    end)

    track(UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startInput
            if delta.Magnitude > 5 then
                moved = true
            end
            if moved then
                local goal = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
                tween(target, 0.08, { Position = goal }, Enum.EasingStyle.Linear)
            end
        end
    end))
end

-- ============================================================
-- КОСМЕТИКА (реальная, на своём персонаже)
-- ============================================================
local Cos = {}

local setBodyHidden
local hiddenOrig = {}

local function destroyCos(name)
    if Cos[name] then
        for _, o in ipairs(Cos[name].objs) do
            pcall(function() o:Destroy() end)
        end
        Cos[name] = nil
        if name == "skeleton" and setBodyHidden then setBodyHidden(false) end
    end
end

local function isOwnCosmetic(p)
    return p:FindFirstAncestor("luxxsWings") or p:FindFirstAncestor("luxxsHat") or p:FindFirstAncestor("luxxsSkeleton")
end

function setBodyHidden(hidden)
    if hidden then
        local char = LocalPlayer.Character
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if (p:IsA("BasePart") or p:IsA("Decal")) and p.Name ~= "HumanoidRootPart" and not isOwnCosmetic(p) then
                if hiddenOrig[p] == nil then hiddenOrig[p] = p.Transparency end
                p.Transparency = 1
            end
        end
    else
        for p, tr in pairs(hiddenOrig) do
            if p.Parent then p.Transparency = tr end
        end
        hiddenOrig = {}
    end
end

local function newPart(size, parentObj)
    local p = Instance.new("Part")
    p.Size = size
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.Massless = true
    p.Anchored = false
    p.Parent = parentObj
    return p
end

local function buildWings()
    destroyCos("wings")
    local char = LocalPlayer.Character
    local torso = char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"))
    if not torso then return end

    local model = Instance.new("Model")
    model.Name = "luxxsWings"
    local feathers = {}
    for _, side in ipairs({ -1, 1 }) do
        for i = 1, 6 do
            local len = 4.2 - i * 0.35
            local p = newPart(Vector3.new(len, 0.5, 0.08), model)
            p.Material = Enum.Material.Neon
            local w = Instance.new("Weld")
            w.Part0 = torso
            w.Part1 = p
            w.Parent = p
            feathers[#feathers + 1] = { part = p, weld = w, side = side, i = i, len = len }
        end
    end
    model.Parent = char
    Cos.wings = { objs = { model }, model = model, feathers = feathers }
end

local function buildHat()
    destroyCos("hat")
    local char = LocalPlayer.Character
    local head = char and char:FindFirstChild("Head")
    if not head then return end

    local model = Instance.new("Model")
    model.Name = "luxxsHat"
    local slices = {}
    local n = 28
    for i = 1, n do
        local t = (i - 1) / (n - 1)
        local r = 2.1 * (1 - t) ^ 1.15 + 0.05
        local p = newPart(Vector3.new(0.14, r * 2, r * 2), model)
        p.Shape = Enum.PartType.Cylinder
        p.Material = Enum.Material.SmoothPlastic
        local w = Instance.new("Weld")
        w.Part0 = head
        w.Part1 = p
        w.C0 = CFrame.new(0, 0.5 + t * 0.95, 0) * CFrame.Angles(0, 0, math.pi / 2)
        w.Parent = p
        slices[i] = p
    end
    model.Parent = char
    Cos.hat = { objs = { model }, model = model, slices = slices }
end

local function buildTrail()
    destroyCos("trail")
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local a0 = Instance.new("Attachment")
    a0.Name = "luxxsA0"
    a0.Parent = hrp
    local a1 = Instance.new("Attachment")
    a1.Name = "luxxsA1"
    a1.Parent = hrp

    local tr = Instance.new("Trail")
    tr.Name = "luxxsTrail"
    tr.Attachment0 = a0
    tr.Attachment1 = a1
    tr.LightEmission = 1
    tr.FaceCamera = true
    tr.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(1, 1),
    })
    tr.Parent = hrp
    Cos.trail = { objs = { a0, a1, tr }, a0 = a0, a1 = a1, trail = tr }
end

local function buildSkeleton()
    destroyCos("skeleton")
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local model = Instance.new("Model")
    model.Name = "luxxsSkeleton"
    local bones = {}
    -- pos — смещение от HumanoidRootPart, size.X — длина кости, vert — вертикальная
    local defs = {
        { pos = Vector3.new(0, 1.55, 0), size = Vector3.new(0.55, 0.55, 0.55), ball = true },
        { pos = Vector3.new(0, 1.15, 0), size = Vector3.new(0.35, 0.14, 0.14), vert = true },
        { pos = Vector3.new(0, 0.55, 0), size = Vector3.new(1.4, 0.14, 0.14), vert = true },
        { pos = Vector3.new(0, 1.0, 0), size = Vector3.new(1.3, 0.12, 0.12) },
        { pos = Vector3.new(0, 0.05, 0), size = Vector3.new(0.5, 0.12, 0.12) },
        { pos = Vector3.new(-0.65, 0.55, 0), size = Vector3.new(0.9, 0.12, 0.12), vert = true },
        { pos = Vector3.new(-0.65, -0.3, 0), size = Vector3.new(0.8, 0.12, 0.12), vert = true },
        { pos = Vector3.new(0.65, 0.55, 0), size = Vector3.new(0.9, 0.12, 0.12), vert = true },
        { pos = Vector3.new(0.65, -0.3, 0), size = Vector3.new(0.8, 0.12, 0.12), vert = true },
        { pos = Vector3.new(-0.2, -0.65, 0), size = Vector3.new(1.0, 0.16, 0.16), vert = true },
        { pos = Vector3.new(-0.2, -1.55, 0), size = Vector3.new(0.9, 0.14, 0.14), vert = true },
        { pos = Vector3.new(0.2, -0.65, 0), size = Vector3.new(1.0, 0.16, 0.16), vert = true },
        { pos = Vector3.new(0.2, -1.55, 0), size = Vector3.new(0.9, 0.14, 0.14), vert = true },
    }
    for i, d in ipairs(defs) do
        local p = newPart(d.size, model)
        p.Material = Enum.Material.SmoothPlastic
        local rot = CFrame.new()
        if d.ball then
            p.Shape = Enum.PartType.Ball
        else
            p.Shape = Enum.PartType.Cylinder
            if d.vert then rot = CFrame.Angles(0, 0, math.pi / 2) end
        end
        local w = Instance.new("Weld")
        w.Part0 = hrp
        w.Part1 = p
        w.C0 = CFrame.new(d.pos) * rot
        w.Parent = p
        bones[i] = p
    end
    model.Parent = char
    Cos.skeleton = { objs = { model }, model = model, bones = bones }
    setBodyHidden(true)
end

local SKINS = {
    ["Gold"] = { Color3.fromRGB(255, 200, 40), Enum.Material.Metal },
    ["Neon"] = { Color3.fromRGB(255, 200, 60), Enum.Material.Neon },
    ["Ice"] = { Color3.fromRGB(150, 220, 255), Enum.Material.Ice },
    ["Ghost"] = { Color3.fromRGB(230, 230, 255), Enum.Material.ForceField },
    ["Lava"] = { Color3.fromRGB(255, 80, 20), Enum.Material.CrackedLava },
    ["Black"] = { Color3.fromRGB(20, 20, 20), Enum.Material.Plastic },
}
local SKIN_NAMES = { "Выкл", "Gold", "Neon", "Ice", "Ghost", "Lava", "Black" }
local skinOrig = {}

local function resetSkin()
    for p, d in pairs(skinOrig) do
        if p.Parent then
            p.Color = d.c
            p.Material = d.m
        end
    end
    skinOrig = {}
end

local function applySkin(name)
    resetSkin()
    local skin = SKINS[name]
    local char = LocalPlayer.Character
    if not skin or not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" and not isOwnCosmetic(p) then
            skinOrig[p] = { c = p.Color, m = p.Material }
            p.Color = skin[1]
            p.Material = skin[2]
        end
    end
end

local function colorSeq(name, t)
    if name == "Радужный" then
        local kp = {}
        for k = 0, 6 do
            kp[#kp + 1] = ColorSequenceKeypoint.new(k / 6, getColor(name, t, -k / 6 * 0.8))
        end
        return ColorSequence.new(kp)
    end
    return ColorSequence.new(getColor(name))
end

track(RunService.Heartbeat:Connect(function(dt)
    local t = os.clock()

    local w = Cos.wings
    if w and w.model.Parent then
        local flap = math.sin(t * (Flags["Visuals/Скорость крыльев"] or 3)) * 0.2
        local cname = Flags["Visuals/Цвет крыльев"]
        for _, f in ipairs(w.feathers) do
            local a = math.rad(10 + f.i * 12) + flap * (0.5 + f.i * 0.12)
            local theta = (f.side == 1) and a or (math.pi - a)
            f.weld.C0 = CFrame.new(f.side * 0.5, 0.45, 0.6)
                * CFrame.Angles(0, f.side * -0.35, 0)
                * CFrame.Angles(0, 0, theta)
                * CFrame.new(f.len / 2, 0, 0)
            f.part.Color = getColor(cname, t, f.i * 0.05)
        end
    end

    local h = Cos.hat
    if h and h.model.Parent then
        local cname = Flags["Visuals/Цвет шляпы"]
        for i, s in ipairs(h.slices) do
            s.Color = getColor(cname, t, i * 0.02)
        end
    end

    local tr = Cos.trail
    if tr and tr.trail.Parent then
        local width = (Flags["Visuals/Ширина трейла"] or 4) * 0.4
        tr.a0.Position = Vector3.new(0, width / 2, 0)
        tr.a1.Position = Vector3.new(0, -width / 2, 0)
        tr.trail.Lifetime = math.max(0.1, (Flags["Visuals/Длина трейла"] or 10) / 10)
        tr.trail.Color = colorSeq(Flags["Visuals/Цвет трейла"], t)
    end

    local sk = Cos.skeleton
    if sk and sk.model.Parent then
        local c = getColor(Flags["Visuals/Цвет скелета"], t, 0)
        for _, b in ipairs(sk.bones) do
            b.Color = c
        end
    end

    if Flags["Character/Спин"] then
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad((Flags["Character/Скорость спина"] or 60) * 6) * dt, 0)
        end
    end
end))

local function applyCosmetics()
    if Flags["Visuals/Крылья"] then buildWings() else destroyCos("wings") end
    if Flags["Visuals/Китайская шляпа"] then buildHat() else destroyCos("hat") end
    if Flags["Visuals/Трейл"] then buildTrail() else destroyCos("trail") end
    if Flags["Visuals/Скелет"] then buildSkeleton() else destroyCos("skeleton") end
    applySkin(Flags["Skins/Скин"] or "Выкл")
end

track(LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart", 10)
    char:WaitForChild("Head", 10)
    task.wait(0.3)
    applyCosmetics()
end))

-- ============================================================
-- ШЕЙДЕРЫ (клиентские эффекты Lighting)
-- ============================================================
local Shader = {}

local PRESETS = {
    ["Cinematic"] = { b = 0.02, c = 0.25, s = -0.1, tint = Color3.fromRGB(255, 238, 220), bloom = 0.5, bsize = 28, bth = 1.0, rays = 0.08, dens = 0.3, haze = 1.2, acol = Color3.fromRGB(190, 190, 205) },
    ["Neon Night"] = { b = -0.03, c = 0.3, s = 0.5, tint = Color3.fromRGB(215, 190, 255), bloom = 1.3, bsize = 42, bth = 0.75, rays = 0, dens = 0.35, haze = 1.5, acol = Color3.fromRGB(110, 70, 200) },
    ["Sunset"] = { b = 0.03, c = 0.15, s = 0.3, tint = Color3.fromRGB(255, 205, 160), bloom = 0.6, bsize = 30, bth = 0.9, rays = 0.25, dens = 0.3, haze = 1.8, acol = Color3.fromRGB(255, 170, 120) },
    ["Vivid"] = { b = 0.02, c = 0.2, s = 0.7, tint = Color3.fromRGB(255, 255, 255), bloom = 0.4, bsize = 24, bth = 1.0, rays = 0.1, dens = 0.2, haze = 0.5, acol = Color3.fromRGB(200, 215, 235) },
    ["Noir"] = { b = -0.02, c = 0.4, s = -1, tint = Color3.fromRGB(235, 235, 245), bloom = 0.3, bsize = 20, bth = 1.0, rays = 0, dens = 0.35, haze = 2.2, acol = Color3.fromRGB(160, 160, 170) },
    ["Dream"] = { b = 0.05, c = -0.05, s = 0.3, tint = Color3.fromRGB(255, 210, 255), bloom = 1.0, bsize = 50, bth = 0.7, rays = 0.15, dens = 0.4, haze = 1.0, acol = Color3.fromRGB(255, 190, 240) },
}
local PRESET_NAMES = { "Выкл", "Cinematic", "Neon Night", "Sunset", "Vivid", "Noir", "Dream" }
local NEUTRAL = { b = 0, c = 0, s = 0, tint = Color3.fromRGB(255, 255, 255), bloom = 0, bsize = 24, bth = 1, rays = 0 }

local function ensureShader()
    if Shader.cc then return end
    local function mk(class)
        local i = Instance.new(class)
        i.Name = "luxxs_" .. class
        i.Parent = Lighting
        return i
    end
    Shader.cc = mk("ColorCorrectionEffect")
    Shader.bloom = mk("BloomEffect")
    Shader.rays = mk("SunRaysEffect")

    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    if atm then
        Shader.atm = atm
        Shader.atmOrig = { Density = atm.Density, Haze = atm.Haze, Color = atm.Color }
    else
        Shader.atm = mk("Atmosphere")
        Shader.atm.Density = 0
        Shader.atmCreated = true
    end
end

local function disableShader(full)
    if not Shader.cc then return end
    Shader.cc.Enabled = false
    Shader.bloom.Enabled = false
    Shader.rays.Enabled = false
    if Shader.atmOrig then
        pcall(function()
            tween(Shader.atm, 0.5, Shader.atmOrig)
        end)
    elseif Shader.atm then
        pcall(function() Shader.atm.Density = 0 end)
    end
    if full then
        for _, k in ipairs({ "cc", "bloom", "rays" }) do
            pcall(function() Shader[k]:Destroy() end)
        end
        if Shader.atmCreated then
            pcall(function() Shader.atm:Destroy() end)
        end
        Shader = {}
    end
end

local function refreshShader(time)
    time = time or 0.9
    local preset = PRESETS[Flags["Shaders/Пресет"] or "Выкл"]
    local ob = (Flags["Shaders/Яркость"] or 0) / 100
    local oc = (Flags["Shaders/Контраст"] or 0) / 100
    local os_ = (Flags["Shaders/Насыщенность"] or 0) / 100
    local obl = (Flags["Shaders/Bloom"] or 0) / 50

    if not preset and ob == 0 and oc == 0 and os_ == 0 and obl == 0 then
        disableShader(false)
        return
    end

    ensureShader()
    local p = preset or NEUTRAL
    Shader.cc.Enabled = true
    Shader.bloom.Enabled = true
    Shader.rays.Enabled = true

    tween(Shader.cc, time, {
        Brightness = p.b + ob,
        Contrast = p.c + oc,
        Saturation = p.s + os_,
        TintColor = p.tint,
    })
    tween(Shader.bloom, time, { Intensity = p.bloom + obl, Size = p.bsize, Threshold = p.bth })
    tween(Shader.rays, time, { Intensity = p.rays })

    if preset then
        tween(Shader.atm, time, { Density = preset.dens, Haze = preset.haze, Color = preset.acol })
    elseif Shader.atmOrig then
        tween(Shader.atm, time, Shader.atmOrig)
    else
        tween(Shader.atm, time, { Density = 0 })
    end
end

-- ============================================================
-- ИНТЕРФЕЙС
-- ============================================================
local main = Instance.new("CanvasGroup")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.Size = UDim2.new(0, 880, 0, 440)
main.BackgroundColor3 = BG
main.BorderSizePixel = 0
main.GroupTransparency = 1
main.Visible = false
main.Parent = gui
corner(main, 14)
stroke(main, PURPLE, 1.5, 0.4)

local scale = Instance.new("UIScale")
scale.Scale = 0.7
scale.Parent = main

local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 46)
top.BackgroundColor3 = BG2
top.BorderSizePixel = 0
top.Parent = main

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 16, 0, 0)
title.Size = UDim2.new(0, 200, 1, 0)
title.RichText = true
title.Font = Enum.Font.GothamBold
title.TextSize = 24
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = '<b>lu<font color="rgb(150,80,255)">xxs</font></b>'
title.TextColor3 = WHITE
title.Parent = top

local byLbl = Instance.new("TextLabel")
byLbl.BackgroundTransparency = 1
byLbl.Position = UDim2.new(0, 98, 0, 4)
byLbl.Size = UDim2.new(0, 100, 1, 0)
byLbl.Font = Enum.Font.Gotham
byLbl.TextSize = 12
byLbl.TextColor3 = GRAY
byLbl.TextXAlignment = Enum.TextXAlignment.Left
byLbl.Text = "by DrHub"
byLbl.Parent = top

local ver = Instance.new("TextLabel")
ver.BackgroundTransparency = 1
ver.Position = UDim2.new(1, -120, 0, 0)
ver.Size = UDim2.new(0, 104, 1, 0)
ver.Font = Enum.Font.Gotham
ver.TextSize = 12
ver.TextColor3 = GRAY
ver.TextXAlignment = Enum.TextXAlignment.Right
ver.Text = "v5.0 • MM2"
ver.Parent = top

local side = Instance.new("Frame")
side.Position = UDim2.new(0, 0, 0, 46)
side.Size = UDim2.new(0, 130, 1, -46)
side.BackgroundColor3 = BG2
side.BorderSizePixel = 0
side.Parent = main

local sideList = Instance.new("Frame")
sideList.BackgroundTransparency = 1
sideList.Position = UDim2.new(0, 8, 0, 10)
sideList.Size = UDim2.new(1, -16, 1, -20)
sideList.Parent = side

local indicator = Instance.new("Frame")
indicator.Size = UDim2.new(0, 4, 0, 24)
indicator.Position = UDim2.new(0, 0, 0, 15)
indicator.BackgroundColor3 = PURPLE
indicator.BorderSizePixel = 0
indicator.ZIndex = 3
indicator.Parent = side
corner(indicator, 2)

local pages = Instance.new("Frame")
pages.BackgroundTransparency = 1
pages.Position = UDim2.new(0, 140, 0, 56)
pages.Size = UDim2.new(0, 470, 1, -66)
pages.ClipsDescendants = true
pages.Parent = main

-- панель превью: часть окна, двигается и анимируется вместе с меню
local previewPanel = Instance.new("Frame")
previewPanel.Name = "Preview"
previewPanel.Position = UDim2.new(0, 620, 0, 56)
previewPanel.Size = UDim2.new(0, 250, 1, -66)
previewPanel.BorderSizePixel = 0
previewPanel.Parent = main

-- ===== Вкладки =====
local tabs = {}
local currentTab = nil
local switching = false

local function selectTab(tab)
    if currentTab == tab or switching then return end
    switching = true

    local old = currentTab
    currentTab = tab

    tween(indicator, 0.35, { Position = UDim2.new(0, 0, 0, 15 + tab.index * 40) }, Enum.EasingStyle.Back)
    for _, t in ipairs(tabs) do
        tween(t.button, 0.25, {
            TextColor3 = (t == tab) and WHITE or GRAY,
            BackgroundTransparency = (t == tab) and 0.7 or 1,
        })
    end

    if old then
        tween(old.page, 0.2, { GroupTransparency = 1, Position = UDim2.new(0, -20, 0, 0) })
        task.delay(0.2, function()
            old.page.Visible = false
        end)
    end

    task.delay(old and 0.15 or 0, function()
        tab.page.Position = UDim2.new(0, 20, 0, 0)
        tab.page.GroupTransparency = 1
        tab.page.Visible = true
        tween(tab.page, 0.35, { GroupTransparency = 0, Position = UDim2.new(0, 0, 0, 0) })
        task.delay(0.35, function()
            switching = false
        end)
    end)
end

local function createTab(name, topHeight)
    local index = #tabs
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 34)
    button.Position = UDim2.new(0, 0, 0, index * 40)
    button.BackgroundColor3 = PURPLE
    button.BackgroundTransparency = 1
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 14
    button.TextColor3 = GRAY
    button.Text = name
    button.AutoButtonColor = false
    button.Parent = sideList
    corner(button, 8)

    local page = Instance.new("CanvasGroup")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.GroupTransparency = 1
    page.Parent = pages

    local topFrame
    local offset = 0
    if topHeight then
        topFrame = Instance.new("Frame")
        topFrame.Size = UDim2.new(1, 0, 0, topHeight)
        topFrame.BorderSizePixel = 0
        topFrame.Parent = page
        offset = topHeight + 8
    end

    local scroll = Instance.new("ScrollingFrame")
    scroll.Position = UDim2.new(0, 0, 0, offset)
    scroll.Size = UDim2.new(1, 0, 1, -offset)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = PURPLE
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = page

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    local pad = Instance.new("UIPadding")
    pad.PaddingRight = UDim.new(0, 6)
    pad.PaddingTop = UDim.new(0, 2)
    pad.Parent = scroll

    local tab = { button = button, page = page, scroll = scroll, top = topFrame, index = index, name = name }
    table.insert(tabs, tab)

    button.MouseButton1Click:Connect(function()
        selectTab(tab)
    end)
    button.MouseEnter:Connect(function()
        if currentTab ~= tab then tween(button, 0.2, { TextColor3 = WHITE }) end
    end)
    button.MouseLeave:Connect(function()
        if currentTab ~= tab then tween(button, 0.2, { TextColor3 = GRAY }) end
    end)

    -- === Элементы ===
    function tab:Label(text)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, 20)
        l.BackgroundTransparency = 1
        l.Font = Enum.Font.GothamBold
        l.TextSize = 13
        l.TextColor3 = PURPLE
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Text = text
        l:SetAttribute("hdr", true)
        l.Parent = scroll
    end

    function tab:Text(text)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, 24)
        l.BackgroundColor3 = BG3
        l.Font = Enum.Font.Gotham
        l.TextSize = 13
        l.TextColor3 = GRAY
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Text = "   " .. text
        l.Parent = scroll
        corner(l, 6)
    end

    function tab:Toggle(text, default, callback)
        local key = name .. "/" .. text
        local state = default or false

        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, 0, 0, 38)
        row.BackgroundColor3 = BG3
        row.AutoButtonColor = false
        row.Text = ""
        row.Parent = scroll
        corner(row, 8)

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.Size = UDim2.new(1, -70, 1, 0)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 14
        lbl.TextColor3 = WHITE
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = text
        lbl.Parent = row

        local sw = Instance.new("Frame")
        sw.AnchorPoint = Vector2.new(1, 0.5)
        sw.Position = UDim2.new(1, -12, 0.5, 0)
        sw.Size = UDim2.new(0, 40, 0, 20)
        sw.BackgroundColor3 = state and PURPLE or Color3.fromRGB(60, 56, 80)
        sw.Parent = row
        corner(sw, 10)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        knob.BackgroundColor3 = WHITE
        knob.Parent = sw
        corner(knob, 8)

        register(key, state, function(v)
            state = v and true or false
            Flags[key] = state
            tween(sw, 0.25, { BackgroundColor3 = state and PURPLE or Color3.fromRGB(60, 56, 80) })
            tween(knob, 0.3, {
                Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            }, Enum.EasingStyle.Back)
            if callback then task.spawn(callback, state) end
        end)

        row.MouseButton1Click:Connect(function() Setters[key](not state) end)
        row.MouseEnter:Connect(function() tween(row, 0.2, { BackgroundColor3 = Color3.fromRGB(44, 39, 64) }) end)
        row.MouseLeave:Connect(function() tween(row, 0.2, { BackgroundColor3 = BG3 }) end)
    end

    function tab:Button(text, callback)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 38)
        b.BackgroundColor3 = PURPLE
        b.BackgroundTransparency = 0.25
        b.AutoButtonColor = false
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 14
        b.TextColor3 = WHITE
        b.Text = text
        b.Parent = scroll
        corner(b, 8)

        b.MouseEnter:Connect(function() tween(b, 0.2, { BackgroundTransparency = 0 }) end)
        b.MouseLeave:Connect(function() tween(b, 0.2, { BackgroundTransparency = 0.25 }) end)
        b.MouseButton1Click:Connect(function()
            tween(b, 0.08, { Size = UDim2.new(1, -8, 0, 34) })
            task.delay(0.08, function()
                tween(b, 0.25, { Size = UDim2.new(1, 0, 0, 38) }, Enum.EasingStyle.Back)
            end)
            if callback then task.spawn(callback) end
        end)
    end

    function tab:Slider(text, min, max, default, callback)
        local key = name .. "/" .. text
        local value = default or min

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 50)
        row.BackgroundColor3 = BG3
        row.Parent = scroll
        corner(row, 8)

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Position = UDim2.new(0, 12, 0, 4)
        lbl.Size = UDim2.new(1, -24, 0, 20)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 14
        lbl.TextColor3 = WHITE
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = text .. ": " .. tostring(value)
        lbl.Parent = row

        local bar = Instance.new("Frame")
        bar.Position = UDim2.new(0, 12, 0, 34)
        bar.Size = UDim2.new(1, -24, 0, 6)
        bar.BackgroundColor3 = Color3.fromRGB(60, 56, 80)
        bar.Parent = row
        corner(bar, 3)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = PURPLE
        fill.BorderSizePixel = 0
        fill.Parent = bar
        corner(fill, 3)

        register(key, value, function(v)
            v = math.clamp(math.floor((tonumber(v) or min) + 0.5), min, max)
            value = v
            Flags[key] = v
            lbl.Text = text .. ": " .. tostring(v)
            tween(fill, 0.1, { Size = UDim2.new((v - min) / (max - min), 0, 1, 0) }, Enum.EasingStyle.Linear)
            if callback then task.spawn(callback, v) end
        end)

        local sliding = false
        local function update(x)
            local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            Setters[key](min + (max - min) * rel)
        end

        bar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                sliding = true
                update(i.Position.X)
            end
        end)
        track(UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                sliding = false
            end
        end))
        track(UIS.InputChanged:Connect(function(i)
            if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                update(i.Position.X)
            end
        end))
    end

    -- Выбор из списка: ЛКМ — дальше, ПКМ — назад
    function tab:Choice(text, options, default, callback)
        local key = name .. "/" .. text
        local idx = table.find(options, default) or 1

        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, 0, 0, 38)
        row.BackgroundColor3 = BG3
        row.AutoButtonColor = false
        row.Text = ""
        row.Parent = scroll
        corner(row, 8)

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.Size = UDim2.new(0.5, -12, 1, 0)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 14
        lbl.TextColor3 = WHITE
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = text
        lbl.Parent = row

        local val = Instance.new("TextLabel")
        val.BackgroundTransparency = 1
        val.Position = UDim2.new(0.5, 0, 0, 0)
        val.Size = UDim2.new(0.5, -12, 1, 0)
        val.Font = Enum.Font.GothamBold
        val.TextSize = 14
        val.TextColor3 = PURPLE
        val.TextXAlignment = Enum.TextXAlignment.Right
        val.Text = options[idx] .. "  ›"
        val.Parent = row

        register(key, options[idx], function(v)
            local i = table.find(options, v)
            if not i then return end
            idx = i
            Flags[key] = options[i]
            val.Text = options[i] .. "  ›"
            val.TextTransparency = 1
            tween(val, 0.25, { TextTransparency = 0 })
            if callback then task.spawn(callback, options[i]) end
        end)

        row.MouseButton1Click:Connect(function()
            Setters[key](options[idx % #options + 1])
        end)
        row.MouseButton2Click:Connect(function()
            Setters[key](options[(idx - 2) % #options + 1])
        end)
        row.MouseEnter:Connect(function() tween(row, 0.2, { BackgroundColor3 = Color3.fromRGB(44, 39, 64) }) end)
        row.MouseLeave:Connect(function() tween(row, 0.2, { BackgroundColor3 = BG3 }) end)
    end

    -- Палитра: оттенок / насыщенность / яркость + радужный режим
    function tab:ColorPicker(text, default)
        local key = name .. "/" .. text
        local hsv = { default[1], default[2], default[3] }
        local rainbow = false

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 142)
        row.BackgroundColor3 = BG3
        row.Parent = scroll
        corner(row, 8)

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Position = UDim2.new(0, 12, 0, 6)
        lbl.Size = UDim2.new(0.5, -12, 0, 20)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 14
        lbl.TextColor3 = WHITE
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = text
        lbl.Parent = row

        local sw = Instance.new("Frame")
        sw.AnchorPoint = Vector2.new(1, 0)
        sw.Position = UDim2.new(1, -12, 0, 8)
        sw.Size = UDim2.new(0, 34, 0, 18)
        sw.BorderSizePixel = 0
        sw.Parent = row
        corner(sw, 5)
        stroke(sw, WHITE, 1, 0.6)

        local rb = Instance.new("TextButton")
        rb.AnchorPoint = Vector2.new(1, 0)
        rb.Position = UDim2.new(1, -52, 0, 8)
        rb.Size = UDim2.new(0, 62, 0, 18)
        rb.BackgroundTransparency = 1
        rb.AutoButtonColor = false
        rb.Font = Enum.Font.GothamBold
        rb.TextSize = 9
        rb.Text = "РАДУЖНЫЙ"
        rb.TextColor3 = GRAY
        rb.Parent = row

        local bars = {}
        local captions = { "ОТТЕНОК", "НАСЫЩЕННОСТЬ", "ЯРКОСТЬ" }
        for i = 1, 3 do
            local y = 34 + (i - 1) * 34
            local cap = Instance.new("TextLabel")
            cap.BackgroundTransparency = 1
            cap.Position = UDim2.new(0, 12, 0, y)
            cap.Size = UDim2.new(1, -24, 0, 12)
            cap.Font = Enum.Font.Gotham
            cap.TextSize = 9
            cap.TextColor3 = GRAY
            cap.TextXAlignment = Enum.TextXAlignment.Left
            cap.Text = captions[i]
            cap.Parent = row

            local bar = Instance.new("Frame")
            bar.Position = UDim2.new(0, 12, 0, y + 15)
            bar.Size = UDim2.new(1, -24, 0, 12)
            bar.BackgroundColor3 = WHITE
            bar.BorderSizePixel = 0
            bar.Parent = row
            corner(bar, 6)

            local g = Instance.new("UIGradient")
            g.Parent = bar

            local knob = Instance.new("Frame")
            knob.AnchorPoint = Vector2.new(0.5, 0.5)
            knob.Size = UDim2.new(0, 6, 0, 18)
            knob.Position = UDim2.new(hsv[i], 0, 0.5, 0)
            knob.BackgroundColor3 = WHITE
            knob.BorderSizePixel = 0
            knob.ZIndex = 3
            knob.Parent = bar
            corner(knob, 3)
            stroke(knob, Color3.new(0, 0, 0), 1, 0.4)

            bars[i] = { bar = bar, g = g, knob = knob }
        end

        local function refresh()
            local h, sat, v = hsv[1], hsv[2], hsv[3]
            local hue = {}
            for k = 0, 6 do
                hue[#hue + 1] = ColorSequenceKeypoint.new(k / 6, Color3.fromHSV(math.min(k / 6, 0.999), 1, 1))
            end
            bars[1].g.Color = ColorSequence.new(hue)
            bars[2].g.Color = ColorSequence.new(Color3.fromHSV(h, 0, v), Color3.fromHSV(h, 1, v))
            bars[3].g.Color = ColorSequence.new(Color3.fromHSV(h, sat, 0), Color3.fromHSV(h, sat, 1))
            for i = 1, 3 do
                bars[i].knob.Position = UDim2.new(hsv[i], 0, 0.5, 0)
                bars[i].bar.BackgroundTransparency = rainbow and 0.6 or 0
            end
            sw.BackgroundColor3 = Color3.fromHSV(h, sat, v)
            rb.TextColor3 = rainbow and PURPLE or GRAY
        end

        register(key, { hsv[1], hsv[2], hsv[3] }, function(v)
            if v == "Радужный" then
                rainbow = true
            elseif type(v) == "table" and #v >= 3 then
                rainbow = false
                hsv = { v[1], v[2], v[3] }
            end
            Flags[key] = rainbow and "Радужный" or { hsv[1], hsv[2], hsv[3] }
            refresh()
        end)
        refresh()

        rb.MouseButton1Click:Connect(function()
            Setters[key](rainbow and { hsv[1], hsv[2], hsv[3] } or "Радужный")
        end)

        local active = nil
        local function setFromX(i, x)
            local bar = bars[i].bar
            local n = { hsv[1], hsv[2], hsv[3] }
            n[i] = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
            Setters[key](n)
        end
        for i = 1, 3 do
            bars[i].bar.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    active = i
                    scroll.ScrollingEnabled = false
                    setFromX(i, inp.Position.X)
                end
            end)
        end
        track(UIS.InputChanged:Connect(function(inp)
            if active and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                setFromX(active, inp.Position.X)
            end
        end))
        track(UIS.InputEnded:Connect(function(inp)
            if active and (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then
                active = nil
                scroll.ScrollingEnabled = true
            end
        end))
    end

    return tab
end

-- ===== Открытие / закрытие =====
local menuTrans = 0

local function fitScale()
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
    return math.min(1, (vp.X - 20) / 880, (vp.Y - 20) / 440)
end

local isOpen = false
local busy = false

local function openMenu()
    if busy then return end
    busy = true
    isOpen = true
    main.Visible = true
    local fit = fitScale()
    scale.Scale = fit * 0.7
    main.GroupTransparency = 1
    tween(scale, 0.45, { Scale = fit }, Enum.EasingStyle.Back)
    tween(main, 0.3, { GroupTransparency = menuTrans })
    task.delay(0.45, function() busy = false end)
end

local function closeMenu()
    if busy then return end
    busy = true
    isOpen = false
    tween(scale, 0.3, { Scale = fitScale() * 0.7 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    tween(main, 0.3, { GroupTransparency = 1 })
    task.delay(0.3, function()
        main.Visible = false
        busy = false
    end)
end

local function toggleMenu()
    if isOpen then closeMenu() else openMenu() end
end

-- ===== Иконка LX =====
local icon = Instance.new("TextButton")
icon.Name = "Icon"
icon.Size = UDim2.new(0, 56, 0, 56)
icon.Position = UDim2.new(0, 30, 0.5, -28)
icon.BackgroundColor3 = BG
icon.AutoButtonColor = false
icon.Text = ""
icon.ZIndex = 5
icon.Parent = gui
corner(icon, 28)

local iconStroke = stroke(icon, PURPLE, 2.5, 0)
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, PURPLE),
    ColorSequenceKeypoint.new(0.5, WHITE),
    ColorSequenceKeypoint.new(1, PURPLE),
})
grad.Parent = iconStroke

local iconText = Instance.new("TextLabel")
iconText.BackgroundTransparency = 1
iconText.Size = UDim2.new(1, 0, 1, 0)
iconText.Font = Enum.Font.GothamBlack
iconText.TextSize = 22
iconText.RichText = true
iconText.Text = '<b>L<font color="rgb(150,80,255)">X</font></b>'
iconText.TextColor3 = WHITE
iconText.ZIndex = 6
iconText.Parent = icon

local iconScale = Instance.new("UIScale")
iconScale.Parent = icon

task.spawn(function()
    local t = 0
    while gui.Parent do
        t += task.wait()
        grad.Rotation = (t * 90) % 360
    end
end)
task.spawn(function()
    while gui.Parent do
        tween(iconScale, 1.2, { Scale = 1.08 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1.2)
        tween(iconScale, 1.2, { Scale = 1 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1.2)
    end
end)

icon.MouseEnter:Connect(function() tween(iconText, 0.2, { TextSize = 26 }) end)
icon.MouseLeave:Connect(function() tween(iconText, 0.2, { TextSize = 22 }) end)

makeDraggable(icon, icon, toggleMenu)
makeDraggable(top, main)

track(UIS.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightShift then
        toggleMenu()
    end
end))

-- ============================================================
-- РАЗДЕЛЫ
-- ============================================================

-- ---------- Main ----------
local mainTab = createTab("Profile")
do
    local av = Instance.new("Frame")
    av.Size = UDim2.new(1, 0, 0, 100)
    av.BackgroundColor3 = BG3
    av.Parent = mainTab.scroll
    corner(av, 8)

    local img = Instance.new("ImageLabel")
    img.Position = UDim2.new(0, 10, 0, 8)
    img.Size = UDim2.new(0, 84, 0, 84)
    img.BackgroundColor3 = BG2
    img.BorderSizePixel = 0
    img.Parent = av
    corner(img, 42)
    stroke(img, PURPLE, 2, 0)

    local nm = Instance.new("TextLabel")
    nm.BackgroundTransparency = 1
    nm.Position = UDim2.new(0, 102, 0, 24)
    nm.Size = UDim2.new(1, -108, 0, 22)
    nm.Font = Enum.Font.GothamBold
    nm.TextSize = 15
    nm.TextColor3 = WHITE
    nm.TextXAlignment = Enum.TextXAlignment.Left
    nm.TextTruncate = Enum.TextTruncate.AtEnd
    nm.Text = LocalPlayer.DisplayName
    nm.Parent = av

    local un = Instance.new("TextLabel")
    un.BackgroundTransparency = 1
    un.Position = UDim2.new(0, 102, 0, 48)
    un.Size = UDim2.new(1, -108, 0, 18)
    un.Font = Enum.Font.Gotham
    un.TextSize = 12
    un.TextColor3 = GRAY
    un.TextXAlignment = Enum.TextXAlignment.Left
    un.Text = "@" .. LocalPlayer.Name
    un.Parent = av

    task.spawn(function()
        local ok, url = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size150x150)
        end)
        if ok and url then img.Image = url end
    end)
end
mainTab:Label("luxxs")
mainTab:Text("RightShift — открыть / закрыть меню")
mainTab:Text("Иконка LX и окно перетаскиваются")
mainTab:Text("Превью справа показывает ваши настройки")

-- ---------- Visuals (превью сверху) ----------
local visTab = createTab("Visuals")

visTab:Label("Ангельские крылья")
visTab:Toggle("Крылья", false, function(state)
    if state then buildWings() else destroyCos("wings") end
end)
visTab:ColorPicker("Цвет крыльев", { 0.62, 0.08, 1 })
visTab:Slider("Скорость крыльев", 1, 10, 3)

visTab:Label("Китайская шляпа")
visTab:Toggle("Китайская шляпа", false, function(state)
    if state then buildHat() else destroyCos("hat") end
end)
visTab:ColorPicker("Цвет шляпы", { 0.76, 0.55, 1 })

visTab:Label("Трейл")
visTab:Toggle("Трейл", false, function(state)
    if state then buildTrail() else destroyCos("trail") end
end)
visTab:ColorPicker("Цвет трейла", { 0.75, 0.8, 1 })
visTab:Slider("Длина трейла", 1, 30, 10)
visTab:Slider("Ширина трейла", 1, 10, 4)

visTab:Label("Скелет (на вашем персонаже)")
visTab:Toggle("Скелет", false, function(state)
    if state then buildSkeleton() else destroyCos("skeleton") end
end)
visTab:Choice("Цвет скелета", COLOR_NAMES, "Белый")

-- ---------- Character ----------
local origZoom = { LocalPlayer.CameraMinZoomDistance, LocalPlayer.CameraMaxZoomDistance }
local chTab = createTab("Character")
chTab:Label("Персонаж")
chTab:Toggle("Third Person", false, function(state)
    if state then
        LocalPlayer.CameraMinZoomDistance = 8
        LocalPlayer.CameraMaxZoomDistance = 20
    else
        LocalPlayer.CameraMinZoomDistance = origZoom[1]
        LocalPlayer.CameraMaxZoomDistance = origZoom[2]
    end
end)
chTab:Toggle("Спин", false)
chTab:Slider("Скорость спина", 1, 1000, 60)
chTab:Slider("FOV камеры", 50, 110, math.clamp(math.floor(workspace.CurrentCamera.FieldOfView + 0.5), 50, 110), function(v)
    workspace.CurrentCamera.FieldOfView = v
end)

-- ---------- Weapons (скины для ножа и пистолета, видны только вам) ----------
local WMATS = {
    ["Neon"] = Enum.Material.Neon, ["Metal"] = Enum.Material.Metal, ["Glass"] = Enum.Material.Glass,
    ["ForceField"] = Enum.Material.ForceField, ["Ice"] = Enum.Material.Ice, ["Lava"] = Enum.Material.CrackedLava,
    ["Foil"] = Enum.Material.Foil, ["Plastic"] = Enum.Material.Plastic,
}
local WMAT_NAMES = { "Как есть", "Neon", "Metal", "Glass", "ForceField", "Ice", "Lava", "Foil", "Plastic" }
local wOrig = {}
local wTools = {}

local function weaponKind(tool)
    local n = string.lower(tool.Name)
    if n:find("knife") or n:find("blade") or n:find("sword") or n:find("dagger") then return "Нож" end
    if n:find("gun") or n:find("revolver") or n:find("pistol") or n:find("luger") then return "Пистолет" end
    return "Прочее"
end

local function collectWeapons()
    local list = {}
    local target = Flags["Weapons/Цель"] or "Все"
    local function scan(container)
        if not container then return end
        for _, o in ipairs(container:GetChildren()) do
            if o:IsA("Tool") and (target == "Все" or weaponKind(o) == target) then
                list[#list + 1] = o
            end
        end
    end
    scan(LocalPlayer.Character)
    scan(LocalPlayer:FindFirstChildOfClass("Backpack"))
    return list
end

local function restoreWeapons()
    for p, d in pairs(wOrig) do
        if p.Parent then
            if d.mesh then
                p.TextureId = d.tex
            else
                p.Color = d.c
                p.Material = d.m
                p.Transparency = d.t
                if d.tex ~= nil then p.TextureID = d.tex end
            end
        end
    end
    wOrig = {}
    for _, tool in ipairs(wTools) do
        local h = tool:FindFirstChild("luxxsWeaponHL")
        if h then h:Destroy() end
    end
    wTools = {}
end

local function skinTool(tool, col, mat, trans, glow)
    for _, p in ipairs(tool:GetDescendants()) do
        if p:IsA("BasePart") then
            if not wOrig[p] then
                wOrig[p] = { c = p.Color, m = p.Material, t = p.Transparency, tex = p:IsA("MeshPart") and p.TextureID or nil }
            end
            local d = wOrig[p]
            if d.t < 0.99 then
                p.Color = col
                if mat then p.Material = mat end
                p.Transparency = math.max(d.t, trans)
                if d.tex and d.tex ~= "" then p.TextureID = "" end
            end
        elseif p:IsA("SpecialMesh") then
            if not wOrig[p] then wOrig[p] = { mesh = true, tex = p.TextureId } end
            if p.TextureId ~= "" then p.TextureId = "" end
        end
    end
    local hl = tool:FindFirstChild("luxxsWeaponHL")
    if glow then
        if not hl then
            hl = Instance.new("Highlight")
            hl.Name = "luxxsWeaponHL"
            hl.FillTransparency = 1
            hl.DepthMode = Enum.HighlightDepthMode.Occluded
            hl.Parent = tool
        end
        hl.OutlineColor = col
    elseif hl then
        hl:Destroy()
    end
end

local wAcc = 0
track(RunService.Heartbeat:Connect(function(dt)
    if not Flags["Weapons/Скин оружия"] then return end
    wAcc = wAcc + dt
    if wAcc >= 0.25 then
        wAcc = 0
        wTools = collectWeapons()
    end
    local col = getColor(Flags["Weapons/Цвет оружия"], os.clock(), 0)
    local mat = WMATS[Flags["Weapons/Материал"] or "Neon"]
    local trans = (Flags["Weapons/Прозрачность"] or 0) / 100
    local glow = Flags["Weapons/Обводка"]
    for _, tool in ipairs(wTools) do
        if tool.Parent then skinTool(tool, col, mat, trans, glow) end
    end
end))

local weaponTab = createTab("Weapons")
weaponTab:Label("Скин оружия (виден только вам)")
weaponTab:Toggle("Скин оружия", false, function(on)
    if on then wTools = collectWeapons() else restoreWeapons() end
end)
weaponTab:Choice("Цель", { "Все", "Нож", "Пистолет" }, "Все", function()
    restoreWeapons()
    if Flags["Weapons/Скин оружия"] then wTools = collectWeapons() end
end)
weaponTab:Choice("Материал", WMAT_NAMES, "Neon")
weaponTab:ColorPicker("Цвет оружия", { 0.76, 0.7, 1 })
weaponTab:Slider("Прозрачность", 0, 80, 0)
weaponTab:Toggle("Обводка", true)

-- приближённый вид по цветам и материалам, самих моделей тут нет
local WPRESETS = {
    ["Chroma"] = { "Радужный", "Neon" },
    ["Swirly"] = { "Радужный", "Plastic" },
    ["Eternalcane"] = { { 0.0, 0.85, 1 }, "Plastic" },
    ["Icebeam"] = { { 0.55, 0.5, 1 }, "Neon" },
    ["Icewing"] = { { 0.55, 0.25, 1 }, "Ice" },
    ["Ice Dragon"] = { { 0.57, 0.7, 1 }, "Ice" },
    ["Gemstone"] = { { 0.78, 0.65, 1 }, "Glass" },
    ["Luger"] = { { 0.0, 0.0, 0.35 }, "Metal" },
}
weaponTab:Label("Пресеты в стиле MM2")
weaponTab:Choice("Пресет MM2", { "Свой", "Chroma", "Swirly", "Eternalcane", "Icebeam", "Icewing", "Ice Dragon", "Gemstone", "Luger" }, "Свой", function(n)
    local pr = WPRESETS[n]
    if not pr then return end
    Setters["Weapons/Цвет оружия"](pr[1])
    Setters["Weapons/Материал"](pr[2])
    Setters["Weapons/Скин оружия"](true)
end)

-- ---------- Shaders ----------
local shTab = createTab("Shaders")
shTab:Label("Шейдеры")
shTab:Choice("Пресет", PRESET_NAMES, "Выкл", function() refreshShader(0.9) end)
shTab:Slider("Яркость", -50, 50, 0, function() refreshShader(0.15) end)
shTab:Slider("Контраст", -50, 50, 0, function() refreshShader(0.15) end)
shTab:Slider("Насыщенность", -100, 100, 0, function() refreshShader(0.15) end)
shTab:Slider("Bloom", 0, 100, 0, function() refreshShader(0.15) end)
shTab:Button("Сбросить шейдеры", function()
    Setters["Shaders/Пресет"]("Выкл")
    Setters["Shaders/Яркость"](0)
    Setters["Shaders/Контраст"](0)
    Setters["Shaders/Насыщенность"](0)
    Setters["Shaders/Bloom"](0)
end)

-- ---------- Settings (конфиги) ----------
local setTab = createTab("Settings")

local FOLDER = "luxxs"
local hasFS = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
local SLOTS = { "1", "2", "3", "4", "5" }

local function cfgPath(slot)
    return FOLDER .. "/config_" .. slot .. ".json"
end

local function isSettingsKey(k)
    return k:sub(1, 9) == "Settings/"
end

local function ensureFolder()
    if type(makefolder) == "function" and type(isfolder) == "function" and not isfolder(FOLDER) then
        pcall(makefolder, FOLDER)
    end
end

local function saveConfig(slot)
    if not hasFS then
        notify("Файловая система недоступна")
        return
    end
    ensureFolder()
    local data = {}
    for k, v in pairs(Flags) do
        if not isSettingsKey(k) then data[k] = v end
    end
    local ok = pcall(function()
        writefile(cfgPath(slot), HttpService:JSONEncode(data))
    end)
    notify(ok and ("Конфиг сохранён: слот " .. slot) or "Ошибка сохранения")
end

local function loadConfig(slot, silent)
    if not hasFS then
        if not silent then notify("Файловая система недоступна") end
        return
    end
    local path = cfgPath(slot)
    if not isfile(path) then
        if not silent then notify("Слот " .. slot .. " пуст") end
        return
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    if not ok or type(data) ~= "table" then
        notify("Ошибка чтения конфига")
        return
    end
    for k, v in pairs(data) do
        if Setters[k] and not isSettingsKey(k) then
            Setters[k](v)
        end
    end
    notify("Конфиг загружен: слот " .. slot)
end

local function resetAll()
    for k, d in pairs(Defaults) do
        if not isSettingsKey(k) and Setters[k] then
            Setters[k](d)
        end
    end
    notify("Настройки сброшены")
end

local function unload()
    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    destroyCos("wings")
    destroyCos("hat")
    destroyCos("trail")
    destroyCos("skeleton")
    resetSkin()
    restoreWeapons()
    if origZoom then
        LocalPlayer.CameraMinZoomDistance = origZoom[1]
        LocalPlayer.CameraMaxZoomDistance = origZoom[2]
    end
    disableShader(true)
    gui:Destroy()
end

setTab:Label("Интерфейс")
setTab:Slider("Прозрачность меню", 30, 100, 100, function(v)
    menuTrans = (100 - v) / 100
    if isOpen then main.GroupTransparency = menuTrans end
end)
setTab:Label("Конфиги")
setTab:Choice("Слот конфига", SLOTS, "1")
setTab:Button("Сохранить конфиг", function()
    saveConfig(Flags["Settings/Слот конфига"])
end)
setTab:Button("Загрузить конфиг", function()
    loadConfig(Flags["Settings/Слот конфига"])
end)
setTab:Toggle("Автозагрузка", false, function(state)
    if not hasFS then return end
    ensureFolder()
    pcall(function()
        writefile(FOLDER .. "/autoload.txt", state and Flags["Settings/Слот конфига"] or "")
    end)
    notify(state and "Автозагрузка включена" or "Автозагрузка выключена")
end)
setTab:Button("Сбросить всё", resetAll)
setTab:Label("Меню")
setTab:Button("Закрыть меню", closeMenu)
setTab:Button("Удалить luxxs", unload)

-- ============================================================
-- ПРЕВЬЮ (справа, одно целое с меню): серый 2D манекен
-- ============================================================
local function solid(parentObj, x, y, w, h, color, z, r)
    local f = Instance.new("Frame")
    f.Position = UDim2.new(0, x, 0, y)
    f.Size = UDim2.new(0, w, 0, h)
    f.BackgroundColor3 = color
    f.BorderSizePixel = 0
    f.ZIndex = z or 1
    f.Parent = parentObj
    if r then corner(f, r) end
    return f
end

local function line(parentObj, x1, y1, x2, y2, thick, color, z)
    local dx, dy = x2 - x1, y2 - y1
    local f = Instance.new("Frame")
    f.AnchorPoint = Vector2.new(0.5, 0.5)
    f.Position = UDim2.new(0, (x1 + x2) / 2, 0, (y1 + y2) / 2)
    f.Size = UDim2.new(0, math.sqrt(dx * dx + dy * dy), 0, thick)
    f.Rotation = math.deg(math.atan2(dy, dx))
    f.BackgroundColor3 = color
    f.BorderSizePixel = 0
    f.ZIndex = z or 1
    f.Parent = parentObj
    return f
end

local function buildPreview(panel)
    panel.BackgroundColor3 = WHITE
    panel.ClipsDescendants = true
    corner(panel, 10)
    stroke(panel, PURPLE, 1, 0.6)

    local bgGrad = Instance.new("UIGradient")
    bgGrad.Color = ColorSequence.new(Color3.fromRGB(28, 20, 46), Color3.fromRGB(10, 9, 15))
    bgGrad.Rotation = 90
    bgGrad.Parent = panel

    local cap = Instance.new("TextLabel")
    cap.BackgroundTransparency = 1
    cap.Position = UDim2.new(0, 12, 0, 6)
    cap.Size = UDim2.new(0, 90, 0, 16)
    cap.Font = Enum.Font.GothamBold
    cap.TextSize = 11
    cap.TextColor3 = GRAY
    cap.TextXAlignment = Enum.TextXAlignment.Left
    cap.Text = "PREVIEW"
    cap.ZIndex = 20
    cap.Parent = panel

    local fig = Instance.new("Frame")
    fig.AnchorPoint = Vector2.new(0.5, 0.5)
    fig.Position = UDim2.new(0.5, 0, 0, 205)
    fig.Size = UDim2.new(0, 90, 0, 170)
    fig.BackgroundTransparency = 1
    fig.Parent = panel
    local figScale = Instance.new("UIScale")
    figScale.Scale = 1.35
    figScale.Parent = fig

    local body = Instance.new("Frame")
    body.Size = UDim2.new(1, 0, 1, 0)
    body.BackgroundTransparency = 1
    body.Parent = fig

    -- трейл
    local trailF = {}
    for k = 1, 12 do
        local f = solid(body, 0, 0, 12, 10, WHITE, 1, 5)
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        trailF[k] = f
    end

    -- крылья
    local wingF = {}
    local lens = { 56, 52, 46, 40, 34 }
    for _, side in ipairs({ -1, 1 }) do
        for i = 1, 5 do
            local f = solid(body, 0, 0, lens[i], 9, WHITE, 1, 5)
            f.AnchorPoint = Vector2.new(0.5, 0.5)
            wingF[#wingF + 1] = { f = f, side = side, i = i, len = lens[i] }
        end
    end

    -- манекен
    local bodyParts = {}
    local function part(x, y, w, h, r)
        bodyParts[#bodyParts + 1] = solid(body, x, y, w, h, BODY_GRAY, 3, r)
    end
    part(32, 14, 26, 26, 13)   -- голова
    part(25, 44, 40, 56, 8)    -- торс
    part(10, 46, 12, 52, 6)    -- левая рука
    part(68, 46, 12, 52, 6)    -- правая рука
    part(27, 102, 16, 62, 6)   -- левая нога
    part(47, 102, 16, 62, 6)   -- правая нога

    -- скелет: кости + суставы
    local skel = Instance.new("Frame")
    skel.Size = UDim2.new(1, 0, 1, 0)
    skel.BackgroundTransparency = 1
    skel.ZIndex = 6
    skel.Parent = body

    local J = {
        head = { 45, 27 }, neck = { 45, 44 },
        shL = { 26, 50 }, shR = { 64, 50 },
        elL = { 16, 74 }, elR = { 74, 74 },
        haL = { 16, 98 }, haR = { 74, 98 },
        pel = { 45, 100 }, hipL = { 35, 102 }, hipR = { 55, 102 },
        knL = { 35, 133 }, knR = { 55, 133 },
        ftL = { 35, 164 }, ftR = { 55, 164 },
    }
    local BONES = {
        { "head", "neck" }, { "neck", "pel" }, { "neck", "shL" }, { "neck", "shR" },
        { "shL", "elL" }, { "elL", "haL" }, { "shR", "elR" }, { "elR", "haR" },
        { "pel", "hipL" }, { "pel", "hipR" },
        { "hipL", "knL" }, { "knL", "ftL" }, { "hipR", "knR" }, { "knR", "ftR" },
    }
    local skelParts = {}
    for _, b in ipairs(BONES) do
        local a, c = J[b[1]], J[b[2]]
        skelParts[#skelParts + 1] = line(skel, a[1], a[2], c[1], c[2], 2, WHITE, 6)
    end
    for _, p in pairs(J) do
        skelParts[#skelParts + 1] = solid(skel, p[1] - 3, p[2] - 3, 6, 6, WHITE, 7, 3)
    end

    -- китайская шляпа (конус из слоёв)
    local hatS = {}
    local hatN = 30
    for i = 1, hatN do
        local t = (i - 1) / (hatN - 1)
        local w = 70 * (1 - t) ^ 1.15 + 3
        hatS[i] = solid(body, 45 - w / 2, 18 - i * 1.2, w, 2, WHITE, 5)
    end

    track(RunService.RenderStepped:Connect(function()
        if not isOpen then return end
        local t = os.clock()

        body.Position = UDim2.new(0, 0, 0, math.sin(t * 2) * 2)

        -- скин и скелет
        local skelOn = Flags["Visuals/Скелет"]
        local skin = SKINS[Flags["Skins/Скин"] or ""]
        local bcol = skin and skin[1] or BODY_GRAY
        for _, p in ipairs(bodyParts) do
            p.BackgroundColor3 = bcol
            p.BackgroundTransparency = skelOn and 0.8 or 0
        end
        skel.Visible = skelOn
        if skelOn then
            local scol = getColor(Flags["Visuals/Цвет скелета"], t, 0)
            for _, s in ipairs(skelParts) do
                s.BackgroundColor3 = scol
            end
        end

        -- шляпа
        local hatOn = Flags["Visuals/Китайская шляпа"]
        local hcol = Flags["Visuals/Цвет шляпы"]
        for i, s in ipairs(hatS) do
            s.Visible = hatOn
            if hatOn then s.BackgroundColor3 = getColor(hcol, t, i * 0.025) end
        end

        -- крылья
        local wingsOn = Flags["Visuals/Крылья"]
        local wcol = Flags["Visuals/Цвет крыльев"]
        local flap = math.sin(t * (Flags["Visuals/Скорость крыльев"] or 3)) * 0.2
        for _, w in ipairs(wingF) do
            w.f.Visible = wingsOn
            if wingsOn then
                local a = math.rad(12 + w.i * 13) + flap * (0.5 + w.i * 0.15)
                local dx, dy = w.side * math.cos(a), -math.sin(a)
                local sx = (w.side == -1) and 26 or 64
                w.f.Position = UDim2.new(0, sx + dx * w.len / 2, 0, 52 + dy * w.len / 2)
                w.f.Rotation = math.deg(math.atan2(dy, dx))
                w.f.BackgroundColor3 = getColor(wcol, t, w.i * 0.05)
                w.f.BackgroundTransparency = 0.08
            end
        end

        -- трейл
        local trailOn = Flags["Visuals/Трейл"]
        local tcol = Flags["Visuals/Цвет трейла"]
        local tlen = math.clamp(Flags["Visuals/Длина трейла"] or 10, 1, 30)
        local count = math.clamp(math.floor(tlen / 30 * 12) + 2, 3, 12)
        local twidth = Flags["Visuals/Ширина трейла"] or 4
        for k, f in ipairs(trailF) do
            local show = trailOn and k <= count
            f.Visible = show
            if show then
                local fall = k / count
                f.Position = UDim2.new(0, 22 - k * 8, 0, 108 + math.sin(t * 4 + k * 0.6) * 4 * fall)
                f.Size = UDim2.new(0, 12, 0, math.max(2, twidth * 2.2 * (1 - fall * 0.8)))
                f.BackgroundTransparency = 0.1 + fall * 0.85
                f.BackgroundColor3 = getColor(tcol, t, -k * 0.04)
            end
        end
    end))
end

buildPreview(previewPanel)

-- ===== Две колонки: слева, когда место кончилось — справа =====
local function twoColumns(tab)
    local scroll = tab.scroll
    local items = {}
    for _, ch in ipairs(scroll:GetChildren()) do
        if ch:IsA("GuiObject") then items[#items + 1] = ch end
    end
    local lay = scroll:FindFirstChildOfClass("UIListLayout")
    if lay then lay:Destroy() end

    local function mkCol(xs, xo)
        local f = Instance.new("Frame")
        f.BackgroundTransparency = 1
        f.Position = UDim2.new(xs, xo, 0, 0)
        f.Size = UDim2.new(0.5, -4, 0, 0)
        f.AutomaticSize = Enum.AutomaticSize.Y
        f.Parent = scroll
        local l = Instance.new("UIListLayout")
        l.Padding = UDim.new(0, 8)
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Parent = f
        return f
    end
    local colL, colR = mkCol(0, 0), mkCol(0.5, 4)

    local limit = 440 - 66 - 10
    local h, right = 0, false
    for _, it in ipairs(items) do
        local ih = it.Size.Y.Offset + 8
        local need = it:GetAttribute("hdr") and (ih + 38) or ih
        if not right and h + need > limit then right = true end
        if not right then h = h + ih end
        it.Parent = right and colR or colL
    end
end
for _, t in ipairs(tabs) do twoColumns(t) end

-- ===== Старт =====
selectTab(mainTab)

if hasFS then
    pcall(function()
        local p = FOLDER .. "/autoload.txt"
        if isfile(p) then
            local slot = readfile(p)
            if slot ~= "" and table.find(SLOTS, slot) then
                Setters["Settings/Слот конфига"](slot)
                loadConfig(slot, true)
                Setters["Settings/Автозагрузка"](true)
            end
        end
    end)
end

notify("загружен • RightShift или иконка LX")
