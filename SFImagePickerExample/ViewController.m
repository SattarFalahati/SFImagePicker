//
//  ViewController.m
//  SFImagePickerExample
//
//  Created by Sattar Falahati on 31/03/17.
//  Copyright © 2017 Sattar Falahati. All rights reserved.
//

#import "ViewController.h"

// SFImagePicker
#import "SFImagePicker.h"

@interface ViewController () <SFImagePickerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.img.image = [UIImage imageNamed:@"Happy"];
}

- (IBAction)openSFImagePicker:(id)sender
{
    BOOL camera =  [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    
    if (!camera) return;
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"ImagePicker" bundle:nil];
    SFImagePicker *next = [storyboard instantiateViewControllerWithIdentifier:@"SFImagePicker"];
    next.delegate = self;
    next.option = SFImagePickerCameraFront;
    [self presentViewController:next animated:YES completion:^{
        
    }];
}

// MARK: SFImagePicker Delegate

- (void)selectedPhoto:(UIImage *)photo
{
    self.img.image = photo;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
