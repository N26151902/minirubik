#!/bin/bash
cd '/home/dogbear118/桌面/minirubik'
export DISPLAY=:0
export XAUTHORITY=/run/user/1000/.mutter-Xwaylandauth.1P9IW3
export QT_QPA_PLATFORM=xcb
exec "$HOME/下載/Ripes-v2.2.6-106-g5b8a616-linux-x86_64.AppImage" --mode cli --src report_vector.elf -t elf --proc RV32_ISS --iret --cycles --cpi --ipc --exectime --regs --runinfo
