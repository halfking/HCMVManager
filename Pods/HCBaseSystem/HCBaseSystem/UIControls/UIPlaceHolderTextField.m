//
//  UIPlaceHolderTextField.m
//  RBNews
//
//  Created by XUTAO HUANG on 13-5-31.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import "UIPlaceHolderTextField.h"

@implementation UIPlaceHolderTextField
@synthesize placeHolderLabel;
@synthesize placeholderString;
@synthesize placeholderColor;
@synthesize showMust;
@synthesize mustText;
@synthesize placeholderFont;
@synthesize placeholderTextAlignment;

//@synthesize isHolderCenter;

- (void)dealloc
{
#ifdef TRACKPAGES
    Class claz = [self class];
    NSString * cname = NSStringFromClass(claz);
    void * p = (void*)self;
    NSString * addr = [NSString stringWithFormat:@"%X",(unsigned int)p];
    [[SystemConfiguration sharedSystemConfiguration] closePageRec:cname  Addr:addr];
#endif
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    PP_RELEASE(placeHolderLabel);
    PP_RELEASE(placeholderColor);
    PP_RELEASE(placeholderString);
    PP_RELEASE(placeholderFont);
    if(showMustLabel)
    {
        PP_RELEASE(showMustLabel);
    }
    if(mustText)
    {
        PP_RELEASE(mustText);
    }
    PP_SUPERDEALLOC;
}


- (void)awakeFromNib
{
    [super awakeFromNib];
//    isHolderCenter = YES;
    [self setPlaceholderString:@""];
    [self setPlaceholderColor:[UIColor lightGrayColor]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textChanged:)
                                                 name:UITextFieldTextDidChangeNotification object:nil];
//    [self resetViews];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
#ifdef TRACKPAGES
        Class claz = [self class];
        NSString * cname = NSStringFromClass(claz);
        void * p = (void*)self;
        NSString * addr = [NSString stringWithFormat:@"%X",(unsigned int)p];
        [[SystemConfiguration sharedSystemConfiguration] openPageRec:cname  Addr:addr];
#endif
        [self setPlaceholderString:@""];
        mustText = @"必填";
//        isHolderCenter = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextFieldTextDidChangeNotification object:nil];
        
//        [self resetViews];
        placeholderTextAlignment = NSTextAlignmentLeft;
    }
    
    return self;
}
- (void)textChanged:(NSNotification *)notification
{
    if([[self text] length] == 0)
    {
        if(showMustLabel)
        {
            showMustLabel.alpha = 1;
        }
//        return;
    }
    if(placeHolderLabel)
    {
        if([[self text] length] == 0)
        {
            placeHolderLabel.alpha = 1;
            if(showMustLabel)
            {
                showMustLabel.alpha = 1;
            }
        }
        else
        {
            [placeHolderLabel setAlpha:0];
            if(showMustLabel)
            {
                showMustLabel.alpha = 0;
            }
            //            [[self viewWithTag:999] setAlpha:0];
        }
    }
}

- (void)setText:(NSString *)text {
    [super setText:text];
    [self textChanged:nil];
}
- (void)resetViews
{
    if(!placeHolderLabel)
    {
        CGFloat left = 6;
        if(self.leftView)
        {
            left += self.leftView.frame.size.width;
        }
        placeHolderLabel = [[UILabel alloc] initWithFrame:CGRectMake(left,4,self.bounds.size.width - left,0)];
        placeHolderLabel.lineBreakMode = NSLineBreakByWordWrapping;
        placeHolderLabel.numberOfLines = 0;
        placeHolderLabel.font = placeholderFont?placeholderFont:self.font;
        placeHolderLabel.backgroundColor = [UIColor clearColor];
        placeHolderLabel.textColor = self.placeholderColor;
        placeHolderLabel.alpha = 0;
        //            placeHolderLabel.tag = 999;
        [self addSubview:placeHolderLabel];
    }
    else
    {
        if(!placeHolderLabel.font)
        {
            placeHolderLabel.font = placeholderFont?placeholderFont:self.font;
        }
    }
    if( [[self placeholderString] length] > 0 && placeholderString )
    {
        placeHolderLabel.text = self.placeholderString;
        if(self.placeholderColor)
            placeHolderLabel.textColor = self.placeholderColor;
        placeHolderLabel.textAlignment = placeholderTextAlignment;
        UIFont * fontLbl = placeholderFont?placeholderFont:self.font;
        //设置段落模式
        NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
        paragraph.lineBreakMode = NSLineBreakByCharWrapping;
        NSDictionary *attribute = @{NSFontAttributeName: fontLbl, NSParagraphStyleAttributeName: paragraph};
        
        CGSize sizeLbl = [placeholderString boundingRectWithSize:CGSizeMake(self.frame.size.width -6, self.frame.size.height) options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attribute context:nil].size;
        CGRect holderFrame = placeHolderLabel.frame;
        holderFrame.origin.y = (self.frame.size.height - sizeLbl.height)/2;
        holderFrame.size.height = sizeLbl.height;
        placeHolderLabel.frame = holderFrame;
        
        PP_RELEASE(paragraph);
//        CGRectMake(6, (self.frame.size.height - sizeLbl.height)/2, sizeLbl.width, sizeLbl.height);
    }
    
    
    if(showMust && mustText && mustText.length>0 && (!showMustLabel))
    {
//        CGSize size = [mustText sizeWithFont:placeHolderLabel.font];
        //设置段落模式
//        NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
//        paragraph.alignment = NSLineBreakByCharWrapping;
//        NSDictionary *attribute = @{NSFontAttributeName: placeHolderLabel.font, NSParagraphStyleAttributeName: paragraph};
        
//        CGSize size = [mustText boundingRectWithSize:CGSizeMake(self.frame.size.width -6, self.frame.size.height) options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attribute context:nil].size;
        
        CGSize  size = [mustText sizeWithAttributes: @{NSFontAttributeName: placeHolderLabel.font}];
        showMustLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.bounds.size.width - 6-size.width,placeHolderLabel.frame.origin.y,size.width,size.height)];
        showMustLabel.lineBreakMode = NSLineBreakByWordWrapping;
        showMustLabel.numberOfLines = 0;
        showMustLabel.font = placeHolderLabel.font;
        showMustLabel.backgroundColor = [UIColor clearColor];
        showMustLabel.textColor = self.placeholderColor;
        showMustLabel.text = mustText;
        showMustLabel.alpha = 0;
        [self addSubview:showMustLabel];
    }
    if( [[self text] length] == 0 && [[self placeholderString] length] > 0 )
    {
        if(placeHolderLabel)
            [placeHolderLabel setAlpha:1];
        if(showMustLabel)
            showMustLabel.alpha = 1;
    }
}
- (void)layoutSubviews
{
    [self resetViews];
    [super layoutSubviews];
}

//- (void)drawRect:(CGRect)rect
//{
//        [super drawRect:rect];
//}

@end
