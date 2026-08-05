--!strict

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- Configuration de l'identifiant et du nom de l'UI (Anti-Multi-Instance)
local PLAYER_ID = Player.UserId
local UI_NAME = PLAYER_ID .. "_WLibraryUI"

local function cleanupOldInstances()
	pcall(function()
		-- 1. Nettoyage dans CoreGui
		if CoreGui then
			local oldGui = CoreGui:FindFirstChild(UI_NAME)
			if oldGui then
				oldGui:Destroy()
			end
		end
		
		-- 2. Nettoyage dans gethui() (environnements d'exécuteurs avancés)
		if typeof(gethui) == "function" then
			local success, hui = pcall(gethui)
			if success and hui then
				local oldGui = hui:FindFirstChild(UI_NAME)
				if oldGui then
					oldGui:Destroy()
				end
			end
		end
		
		-- 3. Nettoyage de secours dans PlayerGui
		if PlayerGui then
			local oldGui = PlayerGui:FindFirstChild(UI_NAME)
			if oldGui then
				oldGui:Destroy()
			end
		end
		
		-- 4. Nettoyage des effets de lighting orphelins
		if Lighting then
			local oldBlur = Lighting:FindFirstChild("SecEngine_Blur")
			if oldBlur then oldBlur:Destroy() end
			local oldCC = Lighting:FindFirstChild("SecEngine_CC")
			if oldCC then oldCC:Destroy() end
		end
	end)
end

-- Exécution immédiate du nettoyage anti-multi-instance
cleanupOldInstances()

task.spawn(function()
	local hasRConsole = (typeof(rconsoleprint) == "function")
	if hasRConsole then
		pcall(function() rconsoleprint("\27[33m") end)
	end
	for i = 1, 100, 5 do
		local bar = "[" .. string.rep("=", math.floor(i/10)) .. string.rep("-", 10 - math.floor(i/10)) .. "] " .. tostring(i) .. "% Loading SecEngine Premium Window Library..."
		if hasRConsole then
			pcall(function() rconsoleprint(bar .. "\n") end)
		else
			print("\27[33m" .. bar .. "\27[0m")
		end
		task.wait(0.015)
	end
	if hasRConsole then
		pcall(function() rconsoleprint("\27[0m") end)
	end
end)

export type ThemeConfig = {
	Background: Color3,
	SecondaryBackground: Color3,
	ContainerBackground: Color3,
	Accent: Color3,
	Text: Color3,
	TextDim: Color3,
	Border: Color3,
	Error: Color3,
	GlassTransparency: number,
}

local Themes: {[string]: ThemeConfig} = {
	Default = {
		Background = Color3.fromRGB(15, 15, 19),
		SecondaryBackground = Color3.fromRGB(22, 22, 28),
		ContainerBackground = Color3.fromRGB(19, 19, 25),
		Accent = Color3.fromRGB(0, 225, 130),
		Text = Color3.fromRGB(240, 240, 245),
		TextDim = Color3.fromRGB(170, 170, 185),
		Border = Color3.fromRGB(40, 40, 52),
		Error = Color3.fromRGB(180, 50, 50),
		GlassTransparency = 0.18,
	},
	Halloween = {
		Background = Color3.fromRGB(18, 15, 22),
		SecondaryBackground = Color3.fromRGB(26, 21, 32),
		ContainerBackground = Color3.fromRGB(22, 18, 28),
		Accent = Color3.fromRGB(255, 140, 0),
		Text = Color3.fromRGB(245, 240, 250),
		TextDim = Color3.fromRGB(180, 165, 195),
		Border = Color3.fromRGB(55, 40, 70),
		Error = Color3.fromRGB(200, 50, 50),
		GlassTransparency = 0.18,
	},
	WinterArc = {
		Background = Color3.fromRGB(14, 18, 25),
		SecondaryBackground = Color3.fromRGB(20, 26, 36),
		ContainerBackground = Color3.fromRGB(17, 22, 31),
		Accent = Color3.fromRGB(0, 180, 255),
		Text = Color3.fromRGB(235, 245, 255),
		TextDim = Color3.fromRGB(160, 185, 210),
		Border = Color3.fromRGB(35, 50, 75),
		Error = Color3.fromRGB(200, 60, 60),
		GlassTransparency = 0.18,
	},
	Autumn = {
		Background = Color3.fromRGB(20, 17, 15),
		SecondaryBackground = Color3.fromRGB(30, 25, 22),
		ContainerBackground = Color3.fromRGB(25, 21, 18),
		Accent = Color3.fromRGB(210, 105, 30),
		Text = Color3.fromRGB(250, 240, 230),
		TextDim = Color3.fromRGB(190, 170, 155),
		Border = Color3.fromRGB(65, 45, 35),
		Error = Color3.fromRGB(180, 70, 50),
		GlassTransparency = 0.18,
	}
}

local WindowManager = {}
WindowManager.__index = WindowManager

local activeWindows = {}
local isMenuVisible = true
local screenGui: ScreenGui? = nil
local blurEffect: BlurEffect? = nil
local colorCorrection: ColorCorrectionEffect? = nil
local globalZIndexCounter = 100

local CONFIG_FILE_NAME = "ModMenu_Config.json"
local defaultConfig = {
	ToggleKey = "F1",
	WindowTransparency = 0.18,
	CurrentTheme = "Default",
}
local configStorage = table.clone(defaultConfig)
local Theme: ThemeConfig = Themes.Default

local function getKeyCodeFromName(name: string): Enum.KeyCode
	for _, item in ipairs(Enum.KeyCode:GetEnumItems()) do
		if item.Name == name then
			return item
		end
	end
	return Enum.KeyCode.F1
end

local function loadConfiguration()
	local hasRead = (typeof(readfile) == "function")
	local hasIsFile = (typeof(isfile) == "function")
	if not hasRead or not hasIsFile then return end
	pcall(function()
		if isfile(CONFIG_FILE_NAME) then
			local content = readfile(CONFIG_FILE_NAME)
			if typeof(content) == "string" and #content > 0 then
				local success, decoded = pcall(function()
					return HttpService:JSONDecode(content)
				end)
				if success and typeof(decoded) == "table" then
					for k, v in pairs(decoded) do
						configStorage[k] = v
					end
				end
			end
		end
	end)
	if configStorage.CurrentTheme and Themes[configStorage.CurrentTheme] then
		Theme = Themes[configStorage.CurrentTheme]
	end
end

local function saveConfiguration()
	if typeof(writefile) ~= "function" then return end
	pcall(function()
		local success, encoded = pcall(function()
			return HttpService:JSONEncode(configStorage)
		end)
		if success and typeof(encoded) == "string" then
			writefile(CONFIG_FILE_NAME, encoded)
		end
	end)
end

loadConfiguration()

local function initializeLightingEffects()
	pcall(function()
		if not blurEffect then
			blurEffect = Instance.new("BlurEffect")
			blurEffect.Name = "SecEngine_Blur"
			blurEffect.Size = 0
			blurEffect.Parent = Lighting
		end
		if not colorCorrection then
			colorCorrection = Instance.new("ColorCorrectionEffect")
			colorCorrection.Name = "SecEngine_CC"
			colorCorrection.Brightness = 0
			colorCorrection.Parent = Lighting
		end
	end)
end

local function initializeGui(): ScreenGui
	if screenGui and screenGui.Parent then return screenGui end
	
	initializeLightingEffects()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = UI_NAME
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	pcall(function()
		if typeof(gethui) == "function" then
			screenGui.Parent = gethui()
		elseif CoreGui then
			screenGui.Parent = CoreGui
		else
			screenGui.Parent = PlayerGui
		end
	end)
	
	if not screenGui.Parent then
		pcall(function()
			screenGui.Parent = PlayerGui
		end)
	end
	return screenGui
end

-- Système de Notification Global hautement stylisé
local NotificationHolder: Frame? = nil
local function getNotificationHolder(): Frame
	if NotificationHolder and NotificationHolder.Parent then return NotificationHolder end
	local gui = initializeGui()
	local holder = Instance.new("Frame")
	holder.Name = "NotificationHolder"
	holder.Size = UDim2.new(0, 280, 1, -40)
	holder.Position = UDim2.new(1, -290, 0, 20)
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.ZIndex = 9999
	holder.Parent = gui
	
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.Padding = UDim.new(0, 8)
	layout.Parent = holder
	
	NotificationHolder = holder
	return holder
end

function WindowManager.Notify(title: string, message: string, duration: number?)
	task.spawn(function()
		local holder = getNotificationHolder()
		local dur = duration or 3
		
		local notif = Instance.new("Frame")
		notif.Size = UDim2.new(1, 0, 0, 54)
		notif.BackgroundColor3 = Theme.SecondaryBackground
		notif.BackgroundTransparency = 0.1
		notif.BorderSizePixel = 0
		notif.Parent = holder
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = notif
		
		local stroke = Instance.new("UIStroke")
		stroke.Color = Theme.Accent
		stroke.Transparency = 0.3
		stroke.Thickness = 1.5
		stroke.Parent = notif
		
		local shadow = Instance.new("ImageLabel")
		shadow.Name = "Shadow"
		shadow.AnchorPoint = Vector2.new(0.5, 0.5)
		shadow.Position = UDim2.new(0.5, 0, 0.5, 3)
		shadow.Size = UDim2.new(1, 24, 1, 24)
		shadow.BackgroundTransparency = 1
		shadow.Image = "rbxassetid://1316045217"
		shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
		shadow.ImageTransparency = 0.4
		shadow.ScaleType = Enum.ScaleType.Slice
		shadow.SliceCenter = Rect.new(10, 10, 118, 118)
		shadow.ZIndex = notif.ZIndex - 1
		shadow.Parent = notif
		
		local titleLbl = Instance.new("TextLabel")
		titleLbl.Size = UDim2.new(1, -20, 0, 18)
		titleLbl.Position = UDim2.new(0, 12, 0, 6)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Font = Enum.Font.GothamBold
		titleLbl.Text = title
		titleLbl.TextColor3 = Theme.Text
		titleLbl.TextSize = 12
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.Parent = notif
		
		local msgLbl = Instance.new("TextLabel")
		msgLbl.Size = UDim2.new(1, -20, 0, 20)
		msgLbl.Position = UDim2.new(0, 12, 0, 24)
		msgLbl.BackgroundTransparency = 1
		msgLbl.Font = Enum.Font.Gotham
		msgLbl.Text = message
		msgLbl.TextColor3 = Theme.TextDim
		msgLbl.TextSize = 11
		msgLbl.TextXAlignment = Enum.TextXAlignment.Left
		msgLbl.Parent = notif
		
		-- Animation d'apparition
		notif.Position = UDim2.new(1, 50, 0, 0)
		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		TweenService:Create(notif, tweenInfo, {Position = UDim2.new(0, 0, 0, 0)}):Play()
		
		task.wait(dur)
		
		local outTween = TweenService:Create(notif, tweenInfo, {Position = UDim2.new(1, 50, 0, 0), BackgroundTransparency = 1})
		outTween:Play()
		outTween.Completed:Connect(function()
			notif:Destroy()
		end)
	end)
end

export type ContainerObj = {
	Instance: Frame,
	ParentContainer: Frame,
	Title: string,
	Connections: {RBXScriptConnection},
	AddLabel: (self: ContainerObj, text: string) -> TextLabel,
	AddButton: (self: ContainerObj, text: string, callback: () -> ()) -> TextButton,
	AddToggle: (self: ContainerObj, text: string, defaultState: boolean, callback: (boolean) -> ()) -> TextButton,
	AddSlider: (self: ContainerObj, text: string, min: number, max: number, defaultVal: number, callback: (number) -> ()) -> Frame,
	AddKeybind: (self: ContainerObj, text: string, defaultKey: Enum.KeyCode, callback: (Enum.KeyCode) -> ()) -> Frame,
	Destroy: (self: ContainerObj) -> (),
}

local ContainerMeta = {}
ContainerMeta.__index = ContainerMeta

function ContainerMeta:AddLabel(text: string): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = Theme.TextDim
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = self.ParentContainer
	return label
end

function ContainerMeta:AddButton(text: string, callback: () -> ()): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 34)
	btn.BackgroundColor3 = Theme.SecondaryBackground
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Font = Enum.Font.GothamMedium
	btn.Text = text
	btn.TextColor3 = Theme.Text
	btn.TextSize = 12
	btn.Parent = self.ParentContainer
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Border
	stroke.Thickness = 1
	stroke.Parent = btn
	
	local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	table.insert(self.Connections, btn.MouseButton1Click:Connect(function()
		TweenService:Create(btn, tweenInfo, {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Background, Size = UDim2.new(1, 0, 0, 35)}):Play()
		task.delay(0.15, function()
			if btn and btn.Parent then
				TweenService:Create(btn, tweenInfo, {BackgroundColor3 = Theme.SecondaryBackground, TextColor3 = Theme.Text, Size = UDim2.new(1, 0, 0, 34)}):Play()
			end
		end)
		if callback then task.spawn(callback) end
	end))
	table.insert(self.Connections, btn.MouseEnter:Connect(function()
		TweenService:Create(btn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(34, 34, 44)}):Play()
	end))
	table.insert(self.Connections, btn.MouseLeave:Connect(function()
		TweenService:Create(btn, tweenInfo, {BackgroundColor3 = Theme.SecondaryBackground}):Play()
	end))
	return btn
end

function ContainerMeta:AddToggle(text: string, defaultState: boolean, callback: (boolean) -> ()): TextButton
	local id = self.Title .. "_" .. text
	local state = if configStorage[id] ~= nil then configStorage[id] else (defaultState or false)
	
	local container = Instance.new("TextButton")
	container.Size = UDim2.new(1, 0, 0, 34)
	container.BackgroundColor3 = Theme.SecondaryBackground
	container.BorderSizePixel = 0
	container.AutoButtonColor = false
	container.Text = ""
	container.Parent = self.ParentContainer
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = container
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Border
	stroke.Thickness = 1
	stroke.Parent = container
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -50, 1, 0)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = text
	label.TextColor3 = Theme.Text
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	
	local toggleBg = Instance.new("Frame")
	toggleBg.Name = "ToggleBg"
	toggleBg.Size = UDim2.new(0, 38, 0, 20)
	toggleBg.Position = UDim2.new(1, -46, 0.5, -10)
	toggleBg.BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(38, 38, 48)
	toggleBg.BorderSizePixel = 0
	toggleBg.Parent = container
	
	local toggleBgCorner = Instance.new("UICorner")
	toggleBgCorner.CornerRadius = UDim.new(1, 0)
	toggleBgCorner.Parent = toggleBg
	
	local toggleCircle = Instance.new("Frame")
	toggleCircle.Size = UDim2.new(0, 16, 0, 16)
	toggleCircle.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
	toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	toggleCircle.BorderSizePixel = 0
	toggleCircle.Parent = toggleBg
	
	local circleCorner = Instance.new("UICorner")
	circleCorner.CornerRadius = UDim.new(1, 0)
	circleCorner.Parent = toggleCircle
	
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local function updateVisual(instant: boolean)
		local goalBgColor = state and Theme.Accent or Color3.fromRGB(38, 38, 48)
		local goalCirclePos = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
		if instant then
			toggleBg.BackgroundColor3 = goalBgColor
			toggleCircle.Position = goalCirclePos
			stroke.Color = state and Theme.Accent or Theme.Border
		else
			TweenService:Create(toggleBg, tweenInfo, {BackgroundColor3 = goalBgColor}):Play()
			TweenService:Create(toggleCircle, tweenInfo, {Position = goalCirclePos}):Play()
			TweenService:Create(stroke, tweenInfo, {Color = state and Theme.Accent or Theme.Border}):Play()
		end
	end
	
	updateVisual(true)
	if callback then task.spawn(callback, state) end
	
	table.insert(self.Connections, container.MouseButton1Click:Connect(function()
		state = not state
		configStorage[id] = state
		saveConfiguration()
		updateVisual(false)
		if callback then task.spawn(callback, state) end
	end))
	table.insert(self.Connections, container.MouseEnter:Connect(function()
		TweenService:Create(container, tweenInfo, {BackgroundColor3 = Color3.fromRGB(30, 30, 38)}):Play()
	end))
	table.insert(self.Connections, container.MouseLeave:Connect(function()
		TweenService:Create(container, tweenInfo, {BackgroundColor3 = Theme.SecondaryBackground}):Play()
	end))
	return container
end

function ContainerMeta:AddSlider(text: string, min: number, max: number, defaultVal: number, callback: (number) -> ()): Frame
	local id = self.Title .. "_" .. text
	local val = if configStorage[id] ~= nil then configStorage[id] else (defaultVal or min)
	
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 52)
	container.BackgroundColor3 = Theme.SecondaryBackground
	container.BorderSizePixel = 0
	container.Parent = self.ParentContainer
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = container
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Border
	stroke.Thickness = 1
	stroke.Parent = container
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -24, 0, 20)
	label.Position = UDim2.new(0, 12, 0, 6)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = text .. ": " .. tostring(val)
	label.TextColor3 = Theme.Text
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	
	local sliderBar = Instance.new("TextButton")
	sliderBar.Size = UDim2.new(1, -24, 0, 6)
	sliderBar.Position = UDim2.new(0, 12, 0, 34)
	sliderBar.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
	sliderBar.BorderSizePixel = 0
	sliderBar.AutoButtonColor = false
	sliderBar.Text = ""
	sliderBar.Parent = container
	
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = sliderBar
	
	local sliderFill = Instance.new("Frame")
	sliderFill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
	sliderFill.BackgroundColor3 = Theme.Accent
	sliderFill.BorderSizePixel = 0
	sliderFill.Parent = sliderBar
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = sliderFill
	
	-- Pastille de curseur élégante
	local thumb = Instance.new("Frame")
	thumb.Size = UDim2.new(0, 12, 0, 12)
	thumb.AnchorPoint = Vector2.new(0.5, 0.5)
	thumb.Position = UDim2.new(1, 0, 0.5, 0)
	thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	thumb.BorderSizePixel = 0
	thumb.Parent = sliderFill
	
	local thumbCorner = Instance.new("UICorner")
	thumbCorner.CornerRadius = UDim.new(1, 0)
	thumbCorner.Parent = thumb
	
	local sliding = false
	local function updateValue(inputPos: number)
		local sizeX = sliderBar.AbsoluteSize.X
		if sizeX <= 0 then return end
		local posRelative = math.clamp((inputPos - sliderBar.AbsolutePosition.X) / sizeX, 0, 1)
		val = math.floor((min + (max - min) * posRelative) * 10) / 10
		sliderFill.Size = UDim2.new(posRelative, 0, 1, 0)
		label.Text = text .. ": " .. tostring(val)
		configStorage[id] = val
		saveConfiguration()
		if callback then task.spawn(callback, val) end
	end
	
	table.insert(self.Connections, sliderBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			TweenService:Create(thumb, TweenInfo.new(0.15), {Size = UDim2.new(0, 16, 0, 16)}):Play()
			updateValue(input.Position.X)
		end
	end))
	table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if sliding then
				sliding = false
				TweenService:Create(thumb, TweenInfo.new(0.15), {Size = UDim2.new(0, 12, 0, 12)}):Play()
			end
		end
	end))
	table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateValue(input.Position.X)
		end
	end))
	
	if callback then task.spawn(callback, val) end
	return container
end

function ContainerMeta:AddKeybind(text: string, defaultKey: Enum.KeyCode, callback: (Enum.KeyCode) -> ()): Frame
	local id = self.Title .. "_" .. text
	local currentKey = defaultKey
	if configStorage[id] then
		currentKey = getKeyCodeFromName(configStorage[id])
	end
	
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 34)
	container.BackgroundColor3 = Theme.SecondaryBackground
	container.BorderSizePixel = 0
	container.Parent = self.ParentContainer
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = container
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Border
	stroke.Thickness = 1
	stroke.Parent = container
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -110, 1, 0)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = text
	label.TextColor3 = Theme.Text
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	
	local bindButton = Instance.new("TextButton")
	bindButton.Size = UDim2.new(0, 90, 0, 24)
	bindButton.Position = UDim2.new(1, -98, 0.5, -12)
	bindButton.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
	bindButton.BorderSizePixel = 0
	bindButton.Font = Enum.Font.Code
	bindButton.Text = currentKey.Name
	bindButton.TextColor3 = Color3.fromRGB(200, 200, 215)
	bindButton.TextSize = 11
	bindButton.Parent = container
	
	local bindCorner = Instance.new("UICorner")
	bindCorner.CornerRadius = UDim.new(0, 6)
	bindCorner.Parent = bindButton
	
	local binding = false
	table.insert(self.Connections, bindButton.MouseButton1Click:Connect(function()
		binding = true
		bindButton.Text = "..."
		bindButton.TextColor3 = Theme.Accent
	end))
	table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if binding then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				currentKey = input.KeyCode
				bindButton.Text = currentKey.Name
				bindButton.TextColor3 = Color3.fromRGB(200, 200, 215)
				binding = false
				configStorage[id] = currentKey.Name
				saveConfiguration()
				WindowManager.Notify("Keybind Updated", text .. " -> " .. currentKey.Name, 2)
			end
		elseif not gameProcessed and input.KeyCode == currentKey then
			if callback then task.spawn(callback, currentKey) end
		end
	end))
	return container
end

function ContainerMeta:Destroy()
	for _, conn in ipairs(self.Connections) do
		conn:Disconnect()
	end
	table.clear(self.Connections)
	if self.Instance then
		self.Instance:Destroy()
	end
end

export type WindowObj = {
	Title: string,
	Size: UDim2,
	Position: UDim2,
	MainFrame: Frame,
	TitleBar: Frame,
	TitleLabel: TextLabel,
	Container: ScrollingFrame,
	ResizeHandle: TextButton,
	MinimizeButton: TextButton,
	IsMinimized: boolean,
	Connections: {RBXScriptConnection},
	CreateGui: (self: WindowObj) -> (),
	InitDragging: (self: WindowObj) -> (),
	InitResizing: (self: WindowObj) -> (),
	BringToFront: (self: WindowObj) -> (),
	SetTransparency: (self: WindowObj, transparency: number) -> (),
	ToggleMinimize: (self: WindowObj) -> (),
	AddContainer: (self: WindowObj, titleText: string?) -> ContainerObj,
	AddLabel: (self: WindowObj, text: string) -> TextLabel,
	AddButton: (self: WindowObj, text: string, callback: () -> ()) -> TextButton,
	AddToggle: (self: WindowObj, text: string, defaultState: boolean, callback: (boolean) -> ()) -> TextButton,
	AddSlider: (self: WindowObj, text: string, min: number, max: number, defaultVal: number, callback: (number) -> ()) -> Frame,
	AddKeybind: (self: WindowObj, text: string, defaultKey: Enum.KeyCode, callback: (Enum.KeyCode) -> ()) -> Frame,
	Destroy: (self: WindowObj) -> (),
}

local Window = {}
Window.__index = Window

function Window.new(titleText: string, size: UDim2?, position: UDim2?): WindowObj
	local self = setmetatable({}, Window) :: any
	self.Title = titleText or "Panel"
	self.Size = size or UDim2.new(0, 360, 0, 440)
	self.IsMinimized = false
	self.Connections = {}
	
	if position then
		self.Position = position
	else
		local windowCount = #activeWindows
		local defaultWidth = 360
		local defaultHeight = 440
		local spacing = 20
		local viewportSize = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
		local maxPerRow = math.floor((viewportSize.X - 40) / (defaultWidth + spacing))
		if maxPerRow < 1 then maxPerRow = 1 end
		
		local rowIndex = math.floor(windowCount / maxPerRow)
		local colIndex = windowCount % maxPerRow
		
		local startX = 30 + colIndex * (defaultWidth + spacing)
		local startY = 30 + rowIndex * (defaultHeight + spacing)
		
		if startY + defaultHeight > viewportSize.Y - 30 then
			startY = 30 + (windowCount % 3) * 20
			startX = 30 + (windowCount * 25)
		end
		
		self.Position = UDim2.new(0, startX, 0, startY)
	end
	
	self:CreateGui()
	table.insert(activeWindows, self)
	return self
end

function Window:BringToFront()
	globalZIndexCounter += 1
	if self.MainFrame then
		self.MainFrame.ZIndex = globalZIndexCounter
	end
end

function Window:CreateGui()
	local parentGui = initializeGui()
	
	-- Ombre douce arrière (ImageLabel floue GTA V Style)
	local shadow = Instance.new("ImageLabel")
	shadow.Name = self.Title .. "_Shadow"
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
	shadow.Size = UDim2.new(1, 36, 1, 36)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://1316045217"
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.35
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(10, 10, 118, 118)
	
	self.MainFrame = Instance.new("Frame")
	self.MainFrame.Name = self.Title .. "_Window"
	self.MainFrame.Size = self.Size
	self.MainFrame.Position = self.Position
	self.MainFrame.BackgroundColor3 = Theme.Background
	self.MainFrame.BackgroundTransparency = configStorage.WindowTransparency or Theme.GlassTransparency
	self.MainFrame.BorderSizePixel = 0
	self.MainFrame.Active = true
	self.MainFrame.ZIndex = globalZIndexCounter
	
	shadow.Parent = self.MainFrame
	self.MainFrame.Parent = parentGui
	
	-- Effet Glassmorphism Gradient & Coins arrondis 10px
	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 10)
	mainCorner.Parent = self.MainFrame
	
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Name = "WindowStroke"
	uiStroke.Color = Theme.Border
	uiStroke.Thickness = 1
	uiStroke.Parent = self.MainFrame
	
	local uiGradient = Instance.new("UIGradient")
	uiGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 0.15)
	})
	uiGradient.Rotation = 45
	uiGradient.Parent = self.MainFrame
	
	local topAccent = Instance.new("Frame")
	topAccent.Name = "TopAccent"
	topAccent.Size = UDim2.new(1, 0, 0, 2)
	topAccent.BackgroundColor3 = Theme.Accent
	topAccent.BorderSizePixel = 0
	topAccent.Parent = self.MainFrame
	
	self.TitleBar = Instance.new("Frame")
	self.TitleBar.Name = "TitleBar"
	self.TitleBar.Size = UDim2.new(1, 0, 0, 36)
	self.TitleBar.Position = UDim2.new(0, 0, 0, 2)
	self.TitleBar.BackgroundColor3 = Theme.SecondaryBackground
	self.TitleBar.BackgroundTransparency = 0.1
	self.TitleBar.BorderSizePixel = 0
	self.TitleBar.Parent = self.MainFrame
	
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 10)
	titleCorner.Parent = self.TitleBar
	
	-- Correcteur d'arrondi bas du titre
	local coverFix = Instance.new("Frame")
	coverFix.Size = UDim2.new(1, 0, 0, 10)
	coverFix.Position = UDim2.new(0, 0, 1, -10)
	coverFix.BackgroundColor3 = Theme.SecondaryBackground
	coverFix.BackgroundTransparency = 0.1
	coverFix.BorderSizePixel = 0
	coverFix.ZIndex = self.TitleBar.ZIndex
	coverFix.Parent = self.TitleBar
	
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Name = "TitleStroke"
	titleStroke.Color = Theme.Border
	titleStroke.Thickness = 1
	titleStroke.Parent = self.TitleBar
	
	self.TitleLabel = Instance.new("TextLabel")
	self.TitleLabel.Size = UDim2.new(1, -70, 1, 0)
	self.TitleLabel.Position = UDim2.new(0, 14, 0, 0)
	self.TitleLabel.BackgroundTransparency = 1
	self.TitleLabel.Font = Enum.Font.Code
	self.TitleLabel.Text = "// " .. string.upper(self.Title)
	self.TitleLabel.TextColor3 = Theme.Text
	self.TitleLabel.TextSize = 12
	self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.TitleLabel.Parent = self.TitleBar
	
	self.MinimizeButton = Instance.new("TextButton")
	self.MinimizeButton.Name = "MinimizeButton"
	self.MinimizeButton.Size = UDim2.new(0, 26, 0, 22)
	self.MinimizeButton.Position = UDim2.new(1, -34, 0.5, -11)
	self.MinimizeButton.BackgroundColor3 = Theme.SecondaryBackground
	self.MinimizeButton.BorderSizePixel = 0
	self.MinimizeButton.AutoButtonColor = false
	self.MinimizeButton.Font = Enum.Font.GothamBold
	self.MinimizeButton.Text = "-"
	self.MinimizeButton.TextColor3 = Theme.Text
	self.MinimizeButton.TextSize = 14
	self.MinimizeButton.Parent = self.TitleBar
	
	local minCorner = Instance.new("UICorner")
	minCorner.CornerRadius = UDim.new(0, 6)
	minCorner.Parent = self.MinimizeButton
	
	local minStroke = Instance.new("UIStroke")
	minStroke.Name = "MinStroke"
	minStroke.Color = Theme.Border
	minStroke.Thickness = 1
	minStroke.Parent = self.MinimizeButton
	
	table.insert(self.Connections, self.MinimizeButton.MouseButton1Click:Connect(function()
		self:ToggleMinimize()
	end))
	
	self.Container = Instance.new("ScrollingFrame")
	self.Container.Name = "Container"
	self.Container.Size = UDim2.new(1, -20, 1, -54)
	self.Container.Position = UDim2.new(0, 10, 0, 44)
	self.Container.BackgroundTransparency = 1
	self.Container.BorderSizePixel = 0
	self.Container.CanvasSize = UDim2.new(0, 0, 0, 0)
	self.Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
	self.Container.ScrollBarThickness = 3
	self.Container.ScrollBarImageColor3 = Theme.Accent
	self.Container.Parent = self.MainFrame
	
	local uiLayout = Instance.new("UIListLayout")
	uiLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiLayout.Padding = UDim.new(0, 8)
	uiLayout.Parent = self.Container
	
	self.ResizeHandle = Instance.new("TextButton")
	self.ResizeHandle.Name = "ResizeHandle"
	self.ResizeHandle.Size = UDim2.new(0, 16, 0, 16)
	self.ResizeHandle.Position = UDim2.new(1, -16, 1, -16)
	self.ResizeHandle.BackgroundColor3 = Theme.Border
	self.ResizeHandle.BackgroundTransparency = 0.3
	self.ResizeHandle.BorderSizePixel = 0
	self.ResizeHandle.Text = ""
	self.ResizeHandle.AutoButtonColor = false
	self.ResizeHandle.Parent = self.MainFrame
	
	local resCorner = Instance.new("UICorner")
	resCorner.CornerRadius = UDim.new(0, 4)
	resCorner.Parent = self.ResizeHandle
	
	table.insert(self.Connections, self.MainFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self:BringToFront()
		end
	end))
	
	-- Animation d'ouverture fluide (GTA V style)
	self.MainFrame.Size = UDim2.new(0, self.Size.X.Offset * 0.85, 0, self.Size.Y.Offset * 0.85)
	self.MainFrame.BackgroundTransparency = 1
	local openTween = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	TweenService:Create(self.MainFrame, openTween, {Size = self.Size, BackgroundTransparency = configStorage.WindowTransparency or Theme.GlassTransparency}):Play()
	
	self:InitDragging()
	self:InitResizing()
end

function Window:ToggleMinimize()
	self.IsMinimized = not self.IsMinimized
	local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	if self.IsMinimized then
		self.MinimizeButton.Text = "+"
		self.Container.Visible = false
		self.ResizeHandle.Visible = false
		TweenService:Create(self.MainFrame, tweenInfo, {Size = UDim2.new(self.MainFrame.Size.X.Scale, self.MainFrame.Size.X.Offset, 0, 38)}):Play()
	else
		self.MinimizeButton.Text = "-"
		self.Container.Visible = true
		self.ResizeHandle.Visible = true
		TweenService:Create(self.MainFrame, tweenInfo, {Size = self.Size}):Play()
	end
end

function Window:InitDragging()
	local dragging = false
	local dragInput: InputObject? = nil
	local dragStart = Vector3.zero
	local startPos = UDim2.new()
	
	table.insert(self.Connections, self.TitleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = self.MainFrame.Position
			self:BringToFront()
			
			local conn
			conn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if conn then conn:Disconnect() end
				end
			end)
		end
	end))
	
	table.insert(self.Connections, self.TitleBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end))
	
	table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			self.MainFrame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end))
end

function Window:InitResizing()
	local resizing = false
	local resizeStart = Vector3.zero
	local startSize = Vector2.zero
	
	table.insert(self.Connections, self.ResizeHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			resizeStart = input.Position
			startSize = self.MainFrame.AbsoluteSize
			self:BringToFront()
			
			local conn
			conn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					resizing = false
					if conn then conn:Disconnect() end
				end
			end)
		end
	end))
	
	table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - resizeStart
			local newWidth = math.clamp(startSize.X + delta.X, 260, 850)
			local newHeight = math.clamp(startSize.Y + delta.Y, 200, 800)
			self.Size = UDim2.new(0, newWidth, 0, newHeight)
			if not self.IsMinimized then
				self.MainFrame.Size = self.Size
			end
		end
	end))
end

function Window:SetTransparency(transparency: number)
	if self.MainFrame then
		self.MainFrame.BackgroundTransparency = transparency
	end
end

function Window:AddContainer(titleText: string?): ContainerObj
	local containerFrame = Instance.new("Frame")
	containerFrame.Size = UDim2.new(1, 0, 0, 0)
	containerFrame.AutomaticSize = Enum.AutomaticSize.Y
	containerFrame.BackgroundColor3 = Theme.ContainerBackground
	containerFrame.BackgroundTransparency = 0.1
	containerFrame.BorderSizePixel = 0
	containerFrame.Parent = self.Container
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = containerFrame
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Border
	stroke.Thickness = 1
	stroke.Parent = containerFrame
	
	local innerLayout = Instance.new("UIListLayout")
	innerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	innerLayout.Padding = UDim.new(0, 6)
	innerLayout.Parent = containerFrame
	
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = containerFrame
	
	if titleText and titleText ~= "" then
		local header = Instance.new("TextLabel")
		header.Name = "HeaderLabel"
		header.Size = UDim2.new(1, 0, 0, 20)
		header.BackgroundTransparency = 1
		header.Font = Enum.Font.Code
		header.Text = string.upper(titleText)
		header.TextColor3 = Theme.Accent
		header.TextSize = 10
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.Parent = containerFrame
	end
	
	local wrapper = setmetatable({
		Instance = containerFrame,
		ParentContainer = containerFrame,
		Title = self.Title,
		Connections = {}
	}, ContainerMeta) :: any
	
	return wrapper
end

function Window:AddLabel(text: string): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 22)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = Theme.TextDim
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = self.Container
	return label
end

function Window:AddButton(text: string, callback: () -> ()): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 34)
	btn.BackgroundColor3 = Theme.SecondaryBackground
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Font = Enum.Font.GothamMedium
	btn.Text = text
	btn.TextColor3 = Theme.Text
	btn.TextSize = 12
	btn.Parent = self.Container
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Border
	stroke.Thickness = 1
	stroke.Parent = btn
	
	local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	table.insert(self.Connections, btn.MouseButton1Click:Connect(function()
		TweenService:Create(btn, tweenInfo, {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Background, Size = UDim2.new(1, 0, 0, 35)}):Play()
		task.delay(0.15, function()
			if btn and btn.Parent then
				TweenService:Create(btn, tweenInfo, {BackgroundColor3 = Theme.SecondaryBackground, TextColor3 = Theme.Text, Size = UDim2.new(1, 0, 0, 34)}):Play()
			end
		end)
		if callback then task.spawn(callback) end
	end))
	table.insert(self.Connections, btn.MouseEnter:Connect(function()
		TweenService:Create(btn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(34, 34, 44)}):Play()
	end))
	table.insert(self.Connections, btn.MouseLeave:Connect(function()
		TweenService:Create(btn, tweenInfo, {BackgroundColor3 = Theme.SecondaryBackground}):Play()
	end))
	return btn
end

function Window:AddToggle(text: string, defaultState: boolean, callback: (boolean) -> ()): TextButton
	local id = self.Title .. "_" .. text
	local state = if configStorage[id] ~= nil then configStorage[id] else (defaultState or false)
	
	local container = Instance.new("TextButton")
	container.Size = UDim2.new(1, 0, 0, 34)
	container.BackgroundColor3 = Theme.SecondaryBackground
	container.BorderSizePixel = 0
	container.AutoButtonColor = false
	container.Text = ""
	container.Parent = self.Container
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = container
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Border
	stroke.Thickness = 1
	stroke.Parent = container
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -50, 1, 0)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = text
	label.TextColor3 = Theme.Text
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	
	local toggleBg = Instance.new("Frame")
	toggleBg.Name = "ToggleBg"
	toggleBg.Size = UDim2.new(0, 38, 0, 20)
	toggleBg.Position = UDim2.new(1, -46, 0.5, -10)
	toggleBg.BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(38, 38, 48)
	toggleBg.BorderSizePixel = 0
	toggleBg.Parent = container
	
	local toggleBgCorner = Instance.new("UICorner")
	toggleBgCorner.CornerRadius = UDim.new(1, 0)
	toggleBgCorner.Parent = toggleBg
	
	local toggleCircle = Instance.new("Frame")
	toggleCircle.Size = UDim2.new(0, 16, 0, 16)
	toggleCircle.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
	toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	toggleCircle.BorderSizePixel = 0
	toggleCircle.Parent = toggleBg
	
	local circleCorner = Instance.new("UICorner")
	circleCorner.CornerRadius = UDim.new(1, 0)
	circleCorner.Parent = toggleCircle
	
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local function updateVisual(instant: boolean)
		local goalBgColor = state and Theme.Accent or Color3.fromRGB(38, 38, 48)
		local goalCirclePos = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
		if instant then
			toggleBg.BackgroundColor3 = goalBgColor
			toggleCircle.Position = goalCirclePos
			stroke.Color = state and Theme.Accent or Theme.Border
		else
			TweenService:Create(toggleBg, tweenInfo, {BackgroundColor3 = goalBgColor}):Play()
			TweenService:Create(toggleCircle, tweenInfo, {Position = goalCirclePos}):Play()
			TweenService:Create(stroke, tweenInfo, {Color = state and Theme.Accent or Theme.Border}):Play()
		end
	end
	
	updateVisual(true)
	if callback then task.spawn(callback, state) end
	
	table.insert(self.Connections, container.MouseButton1Click:Connect(function()
		state = not state
		configStorage[id] = state
		saveConfiguration()
		updateVisual(false)
		if callback then task.spawn(callback, state) end
	end))
	table.insert(self.Connections, container.MouseEnter:Connect(function()
		TweenService:Create(container, tweenInfo, {BackgroundColor3 = Color3.fromRGB(30, 30, 38)}):Play()
	end))
	table.insert(self.Connections, container.MouseLeave:Connect(function()
		TweenService:Create(container, tweenInfo, {BackgroundColor3 = Theme.SecondaryBackground}):Play()
	end))
	return container
end

function Window:AddSlider(text: string, min: number, max: number, defaultVal: number, callback: (number) -> ()): Frame
	local id = self.Title .. "_" .. text
	local val = if configStorage[id] ~= nil then configStorage[id] else (defaultVal or min)
	
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 52)
	container.BackgroundColor3 = Theme.SecondaryBackground
	container.BorderSizePixel = 0
	container.Parent = self.Container
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = container
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Border
	stroke.Thickness = 1
	stroke.Parent = container
	
	local label = Instance.new("TextLabel")
	label.Name = "SliderLabel"
	label.Size = UDim2.new(1, -24, 0, 20)
	label.Position = UDim2.new(0, 12, 0, 6)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = text .. ": " .. tostring(val)
	label.TextColor3 = Theme.Text
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	
	local sliderBar = Instance.new("TextButton")
	sliderBar.Size = UDim2.new(1, -24, 0, 6)
	sliderBar.Position = UDim2.new(0, 12, 0, 34)
	sliderBar.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
	sliderBar.BorderSizePixel = 0
	sliderBar.AutoButtonColor = false
	sliderBar.Text = ""
	sliderBar.Parent = container
	
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = sliderBar
	
	local sliderFill = Instance.new("Frame")
	sliderFill.Name = "SliderFill"
	sliderFill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
	sliderFill.BackgroundColor3 = Theme.Accent
	sliderFill.BorderSizePixel = 0
	sliderFill.Parent = sliderBar
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = sliderFill
	
	local thumb = Instance.new("Frame")
	thumb.Size = UDim2.new(0, 12, 0, 12)
	thumb.AnchorPoint = Vector2.new(0.5, 0.5)
	thumb.Position = UDim2.new(1, 0, 0.5, 0)
	thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	thumb.BorderSizePixel = 0
	thumb.Parent = sliderFill
	
	local thumbCorner = Instance.new("UICorner")
	thumbCorner.CornerRadius = UDim.new(1, 0)
	thumbCorner.Parent = thumb
	
	local sliding = false
	local function updateValue(inputPos: number)
		local sizeX = sliderBar.AbsoluteSize.X
		if sizeX <= 0 then return end
		local posRelative = math.clamp((inputPos - sliderBar.AbsolutePosition.X) / sizeX, 0, 1)
		val = math.floor((min + (max - min) * posRelative) * 10) / 10
		sliderFill.Size = UDim2.new(posRelative, 0, 1, 0)
		label.Text = text .. ": " .. tostring(val)
		configStorage[id] = val
		saveConfiguration()
		if callback then task.spawn(callback, val) end
	end
	
	table.insert(self.Connections, sliderBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			TweenService:Create(thumb, TweenInfo.new(0.15), {Size = UDim2.new(0, 16, 0, 16)}):Play()
			updateValue(input.Position.X)
		end
	end))
	table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if sliding then
				sliding = false
				TweenService:Create(thumb, TweenInfo.new(0.15), {Size = UDim2.new(0, 12, 0, 12)}):Play()
			end
		end
	end))
	table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateValue(input.Position.X)
		end
	end))
	
	if callback then task.spawn(callback, val) end
	return container
end

function Window:AddKeybind(text: string, defaultKey: Enum.KeyCode, callback: (Enum.KeyCode) -> ()): Frame
	local id = self.Title .. "_" .. text
	local currentKey = defaultKey
	if configStorage[id] then
		currentKey = getKeyCodeFromName(configStorage[id])
	end
	
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 34)
	container.BackgroundColor3 = Theme.SecondaryBackground
	container.BorderSizePixel = 0
	container.Parent = self.Container
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = container
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Border
	stroke.Thickness = 1
	stroke.Parent = container
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -110, 1, 0)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = text
	label.TextColor3 = Theme.Text
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	
	local bindButton = Instance.new("TextButton")
	bindButton.Size = UDim2.new(0, 90, 0, 24)
	bindButton.Position = UDim2.new(1, -98, 0.5, -12)
	bindButton.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
	bindButton.BorderSizePixel = 0
	bindButton.Font = Enum.Font.Code
	bindButton.Text = currentKey.Name
	bindButton.TextColor3 = Color3.fromRGB(200, 200, 215)
	bindButton.TextSize = 11
	bindButton.Parent = container
	
	local bindCorner = Instance.new("UICorner")
	bindCorner.CornerRadius = UDim.new(0, 6)
	bindCorner.Parent = bindButton
	
	local binding = false
	table.insert(self.Connections, bindButton.MouseButton1Click:Connect(function()
		binding = true
		bindButton.Text = "..."
		bindButton.TextColor3 = Theme.Accent
	end))
	table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if binding then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				currentKey = input.KeyCode
				bindButton.Text = currentKey.Name
				bindButton.TextColor3 = Color3.fromRGB(200, 200, 215)
				binding = false
				configStorage[id] = currentKey.Name
				saveConfiguration()
				WindowManager.Notify("Keybind Updated", text .. " -> " .. currentKey.Name, 2)
			end
		elseif not gameProcessed and input.KeyCode == currentKey then
			if callback then task.spawn(callback, currentKey) end
		end
	end))
	return container
end

function Window:Destroy()
	for _, conn in ipairs(self.Connections) do
		conn:Disconnect()
	end
	table.clear(self.Connections)
	for i, win in ipairs(activeWindows) do
		if win == self then
			table.remove(activeWindows, i)
			break
		end
	end
	if self.MainFrame then
		self.MainFrame:Destroy()
	end
end

function WindowManager.CreateWindow(title: string, size: UDim2?, position: UDim2?): WindowObj
	return Window.new(title, size, position)
end

-- Barre d'état supérieure globale (SecEngine - FPS, Ping, Heure, User)
local topStatusBar: Frame? = nil
local function initializeStatusBar()
	if topStatusBar and topStatusBar.Parent then return end
	local gui = initializeGui()
	
	local bar = Instance.new("Frame")
	bar.Name = "SecEngine_StatusBar"
	bar.Size = UDim2.new(0, 420, 0, 30)
	bar.Position = UDim2.new(0.5, -210, 0, 12)
	bar.BackgroundColor3 = Theme.SecondaryBackground
	bar.BackgroundTransparency = 0.2
	bar.BorderSizePixel = 0
	bar.ZIndex = 500
	bar.Parent = gui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = bar
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Border
	stroke.Thickness = 1
	stroke.Parent = bar
	
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.Code
	lbl.TextColor3 = Theme.Text
	lbl.TextSize = 11
	lbl.Text = "SecEngine | FPS: 144 | Ping: 32ms | User: " .. Player.Name
	lbl.Parent = bar
	
	local frameCount = 0
	local lastTick = tick()
	table.insert(activeWindows, {
		Destroy = function()
			if bar then bar:Destroy() end
		end
	} :: any)
	
	RunService.RenderStepped:Connect(function()
		frameCount += 1
		local currentTick = tick()
		if currentTick - lastTick >= 1 then
			local fps = math.floor(frameCount / (currentTick - lastTick))
			local ping = 32
			pcall(function()
				ping = math.floor(Player:GetNetworkPing() * 1000)
			end)
			local timeStr = os.date("%H:%M")
			lbl.Text = string.format("SecEngine | FPS: %d | Ping: %dms | %s | %s", fps, ping, timeStr, Player.Name)
			frameCount = 0
			lastTick = currentTick
		end
	end)
	topStatusBar = bar
end

local function applyThemeToAll()
	for _, window in ipairs(activeWindows) do
		if window.MainFrame then
			window.MainFrame.BackgroundColor3 = Theme.Background
			window.MainFrame.BackgroundTransparency = configStorage.WindowTransparency or Theme.GlassTransparency
			local stroke = window.MainFrame:FindFirstChildOfClass("UIStroke")
			if stroke then stroke.Color = Theme.Border end
			
			local topAccent = window.MainFrame:FindFirstChild("TopAccent")
			if topAccent then (topAccent :: Frame).BackgroundColor3 = Theme.Accent end
			
			if window.TitleBar then
				window.TitleBar.BackgroundColor3 = Theme.SecondaryBackground
				local tStroke = window.TitleBar:FindFirstChildOfClass("UIStroke")
				if tStroke then tStroke.Color = Theme.Border end
			end
			
			if window.TitleLabel then
				window.TitleLabel.TextColor3 = Theme.Text
			end
			
			if window.MinimizeButton then
				window.MinimizeButton.BackgroundColor3 = Theme.SecondaryBackground
				window.MinimizeButton.TextColor3 = Theme.Text
				local mStroke = window.MinimizeButton:FindFirstChildOfClass("UIStroke")
				if mStroke then mStroke.Color = Theme.Border end
			end
			
			if window.Container then
				window.Container.ScrollBarImageColor3 = Theme.Accent
				for _, child in ipairs(window.Container:GetDescendants()) do
					if child:IsA("Frame") then
						if child.Name == "ToggleBg" then
							-- géré dynamiquement par l'état
						elseif child.Name == "SliderFill" then
							child.BackgroundColor3 = Theme.Accent
						else
							child.BackgroundColor3 = Theme.ContainerBackground
							local cStroke = child:FindFirstChildOfClass("UIStroke")
							if cStroke then cStroke.Color = Theme.Border end
							local header = child:FindFirstChild("HeaderLabel")
							if header and header:IsA("TextLabel") then
								header.TextColor3 = Theme.Accent
							end
						end
					elseif child:IsA("TextButton") then
						child.BackgroundColor3 = Theme.SecondaryBackground
						child.TextColor3 = Theme.Text
						local bStroke = child:FindFirstChildOfClass("UIStroke")
						if bStroke then bStroke.Color = Theme.Border end
					elseif child:IsA("TextLabel") then
						if child.Name ~= "HeaderLabel" then
							child.TextColor3 = Theme.Text
						end
					end
				end
			end
			
			if window.ResizeHandle then
				window.ResizeHandle.BackgroundColor3 = Theme.Border
			end
		end
	end
end

local function toggleModMenu()
	isMenuVisible = not isMenuVisible
	local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local blurGoal = isMenuVisible and 25 or 0
	local ccGoal = isMenuVisible and -0.1 or 0
	if blurEffect then TweenService:Create(blurEffect, tweenInfo, {Size = blurGoal}):Play() end
	if colorCorrection then TweenService:Create(colorCorrection, tweenInfo, {Brightness = ccGoal}):Play() end
	
	if screenGui then
		screenGui.Enabled = true
		for _, window in ipairs(activeWindows) do
			if window.MainFrame then
				local frame = window.MainFrame
				local targetTransparency = configStorage.WindowTransparency or Theme.GlassTransparency
				if isMenuVisible then
					frame.Visible = true
					frame.BackgroundTransparency = 1
					TweenService:Create(frame, tweenInfo, {BackgroundTransparency = targetTransparency}):Play()
				else
					local tw = TweenService:Create(frame, tweenInfo, {BackgroundTransparency = 1})
					tw:Play()
					tw.Completed:Connect(function()
						if not isMenuVisible then
							frame.Visible = false
						end
					end)
				end
			end
		end
		if not isMenuVisible then
			task.delay(0.4, function()
				if not isMenuVisible then
					screenGui.Enabled = false
				end
			end)
		end
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	local toggleKeyStr = configStorage.ToggleKey or "F1"
	local targetKeyCode = getKeyCodeFromName(toggleKeyStr)
	if input.KeyCode == targetKeyCode then
		toggleModMenu()
	end
end)

local function buildSettingsWindow()
	local settingsWin = WindowManager.CreateWindow("Settings", UDim2.new(0, 360, 0, 420))
	
	local themeContainer = settingsWin:AddContainer("Theme Selection")
	themeContainer:AddButton("Theme: Default", function()
		configStorage.CurrentTheme = "Default"
		Theme = Themes.Default
		saveConfiguration()
		applyThemeToAll()
		WindowManager.Notify("Theme Changed", "Applied Default theme.", 2)
	end)
	themeContainer:AddButton("Theme: Halloween", function()
		configStorage.CurrentTheme = "Halloween"
		Theme = Themes.Halloween
		saveConfiguration()
		applyThemeToAll()
		WindowManager.Notify("Theme Changed", "Applied Halloween theme.", 2)
	end)
	themeContainer:AddButton("Theme: Winter Arc", function()
		configStorage.CurrentTheme = "WinterArc"
		Theme = Themes.WinterArc
		saveConfiguration()
		applyThemeToAll()
		WindowManager.Notify("Theme Changed", "Applied Winter Arc theme.", 2)
	end)
	themeContainer:AddButton("Theme: Autumn", function()
		configStorage.CurrentTheme = "Autumn"
		Theme = Themes.Autumn
		saveConfiguration()
		applyThemeToAll()
		WindowManager.Notify("Theme Changed", "Applied Autumn theme.", 2)
	end)
	
	local bindContainer = settingsWin:AddContainer("UI Toggle Keybind")
	bindContainer:AddKeybind("Toggle Key", getKeyCodeFromName(configStorage.ToggleKey or "F1"), function(key)
		configStorage.ToggleKey = key.Name
		saveConfiguration()
	end)
end

task.spawn(function()
	task.wait(0.1)
	initializeStatusBar()
	buildSettingsWindow()
	WindowManager.Notify("SecEngine Loaded", "Welcome back, " .. Player.Name .. "!", 4)
end)

return WindowManager
