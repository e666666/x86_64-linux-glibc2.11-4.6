Original Dockerfile credit: https://github.com/csm10495/ubuntu_10_04_build

My attempt to automate building of "platform/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.11-4.6" from the AOSP.

Commands required: docker, git, patch, and diff

To replicate, run ./build.sh, the artifact will be in the same directory.
