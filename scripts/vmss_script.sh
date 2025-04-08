apt update
apt install cifs-utils

#Mount Azure SMB File Share
# mkdir -p /mnt/azure
# mount -t cifs //${AZURE_STORAGE_ACCOUNT}.file.core.windows.net/${AZURE_FILE_SHARE} /mnt/azure -o vers=3.0,username=${AZURE_STORAGE_ACCOUNT},password=${AZURE_STORAGE_KEY},dir_mode=0777,file_mode=0777,serverino

wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

apt-get update -y

apt-get install jenkins -y

apt install fontconfig openjdk-17-jre -y

sudo systemctl enable jenkins
sudo systemctl start jenkins