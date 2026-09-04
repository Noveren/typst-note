#import "../template.typ": *
#show: conf

#context {
  let is-main-file = state("is-main-file", false).get()
  if not is-main-file {
    outline()
    pagebreak()
  }
}

= ELF

== 动态库 `<dflcn.h>`

若为 `NULL`，则表示当前程序并可查找内部符号
相对路径或绝对路径对应的

#table(align: center + horizon, columns: (1fr, 1fr, 5fr),
  table.cell(rowspan: 4)[`dlopen`],
  table.cell(colspan: 2)[
    `void *(*)(const char *filename, int flag)`
  ],
  table.cell(colspan: 2)[
    加载 `filename` 指定 _动态库_ 并返回 _句柄_
  ],
  table.cell(rowspan: 2)[`filename`],
  align(left)[
    #h(1em)`NULL`：
  ],
  align(left)[
    #h(1em)`path`：
  ],
  // table.cell(rowspan: 2)[`dlerror`],
  // `char *(*)(void)`,
  // [

  // ],
  // table.cell(rowspan: 2)[`dlsym`],
  // `void *(*)(void *handle, const char *symbol)`,
  // [

  // ],
  // table.cell(rowspan: 2)[`dlclose`],
  // `int (*)(void *handle)`,
  // [

  // ],
)