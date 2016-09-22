#!/bin/bash

# made by Micky1979 on 07/05/2016 based on Slice, Zenith432, STLVNUB, JrCs, cvad and Rehabman works

# Tested in OSX using both GNU gcc and clang (Xcode 6.4, 7.2.1, 7.3.1 and Xcode 8). Preferred 
# OS is El Capitan with Xcode >= 7.3.1 and Sierra with Xcode >= 8.
# I older version of OS X is better to use GNU gcc.

# Tested in linux Ubuntu 16.04 amb64 (x86_64). This script install all missing dependencies in the iso images you
# can download at the official download page here: http://releases.ubuntu.com/16.04/ubuntu-16.04.1-desktop-amd64.iso
# where nasm, subversion, uuid-dev headers are missing.
# gcc 5.4 coming with Ubuntu 16.04 is well compiled for Clover, so no need to make a "cross" compilation of it, and 
# I hope will be the same for future version installed here.
# May you have apported changes to your installation, but this is not my fault!
# New incoming release of Ubuntu should be compatible as well..

#
# Big thanks to the following testers:
# droples, Riley Freeman, pico joe, fantomas1, Fljagd, calibre, Mork vom Ork, Maniac10, Matgen84,
# Sherlocks, ellaosx, magnifico, AsusFreak,
# and all others (I'll be happy to increase this list)
#

# --------------------------------------
# preferred build tool (gnu or darwin)
# --------------------------------------
XCODE="XCODE5"     # XCODE32
GNU="GCC49"        # GCC49 GCC53
BUILDTOOL="$XCODE" # XCODE or GNU?      (use $GNU to use GNU gcc, $XCODE to use the choosen Xcode version)
# in Linux this get overrided and GCC53 used anyway!
# --------------------------------------
SCRIPTVER="v4.0.3"
SYSNAME="$( uname )"

BUILDER=$USER # don't touch!

EDK2_REV="22628"   # or any revision supported by Slice (otherwise no claim please)
# <----------------------------
# Preferences:

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
ARCH="IA32_X64"    # will ask if you want IA32 or X64 only
DEFINED_MACRO=""
CUSTOM_BUILD="NO"
START_BUILD=""
TIMES=0

edk2array=(
                BaseTools
                MdePkg
                DuetPkg
                EdkCompatibilityPkg
                IntelFrameworkModulePkg
                IntelFrameworkPkg
                MdeModulePkg
                OvmfPkg
                PcAtChipsetPkg
                ShellPkg
                UefiCpuPkg
            )
# <----------------------------
# default paths (don't touch these vars)
# first check for our path
if [[ "$MODE" == "S" ]]; then
    export DIR_MAIN=${DIR_MAIN:-"${HOME}"/src}
elif [[ "$MODE" == "R" ]]; then
    # Rehabman wants the script path as the place for the edk2 source!
    cd "$(dirname "$0")"
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
        DISABLE_LTO
        ENABLE_SECURE_BOOT
        USE_ION
        DISABLE_USB_MASS_STORAGE
        ENABLE_USB_OHCI
        ENABLE_USB_XHCI
        REAL_NVRAM
        CHECK_FLAGS
        )
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
printCloverRev() {
    # get the revisions
    getRev "remote_local"

    # Remote
    if [ -z "${REMOTE_REV}" ]; then
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
        REMOTE_REV="${REMOTE_REV}"
        printf "\033[1;32m${1}${REMOTE_REV}\033[0m\040"
        # Local
        if [ -z "${LOCAL_REV}" ]; then
            LOCAL_REV="\nSomething went wrong while getting the local revision!"
            printError "$LOCAL_REV"
        else
            LOCAL_REV="${LOCAL_REV}"
            if [ $LOCAL_REV == $REMOTE_REV ]; then
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
donwloader(){
    #$1 link
    #$2 file name
    #$3 path (where will be saved)
    local cmd=""
    local downloadlink=""
    local suggestedFilename=""
    local downloadLocation=""

    if [ -z "${1}" ]; then printError "\nError: donwloader() require 3 argument!!\n" && exit 1; fi
    if [ -z "${2}" ]; then
        printError "\nError: donwloader() require a suggested file name\n" && exit 1
    fi
    if [ -z "${3}" ] || [[ ! -d "${3}" ]]; then printError "\nError: donwloader() require the download path!!\n" && exit 1; fi

    downloadlink="${1}"
    suggestedFilename="${2}"
    downloadLocation="${3}"

    if [ -n $(which curl) ]; then
        cmd="curl -o ${downloadLocation}/${suggestedFilename} -LOk ${downloadlink}"
    elif [ -n $(which wget) ]; then
        cmd="wget -O ${downloadLocation}/${suggestedFilename} ${downloadlink}"
    else
        printError "\nNor curl nor wget are installed! Install one of it and retry..\n" && exit 1
    fi

    # default behavior = replace existing download!
    if [[ -d "${downloadLocation}/${suggestedFilename}" ]]; then
        rm -rf "${downloadLocation}/${suggestedFilename}"
    fi

    eval "${cmd}"
}
# --------------------------------------
clear
printHeader "Build_Clover script $SCRIPTVER"
printHeader "By Micky1979 based on Slice, Zenith432, STLVNUB, JrCs, cecekpawon, Needy,\ncvad, Rehabman, philip_petev\n\nSupported OSes: macOS X, Ubuntu 16.04"

if [[ "$SYSNAME" == Linux ]]; then
    restoreIFS
    tasksARRAY=()

    if [[ "$(uname -m)" != x86_64 ]]; then
        printError "\nBuild_Clover.command is tested only on x86_64 architecture, aborting..\n"
        exit 1
    fi

    # check if the Universally Unique ID library - headers are installed

    if [[ "$(dpkg -s uuid-dev | grep Status)" =~ 'install ok installed' ]]; then
        echo "uuid-dev found.." > /dev/null 2>&1
    else
        tasksARRAY+=('uuid-dev')
    fi

    if [[ -z $(which svn) ]]; then 
        tasksARRAY+=('subversion')
    else
        echo "subversion found.." > /dev/null 2>&1
    fi

    if [ "${#tasksARRAY[@]}" -ge "1" ]; then
        echo "Build_Clover need these things to be installed:"
        echo "${tasksARRAY[@]}"
        echo "but they were not found."
        echo "would you allow to install it/them? (Y/N)"
	
        read answer

        case $answer in
        Y | y)
            if [[ "$USER" != root ]]; then echo "type your password to install:" && sudo -s; fi
            apt-get update
            for stuff in "${tasksARRAY[@]}"
            do
                apt-get install $stuff
    		done
            sudo -k
    	;;
    	*)
            printError "Build_Clover cannot go ahead without it/them, process aborted!\n"
            exit 1
        ;;
        esac
    fi
fi
# ---------------------------->
# Upgrade the working copy
svnUpgrade(){
    # error proof
    if [ ! ${1} ]; then
        return 1;
    fi

    # Upgrade the working copy for the indicated path
    svn upgrade ${1}
}
# ---------------------------->
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

    local dir=("${DIR_MAIN}/edk2/" "${DIR_MAIN}/edk2/Clover/")

    dir_len=${#dir[*]}

    for (( i = 0; i < $(( $dir_len )); i++ )); do
        if [[ -d "${dir[$i]}".svn ]]; then
            svn info "${dir[$i]}" $1 $2 2>&1 | grep 'svn upgrade'
            if [[ $? -eq 0 ]]; then
                printError "Error: You need to upgrade the working copy first.\n"
                printWarning "Would you like to upgrade the working copy in the ${dir[$i]}?\n"
                read input
                local answer=$(echo "$input" | tr '[:upper:]' '[:lower:]')
                if [[ ${answer} == *"y"* ]]; then
                    svnUpgrade "${dir[$i]}"
                    getRev "${1}"
                elif [[ ${answer} == *"n"* ]]; then
                    printWarning "You may encounter errors!\n"
                    return 2;
                fi
            fi
        fi
    done

    # universal
    if [[ ${Arg} == *"remote"* ]]; then
        # Remote
        REMOTE_REV=$(svn info ${CLOVER_REP} | grep '^Revision:' | tr -cd [:digit:])
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
# --------------------------------------
selectArch () {
    restoreIFS
    archs=(
            'Standard with both ia32 and x64'
            'x64 only'
            'ia32 only'
          )

    clear
    printHeader "Select the desired architecture"

    if [ -n "$1" ]; then
        echo "$1" && echo
    fi
    local count=1
    for op in "${archs[@]}"
    do
        printf "\t $count) ${op}\n"
        ((count+=1))
    done

    read opt

    case $opt in
    1)
        ARCH="IA32_X64"
    ;;
    2)
        ARCH="X64"
    ;;
    3)
        ARCH="IA32"
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
    printf "+ using Xcode 7.3 +, but should works fine using gcc 4,9 (GCC49)\n"
    printf "in older ones. Also gcc 5,3 can be used but not actually advised.\n"
    echo
    printf "Don't be surprised if this does not work in Snow Leopard (because can't).\n"
    printf "In Lion can require you to uncomment/comment some line in clover() function.\n"
    echo
    printf "Using old Xcode like v7.2 and older, this script automatically disable\n"
    printf "LTO as suggested by devs. The result will be binaries increased in size.\n"
    printf "Off course that is automatic only for standard compilations, but consider to\n"
    printf "switch back to gcc 4,9 (GCC49).\n"
    echo
    printf "Since v3.5 Build_Clover.command is able to build Clover in Ubuntu 16.04\n"
    printf "using the built-in gcc and installing some dependecies like nasm, subversion and\n"
    printf "the uuid-dev headers if not installed. Off course using only the\n"
    printf "amd64 release (x86_64).\n"
    printf "May work on new releases of Ubuntu as well, but not on older ones.\n"
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
    printf "section. Or enter the Developers mode.\n"
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
    printf "Blanck spaces in the path are not allowed because it will fail!\n"
    echo "${Line}"
    exit 0
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
# $2 = first argument
# $3 = second argument
# $4 = ... and so on

    case "$1" in
            --run-script)
                if [[ -x "${2}" ]]; then
                    "${2}"
                else
                    echo
                    echo "doSomething: \"--run-script\" option require you to add a \"${2}\" script.."
                    echo
                fi
            ;;
            *)
                printError "doSomething: invalid \"$1\" option\n"
                exit 1
            ;;
        esac
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

    if [ -z "${1}" ]; then return; fi

    local cmd="${1}"
    echo "" > "${SVN_STDERR_LOG}"
    eval "${cmd}" 2> "${SVN_STDERR_LOG}"

    local errors=(  'svn: E'
                    'Unable to connect'
                    'Unknown hostname'
                    'timeout'
                    'time out' )

    local ErrCount=0

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
        return 1 # exit success anyway (script is fast)
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
IsNumericOnly() {
    if [[ "${1}" =~ ^-?[0-9]+$ ]]; then
        return 0 # no, contains other or is empty
    else
        return 1 # yes is an integer (no matter for bash if there are zeroes at the beginning comparing it as integer)
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

    if [[ ! -d "${DIR_MAIN}/edk2" ]] ; then
        printHeader 'Downloading edk2'
        mkdir -p "${DIR_MAIN}"/edk2
    else
        printHeader 'Updating edk2'
        if [[ -d "${DIR_MAIN}/edk2/BaseTools" ]] ; then
            getRev "BaseTools"
        fi
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
        printf "\033[1;34m${d}:\033[0m\n"
        TIMES=0
        IsLinkOnline "$EDK2_REP/${d}"
        cd "${DIR_MAIN}"/edk2
        if [[ -d "${DIR_MAIN}/edk2/${d}" ]] ; then
            cd "${DIR_MAIN}/edk2/${d}"
            svnWithErrorCheck "svn update --accept tf --non-interactive --trust-server-cert $revision"
        else
            cd "${DIR_MAIN}"/edk2
            svnWithErrorCheck "svn co $revision --non-interactive --trust-server-cert $EDK2_REP/${d}"
        fi

    done

    cleanAllTools $BaseToolsRev
}
# --------------------------------------
clover() {
    TIMES=0

    IsLinkOnline ${CLOVER_REP}
    getRev "remote"
    local cmd=""

    echo
    if [[ ! -d "${DIR_MAIN}/edk2/Clover" ]] ; then
        printHeader 'Downloading Clover'
        mkdir -p "${DIR_MAIN}"/edk2/Clover
        if IsNumericOnly "${REMOTE_REV}"; then
            cmd="svn checkout -r $REMOTE_REV --non-interactive --trust-server-cert ${CLOVER_REP} ."
        else
            printError "unable to get latest Clover's revision, check your internet connection or try later.\n"
            exit 1
        fi
    else
        printHeader 'Updating Clover'
        cmd="svn update"
    fi

    cd "${DIR_MAIN}"/edk2/Clover
    svnWithErrorCheck "$cmd"

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

    if [[ "$MOD_PKG_FLAG" != YES ]] || [[ "$SYSNAME" != Darwin ]]; then
        return
    fi
    local NR=0
    printHeader 'Modding package resources'
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
            donwloader "http://www.nasm.us/pub/nasm/releasebuilds/${NASM_PREFERRED}/nasm-${NASM_PREFERRED}.tar.gz" "${NASM_PREFERRED}.tar.gz" "${DIR_DOWNLOADS}/source.download"
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
            donwloader "http://www.nasm.us/pub/nasm/releasebuilds/${NASM_PREFERRED}/macosx/nasm-${NASM_PREFERRED}-macosx.zip" "${NASM_PREFERRED}.zip" "${DIR_DOWNLOADS}/source.download"
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

    if [[ ( "${#DEFINED_MACRO} " < 1 ) ]] ; then
        echo "actual macros defined: no one"
    else
        echo "actual macros defined: $DEFINED_MACRO"
    fi

    echo

    if [ "${#macros[@]}" -gt "0" ]; then
        echo "enter you choice or press \"b\" to build:"
        read choice
        if [ "${choice}" == "b" ]; then
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
    if [[ -d "${DIR_MAIN}/edk2/Clover" ]] ; then
        echo 'Please enter your choice: '
        local options=()
        if [[ "$BUILDER" == 'slice' ]]; then
            set +e
            options=(
                 "build with ./ebuild.sh -nb"
                 "build with ./ebuild.sh --module=rEFIt_UEFI/refit.inf"
                 "build binaries (boot3, 6 and 7 also)"
                 "build binaries with FORCEREBUILD (boot3, 6 and 7 also)"
                 "build pkg"
                 "build iso"
                 "build pkg+iso"
                 "build all for Release"
                 "Back to Main Menu"
                 "Exit"
                )
        else
            options=(
                 "update Clover only (no building)"
                 "update & build Clover"
                 "run my script on the source"
                 "build existing revision (no update, standard build)"
                 "build existing revision for release (no update, standard build)"
                 "build existing revision with custom macros enabled"
                 "info and limitations about this script"
                 "enter Developers mode (only for devs)"
                 "Exit"
                )
        fi

        select opt in "${options[@]}"
        do
            case $opt in
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
                break
            ;;
            "update & build Clover")
                BUILD_FLAG="YES"
                selectArch
                break
            ;;
            "build existing revision (no update, standard build)")
                UPDATE_FLAG="NO"
                BUILD_FLAG="YES"
                selectArch
                break
            ;;
            "build with ./ebuild.sh -nb")
                printHeader 'ebuild.sh -nb'
                cd "${DIR_MAIN}"/edk2/Clover
                START_BUILD=$(date)
                ./ebuild.sh -nb
                break
            ;;
            "build with ./ebuild.sh --module=rEFIt_UEFI/refit.inf")
                cd "${DIR_MAIN}"/edk2/Clover
                printHeader 'ebuild.sh --module=rEFIt_UEFI/refit.inf'
                START_BUILD=$(date)
                ./ebuild.sh --module=rEFIt_UEFI/refit.inf
                echo && printf "build started at:\n${START_BUILD}\nfinished at\n$(date)\n\nDone!\n"
                break
            ;;
            "build binaries (boot3, 6 and 7 also)")
                cd "${DIR_MAIN}"/edk2/Clover
                START_BUILD=$(date)
                printHeader 'boot6'
                ./ebuild.sh -x64 -D NO_GRUB_DRIVERS_EMBEDDED -D CHECK_FLAGS -t XCODE5
                printHeader 'boot7'
                ./ebuild.sh -mc --no-usb -D NO_GRUB_DRIVERS_EMBEDDED -D CHECK_FLAGS -t XCODE5
                printHeader 'boot3'
                ./ebuild.sh -ia32 -D NO_GRUB_DRIVERS_EMBEDDED -D CHECK_FLAGS -t XCODE5
                echo && printf "build started at:\n${START_BUILD}\nfinished at\n$(date)\n\nDone!\n"
                break
            ;;
            "build binaries with FORCEREBUILD (boot3, 6 and 7 also)")
                cd "${DIR_MAIN}"/edk2/Clover
                START_BUILD=$(date)
                printHeader 'boot6'
                ./ebuild.sh -fr -x64 -D NO_GRUB_DRIVERS_EMBEDDED -D CHECK_FLAGS -t XCODE5
                printHeader 'boot7'
                ./ebuild.sh -fr -mc --no-usb -D NO_GRUB_DRIVERS_EMBEDDED -D CHECK_FLAGS -t XCODE5
                printHeader 'boot3'
                ./ebuild.sh -fr -ia32 -D NO_GRUB_DRIVERS_EMBEDDED -D CHECK_FLAGS -t XCODE5
                echo && printf "build started at:\n${START_BUILD}\nfinished at\n$(date)\n\nDone!\n"
                break
            ;;
            "build pkg")
                cd "${DIR_MAIN}"/edk2/Clover/CloverPackage
                START_BUILD=$(date)
                printHeader 'make pkg'
                make pkg
                echo && printf "build started at:\n${START_BUILD}\nfinished at\n$(date)\n\nDone!\n"
                break
            ;;
            "build iso")
                cd "${DIR_MAIN}"/edk2/Clover/CloverPackage
                printHeader 'make iso'
                make iso
                echo && printf "build started at:\n${START_BUILD}\nfinished at\n$(date)\n\nDone!\n"
                break
            ;;
            "build pkg+iso")
                cd "${DIR_MAIN}"/edk2/Clover/CloverPackage
                START_BUILD=$(date)
                printHeader 'make pkg + make iso'
                make pkg
                make iso
                echo && printf "build started at:\n${START_BUILD}\nfinished at\n$(date)\n\nDone!\n"
                break
            ;;
            "build all for Release")
                cd "${DIR_MAIN}"/edk2/Clover
                START_BUILD=$(date)
                printHeader 'boot6'
                ./ebuild.sh -fr -x64 -D NO_GRUB_DRIVERS_EMBEDDED -D CHECK_FLAGS -t XCODE5
                printHeader 'boot7'
                ./ebuild.sh -fr -mc --no-usb -D NO_GRUB_DRIVERS_EMBEDDED -D CHECK_FLAGS -t XCODE5
                printHeader 'boot3'
                ./ebuild.sh -fr -ia32 -D NO_GRUB_DRIVERS_EMBEDDED -D CHECK_FLAGS -t XCODE5

                cd "${DIR_MAIN}"/edk2/Clover/CloverPackage
                make clean
                printHeader 'make pkg'
                make pkg
                printHeader 'make iso'
                make iso
                echo && printf "build started at:\n${START_BUILD}\nfinished at\n$(date)\n\nDone!\n"
                break
            ;;
            "build existing revision for release (no update, standard build)")
                FORCEREBUILD="-fr"
                UPDATE_FLAG="NO"
                BUILD_FLAG="YES"
                selectArch
                break
            ;;
            "build existing revision with custom macros enabled")
                DEFINED_MACRO=""
                UPDATE_FLAG="NO"
                BUILD_FLAG="YES"
                selectArch
                showMacros ""
                break
            ;;
            "run my script on the source")
                if [[ "$USER" == 'Micky1979' ]]; then
                    printHeader Pandora
                    mydir="$(cd "$(dirname "$BASH_SOURCE")"; pwd)"
                    cd "${mydir}"
                    ./CloverPandora.sh Clover $BUILDTOOL
                    printHeader Done
                else
                    printHeader "add the script you want to run here.."
                    exit 0
                fi
            ;;
            "info and limitations about this script")
                showInfo
                break
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
        done
    fi

    if [[ "$BUILDER" == 'slice' ]]; then clear && build; fi

    if [[ "$SYSNAME" == Darwin ]]; then
        printHeader "Running from: $( sw_vers -productVersion )"
        printHeader "$( /usr/bin/xcodebuild -version)"
    else
        printHeader "Running from: $SYSNAME"
        printHeader "$( gcc -v )"
    fi

    if [[ "$SYSNAME" == Darwin ]]; then restoreClover; fi

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
        if [[ "$SYSNAME" == Darwin ]]; then "${DIR_MAIN}"/edk2/Clover/build_gcc5.sh; fi
    ;;
    XCODE*)
        exportXcodePaths
        printHeader "BUILDTOOL is $BUILDTOOL"
    ;;
    esac

    if [[ "$BUILDER" != 'slice' ]]; then
        buildEssentials
        if [[ "$SYSNAME" == Darwin ]]; then cleanCloverV2; fi
    fi

    cd "${DIR_MAIN}"/edk2/Clover

    START_BUILD=$(date)

    set +e
    if [[ "$CUSTOM_BUILD" == NO ]]; then
        # using standard options
        case "$ARCH" in
        IA32_X64)
            printHeader 'boot6'
            ./ebuild.sh $FORCEREBUILD -x64 $DEFAULT_MACROS $LTO_FLAG -t $BUILDTOOL
            printHeader 'boot7'
            ./ebuild.sh $FORCEREBUILD -mc --no-usb $DEFAULT_MACROS $LTO_FLAG -t $BUILDTOOL
            printHeader 'boot3'
            ./ebuild.sh $FORCEREBUILD -ia32 $DEFAULT_MACROS $LTO_FLAG -t $BUILDTOOL
        ;;
        X64)
            printHeader 'boot6'
            backupBoot7MCP79
            ./ebuild.sh $FORCEREBUILD -x64 $DEFAULT_MACROS $LTO_FLAG -t $BUILDTOOL
        ;;
        IA32)
            printHeader 'boot3'
            backupBoot7MCP79
            ./ebuild.sh $FORCEREBUILD -ia32 $DEFAULT_MACROS $LTO_FLAG -t $BUILDTOOL
        ;;
        esac
    else
        # using custom macros
        case "$ARCH" in
        IA32_X64)
            printHeader 'boot6'
            ./ebuild.sh -x64 -fr $LTO_FLAG -t $BUILDTOOL # boot6 is always standard here
            printHeader 'Custom boot7'
            ebuildBorg
            ./ebuildBorg.sh -x64 -fr ${DEFINED_MACRO} $LTO_FLAG -t $BUILDTOOL
            printHeader 'boot3'
            ./ebuild.sh -ia32 -fr ${DEFINED_MACRO} $LTO_FLAG -t $BUILDTOOL
        ;;
        X64)
            printHeader 'Custom boot7' # boot7 is the only target here
            backupBoot7MCP79
            ebuildBorg
            ./ebuildBorg.sh -x64 -fr $LTO_FLAG ${DEFINED_MACRO} -t $BUILDTOOL
        ;;
        IA32)
            printHeader 'Custom boot3'
            backupBoot7MCP79
            ebuildBorg
            ./ebuild.sh -ia32 -fr ${DEFINED_MACRO} $LTO_FLAG -t $BUILDTOOL
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
        doSomething --run-script "${PATCHES}/Linux/distribution" # under study (.deb)
    fi

    if [[ "$BUILDER" != 'slice' ]] && [[ "$SYSNAME" == Darwin ]]; then restoreClover; fi
    echo "${ThickLine}"
    printf "build started at:\n${START_BUILD}\nfinished at\n$(date)\n\nDone!\n"
    echo "${Line}"

    exit 0
}

# --------------------------------------

build
