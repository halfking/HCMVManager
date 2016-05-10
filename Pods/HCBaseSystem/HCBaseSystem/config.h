//
//  config.h
//  HCBaseSystem
//
//  Created by HUANGXUTAO on 16/4/20.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#ifndef hcbasesystem_config_h
#define hcbasesystem_config_h

#import <hccoren/config_coren.h>

#define DEFAULT_UserSource      1   //用户来源  1 maiba 11 maibah5 2seen 21 seenh5
#define FILE_USER           @"user.hca"
#define FILE_SETTINGS       @"settings.hca"
#define FILE_CREDIT         @"usercredit.hca"
#define FILE_SUMMARY        @"summary.hca"

#define NT_USERINFOCHANGED      @"CMD_USERINFO_CHANGED" //用户信息发生改变
#define NT_USERIDCHANGED        @"CMD_USERID_CHANGED" //用户发生改变*****************
#define NT_USERSETTINGSCHANGED  @"CMD_USERSETTINGS_CHANGED"
#define NT_USER_LOGOUT          @"CMD_USER_LOGOUT" //用户退出*****************



#define DOMAIN_COVER_ROOT   @"img.seenvoice.com"
#define DOMAIN_HOME_ROOT    @"qhome.seenvoice.com"
//#define DOMAIN_MTVS_ROOT    @"7xjw4n.com2.z0.glb.qiniucdn.com"
#define DOMAIN_MTVS_ROOT    @"media.seenvoice.com"
#define DOMAIN_MUSIC_ROOT   @"music.seenvoice.com"
//#warning 记住把域名改回@"chat.seenvoice.com"
#define DOMAIN_CHAT_ROOT    @"chat.seenvoice.com"

#pragma mark - user info
#define PWD_SALT            @"#@(**WEF"
#define PWD_COMBINSALT_FORMAT   @"#@(**WEF%@"
#define NT_USERINFOCHANGED      @"CMD_USERINFO_CHANGED" //用户信息发生改变
#define NT_USERIDCHANGED        @"CMD_USERID_CHANGED" //用户发生改变*****************
#define NT_USERSETTINGSCHANGED  @"CMD_USERSETTINGS_CHANGED"
#define NT_USER_LOGOUT          @"CMD_USER_LOGOUT" //用户退出*****************
#define NT_CHANGELIKESTATUS     @"NT_CHANGELIKESTATUS"
#define NT_CHANGEFOLLOWSTATUS   @"NT_CHANGEFOLLOWSTATUS"
#define NOTICE_NAME_EDITING     @"notice_edit" ////通知名称
#define TRANFER_MESSAGEGROUP    @"transfer_Group"

#define NT_VIEW_TARBAT_DELMESAGECOUNT  @"TABAR_DELMESSAGECOUNT" ///关于控件监听宏
#define NT_VIEW_TARBAT_SETBILLCOUNT  @"TABAR_SETBILLCOUNT"
/// 关于tabbar消息中心Item的监听宏
#define TABBAR_DELMESSAGECOUNT @"TABBAR_DELMESSAGECOUNT_154"
//#define NOTICE_MEMBERCARDCHANGED      @"CHANGEMEMBERCARD"

#pragma mark - mtvupload and mtv op
#define NT_SHOWWAITING          @"CMD_SHOWWAITING"  //当底层联接有问题时，需要显示提示
#define NT_UPLOADCOMPLETED      @"CMD_UPLOADOK"     //上传完成时
#define NT_UPLOADBEGIN          @"NT_NEWFILEUPLOADING" //新文件开始上传时
#define NT_UPLOADSTATECHANGED   @"CMD_UPLOADSTATSCHANGED" //上传状态发生变化时
#define NT_UPLOADPROGRESSCHANGED @"CMD_UPLOADPROGRESSCHANGED"   //当进度发生变化时
#define NT_UPLOADAUDIOFAIL          @"NT_UPLOADAUDIOFAIL"
#define NT_UPLOADIMAGEFAIL          @"NT_UPLOADIMAGEFAIL"


#define NT_REMOVEMTV            @"NT_REMOVEMTV"             //删除MTV
#define NT_MTVIDCREATED         @"NT_MTVIDCREATED"
#define NT_CHANGEITEMSTATUS     @"NT_CHANGEITEMSTATUS"

#define NT_CACHEMTV                 @"NT_CACHEMTV"
#define NT_CACHEPROGRESS            @"NT_CACHEPROGRESS"
#define NT_CACHECLEARED             @"NT_CACHECLEARED"
#define NT_WILLENTERBACK            @"NT_GOBACKGROUND"  //应用切入到后台
//
//#pragma mark ---------推送------------
////推送
////测试是 ＃ifndef
//
//#ifndef __OPTIMIZE__
//#define GT_AppID                @"MQO8miiWr38bHafSCJ1FI9"
//#define GT_AppKey               @"aNiUCQZGeM8VnaOylGmKb7"
//#define GT_AppSecret            @"dYGSjWzImRAQI6w8Xe9iw"
//#define GT_MasterSecret         @"UieBBM6Isz8znf3nrHN5C5"
//#else
//#define GT_AppID                @"TY0nFypgIW66PXxyDyIye1"
//#define GT_AppKey               @"esms2TuFvN9uEOZMD6zJF5"
//#define GT_AppSecret            @"chOuU7BFtd64l8LdHUXzPA"
//#define GT_MasterSecret         @"inf9JWlLwU65solT5nD498"
//#endif
//
////消息及通讯
////环信
//#define HX_AppID                @"seenvoice#seen"
//#define HX_ClientID             @"YXA6lNh38D8xEeWgFQci37rDCQ"
//#define HX_Secret               @"YXA6MyIZYxK3KG5LJwipeFsG66lN6X0"
//
////推送消息类型
////用宏定义避免出错
//#define NOTI_NEWMESSAGE     @"_newmessage"
//#define NOTI_CLEARMESSAGE   @"_clearmessage"
//#define NOTI_REFRESHMESSAGE @"_refreshmessage"
//
//#define NOTI_ANNOUNCEMENT   @"_announcement"
//#define NOTI_SYSNOTI        @"_sysnoti"
//#define NOTI_PREVIEWMSG     @"_previewmsg"
//#define NOTI_COMMENT        @"_comment"
//#define NOTI_MUSICIANSONG   @"_musiciansong"
//#define NOTI_USERSONG       @"_usersong"
//#define NOTI_NEWPARTY       @"_newparty"
//#define NOTI_NEWLIKE        @"_newlike"
//#define NOTI_BEENSHARED     @"_beenshared"
//#define NOTI_CHATWITHUSER   @"_chatwithuser"
//#define NOTI_CHATINPARTY    @"_chatinparty"
//#define NOTI_CHATWITHCS     @"_chatwithcustomservice"
//
//#pragma mark ----------share -----------
////分享
//#define SHAREURLROOT                @"mbshare.seenvoice.com" //@"http://www.maibapp.com/share"
//#define SHAREURL                    @"http://mbshare.seenvoice.com/?key=%@&t=%d&sid=%ld&mid=%ld"    //分享链接
//#define SHAREURL_USER               @"http://mbshare.seenvoice.com/user?id=%ld"
//
//#define UmengAppkey                 @"55e01759e0f55ad7fd000d32" //@"5211818556240bc9ee01db2f"
//#define UMENGURL                    @"http://www.umeng.com/social"
////新浪微博
//#define SINA_APPKEY                 @"1848569834"
//#define SINA_APPSECKET              @"ae49a36c3bf4965e87035a9401fd441f"
//#define SINA_REDIRECTURL            @"http://sns.whalecloud.com/sina2/callback"
////腾讯微博
//#define Tencent_APPKEY              @"801508101"
//#define Tencent_APPSECKET           @"12452a82cc06164cfb8e57d15ec544e5"
////微信
//#define WCHAT_APPID                @"wx36d7396f30d1e01a"
//#define WCHAT_APPSECKET            @"2200e75142c303d2bb291d60a8184d96"
//
////qq
//#define QQ_APPID                 @"1104834406"
//#define QQ_APPSECKET             @"wYvlH3WIujT8GvGG"
//
////短信
//
////#define SMS_APPID               @"9e78382244f8"
////#define SMS_APPSCECRET          @"c455542580c3e38cbbc3ccbc5f3468bb"
//
////2.0版
//#define SMS_APPID               @"d81e1735dd60"
//#define SMS_APPSCECRET          @"7d063a1df398e42636a255d006f64747"
//
//
//
////TuSDK
//#ifndef __OPTIMIZE__
//#define TU_AppKey               @"d1c70916dfa93d25-02-m7elo1" // 测试版的key
//#else
//#define TU_AppKey               @"390e6ab0040eae65-02-m7elo1" // 正式版的key
////#define TU_AppKey               @"d1c70916dfa93d25-02-m7elo1" // 测试版的key
//#endif
////支付
//
////支付宝公钥
//#define AlipayPubKey       @"MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCnxj/9qwVfgoUh/y2W89L6BkRAFljhNhgPdyPuBV64bfQNN1PjbCzkIM6qRdKBoLPXmKKMiFYnkd6rAoprih3/PrQEB/VsW8OoM8fxn67UDYuyBTqA23MML9q1+ilIZwBC2AQ2UBVOrFXfFl75p6/B5KsiNG9zpgmLCUYuLkxpLQIDAQAB"
//
////合作身份者id，以2088开头的16位纯数字
//#define PartnerID @"2088311280763922"
////收款支付宝账号
//#define SellerID  @"pay@suixing.com"
////安全校验码（MD5）密钥，以数字和字母组成的32位字符
//#define MD5_KEY @"okaq7cmcc0ytukjep0sbrmqon7wer845"
//
////商户私钥，自助生成
//#define PartnerPrivKey @"MIICdwIBADANBgkqhkiG9w0BAQEFAASCAmEwggJdAgEAAoGBAM8qDFp2zHEtnVv9cDRX7m4oJhxDR8nocluGl5ADiIg7lQyK82IiSl0w4+jGk7paXodNiASUfGFn5ZF08Z+cec7yKn2dvyE6NlPHLaUUXu8tWOQDSHcngzBBopGpZ2p0ONXn/zPvptQHY05AVzxiFwO93MlV/JlBMpzJNNuoNMU5AgMBAAECgYBb1LzTIRQxG1JE48xoN45GoF98acqZ0wNWVQw8V4SfNyI0BCgtGRwzwSdWGSiFE+gRPCoONbAJEaAu4VL2OMu5R2uFeQzhs3wGchj0JXmVTUM/HLui/VwfuUfezggbP1bbbyYMmNVgJ9xtjvTbZBrSL1AITzIUfI6aTcK/G4o1PQJBAOjaJeQZ5/+9fpkbd0pPH6+MpmHcRTt5drDBtYlOGnXypLB0+tRvTXB9sG+3IQlSg8iAXohU7aphdVHqPdkaLvcCQQDjwitcLmdNuFMPQGnrUiriB86iN8q9xgVWZ6ha8B9PtK4jF3Tn+9Crq7MgxIhuk1xvjCoYGtjZ6VX0ko87NTFPAkEAjPjNadyZTYZu58juHqnqmACCFsshixFNX1PXUSpc8L2XIVGhLg24h3tA31GyiY9QQ4ocMVOhk75vJcm36gFlHwJBAKtear+mTqYk3aIpJkkgfxGpLCnUbuDRgSydPAiIihav7SKMQLNYPo8c1t/94GXKzQ9FWFrgwG9d6QXnzIuRH3MCQDcDLG3zDD7lYqM4ALMY0A4FJchOA2eVxx5XeSG0EhUeNAmYxjbGCBfyz3FyXGaG7FtADzw9HIWaTxqNp2mq9Fg="
//
//#define AlipayNoticeUrl @"http://pay.suixing.com/mobile/notify_url.aspx"
//
//
////微信支付
//#define ORDER_PAY_NOTIFICATION    @"PAY_RESULT"
//#define WCHAT_PARTNERKEY          @"e5c12fd7f52777ab2387bc3ace1ba408"   //微信公众平台商户模块生成的商户密钥
//#define WCHAT_PARTNERID           @"1222891501"
//#define WCHAT_APPKEY              @"uNRdf9QBYoANZV1Aqe8I6HxrwqtGpuHfL6SGN0vzpqwQGolbqYbCk897WZANVxK3EkhmwhPjSLJEijWkLWA2cmcpqRKwKH7hjT7xZt7dG1SBzfGvrQz3uxPpakf47pyi"
//#define WCHAT_NOTICEURL           @"http://pay.suixing.com/wx/notify_url.aspx"
//


#endif /* config_h */
