local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- Paramètres de design
local NEON_BLUE = Color3.fromRGB(0, 195, 255)
local GLOW_BLUE = Color3.fromRGB(100, 220, 255)
local DARK_BG = Color3.fromRGB(15, 15, 15)
local COMPONENT_BG = Color3.fromRGB(25, 25, 25)
local HOVER_BG = Color3.fromRGB(35, 35, 35)

local UI = {}

function UI:CreateWindow()
    local Window = {}
    local connections = {}
    local guiName = LocalPlayer.UserId .. "_SlayerHub"

    local existingGui = CoreGui:FindFirstChild(guiName)
    if existingGui then
        existingGui:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = guiName
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false

    -- Nettoyage global à la destruction de la GUI
    table.insert(connections, ScreenGui.Destroying:Connect(function()
        for _, conn in ipairs(connections) do
            if typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            end
        end
    end))

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

    function Window:Notify(text, duration)
        duration = duration or 3
        local NotifFrame = Instance.new("Frame")
        NotifFrame.Size = UDim2.new(0, 300, 0, 40)
        NotifFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        NotifFrame.BorderSizePixel = 0
        NotifFrame.BackgroundTransparency = 1
        
        local NotifScale = Instance.new("UIScale", NotifFrame)
        NotifScale.Scale = 0.8

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = NotifFrame

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1.5
        stroke.Color = NEON_BLUE
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Transparency = 1
        stroke.Parent = NotifFrame

        local NotifText = Instance.new("TextLabel")
        NotifText.Parent = NotifFrame
        NotifText.Size = UDim2.new(1, -20, 1, 0)
        NotifText.Position = UDim2.new(0, 10, 0, 0)
        NotifText.BackgroundTransparency = 1
        NotifText.Text = text
        NotifText.TextColor3 = Color3.fromRGB(255, 255, 255)
        NotifText.Font = Enum.Font.GothamBold
        NotifText.TextSize = 13
        NotifText.TextWrapped = true
        NotifText.TextTransparency = 1

        NotifFrame.Parent = NotifContainer

        -- Animation d'apparition Notif
        TweenService:Create(NotifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.1}):Play()
        TweenService:Create(NotifScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.4), {Transparency = 0}):Play()
        TweenService:Create(NotifText, TweenInfo.new(0.4), {TextTransparency = 0}):Play()

        task.delay(duration, function()
            if not NotifFrame or not NotifFrame.Parent then return end
            TweenService:Create(NotifScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0.8}):Play()
            TweenService:Create(NotifFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
            TweenService:Create(NotifText, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
            task.wait(0.3)
            if NotifFrame then NotifFrame:Destroy() end
        end)
    end

    local function MakeDraggable(topbarobject, object)
        local dragging, dragInput, mousePos, framePos

        table.insert(connections, topbarobject.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                mousePos = input.Position
                framePos = object.Position
                
                local innerConn
                innerConn = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        innerConn:Disconnect()
                    end
                end)
                table.insert(connections, innerConn)
            end
        end))

        table.insert(connections, topbarobject.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end))

        table.insert(connections, UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - mousePos
                object.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
            end
        end))
    end

    -- CanvasGroup permet de gérer la transparence globale (Fade-In/Out propre)
    local Main = Instance.new("CanvasGroup")
    Main.Name = "Main"
    Main.Parent = ScreenGui
    Main.BackgroundColor3 = DARK_BG
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, -250, 0.5, -150)
    Main.Size = UDim2.new(0, 500, 0, 350)
    Main.GroupTransparency = 1 -- Début invisible pour l'animation
    
    local MainScale = Instance.new("UIScale", Main)
    MainScale.Scale = 0.85

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = Main

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Thickness = 1.5
    MainStroke.Color = Color3.fromRGB(40, 40, 40)
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainStroke.Parent = Main

    -- Animation d'ouverture (Pop-up smooth + Fade-in)
    TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
    TweenService:Create(MainScale, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()

    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Parent = Main
    TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    TopBar.Size = UDim2.new(1, 0, 0, 40)
    TopBar.BorderSizePixel = 0
    MakeDraggable(TopBar, Main)

    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 8)
    TopCorner.Parent = TopBar

    local Title = Instance.new("TextLabel")
    Title.Parent = TopBar
    Title.Text = "SLAYER TYCOON V1 <font color='#00C3FF'>BY @theuniqueleader</font>"
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
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    CloseBtn.TextSize = 16
    CloseBtn.Font = Enum.Font.GothamBold
    
    -- Animations du bouton Close
    table.insert(connections, CloseBtn.MouseEnter:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 50, 50), Rotation = 90, TextSize = 18}):Play()
    end))
    table.insert(connections, CloseBtn.MouseLeave:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(150, 150, 150), Rotation = 0, TextSize = 16}):Play()
    end))
    
    table.insert(connections, CloseBtn.MouseButton1Click:Connect(function()
        -- Animation de fermeture propre avant Destroy()
        TweenService:Create(MainScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0.85}):Play()
        local closeTween = TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {GroupTransparency = 1})
        closeTween:Play()
        closeTween.Completed:Wait()
        ScreenGui:Destroy()
    end))

    local MinBtn = Instance.new("TextButton")
    MinBtn.Parent = TopBar
    MinBtn.Size = UDim2.new(0, 35, 0, 35)
    MinBtn.Position = UDim2.new(1, -75, 0.5, -17)
    MinBtn.BackgroundTransparency = 1
    MinBtn.Text = "‒"
    MinBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    MinBtn.TextSize = 16
    MinBtn.Font = Enum.Font.GothamBold

    table.insert(connections, MinBtn.MouseEnter:Connect(function()
        TweenService:Create(MinBtn, TweenInfo.new(0.2), {TextColor3 = NEON_BLUE}):Play()
    end))
    table.insert(connections, MinBtn.MouseLeave:Connect(function()
        TweenService:Create(MinBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(150, 150, 150)}):Play()
    end))

    local isMinimized = false
    local originalPos = Main.Position
    table.insert(connections, MinBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            originalPos = Main.Position
            TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 10, 1, -50), Size = UDim2.new(0, 200, 0, 40)}):Play()
        else
            TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = originalPos, Size = UDim2.new(0, 500, 0, 350)}):Play()
        end
    end))

    local TabBar = Instance.new("Frame")
    TabBar.Name = "TabBar"
    TabBar.Parent = Main
    TabBar.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    TabBar.Position = UDim2.new(0, 0, 0, 40)
    TabBar.Size = UDim2.new(0, 110, 1, -40)
    TabBar.BorderSizePixel = 0
    
    -- [[ CORRECTION ICI: Ajout du UICorner pour empêcher la TabBar de déborder en bas à gauche ]]
    local TabBarCorner = Instance.new("UICorner")
    TabBarCorner.CornerRadius = UDim.new(0, 8)
    TabBarCorner.Parent = TabBar

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.Parent = TabBar
    TabListLayout.Padding = UDim.new(0, 6)
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

    -- Fonction pour générer un effet de Flash (clic)
    local function CreateFlash(parent)
        local flash = Instance.new("Frame")
        flash.Size = UDim2.new(1, 0, 1, 0)
        flash.BackgroundColor3 = NEON_BLUE
        flash.BackgroundTransparency = 0.5
        flash.BorderSizePixel = 0
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = flash
        flash.Parent = parent

        local t = TweenService:Create(flash, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
        t:Play()
        t.Completed:Connect(function() flash:Destroy() end)
    end

    function Window:CreateTab(name)
        local Tab = {}
        Window.TabCount = Window.TabCount + 1

        local Page = Instance.new("ScrollingFrame")
        Page.Name = name .. "Page"
        Page.Parent = Window.Pages
        Page.BackgroundTransparency = 1
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.ScrollBarThickness = 2
        Page.ScrollBarImageColor3 = NEON_BLUE
        Page.Visible = (Window.TabCount == 1)
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.BorderSizePixel = 0

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Parent = Page
        PageLayout.Padding = UDim.new(0, 8)
        table.insert(connections, PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y)
        end))

        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = name .. "Tab"
        TabBtn.Parent = Window.TabBar
        TabBtn.Size = UDim2.new(0, 100, 0, 32)
        
        local TabScale = Instance.new("UIScale", TabBtn)
        
        if Window.TabCount == 1 then
            TabBtn.BackgroundColor3 = NEON_BLUE
            TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            TabBtn.BackgroundColor3 = COMPONENT_BG
            TabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
        
        TabBtn.BorderSizePixel = 0
        TabBtn.Text = name
        TabBtn.Font = Enum.Font.GothamBold
        TabBtn.TextSize = 11

        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 6)
        TabCorner.Parent = TabBtn

        -- Hover Tabs
        table.insert(connections, TabBtn.MouseEnter:Connect(function()
            TweenService:Create(TabScale, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {Scale = 1.04}):Play()
        end))
        table.insert(connections, TabBtn.MouseLeave:Connect(function()
            TweenService:Create(TabScale, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {Scale = 1}):Play()
        end))

        table.insert(connections, TabBtn.MouseButton1Click:Connect(function()
            CreateFlash(TabBtn)
            TweenService:Create(TabScale, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), {Scale = 0.95}):Play()
            task.wait(0.1)
            TweenService:Create(TabScale, TweenInfo.new(0.2, Enum.EasingStyle.Bounce), {Scale = 1.04}):Play()

            for _, p in pairs(Window.Pages:GetChildren()) do p.Visible = false end
            for _, t in pairs(Window.TabBar:GetChildren()) do
                if t:IsA("TextButton") then 
                    TweenService:Create(t, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(150, 150, 150), BackgroundColor3 = COMPONENT_BG}):Play()
                end
            end
            Page.Visible = true
            TweenService:Create(TabBtn, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = NEON_BLUE}):Play()
        end))

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
            Label.TextColor3 = Color3.fromRGB(190, 190, 190)
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
            TextBtn.BackgroundColor3 = COMPONENT_BG
            TextBtn.Size = UDim2.new(1, 0, 1, 0)
            TextBtn.Text = "   " .. config.Name
            TextBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
            TextBtn.Font = Enum.Font.Gotham
            TextBtn.TextSize = 13
            TextBtn.TextXAlignment = Enum.TextXAlignment.Left
            TextBtn.BorderSizePixel = 0

            local BtnScale = Instance.new("UIScale", TextBtn)

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = TextBtn

            local StatusContainer = Instance.new("Frame")
            StatusContainer.Parent = TextBtn
            StatusContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            StatusContainer.Position = UDim2.new(1, -45, 0.5, -10)
            StatusContainer.Size = UDim2.new(0, 36, 0, 20)
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
            
            -- UIStroke pour le glow de l'activation
            local ToggleGlow = Instance.new("UIStroke", StatusContainer)
            ToggleGlow.Color = GLOW_BLUE
            ToggleGlow.Thickness = 2
            ToggleGlow.Transparency = 1

            local enabled = false

            -- Hover toggle background
            table.insert(connections, TextBtn.MouseEnter:Connect(function()
                TweenService:Create(TextBtn, TweenInfo.new(0.2), {BackgroundColor3 = HOVER_BG}):Play()
            end))
            table.insert(connections, TextBtn.MouseLeave:Connect(function()
                TweenService:Create(TextBtn, TweenInfo.new(0.2), {BackgroundColor3 = COMPONENT_BG}):Play()
            end))

            local function SetState(state)
                enabled = state
                if enabled then
                    -- Animation on: Cercle vers la droite, couleurs néon, et effet glow (explosion)
                    TweenService:Create(StatusCircle, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -18, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                    TweenService:Create(StatusContainer, TweenInfo.new(0.3), {BackgroundColor3 = NEON_BLUE}):Play()
                    
                    -- Petite explosion/glow
                    ToggleGlow.Transparency = 0
                    TweenService:Create(ToggleGlow, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()
                else
                    -- Animation off: Retour à gauche
                    TweenService:Create(StatusCircle, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = Color3.fromRGB(150, 150, 150)}):Play()
                    TweenService:Create(StatusContainer, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
                end
            end

            table.insert(connections, TextBtn.MouseButton1Down:Connect(function()
                TweenService:Create(BtnScale, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {Scale = 0.97}):Play()
            end))
            
            table.insert(connections, TextBtn.MouseButton1Click:Connect(function()
                TweenService:Create(BtnScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
                enabled = not enabled
                SetState(enabled)
                if config.Callback then config.Callback(enabled, SetState) end
            end))
            return SetState
        end

        function Tab:CreateBind(config)
            local BindFrame = Instance.new("Frame")
            BindFrame.Size = UDim2.new(1, 0, 0, 38)
            BindFrame.BackgroundTransparency = 1
            BindFrame.Parent = Page

            local Container = Instance.new("Frame")
            Container.Size = UDim2.new(1, 0, 1, 0)
            Container.BackgroundColor3 = COMPONENT_BG
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

            -- Hover Effect
            table.insert(connections, Container.MouseEnter:Connect(function()
                TweenService:Create(Container, TweenInfo.new(0.2), {BackgroundColor3 = HOVER_BG}):Play()
            end))
            table.insert(connections, Container.MouseLeave:Connect(function()
                TweenService:Create(Container, TweenInfo.new(0.2), {BackgroundColor3 = COMPONENT_BG}):Play()
            end))

            table.insert(connections, BindBtn.MouseButton1Click:Connect(function()
                BindBtn.Text = "..."
                TweenService:Create(BindBtn, TweenInfo.new(0.2), {BackgroundColor3 = NEON_BLUE}):Play()
                
                if config.BindTable then config.BindTable.IsBinding = true end
                local conn
                conn = UserInputService.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.Keyboard or i.UserInputType.Name:find("MouseButton") then
                        local key = (i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode or i.UserInputType)
                        if config.BindTable and config.KeyIndex then
                            config.BindTable[config.KeyIndex] = key
                        end
                        BindBtn.Text = tostring(key.Name or key)
                        TweenService:Create(BindBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
                        if config.BindTable then config.BindTable.IsBinding = false end
                        conn:Disconnect()
                    end
                end)
                table.insert(connections, conn)
            end))
        end

        function Tab:CreateButton(config)
            local TextBtn = Instance.new("TextButton")
            TextBtn.Parent = Page
            TextBtn.BackgroundColor3 = COMPONENT_BG
            TextBtn.Size = UDim2.new(1, 0, 0, 38)
            TextBtn.Text = config.Name
            TextBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            TextBtn.Font = Enum.Font.GothamBold
            TextBtn.TextSize = 13
            TextBtn.BorderSizePixel = 0

            local btnScale = Instance.new("UIScale", TextBtn)

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = TextBtn
            
            -- Hover Animation
            table.insert(connections, TextBtn.MouseEnter:Connect(function()
                TweenService:Create(TextBtn, TweenInfo.new(0.2), {BackgroundColor3 = HOVER_BG}):Play()
                TweenService:Create(btnScale, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {Scale = 1.01}):Play()
            end))
            table.insert(connections, TextBtn.MouseLeave:Connect(function()
                TweenService:Create(TextBtn, TweenInfo.new(0.2), {BackgroundColor3 = COMPONENT_BG}):Play()
                TweenService:Create(btnScale, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {Scale = 1}):Play()
            end))

            table.insert(connections, TextBtn.MouseButton1Down:Connect(function()
                TweenService:Create(btnScale, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {Scale = 0.96}):Play()
            end))

            table.insert(connections, TextBtn.MouseButton1Click:Connect(function()
                CreateFlash(TextBtn)
                TweenService:Create(btnScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.01}):Play()
                if config.Callback then config.Callback() end
            end))
        end

        function Tab:CreateSlider(config)
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Size = UDim2.new(1, 0, 0, 50)
            SliderFrame.BackgroundColor3 = COMPONENT_BG
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
            SliderFill.BackgroundColor3 = NEON_BLUE
            SliderFill.Size = UDim2.new(math.clamp((config.Default - config.Min) / (config.Max - config.Min), 0, 1), 0, 1, 0)
            SliderFill.BorderSizePixel = 0

            local sfCorner = Instance.new("UICorner")
            sfCorner.CornerRadius = UDim.new(1, 0)
            sfCorner.Parent = SliderFill
            
            -- Hover effect background
            table.insert(connections, SliderFrame.MouseEnter:Connect(function()
                TweenService:Create(SliderFrame, TweenInfo.new(0.2), {BackgroundColor3 = HOVER_BG}):Play()
            end))
            table.insert(connections, SliderFrame.MouseLeave:Connect(function()
                TweenService:Create(SliderFrame, TweenInfo.new(0.2), {BackgroundColor3 = COMPONENT_BG}):Play()
            end))

            local sliding = false
            local function update(input)
                local pos = math.clamp((input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
                -- Utilisation d'un tween pour la jauge
                TweenService:Create(SliderFill, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(pos, 0, 1, 0)}):Play()
                
                local val = math.floor(((config.Max - config.Min) * pos) + config.Min)
                Label.Text = "   " .. config.Name .. " : " .. val
                if config.Callback then config.Callback(val) end
            end

            table.insert(connections, SliderBack.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
                    sliding = true 
                    update(input) 
                end
            end))

            table.insert(connections, UserInputService.InputChanged:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then 
                    update(input) 
                end
            end))

            table.insert(connections, UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
                    sliding = false 
                end
            end))
        end
        
        function Tab:CreateTextBox(config)
            local TextBoxFrame = Instance.new("Frame")
            TextBoxFrame.Size = UDim2.new(1, 0, 0, 38)
            TextBoxFrame.BackgroundTransparency = 1
            TextBoxFrame.Parent = Page

            local Container = Instance.new("Frame")
            Container.Size = UDim2.new(1, 0, 1, 0)
            Container.BackgroundColor3 = COMPONENT_BG
            Container.Parent = TextBoxFrame

            local cCorner = Instance.new("UICorner")
            cCorner.CornerRadius = UDim.new(0, 6)
            cCorner.Parent = Container
            
            -- UIStroke pour effet focus
            local BoxStroke = Instance.new("UIStroke", Container)
            BoxStroke.Color = NEON_BLUE
            BoxStroke.Thickness = 1.5
            BoxStroke.Transparency = 1
            BoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

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

            table.insert(connections, TextBox.Focused:Connect(function()
                TweenService:Create(BoxStroke, TweenInfo.new(0.3), {Transparency = 0}):Play()
                TweenService:Create(Container, TweenInfo.new(0.3), {BackgroundColor3 = HOVER_BG}):Play()
            end))

            table.insert(connections, TextBox.FocusLost:Connect(function()
                TweenService:Create(BoxStroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
                TweenService:Create(Container, TweenInfo.new(0.3), {BackgroundColor3 = COMPONENT_BG}):Play()
                if config.Callback then
                    config.Callback(TextBox.Text)
                end
            end))
        end

        return Tab
    end

    return Window
end

return UI
