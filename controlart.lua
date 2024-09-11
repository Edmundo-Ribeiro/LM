
local CRLF = '\r\n'

-- Coloca o mac no formato que a controlart entende nos comandos TCP
function formatMac(mac_string)
    return "$".. mac_string:sub(1,2) .. ",$" .. mac_string:sub(4,5) .. ",$" .. mac_string:sub(7,8)
end


--Transforma string retonrndada pelo comando getmac no formato para envio nos comandos TCP
function macString(mac_string)  
  local _, macDigits = mac_string:match("([^,]+),([^,]+)") -- macDigits -> XX-XX-XX  
  return formatMac(macDigits)
end


--Conteudo da classe controlart
Controlart = {}
  
--Construtor da classe controlart
function Controlart:new(ip, mac, name, TYPE)
    local o = {}
    setmetatable(o, self)
    self.__index = self


    self.IP = ip or ''
    self.MAC = mac or ''
    self.NAME = name or ''
    self.TYPE = TYPE or ''
    self.PORT = 4998
    
    self.client = nil
    self.TIMEOUT_THRESHOLD = 5
    self.lastIoUpdate = 0

    return o
end


--Transformar as informações do objeto em uma string para debug 
function Controlart:toString()
  local str = ''
  
  if self.name then 
    str = str.. "Nome: "..self.name..","
  end

  if self.IP then 
    str = str.. " IP: "..self.IP..","
  end

  if self.MAC then 
    str = str.. " MAC: "..self.MAC..","
  end

  if self.TYPE then 
    str = str.. " tipo: "..self.TYPE..","
  end

  return str
end


-- Realizar a conexão do socket TCP
function Controlart:connect()
    self.client = socket.tcp()
    
    self.client:settimeout(Xport.TIMEOUT_THRESHOLD)
    local established, connectionErr = self.client:connect(self.IP, self.PORT)  --realiza conexão 
    
    if established then
      self.connectionStatus = true
      log("Estabelecida conexão com modulo: "..self:toString().."\n")  

      if self.MAC == '' and self.TYPE == "CABLE"then -- obter o mac dos modulos cabeados caso não tenha sido informado
        self:askForMac()
      end 
    end
    
    if connectionErr then
      log("Não foi possivel conectar modulo: "..self:toString().."\n Erro: "..connectionErr.."\n")
      self.connectionStatus = false
      self.client = nil
    end
    
    return self.connectionStatus, connectionErr
end


-- Desconectar socket  
function Controlart:disconnect()
    if self.client then
      self.client:close()  
      self.client =  nil
    end
    log("Socket de coexão com "..self:toString().." fechado\n")
end


-- Realizar um ping para o equipamento, se conseguiu retorna true
function Controlart:checkConnection()

    local pingCommand = "ping -c 1 " .. self.IP
    local pingProcess = io.popen(pingCommand)
    local pingOutput = pingProcess:read("*a")
    pingProcess:close()
      --log(pingOutput)
    return string.find(pingOutput, "1 packets received") ~=0
    
end


-- Enviar comandos para equipamento e aguardar resposta
function Controlart:sendCommand(cmd, waitForResponse)
  
    waitForResponse = waitForResponse or self.TIMEOUT_THRESHOLD
    
    -- Se estiver conectado 
    if self.connectionStatus then
      local _, sendErr = self.client:send(cmd..CRLF)
      if sendErr then
        log("Erro: ["..sendErr.."] ao tentar enviar comando para o modulo: "..self:toString().."\n")
        return false
      end
    else
      log("Não há conexão com modulo: "..self:toString().."\n")
      return false
    end
   
    if waitForResponse == 0 then
      return true
    end
    
    return self:getResponse(waitForResponse)
    
end

--Receber resposta após enviar um comando
function Controlart:getResponse(wait)
    wait = wait or 0
    local lastDataReceived, deltaTime = os.time(), 0
  
      while deltaTime <= wait do
      
      local readable, _, err = socket.select({self.client}, nil, 0)
      
      if #readable > 0 then
          local data, receiveErr, partialData = self.client:receive("*l")
        
        if data then
            return data
          end
        
        if receiveErr then
            log("Erro ["..receiveErr.."] ao tentar receber resposta de "..self:toString().."\n")  
        end
        
      end
      
      deltaTime = os.time() - lastDataReceived
      end
    
    
      log("Timeout, Tempo para resposta ao tentar receber resposta de "..self:toString().."\n")
      return false  
end


-----------------------------------------------------------------------------
function Controlart:checkType(...)
  local args = {...}
  for i, v in ipairs(args) do
    if v == self.TYPE then return true
  end
  return false
end





return Controlart