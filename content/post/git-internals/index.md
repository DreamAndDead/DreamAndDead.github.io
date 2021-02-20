---
date: "2018-01-03T00:00:00Z"
tags: git
title: Git Internals
---

这篇文章旨在介绍git的关键概念与内部存储形式，相比对git的使用，关注的重点更底层。

所有示例使用git版本 2.7.4，
示例仓库可见于github: [https://github.com/DreamAndDead/git-internals-example](https://github.com/DreamAndDead/git-internals-example)

<!--more-->

# .git folder

git仓库所有数据都存储在工作区目录的.git文件夹

在空目录，init初始化仓库

```
mkdir git-internals-example
cd git-internals-example
git init
```

.git/结构如下

```
.git/
 ├── branches/
 ├── config
 ├── description
 ├── HEAD
 ├── hooks/
 │   ├── applypatch-msg.sample
 │   ├── commit-msg.sample
 │   ├── post-update.sample
 │   ├── pre-applypatch.sample
 │   ├── pre-commit.sample
 │   ├── prepare-commit-msg.sample
 │   ├── pre-push.sample
 │   ├── pre-rebase.sample
 │   └── update.sample
 ├── info/
 │   └── exclude
 ├── objects/
 │   ├── info/
 │   └── pack/
 └── refs/
     ├── heads/
     └── tags/
```

- branches/ TODO，暂时不清楚
- config 本地仓库配置
- description 只用于gitweb
- *HEAD 标识当前所在commit*
- hooks/ git钩子
- info/ 目前只有exclude文件，效果同.gitignore
- *objects/ 存储对象*
- *refs/ 引用*

标注的条目，是本文主要关注的

# key objects

git有4类关键对象，它们是git设计的核心。

层次由低到高为blob，tree，commit，tag，它们都以文件的形式存储在.git目录下。

git命令分为两类，高层(porcelain)命令与底层(plumbing)命令。

高层命令是我们通常使用
git时使用的命令如add，commit等，底层命令则不常用。高层命令完成的操作是由一系列底层
命令协作完成的。底层命令的操作内容更简单，更专一，每个关键对象，都有对应的底层命令。


## blob

最简单的理解，一个blob对应于一个文件，将一个文件压缩存储便是一个blob。

没有高层命令只用于生成blob，而有相应的底层命令来做这件事，hash-object。

- 在工作区新建makefile文件，内容是一行注释。
- hash-object以文件为参数，-w 写入blob。
  返回值是一个哈希值，ce616eb8c060404bb253822921a12aab81ed1ae0

```
$ echo '# makefile' > makefile
$ git hash-object -w makefile
ce616eb8c060404bb253822921a12aab81ed1ae0
```

- blob存储在.git/objects/，哈希值前两个字符为子文件夹名，后续字符为文件名。

```
$ find .git/objects -type f
.git/objects/ce/616eb8c060404bb253822921a12aab81ed1ae0
```

- git用zlib压缩文件生成blob，直接查看blob文件是乱码。
- git有相应的底层命令查看对象，cat-file，-p means pretty，参数为哈希值而不是blob文件路径。
  这里输出的就是makefile文件的内容。

```
$ cat .git/objects/ce/616eb8c060404bb253822921a12aab81ed1ae0
.....messive output....
$ git cat-file -p ce616eb8c060404bb253822921a12aab81ed1ae0
# makefile
```

- blob是压缩过的文件，自然可以解压缩。
  pigz命令针对zlib进行压缩与解压缩，-d means解压缩。
  hexdump -C 以单字节解码，以16进制标识地址。

```
$ pigz -d < .git/objects/ce/616eb8c060404bb253822921a12aab81ed1ae0 | hexdump -c
00000000  62 6c 6f 62 20 31 31 00  23 20 6d 61 6b 65 66 69  |blob 11.# makefi|
00000010  6c 65 0a                                          |le.|
00000013
```

从hexdump输出，可以清楚的看到blob中不只存储了文件内容，还附加了其它一些信息。

blob解压后内容，字节由前至后：
- 4byte：blob 4个字符
- 1byte：空格
- 未知byte：解析为10进制数字，表示原文件内容的字节长度
- 1byte：\0
- 剩余byte：原文件内容

那么blob文件名是如何生成的呢？看起来像是随机的一串字符，实际是用SHA1哈希算法生成的。
算法的输入就是blob解压的内容。

```
$ pigz -d < .git/objects/ce/616eb8c060404bb253822921a12aab81ed1ae0 | sha1sum
ce616eb8c060404bb253822921a12aab81ed1ae0  -
```

由此blob生成的过程就非常清晰：
- 读取文件内容，计算内容字节长度
- "blob"，字节长度信息，文件内容，组合为blob原始内容
- 计算SHA1哈希值
- 以哈希值前2个字符与剩余字符为名称，在.git/objects/下新建文件夹与文件
- 将原始内容用zlib压缩，存储路径为上一步的文件路径

## tree
   
blob只存储内容信息，那么文件名信息存储在哪里呢？如果只有blob对象，文件名是肯定找不到的，
事实上它们存储在tree对象中。

形象的比喻，如果blob代表文件，tree就代表文件夹。文件夹包含子文件夹与其它文件，同样的，
tree对象也“包含”其它tree对象与其它blob。

因为tree对象是由git index暂存区的内容生成的，在深入tree对象之前，先了解下index暂存区

### index
   
index默认存储于.git/index文件，git init并没有生成它。添加文件到暂存区时，git才会生成
.git/index并存储暂存区内容。

- 借助git高层命令add，将makefile加入index
- 用hexdump查看index内容

```
$ git add makefile
$ hexdump -C .git/index
00000000  44 49 52 43 00 00 00 02  00 00 00 01 5a 4c 75 73  |DIRC........ZLus|
00000010  21 0f 5c 21 5a 4c 75 73  21 0f 5c 21 00 00 08 0b  |!.\!ZLus!.\!....|
00000020  00 50 34 54 00 00 81 a4  00 00 03 e8 00 00 03 e8  |.P4T............|
00000030  00 00 00 0b ce 61 6e b8  c0 60 40 4b b2 53 82 29  |.....an..`@K.S.)|
00000040  21 a1 2a ab 81 ed 1a e0  00 08 6d 61 6b 65 66 69  |!.*.......makefi|
00000050  6c 65 00 00 38 0a 9e 35  0e c7 cb c0 4d 17 b6 06  |le..8..5....M...|
00000060  06 f1 3d 84 2f e4 c9 13                           |..=./...|
00000068
```

index文件没有被压缩，以2进制存储，网络字节序。
具体分析其内容，需要借助[官方文档](https://github.com/git/git/blob/v2.7.4/Documentation/technical/index-format.txt)。

针对目前index的内容，用下面的表格来解读：

| 行\列 | 0                                 | 4              | 8                           | c             |
|-------|-----------------------------------|----------------|-----------------------------|---------------|
|    00 | DIRC                              | version        | index entries number        | ctime seconds |
|    10 | ctime nanosecond fractions        | mtime seconds  | mtime nanosecond fractions  | dev           |
|    20 | ino                               | mode           | uid                         | gid           |
|    30 | file size                         | entry SHA1.... | ....                        | ....          |
|    40 | ....                              | ....           | flags(2 byte)  entry path.. | ....          |
|    50 | .. padding to multiple of 8 bytes | index SHA1.... | ....                        | ....          |
|    60 | ....                              | ....           |                             |               |

- 00，0： DIRC，4个字符，标识文件类型
- 00，4： index格式版本，可取2，3，4。00 00 00 02， 当前版本为2
- 00，8： index entries number，index存储条目的数量。00 00 00 01， 只有一条index entry，是上面添加的
          makefile。此后的所有字节都由index entry组成
- index entry:
  - 00，c： ctime，通过stat -c "%z" makefile获得其10进制表示。 5a 4c 75 73，转换为10进制并用date解析，date --date="@$(printf "%d" "0x5a4c7573")"
  - 10，0： ctime精确到微秒
  - 10，4： mtime，通过stat -c "%w" makefile获得其10进制表示。计算同上
  - 10，8： mtime精确到微秒
  - 10，c： device number，通过stat -c "%d" makefile获得其10进制表示
  - 20，0： inode number，通过stat -c "%i" makefile获得其10进制表示
  - 20，4： 文件类型与权限。占用32bit，只需解读后16bit。 81 a4 => 1000 0001 1010 0100，前4bit 1000代表文件为regular file，其后3bit不使用，最后9bit
           代表文件权限 110 100 100 => 0644
  - 20，8： uid，state -c "%u" makefile获得其10进制表示
  - 20，c： gid，state -c "%g" makefile获得其10进制表示
  - 30，0： file size，state -c "%s" makefile获得其10进制表示， 00 00 00 0b => 11，正是blob所存储的
  - 30，4 - 40，4： blob SHA1，和blob一节计算的相同，ce616eb8c060404bb253822921a12aab81ed1ae0
  - 40，8： flags，16bit， 00 08 => 0000 1000
    - 1bit，assume valid flag (? TODO)
    - 1bit，版本2中一定为0
    - 2bit，stage (during merge) (? TODO) 
    - 12bit，16进制数，表示文件名长度。08 => 8，m a k e f i l e
  - 40，8 - 50，0： file name，从40，8的后16bit开始，存储文件名。最后部分用00 byte补齐为8 byte倍数
  - 50，4 - last： index SHA1，对index已经存储的内容计算SHA1，并附加到index最后。 head -c -20 .git/index | sha1sum 计算得 
                   380a9e350ec7cbc04d17b60606f13d842fe4c913
  
index内存储了相当多的除了文件内容外，关于文件的其它信息。
后续tree对象的生成，信息都是从这里提取。

### tree object

了解index以后，回到tree对象来。

- 使用git底层命令，write-tree，由当前index生成tree对象
- tree对象和blob相同，也存储在objects目录下
- cat-file查看tree对象，显示blob信息

```
$ git write-tree
5e35decc375ba1d3d14511b6341f2827943aa42f
$ find .git/objects -type f
.git/objects/5e/35decc375ba1d3d14511b6341f2827943aa42f
.git/objects/ce/616eb8c060404bb253822921a12aab81ed1ae0
$ git cat-file -p 5e35decc375ba1d3d14511b6341f2827943aa42f
100644 blob ce616eb8c060404bb253822921a12aab81ed1ae0    makefile
```

tree对象存储了什么内容呢？
- 其它tree对象也使用zlib压缩存储，解压来看内容

```
$ pigz -d < .git/objects/5e/35decc375ba1d3d14511b6341f2827943aa42f | hexdump -C
00000000  74 72 65 65 20 33 36 00  31 30 30 36 34 34 20 6d  |tree 36.100644 m|
00000010  61 6b 65 66 69 6c 65 00  ce 61 6e b8 c0 60 40 4b  |akefile..an..`@K|
00000020  b2 53 82 29 21 a1 2a ab  81 ed 1a e0              |.S.)!.*.....|
0000002c
```

- 4byte： tree，4个字符
- 1byte： 空格
- 未知byte： 解读为10进制数，这里为36，表示tree字节内容长度为36
- 1byte： \0。之后所有字节为tree对象内容
- 6byte： 100644代表blob
- 1byte： 空格
- 未知byte： 存储文件名
- 1byte： \0
- 20byte： blob hash值，ce616eb8c060404bb253822921a12aab81ed1ae0

与cat-file返回的信息保持一致。

可见tree对象包含的信息也很少，仅说明它下层包含了哪些blob与其它tree，更具体的如文件权限，写入时间
之类的信息要从index中寻找。所以index暂存区并不仅仅是“暂存”的文件，它也会随着git push/pull在本地/远程
之间流转。

这里有个疑问，工作区并没有目录，为什么会有tree对象？

其实这个tree对象代表的就是工作区根目录，makefile就是在
根目录下。工作区目录就像linux中的/目录，存在于每一个仓库。

## commit
  
commit是日常使用git接触的最多的概念，一个commit具体代表什么？这就是本节所要讨论的。

- 借助git底层命令，commit-tree，生成commit对象。创建commit的时候，需要指定tree对象hash值与comments信息
  - git中所有commit组织为有向无环图的结构，每一个提交都有一/多个parent commit，除了第1个commit。
    `commit-tree -p <hash>`可以在创建commit时指定parent commit，因为这里就是第1个commit，所以不需要指定parent commit。
- 同样的，commit对象也存储在objects目录下
- cat-file查看commit，其中存储了：
  - tree对象hash
  - 因为没有parent commit，这里没有显示parent commit
  - author
  - committer
    - 当前commit的author committer信息来自于git config中的user.name与user.email
  - 提交时的message

```
$ echo 'first commit' | git commit-tree 5e35decc375ba1d3d14511b6341f2827943aa42f
409eed957ae86ad7a1ef1eb0ea4a299395d4457d
$ find .git/objects -type f
.git/objects/5e/35decc375ba1d3d14511b6341f2827943aa42f
.git/objects/ce/616eb8c060404bb253822921a12aab81ed1ae0
.git/objects/40/9eed957ae86ad7a1ef1eb0ea4a299395d4457d
$ git cat-file -p 409eed957ae86ad7a1ef1eb0ea4a299395d4457d
tree 5e35decc375ba1d3d14511b6341f2827943aa42f
author DreamAndDead <favorofife@yeah.net> 1515037063 +0800
committer DreamAndDead <favorofife@yeah.net> 1515037063 +0800

first commit
```

具体看commit对象的存储，完全是字符串

```
$ pigz -d < .git/objects/40/9eed957ae86ad7a1ef1eb0ea4a299395d4457d | hexdump -C
00000000  63 6f 6d 6d 69 74 20 31  38 31 00 74 72 65 65 20  |commit 181.tree |
00000010  35 65 33 35 64 65 63 63  33 37 35 62 61 31 64 33  |5e35decc375ba1d3|
00000020  64 31 34 35 31 31 62 36  33 34 31 66 32 38 32 37  |d14511b6341f2827|
00000030  39 34 33 61 61 34 32 66  0a 61 75 74 68 6f 72 20  |943aa42f.author |
00000040  44 72 65 61 6d 41 6e 64  44 65 61 64 20 3c 66 61  |DreamAndDead <fa|
00000050  76 6f 72 6f 66 69 66 65  40 79 65 61 68 2e 6e 65  |vorofife@yeah.ne|
00000060  74 3e 20 31 35 31 35 30  33 37 30 36 33 20 2b 30  |t> 1515037063 +0|
00000070  38 30 30 0a 63 6f 6d 6d  69 74 74 65 72 20 44 72  |800.committer Dr|
00000080  65 61 6d 41 6e 64 44 65  61 64 20 3c 66 61 76 6f  |eamAndDead <favo|
00000090  72 6f 66 69 66 65 40 79  65 61 68 2e 6e 65 74 3e  |rofife@yeah.net>|
000000a0  20 31 35 31 35 30 33 37  30 36 33 20 2b 30 38 30  | 1515037063 +080|
000000b0  30 0a 0a 66 69 72 73 74  20 63 6f 6d 6d 69 74 0a  |0..first commit.|
000000c0
```

- 6byte：commit，6个字符
- 1byte：空格
- 未知byte：解析为10进制数字，表示commit内容长度
- 1byte：\0
- 4byte：tree，4个字符
- 1byte：空格
- 40byte：ascii表示的tree hash，不同于之前用2进制来存储
- 1byte：\n
- author info：
  - 6byte：author，6个字符
  - 1byte：空格
  - 未知byte：author name
  - 1byte：空格
  - 未知byte：author email
  - 1byte：空格
  - 未知byte：解析为10进制数字，编写patch的时间，用  date --date="@1515037063" 解读
  - 1byte：空格
  - 未知byte：时区
- 1byte：\n
- committer info： 格式同author info
- 2byte：\n\n
- 未知byte：提交时输入的message信息

可见commit的本质在于，指定某一时刻由index生成的tree对象。而某个tree对象，就对应于工作区所有内容的一个快照，是
永远不变的（除非你修改git历史）。每个commit对应于一个版本的内容，这就是git版本控制的基础。

## tag
   
tag在git中，使用也很频繁，通常用于标定一个提交，且设定后不轻易修改。

从某种意义上，tag和refs很像，虽然refs不是对象。在了解tag之前，先来看一下refs。
   
### branch ref

通常我们会使用`git log <parameter>`来查看commit log，但是一直记住一个hash作为参数值还是很困难的，
尤其是commit会越来越多。

refs可以理解为，是用来指定commit的指针。
git中的分支，就是一种refs，比如我们通过master这样简单好记的名称来引用commit。

- git关于refs的底层命令是update-ref
- 几乎所有仓库都有master分支。这里创建一个master引用，指向唯一一个commit。
  引用不是git对象，引用存储在.git/refs/目录下
- 引用的存储方式很简单，单纯记录指定commit的hash值

```
$ git update-ref refs/heads/master 409eed957ae86ad7a1ef1eb0ea4a299395d4457d
$ find .git/refs/heads/ -type f
.git/refs/heads/master
$ cat .git/refs/heads/master 
409eed957ae86ad7a1ef1eb0ea4a299395d4457d
```

创建master引用之后，git log的操作就简单了

```
$ git log master
```

这就是git分支的本质

### tag ref
    
- tag也是commit的引用，也可以用相同的方式创建。不同的是，tags存储在.git/refs/tags目录下
- 这样就创建了一个标签引用，本质同master一样

```
$ git update-ref refs/tags/v1.0 409eed957ae86ad7a1ef1eb0ea4a299395d4457d
$ git tag -l
v1.0
$ cat .git/refs/tags/v1.0
409eed957ae86ad7a1ef1eb0ea4a299395d4457d
```

这样的话，tag怎么会算作一个对象呢？对象都应该存储在objects目录下才对。

实际上，这只是一种简单的tag形式。通常我们在使用tag的时候，还会加上附注等
其它的信息，这不是单单一个refs文件所存储的。

### tag object
    
- 用git高层命令tag创建tag对象，版本号v1.1
- refs中指向的值是 d879e38d57885a2728e0fd7281c1c1ff701b5042， 而不是 409eed957ae86ad7a1ef1eb0ea4a299395d4457d
- objects目录下多了新文件，标明的正是tag对象
- cat-file，tag对象存储的信息也很明了，一眼可看明

```
$ git tag -a v1.1 409eed957ae86ad7a1ef1eb0ea4a299395d4457d -m 'minor version update'
$ cat .git/refs/tags/v1.1
d879e38d57885a2728e0fd7281c1c1ff701b5042
$ find .git/objects -type f
.git/objects/5e/35decc375ba1d3d14511b6341f2827943aa42f
.git/objects/ce/616eb8c060404bb253822921a12aab81ed1ae0
.git/objects/d8/79e38d57885a2728e0fd7281c1c1ff701b5042
.git/objects/40/9eed957ae86ad7a1ef1eb0ea4a299395d4457d
$ git cat-file -p d879e38d57885a2728e0fd7281c1c1ff701b5042
object 409eed957ae86ad7a1ef1eb0ea4a299395d4457d
type commit
tag v1.1
tagger DreamAndDead <favorofife@yeah.net> 1515050557 +0800

minor version update
```

解析原理同之前的几节，查看tag对象的存储

```
$ pigz -d < .git/objects/d8/79e38d57885a2728e0fd7281c1c1ff701b5042 | hexdump -C
00000000  74 61 67 20 31 35 30 00  6f 62 6a 65 63 74 20 34  |tag 150.object 4|
00000010  30 39 65 65 64 39 35 37  61 65 38 36 61 64 37 61  |09eed957ae86ad7a|
00000020  31 65 66 31 65 62 30 65  61 34 61 32 39 39 33 39  |1ef1eb0ea4a29939|
00000030  35 64 34 34 35 37 64 0a  74 79 70 65 20 63 6f 6d  |5d4457d.type com|
00000040  6d 69 74 0a 74 61 67 20  76 31 2e 31 0a 74 61 67  |mit.tag v1.1.tag|
00000050  67 65 72 20 44 72 65 61  6d 41 6e 64 44 65 61 64  |ger DreamAndDead|
00000060  20 3c 66 61 76 6f 72 6f  66 69 66 65 40 79 65 61  | <favorofife@yea|
00000070  68 2e 6e 65 74 3e 20 31  35 31 35 30 35 30 35 35  |h.net> 151505055|
00000080  37 20 2b 30 38 30 30 0a  0a 6d 69 6e 6f 72 20 76  |7 +0800..minor v|
00000090  65 72 73 69 6f 6e 20 75  70 64 61 74 65 0a        |ersion update.|
0000009e
```

存储内容也是字符串，同cat-file输出是一致的

这里的tag只是unsigned tag，如果是signed tag，可能有所不同，这里讨论未涉及

# more about refs 
  
在git对象的解析中，提到了branch ref与tag ref。还有其它的refs值得关注

## HEAD

HEAD引用起的作用非常简单，标识当前所在的commit。

- 存储在.git/HEAD文件中，内容很简单，标明当前的HEAD是一个ref，再通过解引用master ref，就可以定位到当前提交

```
$ cat .git/HEAD 
ref: refs/heads/master
```

git底层命令symbolic-ref可以用来修改HEAD
- 新建分支dev
- 修改HEAD，指向dev ref
- 此时HEAD指向dev，等同于git checkout切换分支

```
$ git branch dev
$ git symbolic-ref HEAD refs/heads/dev
$ cat .git/HEAD 
ref: refs/heads/dev
```

如果指定checkout参数为某个历史提交的hash值，git会提示我们，当前处于deteched HEAD状态。
意思是当前commit没有被任何分支refs引用。相应的，.git/HEAD中仅仅存储了当前所在commit的hash值。
   
## remote ref
   
目前的git仓库仅仅是本地仓库，如果添加服务器版本库地址并进行推送，git会记录相应refs信息到.git/refs/remotes/目录下。

比如
- 切换回master分支
- 添加远程git地址
- 推送master分支至远程git服务器
- .git/refs/remotes/下生成origin/master文件
- 文件内容为一个hash值，记录的是远程服务器git仓库master ref所指向的commit hash值

```
$ git checkout master
$ git remote add origin git@github.com:DreamAndDead/git-internals-example.git
$ git push origin master
对象计数中: 3, 完成.
写入对象中: 100% (3/3), 223 bytes | 0 bytes/s, 完成.
Total 3 (delta 0), reused 0 (delta 0)
To git@github.com:DreamAndDead/git-internals-example.git
* [new branch]      master -> master
$ find .git/refs/remotes/ -type f
.git/refs/remotes/origin/master
$ cat .git/refs/remotes/origin/master 
409eed957ae86ad7a1ef1eb0ea4a299395d4457d
```

如果服务器master分支领先于本地，可以使用git fetch来获取远程仓库内容，同时更新remotes/origin/master引用。

远程引用与本地引用最主要的区别在于，远程引用是只读的。虽然可以checkout到远程引用，但是git并不会更新HEAD，所以不能
直接在远程引用上创建新commit，只能将本地引用与远程引用相关联，使用push来更新远程引用。

# objects relation

从之前对git对象的分析（refs不是对象，但是也放在这里讨论），它们之间的关系非常明确。
由层次的包含关系，从下至上，如图所示：

{% include image.html url="git-object-relation.png" desc="git object relation" %}

- blob对应单个文件单元
- tree包含blob与tree，形成层次关系。最上层的tree为工作区目录对应的tree，向下可遍历到所有的子tree与blob
- commit指定一个tree（一般都是最上层的tree），此tree向下遍历的所有tree与blob，是当前commit对应的所有文件内容
- tag用于标识一个commit，通常用于标识代码版本。tag通常不轻易改变，指定对应commit，间接指定了对应的tree，再间接索引了
  某个时刻所有文件内容的快照。如果不修改git commit历史，快照永远不变
- refs，非对象，和tag的作用类似，间接指定某个commit，方便git操作

# more commits

## commits tree
   
目前只有一个commit，结构非常简单。任何项目都会有成百上千数量的commit，如此多个commit的情况下，
底层对象是怎样组织的呢？

我们先生成一些新的commit。
- 创建新目录src
- 创建新文件src/main.c
- 加入index
- 生成第2个commit

```
$ mkdir src
$ cat > src/main.c <<EOF
int main(int argc, char** argv) {
    return 0;
}
EOF
$ git add .
$ git commit -m 'add main.c source file'
[master ade93a8] add main.c source file
 1 file changed, 3 insertions(+)
 create mode 100644 src/main.c
```

- 修改makefile内容，可以正常编译main.c
- 更新index
- 生成第3个commit  

```
$ TAB="$(printf '\t')"
$ cat >> makefile <<EOF
all:
${TAB}gcc src/main.c
EOF
$ git add .
$ git commit -m 'makefile: compile main.c'
[master f15d0db] makefile: compile main.c
 1 file changed, 2 insertions(+)
```


- 这时再看一下objects/目录，已经有11个对象
- 依照对git对象关系的理解，用shell脚本，打印出对象之间的组织结构。
  打印内容分为3部分，每部分都是一个commit，按parent指针遍历。
  每个commit部分具体输出
  - commit对象信息hash
  - commit所指向的tree对象hash
  - tree对象包含的所有blob对象与tree对象hash
- 一共只有10个对象，还有一个tag对象，最后也列出来

```
$ find .git/objects -type f
.git/objects/5e/35decc375ba1d3d14511b6341f2827943aa42f
.git/objects/ce/616eb8c060404bb253822921a12aab81ed1ae0
.git/objects/ad/e93a829fdc058506eab8511e3925ce588bde2d
.git/objects/b1/d1b69671a4d54e36adbfec34d268aeeb997164
.git/objects/d1/419c98aa74222a057e961b65935e67398129bf
.git/objects/9b/130982db52fca0d9c7bdeacf62800794cc3c06
.git/objects/01/6a4b40ad7446aa80fc5967fdbcbb9e93ad563a
.git/objects/d8/79e38d57885a2728e0fd7281c1c1ff701b5042
.git/objects/40/9eed957ae86ad7a1ef1eb0ea4a299395d4457d
.git/objects/f1/5d0db34f6043bf79800105cb7fbf9abd7074fa
.git/objects/6a/04ac96c2dd07c1c034c575a17be4deef9f9970
$ git rev-list --all |
> while read commit; do
>   tree=$(git cat-file -p $commit | head -n 1 | awk '{print $2}')
>   echo "commit: $commit $(git show -s --format=%s $commit)"
>   echo "tree: $tree"
>   echo
>   git ls-tree -tr $tree
>   echo
>   echo
> done
commit: f15d0db34f6043bf79800105cb7fbf9abd7074fa makefile: compile main.c
tree: 6a04ac96c2dd07c1c034c575a17be4deef9f9970

100644 blob b1d1b69671a4d54e36adbfec34d268aeeb997164    makefile
040000 tree 016a4b40ad7446aa80fc5967fdbcbb9e93ad563a    src
100644 blob 9b130982db52fca0d9c7bdeacf62800794cc3c06    src/main.c


commit: ade93a829fdc058506eab8511e3925ce588bde2d add main.c source file
tree: d1419c98aa74222a057e961b65935e67398129bf

100644 blob ce616eb8c060404bb253822921a12aab81ed1ae0    makefile
040000 tree 016a4b40ad7446aa80fc5967fdbcbb9e93ad563a    src
100644 blob 9b130982db52fca0d9c7bdeacf62800794cc3c06    src/main.c


commit: 409eed957ae86ad7a1ef1eb0ea4a299395d4457d first commit
tree: 5e35decc375ba1d3d14511b6341f2827943aa42f

100644 blob ce616eb8c060404bb253822921a12aab81ed1ae0    makefile


$ git cat-file -p d879e38d57885a2728e0fd7281c1c1ff701b5042
object 409eed957ae86ad7a1ef1eb0ea4a299395d4457d
type commit
tag v1.1
tagger DreamAndDead <favorofife@yeah.net> 1515050557 +0800

minor version update

```

依照输出分析，所有对象间关系如图：

{% include image.html url="git-log-internal.png" desc="relations between git objects" %}

到这里，我们对git已经有比较深刻地理解：
- 通常情况，tree与blob对用户不可见，commit是理解git的基本单元
- 所有commit，按照 有向无环图 的形式来组织。每一个新提交，都指向当前commit作为parent
- 每次创建commit的本质没有根本性的变化
- git对tree与blob的存储是十分紧凑的，相同内容的tree与blob在多个commit之间复用

## remote commits

使用git，不免使用服务器来与其它人进行远程项目开发与协作。

假设目前的工作流：
- 你在本地master分支建立了A B两个commit，push到服务器
- 甲 pull服务器的代码，建立commit C，push到服务器
- 乙 pull服务器代码，基于commit A，建立新分支，创建了commit E F。切换至master分支，合并分支生成提交D。
  push到服务器

在这段时间内，你并不清楚甲乙进行了什么样的操作。使用git fetch获取服务器仓库内容，
对你而言，整个仓库的commit结构是这样的：


{% include image.html url="git-remote-ref.png" desc="git commits structure" %}

- 本地master指向的最新提交还是B，由parent遍历，只有A B两个提交对自己可见
- git fetch从服务器取得新的commit/tree/blob对象，更新remote/origin/master引用
  服务器所拥有的commit，本地存在一份完整相同的备份！
- 假如在master分支，git merge合并origin/master，master会指向提交D，这时提交A B C D E F都会对本地可见

这里的合并是一个fast-forward，没有考虑合并冲突等情况，但是多人远程协作工作流的本质是类似的。
  
# pack

git默认存储对象的格式被称为松散（loose）对象格式，各个对象分布在.git/objects/子目录中。
git提供了pack机制，将所有松散对象打包整理为一个二进制包文件packfile，使用delta compression
差量压缩的方式，文件更为紧凑，体积更小。

## create pack
  
先来执行pack过程将松散对象打包为packfile。

- git gc命令，垃圾回收的同时，进行对象pack
- 打包之后，所有之前的松散对象消失了。在.git/objects/pack/与info/目录下，生成了3个新文件
- 还有一个新文件.git/packed-refs

```
$ git gc
对象计数中: 11, 完成.
Delta compression using up to 8 threads.
压缩对象中: 100% (7/7), 完成.
写入对象中: 100% (11/11), 完成.                                                                          
Total 11 (delta 0), reused 11 (delta 0)             
$ find .git/objects/ -type f
.git/objects/pack/pack-74058ffa32d64f2525e69aef0fdf5ba3f95e24df.pack
.git/objects/pack/pack-74058ffa32d64f2525e69aef0fdf5ba3f95e24df.idx
.git/objects/info/packs
$ ls .git/packed-refs                                  
.git/packed-refs                                    
```

下面的章节详细解释这4个文件相关内容。

## packed-refs

如果执行了pack，git会将原有的refs都移动到packed-refs文件中。
如果创建新的引用，新的引用会在.git/refs下新生成，不会更改packed-refs文件。

- 原有的refs消失了
- 查看文件内容
  - 每一行内容，hash对应refs
  - 最后一行以^开头，说明其上一行是tag对象，最后一行代表上一行tag对象指向的commit hash

```
$ find .git/refs/ -type f          
$ cat .git/packed-refs
# pack-refs with: peeled fully-peeled                                                                    
409eed957ae86ad7a1ef1eb0ea4a299395d4457d refs/heads/dev                                                  
f15d0db34f6043bf79800105cb7fbf9abd7074fa refs/heads/master                                               
f15d0db34f6043bf79800105cb7fbf9abd7074fa refs/remotes/origin/master                                      
409eed957ae86ad7a1ef1eb0ea4a299395d4457d refs/tags/v1.0                                                  
d879e38d57885a2728e0fd7281c1c1ff701b5042 refs/tags/v1.1                                                  
^409eed957ae86ad7a1ef1eb0ea4a299395d4457d  
```

使用packed-refs文件，是为了效率。
因为为了获取指定引用的hash值，git会先在refs中查找，再到packed-refs文件中查找，
而不是再解析packfile去查找。
   
## info/pack

TODO，虽然文件内容很简单，但是不清楚这个文件的准确作用，没有找到官方文档记载

- 查看文件内容

```
$ cat .git/objects/info/packs 
P pack-74058ffa32d64f2525e69aef0fdf5ba3f95e24df.pack
```

看内容的话，像是只用于记录已打包的包文件名。

如果你找到准确的文档记载，please tell me :)

## pack file index

packfile内部的结构是非常有意思的，详细参阅 [官方文档](https://github.com/git/git/blob/v2.7.4/Documentation/technical/pack-format.txt)

在pack过程中，除了生成packfile，同时会生成pack index文件。同packed-refs一样，pack index
也是为了效率，可以快速定位packfile中所需要的对象。

- verify-pack底层命令可用于解析pack index file。一共11个对象，同pack前是一致的。
  verify-pack的输出分为5列：
  - 对象hash
  - 对象类型
  - 对象解压后大小
  - 对象在packfile中的大小
  - 对象在packfile中的起始偏移位置
- 最后一行输出，“非 delta”，说明packfile中没有存储delta。delta也是一个比较复杂的话题，后面再研究

```
$ git verify-pack -v .git/objects/pack/pack-74058ffa32d64f2525e69aef0fdf5ba3f95e24df.idx
f15d0db34f6043bf79800105cb7fbf9abd7074fa commit 241 165 12
ade93a829fdc058506eab8511e3925ce588bde2d commit 239 161 177
409eed957ae86ad7a1ef1eb0ea4a299395d4457d commit 181 124 338
d879e38d57885a2728e0fd7281c1c1ff701b5042 tag    150 134 462
6a04ac96c2dd07c1c034c575a17be4deef9f9970 tree   66 77 596
016a4b40ad7446aa80fc5967fdbcbb9e93ad563a tree   34 45 673
d1419c98aa74222a057e961b65935e67398129bf tree   66 76 718
5e35decc375ba1d3d14511b6341f2827943aa42f tree   36 47 794
b1d1b69671a4d54e36adbfec34d268aeeb997164 blob   32 42 841
9b130982db52fca0d9c7bdeacf62800794cc3c06 blob   50 55 883
ce616eb8c060404bb253822921a12aab81ed1ae0 blob   11 20 938
非 delta：11 个对象
.git/objects/pack/pack-74058ffa32d64f2525e69aef0fdf5ba3f95e24df.pack: ok
```

- 查看pack index本身，输出内容有些长，be patient

```
$ hexdump -C .git/objects/pack/pack-74058ffa32d64f2525e69aef0fdf5ba3f95e24df.idx 
00000000  ff 74 4f 63 00 00 00 02  00 00 00 00 00 00 00 01  |.tOc............|
00000010  00 00 00 01 00 00 00 01  00 00 00 01 00 00 00 01  |................|
*
00000100  00 00 00 01 00 00 00 01  00 00 00 02 00 00 00 02  |................|
00000110  00 00 00 02 00 00 00 02  00 00 00 02 00 00 00 02  |................|
*
00000180  00 00 00 03 00 00 00 03  00 00 00 03 00 00 00 03  |................|
*
000001b0  00 00 00 04 00 00 00 04  00 00 00 04 00 00 00 04  |................|
*
00000270  00 00 00 04 00 00 00 05  00 00 00 05 00 00 00 05  |................|
00000280  00 00 00 05 00 00 00 05  00 00 00 05 00 00 00 05  |................|
*
000002b0  00 00 00 05 00 00 00 05  00 00 00 05 00 00 00 06  |................|
000002c0  00 00 00 06 00 00 00 06  00 00 00 06 00 00 00 07  |................|
000002d0  00 00 00 07 00 00 00 07  00 00 00 07 00 00 00 07  |................|
*
00000340  00 00 00 08 00 00 00 08  00 00 00 08 00 00 00 09  |................|
00000350  00 00 00 09 00 00 00 09  00 00 00 09 00 00 00 09  |................|
00000360  00 00 00 09 00 00 00 09  00 00 00 0a 00 00 00 0a  |................|
00000370  00 00 00 0a 00 00 00 0a  00 00 00 0a 00 00 00 0a  |................|
*
000003c0  00 00 00 0a 00 00 00 0a  00 00 00 0a 00 00 00 0b  |................|
000003d0  00 00 00 0b 00 00 00 0b  00 00 00 0b 00 00 00 0b  |................|
*
00000400  00 00 00 0b 00 00 00 0b  01 6a 4b 40 ad 74 46 aa  |.........jK@.tF.|
00000410  80 fc 59 67 fd bc bb 9e  93 ad 56 3a 40 9e ed 95  |..Yg......V:@...|
00000420  7a e8 6a d7 a1 ef 1e b0  ea 4a 29 93 95 d4 45 7d  |z.j......J)...E}|
00000430  5e 35 de cc 37 5b a1 d3  d1 45 11 b6 34 1f 28 27  |^5..7[...E..4.('|
00000440  94 3a a4 2f 6a 04 ac 96  c2 dd 07 c1 c0 34 c5 75  |.:./j........4.u|
00000450  a1 7b e4 de ef 9f 99 70  9b 13 09 82 db 52 fc a0  |.{.....p.....R..|
00000460  d9 c7 bd ea cf 62 80 07  94 cc 3c 06 ad e9 3a 82  |.....b....<...:.|
00000470  9f dc 05 85 06 ea b8 51  1e 39 25 ce 58 8b de 2d  |.......Q.9%.X..-|
00000480  b1 d1 b6 96 71 a4 d5 4e  36 ad bf ec 34 d2 68 ae  |....q..N6...4.h.|
00000490  eb 99 71 64 ce 61 6e b8  c0 60 40 4b b2 53 82 29  |..qd.an..`@K.S.)|
000004a0  21 a1 2a ab 81 ed 1a e0  d1 41 9c 98 aa 74 22 2a  |!.*......A...t"*|
000004b0  05 7e 96 1b 65 93 5e 67  39 81 29 bf d8 79 e3 8d  |.~..e.^g9.)..y..|
000004c0  57 88 5a 27 28 e0 fd 72  81 c1 c1 ff 70 1b 50 42  |W.Z'(..r....p.PB|
000004d0  f1 5d 0d b3 4f 60 43 bf  79 80 01 05 cb 7f bf 9a  |.]..O`C.y.......|
000004e0  bd 70 74 fa 2c 66 bb 82  0c ff 79 90 ce 00 7b 86  |.pt.,f....y...{.|
000004f0  b9 6f 6a bd ac d3 e5 f9  25 29 01 fa af 5e b3 e0  |.oj.....%)...^..|
00000500  61 73 a7 c1 a8 56 9c af  04 55 c6 f8 f0 2e 58 76  |as...V...U....Xv|
00000510  00 00 02 a1 00 00 01 52  00 00 03 1a 00 00 02 54  |.......R.......T|
00000520  00 00 03 73 00 00 00 b1  00 00 03 49 00 00 03 aa  |...s.......I....|
00000530  00 00 02 ce 00 00 01 ce  00 00 00 0c 74 05 8f fa  |............t...|
00000540  32 d6 4f 25 25 e6 9a ef  0f df 5b a3 f9 5e 24 df  |2.O%%.....[..^$.|
00000550  a5 74 df 44 c3 8a e3 5d  83 8c 9e 93 c8 e2 34 f2  |.t.D...]......4.|
00000560  ec 72 9f 78                                       |.r.x|
00000564
```

同之前讲到的，pack index并不存储对象，只是为了更方便的在packfile中索引对象。

一图胜千言，借用 [git community book 的插图](http://shafiulazam.com/gitbook/7_the_packfile.html%0A)

{% include image.html url="git-packfile-index-structure.jpg" desc="图解pack index file存储结构" %}

index file一般都使用version 2，对照上面index file内容，逐字节解析：
- 4byte：ff 74 4f 63，magic number
- 4byte：00 00 00 02，标明版本号
- 256*4byte：fanout table，很有趣的结构，下面单独章节说明，00：8 - 400：8
- 对象个数*20byte：所有对象的hash值，按ascii排序。400：8 - 4e0：4部分，11个SHA1顺序排列
- 对象个数*4byte：在packfile中每个对象的crc checksums。4e0：4 - 510：0
- 对象个数*4byte：在packfile中每个对象的起始偏移位置。510：0 - 530：c
- 0byte：只有packfile大小超过2G才会存在，这里不追究
- 2*20byte： packfile SHA1与pack index file SHA1。530：c - end

### fanout table
    
pack file index存储结构一目了然，其它块表示的意思很明确。
fanout table不是一行可以讲完的，这里单独分出一个章节来。

fanout table的作用也是在于提高查询效率，用于在pack index file中快速查询SHA1。
下面来详细解析下它是如何做到这一点的。

- 单独截取pack index file中fanout table部分
- 单独截取对象SHA1列表部分

```
$ dd status=none ibs=1 skip=$((0x08)) count=$((0x400)) if=.git/objects/pack/pack-74058ffa32d64f2525e69aef0fdf5ba3f95e24df.idx | hexdump -C
00000000  00 00 00 00 00 00 00 01  00 00 00 01 00 00 00 01  |................|
00000010  00 00 00 01 00 00 00 01  00 00 00 01 00 00 00 01  |................|
*
00000100  00 00 00 02 00 00 00 02  00 00 00 02 00 00 00 02  |................|
*
00000170  00 00 00 02 00 00 00 02  00 00 00 03 00 00 00 03  |................|
00000180  00 00 00 03 00 00 00 03  00 00 00 03 00 00 00 03  |................|
*
000001a0  00 00 00 03 00 00 00 03  00 00 00 04 00 00 00 04  |................|
000001b0  00 00 00 04 00 00 00 04  00 00 00 04 00 00 00 04  |................|
*
00000260  00 00 00 04 00 00 00 04  00 00 00 04 00 00 00 05  |................|
00000270  00 00 00 05 00 00 00 05  00 00 00 05 00 00 00 05  |................|
*
000002b0  00 00 00 05 00 00 00 06  00 00 00 06 00 00 00 06  |................|
000002c0  00 00 00 06 00 00 00 07  00 00 00 07 00 00 00 07  |................|
000002d0  00 00 00 07 00 00 00 07  00 00 00 07 00 00 00 07  |................|
*
00000330  00 00 00 07 00 00 00 07  00 00 00 08 00 00 00 08  |................|
00000340  00 00 00 08 00 00 00 09  00 00 00 09 00 00 00 09  |................|
00000350  00 00 00 09 00 00 00 09  00 00 00 09 00 00 00 09  |................|
00000360  00 00 00 0a 00 00 00 0a  00 00 00 0a 00 00 00 0a  |................|
*
000003c0  00 00 00 0a 00 00 00 0b  00 00 00 0b 00 00 00 0b  |................|
000003d0  00 00 00 0b 00 00 00 0b  00 00 00 0b 00 00 00 0b  |................|
*
00000400
$ dd status=none ibs=1 skip=$((0x400+0x08)) count=$((0x0b*20)) if=.git/objects/pack/pack-74058ffa32d64f2525e69aef0fdf5ba3f95e24df.idx | hexdump -C
00000000  01 6a 4b 40 ad 74 46 aa  80 fc 59 67 fd bc bb 9e  |.jK@.tF...Yg....|
00000010  93 ad 56 3a 40 9e ed 95  7a e8 6a d7 a1 ef 1e b0  |..V:@...z.j.....|
00000020  ea 4a 29 93 95 d4 45 7d  5e 35 de cc 37 5b a1 d3  |.J)...E}^5..7[..|
00000030  d1 45 11 b6 34 1f 28 27  94 3a a4 2f 6a 04 ac 96  |.E..4.('.:./j...|
00000040  c2 dd 07 c1 c0 34 c5 75  a1 7b e4 de ef 9f 99 70  |.....4.u.{.....p|
00000050  9b 13 09 82 db 52 fc a0  d9 c7 bd ea cf 62 80 07  |.....R.......b..|
00000060  94 cc 3c 06 ad e9 3a 82  9f dc 05 85 06 ea b8 51  |..<...:........Q|
00000070  1e 39 25 ce 58 8b de 2d  b1 d1 b6 96 71 a4 d5 4e  |.9%.X..-....q..N|
00000080  36 ad bf ec 34 d2 68 ae  eb 99 71 64 ce 61 6e b8  |6...4.h...qd.an.|
00000090  c0 60 40 4b b2 53 82 29  21 a1 2a ab 81 ed 1a e0  |.`@K.S.)!.*.....|
000000a0  d1 41 9c 98 aa 74 22 2a  05 7e 96 1b 65 93 5e 67  |.A...t"*.~..e.^g|
000000b0  39 81 29 bf d8 79 e3 8d  57 88 5a 27 28 e0 fd 72  |9.)..y..W.Z'(..r|
000000c0  81 c1 c1 ff 70 1b 50 42  f1 5d 0d b3 4f 60 43 bf  |....p.PB.]..O`C.|
000000d0  79 80 01 05 cb 7f bf 9a  bd 70 74 fa              |y........pt.|
000000dc
```

- SHA1列表每20byte为一项，共11项，对应11个对象
- fanout table每4byte为一项，共256项
  - 第1项，代表所有SHA1中以 01 开始的最小的SHA1在SHA1列表中的索引值。00 00 00 00 表示索引值为0，对应SHA1列表中的
    016a4b40ad7446aa80fc5967fdbcbb9e93ad563a。为什么不是代表以 00 开始的SHA1呢？因为 00 开始的最小的SHA1无论是否存在，必定
    是从索引值0开始的，不需要存储
  - 第2项，代表所有SHA1中以 02 开始的最小的SHA1在SHA1列表中的索引值。00 00 00 01 表示索引值为1，因为索引0已经存储1个 01 开始SHA1，
    所以 02 开始的SHA1至少从索引1开始。而索引1对应SHA1列表中的409eed957ae86ad7a1ef1eb0ea4a299395d4457d，以 40 而非以 02 开始，所以
    不存在SHA1以 02 为起始的对象
  - 第3项，代表所有SHA1中以 03 开始的最小的SHA1在SHA1列表中的索引值。00 00 00 01，理解同上，不存在SHA1以 03 起始的对象
  - ..............
  - 第255项，代表所有SHA1中以 ff 开始的最小的SHA1在SHA1列表中的索引值。00 00 00 0b，已经超出了SHA1表的范围，所以不存在 ff 起始的SHA1
  - 第256项，代表所有对象的个数。00 00 00 0b，共11个对象。第256项代表的索引总是超出SHA1表且指向SHA1表的末尾

所以在查询一个SHA1值，比如 29afa901，先在fanout table找到 29 对应的索引，再找到 2a 对应的索引，所查找的SHA1必定在这两个索引之间。
如果两个索引相同，说明SHA1不存在于index file中；如果不相同，用二分法查找SHA1，非常快速。

这就是fanout table提高查询效率的方式。

## pack file

pack index file存储对象的SHA1，crc等信息，packfile存储对象的内容。

- 查看packfile内容，输出内容过多，中间部分用.......省略输出

```
$ hexdump -C .git/objects/pack/pack-74058ffa32d64f2525e69aef0fdf5ba3f95e24df.pack 
00000000  50 41 43 4b 00 00 00 02  00 00 00 0b 91 0f 78 9c  |PACK..........x.|
00000010  9d cc 41 6a c3 30 10 46  e1 bd 4e a1 7d 21 8c 6c  |..Aj.0.F..N.}!.l|
00000020  8f 25 95 50 52 f0 45 c6  33 bf 88 69 65 07 a1 06  |.%.PR.E.3..ie...|
00000030  7a fb f8 0c d9 bd cd f7  7a 03 fc 2c 34 89 e6 59  |z.......z..,4..Y|
..............................................................................
..............................................................................
..............................................................................
..............................................................................
00000390  9c 32 4d 85 6a 2e 05 20  28 4a 2d 29 2d ca 53 30  |.2M.j.. (J-)-.S0|
000003a0  b0 e6 aa e5 02 00 a4 a5  0f 59 3b 78 9c 53 56 c8  |.........Y;x.SV.|
000003b0  4d cc 4e 4d cb cc 49 e5  02 00 14 ae 03 8c 74 05  |M.NM..I.......t.|
000003c0  8f fa 32 d6 4f 25 25 e6  9a ef 0f df 5b a3 f9 5e  |..2.O%%.....[..^|
000003d0  24 df                                             |$.|
000003d2
```

packfile的格式非常简单清晰，同样借用 [git community book 插图](http://shafiulazam.com/gitbook/7_the_packfile.html%0A)

{% include image.html url="git-packfile-structure.jpg" desc="图解packfile格式" %}

- 4byte： PACK 4个字符
- 4byte： 版本号
- 4byte： 存储对象的个数，00 00 00 0b，11个对象
- objects，所有对象内容列表：
  - head info，占用多少byte不固定，取决于每个byte的第1个bit:
    - 1byte： 0x91 => 1001 0001
      - 1bit： 如果为1，说明其后的1个byte还是head部分；如果为0，说明其后的byte就是对象数据。这里为1
      - 3bit： 标明对象的类型， 001 标明对象为 commit
      - 4bit： 对象解压缩后字节大小（需要多部分组合计算）
    - 1byte： 0x0f => 0000 1111，因为上一个byte 第1bit为1，所以这个byte也属于head的一部分
      - 1bit： 如果为1，说明其后的1个byte还是head部分；如果为0，说明其后的byte就是对象数据。这里为0
      - 7bit： 对象解压缩后字节大小（需要多部分组合计算）
  - data，对象压缩内容

借用图解来解释head部分对象解压缩大小的计算，thanks [git community book](http://shafiulazam.com/gitbook/7_the_packfile.html%0A)

{% include image.html url="git-packfile-object-head-structure.jpg" desc="如何计算对象size" %}

- 第一个byte低4bit，为对象解压缩size的最低4bit
- 其后每个byte的低7bit，按照移位规则，最终组合成的数字代表对象解压缩的size数值


接下来从packfile中提取压缩对象
- 从packfile index中，提取出所有对象在packfile中的偏移信息。最后一个对象的偏移最小，0x0c，对应SHA1列表中的最后一个，f15d0db34f6043bf79800105cb7fbf9abd7074fa
- 上面讲到，head之后才是属于对象内容，那对象内容的大小是多少？并没有告诉我们。这里先在所有对象偏移信息中，找到
  第2小的偏移，0xb1，可以认定从0x0c - 0xb1中的内容，就是压缩对象的内容。果不其然，解压出一个commit对象

```
$ dd status=none ibs=1 skip=$((0x400+0x08+0x0b*20+0x0b*4)) count=$((0x0b*4)) if=.git/objects/pack/pack-74058ffa32d64f2525e69aef0fdf5ba3f95e24df.idx | hexdump -C
00000000  00 00 02 a1 00 00 01 52  00 00 03 1a 00 00 02 54  |.......R.......T|
00000010  00 00 03 73 00 00 00 b1  00 00 03 49 00 00 03 aa  |...s.......I....|
00000020  00 00 02 ce 00 00 01 ce  00 00 00 0c              |............|
0000002c
$ dd status=none ibs=1 skip=$((0x0c+2)) count=$((0xb1-0x0c-2)) if=.git/objects/pack/pack-74058ffa32d64f2525e69aef0fdf5ba3f95e24df.pack | pigz -d | hexdump -C
00000000  74 72 65 65 20 36 61 30  34 61 63 39 36 63 32 64  |tree 6a04ac96c2d|
00000010  64 30 37 63 31 63 30 33  34 63 35 37 35 61 31 37  |d07c1c034c575a17|
00000020  62 65 34 64 65 65 66 39  66 39 39 37 30 0a 70 61  |be4deef9f9970.pa|
00000030  72 65 6e 74 20 61 64 65  39 33 61 38 32 39 66 64  |rent ade93a829fd|
00000040  63 30 35 38 35 30 36 65  61 62 38 35 31 31 65 33  |c058506eab8511e3|
00000050  39 32 35 63 65 35 38 38  62 64 65 32 64 0a 61 75  |925ce588bde2d.au|
00000060  74 68 6f 72 20 44 72 65  61 6d 41 6e 64 44 65 61  |thor DreamAndDea|
00000070  64 20 3c 66 61 76 6f 72  6f 66 69 66 65 40 79 65  |d <favorofife@ye|
00000080  61 68 2e 6e 65 74 3e 20  31 35 31 35 30 35 37 30  |ah.net> 15150570|
00000090  38 38 20 2b 30 38 30 30  0a 63 6f 6d 6d 69 74 74  |88 +0800.committ|
000000a0  65 72 20 44 72 65 61 6d  41 6e 64 44 65 61 64 20  |er DreamAndDead |
000000b0  3c 66 61 76 6f 72 6f 66  69 66 65 40 79 65 61 68  |<favorofife@yeah|
000000c0  2e 6e 65 74 3e 20 31 35  31 35 30 35 37 30 38 38  |.net> 1515057088|
000000d0  20 2b 30 38 30 30 0a 0a  6d 61 6b 65 66 69 6c 65  | +0800..makefile|
000000e0  3a 20 63 6f 6d 70 69 6c  65 20 6d 61 69 6e 2e 63  |: compile main.c|
000000f0  0a                                                |.|
000000f1
```

这里存在一个疑问，如果只能确定对象在packfile中的偏移，不能确定对象在packfile中的大小，如果每次都像上面的做法一样，找到其次的偏移再进行减法，
无疑是非常低效的。

事实上，对象内容的范围由zlib压缩算法就可以确定。
- 比如我们从对象偏移处截取的数据多于对象本身（250byte），再进行解压缩，
  最后还是解析出了对象，不过pigz stderr输出了warnning信息，trailing junk，说明多余的数据并没有参与解压运算。

```
$ dd status=none ibs=1 skip=$((0x0c+2)) count=250 if=.git/objects/pack/pack-74058ffa32d64f2525e69aef0fdf5ba3f95e24df.pack | pigz -d | hexdump -C
00000000  74 72 65 65 20 36 61 30  34 61 63 39 36 63 32 64  |tree 6a04ac96c2d|
00000010  64 30 37 63 31 63 30 33  34 63 35 37 35 61 31 37  |d07c1c034c575a17|
00000020  62 65 34 64 65 65 66 39  66 39 39 37 30 0a 70 61  |be4deef9f9970.pa|
00000030  72 65 6e 74 20 61 64 65  39 33 61 38 32 39 66 64  |rent ade93a829fd|
pigz: <stdin> OK, has trailing junk which was ignored00000040  63 30 35 38 35 30 36 65  61 62 38 35 31 31 65 33  |c058506eab8511e3|

00000050  39 32 35 63 65 35 38 38  62 64 65 32 64 0a 61 75  |925ce588bde2d.au|
00000060  74 68 6f 72 20 44 72 65  61 6d 41 6e 64 44 65 61  |thor DreamAndDea|
00000070  64 20 3c 66 61 76 6f 72  6f 66 69 66 65 40 79 65  |d <favorofife@ye|
00000080  61 68 2e 6e 65 74 3e 20  31 35 31 35 30 35 37 30  |ah.net> 15150570|
00000090  38 38 20 2b 30 38 30 30  0a 63 6f 6d 6d 69 74 74  |88 +0800.committ|
000000a0  65 72 20 44 72 65 61 6d  41 6e 64 44 65 61 64 20  |er DreamAndDead |
000000b0  3c 66 61 76 6f 72 6f 66  69 66 65 40 79 65 61 68  |<favorofife@yeah|
000000c0  2e 6e 65 74 3e 20 31 35  31 35 30 35 37 30 38 38  |.net> 1515057088|
000000d0  20 2b 30 38 30 30 0a 0a  6d 61 6b 65 66 69 6c 65  | +0800..makefile|
000000e0  3a 20 63 6f 6d 70 69 6c  65 20 6d 61 69 6e 2e 63  |: compile main.c|
000000f0  0a                                                |.|
000000f1
```

可以确定，只需要对象数据的开始，就可以解压缩出对象本身。至于具体压缩大小是如何计算的，我还不得而知。Please inform me if you know how :)        
   
## delta in pack file

前面解读了packfile中内容，所有对象经过zlib压缩，排列在一起，聚合为packfile。好像没什么新鲜的，因为每个松散对象
也是经过zlib压缩的，packfile好像不过是把大家聚集在一个文件中而已，并没有带来什么空间利用率上的提升。

这也是为什么需要delta机制的原因，delta是packfile得以压缩空间的关键所在。packfile采用了一种名为delta compression的机制，
将多个对象中重复部分单独存储，其它部分差量存储。

先来构建一个可以产生delta的环境。

- 编译main.c，生成a.out可执行文件
- 添加a.out
- 创建新的commit

```
$ make
$ git add .
$ git commit -m 'add a.out binary file'
[master 3d58afd] add a.out binary file
 1 file changed, 0 insertions(+), 0 deletions(-)
 create mode 100755 a.out
```

- 强制在a.out文件后续添加9个字符（包括0x0a）。a.out有8k的大小，9个字符相对其来说不值一提。
  两个文件有8k内容是相同的，只有9个字符的区别，如果将两个文件分别全部存储，那就有8k的冗余数据啊
- 添加新的a.out
- 创建新commit
- 再次执行pack，输出和之前不同的在 Total 17 (delta 1)，有一个差量存储（果不其然，生成了delta）
- 生成了新的packfile，同之前的不同

```
$ echo '12345678' >> a.out
$ git add .
$ git commit -m 'add trailing junk to a.out'
[master cfaf867] add trailing junk to a.out
 1 file changed, 0 insertions(+), 0 deletions(-)
$ git gc
对象计数中: 17, 完成.
Delta compression using up to 8 threads.
压缩对象中: 100% (13/13), 完成.
写入对象中: 100% (17/17), 完成.
Total 17 (delta 1), reused 11 (delta 0)
$ find .git/objects/ -type f
.git/objects/pack/pack-dcb9339ef1f0cd8395021b7e50d7457a340b5519.idx
.git/objects/pack/pack-dcb9339ef1f0cd8395021b7e50d7457a340b5519.pack
.git/objects/info/packs
```

- 先来找到两个版本a.out的blob SHA1值
  - git log，最新的两个commit包含a.out文件
  - 最新commit包含的a.out blob SHA1为 0a323ebc526b357580590d6d7a884d1dd473321b，对应的为append多余字符的a.out
  - parent commit包含的a.out blob SHA1为 0ec8e3e23234ba10a9822951812ba37f391da114，对应的是make生成的a.out
- 再次执行verify-pack来解析下packfile，有一行的输出比较特别，有7列内容
  - 前5列同之前的解析是相同的
  - 第6列，delta chain的深度，TODO，具体不清楚其含义
  - 第7列，delta对应的base对象SHA1。delta要构建在base对象上，才可以生成新的对象

```
$ git log --oneline
cfaf867 add trailing junk to a.out
3d58afd add a.out binary file
f15d0db makefile: compile main.c
ade93a8 add main.c source file
409eed9 first commit
$ git ls-tree -tr cfaf867
100755 blob 0a323ebc526b357580590d6d7a884d1dd473321b    a.out
100644 blob b1d1b69671a4d54e36adbfec34d268aeeb997164    makefile
040000 tree 016a4b40ad7446aa80fc5967fdbcbb9e93ad563a    src
100644 blob 9b130982db52fca0d9c7bdeacf62800794cc3c06    src/main.c
$ git ls-tree -tr 3d58afd
100755 blob 0ec8e3e23234ba10a9822951812ba37f391da114    a.out
100644 blob b1d1b69671a4d54e36adbfec34d268aeeb997164    makefile
040000 tree 016a4b40ad7446aa80fc5967fdbcbb9e93ad563a    src
100644 blob 9b130982db52fca0d9c7bdeacf62800794cc3c06    src/main.c
$ git verify-pack -v .git/objects/pack/pack-dcb9339ef1f0cd8395021b7e50d7457a340b5519.idx
cfaf8679609f0d2bce01944f58b509db50d371a0 commit 243 167 12
3d58afd50b5b4211be1850255a3411dd2cc70bae commit 238 160 179
f15d0db34f6043bf79800105cb7fbf9abd7074fa commit 241 165 339
ade93a829fdc058506eab8511e3925ce588bde2d commit 239 161 504
409eed957ae86ad7a1ef1eb0ea4a299395d4457d commit 181 124 665
d879e38d57885a2728e0fd7281c1c1ff701b5042 tag    150 134 789
c0649f8482ba4535cb5b662757bd81018b3c21e4 tree   99 110 923
016a4b40ad7446aa80fc5967fdbcbb9e93ad563a tree   34 45 1033
9d82ecb86dcde3221b4815505d185791a1a657c7 tree   99 112 1078
6a04ac96c2dd07c1c034c575a17be4deef9f9970 tree   66 77 1190
d1419c98aa74222a057e961b65935e67398129bf tree   66 76 1267
5e35decc375ba1d3d14511b6341f2827943aa42f tree   36 47 1343
0a323ebc526b357580590d6d7a884d1dd473321b blob   8561 2331 1390
0ec8e3e23234ba10a9822951812ba37f391da114 blob   7 18 3721 1 0a323ebc526b357580590d6d7a884d1dd473321b
b1d1b69671a4d54e36adbfec34d268aeeb997164 blob   32 42 3739
9b130982db52fca0d9c7bdeacf62800794cc3c06 blob   50 55 3781
ce616eb8c060404bb253822921a12aab81ed1ae0 blob   11 20 3836
非 delta：16 个对象
链长 = 1: 1 对象
.git/objects/pack/pack-dcb9339ef1f0cd8395021b7e50d7457a340b5519.pack: ok
```

这里有个疑问，0ec8对应的是make生成的a.out，0a32对应的是append字符的a.out。为什么0a32是base，0ec8不是base？
这样做可能还是因为效率，因为最新的对象，被引用的机率要大于历史对象，将最新的a.out完整存储，方便快速取出对象。


下面根据verify-pack输出的偏移值，来仔细查看base与delta
- base对象的前16个字节，0xb1 97 04，head info占用了3个字节
- 3个字节之后就是base a.out blob的内容。内容过长，中间用........省略
- delta对象偏移的前16个字节
  - 0x67 => 0110 0111
    - 0 表示 后续字节不属于head信息
    - 110 表示 存储类型为 OBJ_OFS_DELTA
    - 0111 表示 存储数据解压后大小为 7 字节
  - 0x91 1b，解析为一个负的offset值 => 1001 0001 0001 1011
    - 1 表示后续字节为offset字段的一部分
    - 001 0001， offset的一部分，需组合计算，运算规则同对象size的计算，同样的应用移位
    - 0 表示后续字节为delta数据部分
    - 001 1011，offset的一部分，需组合计算，运算规则同对象size的计算，同样的应用移位
    - 组合offset的内容为 00 1101 1001 0001 => 0xd91
  - delta data，用zlib解压缩，内容为 0xf1 42 e8 42 b0 68 21

```
$ dd status=none ibs=1 skip=$((1390)) if=.git/objects/pack/pack-dcb9339ef1f0cd8395021b7e50d7457a340b5519.pack | hexdump -C | head -n 1
00000000  b1 97 04 78 9c ed 59 6f  6c 5b 57 15 bf cf ce df  |...x..Yol[W.....|
$ dd status=none ibs=1 skip=$((1390+3)) if=.git/objects/pack/pack-dcb9339ef1f0cd8395021b7e50d7457a340b5519.pack | pigz -d | hexdump -C
00000000  7f 45 4c 46 02 01 01 00  00 00 00 00 00 00 00 00  |.ELF............|
00000010  02 00 3e 00 01 00 00 00  e0 03 40 00 00 00 00 00  |..>.......@.....|
pigz: 00000020  40 00 00 00 00 00 00 00  a8 19 00 00 00 00 00 00  |@...............|
<stdin> OK, has trailing junk which was ignored
00000030  00 00 00 00 40 00 38 00  09 00 40 00 1f 00 1c 00  |....@.8...@.....|
00000040  06 00 00 00 05 00 00 00  40 00 00 00 00 00 00 00  |........@.......|
00000050  40 00 40 00 00 00 00 00  40 00 40 00 00 00 00 00  |@.@.....@.@.....|
..............................................................................
..............................................................................
..............................................................................
00002140  98 16 00 00 00 00 00 00  01 02 00 00 00 00 00 00  |................|
00002150  00 00 00 00 00 00 00 00  01 00 00 00 00 00 00 00  |................|
00002160  00 00 00 00 00 00 00 00  31 32 33 34 35 36 37 38  |........12345678|
00002170  0a                                                |.|
00002171
$ dd status=none ibs=1 skip=$((3721)) if=.git/objects/pack/pack-dcb9339ef1f0cd8395021b7e50d7457a340b5519.pack | hexdump -C | head -n 1
00000000  67 91 1b 78 9c fb e8 f4  c2 69 43 86 22 00 10 bb  |g..x.....iC."...|
$ dd status=none ibs=1 skip=$((3721+3)) if=.git/objects/pack/pack-dcb9339ef1f0cd8395021b7e50d7457a340b5519.pack | pigz -d | hexdump -C
pigz: <stdin> OK, has trailing junk which was ignored
00000000  f1 42 e8 42 b0 68 21                              |.B.B.h!|
00000007
```

可见两个版本的a.out并没有存储两份，delta部分数据量尤其的小，节省了50%的空间。

不幸的是，虽然按照 [官方文档](https://github.com/git/git/blob/v2.7.4/Documentation/technical/pack-format.txt#L112) 的方式解开了OBJ_OFS_DELTA的内容，
但是我却不知道如何解读，这方面并没有详细的记载，只有找到唯一 [官方又有些诙谐的文档](https://github.com/git/git/blob/v2.7.4/Documentation/technical/pack-heuristics.txt) ，可以读一下，very funny。

希望后续有时间深入源码，再来详细的解释delta(dark corner of git)部分 :)

