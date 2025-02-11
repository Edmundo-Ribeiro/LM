require('socket')

CRLF = '\r\n'




-- Controlart class definition
Controlart = {
    IP = '', -- Device IP address
    MAC = '', -- Device MAC address
    NAME = '', -- Device name
    TYPE = '', -- Device type (e.g., CABLE_RELAY, CABLE_DIMMER)
    PORT = 4998, -- Default TCP port
    connectionStatus = false, -- Connection status
    online = false, -- Online status of the device
    TIMEOUT_THRESHOLD = 2, -- Timeout threshold in seconds
    lastIoUpdate = 0, -- Last IO update timestamp
    client = {}, -- TCP client socket
  	
		-- Define types of modules
		TYPES = {CABLE_RELAY = 1, CABLE_DIMMER = 2, XPORT = 3, SEVENPORT = 4}
}

-- Constructor for Controlart class
-- @param ip string: Device IP address
-- @param mac string: Device MAC address
-- @param name string: Device name
-- @param TYPE string: Device type (e.g., CABLE_RELAY, CABLE_DIMMER)
-- @return table: New Controlart object
function Controlart:new(ip, mac, name, TYPE)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    -- Initialize object attributes
    self.IP = ip or ''
    self.MAC = mac or ''
    self.NAME = name or ''
    self.TYPE = TYPE or ''
    self.client = socket.tcp() -- Create TCP client socket

    -- Initialize additional attributes for relays or dimmers
    if self.TYPES.CABLE_RELAY == TYPE or self.TYPES.CABLE_DIMMER == TYPE then
        self.inputs_status = {}
        self.outputs_status = {}
        self.loads = {}
        self.DEFAULT_RAMP = 3
    end

    return o
end

-- Converts object information into a string for debugging
-- @return string: Concatenated string with object details
function Controlart:toString()
    local str = ''

    if self.NAME then str = str .. "Nome: " .. self.NAME .. "," end
    if self.IP then str = str .. " IP: " .. self.IP .. "," end
    if self.MAC then str = str .. " MAC: " .. self.MAC .. "," end
    if self.TYPE then str = str .. " tipo: " .. self.TYPE .. "," end

    return str
end

-- Establishes a TCP connection with the device
-- @return boolean, string: Connection status (true if successful), error message (if any)
function Controlart:connect()
    self.client = socket.tcp()

    self.client:settimeout(self.TIMEOUT_THRESHOLD)
    local established, connectionErr = self.client:connect(self.IP, self.PORT)

    if established then
        self.connectionStatus = true
        self.online = true

        -- If MAC is not available and the type is relay or dimmer, retrieve the MAC
        if self.MAC == '' and
            self:checkType(Controlart.TYPES.CABLE_RELAY, Controlart.TYPES.CABLE_DIMMER) then
            self:askForMac()
        end
    end

    -- Log an error if the connection failed
    if connectionErr then
        log("Não foi possivel conectar modulo: " .. self:toString() ..
                "\n Erro: " .. connectionErr .. "\n")
        self.connectionStatus = false
        self.client = nil
    end

    return self.connectionStatus, connectionErr
end

-- Closes the TCP connection with the device
-- @return nil
function Controlart:disconnect() if self.client then self.client:close() end end

-- Sends a ping command to the device to check if it is online
-- @return boolean: True if the device responds to the ping, false otherwise
function Controlart:ping()
    local pingCommand = "ping -c 1 " .. self.IP
    local pingProcess = io.popen(pingCommand)
    local pingOutput = pingProcess:read("*a")
    pingProcess:close()
    return string.find(pingOutput, "1 packets received") ~= nil
end

-- Sends a command to the device and optionally waits for a response
-- @param cmd string: Command to be sent
-- @param waitForResponse number (optional): Time to wait for a response (defaults to TIMEOUT_THRESHOLD)
-- @return string or boolean: Response from the device or false if there was an error
function Controlart:sendCommand(cmd, waitForResponse)
    waitForResponse = waitForResponse or self.TIMEOUT_THRESHOLD

    -- If the connection is active, send the command
    if self.connectionStatus then
        local _, sendErr = self.client:send(cmd .. CRLF)
        if sendErr then
            log("Erro: [" .. sendErr ..
                    "] ao tentar enviar comando para o modulo: " ..
                    self:toString() .. "\n")
            return false
        end
    else
        log("Não há conexão com modulo: " .. self:toString() .. "\n")
        return false
    end

    -- If no response is expected, return true
    if waitForResponse == 0 then return true end

    return self:getResponse(waitForResponse)
end

--- Receives a response from the device after sending a command
---@param wait number (optional): Time in seconds to wait for a response
---@return string|boolean Full response data or false if timeout/error occurs
function Controlart:getResponse(wait)
    wait = wait or self.TIMEOUT_THRESHOLD -- Default wait time if not specified
    local startTime = os.time()
    local responseBuffer = {} -- Store multiple parts of the response

    log(startTime, "Aguardando resposta por até " .. wait .. " segundos...")

    while (os.time() - startTime) <= wait do
        --log(os.time(), os.time() - startTime)
        
        -- Wait for data to be available on the socket
        local readable, _, err = socket.select({self.client}, nil, 1) -- Wait up to 1 second

        if readable and #readable > 0 then
            local data, receiveErr, partialData = self.client:receive("*l") -- Read a line
            
            if data then
                table.insert(responseBuffer, data) -- Store received data
                log("Parte da resposta recebida: " .. data)
            elseif receiveErr then
                log("Erro ao receber resposta: " .. receiveErr)
            end
        end

        -- If timeout is reached, return accumulated response
        if (os.time() - startTime) >= wait then
            local fullResponse = table.concat(responseBuffer, "\n") -- Combine all received parts
            if #fullResponse > 0 then
                log("Resposta completa recebida: " .. fullResponse)
                return fullResponse
            else
                log("Timeout atingido ao aguardar resposta de " .. self:toString())
                return false
            end
        end
    end

    log("Timeout, sem resposta recebida de " .. self:toString())
    return false
end



-- Checks if the device type matches one of the provided types
-- @param ... string: List of device types to check
-- @return boolean: True if the device type matches any of the provided types
function Controlart:checkType(...)
    local args = {...}
    for i, v in ipairs(args) do if v == self.TYPE then return true end end
    return false
end


-- Formats MAC address for Controlart TCP commands
-- @param mac_string string: MAC address in the format "12-34-56-78"
-- @return string: Formatted MAC address suitable for TCP commands in the format "$12,$34,$56"
function Controlart:formatMAC(mac_string)
  --log(mac_string)
    return
        "$" .. mac_string:sub(1, 2) .. ",$" .. mac_string:sub(4, 5) .. ",$" ..
            mac_string:sub(7, 8)
end

-- Converts MAC string returned by getmac command to TCP command format
-- @param mac_string string: MAC address string returned by getmac command
-- @return string: Formatted MAC string for TCP command usage
function Controlart:macString(mac_string)
    local _, macDigits = mac_string:match("([^,]+),([^,]+)") -- Extracts the MAC part
    return self:formatMAC(macDigits)
end


return Controlart
