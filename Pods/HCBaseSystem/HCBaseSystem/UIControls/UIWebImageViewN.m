//
//  UIWebImageViewN.m
//  HotelCloud
//
//  Created by XUTAO HUANG on 13-5-10.
//  Copyright (c) 2013年 Suixing. All rights reserved.
//

#import "UIWebImageViewN.h"

#import <hccoren/UIImage-Transform.h>
#import <hccoren/UIImage-Extension.h>

#import <QuartzCore/QuartzCore.h>

#import "SDImageCache.h"
#import "SDWebImageCompat.h"
#import "SDWebImageManager.h"
#import "UIImageView+WebCache.h"

@interface UIWebImageViewN ()<SDWebImageManagerDelegate>
{
}
@end

@implementation UIWebImageViewN
@synthesize userInteractionEnabled;
@synthesize isFill_;
@synthesize keepScale_;
@synthesize orgFrame_;
@synthesize delegate;
@synthesize fillImageSize_;
@synthesize borderColor_;
@synthesize borderWidth_;
@synthesize showIndicator_;
@synthesize fastMode = fastMode_;
//@synthesize tapReload_;
-(id)init
{
    if(self = [super init])
    {
        self.userInteractionEnabled = NO;
        isFill_ = NO;
        keepScale_ = NO;
        isLoaded_ = NO;
        orgFrame_ = CGRectZero;
        showIndicator_ = YES;
        orgUrl_ = nil;
        fastMode_ = YES;
        //fastMode_ = NO;
#ifdef TRACKPAGES
        Class claz = [self class];
        NSString * cname = NSStringFromClass(claz);
        void * p = (void*)self;
        NSString * addr = [NSString stringWithFormat:@"%X",(unsigned int)p];
        [[SystemConfiguration sharedSystemConfiguration] openPageRec:cname  Addr:addr];
#endif
    }
    return self;
}
-(id)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        isLoaded_ = NO;
        orgFrame_ = frame;
        self.userInteractionEnabled = NO;
        isFill_ = NO;
        keepScale_ = NO;
        fastMode_ = YES;
        //fastMode_ = NO;
        fillImageSize_ = frame.size;
#ifdef TRACKPAGES
        Class claz = [self class];
        NSString * cname = NSStringFromClass(claz);
        void * p = (void*)self;
        NSString * addr = [NSString stringWithFormat:@"%X",(unsigned int)p];
        [[SystemConfiguration sharedSystemConfiguration] openPageRec:cname  Addr:addr];
#endif
    }
    return self;
}
-(void)setBorder
{
    
}
- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
}
-(void)readyToRelease
{
    self.delegate = nil;
    if(!isLoaded_)
    {
        [self sd_cancelCurrentImageLoad];
    }
    if(indicator_)
    {
        [indicator_ removeFromSuperview];
        PP_RELEASE(indicator_);
    }
    
}
-(void)dealloc
{
    [self readyToRelease];
    
    PP_RELEASE(urlParam_);
    PP_RELEASE(borderColor_);
    PP_RELEASE(url_);
    PP_RELEASE(orgUrl_);
    PP_RELEASE(urlString_);
    
#ifdef TRACKPAGES
    Class claz = [self class];
    NSString * cname = NSStringFromClass(claz);
    void * p = (void*)self;
    NSString * addr = [NSString stringWithFormat:@"%X",(unsigned int)p];
    [[SystemConfiguration sharedSystemConfiguration] closePageRec:cname  Addr:addr];
#endif
    PP_SUPERDEALLOC;
}
- (NSString*)getUrlString
{
    return urlString_;
}
//传入的URL
- (NSString *)getUrlParam
{
    return urlParam_;
}
- (void)setImageWithURLString:(NSString *)urlString width:(int)width height:(int)height placeholderImageName:(NSString*)imageName
{
    return [self setImageWithURLString:urlString
                                 width:width
                                height:height
                      placeholderImage:imageName&& imageName.length>0?[UIImage imageNamed:imageName]:nil];
}
- (void)setImageWithURLString:(NSString *)urlString width:(int)width height:(int)height mode:(int)mode placeholderImageName:(NSString*)imageName
{
    return [self setImageWithURLString:urlString
                                 width:width
                                height:height mode:mode
                      placeholderImage:imageName&& imageName.length>0?[UIImage imageNamed:imageName]:nil];
}
- (void)setImageWithURLString:(NSString *)urlString width:(int)width height:(int)height placeholderImage:(UIImage *)placeholder
{
    [self setImageWithURLString:urlString width:width height:height mode:2 placeholderImage:placeholder];
}
- (BOOL) isQiniuServer:(NSString *)urlString
{
    return [HCFileManager isQiniuServer:urlString];
}
- (void)setHolderImage:(UIImage *)placeholder
{
//    if([NSThread isMainThread])
//    {
//        NSLog(@"WI:set placeholder:%@",placeholder);
        if(placeholder && (!self.image))
        {
            [self setImage:placeholder];
        }
        if(showIndicator_)
        {
            if(indicator_)
            {
                [indicator_ startAnimating];
            }
            else
            {
                indicator_ = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
                indicator_.backgroundColor = [UIColor clearColor];
                indicator_.center = CGPointMake(self.frame.size.width/2.0f, self.frame.size.height/2.0f);
                [self addSubview:indicator_];
                [indicator_ startAnimating];
            }
        }
        
//    }
//    else
//    {
//        __weak UIWebImageViewN * weakSelf = self;
//        dispatch_async(dispatch_get_main_queue(),^(void)
//                       {
//                           __strong UIWebImageViewN * strongSelf = weakSelf;
//                           [strongSelf setHolderImage:placeholder];
//                           strongSelf = nil;
//                       });
//    }
}
- (void)setImageWithURLString:(NSString *)urlString width:(int)width height:(int)height  mode:(int)mode placeholderImage:(UIImage *)placeholder
{
    
    if(urlString==nil|| [urlString isKindOfClass:[NSNull class]]||[urlString length]==0)
    {
        PP_RELEASE(urlParam_);
        self.image = placeholder;
        if(self.delegate && [self respondsToSelector:@selector(webImageView:didFailureWithError:)])
        {
            [self.delegate webImageView:self didFailureWithError:[NSError errorWithDomain:@"url is empty." code:-1 userInfo:nil]];
        }
        return;
    }

    //    else if([urlString rangeOfString:@"{"].length>0)
    //    {
    //        HCImageItem * imageItem = [HCImageItem initWithJson:urlString];
    //        urlString = imageItem.Src;
    //    }
//    NSLog(@"WI:set imageurl:%@",urlString);
    
    PP_RELEASE(urlParam_);
    urlParam_ = PP_RETAIN(urlString);
    
    NSString * url = nil;
    
    
    url = [HCImageItem urlWithWH:urlString width:width height:height mode:mode];
    
    if([HCFileManager isInAblum:url] ==NO && [HCFileManager isLocalFile:url]==NO)
    {
        NSString * encodingString = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        PP_RELEASE(url_);
        url_ = PP_RETAIN([NSURL URLWithString:encodingString]);
        
        // 处理缓存 感觉卡顿
//        UIImage * image = [self queryImageFromCache:url_];
//        if(image)
//        {
////            NSLog(@"WI:get cache imageurl:%@",url);
//            PP_RELEASE(urlString_);
//            urlString_ = [url copy];
//            [self didImageOK:image url:url_];
//            
//            // collectionview reloaddata 时 dispatch图片出现闪烁 因此注释掉
////            __weak UIWebImageViewN * weakSelf = self;
////            dispatch_async(dispatch_get_main_queue(),^(void)
////                           {
////                               __strong UIWebImageViewN * strongSelf = weakSelf;
////                               [strongSelf didImageOK:image url:url_];
////                               strongSelf = nil;
////                           });
//            return;
//        }
        
        [self setHolderImage:placeholder];
        
        [self download:[NSURL URLWithString:encodingString] holderplace:nil];
    }
    else
    {
        //NSString * documentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        url = [HCFileManager checkPath:url];
        //        if(url && [url hasPrefix:@"file://"])
        //            url = [url substringFromIndex:7];
        
        // 检查本地文件路径会不会发生变化
        NSString * regex = @"/Application/[^/]+|/Applications/[^/]+";
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString * localApplication =  PP_RETAIN([documentsDirectory stringByMatching:regex]);
        if(localApplication)
        {
            url = [url stringByReplacingOccurrencesOfRegex:regex withString:localApplication];
        }
        
        NSRange range1 = [url rangeOfString:@"/"];
        UIImage * localImage = nil;
        if(range1.length>0)
        {
            localImage = [UIImage imageWithContentsOfFile:url];
        }
        else
        {
            localImage = [UIImage imageNamed:url];
        }
        if(localImage)
        {
            [self didImageOK:localImage url:[NSURL fileURLWithPath:url]];
        }
        else
        {
            [self setHolderImage:placeholder];
        }
    }
    
    PP_RELEASE(urlString_);
    urlString_ = [url copy];
}
- (void)didImageOK:(UIImage *)image url:(NSURL*)url
{
//    if([NSThread isMainThread])
//    {
        // NSLog(@"WI:did image ok....%@",[url absoluteString]);
        [self hideIndicator];
        image = [self resetImageFrame:image];
        
        if([self isQiniuServer:[url absoluteString]])
        {
            //淡入淡出效果
            if(self.fastMode)
            {
//                if (self.image == nil || self.image == placeHolderImage_) {
//                    
//                    CATransition *transtion = [CATransition animation];
//                    // transtion.duration = 0.5;
//                    [transtion setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
//                    [transtion setType:kCATransitionFade];
//                    [transtion setSubtype:kCATransitionFromRight];
//                    self.layer.actions = @{@"contents":transtion};
//                    [self.layer addAnimation:transtion forKey:@"transtionKey"];
//                    
//                    // 使用[layer setcontents:]的方法点击 图片会丢掉
//                    //[self.layer setContents:(id)image.CGImage];
//                }
                [self setImage:image];
            }
            else
            {
                [self setImage:image];
            }
            __weak __typeof(self)weakSelf = self;
            if(self.delegate && [self.delegate respondsToSelector:@selector(webImageView:didLoadedWithImage:width:height:)])
            {
                [self.delegate webImageView:weakSelf didLoadedWithImage:image
                                      width:self.frame.size.width
                                     height:self.frame.size.height];
                
            }
        }
        else
        {
            @autoreleasepool {
                //用原来的URL转存一次，按当前的URL缓存，下次就可以直接读取缓存的数据
                if(orgUrl_ && [[orgUrl_ absoluteString] isEqualToString:[url_ absoluteString]]==NO)
                {
                    SDImageCache * cache = [SDImageCache sharedImageCache];
                    
                    NSString * key = [[SDWebImageManager sharedManager]cacheKeyForURL:orgUrl_];
                    //                [CommonUtil md5Hash:[orgUrl_ absoluteString]];
                    [cache storeImage:image forKey:key toDisk:YES];
                    
                }
                
                
                //如果需要保持比例或填充，暂时这样处理，先不必要去处理非填充的情况
                UIImage * imageDownloaded = image;
                
                //淡入淡出效果
                if(self.fastMode)
                {
//                    if (self.image == nil || self.image == placeHolderImage_) {
//                        
//                        CATransition *transtion = [CATransition animation];
//                        // transtion.duration = 0.5;
//                        [transtion setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
//                        [transtion setType:kCATransitionFade];
//                        [transtion setSubtype:kCATransitionFromRight];
//                        self.layer.actions = @{@"contents":transtion};
//                        [self.layer addAnimation:transtion forKey:@"transtionKey"];
//                        
//                        // 使用[layer setcontents:]的方法点击 图片会丢掉
//                        //[self.layer setContents:(id)image.CGImage];
//                    }
                    [self setImage:image];
                }
                else
                {
                    [self setImage:image];
                }
                
                __weak __typeof(self)weakSelf = self;
                if(self.delegate && [self.delegate respondsToSelector:@selector(webImageView:didLoadedWithImage:width:height:)])
                {
                    [self.delegate webImageView:weakSelf didLoadedWithImage:imageDownloaded
                                          width:self.frame.size.width
                                         height:self.frame.size.height];
                    
                }
                
                fillImageSize_ = self.frame.size;
                
                return;
            }
        }
//    }
//    else
//    {
//        __weak UIWebImageViewN * weakSelf = self;
//        dispatch_async(dispatch_get_main_queue(),^(void)
//                       {
//                           __strong UIWebImageViewN * strongSelf = weakSelf;
//                           [strongSelf didImageOK:image url:url];
//                           strongSelf = nil;
//                           
//                       });
//    }
}
-(void)didImageFailure:(NSError *)error url:(NSURL*)url
{
    [self hideIndicator];
    if(self.delegate && [self respondsToSelector:@selector(webImageView:didFailureWithError:)])
    {
        [self.delegate webImageView:self didFailureWithError:error];
    }
    
}
- (UIImage *)queryImageFromCache:(NSURL*)url
{
    SDImageCache * cache = [SDImageCache sharedImageCache];
    
    NSString * key = [[SDWebImageManager sharedManager]cacheKeyForURL:url];
    UIImage * image = [cache imageFromMemoryCacheForKey:key];
    if(!image)
    {
        image = [cache imageFromDiskCacheForKey:key];
    }
    return image;
}
- (void)hideIndicator
{
    if(indicator_)
    {
        [indicator_ stopAnimating];
        [indicator_ removeFromSuperview];
        PP_RELEASE(indicator_);
    }
}
- (void)setShowIndicator:(BOOL)show
{
    showIndicator_ = show;
}
#pragma mark - imageview delegate
- (void)download:(NSURL *)url holderplace:(UIImage *)placeholder
{
    [self sd_cancelCurrentImageLoad];
    isLoaded_ = NO;
    if(placeholder)
    {
        [self setHolderImage:placeholder];
    }
    [self sd_setImageWithURL:url placeholderImage:placeholder
                     options:0
                    progress:^(NSInteger receivedSize,NSInteger expectedSize){
                        
                    }
                   completed:^(UIImage * image,NSError * error,SDImageCacheType cacheType,NSURL * imageUrl)
     {
         [self hideIndicator];
         isLoaded_ = YES;
         if(image)
         {
             [self didImageOK:image url:imageUrl];
         }
         else
         {
             [self didImageFailure:error url:imageUrl];
         }
     }];
}

/** SDWebImage Set Web Image */
- (void)setSDWebImageWithURLString:(NSString *)urlString width:(int)width height:(int)height  mode:(int)mode placeholderImage:(UIImage *)placeholder
{
    return [self setImageWithURLString:urlString width:width height:height mode:mode placeholderImage:placeholder];
    
//    if(urlString == nil || [urlString isKindOfClass:[NSNull class]] || [urlString length] == 0)
//    {
//        PP_RELEASE(urlParam_);
//        self.image = placeholder;
//        if(self.delegate && [self respondsToSelector:@selector(webImageView:didFailureWithError:)])
//        {
//            [self.delegate webImageView:self didFailureWithError:[NSError errorWithDomain:@"url is empty." code:-1 userInfo:nil]];
//        }
//        return;
//    }
//    
//    NSString * url = nil;
//    url = [HCImageItem urlWithWH:urlString width:width height:height mode:mode];
//    
//    if([CommonUtil isInAblum:url] == NO && [CommonUtil isLocalFile:url] == NO)
//    {
////        NSString * encodingString = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
////        NSURL * URL = [NSURL URLWithString:encodingString];
////        UIImage * image = [self queryImageFromCache:URL];
////        
////        if(image)
////        {
////            [self setImage:image];
////        }
////        else
////        {
//            [self sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:placeholder];
////        }
//    }
//    else
//    {
//        url = [CommonUtil checkPath:url];
//        
//        // 检查本地文件路径会不会发生变化
//        NSString * regex = @"/Application/[^/]+|/Applications/[^/]+";
//        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
//        NSString *documentsDirectory = [paths objectAtIndex:0];
//        NSString * localApplication =  PP_RETAIN([documentsDirectory stringByMatching:regex]);
//        if(localApplication)
//        {
//            url = [url stringByReplacingOccurrencesOfRegex:regex withString:localApplication];
//        }
//        
//        NSRange range1 = [url rangeOfString:@"/"];
//        UIImage * localImage = nil;
//        if(range1.length > 0)
//        {
//            localImage = [UIImage imageWithContentsOfFile:url];
//        }
//        else
//        {
//            localImage = [UIImage imageNamed:url];
//        }
//        if(localImage)
//        {
//            //淡入淡出效果
//            if(self.fastMode)
//            {
//                CATransition *transtion = [CATransition animation];
//                //transtion.duration = 0.5;
//                [transtion setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
//                [transtion setType:kCATransitionFade];
//                [transtion setSubtype:kCATransitionFromRight];
//                [self.layer addAnimation:transtion forKey:@"transtionKey"];
//            }
//            [self setImage:localImage];
//        }
//        else
//        {
//            if(placeholder && (!self.image))
//            {
//                [self setImage:placeholder];
//            }
//        }
//    }
}

- (UIImage *)resetImageFrame:(UIImage *)image
{
    CGSize imageSize = image.size;
    if (imageSize.width <= 0 || imageSize.height <= 0)
        return image;
    if(image && isFill_)
    {
        CGRect cropRect = [CommonUtil rectFitWithScale:imageSize rectMask:self.bounds.size];
        
        CGFloat rate1 = imageSize.height<=0?1:roundf(imageSize.width/imageSize.height * 10) / 10.0;
        CGFloat rate2 = cropRect.size.height<=0?1:roundf(cropRect.size.width/cropRect.size.height *10) / 10.0;
        if(cropRect.size.height==0 ||cropRect.size.width==0
           ||rate1==rate2) //相同，则不处理
        {
            
        }
        else
        {
            image = [image imageAtRect:cropRect];
        }
    }
    else if(image && keepScale_)
    {
        CGPoint center = self.center;
        CGRect frame = self.frame;
        CGRect bounds = self.bounds;
        CGFloat rate1 = imageSize.height<=0?1:((int)roundf(imageSize.width/imageSize.height * 10)) / 10.0;
        CGFloat rate2 = frame.size.height<=0?1:((int)roundf(frame.size.width/frame.size.height * 10)) / 10.0;
        CGFloat rate3 = bounds.size.height<=0?1:((int)roundf(bounds.size.width/bounds.size.height * 10)) / 10.0;
        if (rate1 == rate2 || rate1 == rate3) {
            
        } else {
            if (rate1 > 1) {
                //                    if (imageSize.width >= frame.size.width) {
                //                        frame.size.width = imageSize.width;
                //                    }
                frame.size.height = frame.size.width / rate1;
            } else if (rate1 < 1) {
                frame.size.width = frame.size.height / rate1;
            } else {
                if (rate2 > 1) {
                    frame.size.width = frame.size.height;
                } else {
                    frame.size.height = frame.size.width;
                }
            }
            self.frame = frame;
            self.center = center;
            
//            image = [image imageAtRect:frame];
        }
    }
    return image;
}

@end
