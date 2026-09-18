#import "../template.typ": *
#show: conf

#context {
  let is-main-file = state("is-main-file", false).get()
  if not is-main-file {
    outline()
    pagebreak()
  }
}

= PCI

== PCI Utilities

#h(2em)#link("https://mj.ucw.cz/sw/pciutils/")[PCI Utilities] 项目
维护在各种操作系统上提供对 PCI 配置空间访问进行支持的 _跨平台、用户态_
库 `libpci`，并基于该库提供了一系列用于访问 PCI 设备的程序集合
（不同平台的可访问性和支持特性存在差异）

#list(
  [
    *备注*：Linux 内核已将 PCI 设备暴露在 `/sys/bus/pci/devices` 下，
    可直接读写，但 `libpci` 对 PCI 访问进行封装，支持设备信息的解析，
    以及更安全地进行 _用户态_ 配置
  ]
)

```bash
$ apt install libcpi3 # 相关可执行程序（多数发行版已安装）
$ lspci               # 列出当前 PCI 设备
```

=== libpci




