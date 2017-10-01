# Build_Clover
A script to build [Clover V2](https://sourceforge.net/p/cloverefiboot/code/HEAD/tree) bootloader under macOS / OS X, Ubuntu 16.04+ and Debian Jessie 8.6+

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
Build_Clover script v4.5.6                                  No update available.
                             <--------------------------------------------------
================================================================================
By Micky1979 based on Slice, Zenith432, STLVNUB, JrCs, cecekpawon, Needy,
cvad, Rehabman, philip_petev, ErmaC

Supported OSes: macOS X, Ubuntu (16.04/16.10), Debian Jessie and Stretch
                             <--------------------------------------------------
CLOVER	Remote revision: 4232	Local revision: 4232
EDK2	Remote revision: 25452	Local revision: 25373

The current local EDK2 revision is the suggested one (25373).
                             <--------------------------------------------------
Please enter your choice:
 1) add "buildclover" symlink to /usr/local/bin
 2) update Clover only (no building)
 3) update Clover + force edk2 update (no building)
 4) run my script on the source
 5) build existing revision (no update, for testing only)
 6) build existing revision for release (no update, standard build)
 7) build existing revision with custom macros enabled
 8) info and limitations about this script
 9) enter Developers mode (only for devs)
 10) manage Build_Clover.command preferences
 11) Exit
```
>**Menu for advanced users:**

``` bash
Please enter your choice:
    EDK2 revision used r25373 latest avaiable is r25452
 1) add "buildclover" symlink to /usr/local/bin
 2) build with ./ebuild.sh -nb
 3) build with ./ebuild.sh --module=rEFIt_UEFI/refit.inf
 4) build binaries w/o -fr (boot6 and 7)
 5) build binaries with -fr (boot6 and 7)
 6) build boot6/7 with -fr --std-ebda
 7) build pkg
 8) build iso
 9) build pkg+iso
 10) build all for Release
 11) Back to Main Menu
 12) Exit
```
## Other
**Special thanks to the [InsanelyMac board](http://www.insanelymac.com/forum/topic/313240-build-clovercommand-another-script-to-build-standard-clover-or-customized/) and its members, who are testing the script and report issues.**

