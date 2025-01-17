#!/bin/bash
export ANDROID_BUILD_TOP="$(pwd)"

#fetch submodules
git submodule init && git submodule update

#clean the out directory
rm -rf ${ANDROID_BUILD_TOP}/out

# Create a log file and print start time
echo -e "Build started at: $(date)\n" | tee logs.txt

# OEM Variables
export TARGET_BUILD_VARIANT="user"
export CHIPSET_NAME="sm6225"
export MODEL="a05s"
export TARGET_PRODUCT=gki
export TARGET_BOARD_PLATFORM=gki
export MERGE_CONFIG="${ANDROID_BUILD_TOP}/kernel_platform/msm-kernel/scripts/kconfig/merge_config.sh"

#init ksu
cd kernel_platform/common && git submodule init && git submodule update && cd ${ANDROID_BUILD_TOP}

#localversion
if [ -z "$BUILD_KERNEL_VERSION" ]; then
    export BUILD_KERNEL_VERSION="dev"
fi

#setting up localversion
echo -e "CONFIG_LOCALVERSION_AUTO=n\nCONFIG_LOCALVERSION=\"-ravindu644-${BUILD_KERNEL_VERSION}\"\n" > "${ANDROID_BUILD_TOP}/custom_defconfigs/custom_defconfig"

# Build paths
export ANDROID_PRODUCT_OUT=${ANDROID_BUILD_TOP}/out/target/product/${MODEL}
export OUT_DIR=${ANDROID_BUILD_TOP}/out/msm-${CHIPSET_NAME}-${CHIPSET_NAME}-${TARGET_PRODUCT}

# For Lcd (techpack) driver build
export KBUILD_EXTRA_SYMBOLS="${ANDROID_BUILD_TOP}/out/vendor/qcom/opensource/mmrm-driver/Module.symvers \
		${ANDROID_BUILD_TOP}/out/vendor/qcom/opensource/mm-drivers/hw_fence/Module.symvers \
		${ANDROID_BUILD_TOP}/out/vendor/qcom/opensource/mm-drivers/sync_fence/Module.symvers \
		${ANDROID_BUILD_TOP}/out/vendor/qcom/opensource/mm-drivers/msm_ext_display/Module.symvers \
		${ANDROID_BUILD_TOP}/out/vendor/qcom/opensource/securemsm-kernel/Module.symvers \
"

# For Audio (techpack) driver build
export MODNAME=audio_dlkm

export KBUILD_EXT_MODULES="../vendor/qcom/opensource/mm-drivers/msm_ext_display \
  ../vendor/qcom/opensource/mm-drivers/sync_fence \
  ../vendor/qcom/opensource/mm-drivers/hw_fence \
  ../vendor/qcom/opensource/mmrm-driver \
  ../vendor/qcom/opensource/securemsm-kernel \
  ../vendor/qcom/opensource/display-drivers/msm \
  ../vendor/qcom/opensource/audio-kernel \
  ../vendor/qcom/opensource/camera-kernel \
  "

# Downloading Toolchain
if [ ! -d "${ANDROID_BUILD_TOP}/kernel_platform/prebuilts" ]; then
    echo -e "[+] Downloading Toolchain...\n"
    curl -LO --progress-bar https://github.com/ravindu644/a05s_stock/releases/download/toolchain/toolchain.zip
    curl -LO --progress-bar https://github.com/ravindu644/a05s_stock/releases/download/toolchain/toolchain.z01
    zip -s- toolchain.zip -O combined.zip && unzip combined.zip && rm combined.zip
    tar -xvf toolchain.tar.gz
    mv prebuilts "${ANDROID_BUILD_TOP}/kernel_platform" && chmod +x -R "${ANDROID_BUILD_TOP}/kernel_platform/prebuilts"
    rm toolchain*
    sudo apt install rsync > /dev/null 2>&1
else
    echo -e "[+] Toolchain already installed...\n"  
fi

# requirements
if [ ! -f .requirements ]; then
    echo -e "[+] Installing Requirements...\n"
    sudo apt update -y ; sudo apt install default-jdk git-core gnupg flex bison gperf build-essential zip curl libc6-dev libncurses5-dev x11proto-core-dev libx11-dev libreadline6-dev libgl1-mesa-glx libgl1-mesa-dev python3 make sudo gcc g++ bc grep tofrodos python3-markdown libxml2-utils xsltproc zlib1g-dev libncurses5 python-is-python3 libc6-dev libtinfo5 ncurses-dev make python2 cpio kmod openssl libelf-dev dwarves libssl-dev libelf-dev -y
    echo 1 > .requirements
else
    echo -e "[+] Requirements already installed...\n"      
fi

#build dir
if [ ! -d "${ANDROID_BUILD_TOP}/build" ]; then
    mkdir -p "${ANDROID_BUILD_TOP}/build"
else
    rm -rf "${ANDROID_BUILD_TOP}/build" && mkdir -p "${ANDROID_BUILD_TOP}/build"
fi

#main execution
export SKIP_MRPROPER=1
RECOMPILE_KERNEL=1 ${ANDROID_BUILD_TOP}/kernel_platform/build/android/prepare_vendor.sh sec ${TARGET_PRODUCT} && cp ${ANDROID_BUILD_TOP}/out/msm-sm6225-sm6225-gki/dist/boot.img "${ANDROID_BUILD_TOP}/build"

#build odin flashable tar
build_tar(){
    cd ${ANDROID_BUILD_TOP}/build
    tar -cvf "KernelSU-Next-SM-M145F-${BUILD_KERNEL_VERSION}.tar" boot.img && rm boot.img
    echo -e "\n[i] Build Finished..!\n" && cd ${ANDROID_BUILD_TOP}
} 

build_tar
echo "[+] Build finished at: $(date)"
