//
//  AudioGenerater.h
//  maiba
//
//  Created by HUANGXUTAO on 16/4/11.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface AudioGenerater : NSObject
{
    TimeScale defaultAudioScale_;
}
//从现有文件中截取一段音频
- (BOOL) generateAudioWithRange:(NSURL *)audioUrl
                   beginSeconds:(CGFloat)beginSeconds
                     endSeconds:(CGFloat)endSeconds
                     targetFile:(NSString*)targetFile
                      completed:(void(^)(NSURL *audioUrl, NSError *error))completeHandler;
//合成音频文件
-(BOOL) generateAudioWithAccompany:(NSArray *)audioItemQueue
//                          Accompany:(NSURL *)accompany
                           filePath:(NSString *) filePath
                       beginSeconds:(CGFloat)beginSeconds
                         endSeconds:(CGFloat)endSeconds
                          overwrite:(BOOL) overwrite
                         completed:(void(^)(NSURL *audioUrl, NSError *error))completeHandler;
//拉伸或压缩声音
- (BOOL)scaleAudio:(AVAsset *)asset withRate:(CGFloat)rate writeFile:(NSString *)targetFile
      beginSeconds:(CGFloat)beginSeconds
        endSeconds:(CGFloat)endSeconds
         completed:(void(^)(NSURL *audioUrl, NSError *error))completeHandler;

- (NSString *)scaleAudio:(AVAsset *)asset withRate:(CGFloat)rate beginSeconds:(CGFloat)beginSeconds
              endSeconds:(CGFloat)endSeconds;


- (BOOL)createAudioFromVideo:(NSURL *)fileUrl completed:(void(^)(NSURL *audioUrl, NSError *error))completed;

- (NSString *)getAudioFileNameByQueue:(NSArray *)audioItemQueue;

+ (OSStatus)mixAudio:(NSString *)audioPath1
            andAudio:(NSString *)audioPath2
              toFile:(NSString *)outputPath
  preferedSampleRate:(float)sampleRate;
@end
