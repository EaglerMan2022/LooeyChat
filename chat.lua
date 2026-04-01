print("Chat loading...")

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- executor request support
local request = (syn and syn.request) or (http and http.request) or http_request

if not request then
    warn("No HTTP request function found!")
    return
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "ExecChat"
pcall(function()
    gui.Parent = game.CoreGui
end)

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,300,0,200)
frame.Position = UDim2.new(1,-310,1,-210)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)

local label = Instance.new("TextLabel", frame)
label.Size = UDim2.new(1,-10,1,-50)
label.Position = UDim2.new(0,5,0,5)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.new(1,1,1)
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.Text = ""

local box = Instance.new("TextBox", frame)
box.Size = UDim2.new(1,-10,0,30)
box.Position = UDim2.new(0,5,1,-35)
box.PlaceholderText = "Type..."

local URL = "https://nodejs-production-656b7.up.railway.app/chat"

-- SEND
box.FocusLost:Connect(function(enter)
    if enter and box.Text ~= "" then
        print("Sending:", box.Text)

        request({
            Url = URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                display = "ChatUser"..math.random(1,9999),
                message = box.Text
            })
        })

        box.Text = ""
    end
end)

-- RECEIVE
task.spawn(function()
    while true do
        local res = request({
            Url = URL,
            Method = "GET"
        })

        if res and res.Body then
            local data = HttpService:JSONDecode(res.Body)
            local text = ""

            for _,msg in ipairs(data) do
                text = text .. msg.display .. ": " .. msg.message .. "\n"
            end

            label.Text = text
        end

        task.wait(2)
    end
end)

print("Chat loaded!")
