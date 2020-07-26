//
//  ViewController.m
//  WSIcon
//
//  Created by Leptos on 6/13/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (UIImage *)iconForDimension:(CGFloat)dimension scale:(CGFloat)scale inset:(BOOL)inset {
    CGFloat const offset = inset ? dimension/16 : 0;
    CGRect const fullFrame = CGRectMake(0, 0, dimension, dimension);
    dimension -= (offset * 2);
    CGRect const frame = CGRectMake(offset, offset, dimension, dimension);
    
    UIGraphicsBeginImageContextWithOptions(fullFrame.size, NO, scale);
    CGContextRef __unused context = UIGraphicsGetCurrentContext();
    
    // TODO: Icon
    
    [UIColor.systemFillColor setFill];
    [[UIBezierPath bezierPathWithRect:fullFrame] fill];
    
    UIFont *roundedFont = [UIFont fontWithName:@"SFCompactRounded-Semibold" size:dimension/1.6];
    NSDictionary<NSAttributedStringKey, id> *stringAttributes = @{
        NSFontAttributeName : roundedFont,
        NSForegroundColorAttributeName : UIColor.systemGreenColor
    };
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"WS" attributes:stringAttributes];
    CGRect stringReq = [string boundingRectWithSize:frame.size options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    
    stringReq.origin.x = (fullFrame.size.width-stringReq.size.width)/2;
    stringReq.origin.y = (fullFrame.size.height-stringReq.size.height)/2;
    
    [string drawInRect:stringReq];
    
    
    UIImage *ret = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return ret;
}

// e.g. "Assets.xcassets/AppIcon.appiconset"
- (void)writeIconAssetsForIconSet:(NSString *)appiconset inset:(BOOL)inset {
    NSString *manifest = [appiconset stringByAppendingPathComponent:@"Contents.json"];
    NSData *parse = [NSData dataWithContentsOfFile:manifest];
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:parse options:(NSJSONReadingMutableContainers) error:&error];
    NSArray<NSMutableDictionary<NSString *, NSString *> *> *images = dict[@"images"];
    for (NSMutableDictionary<NSString *, NSString *> *image in images) {
        NSString *scale = image[@"scale"];
        NSString *size = image[@"size"];
        NSInteger scaleLastIndex = scale.length - 1;
        assert([scale characterAtIndex:scaleLastIndex] == 'x');
        NSString *numScale = [scale substringToIndex:scaleLastIndex];
        
        NSArray<NSString *> *sizeParts = [size componentsSeparatedByString:@"x"];
        assert(sizeParts.count == 2);
        NSString *numSize = sizeParts.firstObject;
        assert([numSize isEqualToString:sizeParts.lastObject]);
        
        NSString *fileName = [NSString stringWithFormat:@"AppIcon%@@%@.png", size, scale];
        UIImage *render = [self iconForDimension:numSize.doubleValue scale:numScale.doubleValue inset:inset];
        NSData *fileData = UIImagePNGRepresentation(render);
        assert([fileData writeToFile:[appiconset stringByAppendingPathComponent:fileName] atomically:YES]);
        image[@"filename"] = fileName;
    }
    NSData *serial = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    assert([serial writeToFile:manifest atomically:YES]);
}

#if 0
- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *file = @__FILE__;
    NSString *targetRoot = file.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent;
    NSString *projectRoot = targetRoot.stringByDeletingLastPathComponent;
    NSString *iconSet = [projectRoot stringByAppendingPathComponent:@"WorkoutSpot/Assets.xcassets/AppIcon.appiconset"];
    [self writeIconAssetsForIconSet:iconSet inset:YES];
}
#endif

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    UIImageView *imageView = self.imageView;
    CGRect const rect = imageView.frame;
    imageView.image = [self iconForDimension:fmin(rect.size.width, rect.size.height) scale:0 inset:YES];
}

@end
