-- Dex Explorer Standalone v2.0
-- LocalScript / in-game debug explorer
-- Features:
--  • Recursive tree + real collapse/expand
--  • Strong search: name, class, path, attributes, tags
--  • Breadcrumb/path context
--  • Property inspector + safe live editing
--  • Attribute editor
--  • Asset/class icons with configurable image assets
--  • AI-style purpose analysis from metadata
--  • Copy path/name/class
--  • Resizable + draggable dark UI
--  • Refresh / expand all / collapse all
--  • No Studio Plugin API required

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")

local LP = Players.LocalPlayer

local function getParent()
    local ok, hui = pcall(function()
        return gethui and gethui()
    end)
    if ok and hui then return hui end
    return LP:WaitForChild("PlayerGui")
end

local ROOT_GUI = getParent()

pcall(function()
    local old = ROOT_GUI:FindFirstChild("DexExplorerV2")
    if old then old:Destroy() end
end)

local CFG = {
    Title = "Dex Explorer",
    Version = "2.0",
    Accent = Color3.fromRGB(125, 65, 255),
    Accent2 = Color3.fromRGB(70, 170, 255),
    Bg = Color3.fromRGB(14, 14, 18),
    Bg2 = Color3.fromRGB(23, 23, 29),
    Bg3 = Color3.fromRGB(31, 31, 39),
    Row = Color3.fromRGB(27, 27, 34),
    Hover = Color3.fromRGB(39, 39, 49),
    Text = Color3.fromRGB(235, 235, 242),
    Dim = Color3.fromRGB(145, 145, 158),
    Good = Color3.fromRGB(80, 210, 125),
    Warn = Color3.fromRGB(255, 185, 70),
    Bad = Color3.fromRGB(255, 90, 100),
    Font = Enum.Font.Gotham,
    Bold = Enum.Font.GothamBold,
    Mono = Enum.Font.Code,
    Logo = "rbxassetid://6031075931",
}

local CLASS_ICON = {
    Workspace="◆", Players="●", Lighting="☼", ReplicatedStorage="▣",
    ServerStorage="▤", ServerScriptService="⚙", StarterGui="▣",
    StarterPack="◇", StarterPlayer="●", Teams="⚑", SoundService="♪",
    TextChatService="✉", Chat="✉", RunService="▶", UserInputService="⌨",
    TweenService="↝", Debris="⌫", CollectionService="◆",
    RemoteEvent="↯", RemoteFunction="↯", UnreliableRemoteEvent="↯",
    BindableEvent="◈", BindableFunction="◈", Script="S",
    LocalScript="L", ModuleScript="M", Folder="□", Model="◇",
    Part="■", MeshPart="◆", UnionOperation="◈", Terrain="△",
    Camera="◎", Humanoid="♙", HumanoidRootPart="■", Animator="A",
    Animation="▶", Sound="♪", Tool="⚒", ProximityPrompt="⌁",
    ClickDetector="⌁", Attachment="⊙", ParticleEmitter="✦",
    Trail="〰", Beam="━", PointLight="☼", SpotLight="◉",
    SurfaceLight="☼", BillboardGui="▤", ScreenGui="▣", Frame="□",
    TextLabel="T", TextButton="B", TextBox="⌨", ImageLabel="▧",
    ImageButton="▧", ScrollingFrame="▥", UIListLayout="☷",
    UIGridLayout="▦", UICorner="◐", UIStroke="◯",
    StringValue="S", IntValue="#", NumberValue="#", BoolValue="✓",
    ObjectValue="◌", Vector3Value="V", CFrameValue="C", Color3Value="●",
    Accessory="◇", Shirt="◇", Pants="◇", BodyColors="●", Seat="□",
    VehicleSeat="□", SpawnLocation="⚑", Decal="▧", Texture="▧",
}

local function iconFor(className)
    return CLASS_ICON[className] or "•"
end

local function mk(className, props, parent)
    local x = Instance.new(className)
    for k,v in pairs(props or {}) do
        pcall(function() x[k] = v end)
    end
    if parent then x.Parent = parent end
    return x
end

local function round(x, r)
    mk("UICorner", {CornerRadius=UDim.new(0,r or 7)}, x)
end

local function outline(x, color, thickness)
    mk("UIStroke", {
        Color=color or Color3.fromRGB(52,52,64),
        Thickness=thickness or 1,
        Transparency=0.15,
    }, x)
end

local function tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or .14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local gui = mk("ScreenGui", {
    Name="DexExplorerV2",
    ResetOnSpawn=false,
    IgnoreGuiInset=true,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
}, ROOT_GUI)

local main = mk("Frame", {
    Name="Main",
    Size=UDim2.fromOffset(930,610),
    Position=UDim2.new(.5,-465,.5,-305),
    BackgroundColor3=CFG.Bg,
    BorderSizePixel=0,
    Active=true,
}, gui)
round(main,12)
outline(main, Color3.fromRGB(58,58,72), 1)

local top = mk("Frame", {
    Size=UDim2.new(1,0,0,48),
    BackgroundColor3=CFG.Bg2,
    BorderSizePixel=0,
    Active=true,
}, main)

local logo = mk("ImageLabel", {
    Size=UDim2.fromOffset(34,34),
    Position=UDim2.fromOffset(9,7),
    BackgroundColor3=CFG.Bg3,
    Image=CFG.Logo,
    ScaleType=Enum.ScaleType.Fit,
    BorderSizePixel=0,
}, top)
round(logo,9)
outline(logo, CFG.Accent, 1.5)

mk("TextLabel", {
    Size=UDim2.new(1,-180,0,22),
    Position=UDim2.fromOffset(53,6),
    BackgroundTransparency=1,
    Text=CFG.Title,
    TextColor3=CFG.Text,
    TextSize=15,
    Font=CFG.Bold,
    TextXAlignment=Enum.TextXAlignment.Left,
}, top)

mk("TextLabel", {
    Size=UDim2.new(1,-180,0,16),
    Position=UDim2.fromOffset(53,27),
    BackgroundTransparency=1,
    Text="Standalone • Debug Explorer • v"..CFG.Version,
    TextColor3=CFG.Dim,
    TextSize=9,
    Font=CFG.Font,
    TextXAlignment=Enum.TextXAlignment.Left,
}, top)

local minimize = mk("TextButton", {
    Size=UDim2.fromOffset(32,30),
    Position=UDim2.new(1,-75,0,9),
    BackgroundColor3=CFG.Bg3,
    Text="—",
    TextColor3=CFG.Text,
    TextSize=16,
    Font=CFG.Bold,
    BorderSizePixel=0,
}, top)
round(minimize,7)

local close = mk("TextButton", {
    Size=UDim2.fromOffset(32,30),
    Position=UDim2.new(1,-39,0,9),
    BackgroundColor3=Color3.fromRGB(55,25,32),
    Text="×",
    TextColor3=CFG.Bad,
    TextSize=18,
    Font=CFG.Bold,
    BorderSizePixel=0,
}, top)
round(close,7)

local searchFrame = mk("Frame", {
    Size=UDim2.new(1,-20,0,38),
    Position=UDim2.fromOffset(10,57),
    BackgroundColor3=CFG.Bg3,
    BorderSizePixel=0,
}, main)
round(searchFrame,8)
outline(searchFrame)

local search = mk("TextBox", {
    Size=UDim2.new(1,-95,1,0),
    Position=UDim2.fromOffset(12,0),
    BackgroundTransparency=1,
    PlaceholderText="Search name, class, path, attribute or tag...",
    PlaceholderColor3=CFG.Dim,
    Text="",
    TextColor3=CFG.Text,
    TextSize=12,
    Font=CFG.Font,
    ClearTextOnFocus=false,
    TextXAlignment=Enum.TextXAlignment.Left,
}, searchFrame)

local clearSearch = mk("TextButton", {
    Size=UDim2.fromOffset(62,26),
    Position=UDim2.new(1,-70,.5,-13),
    BackgroundColor3=CFG.Bg2,
    Text="CLEAR",
    TextColor3=CFG.Dim,
    TextSize=9,
    Font=CFG.Bold,
    BorderSizePixel=0,
}, searchFrame)
round(clearSearch,6)

local toolbar = mk("Frame", {
    Size=UDim2.new(1,-20,0,34),
    Position=UDim2.fromOffset(10,101),
    BackgroundTransparency=1,
}, main)

local function tool(text, x, width)
    local b = mk("TextButton", {
        Size=UDim2.fromOffset(width or 82,30),
        Position=UDim2.fromOffset(x,2),
        BackgroundColor3=CFG.Bg2,
        Text=text,
        TextColor3=CFG.Text,
        TextSize=10,
        Font=CFG.Font,
        BorderSizePixel=0,
    }, toolbar)
    round(b,6)
    outline(b)
    return b
end

local refresh = tool("⟳  REFRESH",0,86)
local expandAll = tool("⊞  EXPAND",92,82)
local collapseAll = tool("⊟  COLLAPSE",180,88)
local aiCheck = tool("✦  AI CHECK",276,92)

local countLabel = mk("TextLabel", {
    Size=UDim2.fromOffset(180,30),
    Position=UDim2.new(1,-180,0,2),
    BackgroundTransparency=1,
    Text="0 instances",
    TextColor3=CFG.Dim,
    TextSize=10,
    Font=CFG.Mono,
    TextXAlignment=Enum.TextXAlignment.Right,
}, toolbar)

local content = mk("Frame", {
    Size=UDim2.new(1,-20,1,-178),
    Position=UDim2.fromOffset(10,141),
    BackgroundTransparency=1,
}, main)

local treePanel = mk("Frame", {
    Size=UDim2.new(.54,-5,1,0),
    BackgroundColor3=CFG.Bg2,
    BorderSizePixel=0,
}, content)
round(treePanel,9)
outline(treePanel)

local inspector = mk("Frame", {
    Size=UDim2.new(.46,-5,1,0),
    Position=UDim2.new(.54,10,0,0),
    BackgroundColor3=CFG.Bg2,
    BorderSizePixel=0,
}, content)
round(inspector,9)
outline(inspector)

local treeHeader = mk("Frame", {
    Size=UDim2.new(1,0,0,34),
    BackgroundColor3=CFG.Bg3,
    BorderSizePixel=0,
}, treePanel)
round(treeHeader,9)

mk("TextLabel", {
    Size=UDim2.new(1,-15,1,0),
    Position=UDim2.fromOffset(10,0),
    BackgroundTransparency=1,
    Text="EXPLORER",
    TextColor3=CFG.Dim,
    TextSize=10,
    Font=CFG.Bold,
    TextXAlignment=Enum.TextXAlignment.Left,
}, treeHeader)

local tree = mk("ScrollingFrame", {
    Size=UDim2.new(1,-8,1,-42),
    Position=UDim2.fromOffset(4,38),
    BackgroundTransparency=1,
    BorderSizePixel=0,
    ScrollBarThickness=5,
    ScrollBarImageColor3=CFG.Accent,
    CanvasSize=UDim2.new(),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,
}, treePanel)

local treeLayout = mk("UIListLayout", {
    Padding=UDim.new(0,1),
    SortOrder=Enum.SortOrder.LayoutOrder,
}, tree)

local inspectHeader = mk("Frame", {
    Size=UDim2.new(1,0,0,34),
    BackgroundColor3=CFG.Bg3,
    BorderSizePixel=0,
}, inspector)
round(inspectHeader,9)

local inspectTitle = mk("TextLabel", {
    Size=UDim2.new(1,-18,1,0),
    Position=UDim2.fromOffset(10,0),
    BackgroundTransparency=1,
    Text="INSPECTOR",
    TextColor3=CFG.Dim,
    TextSize=10,
    Font=CFG.Bold,
    TextXAlignment=Enum.TextXAlignment.Left,
}, inspectHeader)

local props = mk("ScrollingFrame", {
    Size=UDim2.new(1,-8,1,-42),
    Position=UDim2.fromOffset(4,38),
    BackgroundTransparency=1,
    BorderSizePixel=0,
    ScrollBarThickness=5,
    ScrollBarImageColor3=CFG.Accent,
    CanvasSize=UDim2.new(),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,
}, inspector)

local propLayout = mk("UIListLayout", {
    Padding=UDim.new(0,4),
    SortOrder=Enum.SortOrder.LayoutOrder,
}, props)

local status = mk("TextLabel", {
    Size=UDim2.new(1,-20,0,20),
    Position=UDim2.new(0,10,1,-27),
    BackgroundTransparency=1,
    Text="Ready",
    TextColor3=CFG.Dim,
    TextSize=10,
    Font=CFG.Mono,
    TextXAlignment=Enum.TextXAlignment.Left,
}, main)

local minimized = false
local selected
local expanded = {}
local rendered = {}
local searchToken = 0

local function setStatus(text, color)
    status.Text = text
    status.TextColor3 = color or CFG.Dim
end

local function safeCopy(text)
    text = tostring(text or "")
    local ok = pcall(function()
        if setclipboard then
            setclipboard(text)
        else
            error("clipboard unavailable")
        end
    end)
    if ok then
        setStatus("Copied: "..text, CFG.Good)
    else
        setStatus("Clipboard unavailable • "..text, CFG.Warn)
    end
end

local function getPath(obj)
    if not obj then return "" end
    local parts = {}
    local cur = obj
    while cur and cur ~= game do
        table.insert(parts,1,cur.Name)
        cur = cur.Parent
    end
    return "game."..table.concat(parts,".")
end

local function getTags(obj)
    local ok,t = pcall(function()
        return CollectionService:GetTags(obj)
    end)
    return ok and t or {}
end

local function getSearchBlob(obj)
    local chunks = {
        obj.Name,
        obj.ClassName,
        getPath(obj),
    }
    for n,v in pairs(obj:GetAttributes()) do
        table.insert(chunks,n)
        table.insert(chunks,tostring(v))
    end
    for _,tag in ipairs(getTags(obj)) do
        table.insert(chunks,tag)
    end
    return table.concat(chunks," "):lower()
end

local function matches(obj, query)
    if query == "" then return true end
    query = query:lower()
    local blob = getSearchBlob(obj)

    for token in query:gmatch("%S+") do
        if not blob:find(token,1,true) then
            return false
        end
    end
    return true
end

local function descendantsForSearch(root, query, out)
    out = out or {}
    for _,child in ipairs(root:GetChildren()) do
        if matches(child,query) then
            table.insert(out,child)
        end
        descendantsForSearch(child,query,out)
    end
    return out
end

local function clearContainer(container, keepLayout)
    for _,x in ipairs(container:GetChildren()) do
        if not (keepLayout and x:IsA("UIListLayout")) then
            x:Destroy()
        end
    end
end

local function section(text)
    local b = mk("TextLabel", {
        Size=UDim2.new(1,-4,0,25),
        BackgroundTransparency=1,
        Text="  "..text,
        TextColor3=CFG.Accent2,
        TextSize=10,
        Font=CFG.Bold,
        TextXAlignment=Enum.TextXAlignment.Left,
    }, props)
    return b
end

local function inspectorRow(label, value, editable, setter)
    local row = mk("Frame", {
        Size=UDim2.new(1,-4,0,39),
        BackgroundColor3=CFG.Bg3,
        BorderSizePixel=0,
    }, props)
    round(row,6)

    mk("TextLabel", {
        Size=UDim2.new(.32,-4,1,0),
        Position=UDim2.fromOffset(8,0),
        BackgroundTransparency=1,
        Text=label,
        TextColor3=CFG.Dim,
        TextSize=10,
        Font=CFG.Font,
        TextXAlignment=Enum.TextXAlignment.Left,
    }, row)

    if editable then
        local box = mk("TextBox", {
            Size=UDim2.new(.68,-12,0,27),
            Position=UDim2.new(.32,0,.5,-13),
            BackgroundColor3=CFG.Bg,
            Text=tostring(value),
            TextColor3=CFG.Text,
            TextSize=10,
            Font=CFG.Mono,
            ClearTextOnFocus=false,
            TextXAlignment=Enum.TextXAlignment.Left,
            BorderSizePixel=0,
        }, row)
        round(box,5)
        box.FocusLost:Connect(function(enter)
            if not enter then return end
            local ok,err = pcall(function()
                setter(box.Text)
            end)
            if ok then
                setStatus("Updated "..label,CFG.Good)
            else
                setStatus("Update failed: "..tostring(err),CFG.Bad)
                box.Text=tostring(value)
            end
        end)
    else
        mk("TextLabel", {
            Size=UDim2.new(.68,-12,1,0),
            Position=UDim2.new(.32,0,0,0),
            BackgroundTransparency=1,
            Text=tostring(value),
            TextColor3=CFG.Text,
            TextSize=10,
            Font=CFG.Mono,
            TextXAlignment=Enum.TextXAlignment.Left,
            TextTruncate=Enum.TextTruncate.AtEnd,
        }, row)
    end

    return row
end

local function analyzePurpose(obj)
    local c = obj.ClassName
    local n = obj.Name:lower()
    local tags = getTags(obj)
    local attrs = obj:GetAttributes()
    local notes = {}

    if c == "RemoteEvent" then
        table.insert(notes,"RemoteEvent: dùng để truyền tín hiệu một chiều giữa client/server.")
    elseif c == "RemoteFunction" then
        table.insert(notes,"RemoteFunction: dùng cho request/response giữa client/server.")
    elseif c == "BindableEvent" then
        table.insert(notes,"BindableEvent: giao tiếp nội bộ giữa script trong cùng phía.")
    elseif c == "BindableFunction" then
        table.insert(notes,"BindableFunction: gọi hàm nội bộ có giá trị trả về.")
    elseif c == "ModuleScript" then
        table.insert(notes,"ModuleScript: thường chứa thư viện hoặc logic được script khác require.")
    elseif c == "LocalScript" then
        table.insert(notes,"LocalScript: logic chạy phía client.")
    elseif c == "Script" then
        table.insert(notes,"Script: logic server-side trong game Roblox.")
    elseif c == "Tool" then
        table.insert(notes,"Tool: vật phẩm có thể được trang bị/sử dụng bởi người chơi.")
    elseif c == "ProximityPrompt" then
        table.insert(notes,"ProximityPrompt: tương tác khi người chơi đứng gần object.")
    elseif c == "ClickDetector" then
        table.insert(notes,"ClickDetector: nhận tương tác click trên object.")
    elseif c == "Humanoid" then
        table.insert(notes,"Humanoid: điều khiển nhân vật, trạng thái và chuyển động.")
    elseif c == "Animation" or c == "Animator" then
        table.insert(notes,"Animation system: liên quan tới phát/chạy animation.")
    elseif c == "ParticleEmitter" or c == "Beam" or c == "Trail" then
        table.insert(notes,"Visual effect: tạo hiệu ứng hình ảnh/ánh sáng/chuyển động.")
    elseif c == "Sound" then
        table.insert(notes,"Sound: phát âm thanh trong game.")
    elseif c == "Folder" or c == "Model" then
        table.insert(notes,"Container: chủ yếu dùng để tổ chức hierarchy.")
    elseif c == "StringValue" or c == "IntValue" or c == "NumberValue" or c == "BoolValue" or c == "ObjectValue" then
        table.insert(notes,"Value object: lưu dữ liệu/giá trị mà script khác có thể đọc.")
    else
        table.insert(notes,"Chưa có mẫu chuyên biệt; tác dụng được suy luận từ ClassName, Name, Attributes và Tags.")
    end

    local keywordMap = {
        damage="Tên có keyword 'damage' → có khả năng liên quan sát thương.",
        heal="Tên có keyword 'heal' → có khả năng liên quan hồi máu.",
        health="Tên có keyword 'health' → có khả năng liên quan HP.",
        speed="Tên có keyword 'speed' → có khả năng liên quan tốc độ.",
        weapon="Tên có keyword 'weapon' → có khả năng liên quan vũ khí.",
        admin="Tên có keyword 'admin' → có khả năng liên quan quyền quản trị.",
        config="Tên có keyword 'config' → có khả năng là cấu hình.",
        data="Tên có keyword 'data' → có khả năng liên quan dữ liệu.",
        shop="Tên có keyword 'shop' → có khả năng liên quan cửa hàng.",
        quest="Tên có keyword 'quest' → có khả năng liên quan nhiệm vụ.",
    }

    for keyword,note in pairs(keywordMap) do
        if n:find(keyword,1,true) then
            table.insert(notes,note)
        end
    end

    if next(attrs) then
        table.insert(notes,"Có "..tostring(#(function()
            local a={} for k in pairs(attrs) do table.insert(a,k) end return a
        end)()).." attribute(s); các attribute có thể là metadata/config cho logic game.")
    end

    if #tags > 0 then
        table.insert(notes,"Tags: "..table.concat(tags,", "))
    end

    return notes
end

local function showInspector(obj)
    clearContainer(props,true)

    if not obj then
        inspectTitle.Text="INSPECTOR"
        return
    end

    inspectTitle.Text=iconFor(obj.ClassName).."  "..obj.Name

    section("IDENTITY")
    inspectorRow("Name",obj.Name,true,function(v)
        if v == "" then error("Name cannot be empty") end
        obj.Name=v
        showInspector(obj)
        refreshTree()
    end)
    inspectorRow("ClassName",obj.ClassName,false)
    inspectorRow("Path",getPath(obj),false)
    inspectorRow("Parent",obj.Parent and obj.Parent:GetFullName() or "nil",false)
    inspectorRow("Archivable",obj.Archivable,true,function(v)
        obj.Archivable=(v:lower()=="true" or v=="1" or v:lower()=="yes")
    end)

    section("ATTRIBUTES")
    local attrs=obj:GetAttributes()
    local hasAttr=false
    for name,value in pairs(attrs) do
        hasAttr=true
        inspectorRow(name,value,true,function(v)
            local old=value
            local typ=typeof(old)
            if typ=="string" then
                obj:SetAttribute(name,v)
            elseif typ=="number" then
                local num=tonumber(v)
                if not num then error("Invalid number") end
                obj:SetAttribute(name,num)
            elseif typ=="boolean" then
                obj:SetAttribute(name,(v:lower()=="true" or v=="1" or v:lower()=="yes"))
            else
                error("Complex attribute type is read-only in this editor")
            end
        end)
    end
    if not hasAttr then
        inspectorRow("Status","No attributes",false)
    end

    section("TAGS")
    local tags=getTags(obj)
    inspectorRow("Tags",#tags>0 and table.concat(tags,", ") or "None",false)

    section("AI PURPOSE CHECK")
    local notes=analyzePurpose(obj)
    for i,note in ipairs(notes) do
        inspectorRow("Insight "..i,note,false)
    end

    section("ACTIONS")
    local actions=mk("Frame",{
        Size=UDim2.new(1,-4,0,36),
        BackgroundTransparency=1,
    },props)

    local function action(txt,x,cb,w)
        local b=mk("TextButton",{
            Size=UDim2.fromOffset(w or 86,28),
            Position=UDim2.fromOffset(x,3),
            BackgroundColor3=CFG.Bg3,
            Text=txt,
            TextColor3=CFG.Text,
            TextSize=9,
            Font=CFG.Bold,
            BorderSizePixel=0,
        },actions)
        round(b,6)
        outline(b)
        b.MouseButton1Click:Connect(cb)
    end

    action("COPY PATH",0,function() safeCopy(getPath(obj)) end)
    action("COPY NAME",92,function() safeCopy(obj.Name) end)
    action("COPY CLASS",184,function() safeCopy(obj.ClassName) end)
end

local function createTreeRow(obj,depth,order,matchSet)
    if not obj or not obj.Parent then return end

    if matchSet and not matchSet[obj] then
        return
    end

    local hasChildren=#obj:GetChildren()>0
    local isOpen=expanded[obj] == true
    local arrow=hasChildren and (isOpen and "▼" or "▶") or "·"

    local row=mk("TextButton",{
        Size=UDim2.new(1,-5,0,27),
        BackgroundColor3=CFG.Row,
        BackgroundTransparency=.25,
        Text="",
        AutoButtonColor=false,
        BorderSizePixel=0,
        LayoutOrder=order,
    },tree)
    round(row,5)

    local indent=depth*15
    mk("TextLabel",{
        Size=UDim2.fromOffset(18,27),
        Position=UDim2.fromOffset(indent,0),
        BackgroundTransparency=1,
        Text=arrow,
        TextColor3=hasChildren and CFG.Dim or Color3.fromRGB(80,80,90),
        TextSize=9,
        Font=CFG.Bold,
    },row)

    mk("TextLabel",{
        Size=UDim2.fromOffset(23,27),
        Position=UDim2.fromOffset(indent+18,0),
        BackgroundTransparency=1,
        Text=iconFor(obj.ClassName),
        TextColor3=CFG.Accent,
        TextSize=12,
        Font=CFG.Bold,
    },row)

    mk("TextLabel",{
        Size=UDim2.new(1,-indent-50,1,0),
        Position=UDim2.fromOffset(indent+43,0),
        BackgroundTransparency=1,
        Text=obj.Name.."  ["..obj.ClassName.."]",
        TextColor3=CFG.Text,
        TextSize=10,
        Font=CFG.Font,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,
    },row)

    row.MouseEnter:Connect(function()
        if selected~=obj then tween(row,{BackgroundColor3=CFG.Hover},.08) end
    end)

    row.MouseLeave:Connect(function()
        if selected~=obj then tween(row,{BackgroundColor3=CFG.Row},.08) end
    end)

    row.MouseButton1Click:Connect(function()
        selected=obj
        for _,r in ipairs(tree:GetChildren()) do
            if r:IsA("TextButton") then
                r.BackgroundColor3=CFG.Row
                r.BackgroundTransparency=.25
            end
        end
        row.BackgroundColor3=CFG.Accent
        row.BackgroundTransparency=.65
        showInspector(obj)

        if hasChildren then
            expanded[obj]=not expanded[obj]
            task.defer(function()
                -- rebuild below
                refreshTree()
            end)
        end
        setStatus("Selected: "..getPath(obj),CFG.Text)
    end)

    rendered[obj]=row
end

function refreshTree()
    searchToken+=1
    local token=searchToken
    clearContainer(tree,true)
    rendered={}
    local query=search.Text:lower()
    local matchSet=nil

    if query~="" then
        matchSet={}
        local results=descendantsForSearch(game,query)
        for _,obj in ipairs(results) do
            matchSet[obj]=true
            local p=obj.Parent
            while p and p~=game do
                matchSet[p]=true
                p=p.Parent
            end
        end
    end

    local order=0
    local count=0

    local function scan(parent,depth)
        if token~=searchToken then return end
        local children=parent:GetChildren()

        table.sort(children,function(a,b)
            return a.Name:lower()<b.Name:lower()
        end)

        for _,child in ipairs(children) do
            if not matchSet or matchSet[child] then
                order+=1
                count+=1
                createTreeRow(child,depth,order,matchSet)

                local shouldOpen=expanded[child]
                if query~="" then shouldOpen=true end
                if shouldOpen then
                    scan(child,depth+1)
                end
            end
        end
    end

    -- Start at game so services exposed to the client are visible.
    scan(game,0)

    countLabel.Text=tostring(count).." visible"
    if query~="" then
        setStatus("Search: "..query.." • "..count.." matches/context",CFG.Accent2)
    else
        setStatus("Explorer refreshed • "..count.." visible instances",CFG.Good)
    end
end

local function expandEverything()
    local n=0
    for _,obj in ipairs(game:GetDescendants()) do
        if #obj:GetChildren()>0 then
            expanded[obj]=true
            n+=1
        end
    end
    refreshTree()
    setStatus("Expanded "..n.." containers",CFG.Good)
end

local function collapseEverything()
    table.clear(expanded)
    refreshTree()
    setStatus("Collapsed all",CFG.Text)
end

local function runAICheck()
    if not selected then
        setStatus("Select an instance first",CFG.Warn)
        return
    end

    showInspector(selected)
    setStatus("AI purpose check completed for "..selected.Name,CFG.Good)
end

refresh.MouseButton1Click:Connect(refreshTree)
expandAll.MouseButton1Click:Connect(expandEverything)
collapseAll.MouseButton1Click:Connect(collapseEverything)
aiCheck.MouseButton1Click:Connect(runAICheck)

clearSearch.MouseButton1Click:Connect(function()
    search.Text=""
    refreshTree()
end)

search:GetPropertyChangedSignal("Text"):Connect(function()
    task.defer(refreshTree)
end)

minimize.MouseButton1Click:Connect(function()
    minimized=not minimized
    if minimized then
        content.Visible=false
        searchFrame.Visible=false
        toolbar.Visible=false
        main.Size=UDim2.fromOffset(930,48)
        minimize.Text="+"
    else
        content.Visible=true
        searchFrame.Visible=true
        toolbar.Visible=true
        main.Size=UDim2.fromOffset(930,610)
        minimize.Text="—"
    end
end)

close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- Dragging
do
    local dragging=false
    local dragStart
    local startPos

    top.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1
        or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            dragStart=input.Position
            startPos=main.Position

            input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then
                    dragging=false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType==Enum.UserInputType.MouseMovement
        or input.UserInputType==Enum.UserInputType.Touch then
            local delta=input.Position-dragStart
            main.Position=UDim2.new(
                startPos.X.Scale,startPos.X.Offset+delta.X,
                startPos.Y.Scale,startPos.Y.Offset+delta.Y
            )
        end
    end)
end

-- Basic resize handle
local resize=mk("TextButton",{
    Size=UDim2.fromOffset(18,18),
    Position=UDim2.new(1,-20,1,-20),
    BackgroundTransparency=1,
    Text="◢",
    TextColor3=CFG.Dim,
    TextSize=12,
    Font=CFG.Bold,
},main)

do
    local resizing=false
    local startMouse
    local startSize

    resize.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1
        or input.UserInputType==Enum.UserInputType.Touch then
            resizing=true
            startMouse=input.Position
            startSize=main.AbsoluteSize
            input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then
                    resizing=false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not resizing then return end
        if input.UserInputType==Enum.UserInputType.MouseMovement
        or input.UserInputType==Enum.UserInputType.Touch then
            local d=input.Position-startMouse
            local w=math.max(650,startSize.X+d.X)
            local h=math.max(430,startSize.Y+d.Y)
            main.Size=UDim2.fromOffset(w,h)
        end
    end)
end

-- Keyboard shortcuts
UserInputService.InputBegan:Connect(function(input,processed)
    if processed or not gui.Parent then return end

    if input.KeyCode==Enum.KeyCode.RightShift then
        main.Visible=not main.Visible
    elseif input.KeyCode==Enum.KeyCode.F and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        search:CaptureFocus()
    elseif input.KeyCode==Enum.KeyCode.R and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        refreshTree()
    end
end)

refreshTree()
