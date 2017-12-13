#!/bin/bash

APK_PRE_PATH=$1
ROOT_PATH=$2
APK_TEMP_DIR="temp"
VERSION_CODE=1
VERSION_NAME=1.0
CHANNELS=1
UNSIGNED_APK=""

# 找到对应apk文件
function findUnsignedApk() {
    for apk in $ `ls`
    do
        if [[ ${apk} =~ ".apk" ]];
        then
            UNSIGNED_APK=${apk}
            log $? "找到apk文件:"${apk}
            break
        fi
    done
}

# 解压apk包
function unzipUnsignedApk() {
    apktool d -o ./${APK_TEMP_DIR} ./${UNSIGNED_APK}
    log $? ${UNSIGNED_APK}"未签名apk解压完毕" "apk文件解压失败"
}

# 从AndroidManifest.xml中获取所有渠道
function getChannels() {
    CHANNELS_PATTERN='android:name="multi-channel".*'
    CHANNELS=`grep ${CHANNELS_PATTERN} ./${APK_TEMP_DIR}/AndroidManifest.xml | cut -d '"' -f 4`
    log $? "获取所有渠道完毕："${CHANNELS} "获取渠道失败"
}

# 获取版本信息
function getVersionInfo() {
    version_info=`cat ./version-info.txt`
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

# 遍历所有渠道进行渠道设置并打包签名
function setChannelNSignApk() {
    OLD_IFS="$IFS"
    IFS=";"
    arr=(${CHANNELS})
    IFS="$OLD_IFS"
    for channel in ${arr[*]}
    do
        setChannel ${channel}
        packageNSign ${channel}
    done
}

# 向AndroidManifest.xml文件写入channel
function setChannel() {
    channel=$1
    OLD_PATTERN="meta-.*\"channel\".*\""
    NEW_PATTERN="meta-data android:name=\"channel\" android:value=\"${channel}\""
    # 修改对应meta-data的值
    sed -i "" "s/${OLD_PATTERN}/${NEW_PATTERN}/" ./${APK_TEMP_DIR}/AndroidManifest.xml
    log $? "渠道号注入完毕："${channel} "渠道号注入失败"${channel}
}

# 打包签名
function packageNSign() {
    channel=$1
    unsignedApkName="unsigned-${channel}.apk"
    signedApkName="signed-${channel}-vn${VERSION_NAME}-vc${VERSION_CODE}.apk"
    # 打包
    apktool b -o ./${unsignedApkName} ./${APK_TEMP_DIR}
    log $? ${channel}"渠道打包完毕" ${channel}"渠道打包失败"
    # 签名
    jarsigner -sigalg MD5withRSA -digestalg SHA1 -keystore ${ROOT_PATH}/dog.keystore -storepass 111111 -signedjar ./${signedApkName} ./${unsignedApkName} dog
    log $? ${channel}"渠道签名完毕" ${channel}"渠道签名失败"
    # 删除未签名apk
    rm -f ./${unsignedApkName}
    log $? "删除${channel}渠道临时apk" "删除${channel}渠道临时apk失败"
}

# 删除临时文件
function deleteTempFiles() {
    # 删除解压的临时文件
    rm -rf ./${APK_TEMP_DIR}
    log $? "删除临时文件夹："${APK_TEMP_DIR} "临时文件夹删除失败"${APK_TEMP_DIR}
    # 删除未签名apk
    rm -f ./${UNSIGNED_APK}
    log $? "删除原始未签名apk"${UNSIGNED_APK} "原始apk文件删除失败"${UNSIGNED_APK}
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
findUnsignedApk
unzipUnsignedApk
getChannels
getVersionInfo
setChannelNSignApk
deleteTempFiles


