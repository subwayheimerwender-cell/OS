RED="\033[31m"
GREEN="\033[32m"
MAGENTA="\033[35m"
RESET="\033[0m"

set -e
trap 'printf "${RED}Build failed!${RESET}\n"; exit 1' ERR

nasm -f bin ~/Downloads/xmode/kernel/kernel.asm -o ~/Downloads/xmode/kernel/kernel.bin
nasm -f bin ~/Downloads/xmode/programs/help.asm -o ~/Downloads/xmode/programs/help.bin
nasm -f bin ~/Downloads/xmode/programs/window.asm -o ~/Downloads/xmode/programs/window.bin
nasm -f bin ~/Downloads/xmode/xasm/xasm.asm -o  ~/Downloads/xmode/xasm/xasm.bin


# nasm -f elf32 ~/Downloads/xmode/kernel/kernel.asm -o ~/Downloads/xmode/kernel/kernel.o
# gcc -m32 -ffreestanding -c ~/Downloads/xmode/kernel/kernel.c -o ~/Downloads/xmode/kernel/kernelc.o
# ld -m elf_i386 -T ~/Downloads/xmode/build/linker.ld -o ~/Downloads/xmode/kernel/kernel.bin ~/Downloads/xmode/kernel/kernel.o ~/Downloads/xmode/kernel/kernelc.o
# printf "${GREEN}Succesfully compiled files!${RESET}\n"

nasm -f win64 ~/Downloads/xmode/boot.asm -o ~/Downloads/xmode/boot.obj
x86_64-w64-mingw32-ld -dll -shared --subsystem 10 -e _efi_main -o ~/Downloads/xmode/bootx64.efi ~/Downloads/xmode/boot.obj

mmd -i disk.img ::/EFI
mmd -i disk.img ::/EFI/BOOT
mcopy -i disk.img ~/Downloads/xmode/bootx64.efi ::/EFI/BOOT
mcopy -i disk.img ~/Downloads/xmode/kernel/kernel.bin ::XMODE.BIN
mcopy -i disk.img ~/Downloads/xmode/programs/help.bin ::HELP.BIN
mcopy -i disk.img ~/Downloads/xmode/programs/window.bin ::WINDOW.BIN
mcopy -i disk.img ~/Downloads/xmode/xasm/xasm.bin ::XASM.BIN
mcopy -i disk.img ~/Downloads/xmode/sys/ ::SYS
mattrib -i disk.img +s ::SYS/AUTOSTRT.SYS
mattrib -i disk.img +s ::SYS/1BOOT.SYS
mcopy -i disk.img ~/Downloads/xmode/xasm/test.asm ::TEST.ASM