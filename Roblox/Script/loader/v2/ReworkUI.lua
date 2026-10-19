-- Standalone UI V2.5 | For rework scripts
-- Directed by: Azuno

-- FEATURES:
--   - 3 themes (dark,black,light) + custom accent color, live switch
--   - Search bar (filter by label, click to jump)
--   - Persistence (save,load,reset via writefile,readfile)
--   - Components: Toggle, Slider, Button, LoadingButton, Bind, TextBox, Dropdown, ColorPicker, CollapsibleSection, Info, Section, Hero, Discord, QuickStart
--   - Error log + auto pcall on all callbacks
--   - Compact mode (hide sidebar)
--   - Keybind conflict detection
--   - Notification progress + close button
--   - Window:Destroy, Tab:Clear, Tab:Get
--
-- USAGE:
--   local UI = loadstring(game:HttpGet("URL"))()
--   UI:SetTheme("dark" | "black" | "light")   -- or pass a table
--   UI:SetAccent(Color3.fromRGB(120, 60, 255))
--   local W = UI:CreateWindow({Title="My Wolf Hub", Subtitle="v1.0"})
--   local T = W:CreateTab("Home", 107739421502217)
--   local tog = T:Toggle("Auto X", "desc", false, function(v) end, true, "auto_x")
--   tog:set(true); print(tog.v); print(T:Get("Auto X").v)
--   UI:SaveSettings(); UI:LoadSettings(); UI:ResetTheme()

-- Changelogs: Améliorer la responsive mobile, pour que les mobiles/ipad puissent correctement utiliser les slide bar, juste besoin de passer leurs doigts, et j'ai ajouté une barre de recherche également, avec 3 themes
-- Prochain: theme halloween, et fixé des bugs si certainne personne report un bug.

local Library = {}
Library.Version = "2.5.0"
Library.__index = Library
Library._errors = {}
Library._registry = {}
Library._shortcuts = {
    Toggle = Enum.KeyCode.RightShift,
}
Library._currentTheme = "dark"

Library.Defaults = {
    bg = Color3.fromRGB(12,12,14), sb = Color3.fromRGB(16,16,20), sf = Color3.fromRGB(22,22,26),
    hv = Color3.fromRGB(30,30,35), ln = Color3.fromRGB(35,35,42), tx = Color3.fromRGB(240,240,245),
    dm = Color3.fromRGB(140,140,150), d2 = Color3.fromRGB(95,95,108), ac = Color3.fromRGB(88,101,242),
    ag = Color3.fromRGB(120,132,255), ok = Color3.fromRGB(46,204,113), dg = Color3.fromRGB(231,76,60),
    wn = Color3.fromRGB(241,196,15),
}
Library.Config = {}
for k, v in pairs(Library.Defaults) do Library.Config[k] = v end
Library.Config.fontBold = Enum.Font.GothamBlack
Library.Config.fontMed = Enum.Font.GothamBold
Library.Config.soundClick = "6895079853"
Library.Config.soundHover = "6042053626"
Library.Config.soundOpen = "9125402735"
Library.Config.soundNote = "4590657391"
Library.Config.soundErr = "9120386436"

Library.Themes = {
    dark = {},
    black = {
        bg=Color3.fromRGB(0,0,0), sb=Color3.fromRGB(8,8,8), sf=Color3.fromRGB(14,14,14),
        hv=Color3.fromRGB(22,22,22), ln=Color3.fromRGB(28,28,28), tx=Color3.fromRGB(255,255,255),
        dm=Color3.fromRGB(160,160,160), d2=Color3.fromRGB(100,100,100),
    },
    light = {
        bg=Color3.fromRGB(245,245,248), sb=Color3.fromRGB(235,235,240), sf=Color3.fromRGB(255,255,255),
        hv=Color3.fromRGB(228,228,235), ln=Color3.fromRGB(210,210,220), tx=Color3.fromRGB(20,20,30),
        dm=Color3.fromRGB(90,90,110), d2=Color3.fromRGB(130,130,150),
        ok=Color3.fromRGB(30,180,90), dg=Color3.fromRGB(220,60,50), wn=Color3.fromRGB(220,170,20),
    },
}
for k, v in pairs(Library.Defaults) do Library.Themes.dark[k] = v end
Library.Themes.dark.ac = nil
Library.Themes.dark.ag = nil

local Pl = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local CG = game:GetService("CoreGui")
local SS = game:GetService("SoundService")
local DB = game:GetService("Debris")
local HS = game:GetService("HttpService")
local lp = Pl.LocalPlayer
local cam = workspace.CurrentCamera
repeat task.wait() cam = workspace.CurrentCamera until cam
local mob = UIS.TouchEnabled and not UIS.KeyboardEnabled

local themed = {}
local colorKeyMap = {}
local function rebuildColorKeyMap()
    colorKeyMap = {}
    for k, v in pairs(Library.Config) do
        if typeof(v) == "Color3" then colorKeyMap[v] = k end
    end
end
rebuildColorKeyMap()

local function mk(c, p, pa)
    local o = Instance.new(c)
    if o:IsA("GuiObject") then o.BorderSizePixel = 0 end
    for k, v in pairs(p or {}) do
        o[k] = v
        if typeof(v) == "Color3" then
            local key = colorKeyMap[v]
            if key then table.insert(themed, {inst=o, prop=k, key=key}) end
        end
    end
    if pa then o.Parent = pa end
    return o
end
local function rc(p, r) return mk("UICorner", {CornerRadius = UDim.new(0, r or 10)}, p) end
local function sk(p, c, t, tr) return mk("UIStroke", {Color = c or Library.Config.ln, Thickness = t or 1, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, p) end
local function gr(p, a, b, r)
    local g = mk("UIGradient", {Color = ColorSequence.new(a, b), Rotation = r or 0}, p)
    if typeof(a) == "Color3" and typeof(b) == "Color3" then
        local ka, kb = colorKeyMap[a], colorKeyMap[b]
        if ka and kb then
            table.insert(themed, {inst=g, prop="Color", key={a=ka, b=kb}, isGradient=true})
        elseif kb then
            table.insert(themed, {inst=g, prop="Color", key={a=a, b=kb}, isGradient=true, fixedA=true})
        end
    end
    return g
end
local function ti(t) return TweenInfo.new(t or .2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out) end
local function tw(o, t, p) if o and o.Parent then local a = TS:Create(o, ti(t), p); a:Play(); return a end end
local function sn(id, v) local s = mk("Sound", {SoundId = "rbxassetid://" .. tostring(id), Volume = v or .3}, SS); s:Play(); DB:AddItem(s, 3) end
local function rn()
    local c = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local s = ""
    for _ = 1, math.random(4, 8) do local i = math.random(1, 62); s = s .. c:sub(i, i) end
    return s
end

local function logError(ctx, err)
    table.insert(Library._errors, {time = os.time(), ctx = ctx, err = tostring(err)})
    if #Library._errors > 50 then table.remove(Library._errors, 1) end
    pcall(function() warn("[NinjaUI/" .. ctx .. "] " .. tostring(err)) end)
end

local function applyThemeAll()
    for _, e in ipairs(themed) do
        if e.inst and e.inst.Parent then
            if e.isGradient then
                local a = e.fixedA and e.key.a or Library.Config[e.key.a]
                local b = Library.Config[e.key.b]
                pcall(function() e.inst.Color = ColorSequence.new(a, b) end)
            else
                pcall(function() e.inst[e.prop] = Library.Config[e.key] end)
            end
        end
    end
end

function Library:SetTheme(theme)
    if type(theme) == "string" then
        local name = theme
        theme = Library.Themes[name]
        if not theme then return false end
        Library._currentTheme = name
    elseif type(theme) == "table" then
        Library._currentTheme = "custom"
    else
        return false
    end
    for k, v in pairs(theme) do
        if typeof(v) == "Color3" and Library.Config[k] then Library.Config[k] = v end
    end
    rebuildColorKeyMap()
    applyThemeAll()
    return true
end

function Library:ResetTheme()
    for k, v in pairs(Library.Defaults) do Library.Config[k] = v end
    rebuildColorKeyMap()
    applyThemeAll()
    return true
end

function Library:SetAccent(color)
    if typeof(color) ~= "Color3" then return false end
    Library.Config.ac = color
    Library.Config.ag = Color3.new(
        math.min(1, color.R * 1.25 + .08),
        math.min(1, color.G * 1.25 + .08),
        math.min(1, color.B * 1.25 + .08)
    )
    rebuildColorKeyMap()
    applyThemeAll()
    return true
end

function Library:GetErrorLog() return Library._errors end
function Library:ClearErrorLog() Library._errors = {} end

local persistPath = "NinjaUI/config.json"
local function canPersist() return writefile and readfile and isfile and isfolder and makefolder end

function Library:SaveSettings()
    if not canPersist() then return false, "persistence not supported by executor" end
    local data = {}
    for id, h in pairs(Library._registry) do
        if h and h._serialize then
            local ok, v = pcall(h._serialize, h)
            if ok and v ~= nil then data[id] = v end
        end
    end
    local ok, err = pcall(function()
        if not isfolder("NinjaUI") then makefolder("NinjaUI") end
        writefile(persistPath, HS:JSONEncode(data))
    end)
    if not ok then logError("SaveSettings", err); return false, err end
    return true
end

function Library:LoadSettings()
    if not canPersist() then return false, "persistence not supported" end
    if not isfile(persistPath) then return false, "no saved config" end
    local ok, data = pcall(function() return HS:JSONDecode(readfile(persistPath)) end)
    if not ok or type(data) ~= "table" then return false, "parse error" end
    for id, v in pairs(data) do
        local h = Library._registry[id]
        if h and h._deserialize then pcall(h._deserialize, h, v) end
    end
    return true
end

function Library:ResetSettings()
    for _, h in pairs(Library._registry) do
        if h and h._reset then pcall(h._reset, h) end
    end
    return true
end

local TabMethods = {}
TabMethods.__index = TabMethods

function Library:CreateWindow(cfg)
    cfg = cfg or {}
    local K = Library.Config
    local opts = {
        Title = cfg.Title or "UI",
        Subtitle = cfg.Subtitle or "",
        LoadingTitle = cfg.LoadingTitle or (cfg.Title or "UI"),
        LoadingSteps = cfg.LoadingSteps or {
            {"Loading modules.", .3}, {"Syncing Remotes..", .55},
            {"Building Interface...", .82}, {"READY", 1}
        },
        ShowFloatingButton = cfg.ShowFloatingButton ~= false,
        FloatingButtonText = cfg.FloatingButtonText or "N",
        Keybind = cfg.Keybind or Library._shortcuts.Toggle,
        SearchEnabled = cfg.SearchEnabled ~= false,
        PersistId = cfg.PersistId or tostring(game.PlaceId),
    }

    local conns = {}
    local function Connect(sig, fn) local c = sig:Connect(fn); table.insert(conns, c); return c end

    local gui = mk("ScreenGui", {Name = rn(), ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 2147483647, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
    if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end
    gui.Parent = CG:FindFirstChild("RobloxGui") or CG

    local nh = mk("Frame", {AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(.5, 0, 0, 14), Size = UDim2.new(0, mob and 280 or 360, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 100, Parent = gui})
    mk("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8)}, nh)

    local function ntf(t, c, d, k)
        sn(k == "err" and K.soundErr or K.soundNote, .25)
        local col = k == "err" and K.dg or (k == "warn" and K.wn or K.ac)
        local f = mk("Frame", {Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = K.sf, BackgroundTransparency = 1, Parent = nh})
        rc(f, 10)
        local s = sk(f, col, 1, 1)
        local b = mk("Frame", {Size = UDim2.new(0, 4, 1, -16), Position = UDim2.new(0, 10, 0, 8), BackgroundColor3 = col, BackgroundTransparency = 1, Parent = f})
        rc(b, 4)
        local t1 = mk("TextLabel", {Size = UDim2.new(1, -60, 0, 18), Position = UDim2.new(0, 22, 0, 8), BackgroundTransparency = 1, Text = t or "", TextColor3 = K.tx, Font = K.fontBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, Parent = f})
        local d1 = mk("TextLabel", {Size = UDim2.new(1, -60, 0, 18), Position = UDim2.new(0, 22, 0, 26), BackgroundTransparency = 1, Text = c or "", TextColor3 = K.dm, Font = K.fontMed, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, TextTransparency = 1, Parent = f})
        local prog = mk("Frame", {Size = UDim2.new(1, -8, 0, 2), Position = UDim2.new(0, 4, 1, -6), BackgroundColor3 = col, BackgroundTransparency = .7, Parent = f})
        rc(prog, 1)
        local closeBtn = mk("TextButton", {Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -26, 0, 6), BackgroundColor3 = K.sf, Text = "×", TextColor3 = K.dm, Font = K.fontBold, TextSize = 12, AutoButtonColor = false, Parent = f})
        rc(closeBtn, 4)
        local dur = d or 4
        local function dismiss()
            if not f.Parent then return end
            tw(f, .2, {BackgroundTransparency = 1})
            tw(s, .2, {Transparency = 1}); tw(b, .2, {BackgroundTransparency = 1})
            tw(t1, .2, {TextTransparency = 1}); tw(d1, .2, {TextTransparency = 1})
            tw(prog, .2, {BackgroundTransparency = 1}); tw(closeBtn, .2, {BackgroundTransparency = 1, TextTransparency = 1})
            task.delay(.25, function() f:Destroy() end)
        end
        closeBtn.MouseButton1Click:Connect(dismiss)
        tw(f, .3, {BackgroundTransparency = 0}); tw(s, .3, {Transparency = 0}); tw(b, .3, {BackgroundTransparency = 0})
        tw(t1, .3, {TextTransparency = 0}); tw(d1, .3, {TextTransparency = 0})
        tw(prog, dur, {Size = UDim2.new(0, 0, 0, 2)})
        task.delay(dur, dismiss)
    end

    local win = mk("Frame", {AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(.5, 0, .5, 0), Size = UDim2.new(0, 640, 0, 420), BackgroundColor3 = K.bg, Visible = false, ZIndex = 5, Parent = gui})
    rc(win, 12); sk(win, K.ln, 1)
    local us = mk("UIScale", {Scale = 1}, win)
    local side = mk("Frame", {Size = UDim2.new(0, 150, 1, 0), BackgroundColor3 = K.sb, Parent = win})
    rc(side, 12)
    mk("Frame", {Size = UDim2.new(0, 12, 1, 0), Position = UDim2.new(1, -12, 0, 0), BackgroundColor3 = K.sb, Parent = side})
    local cont = mk("Frame", {Size = UDim2.new(1, -150, 1, 0), Position = UDim2.new(0, 150, 0, 0), BackgroundTransparency = 1, Parent = win})

    -- loading screen
    local ld = mk("Frame", {AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(.5, 0, .5, 0), Size = UDim2.new(0, 300, 0, 116), BackgroundColor3 = K.sb, ZIndex = 10, Parent = gui})
    rc(ld, 12); sk(ld, K.ln, 1)
    local ldt = mk("TextLabel", {Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 0, 18), BackgroundTransparency = 1, Text = opts.LoadingTitle, TextColor3 = K.tx, Font = K.fontBold, TextSize = 20, ZIndex = 10, Parent = ld})
    local lst = mk("TextLabel", {Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 0, 48), BackgroundTransparency = 1, Text = "loading", TextColor3 = K.dm, Font = K.fontMed, TextSize = 11, ZIndex = 10, Parent = ld})
    local lbg = mk("Frame", {Size = UDim2.new(1, -50, 0, 4), Position = UDim2.new(0, 25, 1, -30), BackgroundColor3 = K.ln, ZIndex = 10, Parent = ld})
    rc(lbg, 2)
    local lfl = mk("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = K.ac, ZIndex = 10, Parent = lbg})
    rc(lfl, 2); gr(lfl, K.ac, K.ag, 0)

    -- recherche + nav
    local brand = mk("Frame", {Size = UDim2.new(1, 0, 0, 66), BackgroundTransparency = 1, Parent = side})
    mk("TextLabel", {Size = UDim2.new(1, -24, 0, 22), Position = UDim2.new(0, 14, 0, 16), BackgroundTransparency = 1, Text = opts.Title, TextColor3 = K.tx, Font = K.fontBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, TextScaled = true, Parent = brand})
    if opts.Subtitle ~= "" then
        mk("TextLabel", {Size = UDim2.new(1, -24, 0, 14), Position = UDim2.new(0, 14, 0, 40), BackgroundTransparency = 1, Text = opts.Subtitle, TextColor3 = K.ac, Font = K.fontMed, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = brand})
    end

    local srchInp
    local windowEls = {}
    local navOffset = 74
    local navSizeOffset = -80

    if opts.SearchEnabled then
        local sb = mk("Frame", {Size = UDim2.new(1, -20, 0, 24), Position = UDim2.new(0, 10, 0, 68), BackgroundColor3 = K.sf, Parent = side})
        rc(sb, 6); sk(sb, K.ln, 1)
        mk("ImageLabel", {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 8, .5, -6), BackgroundTransparency = 1, Image = "rbxassetid://9608131918", ImageColor3 = K.dm, Parent = sb})
        srchInp = mk("TextBox", {Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 26, 0, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "Search", PlaceholderColor3 = K.dm, TextColor3 = K.tx, Font = K.fontMed, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = sb})
        navOffset = 100
        navSizeOffset = -106
    end

    local nav = mk("Frame", {Size = UDim2.new(1, -20, 1, navSizeOffset), Position = UDim2.new(0, 10, 0, navOffset), BackgroundTransparency = 1, Parent = side})
    mk("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)}, nav)

    local isVis, isReady, isCompact = false, false, false
    local dg, dsp, sp
    Connect(brand.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dg = true; dsp = i.Position; sp = win.Position
        end
    end)
    Connect(UIS.InputChanged, function(i)
        if dg and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = (i.Position - dsp) / us.Scale
            win.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
    Connect(UIS.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dg = false end
    end)

    local tgt, sw = 1, 150
    local function lay()
        local v = cam.ViewportSize
        local po = v.X < v.Y
        if isCompact then
            win.Size = UDim2.new(0, math.min(v.X - 16, 460), 0, math.min(v.Y - 80, 460))
            tgt = math.clamp(math.min((v.X - 16) / 460, 1), .5, 1)
            side.Size = UDim2.new(0, 0, 1, 0)
            cont.Position = UDim2.new(0, 0, 0, 0)
            cont.Size = UDim2.new(1, 0, 1, 0)
        else
            sw = po and 118 or 150
            if po then
                win.Size = UDim2.new(0, math.min(v.X - 16, 520), 0, math.min(v.Y - 80, 460))
                tgt = math.clamp(math.min((v.X - 16) / math.min(v.X - 16, 520), 1), .5, 1)
            else
                win.Size = UDim2.new(0, 640, 0, 420)
                tgt = math.clamp(math.min((v.X - 24) / 640, (v.Y - 24) / 420), .4, 1)
            end
            side.Size = UDim2.new(0, sw, 1, 0)
            cont.Position = UDim2.new(0, sw, 0, 0)
            cont.Size = UDim2.new(1, -sw, 1, 0)
        end
        if isVis then us.Scale = tgt end
    end
    lay()
    Connect(cam:GetPropertyChangedSignal("ViewportSize"), lay)

    local tbs, cur = {}, nil
    local function pk(o)
        for _, d in ipairs(tbs) do
            local on_ = d.o == o
            d.pg.Visible = on_
            tw(d.b, .2, {BackgroundTransparency = on_ and 0 or 1})
            tw(d.l, .2, {TextColor3 = on_ and K.tx or K.dm})
            tw(d.i, .2, {ImageColor3 = on_ and K.ac or K.dm})
        end
        cur = o
    end

    local function hf(c, f, a)
        c.MouseEnter:Connect(function()
            sn(K.soundHover, .1)
            tw(f, .15, {BackgroundColor3 = K.hv})
            if a then tw(a, .15, {TextColor3 = K.ag}) end
        end)
        c.MouseLeave:Connect(function()
            tw(f, .15, {BackgroundColor3 = K.sf})
            if a then tw(a, .15, {TextColor3 = K.dm}) end
        end)
    end

    local function tab(nm, icn, order)
        local pg = mk("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
            ScrollBarThickness = 4, ScrollBarImageColor3 = K.ac,
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingEnabled = true, ScrollingDirection = Enum.ScrollingDirection.Y,
            ElasticBehavior = Enum.ElasticBehavior.WhenScrollable, Visible = false, Parent = cont
        })
        mk("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)}, pg)
        mk("UIPadding", {PaddingTop = UDim.new(0, 52), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 20), PaddingBottom = UDim.new(0, 18)}, pg)
        local b = mk("TextButton", {Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = K.hv, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = order or 1, Parent = nav})
        rc(b, 8)
        local i = mk("ImageLabel", {Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 12, .5, -8), BackgroundTransparency = 1, Image = "rbxassetid://" .. tostring(icn or 0), ImageColor3 = K.dm, Parent = b})
        local l = mk("TextLabel", {Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 36, 0, 0), BackgroundTransparency = 1, Text = nm, TextColor3 = K.dm, Font = K.fontMed, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = b})
        local o = setmetatable({pg = pg, n = 0, _name = nm, _handles = {}, _activeSection = nil, _id = nm}, TabMethods)

        function o:_nx() self.n = self.n + 1; return self.n end

        function o:_row(h, label)
            local f = mk("Frame", {Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = K.sf, LayoutOrder = self:_nx(), Parent = self.pg})
            rc(f, 10); sk(f, K.ln, 1)
            if label then table.insert(windowEls, {tab = self, frame = f, label = label}) end
            if self._activeSection then
                if not self._activeSection.open then f.Visible = false end
                table.insert(self._activeSection.children, f)
            end
            return f
        end

        function o:Get(label) return self._handles[label] end

        function o:Clear()
            for _, c in ipairs(self.pg:GetChildren()) do
                if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
            end
            self.n = 0; self._handles = {}; self._activeSection = nil
        end

        function o:Section(t)
            self._activeSection = nil
            local f = mk("Frame", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = self:_nx(), Parent = self.pg})
            mk("TextLabel", {Size = UDim2.new(1, -4, 1, 0), BackgroundTransparency = 1, Text = string.upper(t), TextColor3 = K.dm, Font = K.fontBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, Parent = f})
        end

        function o:CollapsibleSection(t, defaultOpen)
            self._activeSection = nil
            local open = defaultOpen ~= false
            local children = {}
            local f = self:_row(30)
            local chevron = mk("TextLabel", {Size = UDim2.new(0, 16, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, Text = open and "▼" or "▶", TextColor3 = K.dm, Font = K.fontBold, TextSize = 10, Parent = f})
            mk("TextLabel", {Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 34, 0, 0), BackgroundTransparency = 1, Text = string.upper(t), TextColor3 = K.tx, Font = K.fontBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = f})
            local click = mk("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = f})
            local section = {open = open, children = children}
            local function setOpen(v)
                open = v; section.open = v
                chevron.Text = v and "▼" or "▶"
                for _, child in ipairs(children) do if child and child.Parent then child.Visible = v end end
            end
            click.MouseButton1Click:Connect(function()
                sn(K.soundClick, .3); setOpen(not open)
            end)
            self._activeSection = section
            return {open = section, set = function(_, v) setOpen(v) end}
        end

        function o:Info(t)
            local f = mk("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = K.sf, LayoutOrder = self:_nx(), Parent = self.pg})
            rc(f, 10); sk(f, K.ln, 1)
            mk("UIPadding", {PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16), Parent = f})
            if self._activeSection then
                if not self._activeSection.open then f.Visible = false end
                table.insert(self._activeSection.children, f)
            end
            return mk("TextLabel", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = t, TextColor3 = K.tx, Font = K.fontMed, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = f})
        end

        function o:Button(t, cb)
            local f = self:_row(44, t)
            local c = mk("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = f})
            mk("TextLabel", {Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 18, 0, 0), BackgroundTransparency = 1, Text = t, TextColor3 = K.tx, Font = K.fontBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = f})
            local a = mk("TextLabel", {Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -30, 0, 0), BackgroundTransparency = 1, Text = ">", TextColor3 = K.dm, Font = K.fontBold, TextSize = 14, Parent = f})
            hf(c, f, a)
            c.MouseButton1Click:Connect(function()
                sn(K.soundClick, .3)
                if cb then
                    local ok, e = pcall(cb)
                    if not ok then logError("Button/" .. t, e); ntf("error", tostring(e), 5, "err") end
                end
            end)
        end

        function o:LoadingButton(t, cb)
            local f = self:_row(44, t)
            local c = mk("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = f})
            local lbl = mk("TextLabel", {Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 18, 0, 0), BackgroundTransparency = 1, Text = t, TextColor3 = K.tx, Font = K.fontBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = f})
            local a = mk("TextLabel", {Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -30, 0, 0), BackgroundTransparency = 1, Text = ">", TextColor3 = K.dm, Font = K.fontBold, TextSize = 14, Parent = f})
            hf(c, f, a)
            local busy = false
            c.MouseButton1Click:Connect(function()
                if busy then return end
                busy = true; sn(K.soundClick, .3)
                lbl.Text = "Loading..."; lbl.TextColor3 = K.wn; a.Text = "..."
                task.spawn(function()
                    local ok, e = pcall(cb)
                    if not ok then logError("LoadingButton/" .. t, e); ntf("error", tostring(e), 5, "err") end
                    lbl.Text = t; lbl.TextColor3 = K.tx; a.Text = ">"
                    busy = false
                end)
            end)
        end

        function o:Toggle(t, d, v, cb, hot, id)
            local hasDesc = d and d ~= ""
            local f = self:_row(hasDesc and 56 or 44, t)
            local c = mk("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = f})
            local ttl = mk("TextLabel", {Size = UDim2.new(1, -96, 0, 18), Position = UDim2.new(0, 18, 0, hasDesc and 10 or 13), BackgroundTransparency = 1, Text = t, TextColor3 = K.tx, Font = K.fontBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = f})
            if hasDesc then
                mk("TextLabel", {Size = UDim2.new(1, -96, 0, 14), Position = UDim2.new(0, 18, 0, 30), BackgroundTransparency = 1, Text = d, TextColor3 = K.dm, Font = K.fontMed, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = f})
            end
            local swt = mk("Frame", {Size = UDim2.new(0, 42, 0, 24), Position = UDim2.new(1, -58, .5, -12), BackgroundColor3 = v and K.ac or K.ln, Parent = f})
            rc(swt, 12)
            local kn = mk("Frame", {Size = UDim2.new(0, 18, 0, 18), Position = v and UDim2.new(0, 21, .5, -9) or UDim2.new(0, 3, .5, -9), BackgroundColor3 = Color3.new(1, 1, 1), Parent = swt})
            rc(kn, 9); hf(c, f)
            local h = {v = v, frame = f, label = ttl, swt = swt, _default = v}
            local function ap(x, q)
                h.v = x
                tw(swt, .22, {BackgroundColor3 = x and K.ac or K.ln})
                tw(kn, .22, {Position = x and UDim2.new(0, 21, .5, -9) or UDim2.new(0, 3, .5, -9)})
                if q then sn(K.soundClick, .3) end
                if cb then
                    local ok, e = pcall(cb, x)
                    if not ok then logError("Toggle/" .. t, e); ntf("error", tostring(e), 5, "err") end
                end
            end
            c.MouseButton1Click:Connect(function() ap(not h.v, true) end)
            function h.set(_, x) if x ~= h.v then ap(x, false) end end
            function h.get(_) return h.v end
            h._serialize = function() return h.v end
            h._deserialize = function(val) if type(val) == "boolean" then ap(val, false) end end
            h._reset = function() ap(h._default, false) end
            if hot then
                local row = mk("Frame", {Size = UDim2.new(1, -96, 0, 18), Position = UDim2.new(0, 18, 0, hasDesc and 10 or 13), BackgroundTransparency = 1, Parent = f})
                mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = row})
                ttl.Size = UDim2.new(0, 0, 1, 0); ttl.AutomaticSize = Enum.AutomaticSize.X
                ttl.Position = UDim2.new(0, 0, 0, 0); ttl.LayoutOrder = 1; ttl.Parent = row
                local badge = mk("Frame", {Size = UDim2.new(0, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Color3.fromRGB(255, 90, 30), LayoutOrder = 2, Parent = row})
                rc(badge, 9)
                gr(badge, Color3.fromRGB(255, 130, 45), Color3.fromRGB(190, 35, 10), 90)
                sk(badge, Color3.fromRGB(255, 150, 70), 1, .35)
                mk("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 8), Parent = badge})
                mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center, Parent = badge})
                local flame = mk("ImageLabel", {Size = UDim2.new(0, 12, 0, 12), BackgroundTransparency = 1, Image = "rbxassetid://100500296638402", ImageColor3 = Color3.fromRGB(255, 220, 120), LayoutOrder = 1, Parent = badge})
                mk("TextLabel", {Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = "HOT", TextColor3 = Color3.fromRGB(255, 248, 240), Font = K.fontBold, TextSize = 9, LayoutOrder = 2, Parent = badge})
                task.spawn(function()
                    while flame.Parent do
                        tw(flame, .55, {Rotation = 10}); task.wait(.55)
                        tw(flame, .55, {Rotation = -10}); task.wait(.55)
                    end
                end)
            end
            local pid = opts.PersistId .. "/" .. (id or t)
            Library._registry[pid] = h
            h._id = pid
            self._handles[t] = h
            return h
        end

        function o:Slider(t, mn, mx, v, cb, inc, id)
            local f = self:_row(58, t)
            mk("TextLabel", {Size = UDim2.new(1, -100, 0, 18), Position = UDim2.new(0, 18, 0, 8), BackgroundTransparency = 1, Text = t, TextColor3 = K.tx, Font = K.fontBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = f})
            local vl = mk("TextLabel", {Size = UDim2.new(0, 80, 0, 18), Position = UDim2.new(1, -98, 0, 8), BackgroundTransparency = 1, Text = tostring(v), TextColor3 = K.ac, Font = K.fontBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, Parent = f})
            local tr = mk("Frame", {Size = UDim2.new(1, -36, 0, 6), Position = UDim2.new(0, 18, 0, 38), BackgroundColor3 = K.ln, Parent = f})
            rc(tr, 3)
            local fl = mk("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = K.ac, Parent = tr}); rc(fl, 3)
            local kn = mk("Frame", {Size = UDim2.new(0, 12, 0, 12), AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(0, 0, .5, 0), BackgroundColor3 = Color3.new(1, 1, 1), Parent = tr}); rc(kn, 6)
            local hit = mk("TextButton", {Size = UDim2.new(1, -36, 0, 18), Position = UDim2.new(0, 18, 0, 30), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = f})
            hf(hit, f)
            local h = {v = v, _default = v}
            local function ap(px, q)
                px = math.clamp(px, 0, 1)
                local val = mn + (mx - mn) * px
                if inc then val = math.floor(val / inc + .5) * inc end
                h.v = val
                fl.Size = UDim2.new(px, 0, 1, 0); kn.Position = UDim2.new(px, 0, .5, 0)
                vl.Text = string.format("%g", val)
                if q and cb then
                    local ok, e = pcall(cb, val)
                    if not ok then logError("Slider/" .. t, e); ntf("error", tostring(e), 5, "err") end
                end
            end
            local dr = false
            local function fx(x) return (x - tr.AbsolutePosition.X) / tr.AbsoluteSize.X end
            hit.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    dr = true; ap(fx(i.Position.X), true)
                end
            end)
            Connect(UIS.InputChanged, function(i)
                if dr and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                    ap(fx(i.Position.X), true)
                end
            end)
            Connect(UIS.InputEnded, function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dr = false end
            end)
            ap((v - mn) / (mx - mn), false)
            function h.set(_, x) ap((x - mn) / (mx - mn), true) end
            function h.get(_) return h.v end
            h._serialize = function() return h.v end
            h._deserialize = function(val)
                if type(val) == "number" then ap((math.clamp(val, mn, mx) - mn) / (mx - mn), false) end
            end
            h._reset = function() ap((h._default - mn) / (mx - mn), false) end
            local pid = opts.PersistId .. "/" .. (id or t)
            Library._registry[pid] = h
            h._id = pid
            self._handles[t] = h
            return h
        end

        function o:Bind(t, cb, dk, id)
            local f = self:_row(44, t)
            local c = mk("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = f})
            mk("TextLabel", {Size = UDim2.new(1, -130, 1, 0), Position = UDim2.new(0, 18, 0, 0), BackgroundTransparency = 1, Text = t, TextColor3 = K.tx, Font = K.fontBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = f})
            local kb = mk("TextButton", {Size = UDim2.new(0, 96, 0, 24), Position = UDim2.new(1, -110, .5, -12), BackgroundColor3 = K.sb, Text = dk and dk.Name or "NONE", TextColor3 = K.ac, Font = K.fontBold, TextSize = 11, AutoButtonColor = false, ZIndex = 3, Parent = f})
            rc(kb, 6); sk(kb, K.ln, 1); hf(c, f)
            local h = {k = dk, _default = dk, v = dk, name = t}
            local lis = false
            local function setKey(newKey, announce)
                if newKey == h.k then return end
                if newKey and Library._bindRegistry and Library._bindRegistry[newKey] and Library._bindRegistry[newKey] ~= h then
                    ntf("Bind conflict", newKey.Name .. " already bound to: " .. (Library._bindRegistry[newKey].name or "?"), 4, "warn")
                    return
                end
                if h.k and Library._bindRegistry then Library._bindRegistry[h.k] = nil end
                h.k = newKey
                h.v = newKey
                if h.k and Library._bindRegistry then Library._bindRegistry[h.k] = h end
                kb.Text = h.k and h.k.Name or "NONE"
                kb.TextColor3 = K.ac
                if announce then ntf("Bind", t .. " -> " .. (h.k and h.k.Name or "NONE"), 3, "ok") end
            end
            c.MouseButton1Click:Connect(function()
                sn(K.soundClick, .3)
                if cb then
                    local ok, e = pcall(cb)
                    if not ok then logError("Bind/" .. t, e); ntf("error", tostring(e), 5, "err") end
                end
            end)
            kb.MouseButton1Click:Connect(function() lis = true; kb.Text = "press key"; kb.TextColor3 = K.wn end)
            Connect(UIS.InputBegan, function(i, p)
                if lis then
                    if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
                    lis = false
                    setKey(i.KeyCode == Enum.KeyCode.Escape and nil or i.KeyCode, false)
                    return
                end
                if not p and h.k and i.KeyCode == h.k and isReady and cb then
                    local ok, e = pcall(cb)
                    if not ok then logError("Bind/" .. t, e); ntf("error", tostring(e), 5, "err") end
                end
            end)
            Library._bindRegistry = Library._bindRegistry or {}
            if h.k then Library._bindRegistry[h.k] = h end
            h._serialize = function() return h.k and h.k.Name or nil end
            h._deserialize = function(val)
                if type(val) == "string" then
                    local ok, key = pcall(function() return Enum.KeyCode[val] end)
                    if ok and key then setKey(key, false) end
                end
            end
            h._reset = function() setKey(h._default, false) end
            local pid = opts.PersistId .. "/" .. (id or t)
            Library._registry[pid] = h
            h._id = pid
            self._handles[t] = h
            return h
        end

        function o:TextBox(t, ph, cb, id)
            local f = self:_row(58, t)
            mk("TextLabel", {Size = UDim2.new(1, -36, 0, 18), Position = UDim2.new(0, 18, 0, 8), BackgroundTransparency = 1, Text = t, TextColor3 = K.tx, Font = K.fontBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = f})
            local tb = mk("TextBox", {Size = UDim2.new(1, -36, 0, 26), Position = UDim2.new(0, 18, 0, 28), BackgroundColor3 = K.sb, Text = "", PlaceholderText = ph or "", PlaceholderColor3 = K.dm, TextColor3 = K.tx, Font = K.fontMed, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = f})
            rc(tb, 6); sk(tb, K.ln, 1)
            mk("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = tb})
            local h = {v = "", _default = ""}
            tb.FocusLost:Connect(function(enter)
                h.v = tb.Text
                if enter and cb then
                    local ok, e = pcall(cb, tb.Text)
                    if not ok then logError("TextBox/" .. t, e); ntf("error", tostring(e), 5, "err") end
                end
            end)
            tb:GetPropertyChangedSignal("Text"):Connect(function() h.v = tb.Text end)
            function h.get(_) return h.v end
            h._serialize = function() return h.v end
            h._deserialize = function(val) if type(val) == "string" then tb.Text = val; h.v = val end end
            h._reset = function() tb.Text = h._default; h.v = h._default end
            local pid = opts.PersistId .. "/" .. (id or t)
            Library._registry[pid] = h; h._id = pid
            self._handles[t] = h
            return h
        end

        function o:Dropdown(t, options, default, cb, id)
            options = options or {}
            local current = default or options[1] or ""
            local f = self:_row(44, t)
            local c = mk("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = f})
            mk("TextLabel", {Size = UDim2.new(1, -140, 1, 0), Position = UDim2.new(0, 18, 0, 0), BackgroundTransparency = 1, Text = t, TextColor3 = K.tx, Font = K.fontBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = f})
            local dd = mk("TextButton", {Size = UDim2.new(0, 120, 0, 26), Position = UDim2.new(1, -134, .5, -13), BackgroundColor3 = K.sb, Text = current .. "  ▾", TextColor3 = K.ac, Font = K.fontBold, TextSize = 11, AutoButtonColor = false, ZIndex = 3, Parent = f})
            rc(dd, 6); sk(dd, K.ln, 1); hf(c, f)
            local h = {v = current, _default = current, options = options}
            local menu = mk("Frame", {Size = UDim2.new(0, 120, 0, 0), Position = UDim2.new(0, 0, 1, 2), BackgroundColor3 = K.sb, Visible = false, ZIndex = 100, Parent = dd})
            rc(menu, 6); sk(menu, K.ac, 1, .3)
            local function buildMenu()
                for _, ch in ipairs(menu:GetChildren()) do
                    if ch:IsA("TextButton") or ch:IsA("UIListLayout") or ch:IsA("UIPadding") then ch:Destroy() end
                end
                mk("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2)}, menu)
                mk("UIPadding", {PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = menu})
                for i, opt in ipairs(options) do
                    local b = mk("TextButton", {Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = K.bg, BackgroundTransparency = .3, Text = "", AutoButtonColor = false, LayoutOrder = i, Parent = menu})
                    rc(b, 4)
                    local lbl = mk("TextLabel", {Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, Text = tostring(opt), TextColor3 = K.tx, Font = K.fontMed, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = b})
                    b.MouseEnter:Connect(function() b.BackgroundTransparency = 0; lbl.TextColor3 = K.ag end)
                    b.MouseLeave:Connect(function() b.BackgroundTransparency = .3; lbl.TextColor3 = K.tx end)
                    b.MouseButton1Click:Connect(function()
                        h.v = opt
                        dd.Text = tostring(opt) .. "  ▾"
                        menu.Visible = false
                        if cb then
                            local ok, e = pcall(cb, opt)
                            if not ok then logError("Dropdown/" .. t, e); ntf("error", tostring(e), 5, "err") end
                        end
                    end)
                end
                menu.Size = UDim2.new(0, 120, 0, math.min(#options * 26 + 8, 200))
            end
            buildMenu()
            local open = false
            dd.MouseButton1Click:Connect(function()
                open = not open
                menu.Visible = open
                sn(K.soundClick, .3)
            end)
            function h.get(_) return h.v end
            function h.set(_, val) h.v = val; dd.Text = tostring(val) .. "  ▾" end
            h._serialize = function() return h.v end
            h._deserialize = function(val) if type(val) == "string" or type(val) == "number" then h:set(val) end end
            h._reset = function() h:set(h._default) end
            local pid = opts.PersistId .. "/" .. (id or t)
            Library._registry[pid] = h; h._id = pid
            self._handles[t] = h
            return h
        end

        function o:ColorPicker(t, default, cb, id)
            local K2 = Library.Config
            local current = default or K2.ac
            local f = self:_row(44, t)
            mk("TextLabel", {Size = UDim2.new(1, -130, 1, 0), Position = UDim2.new(0, 18, 0, 0), BackgroundTransparency = 1, Text = t, TextColor3 = K2.tx, Font = K2.fontBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = f})
            local swatch = mk("Frame", {Size = UDim2.new(0, 96, 0, 24), Position = UDim2.new(1, -110, .5, -12), BackgroundColor3 = current, Parent = f})
            rc(swatch, 6); sk(swatch, K2.ln, 1)
            local btn = mk("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = swatch})
            local h = {v = current, _default = current}
            local presets = {
                {Color3.fromRGB(88,101,242), "Blue"}, {Color3.fromRGB(46,204,113), "Green"},
                {Color3.fromRGB(231,76,60), "Red"}, {Color3.fromRGB(241,196,15), "Yellow"},
                {Color3.fromRGB(155,89,182), "Purple"}, {Color3.fromRGB(26,188,156), "Teal"},
                {Color3.fromRGB(230,126,34), "Orange"}, {Color3.fromRGB(149,165,166), "Gray"},
            }
            local popup
            btn.MouseButton1Click:Connect(function()
                sn(K2.soundClick, .3)
                if popup then popup:Destroy(); popup = nil; return end
                popup = mk("Frame", {Size = UDim2.new(0, 220, 0, 88), Position = UDim2.new(1, -110, 1, 4), BackgroundColor3 = K2.sb, ZIndex = 500, Parent = swatch})
                rc(popup, 8); sk(popup, K2.ac, 1, .3)
                mk("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = popup})
                for i, p in ipairs(presets) do
                    local col, name = p[1], p[2]
                    local row = math.floor((i - 1) / 4); local col_ = (i - 1) % 4
                    local b = mk("TextButton", {Size = UDim2.new(0, 46, 0, 32), Position = UDim2.new(0, col_ * 50, 0, row * 36), BackgroundColor3 = col, Text = "", AutoButtonColor = false, Parent = popup})
                    rc(b, 4); sk(b, K2.ln, 1, .3)
                    b.MouseButton1Click:Connect(function()
                        h.v = col; swatch.BackgroundColor3 = col
                        if cb then
                            local ok, e = pcall(cb, col)
                            if not ok then logError("ColorPicker/" .. t, e); ntf("error", tostring(e), 5, "err") end
                        end
                        popup:Destroy(); popup = nil
                    end)
                end
                local hex = mk("TextBox", {Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 1, -22), BackgroundColor3 = K2.bg, Text = "", PlaceholderText = "#RRGGBB", PlaceholderColor3 = K2.dm, TextColor3 = K2.tx, Font = K2.fontMed, TextSize = 10, ClearTextOnFocus = false, Parent = popup})
                rc(hex, 4); sk(hex, K2.ln, 1)
                hex.FocusLost:Connect(function(enter)
                    if not enter then return end
                    local s = hex.Text:gsub("#", "")
                    if #s == 6 then
                        local r = tonumber(s:sub(1,2), 16); local g = tonumber(s:sub(3,4), 16); local b = tonumber(s:sub(5,6), 16)
                        if r and g and b then
                            local c = Color3.fromRGB(r,g,b)
                            h.v = c; swatch.BackgroundColor3 = c
                            if cb then pcall(cb, c) end
                            popup:Destroy(); popup = nil
                        end
                    end
                end)
            end)
            function h.get(_) return h.v end
            function h.set(_, c) h.v = c; swatch.BackgroundColor3 = c end
            h._serialize = function() return {r = h.v.R, g = h.v.G, b = h.v.B} end
            h._deserialize = function(val)
                if type(val) == "table" and val.r and val.g and val.b then
                    h:set(Color3.new(val.r, val.g, val.b))
                end
            end
            h._reset = function() h:set(h._default) end
            local pid = opts.PersistId .. "/" .. (id or t)
            Library._registry[pid] = h; h._id = pid
            self._handles[t] = h
            return h
        end

        function o:Hero(cfg2)
            cfg2 = cfg2 or {}
            self.n = self.n + 1
            local hero = mk("Frame", {Size = UDim2.new(1, 0, 0, 148), BackgroundColor3 = K.sf, LayoutOrder = self.n, BackgroundTransparency = 1, Parent = self.pg})
            rc(hero, 14); sk(hero, K.ln, 1); gr(hero, Color3.fromRGB(24, 24, 46), K.sf, 90)
            local badgeHolder = mk("Frame", {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0, 65, 0.5, 0), BackgroundTransparency = 1, Parent = hero})
            local badgeGlow = mk("Frame", {Size = UDim2.new(0, 76, 0, 76), Position = UDim2.new(0.5, -38, 0.5, -38), BackgroundColor3 = K.ac, BackgroundTransparency = .75, Parent = badgeHolder})
            rc(badgeGlow, 38)
            local badge = mk("Frame", {Size = UDim2.new(0, 72, 0, 72), Position = UDim2.new(0.5, -36, 0.5, -36), BackgroundColor3 = K.sb, Parent = badgeHolder})
            rc(badge, 36); sk(badge, K.ac, 1.5, .3)
            local waveIcon = mk("ImageLabel", {Size = UDim2.new(0, 42, 0, 42), Position = UDim2.new(0.5, -21, 0.5, -21), BackgroundTransparency = 1, Image = cfg2.Image or "rbxassetid://119576006294033", ImageColor3 = K.ac, Parent = badge})
            local hTitle = mk("TextLabel", {Size = UDim2.new(1, -150, 0, 30), Position = UDim2.new(0, 140, 0, 26), BackgroundTransparency = 1, Text = "", TextColor3 = K.tx, Font = K.fontBold, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left, Parent = hero})
            local hSub = mk("TextLabel", {Size = UDim2.new(1, -150, 0, 18), Position = UDim2.new(0, 140, 0, 60), BackgroundTransparency = 1, Text = cfg2.Subtitle or "", TextColor3 = K.dm, Font = K.fontMed, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, Parent = hero})
            local statusRow = mk("Frame", {Size = UDim2.new(1, -150, 0, 22), Position = UDim2.new(0, 140, 0, 92), BackgroundTransparency = 1, Parent = hero})
            mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}, statusRow)
            local pills = {}
            for idx, pdef in ipairs(cfg2.Pills or {}) do
                local col = pdef.color
                if type(col) == "string" then col = K[col] or K.dm end
                local p = mk("Frame", {Size = UDim2.new(0, 0, 0, 20), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = col, BackgroundTransparency = .85, LayoutOrder = idx, Parent = statusRow})
                rc(p, 10)
                mk("UIPadding", {PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 10), Parent = p})
                mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), VerticalAlignment = Enum.VerticalAlignment.Center, Parent = p})
                local dot = mk("Frame", {Size = UDim2.new(0, 6, 0, 6), BackgroundColor3 = col, LayoutOrder = 1, Parent = p}); rc(dot, 3)
                local lbl = mk("TextLabel", {Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = pdef.text or "", TextColor3 = col, Font = K.fontMed, TextSize = 10, LayoutOrder = 2, Parent = p})
                table.insert(pills, {frame = p, label = lbl, dot = dot})
            end
            task.spawn(function()
                while not isReady do task.wait(.1) end
                task.wait(.35)
                tw(hero, .45, {BackgroundTransparency = 0})
                tw(badgeHolder, .5, {Size = UDim2.new(0, 90, 0, 90), Position = UDim2.new(0, 20, 0.5, -45)})
                task.wait(.3)
                local name = tostring(lp.DisplayName or lp.Name or "Player")
                local full = (cfg2.WelcomeText or "Welcome back, ") .. name .. "!"
                for i = 1, #full do
                    if not hTitle.Parent then break end
                    hTitle.Text = string.sub(full, 1, i); task.wait(.035)
                end
                tw(hSub, .35, {TextTransparency = 0})
                task.wait(.12)
                for _, p in ipairs(pills) do p.label.TextTransparency = 1; p.dot.BackgroundTransparency = 1 end
                for _, p in ipairs(pills) do
                    if not p.frame.Parent then break end
                    tw(p.label, .25, {TextTransparency = 0}); tw(p.dot, .25, {BackgroundTransparency = 0}); task.wait(.07)
                end
            end)
            if cfg2.AnimateIcon ~= false then
                task.spawn(function()
                    while not isReady do task.wait(.1) end
                    task.wait(1.2)
                    while waveIcon.Parent do
                        tw(waveIcon, .4, {Rotation = 22}); task.wait(.4)
                        tw(waveIcon, .4, {Rotation = -22}); task.wait(.4)
                        tw(waveIcon, .4, {Rotation = 0}); task.wait(1)
                    end
                end)
            end
            task.spawn(function()
                while not isReady do task.wait(.1) end
                task.wait(1)
                while badgeGlow.Parent do
                    tw(badgeGlow, 1.4, {Size = UDim2.new(0, 90, 0, 90), Position = UDim2.new(0.5, -45, 0.5, -45), BackgroundTransparency = .88}); task.wait(1.4)
                    tw(badgeGlow, 1.4, {Size = UDim2.new(0, 76, 0, 76), Position = UDim2.new(0.5, -38, 0.5, -38), BackgroundTransparency = .75}); task.wait(1.4)
                end
            end)
            return {pills = pills}
        end

        function o:Discord(cfg2)
            cfg2 = cfg2 or {}
            self.n = self.n + 1
            local url = cfg2.URL or ""
            local row = mk("Frame", {Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = K.sf, LayoutOrder = self.n, Parent = self.pg})
            rc(row, 10); local stroke = sk(row, K.ln, 1)
            mk("ImageLabel", {Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(0, 14, 0.5, -9), BackgroundTransparency = 1, Image = cfg2.Icon or "rbxassetid://84828491431270", ImageColor3 = K.ac, Parent = row})
            mk("TextLabel", {Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 42, 0, 0), BackgroundTransparency = 1, Text = cfg2.Text or "Join our Discord", TextColor3 = K.tx, Font = K.fontBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = row})
            local arrow = mk("TextLabel", {Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -30, 0, 0), BackgroundTransparency = 1, Text = ">", TextColor3 = K.dm, Font = K.fontBold, TextSize = 14, Parent = row})
            local click = mk("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = row})
            click.MouseEnter:Connect(function()
                sn(K.soundHover, .1); tw(row, .15, {BackgroundColor3 = K.hv}); tw(stroke, .15, {Color = K.ac}); tw(arrow, .15, {TextColor3 = K.ac, Position = UDim2.new(1, -24, 0, 0)})
            end)
            click.MouseLeave:Connect(function()
                tw(row, .15, {BackgroundColor3 = K.sf}); tw(stroke, .15, {Color = K.ln}); tw(arrow, .15, {TextColor3 = K.dm, Position = UDim2.new(1, -30, 0, 0)})
            end)
            click.MouseButton1Click:Connect(function()
                sn(K.soundClick, .3)
                local copied = false
                if setclipboard then copied = pcall(setclipboard, url)
                elseif toclipboard then copied = pcall(toclipboard, url) end
                pcall(function() if OpenBrowserWindow then OpenBrowserWindow(url) end end)
                if copied then ntf("Discord", "Invite link copied to clipboard!", 4, "ok")
                else ntf("Discord", url, 6, "ok") end
            end)
        end

        function o:QuickStart(rows)
            self.n = self.n + 1
            local header = mk("Frame", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = self.n, Parent = self.pg})
            mk("ImageLabel", {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 0, 0.5, -7), BackgroundTransparency = 1, Image = "rbxassetid://90838150633173", ImageColor3 = K.ac, Parent = header})
            mk("TextLabel", {Size = UDim2.new(1, -22, 1, 0), Position = UDim2.new(0, 22, 0, 0), BackgroundTransparency = 1, Text = "QUICK START", TextColor3 = K.dm, Font = K.fontBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, Parent = header})
            for _, r in ipairs(rows or {}) do
                self.n = self.n + 1
                local key, desc = r[1], r[2]
                local row = mk("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = K.sf, LayoutOrder = self.n, Parent = self.pg})
                rc(row, 10); local stroke = sk(row, K.ln, 1)
                local cap = mk("Frame", {Size = UDim2.new(0, 0, 0, 24), AutomaticSize = Enum.AutomaticSize.X, Position = UDim2.new(0, 14, 0.5, -12), BackgroundColor3 = K.sb, Parent = row})
                rc(cap, 6); sk(cap, K.ac, 1, .4)
                mk("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = cap})
                mk("TextLabel", {Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = key, TextColor3 = K.ac, Font = K.fontBold, TextSize = 11, Parent = cap})
                mk("TextLabel", {Size = UDim2.new(1, -200, 1, 0), Position = UDim2.new(0, 120, 0, 0), BackgroundTransparency = 1, Text = desc, TextColor3 = K.tx, Font = K.fontMed, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = row})
                row.MouseEnter:Connect(function() sn(K.soundHover, .08); tw(row, .15, {BackgroundColor3 = K.hv}); tw(stroke, .15, {Color = K.ac}) end)
                row.MouseLeave:Connect(function() tw(row, .15, {BackgroundColor3 = K.sf}); tw(stroke, .15, {Color = K.ln}) end)
            end
        end

        function o:About(t) self:Section("About"); self:Info(t) end
        function o:Disclaimer(t)
            self:Section("Disclaimer")
            self.n = self.n + 1
            local disc = mk("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Color3.fromRGB(38, 20, 20), LayoutOrder = self.n, Parent = self.pg})
            rc(disc, 10); sk(disc, K.dg, 1, .3)
            mk("UIPadding", {PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16), Parent = disc})
            mk("TextLabel", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = t, TextColor3 = K.dg, Font = K.fontMed, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, LineHeight = 1.3, Parent = disc})
        end

        b.MouseEnter:Connect(function()
            if cur ~= o then sn(K.soundHover, .08); tw(b, .15, {BackgroundTransparency = .4}); tw(l, .15, {TextColor3 = K.tx}) end
        end)
        b.MouseLeave:Connect(function()
            if cur ~= o then tw(b, .15, {BackgroundTransparency = 1}); tw(l, .15, {TextColor3 = K.dm}) end
        end)
        b.MouseButton1Click:Connect(function() sn(K.soundClick, .3); pk(o) end)
        tbs[#tbs + 1] = {o = o, pg = pg, b = b, l = l, i = i}
        if not cur then pk(o) end
        return o
    end

    -- recherche
    local srchDrop
    if opts.SearchEnabled and srchInp then
        srchDrop = mk("Frame", {Size = UDim2.new(1, -20, 0, 0), Position = UDim2.new(0, 10, 0, 100), BackgroundColor3 = K.sb, Visible = false, ZIndex = 50, Parent = win})
        rc(srchDrop, 6); sk(srchDrop, K.ac, 1, .3)
        local function updateSearch()
            for _, c in ipairs(srchDrop:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            local q = srchInp.Text:lower()
            if q == "" then srchDrop.Visible = false; return end
            local matches = {}
            for _, el in ipairs(windowEls) do
                if el.frame and el.frame.Parent and el.label:lower():find(q, 1, true) then table.insert(matches, el) end
            end
            if #matches == 0 then srchDrop.Visible = false; return end
            local shown = math.min(#matches, 6)
            for i = 1, shown do
                local el = matches[i]
                local b = mk("TextButton", {Size = UDim2.new(1, -8, 0, 24), Position = UDim2.new(0, 4, 0, 4 + (i - 1) * 24), BackgroundColor3 = K.bg, BackgroundTransparency = .3, Text = "", AutoButtonColor = false, Parent = srchDrop})
                rc(b, 4)
                mk("TextLabel", {Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, Text = el.label, TextColor3 = K.tx, Font = K.fontMed, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = b})
                b.MouseEnter:Connect(function() b.BackgroundTransparency = 0 end)
                b.MouseLeave:Connect(function() b.BackgroundTransparency = .3 end)
                b.MouseButton1Click:Connect(function()
                    pk(el.tab)
                    task.wait(.1)
                    local y = el.frame.AbsolutePosition.Y - el.tab.pg.AbsolutePosition.Y - 100
                    tw(el.tab.pg, .3, {CanvasPosition = Vector2.new(0, math.max(0, y))})
                    srchInp.Text = ""
                    srchDrop.Visible = false
                end)
            end
            srchDrop.Size = UDim2.new(1, -20, 0, shown * 24 + 8)
            srchDrop.Visible = true
        end
        srchInp:GetPropertyChangedSignal("Text"):Connect(updateSearch)
        srchInp.Focused:Connect(updateSearch)
        srchInp.FocusLost:Connect(function()
            task.wait(.15)
            srchDrop.Visible = false
        end)
    end

    -- controles
    local function ctl(t, x, hc, cb, tooltip)
        local b = mk("TextButton", {Position = UDim2.new(1, x, 0, 12), Size = UDim2.new(0, 26, 0, 26), BackgroundColor3 = K.sf, Text = t, TextColor3 = K.dm, Font = K.fontBold, TextSize = 14, AutoButtonColor = false, ZIndex = 10, Parent = win})
        rc(b, 6); sk(b, K.ln, 1)
        b.MouseEnter:Connect(function() sn(K.soundHover, .08); tw(b, .15, {BackgroundColor3 = hc, TextColor3 = K.tx}) end)
        b.MouseLeave:Connect(function() tw(b, .15, {BackgroundColor3 = K.sf, TextColor3 = K.dm}) end)
        b.MouseButton1Click:Connect(cb)
        return b
    end

    local Window = setmetatable({}, Library)
    Window._win = win
    Window._onClose = nil
    Window._isCompact = false

    local compactBtn = ctl("□", -98, K.hv, function()
        Window:SetCompact(not isCompact)
    end)
    ctl("-", -66, K.hv, function() Window:SetVisible(false) end)
    ctl("×", -34, K.dg, function() Window:Destroy() end)

    function Window:SetCompact(on)
        isCompact = on; self._isCompact = on
        lay()
    end

    function Window:CreateTab(name, icon) return tab(name, icon) end
    function Window:Notify(title, text, dur, kind) ntf(title, text, dur, kind) end

    function Window:SetVisible(v)
        if v == isVis then return end
        isVis = v
        if v then
            win.Visible = true
            us.Scale = tgt * .9
            tw(us, .28, {Scale = tgt})
            sn(K.soundOpen, .25)
        else
            win.Visible = false
            if srchDrop then srchDrop.Visible = false end
        end
    end
    function Window:Toggle() self:SetVisible(not isVis) end
    function Window:OnClose(fn) self._onClose = fn end

    function Window:Destroy()
        if self._onClose then pcall(self._onClose) end
        for id, h in pairs(Library._registry) do
            if h and h._id and h._id:sub(1, #opts.PersistId) == opts.PersistId then
                Library._registry[id] = nil
            end
        end
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        if gui then gui:Destroy() end
    end

    function Window:SetTheme(theme) return Library:SetTheme(theme) end
    function Window:SetAccent(color) return Library:SetAccent(color) end
    function Window:SaveSettings() return Library:SaveSettings() end
    function Window:LoadSettings() return Library:LoadSettings() end

    local uiTab = tab("UI", 103950363563606, 100)
    uiTab:Section("Appearance")
    local themeDropdown
    themeDropdown = uiTab:Dropdown("Theme", {"dark", "black", "light"}, Library._currentTheme or "dark", function(v)
        Library:SetTheme(v)
        Window:Notify("UI", "Theme set to: " .. tostring(v), 3, "ok")
    end)
    local accentPicker
    accentPicker = uiTab:ColorPicker("Accent Color", Library.Config.ac, function(c)
        Library:SetAccent(c)
    end)
    uiTab:Section("Quick Actions")
    uiTab:Button("Reset Appearance", function()
        Library:ResetTheme()
        Library._currentTheme = "dark"
        if themeDropdown and themeDropdown.set then themeDropdown:set("dark") end
        if accentPicker and accentPicker.set then accentPicker:set(Library.Config.ac) end
        Window:Notify("UI", "Appearance reset to defaults.", 3, "ok")
    end)
    uiTab:Button("Toggle Compact Mode", function()
        Window:SetCompact(not Window._isCompact)
    end)

    -- bouton qui flote
    if opts.ShowFloatingButton then
        local mbtn = mk("TextButton", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -14), Size = UDim2.new(0, 40, 0, 40), BackgroundColor3 = K.sb, Text = opts.FloatingButtonText, TextColor3 = K.ac, Font = K.fontBold, TextSize = 16, AutoButtonColor = false, ZIndex = 20, Parent = gui})
        rc(mbtn, 20); sk(mbtn, K.ln, 1)
        mbtn.MouseButton1Click:Connect(function() if isReady then Window:Toggle() end end)
    end
    Connect(UIS.InputBegan, function(i, p)
        if not p and i.KeyCode == opts.Keybind and isReady then Window:Toggle() end
    end)

    task.spawn(function()
        for _, p in ipairs(opts.LoadingSteps) do
            lst.Text = p[1]
            tw(lfl, .35, {Size = UDim2.new(p[2], 0, 1, 0)})
            task.wait(.42)
        end
        task.wait(.15)
        for _, c in ipairs(ld:GetDescendants()) do
            if c:IsA("GuiObject") then
                tw(c, .3, {BackgroundTransparency = 1})
                if c:IsA("TextLabel") or c:IsA("TextButton") then tw(c, .3, {TextTransparency = 1}) end
            elseif c:IsA("UIStroke") then
                tw(c, .3, {Transparency = 1})
            end
        end
        task.wait(.3)
        ld:Destroy()
        isReady = true
        Window:SetVisible(true)
    end)

    return Window
end

return Library
