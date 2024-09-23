local Cable = require('user.controlart')

function Cable:getIO()

    local cmd = "mdcmd_getmd," .. self.MAC

    local res = self:sendCommand(cmd)

    if (string.match(res, 'setcmd')) then
        self:updateIO(res)
        return res
    end

    return nil
end

function Cable:updateIO(res)

    local last_input_index = 0
    if self:checkType(TYPES.CABLE_RELAY) then
        last_input_index = 12 + 2 -- possui 12 entradas + offset de 2 posições
    elseif self:checkType(TYPES.CABLE_DIMMER) then
        last_input_index = 11 + 2
    else
        return
    end

    local i = 0
    local ins = {}
    local outs = {}

    for str in string.gmatch(res, '([^,]+)') do
        if i > 1 then
            if i < last_input_index then
                table.insert(ins, tonumber(str))
            else
                table.insert(outs, tonumber(str))
            end
        end
        i = i + 1
    end
    self.outputs_status = outs
    -- por enquanto não estou interessado em fazer nada com os inputs
    -- self.inputs_status = ins
    self.lastIoUpdate = os.time()

end

function Cable:setOutput(ch, val, ramp)

    if self:checkType(TYPES.CABLE_RELAY) then
        local cmd =
            "mdcmd_sendrele," .. self.MAC .. "," .. tostring(ch) .. "," ..
                tostring(val)
        return self:sendCommand(cmd)
    end

    if self:checkType(TYPES.CABLE_DIMMER) then
        ramp = ramp or self.DEFAULT_RAMP
        local cmd =
            "mdcmd_sendrele," .. self.MAC .. "," .. tostring(ch) .. "," ..
                tostring(val) .. "," .. tostring(ramp)
        return self:sendCommand(cmd)
    end

end

function Cable:masterOff()

    if not self:checkType(TYPES.CABLE_RELAY, TYPES.CABLE_DIMMER) then return end
    -- desligar todas as saidas de uma vez  
    local cmd = "mdcmd_setalloffmd," .. self.MAC
    -- log(cmd)
    return self:sendCommand(cmd)
end

function Cable:masterOn()

    if not self:checkType(TYPES.CABLE_RELAY, TYPES.CABLE_DIMMER) then return end

    -- desligar todas as saidas de uma vez  
    local cmd = "mdcmd_setallonmd," .. self.MAC
    -- log(cmd)
    return self:sendCommand(cmd)
end

function Cable:reset()

    if not self:checkType(TYPES.CABLE_RELAY, TYPES.CABLE_DIMMER) then return end

    local res = self:sendCommand("reset_cCableRelay_cCableRelay", 10)
    if res == "OK" then
        log("Reset de: " .. self:toString() .. " enviado com sucesso\n")
    else
        log("Reset de: " .. self:toString() .. " não teve confirmação\n" ..
                res)
    end

    self:disconnect()
end

function Cable:askForMac()

    if not self:checkType(TYPES.CABLE_RELAY, TYPES.CABLE_DIMMER) then return end

    local res = self:sendCommand("get_mac_addr")
    local formatedMac = macString(res)

    self.MAC = formatedMac
    return formatedMac

end

return Cable