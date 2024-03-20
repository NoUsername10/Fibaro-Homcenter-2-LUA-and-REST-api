
-- Function to dynamically retrieve the Home Center IP address
function getHomeCenterIP()
    local networkSettings = api.get("/settings/network")
    return networkSettings.ip or "unknown IP"
end

-- Function to fetch and print debug messages for a specific element of the virtual device
function getVDDebugInfo(vdID)
    local endpoint = "/virtualDevices/" .. vdID .. "/debugMessages"
    local response, status = api.get(endpoint)

    if status == 200 and response and #response > 0 then
        local vdName = api.get("/virtualDevices/" .. vdID).name or "Unnamed VD"
        -- Only return details for VDs with debug messages
        return {id = vdID, count = #response, name = vdName}
    end

    return nil
end

-- Execute the function to fetch and summarize debug messages for all virtual devices
function fetchAndSummarizeDebugMessagesForAllVDs()
    local homeCenterIP = getHomeCenterIP()
    local allVDs = api.get("/virtualDevices")
    local summary = {}

    if allVDs then
        for _, vd in ipairs(allVDs) do
            local vdInfo = getVDDebugInfo(vd.id)
            if vdInfo then
                table.insert(summary, vdInfo)
            end
        end
    else
        fibaro:debug("Failed to retrieve virtual devices list.")
        return
    end

    -- Sort summary by debug message count (lowest to highest)
    table.sort(summary, function(a, b) return a.count < b.count end)

    -- Define the text color as a variable for easy change
    local textColor = "green"

    -- Begin the HTML for the debug output with CSS that includes the text color variable
    local htmlOutput = "<style>:root { --text-color: " .. textColor .. "; } table{width:100%;border-collapse:collapse;background-color: #f4f4f4;}td,th{border:1px solid #888;padding:8px;text-align:left;color: var(--text-color);}tr:nth-child(even){background-color:#ddd;}tr:hover{background-color:#aaa;}th{padding-top:12px;padding-bottom:12px;text-align:left;background-color:#333;color:#fff;}</style>"
    htmlOutput = htmlOutput .. "Sorted summary of debug messages for virtual devices (excluding VDs with 0 messages):<br><table><tr><th>VD ID</th><th>Name</th><th>Debug Messages</th><th>Link</th></tr>"

    -- Loop through each virtual device to add to the HTML string
    for _, info in ipairs(summary) do
        local url = "http://" .. homeCenterIP .. "/fibaro/en/devices/virtual_edit.html?id=" .. info.id
        local clickableLink = '<a href="' .. url .. '" style="color: #06c; text-decoration: underline;">Edit VD</a>'
        htmlOutput = htmlOutput .. "<tr><td>" .. info.id .. "</td><td>" .. info.name .. "</td><td>" .. info.count .. "</td><td>" .. clickableLink .. "</td></tr>"
    end

    -- Close the HTML table
    htmlOutput = htmlOutput .. "</table>"

    -- Debug the final HTML output
    fibaro:debug(htmlOutput)
end

-- Execute the function
fetchAndSummarizeDebugMessagesForAllVDs()
