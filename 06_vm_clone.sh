#!/bin/bash

#author: Sen Du
#email: dusen@gennlife.com
#created: 2023-06-01 10:00:00
#updated: 2023-06-01 10:00:00

set -e 
source 00_env

#基于模版克隆虚拟机
function clone_vm() {
    cat config/vm_conf | grep -v "^#" | grep -v "^$" | while read PhysicalIp VirtualIp VirtualName VirtualCPU VirtualMem
    do 
        echo -e "$CSTART>>>>$PhysicalIp>$VirtualIp$CEND"
        # 1.验证物理机剩余内存，避免超分配
        total_mem=$(ssh -n $PhysicalIp "cat /proc/meminfo | grep 'MemTotal' | sed 's/[^0-9]//g'")
        allocated_mem=$(ssh -n $PhysicalIp "virsh list --name | xargs -l virsh dominfo | grep 'Max memory' | sed 's/[^0-9]//g' | paste -sd+ | bc")
        tobe_allocated_mem=$(( $VirtualMem * 1024 * 1024 ))
        safety_mem=$(( 4 * 1024 * 1024)) # 系统安全余量内存 4G
        remaining_mem=$(( $total_mem - $allocated_mem - $tobe_allocated_mem - $safety_mem)) # 剩余内存
        if [[ $remaining_mem -lt 0 ]]; then 
            echo "物理机内存空间不足，无法创建新虚拟机，请调整后再进行！！！"
            echo ">>物理机总内存(MB):[$(( $total_mem / 1024 ))] 已分配内存:[$(( $allocated_mem / 1024 ))] 剩余内存:[$(( $remaining_mem / 1024 ))] 需要分配的内存:[$(( $tobe_allocated_mem / 1024 ))]"
            echo ">>物理机总内存(GB):[$(( $total_mem / 1024 / 1024 ))] 已分配内存:[$(( $allocated_mem / 1024 / 1024 ))] 剩余内存:[$(( $remaining_mem / 1024 / 1024 ))] 需要分配的内存:[$(( $tobe_allocated_mem / 1024 / 1024 ))]"
            exit 128
        fi

        # 2.开始分配虚拟机
        ssh -n $PhysicalIp "virsh destroy $TEMPLATE_NAME" || true
        ssh -n $PhysicalIp "virt-clone --original $TEMPLATE_NAME --name $VirtualName --auto-clone"
    done
}

function main() {
    echo -e "$CSTART>06_vm_clone.sh$CEND"

    echo -e "$CSTART>>clone_vm$CEND"
    clone_vm
}

main