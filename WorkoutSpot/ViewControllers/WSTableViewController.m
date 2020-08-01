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
#import "../Models/WSPoseWorkout.h"
#import "../Models/NSArray+WSMapping.h"

@implementation WSTableViewController {
    HKAnchoredObjectQuery *_workoutQuery;
    UITableViewDiffableDataSource<NSString *, WSHashWorkout *> *_dataSource;
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
            NSLog(@"HKHealthStoreRequestAuthorizationCompleted: %@", error);
            return;
        }
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self beginHealthQuery];
            });
        }
    }];
    
    _dataSource = [[UITableViewDiffableDataSource alloc] initWithTableView:self.tableView
                            cellProvider:^UITableViewCell *(UITableView *tableView, NSIndexPath *indexPath, WSHashWorkout *hashWorkout) {
        WSWorkoutViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[WSWorkoutViewCell reusableIdentifier] forIndexPath:indexPath];
        cell.workout = hashWorkout.workout;
        return cell;
    }];
    _dataSource.defaultRowAnimation = UITableViewRowAnimationTop;
}

- (IBAction)beginHealthQuery {
    dispatch_assert_queue(dispatch_get_main_queue());
    
    [self.refreshControl beginRefreshing];
    
    HKHealthStore *healthStore = self.healthStore;
    
    [healthStore stopQuery:_workoutQuery];
    
    HKQuantity *zeroDistance = [HKQuantity quantityWithUnit:[HKUnit meterUnit] doubleValue:0];
    NSPredicate *predicate = [HKQuery predicateForWorkoutsWithOperatorType:NSGreaterThanPredicateOperatorType totalDistance:zeroDistance];
    
    HKWorkoutType *sampleType = [HKWorkoutType workoutType];
    __weak __typeof(self) weakself = self;
    
    NSDiffableDataSourceSnapshot<NSString *, WSHashWorkout *> *snapshot = [NSDiffableDataSourceSnapshot new];
    void(^updateHandler)(HKAnchoredObjectQuery *, NSArray<__kindof HKSample *> *, NSArray<HKDeletedObject *> *, HKQueryAnchor *, NSError *) =
    ^(HKAnchoredObjectQuery *query, NSArray<HKWorkout *> *workouts, NSArray<HKDeletedObject *> *deletedObjects, HKQueryAnchor *newAnchor, NSError *error) {
        if (error) {
            NSLog(@"HKAnchoredObjectQueryHandler: %@", error);
            return;
        }
        
        NSString *const sectionHeader = @"Workouts";
        if (weakself) {
            __strong __typeof(self) strongself = weakself;
            UITableViewDiffableDataSource<NSString *, WSHashWorkout *> *dataSource = strongself->_dataSource;
            
            if (![snapshot.sectionIdentifiers containsObject:sectionHeader]) {
                [snapshot appendSectionsWithIdentifiers:@[ sectionHeader ]];
            }
            
            // workouts seems to be in chronological order added to HealthKit
            NSUInteger const workoutCount = workouts.count;
            NSMutableArray<WSHashWorkout *> *addIdents = [NSMutableArray arrayWithCapacity:workoutCount];
            [workouts enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(HKWorkout *workout, NSUInteger idx, BOOL *stop) {
                addIdents[workoutCount - idx - 1] = [[WSHashWorkout alloc] initWithWorkout:workout];
            }];
            
            NSArray<WSHashWorkout *> *startWorkouts = [snapshot itemIdentifiersInSectionWithIdentifier:sectionHeader];
            
            WSHashWorkout *firstIdentifier = startWorkouts.firstObject;
            if (firstIdentifier != nil) {
                [snapshot insertItemsWithIdentifiers:addIdents beforeItemWithIdentifier:firstIdentifier];
            } else {
                [snapshot appendItemsWithIdentifiers:addIdents intoSectionWithIdentifier:sectionHeader];
            }
            
            [snapshot deleteItemsWithIdentifiers:[deletedObjects map:^WSHashWorkout *(HKDeletedObject *obj) {
                return [[WSPoseWorkout alloc] initWithWorkoutUUID:obj.UUID];
            }]];
            
            [dataSource applySnapshot:snapshot animatingDifferences:YES completion:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakself.refreshControl endRefreshing];
                });
            }];
        }
    };
    
    HKAnchoredObjectQuery *workoutQuery = [[HKAnchoredObjectQuery alloc] initWithType:sampleType predicate:predicate anchor:HKAnchoredObjectQueryNoAnchor
                                                                                limit:HKObjectQueryNoLimit resultsHandler:updateHandler];
    workoutQuery.updateHandler = updateHandler;
    
    _workoutQuery = workoutQuery;
    [healthStore executeQuery:workoutQuery];
}

- (WSViewController *)_controllerForIndexPath:(NSIndexPath *)indexPath {
    WSHashWorkout *hashWorkout = [_dataSource itemIdentifierForIndexPath:indexPath];
    WSViewController *controller = [WSViewController fromStoryboard];
    controller.workoutAnalysis = [[WSWorkoutAnalysis alloc] initWithWorkout:hashWorkout.workout store:self.healthStore];
    return controller;
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
