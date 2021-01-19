//
//  WSPrefsViewController.m
//  WorkoutSpot
//
//  Created by Leptos on 1/18/21.
//  Copyright © 2021 Leptos. All rights reserved.
//

#import "WSPrefsViewController.h"
#import "../Views/WSUnitSelectViewCell.h"

@implementation WSPrefsViewController

// MARK: - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSParameterAssert(tableView == self.tableView);
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSParameterAssert(tableView == self.tableView);
    NSParameterAssert(section == 0);
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSParameterAssert(tableView == self.tableView);
    NSParameterAssert(section == 0);
    return @"Units";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(tableView == self.tableView);
    NSParameterAssert(indexPath.section == 0);
    
    WSUnitSelectViewCell *cell = [tableView dequeueReusableCellWithIdentifier:WSUnitSelectViewCell.reusableIdentifier forIndexPath:indexPath];
    cell.type = indexPath.row;
    return cell;
}

@end
