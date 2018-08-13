#!/bin/bash
#set -x

# made by Micky1979 on 07/05/2016 based on Slice, apianti, Zenith432, STLVNUB, JrCs, cvad, Rehabman, and ErmaC works

# Tested in OSX using both GNU gcc and clang (Xcode 6.4, 7.2.1, 7.3.1 and Xcode 8).
# Preferred OS is El Capitan with Xcode >= 7.3.1 and Sierra with Xcode >= 8.
# In older version of OS X is better to use GNU gcc.

# Tested in linux Ubuntu (16.04 and 16.10) / Debian Jessie amd64 (x86_64).
# This script install all missing dependencies in the iso images you
# can download at the official download page here: http://releases.ubuntu.com/16.04/ubuntu-16.04.1-desktop-amd64.iso
# where nasm, subversion, curl (wget if installed is used as replacement) and or uuid-dev headers are missing.
# gcc 5.4 coming with Ubuntu 16.04 is well compiled for Clover, so no need to make a "cross" compilation of it, and 
# I hope will be the same for future version installed here. Debian Jessie instead use gcc 4.9.2 and is already good.
# Note that Debian comes without "sudo" installed (you well know this), but this script require dependecies
# described above so that you have install them by your self, or install sudo and enable it for your account.
#
# May you have apported radical and incompatible changes to your installation, but this is not my fault!
# New incoming release of Ubuntu/Debian should be compatible as well..

#
# Big thanks to the following testers:
# droples, Riley Freeman, pico joe, fantomas1, Fljagd, calibre, Mork vom Ork, Maniac10, Matgen84,
# Sherlocks, ellaosx, magnifico, AsusFreak, Badruzeus, LabyOne, Ukr55, D-an-W, SavageAUS, bronxteck,
# artur_pt, Didanix, polkaholga, Regi Yassin, cyberdevs, ricoc90, tluck, PMheart, fusion71au, ctich,
# FredWst, Nightf4ll, BluemaP1E
# and all others (I'll be happy to increase this list and to not forgot anyone)
#

# --------------------------------------
SCRIPTVER="v4.8.9"
RSCRIPT_INFO="Sync with edk2 r27429."
RSCRIPTVER=""
export LC_ALL=C
SYSNAME="$( uname )"
BUILDER=$USER # don't touch!
# ---------------------------->
# default behavior (don't touch these vars)
BuildCloverRepo="https://github.com/Micky1979/Build_Clover.git"
NASM_PREFERRED="2.13.03"
MAKEPKG_CMD="make pkg"
LTO_FLAG="" # default for Xcode >= 7.3, will automatically adjusted for older ones
MOD_PKG_FLAG="YES" # used only when you add custom macros. Does nothing for normal build.
DEFINED_MACRO=""
CUSTOM_BUILD="NO"
START_BUILD=""
TIMES=0
SYMLINKPATH='/usr/local/bin/buildclover'
SCRIPT_ABS_PATH=""
SCRIPT_ABS_LOC=""
DOWNLOADER_CMD=""
DOWNLOADER_PATH=""
SELF_UPDATE_OPT="NO" # show hide selfUpdate option
PING_RESPONSE="NO" # show hide option with connection dependency
REMOTE_EDK2_REV="" # info for developer submenu this mean to show latest rev avaiable

edk2array=(
	MdePkg
	MdeModulePkg
	CryptoPkg
	DuetPkg
	EdkCompatibilityPkg
	IntelFrameworkModulePkg
	IntelFrameworkPkg
	OvmfPkg
	OptionRomPkg
	PcAtChipsetPkg
	ShellPkg
	UefiCpuPkg
	BaseTools
	)

ThirdPartyList=(
	https://github.com/vit9696/AptioFixPkg.git
	https://github.com/CupertinoNet/CupertinoModulePkg
	https://github.com/CupertinoNet/EfiMiscPkg
	https://github.com/CupertinoNet/EfiPkg
	https://github.com/acidanthera/AppleSupportPkg.git
)
# ---------------------------->
# additional macro to compile Clover EFI
macros=(
	USE_APPLE_HFSPLUS_DRIVER
	USE_BIOS_BLOCKIO
	DISABLE_USB_SUPPORT
	NO_GRUB_DRIVERS
	NO_GRUB_DRIVERS_EMBEDDED
	ONLY_SATA_0
	DISABLE_UDMA_SUPPORT
	ENABLE_VBIOS_PATCH_CLOVEREFI
	ENABLE_PS2MOUSE_LEGACYBOOT
	DEBUG_ON_SERIAL_PORT
	ENABLE_SECURE_BOOT
	USE_ION
	DISABLE_USB_MASS_STORAGE
	ENABLE_USB_OHCI
	ENABLE_USB_XHCI
	REAL_NVRAM
	)
# defaults for all the variables, taken from the config file 
var_defaults=(
	"XCODE",,,
	"GNU",,,
	"Build_Tool",,,"XCODE"
	"SUGGESTED_CLOVER_REV",,,
	"MODE",,,"S"
	"DEFAULT_MACROS",,,"-D NO_GRUB_DRIVERS_EMBEDDED"
	"PATCHES",,,"$HOME/CloverPatches"
	"BUILD_PKG",,,"YES"
	"BUILD_ISO",,,"NO"
	"USEHFSPLUS",,,"NO"
	"USEAPFS",,,"NO"
	"USENTFS",,,"NO"
	"GITHUB",,,"https://raw.githubusercontent.com/Micky1979/Build_Clover/master/Build_Clover.command"
	"CLOVER_REP",,,"https://svn.code.sf.net/p/cloverefiboot/code"
	"EDK2_REP",,,"https://svn.code.sf.net/p/edk2/code/trunk/edk2"
	"DISABLE_CLEAR",,,"NO"
	"MY_SCRIPT",,,
	"FAST_UPDATE",,,"NO"
	"INTERACTIVE",,,"YES"
	"SVN_UPDATE_ACCEPT_ARG",,,"tf"
	"ForceEDK2Update",,,"0"
	"ARCH",,,"X64"
	"FORCEREBUILD",,,"-fr"
	"SHOWCCP_ADVERTISE",,,"YES"
	)
# --------------------------------------
# FUNCTIONS
# --------------------------------------
usage() {
printf "\n\e[1m%s\e[0m" "Usage: $0 [--edk2rev <revision>] [--defaults]"
echo
printf "\n%s" "The following optional arguments are recognized:"
echo
printf "\n\e[1m%s\e[0m\t%s" "--edk2rev <revision>" "Overrides the defauls EDK2 revision. If <revision> is ommited or not numeric-only,"
printf "\n\t\t\t%s" "the default EDK2 revision will be used instead."
echo
printf "\n\e[1m%s\e[0m\t\t%s" "--defaults" "Ignores the config file and loads the default values for all settings in that file."
echo
printf "\n\e[1m%s\e[0m\t\t%s" "--cfg <path>" "Overrides the path to the config file. If <path> is ommited or doesn't exist,"
printf "\n\t\t\t%s" "the \$HOME / \$BUILD_CLOVER_CFG_PATH variables will be used instead."
echo
printf "\n%s" "If no argument is provided, the script starts in interactive mode, using the default edk2 revision"
printf "\n%s" "and the settings from the config file."
echo
}
# --------------------------------------
setPaths() {
# setting default paths
case "$MODE" in
	"S" )
		export DIR_MAIN=${DIR_MAIN:-"${HOME}"/src};;
	"R" )
		export DIR_MAIN="${SCRIPT_ABS_PATH}"/src
		if [[ "${DIR_MAIN}" = "${DIR_MAIN%[[:space:]]*}" ]]; then
			echo "good, no blank spaces in DIR_MAIN, continuing.."
		else
			ClearScreen; printError "Error: MODE=\"R\" require a path with no spaces in the middle, exiting!\n"; exit 1
		fi;;
	* )
		ClearScreen; printError "Error: unsupported MODE\n"; exit 1;;
esac
if [[ ! -d "${DIR_MAIN}" ]]; then mkdir -p "${DIR_MAIN}"; fi
SVN_STDERR_LOG="${DIR_MAIN}/svnLog.txt"
CLOVERV2_PATH="${DIR_MAIN}/edk2/Clover/CloverPackage/CloverV2"
PKG_PATH="${DIR_MAIN}/edk2/Clover/CloverPackage/package"
LOCALIZABLE_FILE="${PKG_PATH}/Resources/templates/Localizable.strings"
ebuildB="${DIR_MAIN}/edk2/Clover/ebuildBorg.sh"
ebuild="${DIR_MAIN}/edk2/Clover/ebuild.sh"
exportPaths
}
# --------------------------------------
setBuildTools() {
# Setting the build tool (Xcode or GCC)
case "$SYSNAME" in
	Darwin ) 
		case "$Build_Tool" in
		"XCODE" | "xcode" ) checkXcode; BUILDTOOL="$XCODE";;
		"GNU" | "gnu" ) [[ "$GNU" == "" ]] && BUILDTOOL="GCC53" || BUILDTOOL="$GNU";;
		* ) printError "Wrong build tool: $Build_Tool. It should be \"XCODE\" or \"GNU\" !!!"; exit 1;;
		esac;;
	Linux ) [[ "$GNU" == "" ]] && BUILDTOOL="GCC53" || BUILDTOOL="$GNU";;
esac
}
# --------------------------------------
ClearScreen() {
if [[ "$DISABLE_CLEAR" != "YES" ]]; then clear; fi
}
# --------------------------------------
LoadDefaults() {
for i in "${var_defaults[@]}"
do
	eval "export \"${i%,,,*}=${i#*,,,}\""
done
}
# --------------------------------------
CreateDefaultConf() {
if [[ ! -f "${userconf}" ]]; then
	if [[ ! -d "$(dirname ${userconf})" ]]; then mkdir -p "$(dirname ${userconf})"; fi
	touch "${userconf}"
fi
for i in "${var_defaults[@]}"
do
	echo "${i%,,,*}=${i#*,,,}" >> "${userconf}"
done
}
# --------------------------------------
ReadConf() {
for i in "${var_defaults[@]}"
do
	if cat "${userconf}" | grep "^${i%,,,*}=" 1>/dev/null 2>&1; then
#		echo "Variable ${i%,,,*} found, loading..."
		eval "export \"$(cat ${userconf} | grep ^${i%,,,*}=)\""
	else
#		echo "Variable ${i%,,,*} not found in config, restoring defaut value..."
		echo "${i%,,,*}=${i#*,,,}" >> "${userconf}"
		eval "export \"${i%,,,*}=${i#*,,,}\""
	fi
done
}
# --------------------------------------
CheckProprietary() {
local drivers_off="${DIR_MAIN}/edk2/Clover/CloverPackage/CloverV2/drivers-Off"
local ghlink="https://github.com/Micky1979/Build_Clover/raw/work/Files"
local efifiles=()

if [[ "$USEHFSPLUS" == "YES" ]]; then efifiles+=('HFSPlus_ia32.efi'); efifiles+=('HFSPlus_x64.efi'); fi
if [[ "$USEAPFS" == "YES" ]]; then efifiles+=('apfs.efi'); fi
if [[ "$USENTFS" == "YES" ]]; then efifiles+=('NTFS.efi'); fi
	
if [[ "${#efifiles[@]}" -ge "1" ]]; then
	printMessage "The following proprietary EFI drivers will be added to the Clover package:"
	printWarning "\n${efifiles[*]}\n"
else
	return 0
fi

for fname in "${efifiles[@]}"
do
	if [[ ! -f "${DIR_MAIN}/tools/${fname}" ]]; then
		printWarning "\n${fname} not found, downloading..."
		downloader "${ghlink}/${fname}" "${DIR_MAIN}/tools" "${fname}"
	fi
	printMessage "\nAdding ${fname}..."
	if [[ "${fname}" == *"_ia32"* ]]; then
		if [[ -d "${drivers_off}/drivers32" ]]; then
			cp -f "${DIR_MAIN}/tools/${fname}" "${drivers_off}/drivers32/${fname//_ia32/-32}"
		else
			printWarning "\ndrivers32 not found, maybe that arch hasn't been selected, skipping..."
		fi
	else
		if [[ -d "${drivers_off}/drivers64" ]]; then
			if [[ "${fname}" == *"_x64"* ]]; then
				cp -f "${DIR_MAIN}/tools/${fname}" "${drivers_off}/drivers64/${fname//_x64/-64}"
			else
				cp -f "${DIR_MAIN}/tools/${fname}" "${drivers_off}/drivers64/${fname//.efi/-64.efi}"
			fi
		else
			printWarning "\ndrivers64 not found, maybe that arch hasn't been selected, skipping..."
		fi
		if [[ -d "${drivers_off}/drivers64UEFI" ]]; then
			if [[ "${fname}" == *"_x64"* ]]; then
				cp -f "${DIR_MAIN}/tools/${fname}" "${drivers_off}/drivers64UEFI/${fname//_x64}"
			else
				cp -f "${DIR_MAIN}/tools/${fname}" "${drivers_off}/drivers64UEFI/${fname}"
			fi
		else
			printWarning "\ndrivers64UEFI not found, maybe that arch hasn't been selected, skipping..."
		fi
	fi
done
}
# --------------------------------------
CleanExit() {
if [[ -f /tmp/Build_Clover.tmp ]]; then rm -f /tmp/Build_Clover.tmp; fi
exit 0
}
# --------------------------------------
OsOpen() {
if [[ "$SYSNAME" == Darwin ]]; then
	open "${1}" > /dev/null 2>&1
else
	if which xdg-open > /dev/null; then
		xdg-open "${1}" > /dev/null 2>&1
	elif which gnome-open > /dev/null; then
		gnome-open "${1}" > /dev/null 2>&1
	fi
fi
}
# --------------------------------------
FindScriptPath() {
	local s_path s_name l_path
	local s_orig=$(which "${0}")
	if [[ -L "$s_orig" ]]; then
		[[ "$SYSNAME" == Linux ]] && l_path=$(readlink -f "$s_orig") || l_path=$(readlink "$s_orig")
		s_path=$(dirname "$l_path"); s_name=$(basename "$l_path")
	else
		s_path=$(dirname "$s_orig"); s_name=$(basename "$s_orig")
	fi
	SCRIPT_ABS_PATH=$( cd "${s_path}" && pwd )
	SCRIPT_ABS_LOC="${SCRIPT_ABS_PATH}"/"${s_name}"
}
# --------------------------------------
IsNumericOnly() {
[[ "${1}" =~ ^-?[0-9]+$ ]] && return 0 || return 1
}
# --------------------------------------
pressAnyKey(){
[[ "${2}" != noclear ]] && ClearScreen
printf "${1}\n"
read -rsp $'Press any key to continue...\n' -n1 key
ClearScreen
}
# --------------------------------------
selfUpdate() {
printHeader "SELF UPDATE"
printf "\nA new Build_Clover.command is available,\n"
printf "do you want to overwrite the script? (Y/n): "
read answer
case $answer in
	Y | y)
		if [[ -f /tmp/Build_Clover.tmp ]]; then
			cat /tmp/Build_Clover.tmp > "${SCRIPT_ABS_LOC}"
			exec "${SCRIPT_ABS_LOC}"
		else
			pressAnyKey 'Was not possible to update Build_Clover.command,'
		fi;;
esac
}
# --------------------------------------
printThickLine() {
printf "%*s\n" 80 | tr " " "="
}
# --------------------------------------
printLine() {
printf "\n%*s\n" 80 $( printf "<%*s\n" 50 | tr " " "-" )
}
# --------------------------------------
printHeader() {
printThickLine
printf "\e[1;34m${1}\e[0m"
printLine
}
# --------------------------------------
printError() {
printf "\e[1;31m${1}\e[0m"
#exit 1
}
# --------------------------------------
printWarning() {
printf "\e[1;33m${1}\e[0m"
}
# --------------------------------------
printMessage() {
printf "\e[1;32m${1}\e[0m\040"
}
# --------------------------------------
addSymlink() {
ClearScreen
if [[ ! -d "$(dirname $SYMLINKPATH)" ]]; then
	printError "$(dirname $SYMLINKPATH) does not exist, cannot add a symlink..\n"
	pressAnyKey '\n'
	cbuild
fi
[[ "$USER" != root ]] && echo "type your password to add the symlink:"
[[ -d "${SYMLINKPATH}" ]] && sudo rm -rf "${SYMLINKPATH}" # just in case there's a folder with the same name
eval "sudo ln -nfs \"${SCRIPT_ABS_LOC}\" $SYMLINKPATH"
if [[ $? -ne 0 ]] ; then
	printError "\no_Ops, something wrong, cannot add the symlink..\n"
	pressAnyKey '\n' noclear
	sudo -k && cbuild
else
	echo "now is possible to open the Terminal and type \"buildclover\""
	echo "to simply run Build_Clover.command.."
	pressAnyKey '..the script will be closed to allow you to do that!\n' noclear
	sudo -k && CleanExit
fi
}
# --------------------------------------
initialChecks() {
if [[ "$SYSNAME" == Linux ]]; then
	local depend=""
	if [[ "$(uname -m)" != x86_64 ]]; then
		printError "\nBuild_Clover.command is tested only on x86_64 architecture, aborting..\n"
		exit 1
	fi
	# check if the Universally Unique ID library - headers are installed
	[[ "$(apt-cache policy uuid-dev | grep 'Installed: (none)')" =~ 'Installed: (none)' ]] && depend+=" uuid-dev"
	# check if subversion is installed
	[[ ! -x $(which svn) ]] && depend+=" subversion"
	# check if python is installed
	[[ ! -x $(which python) ]] && depend+=" python"
	# check if gcc or is installed. As a workaround for Linux Mint, it checks for g++ as well
	[[ ! -x $(which gcc) || ! -x $(which g++) ]] && depend+=" build-essential"
	# check whether at least one of curl or wget are installed
	[[ ! -x $(which wget) && ! -x $(which curl) ]] && depend+=" wget"
	# installing the dependencies
	if [[ "$depend" != "" ]]; then ClearScreen; aptInstall "${depend:1}"; fi
	# set the donloader command path
	if [[ -x $(which wget) ]]; then
		DOWNLOADER_PATH=$(dirname $(which wget))
		DOWNLOADER_CMD="wget"
	elif [[ -x $(which curl) ]]; then
		DOWNLOADER_PATH=$(dirname $(which curl))
		DOWNLOADER_CMD="curl"
	else
		printError "\nNo curl nor wget are installed! Install one of them and retry..\n"; exit 1
	fi
else
	# /usr/bin/curl!! (philip_petev)
	DOWNLOADER_PATH=/usr/bin
	DOWNLOADER_CMD="curl"
fi
}
# --------------------------------------
printCloverScriptRev() {
ClearScreen
local LVALUE RVALUE SVERSION RSDATA
local SNameVer="Build_Clover script ${SCRIPTVER}"

if git ls-remote "${BuildCloverRepo}" HEAD >> /dev/null 2>&1; then
	# Retrive and filter remote script version
	downloader "$GITHUB" "/tmp" "Build_Clover.tmp"
	RSCRIPTVER=$( cat /tmp/Build_Clover.tmp | grep '^SCRIPTVER="v' | tr -cd '.0-9' )
	LVALUE=$( echo $SCRIPTVER | tr -cd [:digit:] )
	RVALUE=$( echo $RSCRIPTVER | tr -cd [:digit:] )

	RSCRIPT_INFO=$( cat /tmp/Build_Clover.tmp | grep '^RSCRIPT_INFO=' | cut -d '"' -f 2 )

	printThickLine
	if IsNumericOnly $RVALUE; then
		# Compare local and remote script version
		[[ $LVALUE -ge $RVALUE ]] && SELF_UPDATE_OPT="NO" || SELF_UPDATE_OPT="YES"
		[[ $LVALUE -eq $RVALUE ]] && printf "\e[1;34m${SNameVer}\e[1;32m%*s\e[0m" $((80-${#SNameVer})) "No update available."
		[[ $LVALUE -gt $RVALUE ]] && printf "\e[1;34m${SNameVer}\e[1;33m%*s\e[0m" $((80-${#SNameVer})) "Wow, are you coming from the future?"
		[[ $LVALUE -lt $RVALUE ]] && printf "\e[1;34m${SNameVer}\e[1;5;33m%*s\e[0m" $((80-${#SNameVer})) "Update available (v$RSCRIPTVER)"
	else
		printf "${SNameVer}\e[1;31m\n%s\e[0m" "Remote version unavailable due to unknown reasons!"
	fi
else
	printThickLine
	printf "${SNameVer}\e[1;31m\n%s\n%s\e[0m" "Remote version unavailable, because GitHub is unreachable," "check your internet connection!"
fi
printLine
}
# --------------------------------------
printScriptRevInfo() {
if [[ "$SELF_UPDATE_OPT" == YES ]]; then
	local WHAT_NEW="What's New in Version $RSCRIPTVER?"
	printThickLine
	printf "\e[1;33m%*s\e[0m\n" $((80-${#WHAT_NEW})) "What's New in Version $RSCRIPTVER?"
	echo
	printf "\e[1m$RSCRIPT_INFO\e[0m\n"
fi
}
# --------------------------------------
printRevisions() {
local Clover_Remote Clover_Local EDK2_Remote EDK2_Local
local Unknown="\e[1;31munknown"
# Checking if the local and remote revisions are empty or not
[[ -z "$REMOTE_REV" || -z "$REMOTE_EDK2_REV" ]] && PING_RESPONSE="NO" || PING_RESPONSE="YES"
[[ -z "$REMOTE_REV" ]] && Clover_Remote="$Unknown" || Clover_Remote="$REMOTE_REV"
[[ -z "$LOCAL_REV" ]] && Clover_Local="$Unknown" || Clover_Local="$LOCAL_REV"
[[ -z "$REMOTE_EDK2_REV" ]] && EDK2_Remote="$Unknown" || EDK2_Remote="$REMOTE_EDK2_REV"
[[ -z "$LOCAL_EDK2_REV" ]] && EDK2_Local="$Unknown" || EDK2_Local="$LOCAL_EDK2_REV"

# Coloring the local revisions green (if they're equal to the remote revisions) or yellow (if they're not)
[[ "${Clover_Local}" == "${Clover_Remote}" ]] && Clover_Remote="\e[1;32m${Clover_Remote}" || Clover_Remote="\e[1;33m${Clover_Remote}"
[[ "${EDK2_Local}" == "${EDK2_Remote}" ]] && EDK2_Remote="\e[1;32m${EDK2_Remote}" || EDK2_Remote="\e[1;33m${EDK2_Remote}"

# Printing the results on screen	
printf "\e[1;32mCLOVER\tRemote revision: %b\t\e[1;32mLocal revision: %b\e[0m" "${Clover_Remote}" "${Clover_Local}"
printf "\n\e[1;32mEDK2\tRemote revision: %b\t\e[1;32mLocal revision: %b\e[0m\n" "${EDK2_Remote}" "${EDK2_Local}"

# Printing the error messages in case the local and remote revisions are empty
[[ "$Clover_Remote" == "$Unknown" ]] && printError "Something went wrong while getting the CLOVER remote revision,\ncheck your internet connection!\n"
[[ "$Clover_Local" == "$Unknown" ]] && printError "Something went wrong while getting the CLOVER local revision!\n"
[[ "$EDK2_Remote" == "$Unknown" ]] && printError "Something went wrong while getting the EDK2 remote revision,\ncheck your internet connection!\n"
[[ "$EDK2_Local" == "$Unknown" ]] && printError "Something went wrong while getting the EDK2 local revision!\n"

# Checking if the local EDK2 revision is the suggested one or not
echo
if [[ "${cus_edk2}" == "Y" ]]; then
	printWarning "User-provided EDK2 revision: ${EDK2_REV}\n\n"
fi
if [[ "${LOCAL_EDK2_REV}" == "${EDK2_REV}" ]]; then
	printMessage "The current local EDK2 revision is the suggested one (${EDK2_REV})."
else
	printWarning "\e[5mThe current local EDK2 revision is not the suggested one (${EDK2_REV})!"
	printWarning "\nIt's recommended to change it to the suggested one,"
	printWarning "\nusing the \e[1;32mupdate Clover + force edk2 update\e[1;33m option!"
fi
if [[ "${useDefaults}" == "Y" ]]; then
	printMessage "\nUsed settings: default"
else
	printMessage "\nUsed settings: \e[1;33m${userconf}\e[0m"
fi
printLine
}
# --------------------------------------
downloader(){
#$1 link
#$2 path (where will be saved)
#$3 file name
local cmd=""
case "$DOWNLOADER_CMD" in
	wget )	cmd="${DOWNLOADER_PATH}/${DOWNLOADER_CMD} -qO- ${1}";;
	curl )	cmd="${DOWNLOADER_PATH}/${DOWNLOADER_CMD} -sL ${1}";;
	* ) printError "\nNo curl nor wget are installed! Install one of them and retry..\n"; exit 1;;
esac
if [[ ! -z "${2}" && ! -z "${3}" && -d "${2}" ]]; then
	case "$DOWNLOADER_CMD" in
		wget ) cmd="${DOWNLOADER_PATH}/${DOWNLOADER_CMD} -qO ${2}/${3} ${1}";;
		curl ) cmd="${DOWNLOADER_PATH}/${DOWNLOADER_CMD} -sL -o ${2}/${3} ${1}";;
	esac
	if [[ -d "${2}/${3}" ]]; then rm -rf "${2}/${3}"; fi
fi
eval "${cmd}"
}
# --------------------------------------
aptInstall() {
if [[ -z "${1}" ]]; then return; fi
printWarning "Build_Clover need this:\n"
printError "${1}\n"
printWarning "..to be installed, but was not found.\n"
printWarning "Would you allow to install it? (Y/N)\n"
read answer
case $answer in
	Y | y ) if [[ "$USER" != root ]]; then echo "type your password to install:"; fi
			sudo apt-get update
			sudo apt-get install $1;;
	*) printError "Build_Clover cannot go ahead without it/them, process aborted!\n"; exit 1;;
esac
sudo -k
}
# --------------------------------------
# Upgrage SVN working copy
svnUpgrade() {
svn info "${DIR_MAIN}/edk2/Clover" 2>&1 | grep 'svn upgrade'
# if the svn working directory is outdated, let the user know
if [[ $? -eq 0 ]]; then
	printError "Error: You need to upgrade the working copy first.\n"
	for workingCopy in `find "${DIR_MAIN}/edk2" -name "*.svn"`
	do
		if [[ -d "$(dirname $workingCopy)" ]]; then
			printWarning "Would you like to upgrade the, $(dirname $workingCopy), working copy? (y/n)\n"
			read input
			case $input in
				Y | y) printWarning "Upgrading $(dirname $workingCopy).\n"; svn upgrade "$(dirname $workingCopy)";;
				*) printWarning "You may encounter errors!\n";;
			esac
		fi
	done
fi
}
# --------------------------------------
# Remote and local revisions
getRev() {
REMOTE_REV=$(svnWithErrorCheck "info ${CLOVER_REP}" | grep '^Revision:' | tr -cd [:digit:])
REMOTE_EDK2_REV=$(svnWithErrorCheck "info ${EDK2_REP}" | grep '^Revision:' | tr -cd [:digit:])
if ! IsNumericOnly "${REMOTE_REV}"; then REMOTE_REV=""; fi
if ! IsNumericOnly "${REMOTE_EDK2_REV}"; then REMOTE_EDK2_REV=""; fi

if [[ -d "${DIR_MAIN}"/edk2/Clover/.svn ]]; then
	svnUpgrade # upgrade the working copy to avoid errors
	LOCAL_REV=$(svn info "${DIR_MAIN}"/edk2/Clover | grep '^Revision:' | tr -cd [:digit:])
else
	LOCAL_REV=""
fi
if [[ -d "${DIR_MAIN}"/edk2/.svn ]]; then
	LOCAL_EDK2_REV=$(svn info "${DIR_MAIN}"/edk2 | grep '^Revision:' | tr -cd [:digit:])
else
	LOCAL_EDK2_REV=""
fi
}
# --------------------------------------
selectArch() {
archs=(
	'Standard x64 only'
	'ia32 and x64 (ia32 is deprecated)'
	'ia32 only (deprecated)'
	'Back to Main Menu'
	'Exit'
)
ClearScreen
printHeader "Select the desired architecture"
if [[ -n "$1" ]]; then echo "$1"; echo; fi
local count=1
for op in "${archs[@]}"
do
	case "${op}" in
		'Standard x64 only' ) printf "\e[1;36m\t ${count}) ${op}\e[0m\n";;
		* ) printf "\t $count) ${op}\n";;
	esac
	((count+=1))
done
printf '? ' && read opt
case $opt in
	1 ) ARCH="X64";;
	2 ) ARCH="IA32_X64";;
	3 ) ARCH="IA32";;
	4 ) ClearScreen && BUILDER=$USER && cbuild;;
	5 ) CleanExit;;
	* ) selectArch "invalid choice!";;
esac
if [[ "$SYSNAME" == Darwin && "$LOCAL_REV" -ge "4073" ]]; then slimPKG; fi
}
# --------------------------------------
slimPKG() {
archs=(
	'Standard'
	'slim pkg that skip themes and CloverThemeManager.app'
	'slim pkg that skip themes and CloverThemeManager.app, updater and PrefPanel'
	'slim pkg UEFI only, without RC Scripts, themes & CTM, updater and PrefPanel'
	'Back to Select architecture menu'
	'Exit'
)
ClearScreen
printHeader "Select the desired pkg type"
if [[ -n "$1" ]]; then echo "$1" && echo; fi
local count=1
for op in "${archs[@]}"
do
	case "${op}" in
		'Standard' ) printf "\e[1;36m\t ${count}) ${op}\e[0m\n";;
		* ) printf "\t $count) ${op}\n";;
	esac
	((count+=1))
done
printf '? ' && read opt
case $opt in
	1 ) MAKEPKG_CMD="make pkg";;
	2 ) MAKEPKG_CMD="make slimpkg1";;
	3 ) MAKEPKG_CMD="make slimpkg2";;
	4 ) MAKEPKG_CMD="make slimpkg3";;
	5 ) ClearScreen && selectArch;;
	6 ) CleanExit;;
	* ) slimPKG "invalid choice!";;
esac
}
# --------------------------------------
cleanCloverV2() {
c2paths=(
	"Bootloaders/ia32/boot3"
	"Bootloaders/x64/boot6"
	"Bootloaders/x64/boot7"
	"EFI/BOOT/BOOTIA32.efi"
	"EFI/BOOT/BOOTX64.efi"
	"EFI/CLOVER/CLOVERIA32.efi"
	"EFI/CLOVER/CLOVERX64.efi"
	"EFI/CLOVER/drivers32"
	"EFI/CLOVER/drivers32UEFI"
	"EFI/CLOVER/drivers64"
	"EFI/CLOVER/drivers64UEFI"
	"drivers-Off/drivers32"
	"drivers-Off/drivers32UEFI"
	"drivers-Off/drivers64"
	"drivers-Off/drivers64UEFI"
	)
if [[ -d "${CLOVERV2_PATH}" ]]; then
	for i in "${c2paths[@]}"
	do
		rm -rf "${CLOVERV2_PATH}/${i}"
	done
fi
}
# --------------------------------------
# Function: to manage PATH
pathmunge() {
if [[ ! $PATH =~ (^|:)$1(:|$) ]]; then
	if [[ "${2:-}" = "after" ]]; then
		export PATH=$PATH:$1
	else
		export PATH=$1:$PATH
	fi
fi
}
# --------------------------------------
checkXcode() {
if [[ ! -x /usr/bin/gcc ]]; then printError "Xcode clt not found, exiting!\n"; exit 1; fi
if [[ ! -x /usr/bin/xcodebuild ]]; then printError "xcodebuild not found, exiting!\n"; exit 1; fi
# Autodetect the Xcode version if no specific version is set (XCODE) and disable LTO if Xcode is version 7.2.x or earlier
if [[ "$XCODE" == "" ]]; then
	local xcversion=$(/usr/bin/xcodebuild -version | grep 'Xcode' | awk '{print $NF}')
	case "$xcversion" in
		[4-7] | [4-6].* | 7.[0-2]*) XCODE="XCODE5"; LTO_FLAG="--no-lto";;
		7.[34]*) XCODE="XCODE5";;
		[89]* | 10*) XCODE="XCODE8";;
		*) printError "Unknown Xcode version format, exiting!\n"; exit 1;;
	esac
fi
}
# --------------------------------------
doSomething() {
# $1 = option
# $2 = cmd
# $3 = first argument
# $4 = second argument
# $5 = ... and so on
local cmd=""
case "$1" in
	--run-script ) 
		if [[ -x "${2}" ]]; then
			# rebuild the cmd + all args
			cmd=$(echo "$@" | sed -e 's:--run-script ::g' | sed -e 's/[[:space:]]*$//')
		else
			echo
			echo "doSomething: \"--run-script\" option require you to add a script somewhere.."
			echo
		fi;;
		* ) printError "doSomething: invalid \"--run-script\" long option not specified\n"; exit 1;;
esac
eval "${cmd}"
if [[ $? -ne 0 ]] ; then printError "\no_Ops, $2 exited with error(s), aborting..\n"; exit 1; fi
}
# --------------------------------------
exportPaths() {
# STLVNUB
if [[ "$SYSNAME" == Linux ]]; then
	export TOOLCHAIN_DIR="/usr"
else
	export TOOLCHAIN_DIR="${DIR_MAIN}"/opt/local
fi
export PREFIX="$TOOLCHAIN_DIR"
if [[ -f "/opt/local/bin/nasm" ]]; then
	export NASM_PREFIX="/opt/local/bin/"
elif [[ -f "${TOOLCHAIN_DIR}/bin/nasm" ]]; then
	export NASM_PREFIX="${TOOLCHAIN_DIR}/bin/"
else
	# default for this script!
	export NASM_PREFIX="${TOOLCHAIN_DIR}/bin/"
fi
export DIR_TOOLS=${DIR_TOOLS:-$DIR_MAIN/tools}
export DIR_DOWNLOADS=${DIR_DOWNLOADS:-$DIR_TOOLS/download}
export DIR_LOGS=${DIR_LOGS:-$DIR_TOOLS/logs}
}
# --------------------------------------
exportXcodePaths() {
# Add XCode bin directory for the command line tools to the PATH
pathmunge "$(xcode-select --print-path)"/usr/bin
# Add toolchain bin directory to the PATH
pathmunge "$TOOLCHAIN_DIR"/bin
}
# --------------------------------------
svnWithErrorCheck() {
# $1 = arguments for the svn command to be execute (svn command is added here for security reason)
# $2 = containing folder of our /.svn we are attempting to work on
# $3 = reserved argument ("once") indicating we are calling 'svn resolve'
# $4 = reserved argument equal to initial $1 command string

if [[ -z "${1}" ]]; then return; fi

local cmd="${1}"
if [[ -n "${4}" ]]; then cmd="${4}"; fi

echo "" > "${SVN_STDERR_LOG}"
if [[ ! -x $(which tee) ]]; then
	eval "svn ${cmd}" 2> "${SVN_STDERR_LOG}"
else
	eval "svn ${cmd}" 2>&1  | tee -a "${SVN_STDERR_LOG}"
fi

local errors=(
	"svn: E"
	"Unable to connect"
	"Unknown hostname"
	"timeout"
	"time out" 
)
local ErrCount=0

# try to resolve conflicts if any
if [[ -n "${2}" && "${3}" != once ]]; then
	if grep -q "Tree conflict can only be resolved to 'working' state" "${SVN_STDERR_LOG}" || \
		grep -q "Node remains in conflict" "${SVN_STDERR_LOG}"; then
		printWarning "Calling svn resolve..\n"
		svnWithErrorCheck "resolve ${2}" "${2}" once "${1}"
	fi
fi

for err in "${errors[@]}"
do
	if grep -q "${err}" "${SVN_STDERR_LOG}"; then ((ErrCount+=1)); break; fi
done
if [[ "${ErrCount}" -ge "1" ]];then
	echo
	printError "An error was encountered syncing the repository:\n"
	echo "------------------------------"
	echo "$( cat ${SVN_STDERR_LOG} )"
	echo
	echo "------------------------------"
	printError "Can be temporarily, retry later or seek for help.\n"
	exit 1
fi
}
# --------------------------------------
IsLinkOnline() {
if [[ $FAST_UPDATE != NO ]]; then return 1; fi
if [[ -z "${1}" ]]; then printError "IsLinkOnline() require a link as argument!"; exit 1; fi

((TIMES+=1))
printf "\e[1;35mchecking..\e[0m"
svn info "${1}" > /dev/null
if [[ $? -eq 0 ]]; then
	printf "\e[1;32mavailable, continuing..\e[0m\n"
	TIMES=0
	return 1 # Success!
else
	if [[ $TIMES -ge 5 ]]; then
		printError "\nError: unable to access ${1} after $TIMES attempts.";
		printError "\nBuild_Clover go to fail voluntarily to avoid problems,";
		printError "\ncheck your internet connection or retry later!\n\n";
		return 0
	else
		# retry..
		IsLinkOnline "${1}"
	fi
fi
}
# --------------------------------------
IsPathWritable() {
local result=1
# file/folder exists?
if [[ ! -e "${1}" ]]; then printWarning "${1} does not exist!\n"; return $result; fi
if [[ -w "${1}" ]]; then
	printMessage "${1} is writable!\n"
	result=0
else
	printWarning "${1} is not writable!\n"
fi
return $result
}
# --------------------------------------
downloadThirdParty() {
if [[ "${Build_Tool}" != "XCODE" ]]; then
	return # cannot be compiled with GNU gcc atm
fi
printHeader 'Downloading the third party EFI drivers and their dependencies'

for link in "${ThirdPartyList[@]}"
do
	local x=$(basename $link)
	local c="${x%.git}"
	local pkg="${c##*/}"
	printf "\n\e[1;34m${pkg}:\e[0m\n"
	TIMES=0
	IsLinkOnline $link
	if [[ -d "${DIR_MAIN}/edk2/${pkg}" ]] ; then
		cd "${DIR_MAIN}/edk2/${pkg}"
		if [[ -d "${DIR_MAIN}/edk2/${pkg}/.svn" ]] ; then
			local localRev=$(svn info "${DIR_MAIN}/edk2/${pkg}" | grep '^Revision:' | tr -cd [:digit:])
			local remoteRev=$(svn info ${link} | grep '^Revision:' | tr -cd [:digit:])
			if [[ "$localRev" != "$remoteRev" ]]; then
				svnWithErrorCheck "update --accept $SVN_UPDATE_ACCEPT_ARG --non-interactive --trust-server-cert" "$(pwd)"
			else
				echo "r${localRev} is already the latest version."
			fi
		else
			printWarning ".svn missing, the ${pkg} repo may be corrupted, re-downloading...\n"
			rm -rf ./* > /dev/null 2>&1
			svnWithErrorCheck "co --non-interactive --trust-server-cert ${link}/trunk ."
		fi
	else
		mkdir "${DIR_MAIN}/edk2/${pkg}"
		cd "${DIR_MAIN}/edk2/${pkg}"
		svnWithErrorCheck "co --non-interactive --trust-server-cert ${link}/trunk ."
	fi
done
ClearScreen
}

buildThirdPartyEFI() {
if [[ "${Build_Tool}" != "XCODE" ]]; then
	return  # cannot be compiled with GNU gcc atm
fi
cd "${DIR_MAIN}"/edk2
source edksetup.sh BaseTools
# Create edk tools if necessary
if [[ ! -x "${DIR_MAIN}/edk2/BaseTools/Source/C/bin/GenFv" ]]; then
	make -C "${DIR_MAIN}"/edk2/BaseTools CC="gcc -Wno-deprecated-declarations"
fi

local ncpu=2
if [[ "$SYSNAME" == Linux ]]; then
	ncpu=$(( $(nproc) + 1 ))
else
	ncpu=$(( $(sysctl -n hw.logicalcpu) + 1 ))
fi
for driver in "AptioFixPkg" "AppleSupportPkg"; do
	build -a X64 -b RELEASE -t $BUILDTOOL -n $ncpu -p "${DIR_MAIN}"/edk2/"${driver}"/"${driver}".dsc
done
cd "${DIR_MAIN}"/edk2/Clover
}
# --------------------------------------
edk2() {
local revision="-r $EDK2_REV"
local updatelink="https://sourceforge.net/p/cloverefiboot/code/HEAD/tree/update.sh?format=raw"
local edk2ArrayOnline=(
	$( downloader "$updatelink" | grep 'cd ..' | sed -e 's/^cd ..\///' | sed -e 's/\/$//' | sed -e '/Clover/d' \
	| sed -e 's:BaseTools/Conf:BaseTools:g' )
)
# use only if populated, otherwise use the static "edk2array"
if [[ "${#edk2ArrayOnline[@]}" -ge "1" ]]; then unset -v edk2array; edk2array=( "${edk2ArrayOnline[@]}" ); fi

if [[ "$ForceEDK2Update" -ne "1979" ]]; then
	if [[ ! -d "${DIR_MAIN}/edk2/.svn" ]]; then ForceEDK2Update=1; fi
	for d in "${edk2array[@]}"
	do
		if [[ "$d" != Source && "$d" != Scripts ]]; then
			if [[ ! -d "${DIR_MAIN}/edk2/${d}/.svn" ]]; then ForceEDK2Update=1; fi
		fi
	done
fi

if [[ "$ForceEDK2Update" -eq "0" ]]; then
	if [[ "${LOCAL_EDK2_REV}" == "${EDK2_REV}" ]]; then
		printWarning "edk2 appear to be up to date, skipping ...\n"
	else
		printWarning "edk2 is not up to date, but no forced edk2 update is selected, skipping ...\n"
	fi
else
	echo
	if [[ ! -d "${DIR_MAIN}/edk2" ]]; then
		printHeader 'Downloading edk2'
		mkdir -p "${DIR_MAIN}"/edk2
	else
		if [[ "$ForceEDK2Update" -eq "1979" ]]; then
			printHeader 'Updating edk2 (forced)'
		else
			printHeader 'Updating edk2'
		fi
	fi
	TIMES=0
	cd "${DIR_MAIN}"/edk2
	IsLinkOnline $EDK2_REP
	# I want ".svn", also empty at the specified revision! .. so I can update!
	svnWithErrorCheck "--depth empty co $revision --non-interactive --trust-server-cert $EDK2_REP ."
	printf "\n\e[1;34medksetup.sh:\e[0m\n"
	IsLinkOnline $EDK2_REP/edksetup.sh
	svnWithErrorCheck "update --accept $SVN_UPDATE_ACCEPT_ARG --non-interactive --trust-server-cert $revision edksetup.sh" "$(pwd)"
	for d in "${edk2array[@]}"
	do
		if [[ "$d" != "Source" && "$d" != "Scripts" ]]; then
			printf "\n\e[1;34m${d}:\e[0m\n"
			TIMES=0
			IsLinkOnline "$EDK2_REP/${d}"
			cd "${DIR_MAIN}"/edk2
			if [[ -d "${DIR_MAIN}/edk2/${d}" ]] ; then
				if [[ -d "${DIR_MAIN}/edk2/${d}/.svn" ]] ; then
					cd "${DIR_MAIN}/edk2/${d}"
					svnWithErrorCheck "update --ignore-externals --accept $SVN_UPDATE_ACCEPT_ARG --non-interactive --trust-server-cert $revision" "$(pwd)"
					if [[ "$d" == "BaseTools" ]]; then ForceEDK2Update=1979; fi
				else
					printWarning ".svn missing, the ${d} repo may be corrupted, re-downloading...\n"
					cd "${DIR_MAIN}/edk2/${d}"
					rm -rf ./* > /dev/null 2>&1
					svnWithErrorCheck "co $revision --ignore-externals --non-interactive --trust-server-cert $EDK2_REP/${d} ."
				fi
			else
				cd "${DIR_MAIN}"/edk2
				svnWithErrorCheck "co $revision --ignore-externals --non-interactive --trust-server-cert $EDK2_REP/${d}"
			fi
		fi
	done
	if [[ "$ForceEDK2Update" -eq "1979" ]]; then
		printHeader "cleaning BaseTools and Clover / Clover Package"
		echo
		if [[ -d "${DIR_MAIN}/edk2/Clover" ]]; then cd "${DIR_MAIN}/edk2/Clover"; ./ebuild.sh cleanall -t $BUILDTOOL; fi
		if [[ -d "${DIR_MAIN}/edk2/Clover/CloverPackage" ]]; then cd "${DIR_MAIN}/edk2/Clover/CloverPackage"; make clean; fi
		for tpdrv in "AptioFixPkg" "AppleSupportPkg"; do
			if [[ -d "${DIR_MAIN}/edk2/Build/${tpdrv}" ]]; then rm -rf "${DIR_MAIN}/edk2/Build/${tpdrv}"; fi
		done
		FORCEREBUILD="-fr"
	fi
	ForceEDK2Update=0
fi
}
# --------------------------------------
clover() {
local cmd=""
# check if SUGGESTED_CLOVER_REV is set
if [[ -z "$SUGGESTED_CLOVER_REV" ]]; then
	echo
	if [[ ! -d "${DIR_MAIN}/edk2/Clover" ]]; then
		printHeader 'Downloading Clover, using the latest revision'
		if IsNumericOnly "${REMOTE_REV}"; then
			mkdir -p "${DIR_MAIN}"/edk2/Clover
			cmd="co -r $REMOTE_REV --non-interactive --trust-server-cert ${CLOVER_REP} ."
		else
			printError "Unable to get latest Clover revision, check your internet connection or try later.\n"
			exit 1
		fi
	else
		if [[ "${LOCAL_REV}" == "" ]]; then
			printHeader 'Clover local repo not found or damaged, downloading the latest revision'
			rm -rf "${DIR_MAIN}"/edk2/Clover/* > /dev/null 2>&1
			cmd="co -r $REMOTE_REV --non-interactive --trust-server-cert ${CLOVER_REP} ."
		else
			printHeader 'Updating Clover, using the latest revision'
			cmd="up --accept $SVN_UPDATE_ACCEPT_ARG --non-interactive --trust-server-cert"
		fi
	fi
else
	if [[ ! -d "${DIR_MAIN}/edk2/Clover" ]] ; then
		printHeader "Downloading Clover, using the specific revision r${SUGGESTED_CLOVER_REV}"
		mkdir -p "${DIR_MAIN}"/edk2/Clover
		cmd="co -r $SUGGESTED_CLOVER_REV --non-interactive --trust-server-cert ${CLOVER_REP} ."
	else
		if [[ "${LOCAL_REV}" == "" ]]; then
			printHeader "Clover local repo not found or damaged, downloading the specific revision r${SUGGESTED_CLOVER_REV}"
			rm -rf "${DIR_MAIN}"/edk2/Clover/* > /dev/null 2>&1
			cmd="co -r $SUGGESTED_CLOVER_REV --non-interactive --trust-server-cert ${CLOVER_REP} ."
		else 
			printHeader "Updating Clover, using the specific revision r${SUGGESTED_CLOVER_REV}"
			cmd="up --accept $SVN_UPDATE_ACCEPT_ARG --non-interactive --trust-server-cert -r $SUGGESTED_CLOVER_REV"
		fi
	fi
fi
TIMES=0
IsLinkOnline ${CLOVER_REP}
cd "${DIR_MAIN}"/edk2/Clover
svnWithErrorCheck "$cmd" "$(pwd)"
printHeader 'Apply Edk2 patches'
cp -R "${DIR_MAIN}"/edk2/Clover/Patches_for_EDK2/* "${DIR_MAIN}"/edk2/

# in Lion cp cause error with subversion (comment this line and enable next)
# rsync -rv --exclude=.svn "${DIR_MAIN}"/edk2/Clover/Patches_for_EDK2/ "${DIR_MAIN}"/edk2
}
# --------------------------------------
needGETTEXT() {
local gettextPath=""
local gettextArray=( $(which -a gettext) )
local needInstall=1
if [[ ${#gettextArray[@]} -ge "1" ]]; then
	for i in "${gettextArray[@]}"
	do
		echo "found gettext at $(dirname ${i})"
	done
else
	needInstall=0
	echo "gettext not found.."
fi
return $needInstall
}
# --------------------------------------
isNASMGood() {
# nasm should be greater or equal to 2.12.02 to be good building Clover.
# There was a bad macho relocation in outmacho.c, fixed by Zenith432
# and accepted by nasm devel during 2.12.rcxx (release candidate)
result=1
local nasmver=$( "${1}" -v | grep 'NASM version' | awk '{print $3}' )
case "$nasmver" in
	2.12.0[2-9]* | 2.12.[1-9]* | 2.1[3-9]* | 2.[2-9]* | [3-9]* | [1-9][1-9]* ) result=0;;
	* ) printWarning "Unknown or unsupported NASM version found at:\n${1}\nDownloading the preferred one (${NASM_PREFERRED})...\n\n";;
esac
return $result
}
# --------------------------------------
ebuildBorg() {
if [[ "$MOD_PKG_FLAG" != YES ]]; then return; fi
local NR=0
if [[ "$SYSNAME" == Darwin ]]; then printHeader 'Modding package resources'; fi
	
case "$ARCH" in
IA32_X64 | X64 )
	local oldTitle='cloverEFI.64.blockio_title'
	local oldDesc='cloverEFI.64.blockio_description'
	local newTitle='"cloverEFI.64.blockio_title" = "Custom CloverEFI 64-bits (boot7)";'
	local newDesc=$(echo "\"cloverEFI.64.blockio_description\" = \"Built using Build_Clover.command with: ${DEFINED_MACRO}\";")
	if grep -q "cloverEFIFile=boot\$((6 + USE_BIOS_BLOCKIO))" "${ebuild}"; then
		cat "${ebuild}" \
			| sed -e 's/cloverEFIFile=boot\$((6 + USE_BIOS_BLOCKIO))/cloverEFIFile=boot7/g' > "${ebuildB}"
		chmod +x "${ebuildB}"
	else
		printError "Error: ebuild.sh changed, this script need to be updated!\n"
		exit 1
	fi;;
IA32 )
	local oldTitle='cloverEFI.32_title'
	local oldDesc='cloverEFI.32_description'
	local newTitle='"cloverEFI.32_title" = "Custom CloverEFI 32-bits (boot3)";'
	local newDesc=$(echo "\"cloverEFI.32_description\" = \"Built using Build_Clover.command with: ${DEFINED_MACRO}\";");;
esac

if [[ "$SYSNAME" != Darwin ]]; then return; fi

# modding po files
cp -R "${LOCALIZABLE_FILE}" /tmp/
set +e # handle the error by ourself
err=0

if [[ -f /tmp/Localizable.strings ]]; then
	NR=$(grep -n "${oldTitle}" /tmp/Localizable.strings | grep -Eo '^[^:]+')
	sed -i "" "${NR}s/.*/${newTitle}/" /tmp/Localizable.strings
	# waiting file reappear
	until [ -f /tmp/Localizable.strings ]; do sleep 0.3; done
	NR=$(grep -n "${oldDesc}" /tmp/Localizable.strings | grep -Eo '^[^:]+')
	sed -i "" "${NR}s/.*/${newDesc}/" /tmp/Localizable.strings
	# waiting file reappear
	until [ -f /tmp/Localizable.strings ]; do sleep 0.3; done
	if (! grep -q "${newTitle}" /tmp/Localizable.strings); then
		printError "Error: in /tmp/Localizable.strings, no changes applied..\n"
		((err+=1))
	fi
	if (! grep -qe "${DEFINED_MACRO}" /tmp/Localizable.strings); then
		printError "Error: in /tmp/Localizable.strings, no changes applied..\n"
		((err+=1))
	fi
else
	printError "Error: Localizable.strings not found\n"
	((err+=1))
fi
if [[ "$err" -eq 0 ]]; then
	mv -f "${LOCALIZABLE_FILE}" "${LOCALIZABLE_FILE}.back"
	mv /tmp/Localizable.strings "${LOCALIZABLE_FILE}"
	cp -R "${PKG_PATH}/po" "${PKG_PATH}/po_back"
	echo "success!"
	echo $ThickLine
fi
set -e
}
# --------------------------------------
restoreClover() {
if [[ -f "${LOCALIZABLE_FILE}.back" ]]; then
	mv -f "${LOCALIZABLE_FILE}.back" "${LOCALIZABLE_FILE}"
fi
if [[ -f "${CLOVERV2_PATH}/Bootloaders/x64/boot7-MCP79.back" ]]; then
	mv -f "${CLOVERV2_PATH}/Bootloaders/x64/boot7-MCP79.back" "${CLOVERV2_PATH}/Bootloaders/x64/boot7-MCP79"
fi
if [[ -d "${PKG_PATH}/po_back" ]]; then
	cp -R "${PKG_PATH}/po_back" "${PKG_PATH}/po"
	rm -rf "${PKG_PATH}/po_back"
fi
if [[ -f "${ebuildB}" ]]; then
	rm -f "${ebuildB}"
fi
}
# --------------------------------------
buildEssentials() {
echo
# ensure custom paths exists
mkdir -p "${TOOLCHAIN_DIR}"/bin
mkdir -p "${DIR_TOOLS}"
mkdir -p "${DIR_DOWNLOADS}"
mkdir -p "${DIR_LOGS}"

# no mach-o in linux,
printHeader "nasm check:"
if [[ ! -x "${NASM_PREFIX}"nasm ]] || ! isNASMGood "${NASM_PREFIX}"nasm; then
	FORCEREBUILD="-fr" # the path to nasm can now be different in generated make files: it is safe to autogen it again!
	printWarning "NASM not found or not the proper version, installing the preferred one..."
	if [[ -d "${DIR_DOWNLOADS}"/source.download ]]; then rm -rf "${DIR_DOWNLOADS}"/source.download/*; else mkdir -p "${DIR_DOWNLOADS}"/source.download; fi
	# NASM_PREFIX (the folder) can be writable or not, but also NASM_PREFIX can be writable and an old nasm inside it not writable because owned by root!
	cd "${DIR_DOWNLOADS}"/source.download

	case "$SYSNAME" in
		Linux )
			printMessage "\nDownloading the preferred version (${NASM_PREFERRED})..."
			downloader "http://www.nasm.us/pub/nasm/releasebuilds/${NASM_PREFERRED}/nasm-${NASM_PREFERRED}.tar.gz" "${DIR_DOWNLOADS}/source.download" "${NASM_PREFERRED}.tar.gz"
			tar -zxf "${NASM_PREFERRED}".tar.gz
			cd "${DIR_DOWNLOADS}/source.download/nasm-${NASM_PREFERRED}"
			printMessage "\n[ NASM ] configure..."
			./configure --prefix="${PREFIX}" 1> /dev/null 2> "${DIR_LOGS}"/nasm-"${NASM_PREFERRED}".config.log.txt
			printMessage "\n[ NASM ] make..."
			make CC=gcc 1> /dev/null 2> "${DIR_LOGS}"/nasm-"${NASM_PREFERRED}".make.log.txt
			printMessage "\n[ NASM ] make install..."
			if ! IsPathWritable "${NASM_PREFIX}"; then
				echo
				echo "installing nasm to ${NASM_PREFIX} require sudo because"
				echo "is not writable by $BUILDER:"
				sudo make install 1> /dev/null 2> "${DIR_LOGS}"/nasm-"${NASM_PREFERRED}".install.log.txt
				sudo -k
			else
				make install 1> /dev/null 2> "${DIR_LOGS}"/nasm-"${NASM_PREFERRED}".install.log.txt
			fi;;
		Darwin )
			printMessage "\nDownloading the preferred version for macOS (${NASM_PREFERRED})..."
			downloader "http://www.nasm.us/pub/nasm/releasebuilds/${NASM_PREFERRED}/macosx/nasm-${NASM_PREFERRED}-macosx.zip" "${DIR_DOWNLOADS}/source.download" "${NASM_PREFERRED}.zip"
			printMessage "\nInstalling..."
			unzip "${NASM_PREFERRED}".zip 1> /dev/null
			if ! IsPathWritable "${NASM_PREFIX}"; then
				echo
				echo "installing nasm to ${NASM_PREFIX} require sudo because"
				echo "is not writable by $BUILDER:"
				sudo cp -R "nasm-${NASM_PREFERRED}"/nasm "${NASM_PREFIX}" && sudo -k # exiting sudo immediately!
			else
				cp -R "nasm-${NASM_PREFERRED}"/nasm "${NASM_PREFIX}"
			fi;;
	esac

	# check the installation made:
	if [[ -x "${NASM_PREFIX}"nasm ]] && isNASMGood "${NASM_PREFIX}"nasm; then
		printMessage "\nDone\n"; echo
	else
		printMessage "\nNASM installation error, check the log!\n"; exit 1
	fi
else
	echo "$(${NASM_PREFIX}nasm -v)"
fi

# ...gettext and mtoc does nothing in Linux because we cannot compile the .pkg
if [[ "$SYSNAME" == Darwin ]]; then
	printHeader "gettext check:"
	if needGETTEXT && [[ ! -x "${TOOLCHAIN_DIR}"/bin/gettext ]]; then
		# buildgettext.sh is buggie:
		# suppose during the download a problem occour you can have an incomplete "gettext-latest.tar.gz" from a previous execution,
		# but buildgettext.sh think that is already downloaded and will try to decompress this incomplete archive, always failing!
		# That's why we remove the archive!
		if [[ -f "${DIR_DOWNLOADS}"/gettext-latest.tar.gz ]]; then rm -f "${DIR_DOWNLOADS}"/gettext-latest.tar.gz; fi
		doSomething --run-script "${DIR_MAIN}"/edk2/Clover/buildgettext.sh
	fi
	printHeader "mtoc check:"
	if [[ ! -x "${TOOLCHAIN_DIR}/bin/mtoc.NEW" ]]; then
		printWarning "mtoc not found, installing...\n"
		doSomething --run-script "${DIR_MAIN}"/edk2/Clover/buildmtoc.sh
		echo "mtoc successfully installed in ${TOOLCHAIN_DIR}/bin."
	else
		echo "mtoc found in ${TOOLCHAIN_DIR}/bin."
	fi
	export MTOC_PREFIX="${TOOLCHAIN_DIR}/bin/"
	printThickLine; echo
fi

rm -rf "${DIR_DOWNLOADS}"/source.download
}
# --------------------------------------
showMacros() {
ClearScreen
CUSTOM_BUILD="YES"
case "$ARCH" in
	IA32_X64 ) printHeader "BUILD boot3 and boot7 with additional macros";;
	X64 ) printHeader "BUILD boot7 with additional macros";;
	IA32 ) printHeader "BUILD boot3 with additional macros";;
esac
local count=1;

for macro in ${macros[@]}
do
	printf "\t $count) ${macro}\n"
	((count+=1))
done
echo $1
printf 'actual macros defined: '
if [[ ( "${#DEFINED_MACRO} " < 1 ) ]] ; then
	printf "\e[1;30mno one\e[0m\n"
else
	printf "\e[1;36m\n${DEFINED_MACRO}\e[0m\n"
fi
echo
if [[ "${#macros[@]}" -gt "0" ]]; then
	echo "enter you choice or press \"b\" to build:"
	printf '? ' && read choice
	if [[ "${choice}" == "b" || "${choice}" == "B" ]]; then
		echo "going to build as requested.."
	elif [[ ${choice} =~ ^[0-9]+$ ]]; then
		if [[ "$choice" -gt "0" && "$choice" -le ${#macros[@]} ]]; then
			local chosed="${macros[choice -1]}"
			DEFINED_MACRO=$(echo "$DEFINED_MACRO -D ${chosed}" | sed -e 's/^[ \t]*//')
			macros=(${macros[@]/${macros[choice -1]}/})
			showMacros "${chosed} added!"
		else
			showMacros "invalid choice!"
		fi
	else
		showMacros "invalid choice!"
	fi
fi
}
# --------------------------------------
backupBoot7MCP79() {
if [[ -f "${CLOVERV2_PATH}/Bootloaders/x64/boot7-MCP79" ]]; then
	mv -f "${CLOVERV2_PATH}/Bootloaders/x64/boot7-MCP79" "${CLOVERV2_PATH}/Bootloaders/x64/boot7-MCP79.back"
fi
}
# --------------------------------------
cbuild() {
if [[ -d "${DIR_MAIN}/edk2/Clover/.svn" && "$INTERACTIVE" != "NO" ]] ; then
	echo 'Please enter your choice: '
	local options=()

	if [[ ! -f "$SYMLINKPATH" ]]; then
		options+=("add \"buildclover\" symlink to $(dirname $SYMLINKPATH)") # add the option to link the script
	else
		# such file exists, but is it really symlink
		if [[ -L "$SYMLINKPATH" ]]; then
			[[ "$SYSNAME" == Linux ]] && symPath="$(readlink -f ${SYMLINKPATH})" || symPath="$(readlink ${SYMLINKPATH})"
			# is that symlink pointing to the currently running script
			[[ "$symPath" != "$SCRIPT_ABS_LOC" ]] && options+=("update \"buildclover\" symlink")
		else
			# not a symlink
			options+=("restore \"buildclover\" symlink")
		fi
	fi
	if [[ "$SELF_UPDATE_OPT" == YES ]]; then options+=("update Build_Clover.command"); fi

	if [[ "$PING_RESPONSE" == YES && "$BUILDER" != 'slice' ]]; then
		options+=("update Clover only (no building)")
		options+=("update Clover + force edk2 update (no building)")
	fi
	if [[ "$BUILDER" == 'slice' ]]; then
		printf "   \e[1;97;104m EDK2 revision used r$EDK2_REV latest avaiable is r$REMOTE_EDK2_REV \e[0m\n"
		set +e
		options+=("build with ./ebuild.sh -nb")
		options+=("build with ./ebuild.sh --module=rEFIt_UEFI/refit.inf")
		options+=("build binaries w/o -fr (boot6 and 7)")
		options+=("build binaries with -fr (boot6 and 7)")
		options+=("build boot6/7 with -fr --std-ebda")
		if [[ "$SYSNAME" == Darwin ]]; then
			options+=("build pkg")
			options+=("build iso")
			options+=("build pkg+iso")
			options+=("build all for Release")
		fi
		options+=("Back to Main Menu")
		options+=("Exit")
	else
		options+=("run my script on the source")
		options+=("build existing revision (no update, for testing only)")
		options+=("build existing revision for release (no update, standard build)")
		options+=("build existing revision with custom macros enabled")
		options+=("enter Developers mode (only for devs)")
		if [[ "$SHOWCCP_ADVERTISE" == YES && "$SYSNAME" == Darwin ]]; then
			if [[ ! -f "${HOME}"/Library/Preferences/com.m79softwares.Clover-Configurator-Pro.plist ]]; then
				options+=("Try Clover Configurator Pro.app")
			fi
		fi
		options+=("edit the configuration file")
		options+=("Exit")
	fi

	local count=1
	for opt in "${options[@]}"
	do
		case $opt in
			"update Build_Clover.command" \
			| "add \"buildclover\" symlink to $(dirname $SYMLINKPATH)" \
			| "restore \"buildclover\" symlink" \
			| "update \"buildclover\" symlink" ) printf "\e[1;31m ${count}) ${opt}\e[0m\n";;
			"build existing revision for release (no update, standard build)" \
			| "update Clover + force edk2 update (no building)" \
			| "build all for Release" \
			| "build binaries with FORCEREBUILD (boot3, 6 and 7 also)" ) printf "\e[1;36m ${count}) ${opt}\e[0m\n";;
			* ) printf " ${count}) ${opt}\n";;
		esac
		((count+=1))
	done

	local choice=""
	local lastIndex="${#options[@]}"
	((lastIndex-=1))
	printf '? ' && read opt

	if IsNumericOnly $opt; then
		((opt-=1))
		if [[ "$opt" -ge "0" && "$opt" -le "$lastIndex" ]]; then choice="$(echo ${options[$opt]})"; fi
	fi

	case $choice in
		"add \"buildclover\" symlink to $(dirname $SYMLINKPATH)" \
		| "restore \"buildclover\" symlink" \
		| "update \"buildclover\" symlink" ) addSymlink;;
		"update Build_Clover.command" ) selfUpdate; cbuild;;
		"enter Developers mode (only for devs)" )
			ClearScreen
			if [[ -d "${DIR_MAIN}/edk2/Clover" ]] ; then
				set +e
				BUILDER="slice"
			else
				BUILDER=$USER
				echo "yep... you are a Dev, but at least download Clover firstly :-)"
			fi
			cbuild;;
		"update Clover only (no building)" )
			UPDATE_FLAG="YES"
			BUILD_FLAG="NO"
			ForceEDK2Update=0;;
		"update Clover + force edk2 update (no building)" )
			UPDATE_FLAG="YES"
			BUILD_FLAG="NO"
			ForceEDK2Update=1979;; # 1979 has a special meaning ...i.e force clean BaseTools
		"build existing revision (no update, for testing only)" )
			FORCEREBUILD=""
			UPDATE_FLAG="NO"
			BUILD_FLAG="YES"
			selectArch;;
		"build with ./ebuild.sh -nb" )
			printHeader 'ebuild.sh -nb'
			cd "${DIR_MAIN}"/edk2/Clover
			START_BUILD=$(date)
			./ebuild.sh -nb;;
		"build with ./ebuild.sh --module=rEFIt_UEFI/refit.inf" )
			cd "${DIR_MAIN}"/edk2/Clover
			printHeader 'ebuild.sh --module=rEFIt_UEFI/refit.inf'
			START_BUILD=$(date)
			./ebuild.sh --module=rEFIt_UEFI/refit.inf
			echo && printf "build started at:\n${START_BUILD}\nfinished at\n$(date)\n\nDone!\n";;
		"build binaries w/o -fr (boot6 and 7)" )
			cd "${DIR_MAIN}"/edk2/Clover
			START_BUILD=$(date)
			printHeader 'boot6'
			./ebuild.sh -x64 -D NO_GRUB_DRIVERS_EMBEDDED -t $BUILDTOOL
			printHeader 'boot7'
			./ebuild.sh -mc --no-usb -D NO_GRUB_DRIVERS_EMBEDDED -t $BUILDTOOL
			echo && printf "build started at:\n${START_BUILD}\nfinished at\n$(date)\n\nDone!\n";;
		"build binaries with -fr (boot6 and 7)" )
			cd "${DIR_MAIN}"/edk2/Clover
			START_BUILD=$(date)
			printHeader 'boot6'
			./ebuild.sh -fr -x64 -D NO_GRUB_DRIVERS_EMBEDDED -t $BUILDTOOL
			printHeader 'boot7'
			./ebuild.sh -fr -mc --no-usb -D NO_GRUB_DRIVERS_EMBEDDED -t $BUILDTOOL
			echo && printf "build started at:\n${START_BUILD}\nfinished at\n$(date)\n\nDone!\n";;
		"build boot6/7 with -fr --std-ebda" )
			cd "${DIR_MAIN}"/edk2/Clover
			START_BUILD=$(date)
			printHeader 'boot6'
			./ebuild.sh -fr -x64 --std-ebda -D NO_GRUB_DRIVERS_EMBEDDED -t $BUILDTOOL
			printHeader 'boot7'
			./ebuild.sh -fr -mc --std-ebda --no-usb -D NO_GRUB_DRIVERS_EMBEDDED -t $BUILDTOOL
			echo && printf "build started at:\n${START_BUILD}\nfinished at\n$(date)\n\nDone!\n";;
		"build pkg" )
			cd "${DIR_MAIN}"/edk2/Clover/CloverPackage
			START_BUILD=$(date)
			printHeader 'make pkg'
			make pkg
			echo && printf "build started at:\n${START_BUILD}\nfinished at\n$(date)\n\nDone!\n";;
		"build iso" )
			cd "${DIR_MAIN}"/edk2/Clover/CloverPackage
			printHeader 'make iso'
			make iso
			echo && printf "build started at:\n${START_BUILD}\nfinished at\n$(date)\n\nDone!\n";;
		"build pkg+iso" )
			cd "${DIR_MAIN}"/edk2/Clover/CloverPackage
			START_BUILD=$(date)
			printHeader 'make pkg + make iso'
			make pkg
			make iso
			echo && printf "build started at:\n${START_BUILD}\nfinished at\n$(date)\n\nDone!\n";;
		"build all for Release" )
			cd "${DIR_MAIN}"/edk2/Clover
			START_BUILD=$(date)
			printHeader 'boot6'
			./ebuild.sh -fr -x64 -D NO_GRUB_DRIVERS_EMBEDDED -t $BUILDTOOL
			printHeader 'boot7'
			./ebuild.sh -fr -mc --no-usb -D NO_GRUB_DRIVERS_EMBEDDED -t $BUILDTOOL

			cd "${DIR_MAIN}"/edk2/Clover/CloverPackage
			make clean
			printHeader 'make pkg'
			make pkg
			printHeader 'make iso'
			make iso
			echo && printf "build started at:\n${START_BUILD}\nfinished at\n$(date)\n\nDone!\n";;
		"build existing revision for release (no update, standard build)" )
			FORCEREBUILD="-fr"
			UPDATE_FLAG="NO"
			BUILD_FLAG="YES"
			selectArch;;
		"build existing revision with custom macros enabled" )
			DEFINED_MACRO=""
			UPDATE_FLAG="NO"
			BUILD_FLAG="YES"
			selectArch
			showMacros "";;
		"run my script on the source" )
			eval "${MY_SCRIPT}" || printHeader "You should export MY_SCRIPT with the path to your script.." && CleanExit;;
		"Back to Main Menu" ) ClearScreen && BUILDER=$USER && cbuild;;
		"edit the configuration file" ) OsOpen "${userconf}"; CleanExit;;
		"Try Clover Configurator Pro.app" ) OsOpen "https://github.com/Micky1979/Clover-Configurator-Pro"; CleanExit;;
		"Exit" ) CleanExit;;
		* ) ClearScreen && echo "invalid option!!" && cbuild;;
	esac
else
	UPDATE_FLAG=YES
	if [[ "$INTERACTIVE" == "NO" ]]; then BUILD_FLAG=YES; else BUILD_FLAG=NO; fi
fi

if [[ "$BUILDER" == 'slice' && "$INTERACTIVE" != "NO" ]]; then ClearScreen && cbuild; fi

# show info about the running OS and its gcc
case "$SYSNAME" in
	Darwin ) printHeader "Running from: macOS $(sw_vers -productVersion)\n$(/usr/bin/xcodebuild -version)";;
	Linux ) if [[ -x "/usr/bin/lsb_release" ]]; then
				printHeader "Running from: $(lsb_release -sir | sed -e ':a;N;$!ba;s/\n/ /g')"
			else
				printHeader "Running from: Linux"
			fi;;
	* ) printHeader "Running from: Unknown OS";;
esac
	
printHeader "Compiler settings"
if [[ "${Build_Tool}" == "GNU" ]]; then
	if [[ -x "${DIR_MAIN}/opt/local/bin/gcc" ]]; then
		printf "\e[1;34m%s\e[0m" "$(${DIR_MAIN}/opt/local/bin/gcc -v 2>&1)"
	elif [[ -x "${DIR_MAIN}/opt/local/cross/bin/x86_64-clover-linux-gnu-gcc" ]]; then
		printf "\e[1;34m%s\e[0m" "$(${DIR_MAIN}/opt/local/cross/bin/x86_64-clover-linux-gnu-gcc -v 2>&1)"
	else
		printWarning "GNU toolchain not found or incomplete!!!"
	fi
else
	printf "\e[1;34m%s\e[0m" "$(gcc -v 2>&1)"
fi
printLine

if [[ "$BUILDER" != 'slice' ]]; then restoreClover; fi
if [[ "$UPDATE_FLAG" == YES && "$BUILDER" != 'slice' ]]; then
	getRev
	edk2
	clover
	downloadThirdParty
fi

if [[ "$INTERACTIVE" != "NO" ]]; then
	if [[ "$BUILD_FLAG" == "NO" ]]; then
		ClearScreen
		# print updated remote and local revision
		if [[ -d "${DIR_MAIN}"/edk2 ]]; then getRev; printRevisions; fi;
		cbuild
	fi
fi

set -e

case "$BUILDTOOL" in
GCC49 )
	printHeader "BUILDTOOL is $BUILDTOOL"
	if [[ "$SYSNAME" == Darwin ]]; then doSomething --run-script "${DIR_MAIN}"/edk2/Clover/buildgcc-4.9.sh; fi;;
GCC53 )
	printHeader "BUILDTOOL is $BUILDTOOL"
	if [[ "$SYSNAME" == Darwin ]]; then doSomething --run-script "${DIR_MAIN}"/edk2/Clover/build_gcc8.sh; fi;;
XCODE* ) exportXcodePaths; printHeader "BUILDTOOL is $BUILDTOOL";;
esac

if [[ "$BUILDER" != 'slice' ]]; then buildEssentials; cleanCloverV2; fi

cd "${DIR_MAIN}"/edk2/Clover

START_BUILD=$(date)

# Slice has removed that flag entirely until new development will comes,
# so the follow is just a momentarily patch for XCODE5
if [[ "$SYSNAME" == Darwin ]]; then LTO_FLAG=""; fi

set +e
buildThirdPartyEFI
if [[ "$CUSTOM_BUILD" == NO ]]; then
	# using standard options
	case "$ARCH" in
	IA32_X64 )
		printHeader 'boot6'
		doSomething --run-script ./ebuild.sh $FORCEREBUILD -x64 $DEFAULT_MACROS $LTO_FLAG -t $BUILDTOOL
		printHeader 'boot7'
		doSomething --run-script ./ebuild.sh $FORCEREBUILD -mc --no-usb $DEFAULT_MACROS $LTO_FLAG -t $BUILDTOOL
		printHeader 'boot3'
		doSomething --run-script ./ebuild.sh $FORCEREBUILD -ia32 $DEFAULT_MACROS $LTO_FLAG -t $BUILDTOOL;;
	X64 )
		printHeader 'boot6'
		backupBoot7MCP79
		doSomething --run-script ./ebuild.sh $FORCEREBUILD -x64 $DEFAULT_MACROS $LTO_FLAG -t $BUILDTOOL
		printHeader 'boot7'
		doSomething --run-script ./ebuild.sh $FORCEREBUILD -mc --no-usb $DEFAULT_MACROS $LTO_FLAG -t $BUILDTOOL;;
	IA32 )
		printHeader 'boot3'
		backupBoot7MCP79
		doSomething --run-script ./ebuild.sh $FORCEREBUILD -ia32 $DEFAULT_MACROS $LTO_FLAG -t $BUILDTOOL;;
	esac
else
	# using custom macros
	case "$ARCH" in
	IA32_X64 )
		printHeader 'boot6'
		doSomething --run-script ./ebuild.sh -x64 -fr $LTO_FLAG -t $BUILDTOOL # boot6 is always standard here
		printHeader 'Custom boot7'
		ebuildBorg
		doSomething --run-script ./ebuildBorg.sh -x64 -fr ${DEFINED_MACRO} $LTO_FLAG -t $BUILDTOOL
		printHeader 'boot3'
		doSomething --run-script ./ebuild.sh -ia32 -fr ${DEFINED_MACRO} $LTO_FLAG -t $BUILDTOOL;;
	X64 )
		printHeader 'Custom boot7' # boot7 is the only target here
		backupBoot7MCP79
		ebuildBorg
		doSomething --run-script ./ebuildBorg.sh -x64 -fr $LTO_FLAG ${DEFINED_MACRO} -t $BUILDTOOL;;
	IA32 )
		printHeader 'Custom boot3'
		backupBoot7MCP79
		ebuildBorg
		doSomething --run-script ./ebuild.sh -ia32 -fr ${DEFINED_MACRO} $LTO_FLAG -t $BUILDTOOL;;
	esac
fi

if [[ "$SYSNAME" == Darwin ]]; then
	if [[ "$BUILD_PKG" == YES || "$BUILD_ISO" == YES ]]; then
		cd "${DIR_MAIN}"/edk2/Clover/CloverPackage
		if [[ "$FORCEREBUILD" == "-fr" ]]; then make clean; fi
	fi
	if [[ "$BUILD_PKG" == YES ]]; then
		printHeader 'MAKE PKG'; CheckProprietary; eval "$MAKEPKG_CMD"
		if [[ $? -ne 0 ]]; then printError "\no_Ops, MAKE PKG exited with error(s), aborting..\n"; exit 1; fi
	fi
	if [[ "$BUILD_ISO" == YES ]]; then
		printHeader 'MAKE ISO'; make iso
		if [[ $? -ne 0 ]]; then printError "\no_Ops, MAKE ISO exited with error(s), aborting..\n"; exit 1; fi
	fi
else
	OsOpen "${CLOVERV2_PATH}"
fi

if [[ "$BUILDER" != 'slice' ]]; then restoreClover; fi
printHeader "build started at:\n${START_BUILD}\nfinished at\n$(date)\n\nDone!\n"
printf '\e[3;0;0t'
if [[ "$INTERACTIVE" != "NO" ]]; then
	pressAnyKey "Clover was built successfully!" noclear
	ClearScreen
	cbuild
else
	printf "\nClover was built successfully!\n\n"; exit 0
fi
}
main() {
# don't use sudo!
if [[ $EUID -eq 0 ]]; then printError "\nThis script should not be run using sudo!!\n\n"; exit 1; fi
# Cleaning up any old data if exists
if [[ -f /tmp/Build_Clover.tmp ]]; then rm -f /tmp/Build_Clover.tmp; fi

FindScriptPath

# Checking if any command line parameters has passed any value
if [[ "${cus_conf}" != "Y" ]]; then
	if [[ "${BUILD_CLOVER_CFG_PATH:-}" ]]; then
		userconf="${BUILD_CLOVER_CFG_PATH}"
	else
		userconf="$HOME/BuildCloverConfig.txt"
	fi
fi

EDK2_REV="${EDK2_REV:-27429}"

if [[ "${useDefaults}" == "Y" ]]; then
	LoadDefaults
elif [[ -f "$userconf" ]]; then
	ReadConf
else
	CreateDefaultConf
	ReadConf
fi

initialChecks
setPaths
setBuildTools

# tools_def.txt provide lto flags for GCC53 in linux
if [[ "$SYSNAME" == Linux ]]; then macros+=('DISABLE_LTO'); fi

# print local Script revision with relative info
printCloverScriptRev

# print script release info news
printScriptRevInfo

printHeader "By Micky1979 based on Slice, apianti, vit9696, Download Fritz, Zenith432,\nSTLVNUB, JrCs,cecekpawon, Needy, cvad, Rehabman, philip_petev, ErmaC\n\nSupported OSes: macOS X, Ubuntu (16.04/16.10), Debian Jessie and Stretch"

# print the remote and the local revision
if [[ -d "${DIR_MAIN}"/edk2 ]]; then getRev; printRevisions; fi;

# readding removed macro CHECK_FLAGS on old source
if [[ "$LOCAL_REV" -lt "4209" ]]; then macros+=("CHECK_FLAGS"); fi

if [[ "$DISABLE_CLEAR" != "YES" ]]; then printf '\e[8;34;90t'; fi
cbuild
}
# --------------------------------------
# MAIN CODE
# --------------------------------------
if [[ $# -eq 0 ]]; then main; fi
while [[ $# -gt 0 ]]; do
	case "${1}" in
		--defaults ) useDefaults="Y";;
		--edk2rev ) if [[ -n "${2}" && "${2}" =~ ^[0-9]+$ ]]; then
						EDK2_REV="${2}"
						cus_edk2="Y"
					fi
					shift;;
			--cfg ) if [[ -n "${2}" && -f "${2}" ]]; then
						userconf="${2}"
						cus_conf="Y"
					fi
					shift;;
		* ) printf "\e[1m%s\e[0m\n" "Invalid option: ${1} !" >&2; usage; exit 1;;
	esac
	shift
done
main
