
-- ID of the virtual device
local vdID = 963
-- Table to keep track of debug messages count and names for each element
local debugInfoSummary = {}

-- Function to fetch and print debug messages for a specific element of the virtual device
function getAndPrintElementDebugInfo(vdID, elementID, elementName)
    local endpoint = "/virtualDevices/" .. vdID .. "/debugMessages/" .. elementID
    local response, status = api.get(endpoint)

    if status == 200 and response then
        if next(response) ~= nil then
            -- Store the count of debug messages and the element name
            debugInfoSummary[elementID] = {count = #response, name = elementName}
            for _, message in ipairs(response) do
                fibaro:debug(message.txt)
            end
        else
            -- Account for the element ID with 0 messages
            debugInfoSummary[elementID] = {count = 0, name = elementName}
        end
    else
        fibaro:debug("Failed to retrieve debug information for Element ID: " .. elementID)
        debugInfoSummary[elementID] = {count = 0, name = elementName}
    end
end

-- Initialize summary for the main loop with a placeholder name "Main Loop"
debugInfoSummary[0] = {count = 0, name = "Main Loop"}

-- Function to fetch details of the virtual device, check for elements with "lua": true, and gather debug info
function fetchAndPrintDebugMessagesForLuaElements(vdID)
    -- Fetch and print debug info for the main loop (ID 0)
    getAndPrintElementDebugInfo(vdID, 0, "Main Loop")

    local vdDetails = api.get("/virtualDevices/" .. vdID)

    if vdDetails and vdDetails.properties and vdDetails.properties.rows then
        for _, row in ipairs(vdDetails.properties.rows) do
            for _, element in ipairs(row.elements) do
                -- Check for elements with Lua scripting enabled
                if element.lua == true then
                    getAndPrintElementDebugInfo(vdID, element.id, element.name)
                end
            end
        end
    else
        fibaro:debug("Failed to retrieve or parse details for VD ID: " .. vdID)
    end

    -- Print summary of debug messages count and names
    fibaro:debug("Summary of debug messages count and names:")
    for elementID, info in pairs(debugInfoSummary) do
        fibaro:debug("Element ID: " .. elementID .. ", Name: " .. info.name .. ", Debug Messages: " .. info.count)
    end
end

-- Execute the function
fetchAndPrintDebugMessagesForLuaElements(vdID)
