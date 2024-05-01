--- 模块功能：MQTT客户端数据发送处理



module(...,package.seeall)

--数据发送的消息队列
local msgQueue = {}

local function insertMsg(topic,payload,qos,user)
    table.insert(msgQueue,{t=topic,p=payload,q=qos,user=user})
    sys.publish("APP_SOCKET_SEND_DATA")
end


--发布回调函数
local function pubQos1TestCb(result)
    log.info("mqttOutMsg.pubQos1TestCb",result)
end
--订阅mqtt_send消息，当录音时执行，将录音流数据上传
sys.subscribe("mqtt_send", function(data)
        insertMsg("mqtt/full/1",data,0,{cb=pubQos1TestCb})
    end)



--- MQTT客户端数据发送处理
-- @param mqttClient，MQTT客户端对象
-- @return 处理成功返回true，处理出错返回false
-- @usage mqttOutMsg.proc(mqttClient)
function proc(mqttClient)
    while #msgQueue>0 do
        local outMsg = table.remove(msgQueue,1)
        local result = mqttClient:publish(outMsg.t,outMsg.p,outMsg.q)
        if outMsg.user and outMsg.user.cb then outMsg.user.cb(result,outMsg.user.para) end
        if not result then return end
    end
    return true
end
