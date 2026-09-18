#import "../typst-note/template.typ": *
#show: conf


= `string.h`

== 字符串分割 `strtok`

```c
char *strtok(char *str, const char *delim);
char *strtok_r(char *str, const char *delim, char **saveptr);
```
将原字符串 `str` 以字符串 `delim` 分割为一系列子字符串 `token`，其内部持有状态（_不可重入_），修改原字符串 `str` 部分位置 `\0`，每次调用返回下一个 `token` 的首地址，或 `NULL` 表示结束，需要主动传入 `str = NULL` 表示下一次调用是上一次的继续


== 字符串拼接 `strcat`

```c
// strcpy(dst + strlen(dst), src)
char *strcat(char *dst, const char *src);
```

将字符串 `src` 追加到字符串 `dst` 的结尾

= `unistd.h`

== POSIX 风格：`getopt`

```c
extern char *optarg;       // 选项参数
extern int optind;         // 下一个参数索引
extern int opterr, optopt; // 是否打印错误、有问题的选项字符
int getopt(int argc, char *argv[], const char *optstring);
```

`getopt` 根据选项配置 `optstring` _有状态的_（迭代式）解析命令行
参数 `argc & argv`，合法返回选项字符 `char`、未知返回 `'?'`、错误
返回 `-1`、 缺参返回 `':'`

== GNU 风格：`getopt_long`

GNU 风格通过引入长选项（Long Options），解决了 POSIX 风格“字母不够用”和“记忆成本高”的痛点，同时完美保留了 POSIX 短选项的便捷性。

GNU 风格的权威定义来自 GNU Coding Standards，具体解析依赖 glibc 中的 getopt_long() 函数。其规则非常严格：

长选项前缀：必须使用两个短横线 -- 开头，后面跟一个或多个英文单词，单词间用单个短横线 - 连接（例如 --output-file）。

参数分隔方式（双重标准）：

使用空格：--output file.txt（标准写法，推荐）。

使用等号 =：--output=file.txt（这是 GNU 风格独有的特性，允许选项与参数紧密相连，在处理包含空格或特殊字符的参数时尤为安全）。

可选参数（GNU 独有）：如果某个选项的参数是可选的（Optional Argument），必须使用 = 号连接，不能使用空格。例如：--color=auto（如果写成 --color auto，解析器会认为 auto 是独立的位置参数）。

允许唯一缩写：只要输入的长选项前缀能唯一匹配该程序支持的所有选项，就是合法的。例如 --ver 可以匹配 --version，但如果程序还有 --verbose，则 --ver 报错歧义。

短选项兼容：GNU 风格强制要求为绝大多数长选项配备对应的单字母短选项（如 --verbose 对应 -v），并且支持 POSIX 风格的短选项捆绑（如 -abc）。