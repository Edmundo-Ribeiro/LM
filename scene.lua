function getscenebyname(name)
    local id = db:getone('SELECT id FROM scenes WHERE name=?', name)
    assert(id, 'scene not found: ' .. name)
    return id
  end
  
  function getsequenceid(sceneid, object)
    local query = 'SELECT id FROM scene_sequence WHERE scene=? AND object=?'
    return db:getone(query, sceneid, object)
  end
  
  function getdata(name, addr)
    local scene = getscenebyname(name)
    local object = buslib.encodega(addr)
    local sequenceid = getsequenceid(scene, object)
  
    return scene, object, sequenceid
  end
  
  function addtoscene(name, addr)
    local scene, object, sequenceid = getdata(name, addr)
    local res, err
  
    if sequenceid then
      err = 'object already added'
    else
      res, err = require('webrequest')('scenes', 'sequence-save', {
        data = {
          scene = scene,
          object = object,
          bus_write = true,
        }
      })
    end
  
    return res, err
  end
  
  function removefromscene(name, addr)
    local scene, object, sequenceid = getdata(name, addr)
    local res, err
  
    if sequenceid then
      res, err = require('webrequest')('scenes', 'sequence-delete', {
        data = {
          id = sequenceid
        }
      })
  
      if not err then
        res = true
      end
    else
      err = 'object not found in scene'
    end
  
    return res, err
  end