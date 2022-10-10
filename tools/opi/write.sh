#!/bin/bash

export LC_ALL=C

bfile="$1"
saddr="$2"

isuint() { case $1 in ''|*[!0-9]*) return 1;;esac;}

write_mem() {
    addr=$1
    value=$2

    # set data
    i2cset -y 0 0x22 0x09 $(printf '0x%x' $value)

    # set address
    i2cset -y 0 0x20 0x09 $(printf '0x%x' $(($(($addr & 240)) / 16)))
    i2cset -y 0 0x21 0x09 $(printf '0x%x' $(($addr & 15)))

    # Perform write
    i2cset -y 0 0x23 0x09 0x03
    sleep 0.01
    i2cset -y 0 0x23 0x09 0x01
    sleep 0.01
}

if [ ! -f "$bfile" ]; then
    echo "Specify file to write"
    exit 1
fi

if [ -z "$saddr" ]; then
    saddr=0
fi

if ! isuint $saddr; then
    echo "Specify numeric address"
    exit 1
fi

# Enable the I2C
i2cset -y 0 0x70 0x00 0x0f

# Reset all GPIO
i2cset -y 0 0x23 0x00 0x00
i2cset -y 0 0x23 0x09 0x00
i2cset -y 0 0x20 0x00 0x00
i2cset -y 0 0x21 0x00 0x00
i2cset -y 0 0x22 0x00 0x00
i2cset -y 0 0x20 0x09 0x00
i2cset -y 0 0x21 0x09 0x00
i2cset -y 0 0x22 0x09 0x00

# Switch Programmer on
i2cset -y 0 0x23 0x09 0x01

# Wait for CPU to enter the reset state
sleep 1

hexdump -v -e '/1 "%u\n"' $bfile | while read c; do
    write_mem $saddr $c
    saddr=$(($saddr + 1))
done

# Switch Programmer off
i2cset -y 0 0x23 0x09 0x00


