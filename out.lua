--[[
    PIXEL CLIENT v7  |  Luau (Roblox)
    RightShift / watermark (mobile) = menu
    ESP (real, GUI-based) + preview on YOUR character | Shaders | Big Cosmetics pack
    Combat + Movement | HUD | GUI | Chat EN/RU | Configs | Keybinds (MMB on a toggle)
]]

local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local CAS = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")

local LP = Players.LocalPlayer
local TOGGLE_KEY = Enum.KeyCode.RightShift
local WHITE = Color3.new(1, 1, 1)
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

local Pixel = {}

-- ================= THEME / SETTINGS =================
local Theme = {
	Background = rgb(10, 10, 18),
	Element    = rgb(30, 30, 46),
	ElementHi  = rgb(52, 52, 76),
	Text       = rgb(240, 240, 250),
	SubText    = rgb(150, 150, 178),
	AccentA    = rgb(150, 90, 255),
	AccentB    = rgb(255, 80, 160),
	GlassAlpha = 0.28,
	ElemAlpha  = 0.45,
}

local Settings = {
	AnimSpeed = 1, ShadowStrength = 50, Scale = 1, Corner = 14,
	GradientSpin = true, GradientSpeed = 50, Rainbow = false, Border = true, Shine = false, Font = "Gotham",
}

local Families = {
	Gotham     = {Regular = Enum.Font.Gotham, Medium = Enum.Font.GothamMedium, Bold = Enum.Font.GothamBold},
	Ubuntu     = {Regular = Enum.Font.Ubuntu, Medium = Enum.Font.Ubuntu, Bold = Enum.Font.Ubuntu},
	Nunito     = {Regular = Enum.Font.Nunito, Medium = Enum.Font.Nunito, Bold = Enum.Font.Nunito},
	Roboto     = {Regular = Enum.Font.Roboto, Medium = Enum.Font.Roboto, Bold = Enum.Font.Roboto},
	Code       = {Regular = Enum.Font.Code, Medium = Enum.Font.Code, Bold = Enum.Font.Code},
	Arcade     = {Regular = Enum.Font.Arcade, Medium = Enum.Font.Arcade, Bold = Enum.Font.Arcade},
	SourceSans = {Regular = Enum.Font.SourceSans, Medium = Enum.Font.SourceSansSemibold, Bold = Enum.Font.SourceSansBold},
}

-- ================= HELPERS =================
local conns = {}
local function connect(sig, fn)
	local c = sig:Connect(fn)
	table.insert(conns, c)
	return c
end

local function dur(t) return t / math.max(Settings.AnimSpeed, 0.1) end

local function tween(obj, props, t, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do o[k] = v end
	o.Parent = parent
	return o
end

local function corner(parent, r) return new("UICorner", {CornerRadius = UDim.new(0, r or 8)}, parent) end

local function list(parent, pad)
	return new("UIListLayout", {Padding = UDim.new(0, pad or 0), SortOrder = Enum.SortOrder.LayoutOrder}, parent)
end

local function isPress(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end
local function isMove(i)
	return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end

local function toHex(c)
	return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
local function fromHex(s)
	local r, g, b = tostring(s):match("^#?(%x%x)(%x%x)(%x%x)$")
	if r then return rgb(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)) end
end

-- shared character helpers (top-level: used everywhere)
local function getChar() return LP.Character end
local function getHum()
	local c = LP.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
	local c = LP.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end
local function assetUrl(x)
	local s = (tostring(x or ""):gsub("%s", ""))
	if s == "" then return "" end
	if tonumber(s) then return "rbxassetid://" .. s end
	return s
end

local function makeDrag(handle, target)
	local dragging, start, startPos
	handle.InputBegan:Connect(function(i)
		if isPress(i) then dragging, start, startPos = true, i.Position, target.Position end
	end)
	connect(UIS.InputChanged, function(i)
		if dragging and isMove(i) then
			local d = i.Position - start
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	connect(UIS.InputEnded, function(i) if isPress(i) then dragging = false end end)
end

-- registries for live customisation
local accents, spinners, scrollbars, elements, texts, corners = {}, {}, {}, {}, {}, {}

local function accent(parent, spin)
	local g = new("UIGradient", {Color = ColorSequence.new(Theme.AccentA, Theme.AccentB)}, parent)
	table.insert(accents, g)
	if spin then table.insert(spinners, g) end
	return g
end

local function applyAccent()
	local seq = ColorSequence.new(Theme.AccentA, Theme.AccentB)
	for i = #accents, 1, -1 do
		local g = accents[i]
		if g.Parent then g.Color = seq else table.remove(accents, i) end
	end
	for i = #scrollbars, 1, -1 do
		local s = scrollbars[i]
		if s.Parent then s.ScrollBarImageColor3 = Theme.AccentA else table.remove(scrollbars, i) end
	end
end

local function elemAlpha(nested)
	return nested and math.min(Theme.ElemAlpha + 0.1, 0.95) or Theme.ElemAlpha
end

local function applyElements()
	for i = #elements, 1, -1 do
		local e = elements[i]
		if e[1].Parent then
			tween(e[1], {BackgroundTransparency = elemAlpha(e[2]),
				BackgroundColor3 = e[2] and Theme.ElementHi or Theme.Element}, 0.2)
		else
			table.remove(elements, i)
		end
	end
end

local function fontFor(weight)
	local fam = Families[Settings.Font] or Families.Gotham
	return fam[weight or "Regular"] or fam.Regular
end

local function txt(class, props, parent, weight)
	local o = new(class, props, nil)
	o.Font = fontFor(weight)
	table.insert(texts, {o, weight})
	o.Parent = parent
	return o
end

local function applyFont()
	for i = #texts, 1, -1 do
		local o, w = texts[i][1], texts[i][2]
		if o.Parent then o.Font = fontFor(w) else table.remove(texts, i) end
	end
end

connect(RunService.Heartbeat, function(dt)
	if Settings.GradientSpin then
		for i = #spinners, 1, -1 do
			local g = spinners[i]
			if g.Parent then g.Rotation = (g.Rotation + dt * Settings.GradientSpeed) % 360
			else table.remove(spinners, i) end
		end
	end
	if Settings.Rainbow then
		local h = (os.clock() * 0.08) % 1
		Theme.AccentA = Color3.fromHSV(h, 0.65, 1)
		Theme.AccentB = Color3.fromHSV((h + 0.15) % 1, 0.75, 1)
		applyAccent()
	end
end)

-- ================= CONFIG REGISTRY =================
local Flags = {}
local ArrayEntries = {}
local BindMap = {}
local BindListening = nil
local ArrayHide = {["Watermark"] = true, ["ArrayList"] = true, ["Target HUD"] = true}

local function register(key, getf, setf)
	local k, n = key, 1
	while Flags[k] do n += 1; k = key .. " #" .. n end
	Flags[k] = {get = getf, set = setf}
end

local CFG_DIR = "PixelClient/configs"
local hasFS = type(writefile) == "function" and type(readfile) == "function" and type(isfolder) == "function"
	and type(makefolder) == "function" and type(listfiles) == "function" and type(delfile) == "function"
local memCfg = {}

local function ensureDir()
	if not hasFS then return end
	pcall(function()
		if not isfolder("PixelClient") then makefolder("PixelClient") end
		if not isfolder(CFG_DIR) then makefolder(CFG_DIR) end
	end)
end

Pixel.Config = {}
function Pixel.Config.Encode()
	local d = {}
	for k, f in pairs(Flags) do d[k] = f.get() end
	return HttpService:JSONEncode(d)
end
function Pixel.Config.ApplyJson(json)
	local ok, d = pcall(function() return HttpService:JSONDecode(json) end)
	if not ok or type(d) ~= "table" then return false end
	for k, v in pairs(d) do
		local f = Flags[k]
		if f then pcall(f.set, v) end
	end
	return true
end
function Pixel.Config.Save(name)
	local json = Pixel.Config.Encode()
	if hasFS then
		ensureDir()
		return (pcall(writefile, CFG_DIR .. "/" .. name .. ".json", json))
	end
	memCfg[name] = json
	return true
end
function Pixel.Config.Load(name)
	local json
	if hasFS then
		local ok, res = pcall(readfile, CFG_DIR .. "/" .. name .. ".json")
		if ok then json = res end
	else
		json = memCfg[name]
	end
	if not json then return false end
	return Pixel.Config.ApplyJson(json)
end
function Pixel.Config.Delete(name)
	if hasFS then return (pcall(delfile, CFG_DIR .. "/" .. name .. ".json")) end
	memCfg[name] = nil
	return true
end
function Pixel.Config.List()
	local out = {}
	if hasFS then
		ensureDir()
		local ok, files = pcall(listfiles, CFG_DIR)
		if ok then
			for _, p in ipairs(files) do
				local n = tostring(p):match("([^/\\]+)%.json$")
				if n then table.insert(out, n) end
			end
		end
	else
		for n in pairs(memCfg) do table.insert(out, n) end
	end
	table.sort(out)
	return out
end

-- ================= SOFT SHADOW (9-slice) =================
local SHADOW_IMG = "rbxassetid://5028857084"
local function makeShadow(parent, pad, offY)
	local img = new("ImageLabel", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, offY or 6), Size = UDim2.new(1, pad * 2, 1, pad * 2), ZIndex = 0,
		Active = false, Image = SHADOW_IMG, ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 1,
		ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(24, 24, 276, 276)}, parent)
	local S = {img = img}
	function S:Set(strength, t)
		local target = 1 - 0.55 * math.clamp(strength, 0, 1)
		if t and t > 0 then tween(img, {ImageTransparency = target}, t, Enum.EasingStyle.Sine)
		else img.ImageTransparency = target end
	end
	return S
end

-- ================= ICONS =================
local function bar(parent, w, h, x, y, rot)
	return new("Frame", {BackgroundColor3 = WHITE, BorderSizePixel = 0, Size = UDim2.fromOffset(w, h),
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, y), Rotation = rot or 0}, parent)
end
local function ring(parent, w, h, x, y, th)
	local f = new("Frame", {BackgroundTransparency = 1, Size = UDim2.fromOffset(w, h),
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, y)}, parent)
	new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, f)
	new("UIStroke", {Color = WHITE, Thickness = th or 1.6}, f)
	return f
end
local function disc(parent, d, x, y)
	local f = bar(parent, d, d, x, y)
	new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, f)
	return f
end

local IconBuilders = {
	eye = function(p) ring(p, 16, 10, 10, 10, 1.6); disc(p, 5, 10, 10) end,
	sword = function(p) bar(p, 2, 12, 12, 8, 45); bar(p, 8, 2, 9, 11, 45); bar(p, 2, 4, 7, 13, 45) end,
	move = function(p)
		for _, dx in ipairs({0, 6}) do
			bar(p, 2, 7, 5.5 + dx, 7.5, -45)
			bar(p, 2, 7, 5.5 + dx, 12.5, 45)
		end
	end,
	dots = function(p) disc(p, 4, 4, 10); disc(p, 4, 10, 10); disc(p, 4, 16, 10) end,
	gear = function(p)
		ring(p, 12, 12, 10, 10, 2); disc(p, 4, 10, 10)
		bar(p, 2, 4, 10, 2.5); bar(p, 2, 4, 10, 17.5); bar(p, 4, 2, 2.5, 10); bar(p, 4, 2, 17.5, 10)
	end,
	user = function(p)
		disc(p, 7, 10, 6.5)
		local b = bar(p, 14, 7, 10, 15.5)
		new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, b)
	end,
}

local function buildIcon(kind, parent)
	local g = new("CanvasGroup", {BackgroundTransparency = 1, Size = UDim2.fromOffset(20, 20),
		Position = UDim2.new(0, 12, 0.5, -10), GroupTransparency = 0.4}, parent)
	if type(kind) == "string" and kind:find("^rbxasset") then
		new("ImageLabel", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = kind, ImageColor3 = WHITE}, g)
	elseif IconBuilders[kind] then
		IconBuilders[kind](g)
	end
	return g
end

-- ================= WALLPAPER =================
local function resolveImage(input)
	local s = tostring(input or "")
	s = s:gsub("^%s+", "")
	s = s:gsub("%s+$", "")
	if s == "" then return nil end
	if tonumber(s) then return "rbxassetid://" .. s end
	if s:find("^rbxassetid://") or s:find("^rbxasset://") or s:find("^rbxthumb://") then return s end
	if s:find("^https?://") then
		local sum = 0
		for c in s:gmatch(".") do sum = (sum * 31 + c:byte()) % 1000000007 end
		local ok, res = pcall(function()
			local name = "pixel_wall_" .. sum .. ".png"
			writefile(name, game:HttpGet(s))
			return getcustomasset(name)
		end)
		if ok then return res end
		return nil, "Ссылки работают только в executor (writefile/getcustomasset)"
	end
	local ok, res = pcall(function() return getcustomasset(s) end)
	if ok then return res end
	return nil, "Файл не найден или нет getcustomasset"
end

-- ================= ROOT GUI =================
local function getParent()
	local ok, hui = pcall(function() return gethui and gethui() end)
	if ok and hui then return hui end
	return LP:WaitForChild("PlayerGui")
end

local gui = new("ScreenGui", {Name = "PixelClient", ResetOnSpawn = false, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999}, getParent())

-- ================= NOTIFICATIONS =================
local notifHolder = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(0, 280, 1, -30),
	Position = UDim2.new(1, -295, 0, 15)}, gui)
new("UIListLayout", {Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Bottom,
	SortOrder = Enum.SortOrder.LayoutOrder}, notifHolder)
local notifOrder = 0

function Pixel:Notify(title, text, duration)
	notifOrder += 1
	local slot = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 58), LayoutOrder = notifOrder}, notifHolder)
	local hold = new("Frame", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Position = UDim2.new(1, 40, 0, 0)}, slot)
	local sh = makeShadow(hold, 22, 4)
	sh:Set(0.7)
	local card = new("Frame", {BackgroundColor3 = Theme.Background, BackgroundTransparency = 0.15,
		Size = UDim2.fromScale(1, 1), ZIndex = 1}, hold)
	corner(card, 10)
	local st = new("UIStroke", {Color = WHITE, Thickness = 1.2, Transparency = 0.25}, card)
	accent(st, true)
	txt("TextLabel", {BackgroundTransparency = 1, TextSize = 14, Text = title, TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 14, 0, 9), Size = UDim2.new(1, -20, 0, 18)}, card, "Bold")
	txt("TextLabel", {BackgroundTransparency = 1, TextSize = 12, Text = text, TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 14, 0, 30), Size = UDim2.new(1, -20, 0, 18)}, card, "Regular")
	tween(hold, {Position = UDim2.new(0, 0, 0, 0)}, dur(0.4), Enum.EasingStyle.Back)
	task.delay(duration or 3, function()
		tween(hold, {Position = UDim2.new(1, 40, 0, 0)}, dur(0.3))
		task.wait(dur(0.35))
		slot:Destroy()
	end)
end

-- ================= ELEMENTS =================
local buildApi
buildApi = function(api, parent, nested, prefix)
	prefix = prefix or ""
	local order = 0
	local function nextOrder() order += 1; return order end
	local function baseColor() return nested and Theme.ElementHi or Theme.Element end

	local function element(h)
		local f = new("Frame", {BackgroundColor3 = baseColor(), BackgroundTransparency = elemAlpha(nested),
			Size = UDim2.new(1, 0, 0, h or 40), LayoutOrder = nextOrder()}, parent)
		table.insert(elements, {f, nested})
		corner(f, 9)
		new("UIStroke", {Color = WHITE, Transparency = nested and 0.9 or 0.93, Thickness = 1}, f)
		return f
	end
	local function hover(f, target)
		target.MouseEnter:Connect(function() tween(f, {BackgroundTransparency = math.max(elemAlpha(nested) - 0.15, 0)}, 0.15) end)
		target.MouseLeave:Connect(function() tween(f, {BackgroundTransparency = elemAlpha(nested)}, 0.15) end)
	end
	local function title(f, text, size)
		return txt("TextLabel", {BackgroundTransparency = 1, TextSize = 13, Text = text, TextColor3 = Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 14, 0, 0),
			Size = size or UDim2.new(1, -80, 0, 40)}, f, "Medium")
	end

	function api:AddLabel(text)
		local l = txt("TextLabel", {BackgroundTransparency = 1, TextSize = 11, Text = string.upper(text),
			TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 22), LayoutOrder = nextOrder()}, parent, "Bold")
		new("UIPadding", {PaddingLeft = UDim.new(0, 4), PaddingTop = UDim.new(0, 6)}, l)
	end

	function api:AddCustom(h) return element(h) end

	function api:AddToggle(text, default, callback, settingsFn, noSave)
		local state = default or false
		local committed = state
		local token = 0
		local open = false
		local setOpen

		local f = element(40)
		local row = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40)}, f)
		title(row, text, UDim2.new(1, settingsFn and -120 or -80, 1, 0))
		local track = new("Frame", {BackgroundColor3 = Theme.ElementHi, Size = UDim2.fromOffset(42, 22),
			Position = UDim2.new(1, -56, 0.5, -11)}, row)
		corner(track, 11)
		local tg = accent(track)
		tg.Enabled = false
		local knob = new("Frame", {BackgroundColor3 = WHITE, Size = UDim2.fromOffset(16, 16),
			Position = UDim2.new(0, 3, 0.5, -8)}, track)
		corner(knob, 8)
		local click = new("TextButton", {BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1)}, row)

		local function render()
			tg.Enabled = state
			track.BackgroundColor3 = state and WHITE or Theme.ElementHi
			tween(knob, {Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}, 0.2, Enum.EasingStyle.Back)
		end
		render()

		if settingsFn then
			f.ClipsDescendants = true
			local gear = new("CanvasGroup", {BackgroundTransparency = 1, Size = UDim2.fromOffset(20, 20),
				Position = UDim2.new(1, -92, 0.5, -10), GroupTransparency = 0.55}, row)
			IconBuilders.gear(gear)
			local holder = new("Frame", {BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 46),
				Size = UDim2.new(1, -16, 0, 0)}, f)
			local lay = list(holder, 6)
			local sub = {}
			buildApi(sub, holder, true, prefix .. "/" .. text)
			settingsFn(sub)
			local function targetH() return 46 + lay.AbsoluteContentSize.Y + 8 end
			setOpen = function(o)
				open = o
				tween(f, {Size = UDim2.new(1, 0, 0, o and targetH() or 40)}, dur(0.28), Enum.EasingStyle.Quart)
				tween(gear, {GroupTransparency = o and 0 or 0.55, Rotation = o and 90 or 0}, 0.25)
			end
			lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				if open then tween(f, {Size = UDim2.new(1, 0, 0, targetH())}, 0.15) end
			end)
		end

		local lastClick = 0
		local function commit()
			if not callback then committed = state return end
			if not settingsFn then
				committed = state
				task.spawn(callback, state)
				return
			end
			token += 1
			local my = token
			task.delay(0.25, function()
				if my == token and state ~= committed then
					committed = state
					task.spawn(callback, state)
				end
			end)
		end

		local obj
		click.MouseButton1Click:Connect(function()
			state = not state
			render()
			if settingsFn then
				local now = os.clock()
				if now - lastClick < 0.3 then
					lastClick = 0
					setOpen(not open)
				else
					lastClick = now
				end
			end
			commit()
		end)
		click.MouseButton2Click:Connect(function()
			if settingsFn then setOpen(not open) end
		end)
		click.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton3 then
				BindListening = obj
				Pixel:Notify("Bind", "СКМ: нажми клавишу → " .. text, 2.5)
			end
		end)
		hover(f, click)

		obj = {
			Set = function(v)
				state = v and true or false; committed = state; token += 1
				render()
				if callback then task.spawn(callback, state) end
			end,
			Get = function() return state end,
			Toggle = function()
				state = not state
				render()
				commit()
			end,
			Name = text,
		}
		if not noSave then register(prefix .. "/" .. text, function() return state end, function(v) obj.Set(v and true or false) end) end
		if not nested and not noSave then
			table.insert(ArrayEntries, {name = text, get = function() return state end})
		end
		return obj
	end

	function api:AddSlider(text, min, max, default, callback, step, noSave)
		step = step or 1
		local value = default or min
		local function shown(x) return tostring(math.floor(x * 100 + 0.5) / 100) end
		local f = element(54)
		title(f, text, UDim2.new(1, -90, 0, 30))
		local valLbl = txt("TextLabel", {BackgroundTransparency = 1, TextSize = 12, Text = shown(value),
			TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Right,
			Position = UDim2.new(1, -74, 0, 0), Size = UDim2.new(0, 60, 0, 30)}, f, "Bold")
		local barF = new("Frame", {BackgroundColor3 = Theme.ElementHi, Size = UDim2.new(1, -28, 0, 6),
			Position = UDim2.new(0, 14, 0, 37)}, f)
		corner(barF, 3)
		local fill = new("Frame", {BackgroundColor3 = WHITE, Size = UDim2.new((value - min) / (max - min), 0, 1, 0)}, barF)
		corner(fill, 3)
		accent(fill)
		local knob = new("Frame", {BackgroundColor3 = WHITE, Size = UDim2.fromOffset(12, 12),
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, 0, 0.5, 0)}, fill)
		corner(knob, 6)

		local function apply(val, fire)
			value = math.clamp(math.floor(val / step + 0.5) * step, min, max)
			valLbl.Text = shown(value)
			tween(fill, {Size = UDim2.new((value - min) / (max - min), 0, 1, 0)}, 0.06)
			if fire and callback then task.spawn(callback, value) end
		end
		local dragging = false
		local function setFromX(x)
			local rel = math.clamp((x - barF.AbsolutePosition.X) / barF.AbsoluteSize.X, 0, 1)
			apply(min + (max - min) * rel, true)
		end
		barF.InputBegan:Connect(function(i)
			if isPress(i) then dragging = true; setFromX(i.Position.X) end
		end)
		connect(UIS.InputChanged, function(i)
			if dragging and isMove(i) then setFromX(i.Position.X) end
		end)
		connect(UIS.InputEnded, function(i) if isPress(i) then dragging = false end end)
		local obj = {Set = function(v) apply(tonumber(v) or value, true) end, Get = function() return value end}
		if not noSave then register(prefix .. "/" .. text, function() return value end, obj.Set) end
		return obj
	end

	function api:AddButton(text, callback)
		local f = element(38)
		local b = txt("TextButton", {BackgroundTransparency = 1, TextSize = 13, Text = text, TextColor3 = Theme.Text,
			AutoButtonColor = false, Size = UDim2.fromScale(1, 1)}, f, "Bold")
		hover(f, b)
		b.MouseButton1Click:Connect(function()
			tween(f, {BackgroundColor3 = Theme.AccentA}, 0.08)
			task.delay(0.12, function() tween(f, {BackgroundColor3 = baseColor()}, 0.25) end)
			if callback then task.spawn(callback) end
		end)
	end

	-- callback(text, enterPressed)
	function api:AddTextbox(text, placeholder, callback, default)
		local f = element(40)
		title(f, text, UDim2.new(0.38, 0, 0, 40))
		local box = txt("TextBox", {BackgroundColor3 = Theme.ElementHi, BackgroundTransparency = 0.3, Text = default or "",
			PlaceholderText = placeholder or "", PlaceholderColor3 = Theme.SubText, TextColor3 = Theme.Text,
			TextSize = 12, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, ClipsDescendants = true,
			Size = UDim2.new(0.62, -24, 0, 26), Position = UDim2.new(0.38, 10, 0.5, -13)}, f, "Regular")
		corner(box, 6)
		new("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, box)
		box.FocusLost:Connect(function(enter)
			if callback then task.spawn(callback, box.Text, enter) end
		end)
		return {Set = function(v) box.Text = v end, Get = function() return box.Text end}
	end

	function api:AddDropdown(text, options, default, callback, noSave)
		local opts = options or {}
		local current = default or opts[1]
		local f = element(40)
		f.ClipsDescendants = true
		title(f, text, UDim2.new(0.5, 0, 0, 40))
		local valLbl = txt("TextLabel", {BackgroundTransparency = 1, TextSize = 12, Text = tostring(current or "-"),
			TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Right,
			Position = UDim2.new(0.4, 0, 0, 0), Size = UDim2.new(0.6, -38, 0, 40)}, f, "Medium")
		local arr = txt("TextLabel", {BackgroundTransparency = 1, TextSize = 18, Text = "›", TextColor3 = Theme.SubText,
			Size = UDim2.fromOffset(24, 40), Position = UDim2.new(1, -30, 0, -1)}, f, "Bold")
		local head = new("TextButton", {BackgroundTransparency = 1, Text = "", Size = UDim2.new(1, 0, 0, 40)}, f)
		local holder = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 0),
			Position = UDim2.fromOffset(10, 42)}, f)
		list(holder, 2)
		local open = false
		local optBtns = {}
		local function fullH() return 42 + #opts * 28 + 4 end
		local function setOpen(o)
			open = o
			tween(f, {Size = UDim2.new(1, 0, 0, o and fullH() or 40)}, dur(0.25), Enum.EasingStyle.Quart)
			tween(arr, {Rotation = o and 90 or 0}, 0.2)
		end
		local function choose(opt, fire)
			current = opt
			valLbl.Text = tostring(opt)
			for o, b in pairs(optBtns) do b.TextColor3 = (o == opt) and Theme.Text or Theme.SubText end
			if fire and callback then task.spawn(callback, opt) end
		end
		local function rebuild()
			for _, b in pairs(optBtns) do b:Destroy() end
			optBtns = {}
			holder.Size = UDim2.new(1, -20, 0, #opts * 28)
			for idx, opt in ipairs(opts) do
				local ob = txt("TextButton", {BackgroundColor3 = Theme.ElementHi, BackgroundTransparency = 0.6,
					AutoButtonColor = false, Text = tostring(opt), TextSize = 12, LayoutOrder = idx,
					TextColor3 = (opt == current) and Theme.Text or Theme.SubText,
					TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 26)}, holder, "Medium")
				corner(ob, 6)
				new("UIPadding", {PaddingLeft = UDim.new(0, 10)}, ob)
				optBtns[opt] = ob
				ob.MouseButton1Click:Connect(function()
					choose(opt, true)
					setOpen(false)
				end)
			end
			if open then f.Size = UDim2.new(1, 0, 0, fullH()) end
		end
		rebuild()
		head.MouseButton1Click:Connect(function() setOpen(not open) end)
		hover(f, head)
		local obj = {
			Set = function(o) choose(o, true) end,
			Get = function() return current end,
			Refresh = function(newOpts)
				opts = newOpts or {}
				local found = false
				for _, o in ipairs(opts) do if o == current then found = true end end
				if not found then current = opts[1]; valLbl.Text = tostring(current or "-") end
				rebuild()
			end,
		}
		if not noSave then register(prefix .. "/" .. text, function() return current end, obj.Set) end
		return obj
	end

	function api:AddColorPicker(text, default, callback, noSave)
		local color = default or WHITE
		local h, s, v = color:ToHSV()
		local f = element(40)
		f.ClipsDescendants = true
		title(f, text)
		local swatch = new("Frame", {BackgroundColor3 = color, Size = UDim2.fromOffset(34, 20),
			Position = UDim2.new(1, -48, 0, 10)}, f)
		corner(swatch, 6)
		new("UIStroke", {Color = WHITE, Transparency = 0.7}, swatch)
		local head = new("TextButton", {BackgroundTransparency = 1, Text = "", Size = UDim2.new(1, 0, 0, 40)}, f)

		local sv = new("Frame", {BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0,
			Size = UDim2.new(1, -28, 0, 90), Position = UDim2.fromOffset(14, 48)}, f)
		corner(sv, 6)
		local wf = new("Frame", {BackgroundColor3 = WHITE, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1)}, sv)
		corner(wf, 6)
		new("UIGradient", {Transparency = NumberSequence.new(0, 1)}, wf)
		local bf = new("Frame", {BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1)}, sv)
		corner(bf, 6)
		new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new(1, 0)}, bf)
		local svCur = new("Frame", {BackgroundTransparency = 1, Size = UDim2.fromOffset(12, 12),
			AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 3}, sv)
		corner(svCur, 6)
		new("UIStroke", {Color = WHITE, Thickness = 2}, svCur)

		local hue = new("Frame", {BackgroundColor3 = WHITE, BorderSizePixel = 0,
			Size = UDim2.new(1, -28, 0, 12), Position = UDim2.fromOffset(14, 146)}, f)
		corner(hue, 6)
		new("UIGradient", {Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, rgb(255, 0, 0)), ColorSequenceKeypoint.new(1 / 6, rgb(255, 255, 0)),
			ColorSequenceKeypoint.new(2 / 6, rgb(0, 255, 0)), ColorSequenceKeypoint.new(3 / 6, rgb(0, 255, 255)),
			ColorSequenceKeypoint.new(4 / 6, rgb(0, 0, 255)), ColorSequenceKeypoint.new(5 / 6, rgb(255, 0, 255)),
			ColorSequenceKeypoint.new(1, rgb(255, 0, 0)),
		})}, hue)
		local hCur = new("Frame", {BackgroundColor3 = WHITE, Size = UDim2.fromOffset(6, 18),
			AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 3}, hue)
		corner(hCur, 3)
		new("UIStroke", {Color = Color3.new(0, 0, 0), Transparency = 0.5}, hCur)

		local hex = txt("TextBox", {BackgroundColor3 = Theme.ElementHi, BackgroundTransparency = 0.3, Text = "",
			TextColor3 = Theme.Text, TextSize = 12, ClearTextOnFocus = false,
			Size = UDim2.new(1, -28, 0, 24), Position = UDim2.fromOffset(14, 166)}, f, "Medium")
		corner(hex, 6)

		local function refresh(fire)
			color = Color3.fromHSV(h, s, v)
			swatch.BackgroundColor3 = color
			sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			svCur.Position = UDim2.new(s, 0, 1 - v, 0)
			hCur.Position = UDim2.new(h, 0, 0.5, 0)
			hex.Text = toHex(color)
			if fire and callback then task.spawn(callback, color) end
		end
		refresh(false)

		local dragSV, dragH = false, false
		local function svFrom()
			local m = UIS:GetMouseLocation()
			s = math.clamp((m.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
			v = 1 - math.clamp((m.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
			refresh(true)
		end
		local function hueFrom()
			local m = UIS:GetMouseLocation()
			h = math.clamp((m.X - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 0.999)
			refresh(true)
		end
		sv.InputBegan:Connect(function(i) if isPress(i) then dragSV = true; svFrom() end end)
		hue.InputBegan:Connect(function(i) if isPress(i) then dragH = true; hueFrom() end end)
		connect(UIS.InputChanged, function(i)
			if isMove(i) then
				if dragSV then svFrom() elseif dragH then hueFrom() end
			end
		end)
		connect(UIS.InputEnded, function(i) if isPress(i) then dragSV, dragH = false, false end end)
		hex.FocusLost:Connect(function()
			local c = fromHex(hex.Text)
			if c then h, s, v = c:ToHSV() end
			refresh(true)
		end)

		local open = false
		head.MouseButton1Click:Connect(function()
			open = not open
			tween(f, {Size = UDim2.new(1, 0, 0, open and 198 or 40)}, dur(0.28), Enum.EasingStyle.Quart)
		end)
		hover(f, head)
		local obj = {Set = function(c) h, s, v = c:ToHSV(); refresh(true) end, Get = function() return color end}
		if not noSave then
			register(prefix .. "/" .. text, function() return toHex(color) end, function(x)
				local c = fromHex(x)
				if c then obj.Set(c) end
			end)
		end
		return obj
	end
end

-- ================= WINDOW =================
function Pixel:CreateWindow(title)
	local Window = {Current = nil, OpenCategory = nil, Theme = Theme, Settings = Settings, Ready = false}
	local visible = false
	local catOrder = 0
	local pointerInside = false
	local unloadHooks = {}
	local ghostToken = 0
	local savedPos

	local root = new("Frame", {Name = "Root", BackgroundTransparency = 1, Size = UDim2.fromOffset(700, 440),
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Visible = false}, gui)
	local uiscale = new("UIScale", {Scale = Settings.Scale * 0.9}, root)
	Window.Root = root
	function Window.IsVisible() return visible end

	local shadow = makeShadow(root, 34, 10)

	local main = new("CanvasGroup", {Name = "Main", BackgroundColor3 = Theme.Background,
		BackgroundTransparency = Theme.GlassAlpha, Size = UDim2.fromScale(1, 1), GroupTransparency = 1,
		Active = true, ZIndex = 1}, root)
	table.insert(corners, new("UICorner", {CornerRadius = UDim.new(0, Settings.Corner)}, main))

	local border = new("Frame", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 10}, root)
	table.insert(corners, new("UICorner", {CornerRadius = UDim.new(0, Settings.Corner)}, border))
	local borderStroke = new("UIStroke", {Color = WHITE, Thickness = 1.5, Transparency = 1}, border)
	accent(borderStroke, true)

	local wallpaper = new("ImageLabel", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
		ScaleType = Enum.ScaleType.Crop, ImageTransparency = 0.55, Visible = false, ZIndex = 0}, main)

	local sidebar = new("Frame", {BorderSizePixel = 0, Size = UDim2.new(0, 210, 1, 0)}, main)
	new("Frame", {BackgroundColor3 = WHITE, BackgroundTransparency = 0.92, BorderSizePixel = 0,
		Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0)}, sidebar)

	local function applyLook()
		main.BackgroundColor3 = Theme.Background
		main.BackgroundTransparency = Theme.GlassAlpha
		sidebar.BackgroundColor3 = Theme.Background:Lerp(Color3.new(0, 0, 0), 0.55)
		sidebar.BackgroundTransparency = math.min(Theme.GlassAlpha + 0.2, 1)
	end
	applyLook()

	local logoArea = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 66)}, sidebar)
	local logo = new("TextLabel", {BackgroundTransparency = 1, Font = Enum.Font.Arcade, TextSize = 30,
		Text = title or "PIXEL", TextColor3 = WHITE, Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0, 14)}, logoArea)
	accent(logo, true)

	txt("TextLabel", {BackgroundTransparency = 1, TextSize = 11, TextColor3 = Theme.SubText, Text = "Pixel Client  v7",
		Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 1, -26)}, sidebar, "Regular")

	local catList = new("ScrollingFrame", {BackgroundTransparency = 1, BorderSizePixel = 0,
		Size = UDim2.new(1, -20, 1, -110), Position = UDim2.new(0, 10, 0, 72), ScrollBarThickness = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y}, sidebar)
	list(catList, 5)

	local topbar = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, -210, 0, 56), Position = UDim2.new(0, 210, 0, 0)}, main)
	local crumb = txt("TextLabel", {BackgroundTransparency = 1, TextSize = 18, Text = "", TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 22, 0, 0), Size = UDim2.new(1, -80, 1, 0),
		RichText = true}, topbar, "Bold")
	new("Frame", {BackgroundColor3 = WHITE, BackgroundTransparency = 0.92, BorderSizePixel = 0,
		Size = UDim2.new(1, -30, 0, 1), Position = UDim2.new(0, 15, 1, 0)}, topbar)
	local closeBtn = txt("TextButton", {BackgroundTransparency = 1, Text = "×", TextSize = 26, TextColor3 = Theme.SubText,
		AutoButtonColor = false, Size = UDim2.fromOffset(34, 34), Position = UDim2.new(1, -46, 0, 11)}, topbar, "Regular")
	closeBtn.MouseEnter:Connect(function() tween(closeBtn, {TextColor3 = Theme.Text}) end)
	closeBtn.MouseLeave:Connect(function() tween(closeBtn, {TextColor3 = Theme.SubText}) end)

	local pages = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, -236, 1, -78),
		Position = UDim2.new(0, 222, 0, 66)}, main)

	local shine = new("Frame", {BackgroundColor3 = WHITE, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
		ZIndex = 20, Visible = false, Active = false}, main)
	local shineG = new("UIGradient", {Rotation = 25, Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.42, 1), NumberSequenceKeypoint.new(0.5, 0.9),
		NumberSequenceKeypoint.new(0.58, 1), NumberSequenceKeypoint.new(1, 1)})}, shine)

	makeDrag(logoArea, root)
	makeDrag(topbar, root)

	-- pointer over menu: game does not react
	local function bindSink(on)
		if on then
			CAS:BindActionAtPriority("PixelSink", function() return Enum.ContextActionResult.Sink end, false,
				Enum.ContextActionPriority.High.Value, Enum.UserInputType.MouseButton1,
				Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseWheel)
		else
			CAS:UnbindAction("PixelSink")
		end
	end
	connect(RunService.Heartbeat, function()
		local inside = false
		if visible then
			local m = UIS:GetMouseLocation()
			local p, s = root.AbsolutePosition, root.AbsoluteSize
			inside = m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y
		end
		if inside ~= pointerInside then
			pointerInside = inside
			bindSink(inside)
		end
		if Settings.Shine and visible then
			shineG.Offset = Vector2.new(-1 + 2 * ((os.clock() / 3.5) % 1), 0)
		end
	end)
	function Window.IsPointerInside() return pointerInside end

	-- open / close
	local function shadowTarget() return Settings.ShadowStrength / 100 end
	local function borderTarget() return Settings.Border and 0.25 or 1 end

	function Window:SetVisible(state)
		if state == visible then return end
		visible = state
		ghostToken += 1
		local my = ghostToken
		if state then
			local wasHidden = not root.Visible
			root.Visible = true
			main.Active = true
			if wasHidden then
				uiscale.Scale = Settings.Scale * 0.88
				main.GroupTransparency = 1
			end
			local t = dur(0.28)
			if savedPos then tween(root, {Position = savedPos}, t, Enum.EasingStyle.Quart) end
			tween(uiscale, {Scale = Settings.Scale}, t, Enum.EasingStyle.Back)
			tween(main, {GroupTransparency = 0}, dur(0.2))
			shadow:Set(shadowTarget(), t)
			tween(borderStroke, {Transparency = borderTarget()}, t)
		else
			main.Active = false
			savedPos = root.Position
			local g = dur(0.22)
			tween(main, {GroupTransparency = 1}, g)
			tween(root, {Position = savedPos + UDim2.fromOffset(0, -18)}, g)
			tween(uiscale, {Scale = Settings.Scale * 0.94}, g)
			shadow:Set(0, g)
			tween(borderStroke, {Transparency = 1}, g)
			task.delay(g + 0.02, function()
				if ghostToken == my and not visible then
					root.Visible = false
					root.Position = savedPos
					uiscale.Scale = Settings.Scale
				end
			end)
		end
	end

	closeBtn.MouseButton1Click:Connect(function()
		Window:SetVisible(false)
		Pixel:Notify("Pixel Client", "Нажми " .. TOGGLE_KEY.Name .. ", чтобы открыть меню", 3)
	end)

	connect(UIS.InputBegan, function(i, gp)
		if gp or not Window.Ready then return end
		if i.KeyCode == TOGGLE_KEY then Window:SetVisible(not visible) end
	end)

	function Window:OnUnload(fn) table.insert(unloadHooks, fn) end
	function Window:Destroy()
		for _, fn in ipairs(unloadHooks) do pcall(fn) end
		pcall(function() CAS:UnbindAction("PixelSink") end)
		for _, c in ipairs(conns) do c:Disconnect() end
		gui:Destroy()
	end

	-- customisation API
	function Window:SetAccent(a, b)
		if a then Theme.AccentA = a end
		if b then Theme.AccentB = b end
		applyAccent()
	end
	function Window:SetBackground(c) Theme.Background = c; applyLook() end
	function Window:SetElementColor(c) Theme.Element = c; applyElements() end
	function Window:SetGlass(a) Theme.GlassAlpha = a; applyLook() end
	function Window:SetElemAlpha(a) Theme.ElemAlpha = a; applyElements() end
	function Window:SetCorner(px)
		Settings.Corner = px
		for _, c in ipairs(corners) do c.CornerRadius = UDim.new(0, px) end
	end
	function Window:SetScale(x)
		Settings.Scale = x
		if visible then tween(uiscale, {Scale = x}, 0.15) end
	end
	function Window:SetShadow(strength)
		Settings.ShadowStrength = strength
		if visible then shadow:Set(shadowTarget(), 0.2) end
	end
	function Window:SetBorder(on)
		Settings.Border = on
		if visible then tween(borderStroke, {Transparency = borderTarget()}, 0.2) end
	end
	function Window:SetShine(on) Settings.Shine = on; shine.Visible = on end
	function Window:SetFont(name) Settings.Font = name; applyFont() end
	function Window:SetWallpaper(input, transparency)
		if transparency then wallpaper.ImageTransparency = transparency end
		local src, err = resolveImage(input)
		if not src then
			wallpaper.Visible = false
			return false, err
		end
		wallpaper.Image = src
		wallpaper.Visible = true
		return true
	end
	function Window:SetWallpaperAlpha(a) wallpaper.ImageTransparency = a end

	-- smooth tab transition
	local function selectTab(t)
		local cur = Window.Current
		if cur == t then return end
		if cur then
			tween(cur.btn, {BackgroundTransparency = 1}, 0.15)
			tween(cur.lbl, {TextColor3 = Theme.SubText}, 0.15)
			tween(cur.dot, {BackgroundTransparency = 0.7}, 0.15)
			tween(cur.page, {GroupTransparency = 1, Position = UDim2.new(0, -18, 0, 0)}, dur(0.16))
			task.delay(dur(0.17), function()
				if Window.Current ~= cur then cur.page.Visible = false end
			end)
		end
		Window.Current = t
		t.page.Position = UDim2.new(0, 18, 0, 0)
		t.page.GroupTransparency = 1
		t.page.Visible = true
		tween(t.page, {GroupTransparency = 0, Position = UDim2.new(0, 0, 0, 0)}, dur(0.3), Enum.EasingStyle.Quart)
		tween(t.btn, {BackgroundTransparency = Theme.ElemAlpha}, 0.15)
		tween(t.lbl, {TextColor3 = Theme.Text}, 0.15)
		tween(t.dot, {BackgroundTransparency = 0}, 0.15)
		crumb.Text = string.format('<font color="rgb(150,150,178)">%s  /  </font>%s', t.category, t.name)
	end

	function Window:AddCategory(name, icon)
		local Category = {}
		local subs = {}
		local expanded = false
		local subOrder = 0
		catOrder += 1

		local wrap = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = catOrder}, catList)
		list(wrap, 3)

		local header = new("TextButton", {BackgroundColor3 = Theme.Element, BackgroundTransparency = 1,
			AutoButtonColor = false, Text = "", Size = UDim2.new(1, 0, 0, 38), LayoutOrder = 1}, wrap)
		corner(header, 9)
		local iconObj = buildIcon(icon, header)
		txt("TextLabel", {BackgroundTransparency = 1, TextSize = 14, Text = name, TextColor3 = Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 42, 0, 0), Size = UDim2.new(1, -72, 1, 0)}, header, "Bold")
		local arrow = txt("TextLabel", {BackgroundTransparency = 1, TextSize = 18, Text = "›", TextColor3 = Theme.SubText,
			Size = UDim2.new(0, 24, 1, 0), Position = UDim2.new(1, -28, 0, -1)}, header, "Bold")

		local subHolder = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
			ClipsDescendants = true, LayoutOrder = 2}, wrap)
		list(subHolder, 3)
		new("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingTop = UDim.new(0, 2)}, subHolder)

		local function setExpanded(state)
			expanded = state
			local n = #subs
			local h = state and (n * 32 + math.max(n - 1, 0) * 3 + 6) or 0
			tween(subHolder, {Size = UDim2.new(1, 0, 0, h)}, dur(0.3), Enum.EasingStyle.Quart)
			tween(arrow, {Rotation = state and 90 or 0, TextColor3 = state and Theme.AccentB or Theme.SubText}, 0.2)
			tween(header, {BackgroundTransparency = state and Theme.ElemAlpha or 1}, 0.2)
			tween(iconObj, {GroupTransparency = state and 0 or 0.4}, 0.2)
		end

		header.MouseEnter:Connect(function()
			if not expanded then tween(header, {BackgroundTransparency = 0.7}, 0.15) end
		end)
		header.MouseLeave:Connect(function()
			if not expanded then tween(header, {BackgroundTransparency = 1}, 0.15) end
		end)
		header.MouseButton1Click:Connect(function()
			if expanded then
				setExpanded(false)
				Window.OpenCategory = nil
			else
				if Window.OpenCategory then Window.OpenCategory.setExpanded(false) end
				setExpanded(true)
				Window.OpenCategory = {setExpanded = setExpanded}
				if subs[1] and not (Window.Current and Window.Current.category == name) then
					selectTab(subs[1])
				end
			end
		end)

		function Category:AddTab(tabName)
			local Tab = {}
			subOrder += 1

			local btn = new("TextButton", {BackgroundColor3 = Theme.Element, BackgroundTransparency = 1,
				AutoButtonColor = false, Text = "", Size = UDim2.new(1, 0, 0, 32), LayoutOrder = subOrder}, subHolder)
			corner(btn, 8)
			local dot = new("Frame", {BackgroundColor3 = WHITE, BackgroundTransparency = 0.7,
				Size = UDim2.fromOffset(6, 6), Position = UDim2.new(0, 10, 0.5, -3)}, btn)
			corner(dot, 3)
			accent(dot)
			local lbl = txt("TextLabel", {BackgroundTransparency = 1, TextSize = 13, Text = tabName, TextColor3 = Theme.SubText,
				TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 26, 0, 0), Size = UDim2.new(1, -30, 1, 0)}, btn, "Medium")

			local pageGroup = new("CanvasGroup", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
				Visible = false, GroupTransparency = 1}, pages)
			local scroll = new("ScrollingFrame", {BackgroundTransparency = 1, BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 1), ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.AccentA,
				CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y}, pageGroup)
			table.insert(scrollbars, scroll)
			list(scroll, 8)
			new("UIPadding", {PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8)}, scroll)

			local data = {name = tabName, category = name, page = pageGroup, btn = btn, lbl = lbl, dot = dot}
			table.insert(subs, data)
			if expanded then setExpanded(true) end

			btn.MouseButton1Click:Connect(function() selectTab(data) end)
			btn.MouseEnter:Connect(function()
				if Window.Current ~= data then tween(btn, {BackgroundTransparency = 0.75}, 0.15) end
			end)
			btn.MouseLeave:Connect(function()
				if Window.Current ~= data then tween(btn, {BackgroundTransparency = 1}, 0.15) end
			end)

			if not Window.Current then
				selectTab(data)
				task.defer(function()
					if not Window.OpenCategory then
						setExpanded(true)
						Window.OpenCategory = {setExpanded = setExpanded}
					end
				end)
			end

			buildApi(Tab, scroll, false, name .. "/" .. tabName)
			return Tab
		end

		return Category
	end

	return Window
end
