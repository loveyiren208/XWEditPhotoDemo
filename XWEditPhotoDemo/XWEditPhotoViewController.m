//
//  XWEditPhotoViewController.m
//  XWEditPhotoDemo
//
//  Created by Xiaonan Wang on 10/5/13.
//  Copyright (c) 2013 Xiaonan Wang. All rights reserved.
//

#import "XWEditPhotoViewController.h"
#define kAnimationIntervalReset 0.2
#define kAnimationIntervalTransform 0.2

// resize the picture to the size of cropWindow
static const CGFloat kMaxUIImageSize = 1024;
// no idea why set it to 120...
static const CGFloat kPreviewImageSize = 120;

static const CGFloat kDefaultCropWidth = 320;
static const CGFloat kDefaultCropHeight = 320;

@interface XWEditPhotoViewController (){
    // handle the gesture count. sometimes handle more than one gesture
    int gestureCount;
    
    // calculate the center. so the scale and ratation can around this center
    CGPoint touchCenter;
    CGPoint rotationCenter;
    CGPoint scaleCenter;
    
    // the photo's right now scale. check if it is within range of min and max scale
    float scaleNow;
}

// this is the photo view
@property (nonatomic,strong) UIImageView *imageView;

// the previous view can show first, may be blur, waiting for clear imageView to show up
@property(nonatomic,copy) UIImage *previewImage;

// the crop rect
@property (nonatomic,assign) CGRect cropRect;

// gestures
@property (nonatomic,strong) IBOutlet UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic,strong) IBOutlet UIRotationGestureRecognizer *rotationGestureRecognizer;
@property (nonatomic,strong) IBOutlet UIPinchGestureRecognizer *pinchGestureRecognizer;
@property (nonatomic,strong) IBOutlet UITapGestureRecognizer *tapGestureRecognizer;

@end

@implementation XWEditPhotoViewController
@synthesize cropWindow = _cropWindow;

// init view controller. add gesture into controller
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        _rotationGestureRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation:)];
        _pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // the app will resize the photo first. so make the scale to 1
    self.minimumScale = 1;
  
    self.view.layer.masksToBounds = YES;
    
    // init the view. later will assign the rigth photo to it
    self.imageView  = [[UIImageView alloc] init];
    
    self.cropWindow.userInteractionEnabled = YES;
    
    // insert image view below cropWindow. thus, it will show the shadow over the photo
    [self.view insertSubview:self.imageView belowSubview:self.cropWindow];
    [self.view setMultipleTouchEnabled:YES];
    
    // init gestures
    self.panGestureRecognizer.cancelsTouchesInView = NO;
    self.panGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:self.panGestureRecognizer];
    self.rotationGestureRecognizer.cancelsTouchesInView = NO;
    self.rotationGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:self.rotationGestureRecognizer];
    self.pinchGestureRecognizer.cancelsTouchesInView = NO;
    self.pinchGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:self.pinchGestureRecognizer];
    self.tapGestureRecognizer.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:self.tapGestureRecognizer];
    
    [self setUpGestures];
    
}

- (void) setUpGestures{
    // accroding to parameters to enable gestures
    self.panGestureRecognizer.enabled = self.panEnabled;
    self.pinchGestureRecognizer.enabled = self.scaleEnabled;
    self.rotationGestureRecognizer.enabled = self.rotateEnabled;
    self.tapGestureRecognizer.enabled = self.tapToResetEnabled;
}

// disenableAllGesture
// eg: when finish edit photo and upload to server.
// gesture should be disenabled
- (void) disenableAllGesture{
    self.panGestureRecognizer.enabled = NO;
    self.pinchGestureRecognizer.enabled = NO;
    self.rotationGestureRecognizer.enabled = NO;
    self.tapGestureRecognizer.enabled = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // draw the crop window, set crop Window cropRect
    [self updateCropRect];
    
    // make the photo show in the middle of crop window
    [self reset:NO];
    
    // first set to the preview image
    self.imageView.image = self.previewImage;
    
    // show a clear image view will delay. so use previewImage to show a picture first(maybe blur)
    // then it will load a clear imageView
    
    // if preview image is already a clear view(just copy from sourceImage, do not resize).
    // then do not need to do this block
    // if not, set the image to a clear view use block
    if(self.previewImage != self.sourceImage) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            CGImageRef hiresCGImage = NULL;
            CGFloat aspect = self.sourceImage.size.height/self.sourceImage.size.width;
            CGSize size;
            if(aspect >= 1.0) { //square or portrait
                size = CGSizeMake(kMaxUIImageSize*aspect,kMaxUIImageSize);
            } else { // landscape
                size = CGSizeMake(kMaxUIImageSize,kMaxUIImageSize*aspect);
            }
            hiresCGImage = [self newScaledImage:self.sourceImage.CGImage withOrientation:self.sourceImage.imageOrientation toSize:size withQuality:kCGInterpolationDefault];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = [UIImage imageWithCGImage:hiresCGImage scale:1.0 orientation:UIImageOrientationUp];
                CGImageRelease(hiresCGImage);
            });
        });
    }
}

#pragma mark Properties

// amazing one, can quickly get the value without delay
- (UIImage *)previewImage
{
    if(_previewImage == nil && _sourceImage != nil) {
        // this if: is very large picture condition
        // seems related with quaility
        if(self.sourceImage.size.height > kMaxUIImageSize || self.sourceImage.size.width > kMaxUIImageSize) {
            CGFloat aspect = self.sourceImage.size.height/self.sourceImage.size.width;
            CGSize size;
            if(aspect >= 1.0) { //square or portrait
                size = CGSizeMake(kPreviewImageSize,kPreviewImageSize*aspect);
            } else { // landscape
                size = CGSizeMake(kPreviewImageSize,kPreviewImageSize*aspect);
            }
            _previewImage = [self scaledImage:self.sourceImage  toSize:size withQuality: kCGInterpolationLow] ;
        } else {
            _previewImage = _sourceImage;
        }
    }
    return  _previewImage;
}

- (void)setSourceImage:(UIImage *)sourceImage
{
        _sourceImage = sourceImage;
        // clear the previewImage, thus select another page, it will not show the previous one
        self.previewImage = nil;
}

// accroding the croprect to set crop window cropRect
- (void) updateCropRect {
    _cropRect = CGRectMake((self.cropWindow.bounds.size.width - self.cropSize.width)/2,
                           (self.cropWindow.bounds.size.height - self.cropSize.height)/2,
                           self.cropSize.width,
                           self.cropSize.height);
    self.cropWindow.cropRect = self.cropRect;
}

// reset the photo. put the original photo in the middle of crop window
-(void)reset:(BOOL)animated
{
    CGFloat w = 0.0f;
    CGFloat h = 0.0f;
    CGFloat sourceAspect = self.sourceImage.size.height/self.sourceImage.size.width;
    CGFloat cropAspect = self.cropRect.size.height/self.cropRect.size.width;
    
    // resize the photo size. make the smaller size fit in the crop fields
    if(sourceAspect > cropAspect) {
        w = CGRectGetWidth(self.cropRect);
        h = sourceAspect * w;
    } else {
        h = CGRectGetHeight(self.cropRect);
        w = h / sourceAspect;
    }
    
    scaleNow = 1;
    
    // tap twice will do rest
    void (^doReset)(void) = ^{
        //NSLog(@"do rest %d",animated);
        self.imageView.transform = CGAffineTransformIdentity;
        self.imageView.frame = CGRectMake(CGRectGetMidX(self.cropRect) - w/2, CGRectGetMidY(self.cropRect) - h/2,w,h);
        self.imageView.transform = CGAffineTransformMakeScale(scaleNow, scaleNow);
    };
    
    // if animate
    if(animated) {
        self.view.userInteractionEnabled = NO;
        [UIView animateWithDuration:kAnimationIntervalReset animations:doReset completion:^(BOOL finished) {
            self.view.userInteractionEnabled = YES;
        }];
    } else {
        doReset();
    }
}


#pragma mark finish actions

// when finish edit photo and do not cancel
- (IBAction)doneAction:(id)sender
{
    self.view.userInteractionEnabled = NO;
    // do some waiting
    [self startTransformHook];
    
    //
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CGImageRef resultRef = [self newTransformedImage:self.imageView.transform
                                             sourceImage:self.sourceImage.CGImage
                                              sourceSize:self.sourceImage.size
                                       sourceOrientation:self.sourceImage.imageOrientation
                                             outputWidth:self.sourceImage.size.width
                                                cropSize:self.cropSize
                                           imageViewSize:self.imageView.bounds.size];
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *image =  [UIImage imageWithCGImage:resultRef scale:1.0 orientation:UIImageOrientationUp];
            CGImageRelease(resultRef);
            self.view.userInteractionEnabled = YES;
            [self.delegate finish:image didCancel:NO];

            // end waiting
            // this should be called in its delegate finish method.
            // eg: when finish uploading, call this method
            //[self endTransformHook];
        });
    });
    
}
// waiting start
- (void)startTransformHook
{
    [self disenableAllGesture];
}
// waiting end
- (void)endTransformHook
{
    [self setUpGestures];
}

// when finish edit photo and cancel
- (IBAction)cancelAction:(id)sender
{
    [self.delegate finish:nil didCancel:YES];
}



#pragma mark Touches
- (void)handleTouches:(NSSet*)touches
{
    touchCenter = CGPointZero;
    if(touches.count < 2) return;

    // it will make the picture change center always at the touch center
    [touches enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        UITouch *touch = (UITouch*)obj;
        CGPoint touchLocation = [touch locationInView:self.imageView];
        touchCenter = CGPointMake(touchCenter.x + touchLocation.x, touchCenter.y + touchLocation.y);
    }];
    touchCenter = CGPointMake(touchCenter.x/touches.count, touchCenter.y/touches.count);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleTouches:[event allTouches]];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleTouches:[event allTouches]];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleTouches:[event allTouches]];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleTouches:[event allTouches]];
}


#pragma mark - Gesture Handler
// check it is within the range of min and max scale
- (CGFloat)boundedScale:(CGFloat)scale;
{
    CGFloat boundedScale = scale;
    if(self.minimumScale > 0 && scale < self.minimumScale) {
        boundedScale = self.minimumScale;
    } else if(self.maximumScale > 0 && scale > self.maximumScale) {
        boundedScale = self.maximumScale;
    }
    return boundedScale;
}

- (BOOL)handleGestureState:(UIGestureRecognizerState)state
{
    BOOL handle = YES;
    switch (state) {
        case UIGestureRecognizerStateBegan:
            gestureCount++;
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            gestureCount--;
            handle = NO;
            if(gestureCount == 0) {
                // here change back to right scale
                CGFloat scale = [self boundedScale:scaleNow];
                
                // if the scale now is not the right scale. change the scale to right one
                if(scale != scaleNow) {
                    // no idea what is that deltax or y used for
                    // seems to calculate, if no deltax or y, when it to the edage of page, it does not work well
                    CGFloat deltaX = scaleCenter.x-self.imageView.bounds.size.width/2.0;
                    CGFloat deltaY = scaleCenter.y-self.imageView.bounds.size.height/2.0;
                    
                    CGAffineTransform transform =  CGAffineTransformTranslate(self.imageView.transform, deltaX, deltaY);
                    transform = CGAffineTransformScale(transform, scale/scaleNow , scale/scaleNow);
                    transform = CGAffineTransformTranslate(transform, -deltaX, -deltaY);
                    self.view.userInteractionEnabled = NO;
                    // change the scale and when completion, check the bounds and make it to right location
                    [UIView animateWithDuration:kAnimationIntervalTransform delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                        self.imageView.transform = transform;
                    } completion:^(BOOL finished) {
                        self.view.userInteractionEnabled = YES;
                        scaleNow = scale;
                        [self doCheckBounds];

                    }];
                } else {
                    [self doCheckBounds];
                }
            }
        } break;
        default:
            break;
    }
    return handle;
}

// check if it is in the right bounds. if not, put the photo back to right location
-(void)doCheckBounds {
    CGFloat yOffset = 0;
    CGFloat xOffset = 0;
    
    // the crop picture is not within right width
    if(self.imageView.frame.origin.x > self.cropRect.origin.x){
        xOffset =  - (self.imageView.frame.origin.x - self.cropRect.origin.x);
        CGFloat newRightX = CGRectGetMaxX(self.imageView.frame) + xOffset;
        if(newRightX < CGRectGetMaxX(self.cropRect)) {
            xOffset =  CGRectGetMaxX(self.cropRect) - CGRectGetMaxX(self.imageView.frame);
        }
    } else if(CGRectGetMaxX(self.imageView.frame) < CGRectGetMaxX(self.cropRect)){
        xOffset = CGRectGetMaxX(self.cropRect) - CGRectGetMaxX(self.imageView.frame);
        CGFloat newLeftX = self.imageView.frame.origin.x + xOffset;
        if(newLeftX > self.cropRect.origin.x) {
            xOffset = self.cropRect.origin.x - self.imageView.frame.origin.x;
        }
    }
    
    // the crop picture is not within right height
    if (self.imageView.frame.origin.y > self.cropRect.origin.y) {
        yOffset = - (self.imageView.frame.origin.y - self.cropRect.origin.y);
        CGFloat newBottomY = CGRectGetMaxY(self.imageView.frame) + yOffset;
        if(newBottomY < CGRectGetMaxY(self.cropRect)) {
            yOffset = CGRectGetMaxY(self.cropRect) - CGRectGetMaxY(self.imageView.frame);
        }
    } else if(CGRectGetMaxY(self.imageView.frame) < CGRectGetMaxY(self.cropRect)){
        yOffset = CGRectGetMaxY(self.cropRect) - CGRectGetMaxY(self.imageView.frame);
        CGFloat newTopY = self.imageView.frame.origin.y + yOffset;
        if(newTopY > self.cropRect.origin.y) {
            yOffset = self.cropRect.origin.y - self.imageView.frame.origin.y;
        }
    }
    
    // set to right location
    if(xOffset || yOffset){
        self.view.userInteractionEnabled = NO;
        CGAffineTransform transform =
        CGAffineTransformTranslate(self.imageView.transform,
                                   xOffset/scaleNow, yOffset/scaleNow);
        [UIView animateWithDuration:kAnimationIntervalTransform delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.imageView.transform = transform;
        } completion:^(BOOL finished) {
            self.view.userInteractionEnabled = YES;
        }];
    }
}

// handle pan
-(IBAction)handlePan:(UIPanGestureRecognizer*)recognizer{
    if([self handleGestureState:recognizer.state]) {
        CGPoint translation = [recognizer translationInView:self.imageView];
        CGAffineTransform transform = CGAffineTransformTranslate( self.imageView.transform, translation.x, translation.y);
        self.imageView.transform = transform;
        
        [recognizer setTranslation:CGPointMake(0, 0) inView:self.cropWindow];
    }

}

// handle rotation
-(IBAction)handleRotation:(UIRotationGestureRecognizer*)recognizer{
    if([self handleGestureState:recognizer.state]) {
        if(recognizer.state == UIGestureRecognizerStateBegan){
            rotationCenter = touchCenter;
        }
        CGFloat deltaX = rotationCenter.x-self.imageView.bounds.size.width/2;
        CGFloat deltaY = rotationCenter.y-self.imageView.bounds.size.height/2;
        
        CGAffineTransform transform =  CGAffineTransformTranslate(self.imageView.transform,deltaX,deltaY);
        transform = CGAffineTransformRotate(transform, recognizer.rotation);
        transform = CGAffineTransformTranslate(transform, -deltaX, -deltaY);
        self.imageView.transform = transform;
        
        recognizer.rotation = 0;
    }

}

// handle pinch
-(IBAction)handlePinch:(UIPinchGestureRecognizer*)recognizer{
    if([self handleGestureState:recognizer.state]) {
        if(recognizer.state == UIGestureRecognizerStateBegan){
            scaleCenter = touchCenter;
        }
        CGFloat deltaX = scaleCenter.x-self.imageView.bounds.size.width/2.0;
        CGFloat deltaY = scaleCenter.y-self.imageView.bounds.size.height/2.0;
        
        CGAffineTransform transform =  CGAffineTransformTranslate(self.imageView.transform, deltaX, deltaY);
        transform = CGAffineTransformScale(transform, recognizer.scale, recognizer.scale);
        transform = CGAffineTransformTranslate(transform, -deltaX, -deltaY);
        scaleNow *= recognizer.scale;
        self.imageView.transform = transform;
        
        recognizer.scale = 1;
    }
}


// handle tap
-(IBAction)handleTap:(UITapGestureRecognizer*)recognizer{
    [self reset:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}



# pragma mark Image Transformation
- (UIImage *)scaledImage:(UIImage *)source toSize:(CGSize)size withQuality:(CGInterpolationQuality)quality
{
    CGImageRef cgImage  = [self newScaledImage:source.CGImage withOrientation:source.imageOrientation toSize:size withQuality:quality];
    UIImage * result = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:UIImageOrientationUp];
    CGImageRelease(cgImage);
    return result;
}


- (CGImageRef)newScaledImage:(CGImageRef)source withOrientation:(UIImageOrientation)orientation toSize:(CGSize)size withQuality:(CGInterpolationQuality)quality
{
    CGSize srcSize = size;
    CGFloat rotation = 0.0;
    
    switch(orientation)
    {
        case UIImageOrientationUp: {
            rotation = 0;
        } break;
        case UIImageOrientationDown: {
            rotation = M_PI;
        } break;
        case UIImageOrientationLeft:{
            rotation = M_PI_2;
            srcSize = CGSizeMake(size.height, size.width);
        } break;
        case UIImageOrientationRight: {
            rotation = -M_PI_2;
            srcSize = CGSizeMake(size.height, size.width);
        } break;
        default:
            break;
    }
    
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 size.width,
                                                 size.height,
                                                 CGImageGetBitsPerComponent(source), //8,
                                                 0,
                                                 CGImageGetColorSpace(source),
                                                 CGImageGetBitmapInfo(source) //kCGImageAlphaNoneSkipFirst
                                                 );
    
    CGContextSetInterpolationQuality(context, quality);
    CGContextTranslateCTM(context,  size.width/2,  size.height/2);
    CGContextRotateCTM(context,rotation);
    
    CGContextDrawImage(context, CGRectMake(-srcSize.width/2 ,
                                           -srcSize.height/2,
                                           srcSize.width,
                                           srcSize.height),
                       source);
    
    CGImageRef resultRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    return resultRef;
}

- (CGImageRef)newTransformedImage:(CGAffineTransform)transform
                      sourceImage:(CGImageRef)sourceImage
                       sourceSize:(CGSize)sourceSize
                sourceOrientation:(UIImageOrientation)sourceOrientation
                      outputWidth:(CGFloat)outputWidth
                         cropSize:(CGSize)cropSize
                    imageViewSize:(CGSize)imageViewSize
{
    CGImageRef source = [self newScaledImage:sourceImage
                             withOrientation:sourceOrientation
                                      toSize:sourceSize
                                 withQuality:kCGInterpolationNone];
    
    CGFloat aspect = cropSize.height/cropSize.width;
    CGSize outputSize = CGSizeMake(outputWidth, outputWidth*aspect);
    
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 outputSize.width,
                                                 outputSize.height,
                                                 CGImageGetBitsPerComponent(source),
                                                 0,
                                                 CGImageGetColorSpace(source),
                                                 CGImageGetBitmapInfo(source));
    CGContextSetFillColorWithColor(context,  [[UIColor clearColor] CGColor]);
    CGContextFillRect(context, CGRectMake(0, 0, outputSize.width, outputSize.height));
    
    CGAffineTransform uiCoords = CGAffineTransformMakeScale(outputSize.width/cropSize.width,
                                                            outputSize.height/cropSize.height);
    uiCoords = CGAffineTransformTranslate(uiCoords, cropSize.width/2.0, cropSize.height/2.0);
    uiCoords = CGAffineTransformScale(uiCoords, 1.0, -1.0);
    CGContextConcatCTM(context, uiCoords);
    
    CGContextConcatCTM(context, transform);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextDrawImage(context, CGRectMake(-imageViewSize.width/2.0,
                                           -imageViewSize.height/2.0,
                                           imageViewSize.width,
                                           imageViewSize.height)
                       ,source);
    
    CGImageRef resultRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGImageRelease(source);
    return resultRef;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
