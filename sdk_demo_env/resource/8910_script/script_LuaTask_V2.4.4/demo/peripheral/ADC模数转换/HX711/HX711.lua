
--- 模块功能：CCS811
--- Author JWL  



module(..., package.seeall)
require "pins"


local   bverify =true
local   GapValue        =   430

local Weight_Total =nil
local Weight_Shiwu =nil
local Weight_Maopi =0
 
local HX711_SCK =  pins.setup(pio.P0_3,0)
local HX711_DOUT=nil

local dummy_cnt=0
local function Delay__hx711_us(cnt)
    cnt =cnt or 1
    for i=1,cnt do
        dummy_cnt = dummy_cnt+1
    end
end

--this function can only be read by TASK!!
function  HX711_Read()
     local count=0
     HX711_DOUT = pins.setup(pio.P0_1,1) --配置为输出
     Delay__hx711_us(100)
     HX711_SCK(0) 

    HX711_DOUT = pins.setup(pio.P0_1, function() end, pio.NOPULL)  --配置为输入
    while  HX711_DOUT() ==1 do end
 

    local tb={}

    for i=1,24 do 
        tb[i]=0
    end
    
    for i=1,24 do 
        HX711_SCK(1)
        HX711_SCK(0)
        tb[i]=HX711_DOUT()
    end

    if "1111111" == table.concat(tb,"",18) then --最后7位不能全部为1
      return 0
    end

    for i=1,24 do 
        count = bit.lshift(count,1)
        if tb[i] ==1 then  count = count+ 1 end
    end

    HX711_SCK(1)
    count = bit.bxor(count,0x800000)
    Delay__hx711_us()
    HX711_SCK(0)
    return count
end


--此函数只能被任务调用!!!
local function Get_Maopi()

    log.info("Weight_Maopi =", "want to get")
    while Weight_Maopi == 0 do 
        Weight_Maopi = HX711_Read()
        sys.wait(200)
    end

    log.info("Weight_Maopi =", Weight_Maopi)
end

--此函数只能被任务调用!!!
function Get_Weight()
    Weight_Total = HX711_Read()
    if Weight_Total >0 then
        Weight_Shiwu = Weight_Total - Weight_Maopi;	
        log.info("totalweight =", Weight_Total, "Maopi=", Weight_Maopi, " delta=",Weight_Shiwu,"Weight_Shiwu"  , "----> ",   Weight_Shiwu/GapValue)
    else
        log.info("[ALM]","Weight_Shiwu==0")
    end
end




sys.taskInit(function()
    pmd.ldoset(15, pmd.LDO_VLCD)

    local times=0
    sys.wait(2000)

    while true do
        if bverify then 
            Get_Maopi()
            bverify=false
        end
    
        Get_Weight()
        sys.wait(100)
    end
end)



local keyName = {
    [0] = {},
    [255] = {
        [255] = "PWRKEY"
    }
}

local function keyMsg(msg)
    log.warn("key",msg.key_matrix_row,msg.key_matrix_col)
    if  keyName[msg.key_matrix_row][msg.key_matrix_col] == "PWRKEY" then
        if msg.pressed then
            --短按开机键校准
            bverify =true
        end
    end
end

--注册按键消息的处理函数
rtos.on(rtos.MSG_KEYPAD, keyMsg)
--初始化键盘阵列
rtos.init_module(rtos.MOD_KEYPAD, 0, 0x1F, 0x1F)
pio.pin.setdebounce(10)--不要调用这个，否则影响GPIO 读取