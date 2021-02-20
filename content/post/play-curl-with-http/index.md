---
date: "2018-04-09T00:00:00Z"
tags: http curl
title: Play curl with http
---

curl是一款强大的网络传输工具，支持多种协议，在HTTP的支持方面尤其为人称道。
对curl的使用越深入，对HTTP也会有更深的理解。

<!--more-->

# a little http

http是应用层协议，其设计非常简单，灵活。请求与响应是HTTP概念的核心，从本质上讲，
请求与响应也极其简单。更多可参考[HTTP协议原理][]

## 请求报文

通常，一个HTTP请求报文由请求行、请求报头、空行、和请求数据4个部分组成。

{% include image.html url="http-request-format.png" desc="http request format" %}

- 请求行
  - Method：请求方法，如GET，POST
  - URI：请求地址
  - HTTP Version：协议版本
- 请求报头
  - key/value组成的键值对，非常有拓展性
- 请求数据
  - client向server传输的数据

## 响应报文

HTTP的响应报文由状态行、消息报头、空行、响应正文组成。
响应正文是服务器返回的资源的内容。

{% include image.html url="http-response-format.png" desc="http response format" %}

- 状态行
  - HTTP Version：协议版本
  - Status Code： 状态码，常见的如200，404
  - Reason Phrase：状态码的描述，如200对应OK
- 消息报头
  - key/value组成的键值对
- 响应正文
  - server返回client的数据

## 简单示例

访问baidu，观察HTTP协议请求与响应

```
$ curl -v http://baidu.com
> GET / HTTP/1.1
> Host: baidu.com
> User-Agent: curl/7.47.0
> Accept: */*
> 
< HTTP/1.1 200 OK
< Date: Sun, 08 Apr 2018 06:01:23 GMT
< Server: Apache
< Last-Modified: Tue, 12 Jan 2010 13:48:00 GMT
< ETag: "51-47cf7e6ee8400"
< Accept-Ranges: bytes
< Content-Length: 81
< Cache-Control: max-age=86400
< Expires: Mon, 09 Apr 2018 06:01:23 GMT
< Connection: Keep-Alive
< Content-Type: text/html
< 
<html>
<meta http-equiv="refresh" content="0;url=http://www.baidu.com/">
</html>
```

分析请求
- 使用GET Method，请求/ URI，协议版本HTTP/1.1
- 请求报头，键值数据
- 空行
- 没有请求数据

分析响应
- 协议版本HTTP/1.1，状态码200，状态OK
- 消息报头，键值数据
- 空行
- 响应正文：文本数据，以text/html的格式来解析

简单易懂

# play curl

## fetch data

curl最基础的功能，获取url资源，打印到stdout。

这里所输出的内容，只是HTTP响应正文的数据，也通常是我们最关心的

```
$ curl http://baidu.com
<html>
<meta http-equiv="refresh" content="0;url=http://www.baidu.com/">
</html>
```


url内容，可存储于文件（即下载）

可以使用重定向的方式

```
$ curl http://www.baidu.com > baidu.index.html
```

或者使用-o选项

```
$ curl -o manual.html http://www.gnu.org/software/gettext/manual/gettext.html
```


有时url只返回重定向，真正的内容在重定向的链接中

*`-L, --location`，跟随重定向，获取重定向url的内容*

```
$ curl -L http://httpbin.org/redirect-to?url=http://baidu.com
<html>
<meta http-equiv="refresh" content="0;url=http://www.baidu.com/">
</html>
```
有两种重定向方式是浏览器支持而curl不支持的
- html包含meta refresh标签，如`<meta http-equiv="refresh" content="0;url=http://www.baidu.com/">`
- js代码实现重定向



上面输出的都是响应正文，curl也可以输出响应头信息

*`-i, --include`, 将响应头与响应正文一并输出*

```
$ curl -i http://www.example.com
HTTP/1.1 200 OK
Cache-Control: max-age=604800
Content-Type: text/html
Date: Sun, 08 Apr 2018 08:00:09 GMT
Etag: "1541025663+ident"
Expires: Sun, 15 Apr 2018 08:00:09 GMT
Last-Modified: Fri, 09 Aug 2013 23:54:35 GMT
Server: ECS (sjc/4F91)
Vary: Accept-Encoding
X-Cache: HIT
Content-Length: 1270

<!doctype html>
<html>
<head>
    <title>Example Domain</title>

    <meta charset="utf-8" />
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
.................................
.................................
.................................
.................................
.................................
```

使用HEAD Method，只请求响应头。
虽然同样输出了响应头，但是同`-i`的本质不同。

*`-I, --head`, 用HEAD Method进行请求并输出*

```    
$ curl -I http://www.example.com
HTTP/1.1 200 OK
Content-Encoding: gzip
Accept-Ranges: bytes
Cache-Control: max-age=604800
Content-Type: text/html
Date: Sun, 08 Apr 2018 07:59:29 GMT
Etag: "1541025663"
Expires: Sun, 15 Apr 2018 07:59:29 GMT
Last-Modified: Fri, 09 Aug 2013 23:54:35 GMT
Server: ECS (sjc/4E44)
X-Cache: HIT
Content-Length: 606
```

curl还可以提取其它有意思的信息。

*`-w, --write-out <format>`，在一次传输之后，输出其它的信息至stdout。format 可包含\n，\t，变量用%{var_name}标识*

比如，提取响应头的content type
```
$ curl -o $(mktemp) -s -w 'content type is %{content_type}\n' www.baidu.com
content type is text/html
```


常用的变量列表

| var name       | description                                  |
|----------------|----------------------------------------------|
| content_type   | 响应头中的Content-Type                       |
| http_code      | 响应状态码                                   |
| redirect_url   | 没有-L选项时，输出实际重定向的地址           |
| url_effective  | 当使用-L选项，最终重定向所访问的地址                          |
| local_ip       | client ip，此次请求中的客户端IP（IP层）      |
| local_port     | client port，此次请求中的客户端端口（tcp层） |
| remote_ip      | server ip，服务器端IP（IP层）                        |
| remote_port    | server port，服务器端端口（tcp层）                    |
| size_download  | 响应正文的总字节数                           |
| size_upload    | 请求正文的总字节数                                         |
| size_header    | 响应头的总字节数                                      |
| size_request   | 请求头的总字节数                                     |
| time_total     | 传输耗费的总时间                             |
| speed_download | 数据传输的下行速度                           |
| speed_upload   | 上行速度                                     |

## progress bar

如果curl没有将url内容输出到stdout（比如另存为文件），就会输出progress信息到stderr

默认样式如下

```
$ curl -o index.html http://baidu.com
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    81  100    81    0     0     17      0  0:00:04  0:00:04 --:--:--    17
```

可以用`-` `#`组成的progress bar来代替默认样式

```
$ curl -o index.html -# http://baidu.com

######################################################################## 100.0%
```

不显示任何progress信息

*`-s, --silent`, silent mode*

```
$ curl -o index.html -s http://baidu.com
```

## debug

### which interface

多网卡情况下，指定特定网卡进行传输
```
$ curl --interface eth0 http://www.example.com
```

### limit band width

手动限制网络传输速度，借此观察传输情况
```
$ curl --limit-rate 1000B http://www.gnu.org/software/gettext/manual/gettext.html
```

### proxy

使用代理

`-x, --proxy <[protocol://][user:password@]proxyhost[:port]>`

```
$ curl -x socks5://10.27.2.200:2024 http://google.com
```

### dns

自定义域名dns解析的ip地址

`--resolve host:port:address`

当curl访问host:port，host就解析为address，最终访问的地址是address:port。
如果访问的host:port其中一个不对应，则host就不会解析为address

```
$ curl --resolve www.example.com:5000:127.0.0.1 http://www.example.com:5000
# 最终访问的地址是127.0.0.1:5000
```

使用其它dns服务器

```
$ curl --dns-servers 8.8.8.8,1.1.1.1 http://www.example.com
```

    
### verbose

verbose option， 输出HTTP请求与响应交互的所有内容

```
$ curl -v http://www.baidu.com
* Rebuilt URL to: http://www.baidu.com/
*   Trying 14.215.177.39...
* Connected to www.baidu.com (14.215.177.39) port 80 (#0)
> GET / HTTP/1.1
> Host: www.baidu.com
> User-Agent: curl/7.47.0
> Accept: */*
> 
< HTTP/1.1 200 OK
< Server: bfe/1.0.8.18
< Date: Thu, 29 Mar 2018 08:54:41 GMT
< Content-Type: text/html
< Content-Length: 2381
......
......
```

### trace 

trace option, 更加详细地输出HTTP交互的所有内容

*`--trace <file>`，dump所有交互数据*

```
$ curl --trace - http://www.example.com
== Info: Rebuilt URL to: http://www.baidu.com/
== Info:   Trying 14.215.177.38...
== Info: Connected to www.baidu.com (14.215.177.38) port 80 (#0)
=> Send header, 77 bytes (0x4d)
0000: 47 45 54 20 2f 20 48 54 54 50 2f 31 2e 31 0d 0a GET / HTTP/1.1..
0010: 48 6f 73 74 3a 20 77 77 77 2e 62 61 69 64 75 2e Host: www.baidu.
.........................
.........................
```

*`--trace-ascii <file>`，不显示hex部分*

```
$ curl --trace-ascii - http://www.example.com
== Info: Rebuilt URL to: http://www.example.com/
== Info:   Trying 93.184.216.34...
== Info: Connected to www.example.com (93.184.216.34) port 80 (#0)
=> Send header, 79 bytes (0x4f)
0000: GET / HTTP/1.1
0010: Host: www.example.com
0027: User-Agent: curl/7.47.0
.........................
.........................
```

*`--trace-time`，同`-v/--trace`一起使用，打印出每一行trace的时间戳*

```
$ curl -v --trace-time http://www.example.com
15:44:37.251685 * Rebuilt URL to: http://www.example.com/
15:44:37.524262 * Connected to www.example.com (93.184.216.34) port 80 (#0)
15:44:37.524415 > GET / HTTP/1.1
15:44:37.524415 > Host: www.example.com
................
................
```

## custom headers

### referer

referer代表的意思是，当前请求是从哪一个页面链接过来。
一些网站用此来判断来自外部网站的链接，进行防盗链的保护

*`-e, --referer`，修改请求头referer字段*

```
$ curl --referer http://www.I.come http://httpbin.org/get
{
  "args": {}, 
  "headers": {
    "Accept": "*/*", 
    "Connection": "close", 
    "Host": "httpbin.org", 
    "Referer": "http://www.I.come", 
    "User-Agent": "curl/7.47.0"
  }, 
  "origin": "121.35.211.97", 
  "url": "http://httpbin.org/get"
}
```

### user agent

user agent在HTTP头部中，标识浏览器类型，修改此header可以隐藏真实浏览器的类型

*`--user-agent`，修改user-agent头部*

将curl扮演为Internet Explorer 5
```
$ curl --user-agent "Mozilla/4.0 (compatible; MSIE 5.01; Windows NT 5.0)" http://httpbin.org/get
{
  "args": {}, 
  "headers": {
    "Accept": "*/*", 
    "Connection": "close", 
    "Host": "httpbin.org", 
    "User-Agent": "Mozilla/4.0 (compatible; MSIE 5.01; Windows NT 5.0)"
  }, 
  "origin": "121.35.211.97", 
  "url": "http://httpbin.org/get"
}
```

### cookie

自定义要传输的cookie

*`--cookie [<file>]`，设置传输cookie*

```
$ curl --cookie "name=Daniel" http://httpbin.org/get
{
  "args": {}, 
  "headers": {
    "Accept": "*/*", 
    "Connection": "close", 
    "Cookie": "name=Daniel", 
    "Host": "httpbin.org", 
    "User-Agent": "curl/7.47.0"
  }, 
  "origin": "121.35.211.97", 
  "url": "http://httpbin.org/get"
}
```

一般自定义cookie的情况是很少的，通常由服务器设置cookie，浏览器每次连接都带上所设置的cookie，用于标识session

*`--cookie-jar <file>`，存储cookie至文件*

```    
$ curl --cookie-jar cookies.txt http://httpbin.org/cookies/set?from=httpbin
$ cat cookies.txt 
# Netscape HTTP Cookie File
# http://curl.haxx.se/docs/http-cookies.html
# This file was generated by libcurl! Edit at your own risk.

httpbin.org     FALSE   /       FALSE   0       from    httpbin
$ curl --cookie cookies.txt http://httpbin.org/get
{
  "args": {}, 
  "headers": {
    "Accept": "*/*", 
    "Connection": "close", 
    "Cookie": "from=httpbin", 
    "Host": "httpbin.org", 
    "User-Agent": "curl/7.47.0"
  }, 
  "origin": "121.35.211.97", 
  "url": "http://httpbin.org/get"
}
```

### all in one

可以设置所有header，包括上面提到的几种，是万能的方法。

*`-H, --header`，设置HTTP请求头信息，可同时设置多个*

自定义数据类型为json
```
$ curl -H "Content-type: application/json" -H "Accept: application/json" --data '{"user": "who"}' http://httpbin.org/post
{
  "args": {}, 
  "data": "{\"user\": \"who\"}", 
  "files": {}, 
  "form": {}, 
  "headers": {
    "Accept": "application/json", 
    "Connection": "close", 
    "Content-Length": "15", 
    "Content-Type": "application/json", 
    "Host": "httpbin.org", 
    "User-Agent": "curl/7.47.0"
  }, 
  "json": {
    "user": "who"
  }, 
  "origin": "121.35.211.97", 
  "url": "http://httpbin.org/post"
}
```

## RESTful api

通常RESTful api使用POST，DELETE，GET，PUT Method代表增删查改，四种对资源的操作。

每种操作都可以携带参数，
参数可以通过两种方式传递
- query： 一般在URI之后，以key=value的形式组织，多个用&相连接
- body： HTTP请求报文的数据部分，参数可组织为任何形式，服务器通过Content-Type来解读参数

通常情况下
- 四种Method都可以使用query传递参数
- POST，PUT，DELETE可以使用body传递参数，GET不使用body
- query，body两种方式可以同时使用

### POST

#### post with body

*`-d, --data`, 默认使用POST Method，Content-type=application/x-www-form-urlencoded，进行HTTP请求*

```
$ curl --data 'tool=curl' --data 'os=linux' http://httpbin.org/post
{
  "args": {}, 
  "data": "", 
  "files": {}, 
  "form": {
    "os": "linux", 
    "tool": "curl"
  }, 
  "headers": {
    "Accept": "*/*", 
    "Connection": "close", 
    "Content-Length": "18", 
    "Content-Type": "application/x-www-form-urlencoded", 
    "Host": "httpbin.org", 
    "User-Agent": "curl/7.58.0"
  }, 
  "json": null, 
  "origin": "183.240.202.4", 
  "url": "http://httpbin.org/post"
}
```

`--data`不会对数据进行url encode，如果传递的参数为`tool=curl and linux`，其中的空格就需要url encode为%20，
再进行请求。
好在curl提供了`--data-urlencode`选项来帮助我们做这件事

*`--data-urlencode`，与`--data`功能相似，对value进行url encode，再进行传输。
当Content-Type=application/x-www-form-urlencoded，推荐使用此选项*

```
$ curl --data-urlencode 'tool=curl and linux' http://httpbin.org/post
{
  "args": {}, 
  "data": "", 
  "files": {}, 
  "form": {
    "tool": "curl and linux"
  }, 
  "headers": {
    "Accept": "*/*", 
    "Connection": "close", 
    "Content-Length": "23", 
    "Content-Type": "application/x-www-form-urlencoded", 
    "Host": "httpbin.org", 
    "User-Agent": "curl/7.58.0"
  }, 
  "json": null, 
  "origin": "183.240.202.4", 
  "url": "http://httpbin.org/post"
}
```

#### different content type

Content-Type的意义在于
- 对于client，form数据用哪一种方式存储到请求body中
- 对于server，取到请求body的时候，如何解读其中的数据

当Content-Type=application/x-www-form-urlencoded，所有key/value数据组织为类似url query的形式
- 以key=value存储，并进行url encode
- 多个key=value用&来连接

如果用来传输二进制文件，对所有非alphanumeric字符进行url encode编码，单字节需要用三个字节来存储，效率非常低。
于是标准提出了新的Content-Type，multipart/form-data，来解决这个问题。更多可参考[form-urlencode-or-form-data][]

具体两种方式的存储方式有什么区别，我们用`--trace`来看清楚

application/x-www-form-urlencoded，参数以类似query的形式，存储在body中，POST到服务器

```
$ curl --trace - --data 'tool=curl' --data 'os=linux' http://httpbin.org/post
................
................
=> Send header, 149 bytes (0x95)
0000: 50 4f 53 54 20 2f 70 6f 73 74 20 48 54 54 50 2f POST /post HTTP/
0010: 31 2e 31 0d 0a 48 6f 73 74 3a 20 68 74 74 70 62 1.1..Host: httpb
0020: 69 6e 2e 6f 72 67 0d 0a 55 73 65 72 2d 41 67 65 in.org..User-Age
0030: 6e 74 3a 20 63 75 72 6c 2f 37 2e 34 37 2e 30 0d nt: curl/7.47.0.
0040: 0a 41 63 63 65 70 74 3a 20 2a 2f 2a 0d 0a 43 6f .Accept: */*..Co
0050: 6e 74 65 6e 74 2d 4c 65 6e 67 74 68 3a 20 31 38 ntent-Length: 18
0060: 0d 0a 43 6f 6e 74 65 6e 74 2d 54 79 70 65 3a 20 ..Content-Type: 
0070: 61 70 70 6c 69 63 61 74 69 6f 6e 2f 78 2d 77 77 application/x-ww
0080: 77 2d 66 6f 72 6d 2d 75 72 6c 65 6e 63 6f 64 65 w-form-urlencode
0090: 64 0d 0a 0d 0a                                  d....
=> Send data, 18 bytes (0x12)
0000: 74 6f 6f 6c 3d 63 75 72 6c 26 6f 73 3d 6c 69 6e tool=curl&os=lin
0010: 75 78                                           ux
== Info: upload completely sent off: 18 out of 18 bytes
................
................
{
  "args": {}, 
  "data": "", 
  "files": {}, 
  "form": {
    "os": "linux", 
    "tool": "curl"
  }, 
  "headers": {
    "Accept": "*/*", 
    "Connection": "close", 
    "Content-Length": "18", 
    "Content-Type": "application/x-www-form-urlencoded", 
    "Host": "httpbin.org", 
    "User-Agent": "curl/7.47.0"
  }, 
  "json": null, 
  "origin": "121.35.211.97", 
  "url": "http://httpbin.org/post"
}
```

multipart/form-data则使用了不同的方式，其中定义一个boundary，所有form字段以
boundary分隔开来，每一段都有`Content-Disposition`，`name`头部，内容不进行url encode处理

```
$ curl --trace - --form 'tool=curl' --form 'os=linux' http://httpbin.org/post
................
................
0000: 50 4f 53 54 20 2f 70 6f 73 74 20 48 54 54 50 2f POST /post HTTP/
0010: 31 2e 31 0d 0a 48 6f 73 74 3a 20 68 74 74 70 62 1.1..Host: httpb
0020: 69 6e 2e 6f 72 67 0d 0a 55 73 65 72 2d 41 67 65 in.org..User-Age
0030: 6e 74 3a 20 63 75 72 6c 2f 37 2e 34 37 2e 30 0d nt: curl/7.47.0.
0040: 0a 41 63 63 65 70 74 3a 20 2a 2f 2a 0d 0a 43 6f .Accept: */*..Co
0050: 6e 74 65 6e 74 2d 4c 65 6e 67 74 68 3a 20 32 33 ntent-Length: 23
0060: 39 0d 0a 45 78 70 65 63 74 3a 20 31 30 30 2d 63 9..Expect: 100-c
0070: 6f 6e 74 69 6e 75 65 0d 0a 43 6f 6e 74 65 6e 74 ontinue..Content
0080: 2d 54 79 70 65 3a 20 6d 75 6c 74 69 70 61 72 74 -Type: multipart
0090: 2f 66 6f 72 6d 2d 64 61 74 61 3b 20 62 6f 75 6e /form-data; boun
00a0: 64 61 72 79 3d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d dary=-----------
00b0: 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 38 30 30 -------------800
00c0: 66 32 31 62 37 32 65 33 38 35 30 30 39 0d 0a 0d f21b72e385009...
00d0: 0a                                              .
=> Send data, 239 bytes (0xef)
0000: 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d ----------------
0010: 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 38 30 30 66 32 31 ----------800f21
0020: 62 37 32 65 33 38 35 30 30 39 0d 0a 43 6f 6e 74 b72e385009..Cont
0030: 65 6e 74 2d 44 69 73 70 6f 73 69 74 69 6f 6e 3a ent-Disposition:
0040: 20 66 6f 72 6d 2d 64 61 74 61 3b 20 6e 61 6d 65  form-data; name
0050: 3d 22 74 6f 6f 6c 22 0d 0a 0d 0a 63 75 72 6c 0d ="tool"....curl.
0060: 0a 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d .---------------
0070: 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 38 30 30 66 32 -----------800f2
0080: 31 62 37 32 65 33 38 35 30 30 39 0d 0a 43 6f 6e 1b72e385009..Con
0090: 74 65 6e 74 2d 44 69 73 70 6f 73 69 74 69 6f 6e tent-Disposition
00a0: 3a 20 66 6f 72 6d 2d 64 61 74 61 3b 20 6e 61 6d : form-data; nam
00b0: 65 3d 22 6f 73 22 0d 0a 0d 0a 6c 69 6e 75 78 0d e="os"....linux.
00c0: 0a 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d .---------------
00d0: 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 2d 38 30 30 66 32 -----------800f2
00e0: 31 62 37 32 65 33 38 35 30 30 39 2d 2d 0d 0a    1b72e385009--..
......................
......................
......................
{
  "args": {}, 
  "data": "", 
  "files": {}, 
  "form": {
    "os": "linux", 
    "tool": "curl"
  }, 
  "headers": {
    "Accept": "*/*", 
    "Connection": "close", 
    "Content-Length": "239", 
    "Content-Type": "multipart/form-data; boundary=------------------------800f21b72e385009", 
    "Expect": "100-continue", 
    "Host": "httpbin.org", 
    "User-Agent": "curl/7.47.0"
  }, 
  "json": null, 
  "origin": "121.35.211.97", 
  "url": "http://httpbin.org/post"
}

```

#### upload file

利用Content-Type=multipart/form-data，上传文件

*`-F, --form`，默认以Content-Type=multipart/form-data，POST Method进行HTTP请求。`--data`不支持文件上传，
`--form`可以用`@<filename>`进行文件上传*

```
$ curl --form source=@test.c --form lang=c http://httpbin.org/post
{
  "args": {}, 
  "data": "", 
  "files": {
    "source": "#include <stdio.h>\n\nint main(void) {\n    return 0;\n}\n"
  }, 
  "form": {
    "lang": "c"
  }, 
  "headers": {
    "Accept": "*/*", 
    "Connection": "close", 
    "Content-Length": "347", 
    "Content-Type": "multipart/form-data; boundary=------------------------5c6f4eef4965c408", 
    "Host": "httpbin.org", 
    "User-Agent": "curl/7.58.0"
  }, 
  "json": null, 
  "origin": "183.240.198.140", 
  "url": "http://httpbin.org/post"
}
```

上传文件时，可以同时标明文件MIME，供服务器参考

```
$ curl --form "page=@index.html;type=text/html" http://httpbin.org/post
{
  "args": {}, 
  "data": "", 
  "files": {
    "page": "<html>\n<meta http-equiv=\"refresh\" content=\"0;url=http://www.baidu.com/\">\n</html>\n"
  }, 
  "form": {}, 
  "headers": {
    "Accept": "*/*", 
    "Connection": "close", 
    "Content-Length": "268", 
    "Content-Type": "multipart/form-data; boundary=------------------------c3339e8e79db4cb4", 
    "Host": "httpbin.org", 
    "User-Agent": "curl/7.58.0"
  }, 
  "json": null, 
  "origin": "183.240.202.4", 
  "url": "http://httpbin.org/post"
}
```

#### post with query

如果POST想使用query来传递参数，必须自己手动输入在URI之后，curl没有选项来做这一件事。
POST使用query的麻烦之处在于，要求我们注意URL的编码

```
$ curl --data-urlencode 'tool=curl and linux' http://httpbin.org/post?reverse%20order=linux%20and%20curl
{
  "args": {
    "reverse order": "linux and curl"
  }, 
  "data": "", 
  "files": {}, 
  "form": {
    "tool": "curl and linux"
  }, 
  "headers": {
    "Accept": "*/*", 
    "Connection": "close", 
    "Content-Length": "23", 
    "Content-Type": "application/x-www-form-urlencoded", 
    "Host": "httpbin.org", 
    "User-Agent": "curl/7.47.0"
  }, 
  "json": null, 
  "origin": "121.35.211.97", 
  "url": "http://httpbin.org/post?reverse order=linux and curl"
}
```

可以使用其它辅助命令来帮助我们做url encode。

urlencode命令来自于包 gridsite-clients，或者使用[其它相同功能的工具][urlencode methods]

```
$ curl --data-urlencode 'tool=curl and linux' http://httpbin.org/post?$(urlencode 'reverse order')=$(urlencode 'linux and curl')
{
  "args": {
    "reverse order": "linux and curl"
  }, 
  "data": "", 
  "files": {}, 
  "form": {
    "tool": "curl and linux"
  }, 
  "headers": {
    "Accept": "*/*", 
    "Connection": "close", 
    "Content-Length": "23", 
    "Content-Type": "application/x-www-form-urlencoded", 
    "Host": "httpbin.org", 
    "User-Agent": "curl/7.47.0"
  }, 
  "json": null, 
  "origin": "121.35.211.97", 
  "url": "http://httpbin.org/post?reverse order=linux and curl"
}
```

### PUT

PUT与POST相似，只不过Method不同

*`-X Method`，指定curl请求所使用的方法*

application/x-www-form-urlencoded示例
```
$ curl -X PUT --data 'tool=curl' --data 'os=linux' http://httpbin.org/put
{
  "args": {}, 
  "data": "", 
  "files": {}, 
  "form": {
    "os": "linux", 
    "tool": "curl"
  }, 
  "headers": {
    "Accept": "*/*", 
    "Connection": "close", 
    "Content-Length": "18", 
    "Content-Type": "application/x-www-form-urlencoded", 
    "Host": "httpbin.org", 
    "User-Agent": "curl/7.47.0"
  }, 
  "json": null, 
  "origin": "121.35.211.97", 
  "url": "http://httpbin.org/put"
}
```

multipart/form-data示例
```
$ curl -X PUT --form source=@test.c --form lang=c http://httpbin.org/put
{
  "args": {}, 
  "data": "", 
  "files": {
    "source": "#include <stdio.h>\n\nint main(void) {\n    return 0;\n}\n"
  }, 
  "form": {
    "lang": "c"
  }, 
  "headers": {
    "Accept": "*/*", 
    "Connection": "close", 
    "Content-Length": "347", 
    "Content-Type": "multipart/form-data; boundary=------------------------e73fa892cfebd218", 
    "Expect": "100-continue", 
    "Host": "httpbin.org", 
    "User-Agent": "curl/7.47.0"
  }, 
  "json": null, 
  "origin": "121.35.211.97", 
  "url": "http://httpbin.org/put"
}   
```

### DELETE

DELETE同POST，PUT，只是Method不同。
使用`-X DELETE`即可

### GET

GET只使用query来传递参数

*`-G, --get`，这个选项会使所有`-d, --data, --data-urlencode`的数据附加在URL之后作为query，而不是POST body，默认使用GET Method*
        
参考[curl url param][]

```
$ curl -G --data-urlencode 'tool=curl and linux' http://httpbin.org/get
{
  "args": {
    "tool": "curl and linux"
  }, 
  "headers": {
    "Accept": "*/*", 
    "Connection": "close", 
    "Host": "httpbin.org", 
    "User-Agent": "curl/7.47.0"
  }, 
  "origin": "121.35.211.97", 
  "url": "http://httpbin.org/get?tool=curl and linux"
}
```

### JSON

通常使用RESTful api，配合使用的Content-Type都为application/json。
结合自定义header的功能，修改Content-Type，用json进行C/S交互

```
$ curl -H "Content-type: application/json" -H "Accept: application/json" --data '{"tool": "curl", "os": "linux"}' http://httpbin.org/post
{
  "args": {}, 
  "data": "{\"tool\": \"curl\", \"os\": \"linux\"}", 
  "files": {}, 
  "form": {}, 
  "headers": {
    "Accept": "application/json", 
    "Connection": "close", 
    "Content-Length": "31", 
    "Content-Type": "application/json", 
    "Host": "httpbin.org", 
    "User-Agent": "curl/7.47.0"
  }, 
  "json": {
    "os": "linux", 
    "tool": "curl"
  }, 
  "origin": "121.35.211.97", 
  "url": "http://httpbin.org/post"
}
```

# more help

command line
```
$ man curl
$ curl --help
$ curl --manual
```

[curl docs online][]


[HTTP协议原理]: http://liuwangshu.cn/application/network/1-http.html
[curl docs online]: https://curl.haxx.se/docs/httpscripting.html
[form-urlencode-or-form-data]: https://stackoverflow.com/questions/4007969/application-x-www-form-urlencoded-or-multipart-form-data
[urlencode methods]: https://stackoverflow.com/questions/296536/how-to-urlencode-data-for-curl-command
[curl url param]: https://stackoverflow.com/a/14284519/9167165
