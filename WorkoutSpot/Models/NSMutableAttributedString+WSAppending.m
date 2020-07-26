//
//  NSMutableAttributedString+WSAppending.m
//  WorkoutSpot
//
//  Created by Leptos on 6/7/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "NSMutableAttributedString+WSAppending.h"

@implementation NSMutableAttributedString (WSAppending)

- (void)appendAttributes:(NSDictionary<NSAttributedStringKey, id> *)attribs format:(NSString *)format, ... {
    va_list arg_list;
    va_start(arg_list, format);
    NSString *string = [[NSString alloc] initWithFormat:format arguments:arg_list];
    va_end(arg_list);
    
    NSAttributedString *attribed = [[NSAttributedString alloc] initWithString:string attributes:attribs];
    [self appendAttributedString:attribed];
}

@end
