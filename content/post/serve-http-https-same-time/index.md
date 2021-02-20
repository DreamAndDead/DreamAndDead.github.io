---
title: Serve http and https at same time with nginx
date: "2018-05-17T14:30:00Z"
categories:
- Nginx
tags: 
- nginx
- trouble-shooting
- http
- https
featured_image: images/featured.jpg
aliases:
- /2018/05/17/serve-http-https-same-time.html
---

之前讨论过，[网站从http迁移到https时，需要注意些什么][tips when migrate to https]。
由于旧有的服务依旧在运行，需要同时保留http与https。
突然有一天，访问http服务，页面上只出现nginx的错误信息：

```
400 bad request the plain http request was sent to https port
```

<!--more-->

这让我觉得非常奇怪，按照之前的理解，这样设置应该是没有问题的。

```nginx
server {
    listen 80;
    listen 443;

    ssl on;
    ssl_certificate /etc/nginx/ssl/domain.crt;
    ssl_certificate_key /etc/nginx/ssl/domain.key;

    .........
    .........
    .........
}
```

后来按照错误信息进行一番搜索，还是漏掉了一些细节。


# trouble shoot

从 [stackoverflow](https://stackoverflow.com/questions/8768946/dealing-with-nginx-400-the-plain-http-request-was-sent-to-https-port-error) 上搜索得到的结果，
发现自己对于 ssl 的配置理解还不够充分。

一般在nginx配置中，ssl 可能出现在两个地方
- 在 listen 指令之后，作为参数
- 在 server 块下，作为指令，参数为 on/off

对于 ssl 指令，[官方文档][ssl directive] 已经不推荐使用，而是推荐使用 listen 指令加 ssl 参数的格式。

listen 指令的 [ssl 参数][listen ssl] 的作用是，标明 listen 的端口应该运行 ssl 模式。
同时托管 http 与 https时，推荐[使用如下配置][http https config]：

```nginx
server {
    listen 80;
    listen 443 ssl;

    ssl off;
    ssl_certificate /etc/nginx/ssl/domain.crt;
    ssl_certificate_key /etc/nginx/ssl/domain.key;

    .........
    .........
    .........
}
```

所以问题的核心就在于，指令 `ssl on`，将所有 listen 的端口，都运行在 ssl 模式，但是对于端口 80，
这样明显是不对的，也就导致了最开始的报错信息。

```
400 bad request the plain http request was sent to https port
```

这时就推荐使用 listen 加 ssl 参数，更细粒度的控制哪些端口运行在 ssl 模式下。


[tips when migrate to https]: /2018/04/11/comfortable-way-when-testing-https-site.html
[ssl directive]: http://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl
[listen ssl]: http://nginx.org/en/docs/http/ngx_http_core_module.html#listen
[http https config]: http://nginx.org/en/docs/http/configuring_https_servers.html#single_http_https_server

