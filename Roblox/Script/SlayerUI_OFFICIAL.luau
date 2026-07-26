local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- CONFIGURATION & THEME
-- ==========================================
local Theme = {
	Background = Color3.fromRGB(20, 20, 22),
	Container = Color3.fromRGB(28, 28, 32),
	Element = Color3.fromRGB(35, 35, 40),
	ElementHover = Color3.fromRGB(45, 45, 52),
	Accent = Color3.fromRGB(85, 170, 255),
	Text = Color3.fromRGB(255, 255, 255),
	TextDark = Color3.fromRGB(150, 150, 150),
	Outline = Color3.fromRGB(40, 40, 45)
}

local Font = Enum.Font.GothamMedium
local FontBold = Enum.Font.GothamBold

-- ==========================================
-- UTILITAIRES
-- ==========================================
local Utility = {
	Connections = {}
}

function Utility:Connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(self.Connections, connection)
	return connection
end

function Utility:Clean()
	for _, conn in ipairs(self.Connections) do
		if conn.Connected then conn:Disconnect() end
	end
	table.clear(self.Connections)
end

function Utility:Create(className, properties)
	local inst = Instance.new(className)
	for k, v in pairs(properties) do
		inst[k] = v
	end
	return inst
end

function Utility:Tween(instance, properties, duration)
	local tween = TweenService:Create(instance, TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), properties)
	tween:Play()
	return tween
end

-- ==========================================
-- FRAMEWORK CORE
-- ==========================================
local Library = {}

function Library:CreateWindow(titleText)
	local guiName = "ZenithUI_" .. LocalPlayer.UserId
	
	-- Nettoyage de l'ancienne instance
	local oldGui = CoreGui:FindFirstChild(guiName)
	if oldGui then 
		oldGui:Destroy() 
		Utility:Clean()
	end

	local ScreenGui = Utility:Create("ScreenGui", {
		Name = guiName,
		Parent = CoreGui,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true
	})

	local Main = Utility:Create("Frame", {
		Name = "Main",
		Parent = ScreenGui,
		BackgroundColor3 = Theme.Background,
		Size = UDim2.new(0, 550, 0, 350),
		Position = UDim2.new(0.5, -275, 0.5, -175),
		Active = true,
	})
	Utility:Create("UICorner", { Parent = Main, CornerRadius = UDim.new(0, 8) })
	Utility:Create("UIStroke", { Parent = Main, Color = Theme.Outline, Thickness = 1 })

	-- Topbar
	local Topbar = Utility:Create("Frame", {
		Name = "Topbar",
		Parent = Main,
		BackgroundColor3 = Theme.Container,
		Size = UDim2.new(1, 0, 0, 40),
		BorderSizePixel = 0
	})
	Utility:Create("UICorner", { Parent = Topbar, CornerRadius = UDim.new(0, 8) })
	
	-- Patch pour le bas de la topbar (coins carrés en bas)
	Utility:Create("Frame", {
		Parent = Topbar,
		BackgroundColor3 = Theme.Container,
		Size = UDim2.new(1, 0, 0, 10),
		Position = UDim2.new(0, 0, 1, -10),
		BorderSizePixel = 0
	})

	local Title = Utility:Create("TextLabel", {
		Parent = Topbar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 15, 0, 0),
		Size = UDim2.new(1, -15, 1, 0),
		Text = titleText or "Zenith Framework",
		Font = FontBold,
		TextSize = 14,
		TextColor3 = Theme.Accent,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	local CloseBtn = Utility:Create("TextButton", {
		Parent = Topbar,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -40, 0, 0),
		Size = UDim2.new(0, 40, 1, 0),
		Text = "×",
		Font = Font,
		TextSize = 20,
		TextColor3 = Theme.TextDark
	})

	Utility:Connect(CloseBtn.MouseEnter, function() Utility:Tween(CloseBtn, {TextColor3 = Color3.fromRGB(255, 50, 50)}) end)
	Utility:Connect(CloseBtn.MouseLeave, function() Utility:Tween(CloseBtn, {TextColor3 = Theme.TextDark}) end)
	Utility:Connect(CloseBtn.MouseButton1Click, function()
		Utility:Clean()
		ScreenGui:Destroy()
	end)

	-- Drag System Fluide
	local dragging, dragInput, dragStart, startPos
	Utility:Connect(Topbar.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = Main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)

	Utility:Connect(Topbar.InputChanged, function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	Utility:Connect(RunService.RenderStepped, function()
		if dragging and dragInput then
			local delta = dragInput.Position - dragStart
			Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	-- Layout des onglets et pages
	local Sidebar = Utility:Create("Frame", {
		Parent = Main,
		BackgroundColor3 = Theme.Container,
		Position = UDim2.new(0, 0, 0, 40),
		Size = UDim2.new(0, 140, 1, -40),
		BorderSizePixel = 0
	})
	Utility:Create("UICorner", { Parent = Sidebar, CornerRadius = UDim.new(0, 8) })
	
	-- Patch des coins droits de la sidebar
	Utility:Create("Frame", {
		Parent = Sidebar,
		BackgroundColor3 = Theme.Container,
		Position = UDim2.new(1, -10, 0, 0),
		Size = UDim2.new(0, 10, 1, 0),
		BorderSizePixel = 0
	})
	Utility:Create("Frame", {
		Parent = Sidebar,
		BackgroundColor3 = Theme.Container,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 10),
		BorderSizePixel = 0
	})

	local TabContainer = Utility:Create("ScrollingFrame", {
		Parent = Sidebar,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0)
	})
	local TabList = Utility:Create("UIListLayout", { Parent = TabContainer, Padding = UDim.new(0, 5), HorizontalAlignment = Enum.HorizontalAlignment.Center })
	Utility:Create("UIPadding", { Parent = TabContainer, PaddingTop = UDim.new(0, 10) })

	Utility:Connect(TabList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		TabContainer.CanvasSize = UDim2.new(0, 0, 0, TabList.AbsoluteContentSize.Y + 20)
	end)

	local PagesContainer = Utility:Create("Frame", {
		Parent = Main,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 140, 0, 40),
		Size = UDim2.new(1, -140, 1, -40),
		ClipsDescendants = true
	})

	local Window = {
		ActiveTab = nil,
		Tabs = {}
	}

	-- ==========================================
	-- GESTION DES ONGLETS
	-- ==========================================
	function Window:CreateTab(name)
		local TabBtn = Utility:Create("TextButton", {
			Parent = TabContainer,
			BackgroundColor3 = Theme.Background,
			Size = UDim2.new(1, -20, 0, 32),
			Text = name,
			Font = Font,
			TextSize = 13,
			TextColor3 = Theme.TextDark,
			AutoButtonColor = false
		})
		Utility:Create("UICorner", { Parent = TabBtn, CornerRadius = UDim.new(0, 6) })
		
		local Indicator = Utility:Create("Frame", {
			Parent = TabBtn,
			BackgroundColor3 = Theme.Accent,
			Size = UDim2.new(0, 3, 0, 0),
			Position = UDim2.new(0, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BorderSizePixel = 0
		})
		Utility:Create("UICorner", { Parent = Indicator, CornerRadius = UDim.new(0, 4) })

		local Page = Utility:Create("ScrollingFrame", {
			Parent = PagesContainer,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 10), -- Léger offset pour l'animation
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Theme.Accent,
			Visible = false
		})
		local PageList = Utility:Create("UIListLayout", { Parent = Page, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center })
		Utility:Create("UIPadding", { Parent = Page, PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) })

		Utility:Connect(PageList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
			Page.CanvasSize = UDim2.new(0, 0, 0, PageList.AbsoluteContentSize.Y + 20)
		end)

		local Tab = { Page = Page }

		Utility:Connect(TabBtn.MouseButton1Click, function()
			if Window.ActiveTab == TabBtn then return end
			
			-- Désactiver l'ancien onglet
			if Window.ActiveTab then
				Utility:Tween(Window.ActiveTab.Indicator, {Size = UDim2.new(0, 3, 0, 0)}, 0.15)
				Utility:Tween(Window.ActiveTab.Btn, {TextColor3 = Theme.TextDark, BackgroundColor3 = Theme.Background}, 0.15)
				Window.ActiveTab.Page.Visible = false
			end

			-- Activer le nouveau
			Window.ActiveTab = {Btn = TabBtn, Indicator = Indicator, Page = Page}
			Page.Visible = true
			Page.Position = UDim2.new(0, 0, 0, 10)
			Utility:Tween(Page, {Position = UDim2.new(0, 0, 0, 0)}, 0.3)
			
			Utility:Tween(Indicator, {Size = UDim2.new(0, 3, 0, 18)}, 0.2)
			Utility:Tween(TabBtn, {TextColor3 = Theme.Text, BackgroundColor3 = Theme.Element}, 0.2)
		end)

		if not Window.ActiveTab then
			TabBtn.Indicator.Size = UDim2.new(0, 3, 0, 18)
			TabBtn.TextColor3 = Theme.Text
			TabBtn.BackgroundColor3 = Theme.Element
			Page.Visible = true
			Page.Position = UDim2.new(0, 0, 0, 0)
			Window.ActiveTab = {Btn = TabBtn, Indicator = Indicator, Page = Page}
		end

		-- ==========================================
		-- ELEMENTS UI (Boutons, Toggles, etc.)
		-- ==========================================
		
		function Tab:CreateLabel(text)
			local Label = Utility:Create("TextLabel", {
				Parent = Page,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -24, 0, 20),
				Text = text,
				Font = FontBold,
				TextSize = 13,
				TextColor3 = Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left
			})
		end

		function Tab:CreateButton(text, callback)
			local Btn = Utility:Create("TextButton", {
				Parent = Page,
				BackgroundColor3 = Theme.Element,
				Size = UDim2.new(1, -24, 0, 36),
				Text = text,
				Font = Font,
				TextSize = 13,
				TextColor3 = Theme.Text,
				AutoButtonColor = false
			})
			Utility:Create("UICorner", { Parent = Btn, CornerRadius = UDim.new(0, 6) })
			Utility:Create("UIStroke", { Parent = Btn, Color = Theme.Outline, Thickness = 1 })

			Utility:Connect(Btn.MouseEnter, function() Utility:Tween(Btn, {BackgroundColor3 = Theme.ElementHover}) end)
			Utility:Connect(Btn.MouseLeave, function() Utility:Tween(Btn, {BackgroundColor3 = Theme.Element}) end)
			Utility:Connect(Btn.MouseButton1Down, function() Utility:Tween(Btn, {Size = UDim2.new(1, -28, 0, 34)}) end)
			Utility:Connect(Btn.MouseButton1Up, function() 
				Utility:Tween(Btn, {Size = UDim2.new(1, -24, 0, 36)})
				if callback then task.spawn(callback) end
			end)
		end

		function Tab:CreateToggle(text, default, callback)
			local toggled = default or false
			
			local ToggleFrame = Utility:Create("TextButton", {
				Parent = Page,
				BackgroundColor3 = Theme.Element,
				Size = UDim2.new(1, -24, 0, 36),
				Text = "",
				AutoButtonColor = false
			})
			Utility:Create("UICorner", { Parent = ToggleFrame, CornerRadius = UDim.new(0, 6) })
			Utility:Create("UIStroke", { Parent = ToggleFrame, Color = Theme.Outline, Thickness = 1 })

			local Title = Utility:Create("TextLabel", {
				Parent = ToggleFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 0),
				Size = UDim2.new(1, -60, 1, 0),
				Text = text,
				Font = Font,
				TextSize = 13,
				TextColor3 = Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left
			})

			local SwitchBg = Utility:Create("Frame", {
				Parent = ToggleFrame,
				BackgroundColor3 = toggled and Theme.Accent or Theme.Background,
				Size = UDim2.new(0, 36, 0, 18),
				Position = UDim2.new(1, -46, 0.5, -9)
			})
			Utility:Create("UICorner", { Parent = SwitchBg, CornerRadius = UDim.new(1, 0) })

			local SwitchCircle = Utility:Create("Frame", {
				Parent = SwitchBg,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Size = UDim2.new(0, 14, 0, 14),
				Position = UDim2.new(0, toggled and 20 or 2, 0.5, -7)
			})
			Utility:Create("UICorner", { Parent = SwitchCircle, CornerRadius = UDim.new(1, 0) })

			Utility:Connect(ToggleFrame.MouseButton1Click, function()
				toggled = not toggled
				Utility:Tween(SwitchBg, {BackgroundColor3 = toggled and Theme.Accent or Theme.Background})
				Utility:Tween(SwitchCircle, {Position = UDim2.new(0, toggled and 20 or 2, 0.5, -7)})
				if callback then task.spawn(callback, toggled) end
			end)
		end

		function Tab:CreateSlider(text, min, max, default, callback)
			local value = default or min
			
			local SliderFrame = Utility:Create("Frame", {
				Parent = Page,
				BackgroundColor3 = Theme.Element,
				Size = UDim2.new(1, -24, 0, 50)
			})
			Utility:Create("UICorner", { Parent = SliderFrame, CornerRadius = UDim.new(0, 6) })
			Utility:Create("UIStroke", { Parent = SliderFrame, Color = Theme.Outline, Thickness = 1 })

			local Title = Utility:Create("TextLabel", {
				Parent = SliderFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 5),
				Size = UDim2.new(1, -60, 0, 20),
				Text = text,
				Font = Font,
				TextSize = 13,
				TextColor3 = Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left
			})

			local ValueLabel = Utility:Create("TextLabel", {
				Parent = SliderFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -50, 0, 5),
				Size = UDim2.new(0, 40, 0, 20),
				Text = tostring(value),
				Font = FontBold,
				TextSize = 13,
				TextColor3 = Theme.Accent,
				TextXAlignment = Enum.TextXAlignment.Right
			})

			local SliderTrack = Utility:Create("TextButton", {
				Parent = SliderFrame,
				BackgroundColor3 = Theme.Background,
				Size = UDim2.new(1, -20, 0, 6),
				Position = UDim2.new(0, 10, 0, 32),
				Text = "",
				AutoButtonColor = false
			})
			Utility:Create("UICorner", { Parent = SliderTrack, CornerRadius = UDim.new(1, 0) })

			local SliderFill = Utility:Create("Frame", {
				Parent = SliderTrack,
				BackgroundColor3 = Theme.Accent,
				Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
			})
			Utility:Create("UICorner", { Parent = SliderFill, CornerRadius = UDim.new(1, 0) })

			local sliding = false
			local function UpdateSlider(input)
				local relativeX = math.clamp(input.Position.X - SliderTrack.AbsolutePosition.X, 0, SliderTrack.AbsoluteSize.X)
				local percent = relativeX / SliderTrack.AbsoluteSize.X
				value = math.floor(min + ((max - min) * percent))
				
				ValueLabel.Text = tostring(value)
				Utility:Tween(SliderFill, {Size = UDim2.new(percent, 0, 1, 0)}, 0.1)
				if callback then task.spawn(callback, value) end
			end

			Utility:Connect(SliderTrack.InputBegan, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					sliding = true
					UpdateSlider(input)
				end
			end)

			Utility:Connect(UserInputService.InputChanged, function(input)
				if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					UpdateSlider(input)
				end
			end)

			Utility:Connect(UserInputService.InputEnded, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					sliding = false
				end
			end)
		end

		function Tab:CreateDropdown(text, list, callback)
			local DropdownFrame = Utility:Create("Frame", {
				Parent = Page,
				BackgroundColor3 = Theme.Element,
				Size = UDim2.new(1, -24, 0, 36),
				ClipsDescendants = true
			})
			Utility:Create("UICorner", { Parent = DropdownFrame, CornerRadius = UDim.new(0, 6) })
			Utility:Create("UIStroke", { Parent = DropdownFrame, Color = Theme.Outline, Thickness = 1 })

			local MainBtn = Utility:Create("TextButton", {
				Parent = DropdownFrame,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 36),
				Text = ""
			})

			local Title = Utility:Create("TextLabel", {
				Parent = MainBtn,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 0),
				Size = UDim2.new(1, -40, 1, 0),
				Text = text .. " : ...",
				Font = Font,
				TextSize = 13,
				TextColor3 = Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left
			})

			local Icon = Utility:Create("TextLabel", {
				Parent = MainBtn,
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -25, 0, 0),
				Size = UDim2.new(0, 20, 1, 0),
				Text = "+",
				Font = FontBold,
				TextSize = 16,
				TextColor3 = Theme.TextDark
			})

			local ItemContainer = Utility:Create("Frame", {
				Parent = DropdownFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 36),
				Size = UDim2.new(1, 0, 1, -36)
			})
			local ItemLayout = Utility:Create("UIListLayout", { Parent = ItemContainer, Padding = UDim.new(0, 2), HorizontalAlignment = Enum.HorizontalAlignment.Center })

			local isOpen = false
			local itemHeight = 30

			Utility:Connect(MainBtn.MouseButton1Click, function()
				isOpen = not isOpen
				Icon.Text = isOpen and "-" or "+"
				local targetHeight = isOpen and (36 + (#list * itemHeight) + (#list * 2) + 5) or 36
				Utility:Tween(DropdownFrame, {Size = UDim2.new(1, -24, 0, targetHeight)}, 0.25)
			end)

			for _, item in ipairs(list) do
				local ItemBtn = Utility:Create("TextButton", {
					Parent = ItemContainer,
					BackgroundColor3 = Theme.Background,
					Size = UDim2.new(1, -12, 0, itemHeight),
					Text = "  " .. tostring(item),
					Font = Font,
					TextSize = 12,
					TextColor3 = Theme.TextDark,
					TextXAlignment = Enum.TextXAlignment.Left,
					AutoButtonColor = false
				})
				Utility:Create("UICorner", { Parent = ItemBtn, CornerRadius = UDim.new(0, 4) })

				Utility:Connect(ItemBtn.MouseEnter, function() Utility:Tween(ItemBtn, {BackgroundColor3 = Theme.ElementHover, TextColor3 = Theme.Text}) end)
				Utility:Connect(ItemBtn.MouseLeave, function() Utility:Tween(ItemBtn, {BackgroundColor3 = Theme.Background, TextColor3 = Theme.TextDark}) end)
				
				Utility:Connect(ItemBtn.MouseButton1Click, function()
					Title.Text = text .. " : " .. tostring(item)
					isOpen = false
					Icon.Text = "+"
					Utility:Tween(DropdownFrame, {Size = UDim2.new(1, -24, 0, 36)}, 0.25)
					if callback then task.spawn(callback, item) end
				end)
			end
		end

		return Tab
	end

	return Window
end

return Library
