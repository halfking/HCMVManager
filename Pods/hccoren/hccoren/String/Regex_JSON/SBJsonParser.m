/*
 Copyright (C) 2009,2010 Stig Brautaset. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
   to endorse or promote products derived from this software without specific
   prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SBJsonParser.h"
#import "HCBase.h"

@interface SBJsonParser ()

- (BOOL)scanValue:(NSObject **)o;

- (BOOL)scanRestOfArray:(NSMutableArray **)o;
- (BOOL)scanRestOfDictionary:(NSMutableDictionary **)o;
- (BOOL)scanRestOfNull:(NSNull **)o;
- (BOOL)scanRestOfUndefined:(NSNull **)o;
- (BOOL)scanRestOfFalse:(NSNumber **)o;
- (BOOL)scanRestOfTrue:(NSNumber **)o;
- (BOOL)scanRestOfString:(NSMutableString **)o;

// Cannot manage without looking at the first digit
- (BOOL)scanNumber:(NSNumber **)o;

- (BOOL)scanHexQuad:(unichar *)x;
- (BOOL)scanUnicodeChar:(unichar *)x;

- (BOOL)scanIsAtEnd;

@end

#define skipWhitespace(c) while (isspace(*c)) c++
#define skipDigits(c) while (isdigit(*c)) c++


@implementation SBJsonParser

static char ctrl[0x22];
static char ctrl_2[0x3];

//用于区分一段字符结束的过程
+ (void)initialize {
    ctrl[0] = '\"';
    ctrl[1] = '\\';
    for (int i = 1; i < 0x20; i++)
        ctrl[i+1] = i;
    ctrl[0x21] = 0;
    
    ctrl_2[0] = ',';
    ctrl_2[1] = ':';
    ctrl_2[2] = '}' ;
}

- (id)objectWithString:(NSString *)repr {
    [self clearErrorTrace];
    
    if (!repr) {
        [self addErrorWithCode:EINPUT description:@"Input was 'nil'"];
        return nil;
    }
//    NSLog(@"string:%@",repr==nil?@"null":repr);
    depth = 0;
    c = [repr UTF8String];
    
    id o;
    if (![self scanValue:&o]) {
        return nil;
    }
    
    // We found some valid JSON. But did it also contain something else?
    if (![self scanIsAtEnd]) {
        [self addErrorWithCode:ETRAILGARBAGE description:@"Garbage after JSON"];
        return nil;
    }
    
    NSAssert1(o, @"Should have a valid object from %@", repr);
    
    // Check that the object we've found is a valid JSON container.
    if (![o isKindOfClass:[NSDictionary class]] && ![o isKindOfClass:[NSArray class]]) {
        [self addErrorWithCode:EFRAGMENT description:@"Valid fragment, but not JSON"];
        return nil;
    }
    
    return o;
}

- (id)objectWithString:(NSString*)repr error:(NSError**)error {
    id tmp = [self objectWithString:repr];
    if (tmp)
        return tmp;
    
    if (error)
        *error = [self.errorTrace lastObject];
    return nil;
}


/*
 In contrast to the public methods, it is an error to omit the error parameter here.
 */
- (BOOL)scanValue:(NSObject **)o
{
    skipWhitespace(c);
    switch (*c++) {
        case '{':
            return [self scanRestOfDictionary:(NSMutableDictionary **)o];
            break;
        case '[':
            return [self scanRestOfArray:(NSMutableArray **)o];
            break;
        case '\'':
            return [self scanRestOfStringSingle:(NSMutableString **)o];
        case '"':
            return [self scanRestOfString:(NSMutableString **)o];
            break;
        case 'f':
            return [self scanRestOfFalse:(NSNumber **)o];
            break;
        case 't':
            return [self scanRestOfTrue:(NSNumber **)o];
            break;
        case 'n':
            return [self scanRestOfNull:(NSNull **)o];
            break;
        case 'U':
        case 'u':
            return [self scanRestOfUndefined:(NSNull **)o];
            break;
        case '-':
        case '0'...'9':
            c--; // cannot verify number correctly without the first character
            return [self scanNumber:(NSNumber **)o];
            break;
        case '+':
            [self addErrorWithCode:EPARSENUM description: @"Leading + disallowed in number"];
            return NO;
            break;
        case 0x0:
            [self addErrorWithCode:EEOF description:@"Unexpected end of string"];
            return NO;
            break;
        default:
            //NSLog(@"string:%@",*c--);
//        {
//            NSMutableString * sb = [NSMutableString new];
//            char * d = (char*)c;
//            while (*d != '\0') {
//                unichar uc = *d;
//                CFStringAppendCharacters((CFMutableStringRef)sb, &uc, 1);
//                d++;
//            }
//            NSLog(@"string:%@",sb);
//        }
            [self addErrorWithCode:EPARSE description: @"Unrecognised leading character"];
            return NO;
            break;
    }
    
    NSAssert(0, @"Should never get here");
    return NO;
}

- (BOOL)scanRestOfTrue:(NSNumber **)o
{
    if (!strncmp(c, "rue", 3)) {
        c += 3;
        *o = [NSNumber numberWithBool:YES];
        return YES;
    }
    [self addErrorWithCode:EPARSE description:@"Expected 'true'"];
    return NO;
}

- (BOOL)scanRestOfFalse:(NSNumber **)o
{
    if (!strncmp(c, "alse", 4)) {
        c += 4;
        *o = [NSNumber numberWithBool:NO];
        return YES;
    }
    [self addErrorWithCode:EPARSE description: @"Expected 'false'"];
    return NO;
}

- (BOOL)scanRestOfNull:(NSNull **)o {
    if (!strncmp(c, "ull", 3)) {
        c += 3;
        *o = [NSNull null];
        return YES;
    }
    [self addErrorWithCode:EPARSE description: @"Expected 'null'"];
    return NO;
}
- (BOOL)scanRestOfUndefined:(NSNull **)o {
    if (!strncmp(c, "ndefined", 8)) {
        c += 8;
        *o = [NSNull null];
        return YES;
    }
    [self addErrorWithCode:EPARSE description: @"Expected 'undefined'"];
    return NO;
}

- (BOOL)scanRestOfArray:(NSMutableArray **)o {
    if (maxDepth && ++depth > maxDepth) {
        [self addErrorWithCode:EDEPTH description: @"Nested too deep"];
        return NO;
    }
    
    *o = [NSMutableArray arrayWithCapacity:8];
    
    for (; *c ;) {
        id v;
        
        skipWhitespace(c);
        if (*c == ']' && c++) {
            depth--;
            return YES;
        }
        
        if (![self scanValue:&v]) {
            [self addErrorWithCode:EPARSE description:@"Expected value while parsing array"];
            return NO;
        }
        
        [*o addObject:v];
        
        skipWhitespace(c);
        if (*c == ',' && c++) {
            skipWhitespace(c);
            if (*c == ']') {
                [self addErrorWithCode:ETRAILCOMMA description: @"Trailing comma disallowed in array"];
                return NO;
            }
        }        
    }
    
    [self addErrorWithCode:EEOF description: @"End of input while parsing array"];
    return NO;
}
//为了提高兼容性，添加过滤不合法的键
- (void)scanRestInvalidString
{
    while (*c!=' ' && *c!='}' && *c!='\0') {
        c ++;
    }
}
- (BOOL)scanRestOfDictionary:(NSMutableDictionary **)o 
{

    if (maxDepth && ++depth > maxDepth) {
        [self addErrorWithCode:EDEPTH description: @"Nested too deep"];
        return NO;
    }
    
//    Class stringClass = [NSString class];
    
    *o = [NSMutableDictionary dictionaryWithCapacity:7];
    
    for (; *c ;) {
        id k, v;
        k = nil;
        v = nil;
        skipWhitespace(c);
        if (*c == '}' && c++) {
            depth--;
            return YES;
        }

//        if(*c=='\"')
//        {
            if (!(*c == '\"' && c++ && [self scanRestOfString:&k])) {
                NSLog(@"json error:%@",[NSString stringWithCString:c encoding:NSUTF8StringEncoding]);
//                [self addErrorWithCode:EPARSE description: @"Object key string expected"];
//                return NO;
                NSLog(@"Object key string expected");
                [self scanRestInvalidString];
                continue;
            }
//        }
//        else
//        {
//            if (!([self scanRestOfString:&k])) {
//                [self addErrorWithCode:EPARSE description: @"Object key string expected"];
//                return NO;
//            }
//        }
        
        skipWhitespace(c);
        if (*c != ':') {
            [self addErrorWithCode:EPARSE description: @"Expected ':' separating key and value"];
            return NO;
        }
//        if([k compare:@"Content" options:NSCaseInsensitiveSearch]==NSOrderedSame)
//        {
//            NSLog(@"log content...");
//        }
        c++;
//        if([k isKindOfClass:[NSString class]] && [(NSString*)k compare:@"LastMessageSyntax"]==0)
//        {
//            NSLog(@"break;");
//        }
//        if([k isEqualToString:@"RepairDesc"])
//        {
//            NSLog(@"key:%@",k);
//        }
        if (![self scanValue:&v]) {
            NSString *string = [NSString stringWithFormat:@"Object value expected for key: %@", k];
            [self addErrorWithCode:EPARSE description: string];
            //测试下一段是否是完整的，如果是完整的，则跳过这一段
            if(*c=='}'||*c==','||*c=='\0')
            {
                v = [NSNull null];
                c --;
            }
            else
            {
                //没有引号，则用另一模式,回退
                while (*(c-1)!=':' && *(c-1)!='{' && *(c-1)!=',') {
                    c --;
                }
                if(![self scanRestOfString:&v hasSi:NO])
                    return NO;
            }
        }
//        if([k isEqualToString:@"RepairDesc"])
//        {
//            NSLog(@"value:%@",v);
//        }
//        if([v isKindOfClass:stringClass])
//        {
//            NSString * v1 = [NSString stringWithFormat:@"%@",v];
//            [*o setObject:v1 forKey:k];
////            NSLog(@"string:%@",v1);
//        }
//        else
            [*o setObject:v forKey:k];
      
        skipWhitespace(c);
        if (*c == ',' && c++) {
            skipWhitespace(c);
            if (*c == '}') {
                [self addErrorWithCode:ETRAILCOMMA description: @"Trailing comma disallowed in object"];
                return NO;
            }
        }        
    }
    
    [self addErrorWithCode:EEOF description: @"End of input while parsing object"];
    return NO;
}
- (BOOL)scanRestOfString:(NSMutableString **)o hasSi:(BOOL)hasSi//是否前面有引号
{
    // if the string has no control characters in it, return it in one go, without any temporary allocations.
    size_t len;
    if(!hasSi)
        len = strcspn(c, ctrl_2);
    else
        len = strcspn(c, ctrl);
    if ((hasSi && len && *(c + len) == '\"')||(!hasSi && len ))
    {
        *o = PP_AUTORELEASE([[NSMutableString alloc] initWithBytes:(char*)c length:len encoding:NSUTF8StringEncoding]);
        if(*(c+len)=='}')
            c += len;
        else
            c += len + 1;
        return YES;
    }
    
    //    *o = [NSMutableString stringWithCapacity:16];
    *o = [NSMutableString stringWithCapacity:32];
    do {
        // First see if there's a portion we can grab in one go.
        // Doing this caused a massive speedup on the long string.
        len = strcspn(c, ctrl);
        if (len) {
            // check for
            id t = [[NSString alloc] initWithBytesNoCopy:(char*)c
                                                  length:len
                                                encoding:NSUTF8StringEncoding
                                            freeWhenDone:NO];
            if (t) {
                [*o appendString:t];
                PP_RELEASE(t);
//                [t release];
                c += len;
            }
        }
        
        
//        if (*c == '"') {
//            if(*(c-1)!='\\') //有可能\\"这种情况，如果按原来的方案就会出错。
//            {
//                c++;
//                return YES;
//            }
//            else
//            {
//                unichar uc = *c;
//                CFStringAppendCharacters((CFMutableStringRef)*o, &uc, 1);
//                c ++;
//            }
//        } else
            if (*c == '\\') {
            unichar uc = *++c;
            switch (uc) {
                case '\\':
                    break;
                case '/':
                case '"':
                    break;
                    
                case 'b':   uc = '\b';  break;
                case 'n':   uc = '\n';  break;
                case 'r':   uc = '\r';  break;
                case 't':   uc = '\t';  break;
                case 'f':   uc = '\f';  break;
                    
                case 'u':
                    c++;
                    if (![self scanUnicodeChar:&uc]) {
                        [self addErrorWithCode:EUNICODE description: @"Broken unicode character"];
                        return NO;
                    }
                    c--; // hack.
                    break;
                default:
                    [self addErrorWithCode:EESCAPE description: [NSString stringWithFormat:@"Illegal escape sequence '0x%x'", uc]];
                    return NO;
                    break;
            }
            CFStringAppendCharacters((CFMutableStringRef)*o, &uc, 1);
            c++;
            
        }
        else if ( *c=='\n' || *c=='\r' || *c=='\t')
        {
            unichar uc = *c;
            CFStringAppendCharacters((CFMutableStringRef)*o, &uc, 1);
            c ++;
        }
        else if (*c < 0x20) {
            [self addErrorWithCode:ECTRL description: [NSString stringWithFormat:@"Unescaped control character '0x%x'", *c]];
            return NO;
            
        } else {
            NSLog(@"should not be able to get here");
        }
    } while (*c);
    
    [self addErrorWithCode:EEOF description:@"Unexpected EOF while parsing string"];
    return NO;
}
- (BOOL)scanRestOfString:(NSMutableString **)o
{
    // if the string has no control characters in it, return it in one go, without any temporary allocations.
    size_t len = strcspn(c, ctrl);
    if (len && *(c + len) == '\"')
    {
        *o = PP_AUTORELEASE([[NSMutableString alloc] initWithBytes:(char*)c
                                              length:len
                                            encoding:NSUTF8StringEncoding]
              );
//         *o = [NSMutableString stringWithCapacity:len];
//        id t = [[NSMutableString alloc] initWithBytesNoCopy:(char*)c length:len
//                                                  encoding:NSUTF8StringEncoding
//                                              freeWhenDone:NO];
//        if(t)
//        {
//            [*o appendString:t];
//            [t release];
//        }
        c += len + 1;
        //NSLog(@"string:%@",*o);
        return YES;
    }
    
//    *o = [NSMutableString stringWithCapacity:16];
        *o = [NSMutableString stringWithCapacity:32];
    do {
        // First see if there's a portion we can grab in one go. 
        // Doing this caused a massive speedup on the long string.
        len = strcspn(c, ctrl);
        if (len) {
            // check for 
            id t = [[NSString alloc] initWithBytesNoCopy:(char*)c
                                                  length:len
                                                encoding:NSUTF8StringEncoding
                                            freeWhenDone:NO];
            if (t) {
                [*o appendString:t];
                PP_RELEASE(t);
//                [t release];
                c += len;
            }
        }
        
       
        if (*c == '"') {
            if(*(c-1)!='\\') //有可能\\"这种情况，如果按原来的方案就会出错。
            {
                c++;
                return YES;
            }
            else  
            {
                unichar uc = *c;
                CFStringAppendCharacters((CFMutableStringRef)*o, &uc, 1);
                c ++;
            }
        } else if (*c == '\\') {
            unichar uc = *++c;
            BOOL matched =YES;
            switch (uc) {
                case '\\':
                    break;
                case '/':
                case '"':
                    break;
                    
                case 'b':   uc = '\b';  break;
                case 'n':   uc = '\n';  break;
                case 'r':   uc = '\r';  break;
                case 't':   uc = '\t';  break;
                case 'f':   uc = '\f';  break;                    
                    
                case 'u':
                    c++;
                    if (![self scanUnicodeChar:&uc]) {
                        [self addErrorWithCode:EUNICODE description: @"Broken unicode character"];
                        return NO;
                    }
                    c--; // hack.
                    break;
                default:
                    matched = NO;
                    //兼容性考虑，此处注释
//                    [self addErrorWithCode:EESCAPE description: [NSString stringWithFormat:@"Illegal escape sequence '0x%x'", uc]];
//                    return NO;
                    break;
            }
            if(matched)
                CFStringAppendCharacters((CFMutableStringRef)*o, &uc, 1);
            else
            {
                //兼容性考虑，加上
                [((NSMutableString *)*o) appendFormat:@"\\%c",uc];
//                CFStringAppendCharacters((CFMutableStringRef)*o, '\\', 1);
//                CFStringAppendCharacters((CFMutableStringRef)*o, &uc, 1);
            }
            c++;
            
        }
        else if ( *c=='\n' || *c=='\r' || *c=='\t')
        {
            unichar uc = *c;
            CFStringAppendCharacters((CFMutableStringRef)*o, &uc, 1);
            c ++;
        }
        else if (*c < 0x20) {
            unichar uc = *c;
            CFStringAppendCharacters((CFMutableStringRef)*o, &uc, 1);
//            [self addErrorWithCode:ECTRL description: [NSString stringWithFormat:@"Unescaped control character '0x%x'", *c]];
            NSLog(@"parse Json:%@",[NSString stringWithFormat:@"Unescaped control character '0x%x'", *c]);
            c++;
            //兼容性考虑，加上
//            return NO;
            
        } else {
            NSLog(@"should not be able to get here");
            c++;
        }
    } while (*c);
    
    //NSLog(@"string:%@",*o);
    
    //兼容性考虑，加上
    [self addErrorWithCode:EEOF description:@"Unexpected EOF while parsing string"];
     NSLog(@"parse Json:%@",[NSString stringWithFormat:@"Unexpected EOF while parsing string:%@", *o]);
//    return NO;
    return YES;
}
//单引号包的字串
- (BOOL)scanRestOfStringSingle:(NSMutableString **)o
{
    // if the string has no control characters in it, return it in one go, without any temporary allocations.
    size_t len = strcspn(c, ctrl);
    if (len && *(c + len) == '\'')
    {
        *o = PP_AUTORELEASE([[NSMutableString alloc] initWithBytes:(char*)c
                                              length:len
                                                          encoding:NSUTF8StringEncoding]);
        
        //         *o = [NSMutableString stringWithCapacity:len];
        //        id t = [[NSMutableString alloc] initWithBytesNoCopy:(char*)c length:len
        //                                                  encoding:NSUTF8StringEncoding
        //                                              freeWhenDone:NO];
        //        if(t)
        //        {
        //            [*o appendString:t];
        //            [t release];
        //        }
        c += len + 1;
        return YES;
    }
    
    //    *o = [NSMutableString stringWithCapacity:16];
    *o = [NSMutableString stringWithCapacity:32];
    do {
        // First see if there's a portion we can grab in one go.
        // Doing this caused a massive speedup on the long string.
        len = strcspn(c, ctrl);
        if (len) {
            // check for
            id t = [[NSString alloc] initWithBytesNoCopy:(char*)c
                                                  length:len
                                                encoding:NSUTF8StringEncoding
                                            freeWhenDone:NO];
            if (t) {
                [*o appendString:t];
                PP_RELEASE(t);
//                [t release];
                c += len;
            }
        }
        
        
        if (*c == '\'') {
            if(*(c-1)!='\\') //有可能\\"这种情况，如果按原来的方案就会出错。
            {
                c++;
                return YES;
            }
            else
            {
                unichar uc = *c;
                CFStringAppendCharacters((CFMutableStringRef)*o, &uc, 1);
                c ++;
            }
        } else if (*c == '\\') {
            unichar uc = *++c;
            BOOL matched =YES;
            switch (uc) {
                case '\\':
                    break;
                case '/':
                case '"':
                    break;
                    
                case 'b':   uc = '\b';  break;
                case 'n':   uc = '\n';  break;
                case 'r':   uc = '\r';  break;
                case 't':   uc = '\t';  break;
                case 'f':   uc = '\f';  break;
                    
                case 'u':
                    c++;
                    if (![self scanUnicodeChar:&uc]) {
                        [self addErrorWithCode:EUNICODE description: @"Broken unicode character"];
                        return NO;
                    }
                    c--; // hack.
                    break;
                default:
                    matched = NO;
                    //兼容性考虑，此处注释
                    //                    [self addErrorWithCode:EESCAPE description: [NSString stringWithFormat:@"Illegal escape sequence '0x%x'", uc]];
                    //                    return NO;
                    break;
            }
            if(matched)
                CFStringAppendCharacters((CFMutableStringRef)*o, &uc, 1);
            else
            {
                //兼容性考虑，加上
                [((NSMutableString *)*o) appendFormat:@"\\%c",uc];
                //                CFStringAppendCharacters((CFMutableStringRef)*o, '\\', 1);
                //                CFStringAppendCharacters((CFMutableStringRef)*o, &uc, 1);
            }
            c++;
            
        }
        else if ( *c=='\n' || *c=='\r' || *c=='\t')
        {
            unichar uc = *c;
            CFStringAppendCharacters((CFMutableStringRef)*o, &uc, 1);
            c ++;
        }
        else if (*c < 0x20) {
            unichar uc = *c;
            CFStringAppendCharacters((CFMutableStringRef)*o, &uc, 1);
            //            [self addErrorWithCode:ECTRL description: [NSString stringWithFormat:@"Unescaped control character '0x%x'", *c]];
            NSLog(@"parse Json:%@",[NSString stringWithFormat:@"Unescaped control character '0x%x'", *c]);
            c++;
            //兼容性考虑，加上
            //            return NO;
            
        } else {
            NSLog(@"should not be able to get here");
            c++;
        }
    } while (*c);
    
    //兼容性考虑，加上
    [self addErrorWithCode:EEOF description:@"Unexpected EOF while parsing string"];
    NSLog(@"parse Json:%@",[NSString stringWithFormat:@"Unexpected EOF while parsing string:%@", *o]);
    //    return NO;
    return YES;
}


- (BOOL)scanUnicodeChar:(unichar *)x
{
    unichar hi, lo;
    hi = 0;
    lo = 0;
    if (![self scanHexQuad:&hi]) {
        [self addErrorWithCode:EUNICODE description: @"Missing hex quad"];
        return NO;        
    }
    
    if (hi >= 0xd800) {     // high surrogate char?
        if (hi < 0xdc00) {  // yes - expect a low char
            
            if (!(*c == '\\' && ++c && *c == 'u' && ++c && [self scanHexQuad:&lo])) {
                [self addErrorWithCode:EUNICODE description: @"Missing low character in surrogate pair"];
                return NO;
            }
            
            if (lo < 0xdc00 || lo >= 0xdfff) {
                [self addErrorWithCode:EUNICODE description:@"Invalid low surrogate char"];
                return NO;
            }
            
            hi = (hi - 0xd800) * 0x400 + (lo - 0xdc00) + 0x10000;
            
        } else if (hi < 0xe000) {
            [self addErrorWithCode:EUNICODE description:@"Invalid high character in surrogate pair"];
            return NO;
        }
    }
    
    *x = hi;
    return YES;
}

- (BOOL)scanHexQuad:(unichar *)x
{
    *x = 0;
    for (int i = 0; i < 4; i++) {
        unichar uc = *c;
        c++;
        int d = (uc >= '0' && uc <= '9')
        ? uc - '0' : (uc >= 'a' && uc <= 'f')
        ? (uc - 'a' + 10) : (uc >= 'A' && uc <= 'F')
        ? (uc - 'A' + 10) : -1;
        if (d == -1) {
            [self addErrorWithCode:EUNICODE description:@"Missing hex digit in quad"];
            return NO;
        }
        *x *= 16;
        *x += d;
    }
    return YES;
}

- (BOOL)scanNumber:(NSNumber **)o
{
    BOOL simple = YES;
    
    const char *ns = c;
    
    // The logic to test for validity of the number formatting is relicensed
    // from JSON::XS with permission from its author Marc Lehmann.
    // (Available at the CPAN: http://search.cpan.org/dist/JSON-XS/ .)
    
    if ('-' == *c)
        c++;
    
    if ('0' == *c && c++) {        
        if (isdigit(*c)) {
            [self addErrorWithCode:EPARSENUM description: @"Leading 0 disallowed in number"];
            return NO;
        }
        
    } else if (!isdigit(*c) && c != ns) {
        [self addErrorWithCode:EPARSENUM description: @"No digits after initial minus"];
        return NO;
        
    } else {
        skipDigits(c);
    }
    
    // Fractional part
    if ('.' == *c && c++) {
        simple = NO;
        if (!isdigit(*c)) {
            [self addErrorWithCode:EPARSENUM description: @"No digits after decimal point"];
            return NO;
        }        
        skipDigits(c);
    }
    
    // Exponential part
    if ('e' == *c || 'E' == *c) {
        simple = NO;
        c++;
        
        if ('-' == *c || '+' == *c)
            c++;
        
        if (!isdigit(*c)) {
            [self addErrorWithCode:EPARSENUM description: @"No digits after exponent"];
            return NO;
        }
        skipDigits(c);
    }
    
    // If we are only reading integers, don't go through the expense of creating an NSDecimal.
    // This ends up being a very large perf win.
    if (simple) {
        BOOL negate = NO;
        long long val = 0;
        const char *d = ns;
        
        if (*d == '-') {
            negate = YES;
            d++;
        }
        
        while (isdigit(*d)) {
            val *= 10;
            if (val < 0)
                goto longlong_overflow;
            val += *d - '0';
            if (val < 0)
                goto longlong_overflow;
            d++;
        }
        
        *o = [NSNumber numberWithLongLong:negate ? -val : val];
        return YES;
        
    } else {
        // jumped to by simple branch, if an overflow occured
        longlong_overflow:;
        
        id str = PP_AUTORELEASE([[NSString alloc] initWithBytesNoCopy:(char*)ns
                                                length:c - ns
                                              encoding:NSUTF8StringEncoding
                                          freeWhenDone:NO]);
//        [str autorelease];
        if (str && (*o = [NSDecimalNumber decimalNumberWithString:str]))
            return YES;
        
        [self addErrorWithCode:EPARSENUM description: @"Failed creating decimal instance"];
        return NO;
    }
}

- (BOOL)scanIsAtEnd
{
    skipWhitespace(c);
    return !*c;
}


@end
