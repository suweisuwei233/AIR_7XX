--- 模块功能：微消息队列_MQTT客户端处理框架
-- @author openLuat
-- @module mqtt.mqttTask
-- @license MIT
-- @copyright openLuat
-- @release 2022.08.31

module(...,package.seeall)

require"misc"
require"mqtt"
require"MessagemqttOutMsg"
require"MessagemqttInMsg"
local ready = false
---------------注意ParentTopic Group_ID 的长度不易过长 ,阿里云限制最多64个字符---------------

ParentTopic="XXX" --父级Topic 必须在微消息队列MQTT版控制台创建
Group_ID="XXXXX" --共用组名 必须在微消息队列MQTT版控制台创建
HOST="XXXXX"--微消息队列接入点
INSTANCE_ID="XXXXXX" --实例ID 微消息队列MQTT版控制台可以看到
AccessKey_ID="XXXXXXXX" ---阿里云访问凭证
AccessKey_Secret="XXXXXXXXXXX"
---------------微消息队列参数设置---------------
--- MQTT连接是否处于激活状态
-- @return 激活状态返回true，非激活状态返回false
-- @usage mqttTask.isReady()
function isReady()
    return ready
end

function getSubscribeTopic()
    -- return PARENT_TOPIC.."/y506/"..nvm.get("deviceSn")
    return ParentTopic.."/ceshiwanglong" ----改为自己的topic
	--------p2p模式----------------------
	
	---return ParentTopic.."/p2p/".."/Group_ID .. "@@@" ..misc.getSn()/" ----改为自己的topic
	----发送P2P消息时，需将二级Topic设为“p2p”，将三级Topic设为目标接收者的Client ID。
	----接收消息的客户端无需任何订阅处理，只需要完成客户端的初始化即可收到P2P消息。
	--------p2p模式----------------------
end



--启动MQTT客户端任务
sys.taskInit(function()
    local retryConnectCnt = 0
    while true do
        if not socket.isReady() then
            retryConnectCnt = 0
            -- 等待网络环境准备就绪，超时时间是5分钟
            sys.waitUntil("IP_READY_IND", 300000)
        end

        if socket.isReady() then
            -- 创建一个MQTT客户端

            local clientID = Group_ID .. "@@@" ..misc.getSn()
            local userName = "Signature|" .. AccessKey_ID .. "|" .. INSTANCE_ID
            local password = string.fromHex(crypto.hmac_sha1(clientID, clientID:len(),AccessKey_Secret,AccessKey_Secret:len()))
            password = crypto.base64_encode(password, password:len())
            local mqttClient = mqtt.client(clientID,600,userName,password,nil)
            -- 阻塞执行MQTT CONNECT动作，直至成功
            -- 如果使用ssl连接，打开mqttClient:connect("lbsmqtt.airm2m.com",1884,"tcp_ssl",{caCert="ca.crt"})，根据自己的需求配置
            -- mqttClient:connect("lbsmqtt.airm2m.com",1884,"tcp_ssl",{caCert="ca.crt"})
            if mqttClient:connect(HOST, 1883, "tcp") then
                retryConnectCnt = 0
                ready = true
                -- 订阅主题
                if mqttClient:subscribe(getSubscribeTopic(),1) then
                    MessagemqttOutMsg.init()
                    -- 循环处理接收和发送的数据
                    while true do
                        if not MessagemqttInMsg.proc(mqttClient) then
                            log.error("mqttTask.MessagemqttInMsg.proc error")
                            break
                        end
                        if not MessagemqttOutMsg.proc(mqttClient) then
                            log.error("mqttTask.MessagemqttOutMsg.proc error")
                            break
                        end
                    end
                    MessagemqttOutMsg.unInit()
                end
                ready = false
            else
                retryConnectCnt = retryConnectCnt + 1
            end
            -- 断开MQTT连接
            mqttClient:disconnect()
            if retryConnectCnt >= 5 then
                link.shut()
                retryConnectCnt = 0
            end
            sys.wait(5000)
        else
            -- 进入飞行模式，20秒之后，退出飞行模式
            net.switchFly(true)
            sys.wait(20000)
            net.switchFly(false)
        end
    end
end)


