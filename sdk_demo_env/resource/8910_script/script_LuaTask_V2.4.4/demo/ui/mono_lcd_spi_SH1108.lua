--- 模块功能：SH1108驱动芯片LCD命令配置
-- @author openLuat
-- @module ui.mono_std_spi_SH1108
-- @license MIT
-- @copyright openLuat
-- @release 2022.06.06
--[[
注意：disp库目前支持I2C接口和SPI接口的屏，此文件的配置，硬件上使用的是724 LCD专用的SPI引脚
硬件连线图如下：
Air模块         LCD
GND      --     GND
V_LCD    --     VCC
LCD_CLK  --     SCL
LCD_DIO  --     SDA
LCD_RST  --     RES
LCD_RS   --     DC
LCD_CS   --     CS
]] module(..., package.seeall)

--[[
函数名：init
功能  ：初始化LCD参数
参数  ：无
返回值：无
]]
local function init()
    local para = {
        width = 128, -- 分辨率宽度，128像素；用户根据屏的参数自行修改
        height = 160, -- 分辨率高度，64像素；用户根据屏的参数自行修改
        bpp = 1, -- 位深度，1表示单色。单色屏就设置为1，不可修改
        bus = disp.BUS_SPI4LINE, -- led位标准SPI接口，不可修改
        yoffset = 0, -- Y轴偏移
        hwfillcolor = 0x0, -- 填充色，黑色
        pinrst = pio.P0_6, -- reset，复位引脚
        pinrs = pio.P0_1, -- rs，命令/数据选择引脚
        -- 初始化命令
        initcmd = {0x000200AE, -- display off
        0x00020081, -- Set Contrast Control
        0x000200D0, 0x000200A0, -- Set Segment Re-map
        0x000200A4, -- Set Entire Display OFF/ON
        0x000200A6, -- Set Normal/Reverse Display
        0x000200A9, -- Display Resolution Control
        0x00020002, 0x000200AD, -- DC-DC Control Mode Set 
        0x00020080, -- set start line address
        0x000200C0, -- Set Common Output Scan Direction
        0x000200A0, --
        0x000200D5, -- Set Display Clock Divide Ratio/Oscillator Frequency
        0x00020040, 0x000200D9, -- Dis-charge/Pre-charge Period Mode Set
        0x0002002F, 0x000200DB, -- Set VCOM Deselect Level
        0x0002003F, 0x00020020, -- Page addressing mode
        0x000200DC, -- VSEGM Deselect Level Mode Set
        0x00020035, 0x00020030, -- Set Discharge VSL Level
        0x000200AF -- turn on oled panel
        },
        -- 休眠命令
        sleepcmd = {0x000200AE},
        -- 唤醒命令
        wakecmd = {0x000200AF}
    }
    disp.init(para)
    disp.clear()
    disp.update()
end

disp.update = function()
    local pic = disp.getframe()
    local size = 0
    for i = 0, 19 do
        disp.write(0x000200b0)
        disp.write(0x00020000 + i)
        disp.write(0x00020000)
        disp.write(0x00020011)
        local data = pic:sub((i * 128) + 1, (i + 1) * 128)
        for i = 1, data:len() do
            disp.write(tonumber(string.toHex(data:sub(i, i)), 16) + 0x00030000)
        end
    end
end
-- 控制SPI引脚的电压域
pmd.ldoset(15, pmd.LDO_VLCD)
init()
