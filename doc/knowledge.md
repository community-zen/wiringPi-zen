# ナレッジ

## WiringPiをZen言語でコンパイルする
---

### 前提
* Zen言語バージョン : 0.8.20191124+552247019
* Raspberry Pi 3 Model B

### コマンド
```
# C言語ソースを用いて、オブジェクトを生成する
zen build-obj --c-source <C言語ビルド対象ファイル>  -isystem WiringPi/wiringPi --library c -target armv8_5a-linux-gnueabihf

# オブジェクトを用いて、実行モジュールを生成する
zen build-exe --object <オブジェクト> --name wiringPi-zen -target armv8_5a-linux-gnueabihf --library c
```

### クロスコンパイルの準備(バグ?)

#### arm-features.h

下記のフォルダに「arm-features.h」が不足している。
[PAHT]zen/lib/zen/libc/glibc/sysdeps/arm/arm-features.h

https://code.woboq.org/userspace/glibc/sysdeps/arm/arm-features.h.html

[原因]
arm-features.hが見つからない。
```
Unable to open [PATH]/zen/lib/zen/libc/glibc/sysdeps/arm/arm-features.h
: file not found
```

#### libc-symbols.h

下記のファイルに「libc-symbols.h」のinclude不足である。
[PAHT]zen/lib/zen/libc/glibc/sysdeps/arm/crtn.S

```
/* Always build .init and .fini sections in ARM mode.  */
#define NO_THUMB

// ↓ADD //
#include <libc-symbols.h>

#include <sysdep.h>
```

[原因]
IS_IN (libc)が未定義だと出た。
```
error: function-like macro 'IS_IN' is not defined
```

#### syscall.h

下記のファイルにある、「syscall.h」が見つからない。
そこで、コメントアウトする。

[PATH]zen/libc/glibc/sysdeps/unix/sysv/linux/include/bits/syscall.h
```
/* The real bits/syscall.h is generated during the build, in
   $(objdir)/misc/bits.  */
// #include <misc/bits/syscall.h>
```

[原因]
「syscall.h」が見つからない。
```
fatal error: 'misc/bits/syscall.h' file not found
#include <misc/bits/syscall.h>
```
「misc/bits/syscall.h」はlinuxでコンパイル時に自動生成されるが、
Zen言語でクロスコンパイルしているから？自動生成されないため、コメントアウトとした。


---
