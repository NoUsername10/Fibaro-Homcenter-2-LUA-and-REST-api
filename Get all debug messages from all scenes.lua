
-- Function to get Home Center IP Address
function getHomeCenterIP()
    local networkSettings = api.get("/settings/network")
    return networkSettings.ip
end

-- Get Home Center IP Address
local homeCenterIP = getHomeCenterIP()

-- Get all scenes
local scenes = api.get("/scenes")

-- Table to store scene information
local sceneInfo = {}

for _, scene in ipairs(scenes) do
    -- Get debug messages for the scene
    local debugMessages = api.get("/scenes/" .. scene.id .. "/debugMessages")
    
    -- Count debug messages
    local debugCount = #debugMessages
    
    -- Only add scenes with one or more debug messages to the list
    if debugCount > 0 then
        table.insert(sceneInfo, {
            id = scene.id,
            name = scene.name,
            debugCount = debugCount,
            url = "http://" .. homeCenterIP .. "/fibaro/en/scenes/edit.html?id=" .. scene.id .. "#bookmark-advanced"
        })
    end
end

-- Sort scenes by debug message count, descending
table.sort(sceneInfo, function(a, b) return a.debugCount > b.debugCount end)

-- Output sorted information
for _, info in ipairs(sceneInfo) do
    fibaro:debug("Scene Name: " .. info.name .. ", ID: " .. info.id .. ", Debug Messages: " .. info.debugCount .. 
        " - <a href='" .. info.url .. "' target='_blank'>Open Scene</a>")
end

