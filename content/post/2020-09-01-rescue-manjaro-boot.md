---
date: "2020-09-01T00:00:00Z"
tags: linux manjaro grub
title: 记一次修复 manjaro 引导的过程
---

{% include image.html url="manjaro-logo.png" desc="" %}

manjaro 发行版最具特色的即是持续不断的软件更新和系统更新，时刻更新自然是一种最佳实践。

```
sudo pacman -Syu
```

但是今天出现更新过程意外中断，中途报错出现段错误。重启之后，无法进入系统。

```
error: file '/vmlinuz-5.7-x86_64' not found.
error: you need to load the kernel first.

Press any key to continue...
```


<!--more-->


# 修复

## 定位

一般来说，大部分出现系统无法引导的问题，原因都在于引导项的路径配置出现错误，比如指向了不正确的分区，这个时间可以借助 grub cmd 模式来解决。

这是今天出现的情况，引导路径没有问题，只是在引导的目录下，找不到内核文件（可能是更新中断的副作用吧）。

所以要修复系统，只能重装内核。

## 重装内核

先在官网下载最新 manjaro 镜像，刻录到 u 盘中，用 u 盘引导进入 live 系统。

仔细查看分区，我的系统在一个单独的硬盘上，`/dev/sdb`。

其中

```
/boot 挂载在 /dev/sdb1
/     挂载在 /dev/sdb2
```

首先将分区挂载

```
sudo mount -t ext4 /dev/sdb2 /mnt
sudo mount -t ext2 /dev/sdb1 /mnt/boot
```

进入“原系统的根目录“，`chroot`

```
cd /mnt
manjaro-choot .
```

在这一步之后，shell 中的操作就和原先正常的系统是一样的。

继续完成之前没有完成的更新

```
sudo pacman -Syu
```

安装内核文件

```
sudo pacman -S linux
```

更新引导

```
sudo update-grub
```

再次重启就恢复正常。

