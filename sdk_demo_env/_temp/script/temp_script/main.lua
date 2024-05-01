
PROJECT = "hello_world"
VERSION = "1.0.0"

sys = require("sys")
print(_VERSION)

sys.timerLoopStart(function()
print("Test Latus\r\n")
end, 1000)

local uartid = 1

local result = uart.setup(uartid,
115200,
8,
1
)















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
