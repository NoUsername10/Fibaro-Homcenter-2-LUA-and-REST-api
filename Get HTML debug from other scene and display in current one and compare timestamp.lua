local otherSceneID = 480 -- ID of the other scene to get / check for debug messages
local currentSceneID = __fibaroSceneId -- ID of the current scene

-- Function to convert timestamp to readable format
function formatTimestamp(timestamp)
    return os.date("!%Y-%m-%d %H:%M:%S", timestamp)
end

-- Function to check if message already exists in the current scene's debug messages
function messageAlreadyExists(formattedMessage)
    local response = api.get("/scenes/" .. currentSceneID .. "/debugMessages")
    if response then
        for _, msg in ipairs(response) do
            if msg.txt == formattedMessage then
                return true
            end
        end
    end
    return false
end

-- Function to fetch and display HTML-style debug messages from another scene
function fetchAndDisplayHtmlDebugMessages()
    local response = api.get("/scenes/" .. otherSceneID .. "/debugMessages")
    
    if response then
        for _, messageObj in ipairs(response) do
            local timestamp = messageObj.timestamp
            local readableTimestamp = formatTimestamp(timestamp)
            local messageWithTimestamp = readableTimestamp .. " - " .. messageObj.txt
            
            -- Check if the message is HTML-style and not already displayed
            if string.find(messageObj.txt, "<style") and not messageAlreadyExists(messageWithTimestamp) then
                fibaro:debug(messageWithTimestamp)
            end
        end
    else
        fibaro:debug("Failed to fetch debug messages from scene " .. otherSceneID)
    end
end

fetchAndDisplayHtmlDebugMessages()
