//
//  config.h
//  hccoren
//
//  Created by HUANGXUTAO on 16/4/20.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#ifndef config_h
#define config_h

#define USECOMPRESS         0       //是否使用文本压缩的模式
#define USEBINARYDATA       1       //SOCKET 是否使用二进制流压缩包的形式
#define TRACK_SOCKET        1

//图片质量枚举
enum _HCImgViewModel{
    HCImgViewModelAgent = 0,        //智能模式
    HCImgViewModelHighQuality = 1,  //高质量
    HCImgViewModelCustom = 2         //普通
};
typedef int HCImgViewModel;

#pragma mark - 网络相关
#define NET_CHANGED             @"CMD_NETWORKCHANGED"       //当网络发生变化时
#define NET_CMDTIMEOUT          @"NET_CMDTIMEOUT"           //命令超时，通知管理器的变化
#define NET_IPCHANGED           @"MSG_IPCHANGED"
#define NET_RECONNECT           @"CMD_RECONNECT"    //当重联服务器时，发送给前端的消息
#define NET_STOPHT              @"CMD_STOPHT"
#define NET_CONNECTED           @"NET_CONNECTED"
#define NET_CONNECTING          @"NET_CONNECTING"

#define NT_LOCATIONCHANGED      @"REFRESH_LOCATION"
#define NT_LOCATIONFAILURE      @"LOCATION_FAILURE"

#pragma mark - 一些常用初始值
#define CENTER_LNG          120.09
#define CENTER_LAT          30.14
#define DEFAULT_WEATHERCITY @"101210101"
#define CT_TESTNETWORK      @"http://www.baidu.com"
#define LOCATION_IDENTIFIER @"zh_CN"
//传给后台的关于当前缓存结果的MD5值的参数名
#define CT_RESULTMD5KEY     @"ResultMD5"


#pragma mark - 一些字串
#define ERROR_TIMEOUT       @"请求超时，请检查网络"
#define MSG_NETWORKERROR    @"哎呀！你的网络好像有点问题哦！"
#define MSG_ERROR           @"错误信息"
#define MSG_OPENLOCATIONERROR    @"打开定位服务失败，请检查是否正确开启了定位服务。"
#define EDIT_OK                     @"确定"
#define EDIT_CANCEL                 @"取消"
#define EDIT_RETRY                  @"重试"
#define EDIT_IKNOWN                 @"知道了"

#endif /* config_h */
