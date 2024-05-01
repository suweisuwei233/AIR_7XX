## LuatOS-SoC@EC618 V1106

1. 新增: mobile库添加网络特殊配置功能
2. 新增: 获取当前服务小区的cellid，不需要重新搜索
3. 新增: websocket库添加sent/disconnect事件
4. 新增: http支持fota
5. 新增: 腾讯云demo
6. 新增: fota.file(path)
7. 新增: 云编译支持设置lua内存到256k
8. 新增: mobile增加一个网络搜索中的常量mobile.SEARCH
9. 新增: mqtt库支持qos2的消息下发
10. 新增: mqtt增加verify参数，可选是否强制校验证书
11. 新增: luatos usb串口增加sent事件回调，但是仅代表数据写入底层缓存
12. 新增: 添加httpsrv
13. 新增: TF卡上电控制
14. 新增: 域名解析，socket.connect里remote_port设置成0则只进行DNS，不做连接，DNS完成后直接返回ON_LINE 
15. 优化: 优化云编译配置，增加uart0释放、字体等
16. 优化: 调整luat_uart_setup的缓冲区默认大小,设置最小值2k, 最大值8k,解决大数量场景下uart缓冲区不够的问题, 尤其是Air780EG的uart2
17. 优化: 增大UART的RX DMA缓存区数量，并可以随用户的RX缓存做调节
18. 优化: string.fromhex()过滤掉非法字符
19. 优化: 更均匀的使用socket id
20. 优化: lcd默认清屏为黑色更合理一些，主要作用避免初始化后显示时有花屏
21. 优化: gnss处理转到lua任务里
22. 优化: 在加载内置库和require前后执行gc,对内存消耗进行削峰
23. 优化: 允许cid1设置用户的apn，用于无法用公网APN激活的专网卡
24. 优化: lpuart异常处理
25. 优化: luatos开机打印完整硬件版本号
26. 优化: luatos uart rs485如果转换超时设置小于1ms会强制改成1ms
27. 优化: luat_websocket_ping先判断一下连接状态再发
28. 优化:优化luatos音量调节
29. 优化: 改进task的mailbox减少内存消耗
30. 优化: mp3解码器重新封装
31. 优化: 加快硬件协议的网卡本地端口的分配
32. 优化: 减少ftp的ram消耗
33. 修复: lwip小概率会对同一个tcp释放两次
34. 修复: luatos wdt重新初始化失效
35. 修复: 修复gc9306 90°方向设置错误
36. 修复: zbuff:unpack、pack.unpack添加lua虚拟栈检测
37. 修复: luatos 获取cellinfo有时候会失败
38. 修复: json库在浮点数0.0的时候会变成科学计数法
39. 修复: libgnss.clear()未能正确清除历史定位数据
40. 修复: I2C读写失败后，内部硬件状态机不能自动恢复
41. 修复: 修复i2c1默认引脚错误
42. 修复: 开启低功耗串口后，再关闭仍然会有中断，串口关闭会死机
43. 修复: uart0输出EPAT log时，如果rx上有杂波，可能会死机
44. 修复: http库的timeout_timer存在多次free的可能性
45. 修复: mqtt库设置will应允许payload为空
46. 修复: http Content-Length=0时异常问题
47. 修复: sntp_connect的判断不正确

## LuatOS-SoC@EC618 V1105

1. 新增: 添加软件DAC (PWM音频输出) **注意：现有版本开发板不支持此功能**

2. 修复: 回滚V1103升级到V1104的fskv库读写整型/浮点型数据的差异

   **此版本同样包含[V1104](https://gitee.com/openLuat/LuatOS/releases/tag/v0007.ec618.v1104)修改所有更新**

## LuatOS-SoC@EC618 V1104 (浏览版)

1. 新增: 新增gmssl库，支持国密sm2/sm3/sm4
2. 新增: 软件uart
3. 新增: 支持w5500,可以外挂以太网模块了
4. 新增: uart1在600,1200,2400,4800,9600波特率情况下，自动启用LPUART功能，休眠时，数据接收不丢失
5. 新增: luatos增加amr编码功能
6. 新增: 支持iconv库
7. 新增: sd/tf卡挂载 （spi接口）
8. 新增: luatos可以选择开启powerkey防抖
9. 新增: luatos增加cam_vcc控制
10. 新增: audio.config增加设置音频播放完毕后关闭pa和dac的时间间隔，消除可能存在的pop音
11. 新增: 添加基站+wifi定位demo lcsLoc.lua
12. 新增: mqtt添加断开事件
13. 新增: 如果未刷入脚本则进行打印提示
14. 新增: 添加fdb/fskv库的iter和next函数
15. 新增: 免boot下载脚本 (需要luatools 2.1.96及以上版本)
16. 优化: adc的id兼容一下老的10/11配置
17. 优化: 解除了用户log单次并发条数的限制
18. 优化: 优化usb串口输出
19. 优化: 优化RRC释放的时机
20. 优化: 动态ram分配优化
21. 优化: 将中断服务函数，高实时性函数和一些常用函数全部放到ram中,提升运行效率
22. 优化: uart rx在正常模式下用DMA接收，大幅度提升高波特率下大数据接收的稳定性
23. 优化: luatos的fota防御内存不足无法初始化的情况
24. 优化: 遇到伪基站时，快速切换到正常基站
25. 优化: SPI开启内部上下拉提高稳定性
26. 优化: http忽略自定义Content-Length
27. 优化: 网络遇到致命错误时可以自动重启协议栈来恢复，需要手动开启
28. 优化: 完善apn激活的操作
29. 优化: http库 url长度无限制
30. 优化: audio任务优先级提升，提高播放的稳定性
31. 修复: luatos socket dtls模式下死机问题
32. 修复: audio_play_stop判断不完整
33. 修复: 修复弱网环境下，dns查询接口阻塞无返回的问题
34. 修复: 修复luat_fs_fopen打开包含不存在目录的路径时会崩溃问题
35. 修复: tls握手完成后，如果一段时间无数据交互会超时
36. 修复: sntp自定义域名为3个时候处理异常
37. 修复: protobuf库无法正确解码64bit的数据
38. 修复: miniz库常量重复导致pairs时死循环
39. 修复: 深度休眠唤醒后无法识别模块类型

## LuatOS-SoC@EC618 V1103

**注意：因socket接口返回值与之前不兼容，特此版本号由v1002升至v1103以作提醒**

**此版本已完整支持Air780EG**

1. 新增: 支持ipv6，需调用mobile.ipv6开启，默认不开启，前提开卡时需要支持ipv6 （对此有什么应用场景的好点子可以和我们反馈呦）
2. 新增: 支持ftp
3. 新增: 支持fskv
4. 新增: libfota.lua封装库，fota更简单
5. 新增: mobile 添加IP_LOSE消息
6. 新增: mobile允许开机优先使用SIM0
7. 新增: lbsLoc.lua封装库，基站定位更简单
8. 新增: sms库支持清理长短信片段 sms.clearLong()
9. 新增: http添加超时参数
10. 新增: 添加rtc.timezone函数
11. 新增: 录音功能
12. 新增: sms库支持禁用长短信的自动合并
13. 新增: i2s回调和异步接收功能
14. 新增: 添加mlx90614驱动
15. 新增: 添加新的ram文件系统
16. 新增: pm.lastReson()更详细的开机原因可用
17. 新增: 支持gtfont
18. 新增: 支持用户自定义APN并激活使用
19. 优化: 485等待发送完成
20. 优化: USB虚拟串口单次发送长度不再限制512
21. 优化: SPI底层驱动优化，启用DMA
22. 优化: I2C底层驱动优化
23. 优化: UART底层驱动优化
24. 优化: 调整iotauth库的代码,使其不使用静态内存，调整默认时间戳，修正输出秘钥长度
25. 修改: GPIO14/15 映射到PAD 13/14的ALT 4, 从而避免与UART0冲突
26. 修改:socket接口规范返回值（与之前版本不兼容，重要！！！！！）
27. 修复: udp接收会有内存泄露
28. 修复: http库未支持自定义Host
29. 修复: sntp自定义地址table处理异常
30. 修复: fota只更新脚本且很小时候有概率失败
31. 修复: sms库在修正多条长短信合并时判断错误
32. 修复: sms库连续收到多条长短信,且顺序混乱时,短信内容合并错误 
33. 修复: 虚拟UART的rx回调
34. 修复: mqtt库在publish消息时,若qos=0,返回的pkgid不合理,应该固定为0
35. 修复: UDP接收数据不全
36. 修复: rtc库未正确实现
37. 修复: http chunk编码异常

## LuatOS-SoC@EC618 V1002

### 音频类, TTS播放

V1002已支持 TTS播放, 可配合音频扩展板和SPI Flash实现离线文本转语音

### SMS短信收发

V1002已支持SMS中英文短信收发, 支持长短信自动合并. 但值得提醒的是, 电信卡不可用

### ErrDump库,自动错误上报

新增的errDump库支持上报开机原因,报错原因,自定义日志,定时上报到指定服务器

### Air780EG的初步支持

V1002支持控制GPS芯片和GPS天线的供电,配合libgnss可完成一般的定位需求,对Air780EG完整支持将在V1003实现,敬请期待.

### 其他修改和bugfix

1. 新增: http/mqtt库的完整加密实现
2. 新增: sntp
3. 新增: iotauth库支持阿里云hmacsha256
4. 新增: 支持iot平台升级
5. 新增: gt911触摸屏驱动支持型号验证
6. 新增: mqtt库支持will消息,支持cleanSession可配置
7. 新增: hmeta库可读取模块类型,可区分Air780E和Air600E
8. 新增: http库支持断点续传和chunked编码
9. 新增: 设置RRC自动释放时间间隔
10. 新增: eink库支持异步,7寸屏幕刷屏不阻塞
11. 新增: sfud库挂载文件系统支持偏移量和大小设置
12. 新增: 基站定位库, lbsLoc
13. 新增: sim状态回调
14. 新增: gpio库新增消抖模式1
15. 新增: 支持多个虚拟GPIO,可读取pwrkey/vbus/wakeup的状态和中断信息
16. 新增: comdb.txt也塞进soc文件,方便调试
17. 修复: websocket无法自定义端口及存在内存泄漏
18. 修复: json.encode浮点数格式设置无效
19. 修复: u8g2库无法使用spi模式
20. 修复: pwm库无法动态调整占空比
21. 修复: 音量调整没起作用
22. 修复: rtc得到的星期不对
23. 示例: 基站定位的demo
24. 示例: tts的demo
25. 示例: 异步socket的demo
26. 文档: 新增库可用性标识,展示当前库已适配在何种模块上

## LuatOS-SoC@EC618 V1001

**初版发布~~~（喜大普奔）**

1. 已支持全部外设,包括uart/i2c/spi/adc/spi/pwm等
2. 网络功能可用，包括socket,http,mqtt,websocket等
3. mobile功能可用
4. 音频功能可用
5. UI库可用，包括u8g2/eink/lcd/lvgl等 （lvgl默认不编译，如需使用请自行编译）
6. fota功能可用（需配合2.1.82及以上版本的luatools 方可生成差分包，2.1.82版本稍后发布更新）
7. wifiscan功能可用
8. 短信功能暂不可用，预计下个版本支持
