//
//  XWViewController.m
//  XWEditPhotoDemo
//
//  Created by Xiaonan Wang on 10/4/13.
//  Copyright (c) 2013 Xiaonan Wang. All rights reserved.
//

#import "XWViewController.h"

@interface XWViewController ()
@property (strong, nonatomic) UIImagePickerController *imgPicker;

@end

@implementation XWViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _imgPicker = [[UIImagePickerController alloc] init];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)pick:(id)sender {
    NSString *actionSheetTitle = @"SELECT A PHOTO";
    NSString *libraryTitle = @"From Library";
    NSString *takePhotoTitle = @"Take A Photo";
    NSString *cancelTitle = @"Cancel";
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:actionSheetTitle
                                  delegate:self
                                  cancelButtonTitle:cancelTitle
                                  destructiveButtonTitle:nil
                                  otherButtonTitles:libraryTitle,takePhotoTitle, nil];
    [actionSheet showInView:self.view];
}


#pragma mark -
#pragma mark UIActionSheetDelegate Methods
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        NSLog(@"press 0");
        [self showImagePicker:UIImagePickerControllerSourceTypePhotoLibrary];
    } else if (buttonIndex == 1) {
        NSLog(@"press 1");
        [self showImagePicker:UIImagePickerControllerSourceTypeCamera];
    }
}


-(void)showImagePicker:(UIImagePickerControllerSourceType) sourceType {
    _imgPicker.sourceType = sourceType;
    [_imgPicker setAllowsEditing:NO];
    _imgPicker.delegate = self;
    if (_imgPicker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        _imgPicker.showsCameraControls = YES;
    }
    if ( [UIImagePickerController isSourceTypeAvailable:sourceType]) {
        [self presentViewController:_imgPicker animated:YES completion:nil];
    }
}
@end
