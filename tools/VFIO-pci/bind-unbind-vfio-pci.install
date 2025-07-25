#!/bin/bash


## This script takes a iommu group as input and binds its members to the vfio-pci driver
## It cannot assign single pci addresses, as it is a safety concern without acs override precautions.


################## Functions ##########################

user_check() {
if [[ "$(whoami)" == root ]]; then
	return 0
else
	echo "Not Root. Aborting." >&2
	exit 1
fi
}


vfio_driver_loaded_check() {
if lsmod | grep -q vfio_pci; then
	return 0
else
	echo "Vfio-pci driver not loaded. Aborting." >&2
	exit 1
fi
}

op_syn_check() {
	local input="$1"

	if [[ "$input" == "--bind" || "$input" == "--unbind" || "$input" == "-b" || "$input" == "-u" ]]; then
		return 0
	else
		return 1
	fi
}

iommu_syn_check() {
	local input="$1"

	# Check if input is a valid integer (IOMMU group)
	if [[ "$input" =~ ^[0-9]+$ ]]; then
		return 0
	else
		return 1
	fi
}


function bind_vfio {
  echo "$1" > "/sys/bus/pci/devices/$1/driver/unbind"
  echo "$2" > /sys/bus/pci/drivers/vfio-pci/new_id
}

function unbind_vfio {
  echo "$2" > "/sys/bus/pci/drivers/vfio-pci/remove_id"
  echo 1 > "/sys/bus/pci/devices/$1/remove"
  echo 1 > "/sys/bus/pci/rescan"
}


#######################################################

user_check
vfio_driver_loaded_check

# uses a script to split a iommu group into its pci address members
if op_syn_check "$1"; then
	if iommu_syn_check "$2"; then

		devices=($(bash ./iommu_to_pci.sh "$2"))

		if [ ${#devices[@]} -eq 0 ]; then echo "No pci devices listed"; exit 1; fi

		declare -a devices_vd=()
		for ((i=0;i<${#devices[@]};i++)); do
		devices_vd[$i]="$(cat /sys/bus/pci/devices/${devices[$i]}/vendor) $(cat /sys/bus/pci/devices/${devices[$i]}/device)"
		done

		if [[ "$1" == "-b" || "$1" == "--bind" ]]; then

			for ((i=0;i<${#devices[@]};i++)); do
				echo "Binding ${devices[$i]} :"
				bind_vfio "${devices[$i]}" "${devices_vd[$i]}"
			done
			exit 0

		elif [[ "$1" == "-u" || "$1" == "--unbind" ]]; then

			for ((i=0;i<${#devices[@]};i++)); do
				echo "Unbinding ${devices[$i]} :"
		                unbind_vfio "${devices[$i]}" "${devices_vd[$i]}"
		        done
		        exit 0

		fi
	else
	echo "$2: not an iommu group" >&2
	exit 1
	fi
else
echo "$1: not a valid operation" >&2
exit 1
fi
