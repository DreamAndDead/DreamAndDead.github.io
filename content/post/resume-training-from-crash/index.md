---
date: "2020-03-04T00:00:00Z"
tags: keras machine-learning deep-learning
title: keras 如何从中断处继续训练
---

深度学习的网络模型层次很深，训练模型的时间也很长，没有强大的算力，调试模型的周期就会
变得非常之长，工作的效率自然就降了下来。

获取算力资源的途径，无论是通过云主机，主机租赁，还是个人组建工作站，都代价不菲。

但是有一点是确定的，无论使用哪一种方式，都会遇到意外，比如断电，宕机，训练过程被迫中断。
如果没有一点准备，就意味着再次从头开始训练，无疑是对效率的又一次打击。

所以我们要在训练伊始，就要做好训练被中断的准备，以及如何从中断处继续开始。

示例项目地址：[DreamAndDead/resume-training-example][example]

<!--more-->

# 运行前建议

这一节和中断无关，但是对于效率的重要性同样重要。

每当提出一个网络模型，在准备训练之前，
建议先在一个性质相似的小型数据集上运行，观察模型质量，
比如手写识别使用 `mnist`，图片识别使用 `cifar10`，
这样有两个好处，
1. 排除代码运行错误
2. 对模型的基本性能有粗略的估计

这样就可以提前修复错误，修正质量不佳的模型，免去在大型数据集上浪费时间。

# 训练过程

在预防训练中断之前，先来了解完整的训练过程是怎样的。

训练模型主要涉及以下三部分，
1. 代码，指导训练过程，文件大小可忽略不计
2. 训练数据集，文件相对比较多，总体容量比较大
3. 训练产出，通常是模型，训练日志，模型精度数据，模型大小一般是 G 级别左右
  
所谓训练过程即，**通过代码构建训练方式，从训练数据集中，得到模型产出，以及评估模型质量的数据。**

训练开始，需要
- 数据预处理方法，比如图片 `reshape`，灰度化，以匹配模型输入
- 标签编码方法，比如 `one-hot` 编码
- 训练测试数据的分割方法，通常按比例分割训练数据和测试数据

训练时的状态
- 当前 `epoch` 序号
- 当前模型权重
- 训练日志，比如当前模型的 `acc, loss, val acc, val loss`
- 当前优化器状态，比如在训练中，使用了随过程 `lr` 可变的优化器

训练产出
- 数据预处理方法
- 标签编码方法
- 训练日志
- 最佳模型，按 `min(val_loss)` 的方式或者 `max(val_acc)` 方式
- 模型质量报告，比如 `sklearn.metrics.classification_report`


我们的目标是，确保整个训练过程最终能得到训练产出。

## 中间状态

在训练过程中，何时发生中断是不可知的，为了确保实现我们的目标，即使中断后再次运行，训练效果应该和没有中断一样。
这就需要在中断时，时刻保存中间状态。

*这里的中间状态以 `epoch` 为单位的，如果在 `epoch` 中间中断，则无法恢复到相应的 `batch` 继续训练。*

以下就从中间状态的角度，对训练过程的每个要素进行审视。

### 数据预处理方法

数据预处理方法，通常是处理训练数据的函数，使数据和模型输入保持一致，
不存在状态，是训练代码的一部分。

它不属于中间状态，但是算作最终产出的一部分，因为其它人在使用模型的时候，对于新的数据，
也需要同样的预处理方法。

不需要单独存储，使用者通过 `import` 导入即可。

### 标签编码方法

标签编码方法，这一步在训练一开始就要安排，而且编码表是产出的一部分（因为模型使用者要对模型输出进行解读），
需要存储，但是不作为中间状态，因为此时模型还未开始训练。

如果使用 `sklearn` 提供的类进行编码，比如 `one-hot encode`，

```python
from sklearn.preprocessing import LabelBinarizer

le = LabelBinarizer()
Y = le.fit_transform(Y)
```

可以使用对象序列化的方式存储 `label encoder`

```python
import pickle

pickle.dump(le, open('le.pkl', 'wb'))
```

使用者可以通过反序列化加载 `label encoder`，用于解读模型输出

```python
import pickle

le = pickle.load(open('le.pkl', 'rb'))

pred = model.predict(X)
Y = le.inverse_transform(pred)
```

### 训练测试数据的分割方法

数据分割本身就本着随机的原则，如果训练的过程中发生中断，
之后再次开始训练，数据就可能重新发生分割。

其实再一次的分割，可能和之前分割得到的数据不同，但是同样本着随机的原则。
所以这一点可以算作中间状态，也可以不算。

如果想要进行准确的控制，可以通过 `random_state` 来控制。

```python
from sklearn.model_selection import train_test_split

trainX, testX, trainY, testY = train_test_split(X, Y, test_size=0.2, random_state=1)
```

### 当前 `epoch` 序号

训练是以 `epoch` 为单位的，中断发生在哪个 `epoch`，这一点绝对是需要记录的中间状态。

这一点可以在 `keras callback` 中来实现。

```python
class CustomCallback(keras.callbacks.Callback):
    def on_epoch_end(self, epoch, logs=None):
	    # save the epoch
```

当从中断处再次运行时，需要加载上次中断的 `epoch` 序号，传入训练过程。

```python
model.fit(initial_epoch=last_epoch+1) # +1，想想为什么
```


### 当前模型权重 和 当前优化器状态

当前模型权重是最重要的中间状态，还有和它一起的优化器状态。

为什么将两者放在一起，因为 `keras` 提供了单独存储权重的方法，但是没有提供单独存储优化器的方法。
所以这两者需要[存储在一起][keras faq]。

存储模型和优化器

```python
model.save(path)
```

加载两者

```python
import keras

model = keras.models.load_model(path)
```

### 训练日志

在每个 `epoch` 结束，`keras` 都会衡量当前模型在训练集和验证集上的表现，比如 `acc, loss`。
这些训练日志，用于在整个训练过程中衡量模型的质量，不仅作为中间状态，还作为最终产出。

和 `epoch` 序号一样，可以通过 `on_epoch_end` 来存储，它可以保存为文本形式，也可以保存为图形。

如果要保存图形，最好不依赖 gui 库。

```python
import matplotlib
matplotlib.use("Agg")
```

### 最佳模型

在训练结束后，我们希望得到一个效果最佳的模型作为最终结果。

但是要在整体过程中，选择哪一个模型是最佳模型，每个人都有自己的判断标准。
选取最大 `val_acc` 的模型是一种常用的办法。

这里要提到一点，如果使用 `keras` 提供的 `ModelCheckpoint` 来记录 `best model`，
如果发生中断，`ModelCheckpoint` 在再次运行时，其中记录的最佳 `val_acc` 会被清除为 `-inf`。

也就是说再次从中断处运行，对于 `ModelCheckpoint` 就像是重新开始一样，这一定不是你想要的结果。

所以记录最佳模型的过程，最好通过自定义 `keras callback` 来做。

### 模型质量报告

这一点并不必需。

在训练结束后，保存相关数据报告，不作为中间状态，用文本存储即可。

```python
from sklearn.metrics import classification_report

predictions = model.predict(testX, batch_size=64)
report = classification_report(testY.argmax(axis=1),
                               predictions.argmax(axis=1))

with open('report.txt', 'w') as f:
    f.write(report)
```

# 结语

通过这种方式，定可以使训练过程更加健壮，提高工作效率。

完整代码可参考 [DreamAndDead/resume-training-example][example]


# refs

1. [keras cn docs](https://keras-cn.readthedocs.io/)
2. [keras callback guide](https://keras.io/callbacks/)
3. project [HarborZeng/resume_traning](https://github.com/HarborZeng/resume_traning)


[keras faq]: https://keras-cn.readthedocs.io/en/latest/legacy/getting_started/FAQ/#save_model
[example]: https://github.com/DreamAndDead/resume-training-example
