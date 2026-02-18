nasm -f bin boot.asm -o boot.bin
nasm -f bin kernel.asm -o kernel.bin
nasm -f bin calc.asm -o calc.bin
dd if=/dev/zero of=disk.img bs=512 count=16
dd if=boot.bin of=disk.img conv=notrunc
dd if=kernel.bin of=disk.img bs=512 seek=1 conv=notrunc
dd if=calc.bin of=disk.img bs=512 seek=5 conv=notrunc
qemu-system-i386 -hda disk.img