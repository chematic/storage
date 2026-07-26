local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local UI = {}

-- Icon IDs
local ICONS = {
    Close = 82404346839314,
    Minimize = 85022922514331,
    Settings = 7059346373,
    Default = 136443043095009
}

-- Animation presets for performance
local TWEEN_CONFIGS = {
    Instant = TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Normal = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Smooth = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Slow = TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut),
    ExtraSmooth = TweenInfo.new(0.7, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut)
}

-- Utility function to create gradients
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

-- Utility function to add glow effect
local function AddGlow(frame, color, size)
    size = size or 15
    local shadow = Instance.new("ShadowObject")
    shadow.Adornee = frame
    shadow.Transparency = 0.7
    shadow.Color3 = color
    shadow.Radius = size
    return shadow
end

function UI:CreateWindow()
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

    -- Enhanced theme with gradients and modern colors
    local Theme = {
        Primary = Color3.fromRGB(30, 144, 255),
        PrimaryLight = Color3.fromRGB(100, 180, 255),
        Secondary = Color3.fromRGB(10, 100, 200),
        SecondaryLight = Color3.fromRGB(40, 130, 230),
        Background = Color3.fromRGB(12, 12, 12),
        Surface = Color3.fromRGB(20, 20, 20),
        SurfaceLight = Color3.fromRGB(30, 30, 30),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(180, 180, 180),
        Accent = Color3.fromRGB(100, 200, 255),
        Success = Color3.fromRGB(76, 175, 80),
        Warning = Color3.fromRGB(255, 152, 0),
        Error = Color3.fromRGB(244, 67, 54),
        Transparency = 0,
        CornerRadius = 8,
        StrokeThickness = 1.5
    }

    Window.Theme = Theme
    Window.Tweens = {}

    -- Notification container
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
        
        local notifColor = Theme.Primary
        if notifType == "success" then notifColor = Theme.Success
        elseif notifType == "warning" then notifColor = Theme.Warning
        elseif notifType == "error" then notifColor = Theme.Error end
        
        local NotifFrame = Instance.new("Frame")
        NotifFrame.Size = UDim2.new(0, 320, 0, 50)
        NotifFrame.BackgroundColor3 = Theme.Background
        NotifFrame.BorderSizePixel = 0
        NotifFrame.BackgroundTransparency = 0.95

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, Theme.CornerRadius)
        corner.Parent = NotifFrame

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = Theme.StrokeThickness
        stroke.Color = notifColor
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Transparency = 0.3
        stroke.Parent = NotifFrame

        local NotifText = Instance.new("TextLabel")
        NotifText.Parent = NotifFrame
        NotifText.Size = UDim2.new(1, -20, 1, 0)
        NotifText.Position = UDim2.new(0, 10, 0, 0)
        NotifText.BackgroundTransparency = 1
        NotifText.Text = text
        NotifText.TextColor3 = Theme.Text
        NotifText.Font = Enum.Font.GothamBold
        NotifText.TextSize = 13
        NotifText.TextWrapped = true
        NotifText.TextTransparency = 0.3

        NotifFrame.Parent = NotifContainer

        local tweens = {
            TweenService:Create(NotifFrame, TWEEN_CONFIGS.Fast, {BackgroundTransparency = 0.1}),
            TweenService:Create(stroke, TWEEN_CONFIGS.Fast, {Transparency = 0}),
            TweenService:Create(NotifText, TWEEN_CONFIGS.Fast, {TextTransparency = 0})
        }
        
        for _, tween in pairs(tweens) do tween:Play() end

        task.delay(duration, function()
            local outTweens = {
                TweenService:Create(NotifFrame, TWEEN_CONFIGS.Fast, {BackgroundTransparency = 1}),
                TweenService:Create(stroke, TWEEN_CONFIGS.Fast, {Transparency = 1}),
                TweenService:Create(NotifText, TWEEN_CONFIGS.Fast, {TextTransparency = 1})
            }
            for _, tween in pairs(outTweens) do tween:Play() end
            
            task.wait(0.15)
            if NotifFrame then
                NotifFrame:Destroy()
            end
        end)
    end

    local function MakeDraggable(topbarobject, object)
        local dragging = false
        local dragInput, mousePos, framePos
        
        topbarobject.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                mousePos = input.Position
                framePos = object.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        
        topbarobject.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - mousePos
                object.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
            end
        end)
    end

    -- Main window frame
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Parent = ScreenGui
    Main.BackgroundColor3 = Theme.Background
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, -250, 0.5, -150)
    Main.Size = UDim2.new(0, 500, 0, 350)
    Main.ClipsDescendants = true

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, Theme.CornerRadius)
    MainCorner.Parent = Main

    -- Create gradient for main background
    CreateGradient(Main, Color3.fromRGB(15, 15, 15), Color3.fromRGB(25, 25, 25), 45)

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Thickness = Theme.StrokeThickness
    MainStroke.Color = Theme.Secondary
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainStroke.Transparency = 0.5
    MainStroke.Parent = Main

    -- Top bar
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Parent = Main
    TopBar.BackgroundColor3 = Theme.Secondary
    TopBar.Size = UDim2.new(1, 0, 0, 40)
    TopBar.BorderSizePixel = 0
    MakeDraggable(TopBar, Main)

    CreateGradient(TopBar, Theme.Secondary, Color3.fromRGB(20, 120, 220), 0)

    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, Theme.CornerRadius)
    TopCorner.Parent = TopBar

    local Title = Instance.new("TextLabel")
    Title.Parent = TopBar
    Title.Text = "SLAYER TYCOON V1 <font color='#64B4FF'>BY @theuniqueleader</font>"
    Title.RichText = true
    Title.TextColor3 = Theme.Text
    Title.Size = UDim2.new(1, -100, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14

    -- Close button with icon
    local CloseBtn = Instance.new("ImageButton")
    CloseBtn.Parent = TopBar
    CloseBtn.Size = UDim2.new(0, 35, 0, 35)
    CloseBtn.Position = UDim2.new(1, -40, 0.5, -17)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Image = "rbxassetid://" .. ICONS.Close
    CloseBtn.ImageColor3 = Color3.fromRGB(255, 80, 80)
    CloseBtn.ScaleType = Enum.ScaleType.Fit

    CloseBtn.MouseEnter:Connect(function()
        TweenService:Create(CloseBtn, TWEEN_CONFIGS.Fast, {ImageColor3 = Color3.fromRGB(255, 120, 120)}):Play()
    end)

    CloseBtn.MouseLeave:Connect(function()
        TweenService:Create(CloseBtn, TWEEN_CONFIGS.Fast, {ImageColor3 = Color3.fromRGB(255, 80, 80)}):Play()
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    -- Minimize button with icon
    local MinBtn = Instance.new("ImageButton")
    MinBtn.Parent = TopBar
    MinBtn.Size = UDim2.new(0, 35, 0, 35)
    MinBtn.Position = UDim2.new(1, -75, 0.5, -17)
    MinBtn.BackgroundTransparency = 1
    MinBtn.Image = "rbxassetid://" .. ICONS.Minimize
    MinBtn.ImageColor3 = Theme.TextSecondary
    MinBtn.ScaleType = Enum.ScaleType.Fit

    MinBtn.MouseEnter:Connect(function()
        TweenService:Create(MinBtn, TWEEN_CONFIGS.Fast, {ImageColor3 = Theme.Text}):Play()
    end)

    MinBtn.MouseLeave:Connect(function()
        TweenService:Create(MinBtn, TWEEN_CONFIGS.Fast, {ImageColor3 = Theme.TextSecondary}):Play()
    end)

    local isMinimized = false
    local originalPos = Main.Position
    
    MinBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            originalPos = Main.Position
            TweenService:Create(Main, TWEEN_CONFIGS.ExtraSmooth, {Position = UDim2.new(0, 10, 1, -50), Size = UDim2.new(0, 200, 0, 40)}):Play()
        else
            TweenService:Create(Main, TWEEN_CONFIGS.ExtraSmooth, {Position = originalPos, Size = UDim2.new(0, 500, 0, 350)}):Play()
        end
    end)

    -- Tab bar with fixed corner radius
    local TabBar = Instance.new("Frame")
    TabBar.Name = "TabBar"
    TabBar.Parent = Main
    TabBar.BackgroundColor3 = Theme.Surface
    TabBar.Position = UDim2.new(0, 0, 0, 40)
    TabBar.Size = UDim2.new(0, 110, 1, -40)
    TabBar.BorderSizePixel = 0
    TabBar.ClipsDescendants = true

    -- FIX: Add corner radius to TabBar
    local TabBarCorner = Instance.new("UICorner")
    TabBarCorner.CornerRadius = UDim.new(0, Theme.CornerRadius)
    TabBarCorner.Parent = TabBar

    CreateGradient(TabBar, Color3.fromRGB(22, 22, 22), Color3.fromRGB(28, 28, 28), 90)

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.Parent = TabBar
    TabListLayout.Padding = UDim.new(0, 5)
    TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local TabPadding = Instance.new("UIPadding")
    TabPadding.Parent = TabBar
    TabPadding.PaddingTop = UDim.new(0, 10)

    local Pages = Instance.new("Frame")
    Pages.Name = "Pages"
    Pages.Parent = Main
    Pages.BackgroundTransparency = 1
    Pages.Position = UDim2.new(0, 120, 0, 50)
    Pages.Size = UDim2.new(1, -130, 1, -60)

    Window.Pages = Pages
    Window.TabBar = TabBar
    Window.TabCount = 0

    function Window:CreateTab(name, customIcon)
        local Tab = {}
        Window.TabCount = Window.TabCount + 1

        local Page = Instance.new("ScrollingFrame")
        Page.Name = name .. "Page"
        Page.Parent = Window.Pages
        Page.BackgroundTransparency = 1
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.ScrollBarThickness = 2
        Page.ScrollBarImageColor3 = Theme.Primary
        Page.Visible = (Window.TabCount == 1)
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Parent = Page
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y)
        end)

        -- Determine icon to use
        local iconToUse
        if customIcon == nil then
            iconToUse = nil -- No icon, no space reserved
        elseif customIcon == false or customIcon == "" then
            iconToUse = ICONS.Default
        else
            iconToUse = customIcon or ICONS.Default
        end

        -- Tab button
        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = name .. "Tab"
        TabBtn.Parent = Window.TabBar
        TabBtn.Size = UDim2.new(0, 100, 0, 32)
        
        if Window.TabCount == 1 then
            TabBtn.BackgroundColor3 = Theme.Primary
            TabBtn.TextColor3 = Theme.Text
        else
            TabBtn.BackgroundColor3 = Theme.Surface
            TabBtn.TextColor3 = Theme.TextSecondary
        end
        
        TabBtn.BorderSizePixel = 0
        TabBtn.Text = ""
        TabBtn.Font = Enum.Font.GothamBold
        TabBtn.TextSize = 11

        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 6)
        TabCorner.Parent = TabBtn

        -- Add gradient to active tabs
        local function UpdateTabGradient()
            if TabBtn.BackgroundColor3 == Theme.Primary then
                local gradChildren = TabBtn:GetChildren()
                for _, child in pairs(gradChildren) do
                    if child:IsA("UIGradient") then
                        child:Destroy()
                    end
                end
                CreateGradient(TabBtn, Theme.Primary, Theme.PrimaryLight, 0)
            else
                local gradChildren = TabBtn:GetChildren()
                for _, child in pairs(gradChildren) do
                    if child:IsA("UIGradient") then
                        child:Destroy()
                    end
                end
                CreateGradient(TabBtn, Theme.Surface, Color3.fromRGB(35, 35, 35), 0)
            end
        end

        UpdateTabGradient()

        -- Tab content container (icon + text)
        local TabContent = Instance.new("Frame")
        TabContent.Parent = TabBtn
        TabContent.BackgroundTransparency = 1
        TabContent.Size = UDim2.new(1, 0, 1, 0)

        local TabContentLayout = Instance.new("UIListLayout")
        TabContentLayout.Parent = TabContent
        TabContentLayout.FillDirection = Enum.FillDirection.Horizontal
        TabContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        TabContentLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        TabContentLayout.Padding = UDim.new(0, 4)

        -- Add icon if exists
        if iconToUse then
            local TabIcon = Instance.new("ImageLabel")
            TabIcon.Parent = TabContent
            TabIcon.BackgroundTransparency = 1
            TabIcon.Size = UDim2.new(0, 16, 0, 16)
            TabIcon.Image = "rbxassetid://" .. iconToUse
            TabIcon.ImageColor3 = TabBtn.TextColor3
            TabIcon.ScaleType = Enum.ScaleType.Fit
        end

        -- Tab text label
        local TabLabel = Instance.new("TextLabel")
        TabLabel.Parent = TabContent
        TabLabel.BackgroundTransparency = 1
        TabLabel.Size = UDim2.new(0, 60, 0, 16)
        TabLabel.Text = name
        TabLabel.TextColor3 = TabBtn.TextColor3
        TabLabel.Font = Enum.Font.GothamBold
        TabLabel.TextSize = 11
        TabLabel.TextXAlignment = Enum.TextXAlignment.Center

        -- Tab click handler
        TabBtn.MouseButton1Click:Connect(function()
            for _, p in pairs(Window.Pages:GetChildren()) do 
                if p:IsA("ScrollingFrame") then 
                    TweenService:Create(p, TWEEN_CONFIGS.Fast, {Position = UDim2.new(1, 0, 0, 0)}):Play()
                    task.wait(0.05)
                    p.Visible = false 
                end
            end
            
            for _, t in pairs(Window.TabBar:GetChildren()) do
                if t:IsA("TextButton") then 
                    TweenService:Create(t, TWEEN_CONFIGS.Fast, {TextColor3 = Theme.TextSecondary, BackgroundColor3 = Theme.Surface}):Play()
                    
                    local iconChild = t:FindFirstChild("ImageLabel") or t:FindFirstChildWhichIsA("ImageLabel")
                    if iconChild then
                        TweenService:Create(iconChild, TWEEN_CONFIGS.Fast, {ImageColor3 = Theme.TextSecondary}):Play()
                    end
                    
                    local gradChildren = t:GetChildren()
                    for _, child in pairs(gradChildren) do
                        if child:IsA("UIGradient") then
                            child:Destroy()
                        end
                    end
                    CreateGradient(t, Theme.Surface, Color3.fromRGB(35, 35, 35), 0)
                end
            end
            
            Page.Visible = true
            Page.Position = UDim2.new(0, 0, 0, 0)
            TweenService:Create(TabBtn, TWEEN_CONFIGS.Fast, {TextColor3 = Theme.Text, BackgroundColor3 = Theme.Primary}):Play()
            
            local iconChild = TabBtn:FindFirstChild("ImageLabel") or TabBtn:FindFirstChildWhichIsA("ImageLabel")
            if iconChild then
                TweenService:Create(iconChild, TWEEN_CONFIGS.Fast, {ImageColor3 = Theme.Text}):Play()
            end
            
            local gradChildren = TabBtn:GetChildren()
            for _, child in pairs(gradChildren) do
                if child:IsA("UIGradient") then
                    child:Destroy()
                end
            end
            CreateGradient(TabBtn, Theme.Primary, Theme.PrimaryLight, 0)
        end)

        function Tab:CreateLabel(text)
            local LabelFrame = Instance.new("Frame")
            LabelFrame.Size = UDim2.new(1, 0, 0, 28)
            LabelFrame.BackgroundTransparency = 1
            LabelFrame.Parent = Page

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
        end

        function Tab:CreateToggle(config)
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Size = UDim2.new(1, 0, 0, 38)
            ToggleFrame.BackgroundTransparency = 1
            ToggleFrame.Parent = Page

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

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = TextBtn

            CreateGradient(TextBtn, Color3.fromRGB(22, 22, 22), Color3.fromRGB(28, 28, 28), 0)

            local StatusContainer = Instance.new("Frame")
            StatusContainer.Parent = TextBtn
            StatusContainer.BackgroundColor3 = Theme.Secondary
            StatusContainer.Position = UDim2.new(1, -45, 0.5, -10)
            StatusContainer.Size = UDim2.new(0, 35, 0, 20)
            StatusContainer.BorderSizePixel = 0

            local statusCorner = Instance.new("UICorner")
            statusCorner.CornerRadius = UDim.new(1, 0)
            statusCorner.Parent = StatusContainer

            local StatusCircle = Instance.new("Frame")
            StatusCircle.Parent = StatusContainer
            StatusCircle.BackgroundColor3 = Theme.TextSecondary
            StatusCircle.Position = UDim2.new(0, 2, 0.5, -8)
            StatusCircle.Size = UDim2.new(0, 16, 0, 16)
            StatusCircle.BorderSizePixel = 0

            local circleCorner = Instance.new("UICorner")
            circleCorner.CornerRadius = UDim.new(1, 0)
            circleCorner.Parent = StatusCircle

            local enabled = false

            local function SetState(state)
                enabled = state
                if enabled then
                    TweenService:Create(StatusCircle, TWEEN_CONFIGS.Fast, {Position = UDim2.new(1, -18, 0.5, -8), BackgroundColor3 = Theme.Accent}):Play()
                    TweenService:Create(StatusContainer, TWEEN_CONFIGS.Fast, {BackgroundColor3 = Theme.Primary}):Play()
                else
                    TweenService:Create(StatusCircle, TWEEN_CONFIGS.Fast, {Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = Theme.TextSecondary}):Play()
                    TweenService:Create(StatusContainer, TWEEN_CONFIGS.Fast, {BackgroundColor3 = Theme.Secondary}):Play()
                end
            end

            TextBtn.MouseButton1Click:Connect(function()
                enabled = not enabled
                SetState(enabled)
                if config.Callback then config.Callback(enabled, SetState) end
            end)

            TextBtn.MouseEnter:Connect(function()
                TweenService:Create(TextBtn, TWEEN_CONFIGS.Fast, {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}):Play()
            end)

            TextBtn.MouseLeave:Connect(function()
                TweenService:Create(TextBtn, TWEEN_CONFIGS.Fast, {BackgroundColor3 = Theme.Surface}):Play()
            end)

            return SetState
        end

        function Tab:CreateBind(config)
            local BindFrame = Instance.new("Frame")
            BindFrame.Size = UDim2.new(1, 0, 0, 38)
            BindFrame.BackgroundTransparency = 1
            BindFrame.Parent = Page

            local Container = Instance.new("Frame")
            Container.Size = UDim2.new(1, 0, 1, 0)
            Container.BackgroundColor3 = Theme.Surface
            Container.Parent = BindFrame

            local cCorner = Instance.new("UICorner")
            cCorner.CornerRadius = UDim.new(0, 6)
            cCorner.Parent = Container

            CreateGradient(Container, Color3.fromRGB(22, 22, 22), Color3.fromRGB(28, 28, 28), 0)

            local Label = Instance.new("TextLabel")
            Label.Parent = Container
            Label.Size = UDim2.new(1, -100, 1, 0)
            Label.BackgroundTransparency = 1
            Label.Text = "   " .. config.Name
            Label.TextColor3 = Theme.TextSecondary
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left

            local BindBtn = Instance.new("TextButton")
            BindBtn.Parent = Container
            BindBtn.BackgroundColor3 = Theme.Secondary
            BindBtn.Size = UDim2.new(0, 80, 0, 24)
            BindBtn.Position = UDim2.new(1, -90, 0.5, -12)
            BindBtn.Text = config.Default and tostring(config.Default.Name or config.Default) or "NONE"
            BindBtn.TextColor3 = Theme.Text
            BindBtn.Font = Enum.Font.GothamBold
            BindBtn.TextSize = 11
            BindBtn.BorderSizePixel = 0

            local bCorner = Instance.new("UICorner")
            bCorner.CornerRadius = UDim.new(0, 4)
            bCorner.Parent = BindBtn

            BindBtn.MouseButton1Click:Connect(function()
                BindBtn.Text = "..."
                TweenService:Create(BindBtn, TWEEN_CONFIGS.Fast, {BackgroundColor3 = Theme.Primary}):Play()
                if config.BindTable then config.BindTable.IsBinding = true end
                local conn
                conn = UserInputService.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.Keyboard or i.UserInputType == Enum.UserInputType.MouseButton2 or i.UserInputType == Enum.UserInputType.MouseButton3 or i.UserInputType == Enum.UserInputType.MouseButton4 or i.UserInputType == Enum.UserInputType.MouseButton5 then
                        local key = (i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode or i.UserInputType)
                        if config.BindTable and config.KeyIndex then
                            config.BindTable[config.KeyIndex] = key
                        end
                        BindBtn.Text = tostring(key.Name or key)
                        TweenService:Create(BindBtn, TWEEN_CONFIGS.Fast, {BackgroundColor3 = Theme.Secondary}):Play()
                        if config.BindTable then config.BindTable.IsBinding = false end
                        conn:Disconnect()
                    end
                end)
            end)
        end

        function Tab:CreateButton(config)
            local TextBtn = Instance.new("TextButton")
            TextBtn.Parent = Page
            TextBtn.BackgroundColor3 = Theme.Secondary
            TextBtn.Size = UDim2.new(1, 0, 0, 38)
            TextBtn.Text = config.Name
            TextBtn.TextColor3 = Theme.Text
            TextBtn.Font = Enum.Font.GothamBold
            TextBtn.TextSize = 13
            TextBtn.BorderSizePixel = 0

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = TextBtn

            CreateGradient(TextBtn, Theme.Secondary, Color3.fromRGB(30, 120, 220), 0)

            TextBtn.MouseButton1Down:Connect(function()
                TweenService:Create(TextBtn, TWEEN_CONFIGS.Fast, {BackgroundColor3 = Theme.Primary}):Play()
            end)
            
            TextBtn.MouseButton1Up:Connect(function()
                TweenService:Create(TextBtn, TWEEN_CONFIGS.Fast, {BackgroundColor3 = Theme.Secondary}):Play()
            end)
            
            TextBtn.MouseEnter:Connect(function()
                TweenService:Create(TextBtn, TWEEN_CONFIGS.Fast, {BackgroundColor3 = Color3.fromRGB(20, 120, 220)}):Play()
            end)

            TextBtn.MouseLeave:Connect(function()
                TweenService:Create(TextBtn, TWEEN_CONFIGS.Fast, {BackgroundColor3 = Theme.Secondary}):Play()
            end)
            
            TextBtn.MouseButton1Click:Connect(function()
                if config.Callback then config.Callback() end
            end)
        end

        function Tab:CreateColoredButton(config)
            local TextBtn = Instance.new("TextButton")
            TextBtn.Parent = Page
            TextBtn.BackgroundColor3 = config.Color or Theme.Primary
            TextBtn.Size = UDim2.new(1, 0, 0, 38)
            TextBtn.Text = config.Name
            TextBtn.TextColor3 = Theme.Text
            TextBtn.Font = Enum.Font.GothamBold
            TextBtn.TextSize = 13
            TextBtn.BorderSizePixel = 0

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = TextBtn

            TextBtn.MouseButton1Down:Connect(function()
                local r = math.min(config.Color.R * 1.3, 1)
                local g = math.min(config.Color.G * 1.3, 1)
                local b = math.min(config.Color.B * 1.3, 1)
                TweenService:Create(TextBtn, TWEEN_CONFIGS.Fast, {BackgroundColor3 = Color3.new(r, g, b)}):Play()
            end)
            
            TextBtn.MouseButton1Up:Connect(function()
                TweenService:Create(TextBtn, TWEEN_CONFIGS.Fast, {BackgroundColor3 = config.Color or Theme.Primary}):Play()
            end)
            
            TextBtn.MouseButton1Click:Connect(function()
                if config.Callback then config.Callback() end
            end)
        end

        function Tab:CreateSlider(config)
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Size = UDim2.new(1, 0, 0, 55)
            SliderFrame.BackgroundColor3 = Theme.Surface
            SliderFrame.Parent = Page

            local sCorner = Instance.new("UICorner")
            sCorner.CornerRadius = UDim.new(0, 6)
            sCorner.Parent = SliderFrame

            CreateGradient(SliderFrame, Color3.fromRGB(22, 22, 22), Color3.fromRGB(28, 28, 28), 0)

            local Label = Instance.new("TextLabel")
            Label.Parent = SliderFrame
            Label.Text = "   " .. config.Name .. " : " .. config.Default
            Label.TextColor3 = Theme.TextSecondary
            Label.Size = UDim2.new(1, 0, 0, 25)
            Label.BackgroundTransparency = 1
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 12
            Label.TextXAlignment = Enum.TextXAlignment.Left

            local SliderBack = Instance.new("Frame")
            SliderBack.Parent = SliderFrame
            SliderBack.BackgroundColor3 = Theme.Secondary
            SliderBack.Position = UDim2.new(0, 10, 0, 30)
            SliderBack.Size = UDim2.new(1, -20, 0, 8)
            SliderBack.BorderSizePixel = 0

            local sbCorner = Instance.new("UICorner")
            sbCorner.CornerRadius = UDim.new(1, 0)
            sbCorner.Parent = SliderBack

            local SliderFill = Instance.new("Frame")
            SliderFill.Parent = SliderBack
            SliderFill.BackgroundColor3 = Theme.Primary
            SliderFill.Size = UDim2.new((config.Default - config.Min) / (config.Max - config.Min), 0, 1, 0)
            SliderFill.BorderSizePixel = 0

            local sfCorner = Instance.new("UICorner")
            sfCorner.CornerRadius = UDim.new(1, 0)
            sfCorner.Parent = SliderFill

            CreateGradient(SliderFill, Theme.Primary, Theme.PrimaryLight, 0)

            -- Slider thumb/ball
            local SliderBall = Instance.new("Frame")
            SliderBall.Parent = SliderBack
            SliderBall.BackgroundColor3 = Theme.Accent
            SliderBall.Size = UDim2.new(0, 16, 0, 16)
            SliderBall.Position = UDim2.new((config.Default - config.Min) / (config.Max - config.Min), -8, 0.5, -8)
            SliderBall.BorderSizePixel = 0
            SliderBall.ZIndex = 10

            local ballCorner = Instance.new("UICorner")
            ballCorner.CornerRadius = UDim.new(1, 0)
            ballCorner.Parent = SliderBall

            local sliding = false
            local function update(input)
                local pos = math.clamp((input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
                SliderFill.Size = UDim2.new(pos, 0, 1, 0)
                SliderBall.Position = UDim2.new(pos, -8, 0.5, -8)
                local val = math.floor(((config.Max - config.Min) * pos) + config.Min)
                Label.Text = "   " .. config.Name .. " : " .. val
                if config.Callback then config.Callback(val) end
            end
            
            SliderBack.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
                    sliding = true
                    TweenService:Create(SliderBall, TWEEN_CONFIGS.Fast, {Size = UDim2.new(0, 20, 0, 20), Position = SliderBall.Position + UDim2.new(0, -2, 0, -2)}):Play()
                    update(input) 
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then 
                    update(input) 
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
                    sliding = false
                    TweenService:Create(SliderBall, TWEEN_CONFIGS.Fast, {Size = UDim2.new(0, 16, 0, 16), Position = SliderBall.Position + UDim2.new(0, 2, 0, 2)}):Play()
                end
            end)
        end

        function Tab:CreateDropdown(config)
            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Size = UDim2.new(1, 0, 0, 38)
            DropdownFrame.BackgroundTransparency = 1
            DropdownFrame.Parent = Page

            local MainBtn = Instance.new("TextButton")
            MainBtn.Parent = DropdownFrame
            MainBtn.BackgroundColor3 = Theme.Surface
            MainBtn.Size = UDim2.new(1, 0, 0, 38)
            MainBtn.Text = "   " .. config.Name .. " : " .. (config.Default or "Select")
            MainBtn.TextColor3 = Theme.TextSecondary
            MainBtn.Font = Enum.Font.Gotham
            MainBtn.TextSize = 13
            MainBtn.TextXAlignment = Enum.TextXAlignment.Left
            MainBtn.BorderSizePixel = 0

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = MainBtn

            CreateGradient(MainBtn, Color3.fromRGB(22, 22, 22), Color3.fromRGB(28, 28, 28), 0)

            local isOpen = false
            local DropdownMenu = Instance.new("Frame")
            DropdownMenu.Parent = DropdownFrame
            DropdownMenu.BackgroundColor3 = Theme.Surface
            DropdownMenu.Position = UDim2.new(0, 0, 0, 38)
            DropdownMenu.Size = UDim2.new(1, 0, 0, 0)
            DropdownMenu.BorderSizePixel = 0
            DropdownMenu.ClipsDescendants = true
            DropdownMenu.ZIndex = 50

            local menuCorner = Instance.new("UICorner")
            menuCorner.CornerRadius = UDim.new(0, 6)
            menuCorner.Parent = DropdownMenu

            local MenuLayout = Instance.new("UIListLayout")
            MenuLayout.Parent = DropdownMenu
            MenuLayout.Padding = UDim.new(0, 2)

            MainBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    local itemHeight = 30 * #config.Items
                    TweenService:Create(DropdownMenu, TWEEN_CONFIGS.Normal, {Size = UDim2.new(1, 0, 0, itemHeight)}):Play()
                else
                    TweenService:Create(DropdownMenu, TWEEN_CONFIGS.Normal, {Size = UDim2.new(1, 0, 0, 0)}):Play()
                end
            end)

            for _, item in pairs(config.Items) do
                local ItemBtn = Instance.new("TextButton")
                ItemBtn.Parent = DropdownMenu
                ItemBtn.BackgroundColor3 = Theme.Secondary
                ItemBtn.Size = UDim2.new(1, -4, 0, 30)
                ItemBtn.Text = item
                ItemBtn.TextColor3 = Theme.TextSecondary
                ItemBtn.Font = Enum.Font.Gotham
                ItemBtn.TextSize = 12
                ItemBtn.BorderSizePixel = 0

                local itemCorner = Instance.new("UICorner")
                itemCorner.CornerRadius = UDim.new(0, 4)
                itemCorner.Parent = ItemBtn

                ItemBtn.MouseEnter:Connect(function()
                    TweenService:Create(ItemBtn, TWEEN_CONFIGS.Fast, {BackgroundColor3 = Theme.Primary}):Play()
                end)

                ItemBtn.MouseLeave:Connect(function()
                    TweenService:Create(ItemBtn, TWEEN_CONFIGS.Fast, {BackgroundColor3 = Theme.Secondary}):Play()
                end)

                ItemBtn.MouseButton1Click:Connect(function()
                    MainBtn.Text = "   " .. config.Name .. " : " .. item
                    isOpen = false
                    TweenService:Create(DropdownMenu, TWEEN_CONFIGS.Normal, {Size = UDim2.new(1, 0, 0, 0)}):Play()
                    if config.Callback then config.Callback(item) end
                end)
            end
        end

        function Tab:CreateTextBox(config)
            local TextBoxFrame = Instance.new("Frame")
            TextBoxFrame.Size = UDim2.new(1, 0, 0, 38)
            TextBoxFrame.BackgroundTransparency = 1
            TextBoxFrame.Parent = Page

            local Container = Instance.new("Frame")
            Container.Size = UDim2.new(1, 0, 1, 0)
            Container.BackgroundColor3 = Theme.Surface
            Container.Parent = TextBoxFrame

            local cCorner = Instance.new("UICorner")
            cCorner.CornerRadius = UDim.new(0, 6)
            cCorner.Parent = Container

            CreateGradient(Container, Color3.fromRGB(22, 22, 22), Color3.fromRGB(28, 28, 28), 0)

            local TextBox = Instance.new("TextBox")
            TextBox.Parent = Container
            TextBox.Size = UDim2.new(1, -20, 1, 0)
            TextBox.Position = UDim2.new(0, 10, 0, 0)
            TextBox.BackgroundTransparency = 1
            TextBox.Text = config.Default or ""
            TextBox.PlaceholderText = config.Name or "Enter text..."
            TextBox.TextColor3 = Theme.Text
            TextBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
            TextBox.Font = Enum.Font.Gotham
            TextBox.TextSize = 13
            TextBox.TextXAlignment = Enum.TextXAlignment.Left
            TextBox.ClearTextOnFocus = false

            TextBox.FocusLost:Connect(function()
                if config.Callback then
                    config.Callback(TextBox.Text)
                end
            end)
        end

        function Tab:CreateButtonGroup(config)
            local GroupFrame = Instance.new("Frame")
            GroupFrame.Size = UDim2.new(1, 0, 0, 38)
            GroupFrame.BackgroundTransparency = 1
            GroupFrame.Parent = Page

            local GroupLayout = Instance.new("UIListLayout")
            GroupLayout.Parent = GroupFrame
            GroupLayout.FillDirection = Enum.FillDirection.Horizontal
            GroupLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            GroupLayout.Padding = UDim.new(0, 5)

            for _, btnConfig in pairs(config.Buttons) do
                local Btn = Instance.new("TextButton")
                Btn.Parent = GroupFrame
                Btn.BackgroundColor3 = Theme.Secondary
                Btn.Size = UDim2.new(0, 60, 0, 38)
                Btn.Text = btnConfig.Name
                Btn.TextColor3 = Theme.Text
                Btn.Font = Enum.Font.GothamBold
                Btn.TextSize = 11
                Btn.BorderSizePixel = 0

                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(0, 6)
                btnCorner.Parent = Btn

                Btn.MouseButton1Down:Connect(function()
                    TweenService:Create(Btn, TWEEN_CONFIGS.Fast, {BackgroundColor3 = Theme.Primary}):Play()
                end)
                
                Btn.MouseButton1Up:Connect(function()
                    TweenService:Create(Btn, TWEEN_CONFIGS.Fast, {BackgroundColor3 = Theme.Secondary}):Play()
                end)

                Btn.MouseButton1Click:Connect(function()
                    if btnConfig.Callback then btnConfig.Callback() end
                end)
            end
        end

        function Tab:CreateProgressBar(config)
            local ProgressFrame = Instance.new("Frame")
            ProgressFrame.Size = UDim2.new(1, 0, 0, 40)
            ProgressFrame.BackgroundColor3 = Theme.Surface
            ProgressFrame.Parent = Page

            local pCorner = Instance.new("UICorner")
            pCorner.CornerRadius = UDim.new(0, 6)
            pCorner.Parent = ProgressFrame

            CreateGradient(ProgressFrame, Color3.fromRGB(22, 22, 22), Color3.fromRGB(28, 28, 28), 0)

            local Label = Instance.new("TextLabel")
            Label.Parent = ProgressFrame
            Label.Size = UDim2.new(1, 0, 0, 18)
            Label.BackgroundTransparency = 1
            Label.Text = config.Name .. " : 0%"
            Label.TextColor3 = Theme.TextSecondary
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 12

            local ProgressBack = Instance.new("Frame")
            ProgressBack.Parent = ProgressFrame
            ProgressBack.BackgroundColor3 = Theme.Secondary
            ProgressBack.Position = UDim2.new(0, 10, 0, 20)
            ProgressBack.Size = UDim2.new(1, -20, 0, 12)
            ProgressBack.BorderSizePixel = 0

            local pbCorner = Instance.new("UICorner")
            pbCorner.CornerRadius = UDim.new(1, 0)
            pbCorner.Parent = ProgressBack

            local ProgressFill = Instance.new("Frame")
            ProgressFill.Parent = ProgressBack
            ProgressFill.BackgroundColor3 = Theme.Primary
            ProgressFill.Size = UDim2.new(0, 0, 1, 0)
            ProgressFill.BorderSizePixel = 0

            local pfCorner = Instance.new("UICorner")
            pfCorner.CornerRadius = UDim.new(1, 0)
            pfCorner.Parent = ProgressFill

            CreateGradient(ProgressFill, Theme.Primary, Theme.PrimaryLight, 0)

            local function SetProgress(value)
                local clampedValue = math.clamp(value, 0, 100)
                TweenService:Create(ProgressFill, TWEEN_CONFIGS.Normal, {Size = UDim2.new(clampedValue / 100, 0, 1, 0)}):Play()
                Label.Text = config.Name .. " : " .. math.floor(clampedValue) .. "%"
            end

            return SetProgress
        end

        function Tab:CreateSwitch(config)
            local SwitchFrame = Instance.new("Frame")
            SwitchFrame.Size = UDim2.new(1, 0, 0, 38)
            SwitchFrame.BackgroundTransparency = 1
            SwitchFrame.Parent = Page

            local TextLabel = Instance.new("TextLabel")
            TextLabel.Parent = SwitchFrame
            TextLabel.Size = UDim2.new(0.6, 0, 1, 0)
            TextLabel.BackgroundTransparency = 1
            TextLabel.Text = config.Name
            TextLabel.TextColor3 = Theme.TextSecondary
            TextLabel.Font = Enum.Font.Gotham
            TextLabel.TextSize = 13
            TextLabel.TextXAlignment = Enum.TextXAlignment.Left

            local SwitchContainer = Instance.new("Frame")
            SwitchContainer.Parent = SwitchFrame
            SwitchContainer.BackgroundColor3 = Theme.Secondary
            SwitchContainer.Position = UDim2.new(0.65, 0, 0.2, 0)
            SwitchContainer.Size = UDim2.new(0.3, 0, 0.6, 0)
            SwitchContainer.BorderSizePixel = 0

            local sCorner = Instance.new("UICorner")
            sCorner.CornerRadius = UDim.new(1, 0)
            sCorner.Parent = SwitchContainer

            local SwitchCircle = Instance.new("Frame")
            SwitchCircle.Parent = SwitchContainer
            SwitchCircle.BackgroundColor3 = Theme.TextSecondary
            SwitchCircle.Position = UDim2.new(0.05, 0, 0.1, 0)
            SwitchCircle.Size = UDim2.new(0.4, 0, 0.8, 0)
            SwitchCircle.BorderSizePixel = 0

            local circleCorner = Instance.new("UICorner")
            circleCorner.CornerRadius = UDim.new(1, 0)
            circleCorner.Parent = SwitchCircle

            local enabled = config.Default or false
            local clickable = Instance.new("TextButton")
            clickable.Parent = SwitchFrame
            clickable.Size = UDim2.new(1, 0, 1, 0)
            clickable.BackgroundTransparency = 1
            clickable.Text = ""

            local function UpdateSwitch()
                if enabled then
                    TweenService:Create(SwitchCircle, TWEEN_CONFIGS.Fast, {Position = UDim2.new(0.55, 0, 0.1, 0), BackgroundColor3 = Theme.Accent}):Play()
                    TweenService:Create(SwitchContainer, TWEEN_CONFIGS.Fast, {BackgroundColor3 = Theme.Primary}):Play()
                else
                    TweenService:Create(SwitchCircle, TWEEN_CONFIGS.Fast, {Position = UDim2.new(0.05, 0, 0.1, 0), BackgroundColor3 = Theme.TextSecondary}):Play()
                    TweenService:Create(SwitchContainer, TWEEN_CONFIGS.Fast, {BackgroundColor3 = Theme.Secondary}):Play()
                end
            end

            clickable.MouseButton1Click:Connect(function()
                enabled = not enabled
                UpdateSwitch()
                if config.Callback then config.Callback(enabled) end
            end)

            UpdateSwitch()
            return function(state) enabled = state UpdateSwitch() end
        end

        -- Advanced: Color Palette Picker
        function Tab:CreateColorPalette(config)
            local PaletteFrame = Instance.new("Frame")
            PaletteFrame.Size = UDim2.new(1, 0, 0, 210)
            PaletteFrame.BackgroundColor3 = Theme.Surface
            PaletteFrame.Parent = Page

            local pCorner = Instance.new("UICorner")
            pCorner.CornerRadius = UDim.new(0, 6)
            pCorner.Parent = PaletteFrame

            CreateGradient(PaletteFrame, Color3.fromRGB(22, 22, 22), Color3.fromRGB(28, 28, 28), 0)

            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Parent = PaletteFrame
            TitleLabel.Size = UDim2.new(1, 0, 0, 20)
            TitleLabel.Position = UDim2.new(0, 0, 0, 5)
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.Text = config.Name or "Color Palette"
            TitleLabel.TextColor3 = Theme.TextSecondary
            TitleLabel.Font = Enum.Font.GothamBold
            TitleLabel.TextSize = 12

            local PaletteGrid = Instance.new("Frame")
            PaletteGrid.Parent = PaletteFrame
            PaletteGrid.BackgroundTransparency = 1
            PaletteGrid.Size = UDim2.new(1, -20, 1, -35)
            PaletteGrid.Position = UDim2.new(0, 10, 0, 25)

            local GridLayout = Instance.new("UIGridLayout")
            GridLayout.Parent = PaletteGrid
            GridLayout.CellSize = UDim2.new(0, 50, 0, 50)
            GridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
            GridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            GridLayout.VerticalAlignment = Enum.VerticalAlignment.Top

            local selectedColor = config.Default or Theme.Primary
            local presets = config.Presets or {
                Color3.fromRGB(30, 144, 255),    -- Blue
                Color3.fromRGB(255, 80, 80),     -- Red
                Color3.fromRGB(76, 175, 80),     -- Green
                Color3.fromRGB(255, 152, 0),     -- Orange
                Color3.fromRGB(156, 39, 176),    -- Purple
                Color3.fromRGB(0, 188, 212),     -- Cyan
                Color3.fromRGB(244, 67, 54),     -- Deep Red
                Color3.fromRGB(233, 30, 99),     -- Pink
            }

            for _, colorVal in pairs(presets) do
                local ColorBtn = Instance.new("TextButton")
                ColorBtn.Parent = PaletteGrid
                ColorBtn.BackgroundColor3 = colorVal
                ColorBtn.Size = UDim2.new(0, 50, 0, 50)
                ColorBtn.Text = ""
                ColorBtn.BorderSizePixel = 0

                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(0, 6)
                btnCorner.Parent = ColorBtn

                local btnStroke = Instance.new("UIStroke")
                btnStroke.Thickness = 2
                btnStroke.Color = colorVal
                btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                btnStroke.Transparency = 0.5
                btnStroke.Parent = ColorBtn

                ColorBtn.MouseEnter:Connect(function()
                    TweenService:Create(ColorBtn, TWEEN_CONFIGS.Fast, {BackgroundColor3 = colorVal}):Play()
                    TweenService:Create(btnStroke, TWEEN_CONFIGS.Fast, {Transparency = 0}):Play()
                end)

                ColorBtn.MouseLeave:Connect(function()
                    TweenService:Create(btnStroke, TWEEN_CONFIGS.Fast, {Transparency = 0.5}):Play()
                end)

                ColorBtn.MouseButton1Click:Connect(function()
                    selectedColor = colorVal
                    if config.Callback then
                        config.Callback(colorVal)
                    end
                    
                    -- Update all selected indicators
                    for _, child in pairs(PaletteGrid:GetChildren()) do
                        if child:IsA("TextButton") then
                            local stroke = child:FindFirstChildOfClass("UIStroke")
                            if stroke then
                                if child.BackgroundColor3 == selectedColor then
                                    TweenService:Create(stroke, TWEEN_CONFIGS.Fast, {Transparency = 0, Thickness = 3}):Play()
                                else
                                    TweenService:Create(stroke, TWEEN_CONFIGS.Fast, {Transparency = 0.5, Thickness = 2}):Play()
                                end
                            end
                        end
                    end
                end)
            end
        end

        return Tab
    end

    -- Auto-create Settings tab with enhanced styling
    local SettingsTab = Window:CreateTab("Settings", ICONS.Settings)

    SettingsTab:CreateLabel("── UI SETTINGS ──")

    SettingsTab:CreateSlider({
        Name = "Window Width",
        Min = 300,
        Max = 800,
        Default = 500,
        Callback = function(value)
            Main.Size = UDim2.new(0, value, 0, Main.Size.Y.Offset)
            Main.Position = UDim2.new(0.5, -value/2, Main.Position.Y.Scale, Main.Position.Y.Offset)
        end
    })

    SettingsTab:CreateSlider({
        Name = "Window Height",
        Min = 200,
        Max = 700,
        Default = 350,
        Callback = function(value)
            Main.Size = UDim2.new(0, Main.Size.X.Offset, 0, value)
        end
    })

    SettingsTab:CreateSlider({
        Name = "Corner Radius",
        Min = 0,
        Max = 20,
        Default = 8,
        Callback = function(value)
            Theme.CornerRadius = value
            MainCorner.CornerRadius = UDim.new(0, value)
            TopCorner.CornerRadius = UDim.new(0, value)
            for _, btn in pairs(TabBar:GetChildren()) do
                if btn:IsA("TextButton") then
                    local corner = btn:FindFirstChild("UICorner")
                    if corner then corner.CornerRadius = UDim.new(0, 6) end
                end
            end
        end
    })

    SettingsTab:CreateSlider({
        Name = "UI Transparency",
        Min = 0,
        Max = 50,
        Default = 0,
        Callback = function(value)
            Theme.Transparency = value / 100
            Main.BackgroundTransparency = value / 100
        end
    })

    SettingsTab:CreateLabel("")
    SettingsTab:CreateLabel("── COLOR PALETTE ──")

    SettingsTab:CreateColorPalette({
        Name = "Quick Colors",
        Default = Theme.Primary,
        Presets = {
            Color3.fromRGB(30, 144, 255),
            Color3.fromRGB(255, 80, 80),
            Color3.fromRGB(76, 175, 80),
            Color3.fromRGB(255, 152, 0),
            Color3.fromRGB(156, 39, 176),
            Color3.fromRGB(0, 188, 212),
            Color3.fromRGB(244, 67, 54),
            Color3.fromRGB(233, 30, 99),
        },
        Callback = function(color)
            Theme.Primary = color
            Theme.PrimaryLight = Color3.new(
                math.min(color.R * 1.3, 1),
                math.min(color.G * 1.3, 1),
                math.min(color.B * 1.3, 1)
            )
            MainStroke.Color = Theme.Primary
            
            -- Update active tab colors
            for _, btn in pairs(TabBar:GetChildren()) do
                if btn:IsA("TextButton") and btn.BackgroundColor3 == Theme.Primary then
                    btn.BackgroundColor3 = Theme.Primary
                end
            end
        end
    })

    SettingsTab:CreateLabel("")
    SettingsTab:CreateLabel("── ADVANCED COLORS ──")

    SettingsTab:CreateTextBox({
        Name = "Primary Color (Hex)",
        Default = "1E90FF",
        Callback = function(value)
            if #value == 6 then
                local r = tonumber(value:sub(1, 2), 16)
                local g = tonumber(value:sub(3, 4), 16)
                local b = tonumber(value:sub(5, 6), 16)
                if r and g and b then
                    Theme.Primary = Color3.fromRGB(r, g, b)
                    MainStroke.Color = Theme.Primary
                end
            end
        end
    })

    SettingsTab:CreateTextBox({
        Name = "Secondary Color (Hex)",
        Default = "0A64C8",
        Callback = function(value)
            if #value == 6 then
                local r = tonumber(value:sub(1, 2), 16)
                local g = tonumber(value:sub(3, 4), 16)
                local b = tonumber(value:sub(5, 6), 16)
                if r and g and b then
                    Theme.Secondary = Color3.fromRGB(r, g, b)
                    TopBar.BackgroundColor3 = Theme.Secondary
                end
            end
        end
    })

    SettingsTab:CreateTextBox({
        Name = "Background Color (Hex)",
        Default = "0C0C0C",
        Callback = function(value)
            if #value == 6 then
                local r = tonumber(value:sub(1, 2), 16)
                local g = tonumber(value:sub(3, 4), 16)
                local b = tonumber(value:sub(5, 6), 16)
                if r and g and b then
                    Theme.Background = Color3.fromRGB(r, g, b)
                    Main.BackgroundColor3 = Theme.Background
                end
            end
        end
    })

    SettingsTab:CreateLabel("")
    SettingsTab:CreateButton({
        Name = "Reset to Default",
        Callback = function()
            Theme.Primary = Color3.fromRGB(30, 144, 255)
            Theme.Secondary = Color3.fromRGB(10, 100, 200)
            Theme.Background = Color3.fromRGB(12, 12, 12)
            Theme.Transparency = 0
            Theme.CornerRadius = 8
            
            Main.BackgroundColor3 = Theme.Background
            Main.BackgroundTransparency = 0
            MainCorner.CornerRadius = UDim.new(0, 8)
            TopBar.BackgroundColor3 = Theme.Secondary
            MainStroke.Color = Theme.Primary
            
            Window:Notify("Theme reset to default", 2, "success")
        end
    })

    return Window
end

return UI
