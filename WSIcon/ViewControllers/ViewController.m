//
//  ViewController.m
//  WSIcon
//
//  Created by Leptos on 6/13/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "ViewController.h"

CGPoint CGPointPolarCenter(CGFloat radius, double angle, CGPoint center) {
    return CGPointMake(center.x + radius * cos(angle), center.y + radius * sin(angle));
}

@implementation ViewController

- (UIImage *)iconForDimension:(CGFloat)dimension scale:(CGFloat)scale inset:(BOOL)inset {
    CGFloat const offset = inset ? dimension/16 : 0;
    CGRect const fullFrame = CGRectMake(0, 0, dimension, dimension);
    CGFloat const fullRadius = dimension/2;
    dimension -= (offset * 2);
    CGRect const frame = CGRectMake(offset, offset, dimension, dimension);
    CGFloat const radius = dimension/2;
    
    UIGraphicsBeginImageContextWithOptions(fullFrame.size, NO, scale);
    
    // [[UIColor colorWithRed:(48.0/0xff) green:(80.0/0xff) blue:(160.0/0xff) alpha:1] setFill];
    [UIColor.blackColor setFill];
    [[UIBezierPath bezierPathWithRect:fullFrame] fill];
    
    [UIColor.whiteColor setStroke];
    [UIColor.whiteColor setFill];
    
    CGFloat const strokeWidth = dimension/48;
    
    if (inset) {
        UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(frame, strokeWidth, strokeWidth)];
        circle.lineWidth = strokeWidth;
        [circle stroke];
    }
    UIBezierPath *hand = [UIBezierPath bezierPath];
    double handAngle = M_PI * 1.825; // radians
    hand.lineWidth = strokeWidth;
    hand.lineCapStyle = kCGLineCapRound;
    CGPoint handCenter = CGPointMake(fullRadius, fullRadius + dimension * 0.16);
    [hand moveToPoint:handCenter];
    [hand addLineToPoint:CGPointPolarCenter(radius * 0.84, handAngle, handCenter)];
    [hand stroke];
    
    UIBezierPath *handPin = [UIBezierPath bezierPath];
    CGFloat handPinRadius = dimension/15;
    CGFloat handPinSpacing = dimension/90;
    double openingAngle = (strokeWidth + handPinSpacing*2) / handPinRadius;
    [handPin addArcWithCenter:handCenter radius:handPinRadius startAngle:(handAngle + openingAngle/2)
                     endAngle:(handAngle - openingAngle/2) clockwise:YES];
    [handPin addArcWithCenter:handCenter radius:(strokeWidth/2 + handPinSpacing) startAngle:(handAngle - M_PI_2) endAngle:(handAngle - M_PI_2*3) clockwise:NO];
    [handPin closePath];
    [handPin fill];
    
    UIBezierPath *mountain = [UIBezierPath bezierPath];
    mountain.lineWidth = strokeWidth;
    CGFloat const mountainScale = dimension * 0.21;
    CGPoint mountainStart = CGPointMake(dimension * 0.12 + offset, dimension * 0.56 + offset);
    [mountain moveToPoint:mountainStart];
    [mountain addLineToPoint:CGPointPolarCenter(mountainScale * 0.50, M_PI/3 * 5, mountain.currentPoint)];
    [mountain addLineToPoint:CGPointPolarCenter(mountainScale * 0.17, M_PI/5 * 1, mountain.currentPoint)];
    [mountain addLineToPoint:CGPointPolarCenter(mountainScale * 0.55, M_PI/3 * 5, mountain.currentPoint)];
    // calculate the radius such that the y component is equal to the y component of mountainStart
    CGPoint mountainPeak = mountain.currentPoint;
    double const descentAngle = M_PI/3;
    [mountain addLineToPoint:CGPointPolarCenter((mountainStart.y - mountainPeak.y) / sin(descentAngle), descentAngle, mountainPeak)];
    [mountain closePath];
    [mountain fill];
    
    CGSize const glyphSize = mountain.bounds.size;
    
    /*
    UIBezierPath *location = [UIBezierPath bezierPath];
    location.lineWidth = dimension/51;
    location.lineJoinStyle = kCGLineJoinRound;
    CGFloat const locationLength = dimension * 0.124;
    double const locationTopInsideAngle = 42.0 * (M_PI/180.0); // radians
    CGFloat locationShortLength = locationLength * sin(locationTopInsideAngle) * sin(M_PI_4) / sin((M_PI - locationTopInsideAngle)/2);
    CGPoint const locationTop = CGPointMake(dimension * 0.300 + offset, dimension * 0.140 + offset);
    [location moveToPoint:locationTop];
    [location addLineToPoint:CGPointPolarCenter(locationLength, M_PI_4 * 3 - locationTopInsideAngle/2, locationTop)];
    [location addLineToPoint:CGPointPolarCenter(locationShortLength, M_PI_2 * 3, location.currentPoint)];
    [location addLineToPoint:CGPointPolarCenter(locationShortLength, M_PI_2 * 2, location.currentPoint)];
    // [location addLineToPoint:CGPointPolarCenter(locationLength, M_PI_4 * 7 + locationTopInsideAngle/2, location.currentPoint)];
    [location closePath];
    [location fill];
    */
    
    UIBezierPath *heart = [UIBezierPath bezierPath];
    heart.lineWidth = strokeWidth;
    CGFloat const heartRadius = glyphSize.height/sqrt(8);
    CGPoint const heartTop = CGPointMake(dimension * 0.66 + offset, dimension * 0.24 + offset); // top point
    [heart addArcWithCenter:CGPointPolarCenter(heartRadius, M_PI_4 * 3, heartTop)
                     radius:heartRadius startAngle:(M_PI_4 * 3) endAngle:(M_PI_4 * 7) clockwise:YES];
    [heart addArcWithCenter:CGPointPolarCenter(heartRadius, M_PI_4 * 1, heartTop)
                     radius:heartRadius startAngle:(M_PI_4 * 5) endAngle:(M_PI_4 * 9) clockwise:YES];
    [heart addLineToPoint:CGPointMake(heartTop.x, heartTop.y + heartRadius * sqrt(8))];
    [heart closePath];
    [heart fill];
    
    UIImageSymbolConfiguration *imageConfig = [UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightForFontWeight(strokeWidth)];
    UIImage *locationImage = [UIImage systemImageNamed:@"location.fill" withConfiguration:imageConfig];
    locationImage = [locationImage imageWithTintColor:UIColor.whiteColor];
    [locationImage drawInRect:CGRectMake(dimension * 0.25 + offset, dimension * 0.15 + offset, glyphSize.width, glyphSize.width)];
    
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
