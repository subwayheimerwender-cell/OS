RED="\033[31m"
GREEN="\033[32m"
MAGENTA="\033[35m"
RESET="\033[0m"

set -e
trap 'printf "${RED}Build failed!${RESET}\n"; exit 1' ERR

nasm -f bin boot.asm -o boot.bin
nasm -f bin kernel/kernel.asm -o kernel/kernel.bin
nasm -f bin programs/hwinfo.asm -o zprograms/hwinfo.bin
nasm -f bin programs/calc.asm -o zprograms/calc.bin
nasm -f bin programs/hello.asm -o zprograms/hello.bin
nasm -f bin programs/ascii.asm -o zprograms/ascii.bin
nasm -f bin programs/xir.asm -o zprograms/xir.bin
nasm -f bin programs/xfetch.asm -o zprograms/xfetch.bin
nasm -f bin programs/lsdisk.asm -o zprograms/lsdisk.bin
nasm -f bin programs/xedit.asm -o zprograms/xedit.bin
nasm -f bin programs/xformat.asm -o zprograms/xformat.bin
nasm -f bin programs/help.asm -o zprograms/help.bin
nasm -f bin programs/font.asm -o zprograms/font.bin
nasm -f bin programs/install.asm -o zprograms/install.bin
nasm -f bin programs/scancode.asm -o zprograms/scancode.bin
printf "${GREEN}Succesfully compiled files!${RESET}\n"

# gcc -ffreestanding -nostdlib -c ~/Downloads/xmode/xasm/xasm.c -o ~/Downloads/xmode/xasm/xasm.o
# ld -T ~/Downloads/xmode/xasm/linker.ld -o ~/Downloads/xmode/xasm/xasm.elf ~/Downloads/xmode/xasm/xasm.o
# objcopy -O binary ~/Downloads/xmode/xasm/xasm.elf ~/Downloads/xmode/xasm/xasm.bin

# rm disk.img
# dd if=/dev/zero of=disk.img bs=1M count=9                                                            # Create disk image
# mkdosfs -F 16 -v -h 2048 disk.img
# mkdosfs -F 16 -v --offset 2048 -h 2048 disk.img                                                        # 1MB offset
mkdosfs -F 16 -v disk.img
dd if=boot.bin of=disk.img bs=1 count=450 seek=62 skip=62 conv=notrunc
mcopy -i disk.img kernel/kernel.bin ::KERNEL.BIN
cd ~/Downloads/xmode
./buildx.sh                                                                                            # UNCOMMENT FOR XMODE
cd -
# mcopy -i disk.img programs/help.bin ::HELP.BIN
mcopy -i disk.img txt/ ::TXT
mcopy -i disk.img zprograms/ ::PROGRAMS
mcopy -i disk.img -s a ::/
# mattrib -i disk.img +s ::KERNEL.BIN
# mattrib -i disk.img +s ::XMODE.BIN
mcopy -i disk.img txt/fscmds.txt ::TEST.TXT
printf "${MAGENTA}Disk layout:${RESET}\n"
mdir -i disk.img ::
# mdir -i floppy.img ::
printf "${GREEN}Copied data to disk image. Loading QEMU...${RESET}\n"
#qemu-system-i386 -hda disk.img -hdb disk2.img -fda floppy.img -fdb floppy8.img -m 64M # -d int -no-reboot # -hdc disk3.img -device ahci 
qemu-system-x86_64 \
  -drive file=disk.img,format=raw,if=ide \
  -drive file=disk4.img,format=raw,if=none,id=disk0 \
  -drive file=disk2.img,format=raw,if=none,id=disk1 \
  -drive file=disk3.img,format=raw,if=none,id=disk2 \
  -device ahci,id=ahci0 \
  -device ide-hd,drive=disk0,bus=ahci0.0 \
  -device ide-hd,drive=disk1,bus=ahci0.1 \
  -device ide-hd,drive=disk2,bus=ahci0.2 \
  -m 50M \
  -drive if=pflash,format=raw,readonly=on,file=/home/technodon/Downloads/xmode/build/OVMF_CODE.4m.fd \
  -drive if=pflash,format=raw,file=/home/technodon/Downloads/xmode/build/OVMF_VARS.4m.fd \
# mkdosfs -F 12 -v disk3.img
# mkdosfs -F 16 -v disk2.img


# memory map of Xiromos
# 0x0x0000:0500 - 0x0000:0x3998: root directory
# 0x0000:0x3999 - 0x0000:0x7bff: FAT
# 0x0000:0x7c00 - 0x0000:0x7e00: boot code
# 0x1000:0x0000 - 0x1000:0xffa0: kernel.bin
# 0x1000:0xfffe - 0x1000:0xffa1: kernel stack
# 0x5000:0x0000 - 0x8000:0x0000: programs
# 0x9000:0x0000 - 0x9000:0x7bff: directories
# 0x9000:0x7c00 - 0x9000:0x7e00: boot code of external disks

# write on USB stick:
# lsblk
# sudo dd if=disk.img of=/dev/sdb bs=4M status=progress conv=fsync
# sync



# HOW TO USE XMODE
# First you have to uncomment "./buildx.sh"
# Then change in the buildx.sh the directories (will be fixed soon)
# also install the following packages: nasm, qemu-full, mtools, mingw-w64-gcc (arch linux)