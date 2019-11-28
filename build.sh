#!/bin/bash
riscv32-unknown-linux-gnu-gcc main.c -nostdlib -nostartfiles -march=rv32i -mabi=ilp32

