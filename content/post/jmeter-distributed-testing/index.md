---
title: 使用Jmeter进行分布式测试
date: "2018-05-24T19:10:00Z"
categories:
- Jmeter
tags:
- jmeter
- test
featured_image: images/featured.jpg
aliases:
- /2018/05/24/jmeter-distributed-testing.html
---

业务发展初期，关注的更多是功能，直至使用量增加到一定量级，就要考虑高并发，程序性能等问题，
因此性能测试就成为重要的一环。

Loadrunner 是性能测试工具领域的王者，但是闭源无法自由（free）使用。相较之下，开源的 Jmeter 算是一个
不错的选择。

性能测试要达到一定的量级，仅仅靠单机是不够的，必须协调多方资源，模拟高数量级的并发。Jmeter 提供的
分布式测试方案刚好满足这一点，这也是本文的由来。

<!--more-->

# Install

Jmeter 使用 Java 编写，要求本机必须存在 Java 环境，推荐使用 8 版本。

```
$ sudo apt install openjdk-8-jdk
```

官方推荐使用 Jmeter 的最新版本，新版本会修复旧有的 bug 并且有新的 feature。
目前最新版本是 4.0，[直接下载 Binaries 压缩包][download jmeter]即可。


解压之后，目录结构如下

```
apache-jmeter-4.0
    ├── backups
    ├── bin
    ├── docs
    ├── extras
    ├── lib
    ├── LICENSE
    ├── licenses
    ├── NOTICE
    ├── printable_docs
    └── README.md
```

主要程序都在 bin/ 目录下，在这里我们主要使用

```
./bin/jmeter
./bin/jmeter-server
```


# GUI or not

Jmeter 运行有两种模式，GUI和非GUI。

GUI由于可视化，方便构建 jmx（Jmeter测试计划文件，本质是 xml）。
而在运行大量测试的时候，GUI会成为资源的负担。
官方推荐使用 GUI 模式来构建测试计划，并进行很小的并发量来调试测试计划，
使用非 GUI 模式来运行大并发量的测试计划。


# Distributed

Jmeter 可以从单机进行测试，但是毕竟单机的资源有限，所发起的并发自然是有限的，
这里我们主要讨论分布式测试。

分布式协同多个主机，同时发起测试，并发量随着主机的增加而增加。
由 Master 发起测试，并将 jmx 传输到所有的 Slave，每个 Slave 都会执行 jmx（Slave 个数决定并发量的翻倍数），
并将相关数据反馈回 Master，由 Master 整合数据，呈现报表。

{{< figure src="images/jmeter-distributed-testing-structure.png" caption="Jmeter分布式测试模型" >}}


从程序的角度来看，`./bin/jmeter`于 Master 运行，发起测试。
`./bin/jmeter-server`于 Slave 运行，从 Master 获取 jmx，并对目标发起测试。

jmeter client 运行于 Master 节点，jmeter server 运行于 Slave 节点，这点概念有些反直觉，我在和同事
交流的时候就经常搞混。所以一开始就要明确概念，推荐 Master/Slave 概念，清晰且符合直觉。


## Deploy

部署 Jmeter 分布式并不复杂，关键要了解怎么样的测试效率是最高的。

- Master/Slave/Target 最好在一个内网内
- 如果 Target 在外网，就要保证网络出口的带宽要足够

进行测试前，所有的 Master/Slave 节点都要已经安装了 Jmeter，参考 [Install](#install) 一节。
所有的 Slave 运行 `./bin/jmeter-server`，监听来自 Master 发起的测试。

在运行 `jmeter-server` 之前，部分配置可能是必要的。

**关闭rmi ssl**

Jmeter默认将 rmi ssl 打开，在 Master/Slave 的通信中使用安全传输，如果都在内网的话，就不必配置 ssl 证书了，
提高效率并节省时间。

在 Master/Slave 节点的 `./bin/jmeter.properties` 文件中，[修改相应配置][jmeter rmi ssl config]

```
# 修改server.rmi.ssl.disable=false为
server.rmi.ssl.disable=true
```


**关闭防火墙**

关闭 Master/Slave 节点上的防火墙，防止对通信中的干扰。

```
$ sudo service ufw stop
```

**设置IP**

在 Master/Slave 节点的 `./bin/system.properties` 中，最后一行添加

```
java.rmi.server.hostname=<当前节点的IP>
```

为什么这么做，具体参考 [jmeter-distributed-testing-trouble-shooting][jmeter distributed testing trouble shooting]，实力踩坑。


# Run


在 Master 节点启动测试前，先[将 Slave 列表加入 Master 配置列表][jmeter remote hosts config]中。
比如

```
remote_hosts=10.28.2.2, 10.28.2.200, 10.28.3.9
```

由非 GUI 模式发起测试

```
$ rm -rf test.jtl report_test
$ jmeter -n -t ./test.jmx -r -l test.jtl -e -o report_test
```

- `-n` means no GUI
- `-t` 指定 jmx
- `-r` 将使用配置文件中 remote_hosts 作为 Slave 节点
- `-l` 指定日志文件
- `-e` 测试结束后生成统计报表
- `-o` 指定数据报表路径。将所有请求的响应作了统计分析，生成网页，非常详细


# Metric

上述测试，只能在测试结束之后，分析响应时间的分布，错误率之类的信息，并不能得到任何
实时性的数据。

实时性的数据是有用的，可以从两个角度来分类
- 一类是jmeter的数据，如当前线程数，当前发送请求数，当前响应时间分布等
- 一类是被测试主机的性能数据，如cpu使用率，内存使用量等

这样可以将相同时间的数据建立关联关系，有助于找出被测试目标的性能瓶颈可能出现在哪里。

在实践过程中，推荐使用 influxdb + grafana 的结合，因为
- 多数应用的 metric 都可以用 influxdb 来收集（包括 jmeter cadvisor gitlab 等）
- grafana 前端优雅好用，完美支持 influxdb 作为后端

Jmeter 本身的 metric 可以用自身的 Backend Listener 来产生，并传输至 influxdb 中。
Jmeter 有两种 Backend Listener
- Graphite
- Influxdb

本质上来讲，两种 Listener 产生的数据信息量都是一样的，不过对于数据的组织形式有所不同。
Graphite本身是一个自带前后端的数据可视化工具，但是自己觉得不是特别好用，好在 Influxdb 
内部提供对 Graphite 的数据适配，可以采集 Graphite 格式的数据，:thumbsup:。


# Example

在这个示例中，将详细描述上述工具是如何协作的。示例项目在 [https://github.com/DreamAndDead/jmeter-distributed-testing-example][example repo]


## Plan

测试针对的目标是 gitlab ，gitlab 提供了丰富的 RESTful 接口供资源操作，通过 Jmeter 分布式，
对部分接口进行压力测试。

{{< figure src="images/jmeter-distributed-test.png" caption="example test architecture" >}}

- Master 编辑测试计划，发起分布式测试
- Slave 对 gitlab 发起测试，同时将实时数据传送至 influxdb
- gitlab 以 docker 运行，提供 api 供 Slave 测试，同时将内部 metric 发送予 influxdb
- cadvisor 从 gitlab docker 中采集数据，发送至 influxdb
- influxdb 收集所有 metric 数据
- grafana 以 influxdb 作为后端，呈现所有 metric 数据

示例主要在于说明整个测试的结构，使用的测试计划非常简单，而且还有一些内网地址，可以根据需要，
做相应的调整。

### Master

目前的结构是，Master/Slave/Target/Collector 都在一个内网内。这里 Master 并不需要特别的设置，
只需要确保已经安装配置了 Jmeter 并与 Slave 的连通性即可。

### Slave

同 Master，需要正确安装配置 Jmeter 并确保与 Master/Target/Collector 的连通性即可。

### gitlab

gitlab 占用资源比较多，用 docker 限定了资源上限，考察其在资源有限时的表现。

具体启动参考[示例项目][setup target]。


### cadvisor

与 gitlab docker 运行在同一主机，收集所有与 docker container 相关的数据。

具体启动参考[示例项目][setup target]。


### influxdb

influxdb 在这里收集3方面数据，而且使用了3种数据采集的方式。

数据的采集需要相关应用的支持，3方面的联通可参考[示例项目的说明][collector readme]。


### grafana

作为数据前端，从 influxdb 读取并呈现数据，重点在于如何取数据，这就要灵活判断相应的数据结构是什么。

[参考示例项目文档][config grafana]。


## Run

在控制所有 Slave 的 Master，执行

```
$ ./bin/jmeter -n -t ./gitlab.jmx -r -l test.jtl -e -o report_test
```

结束之后，在report_test的文件夹下，生成html报表，用浏览器访问查看报表。


# Pitfalls

大部分情况下，分布式测试都运作的很流畅。近期同事发现了一个细节问题，自己明明联通了5台 Slave，却只在
grafana 看到了一台机器的并发量，其它的好像没有执行。

到相应 Slave 节点，查看 `jmeter-server.log` 文件，发现读取文件 csv 不存在。

原来是因为测试计划中，设定从一个 csv 文件中，读取所有用户的信息，并循环执行创建操作，
但是 Master 在执行测试计划时，只分发 jmx 文件，Slave 由于找不到相应数据文件而失败。

所以部署相关的数据文件需要我们自己想办法解决。并且！有时数据文件一模一样也不行，毕竟 Slave 执行的过程是相同的，
一样的文件必然导致其创建相同的用户，引发冲突，还要为每个 Slave 准备一份数据文件！:no_mouth:。

# End

Jmeter 是一款很赞的软件，thanks apache。

[download jmeter]: https://jmeter.apache.org/download_jmeter.cgi
[jmeter rmi ssl config]: https://github.com/apache/jmeter/blob/trunk/bin/jmeter.properties#L330
[jmeter distributed testing trouble shooting]: /2018/05/25/jmeter-distributed-testing-trouble-shooting.html
[jmeter remote hosts config]: https://github.com/apache/jmeter/blob/trunk/bin/jmeter.properties#L254
[example repo]: https://github.com/DreamAndDead/jmeter-distributed-testing-example
[setup target]: https://github.com/DreamAndDead/jmeter-distributed-testing-example/blob/master/setup/target
[collector readme]: https://github.com/DreamAndDead/jmeter-distributed-testing-example/blob/master/setup/collector/readme.md
[config grafana]: https://github.com/DreamAndDead/jmeter-distributed-testing-example/blob/master/setup/collector/readme.md#config-grafana
