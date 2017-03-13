#Build_Clover
A script to build [CloverV2](https://sourceforge.net/p/cloverefiboot/code/HEAD/tree) bootloader under macOS X, Ubuntu 16.04+ and Debian Jessie 8.6+

##Author
Micky1979

##Contributors/Developers
Slice, Zenith432, STLVNUB, JrCs, cecekpawon, Needy, cvad, Rehabman, philip_petev, ErmaC

##Usage
Double _click_ the **Build_Clover.command** or _right click_ on the file, **Build_Clover.command**, and press _open_.
...

###Example output
>**Menu for less comfortable users:**

``` bash
================================================================================
Build_Clover script v4.3.2                                  No update available.
                             <--------------------------------------------------
================================================================================
By Micky1979 based on Slice, Zenith432, STLVNUB, JrCs, cecekpawon, Needy,
cvad, Rehabman, philip_petev, ErmaC

Supported OSes: macOS X, Ubuntu (16.04/16.10), Debian Jessie (8.4/8.5/8.6/8.7)
                             <--------------------------------------------------
CLOVER	Remote revision: 4037	Local revision: 4037
EDK2	Remote revision: 24096	Local revision: 24063

The current local EDK2 revision is the suggested one (24063).
                             <--------------------------------------------------
Please enter your choice:
 1) update Clover only (no building)
 2) update Clover + force edk2 update (no building)
 3) run my script on the source
 4) build existing revision (no update, for testing only)
 5) build existing revision for release (no update, standard build)
 6) build existing revision with custom macros enabled
 7) info and limitations about this script
 8) enter Developers mode (only for devs)
 9) Exit
```
>**Menu for advanced users:**

``` bash
Please enter your choice:
    EDK2 revision used r24063 latest avaiable is r24096
 1) build with ./ebuild.sh -nb
 2) build with ./ebuild.sh --module=rEFIt_UEFI/refit.inf
 3) build binaries w/o -fr (boot6 and 7)
 4) build binaries with -fr (boot6 and 7)
 5) build boot6/7 with -fr --std-ebda
 6) build pkg
 7) build iso
 8) build pkg+iso
 9) build all for Release
 10) Back to Main Menu
 11) Exit
```
##Other
**Special thanks to the [InsanelyMac board](http://www.insanelymac.com/forum/topic/313240-build-clovercommand-another-script-to-build-standard-clover-or-customized/ "www.insanelymac.com/forum/topic/313240-build-clovercommand-another-script-to-build-standard-clover-or-customized/") and its members, who are testing the script and report issues.**

