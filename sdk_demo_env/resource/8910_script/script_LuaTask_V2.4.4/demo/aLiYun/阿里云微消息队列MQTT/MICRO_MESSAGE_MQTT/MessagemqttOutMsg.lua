--- 模块功能：微消息队列_MQTT客户端数据发送处理
-- @author openLuat
-- @module mqtt.mqttOutMsg
-- @license MIT
-- @copyright openLuat
-- @release 2022.08.31


module(...,package.seeall)

--数据发送的消息队列
local msgQueue = {}

local function insertMsg(topic,payload,qos,user)
    if MessagemqttTask.isReady() then
        table.insert(msgQueue,{t=topic,p=payload,q=qos,user=user})
        sys.publish("APP_SOCKET_SEND_DATA")
    end
end
-------发布测试------

local function pubQos0TestCb(result)
    log.info("mqttOutMsg.pubQos0TestCb",result)
    if result then sys.timerStart(pubQos0Test,10000) end
end

function pubQos0Test()
    insertMsg("luatceshi/ceshiwanglong","12345",0,{cb=pubQos0TestCb}) -----换成自己的主题，或者注释掉，不然报错
end



-------发布测试------

--- 初始化“MQTT客户端数据发送”
-- @return 无
-- @usage mqttOutMsg.init()
function init()
    pubQos0Test()
end



--- 去初始化“MQTT客户端数据发送”
-- @return 无
-- @usage mqttOutMsg.unInit()
function unInit()
    while #msgQueue>0 do
        local outMsg = table.remove(msgQueue,1)
        if outMsg.user and outMsg.user.cb then outMsg.user.cb(false,outMsg.user.para) end
    end
end


--- MQTT客户端数据发送处理
-- @param mqttClient，MQTT客户端对象
-- @return 处理成功返回true，处理出错返回false
-- @usage mqttOutMsg.proc(mqttClient)
function proc(mqttClient)
    --log.info("mqttOutMsg.proc1",#msgQueue)
    while #msgQueue>0 do
        local outMsg = table.remove(msgQueue,1)
        log.info("mqttOutMsg.proc before publish",outMsg.p)
        local result = mqttClient:publish(outMsg.t,outMsg.p,outMsg.q)
        --log.info("mqttOutMsg.proc after publish",result)
        if outMsg.user and outMsg.user.cb then outMsg.user.cb(result,outMsg.user.para) end
        if not result then return end
    end
    return true
end
