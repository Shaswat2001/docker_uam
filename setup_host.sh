#!/usr/bin/env bash

# Installation Reference website: https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-22-04

echo "Checking for NVIDIA GPU and driver..."

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

# Function to install Docker
install_docker() {
    echo "Installing Docker on the Host Machine"
    sudo apt update
    sudo apt install apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    apt-cache policy docker-ce
    sudo apt install docker-ce
    sudo systemctl status docker

    echo "Docker Installation finished"
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
install_nvidia_container_toolkit() {
    echo "Setting up NVIDIA Container Toolkit, make sure you have installed NVIDIA Graphics Driver"
    sudo apt install -y curl
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
    && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    
    sed -i -e '/experimental/ s/^#//g' /etc/apt/sources.list.d/nvidia-container-toolkit.list

    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
}

# Check for NVIDIA driver and call the appropriate functions
if check_nvidia_driver; then
    install_docker
    install_nvidia_driver
    install_nvidia_container_toolkit
else
    install_docker
fi