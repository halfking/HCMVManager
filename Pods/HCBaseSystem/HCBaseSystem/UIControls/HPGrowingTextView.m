//
//  HPTextView.m
//
//  Created by Hans Pinckaers on 29-06-10.
//
//	MIT License
//
//	Copyright (c) 2011 Hans Pinckaers
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.

#import "HPGrowingTextView.h"
#import "HPTextViewInternal.h"
#import <hccoren/base.h>
#import <hccoren/UIView+extension.h>

@interface HPGrowingTextView(private)
-(void)commonInitialiser;
-(void)resizeTextView:(NSInteger)newSizeH;
-(void)growDidStop;
@end

@implementation HPGrowingTextView
@synthesize internalTextView;
@synthesize delegate;

@synthesize font;
@synthesize textColor;
@synthesize textAlignment;
@synthesize selectedRange;
@synthesize editable;
@synthesize dataDetectorTypes;
@synthesize animateHeightChange;
@synthesize returnKeyType;

// having initwithcoder allows us to use HPGrowingTextView in a Nib. -- aob, 9/2011
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        [self commonInitialiser];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self commonInitialiser];
    }
    return self;
}

-(void)commonInitialiser
{
    // Initialization code
    CGRect r = self.frame;
    r.origin.y = 0;
    r.origin.x = 0;
    
    internalTextView = [[HPTextViewInternal alloc] initWithFrame:r];
    internalTextView.delegate = self;//[self traverseResponderChainForUIViewController];
    internalTextView.scrollEnabled = NO;
    internalTextView.font = [UIFont fontWithName:@"Helvetica" size:13];
    internalTextView.contentInset = UIEdgeInsetsZero;
    internalTextView.showsHorizontalScrollIndicator = NO;
    internalTextView.text = @"-";
    [self addSubview:internalTextView];
    
    
    
    UIView *internal = (UIView*)[[internalTextView subviews] objectAtIndex:0];
    minHeight = internal.frame.size.height;
    minNumberOfLines = 1;
    
    animateHeightChange = YES;
    
    internalTextView.text = @"";
    
    [self setMaxNumberOfLines:5];
}

-(void)sizeToFit
{
    CGRect r = self.frame;
    
    // check if the text is available in text view or not, if it is available, no need to set it to minimum lenth, it could vary as per the text length
    // fix from Ankit Thakur
    if ([self.text length] > 0) {
        return;
    } else {
        r.size.height = minHeight;
        self.frame = r;
    }
}

-(void)setFrame:(CGRect)aframe
{
    CGRect r = aframe;
    r.origin.y = 0;
    r.origin.x = contentInset.left;
    r.size.width -= contentInset.left + contentInset.right;
    
    internalTextView.frame = r;
    
    [super setFrame:aframe];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self performSelector:@selector(textViewDidChange:) withObject:internalTextView];
    
    if(!internalTextView.delegate || internalTextView.delegate==self)
        internalTextView.delegate = [self traverseResponderChainForUIViewController];
}

-(void)setContentInset:(UIEdgeInsets)inset
{
    contentInset = inset;
    
    CGRect r = self.frame;
    r.origin.y = inset.top - inset.bottom;
    r.origin.x = inset.left;
    r.size.width -= inset.left + inset.right;
    
    internalTextView.frame = r;
    
    [self setMaxNumberOfLines:maxNumberOfLines];
    [self setMinNumberOfLines:minNumberOfLines];
}

-(UIEdgeInsets)contentInset
{
    return contentInset;
}

-(void)setMaxNumberOfLines:(int)n
{
    // Use internalTextView for height calculations, thanks to Gwynne <http://blog.darkrainfall.org/>
    NSString *saveText = internalTextView.text, *newText = @"-";
    
    internalTextView.delegate = nil;
    internalTextView.hidden = YES;
    
    for (int i = 1; i < n; ++i)
        newText = [newText stringByAppendingString:@"\n|W|-"];
    
    internalTextView.text = newText;
    
    maxHeight = [self getTextViewContentHeight:internalTextView];
    
    internalTextView.text = saveText;
    internalTextView.hidden = NO;
    internalTextView.delegate = self;
    
    [self sizeToFit];
    
    maxNumberOfLines = n;
//    NSLog(@"max height:%.1f",maxHeight);
}

-(int)maxNumberOfLines
{
    return maxNumberOfLines;
}

-(void)setMinNumberOfLines:(int)m
{
    if(m<=1)
    {
        minNumberOfLines = m;
        return ;
    }
    
    // Use internalTextView for height calculations, thanks to Gwynne <http://blog.darkrainfall.org/>
    NSString *saveText = internalTextView.text, *newText = @"-";
    
    internalTextView.delegate = nil;
    internalTextView.hidden = YES;
    
    for (int i = 1; i < m; ++i)
        newText = [newText stringByAppendingString:@"\n|W|"];
    
    internalTextView.text = newText;
    
    minHeight = [self getTextViewContentHeight:internalTextView];
    //    minHeight = internalTextView.contentSize.height;
    
    internalTextView.text = saveText;
    internalTextView.hidden = NO;
    internalTextView.delegate = self;
    
    [self sizeToFit];
    
    minNumberOfLines = m;
    
    NSLog(@"min height:%.1f",minHeight);
}

-(int)minNumberOfLines
{
    return minNumberOfLines;
}

- (CGFloat)getTextViewContentHeight:(UITextView *)textView
{
    CGFloat contentHeight = 0.0;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        
        //        CGRect textFrame=[[textView layoutManager]usedRectForTextContainer:[textView textContainer]];
        //        contentHeight = textFrame.size.height;
        
        CGRect txtFrame = textView.frame;
        if(!textView.text||textView.text.length==0)
        {
            contentHeight = minHeight;
        }
        else
        {
            //增加一个换行，用于显示光标题示等
            contentHeight =[[NSString stringWithFormat:@"%@\n",textView.text]
                            boundingRectWithSize:CGSizeMake(txtFrame.size.width, CGFLOAT_MAX)
                            options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                            attributes:[NSDictionary dictionaryWithObjectsAndKeys:textView.font,NSFontAttributeName, nil] context:nil].size.height;
            contentHeight = roundf(contentHeight *2+0.5)/2.0f;
        }
    }
    else
    {
        contentHeight = textView.contentSize.height;
    }
//    NSLog(@"text:%@ \n content height:%.1f",textView.text,contentHeight);
    return contentHeight;
}
- (void)textViewDidChange:(UITextView *)textView
{
    //size of content, so we can set the frame of self
    if(!textView)
    {
        textView = self.internalTextView;
        NSLog(@"change textView...");
    }
    BOOL notCurrentTextView = NO;
    if(textView!= self.internalTextView)
    {
        self.internalTextView.text = textView.text;
        notCurrentTextView = YES;
    }
    CGFloat newSizeH = [self getTextViewContentHeight:textView];
    NSLog(@"grown new height:%.1f",newSizeH);
    BOOL scrollEnabled=NO;
    
    if(newSizeH < minHeight || !internalTextView.hasText)
        newSizeH = minHeight; //not smalles than minHeight
    
    if (newSizeH > maxHeight)
    {
        textView.contentSize = CGSizeMake(textView.contentSize.width, newSizeH + 15);
        newSizeH = maxHeight; // not taller than maxHeight
        scrollEnabled = YES;
    }
    
    //如果不是当前的TextView要变化，比如两个TextView同步，则需要更换当前需要处理的TextView
    if(notCurrentTextView)
    {
        textView = self.internalTextView;
    }
        
    if (textView.frame.size.height != newSizeH)
    {
        
        if(animateHeightChange) {
            
            [UIView animateWithDuration:0.1f
                                  delay:0
                                options:(UIViewAnimationOptionAllowUserInteraction|
                                         UIViewAnimationOptionBeginFromCurrentState)
                             animations:^(void) {
                                 [self resizeTextView:newSizeH];
                             }
                             completion:^(BOOL finished) {
                                 if ([delegate respondsToSelector:@selector(growingTextView:didChangeHeight:)]) {
                                     [delegate growingTextView:self didChangeHeight:newSizeH];
                                 }
                             }];
            
        } else {
            [self resizeTextView:newSizeH];
            if ([delegate respondsToSelector:@selector(growingTextView:didChangeHeight:)]) {
                [delegate growingTextView:self didChangeHeight:newSizeH];
            }
        }
    }
    
    if (scrollEnabled)
    {
        if(!textView.scrollEnabled){
            textView.scrollEnabled = YES;
        }
        //            [internalTextView flashScrollIndicators];
        textView.showsVerticalScrollIndicator = YES;
        textView.alwaysBounceVertical = YES;
        [textView setNeedsDisplay];
    } else {
        textView.scrollEnabled = NO;
    }
    
    if ([delegate respondsToSelector:@selector(growingTextViewDidChange:)]) {
        [delegate growingTextViewDidChange:self];
    }
    
}

-(void)resizeTextView:(NSInteger)newSizeH
{
    if ([delegate respondsToSelector:@selector(growingTextView:willChangeHeight:)]) {
        [delegate growingTextView:self willChangeHeight:newSizeH];
    }
    
    CGRect internalTextViewFrame = self.frame;
    internalTextViewFrame.size.height = newSizeH; // + padding
    self.frame = internalTextViewFrame;
    
    internalTextViewFrame.origin.y = contentInset.top - contentInset.bottom;
    internalTextViewFrame.origin.x = contentInset.left;
    internalTextViewFrame.size.width = internalTextView.contentSize.width;
    
    internalTextView.frame = internalTextViewFrame;
}

-(void)growDidStop
{
    if ([delegate respondsToSelector:@selector(growingTextView:didChangeHeight:)]) {
        [delegate growingTextView:self didChangeHeight:self.frame.size.height];
    }
    
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [internalTextView becomeFirstResponder];
}

- (BOOL)becomeFirstResponder
{
    [super becomeFirstResponder];
    return [self.internalTextView becomeFirstResponder];
}

-(BOOL)resignFirstResponder
{
    [super resignFirstResponder];
    return [internalTextView resignFirstResponder];
}

- (void)dealloc {
    //	[internalTextView release];
    PP_RELEASE(internalTextView);
    PP_SUPERDEALLOC;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark UITextView properties
///////////////////////////////////////////////////////////////////////////////////////////////////

-(void)setText:(NSString *)newText
{
    internalTextView.text = newText;
    
    // include this line to analyze the height of the textview.
    // fix from Ankit Thakur
    [self performSelector:@selector(textViewDidChange:) withObject:internalTextView];
}

-(NSString*) text
{
    return internalTextView.text;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(void)setFont:(UIFont *)afont
{
    internalTextView.font= afont;
    
    [self setMaxNumberOfLines:maxNumberOfLines];
    [self setMinNumberOfLines:minNumberOfLines];
}

-(UIFont *)font
{
    return internalTextView.font;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(void)setTextColor:(UIColor *)color
{
    internalTextView.textColor = color;
}

-(UIColor*)textColor{
    return internalTextView.textColor;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(void)setTextAlignment:(NSTextAlignment)aligment
{
    internalTextView.textAlignment = aligment;
}

-(NSTextAlignment)textAlignment
{
    return internalTextView.textAlignment;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(void)setSelectedRange:(NSRange)range
{
    internalTextView.selectedRange = range;
}

-(NSRange)selectedRange
{
    return internalTextView.selectedRange;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(void)setEditable:(BOOL)beditable
{
    internalTextView.editable = beditable;
}

-(BOOL)isEditable
{
    return internalTextView.editable;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(void)setReturnKeyType:(UIReturnKeyType)keyType
{
    internalTextView.returnKeyType = keyType;
}

-(UIReturnKeyType)returnKeyType
{
    return internalTextView.returnKeyType;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(void)setDataDetectorTypes:(UIDataDetectorTypes)datadetector
{
    internalTextView.dataDetectorTypes = datadetector;
}

-(UIDataDetectorTypes)dataDetectorTypes
{
    return internalTextView.dataDetectorTypes;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)hasText{
    return [internalTextView hasText];
}

- (void)scrollRangeToVisible:(NSRange)range
{
    [internalTextView scrollRangeToVisible:range];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITextViewDelegate


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    if ([delegate respondsToSelector:@selector(growingTextViewShouldBeginEditing:)]) {
        return [delegate growingTextViewShouldBeginEditing:self];
        
    } else {
        return YES;
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    if ([delegate respondsToSelector:@selector(growingTextViewShouldEndEditing:)]) {
        return [delegate growingTextViewShouldEndEditing:self];
        
    } else {
        return YES;
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([delegate respondsToSelector:@selector(growingTextViewDidBeginEditing:)]) {
        [delegate growingTextViewDidBeginEditing:self];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)textViewDidEndEditing:(UITextView *)textView {
    if ([delegate respondsToSelector:@selector(growingTextViewDidEndEditing:)]) {
        [delegate growingTextViewDidEndEditing:self];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range
 replacementText:(NSString *)atext {
    
    //weird 1 pixel bug when clicking backspace when textView is empty
    if(![textView hasText] && [atext isEqualToString:@""]) return NO;
    
    //Added by bretdabaker: sometimes we want to handle this ourselves
    if ([delegate respondsToSelector:@selector(growingTextView:shouldChangeTextInRange:replacementText:)])
        return [delegate growingTextView:self shouldChangeTextInRange:range replacementText:atext];
    
    if ([atext isEqualToString:@"\n"]) {
        if ([delegate respondsToSelector:@selector(growingTextViewShouldReturn:)]) {
            if (![delegate performSelector:@selector(growingTextViewShouldReturn:) withObject:self]) {
                return YES;
            } else {
                [textView resignFirstResponder];
                return NO;
            }
        }
    }
    
    return YES;
    
    
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)textViewDidChangeSelection:(UITextView *)textView {
    if ([delegate respondsToSelector:@selector(growingTextViewDidChangeSelection:)]) {
        [delegate growingTextViewDidChangeSelection:self];
    }
}



@end
