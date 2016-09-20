# Build_Clover
A script to build CloverV2 bootloader under macOS X and Ubuntu 16.04 +

<html>
<head>
<meta content="text/html; charset=ISO-8859-1"
http-equiv="content-type">
<title></title>
</head>
<body>
===============================================================================<br>
<span style="color: rgb(102, 51, 255);">Build_Clover script v4.0.3</span><br>
&lt;----------------------------------------------------<br>
===============================================================================<br>
<span style="color: rgb(102, 51, 255);">By Micky1979 based on Slice,
Zenith432, STLVNUB, JrCs, cecekpawon, Needy,</span><br
style="color: rgb(102, 51, 255);">
<span style="color: rgb(102, 51, 255);">cvad, Rehabman, philip_petev</span><br>
<br>
<span style="color: rgb(102, 51, 255);">Supported OSes: macOS X, Ubuntu
16.04</span><br>
&lt;----------------------------------------------------<br>
<span style="color: rgb(51, 204, 0);">Remote revision: 3760</span> <span
style="color: rgb(153, 153, 0);">Local revision: 3758 </span><br>
&lt;----------------------------------------------------<br>
Please enter your choice: <br>
1) update Clover only (no building)<br>
2) update &amp; build Clover<br>
3) run my script on the source<br>
4) build existing revision (no update, standard build)<br>
5) build existing revision for release (no update, standard build)<br>
6) build existing revision with custom macros enabled<br>
7) info and limitations about this script<br>
8) enter Developers mode (only for devs)<br>
9) Exit<br>
#?<br>
===============================================================================<br>
<br>
<big><big><span style="font-weight: bold;">Select architecture:</span></big></big><br>
<br>
===============================================================================<br>
<span style="color: rgb(102, 51, 255);">Select the desired architecture</span><br>
&lt;----------------------------------------------------<br>
1) Standard with both ia32 and x64<br>
2) x64 only<br>
3) ia32 only<br>
<br>
<big><big><span style="font-weight: bold;">... by selecting option 6
(optional, advanced):</span></big></big><br>
<br>
===============================================================================<br>
<span style="color: rgb(102, 51, 255);">BUILD boot3 and boot7 with
additional macros</span><br>
&lt;----------------------------------------------------<br>
1) USE_APPLE_HFSPLUS_DRIVER<br>
2) USE_BIOS_BLOCKIO<br>
3) DISABLE_USB_SUPPORT<br>
4) NO_GRUB_DRIVERS<br>
5) NO_GRUB_DRIVERS_EMBEDDED<br>
6) ONLY_SATA_0<br>
7) DISABLE_UDMA_SUPPORT<br>
8) ENABLE_VBIOS_PATCH_CLOVEREFI<br>
9) ENABLE_PS2MOUSE_LEGACYBOOT<br>
10) DEBUG_ON_SERIAL_PORT<br>
11) DISABLE_LTO<br>
12) ENABLE_SECURE_BOOT<br>
13) USE_ION<br>
14) DISABLE_USB_MASS_STORAGE<br>
15) ENABLE_USB_OHCI<br>
16) ENABLE_USB_XHCI<br>
17) REAL_NVRAM<br>
18) CHECK_FLAGS<br>
<br>
actual macros defined: no one<br>
<br>
enter you choice or press "b" to build:<br>
===============================================================================<br>
<br style="font-weight: bold;">
<big><big><span style="font-weight: bold;">Developers mode (option 8 in
the main manu):</span></big></big><br>
<br>
Please enter your choice: <br>
1) build with ./ebuild.sh -nb<br>
2) build with ./ebuild.sh --module=rEFIt_UEFI/refit.inf<br>
3) build binaries (boot3, 6 and 7 also)<br>
4) build binaries with FORCEREBUILD (boot3, 6 and 7 also)<br>
5) build pkg<br>
6) build iso<br>
7) build pkg+iso<br>
8) build all for Release<br>
9) Back to Main Menu<br>
10) Exit<br>
</body>
</html>
