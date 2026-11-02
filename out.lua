--[[
    PIXEL CLIENT v6  |  Luau (Roblox)
    RightShift / watermark (mobile) = menu
    Combat + Movement | Visuals ESP (TSB-style) + online | Cosmetics 3D jump/halo/trail/wings
    GUI: wallpapers + preview, no blur, fast close | Chat EN/RU | Keybinds
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

local Pixel = {}

-- ================= ТЕМА И НАСТРОЙКИ =================
local Theme = {
	Background = Color3.fromRGB(10, 10, 18),
	Element    = Color3.fromRGB(30, 30, 46),
	ElementHi  = Color3.fromRGB(52, 52, 76),
	Text       = Color3.fromRGB(240, 240, 250),
	SubText    = Color3.fromRGB(150, 150, 178),
	AccentA    = Color3.fromRGB(150, 90, 255),
	AccentB    = Color3.fromRGB(255, 80, 160),
	GlassAlpha = 0.28,
	ElemAlpha  = 0.45,
}

local Settings = {
	AnimSpeed = 1, Blur = false, BlurSize = 0, ShadowStrength = 50, Scale = 1, Corner = 14,
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

-- ================= ХЕЛПЕРЫ =================
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
	if r then return Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)) end
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

-- реестры для живой кастомизации
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

-- вращение градиентов + радужный режим
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

-- ================= РЕЕСТР КОНФИГОВ =================
local Flags = {}
local ArrayEntries = {}
local BindMap = {} -- [Enum.KeyCode] = { toggleObj, name }
local BindListening = nil -- toggle obj waiting for key

local ArrayHide = {["Watermark"] = true, ["ArrayList"] = true, ["Target HUD"] = true, ["Предпросмотр (демо)"] = true}

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

local function snapshot()
	local d = {}
	for k, f in pairs(Flags) do d[k] = f.get() end
	return d
end

local function applySnapshot(d)
	for k, v in pairs(d) do
		local f = Flags[k]
		if f then pcall(f.set, v) end
	end
end

Pixel.Config = {}
function Pixel.Config.Encode() return HttpService:JSONEncode(snapshot()) end
function Pixel.Config.ApplyJson(json)
	local ok, d = pcall(function() return HttpService:JSONDecode(json) end)
	if not ok or type(d) ~= "table" then return false end
	applySnapshot(d)
	return true
end
function Pixel.Config.Save(name)
	local json = Pixel.Config.Encode()
	if hasFS then
		ensureDir()
		return pcall(writefile, CFG_DIR .. "/" .. name .. ".json", json)
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
	
-- ======================= 3D JUMP CIRCLES =======================
local JumpC = { on = false, style = 1, cd = 0 }
local JUMP_STYLES = {
	Color3.fromRGB(255, 120, 200),
	Color3.fromRGB(120, 200, 255),
	Color3.fromRGB(255, 220, 80),
}
local function spawnJumpRing(pos)
	local col = JUMP_STYLES[JumpC.style] or JUMP_STYLES[1]
	local p = Instance.new("Part")
	p.Name = "PixelJumpRing"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Material = Enum.Material.Neon
	p.Color = col
	p.Size = Vector3.new(0.3, 0.08, 0.3)
	p.CFrame = CFrame.new(pos + Vector3.new(0, 0.05, 0))
	p.Transparency = 0.2
	p.Parent = workspace
	local mesh = Instance.new("SpecialMesh", p)
	mesh.MeshType = Enum.MeshType.Cylinder
	mesh.Scale = Vector3.new(0.2, 0.15, 0.2)
	-- expand
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < 0.55 do
			local a = (os.clock() - t0) / 0.55
			mesh.Scale = Vector3.new(0.2 + a * 4, 0.12, 0.2 + a * 4)
			p.Transparency = 0.2 + a * 0.8
			task.wait()
		end
		p:Destroy()
	end)
end
connect(UIS.JumpRequest, function()
	if not JumpC.on then return end
	if os.clock() < JumpC.cd then return end
	JumpC.cd = os.clock() + 0.35
	local root = getRoot()
	if not root then return end
	local origin = root.Position
	local ray = workspace:Raycast(origin, Vector3.new(0, -8, 0), RaycastParams.new())
	local pos = ray and ray.Position or (origin - Vector3.new(0, 3, 0))
	spawnJumpRing(pos)
end)
-- add to cosmetics if tab exists
pcall(function()
	cosmetics:AddLabel("—— Jump Circles 3D ——")
	cosmetics:AddToggle("Jump Circles 3D", false, function(on) JumpC.on = on end, function(p)
		p:AddDropdown("Style", {"Pink", "Cyan", "Gold"}, "Pink", function(o)
			JumpC.style = (o == "Cyan" and 2) or (o == "Gold" and 3) or 1
		end)
	end)
end)



return Pixel.Config.ApplyJson(json)
end
function Pixel.Config.Delete(name)
	if hasFS then return pcall(delfile, CFG_DIR .. "/" .. name .. ".json") end
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

-- ================= ТЕНИ (мягкие, 9-slice) =================
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

-- ================= ИКОНКИ =================
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

-- ================= ОБОИ =================
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

-- ================= УВЕДОМЛЕНИЯ =================
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

-- ================= ЭЛЕМЕНТЫ =================
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

	-- произвольный блок (например предпросмотр)
	function api:AddCustom(h)
		return element(h)
	end

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
				pcall(function()
					Pixel:Notify("Bind", "СКМ: нажми клавишу → " .. text, 2.5)
				end)
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

	function api:AddTextbox(text, placeholder, callback, default)
		local f = element(40)
		title(f, text, UDim2.new(0.38, 0, 0, 40))
		local box = txt("TextBox", {BackgroundColor3 = Theme.ElementHi, BackgroundTransparency = 0.3, Text = default or "",
			PlaceholderText = placeholder or "", PlaceholderColor3 = Theme.SubText, TextColor3 = Theme.Text,
			TextSize = 12, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
			ClipsDescendants = true,
			Size = UDim2.new(0.62, -24, 0, 26), Position = UDim2.new(0.38, 10, 0.5, -13)}, f, "Regular")
		corner(box, 6)
		new("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, box)
		box.FocusLost:Connect(function()
			if callback then task.spawn(callback, box.Text) end
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
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
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

-- ================= ОКНО =================
function Pixel:CreateWindow(title)
	local Window = {Current = nil, OpenCategory = nil, Theme = Theme, Settings = Settings, Ready = false}
	local visible = false
	local catOrder = 0
	local pointerInside = false
	local unloadHooks = {}
	local ghostToken = 0
	local savedPos

	local blur = new("BlurEffect", {Size = 0}, Lighting)
	local function setBlur(on, t)
		-- blur removed (мешает)
		pcall(function() blur.Size = 0 end)
	end

	local root = new("Frame", {Name = "Root", BackgroundTransparency = 1, Size = UDim2.fromOffset(700, 440),
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Visible = false}, gui)
	local uiscale = new("UIScale", {Scale = Settings.Scale * 0.9}, root)

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

	txt("TextLabel", {BackgroundTransparency = 1, TextSize = 11, TextColor3 = Theme.SubText, Text = "Pixel Client  v5",
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

	-- блик
	local shine = new("Frame", {BackgroundColor3 = WHITE, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
		ZIndex = 20, Visible = false, Active = false}, main)
	local shineG = new("UIGradient", {Rotation = 25, Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.42, 1), NumberSequenceKeypoint.new(0.5, 0.9),
		NumberSequenceKeypoint.new(0.58, 1), NumberSequenceKeypoint.new(1, 1)})}, shine)

	makeDrag(logoArea, root)
	makeDrag(topbar, root)

	-- ===== курсор над меню: игра не реагирует =====
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

	-- ===== открытие / закрытие (с "призрачным" затуханием) =====
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
			setBlur(false, 0)
		else
			main.Active = false
			savedPos = root.Position
			local g = dur(0.22)
			tween(main, {GroupTransparency = 1}, g, Enum.EasingStyle.Quad)
			tween(root, {Position = savedPos + UDim2.fromOffset(0, -18)}, g, Enum.EasingStyle.Quad)
			tween(uiscale, {Scale = Settings.Scale * 0.94}, g, Enum.EasingStyle.Quad)
			shadow:Set(0, g)
			tween(borderStroke, {Transparency = 1}, g)
			setBlur(false, 0)
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
		blur:Destroy()
		gui:Destroy()
	end

	-- ===== API кастомизации =====
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
	function Window:SetBlur(enabled, size)
		if enabled ~= nil then Settings.Blur = enabled end
		if size then Settings.BlurSize = size end
		if visible then setBlur(true) end
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

	-- ===== плавный переход между вкладками =====
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

	-- ===== категория =====
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

-- ================= ЗАГРУЗОЧНЫЙ ЭКРАН =================
local function runLoader(onReady)
	local overlay = new("Frame", {BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1), Active = true, ZIndex = 50}, gui)
	local lw = new("Frame", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(340, 170)}, overlay)
	local sc = new("UIScale", {Scale = 0.85}, lw)
	local sh = makeShadow(lw, 34, 8)
	sh:Set(0.8)
	local card = new("CanvasGroup", {BackgroundColor3 = Theme.Background, BackgroundTransparency = 0.12,
		Size = UDim2.fromScale(1, 1), GroupTransparency = 1, ZIndex = 1}, lw)
	corner(card, 16)
	local bf = new("Frame", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 5}, lw)
	corner(bf, 16)
	local bs = new("UIStroke", {Color = WHITE, Thickness = 1.5, Transparency = 1}, bf)
	accent(bs, true)

	local logo = new("TextLabel", {BackgroundTransparency = 1, Font = Enum.Font.Arcade, TextSize = 38, Text = "PIXEL",
		TextColor3 = WHITE, Size = UDim2.new(1, 0, 0, 50), Position = UDim2.fromOffset(0, 24)}, card)
	accent(logo, true)
	local status = txt("TextLabel", {BackgroundTransparency = 1, TextSize = 12, Text = "", TextColor3 = Theme.SubText,
		Size = UDim2.new(1, -40, 0, 16), Position = UDim2.fromOffset(20, 96), TextXAlignment = Enum.TextXAlignment.Left}, card, "Medium")
	local pct = txt("TextLabel", {BackgroundTransparency = 1, TextSize = 12, Text = "0%", TextColor3 = Theme.Text,
		Size = UDim2.new(1, -40, 0, 16), Position = UDim2.fromOffset(20, 96), TextXAlignment = Enum.TextXAlignment.Right}, card, "Bold")
	local barBg = new("Frame", {BackgroundColor3 = Theme.ElementHi, Size = UDim2.new(1, -40, 0, 8),
		Position = UDim2.fromOffset(20, 124)}, card)
	corner(barBg, 4)
	local fill = new("Frame", {BackgroundColor3 = WHITE, Size = UDim2.fromScale(0, 1)}, barBg)
	corner(fill, 4)
	accent(fill, true)

	tween(overlay, {BackgroundTransparency = 0.45}, 0.4)
	tween(sc, {Scale = 1}, 0.5, Enum.EasingStyle.Back)
	tween(card, {GroupTransparency = 0}, 0.4)
	tween(bs, {Transparency = 0.2}, 0.4)

	task.spawn(function()
		local steps = {"Инициализация ядра...", "Загрузка темы...", "Сборка интерфейса...",
			"Подготовка шейдеров...", "Косметика и HUD...", "Чтение конфигов...", "Готово!"}
		for i, s in ipairs(steps) do
			status.Text = s
			local r = i / #steps
			tween(fill, {Size = UDim2.fromScale(r, 1)}, 0.35, Enum.EasingStyle.Quart)
			pct.Text = math.floor(r * 100) .. "%"
			task.wait(0.28 + math.random() * 0.2)
		end
		task.wait(0.25)
		tween(sc, {Scale = 1.1}, 0.4)
		tween(card, {GroupTransparency = 1}, 0.4)
		tween(bs, {Transparency = 1}, 0.4)
		tween(overlay, {BackgroundTransparency = 1}, 0.45)
		sh:Set(0, 0.4)
		task.wait(0.35)
		if onReady then onReady() end
		task.wait(0.2)
		overlay:Destroy()
	end)
end

-- =====================================================================
--                              СБОРКА
-- =====================================================================
local Win = Pixel:CreateWindow("PIXEL")
local mouse = LP:GetMouse()
local function getChar() return LP.Character end
local function assetUrl(x)
	local s = (tostring(x or ""):gsub("%s", ""))
	if s == "" then return "" end
	if tonumber(s) then return "rbxassetid://" .. s end
	return s
end

local visuals
local cosmetics
local WM, AL, wmFrame, refreshWM, applyWMPos
local RealESP, pixelOnline, pixelClientUsers
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local Cosm
local mkPart, weld, featherSet
local destroyWings, buildWings, destroyHalo, buildHalo, destroyTrail, buildTrail
local queueWings, queueHalo, queueTrail
-- wingsModel/wingsData outer, haloModel, haloWeld, trailObjs

local function BuildPartA()

do -- CombatMove scope

-- ======================= COMBAT =======================
local combat = Win:AddCategory("Combat", "user")
local combatTab = combat:AddTab("Main")
local Cbt = { aim = false, range = 25, sticky = true, antifling = false }
combatTab:AddLabel("Combat functions")
combatTab:AddToggle("Auto Aim (body)", false, function(on) Cbt.aim = on end, function(p)
	p:AddSlider("Range", 5, 80, 25, function(v) Cbt.range = v end)
	p:AddToggle("Sticky target", true, function(on) Cbt.sticky = on end)
end)
combatTab:AddSlider("Aim Range", 5, 100, 25, function(v) Cbt.range = v end)
combatTab:AddToggle("Anti-Fling", false, function(on) Cbt.antifling = on end)
combatTab:AddLabel("Settings via gear on toggle (ПКМ / long settings)")

-- ======================= MOVEMENT =======================
local movement = Win:AddCategory("Movement", "dots")
local moveTab = movement:AddTab("Main")
local Mov = { speed = false, speedVal = 24, fly = false, flyVal = 50, jump = false }
moveTab:AddLabel("Movement functions")
moveTab:AddToggle("Speed (strict)", false, function(on) Mov.speed = on end, function(p)
	p:AddSlider("Speed value", 16, 80, 24, function(v) Mov.speedVal = v end)
end)
moveTab:AddToggle("Fly", false, function(on) Mov.fly = on end, function(p)
	p:AddSlider("Fly speed", 20, 120, 50, function(v) Mov.flyVal = v end)
end)
moveTab:AddToggle("Inf Jump", false, function(on) Mov.jump = on end)

-- getChar defined earlier
local function getHum()
	local c = getChar()
	return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
	local c = getChar()
	return c and c:FindFirstChild("HumanoidRootPart")
end

local AimRangeRing = Instance.new("Part")
AimRangeRing.Name = "PixelAimRange"
AimRangeRing.Anchored = true
AimRangeRing.CanCollide = false
AimRangeRing.CanQuery = false
AimRangeRing.CanTouch = false
AimRangeRing.Material = Enum.Material.Neon
AimRangeRing.Color = Color3.fromRGB(244, 114, 182)
AimRangeRing.Transparency = 1
AimRangeRing.CastShadow = false
AimRangeRing.Shape = Enum.PartType.Cylinder
AimRangeRing.Size = Vector3.new(0.12, 2, 2)
AimRangeRing.Parent = workspace
pcall(function() Win:OnUnload(function() pcall(function() AimRangeRing:Destroy() end) end) end)

connect(RunService.Heartbeat, function()
	local hum = getHum()
	local root = getRoot()
	-- range under feet
	if Cbt.aim and root then
		local r = math.max(2, tonumber(Cbt.range) or 25)
		AimRangeRing.Size = Vector3.new(0.12, r * 2, r * 2)
		AimRangeRing.CFrame = CFrame.new(root.Position.X, root.Position.Y - 2.9, root.Position.Z)
			* CFrame.Angles(0, 0, math.rad(90))
		AimRangeRing.Transparency = 0.55
	else
		AimRangeRing.Transparency = 1
	end
	-- строгий спид (velocity), как стрейф — без слайда WalkSpeed
	if Mov.speed and root and hum and not Mov.fly then
		local spd = tonumber(Mov.speedVal) or 24
		local move = hum.MoveDirection
		if move.Magnitude > 0.05 then
			local dir = Vector3.new(move.X, 0, move.Z)
			if dir.Magnitude > 0.05 then
				dir = dir.Unit
				local vy = root.AssemblyLinearVelocity.Y
				root.AssemblyLinearVelocity = Vector3.new(dir.X * spd, vy, dir.Z * spd)
			end
		end
	end
	if Cbt.antifling and root then
		if root.AssemblyLinearVelocity.Magnitude > 280 then
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
	end
	if Cbt.aim and root and hum then
		local best, bd = nil, Cbt.range
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LP and plr.Character then
				local r = plr.Character:FindFirstChild("HumanoidRootPart")
				local h = plr.Character:FindFirstChildOfClass("Humanoid")
				if r and h and h.Health > 0 then
					local d = (r.Position - root.Position).Magnitude
					if d < bd then best, bd = r, d end
				end
			end
		end
		if best then
			-- Shift Lock перехватывает поворот — отключаем AutoRotate и крутим HRP сами
			hum.AutoRotate = false
			local pos = best.Position
			local flat = Vector3.new(pos.X, root.Position.Y, pos.Z)
			local look = flat - root.Position
			if look.Magnitude > 0.05 then
				local targetCF = CFrame.new(root.Position, flat)
				-- плавный поворот тела (и в shift lock)
				root.CFrame = root.CFrame:Lerp(targetCF, 0.45)
			end
		end
	elseif hum and not Mov.fly then
		-- без аима возвращаем обычный поворот (shift lock снова сам крутит тело)
		if not hum.AutoRotate then
			hum.AutoRotate = true
		end
	end
end)

-- доп. кадр: в Shift Lock тело доворачивается надёжнее
connect(RunService.RenderStepped, function()
	if not Cbt.aim then return end
	local root = getRoot()
	local hum = getHum()
	if not root or not hum then return end
	local shiftLock = (UIS.MouseBehavior == Enum.MouseBehavior.LockCenter)
	if not shiftLock then return end
	local best, bd = nil, Cbt.range
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP and plr.Character then
			local r = plr.Character:FindFirstChild("HumanoidRootPart")
			local h = plr.Character:FindFirstChildOfClass("Humanoid")
			if r and h and h.Health > 0 then
				local d = (r.Position - root.Position).Magnitude
				if d < bd then best, bd = r, d end
			end
		end
	end
	if not best then return end
	hum.AutoRotate = false
	local flat = Vector3.new(best.Position.X, root.Position.Y, best.Position.Z)
	root.CFrame = CFrame.new(root.Position, flat)
end)

connect(UIS.JumpRequest, function()
	if not Mov.jump then return end
	local hum = getHum()
	if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- Fly loop
local flyBV, flyBG
local function stopFly()
	if flyBV then flyBV:Destroy() flyBV = nil end
	if flyBG then flyBG:Destroy() flyBG = nil end
end
connect(RunService.Heartbeat, function()
	if not Mov.fly then stopFly() return end
	local root = getRoot()
	local hum = getHum()
	if not root or not hum then return end
	if not flyBV then
		flyBV = Instance.new("BodyVelocity")
		flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		flyBV.Parent = root
		flyBG = Instance.new("BodyGyro")
		flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
		flyBG.P = 3000
		flyBG.Parent = root
	end
	local cam = workspace.CurrentCamera
	local dir = Vector3.zero
	if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
	if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
	if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
	if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
	if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
	if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
	if dir.Magnitude > 0 then dir = dir.Unit * Mov.flyVal end
	flyBV.Velocity = dir
	flyBG.CFrame = cam.CFrame
	hum.PlatformStand = true
end)
Win:OnUnload(function() stopFly() local h=getHum() if h then h.PlatformStand=false end end)

end -- CombatMove scope

-- ======================= VISUALS =======================
visuals = Win:AddCategory("Visuals", "eye")


-- ---------- ESP (демо-настройки + предпросмотр) ----------
local ESP = {
	enabled = false,
	style = "Box", colVis = Color3.fromRGB(80, 255, 140), colWall = Color3.fromRGB(255, 80, 120),
	thick = 1, fill = 12, name = true, health = true, dist = true, item = false, maxDist = 500, team = true,
	tracers = false, trOrigin = "Bottom", trColor = Color3.fromRGB(255, 80, 160), trThick = 1, trAlpha = 20,
	chams = false, chamsFill = Color3.fromRGB(150, 90, 255), chamsOutline = WHITE, chamsAlpha = 60,
	through = true, chamsPulse = false, headDot = false, dotSize = 4, dotColor = WHITE, wall = false,
}
local ESPUpdate
local function esU() if ESPUpdate then ESPUpdate() end end

local esp = visuals:AddTab("ESP")
esp:AddLabel("ESP — настройки ниже")
do
	local pv = esp:AddCustom(214)
	pv.ClipsDescendants = true
	local stage = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(14, 14, 24),
		BackgroundTransparency = 0.15, Size = UDim2.new(1, -16, 1, -16), Position = UDim2.fromOffset(8, 8),
		ClipsDescendants = true}, pv)
	corner(stage, 8)
	-- сетка пола
	for i = 1, 6 do
		new("Frame", {BackgroundColor3 = WHITE, BackgroundTransparency = 0.95, BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0, 20 + i * 30)}, stage)
	end

	local tracer = new("Frame", {BackgroundColor3 = WHITE, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
		Visible = false}, stage)

	local boxF = new("Frame", {BackgroundColor3 = WHITE, BackgroundTransparency = 0.9, AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 34), Size = UDim2.fromOffset(74, 134)}, stage)
	local boxStroke = new("UIStroke", {Color = WHITE, Thickness = 1}, boxF)

	local function limb(w, h, dx, y, r)
		local p = new("Frame", {BackgroundColor3 = Color3.fromRGB(120, 120, 140), AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(w, h), Position = UDim2.new(0.5, dx, 0, y)}, boxF)
		corner(p, r or 4)
		local st = new("UIStroke", {Color = WHITE, Thickness = 1.2, Enabled = false}, p)
		return p, st
	end
	local parts = {}
	local function addLimb(...)
		local p, st = limb(...)
		table.insert(parts, {p, st})
		return p
	end
	local head = addLimb(22, 22, 0, 20, 11)
	addLimb(32, 46, 0, 58)
	addLimb(11, 44, -22, 58)
	addLimb(11, 44, 22, 58)
	addLimb(14, 46, -8, 106)
	addLimb(14, 46, 8, 106)

	local dot = new("Frame", {BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, 20), Size = UDim2.fromOffset(8, 8), ZIndex = 4, Visible = false}, boxF)
	corner(dot, 8)

	-- уголки
	local cornerBars = {}
	for cx = 0, 1 do
		for cy = 0, 1 do
			local hb = new("Frame", {BackgroundColor3 = WHITE, BorderSizePixel = 0, AnchorPoint = Vector2.new(cx, cy),
				Position = UDim2.fromScale(cx, cy), Size = UDim2.fromOffset(16, 1), Visible = false}, boxF)
			local vb = new("Frame", {BackgroundColor3 = WHITE, BorderSizePixel = 0, AnchorPoint = Vector2.new(cx, cy),
				Position = UDim2.fromScale(cx, cy), Size = UDim2.fromOffset(1, 16), Visible = false}, boxF)
			table.insert(cornerBars, {hb, vb})
		end
	end

	local nameL = txt("TextLabel", {BackgroundTransparency = 1, TextSize = 12, Text = "Pixel_Player", TextColor3 = WHITE,
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, -3), Size = UDim2.fromOffset(140, 14)}, boxF, "Bold")
	local distL = txt("TextLabel", {BackgroundTransparency = 1, TextSize = 11, Text = "23 studs", TextColor3 = Theme.SubText,
		Position = UDim2.new(0.5, -70, 1, 3), Size = UDim2.fromOffset(140, 13)}, boxF, "Medium")
	local itemL = txt("TextLabel", {BackgroundTransparency = 1, TextSize = 11, Text = "[Sword]", TextColor3 = Color3.fromRGB(255, 220, 120),
		Position = UDim2.new(0.5, -70, 1, 16), Size = UDim2.fromOffset(140, 13)}, boxF, "Medium")
	local hpBg = new("Frame", {BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.4, BorderSizePixel = 0,
		Position = UDim2.new(0, -7, 0, 0), Size = UDim2.new(0, 3, 1, 0)}, boxF)
	local hpFill = new("Frame", {BackgroundColor3 = Color3.fromRGB(80, 255, 120), BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0.72)}, hpBg)
	local tag = txt("TextLabel", {BackgroundTransparency = 1, TextSize = 10, Text = "", TextColor3 = Theme.SubText,
		Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(160, 12), TextXAlignment = Enum.TextXAlignment.Left}, stage, "Medium")

	local function setLine(a, b, th)
		local d = b - a
		tracer.Size = UDim2.fromOffset(d.Magnitude, th)
		tracer.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
		tracer.Rotation = math.deg(math.atan2(d.Y, d.X))
	end

	ESPUpdate = function()
		local col = ESP.wall and ESP.colWall or ESP.colVis
		local isCorner, isFilled = ESP.style == "Corner", ESP.style == "Filled"
		boxStroke.Enabled = not isCorner and not isFilled
		boxStroke.Color = col
		boxStroke.Thickness = ESP.thick
		boxF.BackgroundColor3 = col
		boxF.BackgroundTransparency = 1 - (ESP.fill / 100) * (isFilled and 0.9 or 0.55)
		for _, pair in ipairs(cornerBars) do
			pair[1].Visible = isCorner; pair[2].Visible = isCorner
			pair[1].BackgroundColor3 = col; pair[2].BackgroundColor3 = col
			pair[1].Size = UDim2.fromOffset(16, ESP.thick)
			pair[2].Size = UDim2.fromOffset(ESP.thick, 16)
		end
		nameL.Visible = ESP.name
		distL.Visible = ESP.dist
		itemL.Visible = ESP.item
		itemL.Position = UDim2.new(0.5, -70, 1, ESP.dist and 16 or 3)
		hpBg.Visible = ESP.health
		-- chams
		local pulse = (ESP.chams and ESP.chamsPulse) and ((math.sin(os.clock() * 3) + 1) / 2 * 0.3) or 0
		for _, pr in ipairs(parts) do
			if ESP.chams then
				pr[1].BackgroundColor3 = ESP.chamsFill
				pr[1].BackgroundTransparency = math.clamp(ESP.chamsAlpha / 100 + pulse, 0, 1)
				pr[2].Enabled = true
				pr[2].Color = ESP.chamsOutline
			else
				pr[1].BackgroundColor3 = Color3.fromRGB(120, 120, 140)
				pr[1].BackgroundTransparency = 0.15
				pr[2].Enabled = false
			end
		end
		dot.Visible = ESP.headDot
		dot.Size = UDim2.fromOffset(ESP.dotSize * 2, ESP.dotSize * 2)
		dot.BackgroundColor3 = ESP.dotColor
		-- трейсер
		local S = stage.AbsoluteSize
		if ESP.tracers and S.X > 0 then
			local a
			if ESP.trOrigin == "Bottom" then a = Vector2.new(S.X / 2, S.Y)
			elseif ESP.trOrigin == "Center" then a = Vector2.new(S.X / 2, S.Y / 2 - 20)
			else a = Vector2.new(S.X * 0.86, 40) end
			tracer.Visible = true
			tracer.BackgroundColor3 = ESP.trColor
			tracer.BackgroundTransparency = ESP.trAlpha / 100
			setLine(a, Vector2.new(S.X / 2, 34 + 134), ESP.trThick)
		else
			tracer.Visible = false
		end
		tag.Text = ESP.wall and "за стеной" or "в зоне видимости"
		tag.TextColor3 = col
	end
	stage:GetPropertyChangedSignal("AbsoluteSize"):Connect(esU)
	stage.MouseButton1Click:Connect(function() ESP.wall = not ESP.wall; esU() end)
	connect(RunService.Heartbeat, function()
		if ESP.chams and ESP.chamsPulse then esU() end
	end)
	task.defer(esU)
end

esp:AddLabel("ПКМ / двойной клик — настройки")
esp:AddToggle("Player ESP", false, function(on) ESP.enabled = on end, function(p)
	p:AddLabel("Бокс")
	p:AddDropdown("Стиль", {"Box", "Corner", "Filled"}, "Box", function(o) ESP.style = o; esU() end)
	p:AddColorPicker("Цвет (видим)", ESP.colVis, function(c) ESP.colVis = c; esU() end)
	p:AddColorPicker("Цвет (за стеной)", ESP.colWall, function(c) ESP.colWall = c; esU() end)
	p:AddSlider("Толщина линий", 1, 5, 1, function(v) ESP.thick = v; esU() end, 0.5)
	p:AddSlider("Заливка (%)", 0, 100, 12, function(v) ESP.fill = v; esU() end)
	p:AddLabel("Информация")
	p:AddToggle("Имя", true, function(on) ESP.name = on; esU() end)
	p:AddToggle("Здоровье", true, function(on) ESP.health = on; esU() end)
	p:AddToggle("Дистанция", true, function(on) ESP.dist = on; esU() end)
	p:AddToggle("Предмет в руке", false, function(on) ESP.item = on; esU() end)
	p:AddLabel("Фильтры")
	p:AddSlider("Макс. дистанция", 50, 2000, 500, function(v) ESP.maxDist = v end)
	p:AddToggle("Team check", true, function(on) ESP.team = on end)
end)
esp:AddToggle("Tracers", false, function(on) ESP.tracers = on; esU() end, function(p)
	p:AddDropdown("Начало линии", {"Bottom", "Center", "Mouse"}, "Bottom", function(o) ESP.trOrigin = o; esU() end)
	p:AddColorPicker("Цвет", ESP.trColor, function(c) ESP.trColor = c; esU() end)
	p:AddSlider("Толщина", 1, 5, 1, function(v) ESP.trThick = v; esU() end, 0.5)
	p:AddSlider("Прозрачность (%)", 0, 100, 20, function(v) ESP.trAlpha = v; esU() end)
end)
esp:AddToggle("Chams", false, function(on) ESP.chams = on; esU() end, function(p)
	p:AddColorPicker("Заливка", ESP.chamsFill, function(c) ESP.chamsFill = c; esU() end)
	p:AddColorPicker("Контур", ESP.chamsOutline, function(c) ESP.chamsOutline = c; esU() end)
	p:AddSlider("Прозрачность заливки (%)", 0, 100, 60, function(v) ESP.chamsAlpha = v; esU() end)
	p:AddToggle("Через стены", true, function(on) ESP.through = on end)
	p:AddToggle("Пульсация", false, function(on) ESP.chamsPulse = on; esU() end)
end)
esp:AddToggle("Head Dot", false, function(on) ESP.headDot = on; esU() end, function(p)
	p:AddSlider("Размер", 1, 12, 4, function(v) ESP.dotSize = v; esU() end)
	p:AddColorPicker("Цвет", ESP.dotColor, function(c) ESP.dotColor = c; esU() end)
end)
esp:AddToggle("Предпросмотр: за стеной", false, function(on) ESP.wall = on; esU() end, nil, true)

-- ---------- SHADERS ----------
local origLighting = {
	ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, Exposure = Lighting.ExposureCompensation,
	Shadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient, Outdoor = Lighting.OutdoorAmbient,
	FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart,
}
local SH = {
	bloom = {on = false, i = 0.6, s = 24, t = 0.9},
	rays  = {on = false, i = 0.15, s = 0.6},
	cc    = {on = false, b = 0, c = 0.1, s = 0.1, tint = WHITE},
	dof   = {on = false, far = 0.25, focus = 45, radius = 30},
	atm   = {on = false, d = 0.35, h = 1.2, color = Color3.fromRGB(199, 214, 255)},
}
local function fx(class, name)
	local o = Lighting:FindFirstChild(name)
	if not o then o = Instance.new(class); o.Name = name; o.Parent = Lighting end
	return o
end
local function applyBloom()
	local b = fx("BloomEffect", "PixelBloom")
	b.Enabled = SH.bloom.on; b.Intensity = SH.bloom.i; b.Size = SH.bloom.s; b.Threshold = SH.bloom.t
end
local function applyRays()
	local r = fx("SunRaysEffect", "PixelRays")
	r.Enabled = SH.rays.on; r.Intensity = SH.rays.i; r.Spread = SH.rays.s
end
local function applyCC()
	local c = fx("ColorCorrectionEffect", "PixelColor")
	c.Enabled = SH.cc.on; c.Brightness = SH.cc.b; c.Contrast = SH.cc.c; c.Saturation = SH.cc.s; c.TintColor = SH.cc.tint
end
local function applyDof()
	local d = fx("DepthOfFieldEffect", "PixelDOF")
	d.Enabled = SH.dof.on; d.FarIntensity = SH.dof.far; d.FocusDistance = SH.dof.focus
	d.InFocusRadius = SH.dof.radius; d.NearIntensity = 0
end
local atmOriginal, atmCreated
local function applyAtm()
	local a = Lighting:FindFirstChildOfClass("Atmosphere")
	if SH.atm.on then
		if not a then
			a = Instance.new("Atmosphere"); a.Name = "PixelAtmosphere"; a.Parent = Lighting
			atmCreated = a
		elseif a ~= atmCreated and not atmOriginal then
			atmOriginal = {Density = a.Density, Haze = a.Haze, Color = a.Color}
		end
		a.Density = SH.atm.d; a.Haze = SH.atm.h; a.Color = SH.atm.color
	else
		if atmCreated and atmCreated.Parent then
			atmCreated:Destroy(); atmCreated = nil
		elseif a and atmOriginal then
			a.Density = atmOriginal.Density; a.Haze = atmOriginal.Haze; a.Color = atmOriginal.Color
			atmOriginal = nil
		end
	end
end

local C = {}

local ShaderPresets = {
	Off = {},
	Cinematic = {
		time = 17.2,
		bloom = {i = 0.5, s = 24, t = 0.95}, rays = {i = 0.12, s = 0.5},
		cc = {b = 0, c = 0.18, s = -0.12, tint = rgb(255, 236, 216)},
		dof = {far = 0.2, focus = 50, radius = 35}, atm = {d = 0.3, h = 1.2, color = rgb(199, 190, 180)},
	},
	Realistic = {
		time = 14,
		bloom = {i = 0.25, s = 20, t = 1.1}, rays = {i = 0.08, s = 0.45},
		cc = {b = 0, c = 0.08, s = 0.05, tint = rgb(255, 250, 244)},
		dof = nil, atm = {d = 0.28, h = 0.8, color = rgb(190, 208, 235)},
	},
	Vivid = {
		bloom = {i = 0.5, s = 20, t = 1}, rays = {i = 0.15, s = 0.6},
		cc = {b = 0.02, c = 0.2, s = 0.5, tint = WHITE},
	},
	Noir = {
		time = 21,
		bloom = {i = 0.3, s = 16, t = 1.2},
		cc = {b = -0.03, c = 0.38, s = -1, tint = rgb(235, 235, 245)},
		dof = {far = 0.3, focus = 40, radius = 25}, atm = {d = 0.4, h = 2, color = rgb(120, 120, 130)},
	},
	Dream = {
		time = 18,
		bloom = {i = 1.2, s = 40, t = 0.7}, rays = {i = 0.25, s = 0.8},
		cc = {b = 0.03, c = 0.05, s = 0.25, tint = rgb(255, 220, 245)},
		dof = {far = 0.4, focus = 30, radius = 20}, atm = {d = 0.35, h = 2.5, color = rgb(255, 200, 230)},
	},
	Cyberpunk = {
		time = 22,
		bloom = {i = 1.1, s = 36, t = 0.7},
		cc = {b = -0.02, c = 0.3, s = 0.45, tint = rgb(255, 170, 255)},
		dof = {far = 0.25, focus = 60, radius = 40}, atm = {d = 0.38, h = 2.2, color = rgb(120, 70, 190)},
	},
	Sunset = {
		time = 17.8,
		bloom = {i = 0.7, s = 30, t = 0.85}, rays = {i = 0.35, s = 0.9},
		cc = {b = 0.02, c = 0.12, s = 0.3, tint = rgb(255, 205, 160)},
		atm = {d = 0.33, h = 2.0, color = rgb(255, 180, 130)},
	},
	Frozen = {
		time = 12,
		bloom = {i = 0.6, s = 28, t = 0.9}, rays = {i = 0.1, s = 0.6},
		cc = {b = 0.02, c = 0.1, s = -0.15, tint = rgb(200, 225, 255)},
		atm = {d = 0.45, h = 2.5, color = rgb(210, 230, 255)},
	},
	Retro = {
		time = 19,
		bloom = {i = 0.9, s = 34, t = 0.8},
		cc = {b = 0.04, c = -0.05, s = 0.35, tint = rgb(255, 200, 235)},
		dof = {far = 0.15, focus = 55, radius = 40},
	},
	Horror = {
		time = 23.5,
		bloom = {i = 0.2, s = 14, t = 1.3},
		cc = {b = -0.06, c = 0.3, s = -0.5, tint = rgb(190, 215, 190)},
		dof = {far = 0.35, focus = 30, radius = 18}, atm = {d = 0.5, h = 3, color = rgb(80, 95, 85)},
	},
}
local PresetNames = {"Off", "Cinematic", "Realistic", "Vivid", "Noir", "Dream", "Cyberpunk", "Sunset", "Frozen", "Retro", "Horror"}

local function applyPreset(name)
	local p = ShaderPresets[name]
	if not p then return end
	local b = p.bloom
	C.bloomOn:Set(b ~= nil)
	if b then C.bloomI:Set(b.i or 0.6); C.bloomS:Set(b.s or 24); C.bloomT:Set(b.t or 0.9) end
	local r = p.rays
	C.raysOn:Set(r ~= nil)
	if r then C.raysI:Set(r.i or 0.15); C.raysS:Set(r.s or 0.6) end
	local c = p.cc
	C.ccOn:Set(c ~= nil)
	if c then C.ccB:Set(c.b or 0); C.ccC:Set(c.c or 0.1); C.ccS:Set(c.s or 0.1); C.ccT:Set(c.tint or WHITE) end
	local d = p.dof
	C.dofOn:Set(d ~= nil)
	if d then C.dofF:Set(d.far or 0.25); C.dofD:Set(d.focus or 45); C.dofR:Set(d.radius or 30) end
	local a = p.atm
	C.atmOn:Set(a ~= nil)
	if a then C.atmD:Set(a.d or 0.35); C.atmH:Set(a.h or 1.2); C.atmC:Set(a.color or SH.atm.color) end
	if p.time then C.time:Set(p.time) end
end

local shaders = visuals:AddTab("Shaders")
shaders:AddLabel("Пресет")
shaders:AddDropdown("Шейдер-пресет", PresetNames, "Off", applyPreset, true)

shaders:AddLabel("Эффекты (ПКМ / двойной клик - настройки)")
local function reapplyAllShaders()
	pcall(applyBloom)
	pcall(applyRays)
	pcall(applyCC)
	pcall(applyDof)
	pcall(applyAtm)
end
-- шейдеры не слетают после ресета персонажа
connect(LP.CharacterAdded, function()
	task.defer(function()
		task.wait(0.3)
		reapplyAllShaders()
	end)
end)
-- подстраховка: если lighting сбросили
task.spawn(function()
	while gui and gui.Parent do
		task.wait(2)
		if SH.bloom.on or SH.rays.on or SH.cc.on or SH.dof.on or SH.atm.on then
			reapplyAllShaders()
		end
	end
end)

C.bloomOn = shaders:AddToggle("Bloom", false, function(on) SH.bloom.on = on; applyBloom() end, function(p)
	C.bloomI = p:AddSlider("Intensity", 0, 3, 0.6, function(v) SH.bloom.i = v; applyBloom() end, 0.05)
	C.bloomS = p:AddSlider("Size", 0, 56, 24, function(v) SH.bloom.s = v; applyBloom() end)
	C.bloomT = p:AddSlider("Threshold", 0, 2, 0.9, function(v) SH.bloom.t = v; applyBloom() end, 0.05)
end)
C.raysOn = shaders:AddToggle("Sun Rays", false, function(on) SH.rays.on = on; applyRays() end, function(p)
	C.raysI = p:AddSlider("Intensity", 0, 1, 0.15, function(v) SH.rays.i = v; applyRays() end, 0.05)
	C.raysS = p:AddSlider("Spread", 0, 1, 0.6, function(v) SH.rays.s = v; applyRays() end, 0.05)
end)
C.ccOn = shaders:AddToggle("Color Grading", false, function(on) SH.cc.on = on; applyCC() end, function(p)
	C.ccB = p:AddSlider("Brightness", -0.5, 0.5, 0, function(v) SH.cc.b = v; applyCC() end, 0.01)
	C.ccC = p:AddSlider("Contrast", -0.5, 1, 0.1, function(v) SH.cc.c = v; applyCC() end, 0.05)
	C.ccS = p:AddSlider("Saturation", -1, 1, 0.1, function(v) SH.cc.s = v; applyCC() end, 0.05)
	C.ccT = p:AddColorPicker("Tint", WHITE, function(c) SH.cc.tint = c; applyCC() end)
end)
C.dofOn = shaders:AddToggle("Depth of Field", false, function(on) SH.dof.on = on; applyDof() end, function(p)
	C.dofF = p:AddSlider("Far intensity", 0, 1, 0.25, function(v) SH.dof.far = v; applyDof() end, 0.05)
	C.dofD = p:AddSlider("Focus distance", 5, 200, 45, function(v) SH.dof.focus = v; applyDof() end)
	C.dofR = p:AddSlider("In-focus radius", 0, 100, 30, function(v) SH.dof.radius = v; applyDof() end)
end)
C.atmOn = shaders:AddToggle("Atmosphere", false, function(on) SH.atm.on = on; applyAtm() end, function(p)
	C.atmD = p:AddSlider("Density", 0, 1, 0.35, function(v) SH.atm.d = v; applyAtm() end, 0.01)
	C.atmH = p:AddSlider("Haze", 0, 10, 1.2, function(v) SH.atm.h = v; applyAtm() end, 0.1)
	C.atmC = p:AddColorPicker("Color", SH.atm.color, function(c) SH.atm.color = c; applyAtm() end)
end)

shaders:AddLabel("Мир")
C.time = shaders:AddSlider("Время суток", 0, 24, math.floor(origLighting.ClockTime * 10) / 10, function(v) Lighting.ClockTime = v end, 0.1)
shaders:AddSlider("Яркость", 0, 6, math.floor(origLighting.Brightness * 10) / 10, function(v) Lighting.Brightness = v end, 0.1)
shaders:AddSlider("Экспозиция", -3, 3, math.floor(origLighting.Exposure * 10) / 10, function(v) Lighting.ExposureCompensation = v end, 0.1)
shaders:AddToggle("Глобальные тени", origLighting.Shadows, function(on) Lighting.GlobalShadows = on end)
shaders:AddToggle("Fullbright", false, function(on)
	if on then
		Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 1e5
		Lighting.GlobalShadows = false; Lighting.Ambient = WHITE; Lighting.OutdoorAmbient = WHITE
	else
		Lighting.Brightness = origLighting.Brightness; Lighting.ClockTime = origLighting.ClockTime
		Lighting.FogEnd = origLighting.FogEnd; Lighting.GlobalShadows = origLighting.Shadows
		Lighting.Ambient = origLighting.Ambient; Lighting.OutdoorAmbient = origLighting.Outdoor
	end
end)

Win:OnUnload(function()
	for _, n in ipairs({"PixelBloom", "PixelRays", "PixelColor", "PixelDOF"}) do
		local o = Lighting:FindFirstChild(n)
		if o then o:Destroy() end
	end
	SH.atm.on = false; applyAtm()
	Lighting.ClockTime = origLighting.ClockTime; Lighting.Brightness = origLighting.Brightness
	Lighting.ExposureCompensation = origLighting.Exposure; Lighting.GlobalShadows = origLighting.Shadows
	Lighting.Ambient = origLighting.Ambient; Lighting.OutdoorAmbient = origLighting.Outdoor
	Lighting.FogEnd = origLighting.FogEnd; Lighting.FogStart = origLighting.FogStart
end)

-- ---------- COSMETICS ----------
Cosm = {
	wings = {on = false, style = "Angel", size = 1, colorA = rgb(255, 255, 255), colorB = rgb(170, 200, 255),
		material = "Neon", transparency = 0, speed = 3, amount = 14, open = 24, wave = 10, glow = false, react = true},
	halo  = {on = false, color = rgb(255, 225, 120), size = 1, height = 1.3, glow = true},
	trail = {on = false, colorA = rgb(150, 90, 255), colorB = rgb(255, 80, 160), life = 0.8, trans = 0.2},
}

mkPart = function(size, color, material, transparency, parent, shape)
	local p = Instance.new("Part")
	p.Size = size; p.Color = color; p.Material = material; p.Transparency = transparency
	p.CanCollide = false; p.CanTouch = false; p.CanQuery = false; p.Massless = true
	p.CastShadow = false; p.Anchored = false
	if shape == "sphere" then
		new("SpecialMesh", {MeshType = Enum.MeshType.Sphere}, p) -- эллипсоид: мягкая форма пера
	end
	p.Parent = parent
	return p
end
weld = function(p0, p1, c0)
	local w = Instance.new("Weld")
	w.Part0 = p0; w.Part1 = p1; w.C0 = c0
	w.Parent = p0
	return w
end

-- описания крыльев: каждое перо = {ox, oy, theta(рад), length, width, thickness, rowZ, colorT, shape}
featherSet = function(style, size)
	local F = {}
	local function add(ox, oy, deg, len, wid, th, z, ct, shape)
		table.insert(F, {ox = ox * size, oy = oy * size, th = math.rad(deg), len = len * size, wid = wid * size,
			thick = th, z = z, ct = ct, shape = shape or "sphere"})
	end
	if style == "Angel" then
		-- три ряда перьев веером: верхний ряд - длинные, нижние - короче
		for row = 1, 3 do
			local rs = ({1, 0.78, 0.55})[row]
			local n = ({9, 8, 6})[row]
			for i = 0, n - 1 do
				local f = i / (n - 1)
				local deg = 78 - 150 * f + (row - 1) * 4
				local lf = 0.55 + 0.45 * math.sin(math.pi * (0.1 + 0.8 * f))
				add(0.2, 0.1 + (row - 1) * 0.1, deg, 5.2 * rs * lf, 0.78 * rs + 0.1, 0.06, -(row - 1) * 0.06, f * 0.9 + (row - 1) * 0.05)
			end
		end
		-- "рука" крыла
		add(0, 0, 70, 2.6, 0.32, 0.12, 0.06, 0, "block")
	elseif style == "Demon" then
		-- кость + пальцы + перепонка
		add(0, 0, 62, 3.4, 0.22, 0.12, 0.05, 0, "block")
		local bx, by = math.cos(math.rad(62)) * 3.4, math.sin(math.rad(62)) * 3.4
		local fingers = {{80, 4.8}, {48, 5.8}, {16, 5.6}, {-16, 4.7}, {-46, 3.6}}
		for i, fg in ipairs(fingers) do
			add(bx * size / size, by, fg[1], fg[2], 0.14, 0.1, 0.04, i / #fingers, "block")
		end
		for i = 1, #fingers - 1 do
			local a1, a2 = math.rad(fingers[i][1]), math.rad(fingers[i + 1][1])
			local l = (fingers[i][2] + fingers[i + 1][2]) / 2 * 0.72
			add(bx, by, math.deg((a1 + a2) / 2), l, 1.9, 0.04, -0.02, 0.5 + i * 0.1, "sphere")
		end
	elseif style == "Cyber" then
		for row = 1, 2 do
			local n = ({7, 6})[row]
			for i = 0, n - 1 do
				local f = i / (n - 1)
				local deg = 66 - 118 * f
				local len = (4.6 - 1.4 * f) * (row == 1 and 1 or 0.7)
				add(0.2, 0.1, deg, len, 0.5, 0.1, -(row - 1) * 0.05, f, "block")
			end
		end
	end
	return F
end

destroyWings = function()
	if wingsModel then wingsModel:Destroy() end
	wingsModel, wingsData = nil, nil
end

buildWings = function()
	destroyWings()
	local char = getChar()
	if not char then return end
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	if not torso then return end
	local W = Cosm.wings
	local mat = Enum.Material[W.material] or Enum.Material.Neon
	local model = Instance.new("Model")
	model.Name = "PixelWings"
	local data = {}

	for _, side in ipairs({1, -1}) do
		local rootPart = mkPart(Vector3.new(0.2, 0.2, 0.2), WHITE, Enum.Material.SmoothPlastic, 1, model)
		local base = CFrame.new(side * 0.35, 0.4, torso.Size.Z / 2 + 0.12)
		local w = weld(torso, rootPart, base)
		local sd = {weld = w, base = base, feathers = {}}
		data[side] = sd

		local function feather(f, idx, total)
			local color = W.colorA:Lerp(W.colorB, math.clamp(f.ct, 0, 1))
			local tr = W.transparency
			if f.shape == "sphere" and (W.style == "Demon" or W.style == "Fairy") and f.thick < 0.06 then tr = math.clamp(tr + 0.4, 0, 0.95) end
			local p = mkPart(Vector3.new(f.len, f.wid, f.thick), color, mat, tr, model, f.shape == "sphere" and "sphere" or nil)
			local fw = weld(rootPart, p, CFrame.new())
			table.insert(sd.feathers, {weld = fw, f = f, phase = idx / total})
		end

		if W.style == "Fairy" then
			-- два эллипса-лепестка на каждой стороне + прожилки
			local lobes = {
				{2.4, 1.9, 4.4, 3.0, 28, 0.00, W.colorA},
				{1.9, -0.9, 3.2, 2.2, -28, 0.03, W.colorB},
			}
			for _, l in ipairs(lobes) do
				local p = mkPart(Vector3.new(l[3] * W.size, l[4] * W.size, 0.04), l[7], mat,
					math.clamp(W.transparency + 0.3, 0, 0.95), model, "sphere")
				local rot = (side == 1) and math.rad(l[5]) or -math.rad(l[5])
				weld(rootPart, p, CFrame.new(side * l[1] * W.size, l[2] * W.size, l[6]) * CFrame.Angles(0, 0, rot))
			end
			for k = 1, 4 do
				local deg = 20 + k * 14
				local len = 3.4 * W.size
				local th = math.rad(deg)
				local p = mkPart(Vector3.new(len, 0.05, 0.05), W.colorB:Lerp(WHITE, 0.4), mat, math.clamp(W.transparency, 0, 0.9), model, "block")
				local rot = (side == 1) and th or (math.pi - th)
				weld(rootPart, p, CFrame.new(side * math.cos(th) * len / 2, math.sin(th) * len / 2 + 0.2, 0.03) * CFrame.Angles(0, 0, rot))
			end
		else
			local set = featherSet(W.style, W.size)
			for i, f in ipairs(set) do feather(f, i, #set) end
		end

		if W.glow then
			new("PointLight", {Color = W.colorA, Brightness = 1.2, Range = 10}, rootPart)
		end
	end

	model.Parent = char
	wingsModel, wingsData = model, data
end

-- нимб
-- halo outer
destroyHalo = function()
	if haloModel then haloModel:Destroy() end
	haloModel, haloWeld = nil, nil
end
buildHalo = function()
	destroyHalo()
	local char = getChar()
	local head = char and char:FindFirstChild("Head")
	if not head then return end
	local H = Cosm.halo
	local model = Instance.new("Model")
	model.Name = "PixelHalo"
	local rootPart = mkPart(Vector3.new(0.2, 0.2, 0.2), WHITE, Enum.Material.SmoothPlastic, 1, model)
	haloWeld = weld(head, rootPart, CFrame.new(0, H.height, 0))
	local N, r = 28, 0.95 * H.size
	local segLen = 2 * math.pi * r / N * 1.15
	for k = 0, N - 1 do
		local a = k / N * math.pi * 2
		local seg = mkPart(Vector3.new(0.14, 0.14, segLen), H.color, Enum.Material.Neon, 0, model)
		weld(rootPart, seg, CFrame.new(math.cos(a) * r, 0, math.sin(a) * r) * CFrame.Angles(0, -a, 0))
	end
	if H.glow then new("PointLight", {Color = H.color, Brightness = 1.5, Range = 9}, rootPart) end
	model.Parent = char
	haloModel = model
end

-- трейл
-- trailObjs outer
destroyTrail = function()
	if trailObjs then for _, o in ipairs(trailObjs) do o:Destroy() end end
	trailObjs = nil
end
buildTrail = function()
	destroyTrail()
	local char = getChar()
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local T = Cosm.trail
	local a0 = new("Attachment", {Name = "PixelTrailA", Position = Vector3.new(0, 0.9, 0)}, hrp)
	local a1 = new("Attachment", {Name = "PixelTrailB", Position = Vector3.new(0, -0.9, 0)}, hrp)
	local tr = new("Trail", {Attachment0 = a0, Attachment1 = a1, Lifetime = T.life,
		Color = ColorSequence.new(T.colorA, T.colorB), Transparency = NumberSequence.new(T.trans, 1),
		LightEmission = 1, FaceCamera = true, MinLength = 0.05}, hrp)
	trailObjs = {a0, a1, tr}
end

local wingsQueued, haloQueued, trailQueued = false, false, false
queueWings = function()
	if wingsQueued then return end
	wingsQueued = true
	task.delay(0.12, function() wingsQueued = false; if Cosm.wings.on then buildWings() end end)
end
queueHalo = function()
	if haloQueued then return end
	haloQueued = true
	task.delay(0.12, function() haloQueued = false; if Cosm.halo.on then buildHalo() end end)
end
queueTrail = function()
	if trailQueued then return end
	trailQueued = true
	task.delay(0.12, function() trailQueued = false; if Cosm.trail.on then buildTrail() end end)
end

-- анимация (взмах + волна по перьям)
connect(RunService.RenderStepped, function()
	local t = os.clock()
	if wingsData then
		local W = Cosm.wings
		local char = getChar()
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local air = hum and hum.FloorMaterial == Enum.Material.Air
		local boost = (W.react and air) and 1 or 0
		local flap = math.sin(t * W.speed * (1 + boost * 0.8)) * W.amount * (1 + boost * 1.0)
		local waveAmp = math.rad(W.wave) * (1 + boost * 0.6)
		for side, d in pairs(wingsData) do
			d.weld.C0 = d.base * CFrame.Angles(0, -side * math.rad(W.open + flap), 0)
			for _, fe in ipairs(d.feathers) do
				local f = fe.f
				local w = math.sin(t * W.speed * (1 + boost * 0.8) - fe.phase * 2.2) * waveAmp * (0.4 + fe.phase)
				local th = f.th + w
				local rot = (side == 1) and th or (math.pi - th)
				fe.weld.C0 = CFrame.new(side * f.ox, f.oy, f.z) * CFrame.Angles(0, 0, rot) * CFrame.new(f.len / 2, 0, 0)
			end
		end
	end
	if haloWeld then
		local H = Cosm.halo
		haloWeld.C0 = CFrame.new(0, H.height + math.sin(t * 2) * 0.06, 0)
			* CFrame.Angles(math.sin(t * 1.5) * 0.07, t * 0.5, math.cos(t * 1.3) * 0.07)
	end
end)

connect(LP.CharacterAdded, function(char)
	char:WaitForChild("Humanoid")
	task.wait(0.6)
	if Cosm.wings.on then buildWings() end
	if Cosm.halo.on then buildHalo() end
	if Cosm.trail.on then buildTrail() end
end)

Win:OnUnload(function() destroyWings(); destroyHalo(); destroyTrail() end)


do -- RealESP scope

-- ---------- REAL ESP + ONLINE (from TSB) ----------
RealESP = {
	on = false, box = true, name = true, hp = true, dist = true, char = true, tags = true,
	online = true, maxDist = 800,
}
pixelOnline = {}
local realEspCache = {} -- [Player] = drawings/gui

local function detectCharName(char)
	if not char then return nil end
	for _, obj in ipairs(char:GetChildren()) do
		if obj:IsA("Tool") or obj:IsA("Model") then
			local n = string.lower(obj.Name)
			if n:find("saitama") or n:find("caped") then return "Saitama" end
			if n:find("garou") then return "Garou" end
			if n:find("genos") then return "Genos" end
			if n:find("sonic") then return "Sonic" end
			if n:find("metal") then return "Metal Bat" end
			if n:find("atomic") then return "Atomic" end
			if n:find("tatsumaki") or n:find("tornado") then return "Tatsumaki" end
			if n:find("kj") then return "KJ" end
		end
	end
	local a = char:GetAttribute("Character") or char:GetAttribute("Char")
	return a and tostring(a) or nil
end

local useDrawing = false -- Billboard ESP (PC + Mobile)
local function clearRealEsp(plr)
	local c = realEspCache[plr]
	if not c then return end
	if c.mobile then
		pcall(function() if c.bb then c.bb:Destroy() end end)
		pcall(function() if c.hl then c.hl:Destroy() end end)
	else
		for k, v in pairs(c) do
			if k ~= "mobile" then pcall(function() v:Remove() end) end
		end
	end
	realEspCache[plr] = nil
end

local function ensureRealEsp(plr)
	if realEspCache[plr] then return realEspCache[plr] end
	if useDrawing then
		local ok, pack = pcall(function()
			local function T()
				local d = Drawing.new("Text")
				d.Center = true; d.Outline = true; d.Size = 14; d.Visible = false
				return d
			end
			local function S()
				local d = Drawing.new("Square")
				d.Filled = false; d.Thickness = 1; d.Visible = false
				return d
			end
			local box, boxO = S(), S()
			boxO.Thickness = 3; boxO.Color = Color3.new(0,0,0)
			local hpBg, hp = S(), S()
			hpBg.Filled = true; hp.Filled = true
			hpBg.Color = Color3.new(0,0,0)
			return {
				mobile = false, box = box, boxO = boxO, name = T(), char = T(), dist = T(),
				hpBg = hpBg, hp = hp,
			}
		end)
		if ok and pack then realEspCache[plr] = pack return pack end
	end
	-- mobile billboard fallback
	local bb = Instance.new("BillboardGui")
	bb.Name = "PixelESP"
	bb.Size = UDim2.fromOffset(160, 54)
	bb.AlwaysOnTop = true
	bb.StudsOffset = Vector3.new(0, 3.2, 0)
	bb.MaxDistance = 2000
	local nameL = Instance.new("TextLabel", bb)
	nameL.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	nameL.BackgroundTransparency = 0.45
	nameL.Size = UDim2.new(1, 0, 1, 0)
	nameL.TextColor3 = WHITE
	nameL.TextStrokeTransparency = 0.3
	nameL.Font = Enum.Font.GothamBold
	nameL.TextSize = 13
	nameL.Text = ""
	nameL.TextYAlignment = Enum.TextYAlignment.Center
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = nameL
	local hl = Instance.new("Highlight")
	hl.FillTransparency = 0.75
	hl.OutlineTransparency = 0.2
	hl.FillColor = Color3.fromRGB(255, 100, 160)
	hl.OutlineColor = Color3.fromRGB(255, 100, 160)
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	realEspCache[plr] = { mobile = true, bb = bb, nameL = nameL, hl = hl }
	return realEspCache[plr]
end

local function worldToScreen(v3)
	local cam = workspace.CurrentCamera
	if not cam then return nil end
	local v, on = cam:WorldToViewportPoint(v3)
	if not on or v.Z < 0 then return nil end
	return Vector2.new(v.X, v.Y), v.Z
end

connect(RunService.RenderStepped, function()
	if not ESP.enabled then
		for p in pairs(realEspCache) do clearRealEsp(p) end
		return
	end
	local myRoot = getRoot()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local seen = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP then
			local char = plr.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if root and hum and hum.Health > 0 then
				local dist = myRoot and (root.Position - myRoot.Position).Magnitude or 0
				if dist <= (ESP.maxDist or RealESP.maxDist or 500) then
					seen[plr] = true
					local pack = ensureRealEsp(plr)
					local cname = detectCharName(char)
					local isOnline = pixelOnline[plr] == true or (char:GetAttribute("PixelsClientUser") == true)
					local nameStr = ""
					if (ESP.name ~= false) or RealESP.name then nameStr = plr.DisplayName end
					if isOnline then nameStr = (nameStr ~= "" and nameStr.." " or "") .. "[ONLINE]" end
					local distStr = (ESP.dist ~= false) and (math.floor(dist) .. "m") or ""
					local charStr = cname or ""
					local hpPct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)

					if pack.mobile then
						if pack.bb.Parent ~= char then
							pack.bb.Adornee = char:FindFirstChild("Head") or root
							pack.bb.Parent = char
						end
						if pack.hl and pack.hl.Parent ~= char then
							pack.hl.Parent = char
							pack.hl.Adornee = char
						end
						if pack.hl then
							pack.hl.Enabled = true
							local col = isOnline and Color3.fromRGB(120, 255, 160) or Color3.fromRGB(255, 100, 160)
							pack.hl.FillColor = col
							pack.hl.OutlineColor = col
						end
						local tx = nameStr
						if charStr ~= "" then tx = tx .. "\n" .. charStr end
						if distStr ~= "" then tx = (tx ~= "" and (tx .. "\n") or "") .. distStr end
						if ESP.health ~= false then
							tx = (tx ~= "" and (tx .. "\n") or "") .. string.format("HP %d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth))
						end
						pack.nameL.Text = tx
						pack.nameL.TextColor3 = isOnline and Color3.fromRGB(120, 255, 160) or WHITE
					else
						local pos = root.Position
						local top = worldToScreen(pos + Vector3.new(0, 2.5, 0))
						local bot = worldToScreen(pos - Vector3.new(0, 2.5, 0))
						if top and bot then
							local h = math.abs(bot.Y - top.Y)
							local w = h * 0.55
							local x = top.X - w / 2
							local y = top.Y
							if ESP.enabled ~= false then
								pack.boxO.Size = Vector2.new(w, h); pack.boxO.Position = Vector2.new(x, y); pack.boxO.Visible = true
								pack.box.Size = Vector2.new(w, h); pack.box.Position = Vector2.new(x, y)
								pack.box.Color = isOnline and Color3.fromRGB(120,255,160) or Color3.fromRGB(255,100,160)
								pack.box.Visible = true
							else
								pack.box.Visible = false; pack.boxO.Visible = false
							end
							if nameStr ~= "" then
								pack.name.Text = nameStr
								pack.name.Position = Vector2.new(top.X, y - 16)
								pack.name.Color = isOnline and Color3.fromRGB(120,255,160) or WHITE
								pack.name.Visible = true
							else pack.name.Visible = false end
							if charStr ~= "" then
								pack.char.Text = charStr
								pack.char.Position = Vector2.new(top.X, y + h + 2)
								pack.char.Color = Color3.fromRGB(255, 200, 100)
								pack.char.Visible = true
							else pack.char.Visible = false end
							if distStr ~= "" then
								pack.dist.Text = distStr
								pack.dist.Position = Vector2.new(top.X, y + h + 16)
								pack.dist.Color = Color3.fromRGB(200,200,210)
								pack.dist.Visible = true
							else pack.dist.Visible = false end
							if RealESP.hp then
								local bh = h * hpPct
								pack.hpBg.Size = Vector2.new(3, h); pack.hpBg.Position = Vector2.new(x - 6, y); pack.hpBg.Visible = true
								pack.hp.Size = Vector2.new(3, bh); pack.hp.Position = Vector2.new(x - 6, y + (h - bh))
								pack.hp.Color = Color3.fromHSV(hpPct * 0.33, 0.8, 1); pack.hp.Visible = true
							else pack.hp.Visible = false; pack.hpBg.Visible = false end
						else
							pack.box.Visible = false; pack.boxO.Visible = false
							pack.name.Visible = false; pack.char.Visible = false; pack.dist.Visible = false
							pack.hp.Visible = false; pack.hpBg.Visible = false
						end
					end
				else
					clearRealEsp(plr)
				end
			else
				clearRealEsp(plr)
			end
		end
	end
	for p in pairs(realEspCache) do
		if not seen[p] then clearRealEsp(p) end
	end
end)

-- online heartbeat attribute
task.spawn(function()
	while gui.Parent do
		pcall(function()
			local ch = LP.Character
			if ch then ch:SetAttribute("PixelsClientUser", true) end
		end)
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LP then
				local ch = plr.Character
				if ch and ch:GetAttribute("PixelsClientUser") == true then
					pixelOnline[plr] = true
				end
			end
		end
		task.wait(2)
	end
end)


-- External preview of local player (right of GUI, full height)
do
	local prev = Instance.new("ViewportFrame")
	prev.Name = "PixelCharPreview"
	prev.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
	prev.BorderSizePixel = 0
	prev.Visible = false
	prev.Parent = gui
	corner(prev, 12)
	local world = Instance.new("WorldModel", prev)
	local cam = Instance.new("Camera", prev)
	prev.CurrentCamera = cam
	local clone
	local function refreshClone()
		if clone then clone:Destroy() end
		local ch = LP.Character
		if not ch then return end
		local ok, c = pcall(function() return ch:Clone() end)
		if not ok or not c then return end
		for _, d in ipairs(c:GetDescendants()) do
			if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Sound") then d:Destroy() end
		end
		c.Parent = world
		clone = c
		local root = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c.PrimaryPart
		if root then
			cam.CFrame = CFrame.new(root.Position + Vector3.new(0, 1.2, 5.5), root.Position + Vector3.new(0, 1, 0))
		end
	end
	local function placePrev()
		-- match window height, to the right of root window
		local win = gui:FindFirstChild("Root") or gui:FindFirstChildWhichIsA("Frame")
		-- use main window position from Win internals if possible
		local mainRoot
		for _, ch in ipairs(gui:GetChildren()) do
			if ch:IsA("Frame") and ch:FindFirstChildWhichIsA("CanvasGroup") then mainRoot = ch break end
		end
		if not mainRoot then return end
		local gap = 10
		prev.Size = UDim2.fromOffset(math.floor(mainRoot.AbsoluteSize.Y * 0.42), mainRoot.AbsoluteSize.Y)
		prev.Position = UDim2.fromOffset(
			mainRoot.AbsolutePosition.X + mainRoot.AbsoluteSize.X + gap,
			mainRoot.AbsolutePosition.Y
		)
	end
	esp:AddToggle("Player preview (right)", false, function(on)
		prev.Visible = on
		if on then refreshClone(); placePrev() end
	end)
	connect(RunService.Heartbeat, function()
		if prev.Visible then placePrev() end
	end)
	LP.CharacterAdded:Connect(function()
		task.wait(1)
		if prev.Visible then refreshClone() end
	end)
end

end -- RealESP scope


end
local function BuildPartB()
cosmetics = visuals:AddTab("Cosmetics")
cosmetics:AddLabel("ПКМ или двойной клик по функции - настройки")
cosmetics:AddToggle("Wings (крылья)", false, function(on)
	Cosm.wings.on = on
	if on then buildWings() else destroyWings() end
end, function(p)
	local W = Cosm.wings
	p:AddDropdown("Стиль", {"Angel", "Demon", "Cyber", "Fairy"}, W.style, function(o) W.style = o; queueWings() end)
	p:AddSlider("Размер (%)", 50, 200, 100, function(v) W.size = v / 100; queueWings() end)
	p:AddColorPicker("Цвет (основание)", W.colorA, function(c) W.colorA = c; queueWings() end)
	p:AddColorPicker("Цвет (кончики)", W.colorB, function(c) W.colorB = c; queueWings() end)
	p:AddDropdown("Материал", {"Neon", "SmoothPlastic", "ForceField", "Glass", "Metal"}, W.material,
		function(o) W.material = o; queueWings() end)
	p:AddSlider("Прозрачность (%)", 0, 90, 0, function(v) W.transparency = v / 100; queueWings() end)
	p:AddSlider("Скорость взмаха", 0, 12, 3, function(v) W.speed = v end, 0.5)
	p:AddSlider("Амплитуда взмаха", 0, 45, 14, function(v) W.amount = v end)
	p:AddSlider("Волна по перьям", 0, 30, 10, function(v) W.wave = v end)
	p:AddSlider("Раскрытие (угол)", 0, 70, 24, function(v) W.open = v end)
	p:AddToggle("Свечение", false, function(on) W.glow = on; queueWings() end)
	p:AddToggle("Усиленный взмах в прыжке", true, function(on) W.react = on end)
end)
cosmetics:AddToggle("Halo (нимб)", false, function(on)
	Cosm.halo.on = on
	if on then buildHalo() else destroyHalo() end
end, function(p)
	local H = Cosm.halo
	p:AddColorPicker("Цвет", H.color, function(c) H.color = c; queueHalo() end)
	p:AddSlider("Размер (%)", 60, 160, 100, function(v) H.size = v / 100; queueHalo() end)
	p:AddSlider("Высота", 0.6, 2.2, 1.3, function(v) H.height = v end, 0.1)
	p:AddToggle("Свечение", true, function(on) H.glow = on; queueHalo() end)
end)
cosmetics:AddToggle("Trail (шлейф)", false, function(on)
	Cosm.trail.on = on
	if on then buildTrail() else destroyTrail() end
end, function(p)
	local T = Cosm.trail
	p:AddColorPicker("Цвет 1", T.colorA, function(c) T.colorA = c; queueTrail() end)
	p:AddColorPicker("Цвет 2", T.colorB, function(c) T.colorB = c; queueTrail() end)
	p:AddSlider("Длина (сек)", 0.2, 2.5, 0.8, function(v) T.life = v; queueTrail() end, 0.1)
	p:AddSlider("Прозрачность (%)", 0, 90, 20, function(v) T.trans = v / 100; queueTrail() end)
end)

-- ======================= JUMP CIRCLES + CUSTOM MODEL =======================
do -- JumpCM scope
local JC = {on = false, colA = rgb(150, 90, 255), colB = rgb(255, 80, 160), size = 10, life = 1.0, waves = 3,
	fill = true, thick = 3, rainbow = false, land = false}
local CM = {on = false, preset = "Cat Ears", attach = "Auto", color = rgb(255, 150, 215), color2 = rgb(255, 255, 255),
	material = "Neon", scale = 1, ox = 0, oy = 0, oz = 0, rot = 0, meshId = "", texId = "", hide = false, anim = true}

local fxFolder = new("Folder", {Name = "PixelFX"}, workspace)

local function cmMat() return Enum.Material[CM.material] or Enum.Material.Neon end
local function cmPart(parent, size, color, shape, transparency)
	local p = mkPart(size, color, cmMat(), transparency or 0, parent)
	if shape == "cyl" then p.Shape = Enum.PartType.Cylinder
	elseif shape == "ball" then p.Shape = Enum.PartType.Ball end
	return p
end

local CM_PRESETS = {}
CM_PRESETS["Cat Ears"] = {
	attach = "Head", sway = 0.04,
	base = function(part) return CFrame.new(0, part.Size.Y / 2, 0) end,
	build = function(root, model, s)
		local ws = {0.5, 0.38, 0.26, 0.14}
		for _, sd in ipairs({1, -1}) do
			local grp = CFrame.new(sd * 0.4 * s, 0, 0) * CFrame.Angles(0, 0, -sd * 0.28)
			for i, w in ipairs(ws) do
				local y = (0.09 + 0.18 * (i - 1)) * s
				local p = cmPart(model, Vector3.new(w * s, 0.18 * s, 0.16 * s), CM.color)
				weld(root, p, grp * CFrame.new(0, y, 0))
				if i <= 3 then
					local q = cmPart(model, Vector3.new(w * 0.5 * s, 0.18 * s, 0.04 * s), CM.color2)
					weld(root, q, grp * CFrame.new(0, y, -0.09 * s))
				end
			end
		end
	end,
}
CM_PRESETS["Devil Horns"] = {
	attach = "Head", sway = 0.03,
	base = function(part) return CFrame.new(0, part.Size.Y / 2 - 0.1, 0) end,
	build = function(root, model, s)
		for _, sd in ipairs({1, -1}) do
			local pos = Vector3.new(sd * 0.4 * s, 0, 0)
			for k = 1, 6 do
				local a = (k - 1) * 0.3
				local theta = math.pi / 2 - sd * a
				local len = 0.3 * s
				local dir = Vector3.new(math.cos(theta), math.sin(theta), 0)
				local th = (0.2 - 0.028 * k) * s
				local p = cmPart(model, Vector3.new(len * 1.08, th, th), CM.color, "cyl")
				weld(root, p, CFrame.new(pos + dir * len / 2) * CFrame.Angles(0, 0, theta))
				pos = pos + dir * len
			end
		end
	end,
}
CM_PRESETS["Crown"] = {
	attach = "Head", sway = 0,
	base = function(part) return CFrame.new(0, part.Size.Y / 2, 0) end,
	build = function(root, model, s)
		local N, r = 10, 0.62 * s
		for k = 0, N - 1 do
			local a = k / N * math.pi * 2
			local cf = CFrame.new(math.cos(a) * r, 0.12 * s, math.sin(a) * r) * CFrame.Angles(0, -a, 0)
			local seg = cmPart(model, Vector3.new(0.12 * s, 0.24 * s, 0.46 * s), CM.color)
			weld(root, seg, cf)
			if k % 2 == 0 then
				local sp = cmPart(model, Vector3.new(0.12 * s, 0.5 * s, 0.14 * s), CM.color)
				weld(root, sp, CFrame.new(math.cos(a) * r, 0.46 * s, math.sin(a) * r) * CFrame.Angles(0, -a, 0))
				local gem = cmPart(model, Vector3.new(0.15 * s, 0.15 * s, 0.15 * s), CM.color2, "ball")
				weld(root, gem, CFrame.new(math.cos(a) * r, 0.78 * s, math.sin(a) * r))
			end
		end
	end,
}
CM_PRESETS["Antenna"] = {
	attach = "Head", sway = 0.14,
	base = function(part) return CFrame.new(0, part.Size.Y / 2, 0) end,
	build = function(root, model, s)
		local stem = cmPart(model, Vector3.new(0.06 * s, 0.8 * s, 0.06 * s), CM.color)
		weld(root, stem, CFrame.new(0, 0.4 * s, 0))
		local orb = cmPart(model, Vector3.new(0.3 * s, 0.3 * s, 0.3 * s), CM.color2, "ball")
		weld(root, orb, CFrame.new(0, 0.9 * s, 0))
		new("PointLight", {Color = CM.color2, Range = 8, Brightness = 1.2}, orb)
	end,
}
CM_PRESETS["Tail"] = {
	attach = "Torso", sway = 0,
	base = function(part) return CFrame.new(0, -part.Size.Y / 2 + 0.3, part.Size.Z / 2) end,
	build = function(root, model, s, st)
		local n, len = 9, 0.42 * s
		local prev = root
		for k = 1, n do
			local th = (0.26 - 0.2 * (k / n)) * s
			local p = cmPart(model, Vector3.new(th, th, len * 1.1), CM.color:Lerp(CM.color2, k / n))
			local joint = (k == 1) and 0 or len / 2
			local w = weld(prev, p, CFrame.new(0, 0, joint) * CFrame.new(0, 0, len / 2))
			table.insert(st.tail, {weld = w, joint = joint, half = len / 2})
			prev = p
		end
	end,
}
CM_PRESETS["Orb Pet"] = {
	attach = "Torso", sway = 0,
	base = function() return CFrame.new() end,
	build = function(root, model, s, st)
		local orb = cmPart(model, Vector3.new(0.7 * s, 0.7 * s, 0.7 * s), CM.color, "ball")
		local shell = cmPart(model, Vector3.new(1.05 * s, 1.05 * s, 1.05 * s), CM.color2, "ball", 0.65)
		shell.Material = Enum.Material.ForceField
		orb.Anchored = true; shell.Anchored = true
		new("PointLight", {Color = CM.color, Range = 10, Brightness = 1.5}, orb)
		local a0 = new("Attachment", {Position = Vector3.new(0, 0.25 * s, 0)}, orb)
		local a1 = new("Attachment", {Position = Vector3.new(0, -0.25 * s, 0)}, orb)
		new("Trail", {Attachment0 = a0, Attachment1 = a1, Lifetime = 0.6, LightEmission = 1, FaceCamera = true,
			Color = ColorSequence.new(CM.color, CM.color2), Transparency = NumberSequence.new(0.2, 1)}, orb)
		st.orb = {orb, shell}
	end,
}
CM_PRESETS["Mesh (ID)"] = {
	attach = "Torso", sway = 0,
	base = function() return CFrame.new() end,
	build = function(root, model, s)
		local p = cmPart(model, Vector3.new(1, 1, 1) * s, CM.color)
		new("SpecialMesh", {MeshType = Enum.MeshType.FileMesh, MeshId = assetUrl(CM.meshId),
			TextureId = assetUrl(CM.texId), Scale = Vector3.new(s, s, s)}, p)
		if CM.texId ~= "" then p.Color = WHITE end
		weld(root, p, CFrame.new())
	end,
}
local CM_NAMES = {"Cat Ears", "Devil Horns", "Crown", "Antenna", "Tail", "Orb Pet", "Mesh (ID)"}

local function findAttach(char, name)
	if name == "Head" then return char:FindFirstChild("Head") end
	if name == "Torso" then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") end
	if name == "Left Arm" then return char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm") end
	if name == "Right Arm" then return char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm") end
	return char:FindFirstChild("HumanoidRootPart")
end

local cm
local function setBodyHidden(on)
	local char = getChar()
	if not char then return end
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") and not d:FindFirstAncestor("PixelCustom") and not d:FindFirstAncestor("PixelWings")
			and not d:FindFirstAncestor("PixelHalo") then
			d.LocalTransparencyModifier = on and 1 or 0
		end
	end
end
local function destroyCM()
	if cm and cm.model then cm.model:Destroy() end
	cm = nil
end
local function buildCM()
	destroyCM()
	local char = getChar()
	if not char then return end
	local pr = CM_PRESETS[CM.preset]
	if not pr then return end
	local part = findAttach(char, CM.attach == "Auto" and pr.attach or CM.attach)
	if not part then return end
	local model = Instance.new("Model")
	model.Name = "PixelCustom"
	local rootP = mkPart(Vector3.new(0.2, 0.2, 0.2), WHITE, Enum.Material.SmoothPlastic, 1, model)
	local st = {tail = {}}
	st.base = (pr.base and pr.base(part) or CFrame.new()) * CFrame.new(CM.ox, CM.oy, CM.oz) * CFrame.Angles(0, math.rad(CM.rot), 0)
	st.weld = weld(part, rootP, st.base)
	pr.build(rootP, model, CM.scale, st)
	model.Parent = char
	cm = {model = model, st = st, pr = pr}
end

local cmQueued = false
local function queueCM()
	if cmQueued then return end
	cmQueued = true
	task.delay(0.12, function() cmQueued = false; if CM.on then buildCM() end end)
end

-- Jump Circles
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function spawnJumpFX(char, mult)
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end
	mult = mult or 1
	rayParams.FilterDescendantsInstances = {char, fxFolder}
	local res = workspace:Raycast(hrp.Position, Vector3.new(0, -12, 0), rayParams)
	local pos = res and (res.Position + Vector3.new(0, 0.06, 0)) or (hrp.Position - Vector3.new(0, hum.HipHeight + hrp.Size.Y / 2, 0))
	local colA, colB = JC.colA, JC.colB
	if JC.rainbow then
		local h = (os.clock() * 0.25) % 1
		colA, colB = Color3.fromHSV(h, 0.6, 1), Color3.fromHSV((h + 0.14) % 1, 0.75, 1)
	end
	local diameter = JC.size * mult
	local part = Instance.new("Part")
	part.Anchored = true; part.CanCollide = false; part.CanQuery = false; part.CanTouch = false
	part.CastShadow = false; part.Transparency = 1
	part.Size = Vector3.new(diameter, 0.05, diameter)
	part.CFrame = CFrame.new(pos)
	part.Parent = fxFolder
	local sg = new("SurfaceGui", {Face = Enum.NormalId.Top, SizingMode = Enum.SurfaceGuiSizingMode.FixedSize,
		CanvasSize = Vector2.new(512, 512), LightInfluence = 0, AlwaysOnTop = false}, part)
	local life, gap = JC.life, JC.life * 0.2
	if JC.fill then
		local discF = new("Frame", {BackgroundColor3 = colA, BackgroundTransparency = 0.8, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.1, 0.1)}, sg)
		new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, discF)
		local g = new("UIGradient", {Color = ColorSequence.new(colA, colB), Rotation = 45}, discF)
		TweenService:Create(discF, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = UDim2.fromScale(0.92, 0.92), BackgroundTransparency = 1}):Play()
		TweenService:Create(g, TweenInfo.new(life, Enum.EasingStyle.Linear), {Rotation = 225}):Play()
	end
	for k = 1, JC.waves do
		local ringF = new("Frame", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.1, 0.1)}, sg)
		new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, ringF)
		local st = new("UIStroke", {Color = WHITE, Thickness = JC.thick * 4 * (1 - (k - 1) * 0.15), Transparency = 0.05}, ringF)
		local g = new("UIGradient", {Color = ColorSequence.new(colA, colB), Rotation = k * 50}, st)
		local d = (k - 1) * gap
		TweenService:Create(ringF, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, d),
			{Size = UDim2.fromScale(1, 1)}):Play()
		TweenService:Create(st, TweenInfo.new(life, Enum.EasingStyle.Sine, Enum.EasingDirection.In, 0, false, d),
			{Transparency = 1, Thickness = 1}):Play()
		ringF.Visible = false
		task.delay(d, function() if ringF.Parent then ringF.Visible = true end end)
	end
	task.delay(life + JC.waves * gap + 0.3, function() part:Destroy() end)
end

local jumpConn
local function bindJump(char)
	if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
	local hum = char:WaitForChild("Humanoid", 5)
	if not hum then return end
	jumpConn = hum.StateChanged:Connect(function(_, new_)
		if not JC.on then return end
		if new_ == Enum.HumanoidStateType.Jumping then
			spawnJumpFX(char, 1)
		elseif new_ == Enum.HumanoidStateType.Landed and JC.land then
			spawnJumpFX(char, 0.6)
		end
	end)
end
if LP.Character then task.spawn(bindJump, LP.Character) end
connect(LP.CharacterAdded, function(char)
	task.spawn(bindJump, char)
	task.wait(0.6)
	if CM.on then buildCM() end
end)

-- CM animation (append to existing RenderStepped via extra connection)
local hideAcc = 0
connect(RunService.RenderStepped, function(dt)
	local t = os.clock()
	if cm and cm.model and cm.model.Parent then
		local st, pr = cm.st, cm.pr
		if CM.anim and pr.sway and pr.sway > 0 then
			st.weld.C0 = st.base * CFrame.Angles(math.sin(t * 2) * pr.sway, 0, math.cos(t * 1.6) * pr.sway)
		else
			st.weld.C0 = st.base
		end
		for k, j in ipairs(st.tail) do
			local amp = CM.anim and 1 or 0
			j.weld.C0 = CFrame.new(0, 0, j.joint)
				* CFrame.Angles(math.sin(t * 2.4 - k * 0.5) * 0.17 * amp - 0.1, math.sin(t * 1.7 - k * 0.45) * 0.2 * amp, 0)
				* CFrame.new(0, 0, j.half)
		end
		if st.orb then
			local char = getChar()
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local p = hrp.Position + Vector3.new(math.cos(t * 1.2) * 2.6, 2.4 + math.sin(t * 2) * 0.35, math.sin(t * 1.2) * 2.6)
				st.orb[1].CFrame = CFrame.new(p)
				st.orb[2].CFrame = CFrame.new(p) * CFrame.Angles(t, t * 0.7, 0)
			end
		end
	end
	if CM.on and CM.hide then
		hideAcc += dt
		if hideAcc > 0.1 then hideAcc = 0; setBodyHidden(true) end
	end
end)

Win:OnUnload(function()
	destroyCM()
	if jumpConn then jumpConn:Disconnect() end
	if CM.hide then setBodyHidden(false) end
	if fxFolder then fxFolder:Destroy() end
end)

cosmetics:AddToggle("Jump Circles (волны)", false, function(on) JC.on = on end, function(p)
	p:AddColorPicker("Цвет 1", JC.colA, function(c) JC.colA = c end)
	p:AddColorPicker("Цвет 2", JC.colB, function(c) JC.colB = c end)
	p:AddSlider("Размер", 4, 24, 10, function(v) JC.size = v end)
	p:AddSlider("Длительность (сек)", 0.4, 2.5, 1, function(v) JC.life = v end, 0.1)
	p:AddSlider("Количество волн", 1, 5, 3, function(v) JC.waves = v end)
	p:AddSlider("Толщина", 1, 8, 3, function(v) JC.thick = v end, 0.5)
	p:AddToggle("Заливка", true, function(on) JC.fill = on end)
	p:AddToggle("Радужные", false, function(on) JC.rainbow = on end)
	p:AddToggle("При приземлении", false, function(on) JC.land = on end)
	p:AddButton("Тест", function() spawnJumpFX(getChar(), 1) end)
end)
cosmetics:AddToggle("Custom Model", false, function(on)
	CM.on = on
	if on then buildCM() else destroyCM(); setBodyHidden(false) end
end, function(p)
	p:AddDropdown("Модель", CM_NAMES, CM.preset, function(o) CM.preset = o; queueCM() end)
	p:AddDropdown("Крепление", {"Auto", "Head", "Torso", "Left Arm", "Right Arm", "Root"}, "Auto", function(o) CM.attach = o; queueCM() end)
	p:AddColorPicker("Цвет 1", CM.color, function(c) CM.color = c; queueCM() end)
	p:AddColorPicker("Цвет 2", CM.color2, function(c) CM.color2 = c; queueCM() end)
	p:AddDropdown("Материал", {"Neon", "SmoothPlastic", "Metal", "Glass", "ForceField"}, CM.material,
		function(o) CM.material = o; queueCM() end)
	p:AddSlider("Размер (%)", 30, 300, 100, function(v) CM.scale = v / 100; queueCM() end)
	p:AddSlider("Смещение X", -3, 3, 0, function(v) CM.ox = v; queueCM() end, 0.05)
	p:AddSlider("Смещение Y", -3, 3, 0, function(v) CM.oy = v; queueCM() end, 0.05)
	p:AddSlider("Смещение Z", -3, 3, 0, function(v) CM.oz = v; queueCM() end, 0.05)
	p:AddSlider("Поворот Y (°)", 0, 360, 0, function(v) CM.rot = v; queueCM() end)
	p:AddToggle("Анимация", true, function(on) CM.anim = on end)
	p:AddToggle("Скрыть своё тело", false, function(on)
		CM.hide = on
		if not on then setBodyHidden(false) end
	end)
	p:AddTextbox("Mesh ID", "для модели Mesh (ID)", function(t) CM.meshId = t; queueCM() end, "")
	p:AddTextbox("Texture ID", "необязательно", function(t) CM.texId = t; queueCM() end, "")
end)

-- ---------- HUD (watermark, arraylist, target HUD) ----------
end -- JumpCM scope


end
local function BuildPartC()
WM = {on = true, text = "PIXEL", name = true, fps = true, ping = true, time = false, coords = false,
	pos = "Top Left", alpha = 0.3}
AL = {on = false, bg = true}

wmFrame = new("Frame", {BackgroundColor3 = Theme.Background, BackgroundTransparency = WM.alpha,
	AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 28), Position = UDim2.fromOffset(14, 14)}, gui)
corner(wmFrame, 8)
local wmLine = new("Frame", {BackgroundColor3 = WHITE, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 2),
	Position = UDim2.new(0, 0, 1, -2), ZIndex = 3}, wmFrame)
accent(wmLine, true)
local wmLabel = txt("TextLabel", {BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 28),
	Text = "", TextSize = 13, TextColor3 = Theme.Text, RichText = true}, wmFrame, "Bold")
new("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, wmLabel)

function applyWMPos()
	local p = WM.pos
	if p == "Top Left" then wmFrame.AnchorPoint = Vector2.new(0, 0); wmFrame.Position = UDim2.new(0, 14, 0, 14)
	elseif p == "Top Center" then wmFrame.AnchorPoint = Vector2.new(0.5, 0); wmFrame.Position = UDim2.new(0.5, 0, 0, 14)
	elseif p == "Top Right" then wmFrame.AnchorPoint = Vector2.new(1, 0); wmFrame.Position = UDim2.new(1, -14, 0, 14)
	else wmFrame.AnchorPoint = Vector2.new(0, 1); wmFrame.Position = UDim2.new(0, 14, 1, -14) end
end

local fps, fpsCount, fpsTimer = 60, 0, 0
function refreshWM()
	wmFrame.Visible = WM.on
	wmFrame.BackgroundTransparency = WM.alpha
	if not WM.on then return end
	local sep = '<font color="rgb(150,150,178)">  |  </font>'
	local parts = {"<b>" .. (WM.text ~= "" and WM.text or "PIXEL") .. "</b>"}
	if WM.name then table.insert(parts, LP.DisplayName) end
	if WM.fps then table.insert(parts, fps .. " fps") end
	if WM.ping then
		local ok, ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
		table.insert(parts, (ok and math.floor(ping + 0.5) or 0) .. " ms")
	end
	if WM.time then table.insert(parts, os.date("%H:%M:%S")) end
	if WM.coords then
		local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
		if hrp then
			local p = hrp.Position
			table.insert(parts, string.format("%d, %d, %d", p.X, p.Y, p.Z))
		end
	end
	wmLabel.Text = table.concat(parts, sep)
end

local arrFrame = new("Frame", {BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0),
	AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 54), Visible = false}, gui)
new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right,
	Padding = UDim.new(0, 2)}, arrFrame)
local arrKey = ""
local function refreshArray()
	arrFrame.Visible = AL.on
	if not AL.on then return end
	local names = {}
	for _, e in ipairs(ArrayEntries) do
		if e.get() and not ArrayHide[e.name] then table.insert(names, e.name) end
	end
	table.sort(names, function(a, b) return #a > #b end)
	local key = table.concat(names, "|") .. tostring(AL.bg)
	if key == arrKey then return end
	arrKey = key
	for _, c in ipairs(arrFrame:GetChildren()) do
		if c:IsA("TextLabel") then c:Destroy() end
	end
	for i, n in ipairs(names) do
		txt("TextLabel", {BackgroundColor3 = Theme.Background, BackgroundTransparency = AL.bg and 0.35 or 1,
			AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 20), Text = "  " .. n .. "  ",
			TextColor3 = Theme.AccentA, TextSize = 13, LayoutOrder = i}, arrFrame, "Bold")
	end
end

connect(RunService.Heartbeat, function(dt)
	fpsCount += 1; fpsTimer += dt
	if fpsTimer >= 0.4 then
		fps = math.floor(fpsCount / fpsTimer + 0.5); fpsCount = 0; fpsTimer = 0
		refreshWM()
		refreshArray()
		for _, l in ipairs(arrFrame:GetChildren()) do
			if l:IsA("TextLabel") then l.TextColor3 = Theme.AccentA end
		end
	end
end)

-- Target HUD
do -- HUD scope
local HUD = {on = false, preview = false, mode = "Mouse", radius = 40, avatar = true, health = true,
	distance = true, npcs = false, scale = 1, alpha = 0.25}

local hud = new("CanvasGroup", {Name = "TargetHUD", BackgroundColor3 = Theme.Background, BackgroundTransparency = HUD.alpha,
	Size = UDim2.fromOffset(250, 82), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.62, 0),
	GroupTransparency = 1, Visible = false, Active = true}, gui)
corner(hud, 12)
local hudScale = new("UIScale", {Scale = 1}, hud)
local hudBorder = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, -2, 1, -2), Position = UDim2.fromOffset(1, 1)}, hud)
corner(hudBorder, 11)
accent(new("UIStroke", {Color = WHITE, Thickness = 1.2, Transparency = 0.3}, hudBorder), true)
local hudAvatar = new("ImageLabel", {BackgroundColor3 = Theme.ElementHi, Size = UDim2.fromOffset(56, 56),
	Position = UDim2.fromOffset(12, 13), ScaleType = Enum.ScaleType.Crop}, hud)
corner(hudAvatar, 10)
local hudName = txt("TextLabel", {BackgroundTransparency = 1, TextSize = 15, TextColor3 = Theme.Text, Text = "",
	TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	Position = UDim2.fromOffset(78, 9), Size = UDim2.new(1, -90, 0, 18)}, hud, "Bold")
local hudDist = txt("TextLabel", {BackgroundTransparency = 1, TextSize = 11, TextColor3 = Theme.SubText, Text = "",
	TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(78, 27), Size = UDim2.new(1, -90, 0, 14)}, hud, "Regular")
local hudBarBg = new("Frame", {BackgroundColor3 = Theme.ElementHi, Position = UDim2.fromOffset(78, 48),
	Size = UDim2.new(1, -90, 0, 8)}, hud)
corner(hudBarBg, 4)
local hudFill = new("Frame", {BackgroundColor3 = Color3.fromRGB(80, 255, 120), Size = UDim2.fromScale(1, 1)}, hudBarBg)
corner(hudFill, 4)
local hudHp = txt("TextLabel", {BackgroundTransparency = 1, TextSize = 11, TextColor3 = Theme.SubText, Text = "",
	TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(78, 59), Size = UDim2.new(1, -90, 0, 14)}, hud, "Medium")
makeDrag(hud, hud)

local hudUserId
local thumbCache = {}
local function setAvatar(userId)
	hudUserId = userId
	if not userId then hudAvatar.Image = ""; return end
	if thumbCache[userId] then hudAvatar.Image = thumbCache[userId]; return end
	task.spawn(function()
		local ok, img = pcall(function()
			return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)
		if ok then
			thumbCache[userId] = img
			if hudUserId == userId then hudAvatar.Image = img end
		end
	end)
end

local function layoutHud()
	hudAvatar.Visible = HUD.avatar
	local x = HUD.avatar and 78 or 14
	hudName.Position = UDim2.fromOffset(x, 9)
	hudDist.Position = UDim2.fromOffset(x, 27)
	hudBarBg.Position = UDim2.fromOffset(x, 48)
	hudHp.Position = UDim2.fromOffset(x, 59)
	hudName.Size = UDim2.new(1, -(x + 12), 0, 18)
	hudDist.Size = UDim2.new(1, -(x + 12), 0, 14)
	hudBarBg.Size = UDim2.new(1, -(x + 12), 0, 8)
	hudHp.Size = UDim2.new(1, -(x + 12), 0, 14)
	hudBarBg.Visible = HUD.health
	hudHp.Visible = HUD.health
	hudDist.Visible = HUD.distance
	hudScale.Scale = HUD.scale
	hud.BackgroundTransparency = HUD.alpha
end

local function showHudData(name, userId, hp, mx, dist)
	layoutHud()
	hudName.Text = name
	if HUD.avatar and userId ~= hudUserId then setAvatar(userId) end
	local r = math.clamp(hp / math.max(mx, 1), 0, 1)
	tween(hudFill, {Size = UDim2.new(r, 0, 1, 0)}, 0.15)
	hudFill.BackgroundColor3 = Color3.fromHSV(r * 0.33, 0.75, 1)
	hudHp.Text = string.format("HP %d / %d", math.floor(hp + 0.5), math.floor(mx + 0.5))
	hudDist.Text = dist and string.format("%d studs", math.floor(dist + 0.5)) or ""
end

local function humanoidFromPart(part)
	local m = part and part:FindFirstAncestorOfClass("Model")
	while m do
		local h = m:FindFirstChildOfClass("Humanoid")
		if h then return m, h end
		m = m:FindFirstAncestorOfClass("Model")
	end
end

local function findTarget()
	local myChar = getChar()
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if HUD.mode ~= "Radius" and not Win.IsPointerInside() then
		local model, hum = humanoidFromPart(mouse.Target)
		if model and model ~= myChar and hum.Health > 0 then
			local plr = Players:GetPlayerFromCharacter(model)
			if plr or HUD.npcs then
				local r = model:FindFirstChild("HumanoidRootPart")
				return model, hum, plr, (r and myRoot) and (r.Position - myRoot.Position).Magnitude or nil
			end
		end
	end
	if HUD.mode ~= "Mouse" and myRoot then
		local best, bd = nil, HUD.radius
		for _, plr in ipairs(Players:GetPlayers()) do
			local ch = plr.Character
			local r = ch and ch:FindFirstChild("HumanoidRootPart")
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			if plr ~= LP and r and hum and hum.Health > 0 then
				local d = (r.Position - myRoot.Position).Magnitude
				if d <= bd then best, bd = {ch, hum, plr, d}, d end
			end
		end
		if best then return best[1], best[2], best[3], best[4] end
	end
end

local hudShown, hudLastSeen, hudAcc = false, 0, 0
local function showHud(state)
	if state == hudShown then return end
	hudShown = state
	if state then
		hud.Visible = true
		tween(hud, {GroupTransparency = 0}, dur(0.2))
	else
		tween(hud, {GroupTransparency = 1}, dur(0.2))
		task.delay(dur(0.22), function() if not hudShown then hud.Visible = false end end)
	end
end

connect(RunService.Heartbeat, function(dt)
	hudAcc += dt
	if hudAcc < 0.1 then return end
	hudAcc = 0
	if HUD.preview then
		showHudData("Pixel_Player", LP.UserId, 72, 100, 23)
		hudLastSeen = os.clock()
		showHud(true)
		return
	end
	if not HUD.on then showHud(false) return end
	local model, hum, plr, dist = findTarget()
	if model then
		showHudData(plr and plr.DisplayName or model.Name, plr and plr.UserId or nil, hum.Health, hum.MaxHealth, dist)
		hudLastSeen = os.clock()
		showHud(true)
	elseif os.clock() - hudLastSeen > 0.6 then
		showHud(false)
	end
end)

end -- HUD scope

local hudTab = visuals:AddTab("HUD")
hudTab:AddLabel("ПКМ или двойной клик по функции - настройки")
hudTab:AddToggle("Watermark", true, function(on) WM.on = on; refreshWM() end, function(p)
	p:AddTextbox("Текст", "PIXEL", function(t) WM.text = t; refreshWM() end, "PIXEL")
	p:AddToggle("Ник", true, function(on) WM.name = on; refreshWM() end)
	p:AddToggle("FPS", true, function(on) WM.fps = on; refreshWM() end)
	p:AddToggle("Ping", true, function(on) WM.ping = on; refreshWM() end)
	p:AddToggle("Время", false, function(on) WM.time = on; refreshWM() end)
	p:AddToggle("Координаты", false, function(on) WM.coords = on; refreshWM() end)
	p:AddDropdown("Позиция", {"Top Left", "Top Center", "Top Right", "Bottom Left"}, "Top Left", function(o) WM.pos = o; applyWMPos() end)
	p:AddSlider("Прозрачность (%)", 0, 90, 30, function(v) WM.alpha = v / 100; refreshWM() end)
end)
hudTab:AddToggle("ArrayList", false, function(on) AL.on = on; arrKey = ""; refreshArray() end, function(p)
	p:AddToggle("Фон", true, function(on) AL.bg = on; arrKey = ""; refreshArray() end)
end)
hudTab:AddToggle("Target HUD", false, function(on) HUD.on = on end, function(p)
	p:AddDropdown("Режим", {"Mouse", "Radius", "Both"}, "Mouse", function(o) HUD.mode = o end)
	p:AddSlider("Радиус (studs)", 5, 150, 40, function(v) HUD.radius = v end)
	p:AddToggle("Аватар", true, function(on) HUD.avatar = on end)
	p:AddToggle("Здоровье", true, function(on) HUD.health = on end)
	p:AddToggle("Дистанция", true, function(on) HUD.distance = on end)
	p:AddToggle("Показывать NPC (только Mouse)", false, function(on) HUD.npcs = on end)
	p:AddSlider("Масштаб (%)", 70, 150, 100, function(v) HUD.scale = v / 100 end)
	p:AddSlider("Прозрачность фона (%)", 0, 90, 25, function(v) HUD.alpha = v / 100 end)
end)
hudTab:AddLabel("Mouse - навёл мышкой  |  Radius - ближайший в радиусе  |  Both - оба")
hudTab:AddToggle("Предпросмотр (демо)", false, function(on) HUD.preview = on end, nil, true)
hudTab:AddButton("Сбросить позицию Target HUD", function() hud.Position = UDim2.new(0.5, 0, 0.62, 0) end)

-- ======================= GUI (всё в одной вкладке) =======================
local guiCat = Win:AddCategory("GUI", "gear")
local guiTab = guiCat:AddTab("Interface")
local pA, pB
local presets = {
	Pixel  = {rgb(150, 90, 255), rgb(255, 80, 160)},
	Ocean  = {rgb(60, 140, 255), rgb(60, 240, 220)},
	Sunset = {rgb(255, 140, 50), rgb(255, 60, 90)},
	Toxic  = {rgb(80, 255, 120), rgb(200, 255, 60)},
	Mono   = {WHITE, rgb(140, 140, 150)},
	Blood  = {rgb(255, 50, 60), rgb(120, 10, 30)},
}

guiTab:AddLabel("Тема")
guiTab:AddDropdown("Пресет", {"Pixel", "Ocean", "Sunset", "Toxic", "Mono", "Blood"}, "Pixel", function(name)
	local p = presets[name]
	if p and pA and pB then pA.Set(p[1]); pB.Set(p[2]) end
end, true)
pA = guiTab:AddColorPicker("Accent 1", Win.Theme.AccentA, function(c) Win:SetAccent(c, nil) end)
pB = guiTab:AddColorPicker("Accent 2", Win.Theme.AccentB, function(c) Win:SetAccent(nil, c) end)
guiTab:AddColorPicker("Фон окна", Win.Theme.Background, function(c) Win:SetBackground(c) end)
guiTab:AddColorPicker("Цвет элементов", Win.Theme.Element, function(c) Win:SetElementColor(c) end)
guiTab:AddToggle("Rainbow accent", false, function(on) Win.Settings.Rainbow = on end)

guiTab:AddLabel("Стекло")
guiTab:AddSlider("Прозрачность окна (%)", 0, 90, 28, function(v) Win:SetGlass(v / 100) end)
guiTab:AddSlider("Прозрачность элементов (%)", 0, 90, 45, function(v) Win:SetElemAlpha(v / 100) end)
-- Blur removed

guiTab:AddLabel("Окно")
guiTab:AddSlider("Масштаб (%)", 60, 140, 100, function(v) Win:SetScale(v / 100) end)
guiTab:AddSlider("Скругление", 0, 28, 14, function(v) Win:SetCorner(v) end)
guiTab:AddSlider("Сила тени (%)", 0, 100, 50, function(v) Win:SetShadow(v) end)
guiTab:AddToggle("Градиентная рамка", true, function(on) Win:SetBorder(on) end)

guiTab:AddLabel("Анимации и эффекты")
guiTab:AddToggle("Блик (shine)", false, function(on) Win:SetShine(on) end)
guiTab:AddToggle("Вращение градиентов", true, function(on) Win.Settings.GradientSpin = on end)
guiTab:AddSlider("Скорость градиента", 0, 200, 50, function(v) Win.Settings.GradientSpeed = v end)
guiTab:AddSlider("Скорость анимаций (%)", 50, 250, 100, function(v) Win.Settings.AnimSpeed = v / 100 end)

guiTab:AddLabel("Шрифт")
guiTab:AddDropdown("Font", {"Gotham", "Ubuntu", "Nunito", "Roboto", "Code", "Arcade", "SourceSans"}, "Gotham",
	function(f) Win:SetFont(f) end)

guiTab:AddLabel("Обои")
guiTab:AddTextbox("ID / ссылка / файл", "123456789 или https://...", function(text)
	if text == "" then return end
	local ok, err = Win:SetWallpaper(text)
	if ok then
		Pixel:Notify("Wallpaper", "Обои установлены", 2.5)
	else
		Pixel:Notify("Wallpaper", err or "Не удалось загрузить", 3.5)
	end
end)
guiTab:AddSlider("Прозрачность обоев (%)", 0, 95, 55, function(v) Win:SetWallpaperAlpha(v / 100) end)
guiTab:AddButton("Убрать обои", function() Win:SetWallpaper("") end)



end
local function BuildPartD()
do -- Chat scope
-- ======================= CHAT (global Pixel users via API) =======================
local API_URL = "https://mjuchl2kvk.apps.bot-hosting.cloud/api.php"
pixelClientUsers = pixelClientUsers or {}
local GlobalChat = {
	lastMsg = "",
	lastMsgT = 0,
	seen = {}, -- key userid|t -> true
	onlineUsers = {},
}

local function onlineHttp(method, url, jsonBody)
	local headers = { ["Content-Type"] = "application/json" }
	method = string.upper(method or "GET")
	local function bodyOf(res)
		if type(res) == "string" and #res > 0 then return res end
		if type(res) == "table" then
			local b = res.Body or res.body or res.Data or res.data
			if type(b) == "string" and #b > 0 then return b end
		end
		return nil
	end
	local tries = {}
	if syn and type(syn.request) == "function" then
		table.insert(tries, function()
			return syn.request({ Url = url, Method = method, Headers = headers, Body = jsonBody })
		end)
	end
	if type(http_request) == "function" then
		table.insert(tries, function()
			return http_request({ Url = url, Method = method, Headers = headers, Body = jsonBody })
		end)
	end
	if type(request) == "function" then
		table.insert(tries, function()
			return request({ Url = url, Method = method, Headers = headers, Body = jsonBody })
		end)
	end
	if method == "GET" then
		table.insert(tries, function()
			return game:HttpGet(url)
		end)
	end
	for _, fn in ipairs(tries) do
		local ok, res = pcall(fn)
		if ok then
			local body = bodyOf(res)
			if body then
				local dok, decoded = pcall(function() return HttpService:JSONDecode(body) end)
				if dok and type(decoded) == "table" then return decoded end
			end
		end
	end
	return nil
end

local function platformName()
	local touch = false
	pcall(function() touch = UIS.TouchEnabled end)
	return touch and "Mobile" or "PC"
end

local function updateServerStatus(extraFeatures)
	local device = platformName()
	local placeName = tostring(game.PlaceId)
	pcall(function()
		local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
		if info and info.Name then placeName = tostring(info.Name) end
	end)
	local features = { device, "PixelClient" }
	if GlobalChat.lastMsg ~= "" then
		table.insert(features, "msg:" .. GlobalChat.lastMsg:sub(1, 120))
		table.insert(features, "msgt:" .. tostring(GlobalChat.lastMsgT))
		table.insert(features, "msglang:" .. tostring(GlobalChat.lastLang or "ru"))
	end
	-- cosmetics sync flags for other clients
	pcall(function()
		if Cosm and Cosm.wings and Cosm.wings.on then table.insert(features, "cosm_wings:1") end
		if Cosm and Cosm.halo and Cosm.halo.on then table.insert(features, "cosm_halo:1") end
		if Cosm and Cosm.trail and Cosm.trail.on then table.insert(features, "cosm_trail:1") end
	end)
	if type(extraFeatures) == "table" then
		for _, f in ipairs(extraFeatures) do table.insert(features, tostring(f)) end
	end
	local data = {
		userid = tostring(LP.UserId),
		username = LP.Name,
		displayname = LP.DisplayName,
		game = placeName,
		device = device,
		executor = "PixelClient",
		features = features,
	}
	local json = HttpService:JSONEncode(data)
	onlineHttp("POST", API_URL .. "?action=heartbeat", json)
	onlineHttp("POST", API_URL .. "?action=update", json)
end

local function getActiveServerUsers()
	local decoded = onlineHttp("GET", API_URL .. "?action=list", nil)
	if decoded and decoded.status == "ok" then
		return decoded.users or {}
	end
	return {}
end

local function parseUserMsg(user)
	if type(user) ~= "table" or type(user.features) ~= "table" then return nil, nil, nil end
	local msg, ts, lang
	for _, f in ipairs(user.features) do
		local s = tostring(f)
		local m = s:match("^msg:(.+)$")
		if m then msg = m end
		local tt = s:match("^msgt:(%d+)$")
		if tt then ts = tonumber(tt) end
		local lg = s:match("^msglang:(%w+)$")
		if lg then lang = lg end
	end
	return msg, ts, lang or "ru"
end

-- UI: RU / EN channels + mobile Send
local chatCat = Win:AddCategory("Chat", "dots")
GlobalChat.lang = "ru" -- active send lang
GlobalChat.lastLang = "ru"

local chatLogs = { ru = nil, en = nil }
local chatOrder = { ru = 0, en = 0 }

local function appendChatLine(lang, line, color)
	local holder = chatLogs[lang]
	if not holder then return end
	chatOrder[lang] = (chatOrder[lang] or 0) + 1
	local lbl = txt("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -4, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = line,
		TextColor3 = color or Theme.Text,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		LayoutOrder = chatOrder[lang],
	}, holder, "Regular")
	local kids = {}
	for _, c in ipairs(holder:GetChildren()) do
		if c:IsA("TextLabel") then table.insert(kids, c) end
	end
	while #kids > 40 do
		kids[1]:Destroy()
		table.remove(kids, 1)
	end
end

local function sendChat(lang, text)
	text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if text == "" then return end
	if #text > 120 then text = text:sub(1, 120) end
	GlobalChat.lastMsg = text
	GlobalChat.lastMsgT = os.time()
	GlobalChat.lastLang = lang
	GlobalChat.lang = lang
	appendChatLine(lang, "[YOU] " .. text, Theme.AccentA)
	pcall(updateServerStatus)
	Pixel:Notify("Chat", (lang == "ru" and "RU" or "EN") .. " отправлено", 1.2)
end

local function buildChatTab(lang, title, hint)
	local tab = chatCat:AddTab(title)
	tab:AddLabel(hint)
	do
		local custom = tab:AddCustom(150)
		custom.ClipsDescendants = true
		local bg = new("Frame", {
			BackgroundColor3 = Theme.Element,
			BackgroundTransparency = 0.25,
			Size = UDim2.new(1, -12, 1, -12),
			Position = UDim2.fromOffset(6, 6),
			ClipsDescendants = true,
		}, custom)
		corner(bg, 8)
		local scroll = new("ScrollingFrame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -8, 1, -8),
			Position = UDim2.fromOffset(4, 4),
			ScrollBarThickness = 4,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, bg)
		new("UIListLayout", {
			Padding = UDim.new(0, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, scroll)
		chatLogs[lang] = scroll
	end
	local draft = { text = "" }
	tab:AddTextbox("Сообщение", "текст…", function(text)
		draft.text = tostring(text or "")
		-- Enter на ПК тоже шлёт
		if draft.text ~= "" then
			sendChat(lang, draft.text)
			draft.text = ""
		end
	end)
	tab:AddButton("Отправить", function()
		-- телефон: кнопка отправки
		local msg = draft.text
		if msg == "" then
			Pixel:Notify("Chat", "Впиши текст сверху", 1.5)
			return
		end
		sendChat(lang, msg)
		draft.text = ""
	end)
	return tab
end

buildChatTab("ru", "Русский", "Только русский чат (между софтами, не Roblox chat)")
buildChatTab("en", "English", "English only channel (soft chat, not Roblox)")
appendChatLine("ru", "— RU канал подключён —", Theme.SubText)
appendChatLine("en", "— EN channel connected —", Theme.SubText)

local onlineTab = chatCat:AddTab("Online")
onlineTab:AddLabel("Кто сейчас в сети с Pixel Client")
local onlineHolder
do
	local custom = onlineTab:AddCustom(180)
	local bg = new("Frame", {
		BackgroundColor3 = Theme.Element,
		BackgroundTransparency = 0.25,
		Size = UDim2.new(1, -12, 1, -12),
		Position = UDim2.fromOffset(6, 6),
		ClipsDescendants = true,
	}, custom)
	corner(bg, 8)
	local scroll = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 1, -8),
		Position = UDim2.fromOffset(4, 4),
		ScrollBarThickness = 4,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, bg)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
	onlineHolder = scroll
end

local function refreshOnlineUI(users)
	if not onlineHolder then return end
	for _, c in ipairs(onlineHolder:GetChildren()) do
		if c:IsA("TextLabel") then c:Destroy() end
	end
	local n = 0
	for i, u in ipairs(users) do
		n += 1
		local name = tostring(u.displayname or u.username or "?")
		local gameName = tostring(u.game or "?")
		local dev = "?"
		if type(u.features) == "table" then
			for _, f in ipairs(u.features) do
				local s = string.lower(tostring(f))
				if s == "pc" then dev = "PC" end
				if s == "mobile" or s == "phone" then dev = "Mobile" end
			end
		end
		txt("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -4, 0, 32),
			Text = string.format("%s  ·  %s\n%s", name, dev, gameName),
			TextColor3 = Theme.Text,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = i,
		}, onlineHolder, "Medium")
	end
	if n == 0 then
		txt("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -4, 0, 20),
			Text = "Никого онлайн…",
			TextColor3 = Theme.SubText,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, onlineHolder, "Regular")
	end
end

-- poll loop
task.spawn(function()
	task.wait(1.5)
	pcall(updateServerStatus)
	appendChatLine("— Global Pixel Chat connected —", Theme.SubText)
	while gui and gui.Parent do
		local okUsers, users = pcall(getActiveServerUsers)
		if not okUsers then users = {} end
		users = users or {}
		GlobalChat.onlineUsers = users
		pcall(refreshOnlineUI, users)

		for _, u in ipairs(users) do
			local uid = tostring(u.userid or "")
			if uid ~= "" and uid ~= tostring(LP.UserId) then
				local msg, ts, lang = parseUserMsg(u)
				if msg and ts then
					local key = uid .. "|" .. tostring(ts) .. "|" .. msg
					if not GlobalChat.seen[key] then
						GlobalChat.seen[key] = true
						local who = tostring(u.displayname or u.username or uid)
						local gameName = tostring(u.game or "")
						local channel = (lang == "en") and "en" or "ru"
						appendChatLine(channel, string.format("[%s @ %s] %s", who, gameName, msg), Theme.Text)
						-- mark in-server player for ESP
						local idn = tonumber(uid)
						if idn then
							local plr = Players:GetPlayerByUserId(idn)
							if plr then pixelClientUsers[plr] = true end
						end
					end
				else
					local idn = tonumber(uid)
					if idn then
						local plr = Players:GetPlayerByUserId(idn)
						if plr then pixelClientUsers[plr] = true end
					end
				end
				-- cosmetics flags
				local idn2 = tonumber(uid)
				if idn2 then
					local plr = Players:GetPlayerByUserId(idn2)
					if plr and plr ~= LP then
						local flags = { wings = false, halo = false, trail = false }
						if type(u.features) == "table" then
							for _, f in ipairs(u.features) do
								local s = tostring(f)
								if s == "cosm_wings:1" then flags.wings = true end
								if s == "cosm_halo:1" then flags.halo = true end
								if s == "cosm_trail:1" then flags.trail = true end
							end
						end
						pcall(applyRemoteCosmetics, plr, flags)
					end
				end
			end
		end

		pcall(updateServerStatus)
		task.wait(2)
	end
end)

-- keep RealESP pixelOnline in sync
task.spawn(function()
	while gui and gui.Parent do
		for _, u in ipairs(GlobalChat.onlineUsers or {}) do
			local idn = tonumber(tostring(u.userid or ""))
			if idn then
				local plr = Players:GetPlayerByUserId(idn)
				if plr and plr ~= LP then
					pixelClientUsers[plr] = true
					if pixelOnline then pixelOnline[plr] = true end
				end
			end
		end
		task.wait(2)
	end
end)

end -- Chat scope


-- ======================= MISC =======================
local misc = Win:AddCategory("Misc", "dots")

-- ---------- Configs ----------
local cfgTab = misc:AddTab("Configs")
local cfgName = "default"
cfgTab:AddLabel(hasFS and "Хранилище: файлы (PixelClient/configs)" or "Хранилище: только память (нет файловых функций)")
local cfgDD
cfgTab:AddTextbox("Имя конфига", "default", function(t)
	t = t:gsub("[^%w_%-%s]", ""):gsub("^%s+", ""):gsub("%s+$", "")
	if t ~= "" then cfgName = t end
end, "default")
cfgDD = cfgTab:AddDropdown("Список", Pixel.Config.List(), nil, function(n) cfgName = n end, true)
cfgTab:AddButton("Сохранить", function()
	if Pixel.Config.Save(cfgName) then
		cfgDD.Refresh(Pixel.Config.List())
		Pixel:Notify("Configs", "Сохранён: " .. cfgName, 2.5)
	else
		Pixel:Notify("Configs", "Не удалось сохранить", 3)
	end
end)
cfgTab:AddButton("Загрузить", function()
	if Pixel.Config.Load(cfgName) then
		Pixel:Notify("Configs", "Загружен: " .. cfgName, 2.5)
	else
		Pixel:Notify("Configs", "Конфиг не найден: " .. cfgName, 3)
	end
end)
cfgTab:AddButton("Удалить", function()
	Pixel.Config.Delete(cfgName)
	cfgDD.Refresh(Pixel.Config.List())
	Pixel:Notify("Configs", "Удалён: " .. cfgName, 2.5)
end)
cfgTab:AddButton("Обновить список", function() cfgDD.Refresh(Pixel.Config.List()) end)
cfgTab:AddLabel("Обмен")
cfgTab:AddButton("Скопировать конфиг (JSON)", function()
	local ok = pcall(function() setclipboard(Pixel.Config.Encode()) end)
	Pixel:Notify("Configs", ok and "Скопировано в буфер" or "Нет setclipboard", 2.5)
end)
cfgTab:AddTextbox("Импорт JSON", "вставь JSON и нажми Enter", function(t)
	if t == "" then return end
	Pixel:Notify("Configs", Pixel.Config.ApplyJson(t) and "Импортировано" or "Неверный JSON", 2.5)
end)

local settings = misc:AddTab("Settings")
settings:AddButton("Тестовое уведомление", function()
	Pixel:Notify("Pixel Client", "Всё работает отлично!", 3)
end)
settings:AddButton("Unload", function() Win:Destroy() end)

local about = misc:AddTab("About")
about:AddLabel("Pixel Client v6")
about:AddLabel("RightShift / Watermark (mobile) - menu")
about:AddLabel("Combat + Movement + ESP + Cosmetics")

-- ======================= ЗАПУСК =======================
refreshWM()
applyWMPos()
-- mobile watermark opens menu
pcall(function()
	if wmFrame then
		wmFrame.Active = true
		wmFrame.InputBegan:Connect(function(i)
			if UIS.TouchEnabled and isPress(i) then
				Win:SetVisible(true)
			end
		end)
	end
end)
Win.Ready = true
Win:SetVisible(true)
Pixel:Notify("Pixel Client", "v6 • " .. TOGGLE_KEY.Name .. " / watermark (mobile)", 3)



end
BuildPartA()
BuildPartB()
BuildPartC()
BuildPartD()



-- Cosmetics sync: другие клиенты с софтом видят простой нимб/хайлайт
local remoteCosm = {} -- [Player] = {hl, bb}
local function clearRemoteCosm(plr)
	local c = remoteCosm[plr]
	if not c then return end
	pcall(function() if c.hl then c.hl:Destroy() end end)
	pcall(function() if c.bb then c.bb:Destroy() end end)
	remoteCosm[plr] = nil
end
local function applyRemoteCosmetics(plr, flags)
	if not plr or plr == LP or not plr.Character then
		clearRemoteCosm(plr)
		return
	end
	local char = plr.Character
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local pack = remoteCosm[plr]
	if not pack then
		pack = {}
		remoteCosm[plr] = pack
	end
	if flags.halo or flags.wings then
		if not pack.hl or not pack.hl.Parent then
			local hl = Instance.new("Highlight")
			hl.FillTransparency = 0.7
			hl.OutlineTransparency = 0.15
			hl.FillColor = Color3.fromRGB(255, 180, 220)
			hl.OutlineColor = Color3.fromRGB(255, 120, 180)
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.Parent = char
			pack.hl = hl
		end
	elseif pack.hl then
		pack.hl:Destroy()
		pack.hl = nil
	end
	if flags.trail or flags.halo then
		if not pack.bb or not pack.bb.Parent then
			local bb = Instance.new("BillboardGui")
			bb.Size = UDim2.fromOffset(80, 18)
			bb.StudsOffset = Vector3.new(0, 3.5, 0)
			bb.AlwaysOnTop = true
			bb.Adornee = char:FindFirstChild("Head") or root
			bb.Parent = char
			local l = Instance.new("TextLabel", bb)
			l.BackgroundTransparency = 1
			l.Size = UDim2.new(1,0,1,0)
			l.Font = Enum.Font.GothamBold
			l.TextSize = 11
			l.TextColor3 = Color3.fromRGB(255, 200, 230)
			l.TextStrokeTransparency = 0.4
			pack.bb = bb
			pack.lbl = l
		end
		if pack.lbl then
			local tags = {}
			if flags.wings then table.insert(tags, "Wings") end
			if flags.halo then table.insert(tags, "Halo") end
			if flags.trail then table.insert(tags, "Trail") end
			pack.lbl.Text = table.concat(tags, " · ")
		end
	elseif pack.bb then
		pack.bb:Destroy()
		pack.bb = nil
		pack.lbl = nil
	end
end


-- Keybind: СКМ на функции → клавиша
connect(UIS.InputBegan, function(input, gp)
	if gp then return end
	if BindListening then
		if input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then
			for k, v in pairs(BindMap) do
				if v == BindListening then BindMap[k] = nil end
			end
			BindMap[input.KeyCode] = BindListening
			local name = BindListening.Name or "?"
			Pixel:Notify("Bind", name .. " → " .. input.KeyCode.Name, 2)
			BindListening = nil
		end
		return
	end
	local b = BindMap[input.KeyCode]
	if b and b.Toggle then
		b.Toggle()
	end
end)

return Pixel
