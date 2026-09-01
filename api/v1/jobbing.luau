-- @name: autojobModule
local jobModule = {}

--[=[
    Separated module for autofarming. 
    And for me to focus clearly on the task i want to do, 
    which is to make the autofarm work properly and not just a simple script that does everything in a messy way.

    This module handles the logic for automatically performing tasks in the game, 
    such as interacting with prompts, equipping tools, and managing the player's state during the job.

    Authors:
        @vhb7 ........... Discord
        @ammoleking ..... Telegram
        @ammoleking.26 .. Signal

    List of features:
        Auto-equip tools when needed
        Override proximity prompts for faster interaction (basic rule)
        Boost FPS for better performance (breaking the autofarm because of the float part collisions. Should adjust the logic later)
        Smooth teleportation to target locations via tweening
        Handle NPC interactions and deliveries
        Track and manage job state, including earnings and session time (basically via jobModule.jobState, with the UI in-game)

    
    Last Update: 
        2026-09-01
--]=]

--[=[
    Starting work at 22:00 (10:00 PM)

    Noticed:
        The position was patched, because of a new update of MJ valley.
--]=]  

local workspace = game:GetService("Workspace")
local players = game:GetService("Players")
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")
local virtualInputManager = game:GetService("VirtualInputManager")
local lighting = game:GetService("Lighting")

local localPlayer = players.LocalPlayer

jobModule.jobState = {
    enabled = false,
    destroyed = false,
    lastProcessedPrompt = nil,
    floatPart = nil,
    boostConnection = nil,
    floatConnection = nil,
    originalPartStates = {},
    sessionStartTime = 0,
    initialBalance = nil,
    totalEarned = 0,
    history = {},
    connections = {}
}

jobModule.appSettings = {
    autoEquipTools = true,
    promptOverride = true,
    boostFpsAndFloat = false
}

local function disableSeatsFolder()
    pcall(function()
        local seats = workspace:FindFirstChild("Seats")
        if seats then
            for _, obj in ipairs(seats:GetDescendants()) do
                pcall(function()
                    if obj:IsA("Seat") or obj:IsA("VehicleSeat") then
                        obj.Disabled = true
                        obj.CanTouch = false
                    elseif obj:IsA("BasePart") then
                        obj.CanTouch = false
                    end
                end)
            end
            pcall(function()
                seats:Destroy()
            end)
        end
    end)
end

local function trackConnection(conn)
    table.insert(jobModule.jobState.connections, conn)
    return conn
end

local function getBasePart(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") and inst.PrimaryPart then return inst.PrimaryPart end
    return inst:FindFirstChildWhichIsA("BasePart", true)
end

local function getTool(toolName)
    local backpack = localPlayer:FindFirstChildOfClass("Backpack") or localPlayer:FindFirstChild("Backpack")
    local character = localPlayer.Character
    if character and character:FindFirstChild(toolName) then return character:FindFirstChild(toolName) end
    if backpack and backpack:FindFirstChild(toolName) then return backpack:FindFirstChild(toolName) end
    return nil
end

local function equipOnlyTool(toolName)
    if not jobModule.appSettings.autoEquipTools then return end
    local backpack = localPlayer:FindFirstChildOfClass("Backpack") or localPlayer:FindFirstChild("Backpack")
    local character = localPlayer.Character
    if not character or not backpack then return end

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            child.Parent = backpack
        end
    end

    local targetTool = backpack:FindFirstChild(toolName)
    if targetTool and targetTool:IsA("Tool") then
        targetTool.Parent = character
    end
end

local function setupPrompt(prompt)
    if prompt and prompt:IsA("ProximityPrompt") and jobModule.appSettings.promptOverride then
        prompt.HoldDuration = 0
        prompt.KeyboardKeyCode = Enum.KeyCode.E
        prompt.Style = Enum.ProximityPromptStyle.Default
        prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
        prompt.MaxActivationDistance = 4
    end
end

local function triggerPrompt(prompt)
    if not prompt or not prompt.Parent or not prompt.Enabled then return end

    prompt.HoldDuration = 0
    prompt.RequiresLineOfSight = false

    local character = localPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local parentPart = prompt.Parent:IsA("BasePart") and prompt.Parent or prompt.Parent:FindFirstChildWhichIsA("BasePart")

    if root and parentPart and (root.Position - parentPart.Position).Magnitude > (prompt.MaxActivationDistance or 8) then
        root.CFrame = parentPart.CFrame * CFrame.new(0, 0, 2)
        task.wait(0.08)
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
            local keyCode = (prompt.KeyboardKeyCode ~= Enum.KeyCode.Unknown) and prompt.KeyboardKeyCode or Enum.KeyCode.E
            virtualInputManager:SendKeyEvent(true, keyCode, false, game)
            task.wait(0.05)
            virtualInputManager:SendKeyEvent(false, keyCode, false, game)
        end)
    end
end

local function smoothTeleport(targetCFrame)
    local character = localPlayer.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end

    rootPart.Anchored = true
    local t = tweenService:Create(rootPart, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCFrame})
    t:Play()
    t.Completed:Wait()
    rootPart.Anchored = false
end

local function isWhitelistedPart(part)
    local mojave = workspace:FindFirstChild("Mojave")
    local interactiveJobs = mojave and mojave:FindFirstChild("InteractiveJobs")
    local peets = interactiveJobs and interactiveJobs:FindFirstChild("Peets Coffee & Tea")
    local building = peets and peets:FindFirstChild("Building")
    return building and (part:IsDescendantOf(building) or part == building) or false
end

function jobModule.toggleBoostAndFloat(enabled)
    jobModule.appSettings.boostFpsAndFloat = enabled
    local state = jobModule.jobState

    if enabled then
        lighting.GlobalShadows = false

        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") and not part:IsDescendantOf(localPlayer.Character) and part ~= state.floatPart then
                if not state.originalPartStates[part] then
                    state.originalPartStates[part] = {
                        CanCollide = part.CanCollide,
                        Material = part.Material,
                        CastShadow = part.CastShadow
                    }
                end

                local whitelisted = isWhitelistedPart(part)
                pcall(function()
                    part.Material = Enum.Material.SmoothPlastic
                    part.CastShadow = false
                    if not whitelisted then
                        part.CanCollide = false
                    end
                end)
            end
        end

        if state.boostConnection then state.boostConnection:Disconnect() end
        state.boostConnection = workspace.DescendantAdded:Connect(function(part)
            if part:IsA("BasePart") and not part:IsDescendantOf(localPlayer.Character) and part ~= state.floatPart then
                task.wait()
                if not state.originalPartStates[part] then
                    state.originalPartStates[part] = {
                        CanCollide = part.CanCollide,
                        Material = part.Material,
                        CastShadow = part.CastShadow
                    }
                end

                local whitelisted = isWhitelistedPart(part)
                pcall(function()
                    part.Material = Enum.Material.SmoothPlastic
                    part.CastShadow = false
                    if not whitelisted then
                        part.CanCollide = false
                    end
                end)
            end
        end)
        trackConnection(state.boostConnection)

        if not state.floatPart then
            local float = Instance.new("Part")
            float.Name = "FLOATING"
            float.Size = Vector3.new(3, 1, 3)
            float.Transparency = 1
            float.Anchored = true
            float.CanCollide = true
            float.Parent = workspace
            state.floatPart = float
        end

        if state.floatConnection then state.floatConnection:Disconnect() end
        state.floatConnection = runService.Heartbeat:Connect(function()
            if state.floatPart and localPlayer.Character then
                local root = localPlayer.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local rayParams = RaycastParams.new()
                    rayParams.FilterType = Enum.RaycastFilterType.Exclude
                    rayParams.FilterDescendantsInstances = {localPlayer.Character, state.floatPart}

                    local result = workspace:Raycast(root.Position, Vector3.new(0, -40, 0), rayParams)
                    if result then
                        state.floatPart.Position = Vector3.new(root.Position.X, result.Position.Y, root.Position.Z)
                    else
                        state.floatPart.Position = root.Position - Vector3.new(0, 3.5, 0)
                    end
                end
            end
        end)
        trackConnection(state.floatConnection)
    else
        lighting.GlobalShadows = true

        if state.boostConnection then
            state.boostConnection:Disconnect()
            state.boostConnection = nil
        end
        if state.floatConnection then
            state.floatConnection:Disconnect()
            state.floatConnection = nil
        end
        if state.floatPart then
            state.floatPart:Destroy()
            state.floatPart = nil
        end

        for part, data in pairs(state.originalPartStates) do
            if part and part.Parent then
                pcall(function()
                    part.CanCollide = data.CanCollide
                    part.Material = data.Material
                    part.CastShadow = data.CastShadow
                end)
            end
        end
        table.clear(state.originalPartStates)
    end
end

function jobModule.getNumericBalance()
    local success, balanceGui = pcall(function()
        return localPlayer.PlayerGui.MojavePlayerUI.JobBar.Money.Icon.balance
    end)
    if success and balanceGui and balanceGui:IsA("TextLabel") then
        local cleaned = balanceGui.Text:gsub("[^%d]", "")
        return tonumber(cleaned)
    end
    return nil
end

function jobModule.setJobState(state)
    jobModule.jobState.enabled = state
    if state then
        disableSeatsFolder()
        smoothTeleport(CFrame.new(1293, -102, -6274))
        jobModule.jobState.sessionStartTime = tick()
        jobModule.jobState.initialBalance = nil
        jobModule.jobState.totalEarned = 0
    end
end

function jobModule.start()
    trackConnection(runService.Heartbeat:Connect(function()
        if jobModule.jobState.enabled and localPlayer.Character then
            local hum = localPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Sit then
                hum.Sit = false
                hum.Jump = true
            end
        end
    end))

    task.spawn(function()
        local mojaveFolder = workspace:WaitForChild("Mojave", 5)
        local interactiveJobsFolder = mojaveFolder and mojaveFolder:WaitForChild("InteractiveJobs", 5)
        local peetsFolder = interactiveJobsFolder and interactiveJobsFolder:WaitForChild("Peets Coffee & Tea", 5)
        local interactiveFolder = peetsFolder and peetsFolder:WaitForChild("Interactive", 5)
        local npcsFolder = workspace:WaitForChild("NPCs", 5)

        if interactiveFolder then
            for _, desc in ipairs(interactiveFolder:GetDescendants()) do setupPrompt(desc) end
            trackConnection(interactiveFolder.DescendantAdded:Connect(setupPrompt))
        end

        local function applyNpcSpeed(obj)
            if obj:IsA("Humanoid") then
                obj.WalkSpeed = 200
            elseif obj:IsA("Model") then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 200 end
            end
        end

        if npcsFolder then
            for _, desc in ipairs(npcsFolder:GetDescendants()) do
                setupPrompt(desc)
                applyNpcSpeed(desc)
            end
            trackConnection(npcsFolder.DescendantAdded:Connect(function(d)
                setupPrompt(d)
                applyNpcSpeed(d)
            end))
        end

        local function doWorkHere()
            if not peetsFolder then return end
            local workHere = peetsFolder:FindFirstChild("WorkHere")
            if not workHere then return end

            local workPrompt = workHere:FindFirstChildWhichIsA("ProximityPrompt", true) or workHere:FindFirstChild("ProximityPrompt", true)
            if workPrompt then
                setupPrompt(workPrompt)
                local targetPart = getBasePart(workHere) or getBasePart(workPrompt.Parent)
                if targetPart then
                    smoothTeleport(targetPart.CFrame)
                    task.wait(0.15)
                    local startTime = tick()
                    while (tick() - startTime) < 0.4 and not jobModule.jobState.destroyed do
                        triggerPrompt(workPrompt)
                        task.wait(0.05)
                    end
                    task.wait(0.3)
                end
            end
        end

        while not jobModule.jobState.destroyed do
            if not jobModule.jobState.enabled then
                task.wait(0.3)
                continue
            end

            pcall(function()
                if not npcsFolder or not interactiveFolder then return end
                local character = localPlayer.Character
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                if not rootPart then return end

                local anyDisabled = false
                for _, desc in ipairs(interactiveFolder:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") and not desc.Enabled then
                        anyDisabled = true
                        break
                    end
                end
                if anyDisabled then doWorkHere() end

                local handPrompt = nil
                for _, desc in ipairs(npcsFolder:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") and desc.Name == "HandPrompt" and desc ~= jobModule.jobState.lastProcessedPrompt then
                        handPrompt = desc
                        break
                    end
                end

                if jobModule.jobState.lastProcessedPrompt and (not jobModule.jobState.lastProcessedPrompt.Parent or not npcsFolder:IsAncestorOf(jobModule.jobState.lastProcessedPrompt)) then
                    jobModule.jobState.lastProcessedPrompt = nil
                end

                if handPrompt then
                    setupPrompt(handPrompt)
                    local rawText = (handPrompt.ObjectText ~= "") and handPrompt.ObjectText or handPrompt.ActionText
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
                                setupPrompt(itemPrompt)
                                if not itemPrompt.Enabled then
                                    doWorkHere()
                                    task.wait(0.2)
                                end

                                local targetPart = getBasePart(itemPart) or getBasePart(itemPrompt.Parent)
                                if targetPart then
                                    smoothTeleport(targetPart.CFrame)
                                    task.wait(0.1)
                                end

                                local startTime = tick()
                                local tool = getTool(toolName)
                                while not tool and (tick() - startTime < 6) and not jobModule.jobState.destroyed and jobModule.jobState.enabled do
                                    if targetPart then rootPart.CFrame = targetPart.CFrame end
                                    triggerPrompt(itemPrompt)
                                    task.wait(0.25)
                                    tool = getTool(toolName)
                                end

                                equipOnlyTool(toolName)
                                task.wait(0.2)

                                if handPrompt and handPrompt.Parent then
                                    local npcPart = getBasePart(handPrompt.Parent)
                                    if npcPart then
                                        smoothTeleport(npcPart.CFrame)
                                        task.wait(0.1)
                                    end

                                    if handPrompt and handPrompt.Parent then
                                        triggerPrompt(handPrompt)
                                        local deliveryTime = tick()
                                        while getTool(toolName) and (tick() - deliveryTime < 3) and not jobModule.jobState.destroyed and jobModule.jobState.enabled do
                                            task.wait(0.15)
                                        end
                                        jobModule.jobState.lastProcessedPrompt = handPrompt
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

function jobModule.cleanup()
    jobModule.jobState.destroyed = true
    jobModule.jobState.enabled = false

    for _, conn in ipairs(jobModule.jobState.connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(jobModule.jobState.connections)

    if jobModule.jobState.floatPart then
        jobModule.jobState.floatPart:Destroy()
    end

    for part, data in pairs(jobModule.jobState.originalPartStates) do
        if part and part.Parent then
            pcall(function()
                part.CanCollide = data.CanCollide
                part.Material = data.Material
                part.CastShadow = data.CastShadow
            end)
        end
    end
    table.clear(jobModule.jobState.originalPartStates)
end

jobModule.start()

return jobModule
