#!/bin/sh
set -e
binary_name=xochitl
patch_name=${1:-rollback}
backup_file="${binary_name}.2011"
current_version="20191123105338"

trap onexit INT
function onexit(){
    cleanup
    echo "
If everything worked, you may replace the binary to make it permanent with the following:

    cp $binary_name.patched /usr/bin/$binary_name

To start the ui:
    systemctl start xochitl"
    exit 0
}
function cleanup(){
    echo "cleaning up"
    rm /tmp/*crash* 2> /dev/null || true
    rm -fr .cache/remarkable/xochitl/qmlcache/*
}

function rollback(){
    echo "TODO"
    exit
}

if [ ! $(</etc/version) -eq "$current_version" ]; then
	echo "Wrong version, works only on 2.0.1.1"
	exit 1
fi


if [ $patch_name == "rollback" ]; then
    rollback
fi

if [ -z "$SKIP_DOWNLOAD" ]; then
    wget "https://github.com/ddvk/remarkable-hacks/raw/master/patches/$patch_name" -O $patch_name || exit 1
fi

#make sure we keep the original
if [ ! -f $backup_file ]; then
    cp /usr/bin/$binary_name $backup_file
fi
cp $backup_file $binary_name

bspatch $binary_name $binary_name.patched $patch_name
chmod +x xochitl.patched
#clear the cache
systemctl stop xochitl
#it goes into  and endless reboot due to qml mismatch
systemctl stop remarkable-fail
 
cleanup
echo "Trying to start the patched version"
echo "You can play around, press CTRL-C when done"
./xochitl.patched > /dev/null 2>&1 || echo "It crashed?"
cleanup
