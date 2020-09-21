//
//  WSGraphConfiguration.h
//  WorkoutSpot
//
//  Created by Leptos on 9/12/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, WSGraphSmoothingTechnique) {
    /// No smoothing
    WSGraphSmoothingTechniqueNone,
    /// Add points with linear smoothstep
    WSGraphSmoothingTechniqueLinear,
    /// Add points with quadratic steps
    WSGraphSmoothingTechniqueQuadratic,
    
    // not a valid case
    WSGraphSmoothingTechniqueCaseCount
};

/// Configure the drawing of a graph
@interface WSGraphConfiguration : NSObject <NSCopying>

/// Complete size of the graph
@property (nonatomic) CGSize size;
/// Insets within @c size to draw
@property (nonatomic) UIEdgeInsets edgeInsets;
/// The portion of the data to graph
@property (nonatomic) NSRange range;
/// A technique to smooth the graph
@property (nonatomic) WSGraphSmoothingTechnique smoothingTechnique;

@end
