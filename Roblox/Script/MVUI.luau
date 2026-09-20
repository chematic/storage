--[[
    MVUI
    Minimal dark Roblox UI library
    Responsive: Desktop / Tablet / Mobile
]]

local Services = {
    Players = game:GetService("Players"),
    CoreGui = game:GetService("CoreGui"),
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    RunService = game:GetService("RunService"),
    Workspace = game:GetService("Workspace"),
}

local LocalPlayer = Services.Players.LocalPlayer

local Library = {}
Library.__index = Library

Library.Settings = {
    Animations = true,
    ToggleKey = Enum.KeyCode.RightBracket,
    MobileBreakpoint = 600,
    TabletBreakpoint = 1000,
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
    FontMono = Enum.Font.RobotoMono,
}

Library._connections = {}
Library._instances = {}
Library._themes = {}
Library._window = nil
Library._screenGui = nil
Library._destroyed = false

local function trackConnection(connection)
    if connection then
        table.insert(Library._connections, connection)
    end
    return connection
end

local function trackInstance(instance)
    if instance then
        table.insert(Library._instances, instance)
    end
    return instance
end

local function disconnectAll()
    for i = #Library._connections, 1, -1 do
        local connection = Library._connections[i]
        pcall(function()
            if connection and connection.Connected then
                connection:Disconnect()
            end
        end)
        Library._connections[i] = nil
    end
end

local function disconnectList(list)
    if not list then
        return
    end
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

local function destroyAll()
    for i = #Library._instances, 1, -1 do
        local instance = Library._instances[i]
        pcall(function()
            if instance and instance.Parent then
                instance:Destroy()
            end
        end)
        Library._instances[i] = nil
    end
end

local function safeSet(instance, property, value)
    if not instance then
        return
    end
    pcall(function()
        instance[property] = value
    end)
end

local function tween(instance, info, properties)
    if Library._destroyed or not instance or not instance.Parent then
        return nil
    end

    if not Library.Settings.Animations then
        for property, value in pairs(properties) do
            safeSet(instance, property, value)
        end
        return nil
    end

    local ok, animation = pcall(function()
        local t = Services.TweenService:Create(instance, info, properties)
        t:Play()
        return t
    end)

    if ok then
        return animation
    end

    return nil
end

local function corner(parent, radius)
    local item = trackInstance(Instance.new("UICorner"))
    item.CornerRadius = radius or Library.Theme.CornerRadius
    item.Parent = parent
    return item
end

local function stroke(parent, color, thickness)
    local item = trackInstance(Instance.new("UIStroke"))
    item.Color = color or Library.Theme.Stroke
    item.Thickness = thickness or 1
    item.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    item.Parent = parent
    return item
end

local function padding(parent, top, bottom, left, right)
    local item = trackInstance(Instance.new("UIPadding"))
    item.PaddingTop = UDim.new(0, top or 0)
    item.PaddingBottom = UDim.new(0, bottom or 0)
    item.PaddingLeft = UDim.new(0, left or 0)
    item.PaddingRight = UDim.new(0, right or 0)
    item.Parent = parent
    return item
end

local function textObject(parent, className, properties)
    local item = trackInstance(Instance.new(className))
    for property, value in pairs(properties or {}) do
        safeSet(item, property, value)
    end
    item.Parent = parent
    return item
end

local function buttonObject(parent, properties)
    local item = textObject(parent, "TextButton", properties)
    item.AutoButtonColor = false
    return item
end

local function themeObject(instance, role)
    if instance and role then
        pcall(function()
            instance:SetAttribute("MVThemeRole", role)
        end)
    end
    return instance
end

local function getViewport()
    local camera = Services.Workspace.CurrentCamera
    if camera then
        return camera.ViewportSize
    end
    return Vector2.new(1280, 720)
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
    if not root then
        return
    end

    local function apply(instance)
        local role = instance:GetAttribute("MVThemeRole")
        if not role then
            return
        end

        local value = Library.Theme[role]
        if value == nil then
            return
        end

        if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
            instance.TextColor3 = value
        elseif instance:IsA("Frame") or instance:IsA("ScrollingFrame") then
            instance.BackgroundColor3 = value
        elseif instance:IsA("UIStroke") then
            instance.Color = value
        end
    end

    apply(root)
    for _, instance in ipairs(root:GetDescendants()) do
        apply(instance)
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
    else
        error("Unknown breakpoint: " .. name)
    end

    if self._window and self._window._responsiveUpdate then
        self._window:_responsiveUpdate()
    end
end

function Library:RegisterTheme(name, theme)
    assert(type(name) == "string", "Theme name must be a string")
    assert(type(theme) == "table", "Theme must be a table")

    local copy = {}
    for key, value in pairs(theme) do
        copy[key] = value
    end
    self._themes[name] = copy
end

function Library:SetTheme(theme)
    assert(type(theme) == "table", "Theme must be a table")

    for key, value in pairs(theme) do
        if self.Theme[key] ~= nil then
            self.Theme[key] = value
        end
    end

    if self._screenGui then
        updateThemeRecursive(self._screenGui)
    end

    if self._window and self._window._refreshVisuals then
        self._window:_refreshVisuals()
    end
end

function Library:ApplyTheme(name)
    local theme = self._themes[name]
    if not theme then
        return false
    end
    self:SetTheme(theme)
    return true
end

function Library:GetTheme()
    local copy = {}
    for key, value in pairs(self.Theme) do
        copy[key] = value
    end
    return copy
end

function Library:Notify(options)
    options = options or {}

    if self._destroyed or not self._window then
        return nil
    end

    local window = self._window
    local container = window.ToastContainer
    if not container then
        return nil
    end

    local title = tostring(options.Title or "Notification")
    local description = tostring(options.Description or "")
    local kind = tostring(options.Type or "Info")
    local duration = math.max(0, tonumber(options.Duration) or 3)

    local colors = {
        Info = self.Theme.Accent,
        Success = self.Theme.Success,
        Warning = self.Theme.Warning,
        Error = self.Theme.Danger,
    }

    local typeColor = colors[kind] or self.Theme.Accent
    local height = description ~= "" and 62 or 46

    local toast = trackInstance(Instance.new("Frame"))
    toast.Name = "Toast"
    toast.Size = UDim2.new(1, 0, 0, height)
    toast.BackgroundColor3 = self.Theme.Surface
    toast.BorderSizePixel = 0
    toast.BackgroundTransparency = 1
    toast.Position = UDim2.new(1, 24, 0, 0)
    toast.ZIndex = 300
    themeObject(toast, "Surface")
    corner(toast, self.Theme.CardRadius)
    local outline = stroke(toast, typeColor, 1)
    toast.Parent = container

    local titleLabel = textObject(toast, "TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -24, 0, 18),
        Position = UDim2.fromOffset(12, 7),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = self.Theme.Text,
        Font = self.Theme.FontMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 301,
    })
    themeObject(titleLabel, "Text")

    if description ~= "" then
        local descriptionLabel = textObject(toast, "TextLabel", {
            Name = "Description",
            Size = UDim2.new(1, -24, 0, 28),
            Position = UDim2.fromOffset(12, 28),
            BackgroundTransparency = 1,
            Text = description,
            TextColor3 = self.Theme.TextSecondary,
            Font = self.Theme.Font,
            TextSize = 10,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 301,
        })
        themeObject(descriptionLabel, "TextSecondary")
    end

    if self.Settings.Animations then
        tween(toast, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0,
            Position = UDim2.fromScale(0, 0),
        })
        tween(outline, TweenInfo.new(0.2), {Transparency = 0})
    else
        toast.BackgroundTransparency = 0
        toast.Position = UDim2.fromScale(0, 0)
        outline.Transparency = 0
    end

    task.delay(duration, function()
        if not toast.Parent then
            return
        end

        if self.Settings.Animations then
            local exit = tween(toast, TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                BackgroundTransparency = 1,
                Position = UDim2.new(1, 24, 0, 0),
            })
            tween(outline, TweenInfo.new(0.18), {Transparency = 1})

            if exit then
                trackConnection(exit.Completed:Connect(function()
                    pcall(function()
                        toast:Destroy()
                    end)
                end))
            else
                pcall(function()
                    toast:Destroy()
                end)
            end
        else
            pcall(function()
                toast:Destroy()
            end)
        end
    end)

    return toast
end

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

local function hasDescription(options)
    return options.Description ~= nil and tostring(options.Description) ~= ""
end

local function createRow(section, height, order)
    local row = trackInstance(Instance.new("Frame"))
    row.Size = UDim2.new(1, 0, 0, height)
    row.BackgroundColor3 = Library.Theme.Surface
    row.BorderSizePixel = 0
    row.LayoutOrder = order or (#section._rows + 1)
    themeObject(row, "Surface")
    corner(row, Library.Theme.CardRadius)
    local line = stroke(row, Library.Theme.Stroke, 1)
    themeObject(line, "Stroke")
    row.Parent = section.Container
    table.insert(section._rows, row)
    return row
end

local function createTitleAndDescription(row, options, contentWidth, top)
    top = top or 6
    local title = textObject(row, "TextLabel", {
        Size = UDim2.new(1, -contentWidth, 0, 18),
        Position = UDim2.fromOffset(15, top),
        BackgroundTransparency = 1,
        Text = tostring(options.Name or "Item"),
        TextColor3 = Library.Theme.Text,
        Font = Library.Theme.FontMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    themeObject(title, "Text")

    local description = nil
    if hasDescription(options) then
        description = textObject(row, "TextLabel", {
            Size = UDim2.new(1, -contentWidth, 0, 16),
            Position = UDim2.fromOffset(15, top + 20),
            BackgroundTransparency = 1,
            Text = tostring(options.Description),
            TextColor3 = Library.Theme.TextSecondary,
            Font = Library.Theme.Font,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
        themeObject(description, "TextSecondary")
    end

    return title, description
end

function Library:CreateWindow(options)
    options = options or {}

    if self._window then
        self._window:Destroy()
    end

    self._destroyed = false
    self._connections = {}
    self._instances = {}

    if options.ToggleKey ~= nil then
        self.Settings.ToggleKey = options.ToggleKey
    end

    local screenGui = trackInstance(Instance.new("ScreenGui"))
    screenGui.Name = tostring(options.Name or "MVUI")
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999
    screenGui.Parent = self.CoreGui
    self._screenGui = screenGui

    local window = setmetatable({
        Library = self,
        Title = tostring(options.Title or "MV UI"),
        Version = tostring(options.Version or ""),
        Width = math.max(320, tonumber(options.Width) or 580),
        Height = math.max(240, tonumber(options.Height) or 360),
        MinWidth = math.max(260, tonumber(options.MinWidth) or 280),
        MinHeight = math.max(220, tonumber(options.MinHeight) or 240),
        Tabs = {},
        CurrentTab = nil,
        Hidden = false,
        Minimized = false,
        MobileMenuOpen = false,
        _connections = {},
        _instances = {},
    }, Window)

    self._window = window

    local root = trackInstance(Instance.new("Frame"))
    root.Name = "AppWindow"
    root.AnchorPoint = Vector2.new(0.5, 0.5)
    root.Position = UDim2.fromScale(0.5, 0.5)
    root.Size = UDim2.fromOffset(window.Width, window.Height)
    root.BackgroundColor3 = self.Theme.Background
    root.BorderSizePixel = 0
    root.ClipsDescendants = true
    root.Parent = screenGui
    themeObject(root, "Background")
    corner(root, self.Theme.CardRadius)
    local rootStroke = stroke(root, self.Theme.Stroke, 1)
    themeObject(rootStroke, "Stroke")
    window.Root = root

    local uiConstraint = trackInstance(Instance.new("UISizeConstraint"))
    uiConstraint.MinSize = Vector2.new(window.MinWidth, window.MinHeight)
    uiConstraint.Parent = root

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
    themeObject(header, "Background")
    window.Header = header

    local titleFrame = trackInstance(Instance.new("Frame"))
    titleFrame.Size = UDim2.new(1, -116, 1, 0)
    titleFrame.BackgroundTransparency = 1
    titleFrame.Parent = header

    local title = textObject(titleFrame, "TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -20, 0, 18),
        Position = UDim2.fromOffset(14, 7),
        BackgroundTransparency = 1,
        Text = window.Title,
        TextColor3 = self.Theme.Text,
        Font = self.Theme.FontBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    themeObject(title, "Text")
    window.TitleLabel = title

    if window.Version ~= "" then
        local version = textObject(titleFrame, "TextLabel", {
            Name = "Version",
            Size = UDim2.new(1, -20, 0, 13),
            Position = UDim2.fromOffset(14, 25),
            BackgroundTransparency = 1,
            Text = window.Version,
            TextColor3 = self.Theme.TextSecondary,
            Font = self.Theme.Font,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
        themeObject(version, "TextSecondary")
        window.VersionLabel = version
    end

    local controls = trackInstance(Instance.new("Frame"))
    controls.Name = "Controls"
    controls.Size = UDim2.fromOffset(88, 26)
    controls.Position = UDim2.new(1, -98, 0, 8)
    controls.BackgroundTransparency = 1
    controls.ZIndex = 50
    controls.Parent = header

    local function controlButton(textValue, x, hoverColor, callback)
        local button = buttonObject(controls, {
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
        themeObject(button, "Surface")
        corner(button, UDim.new(0, 4))
        local outline = stroke(button, self.Theme.Stroke, 1)
        themeObject(outline, "Stroke")

        trackConnection(button.MouseEnter:Connect(function()
            if getDeviceType() ~= "Mobile" then
                tween(button, TweenInfo.new(0.14), {
                    BackgroundColor3 = hoverColor,
                    TextColor3 = self.Theme.Text,
                })
            end
        end))

        trackConnection(button.MouseLeave:Connect(function()
            tween(button, TweenInfo.new(0.14), {
                BackgroundColor3 = self.Theme.Surface,
                TextColor3 = self.Theme.TextSecondary,
            })
        end))

        trackConnection(button.Activated:Connect(callback))
        return button
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
    body.Position = UDim2.fromOffset(0, 44)
    body.BackgroundTransparency = 1
    body.Parent = canvas
    window.Body = body

    local sidebar = trackInstance(Instance.new("Frame"))
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 140, 1, 0)
    sidebar.BackgroundColor3 = self.Theme.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.ZIndex = 10
    sidebar.Parent = body
    themeObject(sidebar, "Sidebar")
    window.Sidebar = sidebar

    local divider = trackInstance(Instance.new("Frame"))
    divider.Size = UDim2.new(0, 1, 1, 0)
    divider.Position = UDim2.new(1, -1, 0, 0)
    divider.BackgroundColor3 = self.Theme.Stroke
    divider.BorderSizePixel = 0
    divider.ZIndex = 11
    divider.Parent = sidebar
    themeObject(divider, "Stroke")

    local logo = textObject(sidebar, "TextLabel", {
        Name = "Logo",
        Size = UDim2.new(1, -16, 0, 44),
        Position = UDim2.fromOffset(8, 0),
        BackgroundTransparency = 1,
        Text = "  " .. tostring(options.LogoText or window.Title),
        TextColor3 = self.Theme.Text,
        Font = self.Theme.FontBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    themeObject(logo, "Text")
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
    nav.ZIndex = 11
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
    content.ZIndex = 5
    content.Parent = body
    window.Content = content

    local mobileMenuButton = buttonObject(header, {
        Name = "MobileMenu",
        Size = UDim2.fromOffset(26, 26),
        Position = UDim2.fromOffset(8, 9),
        BackgroundColor3 = self.Theme.Surface,
        BorderSizePixel = 0,
        Text = "☰",
        TextColor3 = self.Theme.TextSecondary,
        Font = self.Theme.FontMedium,
        TextSize = 14,
        ZIndex = 60,
        Visible = false,
    })
    themeObject(mobileMenuButton, "Surface")
    corner(mobileMenuButton, UDim.new(0, 4))
    local mobileMenuStroke = stroke(mobileMenuButton, self.Theme.Stroke, 1)
    themeObject(mobileMenuStroke, "Stroke")
    window.MobileMenuButton = mobileMenuButton

    local closeOnMobile = buttonObject(header, {
        Name = "MobileClose",
        Size = UDim2.fromOffset(26, 26),
        Position = UDim2.new(1, -34, 0, 9),
        BackgroundColor3 = self.Theme.Surface,
        BorderSizePixel = 0,
        Text = "×",
        TextColor3 = self.Theme.TextSecondary,
        Font = self.Theme.FontMedium,
        TextSize = 14,
        ZIndex = 60,
        Visible = false,
    })
    themeObject(closeOnMobile, "Surface")
    corner(closeOnMobile, UDim.new(0, 4))
    stroke(closeOnMobile, self.Theme.Stroke, 1)
    window.MobileCloseButton = closeOnMobile

    local toastContainer = trackInstance(Instance.new("Frame"))
    toastContainer.Name = "Notifications"
    toastContainer.Size = UDim2.fromOffset(270, 180)
    toastContainer.Position = UDim2.new(1, -285, 1, -190)
    toastContainer.BackgroundTransparency = 1
    toastContainer.ZIndex = 200
    toastContainer.Parent = screenGui
    window.ToastContainer = toastContainer

    local toastLayout = trackInstance(Instance.new("UIListLayout"))
    toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
    toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    toastLayout.Padding = UDim.new(0, 8)
    toastLayout.Parent = toastContainer

    local floating = buttonObject(screenGui, {
        Name = "ToggleButton",
        Size = UDim2.fromOffset(44, 44),
        Position = UDim2.new(0, 15, 0.5, -22),
        BackgroundColor3 = self.Theme.Sidebar,
        BorderSizePixel = 0,
        Text = tostring(options.ToggleText or "MV"),
        TextColor3 = self.Theme.Accent,
        Font = self.Theme.FontBold,
        TextSize = 13,
        ZIndex = 250,
    })
    themeObject(floating, "Sidebar")
    corner(floating, UDim2.fromScale(1, 1))
    local floatingStroke = stroke(floating, self.Theme.Accent, 1.5)
    floatingStroke.Name = "AccentStroke"
    window.ToggleButton = floating

    local rootDragging = false
    local rootDragStart = nil
    local rootStartPosition = nil

    trackConnection(header.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        if window.Minimized then
            return
        end
        rootDragging = true
        rootDragStart = input.Position
        rootStartPosition = root.Position
    end))

    trackConnection(Services.UserInputService.InputChanged:Connect(function(input)
        if not rootDragging then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local viewport = getViewport()
        local delta = input.Position - rootDragStart
        local startX = rootStartPosition.X.Offset
        local startY = rootStartPosition.Y.Offset
        local halfW = root.AbsoluteSize.X / 2
        local halfH = root.AbsoluteSize.Y / 2
        local xLimit = math.max(0, viewport.X / 2)
        local yLimit = math.max(0, viewport.Y / 2)

        local newX = math.clamp(startX + delta.X, -xLimit - halfW + 80, xLimit + halfW - 80)
        local newY = math.clamp(startY + delta.Y, -yLimit - halfH + 44, yLimit + halfH - 44)

        root.Position = UDim2.new(0.5, newX, 0.5, newY)
    end))

    trackConnection(Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            rootDragging = false
        end
    end))

    local floatingDragging = false
    local floatingDragStart = nil
    local floatingStartPosition = nil
    local floatingMoved = false

    trackConnection(floating.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        floatingDragging = true
        floatingMoved = false
        floatingDragStart = input.Position
        floatingStartPosition = floating.Position
    end))

    trackConnection(Services.UserInputService.InputChanged:Connect(function(input)
        if not floatingDragging then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - floatingDragStart
        if delta.Magnitude > 5 then
            floatingMoved = true
        end

        local viewport = getViewport()
        local maxX = math.max(4, viewport.X - floating.AbsoluteSize.X - 4)
        local maxY = math.max(4, viewport.Y - floating.AbsoluteSize.Y - 4)
        local x = math.clamp(floatingStartPosition.X.Offset + delta.X, 4, maxX)
        local y = math.clamp(floatingStartPosition.Y.Offset + delta.Y, 4, maxY)

        floating.Position = UDim2.fromOffset(x, y)
    end))

    trackConnection(Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        floatingDragging = false
    end))

    trackConnection(floating.Activated:Connect(function()
        if floatingMoved then
            floatingMoved = false
            return
        end
        window:Toggle()
    end))

    trackConnection(mobileMenuButton.Activated:Connect(function()
        window:SetMobileMenu(not window.MobileMenuOpen)
    end))

    trackConnection(closeOnMobile.Activated:Connect(function()
        window:SetMobileMenu(false)
    end))

    trackConnection(Services.UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        if input.KeyCode == self.Settings.ToggleKey then
            window:Toggle()
        end
    end))

    function window:_refreshVisuals()
        if not self.Root or not self.Root.Parent then
            return
        end

        safeSet(root, "BackgroundColor3", self.Library.Theme.Background)
        safeSet(header, "BackgroundColor3", self.Library.Theme.Background)
        safeSet(sidebar, "BackgroundColor3", self.Library.Theme.Sidebar)
        safeSet(divider, "BackgroundColor3", self.Library.Theme.Stroke)
        safeSet(logo, "TextColor3", self.Library.Theme.Text)
        safeSet(title, "TextColor3", self.Library.Theme.Text)

        if self.VersionLabel then
            safeSet(self.VersionLabel, "TextColor3", self.Library.Theme.TextSecondary)
        end

        updateThemeRecursive(root)

        for _, tab in ipairs(self.Tabs) do
            if tab._refreshVisuals then
                tab:_refreshVisuals()
            end
        end

        if self.ToggleButton then
            safeSet(self.ToggleButton, "BackgroundColor3", self.Library.Theme.Sidebar)
            safeSet(self.ToggleButton, "TextColor3", self.Library.Theme.Accent)
        end
    end

    function window:SetMinimized(value)
        value = value == true
        if self.Minimized == value then
            return
        end

        self.Minimized = value
        if value then
            self._preMinimizeHeight = root.Size.Y.Offset
            if self.Library.Settings.Animations then
                tween(root, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(root.Size.X.Offset, 46),
                })
                tween(body, TweenInfo.new(0.15), {Visible = false})
            else
                root.Size = UDim2.fromOffset(root.Size.X.Offset, 46)
                body.Visible = false
            end
        else
            body.Visible = true
            local height = self._preMinimizeHeight or self.Height
            if self.Library.Settings.Animations then
                tween(root, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(root.Size.X.Offset, height),
                })
            else
                root.Size = UDim2.fromOffset(root.Size.X.Offset, height)
            end
        end
    end

    function window:SetVisible(value)
        local visible = value == true
        self.Hidden = not visible
        root.Visible = visible
        floating.Visible = not visible
        if visible then
            self:SetMobileMenu(false)
        end
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

    function window:SetMobileMenu(value)
        local open = value == true
        self.MobileMenuOpen = open

        if getDeviceType() ~= "Mobile" then
            sidebar.Visible = true
            mobileMenuButton.Visible = false
            return
        end

        sidebar.Visible = open
        mobileMenuButton.Visible = true
        closeOnMobile.Visible = false

        sidebar.Size = UDim2.new(0, math.min(190, root.AbsoluteSize.X - 20), 1, 0)
        sidebar.Position = UDim2.fromOffset(0, 0)
        sidebar.ZIndex = 90
        content.ZIndex = open and 5 or 10
        mobileMenuButton.ZIndex = 120

        if open and self.Library.Settings.Animations then
            sidebar.Position = UDim2.fromOffset(-sidebar.AbsoluteSize.X, 0)
            tween(sidebar, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Position = UDim2.fromOffset(0, 0),
            })
        end
    end

    function window:CreateTab(tabOptions)
        tabOptions = tabOptions or {}

        local name = tostring(tabOptions.Name or ("Tab " .. tostring(#self.Tabs + 1)))
        if self:GetTab(name) then
            error("A tab named '" .. name .. "' already exists")
        end

        local tab = setmetatable({
            Window = self,
            Name = name,
            Sections = {},
            Current = false,
            _rows = {},
        }, Tab)

        local button = buttonObject(nav, {
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
            ZIndex = 12,
        })
        themeObject(button, "Sidebar")
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

        local tabPadding = trackInstance(Instance.new("UIPadding"))
        tabPadding.PaddingTop = UDim.new(0, 14)
        tabPadding.PaddingBottom = UDim.new(0, 14)
        tabPadding.PaddingLeft = UDim.new(0, 14)
        tabPadding.PaddingRight = UDim.new(0, 14)
        tabPadding.Parent = scroll
        tab.Padding = tabPadding

        trackConnection(button.Activated:Connect(function()
            self:SelectTab(name)
            if getDeviceType() == "Mobile" then
                self:SetMobileMenu(false)
            end
        end))

        trackConnection(button.MouseEnter:Connect(function()
            if getDeviceType() == "Mobile" or tab.Current then
                return
            end
            tween(button, TweenInfo.new(0.14), {
                BackgroundColor3 = self.Library.Theme.SurfaceHover,
                TextColor3 = self.Library.Theme.Text,
            })
        end))

        trackConnection(button.MouseLeave:Connect(function()
            if tab.Current then
                return
            end
            tween(button, TweenInfo.new(0.14), {
                BackgroundColor3 = self.Library.Theme.Sidebar,
                TextColor3 = self.Library.Theme.TextSecondary,
            })
        end))

        table.insert(self.Tabs, tab)

        if not self.CurrentTab then
            self:SelectTab(name)
        end

        return tab
    end

    function window:SelectTab(name)
        local target = nil
        for _, tab in ipairs(self.Tabs) do
            if tab.Name == name then
                target = tab
                break
            end
        end

        if not target then
            return nil
        end

        self.CurrentTab = target

        for _, tab in ipairs(self.Tabs) do
            local active = tab == target
            tab.Current = active

            if active then
                tab.Page.Visible = true
                tab.Page.GroupTransparency = 0
                tab.Button.BackgroundColor3 = self.Library.Theme.SurfaceHover
                tab.Button.TextColor3 = self.Library.Theme.Text
            else
                if self.Library.Settings.Animations then
                    tab.Page.Visible = true
                    tween(tab.Page, TweenInfo.new(0.12), {GroupTransparency = 1})
                    task.delay(0.13, function()
                        if self.CurrentTab ~= tab and tab.Page and tab.Page.Parent then
                            tab.Page.Visible = false
                        end
                    end)
                else
                    tab.Page.Visible = false
                    tab.Page.GroupTransparency = 1
                end

                tab.Button.BackgroundColor3 = self.Library.Theme.Sidebar
                tab.Button.TextColor3 = self.Library.Theme.TextSecondary
            end
        end

        return target
    end

    function window:GetTab(name)
        for _, tab in ipairs(self.Tabs) do
            if tab.Name == name then
                return tab
            end
        end
        return nil
    end

    function window:_responsiveUpdate()
        if self.Library._destroyed or not root.Parent then
            return
        end

        local device = getDeviceType()
        local viewport = getViewport()
        local maxWidth = math.max(260, viewport.X - 20)
        local maxHeight = math.max(220, viewport.Y - 20)
        local targetWidth = self.Width
        local targetHeight = self.Height

        if device == "Mobile" then
            targetWidth = math.clamp(viewport.X - 16, self.MinWidth, 460)
            targetHeight = math.clamp(viewport.Y - 16, self.MinHeight, 620)
            targetWidth = math.min(targetWidth, maxWidth)
            targetHeight = math.min(targetHeight, maxHeight)

            sidebar.Visible = self.MobileMenuOpen
            content.Size = UDim2.fromScale(1, 1)
            content.Position = UDim2.fromOffset(0, 0)
            header.Size = UDim2.new(1, 0, 0, 44)
            titleFrame.Position = UDim2.fromOffset(38, 0)
            titleFrame.Size = UDim2.new(1, -90, 1, 0)
            controls.Visible = false
            mobileMenuButton.Visible = true
            closeOnMobile.Visible = false

            sidebar.Size = UDim2.new(0, math.min(190, math.max(170, targetWidth - 20)), 1, 0)
            sidebar.Position = UDim2.fromOffset(self.MobileMenuOpen and 0 or -sidebar.AbsoluteSize.X, 0)
            sidebar.ZIndex = 90

            toastContainer.Size = UDim2.fromOffset(math.min(270, math.max(220, targetWidth - 20)), 150)
            toastContainer.Position = UDim2.new(0.5, -toastContainer.AbsoluteSize.X / 2, 1, -160)
        elseif device == "Tablet" then
            targetWidth = math.min(self.Width, maxWidth)
            targetHeight = math.min(self.Height, maxHeight)
            targetWidth = math.max(targetWidth, math.min(440, maxWidth))
            sidebar.Visible = true
            sidebar.Size = UDim2.new(0, 120, 1, 0)
            sidebar.Position = UDim2.fromOffset(0, 0)
            content.Size = UDim2.new(1, -120, 1, 0)
            content.Position = UDim2.fromOffset(120, 0)
            header.Size = UDim2.new(1, 0, 0, 44)
            titleFrame.Position = UDim2.fromOffset(0, 0)
            titleFrame.Size = UDim2.new(1, -116, 1, 0)
            controls.Visible = true
            mobileMenuButton.Visible = false
            closeOnMobile.Visible = false

            toastContainer.Size = UDim2.fromOffset(260, 170)
            toastContainer.Position = UDim2.new(1, -275, 1, -180)
        else
            targetWidth = math.min(self.Width, maxWidth)
            targetHeight = math.min(self.Height, maxHeight)
            targetWidth = math.max(targetWidth, math.min(self.MinWidth, maxWidth))
            targetHeight = math.max(targetHeight, math.min(self.MinHeight, maxHeight))
            sidebar.Visible = true
            sidebar.Size = UDim2.new(0, 140, 1, 0)
            sidebar.Position = UDim2.fromOffset(0, 0)
            content.Size = UDim2.new(1, -140, 1, 0)
            content.Position = UDim2.fromOffset(140, 0)
            header.Size = UDim2.new(1, 0, 0, 44)
            titleFrame.Position = UDim2.fromOffset(0, 0)
            titleFrame.Size = UDim2.new(1, -116, 1, 0)
            controls.Visible = true
            mobileMenuButton.Visible = false
            closeOnMobile.Visible = false

            toastContainer.Size = UDim2.fromOffset(270, 180)
            toastContainer.Position = UDim2.new(1, -285, 1, -190)
        end

        local finalWidth = math.clamp(targetWidth, 240, maxWidth)
        local finalHeight = math.clamp(self.Minimized and 46 or targetHeight, 220, maxHeight)

        uiConstraint.MinSize = Vector2.new(
            math.min(self.MinWidth, finalWidth),
            math.min(self.MinHeight, finalHeight)
        )

        root.Size = UDim2.fromOffset(finalWidth, finalHeight)

        if self.Minimized then
            body.Visible = false
        else
            body.Visible = true
        end

        if device == "Mobile" and self.MobileMenuOpen then
            self:SetMobileMenu(true)
        end

        for _, tab in ipairs(self.Tabs) do
            if tab._responsiveUpdate then
                tab:_responsiveUpdate(device)
            end
        end
    end

    function window:Destroy()
        if self.Library._destroyed then
            return
        end

        self.Library._destroyed = true
        self.Library._window = nil
        disconnectAll()
        destroyAll()
        self.Library._screenGui = nil
    end

    local camera = Services.Workspace.CurrentCamera
    if camera then
        trackConnection(camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            if not self.Library._destroyed then
                self:_responsiveUpdate()
            end
        end))
    end

    window:_responsiveUpdate()

    if options.ShowOnStart == false then
        window:Hide()
    end

    return window
end

function Tab:_responsiveUpdate(device)
    if not self.Scroll or not self.Scroll.Parent then
        return
    end

    local inset = device == "Mobile" and 10 or 14
    self.Padding.PaddingTop = UDim.new(0, inset)
    self.Padding.PaddingBottom = UDim.new(0, inset)
    self.Padding.PaddingLeft = UDim.new(0, device == "Mobile" and 10 or 14)
    self.Padding.PaddingRight = UDim.new(0, device == "Mobile" and 10 or 14)
end

function Tab:_refreshVisuals()
    if self.Button then
        self.Button.BackgroundColor3 = self.Current and Library.Theme.SurfaceHover or Library.Theme.Sidebar
        self.Button.TextColor3 = self.Current and Library.Theme.Text or Library.Theme.TextSecondary
    end

    if self.Scroll then
        self.Scroll.ScrollBarImageColor3 = Library.Theme.Accent
    end
end

function Tab:CreateSection(options)
    options = options or {}

    local section = setmetatable({
        Tab = self,
        Name = tostring(options.Name or "Section"),
        Sections = {},
        _rows = {},
    }, Section)

    local holder = trackInstance(Instance.new("Frame"))
    holder.Name = section.Name .. "Section"
    holder.Size = UDim2.new(1, 0, 0, 0)
    holder.AutomaticSize = Enum.AutomaticSize.Y
    holder.BackgroundTransparency = 1
    holder.LayoutOrder = #self.Sections + 1
    holder.Parent = self.Scroll
    section.Container = holder

    local list = trackInstance(Instance.new("UIListLayout"))
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 8)
    list.Parent = holder
    section.Layout = list

    if options.Name ~= false and tostring(options.Name or "") ~= "" then
        local heading = textObject(holder, "TextLabel", {
            Name = "SectionTitle",
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            Text = string.upper(section.Name),
            TextColor3 = Library.Theme.TextSecondary,
            Font = Library.Theme.FontMedium,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 0,
        })
        themeObject(heading, "TextSecondary")
        section.Header = heading
    end

    table.insert(self.Sections, section)
    return section
end

function Section:CreateToggle(options)
    options = options or {}

    local description = hasDescription(options)
    local row = createRow(self, tonumber(options.Height) or (description and 62 or 50), options.Order)
    createTitleAndDescription(row, options, 82, description and 6 or 0)

    local active = options.Default == true

    local toggle = buttonObject(row, {
        Size = UDim2.fromOffset(44, 24),
        Position = UDim2.new(1, -59, 0.5, -12),
        BackgroundColor3 = active and Library.Theme.Accent or Library.Theme.Stroke,
        BorderSizePixel = 0,
        Text = "",
    })
    corner(toggle, UDim2.fromScale(1, 1))

    local knob = trackInstance(Instance.new("Frame"))
    knob.Size = UDim2.fromOffset(18, 18)
    knob.Position = UDim2.new(0, active and 23 or 3, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = toggle
    corner(knob, UDim2.fromScale(1, 1))

    local api = {
        Instance = row,
        Button = toggle,
        Value = active,
    }

    local function setValue(value, silent)
        active = value == true
        api.Value = active

        tween(toggle, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            BackgroundColor3 = active and Library.Theme.Accent or Library.Theme.Stroke,
        })
        tween(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, active and 23 or 3, 0.5, -9),
        })

        if not silent and options.Callback then
            task.spawn(options.Callback, active)
        end
    end

    trackConnection(toggle.Activated:Connect(function()
        setValue(not active, false)
    end))

    if options.Callback and options.FireOnCreate then
        task.spawn(options.Callback, active)
    end

    function api:Set(value, silent)
        setValue(value, silent)
    end

    function api:Get()
        return active
    end

    return api
end

function Section:CreateButton(options)
    options = options or {}

    local description = hasDescription(options)
    local row = createRow(self, tonumber(options.Height) or (description and 62 or 48), options.Order)
    createTitleAndDescription(row, options, 120, description and 6 or 0)

    local action = buttonObject(row, {
        Size = UDim2.fromOffset(86, 28),
        Position = UDim2.new(1, -101, 0.5, -14),
        BackgroundColor3 = Library.Theme.Sidebar,
        BorderSizePixel = 0,
        Text = tostring(options.Label or "Execute"),
        TextColor3 = Library.Theme.Accent,
        Font = Library.Theme.FontBold,
        TextSize = 11,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    themeObject(action, "Sidebar")
    corner(action, UDim.new(0, 4))
    local outline = stroke(action, Library.Theme.Stroke, 1)
    themeObject(outline, "Stroke")

    trackConnection(action.MouseEnter:Connect(function()
        if getDeviceType() == "Mobile" then
            return
        end
        tween(action, TweenInfo.new(0.14), {
            BackgroundColor3 = Library.Theme.SurfaceHover,
            TextColor3 = Library.Theme.Text,
        })
    end))

    trackConnection(action.MouseLeave:Connect(function()
        tween(action, TweenInfo.new(0.14), {
            BackgroundColor3 = Library.Theme.Sidebar,
            TextColor3 = Library.Theme.Accent,
        })
    end))

    trackConnection(action.Activated:Connect(function()
        if options.Callback then
            task.spawn(options.Callback)
        end
    end))

    return {
        Instance = row,
        Button = action,
    }
end

function Section:CreateSlider(options)
    options = options or {}

    local minVal = tonumber(options.Min) or 0
    local maxVal = tonumber(options.Max) or 100
    if maxVal < minVal then
        minVal, maxVal = maxVal, minVal
    end

    local decimals = tonumber(options.Decimals)
    if decimals == nil then
        decimals = 2
    end
    decimals = math.clamp(math.floor(decimals), 0, 6)

    local description = hasDescription(options)
    local row = createRow(self, tonumber(options.Height) or (description and 82 or 66), options.Order)
    createTitleAndDescription(row, options, 90, 6)

    local value = tonumber(options.Default)
    if value == nil then
        value = minVal
    end
    value = math.clamp(value, minVal, maxVal)

    local valueLabel = textObject(row, "TextLabel", {
        Size = UDim2.fromOffset(70, 18),
        Position = UDim2.new(1, -85, 0, 6),
        BackgroundTransparency = 1,
        Text = string.format("%." .. tostring(decimals) .. "f", value),
        TextColor3 = Library.Theme.TextSecondary,
        Font = Library.Theme.FontMono,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    themeObject(valueLabel, "TextSecondary")

    local trackBar = trackInstance(Instance.new("Frame"))
    trackBar.Size = UDim2.new(1, -30, 0, 6)
    trackBar.Position = UDim2.new(0, 15, 0, description and 61 or 45)
    trackBar.BackgroundColor3 = Library.Theme.Stroke
    trackBar.BorderSizePixel = 0
    trackBar.Parent = row
    themeObject(trackBar, "Stroke")
    corner(trackBar, UDim2.fromScale(1, 1))

    local fill = trackInstance(Instance.new("Frame"))
    fill.Size = UDim2.new(
        (value - minVal) / math.max(0.000001, maxVal - minVal),
        0,
        1,
        0
    )
    fill.BackgroundColor3 = Library.Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = trackBar
    themeObject(fill, "Accent")
    corner(fill, UDim2.fromScale(1, 1))

    local dragging = false
    local api = {
        Instance = row,
        Value = value,
        Track = trackBar,
        Fill = fill,
    }

    local function roundValue(v)
        local multiplier = 10 ^ decimals
        return math.floor(v * multiplier + 0.5) / multiplier
    end

    local function setValue(v, silent)
        v = tonumber(v) or minVal
        value = math.clamp(roundValue(v), minVal, maxVal)
        api.Value = value

        local percent = (value - minVal) / math.max(0.000001, maxVal - minVal)
        fill.Size = UDim2.new(percent, 0, 1, 0)
        valueLabel.Text = string.format("%." .. tostring(decimals) .. "f", value)

        if not silent and options.Callback then
            task.spawn(options.Callback, value)
        end
    end

    local function updateFromInput(input)
        local width = math.max(1, trackBar.AbsoluteSize.X)
        local percent = math.clamp(
            (input.Position.X - trackBar.AbsolutePosition.X) / width,
            0,
            1
        )
        setValue(minVal + ((maxVal - minVal) * percent), false)
    end

    trackConnection(trackBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromInput(input)
        end
    end))

    trackConnection(Services.UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            updateFromInput(input)
        end
    end))

    trackConnection(Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    if options.Callback and options.FireOnCreate then
        task.spawn(options.Callback, value)
    end

    function api:Set(v, silent)
        setValue(v, silent)
    end

    function api:Get()
        return value
    end

    return api
end

function Section:CreateKeybind(options)
    options = options or {}

    local key = options.Default or Enum.KeyCode.RightShift
    local listening = false
    local description = hasDescription(options)

    local row = createRow(self, tonumber(options.Height) or (description and 62 or 48), options.Order)
    createTitleAndDescription(row, options, 110, description and 6 or 0)

    local keyButton = buttonObject(row, {
        Size = UDim2.fromOffset(80, 26),
        Position = UDim2.new(1, -95, 0.5, -13),
        BackgroundColor3 = Library.Theme.Sidebar,
        BorderSizePixel = 0,
        Text = typeof(key) == "EnumItem" and key.Name or tostring(key),
        TextColor3 = Library.Theme.Accent,
        Font = Library.Theme.FontBold,
        TextSize = 11,
    })
    themeObject(keyButton, "Sidebar")
    corner(keyButton, UDim.new(0, 4))
    local outline = stroke(keyButton, Library.Theme.Stroke, 1)
    themeObject(outline, "Stroke")

    local api = {
        Instance = row,
        Button = keyButton,
        Value = key,
    }

    trackConnection(keyButton.Activated:Connect(function()
        listening = true
        keyButton.Text = "Press Key..."
        keyButton.TextColor3 = Library.Theme.Warning
    end))

    trackConnection(Services.UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not listening then
            return
        end

        if input.UserInputType == Enum.UserInputType.Keyboard then
            listening = false
            key = input.KeyCode
            api.Value = key
            keyButton.Text = key.Name
            keyButton.TextColor3 = Library.Theme.Accent

            if options.Callback then
                task.spawn(options.Callback, key)
            end
        end
    end))

    function api:Set(value, silent)
        key = value
        api.Value = value
        keyButton.Text = typeof(value) == "EnumItem" and value.Name or tostring(value)
        keyButton.TextColor3 = Library.Theme.Accent

        if not silent and options.Callback then
            task.spawn(options.Callback, value)
        end
    end

    function api:Get()
        return key
    end

    return api
end

function Section:CreateDropdown(options)
    options = options or {}

    local values = options.Values or options.Options or {}
    local selected = options.Default
    if selected == nil and #values > 0 then
        selected = values[1]
    end

    local open = false
    local description = hasDescription(options)
    local row = createRow(self, tonumber(options.Height) or (description and 62 or 48), options.Order)
    createTitleAndDescription(row, options, 130, description and 6 or 0)

    local selectedButton = buttonObject(row, {
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
    themeObject(selectedButton, "Sidebar")
    corner(selectedButton, UDim.new(0, 4))
    local outline = stroke(selectedButton, Library.Theme.Stroke, 1)
    themeObject(outline, "Stroke")

    local menu = trackInstance(Instance.new("Frame"))
    menu.Name = "DropdownMenu"
    menu.Visible = false
    menu.Size = UDim2.fromOffset(105, 0)
    menu.Position = UDim2.new(1, -120, 1, 4)
    menu.BackgroundColor3 = Library.Theme.Sidebar
    menu.BorderSizePixel = 0
    menu.ZIndex = 150
    menu.Parent = row
    themeObject(menu, "Sidebar")
    corner(menu, UDim.new(0, 4))
    local menuStroke = stroke(menu, Library.Theme.Stroke, 1)
    themeObject(menuStroke, "Stroke")

    local menuLayout = trackInstance(Instance.new("UIListLayout"))
    menuLayout.SortOrder = Enum.SortOrder.LayoutOrder
    menuLayout.Padding = UDim.new(0, 2)
    menuLayout.Parent = menu

    local api = {
        Instance = row,
        Button = selectedButton,
        Value = selected,
    }

    local optionButtons = {}
    local optionConnections = {}

    local function rebuild()
        disconnectList(optionConnections)

        for _, button in ipairs(optionButtons) do
            pcall(function()
                button:Destroy()
            end)
        end
        table.clear(optionButtons)

        for index, item in ipairs(values) do
            local optionButton = buttonObject(menu, {
                Size = UDim2.new(1, -6, 0, 28),
                Position = UDim2.fromOffset(3, 0),
                BackgroundColor3 = Library.Theme.Sidebar,
                BorderSizePixel = 0,
                Text = tostring(item),
                TextColor3 = Library.Theme.TextSecondary,
                Font = Library.Theme.FontMedium,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = index,
                ZIndex = 151,
            })
            themeObject(optionButton, "Sidebar")
            corner(optionButton, UDim.new(0, 3))

            table.insert(optionButtons, optionButton)

            table.insert(optionConnections, optionButton.MouseEnter:Connect(function()
                if getDeviceType() ~= "Mobile" then
                    tween(optionButton, TweenInfo.new(0.12), {
                        BackgroundColor3 = Library.Theme.SurfaceHover,
                        TextColor3 = Library.Theme.Text,
                    })
                end
            end))

            table.insert(optionConnections, optionButton.MouseLeave:Connect(function()
                tween(optionButton, TweenInfo.new(0.12), {
                    BackgroundColor3 = Library.Theme.Sidebar,
                    TextColor3 = Library.Theme.TextSecondary,
                })
            end))

            table.insert(optionConnections, optionButton.Activated:Connect(function()
                selected = item
                api.Value = item
                selectedButton.Text = tostring(item)
                open = false
                menu.Visible = false

                if options.Callback then
                    task.spawn(options.Callback, item)
                end
            end))
        end

        local height = math.min(180, (#values * 30) + 6)
        menu.Size = UDim2.fromOffset(105, height)
    end

    rebuild()

    trackConnection(selectedButton.Activated:Connect(function()
        open = not open
        menu.Visible = open
    end))

    function api:Set(value, silent)
        selected = value
        api.Value = value
        selectedButton.Text = tostring(value or "Select")

        if not silent and options.Callback then
            task.spawn(options.Callback, value)
        end
    end

    function api:Get()
        return selected
    end

    function api:SetValues(newValues)
        values = newValues or {}
        rebuild()
    end

    function api:Open()
        open = true
        menu.Visible = true
    end

    function api:Close()
        open = false
        menu.Visible = false
    end

    return api
end

function Section:CreateTextbox(options)
    options = options or {}

    local description = hasDescription(options)
    local row = createRow(self, tonumber(options.Height) or (description and 70 or 58), options.Order)
    createTitleAndDescription(row, options, 160, description and 6 or 0)

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
    themeObject(box, "Text")
    corner(box, UDim.new(0, 4))
    local outline = stroke(box, Library.Theme.Stroke, 1)
    themeObject(outline, "Stroke")
    padding(box, 0, 0, 9, 9)

    local api = {
        Instance = row,
        TextBox = box,
        Value = box.Text,
    }

    trackConnection(box.FocusLost:Connect(function(enterPressed)
        api.Value = box.Text
        if options.Callback then
            task.spawn(options.Callback, box.Text, enterPressed)
        end
    end))

    function api:Set(value, silent)
        box.Text = tostring(value or "")
        api.Value = box.Text
        if not silent and options.Callback then
            task.spawn(options.Callback, box.Text, false)
        end
    end

    function api:Get()
        return box.Text
    end

    return api
end

function Section:CreateLabel(options)
    options = options or {}

    local row = trackInstance(Instance.new("Frame"))
    row.Size = UDim2.new(1, 0, 0, tonumber(options.Height) or 28)
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.LayoutOrder = options.Order or (#self._rows + 1)
    row.Parent = self.Container
    table.insert(self._rows, row)

    local label = textObject(row, "TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = tostring(options.Text or options.Name or "Label"),
        TextColor3 = Library.Theme.TextSecondary,
        Font = Library.Theme.Font,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    })
    themeObject(label, "TextSecondary")

    local api = {
        Instance = row,
        Label = label,
    }

    function api:Set(value)
        label.Text = tostring(value)
    end

    function api:Get()
        return label.Text
    end

    return api
end

function Section:CreateParagraph(options)
    options = options or {}

    local text = tostring(options.Text or options.Description or "")
    local estimatedLines = math.max(1, math.ceil(#text / 70))
    local height = tonumber(options.Height) or math.clamp(46 + (estimatedLines * 12), 58, 150)
    local row = createRow(self, height, options.Order)

    local title = textObject(row, "TextLabel", {
        Size = UDim2.new(1, -24, 0, 18),
        Position = UDim2.fromOffset(12, 7),
        BackgroundTransparency = 1,
        Text = tostring(options.Title or options.Name or "Information"),
        TextColor3 = Library.Theme.Text,
        Font = Library.Theme.FontMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    themeObject(title, "Text")

    local body = textObject(row, "TextLabel", {
        Size = UDim2.new(1, -24, 1, -34),
        Position = UDim2.fromOffset(12, 27),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Library.Theme.TextSecondary,
        Font = Library.Theme.Font,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
    })
    themeObject(body, "TextSecondary")

    local api = {
        Instance = row,
        Title = title,
        Body = body,
    }

    function api:Set(value)
        body.Text = tostring(value)
    end

    return api
end

function Section:CreateDivider(options)
    options = options or {}

    local row = trackInstance(Instance.new("Frame"))
    row.Size = UDim2.new(1, 0, 0, tonumber(options.Height) or 10)
    row.BackgroundTransparency = 1
    row.LayoutOrder = options.Order or (#self._rows + 1)
    row.Parent = self.Container
    table.insert(self._rows, row)

    local line = trackInstance(Instance.new("Frame"))
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 0.5, 0)
    line.BackgroundColor3 = Library.Theme.Stroke
    line.BorderSizePixel = 0
    line.Parent = row
    themeObject(line, "Stroke")

    return {
        Instance = row,
        Line = line,
    }
end

function Window:Close()
    self:Destroy()
end

function Window:SetToggleKey(key)
    self.Library.Settings.ToggleKey = key
end

function Window:IsVisible()
    return not self.Hidden
end

function Window:IsMinimized()
    return self.Minimized
end

function Library:InitDefaults()
    self:RegisterTheme("Default", self:GetTheme())
    return self
end

Library.CoreGui = Services.CoreGui
Library:InitDefaults()

return Library
