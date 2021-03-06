---
title: Bellman Equation Deduction
date: "2020-08-27T11:09:00Z"
categories:
- Algorithm
tags:
- algorithm
- rl
featured_image: images/featured.jpeg
enableMathJax: true
aliases: /2020/08/27/bellman-equation.html
---

详细理解 Bellman 方程的证明过程。

<!--more-->

# Prequisite

## 条件概率和独立性

条件概率是概率论是最为基础的概念。在事件 B 发生的条件下，A 事件发生的概率等于 A B 事件同时发生的概率除以 B 事件发生的概率。

$$
P(A|B) = P(AB) / P(B)
$$

移项得到

$$
\begin{equation} \label{cond}
 P(AB) = P(A|B)P(B) \tag{1}
\end{equation}
$$

如果 A B 两个事件相互独立，彼此没有依赖关系，则 A B 同时发生的概率等于 A 事件发生的概率乘以 B 事件发生的概率。

$$
P(AB) = P(A)P(B)
$$

在相互独立的前提下，综合可知

$$
\begin{equation} \label{ind}
 P(A|B) = P(A) \tag{2}
\end{equation}
$$

## 全概率公式

若事件 $B_1, B_2, ..., B_n$ 是全空间 $\Omega$ 的一个划分，
 
$$
\sum_{i=1}^n P(B_i) = 1
$$
 
则

$$
P(A) = \sum_{i=1}^n P(AB_i)
$$
 
进一步地，根据 $\eqref{cond}$ 可得

$$
\begin{equation} \label{full}
 P(A) = \sum_{i=1}^n P(A | B_i) P(B_i) \tag{3}
\end{equation}
$$

$\eqref{full}$ 是理解之后公式变化的要点。

# Value function

RL 的基础思想很简洁，Agent 不断和 Env 相交互，以最大化收益为目标。

在 MDP 框架下，Agent 选择 Action 影响 Env，Env 反馈 State 和 Reward。

$$
S_0, A_0, R_1, S_1, A_1, R_2, S_2, A_2, ...
$$

Env 的行为完全由 $p(s', r|s, a)$ 来决定，

$$
\sum_{s'} \sum_r p(s', r|s, a) = 1
$$

Agent 在 t 时刻之后所能得到的全部收益为

$$
\begin{equation}
 G_t = \sum_{k=0}^{\infty} \gamma^k R_{k+t+1}
\end{equation}
$$

当然 $G_t$ 不是孤立的存在，因为后续的收益和 agent 当前所处的状态以及后续使用的策略（policy）相关。

定义 state value function，衡量 agent 在 t 时刻处于 s 状态，后续使用策略 $\pi$ 可得到的累计收益。

$$
V_\pi(s) = E_\pi[G_t | S_t = s]
$$
 
进一步地，假如 agent 已经 在 t 时刻已经采取某一动作 a，定义 state action value function 为在此之后可得到的累计收益。

$$
Q_\pi(s, a) = E_\pi[G_t| S_t = s, A_t = a]
$$

事实上，由于行为和反馈不断循环的特性，$V_\pi(s)$ 和 $Q_\pi(s, a)$ 存在着一定的关系。
 
\begin{align}
V_\pi(s) &= E_\pi[G_t | S_t = s] \nonumber \\\\\\
         &= \sum_a \pi(a|s) E_\pi[G_t| S_t = s, A_t = a] \nonumber \\\\\\
         &= \sum_a \pi(a|s) Q_\pi(s, a) \label{vq} \tag{4}
\end{align}

推导过程利用了 \eqref{full}，其中
 
$$
\sum_a \pi(a|s) = 1
$$
 
至于 Q 则复杂一点，
 
\begin{align}
Q_\pi(s, a) &= E_\pi[G_t| S_t = s, A_t = a] \nonumber \\\\\\
            &= E_\pi[R_{t+1} + \gamma G_{t+1}| S_t = s, A_t = a] \nonumber \\\\\\
            &= E_\pi[R_{t+1} | S_t = s, A_t = a] + \gamma E_\pi[G_{t+1}| S_t = s, A_t = a] \nonumber
\end{align}
 
分成两部分来看，前一部分，
 
$$
E_\pi[R_{t+1}| S_t = s, A_t = a] = \sum_r p(r | s, a) r
$$
 
而
 
$$
p(r | s, a) = \sum_{s'} p(s', r | s, a)
$$
 
（依旧是 \eqref{full}，看出来了吗）
 
综合可得
 
$$
E_\pi[R_{t+1}| S_t = s, A_t = a] = \sum_r p(r | s, a) r = \sum_r \sum_{s'} p(s', r | s, a) r
$$
 
再来看另一项
 
$$
E_\pi[G_{t+1}| S_t = s, A_t = a] = \sum_{s'} p(s' | s, a) E_\pi [G_{t+1} | S_{t+1} = s', S_t = s, A_t = a ]
$$
 
（依旧是 \eqref{full}）
 
其中
 
$$
p(s' | s, a) = \sum_r p(s', r | s, a)
$$

（依旧是 \eqref{full}）

根据 MDP 的定义， $S_t A_t$ 只影响 $R_{t+1}$，和 $R_{t+2}$ 并不相关（相互独立），回忆 \eqref{ind}，综合可知
 
$$
E_\pi[G_{t+1}| S_t = s, A_t = a] = \sum_{s'} \sum_r p(s', r | s, a) E_\pi [G_{t+1} | S_{t+1} = s'] = \sum_{s'} \sum_r p(s', r | s, a) V_\pi(s')
$$
 
$$ 
\begin{equation} \label{qv}
  Q_\pi(s, a) = E_\pi[G_t| S_t = s, A_t = a] = \sum_{s'} \sum_r p(s', r | s, a)[r + \gamma V_\pi(s')] \tag{5}
\end{equation}
$$
  
# Recursive format
 
利用 \eqref{vq} 和 \eqref{qv}，进一步推出各自 value function 的递归形式，

$$
V_\pi(s) = \sum_a \pi(a|s) Q_\pi(s, a) = \sum_a \pi(a|s) \sum_{s'} \sum_r p(s', r | s, a)[r + \gamma V_\pi(s')]
$$
 
 
$$
Q_\pi(s, a) = \sum_{s'} \sum_r p(s', r | s, a)[r + \gamma V_\pi(s')] = \sum_{s'} \sum_r p(s', r | s, a)[r + \gamma \sum_{a'} \pi(a'|s') Q_\pi(s', a')] 
$$
 
 
