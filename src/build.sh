#!/bin/bash
echo "Building MiniWin..."

nasm -f bin boot.asm -o boot.bin
nasm -f bin stage2.asm -o stage2.bin

dd if=/dev/zero of=os.img bs=512 count=2880 2>/dev/null
dd if=boot.bin of=os.img bs=512 count=1 conv=notrunc 2>/dev/null
dd if=stage2.bin of=os.img bs=512 seek=1 conv=notrunc 2>/dev/null

echo ""
echo "✅ BUILD OK"
echo "▶️  Run: qemu-system-x86_64 -drive format=raw,file=os.img"
echo ""
echo -n "Run QEMU now? (y/n): "
read -n 1 answer
echo ""

if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    echo "Starting QEMU..."
    qemu-system-x86_64 -drive format=raw,file=os.img
else
    echo "Exiting."
    exit 0
fi