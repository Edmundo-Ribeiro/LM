require('socket')

-- Funções para converter valores --------------
function boolToNumber(b) return b and 1 or 0 end

function numberToBool(n) return n ~= 0 end

function scaleToByte(n) return math.floor((n / 100) * 255) end

function byteToScale() return math.floor((n / 255) * 100) end
-----------------------------------------------

-- Interface para manipulação facilitada dos devices
-- recebe lista de devicees e retorna tabela que relaciona o nome das seções com o canal e modulo que está conectada
function createModuleInterface(...)
    local args = {...}
    local interface = {}

    -- Check if the first argument is a table (for a list of modules)
    if type(args[1]) == "table" and args[1].loads then
        -- Single module passed
        args = args
    elseif type(args[1]) == "table" then
        -- A list of modules passed as a single argument
        args = args[1]
    end

    -- Iterate over each module
    for _, module in ipairs(args) do
        -- log(_,module)
        -- Iterate over each load in the current module's loads
        for loadName, inputNumber in pairs(module.loads) do
            -- Create a table with the input number and module object
            interface[loadName] = {ch = inputNumber, module = module}
        end
    end

    return interface
end

-- Função que deverá ser chamada para resolver eventos de iluminação gerados por modulos cabeados
-- executa o evento no modulo, atualiza objeto de status e atualiza IOs
function executeLightEvent(e, interface)

    local section_name = grp.alias(e.dst)
    local value = e.getvalue()
    local channel = nil

    -- Decidir se é on/off ou dimmer 
    if type(value) == 'boolean' then
        value = boolToNumber(value)
    else
        value = scaleToByte(value)
    end

    local section = interface[section_name]

    if section then
        local module = section.module
        if module:connect() then
            local res = module:setOutput(section.ch, value)
            module:updateIO(res)
            module:disconnect()
            grp.checkupdate("_" .. section_name, numberToBool(
                                module.outputs_status[section.ch + 1]), 1) -- atualiza o status

        end
    end
end

-- atualizar status dos objetos knx
function updateObjects(m)
    for obj_name, ch in pairs(m.loads) do
        grp.checkupdate("_" .. obj_name, numberToBool(m.outputs_status[ch + 1]),
                        1)
    end
end

-------------------------------------------------

require('socket')
CABLE = require('user.cable')

TYPES = {CABLE_RELAY = 1, CABLE_DIMMER = 2, XPORT = 3, SEVENPORT = 4}

-- Criação de modulos cabeados
DIMMER_A = CABLE:new("192.168.0.121", '', "DIMMER_A", TYPES.CABLE_DIMMER)
DIMMER_B = CABLE:new("192.168.0.122", '', "DIMMER_B", TYPES.CABLE_DIMMER)
DIMMER_C = CABLE:new("192.168.0.123", '', "DIMMER_C", TYPES.CABLE_DIMMER)
DIMMER_D = CABLE:new("192.168.0.124", '', "DIMMER_D", TYPES.CABLE_DIMMER)
RELE_E = CABLE:new("192.168.0.125", '', "RELE_E", TYPES.CABLE_RELAY)

-- Tabela de associação lampadas e modulos
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
    ["S31"] = 6
}

DIMMER_C.loads = {
    ["S50"] = 0,
    ["S49"] = 1,
    ["S33"] = 2,
    ["S32"] = 3,
    ["S39"] = 4,
    ["S40"] = 5,
    ["S41"] = 6
}

DIMMER_D.loads = {
    ["S35"] = 0,
    ["S36"] = 1,
    ["S38"] = 2,
    ["S37"] = 4,
    ["S34"] = 8
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
    ["S42"] = 8,
    ["S21"] = 9
}

-- DEVICE_INTERFACE = createModuleInterface(DIMMER_A, DIMMER_B, DIMMER_C, DIMMER_D, RELE_E) 

local CABLE = require('user.cable')
local teste_rele = CABLE:new("10.100.200.204", '', "rele", TYPES.CABLE_RELAY)
-- local teste_dimmer = CABLE:new("10.100.200.179",'',"dimmer", TYPES.CABLE_DIMMER)

teste_rele.loads = {
    -- ["S1"] = 0,
    ["S2"] = 1,
    ["S3"] = 2,
    ["S4"] = 3,
    ["S5"] = 4,
    ["S6"] = 5,
    ["S7"] = 6,
    ["S8"] = 8
}
TEST_LIST = {teste_rele}
TEST_INTERFACE = createModuleInterface(TEST_LIST)
