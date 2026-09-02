-- @name: autojobModule
local jobModule = {}

--[=[
    Separated module for autofarming with GC Instant Patch. 
    Handles automatic tasks in Peets Coffee & Tea: tool fetching,
    replication-safe equipment, prompt interactions, and NPC deliveries.

    Authors:
        @vhb7 ........... Discord
        @ammoleking ..... Telegram
        @ammoleking.26 .. Signal

    Last Update: 
        2026-09-02
--]=]

local workspace = game:GetService("Workspace")
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local virtualInputManager = game:GetService("VirtualInputManager")
local lighting = game:GetService("Lighting")

local localPlayer = players.LocalPlayer

-- Active le Noclip Caméra
pcall(function()
    localPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
end)

-- ========================================================
-- 1. ULTIMATE INSTANT PATCH (GC MEMORY HOOKS)
-- ========================================================
local debug = debug
local getgc = getgc or filtergc
local PeetsModule, NPCHandlerModule

if getgc then
    pcall(function()
        for _, v in pairs(getgc(true)) do
            if type(v) == "table" then
                if rawget(v, "CustomerAdded") and rawget(v, "CreateLine") then
                    PeetsModule = v
                elseif rawget(v, "StartPatience") and rawget(v, "MoveTo") and rawget(v, "Speak") then
                    NPCHandlerModule = v
                end
            end
        end
    end)
end

if NPCHandlerModule then
    NPCHandlerModule.MoveTo = function(self, targetPos)
        if self.Destroyed or not self.Root then return false end
        self.Moving = true
        self.Root.CFrame = CFrame.new(targetPos) + Vector3.new(0, 2, 0)
        self.Moving = false
        return true
    end

    NPCHandlerModule.Speak = function(self, text)
        if self.Destroyed or not self.Model then return end
        local Head = self.Model:FindFirstChild("Head")
        if not Head then return end
        local NPCHeader = Head:FindFirstChild("NPCHeader")
        if not NPCHeader then return end
        local label = NPCHeader:FindFirstChildWhichIsA("TextLabel")
        if not label then return end

        label.RichText = true
        label.Text = text
    end
end

local function EquipItemForOrder(orderName)
    local character = localPlayer.Character
    local backpack = localPlayer:FindFirstChildOfClass("Backpack") or localPlayer:FindFirstChild("Backpack")
    
    if not character or not backpack then return nil end

    local currentTool = character:FindFirstChildOfClass("Tool")
    if currentTool and (currentTool.Name == orderName or string.find(currentTool.Name:lower(), orderName:lower())) then
        return currentTool
    end

    local targetTool = backpack:FindFirstChild(orderName)
    if not targetTool then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and string.find(item.Name:lower(), orderName:lower()) then
                targetTool = item
                break
            end
        end
    end

    if targetTool then
        targetTool.Parent = character
        
        local start = tick()
        repeat
            task.wait(0.05)
        until character:FindFirstChild(targetTool.Name) or (tick() - start) > 1
        
        task.wait(0.05)
        return targetTool
    end

    return nil
end

if PeetsModule then
    local success, err = pcall(function()
        local oldCustomerAdded = PeetsModule.CustomerAdded
        local upvs = debug.getupvalues(oldCustomerAdded)

        local Interactive = upvs[1]
        local t2 = upvs[2]
        local InteractiveJobFunc = upvs[4]
        local t3 = upvs[5]
        local InteractiveJob = upvs[6]

        PeetsModule.CustomerAdded = function(self, orderName)
            if not Interactive:FindFirstChild("spawnLocation") then return end

            if t2 and #t2 == 0 then
                self:CreateLine()
            end

            if not (t2 and t2[1]) then return end

            local npc = t2[1]
            local HandPrompt = npc.Model.HumanoidRootPart:FindFirstChild("HandPrompt")
            if not HandPrompt then
                HandPrompt = Instance.new("ProximityPrompt")
                HandPrompt.Name = "HandPrompt"
                HandPrompt.RequiresLineOfSight = false
                HandPrompt.ActionText = "Hand Order Over"
                HandPrompt.ObjectText = orderName
                HandPrompt.Style = Enum.ProximityPromptStyle.Default
                HandPrompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
                HandPrompt.HoldDuration = 0
                HandPrompt.MaxActivationDistance = 25
                HandPrompt.Enabled = true
                HandPrompt.Parent = npc.Model.HumanoidRootPart

                HandPrompt.TriggerEnded:Connect(function()
                    EquipItemForOrder(orderName)

                    local ok, errRes = InteractiveJobFunc:InvokeServer("Peets Coffee & Tea", "GaveOrder")
                    if ok then
                        HandPrompt.Enabled = false
                        npc:Speak("Thanks!")
                        npc:MoveTo(Interactive:WaitForChild("spawnLocation").Position)
                        for k, v in ipairs(t2) do
                            if v == npc then table.remove(t2, k) break end
                        end
                        npc:Destroy()
                        self:ReshuffleLine()
                    else
                        if errRes == "No Tool" then
                            npc:Speak("Um.. You are not holding anything, I would like a <font color=\"#FFD700\">" .. orderName .. "</font>")
                        elseif errRes == "Wrong Order" then
                            npc:Speak("Um.. Not my order, I would like a <font color=\"#FFD700\">" .. orderName .. "</font>")
                        end
                    end
                end)
            else
                HandPrompt.ObjectText = orderName
                HandPrompt.Enabled = true
            end

            npc:Speak("Hey, Can I please get a <font color=\"#FFD700\">" .. orderName .. "</font>")

            if not npc.Model:FindFirstChild("PatienceHooked") then
                local tag = Instance.new("BoolValue", npc.Model)
                tag.Name = "PatienceHooked"

                local conn
                conn = npc.OutOfPatience.Event:Connect(function()
                    if HandPrompt then HandPrompt.Enabled = false end
                    npc:Speak(t3.OutOfPatience[math.random(1, #t3.OutOfPatience)])
                    npc:MoveTo(Interactive:WaitForChild("spawnLocation").Position)
                    for k, v in ipairs(t2) do
                        if v == npc then table.remove(t2, k) break end
                    end
                    npc:Destroy()
                    task.spawn(function() self:ReshuffleLine() end)
                    InteractiveJob:FireServer("OutOfPatience", "Peets Coffee & Tea", orderName)
                    conn:Disconnect()
                end)
            end
        end

        _G.AutoDeliverPeetsOrder = function()
            if not t2 or not t2[1] then
                return false, "Aucun client à la caisse"
            end

            local currentNPC = t2[1]
            local hrp = currentNPC.Model and currentNPC.Model:FindFirstChild("HumanoidRootPart")
            local prompt = hrp and hrp:FindFirstChild("HandPrompt")

            if not prompt then
                return false, "HandPrompt non disponible"
            end

            local orderName = prompt.ObjectText
            local tool = EquipItemForOrder(orderName)
            if not tool then
                return false, "Outil manquant dans le Backpack : " .. tostring(orderName)
            end

            local ok, errRes = InteractiveJobFunc:InvokeServer("Peets Coffee & Tea", "GaveOrder")

            if ok then
                prompt.Enabled = false
                currentNPC:Speak("Thanks!")
                currentNPC:MoveTo(Interactive:WaitForChild("spawnLocation").Position)
                for k, v in ipairs(t2) do
                    if v == currentNPC then table.remove(t2, k) break end
                end
                currentNPC:Destroy()
                PeetsModule:ReshuffleLine()
                return true, "Commande livrée avec succès"
            else
                return false, "Erreur Serveur : " .. tostring(errRes)
            end
        end
    end)
end

-- ========================================================
-- 2. AUTOJOB MODULE ENGINE
-- ========================================================

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
        local mojave = workspace:FindFirstChild("Mojave")
        local seats = mojave and mojave:FindFirstChild("Seats")

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
            pcall(function() seats:Destroy() end)
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

local function instantTeleport(targetCFrame)
    local character = localPlayer.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- TP instantané DIRECTEMENT AU-DESSUS (Offset +3 Y)
    rootPart.CFrame = targetCFrame * CFrame.new(0, 3, 0)
end

local function setupPrompt(prompt)
    if prompt and prompt:IsA("ProximityPrompt") and jobModule.appSettings.promptOverride then
        pcall(function()
            prompt.HoldDuration = 0
            prompt.KeyboardKeyCode = Enum.KeyCode.E
            prompt.Style = Enum.ProximityPromptStyle.Default
            prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
            prompt.MaxActivationDistance = 4
            prompt.RequiresLineOfSight = false
        end)
    end
end

local function triggerPrompt(prompt)
    if not prompt or not prompt.Parent or not prompt.Enabled then return end

    setupPrompt(prompt)

    local character = localPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local parentPart = prompt.Parent:IsA("BasePart") and prompt.Parent or prompt.Parent:FindFirstChildWhichIsA("BasePart")

    if root and parentPart then
        root.CFrame = parentPart.CFrame * CFrame.new(0, 3, 0)
        task.wait(0.05)
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

        if state.boostConnection then state.boostConnection:Disconnect(); state.boostConnection = nil end
        if state.floatConnection then state.floatConnection:Disconnect(); state.floatConnection = nil end
        if state.floatPart then state.floatPart:Destroy(); state.floatPart = nil end

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
        instantTeleport(CFrame.new(1293, -102, -6274))
        jobModule.jobState.sessionStartTime = tick()
        jobModule.jobState.initialBalance = nil
        jobModule.jobState.totalEarned = 0
    end
end

function jobModule.start()
    trackConnection(runService.Heartbeat:Connect(function()
        if jobModule.jobState.enabled then
            pcall(function()
                localPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
            end)

            if localPlayer.Character then
                local hum = localPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Sit then
                    hum.Sit = false
                    hum.Jump = true
                end
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
                    instantTeleport(targetPart.CFrame)
                    task.wait(0.05)
                    triggerPrompt(workPrompt)
                    task.wait(0.1)
                end
            end
        end

        while not jobModule.jobState.destroyed do
            if not jobModule.jobState.enabled then
                task.wait(0.2)
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

                if rawget(_G, "AutoDeliverPeetsOrder") then
                    local delivered = _G.AutoDeliverPeetsOrder()
                    if delivered then
                        task.wait(0.1)
                        return
                    end
                end

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
                                    task.wait(0.1)
                                end

                                local targetPart = getBasePart(itemPart) or getBasePart(itemPrompt.Parent)
                                if targetPart then
                                    instantTeleport(targetPart.CFrame)
                                    task.wait(0.05)
                                end

                                local startTime = tick()
                                local tool = EquipItemForOrder(toolName)
                                while not tool and (tick() - startTime < 3) and not jobModule.jobState.destroyed and jobModule.jobState.enabled do
                                    triggerPrompt(itemPrompt)
                                    task.wait(0.1)
                                    tool = EquipItemForOrder(toolName)
                                end

                                if handPrompt and handPrompt.Parent then
                                    local npcPart = getBasePart(handPrompt.Parent)
                                    if npcPart then
                                        instantTeleport(npcPart.CFrame)
                                        task.wait(0.05)
                                    end

                                    if rawget(_G, "AutoDeliverPeetsOrder") then
                                        local delivered = _G.AutoDeliverPeetsOrder()
                                        if delivered then
                                            jobModule.jobState.lastProcessedPrompt = handPrompt
                                            task.wait(0.1)
                                            return
                                        end
                                    end

                                    if handPrompt and handPrompt.Parent then
                                        triggerPrompt(handPrompt)
                                        jobModule.jobState.lastProcessedPrompt = handPrompt
                                        task.wait(0.1)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            task.wait(0.15)
        end
    end)
end

function jobModule.cleanup()
    jobModule.jobState.destroyed = true
    jobModule.jobState.enabled = false

    pcall(function()
        localPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom
    end)

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
