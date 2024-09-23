if not conta then conta = 0 end

for i, m in ipairs(TEST_LIST) do

    local is_obj = grp.alias(m.NAME)

    m.online = m:ping()
    grp.checkupdate(m.NAME, m.online, 1)

    m:connect()

    if m.connectionStatus and is_obj then
        m:getIO()
    elseif not is_obj then
        log("Objeto: " .. m.NAME .. "não foi criado\n")
    end

    updateObjects(m)

    conta = conta + 1
    m:disconnect()
end
