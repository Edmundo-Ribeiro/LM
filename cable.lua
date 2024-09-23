local Cable = require('user.controlart')

-- Retrieves the IO status from the device by sending a command
-- @return string or nil: Returns the response string if successful, nil otherwise
function Cable:getIO()

    local cmd = "mdcmd_getmd," .. self.MAC
    local res = self:sendCommand(cmd)

    -- If the command response contains 'setcmd', it updates the IO status
    if (string.match(res, 'setcmd')) then
        self:updateIO(res)
        return res
    end

    return nil
end

-- Updates the IO (input/output) states based on the response string
-- @param res string: The response string containing IO data
-- @return nil
function Cable:updateIO(res)

    local last_input_index = 0

    -- Determine last input index based on device type (relay or dimmer)
    if self:checkType(TYPES.CABLE_RELAY) then
        last_input_index = 12 + 2 -- 12 inputs + offset of 2 positions
    elseif self:checkType(TYPES.CABLE_DIMMER) then
        last_input_index = 11 + 2
    else
        return -- Unsupported type, exit the function
    end

    local i = 0
    local ins = {}
    local outs = {}

    -- Parse the response string by splitting on commas
    for str in string.gmatch(res, '([^,]+)') do
        if i > 1 then
            if i < last_input_index then
                table.insert(ins, tonumber(str)) -- Collect input values
            else
                table.insert(outs, tonumber(str)) -- Collect output values
            end
        end
        i = i + 1
    end

    -- Store the output states and update the last update time
    self.outputs_status = outs
    self.lastIoUpdate = os.time()

    -- Inputs (ins) are parsed but not used currently
end

-- Sets the output of a specific channel
-- @param ch number: The channel number to set
-- @param val number: The value to set on the channel
-- @param ramp number (optional): The ramp time for dimming, defaults to DEFAULT_RAMP for dimmers
-- @return string: The result of the send command
function Cable:setOutput(ch, val, ramp)

    -- For relays, send the command to set the output value
    if self:checkType(TYPES.CABLE_RELAY) then
        local cmd =
            "mdcmd_sendrele," .. self.MAC .. "," .. tostring(ch) .. "," ..
                tostring(val)
        return self:sendCommand(cmd)
    end

    -- For dimmers, send the command with an optional ramp value
    if self:checkType(TYPES.CABLE_DIMMER) then
        ramp = ramp or self.DEFAULT_RAMP
        local cmd =
            "mdcmd_sendrele," .. self.MAC .. "," .. tostring(ch) .. "," ..
                tostring(val) .. "," .. tostring(ramp)
        return self:sendCommand(cmd)
    end
end

-- Turns off all outputs on the device
-- @return string: The result of the send command
function Cable:masterOff()

    -- Check if the device is a relay or dimmer before proceeding
    if not self:checkType(TYPES.CABLE_RELAY, TYPES.CABLE_DIMMER) then return end

    -- Send the command to turn off all outputs
    local cmd = "mdcmd_setalloffmd," .. self.MAC
    return self:sendCommand(cmd)
end

-- Turns on all outputs on the device
-- @return string: The result of the send command
function Cable:masterOn()

    -- Check if the device is a relay or dimmer before proceeding
    if not self:checkType(TYPES.CABLE_RELAY, TYPES.CABLE_DIMMER) then return end

    -- Send the command to turn on all outputs
    local cmd = "mdcmd_setallonmd," .. self.MAC
    return self:sendCommand(cmd)
end

-- Resets the device
-- @return nil
-- @note Sends the reset command and logs the result
function Cable:reset()

    -- Check if the device is a relay or dimmer before proceeding
    if not self:checkType(TYPES.CABLE_RELAY, TYPES.CABLE_DIMMER) then return end

    -- Send the reset command and log the response
    local res = self:sendCommand("reset_cCableRelay_cCableRelay", 10)
    if res == "OK" then
        log("Reset de: " .. self:toString() .. " enviado com sucesso\n")
    else
        log("Reset de: " .. self:toString() .. " não teve confirmação\n" ..
                res)
    end

    -- Disconnect after resetting
    self:disconnect()
end

-- Retrieves the MAC address of the device
-- @return string: The formatted MAC address of the device
function Cable:askForMac()

    -- Check if the device is a relay or dimmer before proceeding
    if not self:checkType(TYPES.CABLE_RELAY, TYPES.CABLE_DIMMER) then return end

    -- Send the command to get the MAC address and format it
    local res = self:sendCommand("get_mac_addr")
    local formatedMac = macString(res)

    self.MAC = formatedMac
    return formatedMac
end

return Cable
