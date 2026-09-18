#import "../template.typ": *
#show: conf

#context {
  let is-main-file = state("is-main-file", false).get()
  if not is-main-file {
    outline()
    pagebreak()
  }
}

// #import "@preview/digidraw:0.9.3" as dd
// #dd.wave(
//   (
//     signal: (
//       (wave: "x12.udx34z.5.x", data: "Hello "),
//     )
//   )
// )

// #import "@preview/blockcell:0.1.0" as bc
// #bc.bit-row(width: 100%, show-bits: false, fields: (
//   (bits: 4,  label: [Ver],          fill: white),
//   (bits: 4,  label: [IHL],          fill: yellow),
//   (bits: 16,  label: [DSCP],         fill: purple),
//   (bits: 16, label: [Total Length], fill: red),
// ))

= I2C

Inter-Integrated Circuit 是一种硬件通讯协议，由飞利浦公司设计，
广泛用于将低速外围 IC 连接到控制器

I2C, I2C Primer, SMBus, PMBus

指定寄存器再读 Repeated START

如果严格限定在一个事务内（从第一个 START 到最后一个 STOP，中间不释放总线），那么“先写再读”必须使用 Repeated START，因为写和读的方向切换需要重新发地址帧，而 STOP 会结束事务并释放总线。

如果允许拆成两个独立事务，则可以不用 Repeated START，写成：S → Addr+W → Reg → P，然后 S → Addr+R → Data → NACK → P。但这样会释放总线，可能被其他 Master 抢占，且某些从机在 STOP 后内部寄存器指针会复位或改变。

Repeated START 是 I2C 协议的标准机制，由 NXP（原 Philips）I2C 规范定义，不是 SMBus/PMBus 特有。SMBus 和 PMBus 也基于它，并在某些读命令中明确要求使用。


= SMBus

= PMBus

#h(2em)电源管理总线 #link("https://pmbus.org/")[Power Management Bus]
是开放标准 _数字电源管理协议_，简单、标准、灵活、可拓展以及易于编程，其
PMBus Command 实现了电力系统组件之间的通信，在 I2C 基础上拓展，
相对于 I2C _更鲁棒_（超时强制总线复位）、故障通知（可选）
_SMBALERT 警报线_ 或 _Host Notify Protocol_、支持 _数据包错误校验 PEC_ 

== PMBus Command

#h(2em)PMBus 命令为 _单字节_ 编码，其不是设备的寄存器地址


