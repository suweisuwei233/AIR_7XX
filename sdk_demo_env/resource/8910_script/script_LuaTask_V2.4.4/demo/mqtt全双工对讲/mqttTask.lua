--- 模块功能：MQTT客户端处理框架
-- @author openLuat
-- @module mqtt.mqttTask
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.28

module(...,package.seeall)

require"misc"
require"mqtt"
require"mqttOutMsg"
require"mqttInMsg"


--网络业务逻辑看门狗task
socketAppDogCo = sys.taskInit(function()
    while true do
        --连续5分钟没有喂狗，根据项目需求自行修改时长
        if sys.wait(300000) == nil then
            sys.restart("socketApp exception software dog timeout")
        end
    end
end)

--喂狗代码(根据产品业务逻辑，在适当的位置去调用)：
--如何去确认这个“适当的位置”呢？下面列举几种常见的场景：
--1、如果模块和服务器之间有应用心跳的应答机制，则可以在模块每次收到服务器的心跳应答时去喂狗
--2、如果没有心跳应答机制，可以在连接服务器成功后，起个定时器，每隔一段时间去喂一次狗；连接断开时，关闭这个喂狗定时器
--3、如果模块定时会向服务器发送数据，可以在每次发送数据成功后，去喂狗
--4、......
--网络业务逻辑看门狗的设计目的：
--sim卡识别异常、网络注册异常、PDP激活异常、socket异常、mqtt数据交互异常时
--都可以通过网络业务逻辑看门狗控制软重启




local ready = false

--- MQTT连接是否处于激活状态
-- @return 激活状态返回true，非激活状态返回false
-- @usage mqttTask.isReady()
function isReady()
    return ready
end

--启动MQTT客户端任务
sys.taskInit(
    function()
        while true do
            if not socket.isReady() then
                --等待网络环境准备就绪，超时时间是5分钟
                sys.waitUntil("IP_READY_IND",300000)
            end
            
            if socket.isReady() then
                local imei = misc.getImei()
                --创建一个MQTT客户端
                local mqttClient = mqtt.client(imei,600,"user","password")
                --阻塞执行MQTT CONNECT动作，直至成功
                --如果使用ssl连接，打开mqttClient:connect("lbsmqtt.airm2m.com",1884,"tcp_ssl",{caCert="ca.crt"})，根据自己的需求配置
                --mqttClient:connect("lbsmqtt.airm2m.com",1884,"tcp_ssl",{caCert="ca.crt"})
                if mqttClient:connect("lbsmqtt.airm2m.com",1883,"tcp") then
                    sys.timerLoopStart(function () coroutine.resume(socketAppDogCo ,"feed")   end , 120000)
                    ready = true
                    --订阅主题",0
                    if mqttClient:subscribe({["mqtt/full/2"]=0}) then
                        --循环处理接收和发送的数据
                        while true do
                            if not mqttInMsg.proc(mqttClient) then log.error("mqttTask.mqttInMsg.proc error") break end
                            if not mqttOutMsg.proc(mqttClient) then log.error("mqttTask.mqttOutMsg proc error") break end
                        end
                    end
                    ready = false
                end
                --断开MQTT连接

                mqttClient:disconnect()
                sys.wait(5000)
            else
                --进入飞行模式，20秒之后，退出飞行模式
                net.switchFly(true)
                sys.wait(20000)
                net.switchFly(false)
            end
        end
    end
)
