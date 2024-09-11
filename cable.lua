local Controlat = require('controlart')

function Controlart:getIos()
  
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
  
    local cmd = "mdcmd_getmd,"..self.MAC
    local res = self:sendCommand(cmd)
  
    for str in string.gmatch(res, '([^,]+)') do
      if i > 1 then
        if i < last_input_index then 
          table.insert(ins,tonumber(str))
        else
          table.insert(outs,tonumber(str))
        end
      end
      i = i+1
    end
    self.outputs_status = outs
    --por enquanto não estou interessado em fazer nada com os inputs
    -- self.inputs_status = ins
    self.lastIoUpdate = os.time()
  end

function Controlart:setOutput(ch,val)

  if not self:checkType(TYPES.CABLE_RELAY, TYPES.CABLE_DIMMER) then 
    return 
  end

    local cmd = "mdcmd_sendrele,"..self.MAC..","..tostring(ch)..","..tostring(val)
    --log(cmd)
    return self:sendCommand(cmd)
end

function Controlart:setOutputs(mask,val)

  if not self:checkType(TYPES.CABLE_RELAY, TYPES.CABLE_DIMMER) then 
    return 
  end

    local cmd = "mdcmd_msendrele,"..self.MAC..","..tostring(mask)..","..tostring(val)
    --log(cmd)
    return self:sendCommand(cmd)
end

function Controlart:toggleOutputs(mask)

  if not self:checkType(TYPES.CABLE_RELAY, TYPES.CABLE_DIMMER) then 
    return 
  end

    local cmd = "mdcmd_mtogglerele,"..self.MAC..","..tostring(mask)
    --log(cmd)
    return self:sendCommand(cmd)
end


function Controlart:masterOff()

  if not self:checkType(TYPES.CABLE_RELAY, TYPES.CABLE_DIMMER) then 
    return 
  end
	--desligar todas as saidas de uma vez  
    local cmd = "mdcmd_setalloffmd,"..self.MAC
    --log(cmd)
    return self:sendCommand(cmd)
end

function Controlart:masterOn()

  if not self:checkType(TYPES.CABLE_RELAY, TYPES.CABLE_DIMMER) then 
    return 
  end

	--desligar todas as saidas de uma vez  
    local cmd = "mdcmd_setallonmd,"..self.MAC
    --log(cmd)
    return self:sendCommand(cmd)
end


function Controlart:reset()

  if not self:checkType(TYPES.CABLE_RELAY, TYPES.CABLE_DIMMER) then 
    return 
  end

  local res = self:sendCommand("reset_cCableRelay_cCableRelay")
  if res == "OK" then
    log("Reset de: "..self:toString().." enviado com sucesso\n")
  else
    log("Reset de: "..self:toString().." não teve confirmação\n"..res)
  end
  
  self:disconnect()
end


function Controlart:askForMac()

  if not self:checkType(TYPES.CABLE_RELAY, TYPES.CABLE_DIMMER) then 
    return 
  end
    
    local res = self:sendCommand("get_mac_addr")
    local formatedMac =  macString(res)
    
    self.MAC = formatedMac
    return formatedMac
    
end
