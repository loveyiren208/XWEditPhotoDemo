//
//  XWEditPhotoViewController.h
//  XWEditPhotoDemo
//
//  Created by Xiaonan Wang on 10/5/13.
//  Copyright (c) 2013 Xiaonan Wang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XWCropWindow.h"
/**
 after edit the photo. it will ask its delegate to do this method.
 */
@protocol XWFinishEditPhoto
- (void) finish:(UIImage *) image didCancel:(BOOL)cancel;
@end

/**
 This class can crop the photo into different rect
 */
@interface XWEditPhotoViewController : UIViewController<UIGestureRecognizerDelegate>

@property(unsafe_unretained) IBOutlet id<XWFinishEditPhoto> delegate;

// pass the image which you want to edit
@property (nonatomic,copy) UIImage *sourceImage;

// this is the crop window. link it to your view.
// it will mask the wanted size with clear color. the other view size with black color.
@property (nonatomic,strong) IBOutlet XWCropWindow *cropWindow;

// the crop window size. it will pass to XWCropWindow
@property (nonatomic,assign) CGSize cropSize;

// control allowed gesture
@property(nonatomic,assign) BOOL panEnabled;
@property(nonatomic,assign) BOOL rotateEnabled;
@property(nonatomic,assign) BOOL scaleEnabled;
@property(nonatomic,assign) BOOL tapToResetEnabled;

// min and max allowed scale
// right now the min inside the code set to 1. if you want to change it. go inside the code
@property (nonatomic,assign) CGFloat minimumScale;
@property (nonatomic,assign) CGFloat maximumScale;

// redo the photo. photo will show in the middle
-(void)reset:(BOOL)animated;
- (void)startTransformHook;
- (void)endTransformHook;
@end
