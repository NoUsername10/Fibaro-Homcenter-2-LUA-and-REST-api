-- Configuration and initial setup
-- input all your sensors here.
local sensor_IDs = {
    670, 685, 686, 676, 681, 680, 675, 429, 404, 32, 419, 245, 309, 520, 409, 437, 424, 691, 585, 595, 690, 561, 566, 669
}
local sensorStates = { totalArmed = 0, totalBreached = 0, totalBreachedAndArmed = 0 }

-- Utility functions pre-declaration
local utils = {}

-- Constants
local API_ENDPOINTS = {
    DEVICE_INFO = "/devices/%s",
    ROOMS = "/rooms/%s",
    GLOBAL_VARIABLES = "/globalVariables/alarm_arm_state",
    NETWORK_SETTINGS = "/settings/network" -- Added network settings endpoint
}

local SENSOR_STATES = {
    BREACHED = "true",
    ARMED = "true"
}

-- Trim function
function utils.trim(s)
    return s:match("^%s*(.-)%s*$")
end

function utils.apiRequest(url, method)
    method = method or "GET"
    local success, response = pcall(api[method:lower()], url)
  
    -- Special handling for DELETE requests where a nil response might still mean success
    if method == "DELETE" then
        if success then
            -- Consider the operation successful even if the response is nil
            --fibaro:debug("DELETE request executed successfully: " .. url)
            return true  -- Indicate success
        else
            fibaro:debug("Failed DELETE request: " .. url)
            return false  -- Indicate failure
        end
    else
        -- Handling for all other request types (GET, POST, PUT)
        if not success or not response then
            fibaro:debug("Failed API call: " .. url)
            return nil
        end
        return response
    end
end

-- Get Home Center IP Address Dynamically
function utils.getHomeCenterIP()
    local networkSettings = utils.apiRequest(API_ENDPOINTS.NETWORK_SETTINGS)
    return networkSettings and networkSettings.ip or "unknown IP"
end

-- Modified function to directly output HTML content
function utils.debugHtml(htmlContent)
    fibaro:debug(htmlContent)
end

-- Custom Debug Function with HTML Color Support
function utils.fd(message, color, deviceId)
    local homeCenterIP = utils.getHomeCenterIP()
    local colorChoice = {
        red = 'red', yellow = 'yellow', blue = 'blue', green = 'green', grey = 'grey',
        black = 'black', white = 'white', purple = 'purple', orange = 'orange', pink = 'pink'
    }
    local colorCode = colorChoice[color] or 'grey'
    local deviceLink = deviceId and string.format("http://%s/fibaro/en/devices/configuration.html?id=%d", homeCenterIP, deviceId) or "#"
    local messageWithLink = deviceId and string.format("<a href='%s' target='_blank'>%s</a>", deviceLink, message) or message
    fibaro:debug(utils.trim(messageWithLink))
  	--fibaro:debug(utils.trim(string.format("<span style='color:grey;'>[%s]</span> <span style='color:%s;'>%s</span>", os.date("%Y-%m-%d"), colorCode, messageWithLink)))
end

-- Fetch Room Name Using API
function utils.getRoomName(roomID)
    local roomResponse = utils.apiRequest(string.format(API_ENDPOINTS.ROOMS, roomID))
    return roomResponse and roomResponse.name or "Unknown Room"
end

-- Extend sensorStates to hold lists of sensor details
sensorStates.detailsArmed = {}
sensorStates.detailsBreached = {}
sensorStates.detailsBreachedAndArmed = {}

function utils.processDeviceSummary(deviceResponse, sensorID)
    local isBreached = tostring(deviceResponse.properties.value) == SENSOR_STATES.BREACHED
    local isArmed = tostring(deviceResponse.properties.armed) == SENSOR_STATES.ARMED
    local detail = string.format("ID: %d - %s", sensorID, deviceResponse.name or "Unknown Device")
    
    if isArmed then
        sensorStates.totalArmed = sensorStates.totalArmed + 1
        table.insert(sensorStates.detailsArmed, detail)
    end
    if isBreached then
        sensorStates.totalBreached = sensorStates.totalBreached + 1
        table.insert(sensorStates.detailsBreached, detail)
    end
    if isBreached and isArmed then
        sensorStates.totalBreachedAndArmed = sensorStates.totalBreachedAndArmed + 1
        table.insert(sensorStates.detailsBreachedAndArmed, detail)
    end
end

-- Device Summary Processing
function utils.checkDevicesAndCompileSummary()
    for _, sensorID in ipairs(sensor_IDs) do
        local deviceResponse = utils.apiRequest(string.format(API_ENDPOINTS.DEVICE_INFO, sensorID))
        if deviceResponse and deviceResponse.properties then
            utils.processDeviceSummary(deviceResponse, sensorID)
        else
            utils.fd("Failed to get device information for ID: " .. sensorID, 'red', sensorID)
        end
    end
    -- Summary of the checks
    --[[
    utils.fd("Total Devices Checked: " .. #sensor_IDs, 'blue')
    utils.fd("Total Armed: " .. sensorStates.totalArmed, 'green')
    utils.fd("Total Breached: " .. sensorStates.totalBreached, 'pink')
    utils.fd("Total Breached and Armed: " .. sensorStates.totalBreachedAndArmed, 'orange')
    --]]
end


local function generateSensorDetailsHTML(detailsList)
    if #detailsList == 0 then return "None" end
    local homeCenterIP = utils.getHomeCenterIP()  -- Ensure this gets the IP address of your Home Center
    local itemsHtml = ""
    for _, detail in ipairs(detailsList) do
        -- Assuming detail is formatted as "ID: <id>, Name: <name>, Room: <room>"
        -- Extract the ID to use in the URL
        local id = detail:match("ID: (%d+)")
        local url = "http://" .. homeCenterIP .. "/fibaro/en/devices/configuration.html?id=" .. id
        local linkHtml = string.format("<a href='%s' target='_blank'>%s</a>", url, detail)
        itemsHtml = itemsHtml .. "<li>" .. linkHtml .. "</li>"
    end
    return "<ul>" .. itemsHtml .. "</ul>"
end

local function outputSummary(startSourceString)
    -- Color Variables for Enhanced Readability
    local headerBgColor = "#007bff"; -- A darker blue for the header for contrast with white text
    local textColor = "#000000"; -- Black text for maximum visibility on light backgrounds
    local rowBgColorTotalDevices = "#E1F5FE"; -- Light blue
    local rowBgColorTotalArmed = "#E8F5E9"; -- Light green
    local rowBgColorTotalBreached = "#FCE4EC"; -- Light pink
    local rowBgColorTotalBreachedArmed = "#FFF3E0"; -- Light orange

    local summaryHtml = table.concat({
        "<style>",
        "body { font-family: Arial, sans-serif; font-size: 14px; }",
        ".summaryTable {",
        "  width: 100%;",
        "  border-collapse: collapse;",
        "  margin-top: 10px;",
        "  box-shadow: 0 4px 8px rgba(0,0,0,0.2);", -- Enhanced shadow for 3D effect
        "  border-radius: 8px;", -- Slightly larger radius for a softer edge
        "  overflow: hidden;",
        "}",
        ".summaryTable th, .summaryTable td {",
        "  padding: 8px 15px;", -- Increased padding for a more spacious look
        "  text-align: left;",
        "  border-bottom: 2px solid #f0f0f0;", -- Thicker bottom border for depth
        "  color: ", textColor, ";",
        "  background-image: linear-gradient(to bottom, #ffffff, ", rowBgColorTotalDevices, ");", -- Gradient background for cells
        "}",
        ".summaryTable th {",
        "  background-color: ", headerBgColor, ";",
        "  background-image: linear-gradient(to bottom, ", headerBgColor, ", #0056b3);", -- Gradient for header
        "  color: #ffffff;",
        "  font-weight: bold;", -- Bold font weight for headers
        "  text-shadow: 0px 1px 1px rgba(0,0,0,0.2);", -- Text shadow for 3D text effect
        "}",
        ".summaryTable tr:last-child td {",
        "  border-bottom: none;",
        "}",
        ".totalDevices { background-image: linear-gradient(to bottom, #ffffff, ", rowBgColorTotalDevices, "); }",
        ".totalArmed { background-image: linear-gradient(to bottom, #ffffff, ", rowBgColorTotalArmed, "); }",
        ".totalBreached { background-image: linear-gradient(to bottom, #ffffff, ", rowBgColorTotalBreached, "); }",
        ".totalBreachedArmed { background-image: linear-gradient(to bottom, #ffffff, ", rowBgColorTotalBreachedArmed, "); }",
        "</style>",
        "<table class='summaryTable'>",
        "<tr><th>Summary Item</th><th>Count</th><th>Details</th></tr>",

      	-- For each category, include a new cell with details
      	"<tr class='startSource'><td>Date: ", os.date("%Y-%m-%d"), "</td><td>-</td><td>Time: ", os.date("%H:%M:%S"), "</td></tr>",
      	"<tr class='startSource'><td>Source of start: </td><td>", "-", "</td><td>", startSourceString, "</td></tr>",
        "<tr class='totalDevices'><td>Total Devices Checked</td><td>", #sensor_IDs, "</td><td>", "See details below", "</td></tr>",
        "<tr class='totalArmed'><td>Total Armed</td><td>", sensorStates.totalArmed, "</td><td>", generateSensorDetailsHTML(sensorStates.detailsArmed), "</td></tr>",
        "<tr class='totalBreached'><td>Total Breached</td><td>", sensorStates.totalBreached, "</td><td>", generateSensorDetailsHTML(sensorStates.detailsBreached), "</td></tr>",
        "<tr class='totalBreachedAndArmed'><td>Total Breached and Armed</td><td>", sensorStates.totalBreachedAndArmed, "</td><td>", generateSensorDetailsHTML(sensorStates.detailsBreachedAndArmed), "</td></tr>",
        "</table>"
    }, "")

    utils.fd(summaryHtml)  -- Make sure the utils.fd function is capable of interpreting and displaying HTML.
end


function clearDebugMessagesUsingUtils()
    local sceneID = __fibaroSceneId  -- Use the predefined variable to get the current scene's ID
    local success, _ = pcall(utils.apiRequest, "/scenes/" .. sceneID .. "/debugMessages", "DELETE")

    if success then
        --fibaro:debug("Debug messages cleared successfully.")
    else
        fibaro:debug("Failed to clear debug messages with clearDebugMessagesUsingUtils.")
    end
end


-- Main logic including initial checks
local function main()
    local alarmArmState = utils.apiRequest(API_ENDPOINTS.GLOBAL_VARIABLES)

    -- Ensure the scene was started by a sensor event and the alarm state is as expected
    local startSource = fibaro:getSourceTrigger()
    local sensorID = startSource.deviceID and tonumber(startSource.deviceID) or nil
  
      -- Convert startSource to a string representation for display
    local startSourceString
    if startSource['type'] == 'other' then
        startSourceString = "Manual"
    elseif startSource['type'] == 'property' then
        startSourceString = "Device ID: " .. startSource['deviceID']
    -- Add more conditions here if needed to handle different startSource types
    else
        startSourceString = tostring(startSource['type'])
    end
  
    if not sensorID then
        --utils.fd("Scene not started with sensor. ID: " .. tostring(startSource.type), 'grey')
        utils.checkDevicesAndCompileSummary()
    	--fibaro:sleep(3000)
    	--utils.fd("Aborting scene", 'grey')

    	-- Call the function to clear debug messages
    	--clearDebugMessagesUsingUtils()
    	
    	outputSummary(startSourceString)
    	
    	return fibaro:abort()
    end

    if not alarmArmState or alarmArmState.value == "0" then
        --utils.fd("Aborting scene, alarm not activated.", 'grey')
        return fibaro:abort()
    end

    local deviceResponse = utils.apiRequest(string.format(API_ENDPOINTS.DEVICE_INFO, sensorID))
    if not deviceResponse or not deviceResponse.properties then
        utils.fd("Failed to get device information.", 'red')
        return fibaro:abort()
    end

    local deviceArmed = tostring(deviceResponse.properties.armed) == SENSOR_STATES.ARMED
    local deviceValue = tostring(deviceResponse.properties.value) == SENSOR_STATES.BREACHED

    if not deviceArmed then
        utils.fd("Aborting scene, unarmed sensor. ID: " .. sensorID, 'grey')
        return fibaro:abort()
    end

    if not deviceValue then
        utils.fd("Aborting scene, deactivated sensor. ID: " .. sensorID, 'grey')
        return fibaro:abort()
    end

    -- If all checks pass, proceed with device and compile summary
    utils.checkDevicesAndCompileSummary()
end

main()
