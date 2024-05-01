module(..., package.seeall)

require "socket"
require "http"

local data = {
    mode = 2, -- 1表示客户端；2表示服务器；默认为1
    clientNum = 3, -- server可连路数
    intPin = pio.P0_22, -- 以太网芯片中断通知引脚
    rstPin = pio.P0_21, -- 复位以太网芯片引脚
    localPort = 3352, -- 做服务器应用时，本机的端口
    localAddr = "192.168.31.111", -- 本机的地址
    localGateway = "192.168.31.1", -- 本机的网关地址
    CH395MAC = "84C2E4A81124",
    powerFunc = function(state)
        if state then
            local setGpioFnc_TX = pins.setup(pio.P0_7, 0)
            pmd.ldoset(15, pmd.LDO_VMMC)
        else
            pmd.ldoset(0, pmd.LDO_VMMC)
            local setGpioFnc_TX = pins.setup(pio.P0_7, 1)
        end
    end,
    spi = {spi.SPI_1, 0, 0, 8, 800000} -- SPI通道参数，id,cpha,cpol,dataBits,clock，默认spi.SPI_1,0,0,8,800000
}

-- 创建server
local serverOn = {}
local a = true
sys.taskInit(function()
    sys.wait(3000)
    while not link.openNetwork(link.CH395, data) do
        sys.wait(5000)
    end

    while true do
        while not socket.isReady() do
            sys.wait(1000)
        end
        local socketServer = socket.tcp(nil, nil,{type = "TCPSERVER"} )
        --{type = "TCPSERVER"}
        --"TCPSERVER"
        while socketServer:serverSelect() do
        end
        socketServer:close()
        serverOn={}
    end

end)

--关闭连接示例，打开后，会60秒后断开第一个客户端连接
-- sys.timerStart(function ()
--     --关闭server或者server连接
--     serverOn[1]:serverClose()
-- end, 60000)


--server被连接"tcpServer"消息会传值para，利用这个值创建server连接对象。
sys.subscribe("tcpServer", function(para)
    sys.taskInit(function()
        local socketClient
        while not socketClient do
            socketClient = socket.tcp(nil, nil, para)
        end

        serverOn[socketClient.id] = socketClient
        while socketClient:serverSelect() do
        end
        log.info('close',socketClient.id)
        serverOn[socketClient.id] = nil
        socketClient:close()

    end)
end)

-- 测试代码,用于发送消息给socket
sys.taskInit(function()
    local dd = 0
    while true do
        while not socket.isReady() do
            sys.wait(2000)
        end
        sys.wait(1000)
        local num = 0
        for i, v in pairs(serverOn) do
            if serverOn[i] then
                num = num + 1
                serverOn[i]:serverSend("hello word" .. dd.."\r\n", 20)
                sys.wait(500)
            end

        end
        log.info('server client number', num)
        dd = dd + 1
    end
end)

-- 测试代码,用于从socket接收消息
sys.taskInit(function()
    local cnt = 0
    while not socket.isReady() do
        sys.wait(2000)
    end
    sys.wait(10000)
    -- 这是演示用异步接口直接读取服务器数据
    while true do
        for i, v in ipairs(serverOn) do
            if serverOn[i] then
                local data = serverOn[i]:serverRecv()
                if data ~= '' then
                    cnt = cnt + #data
                    log.info("客户端"..serverOn[i].id.."发来数据:", cnt, data:sub(1, 30))
                end
            end
            sys.wait(100)
        end
        sys.wait(100)
    end
end)

---------Http------------
--不属于server功能，可注释
local function cbFnc(result,prompt,head,body)
    log.info("testHttp.cbFnc",result,prompt)
    if result and head then
        for k,v in pairs(head) do
            log.info("testHttp.cbFnc",k..": "..v)
        end
    end
    if result and body then
        log.info("testHttp.cbFnc","bodyLen="..body:len())
    end
end

local function cbFncFile(result,prompt,head,filePath)
    log.info("testHttp.cbFncFile",result,prompt,filePath)
    if result and head then
        for k,v in pairs(head) do
            log.info("testHttp.cbFncFile",k..": "..v)
        end
    end
    if result and filePath then
        local size = io.fileSize(filePath)
        log.info("testHttp.cbFncFile","fileSize="..size)

        --输出文件内容，如果文件太大，一次性读出文件内容可能会造成内存不足，分次读出可以避免此问题
        if size<=4096 then
            log.info("testHttp.cbFncFile",io.readFile(filePath))
        else

        end
    end
    --文件使用完之后，如果以后不再用到，需要自行删除
    if filePath then os.remove(filePath) end
end

--作为server，最多开启7路。如果开启5路server通道，那还剩2通道可做客户端使用。（如果要解析域名建议留2客户端 通道）
sys.taskInit(function ()
     while true do
        sys.wait(30000)
        http.request("GET","http://www.lua.org",nil,nil,nil,nil,cbFnc)
        log.info('结束')
        sys.wait(30000)
        --return
     end
end)

