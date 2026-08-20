# MiniWin Desktop OS

一个用 x86 汇编写的微型图形桌面操作系统。

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Assembly](https://img.shields.io/badge/Assembly-NASM-orange.svg)

---

## 功能

- 320×200 256色图形模式
- PS/2 鼠标驱动
- 十字光标 + 双缓冲
- 状态栏显示坐标
- ~45 FPS

---

## 文件结构

```
MiniWin/
├── src/
│   ├── boot.asm          # 引导扇区
│   └── stage2.asm        # 桌面系统
├── tools/
│   ├── build.sh          # 编译脚本
│   └── STARTOS.BAT       # 一键启动 (Windows)
├── LICENSE
└── README.md


---

## 编译运行

### Windows
双击 `tools/STARTOS.BAT`

### Linux/WSL
```bash
cd src
./build.sh
qemu-system-x86_64 -drive format=raw,file=os.img
```

### 手动编译
```bash
nasm -f bin boot.asm -o boot.bin
nasm -f bin stage2.asm -o stage2.bin
dd if=/dev/zero of=os.img bs=512 count=2880
dd if=boot.bin of=os.img bs=512 count=1 conv=notrunc
dd if=stage2.bin of=os.img bs=512 seek=1 conv=notrunc
```

---

## 依赖

- NASM
- QEMU (运行)
- dd / certutil (打包)

---

## 许可证

MIT License

---

MIT License

Copyright (c) 2026 SimpleTools

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---
