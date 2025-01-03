# v1.0.7-2
### 功能性更新
##### 1.为面具用户主动为shamiko添加action.sh便于快捷使用

# v1.0.7
### 功能性更新
##### 1.为部分模块主动添加action.sh便于快捷使用
### 细节调整
##### 1.将MT管理器终端升级到3004
##### 2.更新附属模块1.0.3
### 问题修复
##### 1.并行处理app安装,未等待安装完成就退出模块安装

# v1.0.6
### 细节调整
##### 1.将app安装变为并行处理,优化安装器的安装速度
##### 2.回退lsposed到npm7075去日志特征版本暂时通过Native Test检查
##### 3.将jq和inotify的开源许可证添加到模块中
##### 4.升级zygisk next 1.2.4
##### 5.升级PlayIntegrityFix v18.0,并且模块移除提供keybox
##### 6.更新附属模块1.0.2

# v1.0.5
### 问题修复
##### 1.再次修复编码问题
##### 2.修复安装时获取当前运行包名的错误,和不兼容模块的判断
### 细节调整
##### 1.升级zygisk next 1.2.3
##### 2.升级PlayIntegrityFix v17.9,并且更换新的有效秘钥
##### 3.将arm64二进制文件jq的重新添加回来
##### 4.当hash获取成功时尝试立即重置
##### 5.重新开放多用户支持

# v1.0.4-2
### 问题修复
##### 1.修复错误的时间戳导致的模块解压失败等原因
### 细节调整
##### 1.升级zygisk next 1.2.2
##### 2.升级PlayIntegrityFix v17.8

# v1.0.4
### 功能性更新
##### 1.添加magisk的action.sh和kernelsu的webui支持
### 细节调整
##### 1.升级zygisk next 1.2.1.1
##### 2.升级lsposed 7119

# v1.0.3
### 功能性更新
##### 1.支持自动从秘钥认证获取avb验证哈希值并取回操作哈希值使avb验证通过
### 问题修复
##### 1.修复错误的app包名列表
##### 2.修复解压的乱码问题
##### 3.修复部分可能导致运行错误的其他书写

# v1.0.2
### 功能性更新
##### 1.制作了一个dex文件来获取过滤列表, 解决因为设备环境的原因无法生成
### 细节调整
##### 1.升级zygisk next到预览版3
##### 2.升级PlayIntegrityFix_v17.7
##### 3.更换lsposed为JingMatrix,以支持安卓15
##### 4.从源码构建新改包名版隐藏应用列表以升级到3.3版本支持安卓15
### 问题修复
##### 1.修复辅助模块如果上次没有成功释放.txt会导致永远无法通过安装模块的方式来修复的问题

# v1.0.1
### 功能性更新
##### 1.支持一键导入自己的隐藏应用列表配置
##### 2.开始尝试支持直接升级
### 细节调整
##### 1.升级zygisk next到预览版2
##### 2.升级爱玩机工具箱到22.0.9.4
##### 3.隐藏应用列表app迁移到附属模块
##### 4.开始默认开启白名单模式。不默认使用黑名单模式
### 问题修复
##### 1.修复自动旋转始终保持打开的问题
##### 2.优化了自动打开隐藏应用列表列表的次数，现在不会轻易打开app加载配置了

# v1.0
### 功能性更新
##### 1.正式支持自动更新隐藏应用列表(仅对模块自带的隐藏应用列表生效)
##### 2.添加中文文件名支持
### 细节调整
##### 1.同步脚本检测设备已启动的检测方法
### 问题修复
##### 1.修复附属模块的名称替换

# v0.2-3
### 细节调整
##### 1.设备启动后等待15秒更改为20秒后启动隐藏应用列表app,防止开启过早导致服务没有成功运行
##### 2.升级Tricky-Store到v1.2.0-RC2
### 问题修复
##### 1.修复打包错误的重启次数

# v0.2-2
### 问题修复
##### 1.修复写错的包名获取命令
##### 2.修复写错的模块状态描述替换命令

# v0.2
### 功能性更新
##### 1.增加对管理器类型的判断. 警告德尔塔用户不受支持
##### 2.上传配置流程图片到github&gitlab
##### 3.生成hma.json文件的脚本重构，完全使用jq生成，防止unix shell的不可预测行为并提升效率
### 细节调整
##### 1.将自动注入的lspd作用域配置文件更改为直接复制到lspd文件夹内
##### 2.更新mt管理器到v5完成版
##### 3.重新加回管理器内更新模块
##### 4.重新加回cherish_peekaboo_1.3.1_test.kpm, 因为收到反馈1.4.2设备兼容性被降低
##### 5.更新PlayIntegrityFix_v17.6
##### 6.更新keybox秘钥,因为原秘钥已被吊销
##### 7.模块描述更新了更清楚的描述
### 问题修复
##### 1.修复被遗漏的自动打开app
##### 2.修复因为版本号太长超出int限制导致的magisk模块不显示内容(更改时间戳格式为yyyyMMddHH格式)

# Demo_v0.1 Better_root_environment
## 将原 fast_config 正式更名为 Better_root_environment
### 功能性更新
##### 1.使用linux底层的inotify实现监听app列表,有新装app时自动更新秘钥注入和隐藏应用列表(仅支持arm处理器实时更新, x86仅支持开机更新)
### 细节调整
##### 1.升级PlayIntegrityFix到17.5
##### 2.升级Tricky-Store到v1.2.0-RC1
##### 3.有关模块配置的实时操作分离到 better_app_config 模块中
##### 4.不再优先尝试暂停selinux规则来绕过pm命令限制获取app列表,解决牛头人 异常10(绕过的免root方法来着5ec1cff@github)
##### 5.移除lsposed集成zloader的解决牛头人权限漏洞问题,并重新开放日志便于反馈
##### 6.更换原隐藏应用列表为自定义改包名版
##### 7.更新爱玩机工具箱到S22.0.9.3
##### 8.更换原piaopiao版mt管理器破解版为Modder Hub@Telegram的2024年9月16日版
### 问题修复
##### 1.修复默认开启shamiko白名单








# v3.2
### 功能性更新
##### 1.尝试安装安卓10-11的密钥注入
##### 2.添加一个自动生成密钥注入目标列表模块
##### 3.向下最低兼容到Android 8.1
### 细节调整
##### 1.安装前设置selinux为宽容模式防止apk安装失败
##### 2.升级PlayIntegrityFix到17.3
##### 3.移除重复的密钥配置,改用模块代替
##### 4.默认尝试开启shamiko白名单
##### 5.安卓10以上默认关闭safetynet-fix
##### 6.移除原版酷安,改用第三方酷安以便缩小模块体积
##### 7.由于用自制模块代替了原Mod版安卓12密钥注入的自动列表功能, 升级安卓12密钥注入到官方1.1.3
### 问题修复
##### 1.尝试修复自动配置的解压HMA失败演示配置文件的问题

# v3.1-2
### 功能性更新
##### 1. 添加MT终端apk
### 问题修复
##### 1. 修复严重安装脚本问题，当在Apatch和KernelSU中安装时不进行面具版本检测
# v3.1
### 功能性更新
##### 1.自动添加LSPosed的Xposed模块作用域
##### 2.自动配置Xposed模块隐藏应用列表
##### 3.自动判断面具Zygisk状态
### 细节调整
##### 1.安装前检查模块文件夹是否为空，不为空则提示用户环境不干净
##### 2.尽可能的支持更低的面具版本
##### 3.默认禁用zygisk-sui模块，防止牛头人26发现异常服务(4)
### 问题修复
##### 1.修复自动解压HMA失败演示配置文件的问题

# v3.0
##### 没有更新日志

# 为什么没有更早的更新日志?
##### 因为更早的版本都是我自身导致大量的bug, 未推送到github, 只是备份作用