
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

-- Function to iterate through all virtual devices, fetch debug messages, and summarize
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

    -- Print sorted summary of debug messages with clickable links
    fibaro:debug("Sorted summary of debug messages for virtual devices (excluding VDs with 0 messages):")
    for _, info in ipairs(summary) do
		local url = "http://" .. homeCenterIP .. "/fibaro/en/devices/virtual_edit.html?id=" .. info.id
        local clickableLink = '<a href="' .. url .. '">' .. "VD ID: " .. info.id .. ", Name: " .. info.name .. ", Debug Messages: " .. info.count .. '</a>'
        fibaro:debug(clickableLink)
    end
end

-- Execute the function to fetch and summarize debug messages for all virtual devices
fetchAndSummarizeDebugMessagesForAllVDs()
