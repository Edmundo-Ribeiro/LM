---@class Xbus : Controlart
local Controlart = require('controlart')

local Xbus = {}
setmetatable(Xbus, { __index = Controlart })

--- Default configuration values for Xbus
Xbus.inputs_status = {}
Xbus.outputs_status = {}
Xbus.links = {}
Xbus.loads = {}

--- Constructor for Xbus object
---@param mac string MAC address of the module
---@param name string Name of the module
---@param type string Type of the module
---@return Xbus
function Xbus.new(mac, name, type)
    local self = Controlart.new("", mac, name, "XBUS_" .. type)
    setmetatable(self, { __index = Xbus })
    return self
end

--- Associates Xport connection with Xbus
---@param xport Xport Xport instance
function Xbus:setXportConnection(xport)
    self.client = xport.client  
    self.IP = xport.IP
    self.connectionStatus = xport.connectionStatus
end

--- Updates the I/O status of Xbus modules
---@param io string I/O data received from the device
function Xbus:setIoStatus(io)
    self.inputs_status = {}
    self.outputs_status = {}
    local i = 1
    
    for v in io:gmatch('([^,]+)') do
        if i <= 3 then
            table.insert(self.inputs_status, v)
        else
            table.insert(self.outputs_status, v)
        end
        i = i + 1
    end
    self.lastIoUpdate = os.time()
end

--- Sends a command to set the output of a channel
---@param ch number Channel number
---@param val number Value to set
---@return string|nil Response from the device
function Xbus:setOutput(ch, val)
    local cmd = string.format("mdcmd_msendmd,%s,%d,%d", self.MAC, ch, val)
    return self:sendCommand(cmd)
end

--- Toggles the output of a specific channel
---@param ch number Channel number to toggle
---@return string|nil Response from the device
function Xbus:toggleCh(ch)
    local cmd = string.format("mdcmd_togglemd,%s,%d", self.MAC, ch)
    return self:sendCommand(cmd)
end

--- Sets RGBW values for Xbus lighting modules
---@param R number Red value (0-255)
---@param G number Green value (0-255)
---@param B number Blue value (0-255)
---@param W number White value (0-255), optional
---@return string|nil Response from the device
function Xbus:setRGBW(R, G, B, W)
    W = W or 0
    local cmd = string.format("mdcmd_sendrgbwmd,%s,%d,%d,%d,%d", self.MAC, R, G, B, W)
    return self:sendCommand(cmd)
end

--- Retrieves a list of registered Xbus modules
---@return table List of module MAC addresses
function Xbus:getModulesList()
    local res = self:sendCommand("getmodulelist", self.TIMEOUT_THRESHOLD * 2)
    local macs = {}
    
    if res then
        for mac in res:gmatch("(%x%x%-%x%x%-%x%x%-%x%x)") do
            table.insert(macs, Controlart.formatMac(mac))
        end
    end
    return macs
end



--- Turns off all outputs on the device
---@return string|nil Response from the device
function Xbus:masterOff()
    return self:sendCommand("mdcmd_setmasteroffmd")
end

--- Turns on all outputs on the device
---@return string|nil Response from the device
function Xbus:masterOn()
    return self:sendCommand("mdcmd_setmasteronmd")
end

return Xbus
