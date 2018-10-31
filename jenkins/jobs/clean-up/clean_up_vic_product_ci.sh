#!/bin/bash
export GOVC_URL='Administrator@vsphere.local:Alfred!23@10.158.214.107'
export GOVC_INSECURE=true

TAR_FILE=vic_v1.4.3.tar.gz
wget --unlink -nv -O ${TAR_FILE} https://storage.googleapis.com/vic-engine-releases/${TAR_FILE}
mkdir bin && tar xvzf ${TAR_FILE} -C bin/ --strip 1
cd bin

#Clean up all VCH
govc find /dc1 -type m -runtime.powerState poweredOff -name VCH-* | xargs basename | xargs -I {} govc vm.power -on {}
govc find /dc1 -type m -runtime.powerState poweredOn -name VCH-* | xargs basename | xargs -I {} ./vic-machine-linux delete -f --target 10.158.214.107 --user 'administrator@vsphere.local' --password 'Alfred!23' --name {}

#Clean up all VIC appliance
# govc find /dc1 -type m -runtime.powerState poweredOn -name OVA-* | xargs basename | xargs -I {} govc vm.power -off -force {}
govc find /dc1 -type m -name OVA-* | xargs basename | xargs -I {} govc vm.destroy {}
