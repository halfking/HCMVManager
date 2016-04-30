//
//  UDManager(Helper).m
//  Wutong
//
//  Created by HUANGXUTAO on 15/5/15.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "UDManager(Helper).h"
#import <hccoren/base.h>
#import <HCCoren/HCimageItem.h>
#import "UDInfo.h"
//#import "Music.h"
#import <hccoren/RegexKitLite.h>
#import "HCDBHelper(WT).h"
#import "config.h"
#import "SDWebImageManager.h"
@implementation UDManager(Helper)
#pragma mark - helper
- (NSString *)remoteUrl:(NSString *)key domainType:(int)domainType
{
    if(![self isKeyValid:key]) return nil;
    //    http://7xi4n3.com1.z0.glb.clouddn.com/0-685b0161be1f7332911a73445b658e1d
    //    http://7xi4n3.com1.z0.glb.clouddn.com/0-685b0161be1f7332911a73445b658e1d
    switch (domainType) {
        case (int)DOMAIN_COVER:
            return [NSString stringWithFormat:@"http://%@/%@",DOMAIN_COVER_ROOT,key];
        case (int)DOMAIN_MTVS:
            return [NSString stringWithFormat:@"http://%@/%@",DOMAIN_MTVS_ROOT,key];
        case (int)DOMAIN_MUSIC:
            return [NSString stringWithFormat:@"http://%@/%@",DOMAIN_MUSIC_ROOT,key];
        case (int)DOMAIN_CHAT:
            return [NSString stringWithFormat:@"http://%@/%@",DOMAIN_CHAT_ROOT,key];
        default:
            return [NSString stringWithFormat:@"http://%@/%@",DOMAIN_HOME_ROOT,key];
            
    }
    //    return [NSString stringWithFormat:@"http://7xi4n3.com1.z0.glb.clouddn.com/%@",key];
}
-(NSString *)getMimeType:(NSString *)path
{
    NSString * extension = [path pathExtension];
    
    if([extension isEqualToString:@"mp3"])
        return @"audio/mpeg";
    else if ([extension isEqualToString:@"wav"])
        return @"audio/x-wav";
    else if ([extension isEqualToString:@"mov"])
        return @"video/quicktime";
    else if ([extension isEqualToString:@"mpeg"])
        return @"video/mpeg";
    else if ([extension isEqualToString:@"mpg"])
        return @"video/mpeg";
    else if ([extension isEqualToString:@"gif"])
        return @"image/gif";
    else if ([extension isEqualToString:@"bmp"])
        return @"image/bmp";
    else if ([extension isEqualToString:@"jpeg"] || [extension isEqualToString:@"jpe"] || [extension isEqualToString:@"jpg"])
        return @"image/jpeg";
    else if ([extension isEqualToString:@"bmp"])
        return @"image/bmp";
    else if ([extension isEqualToString:@"png"])
        return @"image/png";
    else if ([extension isEqualToString:@"mp4"])
        return @"image/png";
    else if ([extension isEqualToString:@"avi"])
        return @"video/x-msvideo";
    else if ([extension isEqualToString:@"asf"])
        return @"video/x-ms-asf";
    else if( [extension isEqualToString:@"htm"] || [extension isEqualToString:@"html"] || [extension isEqualToString:@"xhtml"])
        return @"text/html";
    else
        return @"text/plain";
    /*
     if([extension isEqualToString:@"acx"]) {
     return @"application/internet-property-stream";
     else if ([extension isEqualToString:@"ai"])
     return @"application/postscript";
     else if ([extension isEqualToString:@"aif"])
     return @"audio/x-aiff";
     
     m13	application/x-msmediaview
     m14	application/x-msmediaview
     m3u	audio/x-mpegurl
     
     movie	video/x-sgi-movie
     mp2	video/mpeg
     
     mpa	video/mpeg
     mpe	video/mpeg
     wmf	application/x-msmetafile
     
     
     */
    
    //    else if ([extension isEqualToString:@"aifc"])
    //        return @"audio/x-aiff";
    //    else if ([extension isEqualToString:@"aiff"])
    //        return @"audio/x-aiff";
    //    else if ([extension isEqualToString:@"asf"])
    //        return @"video/x-ms-asf";
    //    else if ([extension isEqualToString:@"asr"])
    //        return @"video/x-ms-asf";
    //    else if ([extension isEqualToString:@"asx"])
    //        return @"video/x-ms-asf";
    //    else if ([extension isEqualToString:@"au"])
    //        return @"audio/basic";
    //    else if ([extension isEqualToString:@"avi"])
    //        return @"video/x-msvideo";
    //    else if ([extension isEqualToString:@""])
    //        return @"";
    //    else if ([extension isEqualToString:@""])
    //        return @"";
    //    else
    //        return @"";
    
    
    /*
    	
    	
     
     axs	application/olescript
     bas	text/plain
     bcpio	application/x-bcpio
     bin	application/octet-stream
     
     c	text/plain
     cat	application/vnd.ms-pkiseccat
     cdf	application/x-cdf
     cer	application/x-x509-ca-cert
     class	application/octet-stream
     clp	application/x-msclip
     cmx	image/x-cmx
     cod	image/cis-cod
     cpio	application/x-cpio
     crd	application/x-mscardfile
     crl	application/pkix-crl
     crt	application/x-x509-ca-cert
     csh	application/x-csh
     css	text/css
     dcr	application/x-director
     der	application/x-x509-ca-cert
     dir	application/x-director
     dll	application/x-msdownload
     dms	application/octet-stream
     doc	application/msword
     dot	application/msword
     dvi	application/x-dvi
     dxr	application/x-director
     eps	application/postscript
     etx	text/x-setext
     evy	application/envoy
     exe	application/octet-stream
     fif	application/fractals
     flr	x-world/x-vrml
     
     gtar	application/x-gtar
     gz	application/x-gzip
     h	text/plain
     hdf	application/x-hdf
     hlp	application/winhlp
     hqx	application/mac-binhex40
     hta	application/hta
     htc	text/x-component
     htm	text/html
     html	text/html
     htt	text/webviewhtml
     ico	image/x-icon
     ief	image/ief
     iii	application/x-iphone
     ins	application/x-internet-signup
     isp	application/x-internet-signup
     jfif	image/pipeg
     
     js	application/x-javascript
     latex	application/x-latex
     lha	application/octet-stream
     lsf	video/x-la-asf
     lsx	video/x-la-asf
     lzh	application/octet-stream
     man	application/x-troff-man
     mdb	application/x-msaccess
     me	application/x-troff-me
     mht	message/rfc822
     mhtml	message/rfc822
     mid	audio/mid
     mny	application/x-msmoney
     mpp	application/vnd.ms-project
     mpv2	video/mpeg
     ms	application/x-troff-ms
     mvb	application/x-msmediaview
     nws	message/rfc822
     oda	application/oda
     p10	application/pkcs10
     p12	application/x-pkcs12
     p7b	application/x-pkcs7-certificates
     p7c	application/x-pkcs7-mime
     p7m	application/x-pkcs7-mime
     p7r	application/x-pkcs7-certreqresp
     p7s	application/x-pkcs7-signature
     pbm	image/x-portable-bitmap
     pdf	application/pdf
     pfx	application/x-pkcs12
     pgm	image/x-portable-graymap
     pko	application/ynd.ms-pkipko
     pma	application/x-perfmon
     pmc	application/x-perfmon
     pml	application/x-perfmon
     pmr	application/x-perfmon
     pmw	application/x-perfmon
     pnm	image/x-portable-anymap
     pot,	application/vnd.ms-powerpoint
     ppm	image/x-portable-pixmap
     pps	application/vnd.ms-powerpoint
     ppt	application/vnd.ms-powerpoint
     prf	application/pics-rules
     ps	application/postscript
     pub	application/x-mspublisher
     qt	video/quicktime
     ra	audio/x-pn-realaudio
     ram	audio/x-pn-realaudio
     ras	image/x-cmu-raster
     rgb	image/x-rgb
     rmi	audio/mid
     roff	application/x-troff
     rtf	application/rtf
     rtx	text/richtext
     scd	application/x-msschedule
     sct	text/scriptlet
     setpay	application/set-payment-initiation
     setreg	application/set-registration-initiation
     sh	application/x-sh
     shar	application/x-shar
     sit	application/x-stuffit
     snd	audio/basic
     spc	application/x-pkcs7-certificates
     spl	application/futuresplash
     src	application/x-wais-source
     sst	application/vnd.ms-pkicertstore
     stl	application/vnd.ms-pkistl
     stm	text/html
     svg	image/svg+xml
     sv4cpio	application/x-sv4cpio
     sv4crc	application/x-sv4crc
     swf	application/x-shockwave-flash
     
     t	application/x-troff
     tar	application/x-tar
     tcl	application/x-tcl
     tex	application/x-tex
     texi	application/x-texinfo
     texinfo	application/x-texinfo
     tgz	application/x-compressed
     tif	image/tiff
     tiff	image/tiff
     tr	application/x-troff
     trm	application/x-msterminal
     tsv	text/tab-separated-values
     txt	text/plain
     uls	text/iuls
     ustar	application/x-ustar
     vcf	text/x-vcard
     vrml	x-world/x-vrml
     
     wcm	application/vnd.ms-works
     wdb	application/vnd.ms-works
     wks	application/vnd.ms-works
     wps	application/vnd.ms-works
     wri	application/x-mswrite
     wrl	x-world/x-vrml
     wrz	x-world/x-vrml
     xaf	x-world/x-vrml
     xbm	image/x-xbitmap
     xla	application/vnd.ms-excel
     xlc	application/vnd.ms-excel
     xlm	application/vnd.ms-excel
     xls	application/vnd.ms-excel
     xlt	application/vnd.ms-excel
     xlw	application/vnd.ms-excel
     xof	x-world/x-vrml
     xpm	image/x-xpixmap
     xwd	image/x-xwindowdump
     z	application/x-compress
     zip	application/zip
     */
}
//获取本地文件的全路径
- (NSString *) localFileFullPath:(NSString *)fileUrl
{
    NSString * localPath = [self localFileDir];
    if(fileUrl && fileUrl.length>0)
    {
        if([self isFullFilePath:fileUrl])
            return fileUrl;
        
        //lowercaseString];
        //    fileUrl = [fileUrl lowercaseString];
        
        NSString * fileName = [self getFileName:fileUrl];
        localPath =  [localPath stringByAppendingPathComponent:fileName];
    }
    return [self getFilePath:localPath];
}
- (NSString *) tempFileFullPath:(NSString *)fileUrl
{
    NSString * localPath = [self tempFileDir];
    if(fileUrl && fileUrl.length>0)
    {
        if([self isFullFilePath:fileUrl])
            return fileUrl;
        
        //lowercaseString];
        //    fileUrl = [fileUrl lowercaseString];
        
        NSString * fileName = [self getFileName:fileUrl];
        localPath =  [localPath stringByAppendingPathComponent:fileName];
    }
    return [self getFilePath:localPath];
}
- (NSString *) recordFileFullPath:(NSString *)fileUrl
{
    NSString * localPath = [self recordDir];
    if(fileUrl && fileUrl.length>0)
    {
        if([self isFullFilePath:fileUrl])
            return fileUrl;
        
        //lowercaseString];
        //    fileUrl = [fileUrl lowercaseString];
        
        NSString * fileName = [self getFileName:fileUrl];
        localPath =  [localPath stringByAppendingPathComponent:fileName];
    }
    return [self getFilePath:localPath];
}
- (NSString *) outputFileFullPath:(NSString *)fileUrl
{
    NSString * localPath = [self outputFileDir];
    if(fileUrl && fileUrl.length>0)
    {
        if([self isFullFilePath:fileUrl])
            return fileUrl;
        
        //lowercaseString];
        //    fileUrl = [fileUrl lowercaseString];
        
        NSString * fileName = [self getFileName:fileUrl];
        localPath =  [localPath stringByAppendingPathComponent:fileName];
    }
    return [self getFilePath:localPath];
}

- (NSString *) getLocalFilePathForUrl:(NSString *)webUrl extension:(NSString *)ext
{
    if(!webUrl ||webUrl.length==0) return nil;
    NSString * fileName = [webUrl lastPathComponent];
    if(ext && ext.length>0)
        fileName = [NSString stringWithFormat:@"%@.%@",fileName,ext];
    else
        fileName = [NSString stringWithFormat:@"%@.mp3",fileName]; //只有Mp3下载，图片使用缓存技术
    
    NSString * dir = [self localFileDir];
    return [self getFilePath:[dir stringByAppendingPathComponent:fileName]];
    
}
- (NSString *) getOuputFilePathForUrl:(NSString *)webUrl extension:(NSString *)ext
{
    if(!webUrl ||webUrl.length==0) return nil;
    NSString * fileName = [webUrl lastPathComponent];
    if(ext && ext.length>0)
        fileName = [NSString stringWithFormat:@"%@.%@",fileName,ext];
    else
        fileName = [NSString stringWithFormat:@"%@.mp3",fileName]; //只有Mp3下载，图片使用缓存技术
    
    NSString * dir = [self outputFileDir];
    return [self getFilePath:[dir stringByAppendingPathComponent:fileName]];
    
}

- (NSString *) outputFileDir
{
    return @"output";
    //    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    //    NSString *documentsDirectory = [paths objectAtIndex:0];
    //    return [documentsDirectory stringByAppendingPathComponent:@"output"];
}
- (NSString *) localFileDir
{
    //    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    //    NSString *documentsDirectory = [paths objectAtIndex:0];
    //    return [documentsDirectory stringByAppendingPathComponent:@"localfiles"];
    return @"localfiles";
}
- (NSString *) webRootFileDir
{
    return @"docroot";
    //    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    //    NSString *documentsDirectory = [paths objectAtIndex:0];
    //    return [documentsDirectory stringByAppendingPathComponent:@"docroot"];
}
- (NSString *) tempFileDir
{
    if(!tempFileRoot_ || tempFileRoot_.length==0)
    {
        //        NSArray *paths =NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        //        NSString *documentsDirectory = [paths objectAtIndex:0];
        //        tempFileRoot_ =  PP_RETAIN([documentsDirectory stringByAppendingPathComponent:@"tempfiles"]);
        tempFileRoot_ = @"tempfiles";
    }
    return tempFileRoot_;
}
- (NSString *) convertFileDir
{
    return @"AudioConvert";
    //    NSArray *paths =NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    //    NSString *documentsDirectory = [paths objectAtIndex:0];
    //    return [documentsDirectory stringByAppendingPathComponent:@"AudioConvert"];
}
- (NSString *) coverStoryFileDir
{
    return @"CoverStory";
    //    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    //
    //    NSString *movieDirectory = [NSString stringWithFormat:@"%@/CoverStory", documentsPath];
    //
    //    BOOL isDirectory;
    //
    //    NSFileManager *fileManager = [NSFileManager defaultManager];
    //
    //    if (![fileManager fileExistsAtPath:movieDirectory isDirectory:&isDirectory]) {
    //        [fileManager createDirectoryAtPath:movieDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    //    }
    //    return movieDirectory;
}
-(NSString *)mtvPlusFileDir
{
    return @"MtvPlus";
    //    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    //
    //    NSString *movieDirectory = [NSString stringWithFormat:@"%@/MtvPlus", documentsPath];
    //
    //    BOOL isDirectory;
    //
    //    NSFileManager *fileManager = [NSFileManager defaultManager];
    //
    //    if (![fileManager fileExistsAtPath:movieDirectory isDirectory:&isDirectory]) {
    //        [fileManager createDirectoryAtPath:movieDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    //    }
    //    return movieDirectory;
}
-(NSString *)lyricFilrDir
{
    return @"Lyric";
    //    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    //
    //    NSString *movieDirectory = [NSString stringWithFormat:@"%@/Lyric", documentsPath];
    //
    //    BOOL isDirectory;
    //
    //    NSFileManager *fileManager = [NSFileManager defaultManager];
    //
    //    if (![fileManager fileExistsAtPath:movieDirectory isDirectory:&isDirectory]) {
    //        [fileManager createDirectoryAtPath:movieDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    //    }
    //    return movieDirectory;
}
- (NSString *)recordDir
{
    return @"recordfiles";
    //    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    //    NSString *documentsDirectory = [paths objectAtIndex:0];
    //    return [documentsDirectory stringByAppendingPathComponent:@"recordfiles"];
}
#pragma mark - filename & filePath转换
- (BOOL) isFullFilePath:(NSString *)filePath
{
    NSString * rootPath = [self getRootPath];
    NSUInteger len = rootPath.length;
    
    if(filePath.length>len) //如果是绝对路径，则肯定会超过ApplicationPath的长度
    {
        NSRange range = [filePath rangeOfString:rootPathMatchString_];
        if(range.location!=NSNotFound)
        {
            return YES;
        }
        return NO;
    }
    else
    {
        return NO;
    }
}
- (NSString *) getFileName:(NSString*)filePath
{
    if(!filePath||filePath.length==0) return filePath;
    
    NSString * rootPath = [self getRootPath];
    NSUInteger len = rootPath.length;
    
    if(filePath.length>len) //如果是绝对路径，则肯定会超过ApplicationPath的长度
    {
        NSRange range = [filePath rangeOfString:rootPathMatchString_];
        if(range.location!=NSNotFound)
        {
            filePath = [filePath substringFromIndex:range.location + range.length+1];
            return filePath;
        }
        else
        {
            return [filePath substringFromIndex:len+1];
        }
    }
    else
    {
        return filePath;
    }
}
- (NSString *) getFilePath:(NSString *)fileName
{
    if(!fileName||fileName.length==0) return fileName;
    
    if([self isFullFilePath:fileName])
    {
        return [self checkPathForApplicationPathChanged:fileName isExists:nil];
    }
    else
    {
        NSString * rootPath = [self getRootPath];
        return [rootPath stringByAppendingPathComponent:fileName];
    }
}

- (BOOL)checkAllDireictories
{
    NSString * path = [self localFileDir];
    [HCFileManager createFileDirectories:[self getFilePath:path]];
    path = [self tempFileDir];
    [HCFileManager createFileDirectories:[self getFilePath:path]];
    path = [self recordDir];
    [HCFileManager createFileDirectories:[self getFilePath:path]];
    path = [self coverStoryFileDir];
    [HCFileManager createFileDirectories:[self getFilePath:path]];
    path = [self outputFileDir];
    [HCFileManager createFileDirectories:[self getFilePath:path]];
    path = [self webRootFileDir];
    [HCFileManager createFileDirectories:[self getFilePath:path]];
    path = [self convertFileDir];
    [HCFileManager createFileDirectories:[self getFilePath:path]];
    path = [self lyricFilrDir];
    [HCFileManager createFileDirectories:[self getFilePath:path]];
    path = [self mtvPlusFileDir];
    [HCFileManager createFileDirectories:[self getFilePath:path]];
    return YES;
}
- (NSString *)getApplicationPath
{
    if(!applicationRoot_ || applicationRoot_.length==0)
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSString * regex = @"/Application/[^/]+|/Applications/[^/]+";
        applicationRoot_  = PP_RETAIN([documentsDirectory stringByMatching:regex]);
    }
    return applicationRoot_;
}
- (NSString *)getRootPath
{
    if(!rootPath_ || rootPath_.length==0)
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSString * regex = @"/Application/[^/]+|/Applications/[^/]+";
        NSRange range = [documentsDirectory rangeOfRegex:regex];
        if(range.location!=NSNotFound)
        {
            rootPathMatchString_  = PP_RETAIN([documentsDirectory substringFromIndex:range.location]);
        }
        else
        {
            NSLog(@"不可能的事发生了!.....");
            rootPathMatchString_ = nil;
        }
        rootPath_ = PP_RETAIN(documentsDirectory);
    }
    return rootPath_;
}
//filetype 0:MTV的路径(FilePath)   1:唱的声音的路径(AudioPath)
- (NSString *)checkPathForApplicationPathChanged:(NSString *)orgPath mtvID:(NSInteger)mtvID filetype:(short)fileType isExists:(BOOL*)isExists
{
    NSString * newPath = [self checkPathForApplicationPathChanged:orgPath isExists:isExists];
    if(isExists)
    {
        newPath = [[UDManager sharedUDManager]getFileName:newPath];
        //更新本地文件，防止上传下载时出错
        if(mtvID!=0)
        {
//            dispatch_async([DBHelper_WT getDBQueue], ^{
//                if(fileType==1)
//                {
//                    [DBHelper_WT updateMtvAudioPath:mtvID audioPath:newPath];
//                }
//                else
//                {
//                    [DBHelper_WT updateMtvFilePath:mtvID filePath:newPath];
//                }
//            });
        }
    }
    return newPath;
}
- (NSString *)removeApplicationPath:(NSString *)filePath
{
    if(!filePath || filePath.length==0) return filePath;
    NSString * regex = @".*/Application/[^/]+/|.*/Applications/[^/]+/";
    return [filePath stringByReplacingOccurrencesOfRegex:regex withString:@""];
}
- (NSString *)checkPathForApplicationPathChanged:(NSString *)orgPath isExists:(BOOL*)isExists
{
    if(!orgPath)
    {
        if(isExists) *isExists = NO;
        return nil;
    }
    
    orgPath = [HCFileManager checkPath:orgPath];
    NSFileManager * fm = [NSFileManager defaultManager];
    if([fm fileExistsAtPath:orgPath])
    {
        if(isExists)
        {
            *isExists = YES;
        }
        return orgPath;
    }
    
    NSString * regex = @"/Application/[^/]+|/Applications/[^/]+";
    NSString * localApplication = [self getApplicationPath];
    if(localApplication)
    {
        NSString * newPath = [orgPath stringByReplacingOccurrencesOfRegex:regex withString:localApplication];
        if([fm fileExistsAtPath:newPath])
        {
            if(isExists) *isExists = YES;
            NSLog(@"path changed ?:\n orgPath: %@ --> \n newPath: %@",orgPath,newPath);
            return newPath;
        }
        else
        {
            if(isExists) *isExists = NO;
            return newPath;
        }
    }
    else
    {
        if(isExists) *isExists = NO;
    }
    return orgPath;
}
- (BOOL)isFileExistAndNotEmpty:(NSString *)filePath size:(UInt64 *)size
{
    if(!filePath || filePath.length==0) return NO;
    BOOL isExists = [self existFileAtPath:filePath];
    if(isExists)
    {
        NSError * error = nil;
        UInt64 sizeTemp =  [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error] fileSize];
        if(error)
        {
            NSLog(@" get file [%@] size failure:%@",filePath,[error description]);
        }
        if(size)
        {
            *size = sizeTemp;
        }
        if(sizeTemp > 0)
        {
            return YES;
        }
        else
            return NO;
    }
    else
    {
        return NO;
    }
}
- (BOOL)isFileExistAndNotEmpty:(NSString *)filePath size:(UInt64 *)size  pathAlter:(NSString**)pathAlter
{
    if(!filePath || filePath.length==0) return NO;
    BOOL isExists = NO;
    NSString * newPath = [self checkPathForApplicationPathChanged:filePath isExists:&isExists];
    if(isExists)
    {
        NSError * error = nil;
        UInt64 sizeTemp =  [[[NSFileManager defaultManager] attributesOfItemAtPath:newPath error:&error] fileSize];
        if(error)
        {
            NSLog(@" get file [%@] size failure:%@",filePath,[error description]);
        }
        if(size)
        {
            *size = sizeTemp;
        }
        if(sizeTemp > 0)
        {
            if(pathAlter)
            {
                *pathAlter = newPath;
            }
            return YES;
        }
        else
            return NO;
    }
    else
    {
        return NO;
    }
}

- (BOOL) isKeyValid:(NSString *)key
{
    if(key && key.length>0)
    {
        return YES;
    }
    return NO;
}
- (BOOL) insertItemToDB:(UDInfo *) item
{
    if(item && [self isKeyValid:item.Key])
    {
        DBHelper * db =  [DBHelper sharedDBHelper];
        return [db insertData:item needOpenDB:YES forceUpdate:YES];
    }
    return NO;
}
- (UDInfo *)queryItemFromDB:(NSString *)key
{
    __block UDInfo * itemDB = nil;
    if (![DBHelper_WT isDBThread]) {
        dispatch_sync([DBHelper_WT getDBQueue], ^{
            itemDB = [self queryItemFromDBInThread:key];
        });
    }
    else{
        itemDB = [self queryItemFromDBInThread:key];
    }
    return itemDB;
}

- (UDInfo *)queryItemFromDBInThread:(NSString *)key
{
    UDInfo * itemDB = [UDInfo new];
    if(![self isKeyValid:key]) return nil;
    //    if([NSThread isMainThread])
    //    {
    //从本地数据库中取读，如果没有则返回Nil
    DBHelper * db =  [DBHelper sharedDBHelper];
    NSString * sql = [NSString stringWithFormat:@"select * from udinfos where key='%@';",key];
    if([db open])
    {
        [db execWithEntity:itemDB sql:sql];
        [db close];
        if(itemDB.Key)
        {
            return PP_AUTORELEASE(itemDB);
        }
        PP_RELEASE(itemDB);
    }
    //    }
    //    else
    //    {
    //        __block UDInfo * itemDB = nil;
    //        dispatch_sync(dispatch_get_main_queue(), ^(void)
    //                       {
    //                           DBHelper * db =  [DBHelper sharedDBHelper];
    //                           NSString * sql = [NSString stringWithFormat:@"select * from udinfos where key='%@';",key];
    //                           itemDB = [UDInfo new];
    //                           if([db open])
    //                           {
    //                               [db execWithEntity:itemDB sql:sql];
    //                               [db close];
    //                           }
    //                           else
    //                           {
    //
    //                           }
    //                       });
    ////        while (!itemDB) {
    ////            [NSThread sleepForTimeInterval:0.05];
    ////        }
    //        if(itemDB.Key)
    //        {
    //            return PP_AUTORELEASE(itemDB);
    //        }
    //        PP_RELEASE(itemDB);
    //    }
    return nil;
}

- (BOOL)removeItemFromDB:(NSString *)key
{
    if(![self isKeyValid:key]) return NO;
    //从本地数据库中取读，如果没有则返回Nil
    DBHelper * db =  [DBHelper sharedDBHelper];
    NSString * sql = [NSString stringWithFormat:@"delete from udinfos where key='%@';",key];
    if([db open])
    {
        BOOL ret = [db execNoQuery:sql];
        [db close];
        return ret;
    }
    return NO;
    
}
#pragma mark - cache check and clear
- (UInt64) getSizeFreeForDevice
{
    struct statfs buf;
    long long freespace = -1;
    if(statfs("/var", &buf) >= 0){
        freespace = (long long)(buf.f_bsize * buf.f_bfree);
    }
    return freespace;
    //    return [NSString stringWithFormat:@"手机剩余存储空间为：%qi MB" ,freespace/1024/1024];
}
- (CGFloat) getCacheSize:(BOOL)includeMyVideo
{
    NSString * path = [self tempFileFullPath:nil];
    CGFloat tempSize = [self folderSizeAtPath:path];
    if(includeMyVideo)
    {
        path = [self recordFileFullPath:nil];
        tempSize += [self folderSizeAtPath:path];
        path = [self localFileFullPath:nil];
        tempSize += [self folderSizeAtPath:path];
        // 去除保留视频音频的内存
        for (NSString *fileName in reservedFileNames_) {
            NSString *filePath = [path stringByAppendingPathComponent:fileName];
            tempSize -= ([self fileSizeAtPath:filePath]/(1024.0*1024.0));
        }
    }
    path = [self getFilePath:[self convertFileDir]];
    CGFloat convertSize = [self folderSizeAtPath:path];
    tempSize +=  convertSize;
    
    path = [self getFilePath:[self lyricFilrDir]];
    convertSize = [self folderSizeAtPath:path];
    tempSize +=  convertSize;
    
    path = [self getFilePath:[self outputFileDir]];
    convertSize = [self folderSizeAtPath:path];
    tempSize +=  convertSize;
    
    path = [self getFilePath:[self mtvPlusFileDir]];
    convertSize = [self folderSizeAtPath:path];
    tempSize +=  convertSize;
    
    path = [self getFilePath:[self localFileDir]];
    convertSize = [self folderSizeAtPath:path];
    tempSize +=  convertSize;
    
    path = [self getFilePath:[self coverStoryFileDir]];
    convertSize = [self folderSizeAtPath:path];
    return tempSize + convertSize;
}

- (CGFloat) getCacheSizeIncludeRecordDir:(BOOL)includeRecordDir includeLocalDir:(BOOL)includeLocalDir
{
    NSString * path = [self tempFileFullPath:nil];
    CGFloat tempSize = [self folderSizeAtPath:path];
    if(includeRecordDir)
    {
        path = [self recordFileFullPath:nil];
        tempSize += [self folderSizeAtPath:path];
    }
    if (includeLocalDir) {
        path = [self localFileFullPath:nil];
        tempSize += [self folderSizeAtPath:path];
        // 去除保留视频音频的内存
        for (NSString *fileName in reservedFileNames_) {
            NSString *filePath = [path stringByAppendingPathComponent:fileName];
            tempSize -= ([self fileSizeAtPath:filePath]/(1024.0*1024.0));
        }
    }
    path = [self getFilePath:[self convertFileDir]];
    CGFloat convertSize = [self folderSizeAtPath:path];
    tempSize +=  convertSize;
    
    path = [self getFilePath:[self lyricFilrDir]];
    convertSize = [self folderSizeAtPath:path];
    tempSize +=  convertSize;
    
    path = [self getFilePath:[self outputFileDir]];
    convertSize = [self folderSizeAtPath:path];
    tempSize +=  convertSize;
    
    path = [self getFilePath:[self mtvPlusFileDir]];
    convertSize = [self folderSizeAtPath:path];
    tempSize +=  convertSize;
    
    path = [self getFilePath:[self coverStoryFileDir]];
    convertSize = [self folderSizeAtPath:path];
    return tempSize + convertSize;
}

- (BOOL) clearCachePath:(BOOL)includeMyVideo
{
    NSString * path = [self tempFileFullPath:nil];
    
    [self removeFilesAtPath:path];
    if(includeMyVideo)
    {
        path = [self recordFileFullPath:nil];
        [self removeFileAtPath:path];
        
        path = [self localFileFullPath:nil];
        [self removeFilesAtPath:path matchRegex:@"\\.(mp4|m4a|jpg|lrc|mp3)$"];
    }
    path = [self getFilePath:[self convertFileDir]];
    [self removeFilesAtPath:path];
    
    path = [self getFilePath:[self lyricFilrDir]];
    [self removeFilesAtPath:path];
    
    path = [self getFilePath:[self outputFileDir]];
    [self removeFilesAtPath:path];
    
    path = [self getFilePath:[self mtvPlusFileDir]];
    [self removeFilesAtPath:path];
    
    path = [self getFilePath:[self coverStoryFileDir]];
    BOOL ret = ret = [self removeFilesAtPath:path];
    return ret;
}
#pragma mark - help for helper
//单个文件的大小
- (long long) fileSizeAtPath:(NSString*) filePath{
    NSFileManager* manager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if ([manager fileExistsAtPath:filePath isDirectory:&isDir] ){
        if(isDir)
        {
            return [self folderSizeAtPath:filePath];
        }
        else
        {
            NSError * error = nil;
            long long size =  [[manager attributesOfItemAtPath:filePath error:&error] fileSize];
            if(error)
            {
                NSLog(@" get file [%@] size failure:%@",filePath,[error description]);
            }
            return size;
        }
    }
    return 0;
}
//遍历文件夹获得文件夹大小，返回多少M
- (CGFloat ) folderSizeAtPath:(NSString*) folderPath{
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return 0;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    long long folderSize = 0;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        folderSize += [self fileSizeAtPath:fileAbsolutePath];
    }
    return folderSize/(1024.0*1024.0);
}
- (BOOL) removeFilesAtPath:(NSString * )folderPath
{
    BOOL ret = YES;
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return 0;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        if([self removeFileAtPath:fileAbsolutePath]==NO)
        {
            ret = NO;
        }
    }
    return ret;
}
- (BOOL) removeFilesAtPath:(NSString * )folderPath matchRegex:(NSString *)regexString
{
    BOOL ret = YES;
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return NO;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        if([fileName isMatchedByRegex:regexString])
        {
            // 去除保留视频音频的内存
            BOOL equal = NO;
            for (NSString *file in reservedFileNames_) {
                if ([fileName isEqualToString:file]) {
                    equal = YES;
                    break;
                }
            }
            if (equal) continue;
            
            NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
            NSError * error = nil;
            [manager removeItemAtPath:fileAbsolutePath error:&error];
            if(error)
            {
                NSLog(@" remove file [%@] error:%@",fileAbsolutePath,[error description]);
                ret = NO;
            }
        }
    }
    return ret;
}
- (BOOL) removeFilesAtPath:(NSString * )folderPath matchRegex:(NSString *)regexString withoutPrefixList:(NSArray *)prefixList
{
    BOOL ret = YES;
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return NO;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        if([fileName isMatchedByRegex:regexString])
        {
            NSLog(@"%@",fileName);
            // 去除保留视频音频的内存
            BOOL equal = NO;
            for (NSString *file in reservedFileNames_) {
                if ([fileName isEqualToString:file]) {
                    equal = YES;
                }
            }
            if (equal) continue;
            
            BOOL has = NO;
            for (NSString *prefix in prefixList) {
                if ([fileName hasPrefix:prefix]) {
                    has = YES;
                }
            }
            if (has) continue;
            
            NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
            NSError * error = nil;
            [manager removeItemAtPath:fileAbsolutePath error:&error];
            if(error)
            {
                NSLog(@" remove file [%@] error:%@",fileAbsolutePath,[error description]);
                ret = NO;
            }
        }
    }
    return ret;
}
- (BOOL) removeFilesAtPath:(NSString * )folderPath withoutPrefixList:(NSArray *)prefixList
{
    BOOL ret = YES;
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return NO;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    while ((fileName = [childFilesEnumerator nextObject]) != nil)
    {
        // 去除保留视频音频的内存
        BOOL equal = NO;
        for (NSString *file in reservedFileNames_) {
            if ([fileName isEqualToString:file]) {
                equal = YES;
            }
        }
        if (equal) continue;
        
        BOOL has = NO;
        for (NSString *prefix in prefixList) {
            if ([fileName hasPrefix:prefix]) {
                has = YES;
            }
        }
        if (has) continue;
        
        NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        NSError * error = nil;
        [manager removeItemAtPath:fileAbsolutePath error:&error];
        if(error)
        {
            NSLog(@" remove file [%@] error:%@",fileAbsolutePath,[error description]);
            ret = NO;
        }
    }
    return ret;
}
- (BOOL) removeFilesAtPath:(NSString * )folderPath withoutRegex:(NSString *)regexString
{
    BOOL ret = YES;
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return NO;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        if(![fileName isMatchedByRegex:regexString])
        {
            // 去除保留视频音频的内存
            BOOL equal = NO;
            for (NSString *file in reservedFileNames_) {
                if ([fileName isEqualToString:file]) {
                    equal = YES;
                }
            }
            if (equal) continue;
            
            NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
            NSError * error = nil;
            [manager removeItemAtPath:fileAbsolutePath error:&error];
            if(error)
            {
                NSLog(@" remove file [%@] error:%@",fileAbsolutePath,[error description]);
                ret = NO;
            }
        }
    }
    return ret;
}
- (BOOL) removeFileAtPath:(NSString*) filePath{
    NSFileManager* manager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL ret  = YES;
    if ([manager fileExistsAtPath:filePath isDirectory:&isDir] ){
        if(isDir)
        {
            return [self removeFilesAtPath:filePath];
        }
        else
        {
            NSError * error = nil;
            ret = [manager removeItemAtPath:filePath error:&error];
            if(error)
            {
                NSLog(@" remove file [%@] error:%@",filePath,[error description]);
            }
            return ret;
        }
    }
    return NO;
}
- (BOOL)existFileAtPath:(NSString *)path
{
    NSFileManager* manager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL ret  = NO;
    if ([manager fileExistsAtPath:path isDirectory:&isDir] ){
        ret = YES;
    }
    return ret;
}

#pragma mark --关于缓存的视频截图
- (NSString *)getThumnatePath:(NSString *)filename minsecond:(int)minsecond size:(CGSize)size
{
    if(!filename)
    {
        filename = @"";
    }
    if([filename rangeOfString:@"/"].length>0)
    {
        filename = [filename lastPathComponent];
    }
    NSString * path =  [NSString stringWithFormat:@"%@_%@.%@.jpg",filename,[CommonUtil stringWithFixedLength:minsecond withLength:6],NSStringFromCGSize(size)];
    return [self tempFileFullPath:path];
}
- (BOOL) removeThumnates:(NSString *)orgFileName size:(CGSize) size
{
    if(!orgFileName)
    {
        orgFileName = @"";
    }
    if([HCFileManager isLocalFile:orgFileName])
    {
        orgFileName = [orgFileName lastPathComponent];
    }
    NSString * regEx = nil;
    if(size.width ==0 || size.height ==0)
        regEx = [NSString stringWithFormat:@"%@_\\d+\\..*\\.jpg",orgFileName];
    else
        regEx = [NSString stringWithFormat:@"%@_\\d+\\.\\{\\d+,\\d+\\}\\.jpg",orgFileName];
    NSString * dir = [self tempFileFullPath:nil];
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:dir]) return NO;
    
    BOOL ret = YES;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:dir] objectEnumerator];
    NSString* fileName;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        if([fileName isMatchedByRegex:regEx])
        {
            NSString* fileAbsolutePath = [dir stringByAppendingPathComponent:fileName];
            if(![self removeFileAtPath:fileAbsolutePath])
            {
                ret = NO;
            }
        }
    }
    return ret;
}
- (BOOL) removeTempVideos
{
    
    //NEED FIXIT 因为还未上传文件就被删除了，所以暂时注释
    return NO;
    //e148dd95a5ce6ac57211ab517e0714aa-0-600.mp4
    NSString * regEx = nil;
    regEx = [NSString stringWithFormat:@"(\\d+)\\.mp4|[a-f0-9]+\\-\\d+\\-\\d+\\.(mp4|chk)"];
    NSString * dir = [self tempFileFullPath:nil];
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:dir]) return NO;
    
    BOOL ret = YES;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:dir] objectEnumerator];
    NSString* fileName;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        if([fileName isMatchedByRegex:regEx])
        {
            NSString* fileAbsolutePath = [dir stringByAppendingPathComponent:fileName];
            if(![self removeFileAtPath:fileAbsolutePath])
            {
                ret = NO;
            }
        }
    }
    return ret;
}
#pragma mark - get cache
- (NSString *)getContentCachedByUrl:(NSString *)urlString ext:(NSString *)ext
{
    if(!urlString ||urlString.length<5) return nil;
    
    NSURL *lrcurl = [NSURL URLWithString:urlString];
    NSString * fileName = [HCFileManager getMD5FileNameKeepExt:urlString defaultExt:ext];
    NSString * cacheFile = [[UDManager sharedUDManager]tempFileFullPath:fileName];
    NSError * error = nil;
    NSString * content = nil;
    BOOL isExists = NO;
    if ([self fileSizeAtPath:cacheFile]>0) {
        isExists = YES;
        content =  [NSString stringWithContentsOfFile:cacheFile encoding:NSUTF8StringEncoding error:&error];
        if(error)
        {
            NSLog(@"read cached file %@ failure:%@",cacheFile,[error localizedDescription]);
        }
        else
        {
            return content;
        }
    }
    
    NSData *lrcData = [NSData dataWithContentsOfURL:lrcurl];
    content = [[NSString alloc]initWithData:lrcData encoding:NSUTF8StringEncoding];
    
    //save cache
    if(isExists || [self existFileAtPath:cacheFile])
    {
        [self removeFileAtPath:cacheFile];
    }
    [content writeToFile:cacheFile atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if(error)
    {
        NSLog(@"write cached file %@ failure:%@",cacheFile,[error localizedDescription]);
    }
    
    return content;
}
- (NSString *)getLyricCachedByUrl:(NSString *)urlString ext:(NSString *)ext
{
    if(!urlString ||urlString.length<5) return nil;
    
    NSURL *lrcurl = [NSURL URLWithString:urlString];
    NSString * fileName = [HCFileManager getMD5FileNameKeepExt:urlString defaultExt:ext];
    //    NSString * cacheFile = [[UDManager sharedUDManager]tempFileFullPath:fileName];
    NSString * cacheFile =  [[self getFilePath:[self lyricFilrDir]]stringByAppendingPathComponent:fileName];
    NSError * error = nil;
    NSString * content = nil;
    BOOL isExists = NO;
    if ([self fileSizeAtPath:cacheFile]>0) {
        isExists = YES;
        content =  [NSString stringWithContentsOfFile:cacheFile encoding:NSUTF8StringEncoding error:&error];
        if(error)
        {
            NSLog(@"read cached file %@ failure:%@",cacheFile,[error localizedDescription]);
        }
        else
        {
            return content;
        }
    }
    
    NSData *lrcData = [NSData dataWithContentsOfURL:lrcurl];
    content = [[NSString alloc]initWithData:lrcData encoding:NSUTF8StringEncoding];
    
    //save cache
    if(isExists || [self existFileAtPath:cacheFile])
    {
        [self removeFileAtPath:cacheFile];
    }
    [content writeToFile:cacheFile atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if(error)
    {
        NSLog(@"write cached file %@ failure:%@",cacheFile,[error localizedDescription]);
    }
    
    return content;
}
- (BOOL)getImageDataFromUrl:(NSString *)urlString size:(CGSize)size completed:(void(^)(UIImage * image,NSError * error))completed
{
    if(![HCFileManager isUrlOK:urlString])
    {
        if([HCFileManager isExistsFile:urlString])
        {
            UIImage * image = [UIImage imageWithContentsOfFile:[HCFileManager checkPath:urlString]];
            completed(image,nil);
        }
        else
        {
            NSError * error = [NSError errorWithDomain:@"com.seenvoice.maiba" code:-999902 userInfo:@{NSLocalizedDescriptionKey:@"文件不存在"}];
            completed(nil,error);
        }
    }
    
    NSString * imgUrl = [HCImageItem urlWithWH:urlString width:size.width height:size.height mode:2];
    
        SDWebImageManager * manager = [SDWebImageManager sharedManager];
        [manager downloadImageWithURL:[NSURL URLWithString:imgUrl] options:SDWebImageHighPriority progress:
         ^(NSInteger receivedSize,NSInteger expectedSize)
         {
             //             NSLog(@"get cover image for merge failure :%f",receivedSize * 1.0f/expectedSize);
         }
                            completed:
         ^(UIImage * image,NSError * error,SDImageCacheType cacheType,BOOL finished,NSURL * imageURL)
         {
             if(completed)
             {
                 completed(image,error);
             }
         }];
    return YES;
}

#pragma mark - test
//测试
// testUpload
- (void)testProgress
{
    UDInfo * item = [[UDInfo alloc]init];
    item.Status = 1;
    item.Key = [NSString stringWithFormat:@"asdfasdfasdf %@ ",[CommonUtil getCurrentTime]];
    item.Percent = 0.1;
    
    //    [[NSNotificationCenter defaultCenter]removeObserver:self name:NT_UPLOADSTATECHANGED object:nil];
    //    [[NSNotificationCenter defaultCenter]removeObserver:self name:NT_UPLOADPROGRESSCHANGED object:nil];
    //    [[NSNotificationCenter defaultCenter]removeObserver:self name:NT_UPLOADCOMPLETED object:nil];
    
    [[NSNotificationCenter defaultCenter]postNotificationName:NT_UPLOADPROGRESSCHANGED object:item];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        item.Percent = 0.2;
        [self testChangeProgress:item];
    });
    
}
- (void)testChangeProgress:(UDInfo*)item
{
    [[NSNotificationCenter defaultCenter]postNotificationName:NT_UPLOADPROGRESSCHANGED object:item];
    
    //0 未开始或暂停 1处理中 2 失败 4完成 5 因为网络，系统自动暂停,6用户取消 9 本地文件不存在
    
    if(item.Percent>=1)
    {
        item.Status = 4;
        [[NSNotificationCenter defaultCenter]postNotificationName:NT_UPLOADCOMPLETED object:item];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            item.Status = 2;
            item.ErrorInfo = @"未知原因";
            [[NSNotificationCenter defaultCenter]postNotificationName:NT_UPLOADSTATECHANGED object:item];
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self testProgress];
        });
    }
    else
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            item.Percent += 0.1;
            [self testChangeProgress:item];
        });
    }
}
@end
