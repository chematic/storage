local Module = {}

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

Module.State = {
    JobEnabled = false,
    Destroyed = false,
    LastProcessedPrompt = nil,
    FloatPart = nil,
    BoostConnection = nil,
    FloatConnection = nil,
    AntiSitConnection = nil,
    OriginalPartStates = {},
    SessionStartTime = 0,
    InitialBalance = nil,
    TotalEarned = 0,
    History = {},
    Connections = {}
}

local function TrackConnection(conn)
    table.insert(Module.State.Connections, conn)
    return conn
end

local function TweenSafe(instance, info, properties)
    if Module.State.Destroyed or not instance or not instance.Parent then return end
    local tween = TweenService:Create(instance, info, properties)
    tween:Play()
    return tween
end

local function SetupPrompt(prompt)
    if prompt and prompt:IsA("ProximityPrompt") then
        prompt.HoldDuration = 0
        prompt.KeyboardKeyCode = Enum.KeyCode.E
        prompt.Style = Enum.ProximityPromptStyle.Default
        prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
        prompt.MaxActivationDistance = 3
    end
end

local function GetBasePart(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") and inst.PrimaryPart then return inst.PrimaryPart end
    return inst:FindFirstChildWhichIsA("BasePart", true)
end

local function GetTool(toolName)
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack") or LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character
    if character and character:FindFirstChild(toolName) then return character:FindFirstChild(toolName) end
    if backpack and backpack:FindFirstChild(toolName) then return backpack:FindFirstChild(toolName) end
    return nil
end

local function EquipOnlyTool(toolName)
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack") or LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character
    if not character or not backpack then return end

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then child.Parent = backpack end
    end

    local targetTool = backpack:FindFirstChild(toolName)
    if targetTool and targetTool:IsA("Tool") then targetTool.Parent = character end
end

local function TriggerPrompt(prompt)
    if not prompt or not prompt.Parent or not prompt.Enabled then return end

    prompt.HoldDuration = 0
    prompt.RequiresLineOfSight = false

    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local parentPart = prompt.Parent:IsA("BasePart") and prompt.Parent or prompt.Parent:FindFirstChildWhichIsA("BasePart")

    if root and parentPart then
        if (root.Position - parentPart.Position).Magnitude > (prompt.MaxActivationDistance or 8) then
            root.CFrame = parentPart.CFrame * CFrame.new(0, 0, 2)
            task.wait(0.08)
        end
    end

    local fired = false
    pcall(function()
        prompt:InputHoldBegin()
        task.wait(0.02)
        prompt:InputHoldEnd()
        fired = true
    end)

    if not fired then
        pcall(function()
            local keyCode = prompt.KeyboardKeyCode ~= Enum.KeyCode.Unknown and prompt.KeyboardKeyCode or Enum.KeyCode.E
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        end)
    end
end

local function SmoothTeleport(targetCFrame)
    local character = LocalPlayer.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end

    rootPart.Anchored = true
    local tween = TweenSafe(rootPart, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCFrame})
    if tween then tween.Completed:Wait() end
    rootPart.Anchored = false
end

local function IsWhitelisted(v)
    local mojave = Workspace:FindFirstChild("Mojave")
    if not mojave then return false end
    local interactiveJobs = mojave:FindFirstChild("InteractiveJobs")
    if not interactiveJobs then return false end
    local peets = interactiveJobs:FindFirstChild("Peets Coffee & Tea")
    if not peets then return false end
    local building = peets:FindFirstChild("Building")
    if not building then return false end

    return v:IsDescendantOf(building) or v == building
end

function Module.ToggleBoostAndFloat(state)
    if state then
        game:GetService("Lighting").GlobalShadows = false
        
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v:IsDescendantOf(LocalPlayer.Character) and v ~= Module.State.FloatPart then
                if not Module.State.OriginalPartStates[v] then
                    Module.State.OriginalPartStates[v] = {
                        CanCollide = v.CanCollide,
                        Material = v.Material,
                        CastShadow = v.CastShadow
                    }
                end
                
                local whitelisted = IsWhitelisted(v)
                pcall(function()
                    v.Material = Enum.Material.SmoothPlastic
                    v.CastShadow = false
                    if not whitelisted then
                        v.CanCollide = false
                    end
                end)
            end
        end
        
        if Module.State.BoostConnection then Module.State.BoostConnection:Disconnect() end
        Module.State.BoostConnection = Workspace.DescendantAdded:Connect(function(v)
            if v:IsA("BasePart") and not v:IsDescendantOf(LocalPlayer.Character) and v ~= Module.State.FloatPart then
                task.wait()
                if not Module.State.OriginalPartStates[v] then
                    Module.State.OriginalPartStates[v] = {
                        CanCollide = v.CanCollide,
                        Material = v.Material,
                        CastShadow = v.CastShadow
                    }
                end
                
                local whitelisted = IsWhitelisted(v)
                pcall(function()
                    v.Material = Enum.Material.SmoothPlastic
                    v.CastShadow = false
                    if not whitelisted then
                        v.CanCollide = false
                    end
                end)
            end
        end)
        TrackConnection(Module.State.BoostConnection)
        
        if not Module.State.FloatPart then
            Module.State.FloatPart = Instance.new("Part")
            Module.State.FloatPart.Name = "FLOATING"
            Module.State.FloatPart.Size = Vector3.new(3, 1, 3)
            Module.State.FloatPart.Transparency = 1
            Module.State.FloatPart.Anchored = true
            Module.State.FloatPart.CanCollide = true
            Module.State.FloatPart.Parent = Workspace
        end
        
        if Module.State.FloatConnection then Module.State.FloatConnection:Disconnect() end
        Module.State.FloatConnection = RunService.Heartbeat:Connect(function()
            if Module.State.FloatPart and LocalPlayer.Character then
                local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local raycastParams = RaycastParams.new()
                    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                    local excludeList = {LocalPlayer.Character}
                    if Module.State.FloatPart then table.insert(excludeList, Module.State.FloatPart) end
                    raycastParams.FilterDescendantsInstances = excludeList
                    
                    local raycastResult = Workspace:Raycast(root.Position, Vector3.new(0, -40, 0), raycastParams)
                    if raycastResult then
                        Module.State.FloatPart.Position = Vector3.new(root.Position.X, raycastResult.Position.Y, root.Position.Z)
                    else
                        Module.State.FloatPart.Position = root.Position - Vector3.new(0, 3.5, 0)
                    end
                end
            end
        end)
        TrackConnection(Module.State.FloatConnection)
    else
        game:GetService("Lighting").GlobalShadows = true
        
        if Module.State.BoostConnection then
            Module.State.BoostConnection:Disconnect()
            Module.State.BoostConnection = nil
        end
        if Module.State.FloatConnection then
            Module.State.FloatConnection:Disconnect()
            Module.State.FloatConnection = nil
        end
        if Module.State.FloatPart then
            Module.State.FloatPart:Destroy()
            Module.State.FloatPart = nil
        end
        
        for part, data in pairs(Module.State.OriginalPartStates) do
            if part and part.Parent then
                pcall(function()
                    part.CanCollide = data.CanCollide
                    part.Material = data.Material
                    part.CastShadow = data.CastShadow
                end)
            end
        end
        table.clear(Module.State.OriginalPartStates)
    end
end

function Module.GetNumericBalance()
    local success, balanceGui = pcall(function()
        return LocalPlayer.PlayerGui.MojavePlayerUI.JobBar.Money.Icon.balance
    end)
    if success and balanceGui and balanceGui:IsA("TextLabel") then
        local text = balanceGui.Text
        local cleaned = text:gsub("[^%d]", "")
        return tonumber(cleaned)
    end
    return nil
end

function Module.SetJobState(state)
    Module.State.JobEnabled = state
    if state then
        SmoothTeleport(CFrame.new(-3463, -102, -15432))
        Module.State.SessionStartTime = tick()
        Module.State.InitialBalance = nil
        Module.State.TotalEarned = 0
    end
end

function Module.Start()
    -- Heartbeat Anti-Sit
    TrackConnection(RunService.Heartbeat:Connect(function()
        if Module.State.JobEnabled and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Sit then
                hum.Sit = false
                hum.Jump = true
            end
        end
    end))

    -- Automation Core Loop
    task.spawn(function()
        local mojaveFolder = Workspace:WaitForChild("Mojave", 5)
        local interactiveJobsFolder = mojaveFolder and mojaveFolder:WaitForChild("InteractiveJobs", 5)
        local peetsFolder = interactiveJobsFolder and interactiveJobsFolder:WaitForChild("Peets Coffee & Tea", 5)
        local interactiveFolder = peetsFolder and peetsFolder:WaitForChild("Interactive", 5)
        local npcsFolder = Workspace:WaitForChild("NPCs", 5)

        if interactiveFolder then
            for _, desc in ipairs(interactiveFolder:GetDescendants()) do SetupPrompt(desc) end
            TrackConnection(interactiveFolder.DescendantAdded:Connect(SetupPrompt))
        end

        local function ApplyNpcWalkSpeed(obj)
            if obj:IsA("Humanoid") then obj.WalkSpeed = 150
            elseif obj:IsA("Model") then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 150 end
            end
        end

        if npcsFolder then
            for _, desc in ipairs(npcsFolder:GetDescendants()) do SetupPrompt(desc); ApplyNpcWalkSpeed(desc) end
            TrackConnection(npcsFolder.DescendantAdded:Connect(function(d) SetupPrompt(d); ApplyNpcWalkSpeed(d) end))
        end

        local function DoWorkHere()
            if not peetsFolder then return end
            local workHere = peetsFolder:FindFirstChild("WorkHere")
            if not workHere then return end

            local workPrompt = workHere:FindFirstChildWhichIsA("ProximityPrompt", true) or workHere:FindFirstChild("ProximityPrompt", true)
            if workPrompt then
                SetupPrompt(workPrompt)
                local targetPart = GetBasePart(workHere) or GetBasePart(workPrompt.Parent)
                if targetPart then
                    SmoothTeleport(targetPart.CFrame)
                    task.wait(0.15)
                    local startWorkTime = tick()
                    while (tick() - startWorkTime) < 0.4 and not Module.State.Destroyed do
                        TriggerPrompt(workPrompt)
                        task.wait(0.05)
                    end
                    task.wait(0.3)
                end
            end
        end

        while not Module.State.Destroyed do
            if not Module.State.JobEnabled then
                task.wait(0.3)
                continue
            end

            pcall(function()
                if not npcsFolder or not interactiveFolder then return end
                local character = LocalPlayer.Character
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                if not rootPart then return end

                local anyDisabled = false
                for _, desc in ipairs(interactiveFolder:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") and not desc.Enabled then
                        anyDisabled = true
                        break
                    end
                end
                if anyDisabled then DoWorkHere() end

                local handPrompt = nil
                for _, desc in ipairs(npcsFolder:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") and desc.Name == "HandPrompt" then
                        if desc ~= Module.State.LastProcessedPrompt then
                            handPrompt = desc
                            break
                        end
                    end
                end

                if Module.State.LastProcessedPrompt and (not Module.State.LastProcessedPrompt.Parent or not npcsFolder:IsAncestorOf(Module.State.LastProcessedPrompt)) then
                    Module.State.LastProcessedPrompt = nil
                end

                if handPrompt then
                    SetupPrompt(handPrompt)
                    local rawText = handPrompt.ObjectText ~= "" and handPrompt.ObjectText or handPrompt.ActionText
                    local objText = string.gsub(rawText or "", "%s+", "")
                    local targetPromptName, toolName = nil, nil

                    if string.find(objText, "Coffee") then
                        targetPromptName, toolName = "Coffee", "Coffee"
                    elseif string.find(objText, "Croissant") then
                        targetPromptName, toolName = "Croissant", "Croissant"
                    elseif string.find(objText, "EggSandwich") or string.find(objText, "Egg") then
                        targetPromptName, toolName = "EggSandwich", "EggSandwich"
                    elseif string.find(objText, "Milkshake") then
                        targetPromptName, toolName = "Milkshake", "Milkshake"
                    end

                    if targetPromptName then
                        local itemPart = interactiveFolder:FindFirstChild(targetPromptName)
                        if itemPart then
                            local itemPrompt = itemPart:FindFirstChildWhichIsA("ProximityPrompt", true) or itemPart:FindFirstChild("ProximityPrompt", true)
                            if itemPrompt then
                                SetupPrompt(itemPrompt)
                                if not itemPrompt.Enabled then
                                    DoWorkHere()
                                    task.wait(0.2)
                                end

                                local targetPart = GetBasePart(itemPart) or GetBasePart(itemPrompt.Parent)
                                if targetPart then
                                    SmoothTeleport(targetPart.CFrame)
                                    task.wait(0.1)
                                end

                                local startTime = tick()
                                local tool = GetTool(toolName)
                                while not tool and (tick() - startTime < 6) and not Module.State.Destroyed and Module.State.JobEnabled do
                                    if targetPart then rootPart.CFrame = targetPart.CFrame end
                                    TriggerPrompt(itemPrompt)
                                    task.wait(0.25)
                                    tool = GetTool(toolName)
                                end

                                EquipOnlyTool(toolName)
                                task.wait(0.2)

                                if handPrompt and handPrompt.Parent then
                                    local npcPart = GetBasePart(handPrompt.Parent)
                                    if npcPart then
                                        SmoothTeleport(npcPart.CFrame)
                                        task.wait(0.1)
                                    end

                                    if handPrompt and handPrompt.Parent then
                                        TriggerPrompt(handPrompt)
                                        local deliveryTime = tick()
                                        while GetTool(toolName) and (tick() - deliveryTime < 3) and not Module.State.Destroyed and Module.State.JobEnabled do
                                            task.wait(0.15)
                                        end
                                        Module.State.LastProcessedPrompt = handPrompt
                                        task.wait(0.5)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            task.wait(0.3)
        end
    end)
end

function Module.Cleanup()
    Module.State.Destroyed = true
    Module.State.JobEnabled = false
    
    for _, conn in ipairs(Module.State.Connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(Module.State.Connections)
    
    if Module.State.FloatPart then
        Module.State.FloatPart:Destroy()
    end
    
    for part, data in pairs(Module.State.OriginalPartStates) do
        if part and part.Parent then
            pcall(function()
                part.CanCollide = data.CanCollide
                part.Material = data.Material
                part.CastShadow = data.CastShadow
            end)
        end
    end
    table.clear(Module.State.OriginalPartStates)
end

return Module
