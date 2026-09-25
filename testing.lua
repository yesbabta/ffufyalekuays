--[[ LiquidGlass Pro v3.0 ]]

local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Constants = {}
Constants.VERSION = "3.0.0"

Constants.Springs = {
    Snappy  = { Tension = 300, Friction = 30, Mass = 1, Precision = 0.01 },
    Default = { Tension = 170, Friction = 26, Mass = 1, Precision = 0.01 },
    Smooth  = { Tension = 120, Friction = 20, Mass = 1, Precision = 0.01 },
    Elastic = { Tension = 150, Friction = 18, Mass = 1, Precision = 0.005 },
}

Constants.ZOrder = {
    Shadow = 0, Background = 10, FrostBase = 20, FrostNoise = 25,
    Refraction = 30, Chromatic = 40, DepthBottom = 50, DepthTop = 51,
    InnerGlow = 55, Border = 60, HoverGlow = 65, PressOverlay = 70, Content = 100,
}

Constants.Defaults = {
    Chromatic = {
        Enabled = true, Intensity = 2.5, EdgeOnly = true,
        RedOffset = Vector2.new(-2, 0), GreenOffset = Vector2.new(0, 0),
        BlueOffset = Vector2.new(2, 0), Opacity = 0.35,
    },
    Refraction = {
        Enabled = true, Intensity = 6, EdgeWidth = 16,
        Layers = 3, FalloffExponent = 2,
    },
    Frost = {
        Enabled = true, NoiseOpacity = 0.05, Layers = 2,
        Tint = Color3.fromRGB(255, 255, 255), TintOpacity = 0.12,
    },
    BorderGradient = {
        Enabled = true, BaseRotation = 135, MouseInfluence = 36, Thickness = 1.5,
    },
    Depth = {
        Enabled = true,
        TopGlowColor = Color3.fromRGB(255, 255, 255), TopGlowOpacity = 0.25,
        BottomShadowColor = Color3.fromRGB(0, 0, 0), BottomShadowOpacity = 0.12,
        InnerGlowColor = Color3.fromRGB(255, 255, 255), InnerGlowOpacity = 0.06,
    },
    Interaction = {
        Enabled = true, HoverScale = 1.03, PressScale = 0.97,
        ElasticEnabled = true, ElasticIntensity = 6,
    },
    Background = {
        Color = Color3.fromRGB(255, 255, 255), Transparency = 0.85,
        GradientTop = Color3.fromRGB(255, 255, 255),
        GradientBottom = Color3.fromRGB(220, 232, 248),
        GradientRotation = 180,
    },
    Shadow = {
        Enabled = true, Color = Color3.fromRGB(0, 0, 40), Transparency = 0.7,
        Offset = Vector2.new(0, 10), Spread = 20, Blur = 28,
    },
    Spring = {
        Position = Constants.Springs.Elastic,
        Scale    = Constants.Springs.Snappy,
    },
}

local MathUtils = {}
function MathUtils.Clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end
function MathUtils.SeededRandom(seed)
    local x = math.sin(seed * 12.9898) * 43758.5453
    return x - math.floor(x)
end

local SpringPhysics = {}
function SpringPhysics.Create2D(initial)
    return { Position = initial, Velocity = Vector2.new(0, 0), Target = initial, AtRest = true }
end
function SpringPhysics.Create(initial)
    return { Position = initial, Velocity = 0, Target = initial, AtRest = true }
end
function SpringPhysics.SetTarget2D(s, t) s.Target = t; s.AtRest = false end
function SpringPhysics.SetTarget(s, t)   s.Target = t; s.AtRest = false end
function SpringPhysics.Step2D(s, cfg, dt)
    if s.AtRest then return true end
    local ten, fri, mass, prec = cfg.Tension, cfg.Friction, cfg.Mass or 1, cfg.Precision or 0.01
    local dx, dy = s.Position.X - s.Target.X, s.Position.Y - s.Target.Y
    local fx = -ten * dx - fri * s.Velocity.X
    local fy = -ten * dy - fri * s.Velocity.Y
    s.Velocity = Vector2.new(s.Velocity.X + (fx/mass)*dt, s.Velocity.Y + (fy/mass)*dt)
    s.Position = Vector2.new(s.Position.X + s.Velocity.X*dt, s.Position.Y + s.Velocity.Y*dt)
    if math.sqrt(s.Velocity.X^2+s.Velocity.Y^2) < prec and math.sqrt(dx^2+dy^2) < prec then
        s.Position = s.Target; s.Velocity = Vector2.new(0,0); s.AtRest = true
    end
    return s.AtRest
end

local SpringAnimations = {}
function SpringAnimations.CreateAnimator(v, cfg)
    cfg = cfg or Constants.Springs.Default
    local isVec = typeof(v) == "Vector2"
    local spring = isVec and SpringPhysics.Create2D(v) or SpringPhysics.Create(v)
    return { Spring = spring, Config = cfg, IsVector = isVec }
end
function SpringAnimations.SetTarget(a, t)
    if not a then return end
    if a.IsVector then SpringPhysics.SetTarget2D(a.Spring, t)
    else SpringPhysics.SetTarget(a.Spring, t) end
end
function SpringAnimations.Step(a, dt)
    if not a then return nil end
    if a.IsVector then SpringPhysics.Step2D(a.Spring, a.Config, dt)
    else
        if a.Spring.AtRest then return a.Spring.Position end
        local cfg = a.Config
        local ten, fri, mass, prec = cfg.Tension, cfg.Friction, cfg.Mass or 1, cfg.Precision or 0.01
        local d = a.Spring.Position - a.Spring.Target
        local accel = (-ten*d - fri*a.Spring.Velocity)/mass
        a.Spring.Velocity = a.Spring.Velocity + accel*dt
        a.Spring.Position = a.Spring.Position + a.Spring.Velocity*dt
        if math.abs(a.Spring.Velocity) < prec and math.abs(d) < prec then
            a.Spring.Position = a.Spring.Target; a.Spring.Velocity = 0; a.Spring.AtRest = true
        end
    end
    return a.Spring.Position
end

local LayerBuilders = {}

function LayerBuilders.CreateShadow(parent, cfg, corner)
    if not cfg.Enabled then return nil end
    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(1, cfg.Spread*2, 1, cfg.Spread*2)
    shadow.Position = UDim2.new(0.5, cfg.Offset.X, 0.5, cfg.Offset.Y)
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundColor3 = cfg.Color
    shadow.BackgroundTransparency = MathUtils.Clamp(cfg.Transparency, 0, 1)
    shadow.BorderSizePixel = 0
    shadow.ZIndex = Constants.ZOrder.Shadow
    shadow.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(corner.Scale, corner.Offset + cfg.Blur*0.4)
    c.Parent = shadow
    for i = 1, 3 do
        local blur = Instance.new("Frame")
        blur.Size = UDim2.new(1, i*6, 1, i*6)
        blur.Position = UDim2.fromScale(0.5, 0.5)
        blur.AnchorPoint = Vector2.new(0.5, 0.5)
        blur.BackgroundColor3 = cfg.Color
        blur.BackgroundTransparency = MathUtils.Clamp(cfg.Transparency + i*0.08, 0, 1)
        blur.BorderSizePixel = 0
        blur.ZIndex = Constants.ZOrder.Shadow - i
        blur.Parent = shadow
        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(corner.Scale, corner.Offset + cfg.Blur*0.4 + i*2)
        bc.Parent = blur
    end
    return shadow
end

function LayerBuilders.CreateBackground(parent, cfg, corner)
    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = cfg.Color
    bg.BackgroundTransparency = MathUtils.Clamp(cfg.Transparency, 0, 1)
    bg.BorderSizePixel = 0
    bg.ZIndex = Constants.ZOrder.Background
    bg.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = corner
    c.Parent = bg
    local grad = Instance.new("UIGradient")
    grad.Rotation = cfg.GradientRotation
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, cfg.GradientTop),
        ColorSequenceKeypoint.new(1, cfg.GradientBottom),
    })
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.82),
        NumberSequenceKeypoint.new(1, 0.88),
    })
    grad.Parent = bg
    return bg
end

function LayerBuilders.CreateFrostLayers(parent, cfg, depthCfg, corner)
    local layers = {}
    if not cfg.Enabled then return layers end

    local base = Instance.new("Frame")
    base.Size = UDim2.fromScale(1, 1)
    base.BackgroundColor3 = cfg.Tint
    base.BackgroundTransparency = MathUtils.Clamp(1 - cfg.TintOpacity, 0, 1)
    base.BorderSizePixel = 0
    base.ZIndex = Constants.ZOrder.FrostBase
    base.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = corner
    c.Parent = base
    table.insert(layers, base)

    for i = 1, cfg.Layers do
        local noise = Instance.new("Frame")
        noise.Size = UDim2.fromScale(1, 1)
        noise.BackgroundColor3 = Color3.new(1, 1, 1)
        noise.BorderSizePixel = 0
        noise.ZIndex = Constants.ZOrder.FrostNoise + i
        noise.Parent = parent
        local nc = Instance.new("UICorner")
        nc.CornerRadius = corner
        nc.Parent = noise
        local g = Instance.new("UIGradient")
        g.Rotation = i * 45
        local cps, tps = {}, {}
        for j = 0, 6 do
            local pos = j / 6
            local v = MathUtils.SeededRandom(12345 + i*100 + j*10)
            local b = MathUtils.Clamp(0.95 + v*0.1, 0, 1)
            table.insert(cps, ColorSequenceKeypoint.new(pos, Color3.new(b, b, b)))
            table.insert(tps, NumberSequenceKeypoint.new(pos, MathUtils.Clamp(1 - cfg.NoiseOpacity + v*cfg.NoiseOpacity*0.4, 0.7, 1)))
        end
        g.Color = ColorSequence.new(cps)
        g.Transparency = NumberSequence.new(tps)
        g.Parent = noise
        table.insert(layers, noise)
    end

    if depthCfg.Enabled then
        local top = Instance.new("Frame")
        top.Size = UDim2.fromScale(1, 0.5)
        top.Position = UDim2.fromScale(0, 0)
        top.BackgroundColor3 = depthCfg.TopGlowColor
        top.BorderSizePixel = 0
        top.ZIndex = Constants.ZOrder.DepthTop
        top.Parent = parent
        local tc = Instance.new("UICorner")
        tc.CornerRadius = corner
        tc.Parent = top
        local tg = Instance.new("UIGradient")
        tg.Rotation = 180
        tg.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, MathUtils.Clamp(1 - depthCfg.TopGlowOpacity, 0, 1)),
            NumberSequenceKeypoint.new(1, 1),
        })
        tg.Parent = top

        local bot = Instance.new("Frame")
        bot.Size = UDim2.fromScale(1, 0.35)
        bot.Position = UDim2.fromScale(0, 0.65)
        bot.BackgroundColor3 = depthCfg.BottomShadowColor
        bot.BorderSizePixel = 0
        bot.ZIndex = Constants.ZOrder.DepthBottom
        bot.Parent = parent
        local bc = Instance.new("UICorner")
        bc.CornerRadius = corner
        bc.Parent = bot
        local bg = Instance.new("UIGradient")
        bg.Rotation = 180
        bg.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, MathUtils.Clamp(1 - depthCfg.BottomShadowOpacity, 0, 1)),
        })
        bg.Parent = bot
    end

    return layers
end

function LayerBuilders.CreateChromaticLayers(parent, cfg, corner)
    if not cfg.Enabled then return {} end
    local out = {}
    local function make(name, color, offset, z)
        local f = Instance.new("Frame")
        f.Name = "Chromatic_" .. name
        f.Size = UDim2.fromScale(1, 1)
        f.Position = UDim2.fromOffset(offset.X * cfg.Intensity, offset.Y * cfg.Intensity)
        f.BackgroundColor3 = color
        f.BorderSizePixel = 0
        f.ZIndex = z
        f.Parent = parent
        local c = Instance.new("UICorner")
        c.CornerRadius = corner
        c.Parent = f
        if cfg.EdgeOnly then
            local g = Instance.new("UIGradient")
            g.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, MathUtils.Clamp(1 - cfg.Opacity, 0, 1)),
                NumberSequenceKeypoint.new(0.12, 1),
                NumberSequenceKeypoint.new(0.88, 1),
                NumberSequenceKeypoint.new(1, MathUtils.Clamp(1 - cfg.Opacity, 0, 1)),
            })
            g.Parent = f
        else
            f.BackgroundTransparency = MathUtils.Clamp(1 - cfg.Opacity, 0, 1)
        end
        return f
    end
    out.Red   = make("Red",   Color3.fromRGB(255, 90, 90), cfg.RedOffset,   Constants.ZOrder.Chromatic)
    out.Green = make("Green", Color3.fromRGB(90, 255, 90), cfg.GreenOffset, Constants.ZOrder.Chromatic + 1)
    out.Blue  = make("Blue",  Color3.fromRGB(90, 90, 255), cfg.BlueOffset,  Constants.ZOrder.Chromatic + 2)
    return out
end

function LayerBuilders.UpdateChromatic(layers, offset, cfg)
    if not cfg.Enabled or not layers then return end
    local mi = cfg.Intensity * 1.5
    if layers.Red then
        layers.Red.Position = UDim2.fromOffset(
            cfg.RedOffset.X*cfg.Intensity + offset.X*mi,
            cfg.RedOffset.Y*cfg.Intensity + offset.Y*mi*0.3)
    end
    if layers.Green then layers.Green.Position = UDim2.fromOffset(0, 0) end
    if layers.Blue then
        layers.Blue.Position = UDim2.fromOffset(
            cfg.BlueOffset.X*cfg.Intensity - offset.X*mi*0.5,
            cfg.BlueOffset.Y*cfg.Intensity - offset.Y*mi*0.3)
    end
end

function LayerBuilders.CreateRefractionLayers(parent, cfg, corner)
    if not cfg.Enabled then return {} end
    local out = { Top = {}, Bottom = {}, Left = {}, Right = {} }
    for _, edge in ipairs({"Top", "Bottom", "Left", "Right"}) do
        for i = 1, cfg.Layers do
            local depthFactor = 1 - ((i - 1) / cfg.Layers)
            local offset = cfg.Intensity * depthFactor
            local size, pos, rot
            if edge == "Top" then
                size = UDim2.new(1, 0, 0, cfg.EdgeWidth)
                pos  = UDim2.new(0, 0, 0, -offset*0.15*i)
                rot  = 180
            elseif edge == "Bottom" then
                size = UDim2.new(1, 0, 0, cfg.EdgeWidth)
                pos  = UDim2.new(0, 0, 1, -cfg.EdgeWidth + offset*0.15*i)
                rot  = 0
            elseif edge == "Left" then
                size = UDim2.new(0, cfg.EdgeWidth, 1, 0)
                pos  = UDim2.new(0, -offset*0.15*i, 0, 0)
                rot  = 90
            else
                size = UDim2.new(0, cfg.EdgeWidth, 1, 0)
                pos  = UDim2.new(1, -cfg.EdgeWidth + offset*0.15*i, 0, 0)
                rot  = 270
            end
            local f = Instance.new("Frame")
            f.Size = size
            f.Position = pos
            f.BackgroundColor3 = Color3.new(1, 1, 1)
            f.BorderSizePixel = 0
            f.ZIndex = Constants.ZOrder.Refraction + i
            f.ClipsDescendants = true
            f.Parent = parent
            local c = Instance.new("UICorner")
            c.CornerRadius = corner
            c.Parent = f
            local g = Instance.new("UIGradient")
            g.Rotation = rot
            local opacity = MathUtils.Clamp(0.04 * depthFactor, 0, 1)
            g.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1 - opacity),
                NumberSequenceKeypoint.new(1, 1),
            })
            g.Parent = f
            table.insert(out[edge], f)
        end
    end
    return out
end

function LayerBuilders.CreateBorder(parent, cfg, corner)
    if not cfg.Enabled then return {} end
    local border = Instance.new("Frame")
    border.Size = UDim2.fromScale(1, 1)
    border.BackgroundTransparency = 1
    border.ZIndex = Constants.ZOrder.Border
    border.Parent = parent
    local bc = Instance.new("UICorner")
    bc.CornerRadius = corner
    bc.Parent = border
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = cfg.Thickness
    stroke.Color = Color3.new(1, 1, 1)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = border
    local grad = Instance.new("UIGradient")
    grad.Rotation = cfg.BaseRotation
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.92),
        NumberSequenceKeypoint.new(0.3, 0.6),
        NumberSequenceKeypoint.new(0.5, 0.05),
        NumberSequenceKeypoint.new(0.7, 0.6),
        NumberSequenceKeypoint.new(1, 0.92),
    })
    grad.Parent = stroke
    return { Frame = border, Stroke = stroke, Gradient = grad }
end

function LayerBuilders.CreateInnerGlow(parent, cfg, corner)
    if not cfg.Enabled then return nil end
    local f = Instance.new("Frame")
    f.Size = UDim2.fromScale(1, 1)
    f.BackgroundColor3 = cfg.InnerGlowColor
    f.BorderSizePixel = 0
    f.ZIndex = Constants.ZOrder.InnerGlow
    f.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = corner
    c.Parent = f
    local g = Instance.new("UIGradient")
    local op = MathUtils.Clamp(cfg.InnerGlowOpacity, 0, 1)
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1 - op),
        NumberSequenceKeypoint.new(0.3, 1),
        NumberSequenceKeypoint.new(0.7, 1),
        NumberSequenceKeypoint.new(1, 1 - op),
    })
    g.Parent = f
    return f
end

function LayerBuilders.CreateHoverGlow(parent, color, corner)
    local f = Instance.new("Frame")
    f.Size = UDim2.fromScale(1, 1)
    f.BackgroundColor3 = color
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.ZIndex = Constants.ZOrder.HoverGlow
    f.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = corner
    c.Parent = f
    return f
end

function LayerBuilders.CreatePressOverlay(parent, corner)
    local f = Instance.new("Frame")
    f.Size = UDim2.fromScale(1, 1)
    f.BackgroundColor3 = Color3.new(0, 0, 0)
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.ZIndex = Constants.ZOrder.PressOverlay
    f.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = corner
    c.Parent = f
    return f
end

function LayerBuilders.CreateContent(parent, corner)
    local f = Instance.new("Frame")
    f.Size = UDim2.fromScale(1, 1)
    f.BackgroundTransparency = 1
    f.ClipsDescendants = true
    f.ZIndex = Constants.ZOrder.Content
    f.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = corner
    c.Parent = f
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, 8)
    p.PaddingBottom = UDim.new(0, 8)
    p.PaddingLeft = UDim.new(0, 12)
    p.PaddingRight = UDim.new(0, 12)
    p.Parent = f
    return f
end

-- LIQUIDGLASS CLASS

local LiquidGlass = {}
LiquidGlass.__index = LiquidGlass

local function deepMerge(base, over)
    if type(base) ~= "table" or type(over) ~= "table" then
        return over ~= nil and over or base
    end
    local r = {}
    for k, v in pairs(base) do r[k] = deepMerge(v, over[k]) end
    for k, v in pairs(over) do if r[k] == nil then r[k] = v end end
    return r
end

function LiquidGlass.new(config)
    local self = setmetatable({}, LiquidGlass)
    config = config or {}
    self._config = deepMerge(Constants.Defaults, config)

    self._isHovered = false
    self._isPressed = false
    self._mouseOffset = Vector2.zero
    self._connections = {}

    self._positionSpring = SpringAnimations.CreateAnimator(Vector2.zero, self._config.Spring.Position)
    self._scaleSpring    = SpringAnimations.CreateAnimator(Vector2.new(1, 1), self._config.Spring.Scale)

    self:_build()
    self:_setupInteraction()
    self:_startLoop()
    return self
end

function LiquidGlass:_build()
    local cfg = self._config
    local corner = cfg.CornerRadius or 16
    if typeof(corner) == "number" then corner = UDim.new(0, corner) end

    local root = Instance.new("Frame")
    root.Name = cfg.Name or "LiquidGlass"
    root.Size = cfg.Size or UDim2.fromOffset(200, 56)
    root.Position = cfg.Position or UDim2.fromScale(0.5, 0.5)
    root.AnchorPoint = cfg.AnchorPoint or Vector2.new(0.5, 0.5)
    root.BackgroundTransparency = 1
    root.BorderSizePixel = 0
    root.ClipsDescendants = false
    root.ZIndex = cfg.ZIndex or 10
    root.Parent = cfg.Parent
    self._root = root

    local rCorner = Instance.new("UICorner")
    rCorner.CornerRadius = corner
    rCorner.Parent = root

    self._uiScale = Instance.new("UIScale")
    self._uiScale.Scale = 1
    self._uiScale.Parent = root

    self._shadow     = LayerBuilders.CreateShadow(root, cfg.Shadow, corner)
    self._background = LayerBuilders.CreateBackground(root, cfg.Background, corner)
    self._frost      = LayerBuilders.CreateFrostLayers(root, cfg.Frost, cfg.Depth, corner)
    self._refraction = LayerBuilders.CreateRefractionLayers(root, cfg.Refraction, corner)
    self._chromatic  = LayerBuilders.CreateChromaticLayers(root, cfg.Chromatic, corner)
    self._innerGlow  = LayerBuilders.CreateInnerGlow(root, cfg.Depth, corner)
    self._border     = LayerBuilders.CreateBorder(root, cfg.BorderGradient, corner)
    self._hoverGlow  = LayerBuilders.CreateHoverGlow(root, cfg.Depth.InnerGlowColor, corner)
    self._pressOvl   = LayerBuilders.CreatePressOverlay(root, corner)
    self._content    = LayerBuilders.CreateContent(root, corner)

    local input = Instance.new("TextButton")
    input.Size = UDim2.fromScale(1, 1)
    input.BackgroundTransparency = 1
    input.Text = ""
    input.AutoButtonColor = false
    input.ZIndex = 200
    input.Parent = root
    self._input = input
end

function LiquidGlass:_setupInteraction()
    local cfg = self._config
    local conns = self._connections

    table.insert(conns, self._input.MouseEnter:Connect(function()
        self._isHovered = true
        SpringAnimations.SetTarget(self._scaleSpring, Vector2.new(cfg.Interaction.HoverScale, cfg.Interaction.HoverScale))
        if self._hoverGlow then
            TweenService:Create(self._hoverGlow, TweenInfo.new(0.25), { BackgroundTransparency = 0.88 }):Play()
        end
        if self._shadow then
            TweenService:Create(self._shadow, TweenInfo.new(0.25), {
                BackgroundTransparency = MathUtils.Clamp(cfg.Shadow.Transparency * 0.85, 0, 1),
                Size = UDim2.new(1, cfg.Shadow.Spread*2.5, 1, cfg.Shadow.Spread*2.5),
            }):Play()
        end
        if cfg.onHover then cfg.onHover() end
    end))

    table.insert(conns, self._input.MouseLeave:Connect(function()
        self._isHovered = false
        self._isPressed = false
        self._mouseOffset = Vector2.zero
        SpringAnimations.SetTarget(self._scaleSpring, Vector2.new(1, 1))
        SpringAnimations.SetTarget(self._positionSpring, Vector2.zero)
        if self._hoverGlow then
            TweenService:Create(self._hoverGlow, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
        end
        if self._shadow then
            TweenService:Create(self._shadow, TweenInfo.new(0.3), {
                BackgroundTransparency = cfg.Shadow.Transparency,
                Size = UDim2.new(1, cfg.Shadow.Spread*2, 1, cfg.Shadow.Spread*2),
            }):Play()
        end
        if self._border and self._border.Gradient then
            TweenService:Create(self._border.Gradient, TweenInfo.new(0.4), { Rotation = cfg.BorderGradient.BaseRotation }):Play()
        end
        if self._chromatic then
            LayerBuilders.UpdateChromatic(self._chromatic, Vector2.zero, cfg.Chromatic)
        end
        if cfg.onHoverEnd then cfg.onHoverEnd() end
    end))

    table.insert(conns, self._input.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            self._isPressed = true
            SpringAnimations.SetTarget(self._scaleSpring, Vector2.new(cfg.Interaction.PressScale, cfg.Interaction.PressScale))
            if self._pressOvl then
                TweenService:Create(self._pressOvl, TweenInfo.new(0.1), { BackgroundTransparency = 0.88 }):Play()
            end
            if cfg.onPress then cfg.onPress() end
        end
    end))

    table.insert(conns, self._input.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            if self._isPressed then
                self._isPressed = false
                local target = self._isHovered and cfg.Interaction.HoverScale or 1
                SpringAnimations.SetTarget(self._scaleSpring, Vector2.new(target, target))
                if self._pressOvl then
                    TweenService:Create(self._pressOvl, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
                end
                if self._isHovered and cfg.onClick then cfg.onClick() end
                if cfg.onRelease then cfg.onRelease() end
            end
        end
    end))

    table.insert(conns, UserInputService.InputChanged:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        if not self._isHovered then return end
        local pos = Vector2.new(inp.Position.X, inp.Position.Y)
        local absPos = self._root.AbsolutePosition
        local absSize = self._root.AbsoluteSize
        local center = absPos + absSize / 2
        local rel = pos - center
        local nx = math.clamp(rel.X / (absSize.X / 2), -1, 1)
        local ny = math.clamp(rel.Y / (absSize.Y / 2), -1, 1)
        self._mouseOffset = Vector2.new(nx, ny)

        if self._border and self._border.Gradient then
            self._border.Gradient.Rotation = cfg.BorderGradient.BaseRotation + nx * cfg.BorderGradient.MouseInfluence
        end
        LayerBuilders.UpdateChromatic(self._chromatic, Vector2.new(nx, ny), cfg.Chromatic)
        if cfg.Interaction.ElasticEnabled then
            local intensity = cfg.Interaction.ElasticIntensity or 6
            SpringAnimations.SetTarget(self._positionSpring, Vector2.new(nx*intensity, ny*intensity))
        end
    end))
end

function LiquidGlass:_startLoop()
    self._loopConn = RunService.Heartbeat:Connect(function(dt)
        if not self._root or not self._root.Parent then return end
        local pos = SpringAnimations.Step(self._positionSpring, dt)
        local scale = SpringAnimations.Step(self._scaleSpring, dt)
        if typeof(pos) == "Vector2" then
            local base = self._config.Position or UDim2.fromScale(0.5, 0.5)
            self._root.Position = UDim2.new(
                base.X.Scale, base.X.Offset + pos.X,
                base.Y.Scale, base.Y.Offset + pos.Y)
        end
        if typeof(scale) == "Vector2" and self._uiScale then
            self._uiScale.Scale = scale.X
        end
    end)
    table.insert(self._connections, self._loopConn)
end

function LiquidGlass:SetContent(child)
    child.Parent = self._content
    return self
end
function LiquidGlass:GetFrame()        return self._root     end
function LiquidGlass:GetContentFrame() return self._content  end
function LiquidGlass:IsHovered()       return self._isHovered end
function LiquidGlass:IsPressed()       return self._isPressed end
function LiquidGlass:SetVisible(v)     self._root.Visible = v end

function LiquidGlass:Destroy()
    for _, c in ipairs(self._connections) do
        if c.Connected then c:Disconnect() end
    end
    self._connections = {}
    if self._root then self._root:Destroy() end
end

-- FACTORY PRESETS

function LiquidGlass.CreateButton(text, onClick, config)
    config = config or {}
    config.onClick = onClick
    if not config.Size         then config.Size         = UDim2.fromOffset(180, 52) end
    if not config.CornerRadius then config.CornerRadius = 26 end
    local btn = LiquidGlass.new(config)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.Text = text or "Button"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 16
    label.ZIndex = 201
    label.Parent = btn:GetContentFrame()
    return btn
end

function LiquidGlass.CreateCard(config)
    config = config or {}
    if not config.Size         then config.Size         = UDim2.fromOffset(320, 200) end
    if not config.CornerRadius then config.CornerRadius = 20 end
    return LiquidGlass.new(config)
end

function LiquidGlass.CreatePill(text, config)
    config = config or {}
    if not config.Size         then config.Size         = UDim2.fromOffset(110, 34) end
    if not config.CornerRadius then config.CornerRadius = 17 end
    local pill = LiquidGlass.new(config)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.Text = text or ""
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 13
    label.ZIndex = 201
    label.Parent = pill:GetContentFrame()
    return pill
end

function LiquidGlass.CreatePanel(config)
    config = config or {}
    if not config.Size         then config.Size         = UDim2.fromOffset(400, 280) end
    if not config.CornerRadius then config.CornerRadius = 22 end
    return LiquidGlass.new(config)
end

function LiquidGlass.CreateModal(config)
    config = config or {}
    if not config.Size         then config.Size         = UDim2.fromOffset(450, 320) end
    if not config.CornerRadius then config.CornerRadius = 20 end
    if not config.Position     then config.Position     = UDim2.fromScale(0.5, 0.5) end
    return LiquidGlass.new(config)
end

function LiquidGlass.CreateStatusBadge(text, color, config)
    config = config or {}
    if not config.Size         then config.Size         = UDim2.fromOffset(90, 28) end
    if not config.CornerRadius then config.CornerRadius = 14 end
    if color then
        config.Frost = config.Frost or {}
        config.Frost.Tint = color
    end
    local badge = LiquidGlass.new(config)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = text or ""
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 12
    label.ZIndex = 201
    label.Parent = badge:GetContentFrame()
    return badge
end

return {
    VERSION = Constants.VERSION,
    new = LiquidGlass.new,
    CreateButton      = LiquidGlass.CreateButton,
    CreateCard        = LiquidGlass.CreateCard,
    CreatePill        = LiquidGlass.CreatePill,
    CreatePanel       = LiquidGlass.CreatePanel,
    CreateModal       = LiquidGlass.CreateModal,
    CreateStatusBadge = LiquidGlass.CreateStatusBadge,
    Constants         = Constants,
    Math              = MathUtils,
    Spring            = SpringPhysics,
    SpringAnimations  = SpringAnimations,
}
