#!/bin/bash
#set -x
printf '\e[8;34;90t'

# made by Micky1979 on 07/05/2016 based on Slice, Zenith432, STLVNUB, JrCs, cvad, Rehabman, and ErmaC works

# Tested in OSX using both GNU gcc and clang (Xcode 6.4, 7.2.1, 7.3.1 and Xcode 8).
# Preferred OS is El Capitan with Xcode >= 7.3.1 and Sierra with Xcode >= 8.
# In older version of OS X is better to use GNU gcc.

# Tested in linux Ubuntu (16.04 and 16.10) / Debian (8.4, 8.5, 8.6 and 8.7) amd64 (x86_64).
# This script install all missing dependencies in the iso images you
# can download at the official download page here: http://releases.ubuntu.com/16.04/ubuntu-16.04.1-desktop-amd64.iso
# where nasm, subversion, curl (wget if installed is used as replacement) and or uuid-dev headers are missing.
# gcc 5.4 coming with Ubuntu 16.04 is well compiled for Clover, so no need to make a "cross" compilation of it, and 
# I hope will be the same for future version installed here. Debian 8.6 instead use gcc 4.9.2 and is already good.
# Note that Debian comes without "sudo" installed (you well know this), but this script require dependecies
# described above so that you have install them by your self, or install sudo and enable it for your account.
#
# May you have apported radical and incompatible changes to your installation, but this is not my fault!
# New incoming release of Ubuntu/Debian should be compatible as well..

#
# Big thanks to the following testers:
# droples, Riley Freeman, pico joe, fantomas1, Fljagd, calibre, Mork vom Ork, Maniac10, Matgen84,
# Sherlocks, ellaosx, magnifico, AsusFreak, badruzeus, LabyOne, Ukr55, D-an-W, SavageAUS, bronxteck,
# artur_pt
# and all others (I'll be happy to increase this list and to not forgot anyone)
#

# --------------------------------------
# preferred build tool (gnu or darwin)
# --------------------------------------
XCODE="XCODE5"     # XCODE32
GNU="GCC53"        # GCC49 GCC53 (means GCC63)
BUILDTOOL="$GNU" # XCODE or GNU?      (use $GNU to use GNU gcc, $XCODE to use the choosen Xcode version)
# in Linux this get overrided and GCC63 used anyway!
# --------------------------------------
SCRIPTVER="v4.3.0"
export LC_ALL=C
SYSNAME="$( uname )"

BUILDER=$USER # don't touch!
# <----------------------------
# Preferences:
EDK2_REV="23974"   # or any revision supported by Slice (otherwise no claim please)

# "SUGGESTED_CLOVER_REV" is used to force the script to updated at the specified revision:
# REQUIRED is a known edk2 revision (EDK2_REV="XXXXX") compatible with the "/Clover/Patches_for_EDK2" coming with
# the specified Clover revision!
# WARNING: anyway too old revision may be incompatible due to radical changes to ebuild.sh and tools_def.txt
SUGGESTED_CLOVER_REV="" # empty by default

# normal behavior (src inside the Home folder)
# MODE="S" src is ~/src
# MODE="R" src created where this script is located (use only if the path has no blank spaces in the middle)
MODE="S"

DEFAULT_MACROS="-D NO_GRUB_DRIVERS_EMBEDDED -D CHECK_FLAGS"
PATCHES="$HOME/CloverPatches" # or where you like
BUILD_PKG="YES" # NO to not build the pkg
BUILD_ISO="NO"  # YES if you want the iso

# FAST_UPDATE is set to NO as default, that means that it check if repos are or not availabile online
# and fail the script accordigily
FAST_UPDATE="NO" # or FAST_UPDATE="YES" # no check, faster
# ---------------------------->
# default behavior (don't touch these vars)
NASM_PREFERRED="2.12.02"
FORCEREBUILD=""
UPDATE_FLAG="YES"
BUILD_FLAG="NO"
NEW_FLAG="YES"
LTO_FLAG=""        # default for Xcode >= 7.3, will automatically adjusted for older ones
MOD_PKG_FLAG="YES" # used only when you add custom macros. Does nothing for normal build.
ARCH="IA32_X64"    # will ask if you want IA32 (deprecated) or X64 only
DEFINED_MACRO=""
CUSTOM_BUILD="NO"
START_BUILD=""
TIMES=0
ForceEDK2Update=0 # cause edk2 to be re-updated again if > 0 (handeled by the script in more places)
SYMLINKPATH='/usr/local/bin/buildclover'

DOWNLOADER_CMD=""
DOWNLOADER_PATH=""
GITHUB='https://raw.githubusercontent.com/Micky1979/Build_Clover/master/Build_Clover.command'
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
            FatPkg
            BaseTools
            )
# <----------------------------
IsNumericOnly() {
    if [[ "${1}" =~ ^-?[0-9]+$ ]]; then
        return 0 # no, contains other or is empty
    else
        return 1 # yes is an integer (no matter for bash if there are zeroes at the beginning comparing it as integer)
    fi
}
# ---------------------------->
pressAnyKey(){
    if [[ "${2}" != noclear ]]; then
        clear
    fi
    printf "${1}\n"
    read -rsp $'Press any key to continue...\n' -n1 key
    clear
}

selfUpdate() {
    printHeader "SELF UPDATE"
    local SELF_PATH="${0}"
    local cmd=""
    local newScriptRev=""
    local currScriptRev=$(echo $SCRIPTVER | tr -cd [:digit:]) # in case of beta suffix
    local newScript=""

    case $1 in
    wget)
        cmd='${DOWNLOADER_PATH}/wget $GITHUB -q -O -'
    ;;
    curl)
        cmd='${DOWNLOADER_PATH}/curl -L $GITHUB'
    ;;
    *)
        printError "selfUpdate(): invalid cmd!\n"
        return
    ;;
    esac

    newScript=$(eval $cmd)

    # don't fail if no script is avail
    if [ -n "${newScript}" ]; then
        echo "${newScript}" > /tmp/Build_Clover.txt
        newScript=$(cat /tmp/Build_Clover.txt)
        newScriptRev=$(cat /tmp/Build_Clover.txt | grep 'SCRIPTVER=' | tr -cd [:digit:])

        if IsNumericOnly $currScriptRev && IsNumericOnly $newScriptRev; then
            if [ "$newScriptRev" -gt "$currScriptRev" ]; then
                # we have a new script, prompt the user
                printf "\na new Build_Clover.command is available,\n"
                echo "do you want to overwrite the script? (Y/n)\n"
                read answer

                case $answer in
                Y | y)
                    # get the line containing MODE variable and replace with what is currently in old script:
                    local lineVarNum=$(cat /tmp/Build_Clover.txt | grep -n '^MODE="' | awk -F ":" '{print $1}')

                    if [[ "$MODE" == "R" ]]; then
                        if IsNumericOnly $lineVarNum; then
                            if [[ "$SYSNAME" == Linux ]]; then
                                sed -i "${lineVarNum}s/.*/MODE=\"R\"/" /tmp/Build_Clover.txt
                            else
                                sed -i "" "${lineVarNum}s/.*/MODE=\"R\"/" /tmp/Build_Clover.txt
                            fi
                            cat /tmp/Build_Clover.txt > "${SELF_PATH}"
                            echo "done!"
                            rm -f /tmp/Build_Clover.txt
                            exec "${SELF_PATH}"
                        else
                            cat /tmp/Build_Clover.txt > "${SELF_PATH}"
                            echo "Warning: was not possible to ensure that MODE var was correctly set,"
                            echo "so apply your changes (if any) and re run the new script"
                            rm -f /tmp/Build_Clover.txt
                            exit 0
                        fi
                    else
                        cat /tmp/Build_Clover.txt > "${SELF_PATH}"
                        echo "done!"
                        rm -f /tmp/Build_Clover.txt
                        exec "${SELF_PATH}"
                    fi
                ;;
                esac
            else
                pressAnyKey 'your script is up to date,\n'
            fi
        fi
    else
        pressAnyKey 'was not possible to retrieve updates for Build_Clover.command,'
    fi
    rm -f /tmp/Build_Clover.txt
}
# <----------------------------
# default paths (don't touch these vars)
# first check for our path
if [[ "$MODE" == "S" ]]; then
    export DIR_MAIN=${DIR_MAIN:-"${HOME}"/src}
elif [[ "$MODE" == "R" ]]; then
    # Rehabman wants the script path as the place for the edk2 source!
    # check if $0 is a symlink
    if [[ -L "${0}" ]]; then
        if [[ "$SYSNAME" == Linux ]]; then
            cd "$(dirname $(readlink -f ${0}))"
        else
            cd "$(dirname $(readlink ${0}))"
        fi
    else
        cd "$(dirname ${0})"
    fi
    export DIR_MAIN="$(pwd)"/src

    if [[ "${DIR_MAIN}" = "${DIR_MAIN%[[:space:]]*}" ]]; then
        echo "good, no blank spaces in DIR_MAIN, continuing.."
    else
        clear
        printError "Error: MODE=\"R\" require a path with no spaces in the middle, exiting!\n"
        exit 1
    fi
else
    clear
    printError "Error: unsupported MODE\n"
    exit 1
fi

SVN_STDERR_LOG="${DIR_MAIN}/svnLog.txt"
CLOVERV2_PATH="${DIR_MAIN}/edk2/Clover/CloverPackage/CloverV2"
PKG_PATH="${DIR_MAIN}/edk2/Clover/CloverPackage/package"
LOCALIZABLE_FILE="${PKG_PATH}/Resources/templates/Localizable.strings"
ebuildB="${DIR_MAIN}/edk2/Clover/ebuildBorg.sh"
ebuild="${DIR_MAIN}/edk2/Clover/ebuild.sh"
CLOVER_REP="svn://svn.code.sf.net/p/cloverefiboot/code"
EDK2_REP="svn://svn.code.sf.net/p/edk2/code/trunk/edk2"
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
        CHECK_FLAGS
        )

# tools_def.txt provide lto flags for GCC63 in linux
if [[ "$SYSNAME" == Linux ]]; then
    macros+=('DISABLE_LTO')
fi
# <----------------------------
# Separators lines
ThickLine='==============================================================================='
Line='                          <----------------------------------------------------'
# --------------------------------------
# functions
# --------------------------------------
# usefull before/after creating an array
# with custom separator
restoreIFS() {
    IFS=$' \t\n';
}
# --------------------------------------
printHeader() {
    echo "${ThickLine}"
    printf "\033[1;34m${1}\033[0m\n"
    echo "${Line}"
}
# --------------------------------------
printError() {
    printf "\033[1;31m${1}\033[0m"
#    exit 1
}
# --------------------------------------
printWarning() {
    printf "\033[1;33m${1}\033[0m"
}
# --------------------------------------
# don't use sudo!
if [[ $EUID -eq 0 ]]; then
    echo
    printError "\nThis script should not be run using sudo!!\n"
    exit 1
fi
# --------------------------------------
addSymlink() {
    local cmd="sudo ln -nfs"
    clear
    if [[ ! -d "$(dirname $SYMLINKPATH)" ]]; then
        printError "$(dirname $SYMLINKPATH) does not exist, cannot add a symlink..\n"
        pressAnyKey '\n'
        build
    fi

    if [[ -L "${0}" ]]; then
        if [[ "$SYSNAME" == Linux ]]; then
            cmd="$cmd $(readlink -f ${0}) $SYMLINKPATH"
        else
            cmd="$cmd $(readlink ${0}) $SYMLINKPATH"
        fi
    else
        cmd="$cmd ${0} $SYMLINKPATH"
    fi

    if [[ "$USER" != root ]]; then echo "type your password to add the symlink:"; fi
    eval "${cmd}"
    if [[ $? -ne 0 ]] ; then
        printError "\no_Ops, something wrong, cannot add the symlink..\n"
        pressAnyKey '\n'
        sudo -k && build
    else
        echo "now is possible to open the Terminal and type \"buildclover\""
        echo "to simply run Build_Clover.command.."
        pressAnyKey '..the script will be closed to allow you to do that!\n'
        sudo -k && exit 0
    fi
}
# --------------------------------------
initialChecks() {
    if [[ "$SYSNAME" == Linux ]]; then
        if [[ "$(uname -m)" != x86_64 ]]; then
            printError "\nBuild_Clover.command is tested only on x86_64 architecture, aborting..\n"
            exit 1
        fi

        # check if the Universally Unique ID library - headers are installed
        if [[ "$(apt-cache policy uuid-dev | grep 'Installed: (none)')" =~ 'Installed: (none)' ]]; then
            aptInstall uuid-dev
        fi
        # check if subversion is installed
        if [[ ! -x $(which svn) ]]; then
            aptInstall subversion
        fi

        # check whether at least one of curl or wget are installed
        if [[ ! -x $(which wget) ]] && [[ ! -x $(which curl) ]]; then
            # ok both of them are no currently installed, we prefear wget
            aptInstall wget
        fi

        # set the donloader command path
        if [[ -x $(which wget) ]]; then
            DOWNLOADER_PATH=$(dirname $(which wget))
            DOWNLOADER_CMD="wget"
        elif [[ -x $(which curl) ]]; then
            DOWNLOADER_PATH=$(dirname $(which curl))
            DOWNLOADER_CMD="curl"
        else
            DOWNLOADER_CMD=$(which curl)
            printError "\nNo curl nor wget are installed! Install one of them and retry..\n" && exit 1
        fi
    else
        # /usr/bin/curl!! (philip_petev)
        DOWNLOADER_PATH=/usr/bin
        DOWNLOADER_CMD="curl"
    fi
}
# --------------------------------------
printCloverScriptRev() {
    initialChecks
    local LVALUE
    local RVALUE
    local SVERSION
    local RSCRIPTVER

    if ping -c 1 github.com >> /dev/null 2>&1; then
        # Retrive and filter remote script version
        if [[ "$DOWNLOADER_CMD" == wget ]]; then
            RSCRIPTVER='v'$("${DOWNLOADER_PATH}/${DOWNLOADER_CMD}" $GITHUB -q -O - | grep '^SCRIPTVER="v' | tr -cd '.0-9')
        elif [[ "$DOWNLOADER_CMD" == curl ]]; then
            RSCRIPTVER='v'$("${DOWNLOADER_PATH}/${DOWNLOADER_CMD}" -v --silent $GITHUB 2>&1 | grep '^SCRIPTVER="v' | tr -cd '.0-9')
        else
            return
        fi

        LVALUE=$(echo $SCRIPTVER | tr -cd [:digit:])
        RVALUE=$(echo $RSCRIPTVER | tr -cd [:digit:])

        if IsNumericOnly $RVALUE; then
            # Compare local and remote script version
            if [ $LVALUE -eq $RVALUE ]; then
                SELF_UPDATE_OPT="NO"
                SVERSION="\033[1;32m${2}${SCRIPTVER}\033[0m\040 is the latest version avaiable"
            elif [ $LVALUE -gt $RVALUE ]; then
                SELF_UPDATE_OPT="NO"
                SVERSION="${SCRIPTVER} (wow, you coming from the future?)"
            else
                SELF_UPDATE_OPT="YES"
                SVERSION="${SCRIPTVER} a new version $RSCRIPTVER is available for download"
            fi
        else
            printError "Build_Clover script ${SCRIPTVER}\n(remote version unavailable due to unknown reasons)\n"
        fi
    else
        printError "Build_Clover script ${SCRIPTVER}\n(remote version unavailable because\ngithub is unreachable, check your internet connection)\n"
    fi
    printHeader "Build_Clover script $SVERSION"
}
# --------------------------------------
printCloverRev() {
    # get the revisions
    getRev "remote_local"

    # Remote
    if [ -z "${REMOTE_REV}" ]; then
        PING_RESPONSE="NO"
        REMOTE_REV="Something went wrong while getting the remote revision, check your internet connection!"
        printError "$REMOTE_REV"
        printf "\n"
        # Local
        if [ -z "${LOCAL_REV}" ]; then
            LOCAL_REV="Something went wrong while getting the local revision!"
            printError "$LOCAL_REV"
        else
            LOCAL_REV="${LOCAL_REV}"
            printWarning "${2}${LOCAL_REV}"
        fi
    else
        PING_RESPONSE="YES"
        REMOTE_REV="${REMOTE_REV}"
        printf "\033[1;32m${1}${REMOTE_REV}\033[0m\040"
        # Local
        if [ -z "${LOCAL_REV}" ]; then
            LOCAL_REV="\nSomething went wrong while getting the local revision!"
            printError "$LOCAL_REV"
        else
            LOCAL_REV="${LOCAL_REV}"
            if [ "${LOCAL_REV}" == "${REMOTE_REV}" ]; then
                printf "\033[1;32m${2}${LOCAL_REV}\033[0m\040"
            else
                printWarning "${2}${LOCAL_REV}"
            fi
        fi
    fi

    printf "\n"
    echo "${Line}"
}
# --------------------------------------
downloader(){
    #$1 link
    #$2 file name
    #$3 path (where will be saved)
    local cmd=""
    local downloadlink=""
    local suggestedFilename=""
    local downloadLocation=""

    if [ -z "${1}" ]; then printError "\nError: downloader() require 3 argument!!\n" && exit 1; fi
    if [ -z "${2}" ]; then
        printError "\nError: downloader() require a suggested file name\n" && exit 1
    fi
    if [ -z "${3}" ] || [[ ! -d "${3}" ]]; then printError "\nError: downloader() require the download path!!\n" && exit 1; fi

    downloadlink="${1}"
    suggestedFilename="${2}"
    downloadLocation="${3}"

    if [[ "$DOWNLOADER_CMD" == wget ]]; then
        cmd="${DOWNLOADER_PATH}/${DOWNLOADER_CMD} -O ${downloadLocation}/${suggestedFilename} ${downloadlink}"
    elif [[ "$DOWNLOADER_CMD" == curl ]]; then
        cmd="${DOWNLOADER_PATH}/${DOWNLOADER_CMD} -o ${downloadLocation}/${suggestedFilename} -LOk ${downloadlink}"
    else
        printError "\nNo curl nor wget are installed! Install one of them and retry..\n" && exit 1
    fi

    # default behavior = replace existing download!
    if [[ -d "${downloadLocation}/${suggestedFilename}" ]]; then
        rm -rf "${downloadLocation}/${suggestedFilename}"
    fi

    eval "${cmd}"
}
# --------------------------------------
aptInstall() {
 
    if [[ -z "${1}" ]]; then 
        return
    fi
    printWarning "Build_Clover need this:\n"
    printError "${1}\n"
    printWarning "..to be installed, but was not found.\n"
    printWarning "would you allow to install it? (Y/N)\n"
	
    read answer

    case $answer in
    Y | y)
        if [[ "$USER" != root ]]; then echo "type your password to install:"; fi
        sudo apt-get update 	
        sudo apt-get install "${1}"
    ;;
    *)
        printError "Build_Clover cannot go ahead without it/them, process aborted!\n"
        exit 1
    ;;
    esac
    sudo -k
}
# --------------------------------------
clear
# print local Script revision with relative info
printCloverScriptRev
printHeader "By Micky1979 based on Slice, Zenith432, STLVNUB, JrCs, cecekpawon, Needy,\ncvad, Rehabman, philip_petev, ErmaC\n\nSupported OSes: macOS X, Ubuntu (16.04/16.10), Debian Jessie (8.4/8.5/8.6/8.7)"

if [[ "$GITHUB" == *"Test_Script_dont_use.command"* ]];then
    printError "This script is for testing only and may be outdated,\n"
    printError "use the regular one at:\n"
    printError "http://www.insanelymac.com/forum/files/download/589-build-clovercommand/\n"
fi
# ---------------------------->
# Upgrage SVN working copy
svnUpgrade () {
    # make sure that a svn working directory exists
    if [[ -d "${DIR_MAIN}/edk2/Clover/.svn" ]]; then
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
					Y | y)
						printWarning "Upgrading $(dirname $workingCopy).\n"
						svn upgrade "$(dirname $workingCopy)"
					;;
					*)
						printWarning "You may encounter errors!\n"
					;;
					esac
				fi
			done
		fi
	fi
}
# Remote and local revisions
getRev() {
    # for svn 1.9 and higher
    #REMOTE_REV=$(svn info --show-item "revision" ${CLOVER_REP})
    #LOCAL_REV=$(svn info --show-item "revision" ${DIR_MAIN}/edk2/Clover)

    # error proof
    if [ ! ${1} ]; then
        return 1;
    fi

    # convert to lowercase
    Arg=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    
    # upgrade the working copy to avoid errors
    svnUpgrade

    # universal
    if ping -c 1 svn.code.sf.net >> /dev/null 2>&1; then
        if [[ ${Arg} == *"remote"* ]]; then
            # Remote
            REMOTE_REV=$(svn info ${CLOVER_REP} | grep '^Revision:' | tr -cd [:digit:])
            REMOTE_EDK2_REV=$(svn info ${EDK2_REP} | grep '^Revision:' | tr -cd [:digit:])
        fi
    else
        REMOTE_REV=""
    fi

    if [[ ${Arg} == *"local"* ]]; then
        # Local
        if [[ -d "${DIR_MAIN}"/edk2/Clover/.svn ]]; then
            LOCAL_REV=$(svn info "${DIR_MAIN}"/edk2/Clover | grep '^Revision:' | tr -cd [:digit:])
        else
            LOCAL_REV="0"
        fi
    fi
    if [[ ${Arg} == *"basetools"* ]]; then
        if [[ -d "${DIR_MAIN}"/edk2/BaseTools/.svn ]]; then
            BaseToolsRev=$(svnversion -n "${DIR_MAIN}"/edk2/BaseTools | tr -d [:alpha:])
        elif [[ -d "${DIR_MAIN}"/edk2/BaseTools/.git ]]; then
            BaseToolsRev=$(git svn find-rev git-svn "${DIR_MAIN}"/edk2/BaseTools | tr -cd [:digit:])
        else
            BaseToolsRev="0"
        fi
    fi
}
# print the remote and the local revision
printCloverRev "Remote revision: " "Local revision: "
# ---------------------------->
# --------------------------------------
selectArch () {
    restoreIFS
    archs=(
            'Standard x64 only'
            'ia32 and x64 (ia32 is deprecated)'
            'ia32 only (deprecated)'
            'Back to Main Menu'
            'Exit'
          )

    clear
    printHeader "Select the desired architecture"

    if [ -n "$1" ]; then
        echo "$1" && echo
    fi
    local count=1
    for op in "${archs[@]}"
    do
        case "${op}" in
        'Standard x64 only')
            printf "\033[1;36m\t ${count}) ${op}\033[0m\n"
        ;;
        *)
            printf "\t $count) ${op}\n"
        ;;
        esac

        ((count+=1))
    done

    printf '? ' && read opt

    case $opt in
    1)
        ARCH="X64"
    ;;
    2)
        ARCH="IA32_X64"
    ;;
    3)
        ARCH="IA32"
    ;;
    4)
        clear && BUILDER=$USER && build
    ;;
    5)
        exit 0;
    ;;
    *)
        selectArch "invalid choice!"
    ;;
    esac
}
# --------------------------------------
cleanCloverV2 () {
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
showInfo () {
    clear
    printHeader "INFO"

    printf "This script was originally created to be run in newer OSes like El Capitan\n"
    printf "using Xcode 7.3 +, but should works fine using gcc 4,9 (GCC49)\n"
    printf "in older ones. Also gcc 5,3 can be used but not actually advised.\n"
    echo
    printf "Don't be surprised if this does not work in Snow Leopard (because can't).\n"
    printf "In Lion can require you to uncomment/comment some line in clover() function.\n"
    echo
    printf "Using old Xcode like v7.2 and older, this script automatically disable\n"
    printf "LTO as suggested by devs. The result will be binaries increased in size.\n"
    printf "Off course that is automatic only for standard compilations, but consider to\n"
    printf "switch back to gcc 4,9 (GCC49).\n"
    printf "UPDATE: actually using XCODE5 LTO is disabled anyway due to problems coming with\n"
    printf "Xcode 8 and new version of clang.\n"
    echo
    printf "Since v3.5 Build_Clover.command is able to build Clover in Ubuntu 16.04 +\n"
    printf "using the built-in gcc and installing some dependecies like nasm, subversion,\n"
    printf "curl (wget is good if found), the uuid-dev headers if not installed.\n"
    printf "Off course using only the amd64 release (x86_64).\n"
    printf "May work on new releases of Ubuntu as well, but not on older ones.\n"
    echo
    printf "UPDATE: since v4.0.9 this script is tested in Debian Jessie 8.6 using gcc 4.9.2,\n"
    printf "but be aware that usually Debian comes without sudo installed:\n"
    printf "in this case you have to manage to install it manually and enable\n"
    printf "your account as sudo user (or just install all dependencies manually).\n"
    echo
    printf "This script conform to Slice's will as the main Clover's developer:\n"
    printf "edk2 is actually set to r${EDK2_REV} and nasm should not be older\n"
    printf "than r${NASM_PREFERRED}.\n"
    printf "Check for update about Build_Clover.command because edk2 can be updated soon\n"
    printf "by Slice, or check for the logs on sourceforge and simply change the\n"
    printf "\"EDK2_REV\" variable inside the scrip by editing it to the advised one.\n"
    printf "Using the same revision that Slice use to build Clover ensure that we\n"
    printf "conform to Him, with same identical conditions. If you are using different\n"
    printf "edk2 revision you will be encounter problems of any kind and you should\n"
    printf "not complain for that!\n"
    echo
    printf "By default the script no longer build the iso image but if you need it,\n"
    printf "just edit BUILD_ISO=\"NO\" to BUILD_ISO=\"YES\" at the \"Preferences\"\n"
    printf "section. Or enter the Developers mode. *(macOS only)\n"
    echo
    printf "You can build both 32/64 bit, only 32bit or only 64 bit packages!\n"
    echo
    printf "Enabling macros to build Clover EFI apply only to boot3/boot7,\n"
    printf "ia32 build can fail defining additional macros. In this case don't panic:\n"
    printf "use only 64-bit target.. or rebuild it with supported functionalities!\n"
    echo
    printf "\"enter Developer mode\" is an option designated for developers:\n"
    printf "no update, no downloads, no installations of any kind, just some\n"
    printf "options you can use to build Clover while you are editing the source code!\n"
    printf "May you encounter some errors with this mode (bad nasm version?), so you need\n"
    printf "to adjust all dependencies (by your-self) before run this way.\n"
    printf "Not a developer? don't use \"Developer mode\"!!!!\n"
    echo
    printf "Anyway the pkg and the iso image are generated in (and for) macOS X only.\n"
    echo
    printf "Warning using the \"R\" mode of this script to create the src folder\n"
    printf "outside the Home folder:\n"
    printf "Blank spaces in the path are not allowed because it will auto-fail!\n"
    echo "${Line}"
    pressAnyKey '' noclear
    build
}
# --------------------------------------
# Function: to manage PATH
pathmunge () {
    if [[ ! $PATH =~ (^|:)$1(:|$) ]]; then
        if [[ "${2:-}" = "after" ]]; then
            export PATH=$PATH:$1
        else
            export PATH=$1:$PATH
        fi
    fi
}
# --------------------------------------
checkXcode () {
    if [[ ! -x /usr/bin/gcc ]]; then
        printError "Xcode clt not found, exiting!\n"
        exit 1
    fi

    if [[ ! -x /usr/bin/xcodebuild ]]; then
        printError "xcodebuild not found, exiting!\n"
        exit 1
    fi

    # disabling lto if Xcode is older than 7.3
    IFS='.'; local array=($( /usr/bin/xcodebuild -version | grep 'Xcode' | awk '{print $NF}' ))
    case "${#array[@]}" in
    "1")
        if [ "${array[0]}" -lt "8" ]; then
            NEW_FLAG="NO"
        else
            NEW_FLAG="YES"
        fi
    ;;
    "2" | "3")
        if [ "${array[0]}" -eq "7" ] && [ "${array[1]}" -ge "3" ]; then
            NEW_FLAG="YES"
        elif [ "${array[0]}" -ge "8" ]; then
            NEW_FLAG="YES"
        else
            NEW_FLAG="NO"
        fi
    ;;
    *)
        printError "Unknown Xcode version format, exiting!\n"
        exit 1
    ;;
    esac

    case "$BUILDTOOL" in
    XCODE5)
        if [[ "$NEW_FLAG" == NO ]]; then
            LTO_FLAG="--no-lto"
        fi
    ;;
    esac

    restoreIFS
}
# --------------------------------------
if [[ "$SYSNAME" == Darwin ]]; then
    checkXcode
else
    BUILDTOOL="GCC53" # ovverride, no chance to use Xcode in linux :-)
fi
# --------------------------------------
doSomething() {
# $1 = option
# $2 = cmd
# $3 = first argument
# $4 = second argument
# $5 = ... and so on
    restoreIFS
    local cmd=""

    case "$1" in
        --run-script)
            if [[ -x "${2}" ]]; then
                # rebuild the cmd + all args
                cmd=$(echo "$@" | sed -e 's:--run-script ::g' | sed -e 's/[[:space:]]*$//')
            else
                echo
                echo "doSomething: \"--run-script\" option require you to add a script somewhere.."
                echo
            fi
        ;;
        *)
            printError "doSomething: invalid \"--run-script\" long option not specified\n"
            exit 1
        ;;
    esac

    eval "${cmd}"

    if [[ $? -ne 0 ]] ; then
        printError "\no_Ops, $2 exited with error(s), aborting..\n"
        exit 1
    fi
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

	# $1 = svn command to be execute
	# $2 = containing folder of our /.svn we are attempting to work on
	# $3 = reserved argument ("once") indicating we are calling 'svn resolve'
	# $4 = reserved argument equal to initial $1 command string
		
    if [ -z "${1}" ]; then return; fi

	local cmd="${1}"
	if [ -n "${4}" ]; then
		cmd="${4}"
	fi
    
    echo "" > "${SVN_STDERR_LOG}"
    if [[ ! -x $(which tee) ]]; then
        eval "${cmd}" 2> "${SVN_STDERR_LOG}"
    else
        eval "${cmd}" 2>&1  | tee -a "${SVN_STDERR_LOG}"
    fi

    local errors=(  "svn: E"
                    "Unable to connect"
                    "Unknown hostname"
                    "timeout"
                    "time out" 
                 )

    local ErrCount=0
    
    # try to resolve conflicts if any
    if [[ -n "${2}" ]] && [[ "${3}" != once ]];then
    	if grep -q "Tree conflict can only be resolved to 'working' state" "${SVN_STDERR_LOG}" || \
                grep -q "Node remains in conflict" "${SVN_STDERR_LOG}"; then
    		printWarning "calling svn resolve..\n"
            svnWithErrorCheck "svn resolve ${2}" "${2}" once "${1}"
        fi
    fi
	
    for err in "${errors[@]}"
    do
        if grep -q "${err}" "${SVN_STDERR_LOG}"; then
            ((ErrCount+=1))
            break
        fi
    done

    if [ "${ErrCount}" -ge "1" ];then
        echo
        printError "an error was encountered syncing the repository:\n"
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
    if [[ $FAST_UPDATE != NO ]]; then
        return 1 # exit success anyway (script is faster)
    fi

    if [ -z "${1}" ]; then
        printError "IsLinkOnline() require a link as argument!"
        exit 1
    fi

    ((TIMES+=1))
    printf "\033[1;35mchecking..\033[0m"
    svn info "${1}" > /dev/null
    if [ $? -eq 0 ]; then
        printf "\033[1;32mavailable, continuing..\033[0m\n"
        TIMES=0
        return 1 # Success!
    else
        if [ $TIMES -ge 5 ]; then
            printError "\nError: unable to access ${$1} after $TIMES attempts:";
            printError "       Build_Clover go to fail voluntarily to avoid problems,";
            printError "       check your internet connection or retry later!";
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
    if [ ! -e "${1}" ]; then echo "${1} does not exist!" && return $result; fi

    if [[ -w "${1}" ]]; then
        echo "${1} is writable!"
        result=0
    else
        echo "${1} is not writable!"
    fi
    return $result
}
# --------------------------------------
# is compiled BaseTools not the same of edk2 after svn up?
# In that case will be cleaned and rebuilted by ebuild.sh
cleanAllTools() {
    local oldRev="${1}"
    #local rev="null"

    # Clean BaseToolsRev
    if [ ! -z "$BaseToolsRev" ]; then
        BaseToolsRev=""
    fi

    if [[ "$oldRev" == unknown ]]; then return; fi

    if [[ -d "${DIR_MAIN}/edk2/BaseTools" ]] ; then
        getRev "BaseTools"

        if IsNumericOnly $oldRev && IsNumericOnly $BaseToolsRev; then
            if [ $BaseToolsRev -ne $oldRev ]; then
                    printHeader "cleaning all because BaseTools mismatch r${EDK2_REV} just synced:"
                    make clean
                    cd "${DIR_MAIN}/edk2/Clover" && ./ebuild.sh clean
                    cd "${DIR_MAIN}/edk2/Clover/CloverPackage" && make clean
                    FORCEREBUILD="-fr"
            fi
        fi
    fi
    echo
    echo "BaseTools before update was: r${oldRev}"
    echo "now is: r${BaseToolsRev}"
}
# --------------------------------------
edk2() {
    echo
    #local BaseToolsRev="unknown"

    # Set BaseToolsRev to unknown
    if [ ! -z "$BaseToolsRev" ]; then
        BaseToolsRev="unknown"
    fi

    local revision="-r $EDK2_REV"

    if [[ ! -d "${DIR_MAIN}/edk2" ]]; then
        printHeader 'Downloading edk2'
        mkdir -p "${DIR_MAIN}"/edk2
    else
        printHeader 'Updating edk2'
        if [[ -d "${DIR_MAIN}/edk2/BaseTools" ]]; then
            getRev "BaseTools"
        fi
    fi

    if [ "$ForceEDK2Update" -eq "1979" ]; then
        # was invoke to force update edk2, so is safe to rebuild BaseTools
        # in case some conflicts are resolved
        BaseToolsRev=$ForceEDK2Update
    fi

    # update only relevant pkgs of edk2 needed by Clover
    # keep them from update.sh used by Slice..
    local cmd=""
    local updatelink="https://sourceforge.net/p/cloverefiboot/code/HEAD/tree/update.sh?format=raw"
    if [[ "$DOWNLOADER_CMD" == wget ]]; then
        cmd="${DOWNLOADER_PATH}/${DOWNLOADER_CMD} $updatelink -q -O -"
    elif [[ "$DOWNLOADER_CMD" == curl ]]; then
        cmd="${DOWNLOADER_PATH}/${DOWNLOADER_CMD} -L $updatelink"
    else
        printError "\nNo curl nor wget are installed! Install one of them and retry..\n" && exit 1
    fi

    local edk2ArrayOnline=(
                            $( eval "${cmd}" | grep 'cd ..' | sed -e 's/^cd ..\///' | sed -e 's/\/$//' | sed -e '/Clover/d' \
                                                                                    | sed -e 's:BaseTools/Conf:BaseTools:g' )
                           )

    # use only if populated, otherwise use the static "edk2array"
    if [ "${#edk2ArrayOnline[@]}" -ge "1" ]; then
        edk2array="${edk2ArrayOnline}"
    fi


    # check if we have all already there and updated at the specified revision..
    # 'Scripts' and 'Source' are not present in edk2. maybe are Slice's stuff
    for d in "${edk2array[@]}"
    do
        if [[ "$d" != Source ]] && [[ "$d" != Scripts ]]; then
            if [[ ! -d "${DIR_MAIN}/edk2/${d}/.svn" ]] || \
               [ "$(svn info "${DIR_MAIN}/edk2/${d}" | grep '^Revision:' | tr -cd [:digit:])" -ne "$EDK2_REV" ]; then
                ((ForceEDK2Update+=1))
            fi
        fi
    done

    # check also edk2/.svn
    if [[ ! -d "${DIR_MAIN}/edk2/.svn" ]] || \
       [ "$(svn info "${DIR_MAIN}/edk2" | grep '^Revision:' | tr -cd [:digit:])" -ne "$EDK2_REV" ]; then
        ((ForceEDK2Update+=1))
    fi

    if [ "$ForceEDK2Update" -eq "0" ];then
        printWarning "edk2 appear to be up to date, skipping ...\n"
        return
    fi

    TIMES=0
    cd "${DIR_MAIN}"/edk2
    IsLinkOnline $EDK2_REP
    # I want ".svn", also empty at the specified revision! .. so I can update!
    svnWithErrorCheck "svn --depth empty co $revision --non-interactive --trust-server-cert $EDK2_REP ."

    echo
    printf "\033[1;34medksetup.sh:\033[0m\n"
    IsLinkOnline $EDK2_REP/edksetup.sh
    svnWithErrorCheck "svn update --accept tf --non-interactive --trust-server-cert $revision edksetup.sh"

    for d in "${edk2array[@]}"
    do
        if [[ "$d" != "Source" ]] && [[ "$d" != "Scripts" ]]; then
            printf "\033[1;34m${d}:\033[0m\n"
            TIMES=0
            IsLinkOnline "$EDK2_REP/${d}"
            cd "${DIR_MAIN}"/edk2
            if [[ -d "${DIR_MAIN}/edk2/${d}" ]] ; then
                cd "${DIR_MAIN}/edk2/${d}"
                svnWithErrorCheck "svn update --accept tf --non-interactive --trust-server-cert $revision" "$(pwd)"
            else
                cd "${DIR_MAIN}"/edk2
                svnWithErrorCheck "svn co $revision --non-interactive --trust-server-cert $EDK2_REP/${d}" "$(pwd)"
            fi
        fi
    done
    ForceEDK2Update=0
    cleanAllTools $BaseToolsRev
}
# --------------------------------------
clover() {
    local cmd=""
    # check if SUGGESTED_CLOVER_REV is set
    if [[ -z "$SUGGESTED_CLOVER_REV" ]]; then
        TIMES=0
        IsLinkOnline ${CLOVER_REP}
        getRev "remote"
        echo
        if [[ ! -d "${DIR_MAIN}/edk2/Clover" ]] ; then
            printHeader 'Downloading Clover, using the latest revision'
            if IsNumericOnly "${REMOTE_REV}"; then
				mkdir -p "${DIR_MAIN}"/edk2/Clover
                cmd="svn co -r $REMOTE_REV --non-interactive --trust-server-cert ${CLOVER_REP} ."
            else
                printError "Unable to get latest Clover revision, check your internet connection or try later.\n"
                exit 1
            fi
        else
            case ${LOCAL_REV} in
				"0")	printHeader 'Clover local repo not found or damaged, downloading the latest revision'
						rm -rf "${DIR_MAIN}"/edk2/Clover/* > /dev/null 2>&1
						cmd="svn co -r $REMOTE_REV --non-interactive --trust-server-cert ${CLOVER_REP} ." ;;
            	*)		printHeader 'Updating Clover, using the latest revision'
						cmd="svn up --accept tf" ;;
			esac
        fi
    else
        if [[ -d "${DIR_MAIN}/edk2/Clover" ]] ; then
			case ${LOCAL_REV} in
				"0")	printHeader "Clover local repo not found or damaged, downloading the specific revision r${SUGGESTED_CLOVER_REV}"
						rm -rf "${DIR_MAIN}"/edk2/Clover/* > /dev/null 2>&1
						cmd="svn co -r $SUGGESTED_CLOVER_REV --non-interactive --trust-server-cert ${CLOVER_REP} ." ;;
            	*)		printHeader "Updating Clover, using the specific revision r${SUGGESTED_CLOVER_REV}"
						cmd="svn up --accept tf --non-interactive --trust-server-cert -r $SUGGESTED_CLOVER_REV" ;;
			esac
        else
				printHeader "Downloading Clover, using the specific revision r${SUGGESTED_CLOVER_REV}"
				mkdir -p "${DIR_MAIN}"/edk2/Clover
                cmd="svn co -r $SUGGESTED_CLOVER_REV --non-interactive --trust-server-cert ${CLOVER_REP} ."
        fi
    fi

	cd "${DIR_MAIN}"/edk2/Clover
    svnWithErrorCheck "$cmd" "$(pwd)"

    printHeader 'Apply Edk2 patches'
    cp -R "${DIR_MAIN}"/edk2/Clover/Patches_for_EDK2/* "${DIR_MAIN}"/edk2/ # in Lion cp cause error with subversion (comment this line and enable next)
    # rsync -rv --exclude=.svn "${DIR_MAIN}"/edk2/Clover/Patches_for_EDK2/ "${DIR_MAIN}"/edk2
}
# --------------------------------------
needGETTEXT() {
    restoreIFS
    local gettextPath=""
    local gettextArray=( $(which -a gettext) )
    local needInstall=1

    if [ ${#gettextArray[@]} -ge "1" ]; then

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
# not used here because you now will
# see that in ebuild.sh, and anyway
# nasm should be found in NASM_PREFIX
# otherwise auto installed!
needNASM() {
    restoreIFS
    local nasmPath=""
    local nasmArray=( $(which -a nasm) )
    local needInstall=1
    local good=""

    if [ ${#nasmArray[@]} -ge "1" ]; then

        for i in "${nasmArray[@]}"
        do
            echo "found nasm v$(${i} -v | grep 'NASM version' | awk '{print $3}') at $(dirname ${i})"
        done

        # we have a good nasm?
        for i in "${nasmArray[@]}"
        do
            if isNASMGood "${i}"; then
                good="${i}"
                break
            fi
        done

        if [[ -x "${good}" ]] ; then
             # only nasm at index 0 is used!
            if [[ "${good}" == "${nasmArray[0]}" ]]; then
                echo "nasm is ok.."
            else
                echo "this one is good:"
                echo "${good}"
                needInstall=0
            fi
        else
            # no nasm versions suitable for Clover
            echo "nasm found, but is not good to build Clover.."
            needInstall=0
        fi
    else
        needInstall=0
        echo "nasm not found.."
    fi

    return $needInstall
}

isNASMGood() {
    # nasm should be greater or equal to 2.12.02 to be good building Clover.
    # There was a bad macho relocation in outmacho.c, fixed by Zenith432
    # and accepted by nasm devel during 2.12.rcxx (release candidate)

    IFS='.';
    result=1

    local array=($( "${1}" -v | grep 'NASM version' | awk '{print $3}' ))

    local index0=0; local index1=0; local index2=0

    # we accept rc versions too (with outmacho.c fix):
    # http://www.nasm.us/pub/nasm/releasebuilds/

    if [ "${#array[@]}" -eq 2 ];then
        index0="$(echo ${array[0]} | egrep -o '^[^rc]+')"
        index1="$(echo ${array[1]} | egrep -o '^[^rc]+')"
    fi
    if [ "${#array[@]}" -eq 3 ];then
        index0="$(echo ${array[0]} | egrep -o '^[^rc]+')"
        index1="$(echo ${array[1]} | egrep -o '^[^rc]+')"
        index2="$(echo ${array[2]} | egrep -o '^[^rc]+')"
    fi

    for comp in ${array[@]}
    do
        if ! IsNumericOnly $comp; then restoreIFS && echo "invalid nasm version component: \"$comp\"" && return $result;fi
    done

    case "${#array[@]}" in
    "2") # two components like "2.12"
        if [ "${index0}" -ge "3" ]; then result=0; fi # index0 > 3 good!
        if [ "${index0}" -eq "2" ] && [ "${index1}" -gt "12" ]; then result=0; fi # index0 = 2 and index1 > 12 good!
    ;;
    "3") # three components like "2.12.02"
        if [ "${index0}" -ge "3" ]; then result=0; fi # index0 > 3 good!
        if [ "${index0}" -eq "2" ] && [ "${index1}" -gt "12" ]; then result=0; fi # index0 = 2 and index1 > 12 good!
        if [ "${index0}" -eq "2" ] && [ "${index1}" -eq "12" ] && [ "${index2}" -ge "2" ]; then result=0; fi
    ;;
    *) # don' know a version of nasm with 1 component or > 3
        echo "Unknown nasm version format (${1}), expected 2 or three components.."
    ;;
    esac
    restoreIFS
    return $result
}
# --------------------------------------
ebuildBorg () {

    if [[ "$MOD_PKG_FLAG" != YES ]]; then
        return
    fi
    local NR=0
    if [[ "$SYSNAME" == Darwin ]]; then
        printHeader 'Modding package resources'
    fi
    
    case "$ARCH" in
    IA32_X64 | X64)
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
        fi
    ;;
    IA32)
        local oldTitle='cloverEFI.32_title'
        local oldDesc='cloverEFI.32_description'
        local newTitle='"cloverEFI.32_title" = "Custom CloverEFI 32-bits (boot3)";'
        local newDesc=$(echo "\"cloverEFI.32_description\" = \"Built using Build_Clover.command with: ${DEFINED_MACRO}\";")
    ;;
    esac

    if [[ "$SYSNAME" != Darwin ]]; then
        return
    fi

    # modding po files
    cp -R "${LOCALIZABLE_FILE}" /tmp/

    set +e # handle the error by ourself
    err=0

    if [[ -f /tmp/Localizable.strings ]]; then
        NR=$(grep -n "${oldTitle}" /tmp/Localizable.strings | grep -Eo '^[^:]+')
        sed -i "" "${NR}s/.*/${newTitle}/" /tmp/Localizable.strings

        # waiting file reappear
        until [ -f /tmp/Localizable.strings ]; do
            sleep 0.3
        done
        NR=$(grep -n "${oldDesc}" /tmp/Localizable.strings | grep -Eo '^[^:]+')
        sed -i "" "${NR}s/.*/${newDesc}/" /tmp/Localizable.strings

        # waiting file reappear
        until [ -f /tmp/Localizable.strings ]; do
            sleep 0.3
        done

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

    if [ "$err" -eq 0 ]; then
        mv -f "${LOCALIZABLE_FILE}" "${LOCALIZABLE_FILE}.back"
        mv /tmp/Localizable.strings "${LOCALIZABLE_FILE}"
        cp -R "${PKG_PATH}/po" "${PKG_PATH}/po_back"
        echo "success!"
        echo $ThickLine
    fi
    set -e
}

restoreClover () {
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

    rm -rf "${DIR_DOWNLOADS}"/source.download


    # no mach-o in linux,
    printHeader "nasm check:"
    if [[ ! -f "${NASM_PREFIX}"nasm ]] || [[ ! -x "${NASM_PREFIX}"nasm ]] || ! isNASMGood "${NASM_PREFIX}"nasm; then
        FORCEREBUILD="-fr" #the path to nasm can now be different in generated make files: it is safe to autogen it again!
        mkdir -p "${DIR_DOWNLOADS}"/source.download
        # NASM_PREFIX (the folder) can be writable or not, but also NASM_PREFIX can be writable and an old nasm inside it not writable because owned by root!

        if [[ "$SYSNAME" == Linux ]]; then
            mkdir -p "${DIR_DOWNLOADS}"/source.download
            downloader "http://www.nasm.us/pub/nasm/releasebuilds/${NASM_PREFERRED}/nasm-${NASM_PREFERRED}.tar.gz" "${NASM_PREFERRED}.tar.gz" "${DIR_DOWNLOADS}/source.download"
            cd "${DIR_DOWNLOADS}"/source.download
            tar -zxf "${NASM_PREFERRED}".tar.gz
            cd "${DIR_DOWNLOADS}/source.download/nasm-${NASM_PREFERRED}"
            ./configure --prefix="${PREFIX}" 1> /dev/null 2> "${DIR_LOGS}"/nasm-"${NASM_PREFERRED}".config.log.txt
            make CC=gcc 1> /dev/null 2> "${DIR_LOGS}"/nasm-"${NASM_PREFERRED}".make.log.txt

            if ([[ ! -e "${NASM_PREFIX}"nasm ]] && ! IsPathWritable "${NASM_PREFIX}") || ([[ -e "${NASM_PREFIX}"nasm ]] && ! IsPathWritable "${NASM_PREFIX}"nasm); then
                echo
                echo "installing nasm to ${NASM_PREFIX} require sudo because"
                echo "is not writable by $BUILDER:"
                sudo make install 1> /dev/null 2> "${DIR_LOGS}"/nasm-"${NASM_PREFERRED}".install.log.txt
                sudo -k
            else
                make install 1> /dev/null 2> "${DIR_LOGS}"/nasm-"${NASM_PREFERRED}".install.log.txt
            fi
        elif [[ "$SYSNAME" == Darwin ]]; then
            mkdir -p "${DIR_DOWNLOADS}"/source.download
            downloader "http://www.nasm.us/pub/nasm/releasebuilds/${NASM_PREFERRED}/macosx/nasm-${NASM_PREFERRED}-macosx.zip" "${NASM_PREFERRED}.zip" "${DIR_DOWNLOADS}/source.download"
            cd "${DIR_DOWNLOADS}"/source.download
            unzip "${NASM_PREFERRED}".zip

            if ([[ ! -e "${NASM_PREFIX}"nasm ]] && ! IsPathWritable "${NASM_PREFIX}") || ([[ -e "${NASM_PREFIX}"nasm ]] && ! IsPathWritable "${NASM_PREFIX}"nasm); then
                echo
                echo "installing nasm to ${NASM_PREFIX} require sudo because"
                echo "is not writable by $BUILDER:"
                sudo cp -R "nasm-${NASM_PREFERRED}"/nasm "${NASM_PREFIX}" && sudo -k # exiting sudo immediately!
            else
                cp -R "nasm-${NASM_PREFERRED}"/nasm "${NASM_PREFIX}"
            fi
        fi

        # check the installation made:
        if [[ -x "${NASM_PREFIX}"nasm ]] && isNASMGood "${NASM_PREFIX}"nasm; then
            echo Done
        else
            echo "nasm installation error, check the log!"
            exit 1
        fi
    else
        echo "$(${NASM_PREFIX}nasm -v)"
    fi

    # ...gettext does nothing in Linux because we cannot compile the .pkg
    if [[ "$SYSNAME" == Darwin ]]; then
        printHeader "gettext check:"
        if needGETTEXT && [[ ! -x "${TOOLCHAIN_DIR}"/bin/gettext ]]; then
            # buildgettext.sh is buggie:
            # suppose during the download a problem occour you can have an incomplete "gettext-latest.tar.gz" from a previous execution,
            # but buildgettext.sh think that is already downloaded and will try to decompress this incomplete archive, always failing!
            # That's why we remove the archive!
            if [[ -f "${DIR_DOWNLOADS}"/gettext-latest.tar.gz ]]; then rm -f "${DIR_DOWNLOADS}"/gettext-latest.tar.gz; fi
            "${DIR_MAIN}"/edk2/Clover/buildgettext.sh
        fi
    fi
    rm -rf "${DIR_DOWNLOADS}"/source.download
}
# --------------------------------------
showMacros() {
    clear
    restoreIFS

    CUSTOM_BUILD="YES"

    case "$ARCH" in
    IA32_X64)
        printHeader "BUILD boot3 and boot7 with additional macros"
    ;;
    X64)
        printHeader "BUILD boot7 with additional macros"
    ;;
    IA32)
        printHeader "BUILD boot3 with additional macros"
    ;;
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
        printf "\e[1;30mno one\033[0m\n"
    else
        printf "\033[1;36m\n${DEFINED_MACRO}\033[0m\n"
    fi

    echo

    if [ "${#macros[@]}" -gt "0" ]; then
        echo "enter you choice or press \"b\" to build:"
        printf '? ' && read choice
        if [ "${choice}" == "b" ] || [ "${choice}" == "B" ]; then
            echo "going to build as requested.."
        elif [[ ${choice} =~ ^[0-9]+$ ]]; then
            if [ "$choice" -gt "0" ] && [ "$choice" -le ${#macros[@]} ]; then
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
build() {
    if [[ -d "${DIR_MAIN}/edk2/Clover/.svn" ]] ; then
        echo 'Please enter your choice: '
        local options=()

        # add the option to link the script
        if [[ ! -f "$SYMLINKPATH" ]]; then
            options+=("add \"buildclover\" symlink to $(dirname $SYMLINKPATH)")
        else
            #  ...but may point to another script..
            local scriptPath="${0}"
            local symPath=""
            if [[ -L "${0}" ]]; then
                if [[ "$SYSNAME" == Linux ]]; then
                    scriptPath="$(readlink -f ${0})"
                else
                    scriptPath="$(readlink ${0})"
                fi
            fi

            if [[ ! -L "$SYMLINKPATH" ]]; then
                # not a symlink..
                options+=("restore \"buildclover\" symlink")
            else
                if [[ "$SYSNAME" == Linux ]]; then
                    symPath="$(readlink -f ${SYMLINKPATH}))"
                else
                    symPath="$(readlink ${SYMLINKPATH}))"
                fi
                if [[ "${scriptPath}" != "$(readlink ${SYMLINKPATH})" ]]; then
                    # script path mismatch..
                    options+=("update \"buildclover\" symlink")
                fi
            fi
        fi

        if [[ "$SELF_UPDATE_OPT" == YES ]]; then
            options+=("update Build_Clover.command")
        fi

        if [[ "$PING_RESPONSE" == YES ]] && [[ "$BUILDER" != 'slice' ]]; then
            options+=("update Clover only (no building)")
        fi
        if [[ "$BUILDER" == 'slice' ]]; then
            printf "   \e[90m EDK2 revision used r$EDK2_REV latest avaiable is r$REMOTE_EDK2_REV \e[0m\n"
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
            options+=("update Clover + force edk2 update (no building)")
            options+=("run my script on the source")
            options+=("build existing revision (no update, for testing only)")
            options+=("build existing revision for release (no update, standard build)")
            options+=("build existing revision with custom macros enabled")
            options+=("info and limitations about this script")
            options+=("enter Developers mode (only for devs)")
            options+=("Exit")
        fi

        restoreIFS
        local count=1
        for opt in "${options[@]}"
        do
            case $opt in
            "update Build_Clover.command" \
            | "add \"buildclover\" symlink to $(dirname $SYMLINKPATH)" \
            | "restore \"buildclover\" symlink" \
            | "update \"buildclover\" symlink")
                printf "\033[1;31m ${count}) ${opt}\033[0m\n"
            ;;
            "build existing revision for release (no update, standard build)" \
            | "update Clover + force edk2 update (no building)" \
            | "build all for Release" \
            | "build binaries with FORCEREBUILD (boot3, 6 and 7 also)")
                printf "\033[1;36m ${count}) ${opt}\033[0m\n"
            ;;
            *)
                printf " ${count}) ${opt}\n"
            ;;
            esac
            ((count+=1))
        done

        local choice=""
        local lastIndex="${#options[@]}"
        ((lastIndex-=1))
        printf '? ' && read opt

        if IsNumericOnly $opt; then
            ((opt-=1))
            if [ "$opt" -ge "0" ] && [ "$opt" -le "$lastIndex" ]; then
                choice="$(echo ${options[$opt]})"
            fi
        fi

        case $choice in
        "add \"buildclover\" symlink to $(dirname $SYMLINKPATH)" | "restore \"buildclover\" symlink" | "update \"buildclover\" symlink")
            addSymlink
        ;;
        "update Build_Clover.command")
            if [[ "$DOWNLOADER_CMD" == wget ]]; then
                selfUpdate wget
            elif [[ "$DOWNLOADER_CMD" == curl ]]; then
                selfUpdate curl
            else
                printError "\nNo curl nor wget are installed! Install one of them and retry..\n" && exit 1
            fi
            build
        ;;
        "enter Developers mode (only for devs)")
            clear
            if [[ -d "${DIR_MAIN}/edk2/Clover" ]] ; then
                set +e
                BUILDER="slice"
            else
                BUILDER=$USER
                echo "yep... you are a Dev, but at least download Clover firstly :-)"
            fi
            build
        ;;
        "update Clover only (no building)")
            BUILD_FLAG="NO"
            ForceEDK2Update=0
        ;;
        "update Clover + force edk2 update (no building)")
            ForceEDK2Update=1979 # 1979 has a special meaning ...i.e force clean BaseTools
        ;;
        "build existing revision (no update, for testing only)")
            UPDATE_FLAG="NO"
            BUILD_FLAG="YES"
            selectArch
        ;;
        "build with ./ebuild.sh -nb")
            printHeader 'ebuild.sh -nb'
            cd "${DIR_MAIN}"/edk2/Clover
            START_BUILD=$(date)
            ./ebuild.sh -nb
        ;;
        "build with ./ebuild.sh --module=rEFIt_UEFI/refit.inf")
            cd "${DIR_MAIN}"/edk2/Clover
            printHeader 'ebuild.sh --module=rEFIt_UEFI/refit.inf'
            START_BUILD=$(date)
            ./ebuild.sh --module=rEFIt_UEFI/refit.inf
            echo && printf "build started at:\n${START_BUILD}\nfinished at\n$(date)\n\nDone!\n"
        ;;
        "build binaries w/o -fr (boot6 and 7)")
            cd "${DIR_MAIN}"/edk2/Clover
            START_BUILD=$(date)
            printHeader 'boot6'
            ./ebuild.sh -x64 -D NO_GRUB_DRIVERS_EMBEDDED -D CHECK_FLAGS -t XCODE5
            printHeader 'boot7'
            ./ebuild.sh -mc --no-usb -D NO_GRUB_DRIVERS_EMBEDDED -D CHECK_FLAGS -t XCODE5
            echo && printf "build started at:\n${START_BUILD}\nfinished at\n$(date)\n\nDone!\n"
        ;;
        "build binaries with -fr (boot6 and 7)")
            cd "${DIR_MAIN}"/edk2/Clover
            START_BUILD=$(date)
            printHeader 'boot6'
            ./ebuild.sh -fr -x64 -D NO_GRUB_DRIVERS_EMBEDDED -D CHECK_FLAGS -t XCODE5
            printHeader 'boot7'
            ./ebuild.sh -fr -mc --no-usb -D NO_GRUB_DRIVERS_EMBEDDED -D CHECK_FLAGS -t XCODE5
            echo && printf "build started at:\n${START_BUILD}\nfinished at\n$(date)\n\nDone!\n"
        ;;
        "build boot6/7 with -fr --std-ebda")
            cd "${DIR_MAIN}"/edk2/Clover
            START_BUILD=$(date)
            printHeader 'boot6'
            ./ebuild.sh -fr -x64 --std-ebda -D NO_GRUB_DRIVERS_EMBEDDED -D CHECK_FLAGS -t XCODE5
            printHeader 'boot7'
            ./ebuild.sh -fr -mc --std-ebda --no-usb -D NO_GRUB_DRIVERS_EMBEDDED -D CHECK_FLAGS -t XCODE5
            echo && printf "build started at:\n${START_BUILD}\nfinished at\n$(date)\n\nDone!\n"
        ;;
        "build pkg")
            cd "${DIR_MAIN}"/edk2/Clover/CloverPackage
            START_BUILD=$(date)
            printHeader 'make pkg'
            make pkg
            echo && printf "build started at:\n${START_BUILD}\nfinished at\n$(date)\n\nDone!\n"
        ;;
        "build iso")
            cd "${DIR_MAIN}"/edk2/Clover/CloverPackage
            printHeader 'make iso'
            make iso
            echo && printf "build started at:\n${START_BUILD}\nfinished at\n$(date)\n\nDone!\n"
        ;;
        "build pkg+iso")
            cd "${DIR_MAIN}"/edk2/Clover/CloverPackage
            START_BUILD=$(date)
            printHeader 'make pkg + make iso'
            make pkg
            make iso
            echo && printf "build started at:\n${START_BUILD}\nfinished at\n$(date)\n\nDone!\n"
        ;;
        "build all for Release")
            cd "${DIR_MAIN}"/edk2/Clover
            START_BUILD=$(date)
            printHeader 'boot6'
            ./ebuild.sh -fr -x64 -D NO_GRUB_DRIVERS_EMBEDDED -D CHECK_FLAGS -t XCODE5
            printHeader 'boot7'
            ./ebuild.sh -fr -mc --no-usb -D NO_GRUB_DRIVERS_EMBEDDED -D CHECK_FLAGS -t XCODE5

            cd "${DIR_MAIN}"/edk2/Clover/CloverPackage
            make clean
            printHeader 'make pkg'
            make pkg
            printHeader 'make iso'
            make iso
            echo && printf "build started at:\n${START_BUILD}\nfinished at\n$(date)\n\nDone!\n"
        ;;
        "build existing revision for release (no update, standard build)")
            FORCEREBUILD="-fr"
            UPDATE_FLAG="NO"
            BUILD_FLAG="YES"
            selectArch
        ;;
        "build existing revision with custom macros enabled")
            DEFINED_MACRO=""
            UPDATE_FLAG="NO"
            BUILD_FLAG="YES"
            selectArch
            showMacros ""
        ;;
        "run my script on the source")
            if [[ $(echo $USER | tr "[:upper:]" "[:lower:]" ) =~ ^micky1979 ]]; then
                printHeader Pandora
                mydir="$(cd "$(dirname "$BASH_SOURCE")"; pwd)"
                cd "${mydir}"
                ./CloverPandora.sh Clover $BUILDTOOL
                printHeader Done
                build
            else
                printHeader "add the script you want to run here.."
                exit 0
            fi
        ;;
        "info and limitations about this script")
            showInfo
        ;;
        "Back to Main Menu")
            clear && BUILDER=$USER && build
        ;;
        "Exit")
            exit 0;
        ;;
        *)
            clear && echo "invalid option!!" && build
        ;;
        esac
    fi

    if [[ "$BUILDER" == 'slice' ]]; then clear && build; fi

    # show info about the running OS and its gcc
    if [[ "$SYSNAME" == Darwin ]]; then
        printHeader "Running from: $( sw_vers -productVersion )"
        printHeader "$( /usr/bin/xcodebuild -version)"
    elif [[ "$SYSNAME" == Linux ]]; then
        if [[ -x "/usr/bin/lsb_release" ]]; then
            printHeader "Running from: $(lsb_release -sir | sed -e ':a;N;$!ba;s/\n/ /g')"
        else
            printHeader "Running from: Linux"
        fi
    else
        printHeader "Running from: Unknown OS"
    fi
    printHeader "$( gcc -v )"

    if [[ "$BUILDER" != 'slice' ]]; then restoreClover; fi

    if [[ "$UPDATE_FLAG" == YES ]] && [[ "$BUILDER" != 'slice' ]]; then
        edk2
        clover
    fi

    if [[ "$BUILD_FLAG" == NO ]]; then
        clear
        # print updated remote and local revision
        printCloverRev "Remote revision: " "Local revision: "
        build
    fi

    set -e

    exportPaths

    case "$BUILDTOOL" in
    GCC49)
        printHeader "BUILDTOOL is $BUILDTOOL"
        if [[ "$SYSNAME" == Darwin ]]; then "${DIR_MAIN}"/edk2/Clover/buildgcc-4.9.sh; fi
    ;;
    GCC53)
        printHeader "BUILDTOOL is $BUILDTOOL"
        if [[ "$SYSNAME" == Darwin ]]; then "${DIR_MAIN}"/edk2/Clover/build_gcc6.sh; fi
    ;;
    XCODE*)
        exportXcodePaths
        printHeader "BUILDTOOL is $BUILDTOOL"
    ;;
    esac

    if [[ "$BUILDER" != 'slice' ]]; then
        buildEssentials
        cleanCloverV2
    fi

    cd "${DIR_MAIN}"/edk2/Clover

    START_BUILD=$(date)

    # Slice has removed that flag entirely until new development will comes,
    # so the follow is just a momentarily patch for XCODE5
    if [[ "$SYSNAME" == Darwin ]]; then LTO_FLAG=""; fi

    set +e


    if [[ "$CUSTOM_BUILD" == NO ]]; then
        # using standard options
        case "$ARCH" in
        IA32_X64)
            printHeader 'boot6'
            doSomething --run-script ./ebuild.sh $FORCEREBUILD -x64 $DEFAULT_MACROS $LTO_FLAG -t $BUILDTOOL
            printHeader 'boot7'
            doSomething --run-script ./ebuild.sh $FORCEREBUILD -mc --no-usb $DEFAULT_MACROS $LTO_FLAG -t $BUILDTOOL
            printHeader 'boot3'
            doSomething --run-script ./ebuild.sh $FORCEREBUILD -ia32 $DEFAULT_MACROS $LTO_FLAG -t $BUILDTOOL
        ;;
        X64)
            printHeader 'boot6'
            backupBoot7MCP79
            doSomething --run-script ./ebuild.sh $FORCEREBUILD -x64 $DEFAULT_MACROS $LTO_FLAG -t $BUILDTOOL

            printHeader 'boot7'
            doSomething --run-script ./ebuild.sh $FORCEREBUILD -mc --no-usb $DEFAULT_MACROS $LTO_FLAG -t $BUILDTOOL
        ;;
        IA32)
            printHeader 'boot3'
            backupBoot7MCP79
            doSomething --run-script ./ebuild.sh $FORCEREBUILD -ia32 $DEFAULT_MACROS $LTO_FLAG -t $BUILDTOOL
        ;;
        esac
    else
        # using custom macros
        case "$ARCH" in
        IA32_X64)
            printHeader 'boot6'
            doSomething --run-script ./ebuild.sh -x64 -fr $LTO_FLAG -t $BUILDTOOL # boot6 is always standard here
            printHeader 'Custom boot7'
            ebuildBorg
            doSomething --run-script ./ebuildBorg.sh -x64 -fr ${DEFINED_MACRO} $LTO_FLAG -t $BUILDTOOL
            printHeader 'boot3'
            doSomething --run-script ./ebuild.sh -ia32 -fr ${DEFINED_MACRO} $LTO_FLAG -t $BUILDTOOL
        ;;
        X64)
            printHeader 'Custom boot7' # boot7 is the only target here
            backupBoot7MCP79
            ebuildBorg
            doSomething --run-script ./ebuildBorg.sh -x64 -fr $LTO_FLAG ${DEFINED_MACRO} -t $BUILDTOOL
        ;;
        IA32)
            printHeader 'Custom boot3'
            backupBoot7MCP79
            ebuildBorg
            doSomething --run-script ./ebuild.sh -ia32 -fr ${DEFINED_MACRO} $LTO_FLAG -t $BUILDTOOL
        ;;
        esac
    fi

    if [[ "$SYSNAME" == Darwin ]]; then
        if [[ "$BUILD_PKG" == YES ]] || [[ "$BUILD_ISO" == YES ]]; then
            cd "${DIR_MAIN}"/edk2/Clover/CloverPackage
            if [[ "$FORCEREBUILD" == "-fr" ]]; then make clean; fi
        fi
        if [[ "$BUILD_PKG" == YES ]]; then
            printHeader 'MAKE PKG'
            make pkg
        fi

        if [[ "$BUILD_ISO" == YES ]]; then
            printHeader 'MAKE ISO'
            make iso
        fi
    else
        if [[ $(echo $USER | tr "[:upper:]" "[:lower:]" ) =~ ^micky1979 ]]; then
            doSomething --run-script "${PATCHES}/Linux/distribution" # under study (.deb)
        else
	    # use xdg-open to use default filemanager for ALL linux.
            #nautilus "${CLOVERV2_PATH}" > /dev/null
	    xdg-open "${CLOVERV2_PATH}" > /dev/null
	fi
    fi

    if [[ "$BUILDER" != 'slice' ]]; then restoreClover; fi
    printHeader "build started at:\n${START_BUILD}\nfinished at\n$(date)\n\nDone!\n"
    printf '\e[3;0;0t'
    exit 0
}

# --------------------------------------

build
