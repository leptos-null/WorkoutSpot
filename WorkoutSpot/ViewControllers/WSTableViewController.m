//
//  WSTableViewController.m
//  WorkoutSpot
//
//  Created by Leptos on 6/2/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import "WSTableViewController.h"
#import "WSViewController.h"
#import "../Views/WSWorkoutViewCell.h"

@implementation WSTableViewController {
    UITableViewDiffableDataSource<NSString *, HKWorkout *> *_dataSource;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.healthStore = [HKHealthStore new];
    // TODO: WorkoutType accessors
    NSArray<HKObjectType *> *types = @[
        [HKWorkoutType workoutType],
        [HKSeriesType workoutRouteType],
        [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate],
    ];
    [self.healthStore requestAuthorizationToShareTypes:nil readTypes:[NSSet setWithArray:types] completion:^(BOOL success, NSError *error) {
        if (error) {
            NSLog(@"%@", error);
            return;
        }
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self beginHealthQuery];
            });
        }
    }];
    
    _dataSource = [[UITableViewDiffableDataSource alloc] initWithTableView:self.tableView
                            cellProvider:^UITableViewCell *(UITableView *tableView, NSIndexPath *indexPath, HKWorkout *workout) {
        WSWorkoutViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[WSWorkoutViewCell reusableIdentifier] forIndexPath:indexPath];
        cell.workout = workout;
        return cell;
    }];
    
    self.tableView.dataSource = _dataSource;
}

- (IBAction)beginHealthQuery {
    [self.refreshControl beginRefreshing];
    
    HKQuantity *zeroDistance = [HKQuantity quantityWithUnit:[HKUnit meterUnit] doubleValue:0];
    NSPredicate *predicate = [HKQuery predicateForWorkoutsWithOperatorType:NSGreaterThanPredicateOperatorType totalDistance:zeroDistance];
    
    HKWorkoutType *sample = [HKWorkoutType workoutType];
    __weak __typeof(self) weakself = self;
    HKSampleQuery *workoutQuery = [[HKSampleQuery alloc] initWithSampleType:sample predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:@[
        [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:NO]
    ] resultsHandler:^(HKSampleQuery *query, NSArray<__kindof HKSample *> *results, NSError *error) {
        if (error) {
            NSLog(@"%@", error);
            return;
        }
        [weakself setWorkouts:results];
    }];
    [self.healthStore executeQuery:workoutQuery];
}

- (WSViewController *)_controllerForIndexPath:(NSIndexPath *)indexPath {
    HKWorkout *workout = [_dataSource itemIdentifierForIndexPath:indexPath];
    WSViewController *controller = [WSViewController fromStoryboard];
    controller.workoutAnalysis = [[WSWorkoutAnalysis alloc] initWithWorkout:workout store:self.healthStore];
    return controller;
}

- (void)setWorkouts:(NSArray<HKWorkout *> *)workouts {
    NSDiffableDataSourceSnapshot<NSString *, HKWorkout *> *snapshot = [NSDiffableDataSourceSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[ @"Workouts" ] ];
    [snapshot appendItemsWithIdentifiers:workouts];
    
    [_dataSource applySnapshot:snapshot animatingDifferences:YES completion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.refreshControl endRefreshing];
        });
    }];
}

// MARK: - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WSViewController *controller = [self _controllerForIndexPath:indexPath];
    [self.navigationController pushViewController:controller animated:YES];
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point {
    __weak __typeof(self) weakself = self;
    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:^UIViewController *{
        return [weakself _controllerForIndexPath:indexPath];
    } actionProvider:NULL];
}

- (void)tableView:(UITableView *)tableView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator {
    switch (animator.preferredCommitStyle) {
        case UIContextMenuInteractionCommitStyleDismiss:
            break;
        case UIContextMenuInteractionCommitStylePop: {
            UIViewController *previewViewController = animator.previewViewController;
            __weak __typeof(self) weakself = self;
            [animator addAnimations:^{
                [weakself.navigationController pushViewController:previewViewController animated:YES];
            }];
        } break;
        default:
            break;
    }
}

// MARK: - Description

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; healthStore = %@; dataSource = %@>", [self class], self, self.healthStore, _dataSource];
}

@end
