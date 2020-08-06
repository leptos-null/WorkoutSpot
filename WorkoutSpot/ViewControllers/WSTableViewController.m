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
    HKAnchoredObjectQuery *_workoutQuery;
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
                            cellProvider:^UITableViewCell *(UITableView *tableView, NSIndexPath *indexPath, HKWorkout *workout) {
        WSWorkoutViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[WSWorkoutViewCell reusableIdentifier] forIndexPath:indexPath];
        cell.workout = workout;
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
    
    NSString *const sectionHeader = @"Workouts";
    NSDiffableDataSourceSnapshot<NSString *, HKWorkout *> *snapshot = [NSDiffableDataSourceSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[ sectionHeader ]];
    
    NSMutableDictionary<NSUUID *, HKWorkout *> *const workoutLookup = [NSMutableDictionary dictionary];
    
    void(^updateHandler)(HKAnchoredObjectQuery *, NSArray<__kindof HKSample *> *, NSArray<HKDeletedObject *> *, HKQueryAnchor *, NSError *) =
    ^(HKAnchoredObjectQuery *query, NSArray<HKWorkout *> *workouts, NSArray<HKDeletedObject *> *deletedObjects, HKQueryAnchor *newAnchor, NSError *error) {
        if (error) {
            NSLog(@"HKAnchoredObjectQueryHandler: %@", error);
            return;
        }
        
        if (weakself) {
            __strong __typeof(self) strongself = weakself;
            
            NSUInteger const workoutCount = workouts.count;
            NSMutableArray<HKWorkout *> *addingWorkouts = [NSMutableArray arrayWithCapacity:workoutCount];
            // workouts seems to be in chronological order added to HealthKit
            // read in reverse to get array as close as to the intended order as possible
            [workouts enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(HKWorkout *workout, NSUInteger idx, BOOL *stop) {
                addingWorkouts[workoutCount - idx - 1] = workout;
                workoutLookup[workout.UUID] = workout;
            }];
            [addingWorkouts sortUsingDescriptors:@[
                [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:NO]
            ]];
            
            NSArray<HKWorkout *> *existingWorkouts = [snapshot itemIdentifiersInSectionWithIdentifier:sectionHeader];
            
            HKWorkout *lastAdding = addingWorkouts.lastObject;
            HKWorkout *firstExisting = existingWorkouts.firstObject;
            /* intended order:
             *   ... // most recent (newer)
             *   addingWorkouts[n-2]
             *   addingWorkouts[n-1] // lastInsert
             *   existingWorkouts[0] // firstExisting
             *   existingWorkouts[1]
             *   ... // least recent (older)
             */
            
            if (lastAdding != nil) { // do we have anything to add anyway?
                if (firstExisting != nil) {
                    if ([lastAdding.startDate compare:firstExisting.startDate] == NSOrderedAscending) {
                        // this should be the least warm branch.
                        // re-sort the entire workout list if appending the sorted additions
                        //   doesn't result in a list with the intended order
                        [snapshot deleteItemsWithIdentifiers:existingWorkouts];
                        
                        [addingWorkouts addObjectsFromArray:existingWorkouts];
                        [addingWorkouts sortUsingDescriptors:@[
                            [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:NO]
                        ]];
                        
                        [snapshot appendItemsWithIdentifiers:addingWorkouts intoSectionWithIdentifier:sectionHeader];
                    } else {
                        // theoretically, this is the warmest branch of the three,
                        //   however in reality it's probably second
                        [snapshot insertItemsWithIdentifiers:addingWorkouts beforeItemWithIdentifier:firstExisting];
                    }
                } else {
                    // this should only be executed one time for each invocation of this method.
                    //   it's more likely that the app is launched, or the user pulls to reload,
                    //   than a workout is added while the app is running.
                    // most likely, this is the warmest branch of the three
                    [snapshot appendItemsWithIdentifiers:addingWorkouts intoSectionWithIdentifier:sectionHeader];
                }
            }
            
            NSMutableArray<HKWorkout *> *deletedWorkouts = [NSMutableArray arrayWithCapacity:deletedObjects.count];
            [deletedObjects enumerateObjectsUsingBlock:^(HKDeletedObject *deletedObj, NSUInteger idx, BOOL *stop) {
                NSUUID *uuid = deletedObj.UUID;
                HKWorkout *lookedUp = workoutLookup[uuid];
                // objects deleted while the app isn't alive are sent here (on launch)
                // when we do launch, the objects that were deleted don't exist anymore,
                //   so they're not sent to us (subsequently, not added to the lookup)
                if (lookedUp != nil) {
                    deletedWorkouts[idx] = lookedUp;
                    [workoutLookup removeObjectForKey:uuid];
                }
            }];
            [snapshot deleteItemsWithIdentifiers:deletedWorkouts];
            
            [strongself->_dataSource applySnapshot:snapshot animatingDifferences:YES completion:^{
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
    HKWorkout *workout = [_dataSource itemIdentifierForIndexPath:indexPath];
    WSViewController *controller = [WSViewController fromStoryboard];
    controller.workoutAnalysis = [[WSWorkoutAnalysis alloc] initWithWorkout:workout store:self.healthStore];
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
