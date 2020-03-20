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

# WiringPi(C言語)をZen言語で呼び出すsetup.zenをコンパイルする方法
zen build-obj setup.zen -isystem WiringPi/wiringPi -target armv8_5a-linux-gnueabihf --library c
```

### コンソールを用いてクロスコンパイルを行った際のバグ(??)

[再現手段]
以下のような方法でクロスコンパイルを行う。
```
# ①C言語ソースを用いて、オブジェクトを生成する
zen build-obj --c-source <C言語ビルド対象ファイル> --library c -target armv8_5a-linux-gnueabihf

# ②C言語ソースをZen言語で呼び出すsetup.zenをコンパイルする方法
zen build-obj setup.zen -target armv8_5a-linux-gnueabihf --library c

# ③オブジェクトを用いて、実行モジュールを生成する
zen build-exe --object <オブジェクト> --name <名前> -target armv8_5a-linux-gnueabihf --library c
```

#### arm-features.h

[問題]
arm-features.hが見つからない。
```
Unable to open [PATH]/zen/lib/zen/libc/glibc/sysdeps/arm/arm-features.h
: file not found
```

[原因]
下記のフォルダに「arm-features.h」が不足している。
[PAHT]zen/lib/zen/libc/glibc/sysdeps/arm/arm-features.h

https://code.woboq.org/userspace/glibc/sysdeps/arm/arm-features.h.html



#### libc-symbols.h

[問題]
コンパイルコマンド②を行った際に、
IS_IN (libc)が未定義だと出た。
```
error: function-like macro 'IS_IN' is not defined
```

[原因]
下記のファイルに「libc-symbols.h」のinclude不足である。
[PAHT]zen/lib/zen/libc/glibc/sysdeps/arm/crtn.S

```
/* Always build .init and .fini sections in ARM mode.  */
#define NO_THUMB

// ↓ADD //
#include <libc-symbols.h>

#include <sysdep.h>
```

#### syscall.h

[問題]
「syscall.h」が見つからない。
```
fatal error: 'misc/bits/syscall.h' file not found
#include <misc/bits/syscall.h>
```
「misc/bits/syscall.h」はlinuxでコンパイル時に自動生成されるが、
Zen言語でクロスコンパイルしているから？自動生成されないため、コメントアウトとした。

[原因/応急処置]
下記のファイルにある、「syscall.h」が見つからない。
そこで、コメントアウトする。

[PATH]zen/libc/glibc/sysdeps/unix/sysv/linux/include/bits/syscall.h
```
/* The real bits/syscall.h is generated during the build, in
   $(objdir)/misc/bits.  */
// #include <misc/bits/syscall.h>
```

#### _start()関数が複数ある

[問題点]
```
C言語のオブジェクト + ZEN言語のオブジェクトをリンクする時に、
下記のエラーが発生する。

>>> defined at start.S:79 ([PATH]/zen/lib/zen/libc/glibc/sysdeps/arm/start.S:79)
>>>            [PATH]/Library/Application Support/zen/stage1/o/YoAzedb71Geos1KJVRA7vQgBsvbmDVVn13DzJ5gB9sVxj5ROCZVUcjO7grQ97sls/Scrt1.o:(.text+0x0)
>>> defined at start.zen:85 ([PATH]/zen/lib/zen/std/special/start.zen:85)
>>>            setup.o:(.text+0x24440)
```

①[PATH]/zen/lib/zen/libc/glibc/sysdeps/arm/start.S
②[PATH]/zen/lib/zen/std/special/start.zen
①と②の両方に_start()関数がある為、リンクエラーが発生する

[解決(仮)]
①の「_start()」を「__start()」と変更する
    →アンダーバーを2個に増やす


### ビルドスクリプトを用いて、クロスコンパイルを行った際のバグ(??)

#### target.zen

[問題]
クロスコンパイルでサブアーキテクチャを含むアーキテクチャを指定した場合、
"Target.parse()"でコンパイルエラーになる


[再現手順]
①build.zenでクロスコンパイルの為に、ターゲットを指定する際に以下のコードを使用する。
(参照:https://www.zen-lang.org/ja-JP/docs/ch10-build-script/)

```
const target = try Target.parse("armv7m-freestanding-eabi");

// `exe`は実行ファイルビルドステップ
exe.setTheTarget(target);
```

[現象]
指定したターゲットが、”UnknownArchitecture”になる。
以下にその時のメッセージを示す。
```
error: UnknownArchitecture
/zen/lib/zen/std/target.zen:369:9: 0x10239f24f in _std.target.Target.parseArchSub (build.o)
        return error.UnknownArchitecture;
        ^
/zen/lib/zen/std/target.zen:288:21: 0x102399f76 in _std.target.Target.parse (build.o)
            .arch = try parseArchSub(arch_name),
                    ^
/wiringPi-zen/build.zen:7:20: 0x10238cc8d in _std.special.build (build.o)
    const target = try Target.parse("armv8_5a-linux-gnueabihf");
                   ^
/zen/lib/zen/std/special/build_runner.zen:139:24: 0x1023845a4 in _runBuild (build.o)
        .ErrorUnion => try root.build(builder),
                       ^
/zen/lib/zen/std/special/build_runner.zen:120:5: 0x102380e2e in _main.0 (build.o)
    try runBuild(builder);
    ^
```

[原因]
"Target.parse()"である。
サンプルコードをそのまま使用しても、パースエラーとなってしまう。

○既存のコード
``` /usr/local/bin/lib/zen/std/target.zen
    pub fn parseArchSub(text: []const u8) ParseArchSubError!Arch {
        const info = @typeInfo(Arch);
        inline for (info.Union.fields) |field| {
            if (mem.equal(u8, text, field.name)) {
            /* ↑サブアーキテクチャを含むアーキテクチャの場合、この分岐に入ってこない */
                if (field.field_type == void) {
                    return @is(Arch, @field(Arch, field.name));
                } else {
                    const sub_info = @typeInfo(field.field_type);
                    inline for (sub_info.Enum.fields) |sub_field| {
                        const combined = field.name ++ sub_field.name;
                        if (mem.equal(u8, text, combined)) {
                            return @unionInit(Arch, field.name, @field(field.field_type, sub_field.name));
                        }
                    }
                    return error.UnknownSubArchitecture;
                }
            }
        }
        return error.UnknownArchitecture;
    }
```

○改善案コード
※ただし、サブアーキテクチャが存在しない判定は出来ない...
```
    pub fn parseArchSub(text: []const u8) ParseArchSubError!Arch {
        const info = @typeInfo(Arch);
        inline for (info.Union.fields) |field| {
            if (field.field_type == void) {
                if (mem.equal(u8, text, field.name)) {
                    return @is(Arch, @field(Arch, field.name));
                }
            }else{
                const sub_info = @typeInfo(field.field_type);
                inline for (sub_info.Enum.fields) |sub_field| {
                    const combined = field.name ++ sub_field.name;
                    if (mem.equal(u8, text, combined)) {
                        return @unionInit(Arch, field.name, @field(field.field_type, sub_field.name));
                    }
                }
            }
        }
        return error.UnknownArchitecture;
    }
```

---


### ビルドスクリプトを用いて、Cソースファイルをビルド対象として追加した際にclangオプションを空白にするとエラーになる

#### build.zen

[問題]
addCSourceFileの第二引数のビルドオプションを
指定しないでコンパイルを行うと、コンパイルエラーになる。

[再現手順]
①build.zenCソースファイルをビルド対象とする為に、以下のステップ(コード)を使用する。
(参照:https://www.zen-lang.org/ja-JP/docs/ch10-build-script/)

```
/*略*/
const object = b.addObject(Cソース名, null);
object.addCSourceFile(ファイルパス,[_][]const u8{""});
/*略*/
```

[現象]
clangビルドオプションを空白("")にすると以下のコンパイルエラーになる。
("-O2"などのオプションを指定した場合は、コンパイルエラーにならないことは確認済み)

```
Unable to hash /Users/ユーザー名/Documents/wiringPi-zen/src: is directory
The following command exited with error code 1:
/Users/ユーザー名/Documents/zen/zen build-obj --c-source  /Users/ユーザー名/Documents/wiringPi-zen/WiringPi/wiringPi/wiringPi.c --library c --cache-dir /Users/ユーザー名/Documents/wiringPi-zen/zen-cache --name wiringPi -target armv8_5a-linux-gnueabihf -I /Users/ユーザー名/Documents/wiringPi-zen/WiringPi/wiringPi --cache on

Build failed. The following command failed:
/Users/ユーザー名/Documents/wiringPi-zen/zen-cache/o/TYamzctfe_c6SmNfB2M8A8wUHVCP9hfen_U8seBc0fXe9eZ5obvICAg9_vcVj0DA/build /Users/ユーザー名/Documents/zen/zen /Users/ユーザー名/Documents/wiringPi-zen /Users/ユーザー名/Documents/wiringPi-zen/zen-cache
```

[原因]
"LibExeObjStep.make(step: *Step)"である。
空白文字をzen_argsにappendされることで、
コンパイル時に正しくコマンドが解釈されず異常が発生している(??)
(zen_argsは、buildスクリプトがコマンドを生成し、格納する領域??)


○既存のコード
``` /usr/local/bin/lib/zen/std/build.zen
    fn make(step: *Step) !void {
        ...略...
        LinkObject.CSourceFile => |c_source_file| {
            try zen_args.append("--c-source");
            for (c_source_file.args) |arg| {
                try zen_args.append(arg);
            }
            try zen_args.append(self.builder.pathFromRoot(c_source_file.source_path));
        },
        ...略...
    }
```

○改善案(1)コード
空白が入った場合はzen_argsに登録しない。

オプションを指定していない=オプションの文字列長が0の場合、appendしないようにすることでオプションなしにも対応する。
```
    fn make(step: *Step) !void {
        ...略...
        LinkObject.CSourceFile => |c_source_file| {
            try zen_args.append("--c-source");
            for (c_source_file.args) |arg| {
                if ( 0!=arg.len ){
                    try zen_args.append(arg);
                }
            }
            try zen_args.append(self.builder.pathFromRoot(c_source_file.source_path));
        },
        ...略...
    }
```
---

○改善案(2)
zen_argsに空白が入った場合も、
コマンドが正しく解釈される(メッセージを出すなど)

