---
title: python virtual env with conda
date: "2019-09-20T09:08:00Z"
categories:
- Python
tags: 
- python
- machine-learning
featured_image: images/python.jpg
aliases:
- /2019/09/20/pipenv-with-conda.html
---

Anaconda 是一个非常流行的 python 集成环境，用于科学计算，机器学习等。
它主要的优势在于，新的包管理器 conda 比 pip 更容易管理 numpy scipy 之类的工具包（安装涉及 C 代码编译）。

另外在开发过程中，保持不同项目使用各自独立的开发环境是一个良好的习惯。
在 python 世界，virtualenv 是最广泛的选择，pipenv 的底层使用的也是它。
conda 内部也有 env 的概念（默认是 base），可以针对不同的项目进行环境的分离，并且对一些开发工具有良好的支持（比如 VS Code 中的 Anaconda 插件）。

最近在配置 emacs 下的 python 开发环境，相比之下在 Anaconda 方面的插件还没有那么成熟，经过搜索发现，
存在可以集成 pipenv[^1] 和 conda env 的方案[^2]。

```bash
$ pipenv --python=$(conda run which python) --site-packages
```

上面的命令，可以将 conda env 作为 pipenv virtualenv 来使用，集成了所有 Anaconda 集成的开发库！

更可贵的是，在使用 conda 升级开发库之后，可以再次重建 virtualenv 获得更新带来的好处。
并且，virtualenv 环境更容易被其它编码工具支持，比如 emacs :)。

[^1]: https://pipenv.readthedocs.io/en/latest/advanced/#pipenv-and-other-python-distributions
[^2]: https://stackoverflow.com/questions/50546339/pipenv-with-conda
