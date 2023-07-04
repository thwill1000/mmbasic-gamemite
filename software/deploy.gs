break
rmkdir A:/pglcd
xsend -t="-DPGLCD2" src/startup.bas A:/pglcd/startup.bas
xsend -t="-DPGLCD2" src/menu.bas A:/pglcd/menu.bas
xsend -t="-DPGLCD2" ../../mmbasic-sptools/src/splib/examples/ctrl-demo-2.bas A:/pglcd/ctrl-demo-2.bas
xsend -t="-DPGLCD2" ../../mmbasic-sptools/src/splib/examples/sound-demo.bas A:/pglcd/sound-demo.bas
xsend -t="-DPGLCD2" ../../mmbasic-lazer-cycle/src/lazer-cycle.bas A:/pglcd/lazer-cycle.bas
xsend -t="-DPGLCD2" ../../mmbasic-third-party/pico-vaders/pico-vaders.bas A:/pglcd/pico-vaders.bas
xsend -t="-DPGLCD2" ../../mmbasic-third-party/3d-maze/3d-maze.bas A:/pglcd/3d-maze.bas
rex flash erase 1
rex load "A:/pglcd/startup.bas"
rex flash save 1
rex option autorun 1
