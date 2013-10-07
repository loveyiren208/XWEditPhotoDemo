//
//  XWPhotoEditorViewController.m
//  XWEditPhotoDemo
//
//  Created by Xiaonan Wang on 10/5/13.
//  Copyright (c) 2013 Xiaonan Wang. All rights reserved.
//

#import "XWPhotoEditorViewController.h"

@interface XWPhotoEditorViewController ()

@end

@implementation XWPhotoEditorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.minimumScale = 0.2;
        self.maximumScale = 10;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// waiting start
- (void)startTransformHook
{
    [super startTransformHook];
    [_indicator startAnimating];
    [_cancelButton setEnabled:NO];
    [_selectButton setEnabled:NO];
}

- (void)endTransformHook{
    [super endTransformHook];
    [_indicator stopAnimating];
    [_cancelButton setEnabled:YES];
    [_selectButton setEnabled:YES];
}

@end
