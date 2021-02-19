---
date: "2018-05-25T00:00:00Z"
tags: jmeter trouble-shooting tips
title: 记一次 Jmeter 分布式测试故障调试过程
---

之前总结了 jmeter 分布式测试的过程，在部署过程中提到，要在 system.properties
中配置自己的 IP。

至于为什么要这么做，源于这一次 debug 的过程。

<!--more-->

# 运行环境

![jmeter-test-env][jmeter-test-env]

[jmeter-test-env]: http://on7blnbb0.bkt.clouddn.com/image/png/jmeter-trouble-shooting.png

mint, ubuntu 两台主机作为 master 节点，一台 win server 作为 slave 节点，采用分布式的方式，
对 target 进行测试。

# 问题

问题很奇怪，以 mint 系统作为 master，调度分布式测试没有问题，

```
$ jmeter -n -t ./test.jmx -R 10.27.2.210 -l test.jtl -e -o report_test
Creating summariser <summary>
Created the tree successfully using ./888.jmx
Configuring remote engine: 10.27.2.210
Starting remote engines
Starting the test @ Wed May 16 10:09:24 CST 2018 (1526436564379)
Remote engines have been started
Waiting for possible Shutdown/StopTestNow/Heapdump message on port 4445
summary =      1 in 00:00:00 =    3.5/s Avg:    20 Min:    20 Max:    20 Err:     0 (0.00%)
Tidying up remote @ Wed May 16 10:09:26 CST 2018 (1526436566910)
... end of run
```

而使用另一台 ubuntu 主机作为 master，调度测试，则卡在 waiting 这一行，

```
$ jmeter -n -t ./test.jmx -R 10.27.2.210 -l test.jtl -e -o report_test
Creating summariser <summary>
Created the tree successfully using ./888.jmx
Configuring remote engine: 10.27.2.210
Starting remote engines
Starting the test @ Wed May 16 10:09:24 CST 2018 (1526436564379)
Remote engines have been started
Waiting for possible Shutdown/StopTestNow/Heapdump message on port 4445
```

## 尝试1：防火墙干扰

第一种猜测，应该是 ubuntu 系统的防火墙干扰，阻止了 4445 端口的数据。

先关闭防火墙

```
$ sudo service ufw stop
```

再次运行测试，依旧卡在 waiting 那一行，看来问题没有那么简单。

## 尝试2：关闭监听功能

以 `Waiting for possible Shutdown/StopTestNow/Heapdump message on port 4445` 
信息在网上查找，有人建议修改 jmeter 设置，不监听 shutdown 信息，相应的也就不会开启 4445 端口，
理论上就不会卡在 waiting 那里，而是直接跳过。


在 ubuntu 主机，修改 jmeter.properties 文件，

<script src="https://gist-it.appspot.com/https://github.com/apache/jmeter/blob/v4_0/bin/jmeter.properties?slice=1074:1076"></script>


```
#jmeterengine.nongui.maxport=4455 修改为
jmeterengine.nongui.maxport=0
```

但是依旧不能工作。

## 尝试3：端口没有开启

在 mint 作为 master，成功调度分布式测试的过程中，mint 主机自身打开了 4445 udp 端口，
用 netstat 可以查看的到。

但是，在 ubuntu 调度的时候，用 netstat 也可以查看到 4445 udp 端口已经打开。
而且用 [netcat 测试 udp 端口][nc test udp port]也是可用的。

```
$ nc -vz -u 10.27.2.13 4445
Connection to 10.27.2.13 4445 port [udp/*] succeeded!
```

看来也不是端口未开放的问题。

## 尝试4：信息被阻塞

猜测是不是在哪个环节，shutdown message 被阻拦，导致收不过消息，而一直卡在那里。

于是在 mint 主机运行测试的时候，用 wireshark 监听所有发送与 4445 udp 的信息，然而！什么都没有！

这样看来，之前对问题的判断是不准确的。一直以为和 shutdown message 有关，其实正常运行一次测试，根本不必要有 shutdown message。

## 尝试5：在日志中寻找

之前一直被表面现象迷惑，认为是 master 的问题，直到进入 slave 节点查看日志 `jmeter-server.log`。
发现这样的错误输出，

```
2018-05-14 18:29:56,240 ERROR o.a.j.s.BatchSampleSender: testEnded(host)
java.rmi.ConnectException: Connection refused to host: 127.0.1.1; nested exception is: 
	java.net.ConnectException: Connection refused: connect
	at sun.rmi.transport.tcp.TCPEndpoint.newSocket(Unknown Source) ~[?:1.8.0_162]
	at sun.rmi.transport.tcp.TCPChannel.createConnection(Unknown Source) ~[?:1.8.0_162]
	at sun.rmi.transport.tcp.TCPChannel.newConnection(Unknown Source) ~[?:1.8.0_162]
	at sun.rmi.server.UnicastRef.invoke(Unknown Source) ~[?:1.8.0_162]
	at java.rmi.server.RemoteObjectInvocationHandler.invokeRemoteMethod(Unknown Source) ~[?:1.8.0_162]
	at java.rmi.server.RemoteObjectInvocationHandler.invoke(Unknown Source) ~[?:1.8.0_162]
	at com.sun.proxy.$Proxy20.testEnded(Unknown Source) ~[?:?]
	at org.apache.jmeter.samplers.BatchSampleSender.testEnded(BatchSampleSender.java:127) [ApacheJMeter_core.jar:4.0 r1823414]
	at org.apache.jmeter.samplers.DataStrippingSampleSender.testEnded(DataStrippingSampleSender.java:86) [ApacheJMeter_core.jar:4.0 r1823414]
	at org.apache.jmeter.samplers.RemoteListenerWrapper.testEnded(RemoteListenerWrapper.java:90) [ApacheJMeter_core.jar:4.0 r1823414]
	at org.apache.jmeter.engine.StandardJMeterEngine.notifyTestListenersOfEnd(StandardJMeterEngine.java:229) [ApacheJMeter_core.jar:4.0 r1823414]
	at org.apache.jmeter.engine.StandardJMeterEngine.run(StandardJMeterEngine.java:495) [ApacheJMeter_core.jar:4.0 r1823414]
	at java.lang.Thread.run(Unknown Source) [?:1.8.0_162]
Caused by: java.net.ConnectException: Connection refused: connect
	at java.net.DualStackPlainSocketImpl.connect0(Native Method) ~[?:1.8.0_162]
	at java.net.DualStackPlainSocketImpl.socketConnect(Unknown Source) ~[?:1.8.0_162]
	at java.net.AbstractPlainSocketImpl.doConnect(Unknown Source) ~[?:1.8.0_162]
	at java.net.AbstractPlainSocketImpl.connectToAddress(Unknown Source) ~[?:1.8.0_162]
	at java.net.AbstractPlainSocketImpl.connect(Unknown Source) ~[?:1.8.0_162]
	at java.net.PlainSocketImpl.connect(Unknown Source) ~[?:1.8.0_162]
	at java.net.SocksSocketImpl.connect(Unknown Source) ~[?:1.8.0_162]
	at java.net.Socket.connect(Unknown Source) ~[?:1.8.0_162]
	at java.net.Socket.connect(Unknown Source) ~[?:1.8.0_162]
	at java.net.Socket.<init>(Unknown Source) ~[?:1.8.0_162]
	at java.net.Socket.<init>(Unknown Source) ~[?:1.8.0_162]
	at sun.rmi.transport.proxy.RMIDirectSocketFactory.createSocket(Unknown Source) ~[?:1.8.0_162]
	at sun.rmi.transport.proxy.RMIMasterSocketFactory.createSocket(Unknown Source) ~[?:1.8.0_162]
	... 13 more
```

为什么地址是 127.0.1.1 ？为什么要向这个地址通信？

根据对 jmeter master/slave 通信机制的理解，不仅 master 主动向 slave 通信， slave 也向 master 主动通信，自然要知道彼此的地址。

由此联想到，在 slave 节点多网卡的时候，一般都[设置 hostname][jmeter server set hostname]，猜测 master 也需要进行同样的设置，告知 slave 自己的通信地址。

于是在 ubuntu master 主机的 [system.properties][jmeter system properties] 最后一行添加，


```
java.rmi.server.hostname=10.27.2.13
```

测试终于正常运行了。

# 写在最后

推而广之，在 jmeter 的所有节点，无论 master/slave，都显示设置自己的 IP 地址。

[system.properties][jmeter system properties] 最后一行添加

```
java.rmi.server.hostname=<IP addr>
```

[nc test udp port]: https://unix.stackexchange.com/a/266368/278131
[jmeter server set hostname]: https://github.com/apache/jmeter/blob/v4_0/bin/jmeter-server#L30
[jmeter system properties]: https://github.com/apache/jmeter/blob/v4_0/bin/system.properties
