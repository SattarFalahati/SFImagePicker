# SFImagePicker
SFImagePicker 

A class to use Camera and gallery of the phone 

iOS Version 8+

## How it's Work
To implement and make this class working : 

A) Copy SFImagePicker.h/m , SFImagePickerCell.h/m and ImagePicker.storyboard to your project

B) You can change icons but if you want to use icons copy the SFImagePicker folder from Images.cxassets

C) Don't Forget about Plist and add this lines :

```
<key>NSCameraUsageDescription</key>
<string>Your description</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Your description</string>
```

## Delegate 
You can Use delegates to controll the selected photo.

```
- (void)selectedPhoto:(UIImage *)photo;
```
## Versioning

Version 1.0.0

## Author
Sattar Falahati 

iOS Developer

Plase report any bug you find

sattar.falahati@gmail.com

## License

This project is licensed under the MIT License
