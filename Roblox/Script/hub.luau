local Library = {}
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local existingWindows = {}
local activeDropdown = nil

local function SafeCallback(func, ...)
    if type(func) ~= "function" then return end
    local success, err = pcall(func, ...)
    if not success then
        warn("Unleashed Hub UI Error: " .. tostring(err))
    end
end

local function Tween(instance, properties, duration, style, direction)
    style = style or Enum.EasingStyle.Sine
    direction = direction or Enum.EasingDirection.Out
    duration = duration or 0.2
    local tween = TweenService:Create(instance, TweenInfo.new(duration, style, direction), properties)
    tween:Play()
    return tween
end

local function ApplyHover(instance, colorNormal, colorHover)
    instance.MouseEnter:Connect(function()
        Tween(instance, {BackgroundColor3 = colorHover}, 0.15)
    end)
    instance.MouseLeave:Connect(function()
        Tween(instance, {BackgroundColor3 = colorNormal}, 0.15)
    end)
end

local function Ripple(obj)
    task.spawn(function()
        obj.ClipsDescendants = true
        local mousePos = UserInputService:GetMouseLocation() - obj.AbsolutePosition
        local circle = Instance.new("ImageLabel")
        circle.Name = "Ripple"
        circle.Parent = obj
        circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        circle.BackgroundTransparency = 1
        circle.ZIndex = obj.ZIndex + 5
        circle.Image = "rbxassetid://266543268"
        circle.ImageTransparency = 0.6
        circle.Size = UDim2.new(0, 0, 0, 0)
        circle.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y - 36)
        circle.AnchorPoint = Vector2.new(0.5, 0.5)
        
        local max = math.max(obj.AbsoluteSize.X, obj.AbsoluteSize.Y) * 1.5
        local t = TweenService:Create(circle, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, max, 0, max),
            ImageTransparency = 1
        })
        t:Play()
        t.Completed:Wait()
        circle:Destroy()
    end)
end

function Library:CreateWindow(cfg)
    if type(cfg) ~= "table" then cfg = {} end
    local title = type(cfg.Name) == "string" and cfg.Name or "UNLEASHED HUB"
    local accent = typeof(cfg.Accent) == "Color3" and cfg.Accent or Color3.fromRGB(255, 0, 75)

    if existingWindows[title] then
        existingWindows[title]:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = title
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false
    existingWindows[title] = ScreenGui

    local Blur = Instance.new("BlurEffect")
    Blur.Parent = Lighting
    Blur.Size = 0
    Tween(Blur, {Size = 15}, 0.5)

    ScreenGui.AncestryChanged:Connect(function()
        if not ScreenGui:IsDescendantOf(game) then
            local t = Tween(Blur, {Size = 0}, 0.3)
            t.Completed:Connect(function() Blur:Destroy() end)
        end
    end)

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Parent = ScreenGui
    Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, -275, 0.5, -175)
    Main.Size = UDim2.new(0, 550, 0, 350)
    Main.ClipsDescendants = false
    Main.GroupTransparency = 1
    
    local UIScale = Instance.new("UIScale")
    UIScale.Parent = Main
    UIScale.Scale = 0.9

    Tween(Main, {GroupTransparency = 0}, 0.4, Enum.EasingStyle.Quint)
    Tween(UIScale, {Scale = 1}, 0.4, Enum.EasingStyle.Quint)

    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.Parent = Main
    Shadow.BackgroundTransparency = 1
    Shadow.Position = UDim2.new(0, -15, 0, -15)
    Shadow.Size = UDim2.new(1, 30, 1, 30)
    Shadow.Image = "rbxassetid://1316045217"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = 0.4
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    Shadow.ZIndex = 0

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Parent = Main
    MainStroke.Color = Color3.fromRGB(40, 40, 40)
    MainStroke.Thickness = 1

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = Main

    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Parent = Main
    Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Sidebar.Size = UDim2.new(0, 140, 1, 0)
    Sidebar.ZIndex = 2
    
    local SidebarStroke = Instance.new("UIStroke")
    SidebarStroke.Parent = Sidebar
    SidebarStroke.Color = Color3.fromRGB(35, 35, 35)
    SidebarStroke.Thickness = 1

    local SideCorner = Instance.new("UICorner")
    SideCorner.CornerRadius = UDim.new(0, 8)
    SideCorner.Parent = Sidebar

    local Title = Instance.new("TextLabel")
    Title.Parent = Sidebar
    Title.Size = UDim2.new(1, 0, 0, 45)
    Title.BackgroundTransparency = 1
    Title.Text = title
    Title.TextColor3 = accent
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.ZIndex = 2

    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Parent = Sidebar
    TabContainer.Position = UDim2.new(0, 5, 0, 50)
    TabContainer.Size = UDim2.new(1, -10, 1, -60)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ScrollBarThickness = 0
    TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabContainer.ZIndex = 2
    
    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.Parent = TabContainer
    TabListLayout.Padding = UDim.new(0, 5)
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabContainer.CanvasSize = UDim2.new(0, 0, 0, TabListLayout.AbsoluteContentSize.Y)
    end)

    local PageContainer = Instance.new("Frame")
    PageContainer.Parent = Main
    PageContainer.Position = UDim2.new(0, 150, 0, 10)
    PageContainer.Size = UDim2.new(1, -160, 1, -20)
    PageContainer.BackgroundTransparency = 1
    PageContainer.ZIndex = 1

    local dragging, dragInput, dragStart, startPos
    local targetPos = Main.Position

    Main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            targetPos = startPos
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
            if dragging then
                local delta = input.Position - dragStart
                targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local dragConnection
    dragConnection = RunService.RenderStepped:Connect(function()
        if ScreenGui.Parent then
            Main.Position = Main.Position:Lerp(targetPos, 0.15)
        else
            dragConnection:Disconnect()
        end
    end)

    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if activeDropdown then
                local isInside = false
                local elements = ScreenGui:GetDescendants()
                for _, v in pairs(elements) do
                    if v == activeDropdown.Frame or v == activeDropdown.Button then
                        local pos = UserInputService:GetMouseLocation()
                        local absPos = v.AbsolutePosition
                        local absSize = v.AbsoluteSize
                        if pos.X >= absPos.X and pos.X <= absPos.X + absSize.X and pos.Y >= absPos.Y - 36 and pos.Y <= absPos.Y - 36 + absSize.Y then
                            isInside = true
                            break
                        end
                    end
                end
                if not isInside then
                    activeDropdown.Close()
                end
            end
        end
    end)

    local Tabs = {}
    local firstPage = true
    local existingTabs = {}
    local zIndexCounter = 100

    function Tabs:CreatePage(name)
        name = type(name) == "string" and name or "Tab"
        if existingTabs[name] then return existingTabs[name] end

        local Page = Instance.new("ScrollingFrame")
        Page.Name = name .. "Page"
        Page.Parent = PageContainer
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.Visible = firstPage
        Page.ScrollBarThickness = 2
        Page.ScrollBarImageColor3 = accent
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.BorderSizePixel = 0
        Page.ZIndex = 1
        
        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Parent = Page
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20)
        end)

        local TabBtn = Instance.new("TextButton")
        TabBtn.Parent = TabContainer
        TabBtn.Size = UDim2.new(1, 0, 0, 32)
        TabBtn.BackgroundColor3 = firstPage and Color3.fromRGB(30, 30, 30) or Color3.fromRGB(20, 20, 20)
        TabBtn.Text = "  " .. name
        TabBtn.TextColor3 = firstPage and accent or Color3.fromRGB(200, 200, 200)
        TabBtn.Font = Enum.Font.GothamSemibold
        TabBtn.TextSize = 12
        TabBtn.TextXAlignment = Enum.TextXAlignment.Left
        TabBtn.AutoButtonColor = false
        TabBtn.ZIndex = 2
        
        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 6)
        BtnCorner.Parent = TabBtn

        local ActiveIndicator = Instance.new("Frame")
        ActiveIndicator.Parent = TabBtn
        ActiveIndicator.BackgroundColor3 = accent
        ActiveIndicator.Size = UDim2.new(0, 3, 0, 16)
        ActiveIndicator.Position = UDim2.new(0, 4, 0.5, -8)
        ActiveIndicator.BackgroundTransparency = firstPage and 0 or 1
        ActiveIndicator.ZIndex = 2
        
        local IndCorner = Instance.new("UICorner")
        IndCorner.CornerRadius = UDim.new(1, 0)
        IndCorner.Parent = ActiveIndicator

        if not firstPage then ApplyHover(TabBtn, Color3.fromRGB(20, 20, 20), Color3.fromRGB(25, 25, 25)) end

        TabBtn.MouseButton1Click:Connect(function()
            Ripple(TabBtn)
            for _, p in pairs(PageContainer:GetChildren()) do 
                if p:IsA("ScrollingFrame") then p.Visible = false end 
            end
            for _, t in pairs(TabContainer:GetChildren()) do 
                if t:IsA("TextButton") then 
                    Tween(t, {BackgroundColor3 = Color3.fromRGB(20, 20, 20)}, 0.2)
                    Tween(t, {TextColor3 = Color3.fromRGB(200, 200, 200)}, 0.2)
                    local ind = t:FindFirstChild("Frame")
                    if ind then Tween(ind, {BackgroundTransparency = 1}, 0.2) end
                    ApplyHover(t, Color3.fromRGB(20, 20, 20), Color3.fromRGB(25, 25, 25))
                end 
            end
            Page.Visible = true
            Tween(TabBtn, {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}, 0.2)
            Tween(TabBtn, {TextColor3 = accent}, 0.2)
            Tween(ActiveIndicator, {BackgroundTransparency = 0}, 0.2)
        end)

        firstPage = false
        local Elements = {}
        existingTabs[name] = Elements

        local existingElements = {}

        function Elements:AddButton(text, callback)
            text = type(text) == "string" and text or "Button"
            if existingElements[text] then return end
            existingElements[text] = true

            local debounce = false

            local Btn = Instance.new("TextButton")
            Btn.Parent = Page
            Btn.Size = UDim2.new(1, -5, 0, 35)
            Btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            Btn.Text = "  " .. text
            Btn.TextColor3 = Color3.fromRGB(220, 220, 220)
            Btn.TextXAlignment = Enum.TextXAlignment.Left
            Btn.Font = Enum.Font.Gotham
            Btn.TextSize = 13
            Btn.AutoButtonColor = false
            Btn.ZIndex = 2
            
            local c = Instance.new("UICorner") 
            c.CornerRadius = UDim.new(0, 6) 
            c.Parent = Btn
            
            local Stroke = Instance.new("UIStroke")
            Stroke.Parent = Btn
            Stroke.Color = Color3.fromRGB(40, 40, 40)
            Stroke.Thickness = 1

            ApplyHover(Btn, Color3.fromRGB(25, 25, 25), Color3.fromRGB(32, 32, 32))

            local Icon = Instance.new("ImageLabel")
            Icon.Parent = Btn
            Icon.Size = UDim2.new(0, 16, 0, 16)
            Icon.Position = UDim2.new(1, -25, 0.5, -8)
            Icon.BackgroundTransparency = 1
            Icon.Image = "rbxassetid://6026663779"
            Icon.ImageColor3 = Color3.fromRGB(200, 200, 200)
            Icon.ZIndex = 2

            Btn.MouseButton1Click:Connect(function()
                if debounce then return end
                debounce = true
                Ripple(Btn)
                Tween(Icon, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(1, -23, 0.5, -6)}, 0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
                task.wait(0.1)
                Tween(Icon, {Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -25, 0.5, -8)}, 0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
                SafeCallback(callback)
                task.wait(0.2)
                debounce = false
            end)
        end

        function Elements:AddToggle(text, callback)
            text = type(text) == "string" and text or "Toggle"
            if existingElements[text] then return end
            existingElements[text] = true

            local debounce = false

            local Tgl = Instance.new("TextButton")
            Tgl.Parent = Page
            Tgl.Size = UDim2.new(1, -5, 0, 35)
            Tgl.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            Tgl.Text = "  " .. text
            Tgl.TextColor3 = Color3.fromRGB(220, 220, 220)
            Tgl.TextXAlignment = Enum.TextXAlignment.Left
            Tgl.Font = Enum.Font.Gotham
            Tgl.TextSize = 13
            Tgl.AutoButtonColor = false
            Tgl.ZIndex = 2
            
            local c = Instance.new("UICorner") 
            c.CornerRadius = UDim.new(0, 6) 
            c.Parent = Tgl

            local Stroke = Instance.new("UIStroke")
            Stroke.Parent = Tgl
            Stroke.Color = Color3.fromRGB(40, 40, 40)
            Stroke.Thickness = 1

            ApplyHover(Tgl, Color3.fromRGB(25, 25, 25), Color3.fromRGB(32, 32, 32))
            
            local Box = Instance.new("Frame")
            Box.Position = UDim2.new(1, -40, 0.5, -9)
            Box.Size = UDim2.new(0, 32, 0, 18)
            Box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            Box.Parent = Tgl
            Box.ZIndex = 2
            local bc = Instance.new("UICorner") 
            bc.CornerRadius = UDim.new(1, 0) 
            bc.Parent = Box

            local Circle = Instance.new("Frame")
            Circle.Parent = Box
            Circle.Size = UDim2.new(0, 14, 0, 14)
            Circle.Position = UDim2.new(0, 2, 0.5, -7)
            Circle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
            Circle.ZIndex = 2
            local cc = Instance.new("UICorner")
            cc.CornerRadius = UDim.new(1, 0)
            cc.Parent = Circle
            
            local enabled = false
            Tgl.MouseButton1Click:Connect(function()
                if debounce then return end
                debounce = true
                enabled = not enabled
                Ripple(Tgl)
                
                if enabled then
                    Tween(Box, {BackgroundColor3 = accent}, 0.2)
                    Tween(Circle, {Position = UDim2.new(1, -16, 0.5, -7), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
                else
                    Tween(Box, {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}, 0.2)
                    Tween(Circle, {Position = UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = Color3.fromRGB(200, 200, 200)}, 0.2)
                end
                
                SafeCallback(callback, enabled)
                task.wait(0.2)
                debounce = false
            end)
        end

        function Elements:AddSlider(text, min, max, default, callback)
            text = type(text) == "string" and text or "Slider"
            min = type(min) == "number" and min or 0
            max = type(max) == "number" and max or 100
            default = type(default) == "number" and default or min
            default = math.clamp(default, min, max)
            if existingElements[text] then return end
            existingElements[text] = true

            local SldFrame = Instance.new("Frame")
            SldFrame.Parent = Page
            SldFrame.Size = UDim2.new(1, -5, 0, 50)
            SldFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            SldFrame.ZIndex = 2
            local c = Instance.new("UICorner") 
            c.CornerRadius = UDim.new(0, 6) 
            c.Parent = SldFrame
            
            local Stroke = Instance.new("UIStroke")
            Stroke.Parent = SldFrame
            Stroke.Color = Color3.fromRGB(40, 40, 40)
            Stroke.Thickness = 1

            local Label = Instance.new("TextLabel")
            Label.Parent = SldFrame
            Label.Position = UDim2.new(0, 10, 0, 5)
            Label.Size = UDim2.new(0, 200, 0, 20)
            Label.Text = text
            Label.TextColor3 = Color3.fromRGB(220, 220, 220)
            Label.BackgroundTransparency = 1
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.ZIndex = 2

            local ValFrame = Instance.new("Frame")
            ValFrame.Parent = SldFrame
            ValFrame.Position = UDim2.new(1, -40, 0, 5)
            ValFrame.Size = UDim2.new(0, 30, 0, 20)
            ValFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            ValFrame.ZIndex = 2
            local vc = Instance.new("UICorner")
            vc.CornerRadius = UDim.new(0, 4)
            vc.Parent = ValFrame

            local ValLabel = Instance.new("TextLabel")
            ValLabel.Parent = ValFrame
            ValLabel.Size = UDim2.new(1, 0, 1, 0)
            ValLabel.Text = tostring(default)
            ValLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            ValLabel.BackgroundTransparency = 1
            ValLabel.Font = Enum.Font.GothamBold
            ValLabel.TextSize = 11
            ValLabel.ZIndex = 2

            local Bar = Instance.new("Frame")
            Bar.Position = UDim2.new(0, 10, 0, 32)
            Bar.Size = UDim2.new(1, -20, 0, 6)
            Bar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            Bar.Parent = SldFrame
            Bar.ZIndex = 2
            local bc = Instance.new("UICorner")
            bc.CornerRadius = UDim.new(1, 0)
            bc.Parent = Bar
            
            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new(math.clamp((default - min) / (max - min), 0, 1), 0, 1, 0)
            Fill.BackgroundColor3 = accent
            Fill.Parent = Bar
            Fill.ZIndex = 2
            local fc = Instance.new("UICorner") 
            fc.CornerRadius = UDim.new(1, 0) 
            fc.Parent = Fill
            
            local Knob = Instance.new("Frame")
            Knob.Parent = Fill
            Knob.Size = UDim2.new(0, 12, 0, 12)
            Knob.Position = UDim2.new(1, -6, 0.5, -6)
            Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Knob.ZIndex = 3
            local kc = Instance.new("UICorner")
            kc.CornerRadius = UDim.new(1, 0)
            kc.Parent = Knob
            
            local KnobStroke = Instance.new("UIStroke")
            KnobStroke.Parent = Knob
            KnobStroke.Color = Color3.fromRGB(20, 20, 20)
            KnobStroke.Thickness = 1

            local sliding = false
            local function move(input)
                local pos = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                Tween(Fill, {Size = UDim2.new(pos, 0, 1, 0)}, 0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                local val = math.floor(((max - min) * pos) + min)
                ValLabel.Text = tostring(val)
                SafeCallback(callback, val)
            end
            
            SldFrame.InputBegan:Connect(function(i) 
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then 
                    sliding = true 
                    Tween(Knob, {Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -8, 0.5, -8)}, 0.1)
                    move(i) 
                end 
            end)
            UserInputService.InputChanged:Connect(function(i) 
                if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then 
                    move(i) 
                end 
            end)
            UserInputService.InputEnded:Connect(function(i) 
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then 
                    sliding = false 
                    Tween(Knob, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(1, -6, 0.5, -6)}, 0.1)
                end 
            end)
        end

        function Elements:AddBind(text, default, callback)
            text = type(text) == "string" and text or "Keybind"
            if existingElements[text] then return end
            existingElements[text] = true

            local currentBind = typeof(default) == "EnumItem" and default or nil
            local binding = false

            local BindBtn = Instance.new("TextButton")
            BindBtn.Parent = Page
            BindBtn.Size = UDim2.new(1, -5, 0, 35)
            BindBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            BindBtn.Text = "  " .. text
            BindBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
            BindBtn.TextXAlignment = Enum.TextXAlignment.Left
            BindBtn.Font = Enum.Font.Gotham
            BindBtn.TextSize = 13
            BindBtn.AutoButtonColor = false
            BindBtn.ZIndex = 2
            
            local c = Instance.new("UICorner") 
            c.CornerRadius = UDim.new(0, 6) 
            c.Parent = BindBtn

            local Stroke = Instance.new("UIStroke")
            Stroke.Parent = BindBtn
            Stroke.Color = Color3.fromRGB(40, 40, 40)
            Stroke.Thickness = 1

            ApplyHover(BindBtn, Color3.fromRGB(25, 25, 25), Color3.fromRGB(32, 32, 32))

            local BindLabel = Instance.new("TextLabel")
            BindLabel.Parent = BindBtn
            BindLabel.Size = UDim2.new(0, 80, 0, 22)
            BindLabel.Position = UDim2.new(1, -90, 0.5, -11)
            BindLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            BindLabel.Text = currentBind and currentBind.Name or "None"
            BindLabel.TextColor3 = accent
            BindLabel.Font = Enum.Font.GothamBold
            BindLabel.TextSize = 11
            BindLabel.ZIndex = 2
            local lc = Instance.new("UICorner") 
            lc.CornerRadius = UDim.new(0, 4) 
            lc.Parent = BindLabel

            BindBtn.MouseButton1Click:Connect(function()
                Ripple(BindBtn)
                binding = true
                BindLabel.Text = "..."
                Tween(BindLabel, {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}, 0.2)
            end)

            UserInputService.InputBegan:Connect(function(input)
                if binding then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode ~= Enum.KeyCode.Unknown then
                            currentBind = input.KeyCode
                            BindLabel.Text = currentBind.Name
                            binding = false
                            Tween(BindLabel, {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}, 0.2)
                        end
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                        binding = false
                        BindLabel.Text = currentBind and currentBind.Name or "None"
                        Tween(BindLabel, {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}, 0.2)
                    end
                else
                    if currentBind and input.KeyCode == currentBind then
                        SafeCallback(callback)
                    end
                end
            end)
        end

        function Elements:AddDropdown(text, list, callback)
            text = type(text) == "string" and text or "Dropdown"
            list = type(list) == "table" and list or {}
            if existingElements[text] then return end
            existingElements[text] = true

            zIndexCounter = zIndexCounter - 1
            local localZIndex = zIndexCounter

            local DropContainer = Instance.new("Frame")
            DropContainer.Parent = Page
            DropContainer.Size = UDim2.new(1, -5, 0, 35)
            DropContainer.BackgroundTransparency = 1
            DropContainer.ClipsDescendants = false
            DropContainer.ZIndex = localZIndex

            local Drop = Instance.new("TextButton")
            Drop.Parent = DropContainer
            Drop.Size = UDim2.new(1, 0, 0, 35)
            Drop.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            Drop.Text = "  " .. text .. " : " .. tostring(list[1] or "None")
            Drop.TextColor3 = Color3.fromRGB(220, 220, 220)
            Drop.TextXAlignment = Enum.TextXAlignment.Left
            Drop.Font = Enum.Font.Gotham
            Drop.TextSize = 13
            Drop.AutoButtonColor = false
            Drop.ZIndex = localZIndex
            
            local c = Instance.new("UICorner") 
            c.CornerRadius = UDim.new(0, 6) 
            c.Parent = Drop
            
            local Stroke = Instance.new("UIStroke")
            Stroke.Parent = Drop
            Stroke.Color = Color3.fromRGB(40, 40, 40)
            Stroke.Thickness = 1

            ApplyHover(Drop, Color3.fromRGB(25, 25, 25), Color3.fromRGB(32, 32, 32))

            local Icon = Instance.new("ImageLabel")
            Icon.Parent = Drop
            Icon.Size = UDim2.new(0, 16, 0, 16)
            Icon.Position = UDim2.new(1, -25, 0.5, -8)
            Icon.BackgroundTransparency = 1
            Icon.Image = "rbxassetid://6026668813"
            Icon.ImageColor3 = Color3.fromRGB(200, 200, 200)
            Icon.ZIndex = localZIndex

            local open = false
            local DropFrame = Instance.new("ScrollingFrame")
            DropFrame.Parent = DropContainer
            DropFrame.Position = UDim2.new(0, 0, 0, 40)
            DropFrame.Size = UDim2.new(1, 0, 0, 0)
            DropFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            DropFrame.ClipsDescendants = true
            DropFrame.Visible = false
            DropFrame.ZIndex = localZIndex + 10
            DropFrame.BorderSizePixel = 0
            DropFrame.ScrollBarThickness = 2
            DropFrame.ScrollBarImageColor3 = accent
            
            local dc = Instance.new("UICorner") 
            dc.CornerRadius = UDim.new(0, 6) 
            dc.Parent = DropFrame
            
            local dStroke = Instance.new("UIStroke")
            dStroke.Parent = DropFrame
            dStroke.Color = accent
            dStroke.Thickness = 1
            dStroke.Transparency = 1
            
            local dlist = Instance.new("UIListLayout") 
            dlist.Parent = DropFrame
            dlist.SortOrder = Enum.SortOrder.LayoutOrder
            
            local function closeDrop()
                open = false
                Tween(Icon, {Rotation = 0}, 0.2)
                Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                Tween(DropContainer, {Size = UDim2.new(1, -5, 0, 35)}, 0.2)
                Tween(dStroke, {Transparency = 1}, 0.2)
                task.delay(0.2, function()
                    if not open then DropFrame.Visible = false end
                end)
                if activeDropdown and activeDropdown.Button == Drop then
                    activeDropdown = nil
                end
            end

            local function openDrop()
                if activeDropdown and activeDropdown.Button ~= Drop then
                    activeDropdown.Close()
                end
                open = true
                DropFrame.Visible = true
                local targetHeight = math.min(#list * 30, 120)
                Tween(Icon, {Rotation = 180}, 0.2)
                Tween(DropFrame, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.2)
                Tween(DropContainer, {Size = UDim2.new(1, -5, 0, 35 + targetHeight + 5)}, 0.2)
                Tween(dStroke, {Transparency = 0}, 0.2)
                
                activeDropdown = {Button = Drop, Frame = DropFrame, Close = closeDrop}
            end

            Drop.MouseButton1Click:Connect(function()
                Ripple(Drop)
                if open then closeDrop() else openDrop() end
            end)

            for _, item in ipairs(list) do
                local strItem = tostring(item)
                local ItemBtn = Instance.new("TextButton")
                ItemBtn.Parent = DropFrame
                ItemBtn.Size = UDim2.new(1, 0, 0, 30)
                ItemBtn.BackgroundTransparency = 1
                ItemBtn.Text = "  " .. strItem
                ItemBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
                ItemBtn.TextXAlignment = Enum.TextXAlignment.Left
                ItemBtn.Font = Enum.Font.Gotham
                ItemBtn.TextSize = 12
                ItemBtn.ZIndex = localZIndex + 11
                ItemBtn.AutoButtonColor = false
                
                ApplyHover(ItemBtn, Color3.fromRGB(20, 20, 20), Color3.fromRGB(30, 30, 30))

                ItemBtn.MouseButton1Click:Connect(function()
                    Drop.Text = "  " .. text .. " : " .. strItem
                    for _, v in pairs(DropFrame:GetChildren()) do
                        if v:IsA("TextButton") then
                            v.TextColor3 = Color3.fromRGB(150, 150, 150)
                        end
                    end
                    Tween(ItemBtn, {TextColor3 = accent}, 0.1)
                    closeDrop()
                    SafeCallback(callback, item)
                end)
            end
            DropFrame.CanvasSize = UDim2.new(0, 0, 0, #list * 30)
        end

        return Elements
    end
    return Tabs
end

return Library
