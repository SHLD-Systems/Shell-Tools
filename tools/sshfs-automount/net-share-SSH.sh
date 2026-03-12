#!/bin/bash

# Vars definitions

EXITED=false
PORT=''
PID=''
REMOTE=''
MOUNTPOINT=''
PASSWORD=''
USER=''
HOST=''
TEST=false

# Util functions

sanitize_string() {
    local input="$1"
    # Remove " and '
    input="${input//\"/}"
    input="${input//\'/}"
    printf '%s' "$input"
}



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
	"-x")
	shift
	PASSWORD="$1"
	shift
	;;
	"-i")
	shift
	KEYFILE="$1"
	shift
	;;
	"-p")
	shift
	PORT="$1"
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

# Sanity checks and contitionals on arguments

MOUNTPOINT=$(sanitize_string "$MOUNTPOINT")
REMOTE=$(sanitize_string "$REMOTE")

## Check if local mountpoint is busy:
if mount | grep -q "$MOUNTPOINT"; then
	echo "Local Mountpoint: \"$MOUNTPOINT\" is busy. Aborting." >&2; exit 1
fi


if [ -n "$KEYFILE" ] && [ -n "$PASSWORD" ]; then
echo "Please specify only a password file (-x) or a key file (-i), not both." >&2; exit 1
fi


if [[ $REMOTE == '' || $MOUNTPOINT == '' || $USER == '' ||  $HOST == ''  ]]; then
	echo "Some critical options weren't specified. Aborting." >&2 ; exit 1
fi


if [ ! -d "$MOUNTPOINT" ]; then
	echo "Mount Folder $MOUNTPOINT not found. Aborting." >&2; exit 1
fi

if [ -n "$PASSWORD" ]; then
	PASSWORD=$(cat "$PASSWORD" | grep password | awk '{print substr($0, index($0,"=")+1)}')
fi

if [[ "$PORT" =~ [^0-9] ]]; then 	#Inverted match for pure numerical inputs
	echo "Port $PORT invalid. Abort." >&2; exit 1
fi


# Function to clean up
cleanup() {
if $EXITED; then
    echo "Unmounting $MOUNTPOINT..."
    fusermount -u "$MOUNTPOINT"				# Exit catch all, process is alive until needed.
    EXITED=true
    exit
fi
}

# Catch signals (attention to systemd signal types and timeouts)
trap cleanup SIGINT SIGTERM EXIT

if [ -n "$PASSWORD" ]; then

	echo "WARNING! Running insecure password method. Consider using keyfile option (-i)."
	# Test function, to see if connection succeeds and creds are good.
	if $TEST; then
		export SSHPASS="$PASSWORD"		#ssh password supplied to sshpass via envvar (-e switch)
		sshpass -e ssh -o StrictHostKeyChecking=no "$USER@$HOST" "[ -d \"$REMOTE\" ]" > /dev/null 2>&1; rc=$?
		exit $rc
	fi


	# Actual daemon logic
	echo "$PASSWORD" | sshfs -p "${PORT}" "${USER}"@"${HOST}":"${REMOTE}" "$MOUNTPOINT" -o password_stdin -o reconnect
	PID=$(pgrep -f "sshfs.*${USER}@${HOST}:${REMOTE}.*${MOUNTPOINT}")

	echo "PID:  $PID"			# I Use a pid to then loop every second to check if it's still there.

	if [[ $PID != '' ]]; then
		echo "sshfs Process on PID $PID"
	else
		echo "No sshfs PID Registered. Aborting"; exit 1
	fi

	# Keep script alive until unmount
	while ps -p "$PID" > /dev/null; do		# loop logic
		sleep 1
	done

elif [ -n "$KEYFILE" ]; then

	if [ ! -r "$KEYFILE" ]; then
		echo "Keyfile not readable or nonexistent. Aborting."; exit 1
	fi

	if $TEST; then
		ssh -i "$KEYFILE"  "$USER@$HOST" "[ -d \"$REMOTE\" ]" > /dev/null 2>&1; rc=$?
		exit $rc
	fi


	# Actual daemon logic
	sshfs -o IdentityFile="$KEYFILE" -p "${PORT}" "${USER}"@"${HOST}":"${REMOTE}" "$MOUNTPOINT" -o password_stdin -o reconnect
	PID=$(pgrep -f "sshfs.*${USER}@${HOST}:${REMOTE}.*${MOUNTPOINT}")

	echo "PID:  $PID"                       # I Use a pid to then loop every second to check if it's still there.

	if [[ "$PID" != '' ]]; then
		echo "sshfs Process on PID $PID"
	else
		echo "No sshfs PID Registered. Aborting"; exit 1
	fi

	# Keep script alive until unmount
	while ps -p "$PID" > /dev/null; do                # loop logic
		sleep 1
	done


fi

exit 0


# Loop ends if sshfs child proc is killed by another process. Ends script with 0 and doesn't restart.
