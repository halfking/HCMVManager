//
//  PublicMControls.h
//  HotelCloud
//
//  Created by XUTAO HUANG on 13-4-2.
//  Copyright (c) 2013年 Suixing. All rights reserved.
//

#ifndef HotelCloud_PublicMControls_h
#define HotelCloud_PublicMControls_h

#ifndef PP_ARC_ENABLED
    #if __has_feature(objc_arc) && __clang_major__ >= 3
    #define PP_ARC_ENABLED 1
    #endif // __has_feature(objc_arc)
#endif


//部分按钮的定义宏
//#define BARBUTTON(TITLE,SELECTOR) [[[UIBarButtonItem alloc] initWithTitle:TITLE style:UIBarButtonItemStylePlain target:self action:SELECTOR] autorelease]

//#define BARBUTTONNEW(NAME,TITLE,IMAGE1,IMAGE2,SELECTOR,WIDTH,HEIGHT,X,Y)  \
//UIBarButtonItem * btn##NAME = [[[UIBarButtonItem alloc] initWithTitle:TITLE style:UIBarButtonItemStylePlain target:self action:SELECTOR] autorelease]; \
//\
//[btn##NAME setBackgroundImage:[[UIImage imageNamed:IMAGE1] stretchableImageWithLeftCapWidth:X topCapHeight:Y] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];\
//\
//[btn##NAME setBackgroundImage:[[UIImage imageNamed:IMAGE2] stretchableImageWithLeftCapWidth:X topCapHeight:Y] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];\
//
//定义导航
//[BARNAME setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"tool_bg.png"]]];
//#define NAVBAR(BARNAME,TITLENAME,TITLE) \
//UINavigationBar * BARNAME = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, _ScreenWidth, HEIGHT_NAV)];\
//\
//[BARNAME setBackgroundImage:[UIImage imageNamed:@"top_bg.png"] forBarMetrics:UIBarMetricsDefault];\
//\
//[BARNAME setBarStyle:UIBarStyleBlack];\
//\
//UINavigationItem * TITLENAME = [[UINavigationItem alloc]initWithTitle:TITLE];\
//\
//[BARNAME pushNavigationItem:TITLENAME animated:YES];\
//\
//[self setNavigationBar:BARNAME];\
//\
//[self.view addSubview:BARNAME];\
//\
//[BARNAME release];\
//\

//UIView * topShadown = [[UIView alloc]initWithFrame:CGRectMake(0, HEIGHT_NAV -2, _ScreenWidth, 2)];\
//\
//topShadown.backgroundColor =[UIColor colorWithPatternImage:[UIImage imageNamed:@"shadow_top.png"]];\
//\
//[self.view addSubview:topShadown];\
//\
//[topShadown release];\


//
////
////定义BarItem按钮
//#define BARBUTTONNEW(NAME,TITLE,IMAGE1,IMAGE2,SELECTOR,WIDTH,HEIGHT,SCALEX,SCALEY)  \
//UIImage * img##NAME=nil;\
//\
//UIImage * img##NAME##_Hove=nil;\
//\
//if([IMAGE1 compare:@"btns_3.png"]==NSOrderedSame) \
//\
//{\
//\
//img##NAME = [[UIImage imageNamed:IMAGE1] stretchableImageWithLeftCapWidth:15.0f topCapHeight:15.0f];\
//\
//img##NAME##_Hove = [[UIImage imageNamed:IMAGE2] stretchableImageWithLeftCapWidth:15.0f topCapHeight:15.0f];\
//\
//}\
//\
//else {\
//\
//img##NAME = [[UIImage imageNamed:IMAGE1] stretchableImageWithLeftCapWidth:SCALEX topCapHeight:SCALEY];\
//\
//img##NAME##_Hove = [[UIImage imageNamed:IMAGE2] stretchableImageWithLeftCapWidth:SCALEX topCapHeight:SCALEY];\
//\
//}\
//\
//UIButton * btn##NAME##_Temp = [UIButton buttonWithType:UIButtonTypeCustom];\
//\
//[btn##NAME##_Temp setBackgroundImage:img##NAME forState:UIControlStateNormal];\
//\
//[btn##NAME##_Temp setBackgroundImage:img##NAME##_Hove forState:UIControlStateHighlighted];\
//\
//[btn##NAME##_Temp setTitle:TITLE forState:UIControlStateNormal];\
//\
//btn##NAME##_Temp.titleLabel.font = [UIFont fontWithName:@"STHeitiJ-Medium" size:13];\
//\
//CGSize btn##NAME##_TempTZ = [TITLE sizeWithFont:[UIFont fontWithName:@"STHeitiJ-Medium" size:13]]; \
//\
//if([IMAGE1 compare:@"btns_3.png"]==NSOrderedSame) \
//{ \
//\
//[btn##NAME##_Temp setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)]; \
//btn##NAME##_Temp.frame = CGRectMake(0, 0, btn##NAME##_TempTZ.width+25, 30);\
//\
//}\
//else{\
//\
//btn##NAME##_Temp.frame = CGRectMake(0, 0, btn##NAME##_TempTZ.width+20 <WIDTH?WIDTH:btn##NAME##_TempTZ.width+20, 30);\
//\
//}\
//\
//[btn##NAME##_Temp addTarget:self action:SELECTOR forControlEvents:UIControlEventTouchUpInside];\
//\
//UIBarButtonItem * NAME = [[[UIBarButtonItem alloc]initWithCustomView:btn##NAME##_Temp]autorelease];\
//\
//
//
////定义按钮
//#define UIBUTTONNEW(NAME,TITLE,IMAGE1,IMAGE2,SELECTOR,WIDTH,HEIGHT,SCALEX,SCALEY)  \
//UIImage * img##NAME = [[UIImage imageNamed:IMAGE1] stretchableImageWithLeftCapWidth:SCALEX topCapHeight:SCALEY];\
//\
//UIImage * img##NAME##_Hove = [[UIImage imageNamed:IMAGE2] stretchableImageWithLeftCapWidth:SCALEX topCapHeight:SCALEY];\
//\
//UIButton * NAME = [UIButton buttonWithType:UIButtonTypeCustom];\
//\
//[NAME setBackgroundImage:img##NAME forState:UIControlStateNormal];\
//\
//[NAME setBackgroundImage:img##NAME##_Hove forState:UIControlStateHighlighted];\
//\
//[NAME setTitle:TITLE forState:UIControlStateNormal];\
//\
//NAME.titleLabel.font = [UIFont fontWithName:@"STHeitiJ-Medium" size:13];\
//\
//if([IMAGE1 compare:@"btns_3.png"]==NSOrderedSame) \
//{ \
//\
//[NAME setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)]; \
//NAME.frame = CGRectMake(0, 0, 60, HEIGHT);\
//\
//}\
//else{\
//\
//NAME.frame = CGRectMake(0, 0, WIDTH, HEIGHT);\
//\
//}\
//\
//[NAME addTarget:self action:SELECTOR forControlEvents:UIControlEventTouchUpInside];\
//\
//
//
//#define BARBUTTONIMAGE(NAME,ICON,IMAGE1,IMAGE2,SELECTOR,WIDTH,HEIGHT,SCALEX,SCALEY)  \
//UIImage * img##NAME = [[UIImage imageNamed:IMAGE1] stretchableImageWithLeftCapWidth:SCALEX topCapHeight:SCALEY];\
//\
//UIImage * img##NAME##_Hove = [[UIImage imageNamed:IMAGE2] stretchableImageWithLeftCapWidth:SCALEX topCapHeight:SCALEY];\
//\
//UIButton * btn##NAME##_Temp = [UIButton buttonWithType:UIButtonTypeCustom];\
//\
//[btn##NAME##_Temp setBackgroundImage:img##NAME forState:UIControlStateNormal];\
//\
//[btn##NAME##_Temp setBackgroundImage:img##NAME##_Hove forState:UIControlStateHighlighted];\
//\
//[btn##NAME##_Temp  setImage:[UIImage imageNamed:ICON] forState:UIControlStateNormal];\
//\
//if([IMAGE1 compare:@"btns_3.png"]==NSOrderedSame) \
//{ \
//\
//[btn##NAME##_Temp setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)]; \
//btn##NAME##_Temp.frame = CGRectMake(0, 0, 60, HEIGHT);\
//\
//}\
//else{\
//\
//btn##NAME##_Temp.frame = CGRectMake(0, 0, WIDTH, HEIGHT);\
//\
//}\
//\
//[btn##NAME##_Temp addTarget:self action:SELECTOR forControlEvents:UIControlEventTouchUpInside];\
//\
//UIBarButtonItem * NAME = [[[UIBarButtonItem alloc]initWithCustomView:btn##NAME##_Temp]autorelease];\
//\
//
//
//
//#define BARBUTTONIMAGENEW(NAME,ICON,IMAGE1,IMAGE2,SELECTOR,WIDTH,HEIGHT,SCALEX,SCALEY,USEDEFAULT)  \
//UIButton * btn##NAME##_Temp = [UIButton buttonWithType:UIButtonTypeCustom];\
//\
//if(IMAGE1 && IMAGE1.length>0){ \
//\
//UIImage * img##NAME = [[UIImage imageNamed:IMAGE1] stretchableImageWithLeftCapWidth:SCALEX topCapHeight:SCALEY];\
//\
//UIImage * img##NAME##_Hove = [[UIImage imageNamed:IMAGE2] stretchableImageWithLeftCapWidth:SCALEX topCapHeight:SCALEY];\
//\
//[btn##NAME##_Temp setBackgroundImage:img##NAME forState:UIControlStateNormal];\
//\
//[btn##NAME##_Temp setBackgroundImage:img##NAME##_Hove forState:UIControlStateHighlighted];\
//\
//}\
//\
//[btn##NAME##_Temp  setImage:[config themeImageWithName:ICON useDefault:USEDEFAULT] forState:UIControlStateNormal];\
//\
//if([IMAGE1 compare:@"btns_3.png"]==NSOrderedSame) \
//{ \
//\
//[btn##NAME##_Temp setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)]; \
//btn##NAME##_Temp.frame = CGRectMake(0, 0, 60, HEIGHT);\
//\
//}\
//else{\
//\
//btn##NAME##_Temp.frame = CGRectMake(0, 0, WIDTH, HEIGHT);\
//\
//}\
//\
//[btn##NAME##_Temp addTarget:self action:SELECTOR forControlEvents:UIControlEventTouchUpInside];\
//\
//UIBarButtonItem * NAME = [[[UIBarButtonItem alloc]initWithCustomView:btn##NAME##_Temp]autorelease];\
//\
//
//
//
////
////定义按钮
//#define BARBUTTON(NAME,TITLE,TARGET,IMAGE1,IMAGE2,SELECTOR,WIDTH,HEIGHT,SCALEX,SCALEY)  \
//UIImage * img##NAME = [[UIImage imageNamed:IMAGE1] stretchableImageWithLeftCapWidth:SCALEX topCapHeight:SCALEY];\
//\
//UIImage * img##NAME##_Hove = [[UIImage imageNamed:IMAGE2] stretchableImageWithLeftCapWidth:SCALEX topCapHeight:SCALEY];\
//\
//UIButton * btn##NAME##_Temp = [UIButton buttonWithType:UIButtonTypeCustom];\
//\
//[btn##NAME##_Temp setBackgroundImage:img##NAME forState:UIControlStateNormal];\
//\
//[btn##NAME##_Temp setBackgroundImage:img##NAME##_Hove forState:UIControlStateHighlighted];\
//\
//[btn##NAME##_Temp setTitle:TITLE forState:UIControlStateNormal];\
//\
//btn##NAME##_Temp.titleLabel.font = [UIFont fontWithName:@"STHeitiJ-Medium" size:13];\
//\
//if([IMAGE1 compare:@"btns_3.png"]==NSOrderedSame) \
//{ \
//\
//[btn##NAME##_Temp setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)]; \
//btn##NAME##_Temp.frame = CGRectMake(0, 0, 60, HEIGHT);\
//\
//}\
//else{\
//\
//btn##NAME##_Temp.frame = CGRectMake(0, 0, WIDTH, HEIGHT);\
//\
//}\
//\
//[btn##NAME##_Temp addTarget:TARGET action:SELECTOR forControlEvents:UIControlEventTouchUpInside];\
//\
//UIBarButtonItem * NAME = [[[UIBarButtonItem alloc]initWithCustomView:btn##NAME##_Temp]autorelease];\
//\
//
////
////
//
//#define SYSBARBUTTON(ITEM, SELECTOR) [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:ITEM target:self action:SELECTOR] autorelease]

#define IS_IPAD	(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#endif

#define DEFAULT_DATE_TIME_FORMAT (@"yyyy-MM-dd HH:mm:ss")


#ifndef SYNTHESIZE_SINGLETON_FOR_CLASS_NEW
#if PP_ARC_ENABLED
#define SYNTHESIZE_SINGLETON_FOR_CLASS_NEW(classname) \
\
static classname *shared##classname = nil; \
\
+ (classname *)shared##classname \
{ \
if(shared##classname == nil) \
{ \
@synchronized(self) \
{ \
if (shared##classname == nil) \
{ \
shared##classname = [[self alloc] init]; \
} \
} \
} \
\
return shared##classname; \
} \
\
+ (id)allocWithZone:(NSZone *)zone \
{ \
@synchronized(self) \
{ \
if (shared##classname == nil) \
{ \
shared##classname = [super allocWithZone:zone]; \
return shared##classname; \
} \
} \
\
return nil; \
} \
\
- (id)copyWithZone:(NSZone *)zone \
{ \
return self; \
} \
\



#else

#define SYNTHESIZE_SINGLETON_FOR_CLASS_NEW(classname) \
\
static classname *shared##classname = nil; \
\
+ (classname *)shared##classname \
{ \
if(shared##classname == nil) \
{ \
@synchronized(self) \
{ \
if (shared##classname == nil) \
{ \
shared##classname = [[self alloc] init]; \
} \
} \
} \
\
return shared##classname; \
} \
\
+ (id)allocWithZone:(NSZone *)zone \
{ \
@synchronized(self) \
{ \
if (shared##classname == nil) \
{ \
shared##classname = [super allocWithZone:zone]; \
return shared##classname; \
} \
} \
\
return nil; \
} \
\
- (id)copyWithZone:(NSZone *)zone \
{ \
return self; \
} \
\
- (id)retain \
{ \
return self; \
} \
\
- (NSUInteger)retainCount \
{ \
return NSUIntegerMax; \
} \
\
- (oneway void)release \
{ \
} \
\
- (id)autorelease \
{ \
return self; \
}\

#endif


#define PARSEDATAARRAY(NEWLIST,ORGLIST,TYPE) \
\
NSMutableArray * NEWLIST = [NSMutableArray new]; \
\
if([ORGLIST isKindOfClass:[NSNull class]]) \
\
{\
    ORGLIST = nil;\
\
}\
\
else if([ORGLIST isKindOfClass:[NSString class]])\
\
{\
    ORGLIST = [(NSString*)ORGLIST JSONValueEx];\
\
}\
\
for (NSDictionary * dic in ORGLIST) { \
\
    TYPE * item = nil; \
\
    if([dic isKindOfClass:[NSDictionary class]]) \
\
    {\
        item = [[TYPE alloc]initWithDictionary:dic];\
\
    } \
\
    else if([dic isKindOfClass:[NSString class]]) \
\
    { \
\
        item = [[TYPE alloc]initWithJSON:(NSString*)dic]; \
\
    } \
\
    else if([dic isKindOfClass:[TYPE class]]) \
\
    { \
        item = PP_RETAIN((TYPE *)dic); \
\
    } \
\
    if(item) \
\
    { \
\
        [NEWLIST addObject:item];\
\
        PP_RELEASE(item);\
\
    } \
\
} \
\


#define PARSEDATA(DICNAME,ITEMNAME,TYPE) \
\
TYPE * ITEMNAME = nil; \
\
if([DICNAME isKindOfClass:[NSDictionary class]]) \
\
{\
ITEMNAME = [[TYPE alloc]initWithDictionary:DICNAME];\
\
} \
\
else if([DICNAME isKindOfClass:[NSString class]]) \
\
{ \
\
ITEMNAME = [[TYPE alloc]initWithJSON:(NSString*)DICNAME]; \
\
} \
\
else if([DICNAME isKindOfClass:[TYPE class]]) \
\
{ \
ITEMNAME = PP_RETAIN((TYPE *)DICNAME); \
\
} \
\


//
//#define IMAGECOUNTVIEW(PVIEW,IMAGECOUNT,LEFT,TOP) \
//\
//{ \
//UIImage * numberImagebg =[UIImage imageNamed:@"icon_picnub_bg.png"]; \
//\
//UIImageView * numberBgView = [[UIImageView alloc]initWithFrame:CGRectMake(LEFT, TOP , 30, 16)]; \
//\
//numberBgView.image = numberImagebg;\
//\
//[PVIEW addSubview:numberBgView]; \
//\
//NSString * numberText = [NSString stringWithFormat:@"x%d",IMAGECOUNT]; \
//\
//UILabel * lable = [[UILabel alloc]initWithFrame:CGRectMake(LEFT +2, TOP, 25, 16)];\
//\
//lable.text = numberText;\
//\
//lable.textColor =[UIColor whiteColor];\
//\
//lable.textAlignment = NSTextAlignmentCenter;\
//\
//lable.font = [UIFont systemFontOfSize:13];\
//\
//lable.backgroundColor = [UIColor clearColor];\
//\
//[PVIEW addSubview:lable];\
//\
//PP_RELEASE(lable);\
//\
//PP_RELEASE(numberBgView);\
//\
//}\
//\

#endif
