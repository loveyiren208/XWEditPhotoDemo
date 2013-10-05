//
//  XWViewController.h
//  XWEditPhotoDemo
//
//  Created by Xiaonan Wang on 10/4/13.
//  Copyright (c) 2013 Xiaonan Wang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XWViewController : UIViewController <UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIActionSheetDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *photo;
- (IBAction)pick:(id)sender;

@end
