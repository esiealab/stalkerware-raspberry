#cd ~
if [ ! -d "android-runner-docker" ]; then
    git clone https://github.com/esiealab/android-runner-docker.git
    cd android-runner-docker
else
    cd android-runner-docker
    git pull
fi
