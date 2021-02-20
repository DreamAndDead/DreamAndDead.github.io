---
title: How uri match nginx location
date: "2018-05-28T09:10:00Z"
categories:
- Nginx
tags: 
- nginx
- web server
featured_image: images/featured.jpg
aliases:
- /2018/05/28/nginx-location.html
---

location 是 nginx 配置中出现最频繁的配置项，一个 uri 是如何与多个 location 进行匹配的？
在有多个 location 都匹配的情况下，如何决定使用哪一个 location 作为匹配结果？

清晰内部机制之后，疑问自然迎刃而解。

<!--more-->

# location 规则类型

根据[官方文档][nginx doc location]，location 配置语法如下

```
Syntax:   location [ = | ~ | ~* | ^~ ] uri { ... }
          location @name { ... }
Default:  —
Context:  server, location
```

其语法对应了 location 规则的 5 种类型：

## prefix

前缀匹配规则，如果 uri 包含相应的前缀，则匹配成功。

语法上， location 之后单纯跟上 uri，没有任何操作符。

```
location /api/v1 {
    ....
}
```

## exact uri

完全匹配规则，如果 uri 和规则完全相同，则匹配成功。

语法上，使用 = 操作符。

```
location = /api/v1 {
    ....
}
```

## case-sensitive regex

区分大小写的正则表达式匹配规则，如果 uri 与正则表达式相匹配，则匹配成功。
正则表达式使用 [pcre library][pcre lib]，语法和 perl 兼容。

语法上，使用 ~ 操作符。

这里有一个细节，uri 作为一个 string，只要 regex 匹配其中的一部分，即可算作匹配。
比如有如下的规则，

```
location ~ /api/v1 {
    ....
}
```

可以匹配 uri
- /api/v1/login
- /pod/api/v1

如果想要匹配整个 string，则要使用 `^ $`。
比如，

```
location ~ ^/api/v1.*$ {
    ....
}
```

可以匹配 uri
- /api/v1/login

不可以匹配
- /pod/api/v1

## case-insensitive regex

规则同上，区别只在于，正则表达式不区分大小写。
**不**区分大小写的正则表达式匹配规则，如果 uri 与正则表达式相匹配，则匹配成功。

语法上，使用 `~*` 操作符。

```
location ~* /api/v1 {
    ....
}
```

## disable regex prefix

匹配流程与 prefix 规则相同，有一点区别在于，如果最长匹配是当前规则，则之后不进行 正则表达式 规则的搜索。
这一点可能有些难以理解，后面会详细讲解。

语法上，使用 `^~` 操作符。

```
location ^~ /api/v1 {
    ....
}
```

# uri 如何选择 location

前面讲到，location 规则有 5 种类型，那么 uri 如何在多种不同类型的 location 规则之间，
最终选择到唯一的 location 规则呢？

根据[官方文档][nginx doc location]的描述，详细规则如下：

1. 如果存在 exact uri 规则与 uri 匹配，至步骤 6
2. 在所有 prefix 规则和 disable regex prefix 规则中进行匹配（**与这些规则定义的顺序无关**），
   如果没有匹配到规则，至步骤 3；如果存在匹配的规则，选择出最长匹配 uri 的规则：
   - 如果规则是 disable regex prefix 类型，至步骤 6
   - 如果规则是 prefix 类型，记住当前匹配的 prefix 规则，选为待定，至步骤 3
3. 逐个遍历 case-sensitive regex 规则和 case-insensitive regex 规则（**按照这些规则定义的前后顺序**）:
   - 如果规则匹配，则遍历终止，至步骤 6
   - 如果规则没有匹配，则继续
4. 如果之前有 prefix 规则条目被选择为待定，至步骤 6
5. 匹配失败，返回404，结束
6. 选择当前规则，使用其配置，结束

![][how-location-match-uri]

[how-location-match-uri]: http://on7blnbb0.bkt.clouddn.com/18-9-28/21577003.jpg
[how-location-match-uri-xml]: http://on7blnbb0.bkt.clouddn.com/how-location-match-uri-in-nginx.xml


# FAQ

有人可能会困惑，如果 prefix 与 disable regex prefix 规则相同，比如，

```
location /static/ {
    ....
}
location ^~ /static/ {
    ....
}
```

最终会匹配哪一条规则？是否应该继续查找 regex 规则？

实际上，这种情况 nginx 会报错，`nginx: [emerg] duplicate location "/static/" in /etc/nginx/conf.d/location.conf`，
所以这种情况是不用考虑的。

# 示例

示例项目在 [nginx example][nginx example]，
参考 readme 文件，在本地启动 nginx server。


其中对 nginx 的配置如下，使用 curl 进行检测。

{{< gist-it path="DreamAndDead/nginx-example/blob/master/location/conf.d/location.conf" start=0 end=34 >}}

exact uri 规则先于所有规则（与规则定义的顺序无关），所以这里匹配了 `= /` exact uri 规则而不是 `/` prefix 规则。

```
$ curl http://localhost:8080/
uri "/": exact match "location = /"
```

exact uri 规则先于所有规则（与规则定义的顺序无关），所以这里没有匹配 `^~ /static/` disable regex prefix 和 `~* \.PNG$`，`~ \.png$` regex 规则。

正是因为 exact uri 规则的这种属性，如果有高频率使用的 uri，建议使用 exact uri 匹配，加快匹配速度。

```
$ curl http://localhost:8080/static/logo.png
uri "/static/logo.png": exact uri match "location = /static/logo.png"
```

prefix 规则中，匹配 uri 长度最长的规则会选中，所以没有选中 `/` prefix 规则。同样的，从这一点来看，`/api` 和 `/api/` 是不一样的。

```
$ curl http://localhost:8080/api
uri "/api": prefix match "location /api"
$ curl http://localhost:8080/api/
uri "/api/": prefix match "location /api/"
$ curl http://localhost:8080/api/v1
uri "/api/v1": prefix match "location /api/"
```

如果匹配了 `^~ /static/` disable regex prefix 规则，则不再去搜索之后的 regex 规则。

```
$ curl http://localhost:8080/static/thinkpad.png
uri "/static/thinkpad.png": disable regex prefix match "location ^~ /static/"
```

在 regex 规则的匹配中，定义的先后顺序是重要的，所以 `~ \.png$` case-sensitive 规则永远不会被匹配。

```
$ curl http://localhost:8080/files/large.png
uri "/files/large.png": case-insesitive regex match "location ~* \.PNG(dollar)"
$ curl http://localhost:8080/files/large.PNG
uri "/files/large.PNG": case-insesitive regex match "location ~* \.PNG(dollar)"
```

即使先匹配了 `/api/` prefix 规则作为待定，但是也匹配了 regex 规则，优先使用 regex 规则。

```
$ curl http://localhost:8080/api/v1/file/logo.png
uri "/api/v1/file/logo.png": case-insesitive regex match "location ~* \.PNG(dollar)"
```

存在 `/` prefix 规则是有益的，收容所有未明确定位的 uri，再做错误处理。

```
$ curl http://localhost:8080/no-where
uri "/no-where": prefix match "location /"
```

[pcre lib]: https://www.pcre.org/
[nginx doc location]: http://nginx.org/en/docs/http/ngx_http_core_module.html#location
[nginx example]: https://github.com/DreamAndDead/nginx-example
