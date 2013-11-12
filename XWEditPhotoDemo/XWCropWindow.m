//
//  XWCropWindow.m
//  XWEditPhotoDemo
//
//  Created by Xiaonan Wang on 10/5/13.
//  Copyright (c) 2013 Xiaonan Wang. All rights reserved.
//
#define IS_WIDESCREEN ( [ [ UIScreen mainScreen ] bounds ].size.height == 568 )
#define IS_IPHONE ( [ [ [ UIDevice currentDevice ] model ] isEqualToString: @"iPhone" ] )
#define IS_IPHONE5 ( IS_IPHONE && IS_WIDESCREEN )
#define IS_RETINA ( [[UIScreen mainScreen] scale] == 2.0 )


#import "XWCropWindow.h"
@interface XWCropWindow()
@property (nonatomic, strong) UIImageView *imageView;
@end

@implementation XWCropWindow

- (void) initialize{
    // set clear color. thus the photo can show in the screen without mask
    self.opaque = NO;
    self.layer.opacity = 0.7;
    self.backgroundColor = [UIColor clearColor];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:imageView];
    self.imageView = imageView;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

// this is important
- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        if (IS_WIDESCREEN) {
            [self setFrame:CGRectMake(0, 0, 320, 524)];
        } else {
            [self setFrame:CGRectMake(0, 0, 320, 436)];
        }
        [self initialize];
    }
    return self;
}


- (void)setCropRect:(CGRect)cropRect
{
    if (!CGRectEqualToRect(_cropRect, cropRect)) {
        _cropRect = cropRect;
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.f);
        // set whole screen black color
        CGContextRef context = UIGraphicsGetCurrentContext();
        [[UIColor blackColor] setFill];
        UIRectFill(self.bounds);
        
        // set the frame border color
        CGContextSetStrokeColorWithColor(context, [[UIColor purpleColor] colorWithAlphaComponent:0.5].CGColor);
        
        // set the frame color. it is clear. so the crop window is clear
        CGContextStrokeRect(context, _cropRect);
        [[UIColor clearColor] setFill];
        
        UIRectFill(CGRectInset(_cropRect, 1, 1));
        
        self.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    }
}
/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

@end
