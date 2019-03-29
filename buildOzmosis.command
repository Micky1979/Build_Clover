#!/bin/bash
#V1.0
set -e #-x 
PS4='Line ${LINENO}: '
#useFlag="=TRUE"
#useShell=
#"-DADD_BINARY_HERMIT_SHELL$useFlag"
quick="no"
DEBUG=no
revision=""
rebuild="no"
uPdateq=
uPOz=
add1=
export proc=X64
export TARGET="RELEASE"
export TOOLCHAIN=GCC5 #XCODE5
LTO=0
isNasm=
export NASM_VERSION="2.14.02"
nasmLocalVers=
#export CC=gcc-6
export LTO_PREFIX=gcc-
export CROSSNAME="clover" #"Ozmosis"
export TOOLCHAIN_DIR="$HOME"/src/opt/local
export crossPath="$HOME"/src/opt/local/cross/bin/x86_64-$CROSSNAME-linux-gnu-
export PREFIX="$TOOLCHAIN_DIR"
workDir=$(dirname "$0")
#export EDK_TOOLS_PATH="$workDir"/BaseTools

hostMachine=$(uname)
function echob() {
	echo "$(tput bold)$1$(tput sgr0)"
}

function echon() {
	echo -n "$(tput bold)$1$(tput sgr0)"
}

function echoc() {
    local exp=$1;
    local color=$2;
    local newline="$3";
    if ! [[ $color =~ '^[0-9]$' ]] ; then
       case $(echo $color | tr '[:upper:]' '[:lower:]') in
        black) color=0 ;;
        red) color=1 ;;
        green) color=2 ;;
        yellow) color=3 ;;
        blue) color=4 ;;
        magenta) color=5 ;;
        cyan) color=6 ;;
        white|*) color=7 ;; # white or invalid color
       esac
    fi
    tput setaf $color;
    tput bold;
    echo $newline "$exp";
    tput sgr0;
}
#[ $DEBUG == yes ] && echoc "Shell is set to:- $useShell" red && exit

#shopt -s nocasematch
Green="\033[0;32m"
Blue="\033[1;34m"
Normal="\033[0m"
Red="\033[1;31m"
myV="0.1"
user=$(id -un)
theBoss=$(id -ur)
declare -r CMD=$([[ $0 == /* ]] && echo "$0" || echo "${PWD}/${0#./}")
declare -r Ozmosis_Builder_Script=$(readlink "$CMD" || echo "$CMD")
declare -r workDIR="${Ozmosis_Builder_Script%/*}"
theShortcut=`echo $HOME/Desktop`
theLink=/usr/local/bin/Oz
ffsDIR="${workDIR}"/Ffs
filesDIR="${workDIR}"/Files
patchDIR="${workDIR}"/Patchs
logDIR="${workDIR}"/logDIR
builtROM="${workDIR}"/builtROM
baseROM="${workDIR}"/baseROM
kextsDIR="${workDIR}"/kextsDIR
efiDIR="${workDIR}"/efiDIR
virtualRomsDIR="${workDIR}"/VRomDIR
#dsdt="${workDIR}"/Files/DSDT.aml
modulesDIR="${workDIR}"/modulesDIR
EDK2PATCHDIR="${workDIR}"/edk2Patch
#export TOOL_CHAIN_CONF="${workDIR}"/edk2Patch/Conf/tools_def.txt
updatesInfoDir="${workDIR}"/Ozmosis_Updates_Info
updatesInfo=
updateEDK2=no
OZ_QEMU_DIR="${workDIR}"/OzQemu
for theDIR in baseROM builtROM logDIR efiDIR virtualRomsDIR kextsDIR modulesDIR; do
[[ ! -d "${workDIR}"/$theDIR ]] && mkdir -p "${workDIR}"/$theDIR
done
OZMTool="$filesDIR"/OzMTool${hostMachine}
export DIR_MAIN=${DIR_MAIN:-$HOME/src}
export DIR_TOOLS=${DIR_TOOLS:-$DIR_MAIN/tools}
export DIR_DOWNLOADS=${DIR_DOWNLOADS:-$DIR_TOOLS/download}
export DIR_LOGS=${DIR_LOGS:-$DIR_TOOLS/logs}
export pcdLog="-y Pcd_Log.txt"

if [ "$hostMachine" == "Linux" ]; then
  THREADNUMBER=$(cat /proc/cpuinfo | grep processor | wc -l)
  edk2DIR=$(locate -l 1 -b edk2 )
  #export PLATFORM_DIR=$(locate -l 1 -b Ozmosis-Working )
  export GCC_VERSION=$(gcc -dumpversion)
  export TOOLCHAIN_DIR=/usr
  openFolder=xdg-open

else
  #defaults write com.apple.terminal "Default Window Settings" "Pro"
  #defaults write com.apple.terminal "Startup Window Settings" "Pro"
  haveXcode=$(which gcc)
  [ -z $haveXcode ] && echoc "Installing xcode command line tools" red && xcode-select --install && wait
  THREADNUMBER=$(sysctl -n hw.ncpu)
	if [ -f "${workDIR}"/.edk2DIR ]; then
		edk2DIR=$(cat "${workDIR}"/.edk2DIR)
		if [ ! -d "${edk2DIR}"/.svn ]; then
			rm -rf "${workDIR}"/.edk2DIR 
		fi
	fi		
	while [ ! -f "${workDIR}"/.edk2DIR ]; do # folder with edk2 svn
		echoc "edk2 folder is NOW universal" green
		echoc " drag in edk2 folder" red
		echoc "and press return/enter" green
		echoc "OR"
		echoc " To use Default,$HOME/src/edk2_Ozmosis_Dev" red
		echoc "press return/enter" green
		read my_edk2DIR
		if [ ! -d "${my_edk2DIR}" ] || [ "$my_edk2DIR" == "" ]; then
			my_edk2DIR="$HOME/src/edk2_Ozmosis_Dev"
		fi
		echo "$my_edk2DIR" > "${workDIR}"/.edk2DIR
	done
  #if [ -f "${workDIR}"/.PLATFORM_DIR ]; then
	#PLATFORM_DIR=$(cat "${workDIR}"/.PLATFORM_DIR)
	#if [ ! -d "${PLATFORM_DIR}"/.svn ]; then
		#echoc "Ozmosis svn folder: PLATFORM_DIR " green -n; echoc "ERROR!!!" re
		#rm "${workDIR}"/.PLATFORM_DIR
	#fi	
  #fi	
  #while [ ! -f "${workDIR}"/.PLATFORM_DIR ]; do # folder with Ozmosis svn source
	#echob "drag in Ozmosis svn folder and press return/enter"
	#read my_PLATFORM_DIR
	#if [ -d "$my_PLATFORM_DIR"/.svn ]; then
		#echo "$my_PLATFORM_DIR" > "${workDIR}"/.PLATFORM_DIR
		#break
	#fi	
  #done
  openFolder="open"
fi
edk2DIR=$(cat "${workDIR}"/.edk2DIR)
let THREADNUMBER++
sleep 2
myArch=`uname -m`
PATH=$PATH:$PREFIX/bin  
export PATH
export archBIT="x86_64"
export URL_BUILD=http://hermitcrabslab.com/build
getInfo=No
scanBuild=build
repoOz="https://repo.hermitcrabslab.com/hermitcrabslab/"
#what system
theSystem=$(uname -r)
theSystem="${theSystem:0:2}"
export acpicaVers=20160729
acpicacheck=$(curl -Is http://downuptime.net/acpica.us.html | grep HTTP | cut -d ' ' -f2)
if [ $acpicacheck == 200 ]; then
	acpicaVersInfo=$(curl -s -f https://acpica.org/downloads/ | grep 'The current release of ACPICA is version <strong>')
	export acpicaVers="${acpicaVersInfo:191:8}"
elif [ "$acpicacheck" == "" ]; then
	echob "No ACPICA Internet" 
fi
#echo $acpicaVers && exit
#Always use current Version when building, will auto compile newest STABLE version.
isNasm=
if [ ! -f ${PREFIX}/bin/nasm ]; then
	isNasm=$(which nasm)
	if [ "$isNasmVersion" != "" ]; then
		isNasmVersion=$($isNasm -v)
			if [ "$isNasmVersion" == "NASM version 0.98.40 (Apple Computer, Inc. build 11) compiled on Apr 10 2017" ]; then
				echoc "Not Using Apple nasm!"
			fi
	fi
	isNasm=""
else
	isNasm=${PREFIX}/bin/nasm	
fi

# pngcrush
if [ -f /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/pngcrush ]; then
	[ ! -d "${PREFIX}/bin/" ] && mkdir -p "${PREFIX}/bin/"
		ln -sf /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/pngcrush ${PREFIX}/bin/pngcrush
	xcodePNG=y
else
	xcodePNG=n
	pngVersInfo=""
	pngVersInfo=$(curl -s -f https://sourceforge.net/projects/pmt/files/latest/download | grep "pngcrush/")
	#if [ -z "$pngVersInfo" ]; then 
		pngVersInfo=pngcrush1.8.13
	#fi
fi
echo "Using pngcrush version: ${pngVersInfo:8:6}"
export TARBALL_PNGCRUSH="${pngVersInfo:8:6}"


case "${theSystem}" in
    [0-8]) rootSystem="unsupported" ;;
    9) export rootSystem="Leopard" ;;
    10) export rootSystem="Snow Leopard" ;;
    11) export rootSystem="Lion" ;;
    12)	export rootSystem="Mountain Lion" ;;
    13)	export rootSystem="Mavericks" ;;
    14)	export rootSystem="Yosemite" ;;
    [15-20]) rootSystem="Unknown" ;;
esac

if [[ -L "$theShortcut"/buildOzmosis.command ]]; then
	theLink="$theShortcut"/buildOzmosis.command
fi

if [[ ! -L "$theShortcut"/buildOzmosis.command || $(readlink "$theShortcut"/buildOzmosis.command) != "$Ozmosis_Builder_Script" ]]; then
	if [[ ! -L /usr/local/bin/Oz || $(readlink /usr/local/bin/Oz) != "$Ozmosis_Builder_Script" ]]; then
		echob "Running buildOzmosis.command"
		theText="link"
		echob "To make building Ozmosis easier to use"
		echob "I will do one of the following:"
		echo "    Create link, in /usr/local/bin.     Select any key"
		echo "    Create Shortcut, put it on Desktop. Select 's'"
		echob "    Type 's' OR any key"
		read theSelect
		case "$theSelect" in
                s|S)
                     theLink="$theShortcut"/buildOzmosis.command
                     theText="shortcut"
                     sudoit=
                     ;;
                *)
                sudoit="sudo"
        esac
		printf "Will create link %s to %s\n" $(echob "$theLink") $(echob "buildOzmosis.command")
		if [ "$theLink" == /usr/local/bin/Oz ]; then
			echob "You can THEN 'run' buildOzmosis.command by typing 'oz'"
			if [ ! -d /usr/local/bin ]; then
				command='sudo mkdir -p /usr/local/bin'; echob "$command" ; eval "$command"
			fi
		else
			echob "You can THEN run by double clicking buildOzmosis.command on Desktop"
		fi		
		command='$sudoit ln -sf "${Ozmosis_Builder_Script}" "$theLink" && $sudoit chown $theBoss "$theLink"'
		echob "$command" ; eval "$command"
	fi
fi

pcdLog="-y Pcd_Log.txt"
archBit="x86_64"
# defines for BuildGCC.sh and edk2 build
if [ "$myArch" == "i386" ]; then # for 32bit cpu, probably NOT needed but...
	archBit=""
	export PROCESSOR=Ia32
else
	Proc="X64"
	export PROCESSOR=X64
fi
function buildOther() {
#
# Build iasl
#
cd ${DIR_DOWNLOADS}
[ ! -d $DIR_LOGS ] && mkdir -p $DIR_LOGS
if [ "$iaslLocalVers" != "$acpicaVers" ] && [ "$acpicacheck" != "" ] ; then
	export TARBALL_ACPICA=acpica-unix-$acpicaVers
	echoc "Detected updated SVN iasl " red -n; echoc ":-$acpicaVers-:" green
  	rm -rf ${PREFIX}/bin/iasl
	if [[ ! -f ${DIR_DOWNLOADS}/${TARBALL_ACPICA}.tar.gz ]]; then
    	echoc "Downloading https://acpica.org/sites/acpica/files/${TARBALL_ACPICA}.tar.gz" green
    	echo
    	curl -f -o download.tmp --remote-name https://acpica.org/sites/acpica/files/${TARBALL_ACPICA}.tar.gz || exit 1
    	mv download.tmp ${TARBALL_ACPICA}.tar.gz
    	echo
	fi
	echoc "Building ACPICA $acpicaVers" green
  	tar -zxf ${TARBALL_ACPICA}.tar.gz
  	cd ${TARBALL_ACPICA}
  	#perl -pi -w -e 's/-Woverride-init//g;' ${TARBALL_ACPICA}/generate/unix/Makefile.config
  	make clean
  	make iasl 1> /dev/null 2> $DIR_LOGS/${TARBALL_ACPICA}.make.log.txt
  	make install 1> $DIR_LOGS/${TARBALL_ACPICA}.install.log.txt 2> /dev/null
  	rm -Rf ${DIR_DOWNLOADS}/${TARBALL_ACPICA}
  	echo

else
	echoc "Detected local iasl " red -n; echoc ":-$iaslLocalVers-:" green 
	iaslUpdate=No
fi
#
# Build pngcrush
#

cd ${DIR_DOWNLOADS}
if [[ ! -f ${DIR_DOWNLOADS}/pngcrush-${TARBALL_PNGCRUSH}.tar.gz ]]; then
  echoc "Downloading http://jaist.dl.sourceforge.net/project/pmt/pngcrush/${TARBALL_PNGCRUSH}/pngcrush-${TARBALL_PNGCRUSH}.tar.gz" green
  echo
  curl -f -o download.tmp --remote-name http://jaist.dl.sourceforge.net/project/pmt/pngcrush/${TARBALL_PNGCRUSH}/pngcrush-${TARBALL_PNGCRUSH}.tar.gz || exit 1
  mv download.tmp pngcrush-${TARBALL_PNGCRUSH}.tar.gz
echo
fi

if [[ ! -f ${PREFIX}/bin/pngcrush ]]; then
  echoc "Building pngcrush" green
  tar -xzf pngcrush-${TARBALL_PNGCRUSH}.tar.gz
  cd pngcrush-${TARBALL_PNGCRUSH}
  make 1> /dev/null 2> $DIR_LOGS/pngcrush-${TARBALL_PNGCRUSH}.make.log.txt
  cp pngcrush ${PREFIX}/bin/
  rm -Rf ${DIR_DOWNLOADS}/pngcrush-${TARBALL_PNGCRUSH}
  echo
fi

#
# Build nasm 2.11
#
#set -x
nasmcheck=$(curl -Is https://www.nasm.us | grep HTTP | cut -d ' ' -f2)
verLen=7
if [ "$nasmcheck" == 200 ]; then
	nasmVersInfo=$(curl -s -f https://www.nasm.us | grep "/releasebuilds/")
	if [ "${nasmVersInfo:152:1}" != "." ]; then
		verLen=4
	fi
	export NASM_VERSION="${nasmVersInfo:148:$verLen}"
elif [ "$nasmcheck" == "" ] || [ "$nasmcheck" == "503" ]; then
	echob "No Nasm Internet" 
fi
#echo $verLen "${nasmVersInfo:148:$verLen}"

if [ "$isNasm" == "" ]; then
	echoc "Will make nasm" green
	nasmUpdate=Yes
else
	isNasmVersion=$($isNasm -v)
	if [ "$isNasmVersion" != "" ]; then
		NASM_VERSION="${isNasmVersion:13:$verLen}"
		if [ "$NASM_VERSION" != "0.98.40" ]; then
			export NASM_PREFIX=$(dirname "$isNasm")/
			echoc "Detected local nasm " red -n; echoc ":-$NASM_VERSION-:" green
			return
		else
			#NASM_VERSION="2.13.01"
			nasmUpdate=Yes
		fi
	fi
fi
cd ${DIR_DOWNLOADS}
tarball="nasm-${NASM_VERSION}.tar.xz"
if [[ ! -f "$tarball" ]]; then
	echoc "Status: $tarball not found." red
    curl -f -o download.tmp --remote-name https://www.nasm.us/pub/nasm/releasebuilds/${NASM_VERSION}/$tarball || exit 1
    mv download.tmp $tarball
fi


if [[ "$nasmUpdate" == "Yes" ]]; then
  echoc "Building nasm V${NASM_VERSION}" green
  tar -zxf $tarball
  cd nasm-${NASM_VERSION}
  ./configure --prefix=${PREFIX}
  make 1> /dev/null 2> $DIR_LOGS/$tarball.make.log.txt
  cp nasm ${PREFIX}/bin/
  rm -Rf ${DIR_DOWNLOADS}/nasm-${NASM_VERSION}
  echo
  export NASM_PREFIX="${PREFIX}/"
fi
cd "${edk2DIR}"
}

function buildOz() {	
#
	if [ -d "$edk2DIR"/Build ]; then
		echob "rm Build folder"
		rm -rf "$edk2DIR"/Build
	fi
  	WORKSPACE=
    ADD=
    cd "${edk2DIR}"
	if [ "$PLATFORMFILE" == "OzEmuPkg/OzEmuPkg.dsc" ] || [ "$PLATFORMFILE" == "OzQemuPkg/OzQemuPkg.dsc" ]; then
		#add1="-DSOURCE_DEBUG_ENABLE"
		#export TARGET="DEBUG"
		doDefaults OzEmu
		useShell="-DADD_BINARY_HERMITSHELL=TRUE"
        Add="-DEMBED_PLATFORM_DRIVER=TRUE -DMDE_CPU_X64 -DBUILD_HERMIT_PLATFORM=TRUE -DBUILD_FAT=TRUE -DBUILD_PARTITION=TRUE
	-DEMBED_SMC_EMULATOR_KEXT=TRUE -DADD_DISABLER_INJECTOR=FALSE -DADD_SENSORS=FALSE -DADD_DHWKEXT=FALSE -DADD_POSTBOOT=FALSE
	-DADD_HFSPLUS_BINARY=TRUE -DBUILD_VBOXFS=FALSE -DADD_VOODOOHDA=FALSE -DADD_NTFS_BINARY=TRUE $useShell $add1"
	else
		add1=
		doDefaults My
		Add="-DEMBED_PLATFORM_DRIVER=TRUE -DMDE_CPU_X64 -DBUILD_HERMIT_PLATFORM=TRUE -DBUILD_FAT=TRUE -DBUILD_PARTITION=TRUE 
	-DEMBED_SMC_EMULATOR_KEXT=TRUE -DADD_DISABLER_INJECTOR=FALSE -DADD_SENSORS=FALSE -DADD_DHWKEXT=FALSE -DADD_POSTBOOT=FALSE
	-DADD_HFSPLUS_BINARY=TRUE -DADD_VOODOOHDA=FALSE -DADD_DIRECT_HW=TRUE -DADD_NTFS_BINARY=TRUE $useShell $add1"
	fi
		
   	    
    # Setup workspace if it is not set
    #
    if [[ -z "$WORKSPACE" ]]; then
        echo "Initializing workspace"
        if [[ ! -x "${PWD}"/edksetup.sh ]]; then
            cd ..
        fi
        export EDK_TOOLS_PATH="${PWD}"/BaseTools/        
        source edksetup.sh BaseTools
    else
        echo "Building from: $WORKSPACE"
    fi

#
# Configure defaults for various options
#
BUILD_OPTIONS=
#
# Pick a default tool type for a given OS
#
export IASL_PREFIX=${PREFIX}/bin/
#export EDK_TOOLS_PATH="$workDIR/BaseTools"

#
#
for b in $proc; do
	PROCESSOR=$b
	for a in $TARGET; do
		BUILDTARGET=$a
		echob "Running edk2 build for $PLATFORMFILE $PROCESSOR $BUILDTARGET $TARGET_TOOLS with $THREADNUMBER CPU's"
		build -p $PLATFORMFILE -a $PROCESSOR -b $BUILDTARGET -t $TARGET_TOOLS -n $THREADNUMBER "$Add" --log=build.txt "$pcdLog"
	done
done
wait
cd ..
if [ "$PLATFORMFILE" == "LefiPkg/LefiPkg.dsc" ] || [ "$PLATFORMFILE" == "CoreBootPkg/CoreBootPkgX64.dsc" ] || [ "$PLATFORMFILE" == "DuetPkg/DuetPkgX64.dsc" ]; then
	postLefi "$1"
	"$openFolder" "${edk2DIR}/Build/$1Pkg${PROCESSOR}/${BUILDTARGET}_${TARGET_TOOLS}"/FV
	exit 1
fi	
}

function buildQEMU(){
	command='$sudoit ln -sf /usr/local/Cellar/qemu/2.5.0_2/bin/qemu-system-x86_64 $OZ_QEMU_DIR/qemu-system-x86_64 '
	echob "$command" ; eval "$command"
	return
	
	cd "${DIR_DOWNLOADS}"
	if [ ! -d qemu ] || [ "$uPdateq" == "yes" ]; then
		echoc "Making qemu" green
		[ ! -d qemu/dtc ] && jobs="clone" 
		if [ -d qemu/.git ]; then
			jobs="pull"
			cd qemu
		fi 
		echoc "git $jobs git://git.qemu-project.org/qemu.git" red 
		git "$jobs" git://git.qemu-project.org/qemu.git
			echoc "git submodule update" red
		git submodule update
		wait
	fi
	cd "${DIR_DOWNLOADS}"/qemu
	pwd	
	if [[ ! -f $OZ_QEMU_DIR/qemu-system-x86_64 ]] || [ "$uPdateq" == "yes" ]; then
		echoc "configure" green
		#oldPath=$(echo $PATH)
		#export PATH=/usr/bin:/bin:/usr/sbin:$PATH
		./configure \
		--prefix="$OZ_QEMU_DIR" \
		--target-list="x86_64-softmmu" 
		wait
		make clean
		wait
		echoc "make" green
		make
		wait
		echoc "make install" green
		make install
		wait
		#export PATH="$oldPath"
	fi
}	

function buildROM(){
PROCESSOR=$proc
numROMS=$(ls "${baseROM}" | wc -l)
if [ $numROMS == "0" ]; then
	echoc "No BaseRom found in" red; echoc "${baseROM}" green; echoc "So not building FW" red
	"$openFolder"  "${edk2DIR}/Build/OzmosisPkg${PROCESSOR}/${BUILDTARGET}_${TARGET_TOOLS}"
	return 0
fi
echoc "running postbuild..." green
postBuild
if [ ! -d "${ffsDIR}/${OzLocalREV}/$PROCESSOR/${TARGET}" ] && [ "$1" == "1" ]; then
	return 0
fi
donorROM=$(ls "${baseROM}"/*.rom)
donorROMname=$(basename -s .rom "${donorROM}")
if [ -f "${builtROM}/${donorROMname}_r${OzLocalREV}_${TARGET}".rom ] && [ "$quick" == "yes" ]; then # only build once
	if [ "$1" == "1" ]; then
		rm -rf "${builtROM}/${donorROMname}_r${OzLocalREV}_${TARGET}".rom
		return 0
	fi	
elif [ ! -f "$OZMTool" ]; then
	echoc "No OZMTool in Files Folder!!" red
	echoc "You Cannot Inject Ozmosis!!"
	return 0
elif [ -f "${builtROM}/${donorROMname}_r${OzLocalREV}_${TARGET}".rom ] && [ "$quick" == "No" ]; then
	if [ "$1" == "1" ]; then
		echoc "${donorROMname}_r${OzLocalREV}_${TARGET}.rom, Already Built!!" red
		echoc "rebuild ${donorROMname}_r${OzLocalREV}_${TARGET}.rom from scratch" green
		return 0	
	fi
fi	
echoc "Running OZMTool, using ${donorROMname} as the base image" green
echoc "Creating ${donorROMname}_r${OzLocalREV}_${TARGET}.rom" red
#./OZMTool --ozmcreate --aggressivity 1 --compressdxe --kext kextdir --ffs ffsdir --dsdt DSDT.aml --out outputfile --input BIOS.ROM
#"${filesDIR}"/OZMTool --ozmcreate --compressdxe --compresskexts --kext "${kextsDIR}"/*.kext --ffs "${ffsDIR}/${OzLocalREV}/${PROCESSOR}/${TARGET}" --input "${donorROM}" --efi "${efiDIR}" --out "${builtROM}/${donorROMname}_r${OzLocalREV}_${TARGET}.rom"
"${OZMTool}" --ozmcreate --compressdxe --ffs "${ffsDIR}/${OzLocalREV}/${PROCESSOR}/${TARGET}" --input "${donorROM}" --efi "${efiDIR}" --out "${builtROM}/${donorROMname}_r${OzLocalREV}_${TARGET}.rom"
#"${OZMTool}" --ozmcreate --compressdxe --ffs "${ffsDIR}/${OzLocalREV}/${PROCESSOR}/${TARGET}" --dsdt "$dsdt" --input "${donorROM}" --out "${builtROM}/${donorROMname}_r${OzLocalREV}_${TARGET}.rom"
[ -f "${builtROM}"/.DS_Store ] && rm "${builtROM}"/.DS_Store
wait
"$openFolder" "${builtROM}"
if [ "$keepROM" == "No" ]; then
	rm -rf "${ffsDIR}/${OzLocalREV}"
fi
return 1
}

# checks for gcc install and installs if NOT found
function checkGCC(){
    export myGCC_VERSION="${GCC_VERSION:0:4}" # needed for BUILD_TOOLS e.g GCC46
    echoc "Checking GCC$GCC_VERSION INSTALL status " green
    echoc "<${crossPath}gcc>" red
    if [ -f "${crossPath}gcc" ]; then 
       	local lVers=$("${crossPath}"gcc -dumpversion)
    	#export myGCC_VERSION="${lVers:0:1}${lVers:2:1}" # needed for BUILD_TOOLS e.g GCC46
    	echoc  "STATUS: <-OK-> Continue..." green
    	return
	else
		echoc "$archBit GCC$GCC_VERSION NOT installed" red; echo
	fi	   
	echob "Press 'i' To install to ${PREFIX}/cross/bin/"
	echob "OR"
	echob "Press RETURN/ENTER' to 'EXIT' OzGrower V$myV"
	read choose
	[[ "$choose" == "" ]] && echob "Good ${hours}" && exit 1
	[ ! -d "${PREFIX}" ] && mkdir -p "${PREFIX}"
	cd "${workDIR}"/Files
	echo "  Download/install GCC$GCC_VERSION Compiler Tool"
	echob "  To: ${PREFIX}"
	sleep 2
	echo "  Files/build_gcc7  ${PREFIX} $GCC_VERSION $archBit"
	echoc "  Starting GCC$GCC_VERSION build process..." red
    export gccVers="${GCC_VERSION}"
	("${filesDIR}"/build_gcc7.sh) # build all to CG_PREFIX with GCC_VERSION
}

function checkit(){
	return_val=$?
	local msg="$1"
	local error_msg="${2:-}"
	if [[ "${return_val}" -eq 0 ]]; then
		echob "$msg OK"
        return $return_val
	else
		echob "$msg $error_msg ERROR!!"
		exit $return_val
	fi
}


function doDefaults(){
	local dName="$1"
	if [ -f "${filesDIR}"/"$dName"Defaults.plist ]; then
		echob "${dName}Defaults.plist FOUND, Will use iT"
		echo "cp -R ${dName}Defaults.plist OzmosisPkg/Defaults.plist"
		cp -R "${filesDIR}"/"${dName}"Defaults.plist "${edk2DIR}"/OzmosisPkg/Defaults.plist		
	fi
}

function makeIso(){
	# courtesy of http://www.contrib.andrew.cmu.edu/~somlo/OSXKVM/MakeMavericksDVD.sh
 			echob "Mount ${theApp}/Contents/SharedSupport/InstallESD.dmg to /Volumes/install_app:"
 			hdiutil attach "${theApp}"/Contents/SharedSupport/InstallESD.dmg -noverify -nobrowse -mountpoint /Volumes/install_app

			echob "Convert /Volumes/install_app/BaseSystem.dmg to $OSXVers.sparseimage:"
			hdiutil convert /Volumes/install_app/BaseSystem.dmg -format UDSP -o /tmp/$OSXVers

			echob "Increase the sparse bundle capacity to accommodate the packages:"
			hdiutil resize -size 8g /tmp/$OSXVers.sparseimage

			echob "Mount /tmp/$OSXVers.sparseimage for package addition:"
			hdiutil attach /tmp/$OSXVers.sparseimage -noverify -nobrowse -mountpoint /Volumes/install_build

			echob "Remove Package link: /Volumes/install_build/System/Installation/Packages:"
			rm /Volumes/install_build/System/Installation/Packages
			echob "cp -rp /Volumes/install_app/Packages /Volumes/install_build/System/Installation/:"
			cp -rp /Volumes/install_app/Packages /Volumes/install_build/System/Installation/

			echob "Unmount the installer image: /Volumes/install_app:" 
			hdiutil detach /Volumes/install_app
			echob "and the sparse bundle: /Volumes/install_build:"
			hdiutil detach /Volumes/install_build

			echob "Resize /tmp/$OSXVers.sparseimage to remove any free space:" 
			hdiutil resize -size $(hdiutil resize -limits /tmp/$OSXVers.sparseimage | tail -n 1 | awk '{ print $1 }')b /tmp/$OSXVers.sparseimage

			echob "Convert /tmp/$OSXVers.sparseimage to ./$OSXVers.cdr:" 
			hdiutil convert /tmp/$OSXVers.sparseimage -format UDTO -o ./$OSXVers

			echob "Remove the sparse bundle: /tmp/$OSXVers.sparseimage"
			rm /tmp/$OSXVers.sparseimage

			echob "mv ./$OSXVers.cdr to ./$OSXVers.iso:"
			mv ./$OSXVers.cdr ./$OSXVers.iso
			echob "Done!..."
			sleep 2
}

function patchEDK2(){
cd "${edk2DIR}"
if  [ ! -f "${binDIR}"/VfrCompile ]; then
	if [ ! -d "${edk2DIR}"/BaseTools/Source ]; then
		echoc "BaseTools corrupt, fixing..." red
		svn up BaseTools # lock to this revision
		#svn up -r 17700 BaseTools # lock to this revision
	fi	
	source ./edksetup.sh
	# Remove old edk2 config files
	#rm -f "${edk2DIR}"/Conf/{BuildEnv.sh,target.txt,tools_def.txt}
	#cp -R "${EDK2PATCHDIR}"/tools_def.template Conf/tools_def.txt
	#cp -R "${filesDIR}"/build_rule.txt Conf
	echoc "Compiling edk2 BaseTools" green
	#cd BaseTools
	oldPath=$(echo $PATH)
	export PATH=/usr/bin:/bin:/usr/sbin:$PATH
	cmd="make -C Basetools clean"
	logfile="$logDIR/edk2.log.txt"
	[ -f "logfile" ] && rm -rf "$logfile"
	[[ -d "${edk2DIR}"/BaseTools/Source/C/bin ]] && eval "$cmd" > /dev/null	
	cmd="make -C Basetools"
	echo "$cmd" > "$logfile"
	eval "$cmd" >> "$logfile" 2>&1	
	if [[ $? -ne 0 ]]; then
    	echoc "Error Compiling edk2 BaseTools ! Check the log $logfile" red
    	echoc "Will try to autofix" red
    	rm "${edk2DIR}"/BaseTools/Source
    	patchEDK2
    	return    	
    fi
    cd ..
	export PATH="$oldPath"
    echo

fi	
}

# below WAS used to patch various files for GCC, but now supported, so just used as is..
function patchIT(){
	if [ "$1" == "" ]; then 
		echob "copy Ozmosis svn source to edk2"
		OzPkgs=$(ls "$PLATFORM_DIR" | grep 'Pkg')
	else
		OzPkgs="$1"Pkg	
	fi	
	for z in $OzPkgs; do
	   	echoc "cp $z to EDK2" red
		cp -R "$PLATFORM_DIR"/$z "${edk2DIR}"/
	done
	pushd "${edk2DIR}"	>/dev/null	
	# patches here
	#echoc "cp -R GNUVersion OzmosisPkg/Tools" red # needed, svnversion does not work.
	#cp -R "${filesDIR}"/GNUVersion OzmosisPkg/Tools
	popd >/dev/null
}


# Function to manage PATH
pathmunge () {
    if [[ ! $PATH =~ (^|:)$1(:|$) ]]; then
        if [[ "${2:-}" = "after" ]]; then
            export PATH=$PATH:$1
        else
            export PATH=$1:$PATH
        fi
    fi
}

function postBuild() {
if [ "$PLATFORMFILE" == "OzmosisPkg/OzmosisPkg.dsc" ]; then
	if [ "${revision}" != "" ]; then
		OzRemoteREV="${revision}"
	else
		OzRemoteREV="${OzLocalREV}"	
	fi
	#for b in X64; do
		PROCESSOR=$proc #$b
		#for a in $TARGET; do
			BUILDTARGET=$TARGET #$a
			[ ! -d "${ffsDIR}/${OzRemoteREV}/${PROCESSOR}/${BUILDTARGET}" ] && mkdir -p "${ffsDIR}/${OzRemoteREV}/${PROCESSOR}/${BUILDTARGET}"
			[ -d "${ffsDIR}/${OzRemoteREV}/${PROCESSOR}/${BUILDTARGET}" ] && rm -rf "${ffsDIR}/${OzRemoteREV}/${PROCESSOR}/${BUILDTARGET}"/*
			efiDIR="${edk2DIR}/Build/OzmosisPkg${PROCESSOR}/${BUILDTARGET}_${TARGET_TOOLS}"/FV/Ffs
			efi=$(ls "${efiDIR}")
			if [ -f "${modulesDIR}"/*.ffs ]; then
				echoc "cp modules to donor ffs" green
				cp -R "${modulesDIR}"/*.ffs "${ffsDIR}/${OzRemoteREV}/$PROCESSOR/${BUILDTARGET}"/
			fi

			for c in $efi; do
				if [[ "$c" == FIRMWARE.inf || "$c" == FvAddress.inf ]]; then
					echoc "Skipping " green -n; echoc "$c" red
				else	
					cGuid="${c:0:36}"
					cName="${c:36:20}"
					#7C04A583-9E3E-4f1c-AD65-E05268D0B4D1Shell
					if [ "$cGuid" == "C57AD6B7-0515-40A8-9D21-551652854E37" ] || [ "$cGuid" == "c57ad6b7-0515-40a8-9d21-551652854e37" ]; then
						echoc "Using HermitShell as the Shell ;)" green	
						cName="HermitShellX64"
					fi
					if [ "$cGuid" == "7C04A583-9E3E-4F1C-AD65-E05268D0B4D1" ]; then
 						echoc "Deleting crappy UEFI shell :)" red
 						#rm -rf "${efiDIR}"/"$c"/"${cGuid}".ffs
 					elif [ "${cName}" == "" ]; then
						break
					else
						echoc "rename " green -n; echoc "${cGuid} " red -n; echoc "To " green -n; echoc "${cName}" red
						cp -R "${efiDIR}"/"$c"/"${cGuid}".ffs "${ffsDIR}/${OzRemoteREV}/$PROCESSOR/${BUILDTARGET}"/"${cName}".ffs
					fi	
				fi	
			done
		#done
	#done
fi
}

function postLefi(){
VBIOSPATCHcrossEFI=0
ONLYSATA0PATCH=0
USE_BIOS_BLOCKIO=0
USE_LOW_EBDA=1
CLANG=0

export BOOTSECTOR_BIN_DIR="${edk2DIR}"/"$1"Pkg/BootSector/bin
export BASETOOLS_DIR="${edk2DIR}"/BaseTools/Source/C/bin
export BUILD_DIR="${edk2DIR}/Build/${1}PkgX64/${BUILDTARGET}_${TARGET_TOOLS}"
echo Compressing DUETEFIMAINFV.FV ...
"${BASETOOLS_DIR}"/LzmaCompress -e -o "${BUILD_DIR}"/FV/DUETEFIMAINFV.z "${BUILD_DIR}"/FV/DUETEFIMAINFV.Fv
echo "OK"
echo Compressing DxeMain.efi ...
"${BASETOOLS_DIR}"/LzmaCompress -e -o "${BUILD_DIR}"/FV/DxeMain.z "${BUILD_DIR}"/$PROCESSOR/DxeCore.efi
echo "OK"
echo Compressing DxeIpl.efi ...
"${BASETOOLS_DIR}"/LzmaCompress -e -o "${BUILD_DIR}"/FV/DxeIpl.z "${BUILD_DIR}"/$PROCESSOR/DxeIpl.efi
echo "OK"
echo Generate Loader Image ...
if [ $PROCESSOR == IA32 ]; then
	"${BASETOOLS_DIR}"/GenFw --rebase 0x10000 -o "${BUILD_DIR}"/$PROCESSOR/EfiLoader.efi "${BUILD_DIR}"/$PROCESSOR/EfiLoader.efi
	"${BASETOOLS_DIR}"/EfiLdrImage -o "${BUILD_DIR}"/FV/Efildr32 "${BUILD_DIR}"/$PROCESSOR/EfiLoader.efi "${BUILD_DIR}"/FV/DxeIpl.z "${BUILD_DIR}"/FV/DxeMain.z "$BUILD_DIR}"/FV/DUETEFIMAINFV.z
	cat "${BOOTSECTOR_BIN_DIR}"/Start16.com "${BOOTSECTOR_BIN_DIR}"/efi32.com2 "${BUILD_DIR}"/FV/Efildr32 > "${BUILD_DIR}"/FV/Efildr16
	cat "${BOOTSECTOR_BIN_DIR}"/Start32.com "${BOOTSECTOR_BIN_DIR}"/efi32.com2 "${BUILD_DIR}"/FV/Efildr32 > "${BUILD_DIR}"/FV/Efildr20
	dd if="${BUILD_DIR}"/FV/Efildr20 of="${BUILD_DIR}"/FV/boot bs=512 skip=1
fi
if [ $PROCESSOR == X64 ]; then
	"${BASETOOLS_DIR}"/GenFw --rebase 0x10000 -o "${BUILD_DIR}"/$PROCESSOR/EfiLoader.efi "${BUILD_DIR}"/$PROCESSOR/EfiLoader.efi
	"${BASETOOLS_DIR}"/EfiLdrImage -o "${BUILD_DIR}"/FV/Efildr64 "${BUILD_DIR}"/$PROCESSOR/EfiLoader.efi "${BUILD_DIR}"/FV/DxeIpl.z "${BUILD_DIR}"/FV/DxeMain.z "${BUILD_DIR}"/FV/DUETEFIMAINFV.z
    startBlock=Start64H.com
	if [[ "$USE_BIOS_BLOCKIO" -ne 0 ]]; then
		crossEFIFile=boot7
		if [[ "$USE_LOW_EBDA" -ne 0 ]]; then
			startBlock=Start64H4.com
		else
			startBlock=Start64H2.com
		fi
	elif [[ "$USE_LOW_EBDA" -ne 0 ]]; then
		startBlock=Start64H3.com
	fi
	echo $startBlock
	cat "$BOOTSECTOR_BIN_DIR/$startBlock" "$BOOTSECTOR_BIN_DIR"/efi64.com3 "${BUILD_DIR}"/FV/Efildr64 > "${BUILD_DIR}"/FV/Efildr20Pure    
	if [[ "$USE_LOW_EBDA" -ne 0 ]]; then
           "$BASETOOLS_DIR"/GenPage "${BUILD_DIR}"/FV/Efildr20Pure -b 0x88000 -f 0x68000 -o "${BUILD_DIR}"/FV/Efildr20
    else   
          "$BASETOOLS_DIR"/GenPage "${BUILD_DIR}"/FV/Efildr20Pure -o "${BUILD_DIR}"/FV/Efildr20
    fi  
        # Create LefiPkgEFI file
    dd if="${BUILD_DIR}"/FV/Efildr20 of="${BUILD_DIR}"/FV/boot bs=512 skip=1
	echo Done!...
fi
}

function runQemu() {
	AUTO_QEMU_ISO=
	AUTO_QEMU_HDA=
	ADD_QEMU_ISO= 
	#yes #to make iso
	AUTO_ISO=
	AUTO_HDC=
	cd "${OZ_QEMU_DIR}"
	if [ -f ./SMBIOS.bin ]; then
		ADD_SMBIOS="-smbios file=./SMBIOS.bin"
	else
		ADD_SMBIOS=
	fi
	if [ "$ADD_QEMU_ISO" == "yes" ]; then
		OSXVers=
 		if [ -e  /Applications/"Install OS X Mavericks.app" ]; then
 			theApp=/Applications/"Install OS X Mavericks.app"
 			OSXVers=Mavericks
 		else
 			echo "Drap Lion-Mavericks app here, OR enter 'x' to exit"
 			read theApp
 		fi
 		if [ ! -e "${theApp}" ] || [ "${theApp}" ==	x ]; then
 			echo "goodbye..." && exit 1
 		else
 			echo "Using ${theApp} as AppStore Source"
 		fi
 		if [ ! -f ./*.iso ]; then
 			echob "Will make $OSXVers.iso from AppStore Source"
 			makeIso
		fi
 	fi
	if [ -f ./*.iso ]; then
		AUTO_ISO=$(ls *.iso)
	fi		
	if [ -f ./"$AUTO_ISO" ]; then
		AUTO_QEMU_ISO="-boot d -cdrom ./$AUTO_ISO" # -drive file=D:${OZ_QEMU_DIR}/darwin.iso,media=cdrom,cache=writeback
	elif [ -f "/Users/stlvnub/Desktop/El_Capitan.iso" ]; then
		AUTO_QEMU_ISO="-cdrom /Users/stlvnub/Desktop/El_Capitan.iso"
	fi	
	if [ -f ./OSX.img ]; then
		echob "Adding OSX as hdb"
		AUTO_QEMU_IMG="-hdb ./OSX.img"
	else
		AUTO_QEMU_IMG=
	fi
	if [ -f ./*.qcow2 ]; then
		AUTO_HDB=$(ls *.qcow2)
		echob "Adding $AUTO_HDB as hdb"
		AUTO_ADD_QCOW2="-hdb ./$AUTO_HDB"
	else
		AUTO_ADD_QCOW2=	
	fi
	if	[ "$AUTO_QEMU_HDA" == "y" ]; then
		if  [ ! -f ./*.vmdk ]; then
			echob "vmdk NOT found, will make darwin-disk.vmdk size 6G..."
			"${QEMU_IMAGE}" create -f vmdk ./darwin-disk.vmdk 6G
			AUTO_HD=./darwin-disk.vmdk
		else
			echob "using $AUTO_HD"
			AUTO_HD=$(ls *.vmdk)
		fi	
		AUTO_QEMU_HDA="-hdb $AUTO_HD"
	fi
	#options="-M pc-i440fx-2.1 -cpu core2duo,kvm=off -smp 1,cores=2 -m 3G -rtc 
	#base=localtime,clock=host -k en-us -smbios type=2 
	#-global PIIX4_PM.disable_s3=0 -serial file:./serial.txt -hda fat32:EFI"

	#-global isa-debugcon.iobase=0x402 -debugcon file:debug.log -net none
	#-drive if=pflash,format=raw,file=Ozmosis.flash
	if [ "$hostMachine" == "Linux" ]; then
	  options="-cpu IvyBridge,kvm=on,+monitor,+dtes64,+pbe,+tm,+ht,+ss,+ds,+vme -smp 1,cores=2 -m 4000 -rtc base=localtime,clock=host -k en-us -serial file:./serial.txt -M q35 -hda fat:EFI" # -boot menu=on"
	else
	  #options="-cpu core2duo,kvm=off 
  	  options="-m 2048 -cpu core2duo -machine q35 -device ahci,id=ahc -usb -device usb-mouse,bus=usb-bus.0,port=2 -device usb-kbd,bus=usb-bus.0,port=1 -serial file:./serial.txt"
  	  #-cpu IvyBridge -m 8192 -smp 2,cores=1 
     # -smbios type=2
     # -rtc base=localtime,clock=host
     # -k en-us
      #-net none
     # -serial file:./serial.txt
     # -device isa-applesmc,osk=ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"
      #-drive file=fat:EFI,format=raw"
	  #-d cpu_reset"
	 # -boot menu=on"
	fi
		#options="-m 4096 -cpu core2duo -smp 1,cores=2
  		#-serial file:./serial.txt"
  		#[ -kernel ./chameleon_boot | -bios OVMF.fd ]
	#fi
	#-drive if=pflash,format=raw,file=${OZ_QEMU_DIR}/OVMF_VARS.fd
 	QEMU_COMMAND_LINE="-drive if=pflash,format=raw,readonly,file=${OZ_QEMU_DIR}/OVMF_CODE.fd
 	$AUTO_QEMU_HDA
 	$AUTO_QEMU_ISO
 	$AUTO_QEMU_IMG
 	$AUTO_ADD_QCOW2
 	$ADD_SMBIOS
 	$options"

	#persistant NVRAM
 	#QEMU_COMMAND="$QEMU_COMMAND -bios ${OZ_QEMU_DIR}/OVMF_CODE.fd $AUTO_QEMU_HDA $AUTO_QEMU_ISO $AUTO_QEMU_IMG $AUTO_ADD_QCOW2 $ADD_SMBIOS $options"
 	#non-persistent BIOS
  	clear
  	echoc "Running: " green -n; echoc "$QEMU_COMMAND" red -n; echoc " With Options:" green; echoc "$QEMU_COMMAND_LINE" red
  	WORKSPACE="$edk2DIR"
  	#cp "$WORKSPACE"/EmulatorPkg/Unix/.gdbinit "$BUILD_ROOT"/"$PROCESSOR"
  	#/usr/bin/gdb $BUILD_ROOT_ARCH/Host -q -cd="$BUILD_ROOT"/"$PROCESSOR" -x "$WORKSPACE"/EmulatorPkg/Unix/GdbRun
  	$QEMU_COMMAND $QEMU_COMMAND_LINE
}


upDateEdk2(){
[ ! -d "${edk2DIR}" ] && mkdir -p "${edk2DIR}"
cd "${edk2DIR}"
if [ ! -d .svn ] || [ ! -d BaseTools ]; then
	echoc "Checkout edk2 Sources" green
	svn co svn://svn.code.sf.net/p/edk2/code/trunk/edk2 . #-r 15815 # BaseTools problem, stick with this revision for now.
	tput bel
elif [ "$1" == "up" ]; then
    svn up
fi		
}

function getOz(){
	#set -x
	pushd . > /dev/null
Repositories="PicoLib Ozmosis PartitionDxe HfsPlus Ntfs HermitShell EnhancedFat"
echoc "Get Ozmosis Source" green
for repo in $Repositories; do
name=$repo
name="${repo}Pkg"
project="$edk2DIR/$name"
arg=git@repo.hermitcrabslab.com:STLVNUB/
gitproj="${arg}${name}".git
[ -d "${project}" ] && cd "${project}"
if [ -d "${project}"/.git ]; then
		arg="."
		gitproj=
		project=
		mode=pull
else
	gitproj="${arg}${name}".git
	mode=clone
fi
cmd="git $mode $gitproj ${project}"
echoc "git $mode $name" green
$cmd 
done
#set +x
popd > /dev/null
}

default(){
    echoc "Setting default..." red
	keepROM="No"
		[ -z $TARGET_TOOLS_VERS ] && TARGET_TOOLS_VERS=9
	#export COLLECT_GCC=gcc
	export TARGET_TOOLS=$TOOLCHAIN
	export GCC_VERSION="7.3.0"
	export GCC5_BIN="$crossPath"
    export PLATFORM_DIR="${edk2DIR}"/OzmosisPkg
	if [ "$useShell" == "" ]; then
         export useShell="-DADD_BINARY_HERMITSHELL=TRUE"
    fi     
    echoc "TARGET_TOOLS :" green -n; echoc " $TARGET_TOOLS" red 
    echoc "TOOLCHAIN_DIR:" green -n; echoc " $TOOLCHAIN_DIR" red
    echoc "TARGET       :" green -n; echoc " $TARGET" red
    echoc "SHELL        :" green -n; echoc " $useShell" red
}

clearVBox(){
   	[ "$runVMs" == "no" ] && exit 1
    export MODE="CLEAR_NVRAM"
    "${edk2DIR}"/VBoxPkg/vboxstart.command
  	#VBoxManage modifyvm "$VM" --cpuidset 00000001 000306a9 00020800 80000201 178bfbff
    if [ -d "$edk2DIR"/Build ]; then
		echob "rm Build folder"
		rm -rf "$edk2DIR"/Build
	fi
}

vboxRun() {
   	[ "$runVMs" == "no" ] && exit 1
	doDefaults VBox
	if [ -z $TARGET_TOOLS ]; then
            default
    fi
	export TARGET_TOOLS=XCODE5   
	export EFI_ROM="${edk2DIR}"/Build/OvmfVBox/${TARGET}_${TARGET_TOOLS}/FV/OVMF.fd
 	#export MODE="EFI_PERSISTENT"
	#MODE="CLEAR_NVRAM"
	export MODE="EFI_NONPERSISTENT"
	#MODE="BIOS"# VirtualBox Script v0.11, tested with VirtualBox v4.3.6-OSX up to v4.3.12-OSX.
	#export VM="Snow"			# Name only
    if [ "$rebuild" == "yes" ]; then
		if [ -f "${EFI_ROM}" ]; then
        	rm "${EFI_ROM}"
        	export rebuild=b
   	    fi
   	    
	fi
	"${edk2DIR}"/VBoxPkg/vboxstart.command 
	exit $?
}	

vboxModel() {
   	[ "$runVMs" == "no" ] && exit 1
    #VBoxManage modifyvm $1 --cpuidset 00000001 000306a9 04100800 7fbae3ff bfebfbff
    VBoxManage setextradata $1 "VBoxInternal/Devices/efi/0/Config/DmiSystemProduct" "MacBookPro11,3"
    VBoxManage setextradata $1 "VBoxInternal/Devices/efi/0/Config/DmiSystemVersion" "1.0"
    VBoxManage setextradata $1 "VBoxInternal/Devices/efi/0/Config/DmiBoardProduct" "Iloveapple"
    VBoxManage setextradata $1 "VBoxInternal/Devices/smc/0/Config/DeviceKey" "ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"
    VBoxManage setextradata $1 "VBoxInternal/Devices/smc/0/Config/GetKeyFromRealSMC" 0
    VBoxManage setextradata $1 "VBoxInternal2/EfiBootArgs" "$bootArgs"
}
vmInstalled=$(which vboxmanage &2>/dev/null)
if [ -z $vmInstalled ]; then
    echoc "No Virtual Machines" red
    export runVms="no"
else
    numVBoxROMS=$(ls -d ~/"VirtualBox VMs/" | wc -l)
    if [ "$numVBoxROMS" == "       0" ]; then
        echoc "No Virtual Machines" red  
        export runVms="no"
    else
        VMS=$(vboxmanage list vms) 
        export VM=Fart #"${VMS:1:4}"
        echoc "Will use $VM as the VBox Virtual Machine" green
        export runVms="yes"
    fi
fi
export BUILD_OPTIONS="-DVBOX -DVBOX_USB -DVBOX_REVERSE_BOOTOPTIONS
	    -DEMBED_PLATFORM_DRIVER=TRUE -DBUILD_FAT=TRUE -DBUILD_PARTITION=TRUE
	    -DEMBED_SMC_EMULATOR_KEXT=TRUE -DADD_DISABLER_INJECTOR=FALSE -DADD_SENSORS=FALSE -DADD_POSTBOOT=FALSE
	    $useShell -DADD_HFSPLUS_BINARY=FALSE -DADD_NTFS_BINARY=TRUE -DBUILD_VBOXFS=FALSE"
#command line
for arg
do
    case $arg in
    q)
  	quick="yes"
  	;;
	br)
	OzLocalREV=$(svnversion "$PLATFORM_DIR") 
	PLATFORMFILE=OzmosisPkg/OzmosisPkg.dsc
	default
	postBuild
	keepROM="Yes"
	buildROM 0
	exit 1
	;;
  	-r)
  	echo "to be fixed" && exit 1
  	revision="$arg"
  	;;
    +)
    useFlag="=TRUE"
    ;;
    -)
    useFlag="=FALSE"
    ;;
    qu)
    uPdateq="yes"
    rebuild="yes"
    buildQEMU
    ;;
	qr)
	QEMU_COMMAND="${OZ_QEMU_DIR}"/bin/qemu-system-$archBit
    QEMU_IMAGE="${OZ_QEMU_DIR}"/bin/qemu-img
	runQemu OzEmu && exit 1
	;;
	nh)
    export useShell="-DBUILD_NEW_HERMITSHELL=TRUE"
    ;;
    nu)
    export useShell="-DBUILD_NEW_UEFISHELL=TRUE"
    [ ! -f "${edk2DIR}"/ShellPkg/ShellPkg.dec ] && upDateEdk2 up
    ;;
    v)
    vboxRun
    ;;
    vo)
    clearVBox
    vboxModel $VM
    export BUILD_OPTIONS="-DVBOX -DVBOX_USB -DVBOX_REVERSE_BOOTOPTIONS 
	-DEMBED_PLATFORM_DRIVER=FALSE $useShell -DADD_HFSPLUS_BINARY=TRUE -DADD_NTFS_BINARY=TRUE -DBUILD_VBOXFS=FALSE"
    vboxRun 
    ;;
    vc)
    clearVBox
    exit
    ;;
    vm)
    clearVBox
    vboxModel $VM
    exit
    ;;
    vn)
    clearVBox
    vboxRun
    ;;
    vnm)
    clearVBox
    vboxModel $VM
    vboxRun 
    ;;
    s|x|f)
    bootArgs="-v -$arg"
    vboxModel $VM
    ;;
	8|9)
	export TARGET_TOOLS_VERS="$arg"
    ;;
    nbt)
    svn up "${edk2DIR}" && wait
    [[ -d "${edk2DIR}"/BaseTools/Source/C/bin ]] && rm -rf "${edk2DIR}"/BaseTools/Source/C/bin
    ;;
    h)
    export useShell="-DADD_BINARY_HERMITSHELL=TRUE"
    ;;
    e)
    export useShell="-DADD_BINARY_EDK2SHELL=TRUE"
    ;;
    u)
    export useShell="-DADD_BINARY_UEFISHELL=TRUE"
    ;;
    bm)
    export useShell="-DADD_BOOT_MANAGER=TRUE"
    ;; 
    X)
    export TARGET_TOOLS="XCLANG" #"GCC${GCC_VERSION:0:1}${GCC_VERSION:2:1}"
    add1="-DCLANG"
    export TOOLCHAIN_DIR=/usr/bin
    export PREFIX="$HOME"/opt
	;;
	C)
    export TARGET_TOOLS="XCODE5" #"GCC${GCC_VERSION:0:1}${GCC_VERSION:2:1}"
    export TOOLCHAIN_DIR=/usr/bin
    export PREFIX="$HOME"/opt
	;;
    b)
    rebuild="yes"
    ;;
    d)
    DEBUG=yes
    export TARGET="DEBUG"
    ;;
    r)
    export TARGET="RELEASE"
	;;
	i)
	getInfo
	exit 1
    ;;
	6)
	#export CC=/usr/local/bin/gcc-6
	export GCC5_BIN=/usr/local/bin/
    #export TOOLCHAIN_DIR=/usr/local/bin/
    #export PREFIX="$HOME"/opt
	#export IASL_PREFIX="${PREFIX}"/bin/
   # export NASM_PREFIX="${PREFIX}"/bin/
	echoc "$using $GCC5_BIN" green 
	;;
	4)
	export proc=X64
	;;
	2)
	export proc=IA32
	export useShell="-DADD_BINARY_HERMIT_SHELL=FALSE"
	;;
	u)
	export uPOz=y
	;;
    *)
    default
    ;;
    esac
done
[ -z $useShell ] && useShell="-DADD_BINARY_HERMITSHELL=TRUE"
# check gcc
if [ "$hostMachine" != "Linux" ]; then
	if [ "$GCC_VERSION" != "UNIXGCC" ]; then
    	if [ "$TARGET_TOOLS" != "XCLANG" ] && [ "$TARGET_TOOLS" != "GCC53" ]; then
        	if [ -z "$TARGET_TOOLS" ]; then
            	default
        	fi    
        	checkGCC
    	fi
	fi 
fi
[ ! -d "${edk2DIR}" ] && mkdir -p "${edk2DIR}"
binDIR="${edk2DIR}"/BaseTools/Source/C/bin
iaslLocalVers=
if [[ -f ${PREFIX}/bin/iasl ]]; then
	iaslLocalInfo=$(${PREFIX}/bin/iasl -v)
	iaslLocalVers=${iaslLocalInfo:81:8} #68
fi

[ ! -d ${DIR_DOWNLOADS} ] && mkdir -p ${DIR_DOWNLOADS}
pngcrushLocalVers=
if [[ -f ${PREFIX}/bin/pngcrush ]]; then
	pngcrushLocalVers=$(${PREFIX}/bin/pngcrush -version)
	pngcrushLocalVers=${pngcrushLocalVers:10:7}
	#echo ${pngcrushLocalVers} && exit 1

fi

[ ! -d ${DIR_DOWNLOADS} ] && mkdir -p ${DIR_DOWNLOADS}srcDIR=$PREFIX/tools/download
echoc "Using..." red
echoc "       ${edk2DIR}" green
echoc "        as edk2 source folder" red 
echoc "Using..." red
echoc "       ${PLATFORM_DIR}" green
echoc "        as Ozmosis svn source folder" red


echoc "Using GCC $GCC_VERSION from:" red
echoc "${crossPath}gcc" green
# Add toolchain bin directory to the PATH
#pathmunge "$TOOLCHAIN_DIR"

# build iasl and pngcrush
buildOther
# if just want info on commits...
#if [ "$getInfo" == "Yes" ] && [ -d "$PLATFORM_DIR"/.svn ]; then
	#echo "showing Ozmosis log"
	#$(svn log "$PLATFORM_DIR" >"$PLATFORM_DIR"/log.txt)
	#more "$PLATFORM_DIR"/log.txt
	#rm "$PLATFORM_DIR"/log.txt
	#exit
#fi

# get local svn revisions
#if [ -d "$PLATFORM_DIR"/.svn ]; then
	#OzLocalREV=$(svnversion "$PLATFORM_DIR") 
#fi
if [ -d "$edk2DIR"/.svn ]; then	
	edk2LocalREV=$(svnversion "$edk2DIR")
fi	
 
if [ "$1" == "c" ] || [ "$2" == "c" ] || [ "$3" == "c" ]; then
	echob "Clean Edk2/Ozmosis!!"
	if [ "$1" == "c" ]; then
		pkg="Ozmosis"
	elif [ "$2" == "c" ] || [ "$3" == "c" ]; then
		pkg=""
	else
		pkg="$1"
	fi
	echob "patchIt $pkg"
	patchIT "$pkg"
	quick="yes"
fi

#buildROM 1
cd "${workDIR}"
upDateEdk2
export PLATFORM_DIR="${edk2DIR}"/OzmosisPkg
if [ -d "$PLATFORM_DIR"/.svn ] && [ "$quick" == "no" ]; then # start quick will skip
	local_modified="0"
	edk2up=
	edk2Up=$(curl -Is https://svn.code.sf.net/p/edk2/code/trunk/edk2 | grep HTTP | cut -d ' ' -f2)
	if [ "$edk2up" == ""  ]; then
		echoc "edk2 is DOWN!!!, not updating" red
	fi	
	#exit 1
	# get OZ svn revisions
	echo ; echoc "----Checking" green -n; echoc " REMOTE and LOCAL " red -n; echoc "Repositories----" green
	echoc "LOCAL " green -n; echoc " Ozmosis svn revision" red -n;	echoc " :-${OzLocalREV:0:4}-:" red -n
	if [ "${OzLocalREV:4:1}" == "M" ] || [ "${OzLocalREV:4:1}" == ":" ]; then
		echoc " MODIFIED" red
		local_modified="1"
	else	
		echo
	fi	
	echoc "REMOTE " green -n; echoc "Ozmosis svn revision " red -n
	OzRemoteInfo=""
	while [ "$OzRemoteInfo" == "" ]; do
		OzRemoteInfo=$(svn info $repoOz | grep 'Last Changed Rev:')
	wait
	done	
	OzRemoteREV=${OzRemoteInfo:18:20}
	echoc ":-${OzRemoteREV}-:" green
	if [ ! -z $edk2up ]; then # check ${OzLocalREV:0:3} so Modified NOT used, i.e 1007M
		edk2RemoteInfo=""
		edk2LocalInfo=$(svn info . | grep 'Last Changed Rev:')
		edk2LocalRev=${edk2LocalInfo:18:20}
		while [ "$edk2RemoteInfo" == "" ]; do
			edk2RemoteInfo=$(svn info https://svn.code.sf.net/p/edk2/code/trunk/edk2 | grep 'Last Changed Rev:')
			wait
		done
		edk2RemoteREV=${edk2RemoteInfo:18:20}
		echoc "LOCAL  " green -n; echoc "edk2    svn revision: " red -n
		echoc "$edk2LocalRev" green
		echoc "REMOTE " green -n; echoc "edk2    svn revision: " red -n
		echoc "$edk2RemoteREV" green
		
		if [ "$edk2LocalRev" != "$edk2RemoteREV" ]; then
			echob "Auto Update edk2 to $edk2RemoteREV"
			svn up 
			echoc "And Revert BaseTools to 17700" red
			svn up -r 17700 BaseTools # lock to this revision
 		else	
			echoc "NOT Updating " red -n;echoc "edk2" green
		fi
	fi
	#if [ "${OzLocalREV:0:4}" != "${OzRemoteREV}" ] || [ "$revision" != "" ]; then
		#if [ -d "$PLATFORM_DIR"/OzmosisPkg ] && [ ! -f "${updatesInfoDir}"/${OzRemoteREV}_info.txt ]; then
			#echob "Auto update Ozmosis Source"
			#echob "${OzRemoteREV} Changes..."
			#changesSVN=$(svn log -v -r "${OzRemoteREV}" "$PLATFORM_DIR")
   			#echob "$changesSVN"
   			#sleep 2
 			#svn up $revision "$PLATFORM_DIR" >"${updatesInfoDir}"/${OzRemoteREV}_info.txt
		#fi
		#echoc "Workspace" green -n; echoc " NOT AT REVISION: " red -n; echoc "${OzRemoteREV} " green -n; echob "Fixing..."
		#patchIT
		#echo "${OzRemoteREV}" > OzmosisPkg/OzVers.txt
	#else
		echoc "NOT Updating " red -n;echoc "Ozmosis" green
	#fi
	echoc "Press " green -n; echoc "Return/Enter " red -n; echoc "to start building " green -n; echoc "r${OzRemoteREV}" red
	echoc "${1}Pkg" green
	echoc "OR " green -n; echoc "'Q' " red -n; echoc "to quit" green
	read getkey
	[ "$getkey" == "q" ] && echoc "bye..." green && exit 1
	
fi # end quick
# patch edk2
patchEDK2
cd "${edk2DIR}"
[ ! -d EnhancedFatPkg ] && getOz
export useShell
OzREV=4096 #svnversion "$PLATFORM_DIR")
#[ ! -d OzmosisPkg ] && echoc "Fixing Source" red && patchIT
echo "${OzREV}" > OzmosisPkg/OzVers.txt
if [ "$1" == "Ovmf" ]; then
	PLATFORMFILE="$1"Pkg/"${1}"Pkg${Proc}.dsc
elif [ "$1" == "Emulator" ];	then
	PLATFORMFILE="$1"Pkg/"${1}"Pkg.dsc
	buildOz
	exit
fi
	
PLATFORMFILE=OzmosisPkg/OzmosisPkg.dsc
#if [ "$revision" != "" ]; then
#	svn cleanup "$PLATFORM_DIR"
#	echob "Update to r$"
#	wait
#	svn up -r "$2" "$PLATFORM_DIR"
#	patchIT
#	echob "Building Ozmosis r$2"
#	sleep 2
#	revision="$2"
#	OzLocalREV="$2"
#	buildOz
#fi

#make
if [ ! -f ${PREFIX}/bin/make ]; then
	if [ -f /usr/bin/make ]; then
		echoc "Linking make for edk2..." green 
    	ln -sf /usr/bin/make ${PREFIX}/bin/make
	else
		echoc "make NOT found" red && exit 0
	fi
fi
if [ $hostMachine == Darwin ]; then
    [ ! -f "${edk2DIR}"/Conf/tools_def.txt ] && "${edk2DIR}"/edksetup.sh
    pushd $"${edk2DIR}"/Conf > /dev/null
    /usr/bin/sed -i '' -e "s/DEF(${TARGET_TOOLS}_IA32_PREFIX)make/make/g" tools_def.txt
    popd  > /dev/null
fi

if [ "$1" == "OzEmu" ] || [ "$1" == "OzQemu" ] || [ "$1" == "Lefi" ] || [ "$1" == "CoreBoot" ] || [ "$1" == "Duet" ] || [ "$1" == "Ovmf" ]; then # if OzEmu OR Lefi, run qemubuild
	#[ ! -d "$1"Pkg ] && echo "$1Pkg Not Found!!, attempting fix" && svn up "$PLATFORM_DIR" && patchIT "$1"
	if [ "$1" == "CoreBoot" ] || [ "$1" == "Duet" ] || [ "$1" == "Ovmf" ]; then
		PLATFORMFILE="$1"Pkg/"$1"PkgX64.dsc
 		BUILD_ROOT="${edk2DIR}/Build/${1}${PROCESSOR}/${TARGET}_${TARGET_TOOLS}"
	else
		PLATFORMFILE="$1"Pkg/"$1"Pkg.dsc
		BUILD_ROOT="${edk2DIR}/Build/${1}Pkg${PROCESSOR}/${TARGET}_${TARGET_TOOLS}"

	fi
	#set +x	
	FV_DIR="${BUILD_ROOT}"/FV
	#set -x
	if  [ "$1" == "OzEmu" ] || [ "$1" == "OzQemu" ] || [ "$1" == "Ovmf" ]; then
	    # use built qemu
    	#TARGET="DEBUG"

        if [ "$rebuild" == "yes" ]; then
			[ -f $OZ_QEMU_DIR/OVMF_CODE.fd ] && rm -rf $OZ_QEMU_DIR/OVMF_CODE.fd
			rm -rf Build
		fi	
		if [ ! -f $OZ_QEMU_DIR/OVMF_CODE.fd ]; then
			echoc "Build $1" green
			buildOz "$1"
			cp -R "${BUILD_ROOT}"/FV/OVMF_*.fd "${OZ_QEMU_DIR}"/
			#cp -R "${BUILD_ROOT}"/X64/Ozmosis.efi "${OZ_QEMU_DIR}"/EFI/Ozmosis$OzREV.efi
		fi
		if	[ "$QEMU_COMMAND" == "" ]; then
			case $PROCESSOR in
  			IA32)
    		if  [ -x `which qemu-system-i386` ]; then
      			QEMU_COMMAND=qemu-system-i386
    		elif  [ -x `which qemu-system-x86_64` ]; then
     			 QEMU_COMMAND=qemu-system-x86_64
    		elif  [ -x `which qemu` ]; then
      			QEMU_COMMAND=qemu
    		else
      		echo Unable to find QEMU for IA32 architecture!
      		exit 1
    		fi
    		;;
  			X64|IA32X64)
    		if [ -z "$QEMU_COMMAND" ]; then
      			#
      			# The user didn't set the QEMU_COMMAND variable.
      			#
      			QEMU_COMMAND=qemu-system-x86_64
    		fi
	    	;;
  			*)
    		echo Unsupported processor architecture: $PROCESSOR
    		echo Only IA32 or X64 is supported
    		exit 1
    		;;
			esac

		else
			QEMU_COMMAND=$(which qemu-system-"$archBit")
			QEMU_IMAGE=$(which qemu-img)
		fi
		echoc "Run $1 with " green -n; echoc "$QEMU_COMMAND" red
		runQemu "$1"
		#open ./serial.txt
	else
		echoc "Build $1" red
		buildOz	"$1"
	fi
	exit 1			
fi
[ ! -d "${edk2DIR}/Build/OzmosisPkg${PROCESSOR}/${BUILDTARGET}_${TARGET_TOOLS}"/FV/Ffs ] && buildOz
if [ $proc == X64 ]; then
	buildROM 2
else
	open "${edk2DIR}/Build/OzmosisPkg${PROCESSOR}/${BUILDTARGET}_${TARGET_TOOLS}"
fi
echo "value =$?"
exit $?
