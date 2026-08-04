--[================================================================================]--
--|                 ROBLOX ADVANCED MODULAR WINDOW LIBRARY                         |--
--|                Secure Client-Side UI & Persistence System                      |--
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

-- État global
local activeWindows = {}
local isMenuVisible = true
local screenGui = nil
local blurEffect = nil
local colorCorrection = nil

-- Données persistantes (configurations)
local configStorage = {}
local CONFIG_FILE_NAME = "ModMenu_Config.json"

-- Fonction de chargement des configurations locales (sécurisé via pcall)
local function loadConfiguration()
	if not writefile or not readfile then return end -- Sécurité si l'environnement d'exécution ne le supporte pas
	pcall(function()
		if isfile and isfile(CONFIG_FILE_NAME) then
			local content = readfile(CONFIG_FILE_NAME)
			local decoded = HttpService:JSONDecode(content)
			if type(decoded) == "table" then
				configStorage = decoded
			end
		end
	end)
end

-- Fonction de sauvegarde
local function saveConfiguration()
	if not writefile then return end
	pcall(function()
		local encoded = HttpService:JSONEncode(configStorage)
		writefile(CONFIG_FILE_NAME, encoded)
	end)
end

loadConfiguration()

-- Initialisation des effets visuels globaux (Lighting)
local function initializeLightingEffects()
	if not blurEffect then
		blurEffect = Instance.new("BlurEffect")
		blurEffect.Name = "ModMenu_Blur"
		blurEffect.Size = 0
		blurEffect.Parent = Lighting
	end
	
	if not colorCorrection then
		colorCorrection = Instance.new("ColorCorrectionEffect")
		colorCorrection.Name = "ModMenu_CC"
		colorCorrection.Brightness = 0
		colorCorrection.Parent = Lighting
	end
end

-- Initialisation du ScreenGui principal
local function initializeGui()
	if screenGui then return screenGui end
	
	initializeLightingEffects()
	
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AdvancedModMenuUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = PlayerGui
	
	return screenGui
end

--[================================================================================]--
--|                         WINDOW CLASS                                           |--
--[================================================================================]--

local Window = {}
Window.__index = Window

function Window.new(titleText: string, size: UDim2?, position: UDim2?)
	local self = setmetatable({}, Window)
	
	self.Title = titleText or "Panel"
	self.Size = size or UDim2.new(0, 300, 0, 350)
	self.Position = position or UDim2.new(0.5, -150, 0.5, -175)
	
	self:CreateGui()
	table.insert(activeWindows, self)
	
	return self
end

function Window:CreateGui()
	local parentGui = initializeGui()
	
	self.MainFrame = Instance.new("Frame")
	self.MainFrame.Name = self.Title .. "_Window"
	self.MainFrame.Size = self.Size
	self.MainFrame.Position = self.Position
	self.MainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
	self.MainFrame.BorderSizePixel = 0
	self.MainFrame.Active = true
	self.MainFrame.Parent = parentGui
	
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 8)
	uiCorner.Parent = self.MainFrame
	
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(45, 45, 52)
	uiStroke.Thickness = 1
	uiStroke.Parent = self.MainFrame
	
	-- Barre de Titre (Drag Handle)
	self.TitleBar = Instance.new("Frame")
	self.TitleBar.Name = "TitleBar"
	self.TitleBar.Size = UDim2.new(1, 0, 0, 32)
	self.TitleBar.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
	self.TitleBar.BorderSizePixel = 0
	self.TitleBar.Parent = self.MainFrame
	
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 8)
	titleCorner.Parent = self.TitleBar
	
	local fixFrame = Instance.new("Frame")
	fixFrame.Size = UDim2.new(1, 0, 0, 8)
	fixFrame.Position = UDim2.new(0, 0, 1, -8)
	fixFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
	fixFrame.BorderSizePixel = 0
	fixFrame.Parent = self.TitleBar
	
	self.TitleLabel = Instance.new("TextLabel")
	self.TitleLabel.Size = UDim2.new(1, -16, 1, 0)
	self.TitleLabel.Position = UDim2.new(0, 12, 0, 0)
	self.TitleLabel.BackgroundTransparency = 1
	self.TitleLabel.Font = Enum.Font.GothamMedium
	self.TitleLabel.Text = self.Title
	self.TitleLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
	self.TitleLabel.TextSize = 13
	self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.TitleLabel.Parent = self.TitleBar
	
	-- Conteneur Scrollable
	self.Container = Instance.new("ScrollingFrame")
	self.Container.Name = "Container"
	self.Container.Size = UDim2.new(1, -16, 1, -48)
	self.Container.Position = UDim2.new(0, 8, 0, 40)
	self.Container.BackgroundTransparency = 1
	self.Container.BorderSizePixel = 0
	self.Container.CanvasSize = UDim2.new(0, 0, 0, 0)
	self.Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
	self.Container.ScrollBarThickness = 4
	self.Container.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 70)
	self.Container.Parent = self.MainFrame
	
	local uiLayout = Instance.new("UIListLayout")
	uiLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiLayout.Padding = UDim.new(0, 6)
	uiLayout.Parent = self.Container
	
	self:InitDragging()
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

--[================================================================================]--
--|                        COMPOSANTS UI AVANCÉS                                   |--
--[================================================================================]--

function Window:AddLabel(text: string)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 24)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = Color3.fromRGB(180, 180, 190)
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = self.Container
	return label
end

function Window:AddButton(text: string, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 32)
	btn.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Font = Enum.Font.GothamMedium
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(200, 200, 210)
	btn.TextSize = 12
	btn.Parent = self.Container
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn
	
	btn.MouseButton1Click:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(50, 50, 65)}):Play()
		task.delay(0.1, function()
			TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(32, 32, 38)}):Play()
		end)
		if callback then task.spawn(callback) end
	end)
	
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40, 40, 48)}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(32, 32, 38)}):Play()
	end)
	
	return btn
end

function Window:AddToggle(text: string, defaultState: boolean, callback)
	local id = self.Title .. "_" .. text
	local state = if configStorage[id] ~= nil then configStorage[id] else (defaultState or false)
	
	local container = Instance.new("TextButton")
	container.Size = UDim2.new(1, 0, 0, 32)
	container.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
	container.BorderSizePixel = 0
	container.AutoButtonColor = false
	container.Text = ""
	container.Parent = self.Container
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = container
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -50, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = text
	label.TextColor3 = Color3.fromRGB(200, 200, 210)
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	
	local toggleBg = Instance.new("Frame")
	toggleBg.Size = UDim2.new(0, 36, 0, 18)
	toggleBg.Position = UDim2.new(1, -44, 0.5, -9)
	toggleBg.BackgroundColor3 = state and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(50, 50, 60)
	toggleBg.BorderSizePixel = 0
	toggleBg.Parent = container
	
	local toggleBgCorner = Instance.new("UICorner")
	toggleBgCorner.CornerRadius = UDim.new(1, 0)
	toggleBgCorner.Parent = toggleBg
	
	local toggleCircle = Instance.new("Frame")
	toggleCircle.Size = UDim2.new(0, 14, 0, 14)
	toggleCircle.Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
	toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	toggleCircle.BorderSizePixel =urses = 0
	toggleCircle.BorderSizePixel = 0
	toggleCircle.Parent = toggleBg
	
	local toggleCircleCorner = Instance.new("UICorner")
	toggleCircleCircleCorner = Instance.new("UICorner")
	toggleCircleCorner.CornerRadius = UDim.new(1, 0)
	toggleCircleCorner.Parent = toggleCircle
	
	local function updateVisual(instant: boolean)
		local goalBgColor = state and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(50, 50, 60)
		local goalCirclePos = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
		
		if instant then
			toggleBg.BackgroundColor3 = goalBgColor
			toggleCircle.Position = goalCirclePos
		else
			TweenService:Create(toggleBg, TweenInfo.new(0.15), {BackgroundColor3 = goalBgColor}):Play()
			TweenService:Create(toggleCircle, TweenInfo.new(0.15), {Position = goalCirclePos}):Play()
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
	container.Size = UDim2.new(1, 0, 0, 50)
	container.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
	container.BorderSizePixel = 0
	container.Parent = self.Container
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = container
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 0, 20)
	label.Position = UDim2.new(0, 10, 0, 4)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = text .. ": " .. tostring(val)
	label.TextColor3 = Color3.fromRGB(200, 200, 210)
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	
	local sliderBar = Instance.new("TextButton")
	sliderBar.Size = UDim2.new(1, -20, 0, 6)
	sliderBar.Position = UDim2.new(0, 10, 0, 32)
	sliderBar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	sliderBar.BorderSizePixel = 0
	sliderBar.AutoButtonColor = false
	sliderBar.Text = ""
	sliderBar.Parent = container
	
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = sliderBar
	
	local sliderFill = Instance.new("Frame")
	sliderFill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
	sliderFill.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
	sliderFill.BorderSizePixel = 0
	sliderFill.Parent = sliderBar
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = sliderFill
	
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
	container.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
	container.BorderSizePixel = 0
	container.Parent = self.Container
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = container
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -100, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = text
	label.TextColor3 = Color3.fromRGB(200, 200, 210)
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	
	local bindButton = Instance.new("TextButton")
	bindButton.Size = UDim2.new(0, 80, 0, 22)
	bindButton.Position = UDim2.new(1, -88, 0.5, -11)
	bindButton.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	bindButton.BorderSizePixel = 0
	bindButton.Font = Enum.Font.GothamMedium
	bindButton.Text = currentKey.Name
	bindButton.TextColor3 = Color3.fromRGB(180, 180, 190)
	bindButton.TextSize = 11
	bindButton.Parent = container
	
	local bindCorner = Instance.new("UICorner")
	bindCorner.CornerRadius = UDim.new(0, 4)
	bindCorner.Parent = bindButton
	
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
				bindButton.TextColor3 = Color3.fromRGB(180, 180, 190)
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
--|                       MANAGER & FADE ANIMATIONS                                |--
--[================================================================================]--

function WindowManager.CreateWindow(title: string, size: UDim2?, position: UDim2?)
	return Window.new(title, size, position)
end

-- Bascule globale du Mod Menu avec Fade In / Fade Out et effets Lighting
local function toggleModMenu()
	isMenuVisible = not isMenuVisible
	
	-- Paramètres de Tween pour les fenêtres
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	
	-- Transition des effets du monde (Lighting)
	local blurGoal = isMenuVisible and 40 or 0
	local ccGoal = isMenuVisible and -1 or 0
	
	TweenService:Create(blurEffect, tweenInfo, {Size = blurGoal}):Play()
	TweenService:Create(colorCorrection, tweenInfo, {Brightness = ccGoal}):Play()
	
	if screenGui then
		screenGui.Enabled = true
		for _, window in ipairs(activeWindows) do
			local frame = window.MainFrame
			if isMenuVisible then
				frame.Visible = true
				frame.Transparency = 1
				TweenService:Create(frame, tweenInfo, {BackgroundTransparency = 0}):Play()
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
		
		-- Si on ferme, on désactive complètement le ScreenGui après le fade out
		if not isMenuVisible then
			task.delay(0.3, function()
				if not isMenuVisible then
					screenGui.Enabled = false
				end
			end)
		end
	end
end

-- Écouteur global pour la combinaison de touches Alt + F1
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	local isAltPressed = UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt)
	if input.KeyCode == Enum.KeyCode.F1 and isAltPressed then
		toggleModMenu()
	end
end)

return WindowManager
