//
//  HCEPropetyType.m
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-11-13.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import "HCEPropetyType.h"
#define skipWhitespace(c) while (isspace(*c)) c++
//#define skipNodotspace(c) while ((*c)!=',') c++

@implementation HCEPropertyType
@synthesize IsAssign;
@synthesize IsCopy;
@synthesize IsReadOnly;
@synthesize IsRetain;
@synthesize IsRedirectSet;
@synthesize IsWeak;
@synthesize IsGarbage;
@synthesize IsDynamic;
@synthesize IsConst;
@synthesize IsChar;
@synthesize Name;
@synthesize Code;
@synthesize Type;
@synthesize Getter;
@synthesize Setter;

static char ctrl[0x03] = {',','\0'};
//Ti,N,VMessageID
//T@"NSString",&,N,VSenderHeadPortrait
//T@"NSString",N,GgetEmail,SsetEmail:
//T@"NSString",&,N,VBlog
//TC,N,VSex
//Tc,N,VIsMobileValid
//T@"NSString",N,GgetMobile,SsetMobile:
//Ti,N,VProvinceID

//用于区分一段字符结束的过程
//+ (void)initialize {
//    ctrl[0] = '\"';
//    ctrl[1] = ',';
//    ctrl[2] = 0;
//}

- (BOOL)scanRestOfSetGet
{
    NSMutableString * o = nil;
    if(*c == 'G')
    {
        c++;
        if([self scanRestOfString:&o])
            Getter = PP_RETAIN(o);//[o retain];
        else
            return NO;
        IsRedirectSet = YES;
        return YES;
    }
    else if(*c =='S')
    {
        c++;
        if([self scanRestOfString:&o])
            Setter = PP_RETAIN(o);//[o retain];
        else
            return NO;
        IsRedirectSet = YES;
        return YES;
    }
    return NO;
}
- (BOOL)scanRestOfOther
{
    if(*(c +1)==','|| *(c+1)=='\0')
    {
        switch (*c) {
            case 'R':
                IsReadOnly = YES;
                break;
            case 'C':
                IsCopy = YES;
                break;
            case '&':
                IsRetain = YES;
                break;
            case 'W':
                IsWeak = YES;
                break;
            case 'D':
                IsDynamic = YES;
                break;
            case 'P':
                IsGarbage = YES;
                break;
            default:
                break;
        }
        c++;
        return YES;
    }
    return NO;
}
- (BOOL)scanRestOfName
{
    NSMutableString * o = nil;
//    if (!strncmp(c, "V", 1)) {
//        c ++;
        [self scanRestOfString:&o];
    Name = PP_RETAIN(o);// [o retain];
        return YES;
//    }
//    return NO;
}
- (BOOL)scanRestOfString:(NSMutableString **)o
{
    size_t len = strcspn(c, ctrl);
    if (len && (*(c + len) == ','||*(c+len)=='\0'))
    {
//        *o = [[[NSMutableString alloc] initWithBytes:(char*)c length:len encoding:NSUTF8StringEncoding] autorelease];
        *o = PP_AUTORELEASE([[NSMutableString alloc] initWithBytes:(char*)c length:len encoding:NSUTF8StringEncoding]);
        c += len;
//        if(*(c+len)==',') c++;
        return YES;
    }
    return NO;
}
-(BOOL)scanRestOfType
{
//    if (strncmp(c, "T", 1)) return NO;
//    c++;
    NSMutableString * o = nil;
    if (!strncmp(c, "r", 1)) {
        c ++ ;
        if([self scanRestOfString:&o])
            Type = PP_RETAIN(o);//[o retain];
        else
            Type = PP_RETAIN(@"r");//[@"r" retain];
        IsConst = YES;
//        skipNodotspace(c);
        return YES;
    }
    else
    {
        IsConst = NO;
        if (!strncmp(c, "c", 1)) {
            c++;
            IsChar = YES;
        }
        if([self scanRestOfString:&o])
            Type = PP_RETAIN(o);// [o retain];
        else
            Type = PP_RETAIN(@"c");//[@"c" retain];
//        skipNodotspace(c);
        return YES;
    }
    return NO;
}
-(HCEPropertyType *) initWithCodeNew:(const char *)code Name:(const char *)pName
{
    self = [super init];
    if(self)
    {
        IsReadOnly = FALSE;
        IsRedirectSet = FALSE;
        IsRetain  = FALSE;
        
        //NSEPropertyType * item = [[NSEPropertyType alloc] init];
        if(code!=nil)
        {
            c = code;
            
            while (*c) {
                skipWhitespace(c);
                if(*c==',') c++;
                switch (*c) {
                    case ':':
                        c++;
                        IsRedirectSet = YES;
                        [self scanRestOfSetGet];
                        break;
                    case 'V':
                        c++;
                        if(!Name)
                        {
                            [self scanRestOfName];
                        }
                        break;
                    case 'T':
                        c++;
                        if(!Type)
                        {
                            [self scanRestOfType];
                        }
                        break;
                    case 'G':
                    case 'S':
                        [self scanRestOfSetGet];
                        break;
                    default:
                        if(![self scanRestOfOther])
                        {
                            if(!Type)
                            {
                                [self scanRestOfType];
                            }
                        }
                        break;
                }
            };
        }
        if(!Name)
            Name = PP_RETAIN([NSString stringWithCString:pName encoding:NSUTF8StringEncoding ]);// retain];
    }
    return self;
}
-(HCEPropertyType *) initWithCode:(NSString *)code Name:(NSString*)pName
{
    self = [super init];
    if(self)
    {
        IsReadOnly = FALSE;
        IsRedirectSet = FALSE;
        IsRetain  = FALSE;
    
        //NSEPropertyType * item = [[NSEPropertyType alloc] init];
        Code = PP_RETAIN(code);//[code retain];
        if(code!=nil)
        {
            c = [code UTF8String];

            while (*c) {
                skipWhitespace(c);
                if(*c==',') c++;
                switch (*c++) {
                    case ':':
                        IsRedirectSet = YES;
                        [self scanRestOfSetGet];
                        break;
                    case 'V':
                        if(!Name)
                        {
                            [self scanRestOfName];
                        }
                        break;
                    case 'T':
                        if(!Type)
                        {
                            [self scanRestOfType];
                        }
                        break;
                    default:
                        [self scanRestOfOther];
                        break;
                }
            };
        }
        if(!Name)
            Name = PP_RETAIN(pName);//[pName retain];
    }
    return self;
}
//只读的和改写了Setter的均不能赋值，后期可能再完善。
-(BOOL)canSetValue
{
    return !IsReadOnly
    &&!IsRedirectSet;
}
-(BOOL)complexValue
{
    if(IsChar) return FALSE;
    if(Type==nil) return TRUE;
    if([Type compare:@"c"]==0
       ||[Type compare:@"C"]==0
       ||[Type compare:@"d"]==0
       ||[Type compare:@"i"]==0
       ||[Type compare:@"f"]==0
       ||[Type compare:@"l"]==0
       ||[Type compare:@"s"]==0
       ||[Type compare:@"I"]==0
       ||[Type compare:@"S"]==0
       ||[Type compare:@"B"]==0
       ||[Type compare:@"q"]==0
       ||[Type compare:@"Q"]==0
       ||[Type compare:@"b"]==0
       )
    {
        
        return FALSE;
    }
    else if( [Type compare:@"@"]==0
            ||[Type compare:@"^v"]==0
            ||[Type compare:@"^i"]==0
            ||[Type compare:@"^?"]==0
            ||[Type compare:@"#"]==0
            ||[Type compare:@"*"]==0
            )
    {
        return TRUE;
    }
    else if([Type compare:@"@\"nsstring\"" options:NSCaseInsensitiveSearch]==NSOrderedSame)
    {
        return FALSE;
    }
    else
    {
        return TRUE;
    }
    return TRUE;
}
-(BOOL)isInt
{
    if(
       [Type compare:@"i"]==0
       ||[Type compare:@"C"]==0
       ||[Type compare:@"l"]==0
       ||[Type compare:@"s"]==0
       ||[Type compare:@"I"]==0
       ||[Type compare:@"S"]==0
//       ||[Type compare:@"q"]==0
//       ||[Type compare:@"Q"]==0
       ||[Type compare:@"B"]==0
       )
    {
        return TRUE;
    }
    return FALSE;
}
-(BOOL) isFloat
{
    if([Type compare:@"f"]==0 ||[Type compare:@"d"]==0
       )
    {
        
        return TRUE;
    }
    return FALSE;
}
-(BOOL) isNumber
{
    if([Type compare:@"d"]==0
       ||[Type compare:@"i"]==0
       ||[Type compare:@"C"]==0
       ||[Type compare:@"f"]==0
       ||[Type compare:@"l"]==0
       ||[Type compare:@"s"]==0
       ||[Type compare:@"I"]==0
       ||[Type compare:@"S"]==0
       ||[Type compare:@"q"]==0
       ||[Type compare:@"Q"]==0
       ||[Type compare:@"B"]==0
       )
    {
        
        return TRUE;
    }
    return FALSE;
}
-(BOOL) isChar
{
    if([Type compare:@"c"]==0
       //||[Type compare:@"C"]==0
       
       )
    {
        
        return TRUE;
    }
    return FALSE;
}
-(BOOL) isString
{
    if([Type compare:@"@\"nsstring\"" options:NSCaseInsensitiveSearch]==NSOrderedSame||
       [Type compare:@"@\"nsmutablestring\"" options:NSCaseInsensitiveSearch]==NSOrderedSame||
       [Type compare:@"NSString"  options:NSCaseInsensitiveSearch]==NSOrderedSame||
       [Type compare:@"NSMutableString"  options:NSCaseInsensitiveSearch]==NSOrderedSame)
        return TRUE;
    else
        return FALSE;
}
-(BOOL) isNSData
{
    if([Type compare:@"@\"nsdata\"" options:NSCaseInsensitiveSearch]==NSOrderedSame||
       [Type compare:@"@\"nsmutabledata\"" options:NSCaseInsensitiveSearch]==NSOrderedSame||
       [Type compare:@"NSData"  options:NSCaseInsensitiveSearch]==NSOrderedSame||
       [Type compare:@"NSMutalData"  options:NSCaseInsensitiveSearch]==NSOrderedSame)
        return TRUE;
    else
        return FALSE;
    
}
-(BOOL) isMutableString
{
    if([Type compare:@"NSMutableString"  options:NSCaseInsensitiveSearch]==NSOrderedSame ||
       [Type compare:@"@\"nsmutablestring\"" options:NSCaseInsensitiveSearch]==NSOrderedSame)
        return TRUE;
    return FALSE;
}
-(BOOL)canSaveToData
{
    if(!IsReadOnly && (([self isNumber] &&(!IsRedirectSet)) || (!IsRedirectSet)) && (!IsWeak && !IsGarbage && !IsDynamic))
    {
        if([Type hasPrefix:@"UI"]) //UI控件不能存储
            return NO;
        else
            return YES;
    }
    else
        return NO;
}
-(BOOL) isEntity
{
    if([Type compare:@"HCEntity"  options:NSCaseInsensitiveSearch]==NSOrderedSame)
        return TRUE;
    return FALSE;
}
-(BOOL) isArray
{
    if([Type compare:@"NSMutableArray"  options:NSCaseInsensitiveSearch]==NSOrderedSame ||
       [Type compare:@"@\"NSArray\"" options:NSCaseInsensitiveSearch]==NSOrderedSame)
        return TRUE;
    return FALSE;
}
-(BOOL) isDictionary
{
    if([Type compare:@"NSMutableDictionary"  options:NSCaseInsensitiveSearch]==NSOrderedSame ||
       [Type compare:@"@\"NSDictionary\"" options:NSCaseInsensitiveSearch]==NSOrderedSame)
        return TRUE;
    return FALSE;
}
- (BOOL) isUrl
{
    if(isUrl_ <=0)
    {
    if([Type compare:@"@\"NSUrl\"" options:NSCaseInsensitiveSearch]==NSOrderedSame)
        isUrl_ = 2;
    else
        isUrl_ = 1;
    }
    if(isUrl_ ==2) return YES;
    else  return NO;
}
- (BOOL) isCMTime
{
    if(isCMTime_<=0)
    {
    if([Type compare:@"{?=qiIq}" options:NSCaseInsensitiveSearch]==NSOrderedSame)
        isCMTime_ =2;
    else
        isCMTime_ = 1;
    }
    if(isCMTime_ ==2) return YES;
    else  return NO;
}
- (BOOL) isSize
{
    if(isSize_<=0)
    {
        if([Type compare:@"{CGSize=dd}" options:NSCaseInsensitiveSearch]==NSOrderedSame)
            isSize_ =2;
        else
            isSize_ = 1;
    }
    if(isSize_ ==2) return YES;
    else  return NO;
}
- (BOOL) isPoint
{
    if(isPoint_<=0)
    {
        if([Type compare:@"{CGPoint=dd}" options:NSCaseInsensitiveSearch]==NSOrderedSame)
            isPoint_ =2;
        else
            isPoint_ = 1;
    }
    if(isPoint_ ==2) return YES;
    else  return NO;
    
   
}
- (BOOL) isRect
{
    if(isRect_<=0)
    {
        if([Type compare:@"{CGRect={CGPoint=dd}{CGSize=dd}}" options:NSCaseInsensitiveSearch]==NSOrderedSame)
            isRect_ =2;
        else
            isRect_ = 1;
    }
    if(isRect_ ==2) return YES;
    else  return NO;
}
-(void)dealloc
{
    PP_RELEASE(Type);
    PP_RELEASE(Name);
    PP_RELEASE(Code);
    if(Getter)
    {
        PP_RELEASE(Getter);
    }
    if(Setter)
    {
        PP_RELEASE(Setter);
    }
//    [Type release];
//    Type=nil;
//    [Name release];
//    Name = nil;
//    [Code release];
//    Code = nil;
//    if(Getter)
//        [Getter release];
//    if(Setter)
//        [Setter release];
    PP_SUPERDEALLOC;
}
@end
