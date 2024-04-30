---
type: card
created: 2024-04-11T17:47
tags:
- blog
- hugo
---

默认hugo serve的cache和生成hugo site的目录相同，为 public
目前将vault和hugo集成在一起，重新生成 public 复制了static图片，导致内部链接出现问题

直接将cache目录放在vault外

```sh
$ hugo serve -D -d ../hugo-cache
```