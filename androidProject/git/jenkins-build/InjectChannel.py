#!/usr/bin/python
# coding=utf-8
import zipfile
import sys
import os

def injectChannel(apk, channel):
    # 空文件 便于写入此空文件到apk包中作为channel文件
    src_empty_file = './empty_file'
    # 创建一个空文件（不存在则创建）
    f = open(src_empty_file, 'w')
    f.close()
    # 获取apk压缩流
    zipped = zipfile.ZipFile(apk, 'a', zipfile.ZIP_DEFLATED)
    # 初始化渠道信息
    empty_channel_file = "META-INF/channel_{channel_}".format(channel_ = channel)
    # 写入渠道信息
    zipped.write(src_empty_file, empty_channel_file)
    # 关闭zip流
    zipped.close()
    #删除空文件
    os.remove(src_empty_file)

injectChannel(sys.argv[1], sys.argv[2])