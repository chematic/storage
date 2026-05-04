local Library = {}
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local function Ripple(obj)
    task.spawn(function()
        local mousePos = UserInputService:GetMouseLocation() - obj.AbsolutePosition
        local circle = Instance.new("ImageLabel")
        circle.Name = "Ripple"
        circle.Parent = obj
        circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        circle.BackgroundTransparency = 0.8
        circle.ZIndex = 10
        circle.Image = "rbxassetid://266543268"
        circle.ImageTransparency = 0.9
        circle.Size = UDim2.new(0, 0, 0, 0)
        circle.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
        
        local tween = TweenService:Create(circle, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 200, 0, 200),
            Position = UDim2.new(0, mousePos.X - 100, 0, mousePos.Y - 100),
            ImageTransparency = 1
        })
        tween:Play()
        tween.Completed:Wait()
        circle:Destroy()
    end)
end

function Library:CreateWindow(cfg)
    local title = cfg.Name or "UNLEASHED HUB"
    local accent = cfg.Accent or Color3.fromRGB(255, 0, 75)
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "UnleashedUI"
    ScreenGui.Parent = game:GetService("CoreGui")
    ScreenGui.ResetOnSpawn = false

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Parent = ScreenGui
    Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, -275, 0.5, -175)
    Main.Size = UDim2.new(0, 550, 0, 350)
    Main.ClipsDescendants = true
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = Main

    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Parent = Main
    Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Sidebar.Size = UDim2.new(0, 140, 1, 0)
    
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

    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Parent = Sidebar
    TabContainer.Position = UDim2.new(0, 5, 0, 50)
    TabContainer.Size = UDim2.new(1, -10, 1, -60)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ScrollBarThickness = 0
    
    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.Parent = TabContainer
    TabListLayout.Padding = UDim.new(0, 5)

    local PageContainer = Instance.new("Frame")
    PageContainer.Parent = Main
    PageContainer.Position = UDim2.new(0, 150, 0, 10)
    PageContainer.Size = UDim2.new(1, -160, 1, -20)
    PageContainer.BackgroundTransparency = 1

    -- Dragging Logic
    local dragging, dragInput, dragStart, startPos
    Main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    local Tabs = {}
    local firstPage = true

    function Tabs:CreatePage(name)
        local Page = Instance.new("ScrollingFrame")
        Page.Name = name .. "Page"
        Page.Parent = PageContainer
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.Visible = firstPage
        Page.ScrollBarThickness = 2
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        
        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Parent = Page
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y)
        end)

        local TabBtn = Instance.new("TextButton")
        TabBtn.Parent = TabContainer
        TabBtn.Size = UDim2.new(1, 0, 0, 32)
        TabBtn.BackgroundColor3 = firstPage and accent or Color3.fromRGB(30, 30, 30)
        TabBtn.Text = name
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabBtn.Font = Enum.Font.GothamSemibold
        TabBtn.TextSize = 12
        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 6)
        BtnCorner.Parent = TabBtn

        TabBtn.MouseButton1Click:Connect(function()
            for _, p in pairs(PageContainer:GetChildren()) do p.Visible = false end
            for _, t in pairs(TabContainer:GetChildren()) do 
                if t:IsA("TextButton") then t.BackgroundColor3 = Color3.fromRGB(30, 30, 30) end 
            end
            Page.Visible = true
            TabBtn.BackgroundColor3 = accent
            Ripple(TabBtn)
        end)

        firstPage = false
        local Elements = {}

        -- BUTTON
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
            local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = Btn
            Btn.MouseButton1Click:Connect(function()
                Ripple(Btn)
                callback()
            end)
        end

        -- TOGGLE
        function Elements:AddToggle(text, callback)
            local Tgl = Instance.new("TextButton")
            Tgl.Parent = Page
            Tgl.Size = UDim2.new(1, -5, 0, 35)
            Tgl.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            Tgl.Text = "  " .. text
            Tgl.TextColor3 = Color3.fromRGB(220, 220, 220)
            Tgl.TextXAlignment = Enum.TextXAlignment.Left
            Tgl.Font = Enum.Font.Gotham
            Tgl.TextSize = 13
            local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = Tgl
            
            local Box = Instance.new("Frame")
            Box.Position = UDim2.new(1, -30, 0.5, -9)
            Box.Size = UDim2.new(0, 18, 0, 18)
            Box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            Box.Parent = Tgl
            local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 4) bc.Parent = Box
            
            local enabled = false
            Tgl.MouseButton1Click:Connect(function()
                enabled = not enabled
                TweenService:Create(Box, TweenInfo.new(0.2), {BackgroundColor3 = enabled and accent or Color3.fromRGB(40, 40, 40)}):Play()
                callback(enabled)
            end)
        end

        -- SLIDER
        function Elements:AddSlider(text, min, max, default, callback)
            local SldFrame = Instance.new("Frame")
            SldFrame.Parent = Page
            SldFrame.Size = UDim2.new(1, -5, 0, 45)
            SldFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = SldFrame

            local Label = Instance.new("TextLabel")
            Label.Parent = SldFrame
            Label.Position = UDim2.new(0, 10, 0, 5)
            Label.Text = text
            Label.TextColor3 = Color3.fromRGB(200, 200, 200)
            Label.BackgroundTransparency = 1
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 12
            Label.TextXAlignment = Enum.TextXAlignment.Left

            local ValLabel = Instance.new("TextLabel")
            ValLabel.Parent = SldFrame
            ValLabel.Position = UDim2.new(1, -40, 0, 5)
            ValLabel.Text = tostring(default)
            ValLabel.TextColor3 = accent
            ValLabel.BackgroundTransparency = 1
            ValLabel.Font = Enum.Font.GothamBold
            ValLabel.TextSize = 12

            local Bar = Instance.new("Frame")
            Bar.Position = UDim2.new(0, 10, 0, 30)
            Bar.Size = UDim2.new(1, -20, 0, 4)
            Bar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            Bar.Parent = SldFrame
            
            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            Fill.BackgroundColor3 = accent
            Fill.Parent = Bar

            local sliding = false
            local function move(input)
                local pos = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                Fill.Size = UDim2.new(pos, 0, 1, 0)
                local val = math.floor(((max - min) * pos) + min)
                ValLabel.Text = tostring(val)
                callback(val)
            end
            SldFrame.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true move(i) end end)
            UserInputService.InputChanged:Connect(function(i) if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then move(i) end end)
            UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end end)
        end

        -- KEYBIND
        function Elements:AddBind(text, default, callback)
            local currentBind = default
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
            local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = BindBtn

            local BindLabel = Instance.new("TextLabel")
            BindLabel.Parent = BindBtn
            BindLabel.Size = UDim2.new(0, 80, 0, 20)
            BindLabel.Position = UDim2.new(1, -85, 0.5, -10)
            BindLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            BindLabel.Text = currentBind and currentBind.Name or "None"
            BindLabel.TextColor3 = accent
            BindLabel.Font = Enum.Font.GothamBold
            BindLabel.TextSize = 11
            local lc = Instance.new("UICorner") lc.CornerRadius = UDim.new(0, 4) lc.Parent = BindLabel

            BindBtn.MouseButton1Click:Connect(function()
                binding = true
                BindLabel.Text = "..."
            end)

            UserInputService.InputBegan:Connect(function(input)
                if binding then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        currentBind = input.KeyCode
                        BindLabel.Text = currentBind.Name
                        binding = false
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                        binding = false
                        BindLabel.Text = currentBind and currentBind.Name or "None"
                    end
                else
                    if input.KeyCode == currentBind then
                        callback()
                    end
                end
            end)
        end

        -- DROPDOWN
        function Elements:AddDropdown(text, list, callback)
            local Drop = Instance.new("TextButton")
            Drop.Parent = Page
            Drop.Size = UDim2.new(1, -5, 0, 35)
            Drop.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            Drop.Text = "  " .. text .. " : " .. (list[1] or "...")
            Drop.TextColor3 = Color3.fromRGB(220, 220, 220)
            Drop.TextXAlignment = Enum.TextXAlignment.Left
            Drop.Font = Enum.Font.Gotham
            Drop.TextSize = 12
            local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = Drop

            local open = false
            local DropFrame = Instance.new("Frame")
            DropFrame.Parent = Page
            DropFrame.Size = UDim2.new(1, -5, 0, 0)
            DropFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            DropFrame.ClipsDescendants = true
            DropFrame.Visible = false
            local dc = Instance.new("UICorner") dc.CornerRadius = UDim.new(0, 6) dc.Parent = DropFrame
            local dlist = Instance.new("UIListLayout") dlist.Parent = DropFrame

            Drop.MouseButton1Click:Connect(function()
                open = not open
                DropFrame.Visible = true
                local targetSize = open and UDim2.new(1, -5, 0, #list * 30) or UDim2.new(1, -5, 0, 0)
                local t = TweenService:Create(DropFrame, TweenInfo.new(0.3), {Size = targetSize})
                t:Play()
                if not open then t.Completed:Wait() if not open then DropFrame.Visible = false end end
            end)

            for _, item in pairs(list) do
                local ItemBtn = Instance.new("TextButton")
                ItemBtn.Parent = DropFrame
                ItemBtn.Size = UDim2.new(1, 0, 0, 30)
                ItemBtn.BackgroundTransparency = 1
                ItemBtn.Text = item
                ItemBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
                ItemBtn.Font = Enum.Font.Gotham
                ItemBtn.TextSize = 12
                ItemBtn.MouseButton1Click:Connect(function()
                    Drop.Text = "  " .. text .. " : " .. item
                    open = false
                    TweenService:Create(DropFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, -5, 0, 0)}):Play()
                    callback(item)
                end)
            end
        end

        return Elements
    end
    return Tabs
end

return Library
