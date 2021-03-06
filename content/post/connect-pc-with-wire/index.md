---
title: connect two pc with a wire
date: "2020-04-10T18:20:00Z"
categories:
- Network
tags: 
- network
- lan
featured_image: images/featured.jpg
aliases:
- /2020/04/10/connect-pc-with-wire.html
---

先前[组装了一台用于深度学习的服务器][compose]，连接在一个局域网内使用。
通过 ssh 远程连接，tmux 终端复用，nfs 挂载编辑代码，vnc 远程桌面，一切运行的都很流畅。

不过最不适的在于，速度太慢了，一时想将开发机中 10G 的数据集传递到服务器，scp rsync nfs 都没有速度。
尤其经常在 nfs 挂载目录查看图片文件，文件数量繁多，预览等待的时间很长，完全没有操作本地文件相似的体验。

为了提高连接速度，计划直接用网线将两者互连。

<!--more-->

# 现状

最简单地抽象内部的网络状况，如下图。

{{< figure src="images/origin.png" >}}

主要涉及两台机器，一台开发机和一台服务器，都运行 Linux 系统。

开发机有一个无线网卡和一个有线接口，服务器只有一个有线接口。
开发机通过无线网卡接入内网，服务器通过有线连接接入内网。

开发机 ip 为 `10.27.3.9/23`，服务器 ip 为 `10.27.2.145/23`，内部网关 ip 为 `10.27.2.1`。

在当前情况下，开发机和服务器网络互通，也可以连通内部网络的其它机器，且都可以连接外网。
连接环境其实很理想，唯一缺点在于连接速度。

# 互连

## 网线

根据先前对网络的了解，同等设备间连接需要使用交叉线，比如 pc 连 pc，交换机连交换机。
但是也有一种说法，当前新的网卡都可以自适应的进行调整，直接使用相同的线序也是可以的（未验证）。
保险起见，还是使用了交叉线的方法，一端使用 568A，一端使用 568B，制作了一根 6 类线。

{{< figure src="images/wire.png" title="交叉线线序" >}}

## 拓扑

由于服务器只有一个有线接口，在将服务器与开发机互连之后，服务器无法像之前一样接入内网。

网络拓扑变化为

{{< figure src="images/new.png" >}}

更改连接后，开发机的网络连接状况没有大的变化，但对于服务器来说，如果想要如期的访问内部网络和外网，就必须通过开发机的转发。

## 网络层地址

原先的内网使用了网段 `10.27.2.0/23`，那目前两个 pc 互连就使用经典网段 `192.168.0.0` 吧。

{{< figure src="images/after.png" >}}

开发机设置

```
ip      192.168.0.1
mask    255.255.254.0
gateway 192.168.0.1
```

服务器设置

```
ip      192.168.0.2
mask    255.255.254.0
gateway 192.168.0.1
```

两者就使用了同样的网段，且开发机作为这个网络的网关。

设置地址之后，用 ping 来检测网络连通性。

在开发机上

```
$ ping 192.168.0.1  # 连通自身
$ ping 192.168.0.2  # 连通服务器
```

在服务器上

```
$ ping 192.168.0.2  # 连通自身
$ ping 192.168.0.1  # 连通开发机
```

网络连通，没有出现问题。

## 包转发

在连通两者的同时，服务器想要连接外部网络（用于安装软件，更新系统），就需要开发机负责转发来自服务器的包。

开发机有两块网卡，要保证网络包在两者之间的转发，需要启用 [ip forward][forward]。

```
$ sudo sysctl net.ipv4.ip_forward=1
```

这时服务器就可以连通开发机的另一个网卡的地址。

```
$ ping 10.27.3.9
```

## NAT

成功设置了包转发之后，服务器虽然可以连通开发机的另一块网卡，但是却连不通相应网络的网关。

```
$ ping 10.27.2.1  # 无法连通
```

[为什么会这样？][connect]

考虑服务器发出去的包，源地址是 `192.168.0.2`，通过有线网络进入开发机，通过无线网卡转发到另一个内网。
当网关 `10.27.2.1` 收到这个包并做出响应，返回包的目的地址是收到包的源地址 `192.168.0.2`。
对于网关来说，它并不属于 `10.27.2.0` 这个网络，需要进一步查找自己的路由表进行发送选择（大概率会被丢弃），
这样返回的包就不能回到内网 `10.27.2.0`，从而也不能返回到开发机，服务器就更不用说了。

我们需要的是，当包在通过无线网卡转发出去的时候，将包的源地址 `192.168.0.2` 修改为开发机的地址 `10.27.3.9`，
这样网关就会将这个包正确返回回来，在开发机内部，将返回包的目的地址重新替换为 `192.168.0.2`，这样服务器就与外部连通了。

设置 [iptables][iptables] 的 nat 表（wlp3s0 是无线网卡）就可以达到这样的效果。

```
$ sudo iptables -P FORWARD ACCEPT
$ sudo iptables -t nat -A POSTROUTING -o wlp3s0 -j MASQUERADE
```

## route

检查开发机的路由表

```
$ route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         10.27.2.1       0.0.0.0         UG    600    0        0 wlp3s0
0.0.0.0         192.168.0.1     0.0.0.0         UG    3600   0        0 enp2s0
10.27.2.0       0.0.0.0         255.255.254.0   U     600    0        0 wlp3s0
192.168.0.0     0.0.0.0         255.255.254.0   U     100    0        0 enp2s0
```

出现了新的默认网关 `192.168.0.1`，这明显是没有必要的，因为那边只有一台机器，不会有什么包需要到那里去。

可以选择将这条记录删除，避免出现无意义的转发

```
$ sudo route del default gw 192.168.0.1 dev enp2s0
```

# end

通过上面的设置，既连通了两台 pc，又没有阻碍彼此对外网的访问。
且 6 类线直接连通两块千兆网卡，文件操作瞬间变顺畅了。


[compose]: /2020/03/25/compose-deep-learning-machine.html
[forward]: https://linuxhint.com/enable_ip_forwarding_ipv4_debian_linux/
[connect]: https://blog.csdn.net/tiger_he/article/details/80805075
[iptables]: https://wiki.archlinux.org/index.php/Iptables_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)
