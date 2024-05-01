--- modbus模块功能
-- @module modbus
-- @author JWL
-- @license MIT
-- @copyright openLuat
-- @release 2021.11.17

module(...,package.seeall)

require"utils"
require"common"



local THISDEV =0x01

--保持系统处于唤醒状态，此处只是为了测试需要，所以此模块没有地方调用pm.sleep("testUart")休眠，不会进入低功耗休眠状态
--在开发“要求功耗低”的项目时，一定要想办法保证pm.wake("modbusrtu")后，在不需要串口时调用pm.sleep("testUart")
pm.wake("modbusrtuslav")

local uart_id = 1
local uart_baud = 9600
--[[
--   起始        地址    功能代码    数据       CRC校验    结束
-- 3.5 字符     8 位      8 位      N x 8 位   16 位      3.5 字符
--- 发送modbus数据函数
@function   modbus_resp
@param      slaveaddr : 从站地址
            Instructions:功能码
            hexdat 回复的数据 HEX STRING
@return     无
@usage modbus_resp("0x01","0x01","0x0101","0x04")
]]
local function modbus_resp(slaveaddr,Instructions,hexdat)
    local data = (string.format("%02x",slaveaddr)..string.format("%02x",Instructions)..hexdat):fromHex()
    local modbus_crc_data= pack.pack('<h', crypto.crc16("MODBUS",data))
    local data_tx = data..modbus_crc_data
    uart.write(uart_id,data_tx)
end

---仿真回复阵列，实际数字位则用业务状态/数据替换
local rsptb={}
rsptb[0x01]={0xFF,0XFF} 
rsptb[0x02]={0x55,0X55} 
rsptb[0x03]={0X00,0X01,0X02,0X03,0X04,0X05,0X06,0X07,0X08,0X09,0X0A,0X0B,0X0C,0X0D,0X0E,0X0F} 
rsptb[0x04]={0X10,0X11,0X12,0X13,0X14,0X15,0X16,0X17,0X18,0X19,0X1A,0X1B,0X1C,0X1D,0X1E,0X1F} 

local function MSK_DIGI(pos)
    local msk =0
    for i=1,pos do
        msk=bit.lshift(msk,1)
        msk=msk+1
    end
    return msk
end

local function modbus_read()
    local cacheData = ""
    while true do
        local s = uart.read(uart_id,1)
        if s == "" then
        
            if not sys.waitUntil("UART_RECEIVE",35000/uart_baud) then
                -- 3.5个字符的时间间隔，只是用在RTU模式下面，因为RTU模式没有开始符和结束符，
                -- 两个数据包之间只能靠时间间隔来区分，Modbus定义在不同的波特率下，间隔时间是不一样的，
                -- 所以就是3.5个字符的时间，波特率高，这个时间间隔就小，波特率低，这个时间间隔相应就大
                -- 4800  = 7.297ms
                -- 9600  = 3.646ms
                -- 19200  = 1.771ms
                -- 38400  = 0.885ms
                --uart接收数据，如果 35000/uart_baud 毫秒没有收到数据，则打印出来所有已收到的数据，清空数据缓冲区，等待下次数据接收
                --注意：
                --因为在整个GSM模块软件系统中，软件定时器的精确性无法保证，例如本demo配置的是100毫秒，在系统繁忙时，实际延时可能远远超过100毫秒，达到200毫秒、300毫秒、400毫秒等
                --设置的延时时间越短，误差越大
                if cacheData:len()>0 then
                    local a = string.toHex(cacheData)
                    log.info("modbus接收数据:",a)

                    -- 0x01: 读线圈寄存器               位操作     单个或多个
                    -- 0x02: 读离散输入寄存器           位操作     单个或多个
                    -- 0x03: 读保持寄存器               字节操作   单个或多个
                    -- 0x04: 读输入寄存器               字节操作   单个或多个
                    -- 0x05: 写单个线圈寄存器           位操作     单个
                    -- 0x06: 写单个保持寄存器           字节操作   单个
                    -- 0x0f: 写多个线圈寄存器           位操作     多个
                    -- 0x10: 写多个保持寄存器           字节操作   多个

                    -- ----------------------错误码定义---------------------------------
                    -- 01	非法功能。对于服务器（或从站）来说，询问中接收到的功能码是不可允许的操作，可能是因为功能码仅适用于新设备而被选单元中不可实现同时，还指出服务器（或从站）在错误状态中处理这种请求，例如：它是未配置的，且要求返回寄存器值。
                    -- 02	非法数据地址。对于服务器（或从站）来说，询问中接收的数据地址是不可允许的地址，特别是参考号和传输长度的组合是无效的。对于带有100个寄存器的控制器来说，偏移量96和长度4的请求会成功，而偏移量96和长度5的请求将产生异常码02。
                    -- 03	非法数据值。对于服务器（或从站）来说，询问中包括的值是不可允许的值。该值指示了组合请求剩余结构中的故障。例如：隐含长度是不正确的。modbus协议不知道任何特殊寄存器的任何特殊值的重要意义，寄存器中被提交存储的数据项有一个应用程序期望之外的值。
                    -- 04	从站设备故障。当服务器（或从站）正在设法执行请求的操作时，产生不可重新获得的差错。
                    -- 05	确认。与编程命令一起使用，服务器（或从站）已经接受请求，并且正在处理这个请求，但是需要长持续时间进行这些操作，返回这个响应防止在客户机（或主站）中发生超时错误，客户机（或主机）可以继续发送轮询程序完成报文来确认是否完成处理。
                    -- 06	从属设备忙。与编程命令一起使用。服务器(或从站)正在处理长持续时间的程序命令。张服务器(或从站)空闲时，用户(或主站)应该稍后重新传输报文。
                    -- 08	存储奇偶差错。与功能码20和21以及参考类型6一起使用，指示扩展文件区不能通过一致性校验。服务器(或从站)设法读取记录文件，但是在存储器中发现一个奇偶校验错误。客户机(或主方)可以重新发送请求，但可以在服务器(或从站)设备上要求服务。
                    -- 10	不可用网关路径。与网关一起使用，指示网关不能为处理请求分配输入端口至输出端口的内部通信路径。通常意味着网关是错误配置的或过载的。
                    -- 11	网关目标设备响应失败。与网关一起使用，指示没有从目标设备中获得响应。通常意味着设备未在网络中。

                    local nextpos ,dev, func = pack.unpack(cacheData,"bb",1)
                    log.info("nextpos ,dev, func ",nextpos , string.format("%02X,%02X", dev or 0, func or 0)  )
                    --01 06 0001 0002 59CB
                    if dev ==THISDEV then
                         if func == 0x01 or func == 0x02  or func == 0x03  or func == 0x04 or func == 0x05 or func == 0x06 then
                            if #cacheData >= 8 then
                                local strcrc= pack.pack('<h', crypto.crc16("MODBUS",cacheData:sub(1,6)))
                                if strcrc == cacheData:sub(7,8) then
                                    local _, reg,val = pack.unpack(cacheData,">H>H",nextpos)
                                    log.info("a-func,crc is correct!",func,  string.format("reg=0x%04X, val=0x%04X",reg,val))
                                    --校验正确后，根据不同的功能码做回复(DEMO 忽略起始地址)
                                    if func ==0x01 or func ==0x02 then 
                                        ---01 01 00 00 00 0A BC 0D
                                        local _,bitcnt =  pack.unpack(cacheData,">H",5)
                                        if bitcnt >0 then 
                                             local bytlen ,hflg=0,false
                                             if bitcnt%8 == 0 then  
                                                bytlen= bitcnt/8 
                                             else  
                                                bytlen=  ( bitcnt- bitcnt%8)/8 + 1  
                                                hflg =true
                                             end
                                             if bytlen <= #rsptb[func] then
                                                local strhex =""
                                                for i=1,bytlen do
                                                    if hflg and i ==bytlen then 
                                                        --不足一个字节的位数，主机和从机之间定好协议，这里就简化成低位掩码,用户自己对照
                                                        local msk = MSK_DIGI(bitcnt%8)
                                                        strhex = strhex.. string.format("%02x", bit.band( rsptb[func][i] ,msk) )  
                                                    else
                                                        strhex = strhex.. string.format("%02x",rsptb[func][i])  
                                                    end
                                                end
                                                log.info(" bytlen , #rsptb[func], msk,strhex", bytlen , #rsptb[func],msk,strhex)
                                                modbus_resp(THISDEV,func, string.format("%02x%s",#strhex/2,strhex))
                                             else
                                                modbus_resp(THISDEV,func+0x80, string.format("%02x",0x02))
                                             end
                                        end
                                    elseif  func ==0x03 or func ==0x04 then 
                                        local _,bytlen =  pack.unpack(cacheData,">H",5)
                                        if bytlen <=#rsptb[func] then
                                            local strhex =""
                                            for i=1,bytlen do
                                               strhex = strhex.. string.format("%04x",rsptb[func][i])  
                                            end
                                            log.info(" bytlen , #rsptb[func], msk,strhex", bytlen , #rsptb[func],msk,strhex)
                                            modbus_resp(THISDEV,func, string.format("%02x%s",#strhex/2,strhex))
                                        else
                                            modbus_resp(THISDEV,func+0x80, string.format("%02x",0x02))
                                        end
                                    elseif  func ==0x05 or func ==0x06 then 
                                        --假设写入都是成功的，实际上写入也要判断值域：回复则是原包返回
                                        log.info("save set data ",func,  string.format("reg=0x%04X, val=0x%04X",reg,val))
                                        local strhex = string.format("%04X%04X",reg,val)
                                        modbus_resp(THISDEV,func, strhex)

                                    else
                                        log.info("unkonw func",func)
                                        modbus_resp(THISDEV,func+0x80, string.format("%02x",0x01))
                                    end
                                else
                                    log.info("a-func #cacheData  crc, calcrc", func, #cacheData, cacheData:sub(7,8) :toHex(),  strcrc:toHex())
                                end
                            end
                        elseif func == 0x0F   then 
                            local dlen = cacheData:byte(nextpos+4)
                            if #cacheData >= 7+dlen+2 then
                                local strcrc= pack.pack('<h', crypto.crc16("MODBUS",cacheData:sub(1,7+dlen)))
                                if strcrc == cacheData:sub(7+dlen+1,7+dlen+2) then
                                    local _, reg,val = pack.unpack(cacheData,">H>H",nextpos)
                                    local tmpdat = cacheData:sub(8,dlen+8-1)
                                     --假设写入都是成功的，实际上写入也要判断值域：回复为起始地址和线圈个数
                                    log.info("b-func crc is correct!",func,dlen,"will save:", tmpdat:toHex())
                                    local strhex = string.format("%04X%04X",reg,val)
                                    modbus_resp(THISDEV,func,strhex)
                                else
                                    log.info("b-func,#cacheData  crc, calcrc",func, #cacheData, cacheData:sub(7+dlen+1,7+dlen+2) :toHex(),  strcrc:toHex())
                                end
                            end

                        elseif func == 0x10 then 
                            local dlen = cacheData:byte(nextpos+4)
                            log.info("#cacheData,func,dlen=",#cacheData,func,dlen)
                            --01 10 0000 000A 14 0000000000000000000000000000000000000000 70FE

                            if #cacheData >= 7+dlen+2 then
                                local strcrc= pack.pack('<h', crypto.crc16("MODBUS",cacheData:sub(1,7+dlen)))
                                if strcrc == cacheData:sub(7+dlen+1,7+dlen+2) then
                                    local _, reg,val = pack.unpack(cacheData,">H>H",nextpos)
                                    local tmpdat = cacheData:sub(8,dlen +8-1)
                                    --假设写入都是成功的，实际上写入也要判断值域：回复为起始地址和字节个数
                                    log.info("c-func crc is correct!",func,dlen,"will save:", tmpdat:toHex(),  #tmpdat/2,"words")
                                    local strhex = string.format("%04X%04X",reg,val)
                                    modbus_resp(THISDEV,func,strhex)

                                else
                                    log.info("c-func,#cacheData  crc, calcrc",func, #cacheData, cacheData:sub(7+dlen+1,7+dlen+2) :toHex(),  strcrc:toHex())
                                end
                            end
                        end
                    end
                    --MODBUS 暂时不考虑粘包的情况
                    cacheData = ""
                end
            end
        else
            cacheData = cacheData..s
        end
    end
end




--配置并且打开串口
uart.setup(uart_id,uart_baud,8,uart.PAR_NONE,uart.STOP_1,nil,1)
--配置485的GPIO DIR
uart.set_rs485_oe(uart_id,18)

--注册串口的数据发送通知函数
uart.on(uart_id,"receive",function() sys.publish("UART_RECEIVE") end)


--启动串口数据接收任务
sys.taskInit(modbus_read)





