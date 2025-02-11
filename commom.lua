require('socket')

-- Converts boolean to number
-- @param b boolean: The input boolean value
-- @return number: Returns 1 if true, otherwise 0
function boolToNumber(b) return b and 1 or 0 end

-- Converts number to boolean
-- @param n number: The input number
-- @return boolean: Returns true if n is not 0, otherwise false
function numberToBool(n) return n ~= 0 end

-- Converts a percentage (0-100) to a byte (0-255)
-- @param n number: The input percentage (0-100)
-- @return number: A byte value in the range 0-255
function scaleToByte(n) return math.floor((n / 100) * 255) end

-- Converts a byte (0-255) to a percentage (0-100)
-- @param n number: The input byte (0-255)
-- @return number: A percentage value in the range 0-100
function byteToScale(n) return math.floor((n / 255) * 100) end

-- Creates a module interface mapping section names to channels and modules
-- @param ... table: One or more module tables or a list of module tables
-- @return table: A table mapping section names to their respective channel and module
function createModuleInterface(...)
    local args = {...}
    local interface = {}

    -- If a single module or a list of modules is passed
    if type(args[1]) == "table" and args[1].loads then
        args = args -- Single module passed
    elseif type(args[1]) == "table" then
        args = args[1] -- List of modules passed
    end

    -- Map each module's loads (section names) to the corresponding channel and module
    for _, module in ipairs(args) do
        for loadName, inputNumber in pairs(module.loads) do
            interface[loadName] = {ch = inputNumber, module = module}
        end
    end

    return interface
end

-- Handles light events triggered by wired modules
-- @param e table: Event object containing event details
-- @param interface table: The interface mapping section names to channels and modules
-- @return nil
-- @note Updates the status of the section based on the event, handles both on/off and dimmer events
function executeLightEvent(e, interface)

    local section_name = grp.alias(e.dst) -- Get the section name from the event
    local value = e.getvalue() -- Get event value (could be boolean or dimmer value)
    local channel = nil

    -- Convert value to appropriate format (boolean to number, percentage to byte)
    if type(value) == 'boolean' then
        value = boolToNumber(value)
    else
        value = scaleToByte(value)
    end

    -- Find the module and channel for the section
    local section = interface[section_name]

    if section then
        local module = section.module
        if module:connect() then -- Connect to the module
            local res = module:setOutput(section.ch, value) -- Set output value for the channel
            module:updateIO(res) -- Update IO states in the module
            module:disconnect() -- Disconnect from the module
            grp.checkupdate("_" .. section_name, numberToBool(
                                module.outputs_status[section.ch + 1]), 1) -- Update object status
        end
    end
end

-- Updates the status of KNX objects based on module output states
-- @param m table: The module containing load and output status
-- @return nil
-- @note Iterates through each load and updates the status of the corresponding KNX object
function updateObjects(m)
    for obj_name, ch in pairs(m.loads) do
        grp.checkupdate("_" .. obj_name, numberToBool(m.outputs_status[ch + 1]),
                        1)
    end
end

-- Load necessary modules
require('socket')

--[[CABLE = require('user.Cable')

-- Define types of modules
TYPES = {CABLE_RELAY = 1, CABLE_DIMMER = 2, XPORT = 3, SEVENPORT = 4}

-- Creation of cable modules (e.g., dimmers and relays) with IP, name, and type
DIMMER_A = CABLE:new("192.168.0.121", '', "DIMMER_A", TYPES.CABLE_DIMMER)
DIMMER_B = CABLE:new("192.168.0.122", '', "DIMMER_B", TYPES.CABLE_DIMMER)
DIMMER_C = CABLE:new("192.168.0.123", '', "DIMMER_C", TYPES.CABLE_DIMMER)
DIMMER_D = CABLE:new("192.168.0.124", '', "DIMMER_D", TYPES.CABLE_DIMMER)
RELE_E = CABLE:new("192.168.0.125", '', "RELE_E", TYPES.CABLE_RELAY)

-- Associate dimmers with their respective loads (sections)
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
-- Test cable modules
local CABLE = require('user.cable')
local teste_rele = CABLE:new("10.100.200.204", '', "rele", TYPES.CABLE_RELAY)

-- Associate test relay with loads
teste_rele.loads = {
    ["S2"] = 1,
    ["S3"] = 2,
    ["S4"] = 3,
    ["S5"] = 4,
    ["S6"] = 5,
    ["S7"] = 6,
    ["S8"] = 8
}

-- Create interface for the test modules
TEST_LIST = {teste_rele}
TEST_INTERFACE = createModuleInterface(TEST_LIST)
]]--


XPORT = require('user.xport')

x_test = XPORT:new("10.100.200.247","","automatic")
x_test:connect()