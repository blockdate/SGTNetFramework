//
//  SGTNetworking+RACSupport.m
//  SGTFoundation
//
//  Created by 磊吴 on 16/5/12.
//  Copyright © 2016年 block. All rights reserved.
//

#import "SGTNetworking+RACSupport.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "AFNetworking.h"
#import "SGTNetManager.h"

@implementation SGTNetManager (RACSupport)

+ (RACSignal *)rac_GET:(NSString *)path parameters:(id)parameters {
    return [[self rac_requestPath:path parameters:parameters method:@"GET"]
            setNameWithFormat:@"%@ -rac_GET: %@, parameters: %@", self.class, path, parameters];
}

+ (RACSignal *)rac_HEAD:(NSString *)path parameters:(id)parameters {
    return [[self rac_requestPath:path parameters:parameters method:@"HEAD"]
            setNameWithFormat:@"%@ -rac_HEAD: %@, parameters: %@", self.class, path, parameters];
}

+ (RACSignal *)rac_POST:(NSString *)path parameters:(id)parameters {
    return [[self rac_requestPath:path parameters:parameters method:@"POST"]
            setNameWithFormat:@"%@ -rac_POST: %@, parameters: %@", self.class, path, parameters];
}

+ (RACSignal *)rac_POST:(NSString *)path parameters:(id)parameters constructingBodyWithBlock:(void (^)(id<AFMultipartFormData>))block {
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        AFHTTPSessionManager *manager = [SGTNetManager sessionManager];
        NSString *url = path;
        if ([SGTNetManager shouldEncode]) {
            url = [SGTNetManager encodeUrl:path];
        }
        NSMutableURLRequest *request = [manager.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:[[NSURL URLWithString:path relativeToURL:[NSURL URLWithString:SGTNetManager.baseUrl]] absoluteString] parameters:parameters constructingBodyWithBlock:block error:nil];
        NSURLSessionDataTask *task = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
            if (error) {
                NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
                if (responseObject) {
                    userInfo[@"responseObject"] = responseObject;
                }
                NSError *errorWithRes = [NSError errorWithDomain:error.domain code:error.code userInfo:[userInfo copy]];
                [subscriber sendError:errorWithRes];
            } else {
                [subscriber sendNext:RACTuplePack(responseObject, response)];
                [subscriber sendCompleted];
            }
        }];
        [task resume];
        
        return [RACDisposable disposableWithBlock:^{
            [task cancel];
        }];
    }] setNameWithFormat:@"%@ -rac_POST: %@, parameters: %@, constructingBodyWithBlock:", self.class, path, parameters];
}

+ (RACSignal *)rac_PUT:(NSString *)path parameters:(id)parameters {
    return [[self rac_requestPath:path parameters:parameters method:@"PUT"]
            setNameWithFormat:@"%@ -rac_PUT: %@, parameters: %@", self.class, path, parameters];
}

+ (RACSignal *)rac_PATCH:(NSString *)path parameters:(id)parameters {
    return [[self rac_requestPath:path parameters:parameters method:@"PATCH"]
            setNameWithFormat:@"%@ -rac_PATCH: %@, parameters: %@", self.class, path, parameters];
}

+ (RACSignal *)rac_DELETE:(NSString *)path parameters:(id)parameters {
    return [[self rac_requestPath:path parameters:parameters method:@"DELETE"]
            setNameWithFormat:@"%@ -rac_DELETE: %@, parameters: %@", self.class, path, parameters];
}

+ (RACSignal *)rac_requestPath:(NSString *)path parameters:(id)parameters method:(NSString *)method {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        AFHTTPSessionManager *manager = [SGTNetManager sessionManager];
        NSString *url = path;
        if ([SGTNetManager shouldEncode]) {
            url = [SGTNetManager encodeUrl:path];
        }
        NSURLRequest *request = [manager.requestSerializer requestWithMethod:method URLString:[[NSURL URLWithString:path relativeToURL:[NSURL URLWithString:SGTNetManager.baseUrl]] absoluteString] parameters:parameters error:nil];
        NSURLSessionDataTask *task = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
            if (error) {
                NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
                if (responseObject) {
                    userInfo[@"responseObject"] = responseObject;
                }
                NSError *errorWithRes = [NSError errorWithDomain:error.domain code:error.code userInfo:[userInfo copy]];
                if ([SGTNetManager isDebug]) {
                    [SGTNetManager logWithSuccessResponse:responseObject url:url params:parameters];
                }
                [subscriber sendError:errorWithRes];
            } else {
                if ([SGTNetManager isDebug]) {
                    [SGTNetManager logWithFailError:error url:url params:parameters];
                }
                [subscriber sendNext:RACTuplePack(responseObject, response)];
                [subscriber sendCompleted];
            }
        }];
        [task resume];
        return [RACDisposable disposableWithBlock:^{
            [task cancel];
        }];
    }];
}

@end
