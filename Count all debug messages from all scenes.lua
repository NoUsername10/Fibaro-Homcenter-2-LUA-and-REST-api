
-- Function to dynamically retrieve the Home Center IP address
function getHomeCenterIP()
    local networkSettings = api.get("/settings/network")
    return networkSettings.ip or "unknown IP"
end

-- Function to fetch and print debug messages for a specific Lua scene
function getSceneDebugInfo(sceneID)
    local endpoint = "/scenes/" .. sceneID .. "/debugMessages"
    local response, status = api.get(endpoint)

    if status == 200 and response and #response > 0 then
        local sceneName = api.get("/scenes/" .. sceneID).name or "Unnamed Scene"
        -- Only return details for scenes with debug messages
        return {id = sceneID, count = #response, name = sceneName}
    end

    return nil
end

-- Function to iterate through all Lua scenes, fetch debug messages, and summarize
function fetchAndSummarizeDebugMessagesForAllScenes()
    local homeCenterIP = getHomeCenterIP()
    local allScenes = api.get("/scenes")
    local summary = {}

    if allScenes then
        for _, scene in ipairs(allScenes) do
            local sceneInfo = getSceneDebugInfo(scene.id)
            if sceneInfo then
                table.insert(summary, sceneInfo)
            end
        end
    else
        fibaro:debug("Failed to retrieve Lua scenes list.")
        return
    end

    -- Sort summary by debug message count (lowest to highest)
    table.sort(summary, function(a, b) return a.count < b.count end)

    -- Define the text color as a variable for easy change
    local textColor = "green"

    -- Begin the HTML for the debug output with CSS that includes the text color variable
    local htmlOutput = "<style>:root { --text-color: " .. textColor .. "; } table{width:100%;border-collapse:collapse;background-color: #f4f4f4;}td,th{border:1px solid #888;padding:8px;text-align:left;color: var(--text-color);}tr:nth-child(even){background-color:#ddd;}tr:hover{background-color:#aaa;}th{padding-top:12px;padding-bottom:12px;text-align:left;background-color:#333;color:#fff;}</style>"
    htmlOutput = htmlOutput .. "Sorted summary of debug messages for Lua scenes (excluding scenes with 0 messages):<br><table><tr><th>Scene ID</th><th>Name</th><th>Debug Messages</th><th>Link</th></tr>"

    -- Loop through each Lua scene to add to the HTML string
    for _, info in ipairs(summary) do
        local url = "http://" .. homeCenterIP .. "/fibaro/en/scenes/edit.html?id=" .. info.id .. "#bookmark-advanced"
        local clickableLink = '<a href="' .. url .. '" style="color: #06c; text-decoration: underline;">Edit Scene</a>'
        htmlOutput = htmlOutput .. "<tr><td>" .. info.id .. "</td><td>" .. info.name .. "</td><td>" .. info.count .. "</td><td>" .. clickableLink .. "</td></tr>"
    end

    -- Close the HTML table
    htmlOutput = htmlOutput .. "</table>"

    -- Debug the final HTML output
    fibaro:debug(htmlOutput)
end

-- Execute the function to fetch and summarize debug messages for all Lua scenes
fetchAndSummarizeDebugMessagesForAllScenes()
