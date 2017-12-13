#!/bin/bash

APK_PRE_PATH=$1
ROOT_PATH=$2
APK_TEMP_DIR="temp"
VERSION_CODE=1
VERSION_NAME=1.0
CHANNELS=1
ORIGIN_APK=""

# 找到对应apk文件
function findOriginApk() {
    for apk in $ `ls`
    do
        if [[ ${apk} =~ ".apk" ]];
        then
            ORIGIN_APK=${apk}
            log $? "找到apk文件:"${apk}
            break
        fi
    done
}

# 获取所有渠道
function getChannels() {
    CHANNELS=`cat ${ROOT_PATH}/channels.txt`
    log $? "获取所有渠道完毕："${CHANNELS} "获取渠道失败"
}

# 获取版本信息
function getVersionInfo() {
    version_info=`cat ${ROOT_PATH}/version-info.txt`
    OLD_IFS="$IFS"
    IFS=";"
    arr=(${version_info})
    IFS="$OLD_IFS"
    for info in ${arr[*]}
    do
        if [[ ${info} =~ "versionCode" ]];
        then
            VERSION_CODE=`echo ${info} | cut -d ":" -f 2`
        elif [[ ${info} =~ "versionName" ]];
        then
            VERSION_NAME=`echo ${info} | cut -d ":" -f 2`
        fi
    done
    log $? "versionCode:${VERSION_CODE} versionName:${VERSION_NAME}" "获取版本信息异常"
}

# 渠道注入
function generateChannelApk() {
    OLD_IFS="$IFS"
    IFS=";"
    arr=(${CHANNELS})
    IFS="$OLD_IFS"
    for channel in ${arr[*]}
    do
        apkFileName=${channel}-vc${VERSION_CODE}-vn${VERSION_NAME}.apk
        copyFile ${ORIGIN_APK} ${apkFileName}
        injectChannel ${channel} ${apkFileName}
    done
}

# 复制apk文件
function copyFile() {
    srcFile=$1
    newFile=$2
    cp ${srcFile} ./${newFile}
    log $? "文件复制成功：${newFile}" "文件复制失败"
}

# 向AndroidManifest.xml文件写入channel
function injectChannel() {
    channel=$1
    apk=$2
    chmod +x ${ROOT_PATH}/InjectChannel.py
    python ${ROOT_PATH}/InjectChannel.py ${ORIGIN_APK} ${channel}
    log $? "渠道号注入成功："${channel} "渠道号注入失败"${channel}
}

# 删除临时文件
function deleteTempFiles() {
    # 删除解压的临时文件
    rm -rf ./${APK_TEMP_DIR}
    # 删除未签名apk
    rm -f ./${ORIGIN_APK}
    log $? "删除临时文件" "删除临时文件失败"
}

# 日志打印
function log() {
    status=$1
    successMsg=$2
    errorMsg=$3
    if [[ ${status} -eq 0 ]]
    then
        echo ${successMsg}
    else
        echo ${errorMsg}
        exit -1
    fi
}

cd ${APK_PRE_PATH}
findOriginApk
getChannels
getVersionInfo
generateChannelApk
deleteTempFiles


