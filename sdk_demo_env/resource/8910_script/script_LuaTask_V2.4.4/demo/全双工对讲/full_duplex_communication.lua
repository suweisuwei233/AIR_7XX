--- 模块功能：音频功能测试.
-- @author openLuat
-- @module audio.testAudio
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.19
module(..., package.seeall)
-- require"record"
require "audio"
require "common"
require "pins"
local FILE = "/record.pcm"
-- 每次读取的录音文件长度
local RCD_READ_UNIT = 4096
-- rcdoffset：当前读取的录音文件内容起始位置
-- rcdsize：录音文件总长度
-- rcdcnt：当前需要读取多少次录音文件，才能全部读取
local rcdoffset, rcdsize, rcdcnt
local recordBuf = ""

--[[脚本测试逻辑：
--基于724 A13开发板，mic输入，spk输出；
--间隔4S，TTS循环播放“上海科技有限公司欢迎您123456上海科技有限公司欢迎您”，
--TTS播放过程中，手动拉高GPIO19，触发gpio19上升沿中断，
--调用audio.stop停止播放TTS，开始对讲测试，对讲测试结束，继续播放TTS
--]]

-- 流录音
function recordCb(result, size, tag)
    log.info("testRecord.rcdcb", result, size, tag)
    if tag == "STREAM" then
        local s = audiocore.streamrecordread(size)
        log.info("MICDATA", string.toHex(s)) ---打印录音数据流数据   
        audiocore.pocstreamplay(s) ---读录音数据流数据  
        ---全双工对讲流式播放音频数据  
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
    -- audiocore.pocstart(audiocore.AMR, 1) ----打开全双工对讲
    sys.wait(3000)
    function gpio19IntFnc(msg)
        log.info("testGpioSingle.gpio19IntFnc", msg, getGpio19Fnc())
        -- 上升沿中断
        if msg == cpu.INT_GPIO_POSEDGE then
            audio.stop(function() log.info("STOP") end)
        else
        end
    end

    -- GPIO19配置为中断，可通过getGpio19Fnc()获取输入电平，产生中断时，自动执行gpio19IntFnc函数
    getGpio19Fnc = pins.setup(pio.P0_19, gpio19IntFnc)

    audio.play(1, "TTS",
               "上海科技有限公司欢迎您123456上海科技有限公司欢迎您",
               1, function(result)
        log.info("TTS.AUDIO_PLAY_IND", result)

        if result == 5 then
            audiocore.pocstart(audiocore.AMR, 1) ----打开全双工对讲
            audio.setVolume(5) ---设置音量
            log.info("PocTest Start")
            recordBuf = ""
            audiocore.pocstreamrecord(10) -- 全双工对讲流录音接口，录音时长10S
            sys.wait(10000)
            audiocore.pocstop() ---全双工对讲停止录音

            audio.play(1, "TTS", "重新开始一次播放测试", 2, nil)
        elseif result == 0 then
            audio.play(1, "TTS", "上次TTS正常播放", 2, nil)
        else
            log.info("testTTS.fail", result)
        end
    end, true, 5000)

end)

