#import "../template.typ": *
#show: conf

#context {
  let is-main-file = state("is-main-file", false).get()
  if not is-main-file {
    outline()
    pagebreak()
  }
}

= PID

#h(2em)比例-积分-微分控制器 Proportional-Intetral-Derivative
Controller 由 _比例单元_、_积分单元_、_微分单元_ 组成，通过调节各单元的
增益 $K_p$、$K_i$、$K_d$ 来调节控制器特性，主要适用于基本线性，且动态
特性不随时间变化的单变量系统，由于其 _不要求系统建模就能实现基本控制_ 而
被广泛使用

#h(2em)控制系统通过调整 _系统参数_ $u$ 控制 _可观测_ 被控
_系统状态_ $y$ 跟踪 $y_t$ 尽量使得 _误差_ $epsilon -> 0$，
对于 PID 控制器：

#table(
  align: center + horizon,
  columns: (auto, auto, 3fr, 3fr), 
  inset: 8pt,
  [*控制器*], [$u_k=$（偏置可选）], [*性质*], [*特性*],
  [P], 
  $
    K_p dot epsilon_k
  $, [
    按 _当前误差_ 比例输出
  ], [ 简单快速 \ 稳态误差 ],
  [PI], 
  $
    K_p dot epsilon_k + K_i sum^k_(n=0) epsilon_n
  $, [
    累积 _历史误差_ 调整输出
  ], [ 稳态精度 \ 振荡过冲、积分饱和 ],
  [PID], 
  $
    K_p dot epsilon_k + 
    K_i sum^k_(n=0) epsilon_n + 
    K_d dot [epsilon_k - epsilon_(k-1)]
  $, [
    参考 _误差变化_ 调整输出
  ], [ 增加阻尼 \ 噪声放大、微分冲击 ],
  [PD], 
  $
    K_p dot epsilon_k + K_d dot [epsilon_k - epsilon_(k-1)]
  $, [], [],
)

#list(
  [
    *备注*：
  ]
)

$
  K dot (
    epsilon(t)
    + 1/T_i integral epsilon(t) "d"t
    + T_d ("d"epsilon(t)) / ("d"t)
  )
  ==>
  K dot (
    epsilon_k + 
    T/T_i sum^k_(n=0) epsilon_n + 
    T_d/T dot [epsilon_k - epsilon_(k-1)]
  )
$

#table(align: center + horizon, columns: (1fr, 1fr, 1fr, 1fr),
  table.cell(rowspan: 2)[*性能指标*], 
  table.cell(colspan: 3)[*参数*],
  [$K_p$ 增大], [$K_i$ 增大], [$K_d$ 增大],
  [偏差], [$arrow.t$], [$arrow.t$], [$arrow.b$], 
  [稳态误差], [$arrow.b$], [], [], 
  [超调量], [$arrow.t$], [$arrow.t$], [$arrow.b$], 
  [振荡频率], [$arrow.t$], [$arrow.t$], [$arrow.t$], 

)

http://www.meidp.sdu.edu.cn/info/1018/1127.htm

== 参数整定

https://doc.embedfire.com/motor/motor_tutorial/zh/latest/improve_part/PID_parameter_tuning.html

临界比例法：对于 P 控制器，调节 $K$ 使得工作在 _线性区的_ 高阶系统出现
_等幅振荡_，记此时有临界增益和 _临界周期_ $K_u$ 和 临界周期 $T_u$，于是按经验参数有：

#table(align: center + horizon, columns: (1fr, 1fr, 1fr, 1fr),
  [*控制器*], $K_p$, $T_i$, $T_d$,
  [P], $0.5 K_u$, [], [],
  [PI], $0.45 K_u$, $0.83 T_U$, [],
  [PID], $0.6 K_u$, $0.50 T_U$, $0.125 T_u$,
)


// === 衰减曲线法

// === 经验整定法