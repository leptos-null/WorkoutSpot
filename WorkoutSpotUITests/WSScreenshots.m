//
//  WSScreenshots.m
//  WSScreenshots
//
//  Created by Leptos on 8/3/20.
//  Copyright © 2020 Leptos. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface WSScreenshots : XCTestCase

@end

@implementation WSScreenshots {
    NSString *_pathHead;
    NSMutableArray<NSString *> *_screenshotPaths;
}

- (void)setUp {
    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    
    NSFileManager *fileManager = NSFileManager.defaultManager;
    
    NSString *compilePath = @__FILE__;
    NSString *root = compilePath.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent;
    NSCAssert([fileManager fileExistsAtPath:root], @"Cannot find project path");
    
    const char *model = getenv("SIMULATOR_MODEL_IDENTIFIER");
    NSCAssert(model != NULL, @"Screenshot collection should be run in the simulator");
    NSString *pathHead = [[root stringByAppendingPathComponent:@"Screenshots"] stringByAppendingPathComponent:@(model)];
    
    BOOL isDir = NO;
    if ([fileManager fileExistsAtPath:pathHead isDirectory:&isDir]) {
        NSCAssert(isDir, @"File exists at %@", pathHead);
    } else {
        [fileManager createDirectoryAtPath:pathHead withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    _pathHead = pathHead;
    _screenshotPaths = [NSMutableArray arrayWithCapacity:7];
}

- (void)tearDown {
    NSMutableString *readme = [NSMutableString string];
    [readme appendFormat:@"## %s %s\n\n", getenv("SIMULATOR_DEVICE_NAME"), getenv("SIMULATOR_RUNTIME_VERSION")];
    
    for (NSString *screenshotPath in _screenshotPaths) {
        [readme appendFormat:@"![%@](%@)\n\n", screenshotPath.stringByDeletingPathExtension, screenshotPath];
    }
    
    NSString *path = [_pathHead stringByAppendingPathComponent:@"README.md"];
    [readme writeToFile:path atomically:YES encoding:NSASCIIStringEncoding error:NULL];
}

- (BOOL)_writeScreenshot:(XCUIScreenshot *)screenshot name:(NSString *)name {
    NSString *path = [name stringByAppendingPathExtension:@"png"];
    [_screenshotPaths addObject:path];
    return [screenshot.PNGRepresentation writeToFile:[_pathHead stringByAppendingPathComponent:path] atomically:YES];
}

- (void)testGetScreenshots {
    XCUIApplication *app = [XCUIApplication new];
    [app launch];
    
    [self _writeScreenshot:app.screenshot name:@"0_home"];
    
    [app.navigationBars[@"Workouts"].buttons[@"Preferences"] tap];
    // tap on something, otherwise this screen goes away really fast
    [app.tables.cells.staticTexts[@"Distance"] tap];
    [self _writeScreenshot:app.screenshot name:@"1_preferences"];
    
    [app.navigationBars[@"Preferences"].buttons[@"Workouts"] tap]; // back to main screen
    
    [app.tables.cells.staticTexts[@"10 minutes, 23 seconds"] pressForDuration:2];
    [self _writeScreenshot:app.screenshot name:@"2_preview"];
    
    [app.otherElements[@"Preview"] tap];
    
    XCUIElement *graphScrollView = app.scrollViews[@"Graph"];
    [graphScrollView pinchWithScale:2 velocity:2];
    [self _writeScreenshot:app.screenshot name:@"3_time_segment"];
    
    [graphScrollView swipeLeft]; // effectively pick a random spot
    [self _writeScreenshot:app.screenshot name:@"4_time_point"];
    
    [app.segmentedControls.buttons[@"Distance"] tap];
    [graphScrollView swipeRight]; // effectively pick another spot
    [self _writeScreenshot:app.screenshot name:@"5_distance_point"];
    
    [graphScrollView tap]; // hide point stats view
    [self _writeScreenshot:app.screenshot name:@"6_distance_segment"];
}

@end
