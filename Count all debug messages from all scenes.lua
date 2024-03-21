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

    -- Modern styling for the debug output
    local htmlOutput = [[
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            font-size: 14px;
        }
        table {
            width: 75%;
            border-collapse: collapse;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            background-color: #fafafa;
            margin-top: 20px;
            border-radius: 8px;
            overflow: hidden;
        }
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ccc;
        }
        th {
            background-color: #009688;
            color: #ffffff;
            font-weight: normal;
        }
        tr:hover {
            background-color: #DADADA;
        }
        td { 
            color: #000000; /* This line changes the text color to black */
        }
        a {
            color: #007bff;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
    </style>
    ]]

    htmlOutput = htmlOutput .. "Sorted summary of debug messages for Lua scenes (excluding scenes with 0 messages):<br><table><tr><th>Scene ID</th><th>Name</th><th>Debug Messages</th><th>Link</th></tr>"

    for _, info in ipairs(summary) do
        local url = "http://" .. homeCenterIP .. "/fibaro/en/scenes/edit.html?id=" .. info.id
        local clickableLink = '<a href="' .. url .. '">Edit Scene</a>'
        htmlOutput = htmlOutput .. "<tr><td>" .. info.id .. "</td><td>" .. info.name .. "</td><td>" .. info.count .. "</td><td>" .. clickableLink .. "</td></tr>"
    end

    htmlOutput = htmlOutput .. "</table>"

    fibaro:debug(htmlOutput)
end

fetchAndSummarizeDebugMessagesForAllScenes()
