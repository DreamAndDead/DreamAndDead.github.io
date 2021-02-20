---
title: Deal with time in programming
date: "2018-05-22T08:08:00Z"
categories:
- Programing
tags:
- programing
- time
- linux
featured_image: images/featured.jpg
aliases:
- /2018/05/22/time-in-programming.html
---

时间无处不在，在编程中也是如此。
比如程序日志，每一行必定包含时间。
通常不会对时间特别关注，除非日志时间不对，或者编程使用时间，取不到正确结果。

其实在编程中只需明确几个简单的概念，就可以正确的使用时间。

<!--more-->

# UNIX Epoch time

> UNIX Epoch time是从1970年1月1日（UTC）到目前经过的秒数

从某种意义上讲，这个时间是“绝对的”，无论在地球上哪个国家，大家的 UNIX Epoch time 是一样的。

它的值确定唯一，这个时间也在程序中广泛使用，比如用作机器间时间同步的 ntp 协议，同步的就是这个时间。
如果每一台机器上的 UNIX Epoch time 都相同，就是保持了时钟的一致。

在 linux 上，可以通过 `date` ，来查看时间

```
####### %s means seconds since 1970-01-01 00:00:00 UTC
####### %N means nanoseconds (000000000..999999999)
$ date +"%s.%N"
1526949060.804222827
```


# Timezone

{{< figure src="images/timezone-map.png" caption="时区图" >}}

在同一时刻，经度距离较远不同地区，时钟的值是不一样的。比如北京时间的晚上8点，同时是纽约时间的早上7点。
那么 UNIX Epoch time 是如何确保不同地区的时间是一致的呢？

原因在于时区，UNIX Epoch time 强制使用 UTC+0 时区的时间，而本地时间则使用各地区时区的时间。

究竟什么是[时区][timezone intro]？

> 时区是一个地区，在这个区域内，大家使用同样的标准时间

一个时区内的当地时间，用与世界标准时间 (UTC) 之间的偏移量来定义。这个偏移量可以表示为 UTC- 或 UTC+，后面接上偏移的小时数和分钟数。
因此时区这个名词常常被用来表示当地时间。比如国内大部分区域使用的就是 UTC+8 时间，在UTC时间的基础上，加8个小时，代表当地时间。

为什么全球不使用一个时间，方便统一？

其实时区的出现就是为了方便不同地区的人对时间概念认知。日出而作，日落而息是所有地区人们的生活习惯，很多地区根据当地的日出日落来设定时钟的时间。
而且你肯定不希望，原来你在家里早上8点起床，出差到另外一个地区之后，要变成晚上2点起床。毕竟晚上2点见到太阳
听起来并不怎么有趣。

[时区发展的历史][timezone history]有点复杂，很多细节，但是正因它的出现，
解决了各地地理差异而带来的时差问题，同时也让各地区的当地时间尽量贴合本地的太阳时间。


## Abbr

用 UTC+8 这样的符号称谓当地时间毕竟不便，大部分地区都为各自地区的时区时间
起一个名称，代表自己的本地时间。
比如国内将本地时间称为China Standard Time，时区简称CST。

按照这样的规律（人们的心理），同一时区会有很多个不同的时区简称，有时还会有重复冲突。
举例来说，在迈阿密，标准时间是 UTC-5，称作东部标准时间 (EST, Eastern Standard Time)。而在古巴的哈瓦那，同样的 UTC-5 标准时间，就被称为古巴标准时间 (CST, Cuba Standard Time)，而CST和国内的时区简称还是重复的！

通常一个地区只关注自己的时间，不加时区简称，但是在世界范围内，如果有相应的重复冲突还是要额外注明。

通常遇到最多的简称如，UTC，GMT，CST。
- UTC 代表[世界标准时间][about utc]，Coordinated Universal Time
- GMT，时区简称，Greenwich Mean Time，UTC+0
- CST，时区简称（有重复冲突），China Standard Time，UTC+8

这里有 [时区简称的列表][timezone list] 和 [时区地图][timezone map]，详细直观，值得一看。

## In linux

- 系统当前时区可以用 `date` 查看
- 时区地区由 `/etc/timezone` 保存

```
$ date +"%Z %z"
CST +0800
$ cat /etc/timezone
Asia/Shanghai
```

- 默认 `date` 使用本地时区呈现时间
- 加上 `-u`，使用 UTC 呈现时间

```
$ date
2018年 04月 12日 星期四 16:03:16 CST
$ date -u
2018年 04月 12日 星期四 08:03:19 UTC
```


保证系统的时区正确是很重要的！这个时区作为所有系统运行程序的默认时区，
如果这个时区不准确，在程序中就取不到准确的本地时间，程序的日志时间自然也有所偏差。

在多数 linux 发行版中，可以通过修改 `/etc/localtime` 软链接来设置时区。

```
$ sudo ln -sf /usr/share/zoneinfo/Africa/Nairobi /etc/localtime
```

相比之下，使用 `timedatectl` 比较稳妥。

```
$ timedatectl status
      Local time: 一 2018-05-21 09:01:08 CST
  Universal time: 一 2018-05-21 01:01:08 UTC
        RTC time: 一 2018-05-21 01:01:08
       Time zone: Asia/Shanghai (CST, +0800)
 Network time on: yes
NTP synchronized: yes
 RTC in local TZ: no
$ timedatectl set-timezone Asia/Hong_Kong
$ timedatectl status
      Local time: 一 2018-05-21 09:01:47 HKT
  Universal time: 一 2018-05-21 01:01:47 UTC
        RTC time: 一 2018-05-21 01:01:47
       Time zone: Asia/Hong_Kong (HKT, +0800)
 Network time on: yes
NTP synchronized: yes
 RTC in local TZ: no
```

参考： [如何设置linux timezone][linux timezone]


# End

这里没有具体针对特定编程语言来说明时间，时区的用法，不过本质是不变的。
相信找到相应接口所针对的时间，可以很快掌握使用。

[about utc]: http://www.timeofdate.com/articles/posts/about-utc.html
[timezone intro]: http://www.timeofdate.com/articles/posts/timezone-introduction.html
[timezone history]: http://www.timeofdate.com/articles/posts/timezone-history.html
[timezone list]: https://www.timeanddate.com/time/zones/
[timezone map]: https://www.timeanddate.com/time/map/
[linux timezone]: https://www.tecmint.com/check-linux-timezone/
