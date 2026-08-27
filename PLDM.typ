#import "../typst-note/template.typ": *
#show: conf

#let url = (
  "DMTF":  "https://www.dmtf.org/standards/pmci",
)

#outline()

#pagebreak()
= 介绍

#h(2em)_平台级数据模型_ #link(url.DMTF)[Platform Level Data Model]
是由国际组织 Distributed Management Task Force (分布式管理任务组) 定
义的一套 _应用层_ 通信协议与规范（*平台管理框架*），提供了标准的
_数据模型_ 和 _信息格式_，定义了对系统固件和系统硬件进行
_管理、监控、控制_ 的方法，旨在实现系统中不同设备之间的高效交互