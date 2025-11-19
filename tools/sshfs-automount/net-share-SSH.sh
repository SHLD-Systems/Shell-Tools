#!/bin/bash
EXITED=false
PID=''
REMOTE=''
MOUNTPOINT=''
PASSWORD=''
USER=''
HOST=''
TEST=false

if [[ $# -le 1 ]]; then
echo "Please Provide Useful Options."; exit 1
fi

while [[ $# -gt 0 ]]; do 
case $1 in
	"-t")
	shift
	TEST=true
	;;
	"-r")
	shift
	REMOTE="$1"
	shift
	;;
	"-m")
	shift
	MOUNTPOINT="$1"
	shift
	;;
	"-u")
	shift
	USER="$1"
	shift
	;;
	"-p")
	shift
	PASSWORD="$1"
	shift
	;;
	"-h")
	shift
	HOST="$1"
	shift
	;;
	*)
	echo "Option Unrecognized: $1"
	exit 1
esac
done

if [[ $REMOTE == '' || $MOUNTPOINT == '' || $USER == '' || $PASSWORD == '' || $HOST == ''  ]]; then
	echo "Options not specified. Aborting."; exit 1
fi


if [ ! -d "$MOUNTPOINT" ]; then
echo "Mount Folder $MOUNTPOINT  Not Found. Aborting." >&2; exit 1
fi
if [ ! -e "$PASSWORD" ]; then
echo "Password file doesn't exist."; exit 1
else
PASSWORD=$(cat "$PASSWORD" | grep password | awk -F '=' '{print $2}')
fi



# Function to clean up
cleanup() {
if $EXITED; then
    echo "Unmounting $MOUNTPOINT..."
    fusermount -u "$MOUNTPOINT"
    EXITED=true
    exit
fi
}

# Catch signals
trap cleanup SIGINT SIGTERM EXIT

# Test function, to see if connection succeeds and creds are good.
if $TEST; then
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USER@$HOST" "[ -d \"$REMOTE\" ]" > /dev/null 2>&1; rc=$?
exit $rc
fi


# Actual daemon logic
echo "$PASSWORD" | sshfs "${USER}"@"${HOST}":"${REMOTE}" "$MOUNTPOINT" -o password_stdin -o reconnect
PID=$(pgrep -f "sshfs.*${USER}@${HOST}:${REMOTE}.*${MOUNTPOINT}")

echo "PID:  $PID"

if [[ $PID != '' ]]; then
echo "sshfs Process on PID $PID"
else
echo "No sshfs PID Registered. Aborting"; exit 1
fi

# Keep script alive until unmount
while ps -p $PID > /dev/null; do
sleep 1
done
