---
date: "2018-05-17T00:00:00Z"
tags: X ssh
title: SSH X11 Forward
---

一般情况下，操作远程电脑，ssh+console足矣。突然有一天，隔壁项目组
想要检测下，从香港服务器浏览他们的网页，效果是怎么样的。
背景漆黑语法高亮的控制台好像帮不了忙...

诚然，vnc是一个易用可行的方案，但是这里想探索一下，X Window System本身对远程应用的支持。

<!--more-->

# X Window System

进入主题之前，先简要了解一下X的设计理念。

## C/S architecture

对于linux操作系统来说，GUI只是子系统，像console一样，提供另外一种用户接口。
没有它，核心系统依然正常运转，对于windows用户，这是难以想像的。

X（X Window System）就是这样一种GUI子系统设计，我们在系统中运行的程序Xorg，是对于设计的一种实现。

X最突出的特点是，C/S结构。实际运行的GUI程序是Client，连接X Server，与X Server相通信，进行GUI交互操作。

初听起来有些不可思议，本质上，X Server负责控制鼠标，键盘，屏幕等GUI相关的资源，根据Client的要求，对资源进行
不同的操作。
从某种角度来看，Client与Server通信的内容很像是“从这里到这里绘制一条线” “用这个字体绘制一些文字在这里” 这样的命令，而
Server端绘制屏幕，处理用户交互，读取鼠标键盘事件，告知Client，Client做出相应的反应，再告知Server进行新的绘制。

这样的设计非常灵活

- Client只需要关心与服务器通信的内容，不必关心显卡之类实际的细节
- C/S不必在同一台机器上，通过网络通信，远程运行GUI程序（本文关注的重点）

## Window manager

使用过GUI的人，都熟悉窗口(window)的概念，对窗口进行最大化，最小化，移动，变换大小等操作也不陌生。
从本质上来讲，窗口不是X Server直接处理的内容。什么意思呢？

X有一条核心的设计原则

> provide mechanism, not policy.
>
> from X11 protocol

从底层来讲，X完全支持你可以设计任何功能（mechanism），但并不强制你用窗口的方式呈现（policy），或许你也有别的方式。
所以说，窗口也只是一种被大家所熟悉的设计方式。

其实在X中，窗口的功能，是通过一个GUI Client来实现的，管理其它的Client App，一般称其为Window manager。

在X的设计中，并不包含Window manager。
也因为如此，市面上存在很多Window manager，比如目前kde plasma 5中，kwin作为Window manager。
每个Window manager都对窗口样式，操作方式有独特的理解，用户可以凭借喜好来选择不同的Window manager。

## Widget library

对于开发者，如果直接写一个GUI App，不会直接从与X交互的通信内容开始。如果那样做，即使绘制一个按钮，过程也是异常复杂的。
通常情况下，使用其它程序库提供的功能，来完成构建GUI App的工作。

程序库提供了封装，提供通用的Widget单元供开发者调用，这类程序库称之为Widget library or Toolkit。
使用Widget library，只需要调用函数，传递一些参数，就可以得到一个控件，如目录，按钮，滚动条，十分方便程序设计。

正因如此，Widget library本身的设计，很大程度决定了用户如何使用GUI程序，每个Library的设计也有自己的喜好。
同Window manager一样，Widget library也有很多实现，如著名的Gtk, Qt。

## Mess

每个Window manager都有自己管理Client的方式，样式与交互有所差别。
同样的，并没有什么规则，强制开发者一定要用使用什么Toolkit来编写程序，
每个Client使用的Toolkit也有所不同，App表现也不同。

程序丰富多样的同时，也是一种混乱。这种混乱有很多坏处，比如
- 用户使用体验不一致
- 同时加载很多不同Toolkit编写的程序，会加载不同的Toolkit library到内存，占用内存空间

## Desktop Environment

桌面环境（Desktop Environment）的出现，旨在提供统一的设计原则，对相关差异的地方达成共识，
使用统一的方式来设计程序。著名的DE有Gnome，KDE，XFce等。

比如KDE，用Qt Toolkit编写，包含Window manager以及其它控制面板，文件管理器等常用功能，用户体验和谐统一。


由于不同DE使用的底层Toolkit不同，偏向使用相同Toolkit编写的App，
比如

| KDE     | Gnome    | 功能       |
|---------|----------|------------|
| kular   | evince   | pdf阅读器  |
| dolphin | nautilus | 文件管理器 |
| ......  | .......  | .......    |

目前来说，运行与当前DE不同Toolkit编写的App，也没有什么主要问题。
我目前在KDE使用GIMP就很舒服，而且GIMP这么大型的程序，不容易用两种Toolkit写两份。

如果X提供了policy，就不会有这么多的混乱，但是也会少了相应的多样性。有舍有得。


# Remote connection

根据X设计，Server/Client是可以相分离，通过网络进行连接。

假如机器A，B都运行了X Window System，各自的App都以localhost为X Server地址，
两者分别在各自机器运行程序。

{% include image.html url="x-remote-connection-a2a-b2b.png" desc="C/S 本地连接" %}

在机器A，如果App使用B机器的X Server作为X Server地址，
则程序在B机器上运行并显示，由B用户操作。

{% include image.html url="x-remote-connection-a2b.png" desc="C/S 远程连接" %}

## Test environment

局域网有两台机器，运行mint与ubuntu

- 两台机器都安装有X
- ubuntu运行ssh server，mint通过ssh client与之连接
- 网络地址如图示

{% include image.html url="x-remote-connection-mint-ubuntu.png" desc="内部测试环境" %}

测试要达到的目标是，将ubuntu上的GUI App，远程运行在mint系统上。

## A little theory

实际操作之前，先消化一些理论 :)

### DISPLAY

在X Window System中，存在一个关键概念叫做display。
display包含键盘，鼠标，屏幕（screen），由X Server来管理。

GUI App运行启动，默认选择的display地址存储于DISPLAY变量中。

变量的格式是

- hostname:D.S，X Server通过Tcp端口6000+D来监听服务（D是变量）
- host/unix:D.S，X Server通过本机的UNIX socket来监听服务，一般位于/tmp/.X11-unix/XD（D是变量）
- :D.S，等同于host/unix:D.S

其中
- hostname，主机名，指定主机的地址，也可以为IP
- D，display编号，数字格式
- S，屏幕编号，一个display可管理多个屏幕，默认为0可不写

一些例子像这样
- DISPLAY=light.uni.verse:0
- DISPLAY=localhost:4
- DISPLAY=:0


除了通过 DISPLAY 变量选择 X Server 地址，部分GUI程序提供 -display 参数，用来指定display地址。
推荐使用 DISPLAY 变量的形式，兼容性更高，比如firefox就没有 -display 选项。

```
$ DISPLAY=10.27.3.9:0 firefox
```

### Connect server

X Server 可以接受来自任何地方的连接，但是你绝不会想使一个陌生人随意连接，
窃取到你鼠标的移动，键入的内容，毕竟mouse，keyboard也是display的一部分。

为了安全起见，部分发行版在启动X Server的时候，没有对外开启 X Server 服务，关闭了相应tcp端口，只使用本地unix socket的方式。
如果需要远程，还是需要打开tcp port，修改文件 /etc/X11/xinit/xserverrc，删除`-nolisten tcp`参数

对于本机 mint 使用 sddm 作为 display manager，需要同时修改/etc/sddm.conf，参考[arch wiki][sddm config x]

```
[XDisplay]
# X server arguments
ServerArguments=-listen tcp
```

重启之后，就可以发现相应的端口已经打开

```
$ sudo netstat -plunt
......
tcp        0      0 0.0.0.0:6000            0.0.0.0:*               LISTEN      1613/Xorg
......
```

针对安全方面，X Server提供两种访问控制，xhost与xauth，从不同的角度来理解安全问题。

#### xhost

xhost的机制非常简单，X Server内部维护一个列表，允许列表内相应的host可以连接X Server，
禁止不在列表内的host连接。

xhost使用相当简单
- xhost，直接列出目前host规则
- xhost +，允许任何host连接
- xhost -，禁止所有host连接
- xhost + host，将一个host添加入允许列表
- xhost - host，相反

```
$ xhost -help
usage: xhost [[+-]hostname ...]
$ xhost
access control enabled, only authorized clients can connect
SI:localuser:zdw
$ xhost +
access control disabled, clients can connect from any host
$ xhost -
access control enabled, only authorized clients can connect
$ xhost + 10.27.2.13
10.27.2.13 being added to access control list
```

xhost在安全方面进行了一定的控制，但是是从主机的粒度，没有区分用户。
所允许的host上，任何用户都可以连接访问X Server。

#### xauth

xauth从另一个角度入手，密钥。只有Client的密钥与X Server的密钥相匹配，才允许连接。

密钥一般称之为magic cookie，常见的模式是MIT-MAGIC-COOKIE-1。
cookie一般存储于 ~/.Xauthority, 只有用户本身有权限读写。

xauth 的主要功能就是管理这些 cookie。一般来说，开机，X Server启动，通过`-auth`加载cookie文件，
通过查看进程，就可以清楚的看到。

sddm加载的文件是 ~/.Xauthority，并将其复制到 /var/run/sddm的临时目录下使用。

```
$ sudo ps aux | grep Xorg
root      1775  2.4  1.2 214440 97896 tty7     Ss+  09:12   0:36 /usr/lib/xorg/Xorg -listen tcp -auth /var/run/sddm/{8c4953d4-ef44-4059-895b-1a9a10b4c5dd} -background none -noreset -displayfd 18 vt7
$ sudo cat /var/run/sddm/\{8c4953d4-ef44-4059-895b-1a9a10b4c5dd\} 
zdw-mint0MIT-MAGIC-COOKIE-1�J��~� Z�أ�����
$ cat .Xauthority 
zdw-mint0MIT-MAGIC-COOKIE-1�J��~� Z�أ�����
```

我在实际的测试过程中，在mint端xhost允许所有host连接，xauth暂时没有做配置，
**但是**ubuntu居然已经可以通过设置DISPLAY的方式，来连接X Server了。

查看两者的.Xauthority，没有相应的 key 对应，却可以连接。

```
######## mint
$ xauth list
zdw-mint/unix:0  MIT-MAGIC-COOKIE-1  9a4ab5c37eb0205a93d8a386fb8bdccc

######## ubuntu
$ xauth list
lzq/unix:0  MIT-MAGIC-COOKIE-1  f13dcc46e1320b3d156abf22fe53dd7e
$ xauth add 10.27.3.9:0 . 9a4ab5c37eb0205a93d8a386fb8bdccc

$ xauth list
lzq/unix:0  MIT-MAGIC-COOKIE-1  cbdfd1f2858f6e933da074f3d299c7f4
zdw.npl.lan:0  MIT-MAGIC-COOKIE-1  9a4ab5c37eb0205a93d8a386fb8bdccc

$ DISPLAY=10.27.3.9:0 xterm
```

文档有提到，较新版本的X Server有随时生成cookie的功能，Server生成cookie，并传递给来连接的Client，
达到认证的目的。
但是如果这样，不是失去了xauth本身的目的吗？具体还没有深入考究，TODO。

上面的示例只是启动了 xterm 程序，流量消耗很小，但是一启动使用firefox，网络带宽达到了10M/s！

{% include image.html url="x11-remote-firefox-network-load.png" desc="x11 remote firefox 带宽情况" %}

xauth从密钥的角度入手，如果要保证安全性，重点在于，如何安全的传递X Server cookie的值到相应的Client。
使用telnet, rlogin都是不安全的做法，推荐使用ssh加密传输，安全易行。

经常只用ssh来传递设置cookie未免过于烦琐，好消息是ssh自身对这种需求有了很好的支持，也到了本文的重点。

# SSH X11 Forward

xhost认证，控制粒度大；xauth认证烦琐，涉及cookie的传输与设置。
实际在部署中，往往涉及防火墙的相关设置。
更重要的是，X Remote App本身的流量是未加密的，有很大的被监听的风险。

ssh提供了一种安全方便的方式，就是X11 Forward，来解决上述问题。

## Quick start

先来快速体验一下 X11 Forward。
在ssh server端，文件/etc/ssh/sshd_config中，配置

```
X11Forwarding yes
X11DisplayOffset 10
```

在ssh client端，可以在连接时加上`-X`选项，或者在~/.ssh/config中，对Host加上配置

```
Host 10.27.2.13
    ForwardX11 yes
```

在我们的示例中，mint作为ssh client，ubuntu作为ssh server，配置了相应选项之后，
ssh连接，在ssh console session中运行

```
$ xterm
```

xterm就出现在mint主机，不需要任何多余的设置，ssh全部帮我们做好，amazing～

## What ssh does

在上面简单的设置中，就实现了X Remote App的功能，不禁觉得神奇，ssh到底做了什么？

其实X机制本身是不变的，像上面讨论的一样，只是ssh帮我们做了相关连接所需要的设置。
在上面的示例中，mint通过ssh连接ubuntu，
这里查看 DISPLAY，端口

```
$ echo $DISPLAY 
localhost:10.0
$ sudo netstat -plunt
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 127.0.0.1:6010          0.0.0.0:*               LISTEN      20093/8         
```

DISPLAY的值是 localhost:10.0 ，根据前面章节对 DISPLAY 值的分析， D=10，
所以在本地监听的端口是 6000+10=6010。

为什么会是10呢？这就和上面 sshd_config 设置有关。

```
X11DisplayOffset 10
```

意思是ssh从D=10开始定义新的 DISPLAY，避免与本机上的原有的 DISPLAY 定义相冲突。

这次连接的示意图如下

{% include image.html url="ssh-x11-forward.png" desc="ssh x11 forward 图示， thanks oreilly" %}

ssh client请求X forward，如果sshd允许，则在本机开启 X proxy server，并且设置了 DISPLAY 变量为 X proxy server，
代理所有X流量，通过ssh，传递到client端的6000（没有开启tcp端口也可以，待测试）

## SSH auth spoof

ssh通过流量转发，使得 X Client 可以远程连接 X Server，但是还没有讲清楚的是认证的问题，
ssh X11 forward是如何处理安全认证的。

先从xhost来说，X11 Forward完全绕过xhost的控制，因为X11 Forward本质是通过流量代理转发。
也就是说，如果在mint主机上，禁止所有host连接自身的X，ubuntu主机依然可以通过X11 Forward，
在mint主机上远程运行App。


其次就是xauth，
先来看连接ssh之后，两台主机的cookie list。

```
###### ubuntu
$ xauth list
lzq/unix:10  MIT-MAGIC-COOKIE-1  0377b5696a856c06f76fd20dc3ed837f
###### mint
$ xauth list
zdw-mint/unix:0  MIT-MAGIC-COOKIE-1  26a01cda76d69ab6a1f39b90a2fbc48b
```

只有本地的条目，而且两者完全不同，难道ssh也绕过了xauth机制？
其实ssh通过一种聪明的方式来传递auth cookie，称为authentication spoofing。

{% include image.html url="ssh-auth-spoof.gif" desc="ssh如何处理auth认证， thanks oreilly" %}

其中的关键就在于，有两个不同的cookie。

X Server本身的cookie这里称为 real display key，其中ssh client
会生成一个同样格式的cookie，称为 fake display key。

1. X Server real display key
2. ssh client 加载 real display key
3. 随机生成一个相同长度的 fake display key
4. 将 fake display key 和其类型发送到 ssh server, 通过 xauth 建立 X proxy server 与 fake display key 的关联
5. X client 开始与 X Proxy Server 通信，读取对应的 fake display key
6. X proxy server通过ssh，传输X流量，第一个包有特殊处理
7. X 流量转发到 ssh client
8. ssh client读取第一个数据包中的 fake display key，与 real display key 相对比
9. 如果不匹配，则连接失败；如果匹配，将包中的Key替换为 real display key
10. 流量传递给 X server，X Server从中读取到key（没有意识到有swap key的过程）
11. （xauth过程）如果不匹配，则连接失败；如果与real display key匹配，则认证成功，连接建立

这样的过程看似复杂，其实很巧妙

- 不使用xhost这样不安全的方式
- 安全的传递cookie
- 全部X流量加密
- 如果ssh server不可信，过程中也没有暴露真实的cookie

What a clever way!


# End

Thanks figures from [oreilly][oreilly ssh x forward]


[X arch]: http://tldp.org/HOWTO/XWindow-Overview-HOWTO/index.html
[Remote X Apps]: http://tldp.org/HOWTO/Remote-X-Apps.html
[oreilly ssh x forward]: https://docstore.mik.ua/orelly/networking_2ndEd/ssh/ch09_03.htm
[generate .Xauthority]: http://justaix.blogspot.hk/2011/01/createrebuild-new-xauthority-file.html
[x11 protocol]: https://www.x.org/archive/X11R7.5/doc/x11proto/proto.pdf
[sddm config x]: https://wiki.archlinux.org/index.php/SDDM
