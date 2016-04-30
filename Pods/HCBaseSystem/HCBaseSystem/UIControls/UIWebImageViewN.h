//
//  UIWebImageViewN.h
//  HotelCloud
//
//  Created by XUTAO HUANG on 13-5-10.
//  Copyright (c) 2013年 Suixing. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <hccoren/base.h>
#import <hccoren/hcimageitem.h>
#import <hccoren/regexkitlite.h>

@class UIWebImageViewN;
@protocol UIWebImageViewDelegateN <NSObject>
@optional
- (void)webImageView:(UIWebImageViewN *)webImageView didLoadedWithImage:(UIImage *)image width:(CGFloat)width height:(CGFloat) height;
- (void)webImageView:(UIWebImageViewN *)webImageView didFailureWithError:(NSError *)error;
@end

@interface UIWebImageViewN : UIImageView
{
    UIActivityIndicatorView * indicator_;
    NSURL * url_;
    NSURL * orgUrl_;
    NSString * urlString_;
    BOOL isLoaded_;
    
    NSString * urlParam_;
//    CGRect orgFrame_;
//    UIImage * orgImage_;
}
@property (nonatomic,assign) BOOL UserDefineIndicator;
@property (nonatomic,PP_WEAK) id<UIWebImageViewDelegateN>  delegate;
@property (nonatomic,assign) BOOL isFill_;
@property (nonatomic,assign) BOOL keepScale_;
@property (nonatomic,assign) BOOL showIndicator_;
@property (nonatomic,assign) CGFloat borderWidth_;
@property (nonatomic,retain) UIColor * borderColor_;
@property (nonatomic,assign) CGRect orgFrame_;
@property (nonatomic,assign,readonly) CGSize fillImageSize_;
@property (nonatomic,assign) BOOL fastMode;
//@property (nonatomic,assign) BOOL tapReload_;
/**
 * Set the imageView `image` with an `url`.
 *
 * The downloand is asynchronous and cached.
 *
 * @param url The url that the image is found.
 * @see setImageWithURL:placeholderImage:
 */
//- (void)setImageWithURL:(NSURL *)url;
- (NSString *)getUrlString;


- (NSString *)getUrlParam; //传入的URL

/**
 * Set the imageView `image` with an `url` and a placeholder.
 *
 * The downloand is asynchronous and cached.
 *
 * @param url The url that the `image` is found.
 * @param placeholder A `image` that will be visible while loading the final image.
 * @see setImageWithURL:placeholderImage:options:
 */
//- (void)setImageWithURLNew:(NSURL *)url placeholderImage:(UIImage *)placeholder;
- (void)setImageWithURLString:(NSString *)urlString width:(int)width height:(int)height placeholderImageName:(NSString*)imageName;
- (void)setImageWithURLString:(NSString *)urlString width:(int)width height:(int)height mode:(int)mode placeholderImageName:(NSString*)imageName;
- (void)setImageWithURLString:(NSString *)urlString width:(int)width height:(int)height placeholderImage:(UIImage *)placeholder;
// mode 1 cut, 2 scale with rate
- (void)setImageWithURLString:(NSString *)urlString width:(int)width height:(int)height  mode:(int)mode placeholderImage:(UIImage *)placeholder;

- (void)setShowIndicator:(BOOL)show;

/**
 * Set the imageView `image` with an `url`, placeholder and custom options.
 *
 * The downloand is asynchronous and cached.
 *
 * @param url The url that the `image` is found.
 * @param placeholder A `image` that will be visible while loading the final image.
 * @param options A list of `SDWebImageOptions` for current `imageView`. Available options are `SDWebImageRetryFailed`, `SDWebImageLowPriority` and `SDWebImageCacheMemoryOnly`.
 */
//- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options;

/**
 * Cancel the current download
 */
//- (void)cancelCurrentImageLoad;
- (void)readyToRelease;
//- (void)reloadView;

// 使用SDWebImage 直接加载
- (void)setSDWebImageWithURLString:(NSString *)urlString width:(int)width height:(int)height  mode:(int)mode placeholderImage:(UIImage *)placeholder;
@end
