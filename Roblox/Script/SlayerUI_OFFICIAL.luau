local v1 = game:GetService("UserInputService")
local v2 = game:GetService("TweenService")
local v3 = game:GetService("CoreGui")
local v4 = game:GetService("Players")

local v5 = v4.LocalPlayer

local v6 = Color3.fromRGB(0, 195, 255)
local v7 = Color3.fromRGB(100, 220, 255)
local v8 = Color3.fromRGB(15, 15, 15)
local v9 = Color3.fromRGB(25, 25, 25)
local v10 = Color3.fromRGB(35, 35, 35)

local UI = {}

function UI:CreateWindow()
    local v11 = {}
    local v12 = {}
    local v13 = v5.UserId .. "_SlayerHub"

    local v14 = v3:FindFirstChild(v13)
    if v14 then
        v14:Destroy()
    end

    local v15 = Instance.new("ScreenGui")
    v15.Name = v13
    v15.Parent = v3
    v15.ResetOnSpawn = false

    table.insert(v12, v15.Destroying:Connect(function()
        for _, v16 in ipairs(v12) do
            if typeof(v16) == "RBXScriptConnection" then
                v16:Disconnect()
            end
        end
    end))

    local v17 = Instance.new("Frame")
    v17.Name = "NotifContainer"
    v17.Parent = v15
    v17.BackgroundTransparency = 1
    v17.Size = UDim2.new(1, 0, 0, 0)
    v17.Position = UDim2.new(0, 0, 0, 30)
    v17.ZIndex = 100

    local v18 = Instance.new("UIListLayout")
    v18.Parent = v17
    v18.SortOrder = Enum.SortOrder.LayoutOrder
    v18.HorizontalAlignment = Enum.HorizontalAlignment.Center
    v18.Padding = UDim.new(0, 10)

    function v11:Notify(text, duration)
        duration = duration or 3
        local v19 = Instance.new("Frame")
        v19.Size = UDim2.new(0, 300, 0, 40)
        v19.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        v19.BorderSizePixel = 0
        v19.BackgroundTransparency = 1
        
        local v20 = Instance.new("UIScale", v19)
        v20.Scale = 0.8

        local v21 = Instance.new("UICorner")
        v21.CornerRadius = UDim.new(0, 8)
        v21.Parent = v19

        local v22 = Instance.new("UIStroke")
        v22.Thickness = 1.5
        v22.Color = v6
        v22.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        v22.Transparency = 1
        v22.Parent = v19

        local v23 = Instance.new("TextLabel")
        v23.Parent = v19
        v23.Size = UDim2.new(1, -20, 1, 0)
        v23.Position = UDim2.new(0, 10, 0, 0)
        v23.BackgroundTransparency = 1
        v23.Text = text
        v23.TextColor3 = Color3.fromRGB(255, 255, 255)
        v23.Font = Enum.Font.GothamBold
        v23.TextSize = 13
        v23.TextWrapped = true
        v23.TextTransparency = 1

        v19.Parent = v17

        v2:Create(v19, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.1}):Play()
        v2:Create(v20, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
        v2:Create(v22, TweenInfo.new(0.4), {Transparency = 0}):Play()
        v2:Create(v23, TweenInfo.new(0.4), {TextTransparency = 0}):Play()

        task.delay(duration, function()
            if not v19 or not v19.Parent then return end
            v2:Create(v20, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0.8}):Play()
            v2:Create(v19, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            v2:Create(v22, TweenInfo.new(0.3), {Transparency = 1}):Play()
            v2:Create(v23, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
            task.wait(0.3)
            if v19 then v19:Destroy() end
        end)
    end

    local function v24(v25, v26)
        local v27, v28, v29, v30

        table.insert(v12, v25.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                v27 = true
                v29 = input.Position
                v30 = v26.Position
                
                local v31, v32
                v31 = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        v27 = false
                        if v31 then v31:Disconnect() end
                        if v32 then v32:Disconnect() end
                    end
                end)
                table.insert(v12, v31)

                v32 = v1.InputEnded:Connect(function(endInput)
                    if endInput == input then
                        v27 = false
                        if v31 then v31:Disconnect() end
                        if v32 then v32:Disconnect() end
                    end
                end)
                table.insert(v12, v32)
            end
        end))

        table.insert(v12, v25.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                v28 = input
            end
        end))

        table.insert(v12, v1.InputChanged:Connect(function(input)
            if input == v28 and v27 then
                local v33 = input.Position - v29
                v26.Position = UDim2.new(v30.X.Scale, v30.X.Offset + v33.X, v30.Y.Scale, v30.Y.Offset + v33.Y)
            end
        end))
    end

    local v34 = Instance.new("CanvasGroup")
    v34.Name = "Main"
    v34.Parent = v15
    v34.BackgroundColor3 = v8
    v34.BorderSizePixel = 0
    v34.Position = UDim2.new(0.5, -250, 0.5, -150)
    v34.Size = UDim2.new(0, 500, 0, 350)
    v34.GroupTransparency = 1
    
    local v35 = Instance.new("UIScale", v34)
    v35.Scale = 0.85

    local v36 = Instance.new("UICorner")
    v36.CornerRadius = UDim.new(0, 8)
    v36.Parent = v34

    local v37 = Instance.new("UIStroke")
    v37.Thickness = 1.5
    v37.Color = Color3.fromRGB(40, 40, 40)
    v37.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    v37.Parent = v34

    v2:Create(v34, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
    v2:Create(v35, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()

    local v38 = Instance.new("Frame")
    v38.Name = "TopBar"
    v38.Parent = v34
    v38.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    v38.Size = UDim2.new(1, 0, 0, 40)
    v38.BorderSizePixel = 0
    v24(v38, v34)

    local v39 = Instance.new("UICorner")
    v39.CornerRadius = UDim.new(0, 8)
    v39.Parent = v38

    local v40 = Instance.new("TextLabel")
    v40.Parent = v38
    v40.Text = "SLAYER TYCOON V1 <font color='#00C3FF'>BY @theuniqueleader</font>"
    v40.RichText = true
    v40.TextColor3 = Color3.fromRGB(255, 255, 255)
    v40.Size = UDim2.new(1, -80, 1, 0)
    v40.Position = UDim2.new(0, 15, 0, 0)
    v40.TextXAlignment = Enum.TextXAlignment.Left
    v40.BackgroundTransparency = 1
    v40.Font = Enum.Font.GothamBold
    v40.TextSize = 14

    local v41 = Instance.new("TextButton")
    v41.Parent = v38
    v41.Size = UDim2.new(0, 35, 0, 35)
    v41.Position = UDim2.new(1, -40, 0.5, -17)
    v41.BackgroundTransparency = 1
    v41.Text = "X"
    v41.TextColor3 = Color3.fromRGB(150, 150, 150)
    v41.TextSize = 16
    v41.Font = Enum.Font.GothamBold
    
    table.insert(v12, v41.MouseEnter:Connect(function()
        v2:Create(v41, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 50, 50), Rotation = 90, TextSize = 18}):Play()
    end))
    table.insert(v12, v41.MouseLeave:Connect(function()
        v2:Create(v41, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(150, 150, 150), Rotation = 0, TextSize = 16}):Play()
    end))
    
    table.insert(v12, v41.MouseButton1Click:Connect(function()
        v2:Create(v35, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0.85}):Play()
        local v42 = v2:Create(v34, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {GroupTransparency = 1})
        v42:Play()
        v42.Completed:Wait()
        v15:Destroy()
    end))

    local v43 = Instance.new("TextButton")
    v43.Parent = v38
    v43.Size = UDim2.new(0, 35, 0, 35)
    v43.Position = UDim2.new(1, -75, 0.5, -17)
    v43.BackgroundTransparency = 1
    v43.Text = "‒"
    v43.TextColor3 = Color3.fromRGB(150, 150, 150)
    v43.TextSize = 16
    v43.Font = Enum.Font.GothamBold

    table.insert(v12, v43.MouseEnter:Connect(function()
        v2:Create(v43, TweenInfo.new(0.2), {TextColor3 = v6}):Play()
    end))
    table.insert(v12, v43.MouseLeave:Connect(function()
        v2:Create(v43, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(150, 150, 150)}):Play()
    end))

    local v44 = false
    local v45 = v34.Position
    table.insert(v12, v43.MouseButton1Click:Connect(function()
        v44 = not v44
        if v44 then
            v45 = v34.Position
            v2:Create(v34, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 10, 1, -50), Size = UDim2.new(0, 200, 0, 40)}):Play()
        else
            v2:Create(v34, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = v45, Size = UDim2.new(0, 500, 0, 350)}):Play()
        end
    end))

    local v46 = Instance.new("Frame")
    v46.Name = "TabBar"
    v46.Parent = v34
    v46.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    v46.Position = UDim2.new(0, 0, 0, 40)
    v46.Size = UDim2.new(0, 110, 1, -40)
    v46.BorderSizePixel = 0
    
    local v47 = Instance.new("UICorner")
    v47.CornerRadius = UDim.new(0, 8)
    v47.Parent = v46

    local v48 = Instance.new("UIListLayout")
    v48.Parent = v46
    v48.Padding = UDim.new(0, 6)
    v48.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local v49 = Instance.new("UIPadding")
    v49.Parent = v46
    v49.PaddingTop = UDim.new(0, 10)

    local v50 = Instance.new("Frame")
    v50.Name = "Pages"
    v50.Parent = v34
    v50.BackgroundTransparency = 1
    v50.Position = UDim2.new(0, 120, 0, 50)
    v50.Size = UDim2.new(1, -130, 1, -60)

    v11.Pages = v50
    v11.TabBar = v46
    v11.TabCount = 0

    local function v51(v52)
        local v53 = Instance.new("Frame")
        v53.Size = UDim2.new(1, 0, 1, 0)
        v53.BackgroundColor3 = v6
        v53.BackgroundTransparency = 0.5
        v53.BorderSizePixel = 0
        local v54 = Instance.new("UICorner")
        v54.CornerRadius = UDim.new(0, 6)
        v54.Parent = v53
        v53.Parent = v52

        local v55 = v2:Create(v53, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
        v55:Play()
        v55.Completed:Connect(function() v53:Destroy() end)
    end

    function v11:CreateTab(name)
        local v56 = {}
        v11.TabCount = v11.TabCount + 1

        local v57 = Instance.new("ScrollingFrame")
        v57.Name = name .. "Page"
        v57.Parent = v11.Pages
        v57.BackgroundTransparency = 1
        v57.Size = UDim2.new(1, 0, 1, 0)
        v57.ScrollBarThickness = 2
        v57.ScrollBarImageColor3 = v6
        v57.Visible = (v11.TabCount == 1)
        v57.CanvasSize = UDim2.new(0, 0, 0, 0)
        v57.BorderSizePixel = 0

        local v58 = Instance.new("UIListLayout")
        v58.Parent = v57
        v58.Padding = UDim.new(0, 8)
        table.insert(v12, v58:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            v57.CanvasSize = UDim2.new(0, 0, 0, v58.AbsoluteContentSize.Y)
        end))

        local v59 = Instance.new("TextButton")
        v59.Name = name .. "Tab"
        v59.Parent = v11.TabBar
        v59.Size = UDim2.new(0, 100, 0, 32)
        
        local v60 = Instance.new("UIScale", v59)
        
        if v11.TabCount == 1 then
            v59.BackgroundColor3 = v6
            v59.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            v59.BackgroundColor3 = v9
            v59.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
        
        v59.BorderSizePixel = 0
        v59.Text = name
        v59.Font = Enum.Font.GothamBold
        v59.TextSize = 11

        local v61 = Instance.new("UICorner")
        v61.CornerRadius = UDim.new(0, 6)
        v61.Parent = v59

        table.insert(v12, v59.MouseEnter:Connect(function()
            v2:Create(v60, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {Scale = 1.04}):Play()
        end))
        table.insert(v12, v59.MouseLeave:Connect(function()
            v2:Create(v60, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {Scale = 1}):Play()
        end))

        table.insert(v12, v59.MouseButton1Click:Connect(function()
            v51(v59)
            v2:Create(v60, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), {Scale = 0.95}):Play()
            task.wait(0.1)
            v2:Create(v60, TweenInfo.new(0.2, Enum.EasingStyle.Bounce), {Scale = 1.04}):Play()

            for _, v62 in pairs(v11.Pages:GetChildren()) do v62.Visible = false end
            for _, v63 in pairs(v11.TabBar:GetChildren()) do
                if v63:IsA("TextButton") then 
                    v2:Create(v63, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(150, 150, 150), BackgroundColor3 = v9}):Play()
                end
            end
            v57.Visible = true
            v2:Create(v59, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = v6}):Play()
        end))

        function v56:CreateLabel(text)
            local v64 = Instance.new("Frame")
            v64.Size = UDim2.new(1, 0, 0, 28)
            v64.BackgroundTransparency = 1
            v64.Parent = v57

            local v65 = Instance.new("TextLabel")
            v65.Parent = v64
            v65.Size = UDim2.new(1, -10, 1, 0)
            v65.Position = UDim2.new(0, 5, 0, 0)
            v65.BackgroundTransparency = 1
            v65.Text = text
            v65.TextColor3 = Color3.fromRGB(190, 190, 190)
            v65.Font = Enum.Font.Gotham
            v65.TextSize = 12
            v65.TextXAlignment = Enum.TextXAlignment.Left
            v65.TextWrapped = true
        end

        function v56:CreateToggle(config)
            local v66 = Instance.new("Frame")
            v66.Size = UDim2.new(1, 0, 0, 38)
            v66.BackgroundTransparency = 1
            v66.Parent = v57

            local v67 = Instance.new("TextButton")
            v67.Parent = v66
            v67.BackgroundColor3 = v9
            v67.Size = UDim2.new(1, 0, 1, 0)
            v67.Text = "   " .. config.Name
            v67.TextColor3 = Color3.fromRGB(200, 200, 200)
            v67.Font = Enum.Font.Gotham
            v67.TextSize = 13
            v67.TextXAlignment = Enum.TextXAlignment.Left
            v67.BorderSizePixel = 0

            local v68 = Instance.new("UIScale", v67)

            local v69 = Instance.new("UICorner")
            v69.CornerRadius = UDim.new(0, 6)
            v69.Parent = v67

            local v70 = Instance.new("Frame")
            v70.Parent = v67
            v70.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            v70.Position = UDim2.new(1, -45, 0.5, -10)
            v70.Size = UDim2.new(0, 36, 0, 20)
            v70.BorderSizePixel = 0

            local v71 = Instance.new("UICorner")
            v71.CornerRadius = UDim.new(1, 0)
            v71.Parent = v70

            local v72 = Instance.new("Frame")
            v72.Parent = v70
            v72.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
            v72.Position = UDim2.new(0, 2, 0.5, -8)
            v72.Size = UDim2.new(0, 16, 0, 16)
            v72.BorderSizePixel = 0

            local v73 = Instance.new("UICorner")
            v73.CornerRadius = UDim.new(1, 0)
            v73.Parent = v72
            
            local v74 = Instance.new("UIStroke", v70)
            v74.Color = v7
            v74.Thickness = 2
            v74.Transparency = 1

            local v75 = false

            table.insert(v12, v67.MouseEnter:Connect(function()
                v2:Create(v67, TweenInfo.new(0.2), {BackgroundColor3 = v10}):Play()
            end))
            table.insert(v12, v67.MouseLeave:Connect(function()
                v2:Create(v67, TweenInfo.new(0.2), {BackgroundColor3 = v9}):Play()
            end))

            local function v76(state)
                v75 = state
                if v75 then
                    v2:Create(v72, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -18, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                    v2:Create(v70, TweenInfo.new(0.3), {BackgroundColor3 = v6}):Play()
                    
                    v74.Transparency = 0
                    v2:Create(v74, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()
                else
                    v2:Create(v72, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = Color3.fromRGB(150, 150, 150)}):Play()
                    v2:Create(v70, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
                end
            end

            table.insert(v12, v67.MouseButton1Down:Connect(function()
                v2:Create(v68, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {Scale = 0.97}):Play()
            end))
            
            table.insert(v12, v67.MouseButton1Click:Connect(function()
                v2:Create(v68, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
                v75 = not v75
                v76(v75)
                if config.Callback then config.Callback(v75, v76) end
            end))
            return v76
        end

        function v56:CreateBind(config)
            local v77 = Instance.new("Frame")
            v77.Size = UDim2.new(1, 0, 0, 38)
            v77.BackgroundTransparency = 1
            v77.Parent = v57

            local v78 = Instance.new("Frame")
            v78.Size = UDim2.new(1, 0, 1, 0)
            v78.BackgroundColor3 = v9
            v78.Parent = v77

            local v79 = Instance.new("UICorner")
            v79.CornerRadius = UDim.new(0, 6)
            v79.Parent = v78

            local v80 = Instance.new("TextLabel")
            v80.Parent = v78
            v80.Size = UDim2.new(1, -100, 1, 0)
            v80.BackgroundTransparency = 1
            v80.Text = "   " .. config.Name
            v80.TextColor3 = Color3.fromRGB(200, 200, 200)
            v80.Font = Enum.Font.Gotham
            v80.TextSize = 13
            v80.TextXAlignment = Enum.TextXAlignment.Left

            local v81 = Instance.new("TextButton")
            v81.Parent = v78
            v81.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            v81.Size = UDim2.new(0, 80, 0, 24)
            v81.Position = UDim2.new(1, -90, 0.5, -12)
            
            local v82 = config.Default
            v81.Text = v82 and tostring(v82.Name or v82) or "NONE"
            v81.TextColor3 = Color3.fromRGB(255, 255, 255)
            v81.Font = Enum.Font.GothamBold
            v81.TextSize = 11
            v81.BorderSizePixel = 0

            local v83 = Instance.new("UICorner")
            v83.CornerRadius = UDim.new(0, 4)
            v83.Parent = v81

            table.insert(v12, v78.MouseEnter:Connect(function()
                v2:Create(v78, TweenInfo.new(0.2), {BackgroundColor3 = v10}):Play()
            end))
            table.insert(v12, v78.MouseLeave:Connect(function()
                v2:Create(v78, TweenInfo.new(0.2), {BackgroundColor3 = v9}):Play()
            end))

            table.insert(v12, v1.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                if v82 and (input.KeyCode == v82 or input.UserInputType == v82) then
                    if config.Callback then
                        config.Callback()
                    end
                end
            end))

            table.insert(v12, v81.MouseButton1Click:Connect(function()
                v81.Text = "..."
                v2:Create(v81, TweenInfo.new(0.2), {BackgroundColor3 = v6}):Play()
                
                if config.BindTable then config.BindTable.IsBinding = true end
                local v84
                v84 = v1.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.Keyboard or i.UserInputType.Name:find("MouseButton") then
                        local v85 = (i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode or i.UserInputType)
                        v82 = v85 
                        if config.BindTable and config.KeyIndex then
                            config.BindTable[config.KeyIndex] = v85
                        end
                        v81.Text = tostring(v85.Name or v85)
                        v2:Create(v81, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
                        if config.BindTable then config.BindTable.IsBinding = false end
                        v84:Disconnect()
                    end
                end)
                table.insert(v12, v84)
            end))
        end

        function v56:CreateButton(config)
            local v86 = Instance.new("TextButton")
            v86.Parent = v57
            v86.BackgroundColor3 = v9
            v86.Size = UDim2.new(1, 0, 0, 38)
            v86.Text = config.Name
            v86.TextColor3 = Color3.fromRGB(255, 255, 255)
            v86.Font = Enum.Font.GothamBold
            v86.TextSize = 13
            v86.BorderSizePixel = 0

            local v87 = Instance.new("UIScale", v86)

            local v88 = Instance.new("UICorner")
            v88.CornerRadius = UDim.new(0, 6)
            v88.Parent = v86
            
            table.insert(v12, v86.MouseEnter:Connect(function()
                v2:Create(v86, TweenInfo.new(0.2), {BackgroundColor3 = v10}):Play()
                v2:Create(v87, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {Scale = 1.01}):Play()
            end))
            table.insert(v12, v86.MouseLeave:Connect(function()
                v2:Create(v86, TweenInfo.new(0.2), {BackgroundColor3 = v9}):Play()
                v2:Create(v87, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {Scale = 1}):Play()
            end))

            table.insert(v12, v86.MouseButton1Down:Connect(function()
                v2:Create(v87, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {Scale = 0.96}):Play()
            end))

            table.insert(v12, v86.MouseButton1Click:Connect(function()
                v51(v86)
                v2:Create(v87, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.01}):Play()
                if config.Callback then config.Callback() end
            end))
        end

        function v56:CreateSlider(config)
            local v89 = Instance.new("Frame")
            v89.Size = UDim2.new(1, 0, 0, 50)
            v89.BackgroundColor3 = v9
            v89.Parent = v57

            local v90 = Instance.new("UICorner")
            v90.CornerRadius = UDim.new(0, 6)
            v90.Parent = v89

            local v91 = Instance.new("TextLabel")
            v91.Parent = v89
            v91.Text = "   " .. config.Name .. " : " .. config.Default
            v91.TextColor3 = Color3.fromRGB(200, 200, 200)
            v91.Size = UDim2.new(1, 0, 0, 25)
            v91.BackgroundTransparency = 1
            v91.Font = Enum.Font.Gotham
            v91.TextSize = 12
            v91.TextXAlignment = Enum.TextXAlignment.Left

            local v92 = Instance.new("Frame")
            v92.Parent = v89
            v92.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            v92.Position = UDim2.new(0, 10, 0, 30)
            v92.Size = UDim2.new(1, -20, 0, 6)
            v92.BorderSizePixel = 0

            local v93 = Instance.new("UICorner")
            v93.CornerRadius = UDim.new(1, 0)
            v93.Parent = v92

            local v94 = Instance.new("Frame")
            v94.Parent = v92
            v94.BackgroundColor3 = v6
            v94.Size = UDim2.new(math.clamp((config.Default - config.Min) / (config.Max - config.Min), 0, 1), 0, 1, 0)
            v94.BorderSizePixel = 0

            local v95 = Instance.new("UICorner")
            v95.CornerRadius = UDim.new(1, 0)
            v95.Parent = v94
            
            table.insert(v12, v89.MouseEnter:Connect(function()
                v2:Create(v89, TweenInfo.new(0.2), {BackgroundColor3 = v10}):Play()
            end))
            table.insert(v12, v89.MouseLeave:Connect(function()
                v2:Create(v89, TweenInfo.new(0.2), {BackgroundColor3 = v9}):Play()
            end))

            local v96 = false
            local function v97(input)
                local v98 = math.clamp((input.Position.X - v92.AbsolutePosition.X) / v92.AbsoluteSize.X, 0, 1)
                v2:Create(v94, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(v98, 0, 1, 0)}):Play()
                
                local v99 = math.floor(((config.Max - config.Min) * v98) + config.Min)
                v91.Text = "   " .. config.Name .. " : " .. v99
                if config.Callback then config.Callback(v99) end
            end

            table.insert(v12, v92.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
                    v96 = true 
                    v97(input) 
                end
            end))

            table.insert(v12, v1.InputChanged:Connect(function(input)
                if v96 and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then 
                    v97(input) 
                end
            end))

            table.insert(v12, v1.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
                    v96 = false 
                end
            end))
        end
        
        function v56:CreateTextBox(config)
            local v100 = Instance.new("Frame")
            v100.Size = UDim2.new(1, 0, 0, 38)
            v100.BackgroundTransparency = 1
            v100.Parent = v57

            local v101 = Instance.new("Frame")
            v101.Size = UDim2.new(1, 0, 1, 0)
            v101.BackgroundColor3 = v9
            v101.Parent = v100

            local v102 = Instance.new("UICorner")
            v102.CornerRadius = UDim.new(0, 6)
            v102.Parent = v101
            
            local v103 = Instance.new("UIStroke", v101)
            v103.Color = v6
            v103.Thickness = 1.5
            v103.Transparency = 1
            v103.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

            local v104 = Instance.new("TextBox")
            v104.Parent = v101
            v104.Size = UDim2.new(1, -20, 1, 0)
            v104.Position = UDim2.new(0, 10, 0, 0)
            v104.BackgroundTransparency = 1
            v104.Text = config.Default or ""
            v104.PlaceholderText = config.Name or "Enter text..."
            v104.TextColor3 = Color3.fromRGB(200, 200, 200)
            v104.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
            v104.Font = Enum.Font.Gotham
            v104.TextSize = 13
            v104.TextXAlignment = Enum.TextXAlignment.Left
            v104.ClearTextOnFocus = false

            table.insert(v12, v104.Focused:Connect(function()
                v2:Create(v103, TweenInfo.new(0.3), {Transparency = 0}):Play()
                v2:Create(v101, TweenInfo.new(0.3), {BackgroundColor3 = v10}):Play()
            end))

            table.insert(v12, v104.FocusLost:Connect(function()
                v2:Create(v103, TweenInfo.new(0.3), {Transparency = 1}):Play()
                v2:Create(v101, TweenInfo.new(0.3), {BackgroundColor3 = v9}):Play()
                if config.Callback then
                    config.Callback(v104.Text)
                end
            end))
        end

        return v56
    end

    return v11
end

return UI
