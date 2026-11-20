#import "../template.typ": *
#show: conf

#context {
  let is-main-file = state("is-main-file", false).get()
  if not is-main-file {
    outline()
    pagebreak()
  }
}

#h(2em)目录 `/sys` 是内核在内存中构建的 _伪文件系统_，用于用户可
从 *用户空间* 查看和配置内核内部的数据结构，其从不同维度对系统中的 _设备_
和 _内核对象_ 进行了分类和组织，以结构化的方式呈现设备、驱动、总线等硬件与
内核对象之间的关系

```
.
├── firmware/                 # 固件相关
├── power/                    # 电源相关
├── hypervisor/               # 虚拟化
├── fs/                       # 文件系统
├── kernel/                   # 内核状态信息和可调参数
├── module/                   # 已加载内核模块
├── devices/                  # 设备树 - 链接目标
├── dev/                      # 设备：major:minor
│   ├── block/ 
│   └── char/
├── block/                    # 设备：块设备
├── bus/                      # 设备：按所需总线分类
|   ├── platform              # 平台总线
│   │   ├── devices           # 平台设备
│   │   └── derivers          # 平台驱动
│   └── <bus> 
└── class/                    # 设备：按功能类型分类
    └── hwmon                 # 硬件监控子系统
```

https://www.cnblogs.com/xiaojiang1025/p/6367061.html

= 平台设备驱动

平台总线：为解决这种驱动代码和设备信息耦合的问题，Linux提出了platform bus(平台总线)的概念，即使用虚拟总线将设备信息和驱动程序进行分离，设备树的提出就是进一步深化这种思想，将设备信息进行更好的整理。平台总线会维护两条链表，分别管理设备和驱动，当一个设备被注册到总线上的时候，总线会根据其名字搜索对应的驱动，如果找到就将设备信息导入驱动程序并执行驱动；当一个驱动被注册到平台总线的时候，总线也会搜索设备。总之，平台总线负责将设备信息和驱动代码匹配，这样就可以做到驱动和设备信息的分离

*设备信息* 包括硬件地址、硬件中断等 _硬件信息_ 和多种多样 _软件信息_

#list(
  [
    *设备树*：DSL 声明，内核设备树中提取设备信息，并注册到相应总线
  ],
  [
    *硬编码*：C 代码注册，可编译到内核 _静态使用_，也可编译为内核
    模块 _动态加载_；资源描述结构体如下
    ```c
    // #include <linux/ioport.h>
    struct resource {
      resource_size_t start; // 起始物理地址 / 中断号
      resource_size_t end;   // 终止物理地址 /   -
      const char *name;
      unsigned long flags;   // 资源类型；可使用宏便捷声明某类资源
      unsigned long desc;
      struct resource *parent, *sibling, *child;
    };
    ```
  ],
)

*平台设备*：使用继承自 `struct device`
的 `struct platform_device` 表示设备

```c
struct platform_device {
	struct device	dev;
	const char	*name;
	int		id;                  // 对应设备数量；仅一个设备使用 -1 
	u32		num_resources;
	struct resource	*resource;
  // ...
};
```


*平台驱动*：使用继承自 `struct device_driver`
的 `struct platform_driver` 表示驱动

#grid(columns: (1fr, 1fr), gutter: 4pt,
```c
// #include <linux/device.h>
struct device_driver {
	const char		*name;
	struct module		*owner;
	const struct of_device_id	*of_match_table;

  // ...
};
```,

```c
// #include <linux/platform_device.h>
struct platform_driver {
	int (*probe)(struct platform_device *);
	int (*remove)(struct platform_device *);
	struct device_driver driver;
	const struct platform_device_id *id_table;
  // ...
};
```
)

单驱动可匹配多设备，可向 `struct platform_driver` 填充相应内容
用于匹配，匹配方式按 _优先级_ 排序如下

#enum(
  [
    *设备树匹配*：声明 `struct of_device_id` _表_ 匹配 `compatible`，
    以 _零成员_ 作为末尾哨兵
  ],
  [
    *硬编码匹配*：声明 `struct platform_device_id` _表_ 匹配 `name`，
    以 _零成员_ 作为末尾哨兵
  ],
  [
    *硬编码匹配*：若 `driver name` 和 `platform_device name` 一致
  ],
)

`/sys/bus/i2c/devices`
`/sys/bus/platform/devices`


= Linux I2C 子系统

```
.
├── class/
│   └── i2c-dev/       # 设备：总线控制器 i2c-N 
├── bus/i2c/
│   ├── devices 
│   │   ├── i2c-N      # 设备：总线控制器 
│   │   └── N-ADDR     # 设备：设备
|   └── drivers        # 驱动：设备驱动
└── devices/
```

#h(2em)Linux I2C 子系统遵循设备驱动模型

#table(
  align: (center + horizon, center + horizon, horizon), 
  columns: (auto, 1fr, 2fr),
  [], [*概念*], align(center)[*说明*],
  table.cell(rowspan: 2)[总线],
  [`struct i2c_adapter`], [
    适配器，即 I2C 总线控制器本身
  ],
  [`struct i2c_algorithm`], [
  ],
  [驱动], [`struct i2c_driver`], [
  ],
  [设备], [`struct i2c_client`], [
  ],
)

*总线注册*：

*设备驱动*：