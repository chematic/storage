local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local UI = {}

function UI:CreateWindow()
    local Window = {}

    if CoreGui:FindFirstChild("NinjaHub") then
        CoreGui:FindFirstChild("NinjaHub"):Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NinjaHub"
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false

    local function MakeDraggable(topbarobject, object)
        local dragging = false
        local dragInput, mousePos, framePos
        topbarobject.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
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
            if input.UserInputType == Enum.UserInputType.MouseMovement then
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

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Parent = ScreenGui
    Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, -250, 0.5, -150)
    Main.Size = UDim2.new(0, 500, 0, 350)
    Main.ClipsDescendants = true

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = Main

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Thickness = 1.5
    MainStroke.Color = Color3.fromRGB(45, 45, 45)
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainStroke.Parent = Main

    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Parent = Main
    TopBar.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    TopBar.Size = UDim2.new(1, 0, 0, 40)
    TopBar.BorderSizePixel = 0
    MakeDraggable(TopBar, Main)

    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 8)
    TopCorner.Parent = TopBar

    local Title = Instance.new("TextLabel")
    Title.Parent = TopBar
    Title.Text = "NINJA TYCOON V1 <font color='#FF004B'>BY @VHB7</font>"
    Title.RichText = true
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Size = UDim2.new(1, -80, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Parent = TopBar
    CloseBtn.Size = UDim2.new(0, 35, 0, 35)
    CloseBtn.Position = UDim2.new(1, -40, 0.5, -17)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
    CloseBtn.TextSize = 18
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    local MinBtn = Instance.new("TextButton")
    MinBtn.Parent = TopBar
    MinBtn.Size = UDim2.new(0, 35, 0, 35)
    MinBtn.Position = UDim2.new(1, -75, 0.5, -17)
    MinBtn.BackgroundTransparency = 1
    MinBtn.Text = "—"
    MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    MinBtn.TextSize = 16
    MinBtn.Font = Enum.Font.GothamBold

    local isMinimized = false
    local originalPos = Main.Position
    MinBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            originalPos = Main.Position
            TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 10, 1, -50), Size = UDim2.new(0, 180, 0, 40)}):Play()
        else
            TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = originalPos, Size = UDim2.new(0, 500, 0, 350)}):Play()
        end
    end)

    local TabBar = Instance.new("Frame")
    TabBar.Name = "TabBar"
    TabBar.Parent = Main
    TabBar.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    TabBar.Position = UDim2.new(0, 0, 0, 40)
    TabBar.Size = UDim2.new(0, 110, 1, -40)
    TabBar.BorderSizePixel = 0

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

    function Window:CreateTab(name)
        local Tab = {}
        Window.TabCount = Window.TabCount + 1

        local Page = Instance.new("ScrollingFrame")
        Page.Name = name .. "Page"
        Page.Parent = Window.Pages
        Page.BackgroundTransparency = 1
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.ScrollBarThickness = 2
        Page.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 75)
        Page.Visible = (Window.TabCount == 1)
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Parent = Page
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y)
        end)

        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = name .. "Tab"
        TabBtn.Parent = Window.TabBar
        TabBtn.Size = UDim2.new(0, 100, 0, 32)
        
        if Window.TabCount == 1 then
            TabBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 75)
            TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            TabBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            TabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
        
        TabBtn.BorderSizePixel = 0
        TabBtn.Text = name
        TabBtn.Font = Enum.Font.GothamBold
        TabBtn.TextSize = 11

        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 6)
        TabCorner.Parent = TabBtn

        TabBtn.MouseButton1Click:Connect(function()
            for _, p in pairs(Window.Pages:GetChildren()) do p.Visible = false end
            for _, t in pairs(Window.TabBar:GetChildren()) do
                if t:IsA("TextButton") then 
                    TweenService:Create(t, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(150, 150, 150), BackgroundColor3 = Color3.fromRGB(25, 25, 25)}):Play()
                end
            end
            Page.Visible = true
            TweenService:Create(TabBtn, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = Color3.fromRGB(255, 0, 75)}):Play()
        end)

        function Tab:CreateToggle(config)
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Size = UDim2.new(1, 0, 0, 38)
            ToggleFrame.BackgroundTransparency = 1
            ToggleFrame.Parent = Page

            local TextBtn = Instance.new("TextButton")
            TextBtn.Parent = ToggleFrame
            TextBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            TextBtn.Size = UDim2.new(1, 0, 1, 0)
            TextBtn.Text = "   " .. config.Name
            TextBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
            TextBtn.Font = Enum.Font.Gotham
            TextBtn.TextSize = 13
            TextBtn.TextXAlignment = Enum.TextXAlignment.Left
            TextBtn.BorderSizePixel = 0

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = TextBtn

            local StatusContainer = Instance.new("Frame")
            StatusContainer.Parent = TextBtn
            StatusContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            StatusContainer.Position = UDim2.new(1, -45, 0.5, -10)
            StatusContainer.Size = UDim2.new(0, 35, 0, 20)
            StatusContainer.BorderSizePixel = 0

            local statusCorner = Instance.new("UICorner")
            statusCorner.CornerRadius = UDim.new(1, 0)
            statusCorner.Parent = StatusContainer

            local StatusCircle = Instance.new("Frame")
            StatusCircle.Parent = StatusContainer
            StatusCircle.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
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
                    TweenService:Create(StatusCircle, TweenInfo.new(0.2), {Position = UDim2.new(1, -18, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                    TweenService:Create(StatusContainer, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 0, 75)}):Play()
                else
                    TweenService:Create(StatusCircle, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = Color3.fromRGB(150, 150, 150)}):Play()
                    TweenService:Create(StatusContainer, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
                end
            end

            TextBtn.MouseButton1Click:Connect(function()
                enabled = not enabled
                SetState(enabled)
                if config.Callback then config.Callback(enabled, SetState) end
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
            Container.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            Container.Parent = BindFrame

            local cCorner = Instance.new("UICorner")
            cCorner.CornerRadius = UDim.new(0, 6)
            cCorner.Parent = Container

            local Label = Instance.new("TextLabel")
            Label.Parent = Container
            Label.Size = UDim2.new(1, -100, 1, 0)
            Label.BackgroundTransparency = 1
            Label.Text = "   " .. config.Name
            Label.TextColor3 = Color3.fromRGB(200, 200, 200)
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left

            local BindBtn = Instance.new("TextButton")
            BindBtn.Parent = Container
            BindBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            BindBtn.Size = UDim2.new(0, 80, 0, 24)
            BindBtn.Position = UDim2.new(1, -90, 0.5, -12)
            BindBtn.Text = config.Default and tostring(config.Default.Name or config.Default) or "NONE"
            BindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            BindBtn.Font = Enum.Font.GothamBold
            BindBtn.TextSize = 11
            BindBtn.BorderSizePixel = 0

            local bCorner = Instance.new("UICorner")
            bCorner.CornerRadius = UDim.new(0, 4)
            bCorner.Parent = BindBtn

            BindBtn.MouseButton1Click:Connect(function()
                BindBtn.Text = "..."
                if config.BindTable then config.BindTable.IsBinding = true end
                local conn
                conn = UserInputService.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.Keyboard or i.UserInputType == Enum.UserInputType.MouseButton2 or i.UserInputType == Enum.UserInputType.MouseButton3 or i.UserInputType == Enum.UserInputType.MouseButton4 or i.UserInputType == Enum.UserInputType.MouseButton5 then
                        local key = (i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode or i.UserInputType)
                        if config.BindTable and config.KeyIndex then
                            config.BindTable[config.KeyIndex] = key
                        end
                        BindBtn.Text = tostring(key.Name or key)
                        if config.BindTable then config.BindTable.IsBinding = false end
                        conn:Disconnect()
                    end
                end)
            end)
        end

        function Tab:CreateButton(config)
            local TextBtn = Instance.new("TextButton")
            TextBtn.Parent = Page
            TextBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            TextBtn.Size = UDim2.new(1, 0, 0, 38)
            TextBtn.Text = config.Name
            TextBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            TextBtn.Font = Enum.Font.GothamBold
            TextBtn.TextSize = 13
            TextBtn.BorderSizePixel = 0

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = TextBtn

            TextBtn.MouseButton1Down:Connect(function()
                TweenService:Create(TextBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(255, 0, 75)}):Play()
            end)
            TextBtn.MouseButton1Up:Connect(function()
                TweenService:Create(TextBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}):Play()
            end)
            TextBtn.MouseButton1Click:Connect(function()
                if config.Callback then config.Callback() end
            end)
        end

        function Tab:CreateSlider(config)
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Size = UDim2.new(1, 0, 0, 50)
            SliderFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            SliderFrame.Parent = Page

            local sCorner = Instance.new("UICorner")
            sCorner.CornerRadius = UDim.new(0, 6)
            sCorner.Parent = SliderFrame

            local Label = Instance.new("TextLabel")
            Label.Parent = SliderFrame
            Label.Text = "   " .. config.Name .. " : " .. config.Default
            Label.TextColor3 = Color3.fromRGB(200, 200, 200)
            Label.Size = UDim2.new(1, 0, 0, 25)
            Label.BackgroundTransparency = 1
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 12
            Label.TextXAlignment = Enum.TextXAlignment.Left

            local SliderBack = Instance.new("Frame")
            SliderBack.Parent = SliderFrame
            SliderBack.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            SliderBack.Position = UDim2.new(0, 10, 0, 30)
            SliderBack.Size = UDim2.new(1, -20, 0, 6)
            SliderBack.BorderSizePixel = 0

            local sbCorner = Instance.new("UICorner")
            sbCorner.CornerRadius = UDim.new(1, 0)
            sbCorner.Parent = SliderBack

            local SliderFill = Instance.new("Frame")
            SliderFill.Parent = SliderBack
            SliderFill.BackgroundColor3 = Color3.fromRGB(255, 0, 75)
            SliderFill.Size = UDim2.new((config.Default - config.Min) / (config.Max - config.Min), 0, 1, 0)
            SliderFill.BorderSizePixel = 0

            local sfCorner = Instance.new("UICorner")
            sfCorner.CornerRadius = UDim.new(1, 0)
            sfCorner.Parent = SliderFill

            local sliding = false
            local function update(input)
                local pos = math.clamp((input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
                SliderFill.Size = UDim2.new(pos, 0, 1, 0)
                local val = math.floor(((config.Max - config.Min) * pos) + config.Min)
                Label.Text = "   " .. config.Name .. " : " .. val
                if config.Callback then config.Callback(val) end
            end
            SliderBack.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true update(input) end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then update(input) end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
            end)
        end
        
        function Tab:CreateTextBox(config)
            local TextBoxFrame = Instance.new("Frame")
            TextBoxFrame.Size = UDim2.new(1, 0, 0, 38)
            TextBoxFrame.BackgroundTransparency = 1
            TextBoxFrame.Parent = Page

            local Container = Instance.new("Frame")
            Container.Size = UDim2.new(1, 0, 1, 0)
            Container.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            Container.Parent = TextBoxFrame

            local cCorner = Instance.new("UICorner")
            cCorner.CornerRadius = UDim.new(0, 6)
            cCorner.Parent = Container

            local TextBox = Instance.new("TextBox")
            TextBox.Parent = Container
            TextBox.Size = UDim2.new(1, -20, 1, 0)
            TextBox.Position = UDim2.new(0, 10, 0, 0)
            TextBox.BackgroundTransparency = 1
            TextBox.Text = config.Default or ""
            TextBox.PlaceholderText = config.Name or "Enter text..."
            TextBox.TextColor3 = Color3.fromRGB(200, 200, 200)
            TextBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
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
