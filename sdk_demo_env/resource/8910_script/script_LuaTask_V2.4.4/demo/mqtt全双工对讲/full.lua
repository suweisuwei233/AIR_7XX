--- 模块功能：网络全双工对讲功能测试.
-- @author openLuat
-- @module Network full duplex intercom
-- @license MIT
-- @copyright openLuat
-- @release 2023.6.7
module(..., package.seeall)
-- require"record"
require "audio"
require "common"
require "pins"


--[[脚本测试逻辑：
--基于724 A13开发板，mic输入，spk输出；
--手动拉高GPIO19，触发gpio19上升沿中断开启录音，触发gpio19下降沿中断关闭录音；
--录音数据上传mqtt
--播放来自mqtt订阅频道消息
--]]

--播放来自mqtt订阅频道录音数据流数据
function play_matt(data)
    log.info("play_stream",string.toHex(data))
    audiocore.pocstreamplay(data)
end
--订阅消息
sys.subscribe("audio_play_full",play_matt)


-- 流录音
function recordCb(result, size, tag)
    log.info("testRecord.rcdcb", result, size, tag)
    if tag == "STREAM" then
        local s = audiocore.streamrecordread(size)
        sys.publish("mqtt_send",s) --发布消息，
        log.info("MICDATA", string.toHex(s)) ---打印录音数据流数据   
        --audiocore.pocstreamplay(s) ---读录音数据流数据  
    else
        log.info("poc stream record end")
    end
end

rtos.on(rtos.MSG_RECORD,
        function(msg) ---注册外部消息的处理函数，rtos.MSG_RECORD录音状态
    log.info("record.MSG_RECORD", msg.record_end_ind, msg.record_error_ind)
    if msg.record_error_ind then recordCb(false, 0, "END") end
    if msg.record_end_ind then
        recordCb(true, recordType == "FILE" and io.fileSize(FILE) or 0, "END")
    end
end)

rtos.on(rtos.MSG_STREAM_RECORD,
        function(msg) ---rtos.MSG_STREAM_RECORD流录音长度
    log.info("record.MSG_STREAM_RECORD", msg.wait_read_len)
    recordCb(true, msg.wait_read_len, "STREAM")
end)

-- recordType = "FILE"
recordType = "STREAM"

sys.taskInit(function()
    audiocore.pocstart(audiocore.AMR, 1) ----打开全双工对讲
    audio.setVolume(5)
    sys.wait(3000)
    function gpio19IntFnc(msg)
        log.info("testGpioSingle.gpio19IntFnc", msg, getGpio19Fnc())
        -- 上升沿中断开启录音，下降沿中断关闭录音
        if msg == cpu.INT_GPIO_POSEDGE then
            audiocore.pocstreamrecord(10,256) -- 全双工对讲流录音接口，录音时长10S
        end
        if msg == cpu.INT_GPIO_NEGEDGE then
            audiocore.pocstoprecord()-- 关闭全双工对讲流录音接口
        end
    end
    --pio.pin.setpull(pio.PULLUP,pio.P0_19)
    -- GPIO19配置为中断，可通过getGpio19Fnc()获取输入电平，产生中断时，自动执行gpio19IntFnc函数
    getGpio19Fnc = pins.setup(pio.P0_19, gpio19IntFnc)

end)

