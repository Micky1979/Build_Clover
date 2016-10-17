#Build_Clover

A script to build [CloverV2](https://sourceforge.net/p/cloverefiboot/code/HEAD/tree) bootloader under macOS X, Ubuntu 16.04+ and Debian Jessie 8.6+
##Author
Micky1979
##Contributors/Developers
Slice, Zenith432, STLVNUB, JrCs, cecekpawon, Needy, cvad, Rehabman, philip_petev, ErmaC

---
##Usage
Double _click_ the **Build_Clover.command** or _right click_ on the file, **Build_Clover.command**, and press _open_.
...
###Example output
>**Menu for less comfortable users:**

``` bash
========================================================================
Build_Clover script {VERSION}
                          <---------------------------------------------
========================================================================
By Micky1979 based on Slice, Zenith432, STLVNUB, JrCs, cecekpawon, Needy,
cvad, Rehabman, philip_petev, ErmaC

Supported OSes: macOS X, Ubuntu 16.04, Debian Jessie 8.6
                          <---------------------------------------------
Remote revision: 3761 Local revision: 3760
                          <---------------------------------------------
Please enter your choice: 
1) update Build_Clover.command
2) update Clover only (no building)
3) update & build Clover
4) run my script on the source
5) build existing revision (no update, for testing only)
6) build existing revision for release (no update, standard build)
7) build existing revision with custom macros enabled
8) info and limitations about this script
9) enter Developers mode (only for devs)
10) Exit
#? 
```
>**Menu for advanced users:**

``` bash
Please enter your choice: 
 1) build with ./ebuild.sh -nb
 2) build with ./ebuild.sh --module=rEFIt_UEFI/refit.inf
 3) build binaries (boot3, 6 and 7 also)
 4) build binaries with FORCEREBUILD (boot3, 6 and 7 also)
 5) build pkg
 6) build iso
 7) build pkg+iso
 8) build all for Release
 9) Back to Main Menu
10) Exit
#? 
```

##Other
**Special thanks to the [InsanelyMac board](http://www.insanelymac.com "www.insanelymac.com") and its members, who are testing the script and report issues.**

