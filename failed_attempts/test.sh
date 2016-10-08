#!/bin/bash

echo "$@" > instruction.S
armv7a-hardfloat-linux-gnueabi-as -mfpu=neon instruction.S
armv7a-hardfloat-linux-gnueabi-objdump -d a.out | tail -n 1
