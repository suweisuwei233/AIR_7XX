
PROJECT = "hello_world"
VERSION = "1.0.0"

sys = require("sys")
print(_VERSION)

sys.timerLoopStart(function()
    print("Test Latus\r\n")
end, 1000)

local uartid = 1 -- 根据实际设备选取不同的uartid
-- 初始化
local result = uart.setup(uartid, -- 串口id
115200, -- 波特率
8, -- 数据位
1 -- 停止位
)
-- sys.taskInit(function()
--     while 0 do
--         sys.wait(50)
--     end
-- end)
-- sys.taskInit(function()
--     while 0 do
--         uart.write(uartid,
--             "你好这个是一个测试你好这个是一个测试你好这个是一个测试你好这个是一个测试\r\n");
--         sys.wait(50)
--     end
-- end)
-- sys.timerLoopStart(uart.write, 10000, uartid,
--     "你好这个是一个测试你好这个是一个测试你好这个是一个测试你好这个是一个测试\r\n")

usart1_printf= function(s, ...)
    return uart.write(uartid,s:format(...))
end
usart1_printf("%s\n", "Hello World!")
sys.taskInit(function()
    local str = ""
    while 1 do
        str = uart.read(uartid,0x800)
        sys.wait(1000);
        uart.write(uartid,str);
        usart1_printf("the get string len : %d\r\n",string.len(str));
            log.info("GET str","str:"..str);
            log.error("GET str","str:"..str);
        sys.wait(1000);

    end
end)


sys.run()
