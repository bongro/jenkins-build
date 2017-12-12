#!/bin/bash

ROOT_PATH=$1
APK_TEMP_DIR="temp"

# 找到对应apk文件
cd ./androidProject/git/jenkins-build/app/build/outputs/apk/release
UNSIGNED_APK=""
for apk in $ `ls`
do
    if [[ ${apk} =~ ".apk" ]];
    then
        UNSIGNED_APK=${apk}
        break
    fi
done

# 解压apk包
apktool d -o ./${APK_TEMP_DIR} ./${UNSIGNED_APK}

# 从AndroidManifest.xml中获取所有渠道
CHANNELS_PATTERN='android:name="multi-channel".*'
CHANNELS=`grep ${CHANNELS_PATTERN} ./${APK_TEMP_DIR}/AndroidManifest.xml | cut -d '"' -f 4`

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
# 删除未签名apk
rm -f ./${UNSIGNED_APK}

# 向AndroidManifest.xml文件写入channel
function setChannel() {
    channel=$1
    OLD_PATTERN="meta-data android:name=\"channel\".*\""
    NEW_PATTERN="meta-data android:name=\"channel\" android:value=\"${channel}\""
    # 修改对应meta-data的值
    sed -i "" "s/${OLD_PATTERN}/${NEW_PATTERN}/" ./temp/AndroidManifest.xml
}

# 打包签名
function packageNSign() {
    channel=$1
    unsignedApkName=unsigned-${channel}.apk
    # 打包
    apktool b -o ./${unsignedApkName} ./${APK_TEMP_DIR}
    # 签名
    jarsigner -sigalg MD5withRSA -digestalg SHA1 -keystore ${ROOT_PATH}dog.keystore -storepass 111111 -signedjar ./apk-release-999-signed.apk ./${UNSIGNED_APK} dog
    # 删除未签名apk
    rm -f ./${unsignedApkName}
}