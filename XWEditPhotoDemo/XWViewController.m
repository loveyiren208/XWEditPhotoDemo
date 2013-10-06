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
@property (strong, nonatomic) XWPhotoEditorViewController *photoEditor;
@property (strong, nonatomic) ALAssetsLibrary *library;
@end

@implementation XWViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _imgPicker = [[UIImagePickerController alloc] init];
    _library = [[ALAssetsLibrary alloc] init];
    _photoEditor = [[XWPhotoEditorViewController alloc] initWithNibName:@"XWPhotoEditorViewController" bundle:nil];
   // _photoEditor.cropSize = CGSizeMake(320, 320);
    
    _photoEditor.panEnabled = YES;
    _photoEditor.scaleEnabled = YES;
    _photoEditor.tapToResetEnabled = YES;
    _photoEditor.rotateEnabled = NO;
    _photoEditor.delegate = self;
    _photoEditor.cropSize = CGSizeMake(200, 220);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)pick:(id)sender {
    NSString *libraryTitle = @"From Library";
    NSString *takePhotoTitle = @"Take A Photo";
    NSString *cancelTitle = @"Cancel";
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:nil
                                  delegate:self
                                  cancelButtonTitle:cancelTitle
                                  destructiveButtonTitle:nil
                                  otherButtonTitles:libraryTitle,takePhotoTitle, nil];
    [actionSheet showInView:self.view];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSURL *assetURL = [info objectForKey:UIImagePickerControllerMediaURL];
    
    [self.library assetForURL:assetURL resultBlock:^(ALAsset *asset) {
        self.photoEditor.sourceImage = image;
        [picker pushViewController:self.photoEditor animated:YES];
        [picker setNavigationBarHidden:YES animated:NO];
    } failureBlock:^(NSError *error) {
        NSLog(@"failed to get asset from library");
    }];
}


-(void)finish:(UIImage *)image didCancel:(BOOL)cancel {
    if (!cancel) {
        [_library
         writeImageToSavedPhotosAlbum:[image CGImage]
         orientation:(ALAssetOrientation)image.imageOrientation
         completionBlock:^(NSURL *assetURL, NSError *error){
             if (error) {
                 UIAlertView *alert =
                 [[UIAlertView alloc] initWithTitle:@"Error Saving"
                                            message:[error localizedDescription]
                                           delegate:nil
                                  cancelButtonTitle:@"Ok"
                                  otherButtonTitles: nil];
                 [alert show];
             }
         }];
        _photo.image = image;
    }
    [self dismissViewControllerAnimated:YES completion:nil];

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
