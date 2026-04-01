-- FULL EXECUTOR CHAT SCRIPT
-- Works with Railway server: https://nodejs-production-656b7.up.railway.app/chat

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ================= CONFIG =================
local CHAT_URL = "https://nodejs-production-656b7.up.railway.app/chat"
local POLL_INTERVAL = 2 -- seconds

-- ================= SETTINGS STORAGE =================
local folder = PlayerGui:FindFirstChild("ExecChatSettings") or Instance.new("Folder", PlayerGui)
folder.Name = "ExecChatSettings"
local file = folder:FindFirstChild("Settings") or Instance.new("StringValue", folder)
file.Name = "Settings"

if file.Value == "" then
    file.Value = HttpService:JSONEncode({DisplayName = ""})
end

local settings = HttpService:JSONDecode(file.Value)

if settings.DisplayName == "" then
    settings.DisplayName = "ChatUser"..math.random(1,10000)
end

local function saveSettings()
    file.Value = HttpService:JSONEncode(settings)
end

-- ================= FILTER FUNCTION =================
local function filter(text)
    local ok, result = pcall(function()
        return TextService:FilterStringAsync(text, LocalPlayer.UserId):GetNonChatStringForBroadcastAsync()
    end)
    return ok and result or "[Filtered]"
end

-- ================= GUI =================
local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "ExecChat"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,350,0,300)
frame.Position = UDim2.new(1,-360,1,-320)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)

-- Topbar
local top = Instance.new("Frame", frame)
top.Size = UDim2.new(1,0,0,30)
top.BackgroundColor3 = Color3.fromRGB(45,45,45)

-- Cog button
local cog = Instance.new("TextButton", top)
cog.Text = "⚙"
cog.Size = UDim2.new(0,30,1,0)
cog.Position = UDim2.new(1,-35,0,0)

-- Minimize button
local minimize = Instance.new("TextButton", top)
minimize.Text = "_"
minimize.Size = UDim2.new(0,30,1,0)
minimize.Position = UDim2.new(1,-70,0,0)

-- Scrolling chat
local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1,0,1,-60)
scroll.Position = UDim2.new(0,0,0,30)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0,0,0,0)

local layout = Instance.new("UIListLayout", scroll)
layout.SortOrder = Enum.SortOrder.LayoutOrder

-- Input box
local box = Instance.new("TextBox", frame)
box.Size = UDim2.new(1,-10,0,25)
box.Position = UDim2.new(0,5,1,-30)
box.PlaceholderText = "Type a message..."
box.ClearTextOnFocus = true

-- ================= SETTINGS UI =================
local settingsFrame = Instance.new("Frame", gui)
settingsFrame.Size = frame.Size
settingsFrame.Position = frame.Position
settingsFrame.BackgroundColor3 = Color3.fromRGB(35,35,35)
settingsFrame.Visible = false

local displayBox = Instance.new("TextBox", settingsFrame)
displayBox.Size = UDim2.new(1,-10,0,30)
displayBox.Position = UDim2.new(0,5,0,20)
displayBox.Text = settings.DisplayName

local saveBtn = Instance.new("TextButton", settingsFrame)
saveBtn.Text = "Save"
saveBtn.Size = UDim2.new(0,100,0,30)
saveBtn.Position = UDim2.new(0,10,0,70)

local backBtn = Instance.new("TextButton", settingsFrame)
backBtn.Text = "Back"
backBtn.Size = UDim2.new(0,100,0,30)
backBtn.Position = UDim2.new(0,120,0,70)

-- ================= FUNCTIONS =================
local function addMessage(display, message)
    local msgLabel = Instance.new("TextLabel", scroll)
    msgLabel.Size = UDim2.new(1,0,0,20)
    msgLabel.BackgroundTransparency = 1
    msgLabel.TextColor3 = Color3.fromRGB(255,255,255)
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.Text = display..": "..message
    scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y)
end

-- Cog open
cog.MouseButton1Click:Connect(function()
    settingsFrame.Visible = true
    frame.Visible = false
end)

-- Back button
backBtn.MouseButton1Click:Connect(function()
    settingsFrame.Visible = false
    frame.Visible = true
end)

-- Save display
saveBtn.MouseButton1Click:Connect(function()
    if displayBox.Text ~= "" then
        settings.DisplayName = displayBox.Text
        saveSettings()
    end
end)

-- Minimize toggle
local minimized = false
minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    scroll.Visible = not minimized
    box.Visible = not minimized
end)

-- ================= SEND MESSAGE =================
box.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        if box.Text ~= "" and settings.DisplayName ~= "" then
            local filtered = filter(box.Text)
            pcall(function()
                game:HttpPost(CHAT_URL, HttpService:JSONEncode({
                    display = settings.DisplayName,
                    message = filtered
                }))
            end)
            box.Text = ""
        end
    end
end)

-- ================= RECEIVE LOOP =================
task.spawn(function()
    local lastCount = 0
    while true do
        local success, response = pcall(function()
            return game:HttpGet(CHAT_URL)
        end)
        if success then
            local data = HttpService:JSONDecode(response)
            if #data > lastCount then
                for i = lastCount+1, #data do
                    local msg = data[i]
                    addMessage(msg.display, msg.message)
                end
                lastCount = #data
            end
        end
        task.wait(POLL_INTERVAL)
    end
end)
