#!/bin/bash
echo "Running installation for environment: ${environment}"
# Update package index
sudo apt update

# Install Java (OpenJDK 11 is a common choice)
sudo apt install -y openjdk-11-jre

# Add Jenkins repository key
wget -O /tmp/jenkins.io-2023.key https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
sudo apt-key add /tmp/jenkins.io-2023.key
rm /tmp/jenkins.io-2023.key

# Add Jenkins repository to sources list
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list
sudo chown root:root /etc/apt/sources.list.d/jenkins.list
sudo chmod 644 /etc/apt/sources.list.d/jenkins.list

# Update package index again
sudo apt update

# Install Jenkins
sudo apt install -y jenkins

# Start and enable Jenkins service
sudo systemctl start jenkins
sudo systemctl enable jenkins
sudo systemctl status jenkins

# Optionally open Jenkins firewall port (if ufw is enabled)
if command -v ufw &> /dev/null; then
  sudo ufw allow 8080
  sudo ufw reload
  sudo ufw status
fi

echo "Jenkins installation complete!"
echo "You can access Jenkins at http://your_server_ip:8080"
echo "The initial administrator password can be found at /var/lib/jenkins/secrets/initialAdminPassword"