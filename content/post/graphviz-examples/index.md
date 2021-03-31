---
title: "Graphviz Examples"
author: ["DreamAndDead"]
date: 2021-03-22T14:48:00+08:00
lastmod: 2021-03-31T17:43:24+08:00
tags: ["tool", "graphviz", "drawing"]
categories: ["Tool"]
draft: false
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

```dot
digraph G {
  main -> init -> make_string;
  main -> {parse, cleanup};
  main -> printf;
  parse -> execute -> {make_string, compare, printf};
}
```

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

```dot
digraph {
    a -> b[label="0.2"];
    a -> c[label="0.4"];
    c -> b[label="0.6"];
    c -> e[label="0.6"];
    e -> e[label="0.1"];
    e -> b[label="0.7"];
}
```

{{< figure src="images/edge-label.png" >}}


### straight line {#straight-line}

```dot
graph {
    splines=line;

    subgraph cluster_0 {
	label="Subgraph A";
	a; b; c
    }

    subgraph cluster_1 {
	label="Subgraph B";
	d; e;
    }

    a -- e;
    a -- d;
    b -- d;
    b -- e;
    c -- d;
    c -- e;
}
```

{{< figure src="images/edge-straight.png" >}}


## table {#table}

```dot
digraph {
	format[label=<
	      <table border="1" cellspacing="4">
		<tr>
		  <td border="0" bgcolor="white">资产</td>
		  <td border="0" bgcolor="white">  =  </td>
		  <td border="0" bgcolor="white">  负债  </td>
		  <td border="0" bgcolor="white">  +  </td>
		  <td border="0" bgcolor="white">所有者权益</td>
		</tr>
		<tr>
		  <td border="0" bgcolor="white">现金</td>
		  <td border="0" colspan="3" bgcolor="white"></td>
		  <td border="0" bgcolor="white">资本</td>
		</tr>
		<tr>
		  <td border="0" bgcolor="white">+400,000</td>
		  <td border="0" colspan="3" bgcolor="white"></td>
		  <td border="0" bgcolor="white">+400,000</td>
		</tr>
	      </table>
	       >, shape=none]
}
```

{{< figure src="images/table.png" >}}

```dot
digraph {
	format[label=<
	      <table border="0" cellspacing="4">
		<tr>
		  <td border="0" colspan="2" bgcolor="white">现金</td>
		</tr>
		<hr/>
		<tr>
		  <td border="0" bgcolor="white">左边</td>
		  <vr/>
		  <td border="0" bgcolor="white">右边</td>
		</tr>
		<tr>
		  <td border="0" bgcolor="white">现金增加</td>
		  <vr/>
		  <td border="0" bgcolor="white">现金减少</td>
		</tr>
	      </table>
	       >, shape=none]
}
```

{{< figure src="images/table-hr-vr.png" >}}


## Resources {#resources}

-   [dot guide](https://www.graphviz.org/pdf/dotguide.pdf), official manual, precise and clear
-   other links
    -   <https://blog.csdn.net/youwen21/article/details/98397993>
    -   <https://www.cnblogs.com/shuqin/p/11897207.html>
    -   <https://stackoverflow.com/questions/10147619/how-can-i-reverse-the-direction-of-every-edge-in-a-graphviz-dot-language-graph>
    -   <https://stackoverflow.com/questions/43599738/graphviz-alignment-of-subgraph>
    -   <https://renenyffenegger.ch/notes/tools/Graphviz/examples/index>
    -   <https://graphs.grevian.org/reference>
    -   <http://graphviz.org/doc/info/attrs.html>


## License {#license}

{{< license >}}
