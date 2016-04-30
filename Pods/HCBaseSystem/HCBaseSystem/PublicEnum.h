//
//  PublicEnum.h
//  HotelCloud
//
//  Created by XUTAO HUANG on 13-4-2.
//  Copyright (c) 2013年 Suixing. All rights reserved.
//

#ifdef IS_MANAGERCONSOLE
#include <sys/types.h>
#endif

#ifndef MEDIA_TYPE
#define MEDIA_TYPE
enum _MediaItemInQueueType{
    
    MediaItemTypeIMAGE,
    MediaItemTypeVIDEO,
    MediaItemTypeTRANS,
    MediaItemTypeAUDIO
    
} ;
typedef u_int8_t MediaItemInQueueType;

#endif
#ifndef   CUTINOUT_MODE
#define   CUTINOUT_MODE
//转场模式类型
enum _CutInOutMode {
    CutInOutModeFadeIn = 0,
    CutInOutModeFadeOut = 1
};
typedef u_int8_t  CutInOutMode;
#endif // CUTINOUT_MODE

#ifndef   USERID_TYPE
#define   USERID_TYPE
//enum _USERID_TYPE {
//    EMAIL           =   0,  //email
//    MOBILE          =   1,  //mobile
//    THIRDLOGIN      =   2   //第三方登录，如QQ、微信等
//};
//typedef u_int8_t  USERID_TYPE;
//推送消息类型
enum _PushMessageType{
    BeginWatchingMTV  = 0,//开始观看视频
    StopWatching = 1,//停止观看视频
    NewComments = 2,//添加评论
    OpenDirectBroadcast = 3,//打开直播
    CloseDirectBroadcast = 4,//关闭直播
    AddConcern = 5,//添加关注
    RemoveConcern = 6,//取消关注。
};
typedef u_int16_t  PushMessageType;
//
////推送消息类型
//enum _PushMessageType{
//    BeginWatchingMTV  = 0,//开始观看视频
//    StopWatching = 1,//停止观看视频
//    NewComments = 2,//添加评论
//    OpenDirectBroadcast = 3,//打开直播
//    CloseDirectBroadcast = 4,//关闭直播
//    AddConcern = 5,//添加关注
//    RemoveConcern = 6,//取消关注。
//};
//typedef u_int16_t  PushMessageType;

//第三方登录类型
enum _HCLoginType{
    HCLoginTypeEmail = 0,
    HCLoginTypeMobile = 1,
    HCLoginTypeSinaWeibo = 2,
    HCLoginTypeTaobao = 3,
    HCLoginTypeQQ = 4,
    HCLoginTypeTencent = 5,
    HCLoginTypeWeixin = 6,
    HCLoginTypeSession = 7,  //朋友圈
    HCLoginTypeQZone = 8,//分享到QQ空间。
    HCLoginTypeRenren = 9//人人
//    HCLoginTypeLinker = 10//链接
};
typedef u_int16_t  HCLoginType;
#endif // USERID_TYPE


#pragma mark - _HCObjectType
enum _HCObjectType{
    HCObjectTypeNotSet = 0,
    HCObjectTypeScene = 1,//景点
    HCObjectTypeRegion = 2,//地点
    HCObjectTypeHotel = 3,//酒店
    HCObjectTypeHotelRoom = 11, //房间
    HCObjectTypePicture = 302,//图片
    HCObjectTypeShop = 30,//LiveHouse
    HCObjectTypeShopFun = 32,//shopfun
    HCObjectTypeMTV = 40,//mtv
    HCObjectTypeMusic = 41,//music
    HCObjectTypeSample = 42, //Sample & 发现-我要翻唱
    HCObjectTypeCoverStory = 43, //发现-封面故事
    HCObjectTypeMusicTest = 44, // 发现-音乐小测试
    HCObjectTypeMTVList = 45, // 发现-作品欣赏
    HCObjectTypeGoods = 50, //商品
    HCObjectTypeActivity = 55,//活动
    HCObjectTypeVip            = 58, //会员
    HCObjectTypeBill = 51,//订单
    HCObjectTypeArticle = 301,//文章，新闻
    HCObjecttypeGuestBook = 320,//留言
    HCObjectTypeShare = 326, //分享
    HCObjectTypeComment = 332,//点评
    HCObjectTypeQuestion = 323, //问题
    HCObjectTypeAD = 325,//广告
    HCObjectTypeUser = 500, //用户
    HCObjectTypeAlbum = 313,//相册
    HCObjectTypeMap = 450,   //地图
    HCObjectTypeService = 451,////服务
    
    HCObjectTypeSystem = 501 //系统
    
};
typedef u_int16_t HCObjectType;

#ifndef   DOMAIN_TYPE_DEF
#define   DOMAIN_TYPE_DEF
enum _DOMAIN_TYPE {
    DOMAIN_HOME         = 0,
    DOMAIN_COVER        = 1,
    DOMAIN_MTVS         = 2,
    DOMAIN_MUSIC        = 3,
    DOMAIN_CHAT         = 4
};
typedef u_int8_t DOMAIN_TYPE;
#endif // DOMAIN_TYPE_DEF



#ifndef   NSMUSIC_TYPE
#define   NSMUSIC_TYPE
enum _MUSIC_TYPE {
    MP3         = 0,
    WAV              = 1
};
typedef u_int8_t MUSIC_TYPE;
#endif // NSMUSIC_TYPE

#ifndef   NSMUSIC_SOURCE
#define   NSMUSIC_SOURCE
enum _MUSIC_SOURCE {
    SAMPLE         = 0,
    UPLOAD         = 1
};
typedef u_int8_t MUSIC_SOURCE;
#endif // MUSIC_SOURCE

#ifndef   NSVIDEO_COMPLETEDPHARSE
#define   NSVIDEO_COMPLETEDPHARSE
enum _VIDEO_COMPLETEDPHARSE {
    NONE         = 0,
    MERGE         = 1
};
typedef u_int8_t VIDEO_COMPLETEDPHARSE;
#endif // VIDEO_COMPLETEDPHARSE



#ifndef PublicEnum_h
#define PublicEnum_h


//分享权限枚举
enum _HCShareRights{
    HCShareRightsPrivate = 0,     //私有
    HCShareRightsFriends = 1,     //好友
    HCShareRightsFuns = 2,   //粉丝
    HCShareRightsPublic = 3  //完全公开
};
typedef u_int8_t HCShareRights;

#pragma mark - _HCQuestionType
///发布的帖子的类型
enum _QuestionType{
    QuestionAlbum = 313,//专辑相册
    QuestionGuestBook = 320,//留言
    QuestionBookReply = 321,//留言回复
    QuestionQA = 323, //Question 问题
    QuestionShare  = 326,//share 分享
    QuestionUserComment = 332,//userComment点评
    QuestionGone = 400,//去过的评价
    QuestionWantgo = 401,//想去
    QuestionConcern = 402,//关注
    QuestionFAV = 403,//收藏
    QuestionRequest = 404//请求
    //HCQuestionTypeMap = 450   //地图
};
typedef u_int16_t QuestionType;

///***************************************************************/
////图片质量枚举
//enum _HCImgViewModel{
//    HCImgViewModelAgent = 0,        //智能模式
//    HCImgViewModelHighQuality = 1,  //高质量
//    HCImgViewModelCustom = 2         //普通
//};
//typedef u_int8_t HCImgViewModel;

//图片质量枚举
enum _HCBother{
    HCOpen = 0,        //开启
    HCSettime = 1,     //某一时间
    HCClose = 2        //关闭
};
typedef u_int8_t HCBother;
/***************************************************************/

//好友关系
enum _HCRelationType{
    HCRelationUnkown = -2,//未知
    HCRelationNone  =-1,         //无
    HCRelationConcern = 0,      //关注
    HCRelationFriends = 1,      //好友
    HCRelationBeConcerned = 2   //被关注
};
typedef int8_t HCRelationType;

//用户在线状态
enum _HCUserState {
    HCUserStateOffline = 0,     //离线
    HCUserStateOnline = 1,      //在线
    HCUserStateBusy = 2         //忙碌
};
typedef u_int8_t HCUserState;

enum _HCSexy {
    HCSexyUnkown = 0,
    HCSexyMan = 1,
    HCSexyWoman = 2
};
typedef u_int8_t HCSexy;




enum _HCShareType{
    HCShareWeibo =1,
    HCShareWeixin = 2,
    HCSharePengyouquan = 3,
    HCShareQQZone =4,
};
typedef u_int16_t HCShareType;
//权限
enum _HCRightsGrantType
{
    HCRightsGrant=1,
    HCRightsRevoke =2,
    HCRightsHichrence = 0
};
typedef u_int8_t HCRightsGrantType;



//服务开放级别
enum _HCServiceArea
{
    HCServiceAreaInSide = 2,//店内
    HCServiceAreaOutSide = 1//店外
};
typedef u_int8_t HCServiceArea;

//ShopFun规则中的类型
enum _HCShopFunRuleType
{
    HCShopFunRuleIntroduce=0,//介绍
    HCShopFunRuleBooking=1,//预订
    HCShopFunRulePackages=2,//套餐
    HCShopFunRuleGoods=3//商品
};
typedef u_int8_t HCShopFunRuleType;

//消息分组类型枚举
enum _HCMessageGroupType {
    HCMessageGroupOther          = 0, ///其他
    HCMessageGroupOrg            = 1, ///酒店2User
    HCMessageGroupFriend       = 2, ///好友 User2User
    HCMessageGroupNews        = 3, ///资讯
    HCMessageGroupSystem          = 4, ///系统通知
    HCMessageGroupShop          =5 ///店中店
};
typedef u_int8_t HCMessageGroupType;
enum _HCUserMessageType
{
    HCUserMessageTypeNAN = 0,
    HCUserMessageTypeSiteMessage = 1, ///站内消息
    HCUserMessageTypeGuestbook = 2, ///留言板
    HCUserMessageTypeNotice        = 3, ///提醒消息（通知）
    HCUserMessageTypeBill      =4 ///订单通知
};
typedef u_int16_t HCUserMessageType;
//用户消息分类
enum _HCContentType
{
    HCContentTypeNAN = 0,
    HCContentTypeSiteMessage = 1, //站内消息
    HCContentTypeGuestbook = 2, //留言板
    HCContentTypeNotice        = 3, //提醒消息
    HCContentTypeNews           = 4, //新闻
    HCContentTypeQuestion      = 5, //提问
    HCContentTypeComment        = 6, //评论
    HCContentTypeShare          = 7, //分享
//    HCContentTypeMap            = 8, //地图
    HCContentTypeMap            = 450,  //地图
    HCContentTypeImage          = 302, //图片
    HCContentTypeActivity       = 55, //活动
    HCContentTypeVip            = 58, //会员
    //    HCContentTypeProduct        = 9, //产品
    HCContentTypeProduct        = 50, //产品
    //    HCContentTypeBill           = 10,  //订单
    HCContentTypeBill           = 51,  //订单
    HCContentTypeRequest        =11,//加好友请求
    HCContentTypeRightsRequest  =12, //特权授权请求
    HCContentTypeHotelIntroduct =13 //酒店介绍
};
typedef u_int16_t HCContentType;


enum _HCPrepareType {
    HCPrepareTypeNone = 0,                  //不需要预付
    HCPrepareTypeFull = 1,                  //全额预付
    HCPrepareTypeFullEighteen = 2,          //18：00之后全额预付
    HCPrepareTypeFullTwentyOne = 3,         //21：00之后全额预付
    HCPrepareTypeFullFirstDay = 4,          //预付首日房费
    HCPrepareTypePayment = 5                //预付定金
};
typedef u_int8_t HCPrepareType;

#pragma mark - _TS_New_DoneType
///通知类型
enum _TS_New_DoneType {
    /// 新商品订单
    TS_New_GoodsBill=10102,
    /// 新订房订单
    TS_New_RoomBill=10103,
    /// 新消息
    TS_New_Message=10104,
    /// 入住请求
    TS_New_CheckIn=10105,
    /// 退房请求
    TS_New_CheckOut=10106,
    /// 新酒店评价
    TS_New_EvaHotel=10107,
    /// 新商品评价
    TS_New_EvaGoods=10108,
    /// 新意见反馈
    TS_New_FeedBack=10109,
    ///新转移的用户
    TS_New_TurnUser=10110,
    
    TS_BILL_CHANGED = 10200,    //订单状态变化，非完成态
    TS_BILL_CANCELLED = 10201,  //订单审核后，被用户取消，需要确认
    TS_BILL_COMPLETED = 10202,   //订单完成
    TS_BILL_FULLCOUNT   = 10299,    //所有未完成订单数
    TS_BILL_CHECKED = 10210,        //订单Checked
    TS_BILL_READYCOMMENT = 10211,   //订单可评价
    TS_SET_MESSAGECOUNT = 10300, //直接设置消息数
    TS_SHOPCART_DEC = 10400,
    TS_SHOPCART_SET = 10410,
    
    TS_BILLCOUNT_SET = 20100, //后期添加的设置变更的订单数
    TS_COMMENTCOUNT_SET = 20200, //变更的评论数
    TS_SYNC_GROUPCOUNT = 20300 //同步减少Group中的新消息数
};
typedef u_int32_t TS_New_DoneType;

#pragma mark - _HCOrderQueryState
//查询订单总体状态
enum _HCOrderQueryState {
    HCOrderQueryStateToComment = 8,     //待评价
    HCOrderQueryStateDoing     = 1,     //处理中
    HCOrderQueryStateDone      = 2,     //已经完成
    HCOrderQueryStateNotCheck  = 0,     //未审核 未提交
    HCOrderQueryStateCancel    = -1,    //取消
    HCOrderQueryStateAll       = -2,    //表示“－1，0，1，2”
    HCOrderQueryPay            = 4,     //待付款
    HCOrderQueryReFund         = 16     //退款
};
typedef u_int8_t HCOrderQueryState;

////配送方式
enum _HCOrderDeliverType{
    HCOrderDeliverTypeNone = 0,
    HCOrderDeliverTypeHotel = 1,    //指定消费点
    HCOrderDeliverTypeRoom  = 2,    //送到客房
    HCOrderDeliverTypeLobby = 4,    //大堂自取
    HCOrderDeliverTypeExpressdelivery = 8   /////快递邮寄
};
typedef u_int8_t HCOrderDeliverType;

////配送时间
enum _HCOrderDeliveryTime{
    HCOrderDeliveryNow = 0,   ////立即送货
    HCOrderDeliveryToday = 1,   //////今天
    HCOrderDeliveryTomorrow = 2,  /////明天
    HCOrderDeliveryErworben = 3,   /////后天
    HCOrderDeliveryAnother = -1
};
typedef u_int8_t HCOrderDeliveryTime;

#pragma mark - _HCOrderState
//订单实际详细状态
enum _HCOrderState {
    HCOrderStateReadyCheck      = 10,          //以提交，待审核....////酒店端  待审核未审核 待确认
//    HCOrderStatePaid            = 11,        //已支付
    HCOrderStateChecked         = 30,          //已经审核..../////酒店端  已审核
    HCOrderStatePay             = 31,          // 待支付
    HCOrderStatePaid            = 32,          //已支付
    HCOrderStatePaid_Checked    = 33,          //已支付，已确认
    HCOrderStateCancel          = 35,          //用户取消，需要审核
    HCOrderStateWaitGoods       = 40,          //订单等待发货 = 40
    HCOrderStateDeliver         = 50,          //已配送.//酒店端  已发货  待收货
    HCOrderStateReceived        = 51,          //已收货
    HCOrderStateRefund          = 80,          // 订单退款 = 80Ω
    
    HCOrderStateCancelConfirm   = 901,         //取消确认
    HCOrderStateDeleteByUser    = 910,         //用户删除,但订单已经执行完成
    HCOrderStateClosed          = 950,         //已关闭
    HCOrderStateCompleted       = 900,         //完成.....////酒店端  已完成
    HCOrderStateCommented       = 999 ,        //已经评论
    
    HCOrderStateReFunding       = 902,   //退款中//*******
    HCOrderStateReFundFail      = 903,   //退款失败
    HCOrderStateReFundSuccess   = 904,   //退款成功
    HCOrderStateReFundActivist  = 905    //维权中
    
};
typedef u_int16_t HCOrderState;

enum _HCOrderOperate{
    HCOrderOperateSubmit = 1,
    HCOrderOperateCancel = 2,
    HCOrderOperateDelete = 3,
    HCOrderOperatePaid = 4,
    HCOrderOperateShow = 5,
    HCOrderOperateComment = 6,
    HCOrderOperateComplete=7
    
};
typedef u_int16_t HCOrderOperate;

//订单实际详细状态
enum _HCHotWordsOrderType {
    HCHotWordsOrderTypeDefault = 0,   ///默认
    HCHotWordsOrderTypeDay = 1,         //日热度
    HCHotWordsOrderTypeWeek = 2,            //周
    HCHotWordsOrderTypeMonth = 3           //月
};
typedef u_int8_t HCHotWordsOrderType;
#pragma mark - _HCTransferType
enum _HCTransferType
{
    HCTransferTypePerson = 1,       //人
    HCTransferTypeObject =2,        //对象
    HCTransferTypeTrip = 4,         //行程
    HCTransferTypeFriends = 8,      //好友
    HCTransferTypeConcern = 16,     //粉丝
    HCTransferTypeMe =32            //我自己
};
typedef u_int16_t HCTransferType;
enum _HCDataDirection
{
    HCDataDirectionPrev = 0,  //往后，找旧数据
    HCDataDirectionNext = 1  //往前，找新数据
};
typedef u_int8_t HCDataDirection;
enum _HCHotelListType
{
    HCHotelListTypeConcern = 0,  //关注酒店
    HCHotelListTypeCredit = 1  //住过
};
typedef u_int8_t HCHotelListType;


enum _HCDataPosition
{
    HCDataAtHeader = 1,
    HCDataAtTail = 2,
    HCDataAtIDOrder = 3,
    HCDataAtCurrent = 0
};
typedef u_int8_t HCDataPosition; //数据位于的位置

enum _HCScheduleType
{
    HCScheduleReady = 0, //关于，用于一开始浏览
    HCScheduleWelcome = 1,
    HCScheduleCheckIn = 2,
    HCScheduleImportDeals = 3,
    HCScheduleLuncher =4,
    HCScheduleBreakfast = 5,
    HCScheduleServices = 6
};
typedef u_int8_t HCScheduleType; //服务的介绍位置，阶段什么的。

#pragma mark - _HCServiceModule ShopFun
//000
//1 无产品 2 列表 3 瀑布流
//0 小图 1 大图 2 多图
//0 展示 1 预订 2 预约 3 快速预订

enum _HCServiceModule
{
    HCOnlyWordsService =19,// 100,//19,        //只有词条显示,类似于词条
    
    HCLobbyService = 24,//200,//24,            //列表    展示           如景点1
    HCReserveSmallPicService=18,//202,//18,    //列表    预约型  小图   如洗衣服务1
    HCReserveBigPicService=26,//212,//26,      //列表    预约型  大图   如洗衣服务2
    HCNativeProductService = 17,//201,//17,    //列表    预订   小图     如土特产
    HCRestService = 16,//221,//16,             //列表    预订   大图     如大堂服务
    HCMedicineService   =  20,//203,// 20,     //列表    快速预订        如常用药品
    
    HCReserveWaterfallService=27,//312,//27,   //瀑布流   预约型  大图   如洗衣服务2
    HCRoomMealService = 14,//301,//14,         //瀑布流   预订      如客房送餐
    HCBreakFastService = 11,//300,//11,        //瀑布流   浏览不预订 如早餐,景点
    
    
    
    HCWashingService = 23,          //列表    预约型          如洗衣服务
    HCChineseFoodService = 12,      //中餐
    HCWestFoodService = 13,         //西餐
    HCLobbyBarService = 15,         //大堂吧
    HCFastReserveWaterfallService=28,   //瀑布流    快速预约型  大图   如洗衣服务
    HCGadgetyService    =   21,     //小配件
    
    
    HCMultiPageService = 29,    //新模板，三页式
    HCHotelCommentsService = 25,    //列表    展示          评论
    
    
    HCWakeupService     = 22,       //唤醒
    HCSummaryService = 1,           //介绍
    HCNavigationService=2,          //导航
    HCCommunicateService=3,         //咨询
    HCWifiServices  =4,             //WIFI设定
    HCRoomServices = 5,             //房间
    HCCheckInServices = 6,          //入住登记
    HCWordsServices = 7,            //关于词型展示
    HCPromotionServices=8,           //营销内容
    HCIntroductDetail = 9,           //介绍详情
    HCBarcodeService = 10,           //二维码显示
    HCNewsService = 30,             //新闻类
    HCImagesService = 31            //图片类
};
typedef  int16_t HCServiceModule;
/// 服务类型
enum _HCRuleFunType
{
    /// <summary>
    ///  介绍
    /// </summary>
    HCRuleFunTypeIntroduce=1,
    /// <summary>
    /// 预约
    /// </summary>
    HCRuleFunTypeAppointment=2,
    /// <summary>
    /// 预订
    /// </summary>
    HCRuleFunTypeReserve = 3,
    /// <summary>
    /// 订购
    /// </summary>
    HCRuleFunTypeOrder=4,
    /// <summary>
    /// 订桌
    /// </summary>
    HCRuleFunTypeReserveTable=5,
    /// <summary>
    /// 订房
    /// </summary>
    HCRuleFunTypeReserveRoom=6,
    /// <summary>
    /// 菜品
    /// </summary>
    HCRuleFunTypeDishes=7
};
typedef int8_t HCRuleFunType;

enum _HCProductPromote
{
    HCProductPromoteNew= 1, //新品
    HCProductPromoteSignBoard = 2, //招牌
    HCProductPromoteCharacteristic = 4,//特色
    HCProductPromoteDiscount = 8,//特价
    HCProductPromoted = 16//推荐
};
typedef int16_t HCProductPromote;
enum _HCFoodSpecies
{
    HCFoodSpecieBreakfast= 1, //早餐
    HCFoodSpecieLunch = 2, //午餐
    HCFoodSpecieDinner = 4,//晚餐
    HCFoodSpecieNightFood = 8 //夜宵
};
typedef int16_t HCFoodSpecies;
#endif
