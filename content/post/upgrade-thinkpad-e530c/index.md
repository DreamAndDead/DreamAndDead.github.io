---
title: thinkpad E530c 的升级之路
date: "2018-05-12T20:10:00Z"
categories:
- Hardware
tags:
- hardware
- thinkpad
featured_image: images/featured.jpg
aliases:
- /2018/05/12/upgrade-thinkpad-e530c.html
---

不知不觉，自己的[Thinkpad E530c][tp e530c config]入手5年，期间换过数次系统，如今不觉有些老态龙钟，
硬件资源已远远不足以支持日常使用的需求，速度慢多次卡顿，十分损伤工作效率。

决心升级一下跟随多年的“小黑”，焕发新颜。

<!--more-->

# 拆机

拆机之前，**一定要先取下电池！！！**，不然容易因为短路之类损伤内部元器件，
后果很严重。

拆机只需要一把小型的十字螺丝刀，和一字螺丝刀。

拆机只需要拆背面就可以，可以更换的主要零件都在这里，不必将电脑拆到芯片级别。

{{< figure src="images/tp-panel.jpg" caption="" >}}

- 从1,2,拆下电源
- 从5,6,7,松开螺丝，从8处撬开面板

{{< figure src="images/tp-panel-inside.jpg" caption="" >}}

主要零件分布
- A处风扇
- B处内存
- C处是CPU
- D处是硬盘
- E处是无线网卡
- F处是显卡

# 硬盘

一般硬盘IO速率，远远小于内存读写的速度，
提升硬盘IO速率，缩短与内存读写速率的差距，
对于性能提升，是非常明显的。
计划将原有的HDD，更换为SSD。

可以安装硬盘的有两个位置，一个是原先的硬盘位，另一个是光驱位。
一般来讲，硬盘位更稳定，速度更快，所以决定在更换HDD的时候，
将SSD安装在原有硬盘位，HDD放到光驱位，光驱将废弃不用。

{{< figure src="images/tp-panel-inside.jpg" caption="" >}}

- 从1,2,处，松开螺丝，向外取出硬盘

{{< figure src="images/tp-disk.jpg" caption="" >}}

一般硬盘的侧面与背面，都有4个螺丝孔（1,2是侧面，3,4是背面）。
在取下原有硬盘之后，将原来的硬盘支架取下来（从1,2螺丝及对面的两颗螺丝），
换上新硬盘，固定支架，再安装回硬盘位。

在更换之后，开机关机秒速，体验很赞。

# 光驱

根据平时的使用经验，光驱基本使用不到，决定将旧硬盘放置到光驱处。
有一种顾虑是，这样内部的散热会不好，因为SSD安装了系统，HDD用于附加存储，使用到的概率很小，平时使用应该不是问题。

{{< figure src="images/tp-panel.jpg" caption="" >}}

- 松开3处的螺丝
- 再从4处将光驱拔出来

因为光驱位的接口与硬盘位的接口不同，虽然都为SATA口，但是有一些区别，所以在将硬盘安装到光驱位
的时候，需要 光驱硬盘支架。

{{< figure src="images/tp-disk-cdrom-interface.jpg" caption="" >}}

光驱位接口

{{< figure src="images/tp-disk-interface.jpg" caption="" >}}

硬盘位接口

{{< figure src="images/tp-disk-cdrom.jpg" caption="" >}}

左边是原来的光驱，右边是光驱硬盘支架。
首先将硬盘安装到 光驱硬盘支架 上，记得将原有光驱位1处的螺丝与2处的外壳，换到新的 光驱硬盘支架 上。
将 光驱硬盘支架 装回原来的光驱位即可。

# 风扇

笔记本原来的风扇不转动，积灰严重，
可以在网上根据对应型号，购买一个新的。

新风扇运转流畅，声音小，散热变得更好。

{{< figure src="images/tp-panel-inside.jpg" caption="" >}}

- 将17处的插口拔下
- 从7,8,9处将螺丝松开，取下风扇
- 换上新风扇

# CPU

平时日常使用，开启Firefox，CPU都要跑满40%，开启关闭标签页时常卡住，
下一步决定主要更换的是CPU。

一般CPU型号，以M（Mobile）结束的，是可以更换的，以U结尾的是焊接在主板上的，不可更换。
E530c的CPU是i5-3210M，lucky。

CPU不是随意更换的，要根据主板型号与功耗，选择合适的。

- 从cpu-upgrade网站，根据主板型号，找到可以适配的所有CPU。E530c的主板型号是[HM77][HM77]，可升级的最高系列是i7-3840QM。
- 从功耗来讲，原来的CPU是35W，i7-3840QM是45W，功率相同是最好，如果强制为了高配置，而强制换上高功率CPU，可能会散热不足，损坏内部元件，所以一定要保持散热。

{{< figure src="images/tp-panel-inside.jpg" caption="" >}}

- CPU在散热片的下面，要先取下风扇，再取下散热片，其次才能取下CPU
- 取下风扇
- 松下10,11,12,13,14,15,16的螺丝，取下散热片

{{< figure src="images/tp-cpu.jpg" caption="" >}}

- 将1处的一字螺丝，逆时针180度，再取下CPU
- 更换新CPU
- 顺时针180紧上

对于更换CPU，还有重要的一点是，一手市面上只有针对PC的CPU售卖，
如果要买到笔记本CPU，只能通过非官方的途径，而这些途径得来的CPU并不能保证
其质量，其中关注最多的就是ES/QS版本的CPU。

简单的说，ES/QS是工程的测试版，没有足够的稳定性，理论上不应该流通在市面上。
具体可参考 [CPU ES版、QS版和正式版的区别][ES-QS]

因为是linux系统，没有cpuz这样的工具，cpu的信息中也看不出是否是正式版。
试用的几天，感觉速度还可以。如果有知道方法的人，感谢可以告诉我 :)

```
$ lscpu
Architecture:          x86_64
CPU 运行模式：    32-bit, 64-bit
Byte Order:            Little Endian
CPU(s):                8
On-line CPU(s) list:   0-7
每个核的线程数：2
每个座的核数：  4
Socket(s):             1
NUMA 节点：         1
厂商 ID：           GenuineIntel
CPU 系列：          6
型号：              58
Model name:            Intel(R) Core(TM) i7-3840QM CPU @ 2.80GHz
步进：              9
CPU MHz：             1200.732
CPU max MHz:           3800.0000
CPU min MHz:           1200.0000
BogoMIPS:              5587.10
虚拟化：           VT-x
L1d 缓存：          32K
L1i 缓存：          32K
L2 缓存：           256K
L3 缓存：           8192K
NUMA node0 CPU(s):     0-7
Flags:                 fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 cx16 xtpr pdcm pcid sse4_1 sse4_2 x2apic popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm epb tpr_shadow vnmi flexpriority ept vpid fsgsbase smep erms xsaveopt dtherm ida arat pln pts
```

# 内存

目前有两个插槽，最初是4G内存，后来加装了一条4G，共8G现在，
目前还够用。

听说这个型号有内存单条8G的限制，还没有验证过，如果是那样，最多升级到16G内存。

{{< figure src="images/tp-panel-inside.jpg" caption="" >}}

- 3,4,5,6是4个卡位，向外掰开，内存就会弹出
- 安装内存时，对准插槽，再按下即可


# 显示器

目前屏幕的分辨率为1366×768，本来想更换为1080P ips屏，
但是根据资料并联系商家，没有相应能适配的屏幕，有些可惜。

不过目前一直使用外接显示器，这一点也可以接受。


# 电池

使用电脑的时间这么多年，电池的续航能力也变差了。

直接在网上搜索对应型号，买原装的可以，简单有效。

[tp e530c config]: http://detail.zol.com.cn/361/360255/param.shtml
[HM77]: http://www.cpu-upgrade.com/mb-Intel_(chipsets)/HM77_Express.html
[ES-QS]: http://ask.zol.com.cn/q/23131.html
