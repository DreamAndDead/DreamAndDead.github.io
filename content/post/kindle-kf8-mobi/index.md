---
title: "Useful Tips for Kindle"
author: ["DreamAndDead"]
date: 2021-03-31T18:15:00+08:00
lastmod: 2021-04-15T16:00:48+08:00
tags: ["kindle", "mobi", "reading"]
categories: ["Tool"]
draft: true
comment: false
featured_image: "images/featured.jpg"
---

Kindle 图书馆服务是 kindle 的一大亮点。
可以存储个人上传的书，而且多端同步注释与阅读进度。

本文来介绍几个 tip，如何更好的使用这项服务。


## Use KF8 Mobi {#use-kf8-mobi}

电子书的本质并不复杂。内容通过 html 标签来组织，通过 css 控制样式。
电子书和阅读器的关系近似于网页和浏览器的关系。

常见电子书格式有 4 种，epub，mobi，azw 和 azw3[^fn:1]。
epub 是开源格式；amazon 认为 epub 由社区发展，
不能很快符合自身的发展需求，于是在之上开发了 mobi。
当前使用的 mobi 有两个版本，KF6 和 KF8。
azw 和 azw3 就是分别在 mobi KF6 和 KF8 上添加了一层“外壳”，
用于版权保护[^fn:2]。

mobi KF8 相比 KF6 有如下优势，可以在 kindle 阅读器上
呈现更丰富的样式，
支持自定义更换字体，
但是缺点是无法呈现书籍封面缩略图（在 android kindle app 可以，在阅读器不行）。

邮件传书不支持 azw3 格式，只支持 mobi[^fn:3]，
为了阅读 KF8 的电子书，需要将 azw3 转换为 KF8 mobi。

calibre 支持转换为 KF8 mobi，但是经实践，
转换得到的电子书无法通过 amazon 审核。

{{< figure src="images/convert.png" caption="Figure 1: calibre 支持转换 KF8 的选项" >}}

另外转换的方式来自论坛 [mobileread](https://www.mobileread.com/forums/)。
先使用 python 脚本解包 azw3 电子书[^fn:4]，
再使用官方提供的 kindlegen 工具加工生成 KF8 mobi 电子书[^fn:5]。

先下载 [KindleUnpack-081.zip](https://www.mobileread.com/forums/attachment.php?attachmentid=168073&d=1543614967)，解压内容如下，

```text
kindleunpack/
├── COPYING.txt
├── DumpMobiHeader_v022.py
├── KindleUnpack_lin.json
├── KindleUnpack.pyw
├── KindleUnpack_ReadMe.htm
├── lib
│   ├── compatibility_utils.py
│   ├── __init__.py
│   ├── kindleunpack.py
│   ├── mobi_cover.py
│   ├── mobi_dict.py
│   ├── mobi_header.py
│   ├── mobi_html.py
│   ├── mobi_index.py
│   ├── mobi_k8proc.py
│   ├── mobi_k8resc.py
│   ├── mobiml2xhtml.py
│   ├── mobi_nav.py
│   ├── mobi_ncx.py
│   ├── mobi_opf.py
│   ├── mobi_pagemap.py
│   ├── mobi_sectioner.py
│   ├── mobi_split.py
│   ├── mobi_uncompress.py
│   ├── mobi_utils.py
│   ├── unipath.py
│   └── unpack_structure.py
├── libgui
│   ├── askfolder_ed.py
│   ├── __init__.py
│   ├── prefs.py
│   └── scrolltextwidget.py
└── README.md
```

这是一个 gui 版本的程序，只需要使用命令相关的功能即可。

```text
$ python kindleunpack/lib/kindleunpack.py --help
KindleUnpack v0.81
   Based on initial mobipocket version Copyright © 2009 Charles M. Hannum <root@ihack.net>
   Extensive Extensions and Improvements Copyright © 2009-2018
       by:  P. Durrant, K. Hendricks, S. Siebert, fandrieu, DiapDealer, nickredding, tkeo.
   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, version 3.
option --help not recognized

Description:
  Unpacks an unencrypted Kindle/MobiPocket ebook to html and images
  or an unencrypted Kindle/Print Replica ebook to PDF and images
  into the specified output folder.
Usage:
  kindleunpack.py -r -s -p apnxfile -d -h --epub_version= infile [outdir]
Options:
    -h                 print this help message
    -i                 use HD Images, if present, to overwrite reduced resolution images
    -s                 split combination mobis into mobi7 and mobi8 ebooks
    -p APNXFILE        path to an .apnx file associated with the azw3 input (optional)
    --epub_version=    specify epub version to unpack to: 2, 3, A (for automatic) or
                         F (force to fit to epub2 definitions), default is 2
    -d                 dump headers and other info to output and extra files
    -r                 write raw data to the output folder
```

以 十分钟冥想.azw3 为例，

```text
$ python kindleunpack/lib/kindleunpack.py -i -s ./十分钟冥想.azw3 ./unpack_output/
```

```text
$ tree ./unpack_output/
unpack_output/
├── HDImages
├── mobi7
│   └── Images
│       ├── cover00128.jpeg
│       ├── image00129.jpeg
│       ├── image00130.jpeg
│       ├── image00131.jpeg
│       ├── image00132.jpeg
│       ├── image00133.jpeg
│       ├── image00134.jpeg
│       ├── image00135.jpeg
│       └── image00136.jpeg
└── mobi8
    ├── 十分钟冥想.epub
    ├── 十分钟冥想.mobi
    ├── META-INF
    │   └── container.xml
    ├── mimetype
    └── OEBPS
        ├── content.opf
        ├── Fonts
        ├── Images
        │   ├── cover00128.jpeg
        │   ├── image00130.jpeg
        │   ├── image00131.jpeg
        │   ├── image00132.jpeg
        │   ├── image00133.jpeg
        │   ├── image00134.jpeg
        │   ├── image00135.jpeg
        │   └── image00136.jpeg
        ├── Styles
        │   ├── style0001.css
        │   └── style0002.css
        ├── Text
        │   ├── cover_page.xhtml
        │   ├── part0000.xhtml
        │   ├── part0001.xhtml
        │   ├── part0002.xhtml
        │   ├── ..............
        │   ├── ..............
        │   ├── ..............
        │   ├── ..............
        │   ├── part0092.xhtml
        │   ├── part0093.xhtml
        │   └── part0094.xhtml
        └── toc.ncx
```

下载安装 kindlegen 工具[^fn:5]，

```text
$ kindlegen

*************************************************************
 Amazon kindlegen(Linux) V2.9 build 1028-0897292
 A command line e-book compiler
 Copyright Amazon.com and its Affiliates 2014
*************************************************************

Usage : kindlegen [filename.opf/.htm/.html/.epub/.zip or directory] [-c0 or -c1 or c2] [-verbose] [-western] [-o <file name>]
Note:
   zip formats are supported for XMDF and FB2 sources
   directory formats are supported for XMDF sources
Options:
   -c0: no compression
   -c1: standard DOC compression
   -c2: Kindle huffdic compression
   -o <file name>: Specifies the output file name. Output file will be created in the same directory as that of input file. <file name> should not contain directory path.
   -verbose: provides more information during ebook conversion
   -western: force build of Windows-1252 book
   -releasenotes: display release notes
   -gif: images are converted to GIF format (no JPEG in the book)
   -locale <locale option> : To display messages in selected language
      en: English
      de: German
      fr: French
      it: Italian
      es: Spanish
      zh: Chinese
      ja: Japanese
      pt: Portuguese
      ru: Russian
      nl: Dutch
```

转换为 mobi，

```text
$ kindlegen unpack_output/mobi8/十分钟冥想.epub -c2 -verbose -o 十分钟冥想.mobi
```

生成文件路径为 `unpack_output/mobi8/十分钟冥想.mobi` 。

用 calibre viewer 打开，可以看到 KF8 的标识，
说明转换成功了。

{{< figure src="images/kf8.png" caption="Figure 2: kf8 标识" >}}

-   部分文件无法转换
-   部分文件转换出乱码


## 配置 calibre 邮件发送 {#配置-calibre-邮件发送}

直接配置

以 qq 邮箱为例

在后台开启 smtp
记住授权码


## License {#license}

{{< license >}}

[^fn:1]: : <http://jdkindle.com/skill/4415/>
[^fn:2]: : <https://zhuanlan.zhihu.com/p/43996780>
[^fn:3]: : <https://www.amazon.cn/gp/help/customer/display.html?nodeId=200767340&ref%5F=pe%5F1825130%5F138612650>
[^fn:4]: : <https://bookfere.com/post/187.html>
[^fn:5]: : <https://bookfere.com/post/92.html>
