local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local UI = {}

local ICONS = {
    Close = 82404346839314,
    Minimize = 85022922514331,
    Settings = 7059346373,
    Default = 136443043095009
}

local TWEEN_CONFIGS = {
    Instant = TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Normal = TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
    Smooth = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
}

local THEMES = {
    Dark = {
        Primary = Color3.fromRGB(30, 144, 255),
        Secondary = Color3.fromRGB(10, 100, 200),
        Background = Color3.fromRGB(12, 12, 12),
        Surface = Color3.fromRGB(20, 20, 20),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(180, 180, 180),
    },
    Light = {
        Primary = Color3.fromRGB(59, 130, 246),
        Secondary = Color3.fromRGB(37, 99, 235),
        Background = Color3.fromRGB(245, 245, 245),
        Surface = Color3.fromRGB(255, 255, 255),
        Text = Color3.fromRGB(30, 30, 30),
        TextSecondary = Color3.fromRGB(100, 100, 100),
    },
    Blue = {
        Primary = Color3.fromRGB(59, 130, 246),
        Secondary = Color3.fromRGB(37, 99, 235),
        Background = Color3.fromRGB(15, 23, 42),
        Surface = Color3.fromRGB(30, 41, 59),
        Text = Color3.fromRGB(248, 250, 252),
        TextSecondary = Color3.fromRGB(203, 213, 225),
    },
    Purple = {
        Primary = Color3.fromRGB(168, 85, 247),
        Secondary = Color3.fromRGB(147, 51, 234),
        Background = Color3.fromRGB(17, 7, 27),
        Surface = Color3.fromRGB(32, 14, 48),
        Text = Color3.fromRGB(250, 245, 255),
        TextSecondary = Color3.fromRGB(216, 180, 254),
    },
    Red = {
        Primary = Color3.fromRGB(239, 68, 68),
        Secondary = Color3.fromRGB(220, 38, 38),
        Background = Color3.fromRGB(20, 8, 8),
        Surface = Color3.fromRGB(37, 14, 14),
        Text = Color3.fromRGB(254, 242, 242),
        TextSecondary = Color3.fromRGB(252, 165, 165),
    }
}

-- THEME MANAGER - Applique les changements réels aux objets UI
local ThemeManager = {}
ThemeManager.__index = ThemeManager

function ThemeManager.new()
    local self = setmetatable({}, ThemeManager)
    self.elements = {}
    return self
end

function ThemeManager:Register(obj, elementType, config)
    if not self.elements[elementType] then
        self.elements[elementType] = {}
    end
    table.insert(self.elements[elementType], {obj = obj, config = config})
end

function ThemeManager:Apply(theme)
    -- Update backgrounds
    for _, item in pairs(self.elements.background or {}) do
        local obj = item.obj
        if obj and obj.Parent then
            obj.BackgroundColor3 = theme[item.config.key]
        end
    end

    -- Update text
    for _, item in pairs(self.elements.text or {}) do
        local obj = item.obj
        if obj and obj.Parent then
            obj.TextColor3 = theme[item.config.key]
        end
    end

    -- Update strokes
    for _, item in pairs(self.elements.stroke or {}) do
        local obj = item.obj
        if obj and obj.Parent then
            obj.Color = theme[item.config.key]
        end
    end

    -- Update gradients
    for _, item in pairs(self.elements.gradient or {}) do
        local obj = item.obj
        if obj and obj.Parent then
            obj.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, theme[item.config.key1]),
                ColorSequenceKeypoint.new(1, theme[item.config.key2])
            })
        end
    end
end

function ThemeManager:Cleanup()
    self.elements = {}
end

local function CreateGradient(parent, color1, color2, rotation)
    rotation = rotation or 0
    local gradient = Instance.new("UIGradient")
    gradient.Parent = parent
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2)
    })
    gradient.Rotation = rotation
    return gradient
end

function UI:CreateWindow(config)
    config = config or {}
    local Window = {}

    local guiName = LocalPlayer.UserId .. "_SlayerHub"
    local existingGui = CoreGui:FindFirstChild(guiName)
    if existingGui then
        existingGui:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = guiName
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false

    local currentThemeName = config.Theme or "Dark"
    local Theme = table.clone(THEMES[currentThemeName])
    
    Window.Theme = Theme
    Window.ThemeName = currentThemeName
    Window.Connections = {}
    Window.ThemeManager = ThemeManager.new()
    Window.Elements = {}

    -- Notification system
    local NotifContainer = Instance.new("Frame")
    NotifContainer.Name = "NotifContainer"
    NotifContainer.Parent = ScreenGui
    NotifContainer.BackgroundTransparency = 1
    NotifContainer.Size = UDim2.new(1, 0, 0, 0)
    NotifContainer.Position = UDim2.new(0, 0, 0, 30)
    NotifContainer.ZIndex = 100

    local NotifLayout = Instance.new("UIListLayout")
    NotifLayout.Parent = NotifContainer
    NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    NotifLayout.Padding = UDim.new(0, 10)

    function Window:Notify(text, duration, notifType)
        duration = duration or 3
        notifType = notifType or "normal"

        local NotifFrame = Instance.new("Frame")
        NotifFrame.Size = UDim2.new(0, 320, 0, 50)
        NotifFrame.BackgroundColor3 = Theme.Background
        NotifFrame.BorderSizePixel = 0
        NotifFrame.BackgroundTransparency = 0.95
        NotifFrame.Parent = NotifContainer

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 16)
        corner.Parent = NotifFrame

        local NotifText = Instance.new("TextLabel")
        NotifText.Parent = NotifFrame
        NotifText.Size = UDim2.new(1, -20, 1, 0)
        NotifText.Position = UDim2.new(0, 10, 0, 0)
        NotifText.BackgroundTransparency = 1
        NotifText.Text = text
        NotifText.TextColor3 = Theme.Text
        NotifText.Font = Enum.Font.GothamBold
        NotifText.TextSize = 13

        TweenService:Create(NotifFrame, TWEEN_CONFIGS.Fast, {BackgroundTransparency = 0.1}):Play()
        task.wait(duration)
        TweenService:Create(NotifFrame, TWEEN_CONFIGS.Fast, {BackgroundTransparency = 1}):Play()
        task.wait(0.15)
        NotifFrame:Destroy()
    end

    -- DRAG SYSTEM
    local function MakeDraggable(topbar, object)
        local dragging = false
        local dragStart = Vector2.new()
        local frameStart = UDim2.new()

        local inputChangedConn
        local inputEndedConn

        local inputBeganConn = topbar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                frameStart = object.Position
            end
        end)

        inputChangedConn = UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                object.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + delta.X, frameStart.Y.Scale, frameStart.Y.Offset + delta.Y)
            end
        end)

        inputEndedConn = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        table.insert(Window.Connections, inputBeganConn)
        table.insert(Window.Connections, inputChangedConn)
        table.insert(Window.Connections, inputEndedConn)
    end

    -- RESIZE SYSTEM - FIXÉ
    local function MakeResizable(mainFrame)
        local resizing = false
        local resizeDir = ""
        local dragStart = Vector2.new()
        local frameSizeStart = Vector2.new()
        local framePos = UDim2.new()

        local function CreateResizeHandle(corner_pos)
            local handle = Instance.new("Frame")
            handle.Name = "ResizeHandle_" .. corner_pos
            handle.Parent = mainFrame
            handle.BackgroundTransparency = 1
            handle.ZIndex = 15
            handle.Size = UDim2.new(0, 12, 0, 12)

            if corner_pos == "TL" then
                handle.Position = UDim2.new(0, -6, 0, -6)
                handle.Cursor = "ResizeNWSE"
            elseif corner_pos == "TR" then
                handle.Position = UDim2.new(1, -6, 0, -6)
                handle.Cursor = "ResizeNESW"
            elseif corner_pos == "BL" then
                handle.Position = UDim2.new(0, -6, 1, -6)
                handle.Cursor = "ResizeNESW"
            elseif corner_pos == "BR" then
                handle.Position = UDim2.new(1, -6, 1, -6)
                handle.Cursor = "ResizeNWSE"
            end

            local handleInputBeganConn = handle.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    resizing = true
                    resizeDir = corner_pos
                    dragStart = input.Position
                    frameSizeStart = Vector2.new(mainFrame.AbsoluteSize.X, mainFrame.AbsoluteSize.Y)
                    framePos = mainFrame.Position
                end
            end)

            table.insert(Window.Connections, handleInputBeganConn)
        end

        CreateResizeHandle("TL")
        CreateResizeHandle("TR")
        CreateResizeHandle("BL")
        CreateResizeHandle("BR")

        local moveConnInput = UserInputService.InputChanged:Connect(function(input)
            if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                local newSize = Vector2.new(frameSizeStart.X, frameSizeStart.Y)
                local newPos = framePos

                if resizeDir == "BR" then
                    newSize = Vector2.new(math.clamp(frameSizeStart.X + delta.X, 300, 800), math.clamp(frameSizeStart.Y + delta.Y, 200, 700))
                elseif resizeDir == "BL" then
                    newSize = Vector2.new(math.clamp(frameSizeStart.X - delta.X, 300, 800), math.clamp(frameSizeStart.Y + delta.Y, 200, 700))
                    newPos = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset)
                elseif resizeDir == "TR" then
                    newSize = Vector2.new(math.clamp(frameSizeStart.X + delta.X, 300, 800), math.clamp(frameSizeStart.Y - delta.Y, 200, 700))
                    newPos = UDim2.new(framePos.X.Scale, framePos.X.Offset, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
                elseif resizeDir == "TL" then
                    newSize = Vector2.new(math.clamp(frameSizeStart.X - delta.X, 300, 800), math.clamp(frameSizeStart.Y - delta.Y, 200, 700))
                    newPos = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
                end

                mainFrame.Size = UDim2.new(0, newSize.X, 0, newSize.Y)
                mainFrame.Position = newPos
            end
        end)

        local endConn = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = false
                resizeDir = ""
            end
        end)

        table.insert(Window.Connections, moveConnInput)
        table.insert(Window.Connections, endConn)
    end

    -- MAIN WINDOW
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Parent = ScreenGui
    Main.BackgroundColor3 = Theme.Background
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, -250, 0.5, -175)
    Main.Size = UDim2.new(0, 500, 0, 350)
    Main.ClipsDescendants = true

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 16)
    MainCorner.Parent = Main

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Thickness = 1.5
    MainStroke.Color = Theme.Secondary
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainStroke.Transparency = 0.5
    MainStroke.Parent = Main

    Window.ThemeManager:Register(Main, "background", {key = "Background"})
    Window.ThemeManager:Register(MainStroke, "stroke", {key = "Secondary"})

    -- TOPBAR
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Parent = Main
    TopBar.BackgroundColor3 = Theme.Secondary
    TopBar.Size = UDim2.new(1, 0, 0, 45)
    TopBar.BorderSizePixel = 0
    MakeDraggable(TopBar, Main)

    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 16)
    TopCorner.Parent = TopBar

    Window.ThemeManager:Register(TopBar, "background", {key = "Secondary"})

    local Title = Instance.new("TextLabel")
    Title.Parent = TopBar
    Title.Text = "SLAYER TYCOON V2 FIXED"
    Title.TextColor3 = Theme.Text
    Title.Size = UDim2.new(1, -100, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 15

    Window.ThemeManager:Register(Title, "text", {key = "Text"})

    -- CLOSE BUTTON
    local CloseBtn = Instance.new("ImageButton")
    CloseBtn.Parent = TopBar
    CloseBtn.Size = UDim2.new(0, 35, 0, 35)
    CloseBtn.Position = UDim2.new(1, -40, 0.5, -17)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Image = "rbxassetid://" .. ICONS.Close
    CloseBtn.ImageColor3 = Color3.fromRGB(255, 80, 80)
    CloseBtn.ScaleType = Enum.ScaleType.Fit

    local closeClickConn = CloseBtn.MouseButton1Click:Connect(function()
        Window:Destroy()
    end)
    table.insert(Window.Connections, closeClickConn)

    -- MINIMIZE BUTTON
    local MinBtn = Instance.new("ImageButton")
    MinBtn.Parent = TopBar
    MinBtn.Size = UDim2.new(0, 35, 0, 35)
    MinBtn.Position = UDim2.new(1, -75, 0.5, -17)
    MinBtn.BackgroundTransparency = 1
    MinBtn.Image = "rbxassetid://" .. ICONS.Minimize
    MinBtn.ImageColor3 = Theme.TextSecondary
    MinBtn.ScaleType = Enum.ScaleType.Fit

    Window.ThemeManager:Register(MinBtn, "text", {key = "TextSecondary"})

    local isMinimized = false
    local originalSize = Main.Size
    local originalPos = Main.Position

    local minClickConn = MinBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            originalSize = Main.Size
            originalPos = Main.Position
            TweenService:Create(Main, TWEEN_CONFIGS.Normal, {Size = UDim2.new(0, 220, 0, 45)}):Play()
            TopBar.Parent = Main
            for _, child in pairs(Main:GetChildren()) do
                if child:IsA("ScrollingFrame") or (child:IsA("Frame") and child.Name == "TabBar") then
                    child.Visible = false
                end
            end
        else
            TopBar.Parent = Main
            for _, child in pairs(Main:GetChildren()) do
                if child:IsA("ScrollingFrame") or (child:IsA("Frame") and child.Name == "TabBar") then
                    child.Visible = true
                end
            end
            TweenService:Create(Main, TWEEN_CONFIGS.Normal, {Size = originalSize}):Play()
        end
    end)
    table.insert(Window.Connections, minClickConn)

    -- TABBAR
    local TabBar = Instance.new("Frame")
    TabBar.Name = "TabBar"
    TabBar.Parent = Main
    TabBar.BackgroundColor3 = Theme.Surface
    TabBar.Position = UDim2.new(0, 0, 0, 45)
    TabBar.Size = UDim2.new(0, 120, 1, -45)
    TabBar.BorderSizePixel = 0
    TabBar.ClipsDescendants = true

    local TabBarCorner = Instance.new("UICorner")
    TabBarCorner.CornerRadius = UDim.new(0, 16)
    TabBarCorner.Parent = TabBar

    Window.ThemeManager:Register(TabBar, "background", {key = "Surface"})

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.Parent = TabBar
    TabListLayout.Padding = UDim.new(0, 6)
    TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabListLayout.FillDirection = Enum.FillDirection.Vertical

    local TabPadding = Instance.new("UIPadding")
    TabPadding.Parent = TabBar
    TabPadding.PaddingTop = UDim.new(0, 10)
    TabPadding.PaddingBottom = UDim.new(0, 10)

    -- PAGES
    local Pages = Instance.new("Frame")
    Pages.Name = "Pages"
    Pages.Parent = Main
    Pages.BackgroundTransparency = 1
    Pages.Position = UDim2.new(0, 120, 0, 45)
    Pages.Size = UDim2.new(1, -120, 1, -45)
    Pages.ClipsDescendants = true

    Window.Pages = Pages
    Window.TabBar = TabBar
    Window.TabCount = 0
    Window.Main = Main

    MakeResizable(Main)

    function Window:CreateTab(name, customIcon)
        local Tab = {}
        Tab._LayoutOrder = 0
        Window.TabCount = Window.TabCount + 1

        local Page = Instance.new("ScrollingFrame")
        Page.Name = name .. "Page"
        Page.Parent = Window.Pages
        Page.BackgroundTransparency = 1
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.ScrollBarThickness = 3
        Page.ScrollBarImageColor3 = Theme.Primary
        Page.Visible = (Window.TabCount == 1)
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.Position = UDim2.new(Window.TabCount == 1 and 0 or 1, 0, 0, 0)

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Parent = Page
        PageLayout.Padding = UDim.new(0, 10)
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local layoutConn = PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20)
        end)
        table.insert(Window.Connections, layoutConn)

        local iconToUse = customIcon
        if customIcon == nil then
            iconToUse = nil
        elseif customIcon == false or customIcon == "" then
            iconToUse = ICONS.Default
        else
            iconToUse = customIcon or ICONS.Default
        end

        -- TAB BUTTON
        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = name .. "Tab"
        TabBtn.Parent = Window.TabBar
        TabBtn.Size = UDim2.new(0, 100, 0, 36)
        TabBtn.BackgroundColor3 = Window.TabCount == 1 and Theme.Primary or Theme.Surface
        TabBtn.TextColor3 = Window.TabCount == 1 and Theme.Text or Theme.TextSecondary
        TabBtn.BorderSizePixel = 0
        TabBtn.Text = ""
        TabBtn.Font = Enum.Font.GothamBold
        TabBtn.TextSize = 12
        TabBtn.AutoButtonColor = false

        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 8)
        TabCorner.Parent = TabBtn

        Window.ThemeManager:Register(TabBtn, "background", {key = Window.TabCount == 1 and "Primary" or "Surface"})

        local TabContent = Instance.new("Frame")
        TabContent.Parent = TabBtn
        TabContent.BackgroundTransparency = 1
        TabContent.Size = UDim2.new(1, 0, 1, 0)

        local TabContentLayout = Instance.new("UIListLayout")
        TabContentLayout.Parent = TabContent
        TabContentLayout.FillDirection = Enum.FillDirection.Horizontal
        TabContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        TabContentLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        TabContentLayout.Padding = UDim.new(0, 5)

        if iconToUse then
            local TabIcon = Instance.new("ImageLabel")
            TabIcon.Parent = TabContent
            TabIcon.BackgroundTransparency = 1
            TabIcon.Size = UDim2.new(0, 18, 0, 18)
            TabIcon.Image = "rbxassetid://" .. iconToUse
            TabIcon.ImageColor3 = TabBtn.TextColor3
            TabIcon.ScaleType = Enum.ScaleType.Fit
        end

        local TabLabel = Instance.new("TextLabel")
        TabLabel.Parent = TabContent
        TabLabel.BackgroundTransparency = 1
        TabLabel.Size = UDim2.new(0, 60, 0, 18)
        TabLabel.Text = name
        TabLabel.TextColor3 = TabBtn.TextColor3
        TabLabel.Font = Enum.Font.GothamBold
        TabLabel.TextSize = 12
        TabLabel.TextXAlignment = Enum.TextXAlignment.Center

        local tabClickConn = TabBtn.MouseButton1Click:Connect(function()
            for _, p in pairs(Window.Pages:GetChildren()) do
                if p:IsA("ScrollingFrame") then
                    p.Position = UDim2.new(1, 0, 0, 0)
                    local outTween = TweenService:Create(p, TWEEN_CONFIGS.Normal, {Position = UDim2.new(-1, 0, 0, 0)})
                    outTween:Play()
                    outTween.Completed:Connect(function()
                        p.Visible = false
                    end)
                end
            end

            for _, t in pairs(Window.TabBar:GetChildren()) do
                if t:IsA("TextButton") then
                    TweenService:Create(t, TWEEN_CONFIGS.Fast, {TextColor3 = Theme.TextSecondary, BackgroundColor3 = Theme.Surface}):Play()
                end
            end

            Page.Position = UDim2.new(1, 0, 0, 0)
            Page.Visible = true
            local inTween = TweenService:Create(Page, TWEEN_CONFIGS.Normal, {Position = UDim2.new(0, 0, 0, 0)})
            inTween:Play()

            TweenService:Create(TabBtn, TWEEN_CONFIGS.Fast, {TextColor3 = Theme.Text, BackgroundColor3 = Theme.Primary}):Play()
        end)
        table.insert(Window.Connections, tabClickConn)

        function Tab:CreateLabel(text)
            local LabelFrame = Instance.new("Frame")
            LabelFrame.Size = UDim2.new(1, 0, 0, 30)
            LabelFrame.BackgroundTransparency = 1
            LabelFrame.Parent = Page
            LabelFrame.LayoutOrder = Tab._LayoutOrder
            Tab._LayoutOrder = Tab._LayoutOrder + 1

            local Label = Instance.new("TextLabel")
            Label.Parent = LabelFrame
            Label.Size = UDim2.new(1, -10, 1, 0)
            Label.Position = UDim2.new(0, 5, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Theme.TextSecondary
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 12
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextWrapped = true

            Window.ThemeManager:Register(Label, "text", {key = "TextSecondary"})
        end

        function Tab:CreateButton(config)
            local ButtonFrame = Instance.new("Frame")
            ButtonFrame.Size = UDim2.new(1, 0, 0, 42)
            ButtonFrame.BackgroundTransparency = 1
            ButtonFrame.Parent = Page
            ButtonFrame.LayoutOrder = Tab._LayoutOrder
            Tab._LayoutOrder = Tab._LayoutOrder + 1

            local TextBtn = Instance.new("TextButton")
            TextBtn.Parent = ButtonFrame
            TextBtn.BackgroundColor3 = Theme.Secondary
            TextBtn.Size = UDim2.new(1, 0, 1, 0)
            TextBtn.Text = config.Name
            TextBtn.TextColor3 = Theme.Text
            TextBtn.Font = Enum.Font.GothamBold
            TextBtn.TextSize = 13
            TextBtn.BorderSizePixel = 0
            TextBtn.AutoButtonColor = false

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 8)
            btnCorner.Parent = TextBtn

            Window.ThemeManager:Register(TextBtn, "background", {key = "Secondary"})
            Window.ThemeManager:Register(TextBtn, "text", {key = "Text"})

            local btnClickConn = TextBtn.MouseButton1Click:Connect(function()
                if config.Callback then config.Callback() end
            end)
            table.insert(Window.Connections, btnClickConn)
        end

        function Tab:CreateToggle(config)
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Size = UDim2.new(1, 0, 0, 42)
            ToggleFrame.BackgroundTransparency = 1
            ToggleFrame.Parent = Page
            ToggleFrame.LayoutOrder = Tab._LayoutOrder
            Tab._LayoutOrder = Tab._LayoutOrder + 1

            local TextBtn = Instance.new("TextButton")
            TextBtn.Parent = ToggleFrame
            TextBtn.BackgroundColor3 = Theme.Surface
            TextBtn.Size = UDim2.new(1, 0, 1, 0)
            TextBtn.Text = "   " .. config.Name
            TextBtn.TextColor3 = Theme.TextSecondary
            TextBtn.Font = Enum.Font.Gotham
            TextBtn.TextSize = 13
            TextBtn.TextXAlignment = Enum.TextXAlignment.Left
            TextBtn.BorderSizePixel = 0
            TextBtn.AutoButtonColor = false

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 8)
            btnCorner.Parent = TextBtn

            Window.ThemeManager:Register(TextBtn, "background", {key = "Surface"})
            Window.ThemeManager:Register(TextBtn, "text", {key = "TextSecondary"})

            local StatusContainer = Instance.new("Frame")
            StatusContainer.Parent = TextBtn
            StatusContainer.BackgroundColor3 = Theme.Secondary
            StatusContainer.Position = UDim2.new(1, -50, 0.5, -11)
            StatusContainer.Size = UDim2.new(0, 40, 0, 22)
            StatusContainer.BorderSizePixel = 0

            Window.ThemeManager:Register(StatusContainer, "background", {key = "Secondary"})

            local statusCorner = Instance.new("UICorner")
            statusCorner.CornerRadius = UDim.new(1, 0)
            statusCorner.Parent = StatusContainer

            local StatusCircle = Instance.new("Frame")
            StatusCircle.Parent = StatusContainer
            StatusCircle.BackgroundColor3 = Theme.TextSecondary
            StatusCircle.Position = UDim2.new(0, 2, 0.5, -8)
            StatusCircle.Size = UDim2.new(0, 16, 0, 16)
            StatusCircle.BorderSizePixel = 0

            Window.ThemeManager:Register(StatusCircle, "background", {key = "TextSecondary"})

            local circleCorner = Instance.new("UICorner")
            circleCorner.CornerRadius = UDim.new(1, 0)
            circleCorner.Parent = StatusCircle

            local enabled = config.Default or false

            local function SetState(state)
                enabled = state
                if enabled then
                    TweenService:Create(StatusCircle, TWEEN_CONFIGS.Fast, {Position = UDim2.new(1, -18, 0.5, -8)}):Play()
                    TweenService:Create(StatusContainer, TWEEN_CONFIGS.Fast, {BackgroundColor3 = Theme.Primary}):Play()
                else
                    TweenService:Create(StatusCircle, TWEEN_CONFIGS.Fast, {Position = UDim2.new(0, 2, 0.5, -8)}):Play()
                    TweenService:Create(StatusContainer, TWEEN_CONFIGS.Fast, {BackgroundColor3 = Theme.Secondary}):Play()
                end
            end

            if enabled then SetState(true) end

            local toggleClickConn = TextBtn.MouseButton1Click:Connect(function()
                enabled = not enabled
                SetState(enabled)
                if config.Callback then config.Callback(enabled, SetState) end
            end)
            table.insert(Window.Connections, toggleClickConn)

            return SetState
        end

        function Tab:CreateSlider(config)
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Size = UDim2.new(1, 0, 0, 62)
            SliderFrame.BackgroundColor3 = Theme.Surface
            SliderFrame.Parent = Page
            SliderFrame.BorderSizePixel = 0
            SliderFrame.LayoutOrder = Tab._LayoutOrder
            Tab._LayoutOrder = Tab._LayoutOrder + 1

            Window.ThemeManager:Register(SliderFrame, "background", {key = "Surface"})

            local sCorner = Instance.new("UICorner")
            sCorner.CornerRadius = UDim.new(0, 8)
            sCorner.Parent = SliderFrame

            local Label = Instance.new("TextLabel")
            Label.Parent = SliderFrame
            Label.Text = "   " .. config.Name .. " : " .. config.Default
            Label.TextColor3 = Theme.TextSecondary
            Label.Size = UDim2.new(1, 0, 0, 28)
            Label.BackgroundTransparency = 1
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 12
            Label.TextXAlignment = Enum.TextXAlignment.Left

            Window.ThemeManager:Register(Label, "text", {key = "TextSecondary"})

            local SliderBack = Instance.new("Frame")
            SliderBack.Parent = SliderFrame
            SliderBack.BackgroundColor3 = Theme.Secondary
            SliderBack.Position = UDim2.new(0, 10, 0, 35)
            SliderBack.Size = UDim2.new(1, -20, 0, 10)
            SliderBack.BorderSizePixel = 0

            Window.ThemeManager:Register(SliderBack, "background", {key = "Secondary"})

            local sbCorner = Instance.new("UICorner")
            sbCorner.CornerRadius = UDim.new(1, 0)
            sbCorner.Parent = SliderBack

            local SliderFill = Instance.new("Frame")
            SliderFill.Parent = SliderBack
            SliderFill.BackgroundColor3 = Theme.Primary
            SliderFill.Size = UDim2.new((config.Default - config.Min) / (config.Max - config.Min), 0, 1, 0)
            SliderFill.BorderSizePixel = 0

            Window.ThemeManager:Register(SliderFill, "background", {key = "Primary"})

            local sfCorner = Instance.new("UICorner")
            sfCorner.CornerRadius = UDim.new(1, 0)
            sfCorner.Parent = SliderFill

            local SliderBall = Instance.new("Frame")
            SliderBall.Parent = SliderBack
            SliderBall.BackgroundColor3 = Theme.Primary
            SliderBall.Size = UDim2.new(0, 18, 0, 18)
            SliderBall.Position = UDim2.new((config.Default - config.Min) / (config.Max - config.Min), -9, 0.5, -9)
            SliderBall.BorderSizePixel = 0
            SliderBall.ZIndex = 10

            Window.ThemeManager:Register(SliderBall, "background", {key = "Primary"})

            local ballCorner = Instance.new("UICorner")
            ballCorner.CornerRadius = UDim.new(1, 0)
            ballCorner.Parent = SliderBall

            local sliderState = {
                sliding = false,
                currentValue = config.Default,
                connections = {}
            }

            local function update(inputPos)
                local relativePos = math.clamp((inputPos.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
                SliderFill.Size = UDim2.new(relativePos, 0, 1, 0)
                SliderBall.Position = UDim2.new(relativePos, -9, 0.5, -9)
                local val = math.floor(((config.Max - config.Min) * relativePos) + config.Min)
                sliderState.currentValue = val
                Label.Text = "   " .. config.Name .. " : " .. val
                if config.Callback then config.Callback(val) end
            end

            local beganConn = SliderBack.InputBegan:Connect(function(input)
                if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not sliderState.sliding then
                    sliderState.sliding = true
                    TweenService:Create(SliderBall, TWEEN_CONFIGS.Fast, {Size = UDim2.new(0, 24, 0, 24), Position = SliderBall.Position + UDim2.new(0, -3, 0, -3)}):Play()
                    update(input.Position)
                end
            end)
            table.insert(sliderState.connections, beganConn)
            table.insert(Window.Connections, beganConn)

            local changedConn = UserInputService.InputChanged:Connect(function(input)
                if sliderState.sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    update(input.Position)
                end
            end)
            table.insert(sliderState.connections, changedConn)
            table.insert(Window.Connections, changedConn)

            local endedConn = UserInputService.InputEnded:Connect(function(input)
                if sliderState.sliding and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                    sliderState.sliding = false
                    TweenService:Create(SliderBall, TWEEN_CONFIGS.Fast, {Size = UDim2.new(0, 18, 0, 18), Position = SliderBall.Position + UDim2.new(0, 3, 0, 3)}):Play()
                end
            end)
            table.insert(sliderState.connections, endedConn)
            table.insert(Window.Connections, endedConn)

            local cleanupConn = SliderFrame.AncestryChanged:Connect(function(child, parent)
                if parent == nil then
                    for _, conn in pairs(sliderState.connections) do
                        if conn then conn:Disconnect() end
                    end
                end
            end)
            table.insert(Window.Connections, cleanupConn)
        end

        function Tab:CreateDropdown(config)
            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Size = UDim2.new(1, 0, 0, 42)
            DropdownFrame.BackgroundTransparency = 1
            DropdownFrame.Parent = Page
            DropdownFrame.LayoutOrder = Tab._LayoutOrder
            Tab._LayoutOrder = Tab._LayoutOrder + 1
            DropdownFrame.ZIndex = 10

            local MainBtn = Instance.new("TextButton")
            MainBtn.Parent = DropdownFrame
            MainBtn.BackgroundColor3 = Theme.Surface
            MainBtn.Size = UDim2.new(1, 0, 0, 42)
            MainBtn.Text = "   " .. config.Name .. " : " .. (config.Default or "Select")
            MainBtn.TextColor3 = Theme.TextSecondary
            MainBtn.Font = Enum.Font.Gotham
            MainBtn.TextSize = 13
            MainBtn.TextXAlignment = Enum.TextXAlignment.Left
            MainBtn.BorderSizePixel = 0
            MainBtn.AutoButtonColor = false

            Window.ThemeManager:Register(MainBtn, "background", {key = "Surface"})
            Window.ThemeManager:Register(MainBtn, "text", {key = "TextSecondary"})

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 8)
            btnCorner.Parent = MainBtn

            local isOpen = false
            local DropdownMenu = Instance.new("ScrollingFrame")
            DropdownMenu.Parent = DropdownFrame
            DropdownMenu.BackgroundColor3 = Theme.Surface
            DropdownMenu.Position = UDim2.new(0, 0, 0, 42)
            DropdownMenu.Size = UDim2.new(1, 0, 0, 0)
            DropdownMenu.BorderSizePixel = 0
            DropdownMenu.ClipsDescendants = true
            DropdownMenu.ZIndex = 50
            DropdownMenu.ScrollBarThickness = 2
            DropdownMenu.CanvasSize = UDim2.new(1, 0, 0, #config.Items * 32)

            Window.ThemeManager:Register(DropdownMenu, "background", {key = "Surface"})

            local menuCorner = Instance.new("UICorner")
            menuCorner.CornerRadius = UDim.new(0, 8)
            menuCorner.Parent = DropdownMenu

            local MenuLayout = Instance.new("UIListLayout")
            MenuLayout.Parent = DropdownMenu
            MenuLayout.Padding = UDim.new(0, 3)

            local MenuPadding = Instance.new("UIPadding")
            MenuPadding.Parent = DropdownMenu
            MenuPadding.PaddingLeft = UDim.new(0, 3)
            MenuPadding.PaddingRight = UDim.new(0, 3)
            MenuPadding.PaddingTop = UDim.new(0, 3)
            MenuPadding.PaddingBottom = UDim.new(0, 3)

            local dropdownClickConn = MainBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    local itemHeight = math.min(32 * #config.Items + 12, 150)
                    TweenService:Create(DropdownMenu, TWEEN_CONFIGS.Normal, {Size = UDim2.new(1, 0, 0, itemHeight)}):Play()
                else
                    TweenService:Create(DropdownMenu, TWEEN_CONFIGS.Normal, {Size = UDim2.new(1, 0, 0, 0)}):Play()
                end
            end)
            table.insert(Window.Connections, dropdownClickConn)

            for _, item in pairs(config.Items) do
                local ItemBtn = Instance.new("TextButton")
                ItemBtn.Parent = DropdownMenu
                ItemBtn.BackgroundColor3 = Theme.Secondary
                ItemBtn.Size = UDim2.new(1, 0, 0, 32)
                ItemBtn.Text = item
                ItemBtn.TextColor3 = Theme.TextSecondary
                ItemBtn.Font = Enum.Font.Gotham
                ItemBtn.TextSize = 12
                ItemBtn.BorderSizePixel = 0
                ItemBtn.AutoButtonColor = false

                Window.ThemeManager:Register(ItemBtn, "background", {key = "Secondary"})
                Window.ThemeManager:Register(ItemBtn, "text", {key = "TextSecondary"})

                local itemCorner = Instance.new("UICorner")
                itemCorner.CornerRadius = UDim.new(0, 6)
                itemCorner.Parent = ItemBtn

                local itemClickConn = ItemBtn.MouseButton1Click:Connect(function()
                    MainBtn.Text = "   " .. config.Name .. " : " .. item
                    isOpen = false
                    TweenService:Create(DropdownMenu, TWEEN_CONFIGS.Normal, {Size = UDim2.new(1, 0, 0, 0)}):Play()
                    if config.Callback then config.Callback(item) end
                end)
                table.insert(Window.Connections, itemClickConn)
            end
        end

        return Tab
    end

    -- AUTO CREATE SETTINGS TAB AVEC THÈME SWITCHER
    local SettingsTab = Window:CreateTab("Settings", ICONS.Settings)

    SettingsTab:CreateLabel("── THEMES ──")

    for themeName, _ in pairs(THEMES) do
        SettingsTab:CreateButton({
            Name = themeName,
            Callback = function()
                Window:SetTheme(themeName)
            end
        })
    end

    SettingsTab:CreateLabel("")
    SettingsTab:CreateLabel("── WINDOW ──")

    SettingsTab:CreateSlider({
        Name = "Width",
        Min = 300,
        Max = 800,
        Default = 500,
        Callback = function(value)
            Main.Size = UDim2.new(0, value, 0, Main.Size.Y.Offset)
            Main.Position = UDim2.new(0.5, -value/2, Main.Position.Y.Scale, Main.Position.Y.Offset)
        end
    })

    SettingsTab:CreateSlider({
        Name = "Height",
        Min = 200,
        Max = 700,
        Default = 350,
        Callback = function(value)
            Main.Size = UDim2.new(0, Main.Size.X.Offset, 0, value)
        end
    })

    -- THEME CHANGER FUNCTION
    function Window:SetTheme(themeName)
        if not THEMES[themeName] then return end
        local newTheme = THEMES[themeName]
        for k, v in pairs(newTheme) do
            Theme[k] = v
        end
        Window.ThemeName = themeName
        Window.ThemeManager:Apply(Theme)
        self:Notify("Theme: " .. themeName, 2, "success")
    end

    -- CLEANUP FUNCTION
    function Window:Destroy()
        for _, conn in pairs(self.Connections) do
            if conn and conn.Connected then
                conn:Disconnect()
            end
        end
        self.Connections = {}
        self.ThemeManager:Cleanup()
        ScreenGui:Destroy()
    end

    return Window
end

return UI
