local Library = {
    Registry = {},
    Flags = {},
    Connections = {},
    ActiveDropdown = nil,
    ConfigName = "Unleashed_Config"
}

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local existingWindows = {}

-- [SÉCURITÉ & UTILITAIRES]
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

-- [CONFIG SYSTEM]
function Library:SaveConfig()
    if not isfolder("UnleashedHub") then makefolder("UnleashedHub") end
    local data = {}
    for i, v in pairs(self.Flags) do
        data[i] = v
    end
    writefile("UnleashedHub/" .. self.ConfigName .. ".json", HttpService:JSONEncode(data))
end

function Library:LoadConfig()
    local path = "UnleashedHub/" .. self.ConfigName .. ".json"
    if isfile(path) then
        local data = HttpService:JSONDecode(readfile(path))
        for i, v in pairs(data) do
            if self.Registry[i] then
                self.Registry[i]:Set(v)
            end
        end
    end
end

-- [MAIN WINDOW]
function Library:CreateWindow(cfg)
    if type(cfg) ~= "table" then cfg = {} end
    local title = type(cfg.Name) == "string" and cfg.Name or "UNLEASHED HUB"
    local accent = typeof(cfg.Accent) == "Color3" and cfg.Accent or Color3.fromRGB(255, 0, 75)
    self.ConfigName = cfg.ConfigName or title

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

    -- [CORRECTION ERREUR GROUPTRANSPARENCY]
    -- Main doit être un CanvasGroup pour supporter GroupTransparency
    local Main = Instance.new("CanvasGroup")
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

    -- [DRAGGING SYSTEM]
    local dragging, dragInput, dragStart, startPos
    local targetPos = Main.Position

    Main.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not Library.ActiveDropdown then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
        end
    end)
    
    table.insert(Library.Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
    
    table.insert(Library.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    table.insert(Library.Connections, RunService.RenderStepped:Connect(function()
        if ScreenGui.Parent then
            Main.Position = Main.Position:Lerp(targetPos, 0.15)
        end
    end))

    -- [UI MANAGER / DROPDOWN CLOSER]
    table.insert(Library.Connections, UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and Library.ActiveDropdown then
            local pos = UserInputService:GetMouseLocation()
            local absPos = Library.ActiveDropdown.Frame.AbsolutePosition
            local absSize = Library.ActiveDropdown.Frame.AbsoluteSize
            
            if not (pos.X >= absPos.X and pos.X <= absPos.X + absSize.X and pos.Y >= absPos.Y - 36 and pos.Y <= absPos.Y - 36 + absSize.Y) then
                Library.ActiveDropdown.Close()
            end
        end
    end))

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
                end 
            end
            Page.Visible = true
            Tween(TabBtn, {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}, 0.2)
            Tween(TabBtn, {TextColor3 = accent}, 0.2)
            Tween(ActiveIndicator, {BackgroundTransparency = 0}, 0.2)
        end)

        firstPage = false
        local Elements = {}

        -- [COMPONENTS]
        function Elements:AddButton(text, callback)
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
            
            local Stroke = Instance.new("UIStroke")
            Stroke.Parent = Btn
            Stroke.Color = Color3.fromRGB(40, 40, 40)
            
            Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
            ApplyHover(Btn, Color3.fromRGB(25, 25, 25), Color3.fromRGB(32, 32, 32))

            Btn.MouseButton1Click:Connect(function()
                Ripple(Btn)
                SafeCallback(callback)
            end)
        end

        function Elements:AddToggle(text, cfg, callback)
            local toggleCfg = type(cfg) == "table" and cfg or {Default = false}
            local flag = toggleCfg.Flag or text
            local enabled = toggleCfg.Default or false
            
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
            
            Instance.new("UICorner", Tgl).CornerRadius = UDim.new(0, 6)
            local Stroke = Instance.new("UIStroke", Tgl)
            Stroke.Color = Color3.fromRGB(40, 40, 40)

            local Box = Instance.new("Frame")
            Box.Position = UDim2.new(1, -40, 0.5, -9)
            Box.Size = UDim2.new(0, 32, 0, 18)
            Box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            Box.Parent = Tgl
            Instance.new("UICorner", Box).CornerRadius = UDim.new(1, 0)

            local Circle = Instance.new("Frame")
            Circle.Parent = Box
            Circle.Size = UDim2.new(0, 14, 0, 14)
            Circle.Position = UDim2.new(0, 2, 0.5, -7)
            Circle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
            Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)
            
            local function Update()
                Library.Flags[flag] = enabled
                if enabled then
                    Tween(Box, {BackgroundColor3 = accent}, 0.2)
                    Tween(Circle, {Position = UDim2.new(1, -16, 0.5, -7), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
                else
                    Tween(Box, {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}, 0.2)
                    Tween(Circle, {Position = UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = Color3.fromRGB(200, 200, 200)}, 0.2)
                end
                SafeCallback(callback, enabled)
            end

            Tgl.MouseButton1Click:Connect(function()
                enabled = not enabled
                Ripple(Tgl)
                Update()
            end)

            local state = {
                Set = function(_, v) enabled = v Update() end,
                Get = function() return enabled end
            }
            Library.Registry[flag] = state
            Update()
            return state
        end

        function Elements:AddSlider(text, cfg, callback)
            local sCfg = type(cfg) == "table" and cfg or {Min = 0, Max = 100, Default = 50}
            local min, max, default = sCfg.Min, sCfg.Max, sCfg.Default
            local flag = sCfg.Flag or text

            local SldFrame = Instance.new("Frame")
            SldFrame.Parent = Page
            SldFrame.Size = UDim2.new(1, -5, 0, 50)
            SldFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            Instance.new("UICorner", SldFrame).CornerRadius = UDim.new(0, 6)
            Instance.new("UIStroke", SldFrame).Color = Color3.fromRGB(40, 40, 40)

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

            local ValLabel = Instance.new("TextLabel")
            ValLabel.Parent = SldFrame
            ValLabel.Position = UDim2.new(1, -40, 0, 5)
            ValLabel.Size = UDim2.new(0, 30, 0, 20)
            ValLabel.Text = tostring(default)
            ValLabel.TextColor3 = accent
            ValLabel.BackgroundTransparency = 1
            ValLabel.Font = Enum.Font.GothamBold
            ValLabel.TextSize = 12

            local Bar = Instance.new("Frame")
            Bar.Position = UDim2.new(0, 10, 0, 32)
            Bar.Size = UDim2.new(1, -20, 0, 6)
            Bar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            Bar.Parent = SldFrame
            Instance.new("UICorner", Bar).CornerRadius = UDim.new(1, 0)
            
            local Fill = Instance.new("Frame")
            Fill.BackgroundColor3 = accent
            Fill.Parent = Bar
            Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

            local function Update(val)
                val = math.clamp(val, min, max)
                local percent = (val - min) / (max - min)
                Fill.Size = UDim2.new(percent, 0, 1, 0)
                ValLabel.Text = tostring(val)
                Library.Flags[flag] = val
                SafeCallback(callback, val)
            end

            local sliding = false
            SldFrame.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    sliding = true
                    local pos = math.clamp((i.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                    Update(math.floor(((max - min) * pos) + min))
                end
            end)

            UserInputService.InputChanged:Connect(function(i)
                if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
                    local pos = math.clamp((i.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                    Update(math.floor(((max - min) * pos) + min))
                end
            end)

            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
            end)

            local state = {
                Set = function(_, v) Update(v) end,
                Get = function() return Library.Flags[flag] end
            }
            Library.Registry[flag] = state
            Update(default)
            return state
        end

        function Elements:AddDropdown(text, cfg, callback)
            local dCfg = type(cfg) == "table" and cfg or {List = {}, Default = ""}
            local list = dCfg.List
            local flag = dCfg.Flag or text

            local DropContainer = Instance.new("Frame")
            DropContainer.Parent = Page
            DropContainer.Size = UDim2.new(1, -5, 0, 35)
            DropContainer.BackgroundTransparency = 1
            DropContainer.ZIndex = zIndexCounter
            zIndexCounter = zIndexCounter - 1

            local Drop = Instance.new("TextButton")
            Drop.Parent = DropContainer
            Drop.Size = UDim2.new(1, 0, 0, 35)
            Drop.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            Drop.Text = "  " .. text .. " : " .. (dCfg.Default or "None")
            Drop.TextColor3 = Color3.fromRGB(220, 220, 220)
            Drop.TextXAlignment = Enum.TextXAlignment.Left
            Drop.Font = Enum.Font.Gotham
            Drop.TextSize = 13
            Drop.AutoButtonColor = false
            
            Instance.new("UICorner", Drop).CornerRadius = UDim.new(0, 6)
            Instance.new("UIStroke", Drop).Color = Color3.fromRGB(40, 40, 40)

            local DropFrame = Instance.new("ScrollingFrame")
            DropFrame.Parent = DropContainer
            DropFrame.Position = UDim2.new(0, 0, 0, 40)
            DropFrame.Size = UDim2.new(1, 0, 0, 0)
            DropFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            DropFrame.Visible = false
            DropFrame.BorderSizePixel = 0
            DropFrame.ScrollBarThickness = 2
            
            local dLayout = Instance.new("UIListLayout", DropFrame)

            local open = false
            local function Toggle(state)
                open = (state ~= nil) and state or not open
                if open then
                    if Library.ActiveDropdown and Library.ActiveDropdown ~= DropContainer then
                        Library.ActiveDropdown.Close()
                    end
                    DropFrame.Visible = true
                    Tween(DropFrame, {Size = UDim2.new(1, 0, 0, math.min(#list * 30, 120))}, 0.2)
                    Tween(DropContainer, {Size = UDim2.new(1, -5, 0, 35 + math.min(#list * 30, 120) + 5)}, 0.2)
                    Library.ActiveDropdown = {Frame = DropFrame, Close = function() Toggle(false) end}
                else
                    Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                    Tween(DropContainer, {Size = UDim2.new(1, -5, 0, 35)}, 0.2)
                    task.delay(0.2, function() DropFrame.Visible = false end)
                    Library.ActiveDropdown = nil
                end
            end

            Drop.MouseButton1Click:Connect(function() Ripple(Drop) Toggle() end)

            local function Populate()
                for _, v in pairs(DropFrame:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
                for _, item in pairs(list) do
                    local ItemBtn = Instance.new("TextButton")
                    ItemBtn.Parent = DropFrame
                    ItemBtn.Size = UDim2.new(1, 0, 0, 30)
                    ItemBtn.BackgroundTransparency = 1
                    ItemBtn.Text = "  " .. tostring(item)
                    ItemBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
                    ItemBtn.TextXAlignment = Enum.TextXAlignment.Left
                    ItemBtn.Font = Enum.Font.Gotham
                    ItemBtn.TextSize = 12
                    
                    ItemBtn.MouseButton1Click:Connect(function()
                        Drop.Text = "  " .. text .. " : " .. tostring(item)
                        Library.Flags[flag] = item
                        SafeCallback(callback, item)
                        Toggle(false)
                    end)
                end
                DropFrame.CanvasSize = UDim2.new(0, 0, 0, #list * 30)
            end

            Populate()
            
            local state = {
                Refresh = function(_, newList) list = newList Populate() end,
                Set = function(_, v) Drop.Text = "  " .. text .. " : " .. tostring(v) Library.Flags[flag] = v SafeCallback(callback, v) end
            }
            Library.Registry[flag] = state
            return state
        end

        return Elements
    end

    function Library:Destroy()
        for _, conn in pairs(self.Connections) do conn:Disconnect() end
        if ScreenGui then ScreenGui:Destroy() end
        if Blur then Blur:Destroy() end
        existingWindows[title] = nil
    end

    return Tabs
end

return Library
