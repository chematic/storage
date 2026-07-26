local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local UI = {}

-- Icon IDs
local ICONS = {
    Close = 82404346839314,
    Minimize = 85022922514331,
    Settings = 7059346373,
    Default = 136443043095009
}

-- Premium animation presets
local TWEEN_CONFIGS = {
    Instant = TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Normal = TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
    Smooth = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Slow = TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut),
    ExtraSmooth = TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
    WindowOpen = TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
}

-- Theme system with presets
local THEMES = {
    Dark = {
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
        CornerRadius = 16,
        StrokeThickness = 1.5
    },
    Light = {
        Primary = Color3.fromRGB(59, 130, 246),
        PrimaryLight = Color3.fromRGB(96, 165, 250),
        Secondary = Color3.fromRGB(37, 99, 235),
        SecondaryLight = Color3.fromRGB(66, 133, 244),
        Background = Color3.fromRGB(245, 245, 245),
        Surface = Color3.fromRGB(255, 255, 255),
        SurfaceLight = Color3.fromRGB(240, 240, 240),
        Text = Color3.fromRGB(30, 30, 30),
        TextSecondary = Color3.fromRGB(100, 100, 100),
        Accent = Color3.fromRGB(96, 165, 250),
        Success = Color3.fromRGB(34, 197, 94),
        Warning = Color3.fromRGB(251, 146, 60),
        Error = Color3.fromRGB(239, 68, 68),
        CornerRadius = 16,
        StrokeThickness = 1.5
    },
    Blue = {
        Primary = Color3.fromRGB(59, 130, 246),
        PrimaryLight = Color3.fromRGB(96, 165, 250),
        Secondary = Color3.fromRGB(37, 99, 235),
        SecondaryLight = Color3.fromRGB(66, 133, 244),
        Background = Color3.fromRGB(15, 23, 42),
        Surface = Color3.fromRGB(30, 41, 59),
        SurfaceLight = Color3.fromRGB(51, 65, 85),
        Text = Color3.fromRGB(248, 250, 252),
        TextSecondary = Color3.fromRGB(203, 213, 225),
        Accent = Color3.fromRGB(96, 165, 250),
        Success = Color3.fromRGB(34, 197, 94),
        Warning = Color3.fromRGB(251, 146, 60),
        Error = Color3.fromRGB(239, 68, 68),
        CornerRadius = 16,
        StrokeThickness = 1.5
    },
    Purple = {
        Primary = Color3.fromRGB(168, 85, 247),
        PrimaryLight = Color3.fromRGB(196, 121, 254),
        Secondary = Color3.fromRGB(147, 51, 234),
        SecondaryLight = Color3.fromRGB(168, 85, 247),
        Background = Color3.fromRGB(17, 7, 27),
        Surface = Color3.fromRGB(32, 14, 48),
        SurfaceLight = Color3.fromRGB(59, 27, 83),
        Text = Color3.fromRGB(250, 245, 255),
        TextSecondary = Color3.fromRGB(216, 180, 254),
        Accent = Color3.fromRGB(196, 121, 254),
        Success = Color3.fromRGB(34, 197, 94),
        Warning = Color3.fromRGB(251, 146, 60),
        Error = Color3.fromRGB(239, 68, 68),
        CornerRadius = 16,
        StrokeThickness = 1.5
    },
    Red = {
        Primary = Color3.fromRGB(239, 68, 68),
        PrimaryLight = Color3.fromRGB(252, 91, 91),
        Secondary = Color3.fromRGB(220, 38, 38),
        SecondaryLight = Color3.fromRGB(239, 68, 68),
        Background = Color3.fromRGB(20, 8, 8),
        Surface = Color3.fromRGB(37, 14, 14),
        SurfaceLight = Color3.fromRGB(65, 25, 25),
        Text = Color3.fromRGB(254, 242, 242),
        TextSecondary = Color3.fromRGB(252, 165, 165),
        Accent = Color3.fromRGB(252, 91, 91),
        Success = Color3.fromRGB(34, 197, 94),
        Warning = Color3.fromRGB(251, 146, 60),
        Error = Color3.fromRGB(239, 68, 68),
        CornerRadius = 16,
        StrokeThickness = 1.5
    }
}

-- Utility functions
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

local function GetResolutionScale()
    local screenSize = LocalPlayer:GetMouse().Icon or "rbxasset://textures/Cursor.png"
    local vpSize = LocalPlayer.PlayerGui.AbsoluteSize
    if vpSize.X <= 400 then return 0.8 end
    if vpSize.X <= 600 then return 0.9 end
    return 1
end

-- Create window with premium UI
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

    -- Initialize theme
    local currentThemeName = config.Theme or "Dark"
    local Theme = table.clone(THEMES[currentThemeName])
    Window.Theme = Theme
    Window.Tweens = {}
    Window.Connections = {}

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
            if NotifFrame then NotifFrame:Destroy() end
        end)
    end

    -- Smooth drag system with inertia
    local function MakeDraggable(topbarobject, object)
        local dragging = false
        local dragStart = Vector2.new()
        local frameStart = UDim2.new()
        local velocity = Vector2.new()
        local lastPos = Vector2.new()
        
        local dragConnection, updateConnection, endConnection
        
        topbarobject.InputBegan:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not dragging then
                dragging = true
                dragStart = input.Position
                frameStart = object.Position
                lastPos = input.Position
                
                -- Kill existing velocity
                if updateConnection then updateConnection:Disconnect() end
                
                updateConnection = UserInputService.InputChanged:Connect(function(moveInput)
                    if dragging and (moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch) then
                        local delta = moveInput.Position - dragStart
                        velocity = moveInput.Position - lastPos
                        lastPos = moveInput.Position
                        
                        object.Position = UDim2.new(
                            frameStart.X.Scale, 
                            math.clamp(frameStart.X.Offset + delta.X, -object.AbsoluteSize.X + 50, ScreenGui.AbsoluteSize.X - 50),
                            frameStart.Y.Scale, 
                            math.clamp(frameStart.Y.Offset + delta.Y, 0, ScreenGui.AbsoluteSize.Y - 50)
                        )
                    end
                end)
            end
        end)
        
        topbarobject.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
                if updateConnection then updateConnection:Disconnect() end
                
                -- Apply inertia
                local inertiaVelocity = velocity * 0.5
                if math.abs(inertiaVelocity.X) > 0.1 or math.abs(inertiaVelocity.Y) > 0.1 then
                    for i = 1, 10 do
                        inertiaVelocity = inertiaVelocity * 0.85
                        local newPos = UDim2.new(
                            object.Position.X.Scale,
                            math.clamp(object.Position.X.Offset + inertiaVelocity.X, -object.AbsoluteSize.X + 50, ScreenGui.AbsoluteSize.X - 50),
                            object.Position.Y.Scale,
                            math.clamp(object.Position.Y.Offset + inertiaVelocity.Y, 0, ScreenGui.AbsoluteSize.Y - 50)
                        )
                        task.wait(0.01)
                        if not dragging then
                            object.Position = newPos
                        end
                    end
                end
            end
        end)
        
        table.insert(Window.Connections, {updateConnection, endConnection})
    end

    -- Resize system (Windows-like)
    local function MakeResizable(mainFrame, minSize, maxSize)
        local resizing = false
        local resizeDir = ""
        local dragStart = Vector2.new()
        local frameSizeStart = Vector2.new()
        local framePos = UDim2.new()
        
        local function CreateResizeHandle(name, cursorPos, sizeFunc)
            local handle = Instance.new("Frame")
            handle.Name = name
            handle.Parent = mainFrame
            handle.BackgroundTransparency = 1
            handle.ZIndex = 15
            handle.Size = UDim2.new(0, 10, 0, 10)
            handle.Position = sizeFunc()
            
            handle.MouseEnter:Connect(function()
                if cursorPos == "corner_tl" or cursorPos == "corner_br" then
                    handle.Cursor = "ResizeNWSE"
                elseif cursorPos == "corner_tr" or cursorPos == "corner_bl" then
                    handle.Cursor = "ResizeNESW"
                elseif cursorPos:find("top") or cursorPos:find("bottom") then
                    handle.Cursor = "ResizeNS"
                else
                    handle.Cursor = "ResizeEW"
                end
            end)
            
            handle.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    resizing = true
                    resizeDir = cursorPos
                    dragStart = input.Position
                    frameSizeStart = Vector2.new(mainFrame.AbsoluteSize.X, mainFrame.AbsoluteSize.Y)
                    framePos = mainFrame.Position
                end
            end)
        end
        
        -- Create all resize handles
        CreateResizeHandle("TL", "corner_tl", function() return UDim2.new(0, -5, 0, -5) end)
        CreateResizeHandle("TR", "corner_tr", function() return UDim2.new(1, -5, 0, -5) end)
        CreateResizeHandle("BL", "corner_bl", function() return UDim2.new(0, -5, 1, -5) end)
        CreateResizeHandle("BR", "corner_br", function() return UDim2.new(1, -5, 1, -5) end)
        CreateResizeHandle("Top", "top", function() return UDim2.new(0.5, -25, 0, -5) end)
        CreateResizeHandle("Bottom", "bottom", function() return UDim2.new(0.5, -25, 1, -5) end)
        CreateResizeHandle("Left", "left", function() return UDim2.new(0, -5, 0.5, -25) end)
        CreateResizeHandle("Right", "right", function() return UDim2.new(1, -5, 0.5, -25) end)
        
        UserInputService.InputChanged:Connect(function(input)
            if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                local newSize = Vector2.new(frameSizeStart.X, frameSizeStart.Y)
                local newPos = framePos
                
                -- Calculate new size and position based on resize direction
                if resizeDir:find("right") then
                    newSize = Vector2.new(math.clamp(frameSizeStart.X + delta.X, minSize.X, maxSize.X), newSize.Y)
                end
                if resizeDir:find("left") then
                    newSize = Vector2.new(math.clamp(frameSizeStart.X - delta.X, minSize.X, maxSize.X), newSize.Y)
                    newPos = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset)
                end
                if resizeDir:find("bottom") then
                    newSize = Vector2.new(newSize.X, math.clamp(frameSizeStart.Y + delta.Y, minSize.Y, maxSize.Y))
                end
                if resizeDir:find("top") then
                    newSize = Vector2.new(newSize.X, math.clamp(frameSizeStart.Y - delta.Y, minSize.Y, maxSize.Y))
                    newPos = UDim2.new(framePos.X.Scale, framePos.X.Offset, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
                end
                
                mainFrame.Size = UDim2.new(0, newSize.X, 0, newSize.Y)
                mainFrame.Position = newPos
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = false
                resizeDir = ""
            end
        end)
    end

    -- Main window frame with animation
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Parent = ScreenGui
    Main.BackgroundColor3 = Theme.Background
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, -250, 0.5, -175)
    Main.Size = UDim2.new(0, 500, 0, 350)
    Main.ClipsDescendants = true

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, Theme.CornerRadius)
    MainCorner.Parent = Main

    CreateGradient(Main, Color3.fromRGB(15, 15, 15), Color3.fromRGB(25, 25, 25), 45)

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Thickness = Theme.StrokeThickness
    MainStroke.Color = Theme.Secondary
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainStroke.Transparency = 0.5
    MainStroke.Parent = Main

    -- Window open animation
    Main.Size = UDim2.new(0, 0, 0, 0)
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    TweenService:Create(Main, TWEEN_CONFIGS.WindowOpen, {
        Size = UDim2.new(0, 500, 0, 350),
        Position = UDim2.new(0.5, -250, 0.5, -175)
    }):Play()

    -- Top bar
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Parent = Main
    TopBar.BackgroundColor3 = Theme.Secondary
    TopBar.Size = UDim2.new(1, 0, 0, 45)
    TopBar.BorderSizePixel = 0
    MakeDraggable(TopBar, Main)

    CreateGradient(TopBar, Theme.Secondary, Color3.fromRGB(20, 120, 220), 0)

    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, Theme.CornerRadius)
    TopCorner.Parent = TopBar

    local Title = Instance.new("TextLabel")
    Title.Parent = TopBar
    Title.Text = "SLAYER TYCOON V2 <font color='#64B4FF'>PREMIUM UI</font>"
    Title.RichText = true
    Title.TextColor3 = Theme.Text
    Title.Size = UDim2.new(1, -100, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 15

    -- Close button
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
        -- Close animation
        TweenService:Create(Main, TWEEN_CONFIGS.Fast, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 1
        }):Play()
        task.wait(0.15)
        ScreenGui:Destroy()
    end)

    -- Minimize button
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
    local originalSize = Main.Size
    local originalPos = Main.Position
    
    MinBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            originalSize = Main.Size
            originalPos = Main.Position
            TweenService:Create(Main, TWEEN_CONFIGS.ExtraSmooth, {
                Position = UDim2.new(0, 10, 1, -50),
                Size = UDim2.new(0, 220, 0, 45)
            }):Play()
        else
            TweenService:Create(Main, TWEEN_CONFIGS.ExtraSmooth, {
                Position = originalPos,
                Size = originalSize
            }):Play()
        end
    end)

    -- Tab bar
    local TabBar = Instance.new("Frame")
    TabBar.Name = "TabBar"
    TabBar.Parent = Main
    TabBar.BackgroundColor3 = Theme.Surface
    TabBar.Position = UDim2.new(0, 0, 0, 45)
    TabBar.Size = UDim2.new(0, 120, 1, -45)
    TabBar.BorderSizePixel = 0
    TabBar.ClipsDescendants = true

    local TabBarCorner = Instance.new("UICorner")
    TabBarCorner.CornerRadius = UDim.new(0, Theme.CornerRadius)
    TabBarCorner.Parent = TabBar

    CreateGradient(TabBar, Color3.fromRGB(22, 22, 22), Color3.fromRGB(28, 28, 28), 90)

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.Parent = TabBar
    TabListLayout.Padding = UDim.new(0, 6)
    TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabListLayout.FillDirection = Enum.FillDirection.Vertical

    local TabPadding = Instance.new("UIPadding")
    TabPadding.Parent = TabBar
    TabPadding.PaddingTop = UDim.new(0, 10)
    TabPadding.PaddingBottom = UDim.new(0, 10)

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

    -- Add resize functionality
    MakeResizable(Main, Vector2.new(300, 200), Vector2.new(800, 700))

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
        Page.Position = UDim2.new(1, 0, 0, 0)

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Parent = Page
        PageLayout.Padding = UDim.new(0, 10)
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        
        local pageConnection = PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20)
        end)
        
        table.insert(Window.Connections, {pageConnection})

        local iconToUse = customIcon
        if customIcon == nil then
            iconToUse = nil
        elseif customIcon == false or customIcon == "" then
            iconToUse = ICONS.Default
        else
            iconToUse = customIcon or ICONS.Default
        end

        -- Tab button with enhanced design
        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = name .. "Tab"
        TabBtn.Parent = Window.TabBar
        TabBtn.Size = UDim2.new(0, 100, 0, 36)
        
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
        TabBtn.TextSize = 12

        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 8)
        TabCorner.Parent = TabBtn

        local TabStroke = Instance.new("UIStroke")
        TabStroke.Thickness = 1
        TabStroke.Color = Theme.Primary
        TabStroke.Transparency = Window.TabCount == 1 and 0 or 0.7
        TabStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        TabStroke.Parent = TabBtn

        CreateGradient(TabBtn, Window.TabCount == 1 and Theme.Primary or Theme.Surface, 
                      Window.TabCount == 1 and Theme.PrimaryLight or Color3.fromRGB(35, 35, 35), 0)

        -- Tab content container
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

        -- Tab click handler with slide animation
        TabBtn.MouseButton1Click:Connect(function()
            for _, p in pairs(Window.Pages:GetChildren()) do 
                if p:IsA("ScrollingFrame") then
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
                    local stroke = t:FindFirstChild("UIStroke")
                    if stroke then
                        TweenService:Create(stroke, TWEEN_CONFIGS.Fast, {Transparency = 0.7}):Play()
                    end
                end
            end
            
            Page.Visible = true
            local inTween = TweenService:Create(Page, TWEEN_CONFIGS.Normal, {Position = UDim2.new(0, 0, 0, 0)})
            inTween:Play()
            
            TweenService:Create(TabBtn, TWEEN_CONFIGS.Fast, {TextColor3 = Theme.Text, BackgroundColor3 = Theme.Primary}):Play()
            local stroke = TabBtn:FindFirstChild("UIStroke")
            if stroke then
                TweenService:Create(stroke, TWEEN_CONFIGS.Fast, {Transparency = 0}):Play()
            end
        end)

        -- Tab hover effects
        TabBtn.MouseEnter:Connect(function()
            if not Page.Visible then
                TweenService:Create(TabBtn, TWEEN_CONFIGS.Fast, {BackgroundColor3 = Color3.new(
                    math.min(Theme.Surface.R + 0.05, 1),
                    math.min(Theme.Surface.G + 0.05, 1),
                    math.min(Theme.Surface.B + 0.05, 1)
                )}):Play()
            end
        end)

        TabBtn.MouseLeave:Connect(function()
            if not Page.Visible then
                TweenService:Create(TabBtn, TWEEN_CONFIGS.Fast, {BackgroundColor3 = Theme.Surface}):Play()
            end
        end)

        -- Tab elements
        function Tab:CreateLabel(text)
            local LabelFrame = Instance.new("Frame")
            LabelFrame.Size = UDim2.new(1, 0, 0, 30)
            LabelFrame.BackgroundTransparency = 1
            LabelFrame.Parent = Page
            LabelFrame.LayoutOrder = self._LayoutOrder
            self._LayoutOrder = self._LayoutOrder + 1

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
            ToggleFrame.Size = UDim2.new(1, 0, 0, 42)
            ToggleFrame.BackgroundTransparency = 1
            ToggleFrame.Parent = Page
            ToggleFrame.LayoutOrder = self._LayoutOrder
            self._LayoutOrder = self._LayoutOrder + 1

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

            CreateGradient(TextBtn, Color3.fromRGB(22, 22, 22), Color3.fromRGB(28, 28, 28), 0)

            local StatusContainer = Instance.new("Frame")
            StatusContainer.Parent = TextBtn
            StatusContainer.BackgroundColor3 = Theme.Secondary
            StatusContainer.Position = UDim2.new(1, -50, 0.5, -11)
            StatusContainer.Size = UDim2.new(0, 40, 0, 22)
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

            local enabled = config.Default or false

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

            if enabled then SetState(true) end

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

        function Tab:CreateButton(config)
            local ButtonFrame = Instance.new("Frame")
            ButtonFrame.Size = UDim2.new(1, 0, 0, 42)
            ButtonFrame.BackgroundTransparency = 1
            ButtonFrame.Parent = Page
            ButtonFrame.LayoutOrder = self._LayoutOrder or 0
            self._LayoutOrder = (self._LayoutOrder or 0) + 1

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

        function Tab:CreateSlider(config)
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Size = UDim2.new(1, 0, 0, 62)
            SliderFrame.BackgroundColor3 = Theme.Surface
            SliderFrame.Parent = Page
            SliderFrame.BorderSizePixel = 0
            SliderFrame.LayoutOrder = self._LayoutOrder or 0
            self._LayoutOrder = (self._LayoutOrder or 0) + 1

            local sCorner = Instance.new("UICorner")
            sCorner.CornerRadius = UDim.new(0, 8)
            sCorner.Parent = SliderFrame

            CreateGradient(SliderFrame, Color3.fromRGB(22, 22, 22), Color3.fromRGB(28, 28, 28), 0)

            local Label = Instance.new("TextLabel")
            Label.Parent = SliderFrame
            Label.Text = "   " .. config.Name .. " : " .. config.Default
            Label.TextColor3 = Theme.TextSecondary
            Label.Size = UDim2.new(1, 0, 0, 28)
            Label.BackgroundTransparency = 1
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 12
            Label.TextXAlignment = Enum.TextXAlignment.Left

            local SliderBack = Instance.new("Frame")
            SliderBack.Parent = SliderFrame
            SliderBack.BackgroundColor3 = Theme.Secondary
            SliderBack.Position = UDim2.new(0, 10, 0, 35)
            SliderBack.Size = UDim2.new(1, -20, 0, 10)
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

            -- SLIDER BALL - ISOLATED STATE
            local SliderBall = Instance.new("Frame")
            SliderBall.Parent = SliderBack
            SliderBall.BackgroundColor3 = Theme.Accent
            SliderBall.Size = UDim2.new(0, 18, 0, 18)
            SliderBall.Position = UDim2.new((config.Default - config.Min) / (config.Max - config.Min), -9, 0.5, -9)
            SliderBall.BorderSizePixel = 0
            SliderBall.ZIndex = 10

            local ballCorner = Instance.new("UICorner")
            ballCorner.CornerRadius = UDim.new(1, 0)
            ballCorner.Parent = SliderBall

            -- LOCAL SLIDER STATE - EACH SLIDER HAS ITS OWN STATE
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
            
            -- INPUT BEGAN - START SLIDING
            local beganConn = SliderBack.InputBegan:Connect(function(input)
                if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not sliderState.sliding then
                    sliderState.sliding = true
                    TweenService:Create(SliderBall, TWEEN_CONFIGS.Fast, {Size = UDim2.new(0, 24, 0, 24), Position = SliderBall.Position + UDim2.new(0, -3, 0, -3)}):Play()
                    update(input.Position)
                end
            end)
            table.insert(sliderState.connections, beganConn)

            -- INPUT CHANGED - UPDATE WHILE SLIDING
            local changedConn = UserInputService.InputChanged:Connect(function(input)
                if sliderState.sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    update(input.Position)
                end
            end)
            table.insert(sliderState.connections, changedConn)

            -- INPUT ENDED - STOP SLIDING
            local endedConn = UserInputService.InputEnded:Connect(function(input)
                if sliderState.sliding and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                    sliderState.sliding = false
                    TweenService:Create(SliderBall, TWEEN_CONFIGS.Fast, {Size = UDim2.new(0, 18, 0, 18), Position = SliderBall.Position + UDim2.new(0, 3, 0, 3)}):Play()
                end
            end)
            table.insert(sliderState.connections, endedConn)

            -- CLEANUP
            SliderFrame.AncestryChanged:Connect(function(child, parent)
                if parent == nil then
                    for _, conn in pairs(sliderState.connections) do
                        if conn then conn:Disconnect() end
                    end
                end
            end)
        end

        function Tab:CreateDropdown(config)
            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Size = UDim2.new(1, 0, 0, 42)
            DropdownFrame.BackgroundTransparency = 1
            DropdownFrame.Parent = Page
            DropdownFrame.LayoutOrder = self._LayoutOrder or 0
            self._LayoutOrder = (self._LayoutOrder or 0) + 1
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

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 8)
            btnCorner.Parent = MainBtn

            CreateGradient(MainBtn, Color3.fromRGB(22, 22, 22), Color3.fromRGB(28, 28, 28), 0)

            local isOpen = false
            local DropdownMenu = Instance.new("Frame")
            DropdownMenu.Parent = DropdownFrame
            DropdownMenu.BackgroundColor3 = Theme.Surface
            DropdownMenu.Position = UDim2.new(0, 0, 0, 42)
            DropdownMenu.Size = UDim2.new(1, 0, 0, 0)
            DropdownMenu.BorderSizePixel = 0
            DropdownMenu.ClipsDescendants = true
            DropdownMenu.ZIndex = 50

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

            MainBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    local itemHeight = 32 * #config.Items + 12
                    TweenService:Create(DropdownMenu, TWEEN_CONFIGS.Normal, {Size = UDim2.new(1, 0, 0, itemHeight)}):Play()
                else
                    TweenService:Create(DropdownMenu, TWEEN_CONFIGS.Normal, {Size = UDim2.new(1, 0, 0, 0)}):Play()
                end
            end)

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

                local itemCorner = Instance.new("UICorner")
                itemCorner.CornerRadius = UDim.new(0, 6)
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

        function Tab:CreateProgressBar(config)
            local ProgressFrame = Instance.new("Frame")
            ProgressFrame.Size = UDim2.new(1, 0, 0, 50)
            ProgressFrame.BackgroundColor3 = Theme.Surface
            ProgressFrame.Parent = Page
            ProgressFrame.BorderSizePixel = 0
            ProgressFrame.LayoutOrder = self._LayoutOrder or 0
            self._LayoutOrder = (self._LayoutOrder or 0) + 1

            local pCorner = Instance.new("UICorner")
            pCorner.CornerRadius = UDim.new(0, 8)
            pCorner.Parent = ProgressFrame

            CreateGradient(ProgressFrame, Color3.fromRGB(22, 22, 22), Color3.fromRGB(28, 28, 28), 0)

            local Label = Instance.new("TextLabel")
            Label.Parent = ProgressFrame
            Label.Size = UDim2.new(1, 0, 0, 20)
            Label.Position = UDim2.new(0, 0, 0, 5)
            Label.BackgroundTransparency = 1
            Label.Text = config.Name .. " : 0%"
            Label.TextColor3 = Theme.TextSecondary
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 12

            local ProgressBack = Instance.new("Frame")
            ProgressBack.Parent = ProgressFrame
            ProgressBack.BackgroundColor3 = Theme.Secondary
            ProgressBack.Position = UDim2.new(0, 10, 0, 27)
            ProgressBack.Size = UDim2.new(1, -20, 0, 15)
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

        return Tab
    end

    -- Auto-create Settings tab
    local SettingsTab = Window:CreateTab("Settings", ICONS.Settings)

    SettingsTab:CreateLabel("── THEME ──")

    local themeButtons = {}
    for themeName, _ in pairs(THEMES) do
        table.insert(themeButtons, {Name = themeName, Callback = function()
            local newTheme = THEMES[themeName]
            for k, v in pairs(newTheme) do
                Theme[k] = v
            end
            Window:Notify("Theme changed to " .. themeName, 2, "success")
        end})
    end

    SettingsTab:CreateLabel("── WINDOW ──")

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

    SettingsTab:CreateLabel("── ADVANCED ──")

    SettingsTab:CreateSlider({
        Name = "UI Transparency",
        Min = 0,
        Max = 50,
        Default = 0,
        Callback = function(value)
            Main.BackgroundTransparency = value / 100
        end
    })

    return Window
end

return UI
