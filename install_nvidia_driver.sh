#!/usr/bin/env bash

echo "Installing NVIDIA driver..."

# Function to check for NVIDIA GPU and driver
check_nvidia_driver() {
    if lspci | grep -i nvidia > /dev/null; then
        if nvidia-smi > /dev/null 2>&1; then
            echo "NVIDIA GPU and driver are properly installed."
            return 0
        else
            echo "NVIDIA GPU found, but driver is not installed or not working properly."
            return 1
        fi
    else
        echo "NVIDIA GPU not found."
        return 1
    fi
}

# Function to install NVIDIA Driver (CuDA 11.8)
install_nvidia_driver() {
    lspci | grep -i nvidia

    ### If you have previous installation remove it first. 
    sudo apt purge nvidia* -y
    sudo apt remove nvidia-* -y
    sudo rm /etc/apt/sources.list.d/cuda*
    sudo apt autoremove -y && sudo apt autoclean -y
    sudo rm -rf /usr/local/cuda*

    # system update
    sudo apt update && sudo apt upgrade -y

    # install other import packages
    sudo apt install g++ freeglut3-dev build-essential libx11-dev libxmu-dev libxi-dev libglu1-mesa libglu1-mesa-dev

    # first get the PPA repository driver
    sudo add-apt-repository ppa:graphics-drivers/ppa
    sudo apt update

    # find recommended driver versions for you
    ubuntu-drivers devices

    # install nvidia driver with dependencies
    sudo apt install libnvidia-common-515 libnvidia-gl-515 nvidia-driver-515 -y

    # verify that the following command works
    nvidia-smi

    sudo wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
    sudo mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
    sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/3bf863cc.pub
    sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/ /"

    # Update and upgrade
    sudo apt update && sudo apt upgrade -y

    # installing CUDA-11.8
    sudo apt install cuda-11-8 -y

    # setup your paths
    echo 'export PATH=/usr/local/cuda-11.8/bin:$PATH' >> ~/.bashrc
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda-11.8/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
    source ~/.bashrc
    sudo ldconfig

    # install cuDNN v11.8
    # First register here: https://developer.nvidia.com/developer-program/signup

    CUDNN_TAR_FILE="cudnn-linux-x86_64-8.7.0.84_cuda11-archive.tar.xz"
    sudo wget https://developer.download.nvidia.com/compute/redist/cudnn/v8.7.0/local_installers/11.8/cudnn-linux-x86_64-8.7.0.84_cuda11-archive.tar.xz
    sudo tar -xvf ${CUDNN_TAR_FILE}
    sudo mv cudnn-linux-x86_64-8.7.0.84_cuda11-archive cuda

    # copy the following files into the cuda toolkit directory.
    sudo cp -P cuda/include/cudnn.h /usr/local/cuda-11.8/include
    sudo cp -P cuda/lib/libcudnn* /usr/local/cuda-11.8/lib64/
    sudo chmod a+r /usr/local/cuda-11.8/lib64/libcudnn*

    # Finally, to verify the installation, check
    nvidia-smi
    nvcc -V

    # install Pytorch (an open source machine learning framework)
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
}
# Function to install NVIDIA Container Toolkit
if check_nvidia_driver; then
    install_nvidia_driver
fi