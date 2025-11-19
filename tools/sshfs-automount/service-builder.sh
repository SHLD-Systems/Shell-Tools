#!/usr/bin/env bash

set -e

start_folder="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
svc_install_dir="/etc/systemd/system"

echo "This utility will build a systemd service file for your SSH Net‑Share script."
read -p "Enter install folder (enter for current folder): " install_folder
read -p "Enter service name (without .service): " svc_name
read -p "Enter service user: " svc_user
read -p "Enter remote host argument (-h …): " arg_host
read -p "Enter remote user argument (-u …): " arg_user
read -p "Enter local “-m” path: " arg_m
read -p "Enter remote mount “-r” path: " arg_r
read -p "Enter creds file path (enter for same as installation dir): " arg_p


# Checking presence of executable
if [ ! -e "${start_folder}/net-share-SSH.sh" ]; then
echo "Critical: ${start_folder}/net-share-SSH.sh  not found. File is expected to exist. Aborting."
exit 1
fi


# Install Folder Configuration, moving executable script to new folder if provided.
if [ -z $install_folder ]; then
	install_folder="$start_folder"
elif [ ! -d $install_folder ]; then
	echo "Folder $install_folder not found, cannot install executables here. Aborting."
	exit 1
else
	cp "${start_folder}/net-share-SSH.sh" "${install_folder}"
fi

# Checking credential file settings. This file can be put in the same folder of binaries, or kept separately.
# First checks if the variable was set, otherwise it sets arg_p to be in the same as the install folder.
# Second checks if the cred file exists already for some reason. IF not, it let's the user create it via the template.
# In all these cases, the file is set to strict permissions for reading.

if [ -z $arg_p ]; then
arg_p="${install_folder}/creds.txt"
fi

if [ ! -e $arg_p ]; then

	if [ ! -d $(dirname "$arg_p") ]; then
	echo "Path to creds file non-existent, creating file in install folder instead."
	arg_p="${install_folder}/creds.txt"
	fi

	echo "Creating Credentials File..."
	> "${arg_p}"
	echo "#Add your Network Share Secret Here" >> "${arg_p}"
	echo "password=" >> "${arg_p}"
	nano "${arg_p}"
	chmod u=r,go-rwx "${arg_p}"
else
	chmod u=r,go-rwx "${arg_p}"
fi

# Construct ExecStart command
exec_cmd=("${install_folder}/net-share-SSH.sh" -u "${arg_user}" -h "${arg_host}" -m "${arg_m}" -r "${arg_r}" -p "${arg_p}")
svc_file="${svc_install_dir}/${svc_name}.service"

read -p "Perform ssh connectivity check for validity of credentials and presence of available storage? y/n  " cond_test

if [[ "$cond_test" == "y" || "$cond_test" == "Y" || "$cond_test" == "yes" ]]; then 

	echo "Testing given credentials with sample connection..."
	echo "Testing existence of remote path..."

	if ${exec_cmd[@]} -t; then
		echo "Connection Test Passed."
	else
		echo "Connection Test not passed."
		read -p "Continue Creating Service Anyways? y/n " cond
		if [[ "$cond" == "n" || "$cond" == "no" || "$cond" == "N" ]]; then
			echo "Exiting."
			exit 0
		fi

	fi

fi


echo "Creating service file at ${svc_file} …"

cat <<EOF | sudo tee "${svc_file}"
[Unit]
Description=Net‑Share SSH service for ${arg_user}@${arg_host}
After=network.target

[Service]
Type=simple
User=${svc_user}
# WorkingDirectory could be set if script needs a specific CWD
ExecStart=${exec_cmd[@]}
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF

echo "Setting permissions …"
sudo chmod 644 "${svc_file}"

read -p "Create Service Symlink in Install Folder for Quick Access? y/n " cond_test
if [[ "$cond_test" == "y" || "$cond_test" == "Y" || "$cond_test" == "yes" ]]; then
	ln -s "$svc_file" "$install_folder" && echo "Symlink Created." || echo "Symlink Couldn't Be Created."
fi

echo "Reloading systemd daemon …"
sudo systemctl daemon-reload

echo "Enabling service to start at boot …"
sudo systemctl enable "${svc_name}.service"

echo "Starting service now …"
sudo systemctl start "${svc_name}.service"

echo "Service ${svc_name}.service created, enabled, and started."
echo "Check status with: sudo systemctl status ${svc_name}.service"
