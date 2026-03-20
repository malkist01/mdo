#!/bin/sh

# Kernel Build Script by Mahiroo aka Yudaa

trap 'echo -e "\n\033[91m[!] Build dibatalkan oleh user.\033[0m"; tg_channelcast "⚠️ <b>Build kernel dibatalkan oleh user!</b>"; cleanup_files; exit 1' INT
exec > >(tee -a build.log) 2>&1

# ============================
# Setup
# ============================
PHONE="mido"
DEFCONFIG="mido_defconfig"
CLANG="$COMPILERDIR $(clang --version 2>&1 | head -n 1)"
ZIPNAME="Teletubies-$PHONE-$(date '+%Y%m%d-%H%M').zip"
BOT_TOKEN="7868194496:AAGY7WwRRbeCOPYOnczoCPh2psC43Q0F3JI"
CHAT_ID="-1002287610863"
COMPILERDIR="$(pwd)/../aosp-clang"
export KBUILD_BUILD_USER="malkist"
export KBUILD_BUILD_HOST="phone"

# ============================
# KernelSU
# ============================

wget https://raw.githubusercontent.com/rksuorg/kernel_patches/refs/heads/master/manual_hook/kernel-4.4_4.9.patch
patch -p1 < kernel-4.4_4.9.patch

echo "CONFIG_KSU=y" >> ./arch/arm64/configs/mido_defconfig
echo "CONFIG_KSU_MANUAL_HOOK=y" >> ./arch/arm64/configs/mido_defconfig
echo "ENABLE CONFIG_KPOBES!" >> ./arch/arm64/configs/mido_defconfig

curl -LSs https://raw.githubusercontent.com/ThRE-Team/KernelSU-Next/main/kernel/setup.sh | bash -s main

# ============================
# Variabel Telegram dan Device Info
# ============================
DEVICE="Redmi Note 4"
DISTRO="$(lsb_release -d | awk -F'\t' '{print $2}')"
PARSE_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
COMMIT_POINT="$(git rev-parse HEAD)"
CPU_NAME="$(lscpu | grep 'Model name' | awk -F': ' '{print $2}')"
PROCS="$(nproc --all)"
TOTAL_RAM_GB="$(free -g | awk '/^Mem:/{print $2}')"
DATE="$(date '+%Y-%m-%d %H:%M:%S')"
MESSAGE_ERROR="Error Build untuk $PHONE Dibatalkan!"
kernel="out/arch/arm64/boot/Image.gz-dtb"
dtb="out/arch/arm64/boot/dtb.img"
dtbo="out/arch/arm64/boot/dtbo.img"

# ============================
# Warna output
# ============================
cyan="\033[96m"
green="\033[92m"
red="\033[91m"
reset="\033[0m"

function install_dependencies() {
    echo -e "${cyan}==> Instalasi dependensi...${reset}"
    sudo apt update
    sudo apt install -y bc cpio flex bison aptitude git python-is-python3 tar aria2 perl wget curl lz4 libssl-dev device-tree-compiler
    sudo apt install -y zstd
}

function clang() {
if [ -d $COMPILERDIR ] ; then
echo -e " "
echo -e "\n$green[!] Lets's Build UwU...\033[0m \n"
else
echo -e " "
echo -e "\n$red[!] clang Dir Not Found!!!\033[0m \n"
sleep 2
echo -e "$green[+] Wait.. Cloning clang...\033[0m \n"
sleep 2
wget -q https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/4d2864f08ff2c290563fb903a5156e0504620bbe/clang-r563880c.tar.gz -O clang.tar.gz
    rm -rf $COMPILERDIR 
    mkdir $COMPILERDIR 
    tar -xvf clang.tar.gz -C $COMPILERDIR
    rm -rf clang.tar.gz
sleep 1
echo
echo -e "\n$green[!] Lets's Build UwU...\033[0m \n"
sleep 1
fi
}

function verify_toolchain_versions() {
    echo -e "${green}🔧 Clang  : $(${COMPILERDIR}/aosp-clang/bin/clang --version | head -n 1)${reset}"
}

function tg_channelcast() {
    local msg=""
    for POST in "$@"; do
        msg+="${POST}"$'\n'
    done
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d disable_web_page_preview=true \
        -d parse_mode=HTML \
        -d text="${msg}"
}

function send_initial_message() {
    tg_channelcast \
        "🚀 <b>Kernel Build Dimulai!</b>" \
        "📱 <b>Device :</b> <code>$DEVICE</code>" \
        "🛠️ <b>Compiler :</b> <code>$CLANG</code>" \
        "🌿 <b>Branch :</b> <code>$PARSE_BRANCH</code>" \
        "📝 <b>Commit :</b> $COMMIT_POINT" \
        "🧠 <b>CPU :</b> <code>$CPU_NAME ($PROCS cores)</code>" \
        "💾 <b>RAM :</b> <code>$TOTAL_RAM_GB GB</code>" \
        "📅 <b>Date :</b> <code>$DATE</code>" \
        "⌛️ Build berjalan..."
}

function send_success_message() {
    tg_channelcast \
        "✅ <b>Build Sukses!</b>" \
        "📱 <b>Device :</b> <code>$DEVICE</code>" \
        "📦 <b>ZIP:</b> <code>$ZIPNAME</code>" \
        "🕒 <b>Durasi:</b> <code>$((DIFF / 60)) menit $((DIFF % 60)) detik</code>"
}

function send_log() {
    curl -s -F "chat_id=${CHAT_ID}" -F "document=@log.txt" -F "caption=${MESSAGE_ERROR}" "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" > /dev/null
}

function clean() {
    echo -e "${red}[!] Clean...${reset}"
    rm -rf log.txt full-build.log out/full_defconfig "$ZIPNAME"
}

function clean_out_dir() {
    echo -e "${red}[!] Bersihkan out/...${reset}"
    [ -d out ] && rm -rf out/* || mkdir out
}

function cleanup_files() {
    echo -e "${red}[!] Cleanup akhir...${reset}"
    [ -f "$ZIPNAME" ] && rm -f "$ZIPNAME"
    [ -f log.txt ] && rm -f log.txt
    [ -f full-build.log ] && rm -f full-build.log
    [ -f out/full_defconfig ] && rm -f out/full_defconfig
}

function build_kernel() {
    export PATH="$COMPILERDIR/bin:$PATH"
    make -j$(nproc --all) O=out ARCH=arm64 ${DEFCONFIG}
    if [ $? -ne 0 ]
then
    echo -e "\n"
    echo -e "$red [!] BUILD FAILED \033[0m"
    echo -e "\n"
else
    echo -e "\n"
    echo -e "$green==================================\033[0m"
    echo -e "$green= [!] START BUILD ${DEFCONFIG}\033[0m"
    echo -e "$green==================================\033[0m"
    echo -e "\n"
fi

# Speed up build process
MAKE="./makeparallel"

# Build Start Here

   make -j$(nproc --all) \
    O=out \
    ARCH=arm64 \
    LLVM=1 \
    LLVM_IAS=1 \
    AR=llvm-ar \
    NM=llvm-nm \
    LD=ld.lld \
    OBJCOPY=llvm-objcopy \
    OBJDUMP=llvm-objdump \
    STRIP=llvm-strip \
    CC=clang \
    DTC_EXT=dtc \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- 2>&1 | tee full-build.log

    grep -Ei "(error|warning)" full-build.log > log.txt

    if grep -q "error:" full-build.log || [ ! -f out/arch/arm64/boot/Image ]; then
        echo -e "${red}[!] Build gagal${reset}"
        send_log
        cleanup_files
        return 1
    fi

    echo -e "${green}[+] Build sukses! Packing ZIP...${reset}"

    [ ! -d AnyKernel3 ] && git clone -q https://github.com/malkist01/AnyKernel3.git -b master AnyKernel3
    cp -f "$kernel" "$dtb" AnyKernel3/
    [ -f "$dtbo" ] && cp -f "$dtbo" AnyKernel3/
    cd AnyKernel3 || return 1
    zip -r9 "../$ZIPNAME" * -x .git README.md *placeholder
    cd .. && rm -rf AnyKernel3

    make O=out ARCH=arm64 savedefconfig
    mv out/defconfig out/full_defconfig

    BUILD_END=$(date +"%s")
    DIFF=$((BUILD_END - BUILD_START))

    echo -e "${green}🕒 Durasi Build : $((DIFF / 60)) menit $((DIFF % 60)) detik${reset}"
    upload_zip
    upload_fullbuild_log
    upload_defconfig
    send_success_message
    cleanup_files
}

function upload_zip() {
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" -F document=@"$ZIPNAME" -F chat_id="$CHAT_ID" > /dev/null
}

function upload_fullbuild_log() {
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" -F document=@"full-build.log" -F caption="Full Build Log - $ZIPNAME" -F chat_id="$CHAT_ID" > /dev/null
}

function upload_defconfig() {
    [ -f out/full_defconfig ] || return
    cp out/full_defconfig mido_defconfig
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" -F document=@"mido_defconfig" -F caption="Full Defconfig - $ZIPNAME" -F chat_id="$CHAT_ID" > /dev/null
    rm -f mido_defconfig
}

# ============================
# Eksekusi utama
# ============================
BUILD_START=$(date +"%s")
install_dependencies
clean
clang
send_initial_message
build_kernel
