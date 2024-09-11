local Controlat = require('controlart')


local CableRelay = {
  inputs_status={},
  outputs_status={}
}

setmetatable(CableRelay, { __index = Controlart })


function CableRelay.new(ip, mac, name)
  local o = Controlart.new(ip, mac, name, "CableRelay_RELAY")
  setmetatable(obj, self)
  self.__index = self
  return o
end


function CableRelay:getIos()
  
  local cmd = "mdcmd_getmd,"..self.MAC
  local res = nil
  local i = 0
  local last_input_index = 12 + 2
  local ins = {}
  local outs = {}
  res = self:sendCommand(cmd)

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

end

function CableRelay:setOutput(ch,val)

    local cmd = "mdcmd_sendrele,"..self.MAC..","..tostring(ch)..","..tostring(val)
    --log(cmd)
    return self:sendCommand(cmd)
end

function CableRelay:setOutputs(mask,val)

    local cmd = "mdcmd_msendrele,"..self.MAC..","..tostring(mask)..","..tostring(val)
    --log(cmd)
    return self:sendCommand(cmd)
end

function CableRelay:toggleOutputs(mask)

    local cmd = "mdcmd_mtogglerele,"..self.MAC..","..tostring(mask)
    --log(cmd)
    return self:sendCommand(cmd)
end


function CableRelay:masterOff()
	--desligar todas as saidas de uma vez  
    local cmd = "mdcmd_setalloffmd,"..self.MAC
    --log(cmd)
    return self:sendCommand(cmd)
end

function CableRelay:masterOn()
	--desligar todas as saidas de uma vez  
    local cmd = "mdcmd_setallonmd,"..self.MAC
    --log(cmd)
    return self:sendCommand(cmd)
end


function CableRelay:reset()
  local res = self:sendCommand("reset_cCableRelay_cCableRelay")
  if res == "OK" then
    log("Reset de: "..self:toString().." enviado com sucesso\n")
  else
    log("Reset de: "..self:toString().." não teve confirmação\n"..res)
  end
  
  self:disconnect()
end



function CableRelay:askForMac()
    
    local res = self:sendCommand("get_mac_addr")
    local formatedMac =  macString(res)
    
    self.MAC = formatedMac
    return formatedMac
    
end



return CableRelay