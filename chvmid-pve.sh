#!/bin/bash

echo "Here is list of all VMs on your server"
qm list

# Prompt the user to enter the VMID to search for
echo "Enter the VMID to change:"
read old_vmid

echo "---------------------ZVOLs------------------------"
zfs list -H -t volume -o name | grep $old_vmid
echo "---------------------ZVOLs------------------------"
echo "                                                  "

echo " These ZVOLs will be renamed, do you want to continue? Y / N"
echo "-------------------------------------------------------------"


read continue_script
if [[ "$continue_script" == [Yy] ]]; then

# Prompt the user to enter the new VMID
echo "Enter the new VMID:"
read new_vmid


    # Search for the VM config file with the same VMID
    vm_config_file=$(find /etc/pve/qemu-server/ -name "*$old_vmid.conf")

    # Check if a VM config file was found
    if [ -n "$vm_config_file" ]; then

      # Replace the VMID in the config file name
      new_vm_config_file=$(echo "$vm_config_file" | sed "s/$old_vmid/$new_vmid/g")

      # Rename the VM config file
      echo "Renaming $vm_config_file to $new_vm_config_file"
      mv "$vm_config_file" "$new_vm_config_file"

  # Search for the disk drive line containing the old ID
  DISK_DRIVE_LINE=$(grep -E "^virtio[0-9]+:.*${old_vmid}.*$" "$new_vm_config_file")

  # Check if a disk drive line with the old ID was found
  if [ -n "$DISK_DRIVE_LINE" ]; then

    # Replace the old ID with the new one in the disk drive line
    NEW_DISK_DRIVE_LINE=$(echo "$DISK_DRIVE_LINE" | sed "s/${old_vmid}/${new_vmid}/g")

    # Replace the old disk drive line with the new one in the configuration file
    sed -i "s#${DISK_DRIVE_LINE}#${NEW_DISK_DRIVE_LINE}#g" "$new_vm_config_file"

    echo "Changed disk ID in $new_vm_config_file"
    echo "Old disk drive line: $DISK_DRIVE_LINE"
    echo "New disk drive line: $NEW_DISK_DRIVE_LINE"

  else

    echo "No disk drives with ID $old_vmid found in $new_vm_config_file"

  fi
# Loop through all the ZFS zvols
for zvol in $(zfs list -H -t volume -o name); do

  # Check if the zvol name contains the old VMID
  if [[ "$zvol" == *"$old_vmid"* ]]; then

    # Replace the old VMID with the new VMID
    new_name=$(echo "$zvol" | sed "s/$old_vmid/$new_vmid/g")

    # Rename the zvol
    echo "Renaming $zvol to $new_name"
    zfs rename "$zvol" "$new_name"
  fi
 done

 else
    echo "Could not find VM config file for VMID $old_vmid"
 fi

else
    echo " Script Canceled, exiting"
    exit 0
fi
