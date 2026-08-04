--[================================================================================]--
--|                 ROBLOX ADVANCED MODULAR WINDOW LIBRARY v2.0                    |--
--|              Secure Client-Side UI, Resizing & Persistence Engine              |--
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

-- État global & Configuration par défaut
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

-- Chargement sécurisé des configurations via pcall
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

-- Initialisation des effets visuels globaux (Lighting haute performance)
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
--|                         WINDOW CLASS (OOP & RESIZABLE)                         |--
--[================================================================================]--

local Window = {}
Window.__index = Window

function Window.new(titleText: string, size: UDim2?, position: UDim2?)
	local self = setmetatable({}, Window)
	
	self.Title = titleText or "Panel"
	self.Size = size or UDim2.new(0, 320, 0, 380)
	self.Position = position or UDim2.new(0.5, -160, 0.5, -190)
	
	self:CreateGui()
	table.insert(activeWindows, self)
	
	return self
end

function Window:CreateGui()
	local parentGui = initializeGui()
	
	-- Panneau principal SANS AUCUN UICorner (Style géométrique net)
	self.MainFrame = Instance.new("Frame")
	self.MainFrame.Name = self.Title .. "_Window"
	self.MainFrame.Size = self.Size
	self.MainFrame.Position = self.Position
	self.MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	self.MainFrame.BackgroundTransparency = configStorage.WindowTransparency or 0
	self.MainFrame.BorderSizePixel = 0
	self.MainFrame.Active = true
	self.MainFrame.Parent = parentGui
	
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(45, 45, 55)
	uiStroke.Thickness = 1
	uiStroke.Parent = self.MainFrame
	
	-- Barre de Titre (Drag Handle)
	self.TitleBar = Instance.new("Frame")
	self.TitleBar.Name = "TitleBar"
	self.TitleBar.Size = UDim2.new(1, 0, 0, 32)
	self.TitleBar.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
	self.TitleBar.BorderSizePixel = 0
	self.TitleBar.Parent = self.MainFrame
	
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(45, 45, 55)
	titleStroke.Thickness = 1
	titleStroke.Parent = self.TitleBar
	
	self.TitleLabel = Instance.new("TextLabel")
	self.TitleLabel.Size = UDim2.new(1, -16, 1, 0)
	self.TitleLabel.Position = UDim2.new(0, 12, 0, 0)
	self.TitleLabel.BackgroundTransparency = 1
	self.TitleLabel.Font = Enum.Font.Code
	self.TitleLabel.Text = "// " .. string.upper(self.Title)
	self.TitleLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
	self.TitleLabel.TextSize = 12
	self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.TitleLabel.Parent = self.TitleBar
	
	-- Conteneur Scrollable (Empêche le surplus et gère l'affichage dynamique)
	self.Container = Instance.new("ScrollingFrame")
	self.Container.Name = "Container"
	self.Container.Size = UDim2.new(1, -16, 1, -48)
	self.Container.Position = UDim2.new(0, 8, 0, 40)
	self.Container.BackgroundTransparency = 1
	self.Container.BorderSizePixel = 0
	self.Container.CanvasSize = UDim2.new(0, 0, 0, 0)
	self.Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
	self.Container.ScrollBarThickness = 3
	self.Container.ScrollBarImageColor3 = Color3.fromRGB(0, 170, 100)
	self.Container.Parent = self.MainFrame
	
	local uiLayout = Instance.new("UIListLayout")
	uiLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiLayout.Padding = UDim.new(0, 6)
	uiLayout.Parent = self.Container
	
	-- Poignée de redimensionnement (Resize Handle en bas à droite)
	self.ResizeHandle = Instance.new("TextButton")
	self.ResizeHandle.Name = "ResizeHandle"
	self.ResizeHandle.Size = UDim2.new(0, 14, 0, 14)
	self.ResizeHandle.Position = UDim2.new(1, -14, 1, -14)
	self.ResizeHandle.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
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
			local newWidth = math.clamp(startSize.X + delta.X, 220, 800)
			local newHeight = math.clamp(startSize.Y + delta.Y, 150, 700)
			
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
--|                        COMPOSANTS UI HAUTE FIDÉLITÉ                            |--
--[================================================================================]--

function Window:AddLabel(text: string)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 22)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = Color3.fromRGB(160, 160, 175)
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = self.Container
	return label
end

function Window:AddButton(text: string, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 30)
	btn.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Font = Enum.Font.GothamMedium
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(210, 210, 220)
	btn.TextSize = 12
	btn.Parent = self.Container
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(45, 45, 55)
	stroke.Thickness = 1
	stroke.Parent = btn
	
	btn.MouseButton1Click:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(0, 170, 100)}):Play()
		task.delay(0.08, function()
			TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(24, 24, 30)}):Play()
		end)
		if callback then task.spawn(callback) end
	end)
	
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(34, 34, 42)}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(24, 24, 30)}):Play()
	end)
	
	return btn
end

function Window:AddToggle(text: string, defaultState: boolean, callback)
	local id = self.Title .. "_" .. text
	local state = if configStorage[id] ~= nil then configStorage[id] else (defaultState or false)
	
	local container = Instance.new("TextButton")
	container.Size = UDim2.new(1, 0, 0, 30)
	container.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
	container.BorderSizePixel = 0
	container.AutoButtonColor = false
	container.Text = ""
	container.Parent = self.Container
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(45, 45, 55)
	stroke.Thickness = 1
	stroke.Parent = container
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -50, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = text
	label.TextColor3 = Color3.fromRGB(210, 210, 220)
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	
	local toggleBg = Instance.new("Frame")
	toggleBg.Size = UDim2.new(0, 32, 0, 16)
	toggleBg.Position = UDim2.new(1, -40, 0.5, -8)
	toggleBg.BackgroundColor3 = state and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(40, 40, 50)
	toggleBg.BorderSizePixel = 0
	toggleBg.Parent = container
	
	local toggleCircle = Instance.new("Frame")
	toggleCircle.Size = UDim2.new(0, 12, 0, 12)
	toggleCircle.Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
	toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	toggleCircle.BorderSizePixel = 0
	toggleCircle.Parent = toggleBg
	
	local function updateVisual(instant: boolean)
		local goalBgColor = state and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(40, 40, 50)
		local goalCirclePos = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
		
		if instant then
			toggleBg.BackgroundColor3 = goalBgColor
			toggleCircle.Position = goalCirclePos
		else
			TweenService:Create(toggleBg, TweenInfo.new(0.12), {BackgroundColor3 = goalBgColor}):Play()
			TweenService:Create(toggleCircle, TweenInfo.new(0.12), {Position = goalCirclePos}):Play()
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
	
	return container
end

function Window:AddSlider(text: string, min: number, max: number, defaultVal: number, callback)
	local id = self.Title .. "_" .. text
	local val = if configStorage[id] ~= nil then configStorage[id] else (defaultVal or min)
	
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 46)
	container.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
	container.BorderSizePixel = 0
	container.Parent = self.Container
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(45, 45, 55)
	stroke.Thickness = 1
	stroke.Parent = container
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 0, 20)
	label.Position = UDim2.new(0, 10, 0, 4)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = text .. ": " .. tostring(val)
	label.TextColor3 = Color3.fromRGB(210, 210, 220)
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	
	local sliderBar = Instance.new("TextButton")
	sliderBar.Size = UDim2.new(1, -20, 0, 4)
	sliderBar.Position = UDim2.new(0, 10, 0, 30)
	sliderBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	sliderBar.BorderSizePixel = 0
	sliderBar.AutoButtonColor = false
	sliderBar.Text = ""
	sliderBar.Parent = container
	
	local sliderFill = Instance.new("Frame")
	sliderFill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
	sliderFill.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
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
	container.Size = UDim2.new(1, 0, 0, 30)
	container.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
	container.BorderSizePixel = 0
	container.Parent = self.Container
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(45, 45, 55)
	stroke.Thickness = 1
	stroke.Parent = container
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -100, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = text
	label.TextColor3 = Color3.fromRGB(210, 210, 220)
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	
	local bindButton = Instance.new("TextButton")
	bindButton.Size = UDim2.new(0, 80, 0, 20)
	bindButton.Position = UDim2.new(1, -88, 0.5, -10)
	bindButton.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	bindButton.BorderSizePixel = 0
	bindButton.Font = Enum.Font.GothamMedium
	bindButton.Text = currentKey.Name
	bindButton.TextColor3 = Color3.fromRGB(180, 180, 195)
	bindButton.TextSize = 11
	bindButton.Parent = container
	
	local binding = false
	
	bindButton.MouseButton1Click:Connect(function()
		binding = true
		bindButton.Text = "..."
		bindButton.TextColor3 = Color3.fromRGB(0, 170, 100)
	end)
	
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if binding then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				currentKey = input.KeyCode
				bindButton.Text = currentKey.Name
				bindButton.TextColor3 = Color3.fromRGB(180, 180, 195)
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
--|                       PANNEAUX SPÉCIAUX (INSTRUCTIONS & SETTINGS)              |--
--[================================================================================]--

function WindowManager.BuildInstructionPanel()
	local instWindow = Window.new("Instructions", UDim2.new(0, 320, 0, 300), UDim2.new(0.5, -340, 0.25, 0))
	instWindow:AddLabel("--- Guide d'Utilisation ---")
	instWindow:AddLabel("• F1 (+ Alt par défaut) : Bascule l'UI.")
	instWindow:AddLabel("• Redimensionnement : Glissez le coin bas-droit.")
	instWindow:AddLabel("• Persistance : Sauvegarde automatique JSON.")
	instWindow:AddLabel("• Utilisez la molette pour scroller les panneaux.")
	return instWindow
end

function WindowManager.BuildSettingsPanel()
	local setWindow = Window.new("UI Settings", UDim2.new(0, 320, 0, 320), UDim2.new(0.5, 20, 0.25, 0))
	
	setWindow:AddLabel("--- Configuration Globale ---")
	
	-- Changement de touche Toggle avec bouton Reset à droite
	local keyContainer = Instance.new("Frame")
	keyContainer.Size = UDim2.new(1, 0, 0, 30)
	keyContainer.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
	keyContainer.BorderSizePixel = tabControl or 0
	keyContainer.Parent = setWindow.Container
	
	local keyLabel = Instance.new("TextLabel")
	keyLabel.Size = UDim2.new(1, -120, 1, 0)
	keyLabel.Position = UDim2.new(0, 10, 0, 0)
	keyLabel.BackgroundTransparency = 1
	keyLabel.Font = Enum.Font.GothamMedium
	keyLabel.Text = "Touche d'Ouverture"
	keyLabel.TextColor3 = Color3.fromRGB(210, 210, 220)
	keyLabel.TextSize = 12
	keyLabel.TextXAlignment = Enum.TextXAlignment.Left
	keyLabel.Parent = keyContainer
	
	local keyBtn = Instance.new("TextButton")
	keyBtn.Size = UDim2.new(0, 50, 0, 20)
	keyBtn.Position = UDim2.new(1, -114, 0.5, -10)
	keyBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	keyBtn.BorderSizePixel = 0
	keyBtn.Font = Enum.Font.GothamMedium
	keyBtn.Text = configStorage.ToggleKey or "F1"
	keyBtn.TextColor3 = Color3.fromRGB(180, 180, 195)
	keyBtn.TextSize = 11
	keyBtn.Parent = keyContainer
	
	local resetBtn = Instance.new("TextButton")
	resetBtn.Size = UDim2.new(0, 50, 0, 20)
	resetBtn.Position = UDim2.new(1, -58, 0.5, -10)
	resetBtn.BackgroundColor3 = Color3.fromRGB(170, 50, 50)
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
	
	-- Slider de transparence des fenêtres
	setWindow:AddSlider("Transparence Panneaux", 0, 0.8, configStorage.WindowTransparency or 0, function(val)
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
	
	local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	
	-- Application stricte des valeurs demandées : Blur = 30, Brightness = -0.1
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
			task.delay(0.35, function()
				if not isMenuVisible then
					screenGui.Enabled = false
				end
			end)
		end
	end
end

-- Écouteur global de la touche de bascule dynamique
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
