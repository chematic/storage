--[================================================================================]--
--|                 ROBLOX ADVANCED MODULAR WINDOW LIBRARY v2.2                    |--
--|         Ultra-Polished UI, Fluid Animations, Sub-Containers & Persistence      |--
--[================================================================================]--

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local WindowManager = {}
WindowManager.__index = WindowManager

-- Global State & Default Configuration
local activeWindows = {}
local isMenuVisible = true
local screenGui = nil
local blurEffect = nil
local colorCorrection = nil

local CONFIG_FILE_NAME = "ModMenu_Config.json"
local defaultConfig = {
	ToggleKey = "F1",
	RequireAlt = true,
	WindowTransparency = 0,
}
local configStorage = table.clone(defaultConfig)

-- Secure Configuration Loading via pcall
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

-- Global Visual Effects Initialization (High Performance Lighting)
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

local function initializeGui()
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
--|                      WINDOW CLASS (OOP, AUTO-LAYOUT & RESIZE)                  |--
--[================================================================================]--

local Window = {}
Window.__index = Window

function Window.new(titleText: string, size: UDim2?, position: UDim2?)
	local self = setmetatable({}, Window)
	
	self.Title = titleText or "Panel"
	self.Size = size or UDim2.new(0, 340, 0, 420)
	
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

function Window:CreateGui()
	local parentGui = initializeGui()
	
	-- Main Frame (Zero Corner Radius - Pure Geometric Sharp Design)
	self.MainFrame = Instance.new("Frame")
	self.MainFrame.Name = self.Title .. "_Window"
	self.MainFrame.Size = self.Size
	self.MainFrame.Position = self.Position
	self.MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 19)
	self.MainFrame.BackgroundTransparency = configStorage.WindowTransparency or 0
	self.MainFrame.BorderSizePixel = 0
	self.MainFrame.Active = true
	self.MainFrame.Parent = parentGui
	
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(40, 40, 52)
	uiStroke.Thickness = 1
	uiStroke.Parent = self.MainFrame
	
	-- Accent Glow Line on Top
	local topAccent = Instance.new("Frame")
	topAccent.Size = UDim2.new(1, 0, 0, 2)
	topAccent.BackgroundColor3 = Color3.fromRGB(0, 225, 130)
	topAccent.BorderSizePixel = 0
	topAccent.Parent = self.MainFrame
	
	-- Title Bar (Drag Handle)
	self.TitleBar = Instance.new("Frame")
	self.TitleBar.Name = "TitleBar"
	self.TitleBar.Size = UDim2.new(1, 0, 0, 34)
	self.TitleBar.Position = UDim2.new(0, 0, 0, 2)
	self.TitleBar.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
	self.TitleBar.BorderSizePixel = 0
	self.TitleBar.Parent = self.MainFrame
	
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(40, 40, 52)
	titleStroke.Thickness = 1
	titleStroke.Parent = self.TitleBar
	
	self.TitleLabel = Instance.new("TextLabel")
	self.TitleLabel.Size = UDim2.new(1, -16, 1, 0)
	self.TitleLabel.Position = UDim2.new(0, 12, 0, 0)
	self.TitleLabel.BackgroundTransparency = 1
	self.TitleLabel.Font = Enum.Font.JetBrainsMono
	self.TitleLabel.Text = "// " .. string.upper(self.Title)
	self.TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
	self.TitleLabel.TextSize = 12
	self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.TitleLabel.Parent = self.TitleBar
	
	-- Scrollable Container
	self.Container = Instance.new("ScrollingFrame")
	self.Container.Name = "Container"
	self.Container.Size = UDim2.new(1, -16, 1, -52)
	self.Container.Position = UDim2.new(0, 8, 0, 42)
	self.Container.BackgroundTransparency = 1
	self.Container.BorderSizePixel = 0
	self.Container.CanvasSize = UDim2.new(0, 0, 0, 0)
	self.Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
	self.Container.ScrollBarThickness = 3
	self.Container.ScrollBarImageColor3 = Color3.fromRGB(0, 225, 130)
	self.Container.Parent = self.MainFrame
	
	local uiLayout = Instance.new("UIListLayout")
	uiLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiLayout.Padding = UDim.new(0, 8)
	uiLayout.Parent = self.Container
	
	-- Bottom-Right Resize Handle
	self.ResizeHandle = Instance.new("TextButton")
	self.ResizeHandle.Name = "ResizeHandle"
	self.ResizeHandle.Size = UDim2.new(0, 14, 0, 14)
	self.ResizeHandle.Position = UDim2.new(1, -14, 1, -14)
	self.ResizeHandle.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
	self.ResizeHandle.BorderSizePixel = 0
	self.ResizeHandle.Text = ""
	self.ResizeHandle.AutoButtonColor = false
	self.ResizeHandle.Parent = self.MainFrame
	
	self:InitDragging()
	self:InitResizing()
end

function Window:InitDragging()
	local dragging, dragInput, dragStart, startPos
	
	self.TitleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = self.MainFrame.Position
			
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	
	self.TitleBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			self.MainFrame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

function Window:InitResizing()
	local resizing, resizeStart, startSize
	
	self.ResizeHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			resizeStart = input.Position
			startSize = self.MainFrame.AbsoluteSize
			
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					resizing = false
				end
			end)
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - resizeStart
			local newWidth = math.clamp(startSize.X + delta.X, 240, 800)
			local newHeight = math.clamp(startSize.Y + delta.Y, 180, 750)
			
			self.MainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
		end
	end)
end

function Window:SetTransparency(transparency: number)
	if self.MainFrame then
		self.MainFrame.BackgroundTransparency = transparency
	end
end

--[================================================================================]--
--|                     SUB-CONTAINER BUILDER (SECTIONS)                           |--
--[================================================================================]--

local ContainerObj = {}
ContainerObj.__index = ContainerObj

function Window:AddContainer(titleText: string?)
	local containerFrame = Instance.new("Frame")
	containerFrame.Size = UDim2.new(1, 0, 0, 0)
	containerFrame.AutomaticSize = Enum.AutomaticSize.Y
	containerFrame.BackgroundColor3 = Color3.fromRGB(19, 19, 25)
	containerFrame.BorderSizePixel = 0
	containerFrame.Parent = self.Container
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(45, 45, 58)
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
		header.Font = Enum.Font.JetBrainsMono
		header.Text = string.upper(titleText)
		header.TextColor3 = Color3.fromRGB(0, 225, 130)
		header.TextSize = 10
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.Parent = containerFrame
	end
	
	local wrapper = setmetatable({
		Instance = containerFrame,
		ParentContainer = containerFrame,
		Title = self.Title
	}, ContainerObj)
	
	return wrapper
end

-- Allow adding components directly inside sub-containers
function ContainerObj:AddLabel(text: string)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = Color3.fromRGB(170, 170, 185)
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = self.ParentContainer
	return label
end

function ContainerObj:AddButton(text: string, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 32)
	btn.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Font = Enum.Font.GothamMedium
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(220, 220, 230)
	btn.TextSize = 12
	btn.Parent = self.ParentContainer
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(45, 45, 58)
	stroke.Thickness = 1
	stroke.Parent = btn
	
	local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	
	btn.MouseButton1Click:Connect(function()
		TweenService:Create(btn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(0, 225, 130), TextColor3 = Color3.fromRGB(15, 15, 19)}):Play()
		task.delay(0.15, function()
			TweenService:Create(btn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(24, 24, 32), TextColor3 = Color3.fromRGB(220, 220, 230)}):Play()
		end)
		if callback then task.spawn(callback) end
	end)
	
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(34, 34, 44), BorderColor3 = Color3.fromRGB(0, 225, 130)}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(24, 24, 32)}):Play()
	end)
	
	return btn
end

--[================================================================================]--
--|                        UI COMPONENTS (HIGH FIDELITY ANIMATIONS)                |--
--[================================================================================]--

function Window:AddLabel(text: string)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 22)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = Color3.fromRGB(170, 170, 185)
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = self.Container
	return label
end

function Window:AddButton(text: string, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 32)
	btn.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Font = Enum.Font.GothamMedium
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(220, 220, 230)
	btn.TextSize = 12
	btn.Parent = self.Container
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(45, 45, 58)
	stroke.Thickness = 1
	stroke.Parent = btn
	
	local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	
	btn.MouseButton1Click:Connect(function()
		TweenService:Create(btn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(0, 225, 130), TextColor3 = Color3.fromRGB(15, 15, 19)}):Play()
		task.delay(0.15, function()
			TweenService:Create(btn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(24, 24, 32), TextColor3 = Color3.fromRGB(220, 220, 230)}):Play()
		end)
		if callback then task.spawn(callback) end
	end)
	
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(34, 34, 44)}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(24, 24, 32)}):Play()
	end)
	
	return btn
end

function Window:AddToggle(text: string, defaultState: boolean, callback)
	local id = self.Title .. "_" .. text
	local state = if configStorage[id] ~= nil then configStorage[id] else (defaultState or false)
	
	local container = Instance.new("TextButton")
	container.Size = UDim2.new(1, 0, 0, 32)
	container.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
	container.BorderSizePixel = 0
	container.AutoButtonColor = false
	container.Text = ""
	container.Parent = self.Container
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(45, 45, 58)
	stroke.Thickness = 1
	stroke.Parent = container
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -50, 1, 0)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = text
	label.TextColor3 = Color3.fromRGB(220, 220, 230)
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	
	local toggleBg = Instance.new("Frame")
	toggleBg.Size = UDim2.new(0, 36, 0, 18)
	toggleBg.Position = UDim2.new(1, -44, 0.5, -9)
	toggleBg.BackgroundColor3 = state and Color3.fromRGB(0, 225, 130) or Color3.fromRGB(38, 38, 48)
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
		local goalBgColor = state and Color3.fromRGB(0, 225, 130) or Color3.fromRGB(38, 38, 48)
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
	
	container.MouseButton1Click:Connect(function()
		state = not state
		configStorage[id] = state
		saveConfiguration()
		updateVisual(false)
		if callback then task.spawn(callback, state) end
	end)
	
	container.MouseEnter:Connect(function()
		TweenService:Create(container, tweenInfo, {BackgroundColor3 = Color3.fromRGB(30, 30, 38)}):Play()
	end)
	container.MouseLeave:Connect(function()
		TweenService:Create(container, tweenInfo, {BackgroundColor3 = Color3.fromRGB(24, 24, 32)}):Play()
	end)
	
	return container
end

function Window:AddSlider(text: string, min: number, max: number, defaultVal: number, callback)
	local id = self.Title .. "_" .. text
	local val = if configStorage[id] ~= nil then configStorage[id] else (defaultVal or min)
	
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 48)
	container.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
	container.BorderSizePixel = 0
	container.Parent = self.Container
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(45, 45, 58)
	stroke.Thickness = 1
	stroke.Parent = container
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -24, 0, 20)
	label.Position = UDim2.new(0, 12, 0, 4)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = text .. ": " .. tostring(val)
	label.TextColor3 = Color3.fromRGB(220, 220, 230)
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
	sliderFill.BackgroundColor3 = Color3.fromRGB(0, 225, 130)
	sliderFill.BorderSizePixel = 0
	sliderFill.Parent = sliderBar
	
	local sliding = false
	
	local function updateValue(inputPos)
		local sizeX = sliderBar.AbsoluteSize.X
		local posRelative = math.clamp((inputPos - sliderBar.AbsolutePosition.X) / sizeX, 0, 1)
		val = math.floor((min + (max - min) * posRelative) * 10) / 10
		
		sliderFill.Size = UDim2.new(posRelative, 0, 1, 0)
		label.Text = text .. ": " .. tostring(val)
		
		configStorage[id] = val
		saveConfiguration()
		
		if callback then task.spawn(callback, val) end
	end
	
	sliderBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			updateValue(input.Position.X)
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = false
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateValue(input.Position.X)
		end
	end)
	
	if callback then task.spawn(callback, val) end
	return container
end

function Window:AddKeybind(text: string, defaultKey: Enum.KeyCode, callback)
	local id = self.Title .. "_" .. text
	local currentKey = defaultKey
	
	if configStorage[id] then
		local success, enumItem = pcall(function()
			return Enum.KeyCode[configStorage[id]]
		end)
		if success and enumItem then currentKey = enumItem end
	end
	
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 32)
	container.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
	container.BorderSizePixel = 0
	container.Parent = self.Container
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(45, 45, 58)
	stroke.Thickness = 1
	stroke.Parent = container
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -110, 1, 0)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = text
	label.TextColor3 = Color3.fromRGB(220, 220, 230)
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	
	local bindButton = Instance.new("TextButton")
	bindButton.Size = UDim2.new(0, 86, 0, 22)
	bindButton.Position = UDim2.new(1, -94, 0.5, -11)
	bindButton.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
	bindButton.BorderSizePixel = 0
	bindButton.Font = Enum.Font.JetBrainsMono
	bindButton.Text = currentKey.Name
	bindButton.TextColor3 = Color3.fromRGB(200, 200, 215)
	bindButton.TextSize = 11
	bindButton.Parent = container
	
	local binding = false
	
	bindButton.MouseButton1Click:Connect(function()
		binding = true
		bindButton.Text = "..."
		bindButton.TextColor3 = Color3.fromRGB(0, 225, 130)
	end)
	
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
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
	end)
	
	return container
end

--[================================================================================]--
--|                       SPECIAL PANELS (INSTRUCTIONS & SETTINGS)                 |--
--[================================================================================]--

function WindowManager.BuildInstructionPanel()
	local instWindow = Window.new("Instructions")
	
	local infoContainer = instWindow:AddContainer("User Guide")
	infoContainer:AddLabel("• F1 (+ Alt by default) : Toggle UI")
	infoContainer:AddLabel("• Resizing : Drag bottom-right corner")
	infoContainer:AddLabel("• Persistence : Auto-saves to JSON")
	infoContainer:AddLabel("• Use mouse wheel to scroll panels")
	
	return instWindow
end

function WindowManager.BuildSettingsPanel()
	local setWindow = Window.new("UI Settings")
	
	local configContainer = setWindow:AddContainer("Global Configuration")
	
	local keyContainer = Instance.new("Frame")
	keyContainer.Size = UDim2.new(1, 0, 0, 32)
	keyContainer.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
	keyContainer.BorderSizePixel = 0
	keyContainer.Parent = configContainer.ParentContainer
	
	local keyLabel = Instance.new("TextLabel")
	keyLabel.Size = UDim2.new(1, -120, 1, 0)
	keyLabel.Position = UDim2.new(0, 12, 0, 0)
	keyLabel.BackgroundTransparency = 1
	keyLabel.Font = Enum.Font.GothamMedium
	keyLabel.Text = "Toggle Key"
	keyLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
	keyLabel.TextSize = 12
	keyLabel.TextXAlignment = Enum.TextXAlignment.Left
	keyLabel.Parent = keyContainer
	
	local keyBtn = Instance.new("TextButton")
	keyBtn.Size = UDim2.new(0, 50, 0, 22)
	keyBtn.Position = UDim2.new(1, -118, 0.5, -11)
	keyBtn.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
	keyBtn.BorderSizePixel = 0
	keyBtn.Font = Enum.Font.JetBrainsMono
	keyBtn.Text = configStorage.ToggleKey or "F1"
	keyBtn.TextColor3 = Color3.fromRGB(200, 200, 215)
	keyBtn.TextSize = 11
	keyBtn.Parent = keyContainer
	
	local resetBtn = Instance.new("TextButton")
	resetBtn.Size = UDim2.new(0, 56, 0, 22)
	resetBtn.Position = UDim2.new(1, -60, 0.5, -11)
	resetBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	resetBtn.BorderSizePixel = 0
	resetBtn.Font = Enum.Font.GothamMedium
	resetBtn.Text = "Reset"
	resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	resetBtn.TextSize = 11
	resetBtn.Parent = keyContainer
	
	local settingKeyBinding = false
	keyBtn.MouseButton1Click:Connect(function()
		settingKeyBinding = true
		keyBtn.Text = "..."
	end)
	
	UserInputService.InputBegan:Connect(function(input)
		if settingKeyBinding and input.UserInputType == Enum.UserInputType.Keyboard then
			configStorage.ToggleKey = input.KeyCode.Name
			keyBtn.Text = input.KeyCode.Name
			settingKeyBinding = false
			saveConfiguration()
		end
	end)
	
	resetBtn.MouseButton1Click:Connect(function()
		configStorage.ToggleKey = defaultConfig.ToggleKey
		configStorage.WindowTransparency = defaultConfig.WindowTransparency
		keyBtn.Text = defaultConfig.ToggleKey
		saveConfiguration()
		for _, w in ipairs(activeWindows) do
			w:SetTransparency(defaultConfig.WindowTransparency)
		end
	end)
	
	setWindow:AddSlider("Panel Transparency", 0, 0.8, configStorage.WindowTransparency or 0, function(val)
		configStorage.WindowTransparency = val
		saveConfiguration()
		for _, w in ipairs(activeWindows) do
			w:SetTransparency(val)
		end
	end)
	
	return setWindow
end

--[================================================================================]--
--|                       MANAGER & ANIMATIONS (FADE IN/OUT)                       |--
--[================================================================================]--

function WindowManager.CreateWindow(title: string, size: UDim2?, position: UDim2?)
	return Window.new(title, size, position)
end

local function toggleModMenu()
	isMenuVisible = not isMenuVisible
	
	local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	
	local blurGoal = isMenuVisible and 30 or 0
	local ccGoal = isMenuVisible and -0.1 or 0
	
	TweenService:Create(blurEffect, tweenInfo, {Size = blurGoal}):Play()
	TweenService:Create(colorCorrection, tweenInfo, {Brightness = ccGoal}):Play()
	
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
		return Enum.KeyCode[configStorage.ToggleKey or "F1"]
	end)
	
	if success and targetKeyCode and input.KeyCode == targetKeyCode then
		local isAltPressed = not configStorage.RequireAlt or (UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt))
		if isAltPressed then
			toggleModMenu()
		end
	end
end)

return WindowManager
