#!/bin/bash

# Function to get PCI devices for a given IOMMU group
get_pci_devices() {
    local group=$1
    local iommu_path="/sys/kernel/iommu_groups/${group}/devices"

    # Check if the group exists
    if [[ ! -d "$iommu_path" ]]; then
        echo "Error: IOMMU group $group does not exist."
        exit 1
    fi

    # Read PCI addresses into an array
    local pci_devices=()
    while IFS= read -r device; do
        pci_devices+=("$device")
    done < <(ls -1 "$iommu_path")

    # Print the array (space separated list)
    echo "${pci_devices[@]}"
}

syn_check() {
    local input="$1"

    # Check if input is a valid integer (IOMMU group)
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        echo "iommu"
        return
    fi

    # Check if input is a valid PCI address format (e.g., 00:XX.X)
    if [[ "$input" =~ ^[0-9a-fA-F]{2}:[0-9a-fA-F]{2}\.[0-9]$ ]]; then
        echo "pci"
        return
    fi

    # Invalid input
    echo "invalid"
}

# Check for input argument
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <IOMMU Group Number>" >&2
    exit 1
fi

if [[ $(syn_check $1) == "iommu" ]]; then
	get_pci_devices "$1"
else
	echo "Not valid iommu group" >&2; echo "Usage: $0 <IOMMU Group Number>" >&2; exit 1
fi
