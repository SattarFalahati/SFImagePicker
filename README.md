# SFImagePicker
SFImagePicker 

A nice framework to use Camera and gallery of the phone 

iOS Version 8+

## How it's Work
To implement and make this framework working : 

A) Copy SFImagePicker.h/m, SFImagePickerCell.h/m, SFImagePickerPreview.h/m  and ImagePicker.storyboard to your project

B) You can change icons but if you want to use original icons that already exist in the framework, copy the SFImagePicker folder from Images.cxassets

C) Don't Forget about Plist and add this lines :

```
<key>NSCameraUsageDescription</key>
<string>Your description</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Your description</string>
```

## Delegate 
You can use this delegate to controll the selected photo.

```
- (void)selectedPhoto:(UIImage *)photo;
```
## Options 

* You can chose between front and back camera (default is back camera) 
```
SFImagePickerCameraOption = SFImagePickerCameraFront/SFImagePickerCameraBack;
```

* You can chose to show selected photo preview (default is NO)
```
showPreview = Yes/No;
```
In preview page you can save image to gallery or retake or send photo also you can filter your photo

## Versioning

Version 3.0.0

## Author
Sattar Falahati 

iOS Developer

Plase report any bug you find

sattar.falahati@gmail.com

## License

This project is licensed under the MIT License
