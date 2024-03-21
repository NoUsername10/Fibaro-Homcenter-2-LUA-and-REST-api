-- Example: Attempt to set the "value" property of a motion sensor to false if it's stuck or not responing in breached mode.

local deviceID = 670 -- Replace with your actual device ID
local data = {
    properties = {
        value = false
    }
}

local response, status = api.put("/devices/" .. deviceID, data)

if status == 200 then
    fibaro:debug("Device property updated successfully.")
else
    fibaro:debug("Failed to update device property. Status: " .. tostring(status))
end
