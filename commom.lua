--Funções para converter valores --------------
function boolToNumber(b) 
	return  b and 1 or 0
end

function numberToBool(n)
	return  n ~= 0
end

function scaleToByte(n)
    return math.floor((n / 100) * 255)
end 

function byteToScale()
    return  math.floor((n / 255) * 100)
end
-----------------------------------------------
require('socket')
CableRelay = require('user.cable_relay')
CableDimmer = require('user.cable_dimmer')
Xport = require('user.xport')   


--Criação de modulos cabeados
DIMMER_A = CableDimmer.new("192.168.0.121",'',"DIMMER_A")
DIMMER_B = CableDimmer.new("192.168.0.122",'',"DIMMER_B")
DIMMER_C = CableDimmer.new("192.168.0.123",'',"DIMMER_C")
DIMMER_D = CableDimmer.new("192.168.0.124",'',"DIMMER_D")
RELE_E = CableRelay.new("192.168.0.125",'',"RELE_E")

--Tabela de associação lampadas e modulos
DIMMER_A.loads = {
    ["S13"] = 0,
    ["S14"] = 1,
    ["S15"] = 2,
    ["S20"] = 3,
    ["S28"] = 4,
    ["S30"] = 5,
    ["S24"] = 6,
    ["S22"] = 8
}

DIMMER_B.loads = {
    ["S10"] = 0,
    ["S11"] = 1,
    ["S9"] = 2,
    ["S16"] = 3,
    ["S17"] = 4,
    ["S18"] = 5,
    ["S31"] = 6,
}

DIMMER_C.loads = {
    ["S50"] = 0,
    ["S49"] = 1,
    ["S33"] = 2,
    ["S32"] = 3,
    ["S39"] = 4,
    ["S40"] = 5,
    ["S41"] = 6,
}

DIMMER_D.loads = {
    ["S35"] = 0,
    ["S36"] = 1,
    ["S38"] = 2,
    ["S37"] = 4,
    ["S34"] = 8,
}

RELE_E.loads = {
    ["S2"] = 0,
    ["S3"] = 1,
    ["S4"] = 2,
    ["S5"] = 3,
    ["S26"] = 4,
    ["S6"] = 5,
    ["S7"] = 6,
    ["S8"] = 7,
    ["S42"] =  8,
    ["S21"] =  9
}

--Adicionar todos os modulos em uma lista
CABLE_LIST = {DIMMER_A ,DIMMER_B ,DIMMER_C ,DIMMER_D ,RELE_E}




XRGB1 = Xbus.new("$66,$BE,$3B", "XRGB1","RGBW_DIMMER")
XRGB3 = Xbus.new("$0E,$55,$CF", "XRGB3","RGBW_DIMMER")
XRGB4 = Xbus.new("$46,$BC,$DB", "XRGB4","RGBW_DIMMER")
XRGB6 = Xbus.new("$39,$27,$64", "XRGB6","RGBW_DIMMER")
XRGB7 = Xbus.new("$04,$F5,$CB", "XRGB7","RGBW_DIMMER")
XRGB8 = Xbus.new("$AA,$AA,$AA", "XRGB8","RGBW_DIMMER")
XBR1 = Xbus.new("$16,$E3,$7C", "XBR1", "RELAY")
XBD1 = Xbus.new("$5F,$BD,$DE", "XBD1", "DIMMER")


XRGB1.loads = { ["S1"] = 15 }--1111 = 15 indica que todos os canais estão sendo controlados juntamente
XRGB1:linkXbus(XRGB6) -- Banheiro tem 2 xbus que devem responer juntos

XRGB3.loads = { 
    ["S23A"] = 1,--001
    ["S23B"] = 2,--010
    ["S23C"] = 4 --100
}
XRGB4.loads = { ["S25"] = 15 }
XRGB7.loads = { ["S50A"] = 15 }
XRGB8.loads = { ["S48"] = 15 }

XBR1.loads = {
    ["S29A"] = 1,
    ["S29B"] = 2,
}

XBD1.loads = {
    ["S44A"] = 1,
    ["S44B"] = 2,
}


xport_bunker = Xport.new("192.168.0.73",,"XPORT")
xport_bunker:addXbus({XRGB1, XRGB3, XRGB4, XRGB6, XRGB7, XRGB8, XBR1, XBD1})

senvenport = SevenPort.new("192.168.0.74",,"SEVENPORT")




--Função que deverá ser chamada para resolver eventos de luminação gerados por modulos cabeados
function executeCableLightEvent(e, modules_list)

    local section_name = grp.alias(e.dst)
    local value = e.getvalue()
    local channel = nil

    if type(value) == boolean then
        value = boolToNumber(value)
    else
        value = scaleToByte(value)
    
    for i, module in ipairs(modules_list) do
        
        channel = module.loads[section_name]

        if channel then
            if module:connect() then
                module:setOutput(channel, value)
                module:disconnect()
                return
            end
        end
    end
end


--Função que deverá ser chamada para resolver eventos de luminação gerados por xbus
function executeXbusLightEvent(e,xport)
    local section_name = grp.alias(e.dst)
    local value = e.getvalue()
    local channel = nil

    if type(value) == boolean then
        value = boolToNumber(value)
    else
        value = scaleToByte(value)

    for i,module in ipairs(xport.xbus) do
        channel = module.loads[section_name]
        if channel then
            if xport:connect() then
                module:setOutput(channel, value)
                xport:disconnect()
                return
            end
        end
    end
end



--Função que deverá ser chamada para resolver eventos de IR na xport ou sevenport
function executeIrEvent(e,ir_map)
    


end

code_tes = require("user.bunker_ir_codes")["AR_BUNKER"]
local SevenPort = require("user.7port")

local ir = SevenPort.new("192.168.1.110","7PORT")

ir_list_test = {ir}


function updateObjects(m)
	for obj_name, ch in pairs(m.loads) do
    grp.update("_"..obj_name,numberToBool(m.outputs_status[ch+1]))
    --grp.checkupdate("_"..obj_name, numberToBool(m.outputs_status[ch]))
    
	end

end
