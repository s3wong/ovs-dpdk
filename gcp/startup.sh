#!/bin/bash

# ONE TIME

# Check and update package lists if needed
if ! dpkg -l build-essential &> /dev/null; then
  sudo apt-get update -y
  sudo apt-get install -yq build-essential ninja-build python3-pip \
    linux-headers-$(uname -r) pkg-config libnuma-dev
fi

# Check and install Python modules in a virtual environment (recommended)
if ! command -v pyelftools &> /dev/null; then
  python3 -m venv venv
  source venv/bin/activate
  pip install pyelftools meson
  deactivate
fi

# Check and download DPDK if needed
if ! test -f dpdk-23.11.2.tar.xz; then
  wget https://fast.dpdk.org/rel/dpdk-23.11.2.tar.xz
fi

# Check and extract DPDK if needed
if ! test -d dpdk-23.11.2; then
  tar xvf dpdk-23.11.2.tar.xz
fi

# Check and setup DPDK if needed
if ! test -f build/bin/dpdk-pmdtool; then
  cd dpdk-23.11.2
  meson setup -Dexamples=all build
  sudo ninja -C build install; sudo ldconfig
  cd ..
fi

# Setup VFIO no-IOMMU mode
if grep -q NOIOMMU /boot/config-$(uname -r); then
sudo bash -c 'echo 1 > /sys/module/vfio/parameters/enable_unsafe_noiommu_mode'
else
   echo "VFIO is not enabled.."
fi

# Setup hugepages.
sudo mkdir -p /mnt/huge
sudo mount -t hugetlbfs -o pagesize=1G none /mnt/huge
sudo bash -c 'echo 4 > /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages'
sudo bash -c 'echo 1024 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages'

