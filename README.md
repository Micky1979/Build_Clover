<h1>Build_Clover</h1>
<p>
A script to build <a href="https://sourceforge.net/p/cloverefiboot/code/HEAD/tree/">CloverV2</a> bootloader under macOS X and Ubuntu 16.04 +
</p>
<h2>Author</h2>
<p>
Micky1979
</p>
<h2>Contributors/Developers</h2>
<p>
Slice, Zenith432, STLVNUB, JrCs, cecekpawon, Needy, cvad, Rehabman, philip_petev
</p>
<h2>Usage</h2>
<p>
Double click the Build_Clover.command or right click on the file, Build_Clover.command, and press open.
...
<h4>Example output</h4>
<p>Menu for less comfortable users: </p>
<p>
<div class="highlight">
<pre>
===============================================================================
Build_Clover script {VERSION}
                          <----------------------------------------------------
===============================================================================
By Micky1979 based on Slice, Zenith432, STLVNUB, JrCs, cecekpawon, Needy,
cvad, Rehabman, philip_petev

Supported OSes: macOS X, Ubuntu 16.04
                          <----------------------------------------------------
Remote revision: 3761 Local revision: 3760
                          <----------------------------------------------------
Please enter your choice: 
1) update Clover only (no building)
2) update & build Clover
3) run my script on the source
4) build existing revision (no update, standard build)
5) build existing revision for release (no update, standard build)
6) build existing revision with custom macros enabled
7) info and limitations about this script
8) enter Developers mode (only for devs)
9) Exit
#? 
</pre>
</div>
<p>Menu for advanced users: </p>
<p>
<div class="highlight">
<pre>
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
</pre>
</div>
</p>
</p>

<h2>Other</h2>
<p>
Special thanks to the <a href="http://www.insanelymac.com">InsanelyMac board</a> and its members, who are testing the script and report issues.
</p>
