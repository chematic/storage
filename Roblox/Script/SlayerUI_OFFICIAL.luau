local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- ARCHITECTURE & MANAGERS
-- ==========================================
local Library = {
	Version = "2.0.0",
	Windows = {},
}

-- Connection Manager (Fixes memory leaks & duplicate events)
local ConnectionManager = {
	Connections = {}
}
function ConnectionManager:Add(conn)
	table.insert(self.Connections, conn)
	return conn
end
function ConnectionManager:Clean()
	for _, conn in ipairs(self.Connections) do
		if typeof(conn) == "RBXScriptConnection" and conn.Connected then
			conn:Disconnect()
		end
	end
	table.clear(self.Connections)
end

-- Theme Manager (Fixes broken theme application)
local ThemeManager = {
	Current = "Dark",
	Objects = {},
	Themes = {
		Dark = {
			Primary = Color3.fromRGB(30, 144, 255),
			Secondary = Color3.fromRGB(15, 15, 15),
			Background = Color3.fromRGB(20, 20, 20),
			Surface = Color3.fromRGB(25, 25, 25),
			Text = Color3.fromRGB(255, 255, 255),
			TextSecondary = Color3.fromRGB(180, 180, 180),
			Accent = Color3.fromRGB(100, 200, 255),
		},
		Light = {
			Primary = Color3.fromRGB(0, 120, 215),
			Secondary = Color3.fromRGB(240, 240, 240),
			Background = Color3.fromRGB(250, 250, 250),
			Surface = Color3.fromRGB(255, 255, 255),
			Text = Color3.fromRGB(30, 30, 30),
			TextSecondary = Color3.fromRGB(100, 100, 100),
			Accent = Color3.fromRGB(50, 150, 255),
		},
		Blue = {
			Primary = Color3.fromRGB(0, 170, 255),
			Secondary = Color3.fromRGB(10, 20, 35),
			Background = Color3.fromRGB(15, 25, 45),
			Surface = Color3.fromRGB(20, 35, 60),
			Text = Color3.fromRGB(255, 255, 255),
			TextSecondary = Color3.fromRGB(170, 200, 230),
			Accent = Color3.fromRGB(100, 200, 255),
		},
		Purple = {
			Primary = Color3.fromRGB(140, 60, 255),
			Secondary = Color3.fromRGB(20, 10, 30),
			Background = Color3.fromRGB(25, 15, 35),
			Surface = Color3.fromRGB(35, 20, 50),
			Text = Color3.fromRGB(255, 255, 255),
			TextSecondary = Color3.fromRGB(200, 170, 230),
			Accent = Color3.fromRGB(180, 120, 255),
		},
		Red = {
			Primary = Color3.fromRGB(255, 60, 60),
			Secondary = Color3.fromRGB(30, 10, 10),
			Background = Color3.fromRGB(35, 15, 15),
			Surface = Color3.fromRGB(50, 20, 20),
			Text = Color3.fromRGB(255, 255, 255),
			TextSecondary = Color3.fromRGB(230, 170, 170),
			Accent = Color3.fromRGB(255, 120, 120),
		}
	}
}

function ThemeManager:Register(instance, property, role)
	table.insert(self.Objects, { Instance = instance, Property = property, Role = role })
	instance[property] = self.Themes[self.Current][role]
end

function ThemeManager:Apply(themeName)
	if not self.Themes[themeName] then return end
	self.Current = themeName
	local theme = self.Themes[themeName]

	for i = #self.Objects, 1, -1 do
		local obj = self.Objects[i]
		if obj.Instance and obj.Instance.Parent then
			TweenService:Create(obj.Instance, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { [obj.Property] = theme[obj.Role] }):Play()
		else
			table.remove(self.Objects, i) -- Clean up destroyed instances
		end
	end
end

-- Animation Manager (Smooth natural curves)
local AnimationManager = {
	Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	Smooth = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	Bounce = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
}

-- Icons
local ICONS = {
	Close = "rbxassetid://82404346839314",
	Minimize = "rbxassetid://85022922514331",
	Settings = "rbxassetid://7059346373",
	Default = "rbxassetid://136443043095009"
}

-- ==========================================
-- UTILITIES
-- ==========================================
local function CreateCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function GetViewportSize()
	local camera = Workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1920, 1080)
end

-- ==========================================
-- CORE LIBRARY
-- ==========================================
function Library:CreateWindow(config)
	config = config or {}
	local TitleText = config.Title or "Modern UI Framework"
	local InitialSize = config.Size or UDim2.new(0, 600, 0, 400)
	
	local Window = {
		Tabs = {},
		ActiveTab = nil,
		IsMinimized = false
	}

	-- Setup GUI
	local guiName = LocalPlayer.UserId .. "_ModernUI"
	local existingGui = CoreGui:FindFirstChild(guiName)
	if existingGui then
		existingGui:Destroy()
		ConnectionManager:Clean()
	end

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = guiName
	ScreenGui.Parent = CoreGui
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Main Frame
	local Main = Instance.new("Frame")
	Main.Name = "Main"
	Main.Parent = ScreenGui
	Main.Position = UDim2.new(0.5, -InitialSize.X.Offset/2, 0.5, -InitialSize.Y.Offset/2)
	Main.Size = InitialSize
	Main.BorderSizePixel = 0
	Main.ClipsDescendants = true
	CreateCorner(Main, 14)
	ThemeManager:Register(Main, "BackgroundColor3", "Background")

	local MainStroke = Instance.new("UIStroke")
	MainStroke.Thickness = 1
	MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	MainStroke.Transparency = 0.5
	MainStroke.Parent = Main
	ThemeManager:Register(MainStroke, "Color", "Surface")

	-- Topbar
	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.Parent = Main
	TopBar.Size = UDim2.new(1, 0, 0, 40)
	TopBar.BorderSizePixel = 0
	CreateCorner(TopBar, 14)
	
	-- Fix bottom corners for Topbar so it blends with Main
	local TopBarPatch = Instance.new("Frame")
	TopBarPatch.Name = "Patch"
	TopBarPatch.Parent = TopBar
	TopBarPatch.Size = UDim2.new(1, 0, 0, 10)
	TopBarPatch.Position = UDim2.new(0, 0, 1, -10)
	TopBarPatch.BorderSizePixel = 0
	ThemeManager:Register(TopBar, "BackgroundColor3", "Secondary")
	ThemeManager:Register(TopBarPatch, "BackgroundColor3", "Secondary")

	local Title = Instance.new("TextLabel")
	Title.Parent = TopBar
	Title.Text = "   " .. TitleText
	Title.Size = UDim2.new(1, -100, 1, 0)
	Title.BackgroundTransparency = 1
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 14
	Title.TextXAlignment = Enum.TextXAlignment.Left
	ThemeManager:Register(Title, "TextColor3", "Text")

	-- Window Controls
	local ControlContainer = Instance.new("Frame")
	ControlContainer.Parent = TopBar
	ControlContainer.BackgroundTransparency = 1
	ControlContainer.Size = UDim2.new(0, 80, 1, 0)
	ControlContainer.Position = UDim2.new(1, -80, 0, 0)

	local Layout = Instance.new("UIListLayout")
	Layout.Parent = ControlContainer
	Layout.FillDirection = Enum.FillDirection.Horizontal
	Layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	Layout.VerticalAlignment = Enum.VerticalAlignment.Center
	Layout.Padding = UDim.new(0, 5)

	-- Minimize Button (Fixes minimize bug)
	local MinBtn = Instance.new("ImageButton")
	MinBtn.Parent = ControlContainer
	MinBtn.Size = UDim2.new(0, 30, 0, 30)
	MinBtn.BackgroundTransparency = 1
	MinBtn.Image = ICONS.Minimize
	ThemeManager:Register(MinBtn, "ImageColor3", "TextSecondary")

	-- Close Button
	local CloseBtn = Instance.new("ImageButton")
	CloseBtn.Parent = ControlContainer
	CloseBtn.Size = UDim2.new(0, 30, 0, 30)
	CloseBtn.BackgroundTransparency = 1
	CloseBtn.Image = ICONS.Close
	CloseBtn.ImageColor3 = Color3.fromRGB(240, 70, 70)

	-- Tab Container & Pages Container
	local ContentContainer = Instance.new("Frame")
	ContentContainer.Name = "Content"
	ContentContainer.Parent = Main
	ContentContainer.BackgroundTransparency = 1
	ContentContainer.Position = UDim2.new(0, 0, 0, 40)
	ContentContainer.Size = UDim2.new(1, 0, 1, -40)

	local TabBar = Instance.new("ScrollingFrame")
	TabBar.Name = "TabBar"
	TabBar.Parent = ContentContainer
	TabBar.Position = UDim2.new(0, 0, 0, 0)
	TabBar.Size = UDim2.new(0, 160, 1, 0)
	TabBar.BorderSizePixel = 0
	TabBar.ScrollBarThickness = 0
	TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
	ThemeManager:Register(TabBar, "BackgroundColor3", "Surface")

	local TabList = Instance.new("UIListLayout")
	TabList.Parent = TabBar
	TabList.Padding = UDim.new(0, 4)
	TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	
	local TabPadding = Instance.new("UIPadding")
	TabPadding.Parent = TabBar
	TabPadding.PaddingTop = UDim.new(0, 8)
	TabPadding.PaddingBottom = UDim.new(0, 8)

	TabList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		TabBar.CanvasSize = UDim2.new(0, 0, 0, TabList.AbsoluteContentSize.Y + 16)
	end)

	local Pages = Instance.new("Frame")
	Pages.Name = "Pages"
	Pages.Parent = ContentContainer
	Pages.BackgroundTransparency = 1
	Pages.Position = UDim2.new(0, 160, 0, 0)
	Pages.Size = UDim2.new(1, -160, 1, 0)
	Pages.ClipsDescendants = true

	-- ==========================================
	-- SYSTEMS IMPLEMENTATION (Drag, Resize, Min)
	-- ==========================================
	
	-- Drag System (Fixes memory leaks & lag)
	local function MakeDraggable(topbar, window)
		local dragging, dragInput, mousePos, framePos
		
		ConnectionManager:Add(topbar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				mousePos = input.Position
				framePos = window.Position
				
				local endConn
				endConn = ConnectionManager:Add(input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
						if endConn then endConn:Disconnect() end
					end
				end))
			end
		end))
		
		ConnectionManager:Add(topbar.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end))
		
		ConnectionManager:Add(RunService.RenderStepped:Connect(function()
			if dragging and dragInput then
				local delta = dragInput.Position - mousePos
				local targetPos = UDim2.new(
					framePos.X.Scale, 
					framePos.X.Offset + delta.X, 
					framePos.Y.Scale, 
					framePos.Y.Offset + delta.Y
				)
				window.Position = window.Position:Lerp(targetPos, 0.4)
			end
		end))
	end
	MakeDraggable(TopBar, Main)

	-- Resize System (Fixes broken corners, fully supports 8 directions)
	local function ImplementResize()
		local resizeThickness = 8
		local minSize = Vector2.new(400, 300)
		local zones = {
			Top = {Size = UDim2.new(1, -resizeThickness*2, 0, resizeThickness), Pos = UDim2.new(0, resizeThickness, 0, 0), Cursor = "SizeNS"},
			Bottom = {Size = UDim2.new(1, -resizeThickness*2, 0, resizeThickness), Pos = UDim2.new(0, resizeThickness, 1, -resizeThickness), Cursor = "SizeNS"},
			Left = {Size = UDim2.new(0, resizeThickness, 1, -resizeThickness*2), Pos = UDim2.new(0, 0, 0, resizeThickness), Cursor = "SizeEW"},
			Right = {Size = UDim2.new(0, resizeThickness, 1, -resizeThickness*2), Pos = UDim2.new(1, -resizeThickness, 0, resizeThickness), Cursor = "SizeEW"},
			TopLeft = {Size = UDim2.new(0, resizeThickness, 0, resizeThickness), Pos = UDim2.new(0, 0, 0, 0), Cursor = "SizeNWSE"},
			TopRight = {Size = UDim2.new(0, resizeThickness, 0, resizeThickness), Pos = UDim2.new(1, -resizeThickness, 0, 0), Cursor = "SizeNESW"},
			BottomLeft = {Size = UDim2.new(0, resizeThickness, 0, resizeThickness), Pos = UDim2.new(0, 0, 1, -resizeThickness), Cursor = "SizeNESW"},
			BottomRight = {Size = UDim2.new(0, resizeThickness, 0, resizeThickness), Pos = UDim2.new(1, -resizeThickness, 1, -resizeThickness), Cursor = "SizeNWSE"}
		}

		for dir, config in pairs(zones) do
			local handle = Instance.new("TextButton")
			handle.Name = "Resize_" .. dir
			handle.Parent = Main
			handle.BackgroundTransparency = 1
			handle.Text = ""
			handle.Size = config.Size
			handle.Position = config.Pos
			handle.ZIndex = 100

			local resizing = false
			local startMouse, startSize, startPos

			ConnectionManager:Add(handle.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					resizing = true
					startMouse = UserInputService:GetMouseLocation()
					startSize = Main.AbsoluteSize
					startPos = Main.AbsolutePosition

					local endConn
					endConn = ConnectionManager:Add(input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then
							resizing = false
							if endConn then endConn:Disconnect() end
						end
					end))
				end
			end))

			ConnectionManager:Add(RunService.RenderStepped:Connect(function()
				if resizing then
					local currentMouse = UserInputService:GetMouseLocation()
					local delta = currentMouse - startMouse
					local newWidth = startSize.X
					local newHeight = startSize.Y
					local newX = startPos.X
					local newY = startPos.Y

					if dir:find("Right") then newWidth = math.max(minSize.X, startSize.X + delta.X) end
					if dir:find("Bottom") then newHeight = math.max(minSize.Y, startSize.Y + delta.Y) end
					if dir:find("Left") then
						newWidth = math.max(minSize.X, startSize.X - delta.X)
						if newWidth > minSize.X then newX = startPos.X + delta.X end
					end
					if dir:find("Top") then
						newHeight = math.max(minSize.Y, startSize.Y - delta.Y)
						if newHeight > minSize.Y then newY = startPos.Y + delta.Y end
					end

					Main.Size = UDim2.new(0, newWidth, 0, newHeight)
					Main.Position = UDim2.new(0, newX, 0, newY)
				end
			end))
		end
	end
	ImplementResize()

	-- Minimize Functionality (Fixes bad minimize state)
	local preMinSize = Main.Size
	local preMinPos = Main.Position
	ConnectionManager:Add(MinBtn.MouseButton1Click:Connect(function()
		Window.IsMinimized = not Window.IsMinimized
		if Window.IsMinimized then
			preMinSize = Main.Size
			preMinPos = Main.Position
			ContentContainer.Visible = false
			TweenService:Create(Main, AnimationManager.Smooth, {Size = UDim2.new(0, 250, 0, 40)}):Play()
		else
			local tw = TweenService:Create(Main, AnimationManager.Smooth, {Size = preMinSize, Position = preMinPos})
			tw:Play()
			tw.Completed:Connect(function()
				if not Window.IsMinimized then ContentContainer.Visible = true end
			end)
		end
	end))

	-- Close Functionality
	ConnectionManager:Add(CloseBtn.MouseButton1Click:Connect(function()
		Window:Destroy()
	end))

	-- ==========================================
	-- TAB SYSTEM (Fixes position bugs & modernizes)
	-- ==========================================
	function Window:CreateTab(name, icon)
		local Tab = { Elements = {} }
		
		-- Create Scroll Page
		local Page = Instance.new("ScrollingFrame")
		Page.Name = name .. "Page"
		Page.Parent = Pages
		Page.BackgroundTransparency = 1
		Page.Size = UDim2.new(1, 0, 1, 0)
		Page.Position = UDim2.new(1, 0, 0, 0) -- Starts hidden on right
		Page.Visible = false
		Page.ScrollBarThickness = 2
		Page.BorderSizePixel = 0
		ThemeManager:Register(Page, "ScrollBarImageColor3", "Primary")

		local PageLayout = Instance.new("UIListLayout")
		PageLayout.Parent = Page
		PageLayout.Padding = UDim.new(0, 8)
		PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		
		local PagePadding = Instance.new("UIPadding")
		PagePadding.Parent = Page
		PagePadding.PaddingTop = UDim.new(0, 10)
		PagePadding.PaddingBottom = UDim.new(0, 10)
		PagePadding.PaddingLeft = UDim.new(0, 5)
		PagePadding.PaddingRight = UDim.new(0, 5)

		ConnectionManager:Add(PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20)
		end))

		-- Create Tab Button
		local TabBtn = Instance.new("TextButton")
		TabBtn.Parent = TabBar
		TabBtn.Size = UDim2.new(1, -16, 0, 36)
		TabBtn.Text = ""
		TabBtn.AutoButtonColor = false
		CreateCorner(TabBtn, 8)
		ThemeManager:Register(TabBtn, "BackgroundColor3", "Surface")

		local Indicator = Instance.new("Frame")
		Indicator.Parent = TabBtn
		Indicator.Size = UDim2.new(0, 3, 0, 0)
		Indicator.Position = UDim2.new(0, 6, 0.5, 0)
		Indicator.AnchorPoint = Vector2.new(0, 0.5)
		CreateCorner(Indicator, 2)
		ThemeManager:Register(Indicator, "BackgroundColor3", "Primary")

		local IconLabel = Instance.new("ImageLabel")
		IconLabel.Parent = TabBtn
		IconLabel.Size = UDim2.new(0, 20, 0, 20)
		IconLabel.Position = UDim2.new(0, 16, 0.5, -10)
		IconLabel.BackgroundTransparency = 1
		IconLabel.Image = icon or ICONS.Default
		ThemeManager:Register(IconLabel, "ImageColor3", "TextSecondary")

		local TextLabel = Instance.new("TextLabel")
		TextLabel.Parent = TabBtn
		TextLabel.Position = UDim2.new(0, 44, 0, 0)
		TextLabel.Size = UDim2.new(1, -44, 1, 0)
		TextLabel.BackgroundTransparency = 1
		TextLabel.Text = name
		TextLabel.Font = Enum.Font.GothamBold
		TextLabel.TextSize = 13
		TextLabel.TextXAlignment = Enum.TextXAlignment.Left
		ThemeManager:Register(TextLabel, "TextColor3", "TextSecondary")

		-- Tab Activation Logic (Fixes tab jumping)
		local function ActivateTab()
			if Window.ActiveTab == Tab then return end
			
			if Window.ActiveTab then
				-- Deactivate old tab
				local OldBtn = Window.ActiveTab.Btn
				local OldPage = Window.ActiveTab.Page
				TweenService:Create(OldBtn.Indicator, AnimationManager.Fast, {Size = UDim2.new(0, 3, 0, 0)}):Play()
				TweenService:Create(OldBtn.IconLabel, AnimationManager.Fast, {ImageColor3 = ThemeManager.Themes[ThemeManager.Current].TextSecondary}):Play()
				TweenService:Create(OldBtn.TextLabel, AnimationManager.Fast, {TextColor3 = ThemeManager.Themes[ThemeManager.Current].TextSecondary}):Play()
				
				TweenService:Create(OldPage, AnimationManager.Smooth, {Position = UDim2.new(-1, 0, 0, 0)}):Play()
				task.delay(0.3, function() OldPage.Visible = false end)
			end

			Window.ActiveTab = Tab
			
			-- Activate new tab
			TweenService:Create(Indicator, AnimationManager.Bounce, {Size = UDim2.new(0, 3, 0, 20)}):Play()
			TweenService:Create(IconLabel, AnimationManager.Fast, {ImageColor3 = ThemeManager.Themes[ThemeManager.Current].Primary}):Play()
			TweenService:Create(TextLabel, AnimationManager.Fast, {TextColor3 = ThemeManager.Themes[ThemeManager.Current].Text}):Play()
			
			Page.Position = UDim2.new(1, 0, 0, 0) -- Force position to right before animating in
			Page.Visible = true
			TweenService:Create(Page, AnimationManager.Smooth, {Position = UDim2.new(0, 0, 0, 0)}):Play()
		end

		ConnectionManager:Add(TabBtn.MouseButton1Click:Connect(ActivateTab))
		Tab.Btn = {Indicator = Indicator, IconLabel = IconLabel, TextLabel = TextLabel}
		Tab.Page = Page

		if not Window.ActiveTab then ActivateTab() end

		-- ==========================================
		-- UI ELEMENTS
		-- ==========================================
		function Tab:CreateLabel(text)
			local LabelFrame = Instance.new("Frame")
			LabelFrame.Size = UDim2.new(1, -10, 0, 25)
			LabelFrame.BackgroundTransparency = 1
			LabelFrame.Parent = Page

			local Label = Instance.new("TextLabel")
			Label.Parent = LabelFrame
			Label.Size = UDim2.new(1, 0, 1, 0)
			Label.BackgroundTransparency = 1
			Label.Text = text
			Label.Font = Enum.Font.GothamBold
			Label.TextSize = 13
			Label.TextXAlignment = Enum.TextXAlignment.Left
			ThemeManager:Register(Label, "TextColor3", "TextSecondary")
		end

		function Tab:CreateButton(config)
			local Btn = Instance.new("TextButton")
			Btn.Parent = Page
			Btn.Size = UDim2.new(1, -10, 0, 42)
			Btn.Text = config.Name or "Button"
			Btn.Font = Enum.Font.GothamBold
			Btn.TextSize = 13
			Btn.AutoButtonColor = false
			CreateCorner(Btn, 8)
			ThemeManager:Register(Btn, "BackgroundColor3", "Surface")
			ThemeManager:Register(Btn, "TextColor3", "Text")

			local UIStroke = Instance.new("UIStroke")
			UIStroke.Parent = Btn
			UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			UIStroke.Thickness = 1
			UIStroke.Transparency = 0.8
			ThemeManager:Register(UIStroke, "Color", "TextSecondary")

			ConnectionManager:Add(Btn.MouseEnter:Connect(function()
				TweenService:Create(Btn, AnimationManager.Fast, {BackgroundColor3 = ThemeManager.Themes[ThemeManager.Current].Secondary}):Play()
				TweenService:Create(UIStroke, AnimationManager.Fast, {Transparency = 0.5}):Play()
			end))

			ConnectionManager:Add(Btn.MouseLeave:Connect(function()
				TweenService:Create(Btn, AnimationManager.Fast, {BackgroundColor3 = ThemeManager.Themes[ThemeManager.Current].Surface}):Play()
				TweenService:Create(UIStroke, AnimationManager.Fast, {Transparency = 0.8}):Play()
			end))

			ConnectionManager:Add(Btn.MouseButton1Down:Connect(function()
				TweenService:Create(Btn, AnimationManager.Fast, {Size = UDim2.new(1, -14, 0, 38)}):Play()
			end))

			ConnectionManager:Add(Btn.MouseButton1Up:Connect(function()
				TweenService:Create(Btn, AnimationManager.Fast, {Size = UDim2.new(1, -10, 0, 42)}):Play()
				if config.Callback then task.spawn(config.Callback) end
			end))
		end

		function Tab:CreateToggle(config)
			local ToggleFrame = Instance.new("TextButton")
			ToggleFrame.Parent = Page
			ToggleFrame.Size = UDim2.new(1, -10, 0, 42)
			ToggleFrame.Text = ""
			ToggleFrame.AutoButtonColor = false
			CreateCorner(ToggleFrame, 8)
			ThemeManager:Register(ToggleFrame, "BackgroundColor3", "Surface")

			local Title = Instance.new("TextLabel")
			Title.Parent = ToggleFrame
			Title.Position = UDim2.new(0, 15, 0, 0)
			Title.Size = UDim2.new(1, -70, 1, 0)
			Title.BackgroundTransparency = 1
			Title.Text = config.Name or "Toggle"
			Title.Font = Enum.Font.GothamBold
			Title.TextSize = 13
			Title.TextXAlignment = Enum.TextXAlignment.Left
			ThemeManager:Register(Title, "TextColor3", "Text")

			local SwitchBack = Instance.new("Frame")
			SwitchBack.Parent = ToggleFrame
			SwitchBack.Size = UDim2.new(0, 40, 0, 20)
			SwitchBack.Position = UDim2.new(1, -55, 0.5, -10)
			CreateCorner(SwitchBack, 10)
			ThemeManager:Register(SwitchBack, "BackgroundColor3", "Secondary")

			local SwitchCircle = Instance.new("Frame")
			SwitchCircle.Parent = SwitchBack
			SwitchCircle.Size = UDim2.new(0, 16, 0, 16)
			SwitchCircle.Position = UDim2.new(0, 2, 0.5, -8)
			CreateCorner(SwitchCircle, 8)
			ThemeManager:Register(SwitchCircle, "BackgroundColor3", "TextSecondary")

			local enabled = config.Default or false

			local function UpdateState(anim)
				local targetX = enabled and 22 or 2
				local info = anim and AnimationManager.Bounce or TweenInfo.new(0)
				
				TweenService:Create(SwitchCircle, info, {Position = UDim2.new(0, targetX, 0.5, -8)}):Play()
				
				if enabled then
					ThemeManager:Register(SwitchBack, "BackgroundColor3", "Primary")
					ThemeManager:Register(SwitchCircle, "BackgroundColor3", "Text")
				else
					ThemeManager:Register(SwitchBack, "BackgroundColor3", "Secondary")
					ThemeManager:Register(SwitchCircle, "BackgroundColor3", "TextSecondary")
				end
				-- Reapply theme to immediately force color switch logic
				ThemeManager:Apply(ThemeManager.Current)
			end
			UpdateState(false)

			ConnectionManager:Add(ToggleFrame.MouseButton1Click:Connect(function()
				enabled = not enabled
				UpdateState(true)
				if config.Callback then task.spawn(config.Callback, enabled) end
			end))
			
			return {
				Set = function(val)
					enabled = val
					UpdateState(true)
				end
			}
		end

		function Tab:CreateSlider(config)
			local SliderFrame = Instance.new("Frame")
			SliderFrame.Parent = Page
			SliderFrame.Size = UDim2.new(1, -10, 0, 56)
			CreateCorner(SliderFrame, 8)
			ThemeManager:Register(SliderFrame, "BackgroundColor3", "Surface")

			local Title = Instance.new("TextLabel")
			Title.Parent = SliderFrame
			Title.Position = UDim2.new(0, 15, 0, 5)
			Title.Size = UDim2.new(1, -30, 0, 20)
			Title.BackgroundTransparency = 1
			Title.Text = config.Name or "Slider"
			Title.Font = Enum.Font.GothamBold
			Title.TextSize = 13
			Title.TextXAlignment = Enum.TextXAlignment.Left
			ThemeManager:Register(Title, "TextColor3", "Text")

			local ValueText = Instance.new("TextLabel")
			ValueText.Parent = SliderFrame
			ValueText.Position = UDim2.new(1, -65, 0, 5)
			ValueText.Size = UDim2.new(0, 50, 0, 20)
			ValueText.BackgroundTransparency = 1
			ValueText.Text = tostring(config.Default or config.Min)
			ValueText.Font = Enum.Font.GothamBold
			ValueText.TextSize = 13
			ValueText.TextXAlignment = Enum.TextXAlignment.Right
			ThemeManager:Register(ValueText, "TextColor3", "Primary")

			local SliderBack = Instance.new("TextButton")
			SliderBack.Parent = SliderFrame
			SliderBack.Size = UDim2.new(1, -30, 0, 6)
			SliderBack.Position = UDim2.new(0, 15, 0, 36)
			SliderBack.Text = ""
			SliderBack.AutoButtonColor = false
			CreateCorner(SliderBack, 3)
			ThemeManager:Register(SliderBack, "BackgroundColor3", "Secondary")

			local SliderFill = Instance.new("Frame")
			SliderFill.Parent = SliderBack
			SliderFill.Size = UDim2.new(0, 0, 1, 0)
			CreateCorner(SliderFill, 3)
			ThemeManager:Register(SliderFill, "BackgroundColor3", "Primary")

			local SliderKnob = Instance.new("Frame")
			SliderKnob.Parent = SliderFill
			SliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
			SliderKnob.Position = UDim2.new(1, 0, 0.5, 0)
			SliderKnob.Size = UDim2.new(0, 14, 0, 14)
			CreateCorner(SliderKnob, 7)
			ThemeManager:Register(SliderKnob, "BackgroundColor3", "Text")

			-- UI Stroke for Knob
			local KnobStroke = Instance.new("UIStroke")
			KnobStroke.Parent = SliderKnob
			KnobStroke.Thickness = 2
			ThemeManager:Register(KnobStroke, "Color", "Primary")

			-- Slider Logic (Fixes all cross-slider interference and mobile bugs)
			local min = config.Min or 0
			local max = config.Max or 100
			local default = config.Default or min
			local sliding = false
			local activeTween = nil

			local function UpdateSlider(input, animate)
				local x = input and input.Position.X or UserInputService:GetMouseLocation().X
				local relativeX = math.clamp(x - SliderBack.AbsolutePosition.X, 0, SliderBack.AbsoluteSize.X)
				local percent = relativeX / SliderBack.AbsoluteSize.X
				local value = math.floor(min + ((max - min) * percent))
				
				ValueText.Text = tostring(value)
				
				if activeTween then activeTween:Cancel() end
				if animate then
					activeTween = TweenService:Create(SliderFill, AnimationManager.Fast, {Size = UDim2.new(percent, 0, 1, 0)})
					activeTween:Play()
				else
					SliderFill.Size = UDim2.new(percent, 0, 1, 0)
				end

				if config.Callback then task.spawn(config.Callback, value) end
			end

			-- Initial set
			local initPercent = (default - min) / (max - min)
			SliderFill.Size = UDim2.new(initPercent, 0, 1, 0)

			ConnectionManager:Add(SliderBack.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					sliding = true
					TweenService:Create(SliderKnob, AnimationManager.Fast, {Size = UDim2.new(0, 18, 0, 18)}):Play()
					UpdateSlider(input, true)
				end
			end))

			ConnectionManager:Add(UserInputService.InputChanged:Connect(function(input)
				if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					UpdateSlider(input, false)
				end
			end))

			ConnectionManager:Add(UserInputService.InputEnded:Connect(function(input)
				if sliding and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
					sliding = false
					TweenService:Create(SliderKnob, AnimationManager.Fast, {Size = UDim2.new(0, 14, 0, 14)}):Play()
				end
			end))
		end

		function Tab:CreateDropdown(config)
			local DropdownFrame = Instance.new("Frame")
			DropdownFrame.Parent = Page
			DropdownFrame.Size = UDim2.new(1, -10, 0, 42)
			DropdownFrame.ClipsDescendants = true
			CreateCorner(DropdownFrame, 8)
			ThemeManager:Register(DropdownFrame, "BackgroundColor3", "Surface")

			local MainBtn = Instance.new("TextButton")
			MainBtn.Parent = DropdownFrame
			MainBtn.Size = UDim2.new(1, 0, 0, 42)
			MainBtn.Text = ""
			MainBtn.BackgroundTransparency = 1

			local Title = Instance.new("TextLabel")
			Title.Parent = MainBtn
			Title.Position = UDim2.new(0, 15, 0, 0)
			Title.Size = UDim2.new(1, -40, 1, 0)
			Title.BackgroundTransparency = 1
			Title.Text = config.Name .. " : " .. (config.Default or "None")
			Title.Font = Enum.Font.GothamBold
			Title.TextSize = 13
			Title.TextXAlignment = Enum.TextXAlignment.Left
			ThemeManager:Register(Title, "TextColor3", "Text")

			local Icon = Instance.new("ImageLabel")
			Icon.Parent = MainBtn
			Icon.Size = UDim2.new(0, 20, 0, 20)
			Icon.Position = UDim2.new(1, -30, 0.5, -10)
			Icon.BackgroundTransparency = 1
			Icon.Image = "rbxassetid://6031090401" -- Down Arrow
			ThemeManager:Register(Icon, "ImageColor3", "TextSecondary")

			-- Fix: Dropdown List uses ScrollingFrame to prevent overflow
			local ListContainer = Instance.new("ScrollingFrame")
			ListContainer.Parent = DropdownFrame
			ListContainer.Position = UDim2.new(0, 0, 0, 42)
			ListContainer.Size = UDim2.new(1, 0, 1, -42)
			ListContainer.BackgroundTransparency = 1
			ListContainer.ScrollBarThickness = 2
			ListContainer.BorderSizePixel = 0
			ThemeManager:Register(ListContainer, "ScrollBarImageColor3", "Primary")

			local ListLayout = Instance.new("UIListLayout")
			ListLayout.Parent = ListContainer
			ListLayout.Padding = UDim.new(0, 2)
			
			local ListPadding = Instance.new("UIPadding")
			ListPadding.Parent = ListContainer
			ListPadding.PaddingTop = UDim.new(0, 5)
			ListPadding.PaddingBottom = UDim.new(0, 5)
			ListPadding.PaddingLeft = UDim.new(0, 5)
			ListPadding.PaddingRight = UDim.new(0, 5)

			local isOpen = false
			local itemHeight = 32
			local maxVisibleItems = 4

			local function ToggleDropdown()
				isOpen = not isOpen
				local targetHeight = 42
				
				if isOpen then
					local itemsToCount = math.min(#config.Items, maxVisibleItems)
					targetHeight = 42 + (itemsToCount * itemHeight) + 10
					TweenService:Create(Icon, AnimationManager.Fast, {Rotation = 180}):Play()
				else
					TweenService:Create(Icon, AnimationManager.Fast, {Rotation = 0}):Play()
				end
				
				TweenService:Create(DropdownFrame, AnimationManager.Smooth, {Size = UDim2.new(1, -10, 0, targetHeight)}):Play()
				ListContainer.CanvasSize = UDim2.new(0, 0, 0, (#config.Items * itemHeight) + 10)
			end

			ConnectionManager:Add(MainBtn.MouseButton1Click:Connect(ToggleDropdown))

			-- Build Items
			for _, item in ipairs(config.Items) do
				local ItemBtn = Instance.new("TextButton")
				ItemBtn.Parent = ListContainer
				ItemBtn.Size = UDim2.new(1, 0, 0, itemHeight)
				ItemBtn.Text = "  " .. tostring(item)
				ItemBtn.Font = Enum.Font.Gotham
				ItemBtn.TextSize = 13
				ItemBtn.TextXAlignment = Enum.TextXAlignment.Left
				ItemBtn.AutoButtonColor = false
				CreateCorner(ItemBtn, 6)
				ThemeManager:Register(ItemBtn, "BackgroundColor3", "Secondary")
				ThemeManager:Register(ItemBtn, "TextColor3", "TextSecondary")

				ConnectionManager:Add(ItemBtn.MouseEnter:Connect(function()
					TweenService:Create(ItemBtn, AnimationManager.Fast, {BackgroundColor3 = ThemeManager.Themes[ThemeManager.Current].Primary}):Play()
					TweenService:Create(ItemBtn, AnimationManager.Fast, {TextColor3 = Color3.fromRGB(255,255,255)}):Play()
				end))

				ConnectionManager:Add(ItemBtn.MouseLeave:Connect(function()
					TweenService:Create(ItemBtn, AnimationManager.Fast, {BackgroundColor3 = ThemeManager.Themes[ThemeManager.Current].Secondary}):Play()
					TweenService:Create(ItemBtn, AnimationManager.Fast, {TextColor3 = ThemeManager.Themes[ThemeManager.Current].TextSecondary}):Play()
				end))

				ConnectionManager:Add(ItemBtn.MouseButton1Click:Connect(function()
					Title.Text = config.Name .. " : " .. tostring(item)
					ToggleDropdown()
					if config.Callback then task.spawn(config.Callback, item) end
				end))
			end
		end

		return Tab
	end

	-- Destructor / Cleanup (Fixes massive memory leaks from the original script)
	function Window:Destroy()
		ConnectionManager:Clean()
		ScreenGui:Destroy()
	end

	-- ==========================================
	-- DEFAULT TABS (Settings & Theme Setup)
	-- ==========================================
	local SettingsTab = Window:CreateTab("Settings", ICONS.Settings)
	
	SettingsTab:CreateLabel("THEME PRESETS")
	
	-- Theme selection mapping correctly updates existing objects
	SettingsTab:CreateDropdown({
		Name = "Select Theme",
		Items = {"Dark", "Light", "Blue", "Purple", "Red"},
		Default = "Dark",
		Callback = function(themeName)
			ThemeManager:Apply(themeName)
		end
	})

	return Window
end

return Library
