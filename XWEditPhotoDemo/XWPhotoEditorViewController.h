//
//  XWPhotoEditorViewController.h
//  XWEditPhotoDemo
//
//  Created by Xiaonan Wang on 10/5/13.
//  Copyright (c) 2013 Xiaonan Wang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XWEditPhotoViewController.h"
@interface XWPhotoEditorViewController : XWEditPhotoViewController
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectButton;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@end
