//
//  FileResource.m
//  iChm
//
//  Created by Robin Lu on 10/17/08.
//  Copyright 2008 robinlu.com. All rights reserved.
//

#import "FileResource.h"
#import "RegexKitLite.h"
#import "HTTPConnection.h"
#import "HTTPServer.h"
#import "HTTPResponse.h"
#import "HTTPFileResponse.h"
#import "RegexKitLite.h"
@implementation FileResource

@synthesize delegate;

+ (BOOL)canHandle:(HTTPMessage*)request
{
    NSURL * url = request.url;
	NSString* fullpath = url.path;
    NSArray * array = [fullpath componentsSeparatedByString:@"/"];
	NSString* path = [array objectAtIndex:1];
	path = [[path componentsSeparatedByString:@"."] objectAtIndex:0];
	NSComparisonResult rslt = [path caseInsensitiveCompare:@"files"];

	return rslt == NSOrderedSame;
}

- (id)initWithConnection:(HTTPConnection*)conn delegate:(id<WebFileResourceDelegate>)fdelegate
{
	if (self = [self init])
	{
        PP_RELEASE(connection);
		request = [conn request];
		parameters = [conn parseGetParams];
		connection = PP_RETAIN(conn);
        
		self.delegate = fdelegate;
	}
	return self;
}

- (void)dealloc
{
    self.delegate = nil;
    PP_RELEASE(connection);
    
    PP_SUPERDEALLOC;
}

- (void)handleRequest:(HTTPMessage *)prequest
{
    request = prequest;
    NSURL * url = request.url;
    NSString * method = request.method;
    NSString * path = url.path;
    
	NSString *_method = [parameters objectForKey:@"_method"];
	
	if ([method isEqualToString:@"GET"])
	{
		if (NSOrderedSame == [path caseInsensitiveCompare:@"/files"])
			[self actionList];
		else
		{
			NSArray *segs = [path componentsSeparatedByString:@"/"];
			if ([segs count] >= 2)
			{
				NSString* fileName = [segs objectAtIndex:2];
				[self actionShow:fileName];
			}			
		}
	}
	else if (([method isEqualToString:@"POST"]) && _method && [[_method lowercaseString] isEqualToString:@"delete"])
	{
		NSArray *segs = [path componentsSeparatedByString:@"/"];
		if ([segs count] >= 2)
		{
			NSString* fileName = [segs objectAtIndex:2];
			[self actionDelete:fileName];
		}
	}
	else if (([method isEqualToString:@"POST"]))
	{
		[self actionNew];
	}
}

- (void)actionDelete:(NSString*)fileName
{
	if (delegate == nil)
	{
		[connection handleResourceNotFound];
		return;
	}
	
	if  ([delegate respondsToSelector:@selector(fileShouldDelete:)])
	{
		[delegate fileShouldDelete:[fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] ];
	}
	[connection redirectoTo:@"/"];
    [[NSNotificationCenter defaultCenter] postNotificationName:HTTPFileDeletedNotification object:fileName];
}

- (void)actionList
{
	if (delegate == nil)
	{
		[connection handleResourceNotFound];
		return;
	}
	
	NSMutableString *output = [[NSMutableString alloc] init];
	[output appendString:@"["];
	for(int i = 0; i<[delegate numberOfFiles]; ++i)
	{
		NSString* filename = [delegate fileNameAtIndex:i];
		NSString* file = [filename stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""] ;
		[output appendFormat:@"{\"name\":\"%@\", \"id\":%d},", file, i];
	}
	if ([output length] > 1)
	{
		NSRange range = NSMakeRange([output length] - 1, 1);
		[output replaceCharactersInRange:range withString:@"]"];
	}
	else
	{
		[output appendString:@"]"];
	}

	[connection sendString:output mimeType:nil];
    PP_RELEASE(output);
}

- (void)actionShow:(NSString*)fileName
{
	if (delegate == nil)
	{
		[connection handleResourceNotFound];
		return;
	}
	
	NSString* filePath = [delegate filePathForFileName:[fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] ];
	if (filePath == nil)
	{
		[connection handleResourceNotFound];
		return;
	}
	
	HTTPFileResponse* response = [[HTTPFileResponse alloc] initWithFilePath:filePath forConnection:connection];
    [connection sendResponseHeadersAndBody:response method:@"GET"];
}

- (void)actionNew
{
	if (delegate == nil)
	{
		[connection handleResourceNotFound];
		return;
	}
    NSDictionary * params = [connection parametesAddtion];
	NSString *tmpfile = [params objectForKey:@"tmpfilename"];
	NSString *filename = [params objectForKey:@"newfile"];
	if ([delegate respondsToSelector:@selector(newFileDidUpload:inTempPath:)])
		[delegate newFileDidUpload:filename inTempPath:tmpfile];
	
	[connection redirectoTo:@"/"];
}
- (NSString *)lastFileName
{
     NSDictionary * params = [connection parametesAddtion];
    if(params)
        return [params objectForKey:@"newfile"];
    else
        return nil;
}
@end
