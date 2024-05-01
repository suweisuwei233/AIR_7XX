--- 模块功能：ftp功能测试
-- @module ftp_test
-- @author Dozingfiretruck
-- @license MIT
-- @copyright OpenLuat.com
-- @release 2020.12.08
require "ftp"
module(..., package.seeall)

-- 挂载SD卡
-- io.mount(io.SDCARD)

function ftp_thread()
    local r, n = ftp.login("PASV", "36.7.87.100", 21, "user", "123456") -- 登录
    log.info("ftp_login", r, n)
    if r ~= "200" then return end

    r, n = ftp.command("SYST") -- 查看服务器信息
    log.info("ftp_command SYST", r, n)
    if r == "426" or r == "503" then return end

    r, n = ftp.list("/") -- 显示目录下文件
    log.info("ftp_list /", r, n)
    if r == "503" or r == "502" or r == "426" then return end

    r, n = ftp.list("/ftp_lib_test_down.txt") -- 显示文件详细信息
    log.info("ftp_list /ftp_lib_test_down.txt", r, n)
    if r == "503" or r == "502" or r == "426" then return end

    r, n = ftp.pwd() -- 显示工作目录
    log.info("ftp_pwd", r, n)
    if r == "426" or r == "503" then return end

    r, n = ftp.mkd("/ftp_test") -- 创建目录
    log.info("ftp_mkd", r, n)
    if r == "426" or r == "503" then return end

    r, n = ftp.cwd("/ftp_test") -- 切换目录
    log.info("ftp_cwd", r, n)
    if r == "426" or r == "503" then return end

    r, n = ftp.pwd() -- 显示工作目录
    log.info("ftp_pwd", r, n)
    if r == "426" or r == "503" then return end

    r, n = ftp.cdup() -- 返回上级工作目录
    log.info("ftp_cdup", r, n)
    if r == "426" or r == "503" then return end

    r, n = ftp.pwd() -- 显示工作目录
    log.info("ftp_pwd", r, n)
    if r == "426" or r == "503" then return end

    -- r, n = ftp.download("/1040K.jpg", "/sdcard0/1040K.jpg") -- 下载ftp服务器的文件至sd卡目录
    -- log.info("ftp_download", r, n)
    -- if r ~= "200" then return end
    -- r, n = ftp.upload("/ftp_lib_test_up.txt","/sdcard0/ftp_lib_test_up.txt") -- 从sd卡目录上传文件至服务器
    -- log.info("ftp_download", r, n)
    -- if r ~= "200" then
    --     return
    -- end
    ftp.close()
end

sys.taskInit(ftp_thread)

-- 卸载SD卡
-- io.unmount(io.SDCARD)
