--[[
    LiquidGlass Pro - Advanced Liquid Glass UI for Roblox
    Version 2.0.0 (FIXED)
]]

--// ═══════════════════════════════════════════════════════════════════════════════
--// SECTION 1: SERVICES
--// ═══════════════════════════════════════════════════════════════════════════════

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local function getService(serviceName: string): any
	local success, service = pcall(function()
		return game:GetService(serviceName)
	end)
	return success and service or nil
end

local CoreGui = getService("CoreGui")
local LocalPlayer = Players.LocalPlayer

--// ═══════════════════════════════════════════════════════════════════════════════
--// SECTION 2: TYPE DEFINITIONS
--// ═══════════════════════════════════════════════════════════════════════════════

export type Vector2Like = { X: number, Y: number }
export type ColorInput = Color3 | string | { R: number, G: number, B: number }

export type GradientStop = {
	Position: number,
	Color: Color3,
	Transparency: number?,
}

export type SpringConfig = {
	Tension: number,
	Friction: number,
	Mass: number?,
	Precision: number?,
	Velocity: number?,
	Clamp: boolean?,
}

export type EasingConfig = {
	Style: Enum.EasingStyle?,
	Direction: Enum.EasingDirection?,
	Duration: number?,
}

export type TweenConfig = {
	Duration: number,
	Style: Enum.EasingStyle?,
	Direction: Enum.EasingDirection?,
	RepeatCount: number?,
	Reverses: boolean?,
	DelayTime: number?,
}

export type ChromaticConfig = {
	Enabled: boolean,
	Intensity: number,
	EdgeOnly: boolean,
	RedOffset: Vector2,
	GreenOffset: Vector2,
	BlueOffset: Vector2,
	Opacity: number,
}

export type RefractionConfig = {
	Enabled: boolean,
	Intensity: number,
	EdgeWidth: number,
	Layers: number,
	FalloffExponent: number,
}

export type FrostConfig = {
	Enabled: boolean,
	Intensity: number,
	NoiseScale: number,
	NoiseOpacity: number,
	Layers: number,
	Tint: Color3,
	TintOpacity: number,
}

export type BorderGradientConfig = {
	Enabled: boolean,
	BaseRotation: number,
	MouseInfluence: number,
	Colors: { GradientStop },
	Thickness: number,
	AnimationSpeed: number,
}

export type DepthConfig = {
	Enabled: boolean,
	TopGlowColor: Color3,
	TopGlowOpacity: number,
	TopGlowSize: number,
	BottomShadowColor: Color3,
	BottomShadowOpacity: number,
	BottomShadowSize: number,
	InnerGlowColor: Color3,
	InnerGlowOpacity: number,
	InnerGlowSize: number,
}

export type InteractionConfig = {
	Enabled: boolean,
	HoverScale: number,
	PressScale: number,
	ElasticEnabled: boolean,
	ElasticIntensity: number,
	ElasticFollow: boolean,
	FollowIntensity: number,
	ContentFollowIntensity: number,
	FollowSpring: SpringConfig?,
	GlowOnHover: boolean,
	HoverGlowIntensity: number,
}

export type BackgroundConfig = {
	Color: Color3,
	Transparency: number,
	GradientEnabled: boolean,
	GradientColors: { GradientStop }?,
	GradientRotation: number?,
}

export type ShadowConfig = {
	Enabled: boolean,
	Color: Color3,
	Transparency: number,
	Offset: Vector2,
	Spread: number,
	Blur: number,
}

export type LiquidGlassConfig = {
	Size: UDim2,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	CornerRadius: UDim?,
	ZIndex: number?,
	Name: string?,
	Parent: Instance?,
	Background: BackgroundConfig?,
	Shadow: ShadowConfig?,
	Chromatic: ChromaticConfig?,
	Refraction: RefractionConfig?,
	Frost: FrostConfig?,
	BorderGradient: BorderGradientConfig?,
	Depth: DepthConfig?,
	Interaction: InteractionConfig?,
	Spring: any?,
	InnerGlow: any?,
	DefaultSpring: SpringConfig?,
	DefaultTween: TweenConfig?,
	Content: { Instance }?,
	onClick: (() -> ())?,
	onHover: (() -> ())?,
	onHoverEnd: (() -> ())?,
	onPress: (() -> ())?,
	onRelease: (() -> ())?,
	OnHoverStart: (() -> ())?,
	OnHoverEnd: (() -> ())?,
	OnPress: (() -> ())?,
	OnRelease: (() -> ())?,
	OnMouseMove: ((position: Vector2) -> ())?,
}

export type ComponentState = {
	IsHovered: boolean,
	IsPressed: boolean,
	MousePosition: Vector2,
	MouseOffset: Vector2,
	SpringState: { Position: Vector2, Velocity: Vector2 },
	GradientRotation: number,
	Connections: { RBXScriptConnection },
	TweensActive: { Tween },
}

export type LayerRefs = {
	Root: Frame,
	Background: Frame?,
	FrostLayers: { Frame }?,
	RefractionLayers: { Frame }?,
	ChromaticLayers: { Red: Frame?, Green: Frame?, Blue: Frame? }?,
	BorderFrame: Frame?,
	BorderGradient: UIGradient?,
	BorderStroke: UIStroke?,
	DepthTop: Frame?,
	DepthBottom: Frame?,
	InnerGlow: Frame?,
	ContentContainer: Frame?,
	Shadow: ImageLabel?,
}

--// ═══════════════════════════════════════════════════════════════════════════════
--// SECTION 3: CONSTANTS
--// ═══════════════════════════════════════════════════════════════════════════════

local Constants = {}

Constants.VERSION = "2.0.0"
Constants.BUILD_DATE = "2025-01-28"

Constants.Math = {
	PI = math.pi,
	TAU = math.pi * 2,
	HALF_PI = math.pi / 2,
	DEG_TO_RAD = math.pi / 180,
	RAD_TO_DEG = 180 / math.pi,
	EPSILON = 1e-6,
	GOLDEN_RATIO = 1.618033988749895,
}

Constants.Timing = {
	FRAME_TIME = 1 / 60,
	SPRING_STEP = 1 / 120,
	DEBOUNCE_DEFAULT = 0.1,
	ANIMATION_FAST = 0.15,
	ANIMATION_NORMAL = 0.25,
	ANIMATION_SLOW = 0.4,
	ANIMATION_VERY_SLOW = 0.6,
}

Constants.Springs = {
	Snappy = { Tension = 300, Friction = 30, Mass = 1, Precision = 0.01 } :: SpringConfig,
	Default = { Tension = 170, Friction = 26, Mass = 1, Precision = 0.01 } :: SpringConfig,
	Smooth = { Tension = 120, Friction = 20, Mass = 1, Precision = 0.01 } :: SpringConfig,
	Bouncy = { Tension = 200, Friction = 12, Mass = 1, Precision = 0.01 } :: SpringConfig,
	Stiff = { Tension = 400, Friction = 40, Mass = 1, Precision = 0.01 } :: SpringConfig,
	Elastic = { Tension = 150, Friction = 18, Mass = 1, Precision = 0.005 } :: SpringConfig,
}

Constants.Tweens = {
	Fast = { Duration = 0.15, Style = Enum.EasingStyle.Quart, Direction = Enum.EasingDirection.Out } :: TweenConfig,
	Normal = { Duration = 0.25, Style = Enum.EasingStyle.Quart, Direction = Enum.EasingDirection.Out } :: TweenConfig,
	Slow = { Duration = 0.4, Style = Enum.EasingStyle.Quart, Direction = Enum.EasingDirection.Out } :: TweenConfig,
	Bounce = { Duration = 0.5, Style = Enum.EasingStyle.Bounce, Direction = Enum.EasingDirection.Out } :: TweenConfig,
	Elastic = { Duration = 0.6, Style = Enum.EasingStyle.Elastic, Direction = Enum.EasingDirection.Out } :: TweenConfig,
	Linear = { Duration = 0.3, Style = Enum.EasingStyle.Linear, Direction = Enum.EasingDirection.InOut } :: TweenConfig,
}

Constants.Colors = {
	Glass = {
		Clear = Color3.fromRGB(255, 255, 255),
		Frosted = Color3.fromRGB(240, 244, 248),
		Tinted = Color3.fromRGB(200, 220, 255),
		Dark = Color3.fromRGB(30, 30, 40),
	},
	Chromatic = {
		Red = Color3.fromRGB(255, 0, 0),
		Green = Color3.fromRGB(0, 255, 0),
		Blue = Color3.fromRGB(0, 0, 255),
		RedAdjusted = Color3.fromRGB(255, 100, 100),
		GreenAdjusted = Color3.fromRGB(100, 255, 100),
		BlueAdjusted = Color3.fromRGB(100, 100, 255),
	},
	Glow = {
		White = Color3.fromRGB(255, 255, 255),
		Warm = Color3.fromRGB(255, 248, 240),
		Cool = Color3.fromRGB(240, 248, 255),
		Accent = Color3.fromRGB(100, 200, 255),
	},
	Shadow = {
		Soft = Color3.fromRGB(0, 0, 0),
		Blue = Color3.fromRGB(20, 40, 80),
		Purple = Color3.fromRGB(40, 20, 80),
	},
	Border = {
		Transparent = Color3.fromRGB(255, 255, 255),
		Highlight = Color3.fromRGB(255, 255, 255),
		Bright = Color3.fromRGB(255, 255, 255),
	},
}

Constants.Defaults = {
	Chromatic = {
		Enabled = true, Intensity = 3, EdgeOnly = true,
		RedOffset = Vector2.new(-2, 0), GreenOffset = Vector2.new(0, 0),
		BlueOffset = Vector2.new(2, 0), Opacity = 0.15,
	} :: ChromaticConfig,

	Refraction = {
		Enabled = true, Intensity = 8, EdgeWidth = 20,
		Layers = 4, FalloffExponent = 2,
	} :: RefractionConfig,

	Frost = {
		Enabled = true, Intensity = 0.6, NoiseScale = 2, NoiseOpacity = 0.08,
		Layers = 3, Tint = Color3.fromRGB(255, 255, 255), TintOpacity = 0.1,
	} :: FrostConfig,

	BorderGradient = {
		Enabled = true, BaseRotation = 135, MouseInfluence = 1.2,
		Colors = {
			{ Position = 0, Color = Color3.fromRGB(255, 255, 255), Transparency = 0.95 },
			{ Position = 0.3, Color = Color3.fromRGB(255, 255, 255), Transparency = 0.7 },
			{ Position = 0.5, Color = Color3.fromRGB(255, 255, 255), Transparency = 0.4 },
			{ Position = 0.7, Color = Color3.fromRGB(255, 255, 255), Transparency = 0.7 },
			{ Position = 1, Color = Color3.fromRGB(255, 255, 255), Transparency = 0.95 },
		},
		Thickness = 1.5, AnimationSpeed = 1,
	} :: BorderGradientConfig,

	Depth = {
		Enabled = true,
		TopGlowColor = Color3.fromRGB(255, 255, 255), TopGlowOpacity = 0.2, TopGlowSize = 30,
		BottomShadowColor = Color3.fromRGB(0, 0, 0), BottomShadowOpacity = 0.1, BottomShadowSize = 20,
		InnerGlowColor = Color3.fromRGB(255, 255, 255), InnerGlowOpacity = 0.05, InnerGlowSize = 10,
	} :: DepthConfig,

	Interaction = {
		Enabled = true, HoverScale = 1.02, PressScale = 0.98,
		ElasticEnabled = true, ElasticIntensity = 8,
		ElasticFollow = true, FollowIntensity = 8, ContentFollowIntensity = 8,
		FollowSpring = Constants.Springs.Elastic,
		GlowOnHover = true, HoverGlowIntensity = 1.3,
	} :: InteractionConfig,

	Background = {
		Color = Color3.fromRGB(255, 255, 255), Transparency = 0.85, GradientEnabled = true,
		GradientColors = {
			{ Position = 0, Color = Color3.fromRGB(255, 255, 255), Transparency = 0.82 },
			{ Position = 1, Color = Color3.fromRGB(240, 245, 250), Transparency = 0.88 },
		},
		GradientRotation = 180,
	} :: BackgroundConfig,

	Shadow = {
		Enabled = true, Color = Color3.fromRGB(0, 0, 30), Transparency = 0.7,
		Offset = Vector2.new(0, 8), Spread = 20, Blur = 30,
	} :: ShadowConfig,

	Spring = {
		Position = Constants.Springs.Elastic,
		Scale = Constants.Springs.Snappy,
		Rotation = Constants.Springs.Smooth,
	},

	InnerGlow = {
		Color = Color3.fromRGB(255, 255, 255),
		Opacity = 0.05,
		Size = 10,
	},
}

Constants.ZOrder = {
	Shadow = 0, Background = 10, FrostBase = 20, FrostLayers = 25,
	RefractionBase = 30, RefractionLayers = 35,
	ChromaticRed = 40, ChromaticGreen = 41, ChromaticBlue = 42,
	DepthBottom = 50, DepthTop = 51, InnerGlow = 55, Border = 60,
	ContentContainer = 100,
}

Constants.NoiseTexture = { Seed = 12345, Octaves = 3, Persistence = 0.5, Scale = 1 }

--// ═══════════════════════════════════════════════════════════════════════════════
--// SECTION 4: MATH UTILITIES
--// ═══════════════════════════════════════════════════════════════════════════════

local MathUtils = {}

function MathUtils.Clamp(value, min, max) return math.max(min, math.min(max, value)) end
function MathUtils.Lerp(a, b, t) return a + (b - a) * t end

function MathUtils.InverseLerp(a, b, value)
	if math.abs(b - a) < Constants.Math.EPSILON then return 0 end
	return (value - a) / (b - a)
end

function MathUtils.Remap(value, inMin, inMax, outMin, outMax)
	local t = MathUtils.InverseLerp(inMin, inMax, value)
	return MathUtils.Lerp(outMin, outMax, t)
end

function MathUtils.Smoothstep(edge0, edge1, x)
	local t = MathUtils.Clamp((x - edge0) / (edge1 - edge0), 0, 1)
	return t * t * (3 - 2 * t)
end

function MathUtils.Smootherstep(edge0, edge1, x)
	local t = MathUtils.Clamp((x - edge0) / (edge1 - edge0), 0, 1)
	return t * t * t * (t * (t * 6 - 15) + 10)
end

function MathUtils.LerpVector2(a, b, t)
	return Vector2.new(MathUtils.Lerp(a.X, b.X, t), MathUtils.Lerp(a.Y, b.Y, t))
end

function MathUtils.LerpColor3(a, b, t)
	return Color3.new(MathUtils.Lerp(a.R, b.R, t), MathUtils.Lerp(a.G, b.G, t), MathUtils.Lerp(a.B, b.B, t))
end

function MathUtils.ExpDecay(current, target, decay, dt)
	return target + (current - target) * math.exp(-decay * dt)
end

function MathUtils.NormalizeToCenter(value, size)
	return (value / size) * 2 - 1
end

function MathUtils.GetNormalizedOffset(localPos, elementSize)
	return Vector2.new(
		MathUtils.NormalizeToCenter(localPos.X, elementSize.X),
		MathUtils.NormalizeToCenter(localPos.Y, elementSize.Y)
	)
end

function MathUtils.SeededRandom(seed)
	local x = math.sin(seed * 12.9898) * 43758.5453
	return x - math.floor(x)
end

function MathUtils.Hash2D(x, y)
	local seed = x * 374761393 + y * 668265263
	return MathUtils.SeededRandom(seed)
end

function MathUtils.ValueNoise2D(x, y)
	local xi, yi = math.floor(x), math.floor(y)
	local xf, yf = x - xi, y - yi
	local c00 = MathUtils.Hash2D(xi, yi)
	local c10 = MathUtils.Hash2D(xi + 1, yi)
	local c01 = MathUtils.Hash2D(xi, yi + 1)
	local c11 = MathUtils.Hash2D(xi + 1, yi + 1)
	local sx = MathUtils.Smoothstep(0, 1, xf)
	local sy = MathUtils.Smoothstep(0, 1, yf)
	local nx0 = MathUtils.Lerp(c00, c10, sx)
	local nx1 = MathUtils.Lerp(c01, c11, sx)
	return MathUtils.Lerp(nx0, nx1, sy)
end

function MathUtils.Magnitude(v)
	return math.sqrt(v.X * v.X + v.Y * v.Y)
end

function MathUtils.Normalize(v)
	local mag = MathUtils.Magnitude(v)
	if mag < Constants.Math.EPSILON then return Vector2.new(0, 0) end
	return Vector2.new(v.X / mag, v.Y / mag)
end

function MathUtils.Dot(a, b)
	return a.X * b.X + a.Y * b.Y
end

--// ═══════════════════════════════════════════════════════════════════════════════
--// SECTION 5: COLOR UTILITIES
--// ═══════════════════════════════════════════════════════════════════════════════

local ColorUtils = {}

function ColorUtils.AdjustBrightness(color, factor)
	return Color3.new(
		MathUtils.Clamp(color.R * factor, 0, 1),
		MathUtils.Clamp(color.G * factor, 0, 1),
		MathUtils.Clamp(color.B * factor, 0, 1)
	)
end

function ColorUtils.HexToColor3(hex)
	hex = hex:gsub("#", "")
	local r = tonumber(hex:sub(1, 2), 16) or 255
	local g = tonumber(hex:sub(3, 4), 16) or 255
	local b = tonumber(hex:sub(5, 6), 16) or 255
	return Color3.fromRGB(r, g, b)
end

--// ═══════════════════════════════════════════════════════════════════════════════
--// SECTION 6: GRADIENT UTILITIES
--// ═══════════════════════════════════════════════════════════════════════════════

local GradientUtils = {}

function GradientUtils.CreateLinearGradient(colors, rotation)
	local colorKeypoints = {}
	local transparencyKeypoints = {}
	for _, stop in ipairs(colors) do
		table.insert(colorKeypoints, ColorSequenceKeypoint.new(stop.Position, stop.Color))
		table.insert(transparencyKeypoints, NumberSequenceKeypoint.new(stop.Position, stop.Transparency or 0))
	end
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(colorKeypoints)
	gradient.Transparency = NumberSequence.new(transparencyKeypoints)
	gradient.Rotation = rotation or 0
	return gradient
end

function GradientUtils.CreateRadialGradient(centerColor, edgeColor, centerTransparency, edgeTransparency)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, edgeColor),
		ColorSequenceKeypoint.new(0.5, centerColor),
		ColorSequenceKeypoint.new(1, edgeColor),
	})
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, edgeTransparency),
		NumberSequenceKeypoint.new(0.5, centerTransparency),
		NumberSequenceKeypoint.new(1, edgeTransparency),
	})
	return gradient
end

function GradientUtils.CreateDynamicBorderGradient(config)
	local colorKeypoints = {}
	local transparencyKeypoints = {}
	for _, stop in ipairs(config.Colors) do
		table.insert(colorKeypoints, ColorSequenceKeypoint.new(stop.Position, stop.Color))
		table.insert(transparencyKeypoints, NumberSequenceKeypoint.new(stop.Position, stop.Transparency or 0))
	end
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(colorKeypoints)
	gradient.Transparency = NumberSequence.new(transparencyKeypoints)
	gradient.Rotation = config.BaseRotation
	return gradient
end

function GradientUtils.CreateTopGlowGradient(glowColor, opacity, size)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(glowColor)
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1 - opacity),
		NumberSequenceKeypoint.new(size, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Rotation = 180
	return gradient
end

function GradientUtils.CreateBottomShadowGradient(shadowColor, opacity, size)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(shadowColor)
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1 - size, 1),
		NumberSequenceKeypoint.new(1, 1 - opacity),
	})
	gradient.Rotation = 180
	return gradient
end

function GradientUtils.CreateInnerGlowGradient(glowColor, opacity)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(glowColor)
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1 - opacity),
		NumberSequenceKeypoint.new(0.3, 1),
		NumberSequenceKeypoint.new(0.7, 1),
		NumberSequenceKeypoint.new(1, 1 - opacity),
	})
	return gradient
end

function GradientUtils.CreateEdgeOnlyGradient(edgeWidth, edgeOpacity)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.new(1, 1, 1))
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1 - edgeOpacity),
		NumberSequenceKeypoint.new(edgeWidth, 1),
		NumberSequenceKeypoint.new(1 - edgeWidth, 1),
		NumberSequenceKeypoint.new(1, 1 - edgeOpacity),
	})
	return gradient
end

function GradientUtils.CreateFrostGradient(tint, opacity)
	local gradient = Instance.new("UIGradient")
	local lightTint = ColorUtils.AdjustBrightness(tint, 1.1)
	local darkTint = ColorUtils.AdjustBrightness(tint, 0.95)
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, lightTint),
		ColorSequenceKeypoint.new(0.5, tint),
		ColorSequenceKeypoint.new(1, darkTint),
	})
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1 - opacity * 0.9),
		NumberSequenceKeypoint.new(0.5, 1 - opacity),
		NumberSequenceKeypoint.new(1, 1 - opacity * 0.95),
	})
	gradient.Rotation = 180
	return gradient
end

--// ═══════════════════════════════════════════════════════════════════════════════
--// SECTION 7: ANIMATION UTILITIES
--// ═══════════════════════════════════════════════════════════════════════════════

local AnimationUtils = {}

function AnimationUtils.CreateTweenInfo(config)
	return TweenInfo.new(
		config.Duration,
		config.Style or Enum.EasingStyle.Quart,
		config.Direction or Enum.EasingDirection.Out,
		config.RepeatCount or 0,
		config.Reverses or false,
		config.DelayTime or 0
	)
end

function AnimationUtils.Tween(instance, properties, config)
	local tweenInfo = AnimationUtils.CreateTweenInfo(config)
	local tween = TweenService:Create(instance, tweenInfo, properties)
	tween:Play()
	return tween
end

--// ═══════════════════════════════════════════════════════════════════════════════
--// SECTION 8: SPRING PHYSICS
--// ═══════════════════════════════════════════════════════════════════════════════

local SpringPhysics = {}

export type SpringState = { Position: number, Velocity: number, Target: number, AtRest: boolean }
export type Spring2DState = { Position: Vector2, Velocity: Vector2, Target: Vector2, AtRest: boolean }

function SpringPhysics.Create(initialPosition, config)
	return {
		Position = initialPosition,
		Velocity = config and config.Velocity or 0,
		Target = initialPosition,
		AtRest = true,
	}
end

function SpringPhysics.Create2D(initialPosition, config)
	return {
		Position = initialPosition,
		Velocity = Vector2.new(0, 0),
		Target = initialPosition,
		AtRest = true,
	}
end

function SpringPhysics.SetTarget(spring, target)
	spring.Target = target
	spring.AtRest = false
end

function SpringPhysics.SetTarget2D(spring, target)
	spring.Target = target
	spring.AtRest = false
end

function SpringPhysics.Step(spring, config, dt)
	if spring.AtRest then return true end
	local tension = config.Tension
	local friction = config.Friction
	local mass = config.Mass or 1
	local precision = config.Precision or 0.01
	local displacement = spring.Position - spring.Target
	local springForce = -tension * displacement
	local dampingForce = -friction * spring.Velocity
	local acceleration = (springForce + dampingForce) / mass
	spring.Velocity = spring.Velocity + acceleration * dt
	spring.Position = spring.Position + spring.Velocity * dt
	local isAtRest = math.abs(spring.Velocity) < precision and math.abs(spring.Position - spring.Target) < precision
	if isAtRest then
		spring.Position = spring.Target
		spring.Velocity = 0
		spring.AtRest = true
	end
	return spring.AtRest
end

function SpringPhysics.Step2D(spring, config, dt)
	if spring.AtRest then return true end
	local tension = config.Tension
	local friction = config.Friction
	local mass = config.Mass or 1
	local precision = config.Precision or 0.01
	local dx = spring.Position.X - spring.Target.X
	local dy = spring.Position.Y - spring.Target.Y
	local fx = -tension * dx - friction * spring.Velocity.X
	local fy = -tension * dy - friction * spring.Velocity.Y
	local ax = fx / mass
	local ay = fy / mass
	spring.Velocity = Vector2.new(spring.Velocity.X + ax * dt, spring.Velocity.Y + ay * dt)
	spring.Position = Vector2.new(
		spring.Position.X + spring.Velocity.X * dt,
		spring.Position.Y + spring.Velocity.Y * dt
	)
	local vMag = MathUtils.Magnitude(spring.Velocity)
	local dMag = MathUtils.Magnitude(spring.Position - spring.Target)
	if vMag < precision and dMag < precision then
		spring.Position = spring.Target
		spring.Velocity = Vector2.new(0, 0)
		spring.AtRest = true
	end
	return spring.AtRest
end

--// ═══════════════════════════════════════════════════════════════════════════════
--// SECTION 9: INSTANCE UTILITIES
--// ═══════════════════════════════════════════════════════════════════════════════

local InstanceUtils = {}

function InstanceUtils.CreateFrame(properties)
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BorderSizePixel = 0
	if properties then
		for key, value in pairs(properties) do
			(frame :: any)[key] = value
		end
	end
	return frame
end

function InstanceUtils.CreateCorner(radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	return corner
end

function InstanceUtils.CreateStroke(properties)
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = 1
	if properties then
		for key, value in pairs(properties) do
			(stroke :: any)[key] = value
		end
	end
	return stroke
end

function InstanceUtils.ApplyCorner(frame, radius)
	local corner = InstanceUtils.CreateCorner(radius)
	corner.Parent = frame
	return corner
end

function InstanceUtils.SetProperties(instance, properties)
	for key, value in pairs(properties) do
		(instance :: any)[key] = value
	end
end

function InstanceUtils.SafeDestroy(instance)
	if instance then instance:Destroy() end
end

function InstanceUtils.CreateGlassContainer(size, position, cornerRadius)
	local container = InstanceUtils.CreateFrame({
		Name = "LiquidGlassContainer",
		Size = size,
		Position = position or UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	})
	local corner = InstanceUtils.CreateCorner(cornerRadius or UDim.new(0, 16))
	corner.Parent = container
	return container, corner
end

--// ═══════════════════════════════════════════════════════════════════════════════
--// SECTION 10: FROST LAYER SYSTEM
--// ═══════════════════════════════════════════════════════════════════════════════

local FrostLayerBuilder = {}

function FrostLayerBuilder.CreateBaseTintLayer(parent, config, cornerRadius)
	local baseTint = InstanceUtils.CreateFrame({
		Name = "FrostBaseTint",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundColor3 = config.Tint,
		BackgroundTransparency = 1 - config.TintOpacity,
		ZIndex = Constants.ZOrder.FrostBase,
		Parent = parent,
	})
	InstanceUtils.ApplyCorner(baseTint, cornerRadius)
	local tintGradient = GradientUtils.CreateFrostGradient(config.Tint, config.TintOpacity)
	tintGradient.Parent = baseTint
	return baseTint
end

function FrostLayerBuilder.CreateNoiseLayers(parent, config, cornerRadius)
	local noiseLayers = {}
	local layerCount = config.Layers or 3
	local rotations = { 0, 45, 90, 135, 22.5, 67.5 }

	for i = 1, layerCount do
		local noiseLayer = InstanceUtils.CreateFrame({
			Name = "FrostNoise_" .. i,
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromScale(0, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0,
			ZIndex = Constants.ZOrder.FrostLayers + i,
			Parent = parent,
		})
		InstanceUtils.ApplyCorner(noiseLayer, cornerRadius)

		local rotation = rotations[((i - 1) % #rotations) + 1]
		local noiseGradient = Instance.new("UIGradient")
		local stops = math.min(8, 4 + i)
		local colorKeypoints = {}
		local transparencyKeypoints = {}

		for j = 0, stops do
			local position = j / stops
			local noiseValue = MathUtils.SeededRandom(Constants.NoiseTexture.Seed + i * 1000 + j * 100)
			local brightness = 0.95 + noiseValue * 0.1
			table.insert(colorKeypoints, ColorSequenceKeypoint.new(position, Color3.new(brightness, brightness, brightness)))
			local baseTransparency = 1 - config.NoiseOpacity
			local transparencyVariation = noiseValue * config.NoiseOpacity * 0.5
			table.insert(transparencyKeypoints, NumberSequenceKeypoint.new(
				position, MathUtils.Clamp(baseTransparency + transparencyVariation, 0.5, 1)
			))
		end

		noiseGradient.Color = ColorSequence.new(colorKeypoints)
		noiseGradient.Transparency = NumberSequence.new(transparencyKeypoints)
		noiseGradient.Rotation = rotation
		noiseGradient.Parent = noiseLayer
		table.insert(noiseLayers, noiseLayer)
	end

	return noiseLayers
end

function FrostLayerBuilder.CreateTopGlowLayer(parent, config, cornerRadius)
	local topGlow = InstanceUtils.CreateFrame({
		Name = "FrostTopGlow",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundColor3 = config.TopGlowColor,
		BackgroundTransparency = 0,
		ZIndex = Constants.ZOrder.DepthTop,
		Parent = parent,
	})
	InstanceUtils.ApplyCorner(topGlow, cornerRadius)
	local glowSize = config.TopGlowSize / 100
	glowSize = MathUtils.Clamp(glowSize, 0.1, 0.5)
	local glowGradient = GradientUtils.CreateTopGlowGradient(config.TopGlowColor, config.TopGlowOpacity, glowSize)
	glowGradient.Parent = topGlow
	return topGlow
end

function FrostLayerBuilder.CreateBottomShadowLayer(parent, config, cornerRadius)
	local bottomShadow = InstanceUtils.CreateFrame({
		Name = "FrostBottomShadow",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundColor3 = config.BottomShadowColor,
		BackgroundTransparency = 0,
		ZIndex = Constants.ZOrder.DepthBottom,
		Parent = parent,
	})
	InstanceUtils.ApplyCorner(bottomShadow, cornerRadius)
	local shadowSize = config.BottomShadowSize / 100
	shadowSize = MathUtils.Clamp(shadowSize, 0.05, 0.3)
	local shadowGradient = GradientUtils.CreateBottomShadowGradient(config.BottomShadowColor, config.BottomShadowOpacity, shadowSize)
	shadowGradient.Parent = bottomShadow
	return bottomShadow
end

function FrostLayerBuilder.BuildFrostLayers(parent, frostConfig, depthConfig, cornerRadius)
	local layers = { BaseTint = nil, NoiseLayers = {}, TopGlow = nil, BottomShadow = nil }
	if not frostConfig.Enabled then return layers end
	layers.BaseTint = FrostLayerBuilder.CreateBaseTintLayer(parent, frostConfig, cornerRadius)
	layers.NoiseLayers = FrostLayerBuilder.CreateNoiseLayers(parent, frostConfig, cornerRadius)
	if depthConfig.Enabled then
		layers.TopGlow = FrostLayerBuilder.CreateTopGlowLayer(parent, depthConfig, cornerRadius)
		layers.BottomShadow = FrostLayerBuilder.CreateBottomShadowLayer(parent, depthConfig, cornerRadius)
	end
	return layers
end

--// ═══════════════════════════════════════════════════════════════════════════════
--// SECTION 11: CHROMATIC ABERRATION LAYER SYSTEM
--// ═══════════════════════════════════════════════════════════════════════════════

local ChromaticLayerBuilder = {}

function ChromaticLayerBuilder.CreateChannelLayer(parent, channel, config, cornerRadius)
	local color, offset, zIndex

	if channel == "Red" then
		color = Constants.Colors.Chromatic.RedAdjusted
		offset = config.RedOffset
		zIndex = Constants.ZOrder.ChromaticRed
	elseif channel == "Green" then
		color = Constants.Colors.Chromatic.GreenAdjusted
		offset = config.GreenOffset
		zIndex = Constants.ZOrder.ChromaticGreen
	else
		color = Constants.Colors.Chromatic.BlueAdjusted
		offset = config.BlueOffset
		zIndex = Constants.ZOrder.ChromaticBlue
	end

	offset = Vector2.new(offset.X * config.Intensity, offset.Y * config.Intensity)

	local channelLayer = InstanceUtils.CreateFrame({
		Name = "Chromatic" .. channel,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(offset.X, offset.Y),
		BackgroundColor3 = color,
		BackgroundTransparency = 0,
		ZIndex = zIndex,
		Parent = parent,
	})
	InstanceUtils.ApplyCorner(channelLayer, cornerRadius)

	if config.EdgeOnly then
		local edgeGradient = GradientUtils.CreateEdgeOnlyGradient(0.15, config.Opacity)
		edgeGradient.Parent = channelLayer
	else
		channelLayer.BackgroundTransparency = 1 - config.Opacity
	end

	return channelLayer
end

function ChromaticLayerBuilder.CreateChromaticLayers(parent, config, cornerRadius)
	if not config.Enabled then return { Red = nil, Green = nil, Blue = nil } end
	return {
		Red = ChromaticLayerBuilder.CreateChannelLayer(parent, "Red", config, cornerRadius),
		Green = ChromaticLayerBuilder.CreateChannelLayer(parent, "Green", config, cornerRadius),
		Blue = ChromaticLayerBuilder.CreateChannelLayer(parent, "Blue", config, cornerRadius),
	}
end

function ChromaticLayerBuilder.UpdateOffsets(layers, mouseOffset, config, animate)
	if not config.Enabled then return end

	local mouseInfluence = config.Intensity * 1.5

	local redOffset = Vector2.new(
		config.RedOffset.X * config.Intensity + mouseOffset.X * mouseInfluence,
		config.RedOffset.Y * config.Intensity + mouseOffset.Y * mouseInfluence * 0.3
	)
	local greenOffset = Vector2.new(
		config.GreenOffset.X * config.Intensity,
		config.GreenOffset.Y * config.Intensity
	)
	local blueOffset = Vector2.new(
		config.BlueOffset.X * config.Intensity - mouseOffset.X * mouseInfluence * 0.5,
		config.BlueOffset.Y * config.Intensity - mouseOffset.Y * mouseInfluence * 0.3
	)

	local function applyOffset(layer, offset)
		if not layer then return end
		local newPosition = UDim2.fromOffset(offset.X, offset.Y)
		if animate then
			AnimationUtils.Tween(layer, { Position = newPosition }, {
				Duration = 0.1, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out,
			})
		else
			layer.Position = newPosition
		end
	end

	applyOffset(layers.Red, redOffset)
	applyOffset(layers.Green, greenOffset)
	applyOffset(layers.Blue, blueOffset)
end

--// ═══════════════════════════════════════════════════════════════════════════════
--// SECTION 12: REFRACTION LAYER SYSTEM
--// ═══════════════════════════════════════════════════════════════════════════════

local RefractionLayerBuilder = {}

function RefractionLayerBuilder.CreateEdgeRefractionLayer(parent, edge, layerIndex, config, cornerRadius)
	local edgeWidth = config.EdgeWidth
	local intensity = config.Intensity
	local falloff = config.FalloffExponent
	local depthFactor = 1 - ((layerIndex - 1) / config.Layers)
	local offsetAmount = intensity * depthFactor ^ falloff

	local size, position, gradientRotation

	if edge == "Top" then
		size = UDim2.new(1, 0, 0, edgeWidth)
		position = UDim2.new(0, 0, 0, -offsetAmount * layerIndex * 0.1)
		gradientRotation = 180
	elseif edge == "Bottom" then
		size = UDim2.new(1, 0, 0, edgeWidth)
		position = UDim2.new(0, 0, 1, -edgeWidth + offsetAmount * layerIndex * 0.1)
		gradientRotation = 0
	elseif edge == "Left" then
		size = UDim2.new(0, edgeWidth, 1, 0)
		position = UDim2.new(0, -offsetAmount * layerIndex * 0.1, 0, 0)
		gradientRotation = 90
	else
		size = UDim2.new(0, edgeWidth, 1, 0)
		position = UDim2.new(1, -edgeWidth + offsetAmount * layerIndex * 0.1, 0, 0)
		gradientRotation = 270
	end

	local refractionLayer = InstanceUtils.CreateFrame({
		Name = "Refraction" .. edge .. "_" .. layerIndex,
		Size = size,
		Position = position,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0,
		ZIndex = Constants.ZOrder.RefractionBase + layerIndex,
		ClipsDescendants = true,
		Parent = parent,
	})

	local corner = Instance.new("UICorner")
	corner.CornerRadius = cornerRadius
	corner.Parent = refractionLayer

	local opacity = 0.05 * depthFactor
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.new(1, 1, 1))
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1 - opacity),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Rotation = gradientRotation
	gradient.Parent = refractionLayer

	return refractionLayer
end

function RefractionLayerBuilder.BuildRefractionLayers(parent, config, cornerRadius)
	local layers = { Top = {}, Bottom = {}, Left = {}, Right = {} }
	if not config.Enabled then return layers end

	for _, edge in ipairs({"Top", "Bottom", "Left", "Right"}) do
		for i = 1, config.Layers do
			local layer = RefractionLayerBuilder.CreateEdgeRefractionLayer(parent, edge, i, config, cornerRadius)
			table.insert(layers[edge], layer)
		end
	end

	return layers
end

function RefractionLayerBuilder.UpdateRefraction(layers, mouseOffset, config)
	if not config.Enabled then return end

	local function updateEdgeLayers(edgeLayers, edgeIntensity)
		for i, layer in ipairs(edgeLayers) do
			local gradient = layer:FindFirstChildOfClass("UIGradient")
			if gradient then
				local baseOpacity = 0.05 * (1 - ((i - 1) / #edgeLayers))
				local adjustedOpacity = baseOpacity * (1 + edgeIntensity * 0.5)
				gradient.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1 - adjustedOpacity),
					NumberSequenceKeypoint.new(1, 1),
				})
			end
		end
	end

	updateEdgeLayers(layers.Top, math.max(0, -mouseOffset.Y))
	updateEdgeLayers(layers.Bottom, math.max(0, mouseOffset.Y))
	updateEdgeLayers(layers.Left, math.max(0, -mouseOffset.X))
	updateEdgeLayers(layers.Right, math.max(0, mouseOffset.X))
end

--// ═══════════════════════════════════════════════════════════════════════════════
--// SECTION 13: DYNAMIC BORDER SYSTEM
--// ═══════════════════════════════════════════════════════════════════════════════

local BorderLayerBuilder = {}

function BorderLayerBuilder.CreatePrimaryBorder(parent, config)
	local borderFrame = InstanceUtils.CreateFrame({
		Name = "BorderFrame",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundTransparency = 1,
		ZIndex = Constants.ZOrder.Border,
		Parent = parent,
	})

	local stroke = InstanceUtils.CreateStroke({
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = config.Thickness,
		Color = Color3.new(1, 1, 1),
		Transparency = 0,
		Parent = borderFrame,
	})

	local gradient = GradientUtils.CreateDynamicBorderGradient(config)
	gradient.Parent = stroke

	local existingCorner = parent:FindFirstChildOfClass("UICorner")
	if existingCorner then
		local borderCorner = Instance.new("UICorner")
		borderCorner.CornerRadius = existingCorner.CornerRadius
		borderCorner.Parent = borderFrame
	end

	return borderFrame, stroke, gradient
end

function BorderLayerBuilder.CreateSecondaryBorder(parent, config)
	local secondaryFrame = InstanceUtils.CreateFrame({
		Name = "SecondaryBorder",
		Size = UDim2.new(1, -4, 1, -4),
		Position = UDim2.fromOffset(2, 2),
		BackgroundTransparency = 1,
		ZIndex = Constants.ZOrder.Border - 1,
		Parent = parent,
	})

	local secondaryStroke = InstanceUtils.CreateStroke({
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = config.Thickness * 0.5,
		Color = Color3.new(1, 1, 1),
		Transparency = 0.85,
		Parent = secondaryFrame,
	})

	local existingCorner = parent:FindFirstChildOfClass("UICorner")
	if existingCorner then
		local borderCorner = Instance.new("UICorner")
		borderCorner.CornerRadius = UDim.new(
			existingCorner.CornerRadius.Scale,
			math.max(0, existingCorner.CornerRadius.Offset - 2)
		)
		borderCorner.Parent = secondaryFrame
	end

	return secondaryFrame, secondaryStroke
end

function BorderLayerBuilder.BuildBorderLayers(parent, config)
	local layers = {
		PrimaryFrame = nil, PrimaryStroke = nil, PrimaryGradient = nil,
		SecondaryFrame = nil, SecondaryStroke = nil,
	}
	if not config.Enabled then return layers end
	layers.PrimaryFrame, layers.PrimaryStroke, layers.PrimaryGradient =
		BorderLayerBuilder.CreatePrimaryBorder(parent, config)
	layers.SecondaryFrame, layers.SecondaryStroke =
		BorderLayerBuilder.CreateSecondaryBorder(parent, config)
	return layers
end

function BorderLayerBuilder.UpdateGradientRotation(gradient, mouseOffset, config, animate)
	if not gradient then return end

	local newRotation = config.BaseRotation + mouseOffset.X * config.MouseInfluence * 30
	newRotation = newRotation + mouseOffset.Y * config.MouseInfluence * 10

	if animate then
		local tweenInfo = TweenInfo.new(0.15 / config.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(gradient, tweenInfo, { Rotation = newRotation }):Play()
	else
		gradient.Rotation = newRotation
	end
end

--// ═══════════════════════════════════════════════════════════════════════════════
--// SECTION 14: SHADOW SYSTEM
--// ═══════════════════════════════════════════════════════════════════════════════

local ShadowLayerBuilder = {}

function ShadowLayerBuilder.CreateShadowLayer(parent, config, cornerRadius)
	local shadowFrame = InstanceUtils.CreateFrame({
		Name = "DropShadow",
		Size = UDim2.new(1, config.Spread * 2, 1, config.Spread * 2),
		Position = UDim2.new(0.5, config.Offset.X, 0.5, config.Offset.Y),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = config.Color,
		BackgroundTransparency = config.Transparency,
		ZIndex = Constants.ZOrder.Shadow,
		Parent = parent,
	})

	local shadowRadius = UDim.new(cornerRadius.Scale, cornerRadius.Offset + config.Blur * 0.3)
	InstanceUtils.ApplyCorner(shadowFrame, shadowRadius)

	local blurLayers = math.min(4, math.ceil(config.Blur / 10))
	for i = 1, blurLayers do
		local blurLayer = InstanceUtils.CreateFrame({
			Name = "ShadowBlur_" .. i,
			Size = UDim2.new(1, i * 4, 1, i * 4),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = config.Color,
			BackgroundTransparency = config.Transparency + i * 0.1,
			ZIndex = Constants.ZOrder.Shadow - i,
			Parent = shadowFrame,
		})
		InstanceUtils.ApplyCorner(blurLayer, UDim.new(shadowRadius.Scale, shadowRadius.Offset + i * 2))
	end

	return shadowFrame
end

function ShadowLayerBuilder.BuildShadowLayer(parent, config, cornerRadius)
	if not config.Enabled then return nil end
	return ShadowLayerBuilder.CreateShadowLayer(parent, config, cornerRadius)
end

function ShadowLayerBuilder.UpdateShadowOnHover(shadow, config, isHovered, duration)
	if not shadow then return end

	local tweenConfig = { Duration = duration, Style = Enum.EasingStyle.Quart, Direction = Enum.EasingDirection.Out }

	if isHovered then
		AnimationUtils.Tween(shadow, {
			Size = UDim2.new(1, config.Spread * 2.5, 1, config.Spread * 2.5),
			Position = UDim2.new(0.5, config.Offset.X, 0.5, config.Offset.Y + 4),
			BackgroundTransparency = config.Transparency * 0.9,
		}, tweenConfig)
	else
		AnimationUtils.Tween(shadow, {
			Size = UDim2.new(1, config.Spread * 2, 1, config.Spread * 2),
			Position = UDim2.new(0.5, config.Offset.X, 0.5, config.Offset.Y),
			BackgroundTransparency = config.Transparency,
		}, tweenConfig)
	end
end

--// ═══════════════════════════════════════════════════════════════════════════════
--// SECTION 15: HOVER EFFECT LAYERS
--// ═══════════════════════════════════════════════════════════════════════════════

local HoverLayerBuilder = {}

function HoverLayerBuilder.CreateHoverGlowLayer(parent, glowColor, maxOpacity, cornerRadius)
	local glowLayer = InstanceUtils.CreateFrame({
		Name = "HoverGlow",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundColor3 = glowColor,
		BackgroundTransparency = 1,
		ZIndex = Constants.ZOrder.InnerGlow,
		Parent = parent,
	})
	InstanceUtils.ApplyCorner(glowLayer, cornerRadius)
	local glowGradient = GradientUtils.CreateRadialGradient(glowColor, glowColor, 1, 1)
	glowGradient.Parent = glowLayer
	glowLayer:SetAttribute("MaxOpacity", maxOpacity)
	return glowLayer
end

function HoverLayerBuilder.CreatePressOverlay(parent, cornerRadius)
	local pressLayer = InstanceUtils.CreateFrame({
		Name = "PressOverlay",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = Constants.ZOrder.InnerGlow + 1,
		Parent = parent,
	})
	InstanceUtils.ApplyCorner(pressLayer, cornerRadius)
	return pressLayer
end

function HoverLayerBuilder.BuildHoverLayers(parent, glowColor, glowOpacity, cornerRadius)
	return {
		HoverGlow = HoverLayerBuilder.CreateHoverGlowLayer(parent, glowColor, glowOpacity, cornerRadius),
		PressOverlay = HoverLayerBuilder.CreatePressOverlay(parent, cornerRadius),
	}
end

function HoverLayerBuilder.UpdateHoverGlow(glow, mouseOffset, isVisible, duration)
	if not glow then return end
	local gradient = glow:FindFirstChildOfClass("UIGradient")
	if not gradient then return end

	local maxOpacity = glow:GetAttribute("MaxOpacity") or 0.15

	if isVisible then
		gradient.Offset = Vector2.new(mouseOffset.X * 0.3, mouseOffset.Y * 0.3)
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1 - maxOpacity),
			NumberSequenceKeypoint.new(0.5, 1 - maxOpacity * 0.5),
			NumberSequenceKeypoint.new(1, 1),
		})
	else
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
	end
end

--// ═══════════════════════════════════════════════════════════════════════════════
--// SECTION 16: CONTENT CONTAINER
--// ═══════════════════════════════════════════════════════════════════════════════

local ContentContainerBuilder = {}

function ContentContainerBuilder.CreateContentContainer(parent, cornerRadius)
	local container = InstanceUtils.CreateFrame({
		Name = "ContentContainer",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = Constants.ZOrder.ContentContainer,
		Parent = parent,
	})
	InstanceUtils.ApplyCorner(container, cornerRadius)

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = container

	return container
end

function ContentContainerBuilder.UpdateContentOffset(container, offset, intensity, animate)
	if not container then return end

	local offsetX = offset.X * intensity
	local offsetY = offset.Y * intensity
	local newPosition = UDim2.new(0.5, offsetX, 0.5, offsetY)

	if animate then
		AnimationUtils.Tween(container, { Position = newPosition }, {
			Duration = 0.2, Style = Enum.EasingStyle.Quart, Direction = Enum.EasingDirection.Out,
		})
	else
		container.Position = newPosition
	end
end

--// ═══════════════════════════════════════════════════════════════════════════════
--// SECTION 17: INNER GLOW LAYER
--// ═══════════════════════════════════════════════════════════════════════════════

local InnerGlowLayerBuilder = {}

function InnerGlowLayerBuilder.CreateInnerGlow(parent, config, cornerRadius)
	local innerGlow = InstanceUtils.CreateFrame({
		Name = "InnerGlow",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundColor3 = config.InnerGlowColor,
		BackgroundTransparency = 0,
		ZIndex = Constants.ZOrder.InnerGlow,
		Parent = parent,
	})
	InstanceUtils.ApplyCorner(innerGlow, cornerRadius)
	local glowGradient = GradientUtils.CreateInnerGlowGradient(config.InnerGlowColor, config.InnerGlowOpacity)
	glowGradient.Parent = innerGlow
	return innerGlow
end

--// ═══════════════════════════════════════════════════════════════════════════════
--// SECTION 18: BACKGROUND LAYER
--// ═══════════════════════════════════════════════════════════════════════════════

local BackgroundLayerBuilder = {}

function BackgroundLayerBuilder.CreateBackground(parent, config, cornerRadius)
	local background = InstanceUtils.CreateFrame({
		Name = "Background",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundColor3 = config.Color,
		BackgroundTransparency = config.Transparency,
		ZIndex = Constants.ZOrder.Background,
		Parent = parent,
	})
	InstanceUtils.ApplyCorner(background, cornerRadius)

	if config.GradientEnabled and config.GradientColors then
		local gradient = GradientUtils.CreateLinearGradient(config.GradientColors, config.GradientRotation)
		gradient.Parent = background
	end

	return background
end

--// ═══════════════════════════════════════════════════════════════════════════════
--// SECTION 19: COMPLETE LAYER BUILDER
--// ═══════════════════════════════════════════════════════════════════════════════

local LayerBuilder = {}

export type CompleteLayerRefs = {
	Root: Frame,
	Shadow: Frame?,
	Background: Frame?,
	FrostLayers: {
		BaseTint: Frame?,
		NoiseLayers: { Frame },
		TopGlow: Frame?,
		BottomShadow: Frame?,
	},
	ChromaticLayers: { Red: Frame?, Green: Frame?, Blue: Frame? },
	RefractionLayers: { Top: { Frame }, Bottom: { Frame }, Left: { Frame }, Right: { Frame } },
	BorderLayers: {
		PrimaryFrame: Frame?, PrimaryStroke: UIStroke?, PrimaryGradient: UIGradient?,
		SecondaryFrame: Frame?, SecondaryStroke: UIStroke?,
	},
	InnerGlow: Frame?,
	HoverLayers: { HoverGlow: Frame?, PressOverlay: Frame? },
	ContentContainer: Frame?,
	InputHandler: TextButton?,
	InputTracking: any?,
}

function LayerBuilder.BuildAllLayers(parent, config)
	local frostConfig = config.Frost or Constants.Defaults.Frost
	local depthConfig = config.Depth or Constants.Defaults.Depth
	local chromaticConfig = config.Chromatic or Constants.Defaults.Chromatic
	local refractionConfig = config.Refraction or Constants.Defaults.Refraction
	local borderConfig = config.BorderGradient or Constants.Defaults.BorderGradient
	local shadowConfig = config.Shadow or Constants.Defaults.Shadow
	local backgroundConfig = config.Background or Constants.Defaults.Background
	local interactionConfig = config.Interaction or Constants.Defaults.Interaction

	local cornerRadius = config.CornerRadius or UDim.new(0, 16)
	if typeof(cornerRadius) == "number" then
		cornerRadius = UDim.new(0, cornerRadius)
	end

	local refs = {
		Root = parent,
		Shadow = nil, Background = nil,
		FrostLayers = { BaseTint = nil, NoiseLayers = {}, TopGlow = nil, BottomShadow = nil },
		ChromaticLayers = { Red = nil, Green = nil, Blue = nil },
		RefractionLayers = { Top = {}, Bottom = {}, Left = {}, Right = {} },
		BorderLayers = {
			PrimaryFrame = nil, PrimaryStroke = nil, PrimaryGradient = nil,
			SecondaryFrame = nil, SecondaryStroke = nil,
		},
		InnerGlow = nil,
		HoverLayers = { HoverGlow = nil, PressOverlay = nil },
		ContentContainer = nil, InputHandler = nil, InputTracking = nil,
	}

	if shadowConfig.Enabled then
		refs.Shadow = ShadowLayerBuilder.BuildShadowLayer(parent, shadowConfig, cornerRadius)
	end

	refs.Background = BackgroundLayerBuilder.CreateBackground(parent, backgroundConfig, cornerRadius)
	refs.FrostLayers = FrostLayerBuilder.BuildFrostLayers(parent, frostConfig, depthConfig, cornerRadius)
	refs.RefractionLayers = RefractionLayerBuilder.BuildRefractionLayers(parent, refractionConfig, cornerRadius)
	refs.ChromaticLayers = ChromaticLayerBuilder.CreateChromaticLayers(parent, chromaticConfig, cornerRadius)

	if depthConfig.Enabled then
		refs.InnerGlow = InnerGlowLayerBuilder.CreateInnerGlow(parent, depthConfig, cornerRadius)
	end

	refs.BorderLayers = BorderLayerBuilder.BuildBorderLayers(parent, borderConfig)

	if interactionConfig.Enabled then
		refs.HoverLayers = HoverLayerBuilder.BuildHoverLayers(
			parent, depthConfig.InnerGlowColor, 0.15, cornerRadius
		)
	end

	refs.ContentContainer = ContentContainerBuilder.CreateContentContainer(parent, cornerRadius)

	-- Input handler
	local handler = Instance.new("TextButton")
	handler.Name = "InputHandler"
	handler.Size = UDim2.fromScale(1, 1)
	handler.Position = UDim2.fromScale(0, 0)
	handler.BackgroundTransparency = 1
	handler.Text = ""
	handler.AutoButtonColor = false
	handler.ZIndex = Constants.ZOrder.ContentContainer + 100
	handler.Parent = parent
	refs.InputHandler = handler

	return refs
end

function LayerBuilder.DestroyAllLayers(refs)
	if refs.InputTracking and refs.InputTracking.Destroy then
		refs.InputTracking.Destroy()
	end
	local function safeDestroy(instance)
		if instance then instance:Destroy() end
	end
	safeDestroy(refs.Shadow)
	safeDestroy(refs.Background)
	safeDestroy(refs.FrostLayers.BaseTint)
	safeDestroy(refs.FrostLayers.TopGlow)
	safeDestroy(refs.FrostLayers.BottomShadow)
	for _, layer in ipairs(refs.FrostLayers.NoiseLayers) do safeDestroy(layer) end
	safeDestroy(refs.ChromaticLayers.Red)
	safeDestroy(refs.ChromaticLayers.Green)
	safeDestroy(refs.ChromaticLayers.Blue)
	for _, layers in pairs(refs.RefractionLayers) do
		for _, layer in ipairs(layers) do safeDestroy(layer) end
	end
	safeDestroy(refs.BorderLayers.PrimaryFrame)
	safeDestroy(refs.BorderLayers.SecondaryFrame)
	safeDestroy(refs.InnerGlow)
	safeDestroy(refs.HoverLayers.HoverGlow)
	safeDestroy(refs.HoverLayers.PressOverlay)
	safeDestroy(refs.ContentContainer)
	safeDestroy(refs.InputHandler)
end

--// ═══════════════════════════════════════════════════════════════════════════════
--// SECTION 20: SPRING ANIMATIONS (FIXED)
--// ═══════════════════════════════════════════════════════════════════════════════

local SpringAnimations = {}

export type SpringAnimator = {
	Spring: any,
	Config: SpringConfig,
	IsVector: boolean,
}

function SpringAnimations.CreateAnimator(initialValue, config)
	local springConfig = config or Constants.Springs.Default
	local isVector = typeof(initialValue) == "Vector2"
	local spring
	if isVector then
		spring = SpringPhysics.Create2D(initialValue, springConfig)
	else
		spring = SpringPhysics.Create(initialValue, springConfig)
	end
	return { Spring = spring, Config = springConfig, IsVector = isVector }
end

function SpringAnimations.SetTarget(animator, target)
	if not animator then return end
	if animator.IsVector then
		SpringPhysics.SetTarget2D(animator.Spring, target)
	else
		SpringPhysics.SetTarget(animator.Spring, target)
	end
end

function SpringAnimations.Step(animator, dt)
	if not animator then return nil end
	if animator.IsVector then
		SpringPhysics.Step2D(animator.Spring, animator.Config, dt)
		return animator.Spring.Position
	else
		SpringPhysics.Step(animator.Spring, animator.Config, dt)
		return animator.Spring.Position
	end
end

--// ═══════════════════════════════════════════════════════════════════════════════
--// SECTION 21: LAYER UPDATE UTILITIES
--// ═══════════════════════════════════════════════════════════════════════════════

local LayerUpdateUtils = {}

function LayerUpdateUtils.UpdateAllOnMouse(refs, mouseOffset, config)
	local chromaticConfig = config.Chromatic or Constants.Defaults.Chromatic
	local borderConfig = config.BorderGradient or Constants.Defaults.BorderGradient
	local refractionConfig = config.Refraction or Constants.Defaults.Refraction
	local interactionConfig = config.Interaction or Constants.Defaults.Interaction

	ChromaticLayerBuilder.UpdateOffsets(refs.ChromaticLayers, mouseOffset, chromaticConfig, false)
	BorderLayerBuilder.UpdateGradientRotation(refs.BorderLayers.PrimaryGradient, mouseOffset, borderConfig, false)
	RefractionLayerBuilder.UpdateRefraction(refs.RefractionLayers, mouseOffset, refractionConfig)
	HoverLayerBuilder.UpdateHoverGlow(refs.HoverLayers.HoverGlow, mouseOffset, true, 0.1)
	ContentContainerBuilder.UpdateContentOffset(
		refs.ContentContainer, mouseOffset, interactionConfig.ContentFollowIntensity, false
	)
end

function LayerUpdateUtils.ResetAll(refs, config)
	local chromaticConfig = config.Chromatic or Constants.Defaults.Chromatic
	local borderConfig = config.BorderGradient or Constants.Defaults.BorderGradient
	local shadowConfig = config.Shadow or Constants.Defaults.Shadow

	ChromaticLayerBuilder.UpdateOffsets(refs.ChromaticLayers, Vector2.zero, chromaticConfig, true)
	BorderLayerBuilder.UpdateGradientRotation(refs.BorderLayers.PrimaryGradient, Vector2.zero, borderConfig, true)
	HoverLayerBuilder.UpdateHoverGlow(refs.HoverLayers.HoverGlow, Vector2.zero, false, 0.3)
	ShadowLayerBuilder.UpdateShadowOnHover(refs.Shadow, shadowConfig, false, 0.3)
	ContentContainerBuilder.UpdateContentOffset(refs.ContentContainer, Vector2.zero, 0, true)
end

--// ═══════════════════════════════════════════════════════════════════════════════
--// SECTION 22: LIQUIDGLASS CLASS
--// ═══════════════════════════════════════════════════════════════════════════════

export type LiquidGlassInstance = any

local LiquidGlass = {}
LiquidGlass.__index = LiquidGlass

function LiquidGlass.new(config)
	local self = setmetatable({}, LiquidGlass)
	local userConfig = config or {}
	self._config = LiquidGlass._mergeWithDefaults(userConfig)

	self._isHovered = false
	self._isPressed = false
	self._mouseOffset = Vector2.zero
	self._lastMousePosition = Vector2.zero
	self._connections = {}
	self._tweens = {}
	self._isDestroyed = false

	local springConfig = self._config.Spring or Constants.Defaults.Spring
	self._positionSpring = SpringAnimations.CreateAnimator(Vector2.zero, springConfig.Position)
	self._scaleSpring = SpringAnimations.CreateAnimator(Vector2.new(1, 1), springConfig.Scale)
	self._rotationSpring = SpringAnimations.CreateAnimator(0, springConfig.Rotation)

	self:_buildUI()
	self:_setupInteractions()
	self:_startUpdateLoop()

	if self._config.Parent then
		self._container.Parent = self._config.Parent
	end

	return self :: any
end

function LiquidGlass._mergeWithDefaults(userConfig)
	local defaults = Constants.Defaults

	local function deepMerge(default, user)
		if type(default) ~= "table" or type(user) ~= "table" then
			return if user ~= nil then user else default
		end
		local result = {}
		for key, defaultValue in pairs(default) do
			result[key] = deepMerge(defaultValue, user[key])
		end
		for key, userValue in pairs(user) do
			if result[key] == nil then
				result[key] = userValue
			end
		end
		return result
	end

	local merged = {
		Size = userConfig.Size or UDim2.fromOffset(200, 60),
		Position = userConfig.Position or UDim2.fromScale(0.5, 0.5),
		AnchorPoint = userConfig.AnchorPoint or Vector2.new(0.5, 0.5),
		CornerRadius = userConfig.CornerRadius or 16,
		ZIndex = userConfig.ZIndex or 1,
		Parent = userConfig.Parent,
		Name = userConfig.Name or "LiquidGlass",
		onClick = userConfig.onClick,
		onHover = userConfig.onHover,
		onHoverEnd = userConfig.onHoverEnd,
		onPress = userConfig.onPress,
		onRelease = userConfig.onRelease,
		Frost = deepMerge(defaults.Frost, userConfig.Frost or {}),
		Chromatic = deepMerge(defaults.Chromatic, userConfig.Chromatic or {}),
		Refraction = deepMerge(defaults.Refraction, userConfig.Refraction or {}),
		BorderGradient = deepMerge(defaults.BorderGradient, userConfig.BorderGradient or {}),
		Shadow = deepMerge(defaults.Shadow, userConfig.Shadow or {}),
		Depth = deepMerge(defaults.Depth, userConfig.Depth or {}),
		Interaction = deepMerge(defaults.Interaction, userConfig.Interaction or {}),
		Spring = deepMerge(defaults.Spring, userConfig.Spring or {}),
		InnerGlow = deepMerge(defaults.InnerGlow, userConfig.InnerGlow or {}),
		Background = deepMerge(defaults.Background, userConfig.Background or {}),
	}

	return merged
end

function LiquidGlass:_buildUI()
	local crValue = self._config.CornerRadius
	if typeof(crValue) == "number" then
		crValue = UDim.new(0, crValue)
	end

	local container = Instance.new("Frame")
	container.Name = self._config.Name or "LiquidGlass"
	container.Size = self._config.Size
	container.Position = self._config.Position
	container.AnchorPoint = self._config.AnchorPoint
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.ClipsDescendants = true
	container.ZIndex = self._config.ZIndex or 1

	local corner = Instance.new("UICorner")
	corner.CornerRadius = crValue
	corner.Parent = container

	self._container = container

	local layerRefs = LayerBuilder.BuildAllLayers(container, self._config)
	self._layerRefs = layerRefs

	self:_applyInitialState()
end

function LiquidGlass:_applyInitialState()
	local shadowConfig = self._config.Shadow
	if self._layerRefs.Shadow then
		ShadowLayerBuilder.UpdateShadowOnHover(self._layerRefs.Shadow, shadowConfig, false, 0)
	end

	if self._layerRefs.HoverLayers.HoverGlow then
		self._layerRefs.HoverLayers.HoverGlow.BackgroundTransparency = 1
	end
	if self._layerRefs.HoverLayers.PressOverlay then
		self._layerRefs.HoverLayers.PressOverlay.BackgroundTransparency = 1
	end

	local chromaticConfig = self._config.Chromatic
	ChromaticLayerBuilder.UpdateOffsets(self._layerRefs.ChromaticLayers, Vector2.zero, chromaticConfig, false)
end

function LiquidGlass:_setupInteractions()
	local inputHandler = self._layerRefs.InputHandler
	if not inputHandler then return end

	table.insert(self._connections, inputHandler.MouseEnter:Connect(function()
		if self._isDestroyed then return end
		self:_onHoverChanged(true)
	end))

	table.insert(self._connections, inputHandler.MouseLeave:Connect(function()
		if self._isDestroyed then return end
		self:_onHoverChanged(false)
		if self._isPressed then self:_onPressChanged(false) end
	end))

	table.insert(self._connections, inputHandler.InputBegan:Connect(function(input)
		if self._isDestroyed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			self:_onPressChanged(true)
		end
	end))

	table.insert(self._connections, inputHandler.InputEnded:Connect(function(input)
		if self._isDestroyed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if self._isPressed then
				self:_onPressChanged(false)
				if self._isHovered and self._config.onClick then
					self._config.onClick()
				end
			end
		end
	end))

	table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
		if self._isDestroyed then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			local mousePos = Vector2.new(input.Position.X, input.Position.Y)
			self._lastMousePosition = mousePos
			if self._isHovered then self:_onMouseMove(mousePos) end
		end
	end))

	table.insert(self._connections, UserInputService.TouchMoved:Connect(function(touch)
		if self._isDestroyed then return end
		if self._isHovered and self._isPressed then
			local touchPos = Vector2.new(touch.Position.X, touch.Position.Y)
			self._lastMousePosition = touchPos
			self:_onMouseMove(touchPos)
		end
	end))
end

function LiquidGlass:_onMouseMove(position)
	if not self._container then return end

	local absPos = self._container.AbsolutePosition
	local absSize = self._container.AbsoluteSize
	local center = absPos + absSize / 2
	local relativePos = position - center
	local normalizedX = math.clamp(relativePos.X / (absSize.X / 2), -1, 1)
	local normalizedY = math.clamp(relativePos.Y / (absSize.Y / 2), -1, 1)
	local normalizedOffset = Vector2.new(normalizedX, normalizedY)

	self._mouseOffset = normalizedOffset

	local interactionConfig = self._config.Interaction
	if interactionConfig.ElasticEnabled then
		local elasticIntensity = interactionConfig.ElasticIntensity or 8
		local targetOffset = normalizedOffset * elasticIntensity
		SpringAnimations.SetTarget(self._positionSpring, targetOffset)
	end

	LayerUpdateUtils.UpdateAllOnMouse(self._layerRefs, normalizedOffset, self._config)
end

function LiquidGlass:_onHoverChanged(isHovered)
	if self._isHovered == isHovered then return end
	self._isHovered = isHovered

	local interactionConfig = self._config.Interaction
	local shadowConfig = self._config.Shadow
	local duration = 0.2

	if isHovered then
		if self._layerRefs.HoverLayers.HoverGlow then
			HoverLayerBuilder.UpdateHoverGlow(self._layerRefs.HoverLayers.HoverGlow, self._mouseOffset, true, duration)
		end
		ShadowLayerBuilder.UpdateShadowOnHover(self._layerRefs.Shadow, shadowConfig, true, duration)

		-- Усиление обводки
		local primaryStroke = self._layerRefs.BorderLayers.PrimaryStroke
		if primaryStroke then
			local borderCfg = self._config.BorderGradient
			TweenService:Create(primaryStroke,
				TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
				{ Thickness = borderCfg.Thickness * 1.6 }
			):Play()
		end

		local hoverScale = interactionConfig.HoverScale or 1.02
		if hoverScale ~= 1 then
			SpringAnimations.SetTarget(self._scaleSpring, Vector2.new(hoverScale, hoverScale))
		end

		if self._config.onHover then self._config.onHover() end
	else
		LayerUpdateUtils.ResetAll(self._layerRefs, self._config)
		SpringAnimations.SetTarget(self._positionSpring, Vector2.zero)
		SpringAnimations.SetTarget(self._scaleSpring, Vector2.new(1, 1))
		SpringAnimations.SetTarget(self._rotationSpring, 0)
		self._mouseOffset = Vector2.zero

		local primaryStroke = self._layerRefs.BorderLayers.PrimaryStroke
		if primaryStroke then
			local borderCfg = self._config.BorderGradient
			TweenService:Create(primaryStroke,
				TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
				{ Thickness = borderCfg.Thickness }
			):Play()
		end

		if self._config.onHoverEnd then self._config.onHoverEnd() end
	end
end

function LiquidGlass:_onPressChanged(isPressed)
	if self._isPressed == isPressed then return end
	self._isPressed = isPressed

	local interactionConfig = self._config.Interaction
	local duration = isPressed and 0.1 or 0.2

	if isPressed then
		local pressScale = interactionConfig.PressScale or 0.96
		SpringAnimations.SetTarget(self._scaleSpring, Vector2.new(pressScale, pressScale))

		if self._layerRefs.HoverLayers.PressOverlay then
			TweenService:Create(self._layerRefs.HoverLayers.PressOverlay,
				TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
				{ BackgroundTransparency = 0.9 }
			):Play()
		end

		if self._config.onPress then self._config.onPress() end
	else
		local targetScale = self._isHovered and (interactionConfig.HoverScale or 1.02) or 1
		SpringAnimations.SetTarget(self._scaleSpring, Vector2.new(targetScale, targetScale))

		if self._layerRefs.HoverLayers.PressOverlay then
			TweenService:Create(self._layerRefs.HoverLayers.PressOverlay,
				TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
				{ BackgroundTransparency = 1 }
			):Play()
		end

		ShadowLayerBuilder.UpdateShadowOnHover(self._layerRefs.Shadow, self._config.Shadow, self._isHovered, duration)

		if self._config.onRelease then self._config.onRelease() end
	end
end

function LiquidGlass:_startUpdateLoop()
	self._updateConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if self._isDestroyed then return end
		self:_updateFrame(deltaTime)
	end)
	table.insert(self._connections, self._updateConnection)
end

function LiquidGlass:_updateFrame(deltaTime)
	local interactionConfig = self._config.Interaction

	local positionValue = SpringAnimations.Step(self._positionSpring, deltaTime)
	local scaleValue = SpringAnimations.Step(self._scaleSpring, deltaTime)
	local rotationValue = SpringAnimations.Step(self._rotationSpring, deltaTime)

	if interactionConfig.ElasticEnabled and self._container then
		if typeof(positionValue) == "Vector2" then
			local basePos = self._config.Position
			self._container.Position = UDim2.new(
				basePos.X.Scale, basePos.X.Offset + positionValue.X,
				basePos.Y.Scale, basePos.Y.Offset + positionValue.Y
			)
		end
	end

	if typeof(scaleValue) == "Vector2" then
		local uiScale = self._container:FindFirstChildOfClass("UIScale")
		if not uiScale then
			uiScale = Instance.new("UIScale")
			uiScale.Parent = self._container
		end
		uiScale.Scale = scaleValue.X
	end

	if typeof(rotationValue) == "number" and math.abs(rotationValue) > 0.001 then
		self._container.Rotation = rotationValue
	end
end

function LiquidGlass:SetContent(content)
	if self._isDestroyed then return end
	local contentFrame = self._layerRefs.ContentContainer
	if contentFrame then
		for _, child in ipairs(contentFrame:GetChildren()) do
			if not child:IsA("UIListLayout") and not child:IsA("UIPadding") and not child:IsA("UICorner") then
				child:Destroy()
			end
		end
		content.Parent = contentFrame
	end
end

function LiquidGlass:SetProperty(key, value)
	if self._isDestroyed then return end
	local keys = string.split(key, ".")
	if #keys == 1 then
		self._config[key] = value
	else
		local current = self._config
		for i = 1, #keys - 1 do
			current = current[keys[i]]
			if not current then return end
		end
		current[keys[#keys]] = value
	end
end

function LiquidGlass:GetFrame() return self._container end
function LiquidGlass:GetContentFrame() return self._layerRefs.ContentContainer end
function LiquidGlass:IsHovered() return self._isHovered end
function LiquidGlass:IsPressed() return self._isPressed end

function LiquidGlass:SetEnabled(enabled)
	if self._isDestroyed then return end
	self._config.Enabled = enabled
	if enabled then
		self._container.BackgroundTransparency = 0
		if self._layerRefs.InputHandler then self._layerRefs.InputHandler.Active = true end
	else
		self._container.BackgroundTransparency = 0.5
		if self._layerRefs.InputHandler then self._layerRefs.InputHandler.Active = false end
		if self._isHovered then self:_onHoverChanged(false) end
		if self._isPressed then self:_onPressChanged(false) end
	end
end

function LiquidGlass:SetVisible(visible)
	if self._isDestroyed then return end
	self._container.Visible = visible
end

function LiquidGlass:TweenProperty(property, value, duration)
	if self._isDestroyed then return end
	local tweenDuration = duration or 0.3
	local tweenInfo = TweenInfo.new(tweenDuration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local tween = TweenService:Create(self._container, tweenInfo, { [property] = value })
	table.insert(self._tweens, tween)
	tween:Play()
end

function LiquidGlass:GetConfig() return self._config end

function LiquidGlass:Destroy()
	if self._isDestroyed then return end
	self._isDestroyed = true

	for _, connection in ipairs(self._connections) do
		if connection.Connected then connection:Disconnect() end
	end
	self._connections = {}

	for _, tween in ipairs(self._tweens) do tween:Cancel() end
	self._tweens = {}

	if self._container then self._container:Destroy() end

	self._container = nil
	self._layerRefs = nil
	self._config = nil
end

--// ═══════════════════════════════════════════════════════════════════════════════
--// SECTION 23: PRESETS & FACTORY METHODS
--// ═══════════════════════════════════════════════════════════════════════════════

LiquidGlass.Presets = {
	Default = { CornerRadius = 16 },
	Button = {
		Size = UDim2.fromOffset(160, 48),
		CornerRadius = 12,
		Interaction = { HoverScale = 1.03, PressScale = 0.97, ElasticEnabled = true, ElasticIntensity = 4 },
	},
	Card = {
		Size = UDim2.fromOffset(300, 200),
		CornerRadius = 20,
		Interaction = { HoverScale = 1.01, PressScale = 0.99, ElasticEnabled = true, ElasticIntensity = 3 },
	},
	Pill = {
		Size = UDim2.fromOffset(120, 36),
		CornerRadius = 18,
		Interaction = { HoverScale = 1.05, PressScale = 0.95, ElasticEnabled = false },
	},
	StatusBadge = {
		Size = UDim2.fromOffset(80, 28),
		CornerRadius = 14,
		Frost = { Enabled = true, Intensity = 0.9, NoiseScale = 2, NoiseOpacity = 0.01, Layers = 3,
			Tint = Color3.fromRGB(100, 200, 100), TintOpacity = 0.25 },
		Interaction = { HoverScale = 1.0, PressScale = 1.0, ElasticEnabled = false },
	},
	Panel = {
		Size = UDim2.fromOffset(400, 300),
		CornerRadius = 24,
		Interaction = { HoverScale = 1.0, PressScale = 1.0, ElasticEnabled = false },
	},
	Modal = {
		Size = UDim2.fromOffset(450, 320),
		CornerRadius = 20,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Interaction = { HoverScale = 1.0, PressScale = 1.0, ElasticEnabled = false },
	},
	Toolbar = {
		Size = UDim2.new(1, -32, 0, 56),
		CornerRadius = 16,
		Interaction = { HoverScale = 1.0, PressScale = 1.0, ElasticEnabled = false },
	},
}

function LiquidGlass._mergeConfigs(base, override)
	local function deepMerge(a, b)
		if type(a) ~= "table" or type(b) ~= "table" then
			return if b ~= nil then b else a
		end
		local result = {}
		for key, value in pairs(a) do
			result[key] = deepMerge(value, b[key])
		end
		for key, value in pairs(b) do
			if result[key] == nil then result[key] = value end
		end
		return result
	end
	return deepMerge(base, override)
end

function LiquidGlass.CreateButton(text, onClick, customConfig)
	local config = LiquidGlass._mergeConfigs(LiquidGlass.Presets.Button, customConfig or {})
	config.onClick = onClick
	local element = LiquidGlass.new(config)

	local label = Instance.new("TextLabel")
	label.Name = "ButtonLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 16
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	element:SetContent(label)

	return element
end

function LiquidGlass.CreateCard(customConfig)
	local config = LiquidGlass._mergeConfigs(LiquidGlass.Presets.Card, customConfig or {})
	return LiquidGlass.new(config)
end

function LiquidGlass.CreatePill(text, customConfig)
	local config = LiquidGlass._mergeConfigs(LiquidGlass.Presets.Pill, customConfig or {})
	local element = LiquidGlass.new(config)

	local label = Instance.new("TextLabel")
	label.Name = "PillLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 13
	element:SetContent(label)

	return element
end

function LiquidGlass.CreatePanel(customConfig)
	local config = LiquidGlass._mergeConfigs(LiquidGlass.Presets.Panel, customConfig or {})
	return LiquidGlass.new(config)
end

function LiquidGlass.CreateModal(customConfig)
	local config = LiquidGlass._mergeConfigs(LiquidGlass.Presets.Modal, customConfig or {})
	return LiquidGlass.new(config)
end

function LiquidGlass.CreateStatusBadge(text, color, customConfig)
	local baseConfig = LiquidGlass._mergeConfigs(LiquidGlass.Presets.StatusBadge, customConfig or {})
	if color then
		baseConfig.Frost = baseConfig.Frost or {}
		baseConfig.Frost.Tint = color
	end
	local element = LiquidGlass.new(baseConfig)

	local label = Instance.new("TextLabel")
	label.Name = "BadgeLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 11
	element:SetContent(label)

	return element
end

--// ═══════════════════════════════════════════════════════════════════════════════
--// SECTION 24: MODULE EXPORT
--// ═══════════════════════════════════════════════════════════════════════════════

return {
	VERSION = Constants.VERSION,
	BUILD_DATE = Constants.BUILD_DATE,
	new = LiquidGlass.new,
	CreateButton = LiquidGlass.CreateButton,
	CreateCard = LiquidGlass.CreateCard,
	CreatePill = LiquidGlass.CreatePill,
	CreatePanel = LiquidGlass.CreatePanel,
	CreateModal = LiquidGlass.CreateModal,
	CreateStatusBadge = LiquidGlass.CreateStatusBadge,
	Presets = LiquidGlass.Presets,
	Constants = Constants,
	Math = MathUtils,
	Color = ColorUtils,
	Gradient = GradientUtils,
	Animation = AnimationUtils,
	Spring = SpringPhysics,
	Instance = InstanceUtils,
	Layers = {
		Frost = FrostLayerBuilder,
		Chromatic = ChromaticLayerBuilder,
		Refraction = RefractionLayerBuilder,
		Border = BorderLayerBuilder,
		Shadow = ShadowLayerBuilder,
		Hover = HoverLayerBuilder,
		InnerGlow = InnerGlowLayerBuilder,
		Background = BackgroundLayerBuilder,
		Content = ContentContainerBuilder,
		Builder = LayerBuilder,
	},
	SpringAnimations = SpringAnimations,
	LayerUpdates = LayerUpdateUtils,
}
