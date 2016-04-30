//
//  NSString+CC.m
//  
//
//  Created by Michael Du on 13-4-15.
//  Copyright (c) 2013年 MichaelDu. All rights reserved.
//

#import "NSString+CC.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (CC)

+ (NSString *)newUUID{
    CFUUIDRef uuidRef = CFUUIDCreate( nil );
    NSString *uuidString = (NSString *)CFBridgingRelease(CFUUIDCreateString( nil, uuidRef ));
    CFRelease(uuidRef);
    return [uuidString lowercaseString];
}

//+ (NSString *)mechineID{
//    return [[UIDevice currentDevice] uniqueGlobalIdentifier];
//}

- (NSString *)md5Digest{
    const char *cStr = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++){
        [hash appendFormat:@"%02x", result[i]];
    }
    return hash;
}

- (NSString *)sha1Digest{
    const char *cStr = [self UTF8String];
    unsigned char result[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(cStr, (CC_LONG)strlen(cStr), result);
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++){
        [hash appendFormat:@"%02x", result[i]];
    }
    return hash;
}

//- (CGSize)sizeWithFont:(UIFont *)font byWidth:(CGFloat)width{
//	return [self sizeWithFont:font
//			constrainedToSize:CGSizeMake(width, 999999.0f)
//				lineBreakMode:NSLineBreakByWordWrapping];
//}
//
//- (CGSize)sizeWithFont:(UIFont *)font byHeight:(CGFloat)height{
//	return [self sizeWithFont:font
//			constrainedToSize:CGSizeMake(999999.0f, height)
//				lineBreakMode:NSLineBreakByWordWrapping];
//}

- (BOOL)isMatch:(NSString *)regex{
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [predicate evaluateWithObject:self];
}

static NSDateFormatter *dateFormatter = nil;
- (NSDate *)dateWithFormate:(NSString *)formate{
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
    }
    [dateFormatter setDateFormat:formate];
    return [dateFormatter dateFromString:self];
}

@end
