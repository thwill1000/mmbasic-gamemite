break
rmkdir A:/GameMite
xsend -t="-n -e=1 -i=1 -DGAMEMITE" src/startup.bas A:/GameMite/startup.bas
xsend -t="-n -e=1 -i=1 -DGAMEMITE" src/menu.bas A:/GameMite/menu.bas
xsend -t="-n -e=1 -i=1 -DGAMEMITE" src/fm.bas A:/GameMite/fm.bas
xsend -t="-n -e=1 -i=1 -DGAMEMITE" ../../mmbasic-sptools/src/splib/examples/ctrl-demo-2.bas A:/GameMite/ctrl-demo-2.bas
xsend -t="-n -e=1 -i=1 -DGAMEMITE" ../../mmbasic-sptools/src/splib/examples/sound-demo.bas A:/GameMite/sound-demo.bas
xsend -t="-n -e=1 -i=1 -DGAMEMITE" ../../mmbasic-lazer-cycle/src/lazer-cycle.bas A:/GameMite/lazer-cycle.bas
xsend -t="-n -e=1 -i=1 -DGAMEMITE" ../../mmbasic-third-party/pico-vaders/pico-vaders.bas A:/GameMite/pico-vaders.bas
xsend -t="-n -e=1 -i=1 -DGAMEMITE" ../../mmbasic-third-party/3d-maze/3d-maze.bas A:/GameMite/3d-maze.bas
xsend -t="-n -e=1 -i=1 -DGAMEMITE" ../../mmbasic-kingdom/src/kingdom.bas A:/GameMite/kingdom.bas
rex flash erase 1
rex load "A:/GameMite/startup.bas"
rex flash save 1
rex option autorun 1
