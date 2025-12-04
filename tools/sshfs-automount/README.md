# **SSH Net-Share Service — Installation Guide**

## **What This Tool Does**

This package lets you automatically connect a folder from another computer or server using SSH.
Once installed, the connection happens on its own at startup, just like a normal drive.

You don’t need to mount anything manually — the systemd service will keep it running for you.

---

## **What You Need Before Starting**

Make sure you know:

1. **Remote Host** — the address of the server you want to connect to
2. **Remote User** — the username that can access the remote folder
3. **Remote Folder** — the directory you want to mount
4. **Local Folder** — the empty folder on your machine where the remote content will appear
5. **Password** for the remote user (this will be stored in a small protected file)

---

## **Installing the Service**

The package includes a script called:

```
build-service.sh
```

This script will automatically:

* set up the credentials file
* install the SSH mount script
* create a systemd service
* enable it at startup
* and start the service immediately

You only need to answer a few questions.

---

## **How to Run the Installer**

1. Open a terminal
2. Enter the folder where you downloaded the package
3. Run:

```
./build-service.sh
```

If the script isn’t executable yet, run:

```
chmod +x build-service.sh
```

---

## **What You Will Be Asked**

The installer will prompt you for:

### **1. Installation Folder**

Where you want the script to live.
Press **Enter** to use the current folder (recommended).

### **2. Service Name**

A simple name without spaces.
Examples:

* `netshare-backup`
* `ssh-storage`
* `remote-drive`

### **3. Service User**

Which system user should run the service.
Typically:

* `root` (if unsure)
* or a special service user you created

### **4. Connection Details**

The installer will ask for:

* remote host (`-h`)
* remote user (`-u`)
* local mount folder (`-m`)
* remote folder (`-r`)

Just type the values you already know.

### **5. Credentials File**

You can store the password in the same folder or somewhere else.
If the file does not exist:

* it will be automatically created
* it will open in a text editor
* you will fill in the password
* strict permissions will be applied for safety

### **6. Optional: Connection Test**

You can choose to run a quick check to make sure:

* the remote server is reachable
* the remote folder exists
* the password is correct

If the test fails, you can still choose to continue.

---

## **After Installation**

When the installer finishes, it will:

* create the service file
* reload systemd
* enable the service at boot
* start it immediately

You will see a final message like:

> **Service <name>.service created, enabled, and started.**

---

## **Checking That Everything Works**

You can check the service with:

```
sudo systemctl status <name>.service
```

If everything is correct, your local mount folder should now show the remote files.

---

## **Starting and Stopping the Service**

Start manually:

```
sudo systemctl start <name>.service
```

Stop:

```
sudo systemctl stop <name>.service
```

Restart:

```
sudo systemctl restart <name>.service
```

---

## **Where Your Password Is Stored**

The installer creates a tiny file containing:

```
password=your_password
```

This file has strict permissions so only the service can read it.

---


# **net-share-SSH Script**

## **Overview**

This script provides a robust and automated way to mount a remote directory over SSHFS.
It is designed for use in long-running services (e.g., systemd units) where stability, credential handling, and clean shutdowns are required.

The script supports:

* Credential-based SSHFS mounting via `sshpass`
* Automatic reconnection (`-o reconnect`)
* A testing mode to verify credentials and remote path availability
* Signal trapping for safe unmounting
* Blocking execution until the remote filesystem is unmounted

This makes it suitable for production systems, backup pipelines, or infrastructure automation where persistent SSHFS mounts are necessary.

---

## **Features**

### ✔ Automated Mounting

Mounts a remote directory at a local mountpoint using SSHFS with password-based authentication.

### ✔ Test Mode (`-t`)

Verifies:

* authentication validity
* remote directory existence
  without performing a mount.

### ✔ Graceful Cleanup

Handles `SIGINT`, `SIGTERM`, and service stops, ensuring:

* safe unmounting
* no stale mountpoints
* no orphaned sshfs processes

### ✔ PID Monitoring

The script monitors the SSHFS process and stays alive until the mount is terminated, making it suitable as a systemd service.

---

## **Usage**

```
./automount.sh [OPTIONS]
```

### **Required Options**

| Option | Argument          | Description                                                  |
| ------ | ----------------- | ------------------------------------------------------------ |
| `-r`   | `<remote-path>`   | Remote directory to mount (absolute path on the remote host) |
| `-m`   | `<mountpoint>`    | Local mountpoint directory (must already exist)              |
| `-u`   | `<user>`          | SSH username                                                 |
| `-p`   | `<password-file>` | File containing `password=<value>`                           |
| `-h`   | `<host>`          | Remote SSH host                                              |

### **Optional Flags**

| Flag | Description                                                             |
| ---- | ----------------------------------------------------------------------- |
| `-t` | Test the connection and credentials, then exit with the SSH return code |

---

## **Password File Format**

The file provided with `-p` must contain a line like:

```
password=yourSecretPassword
```

This avoids exposing the raw password in arguments or environment variables.

---

## **Examples**

### **1. Test-only Mode**

Verify the remote path and credentials:

```
./automount.sh -t -u backupuser -h 10.0.0.12 \
  -r /srv/data \
  -m /mnt/data \
  -p /etc/sshfs-passfile
```

### **2. Perform an Actual Mount**

```
./automount.sh -u backupuser -h 10.0.0.12 \
  -r /srv/data \
  -m /mnt/data \
  -p /etc/sshfs-passfile
```

The script mounts the remote directory and will remain running until the SSHFS process exits or the service is stopped.

---

## **Service Integration**

This script is intended for use inside a systemd unit, allowing:

* automatic startup on boot
* restart on failure
* clean termination via systemd signals

A service definition example will follow (based on the service builder script you mentioned).

---

## **Requirements**

* `sshfs`
* `sshpass`
* `fusermount`
* Bash 4+
* Local mountpoint must pre-exist
* Password file must be readable by the service user (preferably root)

---

## **Behavior on Exit**

When terminated, the script:

1. Runs `fusermount -u <mountpoint>`
2. Cleans internal state
3. Exits cleanly without leaving stale mounts

---

## **Notes**

* Ensure your system’s FUSE configuration allows non-interactive SSHFS mounting.
* Consider restricting network/firewall access for the SSH user used by this service.
* For higher security, consider migrating to key-based authentication (though this script currently expects a password).

