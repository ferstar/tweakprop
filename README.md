# 免ROOT调整build.prop
---

> 这个工具的作用就是用来生成在`RECOVERY`环境下修改`/system/build.prop`的卡刷包, 所以手机`ROOT`与否都无所谓, 只要手机能刷第三方`RECOVERY`如`TWRP`或`CWM`就行, 理论上支持任意机型

在`tmp/tweak.prop`中按要求填入你需要修改或添加的变量, 规定如下:

1. 添加一个变量, 存在则修改, 不存在则新建

   比如直接填`ro.sf.lcd_density=240`就可以把`ro.sf.lcd_density`值修改为`240`

2. 删除一个变量, 在要删除的条目前加`!`即可

   如`!debug.egl`表示将任意包含`debug.egl`的变量删除

3. 变量追加值

   如`@mobiledata.interfaces|,ppp0`表示在`mobiledata.interfaces`后追加`,ppp0`字段

4. 修改变量值

   如`$telephony.lteOnCdmaDevice|1`表示将`telephony.lteOnCdmaDevice`值修改为`1`


举个实例, 魔趣早期的红米4高配ROM相机录像有问题, 我需要对`tmp/tweak.prop`做如下修改

```shell
# Disable HAL3
persist.camera.HAL3.enabled=0
# force HAL1 for below packages(add snap camera)
@camera.hal1.packagelist|,org.cyanogenmod.snap
```

修改完成后, 

- 如果是macOS/Linux系统, 在当前目录运行`./zipit`, 将生成的`tweakprop*.zip`压缩包放进手机内置卡, 进入第三方REC开刷
- 如果是Windows系统, 下载[tweakprop-0.6.0.zip](https://github.com/ferstar/tweakprop/raw/mkn-mr1/tweakprop-0.6.0.zip), 直接用`notepad++`编辑压缩包中的`tmp/tweak.prop`文件, 修改完成后原样塞回`tweakprop-0.6.0.zip`即可, 将压缩包放进手机内置卡, 进入第三方REC开刷

此卡刷包首先会检测内置卡上有无`build.prop.origin`备份文件, 如果有则用此备份文件覆盖到`/system/build.prop`, 此时可以正常刷魔趣OTA更新包; 如果没有, 则备份一份`build.prop`到内置卡, 然后根据`tweak.prop`文件中你希望的改动去修改`/system/build.prop`文件

简单说, 刷一次是修改, 影响OTA, 刷两次是还原, 不影响OTA, 刷三次又是修改, 影响OTA, 刷四次又是还原, 不影响OTA... 以此类推~

**注意不要删除内置卡上的`build.prop.origin`文件**

recovery日志:
```shell
Copying script and personal file...
minzip: Extracted file "/tmp/tweak.prop"
minzip: Extracted file "/tmp/tweakprop.sh"
...Files copied.
Setting permissions and executing script...
.../tmp/tweakprop.sh made rwxr-xr-x.
about to run program [/tmp/tweakprop.sh]
##############################
#       tweakprop 0.6.0      #
#         --by kl3--         #
#   --modified by ferstar--  #
##############################
Mount /system partition...
/system mounted rw
Mount /data partition...
/data remounted rw
Copy /system/build.prop to /sdcard/build.prop.origin...
Don't modify or delete it
Set write permissions for /system/build.prop...
../tmp/tweak.prop found and not empty
scanning /tmp/tweak.prop...
..entry "persist.camera.HAL3.enabled=0" added
..",org.cyanogenmod.snap" appended to value of "camera.hal1.packagelist"
Tweaks successfully applied!
..original permissions for /system/build.prop restored
../system unmounted
../data unmounted Script finished!
.../tmp/tweakprop.sh executed.
Deleting files...

##############################
#       tweakprop 0.6.0      #
#         --by kl3--         #
#   --modified by ferstar--  #
##############################
Mount /system partition...
/system mounted rw
Mount /data partition...
/data remounted rw
build.prop restored, you can use OTA properly.
.../tmp/tweakprop.sh executed.
Deleting files...
```
---


[原README文件](https://github.com/ferstar/tweakprop/blob/master/README.md)
