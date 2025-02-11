---@class Xport : Controlart
local Controlart = require('user.controlart')

local Xport = {}
setmetatable(Xport, { __index = Controlart })

--- Default configuration values for Xport
Xport.DEFAULT_FREQ = 38000
Xport.DEFAULT_DELAY = 1000
Xport.DEFAULT_REPEAT = 1
Xport.DEFAULT_BAUDRATE = 38400
Xport.xbus = {}

--- Constructor for Xport object
---@param ip string IP address of the module
---@param mac string MAC address of the module
---@param name string Name of the module
---@return Xport
function Xport.new(ip, mac, name)
    local self = Controlart.new(ip, mac, name, Controlart.TYPES.XPORT)
    setmetatable(self, Xport)  -- Aqui garantimos que o objeto seja do tipo Xport
    Xport.__index = Xport
    return self
end

--- Sends an IR or RS232 command
---@param ch number Channel number
---@param val string Command value
---@param rep number|nil Number of repetitions
---@param delay number|nil Delay in ms
---@param freq number|nil Frequency in Hz
---@return string|nil Response from the device
function Xport:setCh(ch, val, rep, delay, freq)
    rep = rep or self.DEFAULT_REPEAT
    freq = freq or self.DEFAULT_FREQ
    delay = delay or self.DEFAULT_DELAY
    
    local cmd = (ch == 1) and string.format("sendserialhex,%s", val) or 
                string.format("sendir,1:%d,1,%d,%d,1,%s,%d", ch, freq, rep, val, delay)
    return self:sendCommand(cmd)
end

--- Retrieves a list of registered Xbus modules
---@return table List of module MAC addresses
function Xport:getModulesList()
    local res = self:sendCommand("getmodulelist", self.TIMEOUT_THRESHOLD * 2)
    local macs = {}
    
    if res then
        for mac in res:gmatch("(%x%x%-%x%x%-%x%x%-%x%x)") do
     			 	
            table.insert(macs, Controlart:formatMAC(mac))
      			
        end
    end
    return macs
end

--- Retrieves the status of connected Xbus and cable modules
---@return table xbus List of Xbus modules and their I/O states
---@return table cable List of Cable modules and their I/O states
function Xport:getModulesStatus()
    log('getres', self:sendCommand("getmodulesstatus", 120)    )
    local xbus, cable = {}, {}
    
    --local res = self:getResponse(self.TIMEOUT_THRESHOLD)
   --[[ while res do
        local prefix, mac, ios = res:match("([^,]+),([^,]+),(.+)")
        if prefix and mac and ios then
            local formatted_mac = Controlart:formatMAC(mac)
            if prefix == "setmd" or prefix == "setrgbwmd" then
                xbus[formatted_mac] = ios
            elseif prefix == "setdmmd" or prefix == "setcmd" then
                cable[formatted_mac] = ios
            end
        end
        res = self:getResponse(1)
    end]]--
    return xbus, cable
end

--- Updates the I/O status of registered Xbus modules
function Xport:updateXbus()
    local xbus_status, _ = self:getModulesStatus()
    self.lastIoUpdate = os.time()
    
    for _, device in ipairs(self.xbus) do
        device:setIoStatus(xbus_status[device.MAC])
    end
end

--- Adds an Xbus module to the Xport
---@param device table|table[] Xbus device(s) to be added
function Xport:addXbus(device)
    if type(device) == "table" and #device > 0 then
        for _, obj in ipairs(device) do
            obj.client, obj.IP = self.client, self.IP
            self.xbus[obj.MAC] = obj
        end
    else
        device.client, device.IP = self.client, self.IP
        self.xbus[device.MAC] = device
    end
end

--- Sends a master OFF command to all connected modules
---@return string|nil Response from the device
function Xport:masterOff()
    return self:sendCommand("mdcmd_setmasteroffmd")
end

--- Sends a master ON command to all connected modules
---@return string|nil Response from the device
function Xport:masterOn()
    return self:sendCommand("mdcmd_setmasteronmd")
end

--- Resets the Xport module
function Xport:reset()
    local res = self:sendCommand("reset_xport_xport")
    if res == "OK" then
        log("Reset de: " .. self:toString() .. " enviado com sucesso\n")
    else
        log("Reset de: " .. self:toString() .. " não teve confirmação\n" .. (res or ""))
    end
    self:disconnect()
end

--- Sets the baud rate for the RS-232 communication
---@param baudrate number Baud rate value
---@return string|nil Response from the device
function Xport:setBaudRate(baudrate)
    return self:sendCommand("setbaudrate," .. tostring(baudrate))
end

--- Retrieves the current baud rate of the RS-232 communication
---@return string|nil Baud rate value from the device
function Xport:getBaudRate()
    return self:sendCommand("getbaudrate")
end

return Xport