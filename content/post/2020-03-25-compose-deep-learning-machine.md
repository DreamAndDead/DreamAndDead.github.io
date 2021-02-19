---
date: "2020-03-25T00:00:00Z"
tags: hardware deep-learning
title: 深度学习攒机总结
---

深度学习需要强大的算力做支撑，无奈手边没有这样的机器，租赁和云服务器的方式又略显昂贵，
免费的云计算服务不是网络不通畅，就是在软件环境上有限制，这大大限制了探索深度学习魅力的自由度。

与其花费在租赁和云服务器上，不如自己组装一台算力合适的机器。

<!--more-->

# 规划

## GPU

粗略来看，在深度学习方面 GPU 的训练效率是 CPU 的 10 倍，所以选择 GPU 是最重要的第一步。

根据这两篇出色的文章，[深度学习如何选择GPU?][pick gpu 1]，[更新2080Ti后，深度学习该选什么显卡?][pick gpu 2]

[pick gpu 1]: https://www.cnblogs.com/xiaozhi_5638/p/10923351.html
[pick gpu 2]: https://zhuanlan.zhihu.com/p/42749496

在没有过高的预算情况下，配置了 影弛 RTX 2070 SUPER。

## 主板

选择一个资源丰厚的主板是重要的第二步，因为主板限定了 CPU 的型号，PCIe 通道的数量，以及 m.2 usb3.0 等外接口。

最终选择了 x99 主板，华南寨板 x99-f8（没有预算），因为提供了足够的接口，支持 E5 系列 CPU，提供 40 个 PCIe 通道。

附：[PCIe 通道解析][pcie]

[pcie]: https://www.chiphell.com/thread-2153551-1-1.html

当前的单张显卡占据 16 个通道，后期拓展双显卡使用 32 通道，留出一定拓展空间。

## CPU

CPU 选择了 E5 V3 2080，服务器系列的 CPU 虽然主频不高，但是核心多，足够稳定（还是预算）

附：[E5 性能规格表][xeon]

[xeon]: https://ark.intel.com/content/www/us/en/ark/products/series/78583/intel-xeon-processor-e5-v3-family.html

## 内存

本着内存越大越好，频率越高越好的原则，配置了单条 32G 2400MHz 三星内存。

重要的是它支持 recc，服务器主板的专享。

当前是单条单通道，之后可能拓展到 4 通道。

## 硬盘

硬盘选择的范围就比较小，SSD 是必须的，这里配置了 m.2 接口的 Tigo 硬盘。

## 电源

电源要为所有元件供能，且最高瓦数要有拓展之后的盈余。

在预算吃紧的情况下，配置了口碑不错的 海韵 850W，留出了大量电力供日后拓展。

## 机箱

选购了一个精简的塔式机箱，最大可安装 E-ATX 主板，内部空间足够大，且可以藏线，硬盘位多，前后带 3 个风扇散热通畅，后期也可以加装水冷。

## CPU 散热

这方面选择配套 x99 主板的散热器就可以，铜管数越多越好。

## 支架

显卡的确很重，而且由于主板是侧装的，显卡的重量很容易将 PCIe 接口压弯，所以最好配置一个显卡支架做支撑，不至于引起更多问题。


# 装机

硬件组装的过程就不赘述了，在装入机箱前，一定要先安装 windows，用 AIDA64 跑满足够小时的压力测试，提前发现硬件组合的问题。


# 系统

## OS

虽然 Linux 种类繁多，但是还是推荐 ubuntu 18.04，配置快捷不折腾。

虽然有 server 版，但是这里建议使用 desktop 版，性能差异并非太大，且提供了图形界面（只占用很少的显存），方便查看和调整其中的数据（尤其是图片）。

而且使用了图形界面，所以 NVidia 驱动已经为 [persistence 状态][pers state]。

[pers state]: https://docs.nvidia.com/deploy/driver-persistence/

## Remote

- openssh-server，服务器必备，使用 ssh 可远程终端连接
- nfs-server，用于导出用户根目录，可以挂载到开发机，用心爱的编辑器开发
- tmux，在 ssh 会话中开启多终端，同时防止 ssh 中断导致训练中断
- tigervnc，必要时需要远程使用图形界面

## Env

配置最新的 tensorflow 环境

### Python

建议使用 conda 来提供 python 环境，使用 miniconda，精简，按需添加。

官方下载 miniconda 安装脚本，安装后配置[镜像源][conda mirror]。

[conda mirror]: https://mirror.tuna.tsinghua.edu.cn/help/anaconda/

使用 python 3.7 创建基础环境，和其它的库的版本匹配更好。

```
$ conda create -n deep-learning python==3.7
```

### NVidia driver & Cuda & CuDNN & tensorflow

根据 [tensorflow 的官方文档][cuda apt]，提供了安装 nvidia 驱动，cuda，cudnn 的方法

[cuda apt]: https://www.tensorflow.org/install/gpu#install_cuda_with_apt

对于 18.04 版本，它提供了如下的方法，从官方源安装 driver, cuda, cudnn 这一系列让新手头疼的库。


```
# Add NVIDIA package repositories
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-repo-ubuntu1804_10.1.243-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu1804_10.1.243-1_amd64.deb
sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
sudo apt-get update
wget http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/nvidia-machine-learning-repo-ubuntu1804_1.0.0-1_amd64.deb
sudo apt install ./nvidia-machine-learning-repo-ubuntu1804_1.0.0-1_amd64.deb
sudo apt-get update

# Install NVIDIA driver
sudo apt-get install --no-install-recommends nvidia-driver-440             # 应该是 440，而不是 418!!!!!!
```

在驱动安装之后，使用提供的命令，检测显卡的状态，验证驱动是否已经安装好

```
$ nvidia-smi
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 440.64.00    Driver Version: 440.64.00    CUDA Version: 10.2     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|===============================+======================+======================|
|   0  GeForce RTX 207...  On   | 00000000:03:00.0 Off |                  N/A |
| 34%   30C    P2    36W / 215W |      73MiB /  7979MiB |      4%      Default |
+-------------------------------+----------------------+----------------------+
                                                                               
+-----------------------------------------------------------------------------+
| Processes:                                                       GPU Memory |
|  GPU       PID   Type   Process name                             Usage      |
|=============================================================================|
|    0      1220      G   /usr/lib/xorg/Xorg                            24MiB |
|    0      1290      G   /usr/bin/gnome-shell                          49MiB |
+-----------------------------------------------------------------------------+
```

之后再安装 cuda, cudnn 和 TersorRT（可选）

```
# Install development and runtime libraries (~4GB)
sudo apt-get install --no-install-recommends \
        cuda-10-1 \
        libcudnn7=7.6.4.38-1+cuda10.1  \
        libcudnn7-dev=7.6.4.38-1+cuda10.1
    

# Install TensorRT. Requires that libcudnn7 is installed above.
sudo apt-get install -y --no-install-recommends libnvinfer6=6.0.1-1+cuda10.1 \
        libnvinfer-dev=6.0.1-1+cuda10.1 \
        libnvinfer-plugin6=6.0.1-1+cuda10.1
```

官方发布的 tensorflow 2.1.0 在 cuda 10.1，cudnn 7.6 的[环境][version match]下编译，

[version match]: https://www.tensorflow.org/install/source#linux

根据驱动的版本，安装

```
$ pip install tensorflow-gpu==2.1.0 keras==2.3.1
```

至此，python，tensorflow，显卡驱动，cuda，keras 的版本就有了合理的匹配。


安装之后，检测 tensorflow [是否使用了 gpu][using gpu]。

[using gpu]: https://stackoverflow.com/questions/38009682/how-to-tell-if-tensorflow-is-using-gpu-acceleration-from-inside-python-shell


一切配置检验之后，建议更新所有包到最新版本

```
$ apt update
$ apt upgrade
```

# End

试运行一些项目，内存空间充足，显存足够，显卡算力足够，CPU 24 线程并发，开发效率大大的提高了。

