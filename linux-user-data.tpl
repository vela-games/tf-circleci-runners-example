#!/bin/bash
#

apt install -y zip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf ./aws

sudo mkdir -p /data
sudo mount -t nfs -o nfsvers=4.1 ${fsx_dns_name}:/fsx/ /data
mkdir -p /data/linux_ddc

export platform=linux/amd64
export base_url="https://circleci-binary-releases.s3.amazonaws.com/circleci-launch-agent"
export agent_version=$(curl "$${base_url}/release.txt")

# Set up runner directory
prefix=/opt/circleci
sudo mkdir -p "$prefix/workdir"

# Downloading launch agent
echo "Using CircleCI Launch Agent version $agent_version"
echo "Downloading and verifying CircleCI Launch Agent Binary"
base_url="https://circleci-binary-releases.s3.amazonaws.com/circleci-launch-agent"
curl -sSL "$base_url/$agent_version/checksums.txt" -o checksums.txt
file="$(grep -F "$platform" checksums.txt | cut -d ' ' -f 2 | sed 's/^.//')"
mkdir -p "$platform"
echo "Downloading CircleCI Launch Agent: $file"
curl --compressed -L "$base_url/$agent_version/$file" -o "$file"

# Verifying download
echo "Verifying CircleCI Launch Agent download"
grep "$file" checksums.txt | sha256sum --check && chmod +x "$file"; sudo cp "$file" "$prefix/circleci-launch-agent" || echo "Invalid checksum for CircleCI Launch Agent, please try download again"

instance_id=$(ec2metadata --instance-id)

cat <<EOF > /opt/circleci/launch-agent-config.yaml
api:
  auth_token: "${auth_token}"
runner:
  name: "$instance_id"
  mode: continuous
  command_prefix: ["sudo", "-niHu", "ubuntu", "--"]
  working_directory: /opt/circleci/workdir/%s
  cleanup_working_directory: true
EOF

chown root: /opt/circleci/launch-agent-config.yaml
chmod 600 /opt/circleci/launch-agent-config.yaml

mkdir -p /opt/circleci/workdir
chown -R ubuntu /opt/circleci/workdir

cat <<EOF > /opt/circleci/circleci.service
[Unit]
Description=CircleCI Runner
After=network.target
[Service]
ExecStart=/opt/circleci/circleci-launch-agent --config /opt/circleci/launch-agent-config.yaml
Restart=yes
User=root
NotifyAccess=exec
TimeoutStopSec=18300
[Install]
WantedBy = multi-user.target
EOF
systemctl enable /opt/circleci/circleci.service
systemctl start circleci.service