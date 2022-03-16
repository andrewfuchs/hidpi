#!/bin/bash

## - Forked by Andrew Fuchs (andfuchs@paypal.com)
##   from https://github.com/xzhih/one-key-hidpi
## 
## - Major changes
##   Hardened security and reliability
##   Simplified menus
##   Removed all cURL commands


currentDir="$(cd $(dirname -- $0) && pwd)"
langDisplay="Display"
langMonitors="Monitors"
langIndex="Index"
langVendorID="VendorID"
langProductID="ProductID"
langMonitorName="MonitorName"
langChooseDis="Choose the display"
langInputChoice="Enter your choice"
langEnterError="Enter error, bye"
langEnabled="Enabled, please reboot."
langDisabled="Disabled, restart takes effect"
langCustomRes="Enter the HIDPI resolution, separated by a space，like this: 1680x945 1600x900 1440x810"

langEnableOp1="(1) Enable HIDPI"
langEnableOp2="(2) Enable HIDPI (with EDID)"
langEnableOp3="(3) Revert HIDPI"

langChooseRes="resolution config"
langChooseResOp1="(1) 1920x1080 Display"
langChooseResOp2="(2) 1920x1080 Display (use 1424x802, fix underscaled after sleep)"
langChooseResOp3="(3) 1920x1200 Display"
langChooseResOp4="(4) 2560x1440 Display"
langChooseResOp5="(5) 3000x2000 Display"
langChooseResOpCustom="(6) Manual input resolution"

function get_edid() {
    local index=0
    local selection=0

    gDisplayInf=($(ioreg -lw0 | grep -i "IODisplayEDID" | sed -e "/[^<]*</s///" -e "s/\>//"))

    if [[ "${#gDisplayInf[@]}" -ge 2 ]]; then

        # Multi monitors detected. Choose target monitor.
        echo ""
        echo "                      "${langMonitors}"                      "
        echo "--------------------------------------------------------"
        echo "   "${langIndex}"   |   "${langVendorID}"   |   "${langProductID}"   |   "${langMonitorName}"   "
        echo "--------------------------------------------------------"

        # Show monitors.
        for display in "${gDisplayInf[@]}"; do
            let index++
            MonitorName=("$(echo ${display:190:24} | xxd -p -r)")
            VendorID=${display:16:4}
            ProductID=${display:22:2}${display:20:2}

            if [[ ${VendorID} == 0610 ]]; then
                MonitorName="Apple Display"
            fi

            if [[ ${VendorID} == 1e6d ]]; then
                MonitorName="LG Display"
            fi

            printf "    %d    |    ${VendorID}    |     ${ProductID}    |  ${MonitorName}\n" ${index}
        done

        echo "--------------------------------------------------------"

        # Let user make a selection.

        read -p "${langChooseDis}: " selection
        case $selection in
        [[:digit:]]*)
            # Lower selection (arrays start at zero).
            if ((selection < 1 || selection > index)); then
                echo "${langEnterError}"
                exit 1
            fi
            let selection-=1
            gMonitor=${gDisplayInf[$selection]}
            ;;

        *)
            echo "${langEnterError}"
            exit 1
            ;;
        esac
    else
        gMonitor=${gDisplayInf}
    fi

    EDID=${gMonitor}
    VendorID=$((0x${gMonitor:16:4}))
    ProductID=$((0x${gMonitor:22:2}${gMonitor:20:2}))
    Vid=($(printf '%x\n' ${VendorID}))
    Pid=($(printf '%x\n' ${ProductID}))
    # echo ${Vid}
    # echo ${Pid}
    # echo $EDID
}

# init
function init() {
    rm -rf ${currentDir}/tmp/
    mkdir -p ${currentDir}/tmp/

    targetDir="/Library/Displays/Contents/Resources/Overrides"

    if [[ ! -d "${targetDir}" ]]; then
        sudo mkdir -p "${targetDir}"
    fi

    get_edid
}

# main
function main() {
    sudo mkdir -p ${currentDir}/tmp/DisplayVendorID-${Vid}
    dpiFile=${currentDir}/tmp/DisplayVendorID-${Vid}/DisplayProductID-${Pid}
    sudo chmod -R 777 ${currentDir}/tmp/

    cat >"${dpiFile}" <<-\CCC
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>DisplayProductID</key>
            <integer>PID</integer>
        <key>DisplayVendorID</key>
            <integer>VID</integer>
        <key>IODisplayEDID</key>
            <data>EDid</data>
        <key>scale-resolutions</key>
            <array>
CCC

    echo ""
    echo "------------------------------------------"
    echo "|********** "${langChooseRes}" ***********|"
    echo "------------------------------------------"
    echo ${langChooseResOp1}
    echo ${langChooseResOp2}
    echo ${langChooseResOp3}
    echo ${langChooseResOp4}
    echo ${langChooseResOp5}
    echo ${langChooseResOpCustom}
    echo ""

    read -p "${langInputChoice}: " res
    case ${res} in
    1)
        create_res_1 1680x945 1440x810 1280x720 1024x576
        create_res_2 1280x800 1280x720 960x600 960x540 640x360
        create_res_3 840x472 800x450 720x405 640x360 576x324 512x288 420x234 400x225 320x180
        create_res_4 1680x945 1440x810 1280x720 1024x576 960x540 840x472 800x450 640x360
        ;;
    2)
        create_res_1 1680x945 1424x802 1280x720 1024x576
        create_res_2 1280x800 1280x720 960x600 960x540 640x360
        create_res_3 840x472 800x450 720x405 640x360 576x324 512x288 420x234 400x225 320x180
        create_res_4 1680x945 1440x810 1280x720 1024x576 960x540 840x472 800x450 640x360
        ;;
    3)
        create_res_1 1680x1050 1440x900 1280x800 1024x640
        create_res_2 1280x800 1280x720 960x600 960x540 640x360
        create_res_3 840x472 800x450 720x405 640x360 576x324 512x288 420x234 400x225 320x180
        create_res_4 1680x1050 1440x900 1280x800 1024x640 960x540 840x472 800x450 640x360
        ;;
    4)
        create_res_1 2560x1440 2048x1152 1920x1080 1760x990 1680x945 1440x810 1360x765 1280x720
        create_res_2 1360x765 1280x800 1280x720 1024x576 960x600 960x540 640x360
        create_res_3 960x540 840x472 800x450 720x405 640x360 576x324 512x288 420x234 400x225 320x180
        create_res_4 2048x1152 1920x1080 1680x945 1440x810 1280x720 1024x576 960x540 840x472 800x450 640x360
        ;;
    5)
        create_res_1 3000x2000 2880x1920 2250x1500 1920x1280 1680x1050 1440x900 1280x800 1024x640
        create_res_2 1280x800 1280x720 960x600 960x540 640x360
        create_res_3 840x472 800x450 720x405 640x360 576x324 512x288 420x234 400x225 320x180
        create_res_4 1920x1280 1680x1050 1440x900 1280x800 1024x640 960x540 840x472 800x450 640x360
        ;;
    6)
        custom_res
        create_res_2 1360x765 1280x800 1280x720 960x600 960x540 640x360
        create_res_3 840x472 800x450 720x405 640x360 576x324 512x288 420x234 400x225 320x180
        create_res_4 1680x945 1440x810 1280x720 1024x576 960x540 840x472 800x450 640x360
        ;;
    *)
        echo "${langEnterError}"
        exit 1
        ;;
    esac

    cat >>"${dpiFile}" <<-\FFF
            </array>
        <key>target-default-ppmm</key>
            <real>10.0699301</real>
    </dict>
</plist>
FFF

    /usr/bin/sed -i "" "s/VID/$VendorID/g" ${dpiFile}
    /usr/bin/sed -i "" "s/PID/$ProductID/g" ${dpiFile}
}

# end
function end() {
    sudo chown -R root:wheel ${currentDir}/tmp/
    sudo chmod -R 0755 ${currentDir}/tmp/
    sudo chmod 0644 ${currentDir}/tmp/DisplayVendorID-${Vid}/*
    sudo cp -r ${currentDir}/tmp/* ${targetDir}/
    sudo rm -rf ${currentDir}/tmp
    sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool YES
    echo "${langEnabled}"
}

# custom resolution
function custom_res() {
    echo "${langCustomRes}"
    read -p ":" res
    create_res ${res}
}

# create resolution
function create_res() {
    for res in $@; do
        width=$(echo ${res} | cut -d x -f 1)
        height=$(echo ${res} | cut -d x -f 2)
        hidpi=$(printf '%08x %08x' $((${width} * 2)) $((${height} * 2)) | xxd -r -p | base64)
        #
        cat <<OOO >>${dpiFile}
                <data>${hidpi:0:11}AAAAB</data>
                <data>${hidpi:0:11}AAAABACAAAA==</data>
OOO
    done
}

function create_res_1() {
    for res in $@; do
        width=$(echo ${res} | cut -d x -f 1)
        height=$(echo ${res} | cut -d x -f 2)
        hidpi=$(printf '%08x %08x' $((${width} * 2)) $((${height} * 2)) | xxd -r -p | base64)
        #
        cat <<OOO >>${dpiFile}
                <data>${hidpi:0:11}A</data>
OOO
    done
}

function create_res_2() {
    for res in $@; do
        width=$(echo ${res} | cut -d x -f 1)
        height=$(echo ${res} | cut -d x -f 2)
        hidpi=$(printf '%08x %08x' $((${width} * 2)) $((${height} * 2)) | xxd -r -p | base64)
        #
        cat <<OOO >>${dpiFile}
                <data>${hidpi:0:11}AAAABACAAAA==</data>
OOO
    done
}

function create_res_3() {
    for res in $@; do
        width=$(echo ${res} | cut -d x -f 1)
        height=$(echo ${res} | cut -d x -f 2)
        hidpi=$(printf '%08x %08x' $((${width} * 2)) $((${height} * 2)) | xxd -r -p | base64)
        #
        cat <<OOO >>${dpiFile}
                <data>${hidpi:0:11}AAAAB</data>
OOO
    done
}

function create_res_4() {
    for res in $@; do
        width=$(echo ${res} | cut -d x -f 1)
        height=$(echo ${res} | cut -d x -f 2)
        hidpi=$(printf '%08x %08x' $((${width} * 2)) $((${height} * 2)) | xxd -r -p | base64)
        #
        cat <<OOO >>${dpiFile}
                <data>${hidpi:0:11}AAAAJAKAAAA==</data>
OOO
    done
}

# enable
function enable_hidpi() {
    main
    sed -i "" "/.*IODisplayEDID/d" ${dpiFile}
    sed -i "" "/.*EDid/d" ${dpiFile}
    end
}

# patch
function enable_hidpi_with_patch() {
    main

    version=${EDID:38:2}
    basicparams=${EDID:40:2}
    checksum=${EDID:254:2}
    newchecksum=$(printf '%x' $((0x${checksum} + 0x${version} + 0x${basicparams} - 0x04 - 0x90)) | tail -c 2)
    newedid=${EDID:0:38}0490${EDID:42:6}e6${EDID:50:204}${newchecksum}
    EDid=$(printf ${newedid} | xxd -r -p | base64)

    /usr/bin/sed -i "" "s:EDid:${EDid}:g" ${dpiFile}
    end
}

# disable
function disable() {
    sudo rm -rf "${targetDir}"
    echo "${langDisabled}"
}

#
function start() {
    init
    echo ""
    echo ${langEnableOp1}
    echo ${langEnableOp2}
    echo ${langEnableOp3}
    echo ""

    #
    read -p "${langInputChoice} [1~3]: " input
    case ${input} in
    1)
        enable_hidpi
        ;;
    2)
        enable_hidpi_with_patch
        ;;
    3)
        disable
        ;;
    *)

        echo "${langEnterError}"
        exit 1
        ;;
    esac
}

start
