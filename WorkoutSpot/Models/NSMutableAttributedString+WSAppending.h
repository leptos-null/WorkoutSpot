//
//  NSMutableAttributedString+WSAppending.h
//  WorkoutSpot
//
//  Created by Leptos on 6/7/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableAttributedString (WSAppending)

- (void)appendAttributes:(NSDictionary<NSAttributedStringKey, id> *)attribs format:(NSString *)format, ... NS_FORMAT_FUNCTION(2, 3);

@end
