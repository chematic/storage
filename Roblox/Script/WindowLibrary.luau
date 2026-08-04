--!strict
--[================================================================================]--
--|                 ROBLOX ADVANCED MODULAR WINDOW LIBRARY v3.0                    |--
--|      Industrial-Grade Architecture, Memory Safe, Strict Typing & Theming       |--
--[================================================================================]--

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--[================================================================================]--
--|                       THEMING ENGINE & CONFIGURATION                           |--
--[================================================================================]--

export type ThemeConfig = {
	Background: Color3,
	SecondaryBackground: Color3,
	ContainerBackground: Color3,
	Accent: Color3,
	Text: Color3,
	TextDim: Color3,
	Border: Color3,
	Error: Color3,
}

local Theme: ThemeConfig = {
	Background = Color3.fromRGB(15, 15, 19),
	SecondaryBackground = Color3.fromRGB(22, 22, 28),
	ContainerBackground = Color3.fromRGB(19, 19, 25),
	Accent = Color3.fromRGB(0, 225, 130),
	Text = Color3.fromRGB(240, 240, 245),
	TextDim = Color3.fromRGB(170, 170, 185),
	Border = Color3.fromRGB(40, 40, 52),
	Error = Color3.fromRGB(180, 50, 50),
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
	RequireAlt = true,
	WindowTransparency = 0,
}
local configStorage = table.clone(defaultConfig)

local function loadConfiguration()
	if not writefile or not readfile then return end
	pcall(function()
		if isfile and isfile(CONFIG_FILE_NAME) then
			local content = readfile(CONFIG_FILE_NAME)
			local decoded = HttpService:JSONDecode(content)
			if type(decoded) == "table" then
				for k, v in pairs(decoded) do
					configStorage[k] = v
				end
			end
		end
	end)
end

local function saveConfiguration()
	if not writefile then return end
	pcall(function()
		local encoded = HttpService:JSONEncode(configStorage)
		writefile(CONFIG_FILE_NAME, encoded)
	end)
end

loadConfiguration()

local function initializeLightingEffects()
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
end

local function initializeGui(): ScreenGui
	if screenGui then return screenGui end
	initializeLightingEffects()
	
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SecureAdvancedModMenu"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = PlayerGui
	
	return screenGui
end

--[================================================================================]--
--|                        CONTAINER CLASS & SUB-SECTIONS                          |--
--[================================================================================]--

export type ContainerObj = {
	Instance: Frame,
	ParentContainer: Frame,
	Title: string,
	Connections: {RBXScriptConnection},
	AddLabel: (self: ContainerObj, text: string) -> TextLabel,
	AddButton: (self: ContainerObj, text: string, callback: () -> ()) -> TextButton,
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
	btn.Size = UDim2.new(1, 0, 0, 32)
	btn.BackgroundColor3 = Theme.SecondaryBackground
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Font = Enum.Font.GothamMedium
	btn.Text = text
	btn.TextColor3 = Theme.Text
	btn.TextSize = 12
	btn.Parent = self.ParentContainer
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Border
	stroke.Thickness = 1
	stroke.Parent = btn
	
	local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	
	table.insert(self.Connections, btn.MouseButton1Click:Connect(function()
		TweenService:Create(btn, tweenInfo, {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Background}):Play()
		task.delay(0.15, function()
			if btn and btn.Parent then
				TweenService:Create(btn, tweenInfo, {BackgroundColor3 = Theme.SecondaryBackground, TextColor3 = Theme.Text}):Play()
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

function ContainerMeta:Destroy()
	for _, conn in ipairs(self.Connections) do
		conn:Disconnect()
	end
	table.clear(self.Connections)
	if self.Instance then
		self.Instance:Destroy()
	end
end

--[================================================================================]--
--|                        WINDOW CLASS (OOP, FOCUS & CLEANUP)                     |--
--[================================================================================]--

export type WindowObj = {
	Title: string,
	Size: UDim2,
	Position: UDim2,
	MainFrame: Frame,
	TitleBar: Frame,
	TitleLabel: TextLabel,
	Container: ScrollingFrame,
	ResizeHandle: TextButton,
	Connections: {RBXScriptConnection},
	CreateGui: (self: WindowObj) -> (),
	InitDragging: (self: WindowObj) -> (),
	InitResizing: (self: WindowObj) -> (),
	BringToFront: (self: WindowObj) -> (),
	SetTransparency: (self: WindowObj, transparency: number) -> (),
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
	self.Size = size or UDim2.new(0, 340, 0, 420)
	self.Connections = {}
	
	if position then
		self.Position = position
	else
		local windowCount = #activeWindows
		local defaultWidth = 340
		local spacing = 20
		local startX = 40 + (windowCount * (defaultWidth + spacing))
		local startY = 80
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
	
	self.MainFrame = Instance.new("Frame")
	self.MainFrame.Name = self.Title .. "_Window"
	self.MainFrame.Size = self.Size
	self.MainFrame.Position = self.Position
	self.MainFrame.BackgroundColor3 = Theme.Background
	self.MainFrame.BackgroundTransparency = configStorage.WindowTransparency or 0
	self.MainFrame.BorderSizePixel = 0
	self.MainFrame.Active = true
	self.MainFrame.ZIndex = globalZIndexCounter
	self.MainFrame.Parent = parentGui
	
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Theme.Border
	uiStroke.Thickness = 1
	uiStroke.Parent = self.MainFrame
	
	local topAccent = Instance.new("Frame")
	topAccent.Size = UDim2.new(1, 0, 0, 2)
	topAccent.BackgroundColor3 = Theme.Accent
	topAccent.BorderSizePixel = 0
	topAccent.Parent = self.MainFrame
	
	self.TitleBar = Instance.new("Frame")
	self.TitleBar.Name = "TitleBar"
	self.TitleBar.Size = UDim2.new(1, 0, 0, 34)
	self.TitleBar.Position = UDim2.new(0, 0, 0, 2)
	self.TitleBar.BackgroundColor3 = Theme.SecondaryBackground
	self.TitleBar.BorderSizePixel = 0
	self.TitleBar.Parent = self.MainFrame
	
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Theme.Border
	titleStroke.Thickness = 1
	titleStroke.Parent = self.TitleBar
	
	self.TitleLabel = Instance.new("TextLabel")
	self.TitleLabel.Size = UDim2.new(1, -16, 1, 0)
	self.TitleLabel.Position = UDim2.new(0, 12, 0, 0)
	self.TitleLabel.BackgroundTransparency = 1
	self.TitleLabel.Font = Enum.Font.Code
	self.TitleLabel.Text = "// " .. string.upper(self.Title)
	self.TitleLabel.TextColor3 = Theme.Text
	self.TitleLabel.TextSize = 12
	self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.TitleLabel.Parent = self.TitleBar
	
	self.Container = Instance.new("ScrollingFrame")
	self.Container.Name = "Container"
	self.Container.Size = UDim2.new(1, -16, 1, -52)
	self.Container.Position = UDim2.new(0, 8, 0, 42)
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
	self.ResizeHandle.Size = UDim2.new(0, 14, 0, 14)
	self.ResizeHandle.Position = UDim2.new(1, -14, 1, -14)
	self.ResizeHandle.BackgroundColor3 = Theme.Border
	self.ResizeHandle.BorderSizePixel = 0
	self.ResizeHandle.Text = ""
	self.ResizeHandle.AutoButtonColor = false
	self.ResizeHandle.Parent = self.MainFrame
	
	table.insert(self.Connections, self.MainFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self:BringToFront()
		end
	end))
	
	self:InitDragging()
	self:InitResizing()
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
			local newWidth = math.clamp(startSize.X + delta.X, 240, 800)
			local newHeight = math.clamp(startSize.Y + delta.Y, 180, 750)
			
			self.MainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
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
	containerFrame.BorderSizePixel = 0
	containerFrame.Parent = self.Container
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Border
	stroke.Thickness = 1
	stroke.Parent = containerFrame
	
	local innerLayout = Instance.new("UIListLayout")
	innerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	innerLayout.Padding = UDim.new(0, 6)
	innerLayout.Parent = containerFrame
	
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = containerFrame
	
	if titleText and titleText ~= "" then
		local header = Instance.new("TextLabel")
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
	btn.Size = UDim2.new(1, 0, 0, 32)
	btn.BackgroundColor3 = Theme.SecondaryBackground
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Font = Enum.Font.GothamMedium
	btn.Text = text
	btn.TextColor3 = Theme.Text
	btn.TextSize = 12
	btn.Parent = self.Container
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Border
	stroke.Thickness = 1
	stroke.Parent = btn
	
	local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	
	table.insert(self.Connections, btn.MouseButton1Click:Connect(function()
		TweenService:Create(btn, tweenInfo, {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Background}):Play()
		task.delay(0.15, function()
			if btn and btn.Parent then
				TweenService:Create(btn, tweenInfo, {BackgroundColor3 = Theme.SecondaryBackground, TextColor3 = Theme.Text}):Play()
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
	container.Size = UDim2.new(1, 0, 0, 32)
	container.BackgroundColor3 = Theme.SecondaryBackground
	container.BorderSizePixel = 0
	container.AutoButtonColor = false
	container.Text = ""
	container.Parent = self.Container
	
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
	toggleBg.Size = UDim2.new(0, 36, 0, 18)
	toggleBg.Position = UDim2.new(1, -44, 0.5, -9)
	toggleBg.BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(38, 38, 48)
	toggleBg.BorderSizePixel = 0
	toggleBg.Parent = container
	
	local toggleCircle = Instance.new("Frame")
	toggleCircle.Size = UDim2.new(0, 14, 0, 14)
	toggleCircle.Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
	toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	toggleCircle.BorderSizePixel = 0
	toggleCircle.Parent = toggleBg
	
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	
	local function updateVisual(instant: boolean)
		local goalBgColor = state and Theme.Accent or Color3.fromRGB(38, 38, 48)
		local goalCirclePos = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
		
		if instant then
			toggleBg.BackgroundColor3 = goalBgColor
			toggleCircle.Position = goalCirclePos
		else
			TweenService:Create(toggleBg, tweenInfo, {BackgroundColor3 = goalBgColor}):Play()
			TweenService:Create(toggleCircle, tweenInfo, {Position = goalCirclePos}):Play()
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
	container.Size = UDim2.new(1, 0, 0, 48)
	container.BackgroundColor3 = Theme.SecondaryBackground
	container.BorderSizePixel = 0
	container.Parent = self.Container
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Border
	stroke.Thickness = 1
	stroke.Parent = container
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -24, 0, 20)
	label.Position = UDim2.new(0, 12, 0, 4)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = text .. ": " .. tostring(val)
	label.TextColor3 = Theme.Text
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	
	local sliderBar = Instance.new("TextButton")
	sliderBar.Size = UDim2.new(1, -24, 0, 6)
	sliderBar.Position = UDim2.new(0, 12, 0, 32)
	sliderBar.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
	sliderBar.BorderSizePixel = 0
	sliderBar.AutoButtonColor = false
	sliderBar.Text = ""
	sliderBar.Parent = container
	
	local sliderFill = Instance.new("Frame")
	sliderFill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
	sliderFill.BackgroundColor3 = Theme.Accent
	sliderFill.BorderSizePixel = 0
	sliderFill.Parent = sliderBar
	
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
			updateValue(input.Position.X)
		end
	end))
	
	table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = false
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
		local success, enumItem = pcall(function()
			return (Enum.KeyCode :: any)[configStorage[id]]
		end)
		if success and enumItem then currentKey = enumItem end
	end
	
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 32)
	container.BackgroundColor3 = Theme.SecondaryBackground
	container.BorderSizePixel = 0
	container.Parent = self.Container
	
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
	bindButton.Size = UDim2.new(0, 86, 0, 22)
	bindButton.Position = UDim2.new(1, -94, 0.5, -11)
	bindButton.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
	bindButton.BorderSizePixel = 0
	bindButton.Font = Enum.Font.Code
	bindButton.Text = currentKey.Name
	bindButton.TextColor3 = Color3.fromRGB(200, 200, 215)
	bindButton.TextSize = 11
	bindButton.Parent = container
	
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

--[================================================================================]--
--|                       MANAGER & ANIMATIONS (FADE IN/OUT)                       |--
--[================================================================================]--

function WindowManager.CreateWindow(title: string, size: UDim2?, position: UDim2?): WindowObj
	return Window.new(title, size, position)
end

local function toggleModMenu()
	isMenuVisible = not isMenuVisible
	
	local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	
	local blurGoal = isMenuVisible and 30 or 0
	local ccGoal = isMenuVisible and -0.1 or 0
	
	if blurEffect then TweenService:Create(blurEffect, tweenInfo, {Size = blurGoal}):Play() end
	if colorCorrection then TweenService:Create(colorCorrection, tweenInfo, {Brightness = ccGoal}):Play() end
	
	if screenGui then
		screenGui.Enabled = true
		for _, window in ipairs(activeWindows) do
			local frame = window.MainFrame
			local targetTransparency = configStorage.WindowTransparency or 0
			
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
	
	local success, targetKeyCode = pcall(function()
		return (Enum.KeyCode :: any)[configStorage.ToggleKey or "F1"]
	end)
	
	if success and targetKeyCode and input.KeyCode == targetKeyCode then
		local isAltPressed = not configStorage.RequireAlt or (UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt))
		if isAltPressed then
			toggleModMenu()
		end
	end
end)

return WindowManager
