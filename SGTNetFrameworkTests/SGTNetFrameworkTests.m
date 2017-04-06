//
//  SGTNetFrameworkTests.m
//  SGTNetFrameworkTests
//
//  Created by 吴磊 on 2017/4/6.
//  Copyright © 2017年 磊吴. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SGTNetworking+RACSupport.h"
#import "SGTNetManager.h"

@interface SGTNetFrameworkTests : XCTestCase

@end

@implementation SGTNetFrameworkTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCacheRequest {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    XCTestExpectation *ex = [self expectationWithDescription:@"net request"];
    [SGTNetManager getWithUrl:@"http://spi.itjuzi.com:8086/company" params:nil useCache:YES refreshCache:NO success:^(id  _Nonnull response) {
        NSLog(@"cache success, response:%@", response);
        NSTimeInterval time = [SGTNetManager cacheTimeIntervalForURL:@"http://spi.itjuzi.com:8086/company" params:nil];
        NSLog(@"time interval is %lf", time);
        [ex fulfill];
    } fail:^(NSError * _Nonnull error) {
        NSLog(@"request failed, error %@", error);
        [ex fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:20 handler:^(NSError * _Nullable error) {
        NSLog(@"out of expectation");
    }];
}

- (void)testCacheTimeInterval {
    // This is an example of a performance test case.
    NSTimeInterval time = [SGTNetManager cacheTimeIntervalForURL:@"http://spi.itjuzi.com:8086/company" params:nil];
    BOOL out1Min = [SGTNetManager isCacheOutOfTimeForURL:@"" params:nil limitTime:60];
    BOOL out2Min = [SGTNetManager isCacheOutOfTimeForURL:@"" params:nil limitTime:60*2];
    BOOL out5Min = [SGTNetManager isCacheOutOfTimeForURL:@"" params:nil limitTime:60*5];
    BOOL out1H = [SGTNetManager isCacheOutOfTimeForURL:@"" params:nil limitTime:60*60];
    BOOL out2H = [SGTNetManager isCacheOutOfTimeForURL:@"" params:nil limitTime:60*60*2];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    NSLog(@"cache time:%@",date);
    NSLog(@"cache out 1min:%d",out1Min);
    NSLog(@"cache out 2min:%d",out2Min);
    NSLog(@"cache out 5min:%d",out5Min);
    NSLog(@"cache out 1H:%d",out1H);
    NSLog(@"cache out 2H:%d",out2H);
    //NSLog(@"time interval is %lf", time);
}

@end
