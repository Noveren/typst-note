#import "../typst-note/template.typ": *
#show: conf

#let url = (
  "kernel-module-0": "https://doc.embedfire.com/linux/imx6/driver/zh/latest/linux_driver/module.html",
  "kernel-module-1": "https://github.com/yifengyou/linux-3.13.0",
  "kernel-build-system": "https://docs.kernel.org/kbuild/index.html#",
  "mmu-0": "https://www.cs.cornell.edu/courses/cs4410/2018su/lectures/lec11-mmu.html",
  "printk": "https://docs.kernel.org/core-api/printk-basics.html",
  "mmio-0": "https://www.geeksforgeeks.org/computer-organization-architecture/memory-mapped-i-o-and-isolated-i-o/",
  "mmio-1": "https://www.embeddedrelated.com/showarticle/1683.php",
);

#h(2em)内核 Linux Kenerl 为宏内核 Monolithic Kernel，将
_核心功能、设备驱动、文件系统等编译为整体_，虽然运行效率高，但若需修改内核
功能时，则需要重新编译整个内核，为应对该问题，Linux 引入了 _内核模块_ 机制。

#h(2em)内核模块 Loadable Kernel Module 是一种在内核运行时加载一组目标代
码来实现某个特定功能的机制，其是具有独立功能的程序，可以单独编译，但必须在
_运行时链接到内核并在内核空间运行_

// TODO 内核模块可由用户手动加载，也可直接编译到内核中由内核在启动时自动加载

== 内核头文件 <linux-headers>

// TODO 内核构建

#h(2em)内核头文件 `linux-headers` 提取自内核源码树，保留了编译时的依赖信
息、特性支持情况等信息，与内核严格对应，提供了内核头文件和内核编译系统，主
要用于 _编译内核模块_ 或 _开发与内核交互的应用程序_

#list(
  [
    *常规发行版*：对应 `linux-headers` 可用包管理器如
    `apt install linux-headers-$(uname -r)` 安装，如此相关文件通常位于
    `/usr/src` 下，可将这些文件打包并在交叉编译环境下使用
  ],
  [
    *定制发行版*：通常会在 SDK 中提供，或者需要使用内核构建系统自行编译生成
  ],
)

```bash
linux-headers-xxx/
├── arch/<ARCH>/          # 平台架构相关
├── include/              # 内核公共头文件
├── Makefile              # 内核 kbuild 系统入口
├── Kbuild
├── Kconfig
├── .config               # 记录内核编译时启动的功能选项
├── Module.symvers        # 记录内核导出符号及其版本校验信息
```

用户可通过 `make -C /path/to/linux-headers/ M=/path/to/src` 调用其中的 
`Makefile` 从而编译出适配内核的内核程序，其中源代码 `/path/to/src` 也应该
使用 `Kbuild` 进行组织（源文件、头文件）


== 内核模块项目

```c
#include <linux/module.h>  // MOUDLE 宏定义
#include <linux/init.h>    // SECTION 宏定义
#include <linux/kernel.h>  // 内核函数

// 入口函数：由 linux/init.h 提供函数修饰 .init.text
static int __init foo_init(void) {
  printk(KERN_EMERG "[ KERN_EMERG ]Module Init.\n");
  return 0;
}

// 卸载函数：由 linux/init.h 提供函数修饰 .exit.text
static void __exit foo_exit(void) {
  printk("[ default ]Module Exit.\n");
}

module_init(foo_init);  // 静态函数指针
module_exit(foo_exit);
MODULE_LICENSE("GPL2"); // 静态常量数据
```

=== 符号导出

宏 `EXPORT_SYMBOL` 位于 `<linux/export.h>` 且一般由 `<linux/module.h>`
间接包含，其核心作用是将内核或内核模块中的符号（函数、全局变量）导出，使其
能够被 _其他内核模块_ 动态调用，其使用场景示例如下：

```c
// A.ko
int add(int a, int b) { return a + b; }
EXPORT_SYMBOL(add);                      // 必须于文件全局作用域
// B.ko
extern int add(int a, int b);            // A.ko 加载后在 B.ko 中使用
```

#list(
  [
    *备注*：编译时──对需外部提供的符号产生 `Warning`，加载时──若符号不存
    在将使得 _加载失败_（注意顺序）
  ]
)

TODO https://zhuanlan.zhihu.com/p/22792718875

`typeof` 在 C23 标准中正式支持，同时在 GNU89 或 GNU11 等作为 GCC/Clang
拓展所支持

=== 内核参数

```c
module_param(name, type, perm);
```

加载时，向模块传入参数





= 内核功能接口

== 内核日志

内核空间可使用 #link(url.at("printk"))[`printk`] 向 _内核日志系统_ 打印
信息，这些信息将被写入内核日志 _环形缓冲区_（异步显示），每条信息都携带
_时间戳_ 且允许设置 _日志级别_，格式化字符基本与 C99 兼容但存在一些拓展和
差异

```c
int printk(const char *s, ...); // /linux/prink.h
```

*日志等级*：`printk` 以每条消息 *开头字符串* `KERN_SOH "<N>"` 确定日志
等级；`KERN_SOH` 为控制字符 `"\001"` 表示 `ASCII Start Of Header` 用于
区分消息是否被设置日志等级；`"<N>"` 为 `"0"~"7"` 表示不同日志等级，*数字越
小，重要性越高*， 相关宏定义于 `/linux/kern_levels.h` 形式为 `KERN_XXX`

#table(align: center + horizon, columns: (1fr, 2fr, 4fr),
  [*级别*], [*`KERN_XXX`*], [*说明*],
  [`0`], [`KERN_EMERG`], [ 紧急，系统不可用 ],
  [`1`], [`KERN_ALERT`], [ 警报，需管理员立即介入 ],
  [`2`], [`KERN_CRIT`], [ 严重，存在硬件错误或软件错误 ],
  [`3`], [`KERN_ERR`], [ 错误，非致命问题 ],
  [`4`], [`KERN_WARNING`], [ 警告，存在潜在问题 ],
  [`5`], [`KERN_NOTICE`], [ 注意，值得记录的事件 ],
  [`6`], [`KERN_INFO`], [ 信息，运行过程中的提示性信息 ],
  [`7`], [`KERN_DEBUG`], [ 调试，仅用于开发调试 ],
  [`c`], [`KERN_CONT`], [ 继续；接续上一消息，_而不添加换行和时间戳_ ],
)
#list(
  [
    *备注*：未指定日志等级的消息采用 `#define KERN_DEFAULT ""` 默认等级
  ],
  [
    *备注*：提供包装 `pr_xxx(fmt, ...)`，在包含 `prink.h` 前声明
    `#define pr_fmt(fmt)` 可定制字符串
  ],
)

*日志查看*：日志常使用 `dmesg` 命令查看，另外，也可通过文件 `/proc/kmsg` 
或设备 `/dev/kmsg` 读取，大多数发行版会将内核日志持久化到文件中，以及，日志
也可以直接打印到控制台（若足够重要）

#table(align: (center + horizon, horizon), columns: (1fr, 4fr),
  [*方法*], [*说明*],
  [控制台查看], [
    #h(2em)文件 `/proc/sys/kernel/printk` 设置控制台日志输出级别（当前、
    默认、最低、启动时），级别不低于当前等级才能打印到控制台 `4 4 1 7`
  ],
  [`dmesg`], [
    ```bash
    $ dmesg | tail -20  # 直接使用 demsg 将获得全部日志
    $ dmesg -l 5,6      # 仅显示 5 和 6 级或使用 xxx 名称
    ```
  ],
)

== 内存管理

=== 输入输出

#h(2em)在启用 MMU 的 MMIO 设备上，需要通过 Linux Kernel 建立物理地址和虚
拟地址之间的映射（在 `vmalloc` 区分配虚拟地址块，然后修改
_内核页表_ 将其映射到物理内存），然后再使用 _访存函数_ 进行输入输出操作

```c
void *ioremap(pyhs_addr_t phys_addr, size_t size); // 建立映射并返回起始位置指针
void iounmap(volatile void *addr);                 // 解除映射
```
#list(
  [
    *备注*：`ioremap` 变体如 `ioremap_nocache`（设备驱动常用）、
    `ioremap_cached` 等通过加入一些映射标志位来影响相关内核页表项设置
  ],
  [
    *备注*：由于历史原因，`write` 和 `read` 系列访存函数采用
    `byte`、`word`、`long`、`quad` 首字母结尾表示宽度；虽然获得了虚拟地
    址，且直接通过指针确实可能访问，但访存函数相对于指针操作有以下优势
    #table(align: (center + horizon, horizon + center), columns: (1fr, 3fr),
      [*可移植性*], [
        可根据不同平台架构展开，保证了跨平台兼容性
      ],
      [*缓存一致性*], [
        `ioremap` 默认 `nocache`，每次读写都与设备交互，保证数据一致性
      ],
      [*内存屏障与执行顺序*], [
        设置内存屏障，保证操作按照代码顺序进行，而不受编译器指令重排影响
      ],
      [*端序处理*], [
        自动处理端序转换，确保数据正确性
      ],
      [*类型检查*], [
        使用 `__iomem` 进行标记，可以配合相关工具或机制进行检查
      ],
    )
    由于以上原因，标准库 `memory.h` 中的内存操作函数不应该用于 MMIO 批量
    操作，而应该使用：
    ```c
    void memset_io(volatile void *dst, int value, size_t size);
    void memcpy_fromio(void *dst, const volatile void *src, size_t size);
    void memcpy_toio(volatile void *dst, const void *src, size_t size);
    ```
  ]
)

#table(align: center + horizon, columns: (1fr, 2fr, 2fr),
  [], [*端口映射* `Port-Mapped I/O`], [*内存映射* `Memory-Mapped I/O`],
  [*内存空间*], [ 独立空间 ], [ 统一空间 ],
  [*访问指令*], [ 专用指令 ], [ 访存指令 ],
)


#h(2em)物理内存 Physical Memory 是计算机系统中的一种 _有限的、可能不连续
的不同架构或实现之间地址定义存在差异的_ 资源，

虚拟内存 Virtual Memory 面向应用程序需求对物理内存进行了抽象，屏蔽了物理
内存的复杂性和各自差异

https://docs.kernel.org/admin-guide/mm/concepts.html

https://www.cnblogs.com/wanglouxiaozi/p/15012403.html


#h(2em)内存管理单元 Memory Management Unit 是一种在内存系统中对 _软件_ 
所访问的 _虚拟地址_ 转换为 _物理地址_ 的模块，其由 Table Walk Unit 和
Translation Lookaside Buffer (TLB) 组成，处理器访问的地址，首先通过
TLB 检查应用缓存的转换关系，若缓存失败，则 Table Walk Unit 将在内存中读取

地址转换、权限管理、内存排序、缓存策略

TODO #link(url.at("mmu-0"))[
  Lecture 10: Hardware support for memory management
]

MMU 由操作系统进行管理

MMU 使得应用程序可以 _虚拟地独占整个内存空间_ 而无需关注实际运行过程中的物
理内存视图


https://docs.kernel.org/driver-api/device-io.html#


#h(2em)Linux 提供了一套 _跨总线和设备_ 的进行输入输出操作的 API，从而允许
设备驱动能够独立于总线类型编写

#h(2em)在 linux 系统中，_内核空间_ 需先使用 `ioremap` 或其衍生函数，建立
物理地址和虚拟地址之间的转换关系，然后使用内核提供的方法（如 `readl`、
`writel` 等）对目标内存进行访问，_用户空间_ 则应该通过相关驱动或其他方式访
问




#link(url.at("mmio-0"))[Memory Mapped IO and Isolated IO]

#link(url.at("mmio-1"))[Memory Mapped IO in C]


寄存器类型

#table(align: (center + horizon, horizon), columns: (1fr, 7fr),
  [*类型*], [*说明*],
  [`RO`],
  [],
  [`RW`],
  [],
  [`HWC`],
  [
    #h(2em)硬件清零 `Hard-Ware Clear` 类型的寄存器用于触发某种硬件操作，
    待操作完成后，改寄存器将被硬件自动清零（轮询）以表示操作完成

  ],
  [`WMF`],
  [
    #h(2em)写掩码字段 `Write-Masked Field` 类型的寄存器通常分为
    `掩码域:数据域` 等长的两段，写入时，仅应用掩码域描述的数据域位置来修改
    寄存器；相对于普通寄存器，其“读-改-写”一步到位（原子操作），保证了并发
    安全性
  ],
)




= 内核构建系统

#h(2em)Linux #link(url.at("kernel-build-system"))[内核构建系统] 通常称
为 _Kbuild_，负责协调内核编译过程中的各个环节，其基于 GNU Make 实现并进行
了一定的扩展和优化，便于开发者灵活配置并构建得到 _内核镜像_ 和 _内核模块_，
其主要由以下文件：

// ----------------- 以下再进行整理

#h(2em)`Kbuild` 是 Linux 内核编译系统，负责协调内核编译过程中的各个环节，
基于 Makefile 系统实现并进行了大量的扩展和优化（_定制 Makefile 文件，
称作写作 Kbuild 文件_），用于描述内核各个部分的编译规则、依赖关系以及如何
将它们组合成一个完整的内核镜像

#list(
  [
    *特性*：_模块构建_，内核功能由模块组织，可按照 `obj-y`（编入内核）
    或 `obj-m`（动态加载）分别编译
  ],
  [
    *特性*：_依赖管理_，通过分析 `#include` 及 Makefile 规则自动处理源文
    件之间的依赖关系
  ],
  [
    *特性*：_编译控制_，通过控制选项定制编译过程，如调整优化选项、
    添加调试信息等，还支持 _条件编译模块_
  ],
  [
    *特性*：_平台支持_，通过 `arch/$(ARCH)` 调整编译过程实现跨平台支持
  ],
)

```bash
├── Makefile             # 顶层：遍历内核源码树构建 vmlinux 或 modules
├── .config              # 内核配置文件，在内核配置过程中生成
├── arch/<arch>/Makefile # 架构相关
├── scripts/Makefiles.*  # 对于所有 Kbuild 的通用规则
├── Kbuild
├── Kconfig
```

#quote()[
  普通开发者（驱动、协议、文件系统 ......）需要了解 Kbuild 从而维护其开发
  子系统的编译过程
]

#grid(align: (center + horizon, horizon), columns: (12fr, 10fr),
  image("assets/Kbuild.png", width: 95%),
  [
    #h(2em)使用 `make` 命令执行内核的 `Makefile`，默认编译目标为
    `vmlinux` 并在内核源码目录得到编译产物，若指定 `M=DIR`，则编译目标为
    `modules` 并在模块源码目录得到编译产物
  ]
)


*代码组织*：Kbuild 以 `obj-y obj-m NAME-y` 等 _目标路径列表变量_ 来组
织代码，使用 `+= /path/to/src.o` 指定源文件，使用 `+= /path/to/` 调用子
目录的 Kbuild，使用 `+= name.o` 引入已知规则的目标文件

#table(align: center + horizon, columns: (2fr, 5fr),
  [*变量*], [*说明*],
  [`obj-y`], [ 合并到 `built-in.o` 并最终链接到 vmlinux ],
  [`obj-m`], [ 每一个目标文件都被链接为独立的 `<module>.ko` 文件],
  [`NAME-y`], [ 链接每个目标文件为 `<name>.o` ],
)

*编译选项*：每一个 Kbuild 有 _局部全局的_ `ccflags-y asflags-y ldflags-y`
用于设置编译选项

#table(align: center + horizon, columns: (1fr, 1fr),
  [*形式*], [*说明*],
  [`ccflags-y asflags-y ldflags-y`], [ 仅当前 Kbuild 生效 ],
  [`subdir-ccflags-y subdir-asflags-y`], [ 当前 Kbuild 及子目录生效 ],
  [`CFLAGS_<src>.o AFLAGS_<src>.o`], [ 仅指定文件生效 ],
)

TODO 其他内容待续

*可用参数*：

#table(align: center + horizon, columns: (1fr, 1fr),
  [*参数*], [*说明*],
  [`ARCH=<arch>`], [ 应用 `arch/<arch>` 所描述的架构 ],
  [`CROSS_COMPILE=<prefix>`], [ 使用 `<prefix>-gcc` 作为编译器 ],
)