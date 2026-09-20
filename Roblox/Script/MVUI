
local Services = {
    Players = game:GetService("Players"),
    CoreGui = game:GetService("CoreGui"),
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    RunService = game:GetService("RunService"),
    Workspace = game:GetService("Workspace")
}

local LocalPlayer = Services.Players.LocalPlayer

local Library = {}
Library.__index = Library

Library.Settings = {
    Animations = true,
    ToggleKey = Enum.KeyCode.RightBracket,
    MobileBreakpoint = 600,
    TabletBreakpoint = 1000,
    MinimumScale = 0.78
}

Library.Theme = {
    Background = Color3.fromRGB(12, 12, 14),
    Sidebar = Color3.fromRGB(16, 16, 20),
    Surface = Color3.fromRGB(22, 22, 26),
    SurfaceHover = Color3.fromRGB(30, 30, 35),
    Stroke = Color3.fromRGB(35, 35, 42),
    Text = Color3.fromRGB(240, 240, 245),
    TextSecondary = Color3.fromRGB(140, 140, 150),
    Accent = Color3.fromRGB(88, 101, 242),
    AccentDim = Color3.fromRGB(40, 45, 80),
    Success = Color3.fromRGB(46, 204, 113),
    Danger = Color3.fromRGB(231, 76, 60),
    Warning = Color3.fromRGB(241, 196, 15),
    CornerRadius = UDim.new(0, 6),
    CardRadius = UDim.new(0, 8),
    Font = Enum.Font.Gotham,
    FontMedium = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    FontMono = Enum.Font.RobotoMono
}

Library._connections = {}
Library._instances = {}
Library._tabs = {}
Library._themes = {}
Library._destroyed = false
Library._window = nil
Library._screenGui = nil
Library._toggleButton = nil

local function track(connection)
    table.insert(Library._connections, connection)
    return connection
end

local function trackInstance(instance)
    table.insert(Library._instances, instance)
    return instance
end

local function disconnectAll(list)
    if not list then return end
    for i = #list, 1, -1 do
        local connection = list[i]
        pcall(function()
            if connection and connection.Connected then
                connection:Disconnect()
            end
        end)
        list[i] = nil
    end
end

local function destroyAll(list)
    if not list then return end
    for i = #list, 1, -1 do
        local instance = list[i]
        pcall(function()
            if instance then instance:Destroy() end
        end)
        list[i] = nil
    end
end

local function tween(instance, info, properties)
    if Library._destroyed or not instance or not instance.Parent then return end
    if not Library.Settings.Animations then
        for property, value in pairs(properties) do
            pcall(function() instance[property] = value end)
        end
        return nil
    end
    local ok, animation = pcall(function()
        local t = Services.TweenService:Create(instance, info, properties)
        t:Play()
        return t
    end)
    return ok and animation or nil
end

local function corner(parent, radius)
    local c = trackInstance(Instance.new("UICorner"))
    c.CornerRadius = radius or Library.Theme.CornerRadius
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness)
    local s = trackInstance(Instance.new("UIStroke"))
    s.Color = color or Library.Theme.Stroke
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function padding(parent, top, bottom, left, right)
    local p = trackInstance(Instance.new("UIPadding"))
    p.PaddingTop = UDim.new(0, top or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft = UDim.new(0, left or 0)
    p.PaddingRight = UDim.new(0, right or 0)
    p.Parent = parent
    return p
end

local function addText(parent, properties)
    local label = trackInstance(Instance.new("TextLabel"))
    for property, value in pairs(properties) do label[property] = value end
    label.Parent = parent
    return label
end

local function addButton(parent, properties)
    local button = trackInstance(Instance.new("TextButton"))
    for property, value in pairs(properties) do button[property] = value end
    button.AutoButtonColor = false
    button.Parent = parent
    return button
end

local function getViewport()
    local camera = Services.Workspace.CurrentCamera
    return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

local function getDeviceType()
    local viewport = getViewport()
    if viewport.X <= Library.Settings.MobileBreakpoint then
        return "Mobile"
    elseif viewport.X <= Library.Settings.TabletBreakpoint then
        return "Tablet"
    end
    return "Desktop"
end

local function updateThemeRecursive(root)
    if not root then return end
    for _, obj in ipairs(root:GetDescendants()) do
        local role = obj:GetAttribute("MVThemeRole")
        if role then
            local color = Library.Theme[role]
            if color then
                if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                    obj.TextColor3 = color
                elseif obj:IsA("Frame") then
                    obj.BackgroundColor3 = color
                elseif obj:IsA("UIStroke") then
                    obj.Color = color
                end
            end
        end
    end
end

function Library:GetDeviceType()
    return getDeviceType()
end

function Library:SetBreakpoint(name, value)
    assert(type(name) == "string", "Breakpoint name must be a string")
    assert(type(value) == "number", "Breakpoint value must be a number")
    if name == "Mobile" then
        self.Settings.MobileBreakpoint = value
    elseif name == "Tablet" then
        self.Settings.TabletBreakpoint = value
    end
    if self._window and self._window._responsiveUpdate then
        self._window:_responsiveUpdate()
    end
end

function Library:RegisterTheme(name, theme)
    assert(type(name) == "string", "Theme name must be a string")
    assert(type(theme) == "table", "Theme must be a table")
    self._themes[name] = theme
end

function Library:SetTheme(theme)
    assert(type(theme) == "table", "Theme must be a table")
    for key, value in pairs(theme) do
        self.Theme[key] = value
    end
    if self._screenGui then
        updateThemeRecursive(self._screenGui)
    end
    if self._window and self._window._refreshVisuals then
        self._window:_refreshVisuals()
    end
end

function Library:GetTheme()
    local copy = {}
    for key, value in pairs(self.Theme) do copy[key] = value end
    return copy
end

function Library:Notify(options)
    options = options or {}
    if self._destroyed or not self._window then return end

    local title = tostring(options.Title or "Notification")
    local description = tostring(options.Description or "")
    local kind = tostring(options.Type or "Info")
    local duration = tonumber(options.Duration) or 3

    local typeColors = {
        Info = self.Theme.Accent,
        Success = self.Theme.Success,
        Warning = self.Theme.Warning,
        Error = self.Theme.Danger
    }
    local typeColor = typeColors[kind] or self.Theme.Accent

    local container = self._window._toastContainer
    if not container then return end

    local toast = trackInstance(Instance.new("Frame"))
    toast.Name = "Toast"
    toast.Size = UDim2.new(1, 0, 0, description == "" and 48 or 60)
    toast.BackgroundColor3 = self.Theme.Surface
    toast.BorderSizePixel = 0
    toast.Position = UDim2.new(1, 24, 0, 0)
    toast.BackgroundTransparency = 1
    corner(toast, self.Theme.CardRadius)
    local toastStroke = stroke(toast, typeColor, 1)
    toastStroke.Transparency = 1

    local titleLabel = addText(toast, {
        Name = "Title",
        Size = UDim2.new(1, -22, 0, 18),
        Position = UDim2.new(0, 12, 0, 7),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = self.Theme.Text,
        Font = self.Theme.FontMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    if description ~= "" then
        addText(toast, {
            Name = "Description",
            Size = UDim2.new(1, -22, 0, 25),
            Position = UDim2.new(0, 12, 0, 27),
            BackgroundTransparency = 1,
            Text = description,
            TextColor3 = self.Theme.TextSecondary,
            Font = self.Theme.Font,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
    end

    toast.Parent = container
    if self.Settings.Animations then
        tween(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 0)})
        tween(toastStroke, TweenInfo.new(0.3), {Transparency = 0})
    else
        toast.BackgroundTransparency = 0
        toast.Position = UDim2.new(0, 0, 0, 0)
        toastStroke.Transparency = 0
    end

    task.delay(duration, function()
        if not toast or not toast.Parent then return end
        if self.Settings.Animations then
            local exitTween = tween(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {BackgroundTransparency = 1, Position = UDim2.new(1, 24, 0, 0)})
            tween(toastStroke, TweenInfo.new(0.2), {Transparency = 1})
            if exitTween then
                track(exitTween.Completed:Connect(function()
                    pcall(function() toast:Destroy() end)
                end))
            else
                pcall(function() toast:Destroy() end)
            end
        else
            pcall(function() toast:Destroy() end)
        end
    end)
end

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

local function makeSectionHeader(parent, name)
    local label = addText(parent, {
        Name = "SectionTitle",
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = string.upper(tostring(name or "Section")),
        TextColor3 = Library.Theme.TextSecondary,
        Font = Library.Theme.FontMedium,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    label.LayoutOrder = -1000
    return label
end

function Library:CreateWindow(options)
    options = options or {}
    if self._window then
        self._window:Destroy()
    end

    self._destroyed = false
    self._connections = {}
    self._instances = {}
    self._tabs = {}

    local uiName = tostring(options.Name or "MVUI")
    local screenGui = trackInstance(Instance.new("ScreenGui"))
    screenGui.Name = uiName
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = self.CoreGui
    self._screenGui = screenGui

    local window = setmetatable({
        Library = self,
        Title = tostring(options.Title or "MV UI"),
        Version = tostring(options.Version or ""),
        Width = tonumber(options.Width) or 580,
        Height = tonumber(options.Height) or 360,
        MinWidth = tonumber(options.MinWidth) or 280,
        MinHeight = tonumber(options.MinHeight) or 240,
        Tabs = {},
        CurrentTab = nil,
        Hidden = false,
        Minimized = false,
        _connections = {},
        _instances = {},
    }, Window)

    if options.ToggleKey then
        self.Settings.ToggleKey = options.ToggleKey
    end

    self._window = window

    local root = trackInstance(Instance.new("Frame"))
    root.Name = "AppWindow"
    root.Size = UDim2.fromOffset(window.Width, window.Height)
    root.Position = UDim2.new(0.5, -window.Width / 2, 0.5, -window.Height / 2)
    root.BackgroundColor3 = self.Theme.Background
    root.BorderSizePixel = 0
    root.ClipsDescendants = true
    root.Parent = screenGui
    window.Root = root
    window._instances = {root}
    corner(root, self.Theme.CardRadius)
    stroke(root, self.Theme.Stroke, 1)

    local uiScale = trackInstance(Instance.new("UIScale"))
    uiScale.Parent = root
    window.UIScale = uiScale

    local canvas = trackInstance(Instance.new("CanvasGroup"))
    canvas.Name = "Canvas"
    canvas.Size = UDim2.fromScale(1, 1)
    canvas.BackgroundTransparency = 1
    canvas.Parent = root
    window.Canvas = canvas

    local header = trackInstance(Instance.new("Frame"))
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 44)
    header.BackgroundColor3 = self.Theme.Background
    header.BorderSizePixel = 0
    header.Parent = canvas
    window.Header = header

    local titleFrame = trackInstance(Instance.new("Frame"))
    titleFrame.Size = UDim2.new(1, -88, 1, 0)
    titleFrame.BackgroundTransparency = 1
    titleFrame.Parent = header

    local title = addText(titleFrame, {
        Name = "Title",
        Size = UDim2.new(1, -16, 0, 18),
        Position = UDim2.new(0, 14, 0, 7),
        BackgroundTransparency = 1,
        Text = window.Title,
        TextColor3 = self.Theme.Text,
        Font = self.Theme.FontBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    window.TitleLabel = title

    if window.Version ~= "" then
        local version = addText(titleFrame, {
            Name = "Version",
            Size = UDim2.new(1, -16, 0, 13),
            Position = UDim2.new(0, 14, 0, 25),
            BackgroundTransparency = 1,
            Text = window.Version,
            TextColor3 = self.Theme.TextSecondary,
            Font = self.Theme.Font,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
        window.VersionLabel = version
    end

    local controls = trackInstance(Instance.new("Frame"))
    controls.Name = "Controls"
    controls.Size = UDim2.fromOffset(60, 26)
    controls.Position = UDim2.new(1, -70, 0, 8)
    controls.BackgroundTransparency = 1
    controls.ZIndex = 50
    controls.Parent = header

    local function controlButton(textValue, x, hover, callback)
        local btn = addButton(controls, {
            Name = "Control",
            Size = UDim2.fromOffset(26, 26),
            Position = UDim2.fromOffset(x, 0),
            BackgroundColor3 = self.Theme.Surface,
            BorderSizePixel = 0,
            Text = textValue,
            TextColor3 = self.Theme.TextSecondary,
            Font = self.Theme.FontMedium,
            TextSize = 14,
            ZIndex = 51,
        })
        corner(btn, UDim.new(0, 4))
        stroke(btn, self.Theme.Stroke, 1)
        track(btn.MouseEnter:Connect(function()
            if getDeviceType() ~= "Mobile" then
                tween(btn, TweenInfo.new(0.15), {BackgroundColor3 = hover, TextColor3 = self.Theme.Text})
            end
        end))
        track(btn.MouseLeave:Connect(function()
            tween(btn, TweenInfo.new(0.15), {BackgroundColor3 = self.Theme.Surface, TextColor3 = self.Theme.TextSecondary})
        end))
        track(btn.Activated:Connect(callback))
        return btn
    end

    controlButton("-", 0, self.Theme.SurfaceHover, function()
        window:SetMinimized(not window.Minimized)
    end)

    controlButton("×", 34, self.Theme.Danger, function()
        window:Destroy()
    end)

    local body = trackInstance(Instance.new("Frame"))
    body.Name = "Body"
    body.Size = UDim2.new(1, 0, 1, -44)
    body.Position = UDim2.new(0, 0, 0, 44)
    body.BackgroundTransparency = 1
    body.Parent = canvas
    window.Body = body

    local sidebar = trackInstance(Instance.new("Frame"))
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 140, 1, 0)
    sidebar.BackgroundColor3 = self.Theme.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.Parent = body
    window.Sidebar = sidebar

    local divider = trackInstance(Instance.new("Frame"))
    divider.Size = UDim2.new(0, 1, 1, 0)
    divider.Position = UDim2.new(1, -1, 0, 0)
    divider.BackgroundColor3 = self.Theme.Stroke
    divider.BorderSizePixel = 0
    divider.Parent = sidebar

    local logo = addText(sidebar, {
        Name = "Logo",
        Size = UDim2.new(1, -16, 0, 44),
        Position = UDim2.fromOffset(8, 0),
        BackgroundTransparency = 1,
        Text = "  " .. (options.LogoText or window.Title),
        TextColor3 = self.Theme.Text,
        Font = self.Theme.FontBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    window.LogoLabel = logo

    local nav = trackInstance(Instance.new("ScrollingFrame"))
    nav.Name = "Navigation"
    nav.Size = UDim2.new(1, -20, 1, -54)
    nav.Position = UDim2.fromOffset(10, 48)
    nav.BackgroundTransparency = 1
    nav.BorderSizePixel = 0
    nav.ScrollBarThickness = 2
    nav.ScrollBarImageColor3 = self.Theme.Accent
    nav.AutomaticCanvasSize = Enum.AutomaticSize.Y
    nav.CanvasSize = UDim2.new(0, 0, 0, 0)
    nav.Parent = sidebar
    window.Nav = nav

    local navLayout = trackInstance(Instance.new("UIListLayout"))
    navLayout.SortOrder = Enum.SortOrder.LayoutOrder
    navLayout.Padding = UDim.new(0, 5)
    navLayout.Parent = nav

    local content = trackInstance(Instance.new("Frame"))
    content.Name = "Content"
    content.Size = UDim2.new(1, -140, 1, 0)
    content.Position = UDim2.fromOffset(140, 0)
    content.BackgroundTransparency = 1
    content.Parent = body
    window.Content = content

    local toast = trackInstance(Instance.new("Frame"))
    toast.Name = "Toasts"
    toast.Size = UDim2.new(0, 250, 0, 140)
    toast.Position = UDim2.new(1, -270, 1, -150)
    toast.BackgroundTransparency = 1
    toast.ZIndex = 200
    toast.Parent = screenGui
    window._toastContainer = toast

    local toastLayout = trackInstance(Instance.new("UIListLayout"))
    toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
    toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    toastLayout.Padding = UDim.new(0, 8)
    toastLayout.Parent = toast

    local floating = trackInstance(Instance.new("TextButton"))
    floating.Name = "ToggleButton"
    floating.Size = UDim2.fromOffset(44, 44)
    floating.Position = UDim2.new(0, 15, 0.5, -22)
    floating.BackgroundColor3 = self.Theme.Sidebar
    floating.BorderSizePixel = 0
    floating.Text = tostring(options.ToggleText or "MV")
    floating.TextColor3 = self.Theme.Accent
    floating.Font = self.Theme.FontBold
    floating.TextSize = 13
    floating.AutoButtonColor = false
    floating.ZIndex = 250
    floating.Parent = screenGui
    corner(floating, UDim.new(1, 0))
    stroke(floating, self.Theme.Accent, 1.5)
    window.ToggleButton = floating
    self._toggleButton = floating

    local dragging = false
    local dragStart = nil
    local startPosition = nil

    local function startDrag(input)
        if window.Minimized then return end
        dragging = true
        dragStart = input.Position
        startPosition = root.Position
    end

    track(root.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if input.Position.Y <= root.AbsolutePosition.Y + 48 then
                startDrag(input)
            end
        end
    end))

    track(Services.UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local scaleValue = uiScale.Scale
        local delta = input.Position - dragStart
        local viewport = getViewport()
        local absolute = root.AbsoluteSize
        local newX = startPosition.X.Offset + delta.X / scaleValue
        local newY = startPosition.Y.Offset + delta.Y / scaleValue
        newX = math.clamp(newX, -absolute.X + 64, viewport.X - 64)
        newY = math.clamp(newY, -absolute.Y + 44, viewport.Y - 44)
        root.Position = UDim2.new(0, newX, 0, newY)
    end))

    track(Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    local floatingDragging = false
    local floatingStart = nil
    local floatingOrigin = nil

    track(floating.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            floatingDragging = true
            floatingStart = input.Position
            floatingOrigin = floating.Position
        end
    end))

    track(Services.UserInputService.InputChanged:Connect(function(input)
        if not floatingDragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - floatingStart
        local viewport = getViewport()
        local x = math.clamp(floatingOrigin.X.Offset + delta.X, 4, math.max(4, viewport.X - floating.AbsoluteSize.X - 4))
        local y = math.clamp(floatingOrigin.Y.Offset + delta.Y, 4, math.max(4, viewport.Y - floating.AbsoluteSize.Y - 4))
        floating.Position = UDim2.fromOffset(x, y)
    end))

    track(Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            floatingDragging = false
        end
    end))

    track(floating.Activated:Connect(function()
        if window._didDragFloating then
            window._didDragFloating = false
            return
        end
        window:Toggle()
    end))

    local floatingLast = floating.Position
    track(Services.RunService.RenderStepped:Connect(function()
        if floating.Position ~= floatingLast then
            window._didDragFloating = true
            floatingLast = floating.Position
        end
    end))

    track(Services.UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == self.Settings.ToggleKey then
            window:Toggle()
        end
    end))

    function window:_refreshVisuals()
        updateThemeRecursive(root)
        if window.ToggleButton then
            window.ToggleButton.BackgroundColor3 = self.Library.Theme.Sidebar
            window.ToggleButton.TextColor3 = self.Library.Theme.Accent
        end
    end

    function window:SetMinimized(value)
        value = value == true
        self.Minimized = value
        if value then
            if self._preMinimizeHeight == nil then self._preMinimizeHeight = root.Size.Y.Offset end
            if self.Library.Settings.Animations then
                tween(root, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(root.Size.X.Offset, 50)})
                tween(canvas, TweenInfo.new(0.16), {GroupTransparency = 1})
            else
                root.Size = UDim2.fromOffset(root.Size.X.Offset, 50)
                canvas.GroupTransparency = 1
            end
        else
            local targetHeight = self._preMinimizeHeight or self.Height
            if self.Library.Settings.Animations then
                tween(root, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(root.Size.X.Offset, targetHeight)})
                tween(canvas, TweenInfo.new(0.16), {GroupTransparency = 0})
            else
                root.Size = UDim2.fromOffset(root.Size.X.Offset, targetHeight)
                canvas.GroupTransparency = 0
            end
        end
    end

    function window:SetVisible(value)
        local visible = value == true
        self.Hidden = not visible
        root.Visible = visible
        floating.Visible = not visible or getDeviceType() == "Mobile"
    end

    function window:Toggle()
        self:SetVisible(self.Hidden)
    end

    function window:Hide()
        self:SetVisible(false)
    end

    function window:Show()
        self:SetVisible(true)
    end

    function window:CreateTab(tabOptions)
        tabOptions = tabOptions or {}
        local name = tostring(tabOptions.Name or ("Tab " .. tostring(#self.Tabs + 1)))
        local tab = setmetatable({
            Window = self,
            Name = name,
            Sections = {},
            Current = false,
            _connections = {},
            _instances = {}
        }, Tab)

        local button = addButton(nav, {
            Name = "TabButton",
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = self.Library.Theme.Sidebar,
            BorderSizePixel = 0,
            Text = "  " .. name,
            TextColor3 = self.Library.Theme.TextSecondary,
            Font = self.Library.Theme.FontMedium,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = #self.Tabs + 1,
        })
        corner(button, self.Library.Theme.CornerRadius)
        tab.Button = button

        local page = trackInstance(Instance.new("CanvasGroup"))
        page.Name = name .. "Page"
        page.Size = UDim2.fromScale(1, 1)
        page.BackgroundTransparency = 1
        page.GroupTransparency = 1
        page.Visible = false
        page.Parent = content
        tab.Page = page

        local scroll = trackInstance(Instance.new("ScrollingFrame"))
        scroll.Name = "Scroll"
        scroll.Size = UDim2.fromScale(1, 1)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 3
        scroll.ScrollBarImageColor3 = self.Library.Theme.Accent
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.Parent = page
        tab.Scroll = scroll

        local list = trackInstance(Instance.new("UIListLayout"))
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Padding = UDim.new(0, 10)
        list.Parent = scroll
        tab.Layout = list
        padding(scroll, 14, 14, 14, 14)

        local function switch()
            self:SelectTab(name)
        end

        track(button.Activated:Connect(switch))
        track(button.MouseEnter:Connect(function()
            if tab.Current and getDeviceType() ~= "Mobile" then return end
            if getDeviceType() ~= "Mobile" then
                tween(button, TweenInfo.new(0.15), {BackgroundColor3 = self.Library.Theme.SurfaceHover, TextColor3 = self.Library.Theme.Text})
            end
        end))
        track(button.MouseLeave:Connect(function()
            if tab.Current then return end
            tween(button, TweenInfo.new(0.15), {BackgroundColor3 = self.Library.Theme.Sidebar, TextColor3 = self.Library.Theme.TextSecondary})
        end))

        table.insert(self.Tabs, tab)
        self.Library._tabs[name] = tab

        if #self.Tabs == 1 then
            self:SelectTab(name)
        end
        return tab
    end

    function window:SelectTab(name)
        local target = nil
        for _, tab in ipairs(self.Tabs) do
            if tab.Name == name then target = tab break end
        end
        if not target then return end
        self.CurrentTab = target

        for _, tab in ipairs(self.Tabs) do
            local active = tab == target
            tab.Current = active
            tab.Page.Visible = active or self.Library.Settings.Animations
            if active then
                tab.Page.GroupTransparency = 0
                tween(tab.Button, TweenInfo.new(0.15), {BackgroundColor3 = self.Library.Theme.SurfaceHover, TextColor3 = self.Library.Theme.Text})
            else
                tween(tab.Button, TweenInfo.new(0.15), {BackgroundColor3 = self.Library.Theme.Sidebar, TextColor3 = self.Library.Theme.TextSecondary})
                if self.Library.Settings.Animations then
                    tween(tab.Page, TweenInfo.new(0.15), {GroupTransparency = 1})
                    task.delay(0.16, function()
                        if tab ~= self.CurrentTab and tab.Page then tab.Page.Visible = false end
                    end)
                else
                    tab.Page.Visible = false
                    tab.Page.GroupTransparency = 1
                end
            end
        end
    end

    function window:GetTab(name)
        for _, tab in ipairs(self.Tabs) do if tab.Name == name then return tab end end
    end

    function window:_applyResponsive()
        local device = getDeviceType()
        local viewport = getViewport()
        local targetWidth = self.Width
        local targetHeight = self.Height

        if device == "Mobile" then
            targetWidth = math.clamp(viewport.X - 20, math.min(self.MinWidth, math.max(240, viewport.X - 20)), 430)
            targetHeight = math.clamp(viewport.Y - 24, self.MinHeight, 560)
            sidebar.Visible = false
            content.Size = UDim2.fromScale(1, 1)
            content.Position = UDim2.fromOffset(0, 0)
            header.Size = UDim2.new(1, 0, 0, 48)
        elseif device == "Tablet" then
            targetWidth = math.clamp(math.min(self.Width, viewport.X - 40), 420, self.Width)
            targetHeight = math.clamp(math.min(self.Height, viewport.Y - 40), self.MinHeight, self.Height)
            sidebar.Visible = true
            sidebar.Size = UDim2.new(0, 120, 1, 0)
            content.Size = UDim2.new(1, -120, 1, 0)
            content.Position = UDim2.fromOffset(120, 0)
            header.Size = UDim2.new(1, 0, 0, 44)
        else
            targetWidth = math.min(self.Width, viewport.X - 40)
            targetHeight = math.min(self.Height, viewport.Y - 40)
            sidebar.Visible = true
            sidebar.Size = UDim2.new(0, 140, 1, 0)
            content.Size = UDim2.new(1, -140, 1, 0)
            content.Position = UDim2.fromOffset(140, 0)
            header.Size = UDim2.new(1, 0, 0, 44)
        end

        local scaleValue = math.min(1, viewport.X / (targetWidth + 24), viewport.Y / (targetHeight + 24))
        uiScale.Scale = math.max(scaleValue, self.Library.Settings.MinimumScale)
        root.Size = UDim2.fromOffset(targetWidth, self.Minimized and 50 or targetHeight)

        for _, tab in ipairs(self.Tabs) do
            if tab._responsiveUpdate then tab:_responsiveUpdate(device) end
        end
    end

    function window:_responsiveUpdate()
        self:_applyResponsive()
    end

    function window:_refreshVisuals()
        root.BackgroundColor3 = self.Library.Theme.Background
        sidebar.BackgroundColor3 = self.Library.Theme.Sidebar
        header.BackgroundColor3 = self.Library.Theme.Background
        logo.TextColor3 = self.Library.Theme.Text
        title.TextColor3 = self.Library.Theme.Text
        if window.VersionLabel then window.VersionLabel.TextColor3 = self.Library.Theme.TextSecondary end
        updateThemeRecursive(root)
    end

    function window:Destroy()
        if self.Library._destroyed then return end
        self.Library._destroyed = true
        disconnectAll(self.Library._connections)
        disconnectAll(self._connections)
        destroyAll(self.Library._instances)
        self.Library._window = nil
        self.Library._screenGui = nil
        self.Library._toggleButton = nil
    end

    track(Services.Workspace.CurrentCamera and Services.Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        if not self.Library._destroyed then
            self:_responsiveUpdate()
        end
    end))

    self._responsiveWindow = window
    window:_responsiveUpdate()

    if options.ShowOnStart == false then
        window:Hide()
    end

    return window
end

function Tab:_responsiveUpdate(device)
    if device == "Mobile" then
        padding(self.Scroll, 12, 12, 10, 10)
    else
        padding(self.Scroll, 14, 14, 14, 14)
    end
end

function Tab:CreateSection(options)
    options = options or {}
    local section = setmetatable({
        Tab = self,
        Name = tostring(options.Name or "Section"),
        _instances = {},
        _connections = {},
        _order = #self.Sections + 1
    }, Section)

    local holder = trackInstance(Instance.new("Frame"))
    holder.Name = section.Name .. "Section"
    holder.Size = UDim2.new(1, 0, 0, 0)
    holder.BackgroundTransparency = 1
    holder.AutomaticSize = Enum.AutomaticSize.Y
    holder.LayoutOrder = section._order
    holder.Parent = self.Scroll
    section.Container = holder

    local list = trackInstance(Instance.new("UIListLayout"))
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 8)
    list.Parent = holder
    section.Layout = list

    if options.Name ~= false and options.Name ~= "" then
        local header = makeSectionHeader(holder, section.Name)
        header.LayoutOrder = -1000
        section.Header = header
    end

    table.insert(self.Sections, section)
    return section
end

local function createRow(section, height, order)
    local row = trackInstance(Instance.new("Frame"))
    row.Size = UDim2.new(1, 0, 0, height)
    row.BackgroundColor3 = Library.Theme.Surface
    row.BorderSizePixel = 0
    row.LayoutOrder = order or 1
    row.Parent = section.Container
    corner(row, Library.Theme.CardRadius)
    stroke(row, Library.Theme.Stroke, 1)
    return row
end

function Section:CreateToggle(options)
    options = options or {}
    local active = options.Default == true
    local row = createRow(self, tonumber(options.Height) or 56, options.Order)

    addText(row, {
        Size = UDim2.new(1, -82, 0, 18),
        Position = UDim2.fromOffset(15, 7),
        BackgroundTransparency = 1,
        Text = tostring(options.Name or "Toggle"),
        TextColor3 = Library.Theme.Text,
        Font = Library.Theme.FontMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    addText(row, {
        Size = UDim2.new(1, -82, 0, 17),
        Position = UDim2.fromOffset(15, 27),
        BackgroundTransparency = 1,
        Text = tostring(options.Description or ""),
        TextColor3 = Library.Theme.TextSecondary,
        Font = Library.Theme.Font,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    local toggle = addButton(row, {
        Size = UDim2.fromOffset(44, 24),
        Position = UDim2.new(1, -59, 0.5, -12),
        BackgroundColor3 = active and Library.Theme.Accent or Library.Theme.Stroke,
        BorderSizePixel = 0,
        Text = "",
    })
    corner(toggle, UDim.new(1, 0))

    local knob = trackInstance(Instance.new("Frame"))
    knob.Size = UDim2.fromOffset(18, 18)
    knob.Position = UDim2.new(0, active and 23 or 3, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = toggle
    corner(knob, UDim.new(1, 0))

    local api = {Instance = row, Button = toggle, Value = active}

    local function setValue(value, silent)
        value = value == true
        active = value
        api.Value = value
        tween(toggle, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = value and Library.Theme.Accent or Library.Theme.Stroke})
        tween(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, value and 23 or 3, 0.5, -9)})
        if not silent and options.Callback then
            task.spawn(options.Callback, value)
        end
    end

    function api:Set(value, silent) setValue(value, silent) end
    function api:Get() return active end

    track(toggle.Activated:Connect(function() setValue(not active, false) end))
    if options.Callback and options.FireOnCreate then
        task.spawn(options.Callback, active)
    end

    return api
end

function Section:CreateButton(options)
    options = options or {}
    local row = createRow(self, tonumber(options.Height) or 48, options.Order)

    local title = addText(row, {
        Size = UDim2.new(1, -120, 1, 0),
        Position = UDim2.fromOffset(15, 0),
        BackgroundTransparency = 1,
        Text = tostring(options.Name or "Button"),
        TextColor3 = Library.Theme.Text,
        Font = Library.Theme.FontMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    if options.Description then
        title.Size = UDim2.new(1, -128, 0, 18)
        title.Position = UDim2.fromOffset(15, 6)
        addText(row, {
            Size = UDim2.new(1, -128, 0, 15),
            Position = UDim2.fromOffset(15, 25),
            BackgroundTransparency = 1,
            Text = tostring(options.Description),
            TextColor3 = Library.Theme.TextSecondary,
            Font = Library.Theme.Font,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
    end

    local btn = addButton(row, {
        Size = UDim2.fromOffset(86, 28),
        Position = UDim2.new(1, -101, 0.5, -14),
        BackgroundColor3 = Library.Theme.Sidebar,
        BorderSizePixel = 0,
        Text = tostring(options.Label or "Execute"),
        TextColor3 = Library.Theme.Accent,
        Font = Library.Theme.FontBold,
        TextSize = 11,
    })
    corner(btn, UDim.new(0, 4))
    stroke(btn, Library.Theme.Stroke, 1)

    track(btn.MouseEnter:Connect(function()
        if getDeviceType() ~= "Mobile" then
            tween(btn, TweenInfo.new(0.15), {BackgroundColor3 = Library.Theme.SurfaceHover, TextColor3 = Library.Theme.Text})
        end
    end))
    track(btn.MouseLeave:Connect(function()
        tween(btn, TweenInfo.new(0.15), {BackgroundColor3 = Library.Theme.Sidebar, TextColor3 = Library.Theme.Accent})
    end))
    track(btn.Activated:Connect(function()
        if options.Callback then task.spawn(options.Callback) end
    end))

    return {Instance = row, Button = btn}
end

function Section:CreateSlider(options)
    options = options or {}
    local minVal = tonumber(options.Min) or 0
    local maxVal = tonumber(options.Max) or 100
    local value = math.clamp(tonumber(options.Default) or minVal, minVal, maxVal)
    local decimals = tonumber(options.Decimals)
    if decimals == nil then decimals = 2 end

    local hasDescription = options.Description ~= nil and tostring(options.Description) ~= ""
    local row = createRow(self, tonumber(options.Height) or (hasDescription and 82 or 66), options.Order)

    addText(row, {
        Size = UDim2.new(1, -90, 0, 18),
        Position = UDim2.fromOffset(15, 6),
        BackgroundTransparency = 1,
        Text = tostring(options.Name or "Slider"),
        TextColor3 = Library.Theme.Text,
        Font = Library.Theme.FontMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    if hasDescription then
        addText(row, {
            Size = UDim2.new(1, -30, 0, 15),
            Position = UDim2.fromOffset(15, 26),
            BackgroundTransparency = 1,
            Text = tostring(options.Description),
            TextColor3 = Library.Theme.TextSecondary,
            Font = Library.Theme.Font,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
    end

    local valueLabel = addText(row, {
        Size = UDim2.fromOffset(70, 18),
        Position = UDim2.new(1, -85, 0, 6),
        BackgroundTransparency = 1,
        Text = string.format("%." .. decimals .. "f", value),
        TextColor3 = Library.Theme.TextSecondary,
        Font = Library.Theme.FontMono,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
    })

    local bar = trackInstance(Instance.new("Frame"))
    bar.Size = UDim2.new(1, -30, 0, 6)
    bar.Position = UDim2.new(0, 15, 0, hasDescription and 61 or 45)
    bar.BackgroundColor3 = Library.Theme.Stroke
    bar.BorderSizePixel = 0
    bar.Parent = row
    corner(bar, UDim.new(1, 0))

    local fill = trackInstance(Instance.new("Frame"))
    fill.BackgroundColor3 = Library.Theme.Accent
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new((value - minVal) / math.max(0.000001, maxVal - minVal), 0, 1, 0)
    fill.Parent = bar
    corner(fill, UDim.new(1, 0))

    local draggingSlider = false
    local api = {Instance = row, Value = value}

    local function roundValue(val)
        local mult = 10 ^ decimals
        return math.floor(val * mult + 0.5) / mult
    end

    local function setValue(val, silent)
        value = math.clamp(roundValue(val), minVal, maxVal)
        api.Value = value
        local pct = (value - minVal) / math.max(0.000001, maxVal - minVal)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        valueLabel.Text = string.format("%." .. decimals .. "f", value)
        if not silent and options.Callback then task.spawn(options.Callback, value) end
    end

    local function updateFromInput(input)
        local pct = math.clamp((input.Position.X - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
        setValue(minVal + (maxVal - minVal) * pct, false)
    end

    track(bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = true
            updateFromInput(input)
        end
    end))
    track(Services.UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(input)
        end
    end))
    track(Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = false end
    end))

    function api:Set(val, silent) setValue(val, silent) end
    function api:Get() return value end
    if options.Callback and options.FireOnCreate then task.spawn(options.Callback, value) end
    return api
end

function Section:CreateKeybind(options)
    options = options or {}
    local defaultKey = options.Default or Enum.KeyCode.RightShift
    local key = defaultKey
    local listening = false
    local hasDescription = options.Description ~= nil and tostring(options.Description) ~= ""
    local row = createRow(self, tonumber(options.Height) or (hasDescription and 62 or 48), options.Order)

    addText(row, {
        Size = UDim2.new(1, -110, 0, 18),
        Position = UDim2.fromOffset(15, hasDescription and 6 or 0),
        BackgroundTransparency = 1,
        Text = tostring(options.Name or "Keybind"),
        TextColor3 = Library.Theme.Text,
        Font = Library.Theme.FontMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    if hasDescription then
        addText(row, {
            Size = UDim2.new(1, -110, 0, 15),
            Position = UDim2.fromOffset(15, 26),
            BackgroundTransparency = 1,
            Text = tostring(options.Description),
            TextColor3 = Library.Theme.TextSecondary,
            Font = Library.Theme.Font,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
    end

    local btn = addButton(row, {
        Size = UDim2.fromOffset(80, 26),
        Position = UDim2.new(1, -95, 0.5, -13),
        BackgroundColor3 = Library.Theme.Sidebar,
        BorderSizePixel = 0,
        Text = typeof(key) == "EnumItem" and key.Name or tostring(key),
        TextColor3 = Library.Theme.Accent,
        Font = Library.Theme.FontBold,
        TextSize = 11,
    })
    corner(btn, UDim.new(0, 4))
    stroke(btn, Library.Theme.Stroke, 1)

    local api = {Instance = row, Button = btn, Value = key}

    track(btn.Activated:Connect(function()
        listening = true
        btn.Text = "Press Key..."
        btn.TextColor3 = Library.Theme.Warning
    end))

    track(Services.UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not listening then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            listening = false
            key = input.KeyCode
            api.Value = key
            btn.Text = key.Name
            btn.TextColor3 = Library.Theme.Accent
            if options.Callback then task.spawn(options.Callback, key) end
        end
    end))

    function api:Set(value, silent)
        key = value
        api.Value = value
        btn.Text = typeof(value) == "EnumItem" and value.Name or tostring(value)
        if not silent and options.Callback then task.spawn(options.Callback, value) end
    end
    function api:Get() return key end
    return api
end

function Section:CreateDropdown(options)
    options = options or {}
    local values = options.Values or options.Options or {}
    local selected = options.Default
    if selected == nil and #values > 0 then selected = values[1] end
    local open = false

    local hasDescription = options.Description ~= nil and tostring(options.Description) ~= ""
    local row = createRow(self, hasDescription and 62 or 48, options.Order)
    addText(row, {
        Size = UDim2.new(1, -130, 0, 18),
        Position = UDim2.fromOffset(15, hasDescription and 6 or 0),
        BackgroundTransparency = 1,
        Text = tostring(options.Name or "Dropdown"),
        TextColor3 = Library.Theme.Text,
        Font = Library.Theme.FontMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    if hasDescription then
        addText(row, {
            Size = UDim2.new(1, -130, 0, 15),
            Position = UDim2.fromOffset(15, 26),
            BackgroundTransparency = 1,
            Text = tostring(options.Description),
            TextColor3 = Library.Theme.TextSecondary,
            Font = Library.Theme.Font,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
    end

    local selectedButton = addButton(row, {
        Size = UDim2.fromOffset(105, 28),
        Position = UDim2.new(1, -120, 0.5, -14),
        BackgroundColor3 = Library.Theme.Sidebar,
        BorderSizePixel = 0,
        Text = tostring(selected or "Select"),
        TextColor3 = Library.Theme.TextSecondary,
        Font = Library.Theme.FontMedium,
        TextSize = 11,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    corner(selectedButton, UDim.new(0, 4))
    stroke(selectedButton, Library.Theme.Stroke, 1)

    local menu = trackInstance(Instance.new("Frame"))
    menu.Name = "DropdownMenu"
    menu.Visible = false
    menu.Size = UDim2.new(0, 105, 0, 0)
    menu.Position = UDim2.new(1, -120, 1, 4)
    menu.BackgroundColor3 = Library.Theme.Sidebar
    menu.BorderSizePixel = 0
    menu.ZIndex = 100
    menu.Parent = row
    corner(menu, UDim.new(0, 4))
    stroke(menu, Library.Theme.Stroke, 1)
    local menuLayout = trackInstance(Instance.new("UIListLayout"))
    menuLayout.SortOrder = Enum.SortOrder.LayoutOrder
    menuLayout.Padding = UDim.new(0, 2)
    menuLayout.Parent = menu

    local api = {Instance = row, Button = selectedButton, Value = selected}

    local function rebuild()
        for _, child in ipairs(menu:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for index, value in ipairs(values) do
            local option = addButton(menu, {
                Size = UDim2.new(1, -6, 0, 28),
                Position = UDim2.fromOffset(3, 0),
                BackgroundColor3 = Library.Theme.Sidebar,
                BorderSizePixel = 0,
                Text = tostring(value),
                TextColor3 = Library.Theme.TextSecondary,
                Font = Library.Theme.FontMedium,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = index,
                ZIndex = 101,
            })
            corner(option, UDim.new(0, 3))
            track(option.MouseEnter:Connect(function()
                if getDeviceType() ~= "Mobile" then tween(option, TweenInfo.new(0.12), {BackgroundColor3 = Library.Theme.SurfaceHover, TextColor3 = Library.Theme.Text}) end
            end))
            track(option.MouseLeave:Connect(function()
                tween(option, TweenInfo.new(0.12), {BackgroundColor3 = Library.Theme.Sidebar, TextColor3 = Library.Theme.TextSecondary})
            end))
            track(option.Activated:Connect(function()
                selected = value
                api.Value = value
                selectedButton.Text = tostring(value)
                open = false
                menu.Visible = false
                if options.Callback then task.spawn(options.Callback, value) end
            end))
        end
        menu.Size = UDim2.new(0, 105, 0, math.min(180, #values * 30 + 6))
    end

    rebuild()

    track(selectedButton.Activated:Connect(function()
        open = not open
        menu.Visible = open
    end))

    function api:Set(value, silent)
        selected = value
        api.Value = value
        selectedButton.Text = tostring(value or "Select")
        if not silent and options.Callback then task.spawn(options.Callback, value) end
    end
    function api:Get() return selected end
    function api:SetValues(newValues)
        values = newValues or {}
        rebuild()
    end
    return api
end

function Section:CreateTextbox(options)
    options = options or {}
    local hasDescription = options.Description ~= nil and tostring(options.Description) ~= ""
    local row = createRow(self, tonumber(options.Height) or (hasDescription and 70 or 58), options.Order)

    addText(row, {
        Size = UDim2.new(1, -160, 0, 18),
        Position = UDim2.fromOffset(15, hasDescription and 6 or 0),
        BackgroundTransparency = 1,
        Text = tostring(options.Name or "Textbox"),
        TextColor3 = Library.Theme.Text,
        Font = Library.Theme.FontMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    if hasDescription then
        addText(row, {
            Size = UDim2.new(1, -160, 0, 15),
            Position = UDim2.fromOffset(15, 26),
            BackgroundTransparency = 1,
            Text = tostring(options.Description),
            TextColor3 = Library.Theme.TextSecondary,
            Font = Library.Theme.Font,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
    end

    local box = trackInstance(Instance.new("TextBox"))
    box.Size = UDim2.fromOffset(130, 28)
    box.Position = UDim2.new(1, -145, 0.5, -14)
    box.BackgroundColor3 = Library.Theme.Sidebar
    box.BorderSizePixel = 0
    box.Text = tostring(options.Default or "")
    box.PlaceholderText = tostring(options.Placeholder or "Enter value...")
    box.PlaceholderColor3 = Library.Theme.TextSecondary
    box.TextColor3 = Library.Theme.Text
    box.Font = Library.Theme.Font
    box.TextSize = 11
    box.ClearTextOnFocus = options.ClearOnFocus == true
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.Parent = row
    corner(box, UDim.new(0, 4))
    stroke(box, Library.Theme.Stroke, 1)
    padding(box, 0, 0, 9, 9)

    local api = {Instance = row, TextBox = box, Value = box.Text}
    track(box.FocusLost:Connect(function(enterPressed)
        api.Value = box.Text
        if options.Callback then task.spawn(options.Callback, box.Text, enterPressed) end
    end))
    function api:Set(text, silent)
        box.Text = tostring(text or "")
        api.Value = box.Text
        if not silent and options.Callback then task.spawn(options.Callback, box.Text, false) end
    end
    function api:Get() return box.Text end
    return api
end

function Section:CreateLabel(options)
    options = options or {}
    local row = trackInstance(Instance.new("Frame"))
    row.Size = UDim2.new(1, 0, 0, tonumber(options.Height) or 28)
    row.BackgroundTransparency = 1
    row.LayoutOrder = options.Order or 1
    row.Parent = self.Container

    local label = addText(row, {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = tostring(options.Text or options.Name or "Label"),
        TextColor3 = Library.Theme.TextSecondary,
        Font = Library.Theme.Font,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    })
    local api = {Instance = row, Label = label}
    function api:Set(text) label.Text = tostring(text) end
    function api:Get() return label.Text end
    return api
end

function Section:CreateParagraph(options)
    options = options or {}
    local row = createRow(self, tonumber(options.Height) or 72, options.Order)
    addText(row, {
        Size = UDim2.new(1, -24, 0, 18),
        Position = UDim2.fromOffset(12, 7),
        BackgroundTransparency = 1,
        Text = tostring(options.Title or options.Name or "Information"),
        TextColor3 = Library.Theme.Text,
        Font = Library.Theme.FontMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    local body = addText(row, {
        Size = UDim2.new(1, -24, 0, 38),
        Position = UDim2.fromOffset(12, 27),
        BackgroundTransparency = 1,
        Text = tostring(options.Text or options.Description or ""),
        TextColor3 = Library.Theme.TextSecondary,
        Font = Library.Theme.Font,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
    })
    local api = {Instance = row, Body = body}
    function api:Set(text) body.Text = tostring(text) end
    return api
end

function Library:InitDefaults()
    self:RegisterTheme("Default", self:GetTheme())
    return self
end

Library.CoreGui = Services.CoreGui
Library:InitDefaults()

return Library
