#import "../template.typ": *
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

#outline()
#pagebreak()

#include "compilation.typ"

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

static int debug_level = 0;
module_param(debug_level, int, 0644);
MODULE_PARM_DESC(debug_level, "Debug level (0=off, 1=info, 2=verbose)");

$ insmod /path/to/module.ko debug_level=1
```

#pagebreak()
= 内核功能接口

== 内核通用 `<linux/kernel.h>`

=== 内核日志 `<linux/printk.h>`

#h(2em)内核空间可使用 #link(url.at("printk"))[
  `int printk(const char *s, ...);`
] 向 _内核日志系统_ 打印信息，这些信息将被写入内核日志 _环形缓冲区_
（异步显示），每条信息都携带 _时间戳_ 且允许设置 _日志级别_，格式化字符
基本与 C99 兼容但存在一些拓展和差异

#quote()[
*日志等级*：`printk` 以每条消息 *开头字符串* `KERN_SOH "<N>"` 确定日志
等级；`KERN_SOH` 为控制字符 `"\001"` 表示 `ASCII Start Of Header` 用于
区分消息是否被设置日志等级；`"<N>"` 为 `"0"~"7"` 表示不同日志等级，*数字越
小，重要性越高*， 相关宏定义于 `linux/kern_levels.h` 形式为 `KERN_XXX`

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
    *备注*：提供包装 `pr_xxx(fmt, ...)`；在包含 `prink.h` 前声明
    `#define pr_fmt(fmt)` 可 _定制字符串_
  ],
  [
    *备注*：包装 `pr_debug` 提供两种版本，若编译内核时
    启用 `DYNAMIC_DEBUG` 相关功能（`.config`）则使用 _动态版本_，否则
    根据 `DEBUG` 宏编译时剔除，前者可动态配置输出
    ```bash
    # 动态开关 整个模块、指定文件、指定函数 的 pr_debug 输出
    $ echo "module [<module>] [file <file>.c] [func <func>] [+p -p]" \
      | sudo tee /proc/dynamic_debug/control
    ```
  ],
)
]

#quote()[
*日志查看*：日志常使用 `dmesg` 命令查看，另外，也可通过文件 `/proc/kmsg` 
或设备 `/dev/kmsg` 读取，大多数发行版会将内核日志持久化到文件中，以及，日志
也可以直接打印到控制台（若足够重要）

#table(align: (center + horizon, horizon), columns: (1fr, 4fr),
  [*方法*], align(center)[*说明*],
  [控制台查看], [
    #h(2em)文件 `/proc/sys/kernel/printk` 设置控制台日志输出级别（当前、
    默认、最低、启动时），级别不低于当前等级才能打印到控制台 `4 4 1 7`，临时修改命令：
    ```bash
    $ sudo sh -c "echo '8 4 1 7' > /proc/sys/kernel/printk"
    ```
  ],
  [`dmesg`], [
    ```bash
    $ dmesg | tail -20  # 直接使用 demsg 将获得全部日志
    $ dmesg -l 5,6      # 仅显示 5 和 6 级或使用 xxx 名称
    ```
  ],
)
]

=== 基本类型 `<linux/types.h>`

=== 基本定义 `<linux/stddef.h>`

#table(align: center + horizon, columns: (1fr, 2fr),
  [*符号*], [*说明*],
  [`NULL`], [
    `#define NULL ((void *)0)`
  ],
  [布尔], [
    `enum { false = 0, true 1 }` \
    类型定义 `bool` 位于 `types.h`；内核开发不应该使用 `stdbool.h`
  ],
  [`offsetof(type, member)`], [
    得结构体 `type` 成员 `member` 偏移，现多为编译器实现，旧实现为：\
    `( (size_t)(&((type *)0)->member) )`
  ]
)


=== 成员所属结构体 `container_of`

#grid(align: horizon, columns: (1fr, 2fr), gutter: 4pt, 
  [
    #h(2em)内核宏 `container_of` 可根据结构体 `type` 成员 `member` 的
    地址 `ptr` 获得 _该结构体实例_ 的指针（右侧仅描述实现思路）
  ],
  [
    ```c
    #define container_of(ptr, type, memeber) ({              \
      const typeof(((type *)0)->member) *__mptr = (ptr);     \
      ((type *)((char *)__mptr - offsetof(type, member)));   \
    })
    ```
  ]
)

#list(
  [
    *备注*：拓展（或 `C23`）运算符 `typeof` 可在编译时获得表达式类型，
    会保留类型限定符，不可用于位域
  ],
  [
    *备注*：拓展 _语句表达式_ `({ ...; ...; })` 的值等于最后表达式，若非
    表达式推导为 `void` 导致编译错误
  ],
)

=== 编译期类型检查 `<linux/typecheck.h>`

#grid(align: horizon, columns: (1fr, 1fr), gutter: 4pt, 
  // [],
  [
    ```c
    #define typecheck(type,x) ({        \
      type __dummy; typeof(x) __dummy2; \
      (void)(&__dummy == &__dummy2); 1; \
    })
    ```
  ],
  // [],
  [
    ```c
    #define typecheck_fn(type,function) ({	\
      typeof(type) __tmp = function;        \
      (void)__tmp;                          \
    })
    ```
  ]
)




== 内存管理

=== 输入输出 `<linux/io.h>`

#h(2em)在启用 MMU 的 MMIO 设备上，需要通过 Linux Kernel 建立物理地址和虚
拟地址之间的映射（在 `vmalloc` 区分配虚拟地址块，然后修改
_内核页表_ 将其映射到物理内存），然后再使用 _访存函数_ 进行输入输出操作

```c
void *ioremap(pyhs_addr_t phys_addr, size_t size); // 映射并返回起始地址
void iounmap(volatile void *addr);                 // 解除映射
```
#list(
  [
    *备注*：`ioremap` 变体如 `ioremap_nocache`（设备驱动常用）、
    `ioremap_cached` 等通过加入一些映射标志位来影响相关内核页表项设置
  ],
  [
    *备注*：经典 `write` 和 `read` 访存函数采用
    `byte`、`word`、`long`、`quad` 首字母结尾表示宽度；为 _明确宽度_，
    可使用 `iowrite` 和 `ioread` 系列；为 _重复操作_，可使用 `*s` 或
    `*_rep` 系列；（默认非 `relaxed`，另有衍生）
  ],
  [
    *备注*：虽然获得了虚拟地址，且直接通过指针确实可能访问，但访存函数相对
    于指针操作有以下优势
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
    #quote()[
    由于以上原因，标准库 `memory.h` 中的内存操作函数不应该用于 MMIO 批量
    操作，而应该使用：
    ```c
    void memset_io(volatile void *dst, int value, size_t size);
    void memcpy_fromio(void *dst, const volatile void *src, size_t size);
    void memcpy_toio(volatile void *dst, const void *src, size_t size);
    ```
    可使用 _结构体描述寄存器结构_，但仍应该使用访存函数 _通过成员地址指针_
    `&base->reg`访问；编译器为 CPU 高效访问默认将在结构体成员间填充字节，
    使得成员在其自身大小的整倍数上，因此，为确保结构体成员的顺序和类型与硬
    件寄存器完全一致，应该禁用编译器优化对齐：
    ```c
    struct reg_t { /* ... */ }  __attribute__((packed)); // GCC/Clang
    ```
    - *备注*：使用 `static_assert` 和 `offset_of` 编译期检查确保偏移正确
    ]
  ]
)

#table(align: center + horizon, columns: (1fr, 2fr, 2fr),
  [], [*端口映射* `Port-Mapped I/O`], [*内存映射* `Memory-Mapped I/O`],
  [*内存空间*], [ 独立空间 ], [ 统一空间 ],
  [*访问指令*], [ 专用指令 ], [ 访存指令 ],
)

=== 通用内存 `<linux/slab.h>`

#h(2em)内核在 `slab.h` 中提供一系列面向 _频繁使用小动态内存_ 场景提供一
系列内存分配器

```c
void kfree(const void *);                    // 释放
void *kmalloc(size_t, gfp_t);                // 基本
void *kzalloc(size_t, gfp_t);                // 清零
void *kcalloc(size_t, size_t, gfp_t);        // 数组、清零g
void *krealloc(const void *, size_t, gfp_t); // 调整（拷贝、释放）
```
标志掩码 `gfp_t` 用于控制内存分配行为

- `Get Free Pages` 源自最底层的 `get_free_pages()` 页分配函数

#table(align: center + horizon, columns: (2fr, 1fr, 4fr),
  [*标志*], [*复合*], [*说明*],
  [`GFP_KERNEL`], [是], [
    常规内核分配，可睡眠以等待内存
  ],
)

=== 大块内存 `<linux/vmalloc.h>`

=== 页级内存 `<linux/mm.h>`

== 中断服务 `<linux/interrupt.h>`

```c
int request_thread_irq(
  unsigned int irq,        // 中断编号
  irq_handler_t handler,   // 服务函数 irqreturn_t (*)(int, void *)
  irq_handler_t thread_fn, // 服务线程 NULL -> request_irq
  unsigned long flags,     // 中断标志：共享、单次、边沿、电平
  const char *name,        // 中断名称，在 /proc/interrupts 查看
  void *dev                // 设备对象，传入 handler 使用，共享时区分服务
); 
```

#list(
  [
    *备注*：解除中断服务 `free_irq`、使能失能中断
    `enable_irq/disalbe_irq`（不可用于共享中断）
  ],
  [
    *备注*：资源管理型 API `devm_request_irq`
  ]
)

*中断编号*：查阅芯片数据手册

#list(
  [
    *备注*：对应 ARM 的通用中断控制器 GIC，分为 3 种中断，
    _共享外设中断_ SPI，_私有外设中断_ PPI，_软件生成中断_ SGI
  ]
)

*中断服务*：内核中断响应分为先后两步，首先是 _硬中断上下文_ 的 `handler`
，然后是 _线程上下文_ 的 `thread_fn`；两者函数签名相同，传入中断号和设备对
象，返回 `irqreturn_t` 枚举表示特定含义

#table(align: center + horizon, columns: (1fr, 2fr, 1fr),
  [`irqreturn_t`], [`handler` 快速服务], [`thread_fn` 耗时服务],
  [`IRQ_NONE`], [非所要处理中断；配合共享中断机制], [失败、未处理、异常],
  [`IRQ_HANDLED`], [已处理], [已处理],
  [`IRQ_WAKE_THREAD`], [处理并创建线程 `thread_fn != NULL`], [无意义]
)

#list(
  [
    *备注*：若 `handler` 为 `NULL`，则将应用默认 _不进行任何操作_ 并返回
    `IRQ_WAKE_THREAD` 的 `handler` (风险)
  ]
)

*中断标志*：

#table(align: center + horizon, columns: (1fr, 3fr),
  [`IRQF_`], [说明],
  [`SHARED`], [
    允许共享中断，如 PCI 设备，此时 `irq` 和 `dev` 共同确定此次注册的中
    断服务 \
    对应的 `handler` 若确定不是自己的中断，则应该返回 `IRQ_NONE`
  ],
  [`ONESHOT`], [
    屏蔽中断线直到 `thread_func` 执行完毕（ `handler == NULL` 必要）
  ],
  [`TRIGGER_*`], [
  ],
)

== 处理器管理 `<linux/cpumask.h>`

== 内核线程 `<linux/mutex.h>`

== 互斥锁 `<linux/mutex.h>`

#h(2em)互斥锁 Mutex（Mutual Exclusion）是并发环境中用于
_保障数据一致性_、_避免竟态条件_ 的关键同步工具，其作为
保护 _临界区_ Critical Section 的基础同步原语，
实现 *确保同一时刻只有一个线程能够访问共享资源*，即一个线程在
访问共享资源前，必须尝试获得 Mutex 即 `locked`，待访问结束后
释放即 `unlocked`，尝试访问 `locked` 资源时，将 _等待_ 该其 `unlocked`，
其实现依赖于 _原子操作_ Atomic Operation

#list(
  [
    *备注*：仅一个任务可持有，只有所有者可以释放，禁止多次释放和递归加锁，
    _禁止在中断中使用_，任务不释放锁不能退出，锁驻留内存不能释放，必须通过
    相关内核 API 进行初始化而不可直接进行内存操作
  ],
)

#table(align: center + horizon, columns: (1fr, 2.2fr, 4fr),
  [*操作*], [*API*], [`struct mutex { /* ... */ };`],
  [动态初始化], [`mutex_init(&mutex);`], [
    创建局部静态变量，运行时对互斥锁内存进行初始化
  ],
  [静态初始化], [`DEFINE_MUTEX(name)`], [
    创建作为全局变量的互斥锁，编译期初始化互斥锁内存
  ],
  [销毁], [`mutex_destory(&mutex)`], [
    为代码增加销毁标记，_在非调试模式下为空_，销毁时应解锁
  ],
  [加锁], [`mutex_lock(&mutex);`], [
    若锁已 `locked`，则休眠并等待锁被获取
  ],
  [尝试加锁], [`mutex_trylock(&mutex);`], [
    若成功则返回 `1`，或使用 `mutex_is_locked(&mutex)`
  ],
  [解锁], [`mutex_unlock(&mutex)`], [
    不可多次释放
  ],
  [高级加锁], [`...`], []
)

#list(
  [
    *备注*：初始化时将创建 _唯一标识符_ 供死锁检测工具 `lockdep` 使用，
    建议根据全局或局部，按推荐方式初始化；另外，禁止多次 `mutex_init`，
    特别是 `全局 + mutex_init` 时，应使用全局标志使其仅初始化一次
  ],
)

== 无锁环形队列 `<linux/kfifo.h>`

内核提供 _无锁环形队列_ `struct kfifo` 实现

== 符号查找 `<kallsyms.h>`

函数 `unsigned long kallsyms_lookup_name(const char *name);` 可通过符
号名称查找其地址，需要内核开启 `KALLSYMS & KALLSYMS_ALL` 支持



#pagebreak()
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

#list(
  [
    *备注*：项目 `Makefile` 常使用
    `ifeq ($(KERNELRELEASE),) 用户编译 else 内核编译 endif` 使得该文件
    能被同时被两个环境调用，其中，先执行的 `用户编译` 一般
    声明 `all`、`clean` 等指令并 `make -C` 内核 `Makefile`，
    后执行的 `内核编译` 可独立至 `Kbuild` 文件，后者将被内核构建优先
    读取，并在不存在时回退
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

#pagebreak()
= MMU

#h(2em)_内存管理单元_ Memory Management Unit 是处于 _处理器_ 和
_内存总线_ 之间的硬件模块

#list(
  [
    *地址转换*：将处理器进行内存访问所使用的 _虚拟地址_ 根据 _页表_ 映射为
    _物理地址_，从而对物理内存进行访问
  ],
  [
    *访问控制*：根据 _页表_ 对内存访问地址进行合法性校验，从而限制程序对
    内存的可访问区域，阻止非法访问
  ],
  [
    *分页机制*：
  ],
)

将进程的逻辑地址空间划分为若干 _块 Chunk_ 并称之为 _页 Page_，每页大小
通常在 kB 级别

进程拥有 _动态维护_ 页表记录地址转换，其虚拟地址空间 _从零开始_ 编址，
使得程序虚拟地 _独占_ 整个内存空间（地址可硬编码），连续的虚拟内存实际上
可能是若干不连续的物理内存区段的映射


执行 ELF

#enum(
  [
    读取 Program Header，在进程虚拟内存中创建对应的 VMA 结构体
  ],
  [
    程序尝试访问内存时，若页表内没有有效地址映射，则触发 _缺页异常_
  ]
)


其由 Table Walk Unit 和
Translation Lookaside Buffer (TLB) 组成，处理器访问的地址，首先通过
TLB 检查应用缓存的转换关系，若缓存失败，则 Table Walk Unit 将在内存中读取


#h(2em)物理内存 Physical Memory 是计算机系统中的一种 _有限的、可能不连续
的不同架构或实现之间地址定义存在差异的_ 资源，

虚拟内存 Virtual Memory 面向应用程序需求对物理内存进行了抽象，屏蔽了物理
内存的复杂性和各自差异

https://docs.kernel.org/admin-guide/mm/concepts.html

https://www.cnblogs.com/wanglouxiaozi/p/15012403.html



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



#link(url.mmio-0)[Memory Mapped IO and Isolated IO]

#link(url.mmio-1)[Memory Mapped IO in C]


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
