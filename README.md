<!-- Badges section here. -->
[![GitHub last commit](https://img.shields.io/github/last-commit/google/skia.svg)](https://github.com/Micky1979/Build_Clover)

# Build_Clover
A script to build [Clover V2](https://sourceforge.net/p/cloverefiboot/code/HEAD/tree) bootloader under macOS / OS X, Ubuntu 16.04+ and Debian Jessie and Stretch

## Author
Micky1979

## Contributors/Developers
Slice, Zenith432, STLVNUB, JrCs, cecekpawon, Needy, cvad, Rehabman, philip_petev, ErmaC

## Usage
Double _click_ the **Build_Clover.command** or _right click_ on the file, **Build_Clover.command**, and press _open_.
...

### Example output
>**Menu for less comfortable users:**

``` bash
================================================================================
Build_Clover script v4.7.0                                  No update available.
                             <--------------------------------------------------
================================================================================
By Micky1979 based on Slice, apianti, vit9696, Download Fritz, Zenith432,
STLVNUB, JrCs,cecekpawon, Needy, cvad, Rehabman, philip_petev, ErmaC

Supported OSes: macOS X, Ubuntu (16.04/16.10), Debian Jessie and Stretch
                             <--------------------------------------------------
CLOVER	Remote revision: 4406	Local revision: 4406
EDK2	Remote revision: 26286	Local revision: 26277

The current local EDK2 revision is the suggested one (26277). 
Used settings: /home/username/BuildCloverConfig.txt 
                             <--------------------------------------------------
Please enter your choice: 
 1) add "buildclover" symlink to /usr/local/bin
 2) update Clover only (no building)
 3) update Clover + force edk2 update (no building)
 4) run my script on the source
 5) build existing revision (no update, for testing only)
 6) build existing revision for release (no update, standard build)
 7) build existing revision with custom macros enabled
 8) enter Developers mode (only for devs)
 9) edit the configuration file
 10) Exit
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
## Other
**Special thanks to the [InsanelyMac board](http://www.insanelymac.com/forum/topic/313240-build-clovercommand-another-script-to-build-standard-clover-or-customized/) and its members, who are testing the script and report issues.**

