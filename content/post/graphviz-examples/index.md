---
title: "Graphviz Examples"
author: ["DreamAndDead"]
date: 2021-03-22T14:48:00+08:00
lastmod: 2021-03-24T15:01:54+08:00
tags: ["tool", "graphviz", "drawing"]
categories: ["Tool"]
draft: true
comment: false
featured_image: "images/featured.png"
---

## usage {#usage}

安装相应软件包

```text
$ pacman -S graphviz xdot
```

新建 `test.dot` 文件，保存绘图代码。

使用 xdot 实时预览，

```text
$ xdot test.dot
```

绘图结果，生成 png 图片，

```text
$ dot -Tpng -o test.png test.dot
```


## graph {#graph}


### undirected {#undirected}

```dot
graph {
   label="Undirected Graph";
   rankdir=LR;
   { rank=same; a, c, d };
   splines=line;

   a -- b -- c -- e -- a;
   a -- c -- d;
}
```

{{< figure src="images/undirected-graph.png" >}}


### directed {#directed}

```dot
digraph {
    a -> b;
    b -> c;
    c -> d;
    d -> a;
}
```

{{< figure src="images/directed-graph.png" >}}


### subgraph {#subgraph}


#### asynomous {#asynomous}

{{< figure src="images/subgraph.png" >}}


#### named {#named}

Subgraph name must start with prefix `cluster`.

```dot
digraph {
    subgraph cluster_0 {
	label="Subgraph A";
	a -> b;
	b -> c;
	c -> d;
    }

    subgraph cluster_1 {
	label="Subgraph B";
	a -> f;
	f -> c;
    }
}
```

{{< figure src="images/subgraph-named.png" >}}


## edge {#edge}


### label {#label}

{{< figure src="images/edge-label.png" >}}


### straight line {#straight-line}

{{< figure src="images/edge-straight.png" >}}


## ref {#ref}

<https://blog.csdn.net/youwen21/article/details/98397993>

<https://www.cnblogs.com/shuqin/p/11897207.html>

<https://stackoverflow.com/questions/10147619/how-can-i-reverse-the-direction-of-every-edge-in-a-graphviz-dot-language-graph>

<https://stackoverflow.com/questions/43599738/graphviz-alignment-of-subgraph>

<https://renenyffenegger.ch/notes/tools/Graphviz/examples/index>

<https://graphs.grevian.org/reference>

<https://graphviz.gitlab.io/documentation/>

<http://graphviz.org/doc/info/attrs.html>
