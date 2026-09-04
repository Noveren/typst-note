#import "../typst-note/template.typ": *
#show: conf


= `string.h`

== `strtok`

```c
char *strtok(char *str, const char *delim);
char *strtok_r(char *str, const char *delim, char **saveptr);
```
将原字符串 `str` 以字符串 `delim` 分割为一系列子字符串 `token`，其内部持有状态（_不可重入_），修改原字符串 `str` 部分位置 `\0`，每次调用返回下一个 `token` 的首地址，或 `NULL` 表示结束，需要主动传入 `str = NULL` 表示下一次调用是上一次的继续


== `strcat`

```c
// strcpy(dst + strlen(dst), src)
char *strcat(char *dst, const char *src);
```

将字符串 `src` 追加到字符串 `dst` 的结尾