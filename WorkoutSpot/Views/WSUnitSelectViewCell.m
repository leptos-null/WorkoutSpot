//
//  WSUnitSelectViewCell.m
//  WorkoutSpot
//
//  Created by Leptos on 1/18/21.
//  Copyright © 2021 Leptos. All rights reserved.
//

#import "WSUnitSelectViewCell.h"
#import "../Services/WSUnitPreferences.h"

@implementation WSUnitSelectViewCell {
    NSArray<NSUnit *> *_units;
}

+ (NSString *)reusableIdentifier {
    return @"UnitSelectCell";
}

- (void)setType:(WSUnitSelectType)type {
    _type = type;
    
    WSUnitPreferences *unitPreferences = WSUnitPreferences.shared;
    
    NSString *dimensionTitle;
    NSArray<NSUnit *> *units;
    NSUnit *selectedUnit;
    switch (type) {
        case WSUnitSelectTypeDistance:
            dimensionTitle = @"Distance";
            units = @[
                NSUnitLength.kilometers,
                NSUnitLength.miles,
            ];
            selectedUnit = unitPreferences.distanceUnit;
            break;
        case WSUnitSelectTypeAltitude:
            dimensionTitle = @"Altitude";
            units = @[
                NSUnitLength.meters,
                NSUnitLength.feet,
                NSUnitLength.yards,
            ];
            selectedUnit = unitPreferences.altitudeUnit;
            break;
        case WSUnitSelectTypeSpeed:
            dimensionTitle = @"Speed";
            units = @[
                NSUnitSpeed.kilometersPerHour,
                NSUnitSpeed.milesPerHour,
            ];
            selectedUnit = unitPreferences.speedUnit;
            break;
    }
    
    _units = units;
    self.dimensionLabel.text = dimensionTitle;
    
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
    switch (self.type) {
        case WSUnitSelectTypeDistance:
            unitPreferences.distanceUnit = (NSUnitLength *)selectedUnit;
            break;
        case WSUnitSelectTypeAltitude:
            unitPreferences.altitudeUnit = (NSUnitLength *)selectedUnit;
            break;
        case WSUnitSelectTypeSpeed:
            unitPreferences.speedUnit = (NSUnitSpeed *)selectedUnit;
            break;
    }
}

@end
