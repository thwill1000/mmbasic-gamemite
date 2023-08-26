break
rmkdir A:/GameMite
xsend -t="-DPGLCD2" src/startup.bas A:/GameMite/startup.bas
xsend -t="-DPGLCD2" src/menu.bas A:/GameMite/menu.bas
xsend -t="-DPGLCD2" src/fm.bas A:/GameMite/fm.bas
xsend -t="-DPGLCD2" ../../mmbasic-sptools/src/splib/examples/ctrl-demo-2.bas A:/GameMite/ctrl-demo-2.bas
xsend -t="-DPGLCD2" ../../mmbasic-sptools/src/splib/examples/sound-demo.bas A:/GameMite/sound-demo.bas
xsend -t="-DPGLCD2" ../../mmbasic-lazer-cycle/src/lazer-cycle.bas A:/GameMite/lazer-cycle.bas
xsend -t="-DPGLCD2" ../../mmbasic-third-party/pico-vaders/pico-vaders.bas A:/GameMite/pico-vaders.bas
xsend -t="-DPGLCD2" ../../mmbasic-third-party/3d-maze/3d-maze.bas A:/GameMite/3d-maze.bas
xsend -t="-DPGLCD2" ../../cmm2-kingdom/src/kingdom.bas A:/GameMite/kingdom.bas
rex flash erase 1
rex load "A:/GameMite/startup.bas"
rex flash save 1
rex option autorun 1
