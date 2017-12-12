#!/bin/bash

APK_PATH=$1
ROOT_PATH=$2
APK_TEMP_DIR="temp"


function log() {
    status=$1
    success=$2
    error=$3
    if [[ ${status} -eq 0 ]]
    then
        echo ${success}
    else
        echo ${error}
        exit -1
    fi
}

# 向AndroidManifest.xml文件写入channel
function setChannel() {
    channel=$1
    OLD_PATTERN="meta-data android:name=\"channel\".*\""
    NEW_PATTERN="meta-data android:name=\"channel\" android:value=\"${channel}\""
    # 修改对应meta-data的值
    sed -i "" "s/${OLD_PATTERN}/${NEW_PATTERN}/" ./temp/AndroidManifest.xml
    log $? "渠道号注入完毕："${channel} "渠道号注入失败"${channel}
}

# 打包签名
function packageNSign() {
    channel=$1
    unsignedApkName=unsigned-${channel}.apk
    # 打包
    apktool b -o ./${unsignedApkName} ./${APK_TEMP_DIR}
    log $? ${channel}"渠道打包完毕" ${channel}"渠道打包失败"
    # 签名
    jarsigner -sigalg MD5withRSA -digestalg SHA1 -keystore ${ROOT_PATH}dog.keystore -storepass 111111 -signedjar ./${channel}-signed.apk ./${UNSIGNED_APK} dog
    log $? ${channel}"渠道签名完毕" ${channel}"渠道签名失败"
    # 删除未签名apk
    rm -f ./${unsignedApkName}
    log $? "删除${channel}渠道临时apk" "删除${channel}渠道临时apk失败"
}

# 找到对应apk文件
cd ${APK_PATH}
UNSIGNED_APK=""
for apk in $ `ls`
do
    if [[ ${apk} =~ ".apk" ]];
    then
        UNSIGNED_APK=${apk}
        log $? "找到apk文件"${apk} "没有找到对应的apk文件"
        break
    fi
done

# 解压apk包
apktool d -o ./${APK_TEMP_DIR} ./${UNSIGNED_APK}
log $? ${UNSIGNED_APK}"未签名apk解压完毕" "apk文件解压失败"

# 从AndroidManifest.xml中获取所有渠道
CHANNELS_PATTERN='android:name="multi-channel".*'
CHANNELS=`grep ${CHANNELS_PATTERN} ./${APK_TEMP_DIR}/AndroidManifest.xml | cut -d '"' -f 4`
log $? "获取所有渠道完毕："${CHANNELS} "获取渠道失败"

# 遍历所有渠道进行渠道设置并打包签名
OLD_IFS="$IFS"
IFS=";"
arr=(${CHANNELS})
IFS="$OLD_IFS"
for channel in ${arr[*]}
do
    setChannel ${channel}
    packageNSign ${channel}
done

# 删除解压的临时文件
rm -rf ./${APK_TEMP_DIR}
log $? "删除临时文件夹："${APK_TEMP_DIR} "临时文件夹删除失败"${APK_TEMP_DIR}
# 删除未签名apk
rm -f ./${UNSIGNED_APK}
log $? "删除原始未签名apk"${UNSIGNED_APK} "原始apk文件删除失败"${UNSIGNED_APK}
