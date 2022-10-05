#!/bin/bash

export LC_ALL=C

nbytes="$1"
saddr="$2"

isuint() { case $1 in ''|*[!0-9]*) return 1;;esac;}

counter=0

read_mem() {
    addr=$1

    # set address
    i2cset -y 0 0x20 0x09 $(printf '0x%x' $(($(($addr & 240)) / 16)))
    i2cset -y 0 0x21 0x09 $(printf '0x%x' $(($addr & 15)))

    # Perform read
    i2cset -y 0 0x23 0x09 0x07
    sleep 0.01
    # get data
    c=$(i2cget -y 0 0x22 0x09)

    printf $c
    if [ $(($(($counter + 1)) % 16)) -ne 0 ]; then
        printf ' '
    else
        echo ''
    fi

    i2cset -y 0 0x23 0x09 0x05
    sleep 0.01

    counter=$(($counter + 1))
}

if ! isuint "$nbytes"; then
    echo "Specify number of bytes to read"
    exit 1
fi

if [ -z "$saddr" ]; then
    saddr=0
fi

if ! isuint "$saddr"; then
    echo "Specify numeric address"
    exit 1
fi

# Enable the I2C
i2cset -y 0 0x70 0x00 0x0f

# Reset all GPIO
i2cset -y 0 0x23 0x00 0x00
i2cset -y 0 0x23 0x09 0x04
i2cset -y 0 0x20 0x00 0x00
i2cset -y 0 0x21 0x00 0x00
i2cset -y 0 0x22 0x00 0xff
i2cset -y 0 0x20 0x09 0x00
i2cset -y 0 0x21 0x09 0x00

# Enable programming
i2cset -y 0 0x23 0x09 0x05

while [ "$nbytes" -ne 0 ]; do
  read_mem $saddr
  nbytes=$(($nbytes - 1))
  saddr=$(($saddr + 1))
done

# Disable programming
i2cset -y 0 0x23 0x09 0x04

echo ''

