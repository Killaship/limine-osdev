git pull
export DISPLAY=:0.0
make
qemu-system-x86_64 -cdrom barebones.iso
