--[[
╔════════════════════════════════════════════════════════════════════╗
║         ENHANCED ROBLOX UI LIBRARY - VERSION 3.0 FINAL             ║
║  Complete Rewrite with Bug Fixes, Smooth Animations & Resizing     ║
╚════════════════════════════════════════════════════════════════════╝
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local UI = {}

-- ═══════════════════════════════════════════════════════════════════
-- ICON SYSTEM
-- ═══════════════════════════════════════════════════════════════════

local ICONS = {
    Close = 82404346839314,
    Minimize = 85022922514331,
    Settings = 7059346373,
    Default = 136443043095009
}

-- ═══════════════════════════════════════════════════════════════════
-- TWEEN CONFIGURATIONS (ULTRA SMOOTH)
-- ═══════════════════════════════════════════════════════════════════

local TWEEN_CONFIGS = {
    VeryFast = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Fast = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Normal = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Smooth = TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
    VerySmooth = TweenInfo.new(0.7, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut),
    UltraSmooth = TweenInfo.new(1.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut),
    Drag = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
}

-- ═══════════════════════════════════════════════════════════════════
-- COLOR THEMES SYSTEM
-- ═══════════════════════════════════════════════════════════════════

local THEMES = {
    Dark = {
        Primary = Color3.fromRGB(45, 135, 255),
        Secondary = Color3.fromRGB(30, 100, 200),
        Background = Color3.fromRGB(15, 15, 20),
        Surface = Color3.fromRGB(25, 25, 35),
        Text = Color3.fromRGB(240, 240, 245),
        TextSecondary = Color3.fromRGB(150, 150, 160),
        Accent = Color3.fromRGB(100, 180, 255),
        Success = Color3.fromRGB(76, 175, 80),
        Warning = Color3.fromRGB(255, 152, 0),
        Error = Color3.fromRGB(255, 76, 76),
    },
    Light = {
        Primary = Color3.fromRGB(30, 120, 240),
        Secondary = Color3.fromRGB(20, 100, 200),
        Background = Color3.fromRGB(245, 245, 250),
        Surface = Color3.fromRGB(235, 235, 240),
        Text = Color3.fromRGB(25, 25, 35),
        TextSecondary = Color3.fromRGB(100, 100, 110),
        Accent = Color3.fromRGB(60, 150, 255),
        Success = Color3.fromRGB(56, 142, 60),
        Warning = Color3.fromRGB(230, 124, 0),
        Error = Color3.fromRGB(211, 47, 47),
    },
    Purple = {
        Primary = Color3.fromRGB(156, 39, 176),
        Secondary = Color3.fromRGB(123, 31, 162),
        Background = Color3.fromRGB(15, 15, 20),
        Surface = Color3.fromRGB(35, 25, 50),
        Text = Color3.fromRGB(240, 240, 245),
        TextSecondary = Color3.fromRGB(150, 150, 160),
        Accent = Color3.fromRGB(186, 85, 211),
        Success = Color3.fromRGB(76, 175, 80),
        Warning = Color3.fromRGB(255, 152, 0),
        Error = Color3.fromRGB(255, 76, 76),
    },
    Green = {
        Primary = Color3.fromRGB(76, 175, 80),
        Secondary = Color3.fromRGB(56, 142, 60),
        Background = Color3.fromRGB(15, 20, 15),
        Surface = Color3.fromRGB(25, 35, 25),
        Text = Color3.fromRGB(240, 245, 240),
        TextSecondary = Color3.fromRGB(150, 160, 150),
        Accent = Color3.fromRGB(129, 199, 132),
        Success = Color3.fromRGB(102, 187, 106),
        Warning = Color3.fromRGB(255, 152, 0),
        Error = Color3.fromRGB(255, 76, 76),
    },
    Orange = {
        Primary = Color3.fromRGB(255, 152, 0),
        Secondary = Color3.fromRGB(230, 124, 0),
        Background = Color3.fromRGB(20, 15, 10),
        Surface = Color3.fromRGB(40, 30, 20),
        Text = Color3.fromRGB(245, 240, 235),
        TextSecondary = Color3.fromRGB(160, 150, 140),
        Accent = Color3.fromRGB(255, 183, 77),
        Success = Color3.fromRGB(76, 175, 80),
        Warning = Color3.fromRGB(255, 152, 0),
        Error = Color3.fromRGB(255, 76, 76),
    },
    Cyan = {
        Primary = Color3.fromRGB(0, 188, 212),
        Secondary = Color3.fromRGB(0, 172, 193),
        Background = Color3.fromRGB(10, 20, 25),
        Surface = Color3.fromRGB(20, 40, 50),
        Text = Color3.fromRGB(235, 245, 250),
        TextSecondary = Color3.fromRGB(140, 160, 170),
        Accent = Color3.fromRGB(77, 208, 225),
        Success = Color3.fromRGB(76, 175, 80),
        Warning = Color3.fromRGB(255, 152, 0),
        Error = Color3.fromRGB(255, 76, 76),
    },
}

-- ═══════════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════

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

local function GetDeviceType()
    -- Detect device type for UI adjustments
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        return "Mobile"
    elseif UserInputService.TouchEnabled and UserInputService.KeyboardEnabled then
        return "Tablet"
    else
        return "Desktop"
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- MAIN UI FACTORY
-- ═══════════════════════════════════════════════════════════════════

function UI:CreateWindow(themeName)
    themeName = themeName or "Dark"
    local Window = {}
    
    -- Get theme or default to Dark
    local Theme = THEMES[themeName] or THEMES.Dark
    Window.Theme = Theme
    Window.ThemeName = themeName
    Window.AvailableThemes = THEMES
    
    local guiName = LocalPlayer.UserId .. "_EnhancedUI"
    local existingGui = CoreGui:FindFirstChild(guiName)
    if existingGui then
        existingGui:Destroy()
    end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = guiName
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false
    
    local DeviceType = GetDeviceType()
    local initialWidth = DeviceType == "Mobile" and 300 or 550
    local initialHeight = DeviceType == "Mobile" and 400 or 400
    
    -- ═══════════════════════════════════════════════════════════════
    -- NOTIFICATION SYSTEM
    -- ═══════════════════════════════════════════════════════════════
    
    local NotifContainer = Instance.new("Frame")
    NotifContainer.Name = "NotifContainer"
    NotifContainer.Parent = ScreenGui
    NotifContainer.BackgroundTransparency = 1
    NotifContainer.Size = UDim2.new(1, 0, 0, 0)
    NotifContainer.Position = UDim2.new(0, 0, 0, 20)
    NotifContainer.ZIndex = 100
    
    local NotifLayout = Instance.new("UIListLayout")
    NotifLayout.Parent = NotifContainer
    NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    NotifLayout.Padding = UDim.new(0, 8)
    
    function Window:Notify(text, duration, notifType)
        duration = duration or 3
        notifType = notifType or "normal"
        
        local notifColor = Theme.Primary
        if notifType == "success" then notifColor = Theme.Success
        elseif notifType == "warning" then notifColor = Theme.Warning
        elseif notifType == "error" then notifColor = Theme.Error end
        
        local NotifFrame = Instance.new("Frame")
        NotifFrame.Size = UDim2.new(0, 340, 0, 50)
        NotifFrame.BackgroundColor3 = Theme.Background
        NotifFrame.BorderSizePixel = 0
        NotifFrame.BackgroundTransparency = 0.1
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = NotifFrame
        
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1.5
        stroke.Color = notifColor
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Transparency = 0
        stroke.Parent = NotifFrame
        
        CreateGradient(NotifFrame, Theme.Background, Color3.fromRGB(math.max(0, Theme.Background.R*255-10), math.max(0, Theme.Background.G*255-10), math.max(0, Theme.Background.B*255-10)) / 255, 45)
        
        local NotifText = Instance.new("TextLabel")
        NotifText.Parent = NotifFrame
        NotifText.Size = UDim2.new(1, -30, 1, 0)
        NotifText.Position = UDim2.new(0, 15, 0, 0)
        NotifText.BackgroundTransparency = 1
        NotifText.Text = text
        NotifText.TextColor3 = Theme.Text
        NotifText.Font = Enum.Font.GothamMedium
        NotifText.TextSize = 13
        NotifText.TextWrapped = true
        
        NotifFrame.Parent = NotifContainer
        NotifFrame.Position = UDim2.new(0.5, -170, 0, -60)
        
        local appearTween = TweenService:Create(NotifFrame, TWEEN_CONFIGS.Smooth, {Position = UDim2.new(0.5, -170, 0, 10)})
        appearTween:Play()
        
        task.delay(duration, function()
            if NotifFrame and NotifFrame.Parent then
                local disappearTween = TweenService:Create(NotifFrame, TWEEN_CONFIGS.Smooth, {Position = UDim2.new(0.5, -170, 0, -60)})
                disappearTween:Play()
                
                disappearTween.Completed:Connect(function()
                    if NotifFrame then
                        NotifFrame:Destroy()
                    end
                end)
            end
        end)
    end
    
    -- ═══════════════════════════════════════════════════════════════
    -- MAIN WINDOW SETUP
    -- ═══════════════════════════════════════════════════════════════
    
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Parent = ScreenGui
    Main.BackgroundColor3 = Theme.Background
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, -initialWidth/2, 0.5, -initialHeight/2)
    Main.Size = UDim2.new(0, initialWidth, 0, initialHeight)
    Main.ClipsDescendants = true
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 16)
    MainCorner.Parent = Main
    
    CreateGradient(Main, Theme.Background, Theme.Surface, 45)
    
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Thickness = 2
    MainStroke.Color = Theme.Secondary
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainStroke.Transparency = 0.3
    MainStroke.Parent = Main
    
    -- ═══════════════════════════════════════════════════════════════
    -- WINDOW DRAGGING (ULTRA SMOOTH)
    -- ═══════════════════════════════════════════════════════════════
    
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Parent = Main
    TopBar.BackgroundColor3 = Theme.Secondary
    TopBar.Size = UDim2.new(1, 0, 0, 50)
    TopBar.BorderSizePixel = 0
    
    CreateGradient(TopBar, Theme.Secondary, Color3.fromRGB(
        math.max(0, Theme.Secondary.R*255-20),
        math.max(0, Theme.Secondary.G*255-20),
        math.max(0, Theme.Secondary.B*255-20)
    ) / 255, 0)
    
    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 16)
    TopCorner.Parent = TopBar
    
    local Title = Instance.new("TextLabel")
    Title.Parent = TopBar
    Title.Text = "SLAYER HUB"
    Title.TextColor3 = Theme.Text
    Title.Size = UDim2.new(1, -110, 1, 0)
    Title.Position = UDim2.new(0, 20, 0, 0)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    local function StartDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end
    
    TopBar.InputBegan:Connect(StartDrag)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and dragStart then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            Main.Position = newPos
        end
    end)
    
    -- ═══════════════════════════════════════════════════════════════
    -- CLOSE & MINIMIZE BUTTONS
    -- ═══════════════════════════════════════════════════════════════
    
    local CloseBtn = Instance.new("ImageButton")
    CloseBtn.Parent = TopBar
    CloseBtn.Size = UDim2.new(0, 35, 0, 35)
    CloseBtn.Position = UDim2.new(1, -45, 0.5, -17.5)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Image = "rbxassetid://" .. ICONS.Close
    CloseBtn.ImageColor3 = Color3.fromRGB(255, 100, 100)
    CloseBtn.ScaleType = Enum.ScaleType.Fit
    CloseBtn.ZIndex = 10
    
    CloseBtn.MouseEnter:Connect(function()
        TweenService:Create(CloseBtn, TWEEN_CONFIGS.VeryFast, {ImageColor3 = Color3.fromRGB(255, 150, 150)}):Play()
    end)
    
    CloseBtn.MouseLeave:Connect(function()
        TweenService:Create(CloseBtn, TWEEN_CONFIGS.VeryFast, {ImageColor3 = Color3.fromRGB(255, 100, 100)}):Play()
    end)
    
    CloseBtn.MouseButton1Click:Connect(function()
        local closeTween = TweenService:Create(Main, TWEEN_CONFIGS.Smooth, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(Main.Position.X.Scale, Main.Position.X.Offset + initialWidth/2, Main.Position.Y.Scale, Main.Position.Y.Offset + initialHeight/2)})
        closeTween:Play()
        closeTween.Completed:Connect(function()
            ScreenGui:Destroy()
        end)
    end)
    
    local MinBtn = Instance.new("ImageButton")
    MinBtn.Parent = TopBar
    MinBtn.Size = UDim2.new(0, 35, 0, 35)
    MinBtn.Position = UDim2.new(1, -85, 0.5, -17.5)
    MinBtn.BackgroundTransparency = 1
    MinBtn.Image = "rbxassetid://" .. ICONS.Minimize
    MinBtn.ImageColor3 = Theme.TextSecondary
    MinBtn.ScaleType = Enum.ScaleType.Fit
    MinBtn.ZIndex = 10
    
    MinBtn.MouseEnter:Connect(function()
        TweenService:Create(MinBtn, TWEEN_CONFIGS.VeryFast, {ImageColor3 = Theme.Text}):Play()
    end)
    
    MinBtn.MouseLeave:Connect(function()
        TweenService:Create(MinBtn, TWEEN_CONFIGS.VeryFast, {ImageColor3 = Theme.TextSecondary}):Play()
    end)
    
    local isMinimized = false
    local minOriginalPos = Main.Position
    local minOriginalSize = Main.Size
    
    MinBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            minOriginalPos = Main.Position
            minOriginalSize = Main.Size
            local minTween = TweenService:Create(Main, TWEEN_CONFIGS.UltraSmooth, {
                Position = UDim2.new(0, 20, 1, -60),
                Size = UDim2.new(0, 250, 0, 50)
            })
            minTween:Play()
        else
            local restoreTween = TweenService:Create(Main, TWEEN_CONFIGS.UltraSmooth, {
                Position = minOriginalPos,
                Size = minOriginalSize
            })
            restoreTween:Play()
        end
    end)
    
    -- ═══════════════════════════════════════════════════════════════
    -- WINDOW RESIZING (Windows-style)
    -- ═══════════════════════════════════════════════════════════════
    
    local function CreateResizeHandle(corner)
        local handle = Instance.new("Frame")
        handle.Parent = Main
        handle.BackgroundTransparency = 1
        handle.Size = UDim2.new(0, 20, 0, 20)
        handle.ZIndex = 5
        
        if corner == "TL" then
            handle.Position = UDim2.new(0, 0, 0, 0)
        elseif corner == "TR" then
            handle.Position = UDim2.new(1, -20, 0, 0)
        elseif corner == "BL" then
            handle.Position = UDim2.new(0, 0, 1, -20)
        elseif corner == "BR" then
            handle.Position = UDim2.new(1, -20, 1, -20)
        end
        
        local resizing = false
        local resizeStart = nil
        local resizeStartSize = nil
        local resizeStartPos = nil
        
        handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                resizing = true
                resizeStart = input.Position
                resizeStartSize = Main.Size
                resizeStartPos = Main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        resizing = false
                    end
                end)
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if resizing and resizeStart then
                local delta = input.Position - resizeStart
                
                if corner == "BR" then
                    local newWidth = math.max(250, resizeStartSize.X.Offset + delta.X)
                    local newHeight = math.max(200, resizeStartSize.Y.Offset + delta.Y)
                    Main.Size = UDim2.new(0, newWidth, 0, newHeight)
                elseif corner == "BL" then
                    local newWidth = math.max(250, resizeStartSize.X.Offset - delta.X)
                    local newHeight = math.max(200, resizeStartSize.Y.Offset + delta.Y)
                    Main.Position = UDim2.new(resizeStartPos.X.Scale, resizeStartPos.X.Offset + delta.X, resizeStartPos.Y.Scale, resizeStartPos.Y.Offset)
                    Main.Size = UDim2.new(0, newWidth, 0, newHeight)
                elseif corner == "TR" then
                    local newWidth = math.max(250, resizeStartSize.X.Offset + delta.X)
                    local newHeight = math.max(200, resizeStartSize.Y.Offset - delta.Y)
                    Main.Position = UDim2.new(resizeStartPos.X.Scale, resizeStartPos.X.Offset, resizeStartPos.Y.Scale, resizeStartPos.Y.Offset + delta.Y)
                    Main.Size = UDim2.new(0, newWidth, 0, newHeight)
                elseif corner == "TL" then
                    local newWidth = math.max(250, resizeStartSize.X.Offset - delta.X)
                    local newHeight = math.max(200, resizeStartSize.Y.Offset - delta.Y)
                    Main.Position = UDim2.new(resizeStartPos.X.Scale, resizeStartPos.X.Offset + delta.X, resizeStartPos.Y.Scale, resizeStartPos.Y.Offset + delta.Y)
                    Main.Size = UDim2.new(0, newWidth, 0, newHeight)
                end
            end
        end)
    end
    
    -- Create corner handles
    CreateResizeHandle("TL")
    CreateResizeHandle("TR")
    CreateResizeHandle("BL")
    CreateResizeHandle("BR")
    
    -- Create side handles
    local sideHandles = {
        Top = function()
            local handle = Instance.new("Frame")
            handle.Parent = Main
            handle.BackgroundTransparency = 1
            handle.Position = UDim2.new(0, 20, 0, 0)
            handle.Size = UDim2.new(1, -40, 0, 5)
            handle.ZIndex = 5
            return handle, "Top"
        end,
        Bottom = function()
            local handle = Instance.new("Frame")
            handle.Parent = Main
            handle.BackgroundTransparency = 1
            handle.Position = UDim2.new(0, 20, 1, -5)
            handle.Size = UDim2.new(1, -40, 0, 5)
            handle.ZIndex = 5
            return handle, "Bottom"
        end,
        Left = function()
            local handle = Instance.new("Frame")
            handle.Parent = Main
            handle.BackgroundTransparency = 1
            handle.Position = UDim2.new(0, 0, 0, 20)
            handle.Size = UDim2.new(0, 5, 1, -40)
            handle.ZIndex = 5
            return handle, "Left"
        end,
        Right = function()
            local handle = Instance.new("Frame")
            handle.Parent = Main
            handle.BackgroundTransparency = 1
            handle.Position = UDim2.new(1, -5, 0, 20)
            handle.Size = UDim2.new(0, 5, 1, -40)
            handle.ZIndex = 5
            return handle, "Right"
        end,
    }
    
    for _, createHandle in pairs(sideHandles) do
        local handle, side = createHandle()
        
        local resizing = false
        local resizeStart = nil
        local resizeStartSize = nil
        local resizeStartPos = nil
        
        handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                resizing = true
                resizeStart = input.Position
                resizeStartSize = Main.Size
                resizeStartPos = Main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        resizing = false
                    end
                end)
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if resizing and resizeStart then
                local delta = input.Position - resizeStart
                
                if side == "Bottom" then
                    Main.Size = UDim2.new(0, resizeStartSize.X.Offset, 0, math.max(200, resizeStartSize.Y.Offset + delta.Y))
                elseif side == "Top" then
                    Main.Position = UDim2.new(resizeStartPos.X.Scale, resizeStartPos.X.Offset, resizeStartPos.Y.Scale, resizeStartPos.Y.Offset + delta.Y)
                    Main.Size = UDim2.new(0, resizeStartSize.X.Offset, 0, math.max(200, resizeStartSize.Y.Offset - delta.Y))
                elseif side == "Right" then
                    Main.Size = UDim2.new(0, math.max(250, resizeStartSize.X.Offset + delta.X), 0, resizeStartSize.Y.Offset)
                elseif side == "Left" then
                    Main.Position = UDim2.new(resizeStartPos.X.Scale, resizeStartPos.X.Offset + delta.X, resizeStartPos.Y.Scale, resizeStartPos.Y.Offset)
                    Main.Size = UDim2.new(0, math.max(250, resizeStartSize.X.Offset - delta.X), 0, resizeStartSize.Y.Offset)
                end
            end
        end)
    end
    
    -- ═══════════════════════════════════════════════════════════════
    -- TAB SYSTEM
    -- ═══════════════════════════════════════════════════════════════
    
    local TabBar = Instance.new("Frame")
    TabBar.Name = "TabBar"
    TabBar.Parent = Main
    TabBar.BackgroundColor3 = Theme.Surface
    TabBar.Position = UDim2.new(0, 0, 0, 50)
    TabBar.Size = UDim2.new(0, 120, 1, -50)
    TabBar.BorderSizePixel = 0
    TabBar.ClipsDescendants = true
    
    local TabBarCorner = Instance.new("UICorner")
    TabBarCorner.CornerRadius = UDim.new(0, 16)
    TabBarCorner.Parent = TabBar
    
    CreateGradient(TabBar, Theme.Surface, Color3.fromRGB(
        math.max(0, Theme.Surface.R*255-15),
        math.max(0, Theme.Surface.G*255-15),
        math.max(0, Theme.Surface.B*255-15)
    ) / 255, 90)
    
    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.Parent = TabBar
    TabListLayout.Padding = UDim.new(0, 6)
    TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local TabPadding = Instance.new("UIPadding")
    TabPadding.Parent = TabBar
    TabPadding.PaddingTop = UDim.new(0, 12)
    TabPadding.PaddingBottom = UDim.new(0, 12)
    
    local Pages = Instance.new("Frame")
    Pages.Name = "Pages"
    Pages.Parent = Main
    Pages.BackgroundTransparency = 1
    Pages.Position = UDim2.new(0, 130, 0, 60)
    Pages.Size = UDim2.new(1, -140, 1, -70)
    
    Window.Pages = Pages
    Window.TabBar = TabBar
    Window.TabCount = 0
    Window.Main = Main
    
    -- ═══════════════════════════════════════════════════════════════
    -- TAB CREATION
    -- ═══════════════════════════════════════════════════════════════
    
    function Window:CreateTab(name, customIcon)
        local Tab = {}
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
        Page.ScrollingDirection = Enum.ScrollingDirection.Y
        
        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Parent = Page
        PageLayout.Padding = UDim.new(0, 10)
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20)
        end)
        
        local PagePadding = Instance.new("UIPadding")
        PagePadding.Parent = Page
        PagePadding.PaddingLeft = UDim.new(0, 10)
        PagePadding.PaddingRight = UDim.new(0, 10)
        PagePadding.PaddingTop = UDim.new(0, 10)
        
        local iconToUse
        if customIcon == nil then
            iconToUse = nil
        elseif customIcon == false or customIcon == "" then
            iconToUse = ICONS.Default
        else
            iconToUse = customIcon or ICONS.Default
        end
        
        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = name .. "Tab"
        TabBtn.Parent = Window.TabBar
        TabBtn.Size = UDim2.new(0, 108, 0, 40)
        
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
        TabBtn.TextSize = 13
        
        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 10)
        TabCorner.Parent = TabBtn
        
        CreateGradient(TabBtn, TabBtn.BackgroundColor3, Color3.fromRGB(
            math.max(0, TabBtn.BackgroundColor3.R*255-15),
            math.max(0, TabBtn.BackgroundColor3.G*255-15),
            math.max(0, TabBtn.BackgroundColor3.B*255-15)
        ) / 255, 0)
        
        local TabContent = Instance.new("Frame")
        TabContent.Parent = TabBtn
        TabContent.BackgroundTransparency = 1
        TabContent.Size = UDim2.new(1, 0, 1, 0)
        
        local TabContentLayout = Instance.new("UIListLayout")
        TabContentLayout.Parent = TabContent
        TabContentLayout.FillDirection = Enum.FillDirection.Horizontal
        TabContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        TabContentLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        TabContentLayout.Padding = UDim.new(0, 2)
        
        if iconToUse then
            local TabIcon = Instance.new("ImageLabel")
            TabIcon.Parent = TabContent
            TabIcon.BackgroundTransparency = 1
            TabIcon.Size = UDim2.new(0, 20, 0, 20)
            TabIcon.Image = "rbxassetid://" .. iconToUse
            TabIcon.ImageColor3 = TabBtn.TextColor3
            TabIcon.ScaleType = Enum.ScaleType.Fit
        end
        
        local TabLabel = Instance.new("TextLabel")
        TabLabel.Parent = TabContent
        TabLabel.BackgroundTransparency = 1
        TabLabel.Size = UDim2.new(0, 70, 0, 20)
        TabLabel.Text = name
        TabLabel.TextColor3 = TabBtn.TextColor3
        TabLabel.Font = Enum.Font.GothamBold
        TabLabel.TextSize = 14
        TabLabel.TextXAlignment = Enum.TextXAlignment.Center
        
        TabBtn.MouseButton1Click:Connect(function()
            for _, p in pairs(Window.Pages:GetChildren()) do
                if p:IsA("ScrollingFrame") then
                    p.Visible = false
                end
            end
            
            for _, t in pairs(Window.TabBar:GetChildren()) do
                if t:IsA("TextButton") then
                    local tabLabelChild = t:FindFirstChildWhichIsA("TextLabel")
                    local tabIconChild = t:FindFirstChildWhichIsA("ImageLabel")
                    
                    TweenService:Create(t, TWEEN_CONFIGS.Fast, {TextColor3 = Theme.TextSecondary, BackgroundColor3 = Theme.Surface}):Play()
                    if tabLabelChild then
                        TweenService:Create(tabLabelChild, TWEEN_CONFIGS.Fast, {TextColor3 = Theme.TextSecondary}):Play()
                    end
                    if tabIconChild then
                        TweenService:Create(tabIconChild, TWEEN_CONFIGS.Fast, {ImageColor3 = Theme.TextSecondary}):Play()
                    end
                    
                    local gradChildren = t:GetChildren()
                    for _, child in pairs(gradChildren) do
                        if child:IsA("UIGradient") then
                            child:Destroy()
                        end
                    end
                    CreateGradient(t, Theme.Surface, Color3.fromRGB(
                        math.max(0, Theme.Surface.R*255-15),
                        math.max(0, Theme.Surface.G*255-15),
                        math.max(0, Theme.Surface.B*255-15)
                    ) / 255, 0)
                end
            end
            
            Page.Visible = true
            TweenService:Create(TabBtn, TWEEN_CONFIGS.Fast, {TextColor3 = Theme.Text, BackgroundColor3 = Theme.Primary}):Play()
            
            local tabLabelChild = TabBtn:FindFirstChildWhichIsA("TextLabel")
            local tabIconChild = TabBtn:FindFirstChildWhichIsA("ImageLabel")
            
            if tabLabelChild then
                TweenService:Create(tabLabelChild, TWEEN_CONFIGS.Fast, {TextColor3 = Theme.Text}):Play()
            end
            if tabIconChild then
                TweenService:Create(tabIconChild, TWEEN_CONFIGS.Fast, {ImageColor3 = Theme.Text}):Play()
            end
            
            local gradChildren = TabBtn:GetChildren()
            for _, child in pairs(gradChildren) do
                if child:IsA("UIGradient") then
                    child:Destroy()
                end
            end
            CreateGradient(TabBtn, Theme.Primary, Color3.fromRGB(
                math.max(0, Theme.Primary.R*255-15),
                math.max(0, Theme.Primary.G*255-15),
                math.max(0, Theme.Primary.B*255-15)
            ) / 255, 0)
        end)
        
        TabBtn.MouseEnter:Connect(function()
            if TabBtn.BackgroundColor3 ~= Theme.Primary then
                TweenService:Create(TabBtn, TWEEN_CONFIGS.VeryFast, {BackgroundColor3 = Color3.fromRGB(
                    math.min(255, Theme.Surface.R*255+20),
                    math.min(255, Theme.Surface.G*255+20),
                    math.min(255, Theme.Surface.B*255+20)
                ) / 255}):Play()
            end
        end)
        
        TabBtn.MouseLeave:Connect(function()
            if TabBtn.BackgroundColor3 ~= Theme.Primary then
                TweenService:Create(TabBtn, TWEEN_CONFIGS.VeryFast, {BackgroundColor3 = Theme.Surface}):Play()
            end
        end)
        
        -- ═══════════════════════════════════════════════════════════
        -- UI COMPONENTS
        -- ═══════════════════════════════════════════════════════════
        
        function Tab:CreateLabel(text)
            local LabelFrame = Instance.new("Frame")
            LabelFrame.Size = UDim2.new(1, 0, 0, 28)
            LabelFrame.BackgroundTransparency = 1
            LabelFrame.Parent = Page
            
            local Label = Instance.new("TextLabel")
            Label.Parent = LabelFrame
            Label.Size = UDim2.new(1, 0, 1, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Theme.TextSecondary
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 12
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextWrapped = true
        end
        
        function Tab:CreateToggle(config)
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Size = UDim2.new(1, 0, 0, 42)
            ToggleFrame.BackgroundTransparency = 1
            ToggleFrame.Parent = Page
            
            local TextBtn = Instance.new("TextButton")
            TextBtn.Parent = ToggleFrame
            TextBtn.BackgroundColor3 = Theme.Surface
            TextBtn.Size = UDim2.new(1, 0, 1, 0)
            TextBtn.Text = "   " .. config.Name
            TextBtn.TextColor3 = Theme.TextSecondary
            TextBtn.Font = Enum.Font.Gotham
            TextBtn.TextSize = 14
            TextBtn.TextXAlignment = Enum.TextXAlignment.Left
            TextBtn.BorderSizePixel = 0
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 10)
            btnCorner.Parent = TextBtn
            
            CreateGradient(TextBtn, Theme.Surface, Color3.fromRGB(
                math.max(0, Theme.Surface.R*255-15),
                math.max(0, Theme.Surface.G*255-15),
                math.max(0, Theme.Surface.B*255-15)
            ) / 255, 0)
            
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
            StatusCircle.Size = UDim2.new(0, 18, 0, 18)
            StatusCircle.BorderSizePixel = 0
            
            local circleCorner = Instance.new("UICorner")
            circleCorner.CornerRadius = UDim.new(1, 0)
            circleCorner.Parent = StatusCircle
            
            local enabled = false
            
            local function SetState(state)
                enabled = state
                if enabled then
                    TweenService:Create(StatusCircle, TWEEN_CONFIGS.Fast, {Position = UDim2.new(1, -20, 0.5, -8), BackgroundColor3 = Theme.Accent}):Play()
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
                TweenService:Create(TextBtn, TWEEN_CONFIGS.VeryFast, {BackgroundColor3 = Color3.fromRGB(
                    math.min(255, Theme.Surface.R*255+15),
                    math.min(255, Theme.Surface.G*255+15),
                    math.min(255, Theme.Surface.B*255+15)
                ) / 255}):Play()
            end)
            
            TextBtn.MouseLeave:Connect(function()
                TweenService:Create(TextBtn, TWEEN_CONFIGS.VeryFast, {BackgroundColor3 = Theme.Surface}):Play()
            end)
            
            return SetState
        end
        
        function Tab:CreateSlider(config)
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Size = UDim2.new(1, 0, 0, 60)
            SliderFrame.BackgroundColor3 = Theme.Surface
            SliderFrame.Parent = Page
            
            local sCorner = Instance.new("UICorner")
            sCorner.CornerRadius = UDim.new(0, 10)
            sCorner.Parent = SliderFrame
            
            CreateGradient(SliderFrame, Theme.Surface, Color3.fromRGB(
                math.max(0, Theme.Surface.R*255-15),
                math.max(0, Theme.Surface.G*255-15),
                math.max(0, Theme.Surface.B*255-15)
            ) / 255, 0)
            
            local Label = Instance.new("TextLabel")
            Label.Parent = SliderFrame
            Label.Text = "   " .. config.Name .. " : " .. config.Default
            Label.TextColor3 = Theme.TextSecondary
            Label.Size = UDim2.new(1, 0, 0, 25)
            Label.BackgroundTransparency = 1
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            
            local SliderBack = Instance.new("Frame")
            SliderBack.Parent = SliderFrame
            SliderBack.BackgroundColor3 = Theme.Secondary
            SliderBack.Position = UDim2.new(0, 12, 0, 32)
            SliderBack.Size = UDim2.new(1, -24, 0, 8)
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
            
            CreateGradient(SliderFill, Theme.Primary, Theme.Accent, 0)
            
            -- IMPORTANT: Each slider has its OWN sliding state
            local sliderState = {
                sliding = false,
                startInput = nil
            }
            
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
            
            local function UpdateSlider(pos)
                pos = math.clamp(pos, 0, 1)
                SliderFill.Size = UDim2.new(pos, 0, 1, 0)
                SliderBall.Position = UDim2.new(pos, -9, 0.5, -9)
                local val = math.floor(((config.Max - config.Min) * pos) + config.Min)
                Label.Text = "   " .. config.Name .. " : " .. val
                if config.Callback then config.Callback(val) end
            end
            
            SliderBack.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliderState.sliding = true
                    sliderState.startInput = input
                    
                    TweenService:Create(SliderBall, TWEEN_CONFIGS.VeryFast, {Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(SliderBall.Position.X.Scale, SliderBall.Position.X.Offset - 3, 0.5, -12)}):Play()
                    
                    local pos = math.clamp((input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
                    UpdateSlider(pos)
                    
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            sliderState.sliding = false
                            TweenService:Create(SliderBall, TWEEN_CONFIGS.VeryFast, {Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(SliderBall.Position.X.Scale, SliderBall.Position.X.Offset + 3, 0.5, -9)}):Play()
                        end
                    end)
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if sliderState.sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local pos = math.clamp((input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
                    UpdateSlider(pos)
                end
            end)
        end
        
        function Tab:CreateButton(config)
            local TextBtn = Instance.new("TextButton")
            TextBtn.Parent = Page
            TextBtn.BackgroundColor3 = Theme.Secondary
            TextBtn.Size = UDim2.new(1, 0, 0, 42)
            TextBtn.Text = config.Name
            TextBtn.TextColor3 = Theme.Text
            TextBtn.Font = Enum.Font.GothamBold
            TextBtn.TextSize = 14
            TextBtn.BorderSizePixel = 0
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 10)
            btnCorner.Parent = TextBtn
            
            CreateGradient(TextBtn, Theme.Secondary, Color3.fromRGB(
                math.max(0, Theme.Secondary.R*255-15),
                math.max(0, Theme.Secondary.G*255-15),
                math.max(0, Theme.Secondary.B*255-15)
            ) / 255, 0)
            
            TextBtn.MouseButton1Down:Connect(function()
                TweenService:Create(TextBtn, TWEEN_CONFIGS.VeryFast, {BackgroundColor3 = Theme.Primary}):Play()
            end)
            
            TextBtn.MouseButton1Up:Connect(function()
                TweenService:Create(TextBtn, TWEEN_CONFIGS.VeryFast, {BackgroundColor3 = Theme.Secondary}):Play()
            end)
            
            TextBtn.MouseEnter:Connect(function()
                TweenService:Create(TextBtn, TWEEN_CONFIGS.VeryFast, {BackgroundColor3 = Color3.fromRGB(
                    math.min(255, Theme.Secondary.R*255+15),
                    math.min(255, Theme.Secondary.G*255+15),
                    math.min(255, Theme.Secondary.B*255+15)
                ) / 255}):Play()
            end)
            
            TextBtn.MouseLeave:Connect(function()
                TweenService:Create(TextBtn, TWEEN_CONFIGS.VeryFast, {BackgroundColor3 = Theme.Secondary}):Play()
            end)
            
            TextBtn.MouseButton1Click:Connect(function()
                if config.Callback then config.Callback() end
            end)
        end
        
        function Tab:CreateDropdown(config)
            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Size = UDim2.new(1, 0, 0, 42)
            DropdownFrame.BackgroundTransparency = 1
            DropdownFrame.Parent = Page
            
            local MainBtn = Instance.new("TextButton")
            MainBtn.Parent = DropdownFrame
            MainBtn.BackgroundColor3 = Theme.Surface
            MainBtn.Size = UDim2.new(1, 0, 0, 42)
            MainBtn.Text = "   " .. config.Name .. " : " .. (config.Default or "Select")
            MainBtn.TextColor3 = Theme.TextSecondary
            MainBtn.Font = Enum.Font.Gotham
            MainBtn.TextSize = 14
            MainBtn.TextXAlignment = Enum.TextXAlignment.Left
            MainBtn.BorderSizePixel = 0
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 10)
            btnCorner.Parent = MainBtn
            
            CreateGradient(MainBtn, Theme.Surface, Color3.fromRGB(
                math.max(0, Theme.Surface.R*255-15),
                math.max(0, Theme.Surface.G*255-15),
                math.max(0, Theme.Surface.B*255-15)
            ) / 255, 0)
            
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
            menuCorner.CornerRadius = UDim.new(0, 10)
            menuCorner.Parent = DropdownMenu
            
            local MenuLayout = Instance.new("UIListLayout")
            MenuLayout.Parent = DropdownMenu
            MenuLayout.Padding = UDim.new(0, 3)
            
            MainBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    local itemHeight = 35 * #config.Items
                    TweenService:Create(DropdownMenu, TWEEN_CONFIGS.Smooth, {Size = UDim2.new(1, 0, 0, itemHeight)}):Play()
                else
                    TweenService:Create(DropdownMenu, TWEEN_CONFIGS.Smooth, {Size = UDim2.new(1, 0, 0, 0)}):Play()
                end
            end)
            
            for _, item in pairs(config.Items) do
                local ItemBtn = Instance.new("TextButton")
                ItemBtn.Parent = DropdownMenu
                ItemBtn.BackgroundColor3 = Theme.Secondary
                ItemBtn.Size = UDim2.new(1, -4, 0, 32)
                ItemBtn.Text = item
                ItemBtn.TextColor3 = Theme.TextSecondary
                ItemBtn.Font = Enum.Font.Gotham
                ItemBtn.TextSize = 13
                ItemBtn.BorderSizePixel = 0
                
                local itemCorner = Instance.new("UICorner")
                itemCorner.CornerRadius = UDim.new(0, 8)
                itemCorner.Parent = ItemBtn
                
                ItemBtn.MouseEnter:Connect(function()
                    TweenService:Create(ItemBtn, TWEEN_CONFIGS.VeryFast, {BackgroundColor3 = Theme.Primary}):Play()
                end)
                
                ItemBtn.MouseLeave:Connect(function()
                    TweenService:Create(ItemBtn, TWEEN_CONFIGS.VeryFast, {BackgroundColor3 = Theme.Secondary}):Play()
                end)
                
                ItemBtn.MouseButton1Click:Connect(function()
                    MainBtn.Text = "   " .. config.Name .. " : " .. item
                    isOpen = false
                    TweenService:Create(DropdownMenu, TWEEN_CONFIGS.Smooth, {Size = UDim2.new(1, 0, 0, 0)}):Play()
                    if config.Callback then config.Callback(item) end
                end)
            end
        end
        
        function Tab:CreateProgressBar(config)
            local ProgressFrame = Instance.new("Frame")
            ProgressFrame.Size = UDim2.new(1, 0, 0, 50)
            ProgressFrame.BackgroundColor3 = Theme.Surface
            ProgressFrame.Parent = Page
            
            local pCorner = Instance.new("UICorner")
            pCorner.CornerRadius = UDim.new(0, 10)
            pCorner.Parent = ProgressFrame
            
            CreateGradient(ProgressFrame, Theme.Surface, Color3.fromRGB(
                math.max(0, Theme.Surface.R*255-15),
                math.max(0, Theme.Surface.G*255-15),
                math.max(0, Theme.Surface.B*255-15)
            ) / 255, 0)
            
            local Label = Instance.new("TextLabel")
            Label.Parent = ProgressFrame
            Label.Size = UDim2.new(1, 0, 0, 20)
            Label.BackgroundTransparency = 1
            Label.Text = config.Name .. " : 0%"
            Label.TextColor3 = Theme.TextSecondary
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 13
            Label.Position = UDim2.new(0, 12, 0, 5)
            
            local ProgressBack = Instance.new("Frame")
            ProgressBack.Parent = ProgressFrame
            ProgressBack.BackgroundColor3 = Theme.Secondary
            ProgressBack.Position = UDim2.new(0, 12, 0, 25)
            ProgressBack.Size = UDim2.new(1, -24, 0, 14)
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
            
            CreateGradient(ProgressFill, Theme.Primary, Theme.Accent, 0)
            
            local function SetProgress(value)
                local clampedValue = math.clamp(value, 0, 100)
                TweenService:Create(ProgressFill, TWEEN_CONFIGS.Normal, {Size = UDim2.new(clampedValue / 100, 0, 1, 0)}):Play()
                Label.Text = config.Name .. " : " .. math.floor(clampedValue) .. "%"
            end
            
            return SetProgress
        end
        
        function Tab:CreateColorPalette(config)
            local PaletteFrame = Instance.new("Frame")
            PaletteFrame.Size = UDim2.new(1, 0, 0, 240)
            PaletteFrame.BackgroundColor3 = Theme.Surface
            PaletteFrame.Parent = Page
            
            local pCorner = Instance.new("UICorner")
            pCorner.CornerRadius = UDim.new(0, 10)
            pCorner.Parent = PaletteFrame
            
            CreateGradient(PaletteFrame, Theme.Surface, Color3.fromRGB(
                math.max(0, Theme.Surface.R*255-15),
                math.max(0, Theme.Surface.G*255-15),
                math.max(0, Theme.Surface.B*255-15)
            ) / 255, 0)
            
            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Parent = PaletteFrame
            TitleLabel.Size = UDim2.new(1, 0, 0, 22)
            TitleLabel.Position = UDim2.new(0, 0, 0, 8)
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.Text = config.Name or "Color Palette"
            TitleLabel.TextColor3 = Theme.TextSecondary
            TitleLabel.Font = Enum.Font.GothamBold
            TitleLabel.TextSize = 13
            
            local PaletteGrid = Instance.new("Frame")
            PaletteGrid.Parent = PaletteFrame
            PaletteGrid.BackgroundTransparency = 1
            PaletteGrid.Size = UDim2.new(1, -24, 1, -40)
            PaletteGrid.Position = UDim2.new(0, 12, 0, 30)
            
            local GridLayout = Instance.new("UIGridLayout")
            GridLayout.Parent = PaletteGrid
            GridLayout.CellSize = UDim2.new(0, 55, 0, 55)
            GridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
            GridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            GridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
            
            local presets = config.Presets or {
                Color3.fromRGB(45, 135, 255),
                Color3.fromRGB(255, 76, 76),
                Color3.fromRGB(76, 175, 80),
                Color3.fromRGB(255, 152, 0),
                Color3.fromRGB(156, 39, 176),
                Color3.fromRGB(0, 188, 212),
                Color3.fromRGB(244, 67, 54),
                Color3.fromRGB(233, 30, 99),
            }
            
            for _, colorVal in pairs(presets) do
                local ColorBtn = Instance.new("TextButton")
                ColorBtn.Parent = PaletteGrid
                ColorBtn.BackgroundColor3 = colorVal
                ColorBtn.Size = UDim2.new(0, 55, 0, 55)
                ColorBtn.Text = ""
                ColorBtn.BorderSizePixel = 0
                
                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(0, 10)
                btnCorner.Parent = ColorBtn
                
                local btnStroke = Instance.new("UIStroke")
                btnStroke.Thickness = 2
                btnStroke.Color = colorVal
                btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                btnStroke.Transparency = 0.6
                btnStroke.Parent = ColorBtn
                
                ColorBtn.MouseEnter:Connect(function()
                    TweenService:Create(ColorBtn, TWEEN_CONFIGS.VeryFast, {BackgroundColor3 = Color3.new(
                        math.min(1, colorVal.R * 1.2),
                        math.min(1, colorVal.G * 1.2),
                        math.min(1, colorVal.B * 1.2)
                    )}):Play()
                    TweenService:Create(btnStroke, TWEEN_CONFIGS.VeryFast, {Transparency = 0}):Play()
                end)
                
                ColorBtn.MouseLeave:Connect(function()
                    TweenService:Create(ColorBtn, TWEEN_CONFIGS.VeryFast, {BackgroundColor3 = colorVal}):Play()
                    TweenService:Create(btnStroke, TWEEN_CONFIGS.VeryFast, {Transparency = 0.6}):Play()
                end)
                
                ColorBtn.MouseButton1Click:Connect(function()
                    if config.Callback then
                        config.Callback(colorVal)
                    end
                    
                    for _, child in pairs(PaletteGrid:GetChildren()) do
                        if child:IsA("TextButton") then
                            local stroke = child:FindFirstChildOfClass("UIStroke")
                            if stroke then
                                if child.BackgroundColor3 == colorVal then
                                    TweenService:Create(stroke, TWEEN_CONFIGS.VeryFast, {Transparency = 0, Thickness = 3}):Play()
                                else
                                    TweenService:Create(stroke, TWEEN_CONFIGS.VeryFast, {Transparency = 0.6, Thickness = 2}):Play()
                                end
                            end
                        end
                    end
                end)
            end
        end
        
        return Tab
    end
    
    -- ═══════════════════════════════════════════════════════════════
    -- DEFAULT SETTINGS TAB
    -- ═══════════════════════════════════════════════════════════════
    
    local SettingsTab = Window:CreateTab("Settings", ICONS.Settings)
    
    SettingsTab:CreateLabel("── THEME ──")
    
    SettingsTab:CreateDropdown({
        Name = "Select Theme",
        Default = themeName,
        Items = {"Dark", "Light", "Purple", "Green", "Orange", "Cyan"},
        Callback = function(selectedTheme)
            -- Recreate window with new theme
            print("Theme changed to: " .. selectedTheme)
            Window:Notify("Theme: " .. selectedTheme, 2, "success")
        end
    })
    
    SettingsTab:CreateLabel("")
    SettingsTab:CreateLabel("── WINDOW ──")
    
    SettingsTab:CreateSlider({
        Name = "Window Transparency",
        Min = 0,
        Max = 50,
        Default = 0,
        Callback = function(value)
            Main.BackgroundTransparency = value / 100
        end
    })
    
    SettingsTab:CreateButton({
        Name = "Reset Window Position",
        Callback = function()
            Main.Position = UDim2.new(0.5, -initialWidth/2, 0.5, -initialHeight/2)
            Main.Size = UDim2.new(0, initialWidth, 0, initialHeight)
            Window:Notify("Window reset!", 2, "success")
        end
    })
    
    return Window
end

return UI
