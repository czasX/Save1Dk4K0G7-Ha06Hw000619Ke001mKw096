-- STRUGLIX REMOTE SPY • ONE FILE
-- For debugging a game you control.
-- Roblox client APIs do not expose a universal listener for every remote call.
-- This file catalogs remotes and accepts explicit reports through
-- _G.StruglixRemoteSpy.Log(remote, direction, args, playerName, extra).

local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local HttpService=game:GetService("HttpService")
local LP=Players.LocalPlayer
local PG=LP:WaitForChild("PlayerGui")

local C={
 Bg=Color3.fromRGB(9,10,14),Panel=Color3.fromRGB(16,18,24),
 Panel2=Color3.fromRGB(22,24,32),Row=Color3.fromRGB(28,30,40),
 Text=Color3.fromRGB(235,237,242),Dim=Color3.fromRGB(140,145,158),
 Accent=Color3.fromRGB(155,95,255),Blue=Color3.fromRGB(70,170,255),
 Green=Color3.fromRGB(75,210,135),Red=Color3.fromRGB(245,85,105),
 Yellow=Color3.fromRGB(245,190,75)
}
local MAX_LOGS=2500
local MAX_ROWS=900

local function mk(c,p,parent)
 local x=Instance.new(c)
 for k,v in pairs(p or {}) do x[k]=v end
 x.Parent=parent
 return x
end
local function corner(x,r)
 local u=Instance.new("UICorner");u.CornerRadius=UDim.new(0,r or 6);u.Parent=x
end
local function stroke(x,c,t)
 local u=Instance.new("UIStroke");u.Color=c or C.Panel2;u.Thickness=t or 1;u.Transparency=.15;u.Parent=x
end
local function clear(f)
 for _,x in ipairs(f:GetChildren()) do if not x:IsA("UIListLayout") then x:Destroy() end end
end
local function path(o)
 local ok,v=pcall(function() return o:GetFullName() end)
 return ok and v or tostring(o)
end
local function cloneValue(v,depth,seen)
 depth=depth or 0;seen=seen or {}
 if depth>6 then return "<depth>" end
 local t=typeof(v)
 if t=="Instance" then
  return {__instance=true,class=v.ClassName,name=v.Name,path=path(v)}
 elseif t=="table" then
  if seen[v] then return "<cycle>" end
  seen[v]=true
  local r={};local n=0
  for k,x in pairs(v) do
   n+=1;if n>120 then r["<limit>"]="...";break end
   r[tostring(k)]=cloneValue(x,depth+1,seen)
  end
  return r
 end
 return v
end
local function pretty(v,depth,seen)
 depth=depth or 0;seen=seen or {}
 local t=typeof(v)
 if t=="table" then
  if seen[v] then return "<cycle>" end
  seen[v]=true
  local r={"{"}
  local keys={}
  for k in pairs(v) do keys[#keys+1]=k end
  table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
  for _,k in ipairs(keys) do
   r[#r+1]=string.rep("  ",depth+1)..tostring(k).." = "..pretty(v[k],depth+1,seen)
  end
  r[#r+1]=string.rep("  ",depth).."}"
  return table.concat(r,"\n")
 elseif t=="string" then return string.format("%q",v)
 elseif t=="Instance" then return "<"..v.ClassName.."> "..path(v)
 else return tostring(v) end
end
local function purpose(o)
 local n=(o.Name.." "..o.ClassName.." "..path(o)):lower()
 local rules={
  {"purchase|buy|shop|store|price","Purchase / economy"},
  {"damage|hit|attack|combat|kill","Combat / damage"},
  {"teleport|tp|warp","Teleport / movement"},
  {"admin|ban|kick|mute|mod","Moderation / admin"},
  {"inventory|item|equip|tool","Inventory / item"},
  {"chat|message|say|text","Chat / messaging"},
  {"quest|mission|objective","Quest / progression"},
  {"data|save|load|profile","Data / persistence"},
  {"spawn|summon","Spawn / creation"},
  {"trade|gift","Trading / transfer"}
 }
 for _,r in ipairs(rules) do
  for token in r[1]:gmatch("[^|]+") do if n:find(token,1,true) then return r[2] end end
 end
 return o:IsA("RemoteEvent") and "Event communication endpoint" or "Function communication endpoint"
end

local gui=mk("ScreenGui",{Name="StruglixRemoteSpy",ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},PG)
local main=mk("Frame",{Size=UDim2.fromOffset(1060,650),Position=UDim2.new(.5,-530,.5,-325),BackgroundColor3=C.Bg,BorderSizePixel=0},gui)
corner(main,10);stroke(main,Color3.fromRGB(58,50,85),1)
local top=mk("Frame",{Size=UDim2.new(1,0,0,48),BackgroundColor3=C.Panel,BorderSizePixel=0},main);corner(top,10)
local title=mk("TextLabel",{Size=UDim2.new(1,-250,1,0),Position=UDim2.fromOffset(14,0),BackgroundTransparency=1,Text="◈  STRUGLIX  /  REMOTE SPY",TextColor3=C.Text,Font=Enum.Font.GothamBold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},top)
local state=mk("TextLabel",{Size=UDim2.fromOffset(125,30),Position=UDim2.new(1,-265,0,9),BackgroundTransparency=1,Text="● RECORDING",TextColor3=C.Green,Font=Enum.Font.GothamBold,TextSize=9},top)
local mini=mk("TextButton",{Size=UDim2.fromOffset(34,30),Position=UDim2.new(1,-86,0,9),BackgroundColor3=C.Panel2,Text="−",TextColor3=C.Text,Font=Enum.Font.GothamBold,TextSize=17,BorderSizePixel=0},top);corner(mini,6)
local close=mk("TextButton",{Size=UDim2.fromOffset(34,30),Position=UDim2.new(1,-46,0,9),BackgroundColor3=Color3.fromRGB(55,25,34),Text="×",TextColor3=C.Red,Font=Enum.Font.GothamBold,TextSize=17,BorderSizePixel=0},top);corner(close,6)

local search=mk("TextBox",{Size=UDim2.new(1,-430,0,34),Position=UDim2.fromOffset(14,60),BackgroundColor3=C.Panel2,PlaceholderText="Search remote / path / class / player / purpose / argument...",PlaceholderColor3=C.Dim,Text="",TextColor3=C.Text,Font=Enum.Font.Gotham,TextSize=10,ClearTextOnFocus=false,BorderSizePixel=0},main);corner(search,6)
local function btn(txt,x,w)
 local b=mk("TextButton",{Size=UDim2.fromOffset(w,34),Position=UDim2.fromOffset(x,60),BackgroundColor3=C.Panel2,Text=txt,TextColor3=C.Text,Font=Enum.Font.GothamBold,TextSize=8,BorderSizePixel=0},main);corner(b,6);return b
end
local aiBtn=btn("AI • ON",640,72)
local pauseBtn=btn("PAUSE",718,72)
local clearBtn=btn("CLEAR",796,72)
local sortBtn=btn("SORT • NEW",874,92)

local nav=mk("Frame",{Size=UDim2.new(1,-28,0,36),Position=UDim2.fromOffset(14,103),BackgroundTransparency=1},main)
local tabs={"ALL","EVENTS","FUNCTIONS","PLAYERS","SERVER","UNIQUE"}
local active="ALL";local tabButtons={}
for i,n in ipairs(tabs) do
 local b=mk("TextButton",{Size=UDim2.fromOffset(82,30),Position=UDim2.fromOffset((i-1)*86,0),BackgroundColor3=(i==1 and C.Accent or C.Panel2),Text=n,TextColor3=C.Text,Font=Enum.Font.GothamBold,TextSize=8,BorderSizePixel=0},nav);corner(b,5);tabButtons[n]=b
end

local left=mk("ScrollingFrame",{Size=UDim2.new(.39,-18,1,-181),Position=UDim2.fromOffset(14,145),BackgroundColor3=C.Panel,BorderSizePixel=0,ScrollBarThickness=5,ScrollBarImageColor3=C.Accent,AutomaticCanvasSize=Enum.AutomaticSize.Y},main);corner(left,7)
mk("UIListLayout",{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder},left)
local right=mk("Frame",{Size=UDim2.new(.61,-10,1,-181),Position=UDim2.new(.39,4,0,145),BackgroundColor3=C.Panel,BorderSizePixel=0},main);corner(right,7)
local detailTitle=mk("TextLabel",{Size=UDim2.new(1,-20,0,34),Position=UDim2.fromOffset(10,8),BackgroundTransparency=1,Text="SELECT A REMOTE",TextColor3=C.Blue,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},right)
local detail=mk("ScrollingFrame",{Size=UDim2.new(1,-20,1,-52),Position=UDim2.fromOffset(10,46),BackgroundColor3=C.Bg,BorderSizePixel=0,ScrollBarThickness=5,ScrollBarImageColor3=C.Accent,AutomaticCanvasSize=Enum.AutomaticSize.Y},right);corner(detail,6)
mk("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},detail)
local footer=mk("TextLabel",{Size=UDim2.new(1,-28,0,20),Position=UDim2.new(0,14,1,-29),BackgroundTransparency=1,Text="0 remotes • 0 captured",TextColor3=C.Dim,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},main)

local logs={};local remotes={};local selected=nil;local ai=true;local paused=false;local minimized=false;local sortMode="NEW"
local function signature(e)
 local ok,j=pcall(function()return HttpService:JSONEncode(cloneValue(e.args or {}))end)
 return tostring(e.direction).."|"..tostring(e.path).."|"..tostring(e.class).."|"..(ok and j or "")
end
local function scan()
 table.clear(remotes)
 for _,o in ipairs(game:GetDescendants()) do if o:IsA("RemoteEvent") or o:IsA("RemoteFunction") then remotes[#remotes+1]=o end end
 table.sort(remotes,function(a,b)return path(a):lower()<path(b):lower()end)
end
local function addLog(e)
 if paused then return end
 e.t=e.t or os.clock();e.id=HttpService:GenerateGUID(false);e.signature=e.signature or signature(e)
 e.args=cloneValue(e.args or {})
 logs[#logs+1]=e
 while #logs>MAX_LOGS do table.remove(logs,1) end
end

local render
local function show(e)
 clear(detail);selected=e
 if not e then detailTitle.Text="SELECT A REMOTE";return end
 detailTitle.Text=tostring(e.remoteName).."  •  "..tostring(e.class)
 local box=mk("Frame",{Size=UDim2.new(1,0,0,138),BackgroundColor3=C.Panel2,BorderSizePixel=0},detail);corner(box,6)
 mk("TextLabel",{Size=UDim2.new(1,-18,1,-10),Position=UDim2.fromOffset(9,5),BackgroundTransparency=1,Text=table.concat({
  "Remote: "..tostring(e.remoteName),"Class: "..tostring(e.class),"Path: "..tostring(e.path),
  "Direction: "..tostring(e.direction),"Player: "..tostring(e.playerName or "Server"),
  "Purpose: "..tostring(e.purpose or "Unknown"),"Captured: "..os.date("%H:%M:%S")
 },"\n"),TextColor3=C.Text,TextSize=9,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top},box)
 local head=mk("TextLabel",{Size=UDim2.new(1,-12,0,25),BackgroundTransparency=1,Text="ARGUMENTS  •  click an entry to expand",TextColor3=C.Accent,Font=Enum.Font.GothamBold,TextSize=8,TextXAlignment=Enum.TextXAlignment.Left},detail)
 for k,v in pairs(e.args or {}) do
  local b=mk("TextButton",{Size=UDim2.new(1,-8,0,30),BackgroundColor3=C.Row,Text="▶  "..tostring(k).."  :  "..typeof(v),TextColor3=C.Text,Font=Enum.Font.Code,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,BorderSizePixel=0},detail);corner(b,5)
  local open=false;local child
  b.MouseButton1Click:Connect(function()
   open=not open
   if child then child:Destroy();child=nil end
   if open then
    child=mk("TextLabel",{Size=UDim2.new(1,-16,0,math.min(300,math.max(36,#pretty(v)*.42))),BackgroundColor3=C.Bg,Text=pretty(v),TextColor3=(typeof(v)=="string" and C.Green or C.Text),TextSize=9,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top},detail)
    child.LayoutOrder=b.LayoutOrder+1;b.Text="▼  "..tostring(k).."  :  "..typeof(v)
   else b.Text="▶  "..tostring(k).."  :  "..typeof(v) end
  end)
 end
end
local function matches(e,q)
 if q=="" then return true end
 local blob=(tostring(e.remoteName).." "..tostring(e.path).." "..tostring(e.class).." "..tostring(e.playerName or "").." "..tostring(e.purpose or "").." "..pretty(e.args or {})):lower()
 for t in q:lower():gmatch("%S+") do if not blob:find(t,1,true) then return false end end
 return true
end
render=function()
 clear(left)
 local rows={};local q=search.Text
 if active=="PLAYERS" then
  local p={}
  for _,e in ipairs(logs) do local n=e.playerName or "Server";p[n]=(p[n] or 0)+1 end
  for n,cnt in pairs(p) do rows[#rows+1]={remoteName=n,class="PLAYER",path="Player history",direction="HISTORY",playerName=n,_count=cnt,purpose="Remote activity",t=0,args={}} end
 else
  local src=logs
  if active=="EVENTS" or active=="FUNCTIONS" then
   src={}
   for _,e in ipairs(logs) do if (active=="EVENTS" and e.class=="RemoteEvent") or (active=="FUNCTIONS" and e.class=="RemoteFunction") then src[#src+1]=e end end
  end
  if #src==0 then
   for _,r in ipairs(remotes) do src[#src+1]={remoteName=r.Name,class=r.ClassName,path=path(r),direction="CATALOG",playerName="—",purpose=purpose(r),args={},t=0,signature="CATALOG|"..path(r)} end
  end
  local seen={}
  for _,e in ipairs(src) do
   if matches(e,q) then
    if active=="UNIQUE" then
     local k=e.signature or signature(e)
     if not seen[k] then seen[k]=true;e._count=1;rows[#rows+1]=e
     else for _,x in ipairs(rows) do if (x.signature or "")==k then x._count=(x._count or 1)+1;break end end end
    else rows[#rows+1]=e end
   end
  end
 end
 table.sort(rows,function(a,b)
  if sortMode=="NAME" then return tostring(a.remoteName):lower()<tostring(b.remoteName):lower() end
  if sortMode=="COUNT" then return (a._count or 1)>(b._count or 1) end
  if sortMode=="OLD" then return (a.t or 0)<(b.t or 0) end
  return (a.t or 0)>(b.t or 0)
 end)
 local n=0
 for _,e in ipairs(rows) do
  n+=1;if n>MAX_ROWS then break end
  local r=mk("TextButton",{Size=UDim2.new(1,-8,0,46),BackgroundColor3=(selected==e and Color3.fromRGB(43,36,62) or C.Row),Text="",BorderSizePixel=0,LayoutOrder=n},left);corner(r,6)
  mk("TextLabel",{Size=UDim2.new(1,-15,0,22),Position=UDim2.fromOffset(8,3),BackgroundTransparency=1,Text=(e.class=="RemoteFunction" and "ƒ  " or "◉  ")..tostring(e.remoteName),TextColor3=C.Text,Font=Enum.Font.GothamBold,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},r)
  mk("TextLabel",{Size=UDim2.new(1,-15,0,16),Position=UDim2.fromOffset(8,25),BackgroundTransparency=1,Text=tostring(e.direction).."  •  "..tostring(e.playerName or "Server"),TextColor3=(e.direction=="CLIENT → SERVER" and C.Blue or C.Green),Font=Enum.Font.Code,TextSize=7,TextXAlignment=Enum.TextXAlignment.Left},r)
  if e._count and e._count>1 then
   local c=mk("TextLabel",{Size=UDim2.fromOffset(42,20),Position=UDim2.new(1,-49,0,13),BackgroundColor3=C.Accent,Text="x"..e._count,TextColor3=C.Text,Font=Enum.Font.GothamBold,TextSize=8,BorderSizePixel=0},r);corner(c,5)
  end
  r.MouseButton1Click:Connect(function()show(e);render()end)
 end
 footer.Text=string.format("%d remotes • %d captured • %d shown • AI %s • %s",#remotes,#logs,n,ai and "ON" or "OFF",sortMode)
end

_G.StruglixRemoteSpy={
 Log=function(remote,direction,args,playerName,extra)
  if typeof(remote)~="Instance" then return end
  local e={remoteName=remote.Name,class=remote.ClassName,path=path(remote),direction=direction or "UNKNOWN",playerName=playerName or LP.Name,args=args or {},purpose=purpose(remote)}
  if type(extra)=="table" then for k,v in pairs(extra) do e[k]=v end end
  addLog(e);pcall(render)
 end,
 Clear=function()table.clear(logs);pcall(render)end,
 Refresh=function()scan();pcall(render)end,
}

for name,b in pairs(tabButtons) do b.MouseButton1Click:Connect(function()
 active=name
 for n,x in pairs(tabButtons) do x.BackgroundColor3=(n==name and C.Accent or C.Panel2) end
 render()
end)end
search:GetPropertyChangedSignal("Text"):Connect(function()
 task.delay(.12,function()if gui.Parent then pcall(render)end end)
end)
aiBtn.MouseButton1Click:Connect(function()ai=not ai;aiBtn.Text="AI • "..(ai and "ON" or "OFF");render()end)
pauseBtn.MouseButton1Click:Connect(function()paused=not paused;pauseBtn.Text=paused and "RESUME" or "PAUSE";state.Text=paused and "Ⅱ PAUSED" or "● RECORDING";state.TextColor3=paused and C.Yellow or C.Green end)
clearBtn.MouseButton1Click=function()end
clearBtn.MouseButton1Click:Connect(function()table.clear(logs);show(nil);render()end)
sortBtn.MouseButton1Click:Connect(function()
 local m={"NEW","OLD","NAME","COUNT"};local i=1
 for n,v in ipairs(m) do if v==sortMode then i=n end end
 sortMode=m[i%#m+1];sortBtn.Text="SORT • "..sortMode;render()
end)
close.MouseButton1Click:Connect(function()gui.Enabled=false end)
UIS.InputBegan:Connect(function(i,gp)
 if gp then return end
 if i.KeyCode==Enum.KeyCode.RightShift then gui.Enabled=not gui.Enabled
 elseif i.KeyCode==Enum.KeyCode.F and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then search:CaptureFocus() end
end)

local drag=false;local ds;local sp
top.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true;ds=i.Position;sp=main.Position end end)
UIS.InputChanged:Connect(function(i)
 if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
  local d=i.Position-ds;main.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
 end
end)
UIS.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end end)

mini.MouseButton1Click:Connect(function()
 minimized=not minimized
 if minimized then
  main.Size=UDim2.fromOffset(180,54);title.Text="◈  STRUGLIX";mini.Text="OPEN"
  search.Visible=false;aiBtn.Visible=false;pauseBtn.Visible=false;clearBtn.Visible=false;sortBtn.Visible=false;nav.Visible=false;left.Visible=false;right.Visible=false;footer.Visible=false;state.Visible=false
 else
  main.Size=UDim2.fromOffset(1060,650);title.Text="◈  STRUGLIX  /  REMOTE SPY";mini.Text="−"
  search.Visible=true;aiBtn.Visible=true;pauseBtn.Visible=true;clearBtn.Visible=true;sortBtn.Visible=true;nav.Visible=true;left.Visible=true;right.Visible=true;footer.Visible=true;state.Visible=true
  render()
 end
end)

scan();render()
