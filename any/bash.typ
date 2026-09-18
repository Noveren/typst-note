#import "../template.typ": *
#show: conf

#context {
  let is-main-file = state("is-main-file", false).get()
  if not is-main-file {
    outline()
    pagebreak()
  }
}

= BASH

https://mp.weixin.qq.com/s?__biz=MjM5ODYwMjI2MA==&mid=2649745834&idx=1&sn=a87c1abec3395327436cc812c8579188&chksm=bf6e8d4ed59618f81e067dd44ca99868e3aa79f7904f210b372dbc27791f699855f66307e9e7&mpshare=1&scene=1&srcid=09085yztlAYJW3bLVmXE0ghP&sharer_shareinfo=baf7b778fa9cda5c944b4cbfbe8926ef&sharer_shareinfo_first=baf7b778fa9cda5c944b4cbfbe8926ef#rd



在脚本开始处使用 `set -xeuo pipefail`：bash 脚本默认在遇到异常时继续运行

#list(
  [选项：`-x`；在执行命令前，打印 变量展开后的命令，用于调试],
  [选项：`-e`；若错误码非零，则立即退出；使用 `CMD || true` 或 `CMD || RET=$?` 忽略错误],
  [选项：-u；禁止使用未定义变量（默认展开为空串）；使用 `${VAR:-}` 显式展开为空串],
  [选项：-o；管道错误中断，`-o pipefail`],
)

== 基础

=== 变量

#h(2em)变量以 `VAR=VAL` 形式创建（_两侧不可有空格_），名字以字母
或 `_` 开头，可接数字、字母（大小写敏感），需避免与保留关键字重名，
其值 `VAL` 都是 *字符串*，不含空白符的字符串可不使用 `"` 或 `'` 括起，
使用时以 `$VAR` 形式展开（包括在字符串内），
#text(fill: red, weight: "bold")[
  为避免预期之外的行为，展开时应使用 *引号* 括起
] 并建议使用 `${VAR}` 形式

#table(align: center + horizon, columns: (3fr, 1fr, 2fr, 2fr),
  [], [*名称*], [*作用域（可用位置）*], [*备注*],
  `[readonly] VAR=VAL`, [普通变量], [_进程/脚本_], [
    自动覆盖
  ],
  `export VAR=VAL`, [环境变量], [_进程/脚本_ 及 _子进程_], [
    自动覆盖
  ],
  `local VAR=VAL`, [局部声明], [函数内部], [
    临时覆盖外部同名变量
  ],
  `declare [<option>] VAR=VAL`, [声明], [`option`], [
    `-r` 只读变量
  ],
)

多行字符串

```bash
// str=$(cat << EOF
// EOF)

function foo() {
  local str=(
      "#ifndef _str"
      "#define _str"
      "#define PRODUCT_VERSION (0x${version})"
      "#define PRODUCT_COMPILE_TIME_STRING (\"${compile_time}\")"
      "#endif"
  )
  printf -v str "%s\n" "${str[@]}"
  str="${str%$'\n'}"
}
```


数组

打印到标准错误 `echo "msg" > &2`

=== 函数

```bash
function foo() {
  # 报错、默认值
  local param="${1:?'Too few arguments to function call'}"
  # 使用 getopts 解析 POSIX/GNU 风格参数
}
```



=== 特殊变量

#table(align: center + horizon, columns: (2fr, auto, auto, 4fr),
  [Builtin-Variable], [Script], [Function], [说明],
  `${BASH_SOURCE[0]}`, `Y`, [], [
    当前脚本文件路径
  ],
  `$0`, `Y`, `N`, [
    Shell 名称（若被 `source` 执行）或当前脚本路径
  ],
  `$#`, `Y`, `Y`, [
    参数个数；不含 `$0`
  ],
  `$<N>`, `Y`, `Y`, [
    位置参数；从 1 开始；10 以上需使用 `${<N>}` 形式
  ],
  `$*`, `Y`, `Y`, [
    所有参数；引号时，合并为一个参数，用 `$IFS` 分隔
  ],
  `$@`, `Y`, `Y`, [
    所有参数；引号时，原样保留参数中的空格；建议
  ],
  `$?`, `Y`, `Y`, [
    上次执行命令的错误码 0 ~ 255
  ],
)

== 高级

=== 参数扩展

#table(align: center + horizon, columns: (auto, 1fr, 2fr),
  [*类型*], [*语法*], [*说明*],
  table.cell(rowspan: 4)[基础及默认值], 
  `${var}`, [直接展开],
  `${var:?message}`, [
    若 `var` 未设置或空，则写 `message` 到标准错误并退出
  ],
  `${var:-default}`, [
    若 `var` 未设置或空，则展开为 `default`
  ],
  `${var:=default}`, [
    若 `var` 未设置或空，则赋值为 `default` 并展开
  ],
  table.cell(rowspan: 3)[]
)

命令替换

`$(cmd1; cmd2)` 会启动 _子 Shell_ 依次执行内部指令（可嵌套），并捕获
所有命令的 _标准输出_ 拼接为字符串输出，命令之间可使用 `;` 或 _换行_ 分隔

#pagebreak()
= EXPECT

expect 是由 Don Libes 基于 TCL 语言开发的主要用于控制台自动化交互式操作场景的命令行工具

```bash
#!/usr/bin/expect

spawn ssh admin@127.0.0.1
expect "*password:"
```

```bash
local expect_script=(
    'set timeout 30'
    "spawn scp ${SDK}/product_build/build/output/Debug_Tool ${SSH_CONFIG_HOST}:${TARGET_DIR}"
    'expect "*password:"'
    'send "passwd\r"'
    'expect eof'
    "spawn scp ${SDK}/product_pcie/debug_tool/tool.sh ${SSH_CONFIG_HOST}:${TARGET_DIR}"
    'expect "*password:"'
    'send "passwd\r"'
    'expect eof'
)
printf -v expect_script "%s\n" "${expect_script[@]}"
expect -c "${expect_script}"
```

