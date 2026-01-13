# douglasbaumgart@douglass-mbp tests % cat dal03-inventory.sh 
HOST_RANGE="ubuntu@dal03-sgpu-[105,182,187]"



pdsh -R ssh -w "${HOST_RANGE}" "sudo dmidecode -t system|egrep 'Manufacturer|Product Name'" | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo dmidecode -t baseboard|egrep 'Manufacturer|Product Name|Ver'" | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo dmidecode -t chassis|egrep 'Manufacturer|Product Name|Ver'" | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo lscpu|egrep 'Thread|Socket|Core|Model name'" | dshbak -c 
pdsh -R ssh -w "${HOST_RANGE}" "sudo dmidecode -t memory | egrep 'Volatile Size: |Type: |Manufacturer: |Speed: ' | grep -v Non | grep -v Error | sort|uniq -c|egrep -v 'NO DIMM|Type: Unknown|Configured'" | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo lspci | grep -c 'LSI PCIe Switch'" | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo lspci -n -d ::108 | awk '{ print \$1 }' | paste -s" | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo lspci -n -d ::302 | awk '{ print \$1 }' | paste -s" | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo dmesg | grep PEX | awk -F: '{print \$2 \$3}'" | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo nvme list|grep -c nvme" | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo nvme list|grep \"^/\"|cut -c110-118|sort|uniq -c" | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo nvme list|grep nvme|awk '{ print \$1 }'|while read drive; do echo -n "\$drive - "; sudo smartctl -a \$drive|grep overall-health; done" | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo lspci | grep -ic nvidia" | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo nvidia-smi -L|cut -d\( -f1 " | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo modinfo \`find /usr/lib/modules -name nvidia.ko\` | grep ^version" | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo nvidia-smi -q | grep VBIOS" | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo lspci | grep -i mellanox" | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo dmidecode -s bios-version" | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo ofed_info -s" | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo lspci -vv -d ::200 | grep -P \"[0-9a-f]{2}:[0-9a-f]{2}\.[0-9a-f]|LnkSta:\"" | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo lspci -vv -d ::302 | grep -P \"[0-9a-f]{2}:[0-9a-f]{2}\.[0-9a-f]|LnkSta:\"" | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo lspci -vv -d ::108 | grep -P \"[0-9a-f]{2}:[0-9a-f]{2}\.[0-9a-f]|LnkSta:\"" | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo nvidia-smi nvlink -s | grep Link | awk '{ print $3 }' |sort -k 2n |uniq -c" | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo ibstat | egrep 'mlx|ate'" | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo ibv_devinfo | egrep 'mlx|fw'" | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo nvidia-smi topo -m | md5sum" | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo ipmitool chassis status" | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo ipmitool sensor | wc -l" | dshbak -c
pdsh -R ssh -w "${HOST_RANGE}" "sudo ipmitool sensor | awk -F\"|\" '{print $4}' | grep -c ok" | dshbak -c