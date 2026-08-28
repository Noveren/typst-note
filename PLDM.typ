#import "../typst-note/template.typ": *
#show: conf

#let url = (
  "PMCI":  "https://www.dmtf.org/standards/pmci",
)

#outline()


#pagebreak()
= 介绍

#h(2em)_平台级数据模型_ #link(url.PMCI)[Platform Level Data Model]
（DS0240）
是由国际组织 Distributed Management Task Force (分布式管理任务组) 定
义的一套 _应用层_ 通信协议与规范（*平台管理框架*），提供了标准的
_数据模型_ 和 _信息格式_，定义了对系统固件和系统硬件进行
_管理、监控、控制_ 的方法，旨在实现系统中不同设备之间的高效交互


终端 Terminus 被定义为 PLDM 消息和功能的通信终点，即支持 PLDM 协议并能
被独立寻址和管理的逻辑实体

- 终端网络中拥有唯一 TID

传感器 Sensor
执行器 Effecter

int (*get_state_sensor_field_state)(uint16_t id, uint8_t field_num, uint8_t *state);
该函数直接对应 PLDM 规范中的 GetStateSensorReadings 命令，是对该命令中读取单个传感器、单个字段操作的具体封装。

在PLDM的语境中，FRU 是 Field Replaceable Unit（现场可更换单元） 的缩写。它不仅仅指代物理硬件本身，更核心的是指存储在其中的一套标准化资产信息数据

https://github.com/openbmc/libmctp
https://github.com/openbmc/libpldm


#h(2em)_管理组件传输协议_ #link(url.PMCI)[
Management Component Transport Protocol]（DS0237）

int (*get_sensor_value)(uint16_t id, uint8_t *buf, uint32_t buf_len, uint32_t *actual_len);
int (*get_effecter_value)(uint16_t id, uint8_t *buf, uint32_t buf_len, uint32_t *actual_len);