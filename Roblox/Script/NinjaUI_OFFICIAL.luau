local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local UDim2_new = UDim2.new
local Color3_fromRGB = Color3.fromRGB
local Instance_new = Instance.new

local tweenFast = TweenInfo.new(0.1)
local tweenNormal = TweenInfo.new(0.2)
local tweenMedium = TweenInfo.new(0.3)
local tweenQuartOut = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local UI = {}

function UI:CreateWindow()
    local Window = {}

    local guiName = LocalPlayer.UserId .. "_NinjaHub"

    local existingGui = CoreGui:FindFirstChild(guiName)
    if existingGui then
        existingGui:Destroy()
    end

    local ScreenGui = Instance_new("ScreenGui")
    ScreenGui.Name = guiName
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false

    local connections = {}
    local function addConnection(conn)
        table.insert(connections, conn)
        return conn
    end

    local function cleanupConnections()
        for i = 1, #connections do
            local conn = connections[i]
            if conn and conn.Connected then
                conn:Disconnect()
            end
        end
        table.clear(connections)
    end

    ScreenGui.Destroying:Connect(cleanupConnections)

    local NotifContainer = Instance_new("Frame")
    NotifContainer.Name = "NotifContainer"
    NotifContainer.Parent = ScreenGui
    NotifContainer.BackgroundTransparency = 1
    NotifContainer.Size = UDim2_new(1, 0, 0, 0)
    NotifContainer.Position = UDim2_new(0, 0, 0, 30)
    NotifContainer.ZIndex = 100

    local NotifLayout = Instance_new("UIListLayout")
    NotifLayout.Parent = NotifContainer
    NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    NotifLayout.Padding = UDim.new(0, 10)

    function Window:Notify(text, duration)
        duration = duration or 3
        local NotifFrame = Instance_new("Frame")
        NotifFrame.Size = UDim2_new(0, 300, 0, 40)
        NotifFrame.BackgroundColor3 = Color3_fromRGB(22, 22, 22)
        NotifFrame.BorderSizePixel = 0
        NotifFrame.BackgroundTransparency = 1

        local corner = Instance_new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = NotifFrame

        local stroke = Instance_new("UIStroke")
        stroke.Thickness = 1.5
        stroke.Color = Color3_fromRGB(255, 0, 75)
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Transparency = 1
        stroke.Parent = NotifFrame

        local NotifText = Instance_new("TextLabel")
        NotifText.Parent = NotifFrame
        NotifText.Size = UDim2_new(1, -20, 1, 0)
        NotifText.Position = UDim2_new(0, 10, 0, 0)
        NotifText.BackgroundTransparency = 1
        NotifText.Text = text
        NotifText.TextColor3 = Color3_fromRGB(255, 255, 255)
        NotifText.Font = Enum.Font.GothamBold
        NotifText.TextSize = 13
        NotifText.TextWrapped = true
        NotifText.TextTransparency = 1

        NotifFrame.Parent = NotifContainer

        TweenService:Create(NotifFrame, tweenMedium, {BackgroundTransparency = 0}):Play()
        TweenService:Create(stroke, tweenMedium, {Transparency = 0}):Play()
        TweenService:Create(NotifText, tweenMedium, {TextTransparency = 0}):Play()

        task.delay(duration, function()
            if NotifFrame and NotifFrame.Parent then
                TweenService:Create(NotifFrame, tweenMedium, {BackgroundTransparency = 1}):Play()
                TweenService:Create(stroke, tweenMedium, {Transparency = 1}):Play()
                TweenService:Create(NotifText, tweenMedium, {TextTransparency = 1}):Play()
                task.wait(0.3)
                if NotifFrame then
                    NotifFrame:Destroy()
                end
            end
        end)
    end

    local function MakeDraggable(topbarobject, object)
        local dragging = false
        local dragInput, mousePos, framePos
        local moveConn, endConn

        topbarobject.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                mousePos = input.Position
                framePos = object.Position

                if moveConn then moveConn:Disconnect() end
                if endConn then endConn:Disconnect() end

                moveConn = addConnection(UserInputService.InputChanged:Connect(function(inp)
                    if dragging and (inp == dragInput or inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                        local delta = inp.Position - mousePos
                        object.Position = UDim2_new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
                    end
                end))

                endConn = addConnection(UserInputService.InputEnded:Connect(function(endInput)
                    if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                        if moveConn then moveConn:Disconnect(); moveConn = nil end
                        if endConn then endConn:Disconnect(); endConn = nil end
                    end
                end))
            end
        end)

        topbarobject.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
    end

    local Main = Instance_new("Frame")
    Main.Name = "Main"
    Main.Parent = ScreenGui
    Main.BackgroundColor3 = Color3_fromRGB(15, 15, 15)
    Main.BorderSizePixel = 0
    Main.Position = UDim2_new(0.5, -250, 0.5, -150)
    Main.Size = UDim2_new(0, 500, 0, 350)
    Main.ClipsDescendants = true

    local MainCorner = Instance_new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = Main

    local MainStroke = Instance_new("UIStroke")
    MainStroke.Thickness = 1.5
    MainStroke.Color = Color3_fromRGB(45, 45, 45)
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainStroke.Parent = Main

    local TopBar = Instance_new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Parent = Main
    TopBar.BackgroundColor3 = Color3_fromRGB(22, 22, 22)
    TopBar.Size = UDim2_new(1, 0, 0, 40)
    TopBar.BorderSizePixel = 0
    MakeDraggable(TopBar, Main)

    local TopCorner = Instance_new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 8)
    TopCorner.Parent = TopBar

    local Title = Instance_new("TextLabel")
    Title.Parent = TopBar
    Title.Text = "NINJA TYCOON V1.1.4 <font color='#FF004B'>BY @theuniqueleader</font>"
    Title.RichText = true
    Title.TextColor3 = Color3_fromRGB(255, 255, 255)
    Title.Size = UDim2_new(1, -80, 1, 0)
    Title.Position = UDim2_new(0, 15, 0, 0)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14

    local CloseBtn = Instance_new("TextButton")
    CloseBtn.Parent = TopBar
    CloseBtn.Size = UDim2_new(0, 35, 0, 35)
    CloseBtn.Position = UDim2_new(1, -40, 0.5, -17)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3_fromRGB(255, 50, 50)
    CloseBtn.TextSize = 18
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Activated:Connect(function()
        ScreenGui:Destroy()
    end)

    local MinBtn = Instance_new("TextButton")
    MinBtn.Parent = TopBar
    MinBtn.Size = UDim2_new(0, 35, 0, 35)
    MinBtn.Position = UDim2_new(1, -75, 0.5, -17)
    MinBtn.BackgroundTransparency = 1
    MinBtn.Text = "—"
    MinBtn.TextColor3 = Color3_fromRGB(200, 200, 200)
    MinBtn.TextSize = 16
    MinBtn.Font = Enum.Font.GothamBold

    local isMinimized = false
    local originalPos = Main.Position
    MinBtn.Activated:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            originalPos = Main.Position
            TweenService:Create(Main, tweenQuartOut, {Position = UDim2_new(0, 10, 1, -50), Size = UDim2_new(0, 180, 0, 40)}):Play()
        else
            TweenService:Create(Main, tweenQuartOut, {Position = originalPos, Size = UDim2_new(0, 500, 0, 350)}):Play()
        end
    end)

    local TabBar = Instance_new("Frame")
    TabBar.Name = "TabBar"
    TabBar.Parent = Main
    TabBar.BackgroundColor3 = Color3_fromRGB(18, 18, 18)
    TabBar.Position = UDim2_new(0, 0, 0, 40)
    TabBar.Size = UDim2_new(0, 110, 1, -40)
    TabBar.BorderSizePixel = 0

    local TabListLayout = Instance_new("UIListLayout")
    TabListLayout.Parent = TabBar
    TabListLayout.Padding = UDim.new(0, 5)
    TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local TabPadding = Instance_new("UIPadding")
    TabPadding.Parent = TabBar
    TabPadding.PaddingTop = UDim.new(0, 10)

    local Pages = Instance_new("Frame")
    Pages.Name = "Pages"
    Pages.Parent = Main
    Pages.BackgroundTransparency = 1
    Pages.Position = UDim2_new(0, 120, 0, 50)
    Pages.Size = UDim2_new(1, -130, 1, -60)

    Window.Pages = Pages
    Window.TabBar = TabBar
    Window.TabCount = 0

    function Window:CreateTab(name)
        local Tab = {}
        Window.TabCount = Window.TabCount + 1

        local Page = Instance_new("ScrollingFrame")
        Page.Name = name .. "Page"
        Page.Parent = Window.Pages
        Page.BackgroundTransparency = 1
        Page.Size = UDim2_new(1, 0, 1, 0)
        Page.ScrollBarThickness = 2
        Page.ScrollBarImageColor3 = Color3_fromRGB(255, 0, 75)
        Page.Visible = (Window.TabCount == 1)
        Page.CanvasSize = UDim2_new(0, 0, 0, 0)

        local PageLayout = Instance_new("UIListLayout")
        PageLayout.Parent = Page
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2_new(0, 0, 0, PageLayout.AbsoluteContentSize.Y)
        end)

        local TabBtn = Instance_new("TextButton")
        TabBtn.Name = name .. "Tab"
        TabBtn.Parent = Window.TabBar
        TabBtn.Size = UDim2_new(0, 100, 0, 32)
        
        if Window.TabCount == 1 then
            TabBtn.BackgroundColor3 = Color3_fromRGB(255, 0, 75)
            TabBtn.TextColor3 = Color3_fromRGB(255, 255, 255)
        else
            TabBtn.BackgroundColor3 = Color3_fromRGB(25, 25, 25)
            TabBtn.TextColor3 = Color3_fromRGB(150, 150, 150)
        end
        
        TabBtn.BorderSizePixel = 0
        TabBtn.Text = name
        TabBtn.Font = Enum.Font.GothamBold
        TabBtn.TextSize = 11

        local TabCorner = Instance_new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 6)
        TabCorner.Parent = TabBtn

        TabBtn.Activated:Connect(function()
            local pagesChildren = Window.Pages:GetChildren()
            for i = 1, #pagesChildren do 
                pagesChildren[i].Visible = false 
            end

            local tabChildren = Window.TabBar:GetChildren()
            for i = 1, #tabChildren do
                local t = tabChildren[i]
                if t:IsA("TextButton") then 
                    TweenService:Create(t, tweenMedium, {TextColor3 = Color3_fromRGB(150, 150, 150), BackgroundColor3 = Color3_fromRGB(25, 25, 25)}):Play()
                end
            end
            Page.Visible = true
            TweenService:Create(TabBtn, tweenMedium, {TextColor3 = Color3_fromRGB(255, 255, 255), BackgroundColor3 = Color3_fromRGB(255, 0, 75)}):Play()
        end)

        function Tab:CreateLabel(text)
            local LabelFrame = Instance_new("Frame")
            LabelFrame.Size = UDim2_new(1, 0, 0, 28)
            LabelFrame.BackgroundTransparency = 1
            LabelFrame.Parent = Page

            local Label = Instance_new("TextLabel")
            Label.Parent = LabelFrame
            Label.Size = UDim2_new(1, -10, 1, 0)
            Label.Position = UDim2_new(0, 5, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Color3_fromRGB(180, 180, 180)
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 12
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextWrapped = true
        end

        function Tab:CreateToggle(config)
            local ToggleFrame = Instance_new("Frame")
            ToggleFrame.Size = UDim2_new(1, 0, 0, 38)
            ToggleFrame.BackgroundTransparency = 1
            ToggleFrame.Parent = Page

            local TextBtn = Instance_new("TextButton")
            TextBtn.Parent = ToggleFrame
            TextBtn.BackgroundColor3 = Color3_fromRGB(25, 25, 25)
            TextBtn.Size = UDim2_new(1, 0, 1, 0)
            TextBtn.Text = "   " .. config.Name
            TextBtn.TextColor3 = Color3_fromRGB(200, 200, 200)
            TextBtn.Font = Enum.Font.Gotham
            TextBtn.TextSize = 13
            TextBtn.TextXAlignment = Enum.TextXAlignment.Left
            TextBtn.BorderSizePixel = 0

            local btnCorner = Instance_new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = TextBtn

            local StatusContainer = Instance_new("Frame")
            StatusContainer.Parent = TextBtn
            StatusContainer.BackgroundColor3 = Color3_fromRGB(40, 40, 40)
            StatusContainer.Position = UDim2_new(1, -45, 0.5, -10)
            StatusContainer.Size = UDim2_new(0, 35, 0, 20)
            StatusContainer.BorderSizePixel = 0

            local statusCorner = Instance_new("UICorner")
            statusCorner.CornerRadius = UDim.new(1, 0)
            statusCorner.Parent = StatusContainer

            local StatusCircle = Instance_new("Frame")
            StatusCircle.Parent = StatusContainer
            StatusCircle.BackgroundColor3 = Color3_fromRGB(150, 150, 150)
            StatusCircle.Position = UDim2_new(0, 2, 0.5, -8)
            StatusCircle.Size = UDim2_new(0, 16, 0, 16)
            StatusCircle.BorderSizePixel = 0

            local circleCorner = Instance_new("UICorner")
            circleCorner.CornerRadius = UDim.new(1, 0)
            circleCorner.Parent = StatusCircle

            local enabled = false

            local function SetState(state)
                enabled = state
                if enabled then
                    TweenService:Create(StatusCircle, tweenNormal, {Position = UDim2_new(1, -18, 0.5, -8), BackgroundColor3 = Color3_fromRGB(255, 255, 255)}):Play()
                    TweenService:Create(StatusContainer, tweenNormal, {BackgroundColor3 = Color3_fromRGB(255, 0, 75)}):Play()
                else
                    TweenService:Create(StatusCircle, tweenNormal, {Position = UDim2_new(0, 2, 0.5, -8), BackgroundColor3 = Color3_fromRGB(150, 150, 150)}):Play()
                    TweenService:Create(StatusContainer, tweenNormal, {BackgroundColor3 = Color3_fromRGB(40, 40, 40)}):Play()
                end
            end

            TextBtn.Activated:Connect(function()
                enabled = not enabled
                SetState(enabled)
                if config.Callback then config.Callback(enabled, SetState) end
            end)
            return SetState
        end

        function Tab:CreateBind(config)
            local BindFrame = Instance_new("Frame")
            BindFrame.Size = UDim2_new(1, 0, 0, 38)
            BindFrame.BackgroundTransparency = 1
            BindFrame.Parent = Page

            local Container = Instance_new("Frame")
            Container.Size = UDim2_new(1, 0, 1, 0)
            Container.BackgroundColor3 = Color3_fromRGB(25, 25, 25)
            Container.Parent = BindFrame

            local cCorner = Instance_new("UICorner")
            cCorner.CornerRadius = UDim.new(0, 6)
            cCorner.Parent = Container

            local Label = Instance_new("TextLabel")
            Label.Parent = Container
            Label.Size = UDim2_new(1, -100, 1, 0)
            Label.BackgroundTransparency = 1
            Label.Text = "   " .. config.Name
            Label.TextColor3 = Color3_fromRGB(200, 200, 200)
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left

            local BindBtn = Instance_new("TextButton")
            BindBtn.Parent = Container
            BindBtn.BackgroundColor3 = Color3_fromRGB(40, 40, 40)
            BindBtn.Size = UDim2_new(0, 80, 0, 24)
            BindBtn.Position = UDim2_new(1, -90, 0.5, -12)
            BindBtn.Text = config.Default and tostring(config.Default.Name or config.Default) or "NONE"
            BindBtn.TextColor3 = Color3_fromRGB(255, 255, 255)
            BindBtn.Font = Enum.Font.GothamBold
            BindBtn.TextSize = 11
            BindBtn.BorderSizePixel = 0

            local bCorner = Instance_new("UICorner")
            bCorner.CornerRadius = UDim.new(0, 4)
            bCorner.Parent = BindBtn

            local bindConn
            BindBtn.Activated:Connect(function()
                if bindConn then
                    bindConn:Disconnect()
                    bindConn = nil
                end

                BindBtn.Text = "..."
                if config.BindTable then config.BindTable.IsBinding = true end

                bindConn = addConnection(UserInputService.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.Keyboard 
                       or i.UserInputType == Enum.UserInputType.MouseButton2 
                       or i.UserInputType == Enum.UserInputType.MouseButton3 
                       or i.UserInputType == Enum.UserInputType.MouseButton4 
                       or i.UserInputType == Enum.UserInputType.MouseButton5
                       or i.KeyCode.Name:find("Button") then
                        
                        local key = (i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode) 
                                 or (i.KeyCode.Name:find("Button") and i.KeyCode) 
                                 or i.UserInputType

                        if config.BindTable and config.KeyIndex then
                            config.BindTable[config.KeyIndex] = key
                        end
                        BindBtn.Text = tostring(key.Name or key)
                        if config.BindTable then config.BindTable.IsBinding = false end

                        if bindConn then
                            bindConn:Disconnect()
                            bindConn = nil
                        end
                    end
                end))
            end)
        end

        function Tab:CreateButton(config)
            local TextBtn = Instance_new("TextButton")
            TextBtn.Parent = Page
            TextBtn.BackgroundColor3 = Color3_fromRGB(35, 35, 35)
            TextBtn.Size = UDim2_new(1, 0, 0, 38)
            TextBtn.Text = config.Name
            TextBtn.TextColor3 = Color3_fromRGB(255, 255, 255)
            TextBtn.Font = Enum.Font.GothamBold
            TextBtn.TextSize = 13
            TextBtn.BorderSizePixel = 0

            local btnCorner = Instance_new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = TextBtn

            TextBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    TweenService:Create(TextBtn, tweenFast, {BackgroundColor3 = Color3_fromRGB(255, 0, 75)}):Play()
                end
            end)

            TextBtn.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    TweenService:Create(TextBtn, tweenFast, {BackgroundColor3 = Color3_fromRGB(35, 35, 35)}):Play()
                end
            end)

            TextBtn.Activated:Connect(function()
                if config.Callback then config.Callback() end
            end)
        end

        function Tab:CreateSlider(config)
            local SliderFrame = Instance_new("Frame")
            SliderFrame.Size = UDim2_new(1, 0, 0, 50)
            SliderFrame.BackgroundColor3 = Color3_fromRGB(25, 25, 25)
            SliderFrame.Parent = Page

            local sCorner = Instance_new("UICorner")
            sCorner.CornerRadius = UDim.new(0, 6)
            sCorner.Parent = SliderFrame

            local Label = Instance_new("TextLabel")
            Label.Parent = SliderFrame
            Label.Text = "   " .. config.Name .. " : " .. config.Default
            Label.TextColor3 = Color3_fromRGB(200, 200, 200)
            Label.Size = UDim2_new(1, 0, 0, 25)
            Label.BackgroundTransparency = 1
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 12
            Label.TextXAlignment = Enum.TextXAlignment.Left

            local SliderBack = Instance_new("Frame")
            SliderBack.Parent = SliderFrame
            SliderBack.BackgroundColor3 = Color3_fromRGB(45, 45, 45)
            SliderBack.Position = UDim2_new(0, 10, 0, 30)
            SliderBack.Size = UDim2_new(1, -20, 0, 6)
            SliderBack.BorderSizePixel = 0

            local sbCorner = Instance_new("UICorner")
            sbCorner.CornerRadius = UDim.new(1, 0)
            sbCorner.Parent = SliderBack

            local SliderFill = Instance_new("Frame")
            SliderFill.Parent = SliderBack
            SliderFill.BackgroundColor3 = Color3_fromRGB(255, 0, 75)
            SliderFill.Size = UDim2_new((config.Default - config.Min) / (config.Max - config.Min), 0, 1, 0)
            SliderFill.BorderSizePixel = 0

            local sfCorner = Instance_new("UICorner")
            sfCorner.CornerRadius = UDim.new(1, 0)
            sfCorner.Parent = SliderFill

            local sliding = false
            local moveConn, endConn

            local function update(input)
                local pos = math.clamp((input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
                SliderFill.Size = UDim2_new(pos, 0, 1, 0)
                local val = math.floor(((config.Max - config.Min) * pos) + config.Min)
                Label.Text = "   " .. config.Name .. " : " .. val
                if config.Callback then config.Callback(val) end
            end

            SliderBack.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
                    sliding = true 
                    update(input)

                    if moveConn then moveConn:Disconnect() end
                    if endConn then endConn:Disconnect() end

                    moveConn = addConnection(UserInputService.InputChanged:Connect(function(inp)
                        if sliding and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then 
                            update(inp) 
                        end
                    end))

                    endConn = addConnection(UserInputService.InputEnded:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then 
                            sliding = false 
                            if moveConn then moveConn:Disconnect(); moveConn = nil end
                            if endConn then endConn:Disconnect(); endConn = nil end
                        end
                    end))
                end
            end)
        end
        
        function Tab:CreateTextBox(config)
            local TextBoxFrame = Instance_new("Frame")
            TextBoxFrame.Size = UDim2_new(1, 0, 0, 38)
            TextBoxFrame.BackgroundTransparency = 1
            TextBoxFrame.Parent = Page

            local Container = Instance_new("Frame")
            Container.Size = UDim2_new(1, 0, 1, 0)
            Container.BackgroundColor3 = Color3_fromRGB(25, 25, 25)
            Container.Parent = TextBoxFrame

            local cCorner = Instance_new("UICorner")
            cCorner.CornerRadius = UDim.new(0, 6)
            cCorner.Parent = Container

            local TextBox = Instance_new("TextBox")
            TextBox.Parent = Container
            TextBox.Size = UDim2_new(1, -20, 1, 0)
            TextBox.Position = UDim2_new(0, 10, 0, 0)
            TextBox.BackgroundTransparency = 1
            TextBox.Text = config.Default or ""
            TextBox.PlaceholderText = config.Name or "Enter text..."
            TextBox.TextColor3 = Color3_fromRGB(200, 200, 200)
            TextBox.PlaceholderColor3 = Color3_fromRGB(150, 150, 150)
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

        return Tab
    end

    return Window
end

return UI
