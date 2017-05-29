//
//  SFImagePicker.m
//  SFramework
//
//  Created by Sattar Falahati on 14/03/17.
//  Copyright © 2017 sattar_falahati. All rights reserved.
//

#import "SFImagePicker.h"

// Freamworks
@import AVFoundation;
@import Photos;
@import MediaPlayer;

// CELL
#import "SFImagePickerCell.h"

// Defines
#define  KCapturePhotoWithVolume   @"outputVolume"
#define RGBA(r, g, b, a)                [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]

@interface SFImagePicker () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

// Image gallery
@property (nonatomic, strong) NSArray *arrDataSource;

// Check which camera is active
@property (nonatomic) BOOL frontCamera;

// AVFundation Objects
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureDeviceInput *deviceInput;
@property (strong, nonatomic) AVCaptureStillImageOutput *imageOutput;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;

// Photos framework
@property (strong, nonatomic) PHFetchResult *assetsFetchResults;
@property (strong, nonatomic) PHCachingImageManager *imageManager;

// Check for collection view size
@property (nonatomic) BOOL collectionBigSize;

// Handle audioSession to take photo with volume buttons
@property (strong, nonatomic) AVAudioSession *audioSession;

@end

@implementation SFImagePicker

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // UI
    self.cameraView.alpha = 0;
    
    for (UIButton *btn in self.buttons) {
        btn.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
        [btn setBackgroundColor:RGBA(0, 0, 0, .1)];
        CGFloat radius = fmin(btn.frame.size.height , btn.frame.size.width);
        [btn.layer setCornerRadius:(radius/2.0)];
    }
    
    // Page options
    self.collectionBigSize = NO;
    
    // Initial Camera
    if (self.option == SFImagePickerCameraFront) {
        self.frontCamera = YES;
    }
    else if (self.option == SFImagePickerCameraBack) {
        self.frontCamera = NO;
    }
    else {
        self.frontCamera = NO;
    }
    
    [self initCamera];
    
    // Initial gallery
    self.imageManager = [PHCachingImageManager new];
    [self initialImageGalleryCollection];
    [self checkForAuthorization];
    
    // Initial audio session
    [self initAudioSession];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Hide volume view
    CGRect frame = CGRectMake(-1000, -1000, 100, 100);
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:frame];
    [volumeView sizeToFit];
    [self.view addSubview:volumeView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Remove observer
    [self.audioSession removeObserver:self forKeyPath:KCapturePhotoWithVolume];
}

// MARK: - Capture photo with Volume button

- (void)initAudioSession
{
    self.audioSession = [AVAudioSession sharedInstance];
    [self.audioSession  setActive:YES error:nil];
    
    [self.audioSession addObserver:self forKeyPath:KCapturePhotoWithVolume options:0 context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:KCapturePhotoWithVolume]) {
        
        // Capture photo
        [self capturePhoto];
    }
}


// MARK: - Camera

- (void)initCamera
{
    // Check Authorization status
    if ([self getAuthorizationStatus] == AVAuthorizationStatusDenied) {
        
        // Create alertController
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Ops!" message:@"You have not authorized us to access your camera.\n To change that go to your setting and change camera authorization" preferredStyle:UIAlertControllerStyleAlert];
        
        // Add button
        UIAlertAction *button = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self closeSFImagePicker];
            });
        }];
        [alertController addAction:button];
        
        // Present alert (show)
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:alertController animated:YES completion:nil];
        });
        
        return;
    }

    
    //Capture Session
    self.captureSession = [AVCaptureSession new];
    self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    
    //Add Input & device
    AVCaptureDevice *captureDevice;
    if (self.frontCamera) {
        [self.btnChangeCamera setImage:[UIImage imageNamed:@"SFImagePickerFrontCamera"] forState:UIControlStateNormal];
        captureDevice  = [self getFrontCamera];
    }
    else {
        [self.btnChangeCamera setImage:[UIImage imageNamed:@"SFImagePickerBackCamera"] forState:UIControlStateNormal];
        captureDevice = [self getBackCamera];
    }
    
    self.deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:nil];
    
    if (!self.deviceInput) {
        NSLog(@"No Input");
    }
    
    [self.captureSession addInput:self.deviceInput];
    
    // Add Output
    self.imageOutput = [AVCaptureStillImageOutput new];
    self.imageOutput.outputSettings =@{AVVideoCodecJPEG: AVVideoCodecKey};
    [self.captureSession addOutput:self.imageOutput];
    
    //Preview Layer
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    UIView *myView = self.view;
    self.previewLayer.frame = myView.bounds;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.cameraView.layer addSublayer:self.previewLayer];
    
    //Start capture session
    [self startCameraWithCompletionBlock:^{
        // Do sth if needed
    }];
}

- (void)startCameraWithCompletionBlock:(void (^)())completionBlock
{
    dispatch_async(dispatch_get_main_queue(), ^(){
        
        [self.captureSession startRunning];
        
        [UIView animateWithDuration:.3 animations:^{
            self.cameraView.alpha = 1;
        } completion:^(BOOL finished) {
            
            if (completionBlock) completionBlock();
        }];
    });
}

- (void)stopCameraWithCompletionBlock:(void (^)())completionBlock
{
    dispatch_async(dispatch_get_main_queue(), ^(){
        [self.captureSession stopRunning];
        
        [UIView animateWithDuration:.3 animations:^{
            self.cameraView.alpha = 0;
        } completion:^(BOOL finished) {
            
            if (completionBlock) completionBlock();
        }];
    });
}

// Get front camera
- (AVCaptureDevice *)getFrontCamera
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *device in devices) {
        if (device.position == AVCaptureDevicePositionFront) {
            return device;
        }
    }
    
    return nil;
}

- (AVCaptureDevice *)getBackCamera
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *device in devices) {
        if (device.position == AVCaptureDevicePositionBack) {
            return device;
        }
    }
    
    return nil;
}

- (void)captureOutputImageWithCompletionBlock:(void (^)(UIImage *image))completionBlock
{
    AVCaptureConnection *captureConnection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
    
    [self.imageOutput captureStillImageAsynchronouslyFromConnection:captureConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        UIImage *image = nil;
        
        if (imageDataSampleBuffer) {
            @autoreleasepool {
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                image = [[UIImage alloc] initWithData:imageData];
                
                // Image have right miror orientation when we took photo from front camera, so we need to raotat it again.
                UIImageOrientation orient = image.imageOrientation;
                CGImageRef imageRef = [image CGImage];
                
                if (self.frontCamera && orient == UIImageOrientationRight){
                    image = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:UIImageOrientationLeftMirrored];
                }
            }
        }
        
        if (completionBlock) completionBlock(image);
    }];
}

// MARK: - Authorization

- (AVAuthorizationStatus)getAuthorizationStatus
{
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    return status;
}

// MARK: - Photo gallery

- (void)checkForAuthorization
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    
    if (status == PHAuthorizationStatusAuthorized) {
        [self getAllPhotosFromGallery];
    }
    else {
        [self performSelector:@selector(checkForAuthorization) withObject:nil afterDelay:.5];
    }
}

- (void)getAllPhotosFromGallery
{
    // Fetch all assets, sorted by date created.
    PHFetchOptions *options = [PHFetchOptions new];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    self.assetsFetchResults = [PHAsset fetchAssetsWithOptions:options];
    
    [self.imageCollection reloadData];
    
    [UIView animateWithDuration:.3 animations:^{
        self.imageCollection.alpha = 1;
    } completion:^(BOOL finished) {
        // Do sth if needed
    }];
}

// MARK: - CollectionView & Delegate

- (void)initialImageGalleryCollection
{
    self.imageCollection.alpha = 0;
    self.imageCollection.delegate = self;
    self.imageCollection.dataSource = self;
    self.imageCollection.backgroundColor = [UIColor clearColor];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.assetsFetchResults.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Object
    PHAsset *asset = self.assetsFetchResults[indexPath.item];
    
    // Cell
    SFImagePickerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SFImagePickerCell" forIndexPath:indexPath];
    
    // Show the preview
    [self.imageManager requestImageForAsset:asset targetSize:CGSizeMake(200, 200) contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage *result, NSDictionary *info)
     {
         cell.image.image = result;
     }];
    
    return cell;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 3;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 3;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(self.collectionHaight.constant, self.collectionHaight.constant);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    PHAsset *asset = self.assetsFetchResults[indexPath.item];
    
    [self.imageManager requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage *result, NSDictionary *info)
     {
         // result is the actual image object.
         [self photoSelected:result];
     }];
}

// MARK: - Actions

- (IBAction)btnCloseSFImagePicker:(id)sender
{
    [self closeSFImagePicker];
}

- (IBAction)btnChangeCamera:(id)sender
{
    if (self.frontCamera) {
        // Turn to back camera
        self.frontCamera = NO;
    }
    else {
        // Turn to Front camera
        self.frontCamera = YES;
    }
    
    [self stopCameraWithCompletionBlock:^{
        [self initCamera];
    }];
    
}

- (IBAction)btnCapturePhoto:(id)sender
{
    [self capturePhoto];
}

- (IBAction)btnResizeCollection:(id)sender
{
    // Change the heigght
    if (self.collectionBigSize) {
        self.collectionBigSize = NO;
        [self.collectionHaight setConstant: 100];
    }
    else {
        self.collectionBigSize = YES;
        [self.collectionHaight setConstant: 200];
    }
    
    // Disble button
    [self.btnResize setEnabled: NO];
    
    // Animate view
    [UIView transitionWithView:self.imageCollection duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        
        // View
        [self.view layoutIfNeeded];
        
        // Collection view
        UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *) self.imageCollection.collectionViewLayout;
        layout.itemSize = CGSizeMake(self.collectionHaight.constant, self.collectionHaight.constant);
        [self.imageCollection reloadData];
        [layout invalidateLayout];
        
        // Animate button
        if (CGAffineTransformEqualToTransform(self.btnResize.transform, CGAffineTransformIdentity)) {
            self.btnResize.transform = CGAffineTransformMakeRotation(M_PI * 0.999);
        } else {
            self.btnResize.transform = CGAffineTransformIdentity;
        }
    } completion:^(BOOL finished) {
        // Enable button
        [self.btnResize setEnabled: YES];
    }];
}

- (void)capturePhoto
{
    [self captureOutputImageWithCompletionBlock:^(UIImage *image) {
        [self photoSelected:image];
    }];
}

// MARK: - Helper

- (void)closeSFImagePicker
{
    [self stopCameraWithCompletionBlock:^{
        
    }];
    
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

// MARK: - Delegate

- (void)photoSelected:(UIImage *)image
{
    if ([self.delegate respondsToSelector:@selector(selectedPhoto:)]) {
        [self.delegate selectedPhoto:image];
    }
    
    [self closeSFImagePicker];
}


@end
