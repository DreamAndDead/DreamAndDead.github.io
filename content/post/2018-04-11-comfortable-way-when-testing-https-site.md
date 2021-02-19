---
date: "2018-04-11T00:00:00Z"
tags: nginx http https
title: Comfortable way when testing HTTPS site
---

网站初期一直使用http，近期购买了ssl证书，预期将网站全面升级使用https。

当部署https后，居然出现了这种问题...

<!--more-->

从长道来。

# 测试HTTPS

## 部署环境

在线网实施之前，定要先在内部环境进行测试，确保无误。

因为内部有其它服务依赖网站http服务，所以要将http与https同时保留，
于是简单的在nginx配置了https，也保留了http

```nginx
server {
    listen 80;
    listen 443;

    ssl on;
    ssl_certificate /etc/nginx/ssl/domain.crt;
    ssl_certificate_key /etc/nginx/ssl/domain.key;

    location / {
        include proxy_params;
        proxy_pass http://10.28.18.6:8000;
    }
}
```

## 主要问题


有人可能会想，理论上，只是变更协议而已，不会引发什么问题，而实际中，有多种限制。

对于刚迁移到https的网站，最可能出现的问题就是 [mixed content][]


> 简单来说，mixed content是一种安全策略，本着http协议是不安全的前提，浏览器https环境下限制对http资源的引用。

而很多时候，很多静态链接固定写在html中，这样在https环境下加载就会受到限制

详细来说，混合内容（mixed content）分为
- 被动混合内容
- 主动混合内容

假如在https环境下，加载http资源，而所有http资源都可能被黑客从中替换，被动混合内容指的就是即使被恶意替换，也不会
引起过分安全问题的资源，如
- `<img>`
- `<audio>`
- `<video>`
- etc

主动混合内容就是相对可能会引发危险的一类，如
- `<script>`
- `<link>`
- `<iframe>`
- XMLHttpRequest
- fetch()
- etc

详细可参考 [MDN][mixed content]


对于被动混合内容，浏览器会报warning，但不会阻止加载；
而主动混合内容，浏览器则直接阻止加载。

于是，对于一个新迁移https的网站，就有可能出现网站脚本加载不正常，ajax请求没有返回值之类的问题。

## strict mixed-content

对于网站的测试，自然是用更严格的要求，正是取乎其上，得乎其中。

借助[Content-Security-Policy][]其中的[block-all-mixed-content][]规则，禁止所有混合内容的加载。
可以在nginx中，添加response header来实践

```nginx
server {
    listen 80;
    listen 443;

    ssl on;
    ssl_certificate /etc/nginx/ssl/domain.crt;
    ssl_certificate_key /etc/nginx/ssl/domain.key;

    location / {
        include proxy_params;
        proxy_pass http://10.28.18.6:8000;

        add_header Content-Security-Policy block-all-mixed-content;
    }
}
```

## auto secure urls

测试难免会出现有遗漏的情况，如果mixed content的问题被发布到线网，可不是一件开心的事情。

好在[Content-Security-Policy][] 还提供了 [upgrade-insecure-requests][] 选项，
告知浏览器自动将不安全的http url替换为https来访问。

对于庞大的网站，可以不用重改代码，非常方便。
对于我们，可以将其作为线网的配置，为网站的正常使用加保险。
可以在nginx中配置
```nginx
add_header Content-Security-Policy upgrade-insecure-requests;
```

# HSTS

## http failed

目前网站同时开启http与https，
本以为两协议不同，单独访问并不相关，
但是在测试时，加载ajax，出现问题`Response for preflight is invalid (redirect)`

{% include image.html url="response-for-preflight.png" desc="" %}

再观察数据包情况

{% include image.html url="307-internal-redirect.png" desc="" %}


http请求自动重定向为https请求，wired。

响应头中有提到，想必它就是导致问题的原因。
```
Non-Authoritative-Reason: HSTS
```

## what's HSTS

全名HTTP Strict Transport Security，是一种技术，目的是为了用户访问网站的安全。

网站即使部署https，旧有http入口也应当保留，将其合理的引导到更安全的https网站中，
一般情况下使用301重定向。

严格来讲，这是不够安全的，因为到达https需要一次http的引导，而这唯一一次http访问，可能被黑客利用。
这也就是HSTS所解决的问题，服务器设置头Strict-Transport-Security，告知浏览器，只使用https来请求网站，省去了用来引导重定向的http请求，
使访问更加安全。

以weibo示例

- 网站开启https，同时保持旧有http服务入口
- 使用301永久重定向，引导至https
- 第一次的引导，是不可避免的，如果没有HSTS，每一次到达https，都会使用http进行重定向，增加安全风险

```
$ curl -v http://weibo.com
> GET / HTTP/1.1
> Host: weibo.com
> User-Agent: curl/7.47.0
> Accept: */*
> 
< HTTP/1.1 301 Moved Permanently
< Server: WeiBo
< Date: Wed, 11 Apr 2018 00:22:41 GMT
< Content-Type: text/html
< Content-Length: 276
< Connection: keep-alive
< Location: https://weibo.com/
< LB_HEADER: venus50
< 
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html>
<head><title>301 Moved Permanently</title></head>
<body bgcolor="white">
<h1>301 Moved Permanently</h1>
<p>The requested resource has been assigned a new permanent URI.</p>
<hr/>Powered by WeiBo</body>
</html>
```

一旦用户访问了https，HSTS就会发挥作用，设置 Strict-Transport-Security，浏览器缓存HSTS策略，直到过期。
之后所有http的访问，都会由浏览器主动修改为https，避免了重定向这一步
```
$ curl -I https://weibo.com
> GET / HTTP/1.1
> Host: weibo.com
> User-Agent: curl/7.47.0
> Accept: */*
> 
< HTTP/1.1 302 Moved Temporarily
< Server: WeiBo/LB
< Date: Wed, 11 Apr 2018 00:21:38 GMT
< Content-Type: text/html
< Transfer-Encoding: chunked
< Connection: keep-alive
< Expires: Mon, 26 Jul 1997 05:00:00 GMT
< Last-Modified: Wed, 11 Apr 2018 00:21:38 GMT
< Pramga: no-cache
< Content-Security-Policy: block-all-mixed-content;
< Cache-Control: no-cache, no-store
< Location: https://passport.weibo.com/visitor/visitor?entry=miniblog&a=enter&url=https%3A%2F%2Fweibo.com%2F&domain=.weibo.com&ua=php-sso_sdk_client-0.6.23&_rand=1523406098.2996
< DPOOL_HEADER: dagda26
< Set-Cookie: YF-Ugrow-G0=57484c7c1ded49566c905773d5d00f82;Path=/
< LB_HEADER: venus242
< Strict-Transport-Security: max-age=31536000; preload
```

## HSTS works

测试时，访问https是这样的

{% include image.html url="upgrade-insecure-requests.png" desc="" %}

看到来自服务器设置的HSTS

```
Strict-Transport-Security: max-age=31536000
```

浏览器在某个地方保存了这个策略，只需要删除它，就可以临时解决我们的问题。

删除之前，仔细观察数据包，在request头部，有一个之前没出现过的字段

```
Upgrade-Insecure-Requests: 1
```

这个字段和mixed content中的upgrade-insecure-requests很像，但是没有绝对关系。

作为request的字段，
浏览器用来告知服务器，自己倾向于使用更安全的方式来使用服务，
于是在https环境下，服务器设置Strict-Transport-Security。
具体见[stackoverflow][upgrade-insecure-requests-1]


## clear HSTS cache

HSTS有时间周期，在时间内浏览器会应用安全规则。
浏览器可以清理cookie，自然也可以清理HSTS cache

就chrome来说

1. 访问链接 [chrome://net-internals/#hsts](chrome://net-internals/#hsts)
2. 在`Query HSTS/PKP domain`设置里，输入域名进行搜索
3. 在`Delete domain security policies`设置里，输入域名进行删除
4. 再次搜索域名，验证HSTS cache是否已经被删除

firefox删除方法参考[这里][clear hsts cache]

# End

清理cache可以临时解决http不可使用的问题，如果每次都需要清理，过于笨拙，不如直接在nginx层面将HSTS删除（**只在内部测试环境！**）

```nginx
server {
    listen 80;
    listen 443;

    ssl on;
    ssl_certificate /etc/nginx/ssl/domain.crt;
    ssl_certificate_key /etc/nginx/ssl/domain.key;

    location / {
        include proxy_params;
        proxy_pass http://10.28.18.6:8000;

        # strict mixed content rule in test environment
        add_header Content-Security-Policy block-all-mixed-content;
        # no HSTS in test environment
        proxy_hide_header Strict-Transport-Security;
    }
}
```

这里的配置，对于 ssl 的支持有一些瑕疵，在[这篇文章][http https same time]里，做了相关修正。
Remember to check it :)


[mixed content]: https://developer.mozilla.org/en-US/docs/Web/Security/Mixed_content
[Content-Security-Policy]: https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
[block-all-mixed-content]: https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Headers/Content-Security-Policy__by_cnvoid/block-all-mixed-content
[upgrade-insecure-requests]: https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Headers/Content-Security-Policy/upgrade-insecure-requests
[upgrade-insecure-requests-1]: https://stackoverflow.com/questions/31950470/what-is-the-upgrade-insecure-requests-http-header?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa
[clear hsts cache]: https://www.thesslstore.com/blog/clear-hsts-settings-chrome-firefox/
[http https same time]: /2018/05/17/serve-http-https-same-time.html
