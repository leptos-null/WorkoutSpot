//
//  WSUnitSelectViewCell.m
//  WorkoutSpot
//
//  Created by Leptos on 1/18/21.
//  Copyright © 2021 Leptos. All rights reserved.
//

#import "WSUnitSelectViewCell.h"

@implementation WSUnitSelectViewCell {
    NSArray<NSUnit *> *_units;
}

+ (NSString *)reusableIdentifier {
    return @"UnitSelectCell";
}

- (void)setType:(WSMeasurementType)type {
    _type = type;
    
    NSString *dimensionTitle;
    NSArray<NSUnit *> *units;
    switch (type) {
        case WSMeasurementTypeDistance:
            dimensionTitle = @"Distance";
            units = @[
                NSUnitLength.kilometers,
                NSUnitLength.miles,
            ];
            break;
        case WSMeasurementTypeAltitude:
            dimensionTitle = @"Altitude";
            units = @[
                NSUnitLength.meters,
                NSUnitLength.feet,
                NSUnitLength.yards,
            ];
            break;
        case WSMeasurementTypeSpeed:
            dimensionTitle = @"Speed";
            units = @[
                NSUnitSpeed.kilometersPerHour,
                NSUnitSpeed.milesPerHour,
            ];
            break;
        default:
            dimensionTitle = nil;
            units = nil;
            break;
    }
    
    _units = units;
    self.dimensionLabel.text = dimensionTitle;
    
    WSUnitPreferences *unitPreferences = WSUnitPreferences.shared;
    NSUnit *selectedUnit = [unitPreferences unitForType:type];
    
    UISegmentedControl *segmentControl = self.unitSegment;
    
    [segmentControl removeAllSegments];
    [units enumerateObjectsUsingBlock:^(NSUnit *unit, NSUInteger idx, BOOL *stop) {
        [segmentControl insertSegmentWithTitle:[WSFormatterUtils abbreviatedUnit:unit] atIndex:idx animated:NO];
        if ([unit isEqual:selectedUnit]) {
            [segmentControl setSelectedSegmentIndex:idx];
        }
    }];
}

- (IBAction)unitSegmentDidChange:(UISegmentedControl *)segmentControl {
    WSUnitPreferences *unitPreferences = WSUnitPreferences.shared;
    NSUnit *selectedUnit = _units[segmentControl.selectedSegmentIndex];
    [unitPreferences setUnit:selectedUnit forType:self.type];
}

@end
