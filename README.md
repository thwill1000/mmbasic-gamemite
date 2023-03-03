# PicoGAME LCD

The "PicoGAME LCD" is a handheld videogame based on the Raspberry Pico microcontroller running the [PicoMite](https://geoffg.net/picomite.html) firmware.

**Features:**

 - Raspberry Pico Microcontroller
 - 320x240 ILI9341 SPI LCD display + integrated SD card reader
 - NES style game controller (very clicky)
 - Two channel audio (that sounds like an irate hornet)
 - 3.7V LIPO battery with charging and protection circuit
 - MMBasic programming language

**Photos of the Mk-I:**

<img src="images/mk1-front.jpg" height="500"> <img src="images/mk1-back.jpg" height="500">

**YouTube video:**

&nbsp;&nbsp;&nbsp;&nbsp;<a href="https://www.youtube.com/watch?v=jB5hF2ZWHrA"><img src="https://www.gstatic.com/youtube/img/branding/youtubelogo/svg/youtubelogo.svg" width="10%" title="https://www.youtube.com/watch?v=jB5hF2ZWHrA"></a>

**Credits:**

 * PicoGAME LCD concept, prototype and software by Thomas Hugo Williams (@thwill)
 * Based on the "PicoMite Backpack" by @Mixtel90
 * PicoMite MMBasic:
     * Copyright 2011-2023 Geoff Graham
     * Copyright 2016-2023 Peter Mather
 * With thanks to @bigmik, @Turbo46 and @Volhout

## Hardware

 * [Schematic](hardware/pico-game-lcd-mk1/pico-game-lcd-mk1-schematic-0.1.2.pdf)
 * *PCB coming (not very) soon ... hopefully*

## Software (Games)

 * [Lazer Cycle](software/lazer-cycle-pglcd-095.bas)
 * *More coming soon ... hopefully*

## FAQ

**1. What is a PicoMite ?**

The PicoMite is a Raspberry Pi Pico running the free MMBasic interpreter.

MMBasic is a Microsoft BASIC compatible implementation of the BASIC language with floating point, integer and string variables, arrays, long variable names, a built in program editor and many other features.

Using MMBasic you can use communications protocols such as I2C or SPI to get data from a variety of sensors. You can save data to an SD card, display information on colour LCD displays, measure voltages, detect digital inputs and drive output pins to turn on lights, relays, etc. All from inside this low cost microcontroller.

The PicoMite firmware is totally free to download and use.

More information can be found on the official PicoMite website at https://geoffg.net/picomite.html

**2. How do I contact the creator of the PicoGAME LCD ?**

I can be contacted via:
 - https://github.com as user "thwill1000"
 - https://www.thebackshed.com/forum/ViewForum.php?FID=16 as user "thwill"

##

The PicoGAME LCD schematic and games are distributed for free but if you enjoy it then
perhaps you would like to buy me a coffee?

<a href="https://www.buymeacoffee.com/thwill"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="width:217px;"></a>
