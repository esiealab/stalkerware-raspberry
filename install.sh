sudo apt-get update
sudo apt-get upgrade -y

sudo apt install -y git curl
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker esiealab
sudo rm get-docker.sh
