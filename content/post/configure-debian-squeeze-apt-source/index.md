---
title: Configure apt rightly for debian squeeze
date: "2018-09-26T16:50:00Z"
categories:
- Debian
tags: 
- devops
- linux
- trouble-shooting
featured_image: images/featured.png
aliases:
- /2018/09/26/configure-debian-squeeze-apt-source.html
---

本想在 Debian Squeeze 上安装一些依赖，没想到刚执行 `apt-get update` ，就出现这样的错误信息。

<!--more-->

```
W: GPG error: http://mirrors.163.com squeeze Release: The following signatures were invalid: KEYEXPIRED 1520281423 KEYEXPIRED 1501892461
E: Release file expired, ignoring http://mirrors.163.com/debian-archive/dists/squeeze-lts/Release (invalid since 923d 19h 26min 3s)
```

# 问题出在哪里

Debian Squeeze 6.0 版本对于当前最新的 9.5 版本来说，是过于陈旧了。
错误信息表示，证书过期，也不是太意外的事。

以 `The following signatures were invalid` 为关键字进行搜索，大体有两种方案：

## 缓存原因？

搜索到的大多数结果给出这样的解答，[比如这里](https://www.cnblogs.com/arrongao/archive/2012/12/13/2815614.html)

```
sudo apt-get clean
cd /var/lib/apt
sudo mv lists lists.old
sudo mkdir -p lists/partial
sudo apt-get clean
sudo apt-get update
```

他们认为原因是 apt 系统出现临时性的缓存故障，所以用 clean 的方式来清除。
我不知道在当时是否真的有效，毕竟那篇博客写在 2012 年，当时 Debian 6.0 也才发布一年，决不至于密钥出现过期，怀疑到缓存身上也
情有可原。

但是当前我的密钥是真的过期了，invalid since 923d(ays)，我尝试了这种 clean 的方法，并不能生效。看来解决方案也有保持期啊。

## 密钥续期？

另一种方案是续期密钥，[比如这里](https://askubuntu.com/a/837004)

```
sudo apt-key list | grep "expired: "
sudo apt-key adv --keyserver keys.gnupg.net --recv-keys [KEY]
```

这种方案想为过期的密钥续期，使其可用。
我先在系统里查看了密钥的情况，确实过期的太久。

```
$ sudo apt-key list
/etc/apt/trusted.gpg
--------------------
..........................
..........................
..........................
pub   2048R/6D849617 2009-01-24 [expired: 2013-01-23]
uid                  Debian-Volatile Archive Automatic Signing Key (5.0/lenny)

pub   4096R/B98321F9 2010-08-07 [expired: 2014-08-05]
uid                  Squeeze Stable Release Key <debian-release@lists.debian.org>
..........................
..........................
..........................
```

于是用 `apt-key adv` 进行续期，再次查看密钥情况，发现并没有多少改观，
时间确实前进更新了几个月，但是依旧保持着 expired 状态，毕竟还差很多年。

我想可能和第一种方案是一样的问题，“方案过期”。在当时版本还支持的时候，应该是有效果的，但是当前情况已经
发生了变化，错误信息是一样的，但是问题本身已经出现了本质的变化。

# 当前的正确方案

于是继续搜索，在[官方文档的FAQ部分](https://wiki.debian.org/DebianSqueeze)，找到了官方解答。

1.修改 source.list

```
deb http://archive.debian.org/debian squeeze main
deb http://archive.debian.org/debian squeeze-lts main
```

2.同时配置 apt，添加以下内容到 /etc/apt/apt.conf(没有则新建)

```
Acquire::Check-Valid-Until false;
```

其中特别提到了 `The second line will fail with an "expired" type message, so you also need to ...`，so sweet！

既然 Debian Squeeze 已经不再更新，apt source 也划入了 archive，这个方案应该是最“长治久安”的。
