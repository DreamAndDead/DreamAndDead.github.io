---
title: Understanding ssh port forwarding
date: "2017-12-13T00:00:00Z"
categories:
- SSH
tags:
- network
- ssh
- linux
featured_image: images/featured.png
aliases:
- /2017/12/13/understanding-ssh-tunnel.html
---

这篇文件旨在理好的理解ssh隧道的原理与用法。

<!--more-->

# Port forwarding

端口转发是ssh内建的机制，在已经建立的ssh通道之上，转发应用层的流量。
大家也形象地称之为ssh隧道（ssh tunnel）。

端口转发分为3类：
- local forwarding，将client端口流量转发到server端
- remote forwarding，与local forwarding相反，将server端口流量转发到client端
- dynamic forwarding，本质与前两类相同，流量转发地址由流量访问地址动态决定，和proxy有相似的效果

server是运行sshd服务的主机，client是ssh远程连接server的主机

# Local Forwarding

## meaning

举一个简单的例子相对容易理解。

比如server主机运行web服务，端口80，client使用ssh远程连接server
```
ssh -L 7000:127.0.0.1:80 root@server_ip
```
和普通的ssh连接一样，开启一个新的shell，控制server主机，与此同时，ssh也在client主机监听7000端口。

```
curl -X GET http://localhost:7000
```
在client访问7000端口，流量会通过与server建立的ssh通道，转发至server的127.0.0.1:80，
等同于访问了server的web服务，amazing！

先来解释下示例的命令
- root@server_ip，server ip与用户，与常规使用ssh是一样的
- -L，L means Local，local forwarding
- 7000，本地端口，访问此端口的流量会被转发
- 127.0.0.1:80，重点，127.0.0.1:80是相对于server而言，也就是server_ip:80

## usage

from man page
```
-L [bind_address:]port:host:hostport
-L [bind_address:]port:remote_socket
-L local_socket:host:hostport
-L local_socket:remote_socket
```
参数分为4类，从中看到，端口不仅可以是tcp socket，也可以是unix socket。

对参数的理解要清晰
1. bind_address，可以为以下值
   - localhost：client主机的port为转发端口，但是，client_ip:port不能转发来自client LAN其它主机的流量
   - 忽略：效果同localhost
   - *：端口绑定没有变化，区别在于，client_ip:port可以转发来自client LAN其它主机的流量
2. host:hostport，转发流量所至的端口。host:hostport是相对于server_ip而言，这点非常重要，比如
   - 参数为localhost:80，意味着转发至server_ip:80
   - 参数为another_ip:80，如果another_ip:80对于server_ip是可以访问的，最终会将client_ip:port的流量转发至another_ip:80,server只是作为流量中转。
     another_ip通常取server局域网内其它主机的ip 或 server内其它网桥的ip（如docker）
3. local_socket,remote_socket，socket文件路径，分别相对于client主机与server主机
    
## example

{{< figure src="images/ssh-tunnel-local-forwarding.png" caption="网络示意图" >}}

假如，存在Client LAN与Server LAN，
Client LAN内有两台主机
- 192.168.0.2，ssh与server连接
- 192.168.0.3
Server LAN有两台主机
- 10.27.0.2，运行sshd服务，自身有公网ip 47.52.20.34，同时
  - 主机内运行dockerd服务，使用/var/run/docker.sock进程间通信
  - 运行nginx容器，容器ip 172.168.0.2，web端口80
- 10.27.0.3
  - 主机运行ElasticSearch服务，端口9200，可供LAN其它主机连接

注：以下所有的ssh连接都是在client_A执行

### 访问nginx

因为nginx运行在docker网桥，属于内部网络，没有端口映射到主机，不能通过47.52.20.24:80访问。

```
ssh -L *:7000:172.168.0.2:80 root@47.52.20.34
```
将在client_A主机7000端口，对client LAN提供server_A的nginx服务。

client_B也从中受益，借助client_A访问nginx
```
curl -X GET http://192.168.0.2:7000
```
    
### 访问ElasticSearch

因为server_B没有公网ip，所以访问要借助server_A作为跳板
```
ssh -L 9200:10.27.0.3:9200 root@47.52.20.34
```
仅仅可以在client_A内部的9200访问server_B的ES，不对client LAN分享


### 访问docker

server_A本身运行dockerd服务，但是使用unix socket，只限于在主机内部docker command才可以通信。
```
ssh -L 6112:/var/run/docker.sock root@47.52.20.34
```
这时在client_A主机上，运行
```
docker -H localhost:6112 ps
```
可以查看server_A的docker容器情况！

如果client也使用unix socket
```
ssh -L /tmp/docker.sock:/var/run/docker.sock root@47.52.20.34
```
路径要使用unix://，达到同样的效果
```
docker -H unix:///tmp/docker.sock ps
```

# Remote Forwarding

## meaning

Remote Forwarding与Local Forwarding是相对的，区别仅仅在于，
Local Forwarding将client端口流量转发至server，而Remote Forwarding将
server端口流量转发至client。

假如在client主机执行
```
ssh -R 7000:127.0.0.1:80 root@server_ip
```
将会在server主机开启7000端口，并将所有流向server_ip:7000的流量转发至client_ip:80，
达到内网穿透的效果。
同样的类比，127.0.0.1:80是相对client主机来说的。

## usage

```
-R [bind_address:]port:host:hostport
-R [bind_address:]port:local_socket
-R remote_socket:host:hostport
-R remote_socket:local_socket
-R [bind_address:]port
```
参数整体与Local Forwarding是相似的，主要是以下区别
- -R的参数与-L是相反的，bind_address:port对应的是server主机，而host:hostport与local_socket对应的
是client主机
- bind_address对于LAN的可见性与Local Forwarding相同
- 第5类用法是Local Forwarding中没有的，到[Dynamic Forwarding](#dynamic-forwarding)中再做提及

需要注意的是，当bind_address要使用0.0.0.0/*时，需要在sshd_config中[配置选项](https://serverfault.com/questions/666532/remote-port-forwarding-not-working)并重启sshd

```
GatewayPorts yes
```

## example

{{< figure src="images/ssh-tunnel-remote-forwarding.png" caption="网络示意图" >}}

网络结构同Local Forwarding，区别在于之前在server LAN中的服务，现在运行于client LAN。
通过Remote Forwarding，可以在外网访问到内网的服务，达到网络穿透的效果。

注：以下所有的ssh连接都是在client_A执行

### 访问nginx

server_A并没有运行web服务，下面命令将内网client_A主机的web服务暴露至外网访问
```
ssh -R *:80:172.168.0.2:80 root@47.52.20.34
```
server LAN中的server_B可以通过10.27.0.2:80访问，其它用户可通过公网ip 47.52.20.34:80访问

### 访问ElasticSearch

```
ssh -R *:9200:192.168.0.3:9200 root@47.52.20.34
```
将client_B主机的ES服务暴露于外网访问

### 访问docker

使用unix socket参数，访问内网client_A主机的dockerd服务
```
ssh -R 6112:/var/run/docker.sock root@47.52.20.34
```
在server_A通过
```
docker -H localhost:6112 ps
```
查看client_A主机docker容器情况

如果使用unix socket
```
ssh -R /tmp/docker.sock:/var/run/docker.sock root@47.52.20.34
```
在server_A通过
```
docker -H unix:///tmp/docker.sock ps
```
达到同样的效果

# Dynamic Forwarding

## meaning

Dynamic Forwarding望名生义，动态的端口转发。
动态体现在它可以由来源流量所流向的地址决定转发的地址。
在这种意义上，它有些像一个proxy。

举例来看，网络结构同Local Forwarding章节

{{< figure src="images/ssh-tunnel-dynamic-local-forwarding.png" caption="网络示意图" >}}

在client_A执行
```
ssh -D *:1080 root@47.52.20.34
```
将会在client_A运行一个socks服务器，监听1080端口，转发访问1080的流量

```
export http{s,}_proxy=socks5://127.0.0.1:1080
curl -X GET http://172.168.0.2
curl -X GET https://google.com
```
设置http代理为127.0.0.1:1080
- 访问172.168.0.2，即代理至server_A的web服务
- 访问google.com，便达到了翻墙的效果！

## usage

```
-D [bind_address:]port
-R [bind_address:]port
```
-D表示Local Dynamic Forwarding，-R表示Remote Dynamic Forwarding。
至于为什么不用-L而用-D，不得而知。

虽然称为Dynamic Forwarding，但是端口转发的本质并没有变化
- Local/Remote Forwarding只可以限定某个特定的socket，Dynamic Forwarding可以转发至多个tcp socket
- Dynamic Forwarding不可以转发至unix socket

Dynamic Forwarding使用socks协议，在相应端口运行一个socks服务器，进行动态转发
- Local Dynamic Forwarding是在client端开启socks服务器，将流量转发至server
- Remote Dynamic Forwarding与之相反，在server端开启socks服务器，将流量转发至client

socks协议工作在传输层之上，应用层之下，所以可以转发所有应用层的流量，而对于下层则无能为力。

注：以下所有的ssh连接都是在client_A执行

## example

### cross the wall


{{< figure src="images/ssh-tunnel-dynamic-local-forwarding.png" caption="网络示意图" >}}

在client_A运行一个socks服务器，监听1080端口
```
ssh -D *:1080 root@47.52.20.34
```

client LAN主机设置代理地址，达到内网翻墙的效果
```
export http{s,}_proxy=socks5://192.168.0.2:1080
curl -X GET https://google.com
```


### 内网穿透

{{< figure src="images/ssh-tunnel-dynamic-remote-forwarding.png" caption="网络示意图" >}}

在server_A运行一个socks服务器，监听1080端口
```
ssh -R *:1080 root@47.52.20.34
```

设置公网ip代理地址，进行内网穿透
```
export http_proxy=socks5://47.52.20.34:1080
curl -X GET http://172.168.0.2:80
curl -X GET http://192.168.0.3:9200
```
访问nginx服务与ES服务

