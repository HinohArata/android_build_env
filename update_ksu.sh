#!/usr/bin/env bash
# declare constants
DIR=$(pwd)
repo="https://github.com/tiann/KernelSU"
repodir="KernelSU"

# initialize
rm -rf ${repodir}

# questionaries
echo -ne "\033[1;36m Provide path to kernel source: \033[0m"
read -r path
if [ -d "${path}/drivers/kernelsu" ]; then
        rm -rf ${path}/drivers/kernelsu
        cd ${path} || exit 1
        cd "${DIR}"
fi

# clone
git clone ${repo} ${repodir}
cd ${repodir}
git rev-list --count HEAD | tee version.txt
cd $DIR
version=$(expr 10000 + $(cat ${repodir}/version.txt) + 200)

# make deleted dir
mkdir "${path}"/drivers/kernelsu

# copy from cloned repo
cp -r "${repodir}"/kernel/* "${path}"/drivers/kernelsu

# git add and commit
cd "${path}" || exit 1
git add drivers/kernelsu/*
git commit -s -m "kernelsu: sync with repo
  from ${repo}/tree/main/kernel
 Referenced from https://kernelsu.org/guide/how-to-integrate-for-non-gki.html#integrate-with-kprobe
 and edited a bit to be compatible for CI builds"
echo ""

# add kernelsu nongki amd non kprobe related commit
echo -ne "Do you want to reeapply patch in kernelsu [y/n]: "
read -r kksu
if [[ "${kksu}" == "y" ]]; then
    echo "Applying" && echo ""
    wget https://raw.githubusercontent.com/HinohArata/android_build_env/main/ksu-reapply-kprobes.patch
    git apply ksu-reapply-kprobes.patch
    rm -rf ksu-reapply-kprobes.patch
    git add .
    git commit -s --author="HinohArata <mmgcntk@gmail.com>" -m "[REAPPLY] kernelsu: we're non GKI and non KPROBES build"
    echo "Patching Done"
elif [[ "${kksu}" == "n" ]]; then
    echo "Skipping" && echo ""
fi
echo ""

# add BACKPORT path umount frm 5.9
echo -ne "Do you want to add path umount to from 5.9 [y/n]: "
read -r umount
if [[ "${umount}" == "y" ]]; then
    echo "Applying" && echo ""
    wget https://raw.githubusercontent.com/HinohArata/android_build_env/main/ksu-umount.patch
    git apply ksu-umount.patch
    rm -rf ksu-umount.patch
    git add .
    git commit -s --author="HinohArata <mmgcntk@gmail.com>" -m "BACKPORT: path umount to from 5.9"
    echo "Patching Done"
elif [[ "${umount}" == "n" ]]; then
    echo "Skipping" && echo ""
fi
echo ""

# update kernelsu version
echo "Updating KSU version"
echo ""
sed -i "s/^#define KERNEL_SU_VERSION.*/#define KERNEL_SU_VERSION ($version)/g" drivers/kernelsu/ksu.h
sleep 3
echo "Updated"
git add drivers/kernelsu/*
git commit -s -m "kernelsu: hardcode update kernelsu version"
echo ""

# finalize
cd "${DIR}" || exit 1
echo -e "\n\033[1;36m Done! Synced with latest kernelsu \033[0m"
rm -rf ${repodir}

