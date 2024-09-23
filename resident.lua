-- Initialize 'conta' if not already defined
if not conta then conta = 0 end

-- Loop through each module in TEST_LIST
-- @note This script checks each module's status, connects, retrieves IO data, updates objects, and then disconnects
for i, m in ipairs(TEST_LIST) do

    -- Get the alias of the module's name in grp (group object, presumably KNX or similar)
    local is_obj = grp.alias(m.NAME)

    -- Check if the module is online by pinging it
    m.online = m:ping()

    -- Update the module's online status in the grp (group object)
    grp.checkupdate(m.NAME, m.online, 1)

    -- Attempt to connect to the module
    m:connect()

    -- If connected and the object exists in grp, retrieve IO data
    if m.connectionStatus and is_obj then
        m:getIO()
    elseif not is_obj then
        -- Log if the object does not exist in grp
        log("Objeto: " .. m.NAME .. " não foi criado\n")
    end

    -- Update the objects based on the module's current state
    updateObjects(m)

    -- Increment the counter for each processed module
    conta = conta + 1

    -- Disconnect from the module after processing
    m:disconnect()
end
