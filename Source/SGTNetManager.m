//
//  SGTNetworking.m
//  YiDang-OC
//
//  Created by 磊吴 on 15/10/26.
//  Copyright © 2015年 block. All rights reserved.
//

#import "SGTNetManager.h"
#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import "NSFileManager+pathMethod.h"
#import <CommonCrypto/CommonDigest.h>
#import "NSFileManager+pathMethod.h"

#ifdef DEBUG
#define DebugLog(s, ... ) NSLog( @"[%@：in line: %d]-->[message: %@]", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define DebugLog(s, ... )
#endif

static NSString *kPrivateNetworkBaseUrl = nil;
static BOOL kIsEnableInterfaceDebug = NO;
static BOOL kShouldAutoEncode = YES;
static SGTNetRequestType kHeaderSerializer = SGTNetRequestTypeJSON;
static SGTNetRequestType kResponseSerializer = SGTNetRequestTypeJSON;
static NSDictionary *kHttpHeaders = nil;
static BOOL kShouldLoadCacheWhenNetUNAvaliable = false;
static SGTNetworkStatus kNetworkStatus = SGTNetworkStatusUnknown;
static NSMutableArray<SGTRequestOperation *> *allRequestTasks;
static NSUInteger kMaxCacheSize = 0;

@interface SGTNetManager()

@end

@implementation SGTNetManager

#pragma mark - Class Net Methord

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 尝试清除缓存
        if (kMaxCacheSize > 0 && [self totalCacheSize] > 1024 * 1024 * kMaxCacheSize) {
            [self clearCaches];
        }
    });
}

static AFNetworkReachabilityStatus _netStatue = AFNetworkReachabilityStatusUnknown;
+ (BOOL)isNetAvaliable {
    if (_netStatue == AFNetworkReachabilityStatusReachableViaWiFi || _netStatue == AFNetworkReachabilityStatusReachableViaWWAN) {
        return YES;
    }
    return false;
}

+ (void)updateBaseUrl:(NSString *)baseUrl {
    kPrivateNetworkBaseUrl = baseUrl;
}

+ (NSString *)baseUrl {
    return kPrivateNetworkBaseUrl;
}

+ (void)updateHeaderSerializer:(SGTNetRequestType)type {
    kHeaderSerializer = type;
    if (manager != nil) {
        if (type == SGTNetRequestTypeJSON) {
            AFHTTPRequestSerializer *responseSerializer = [AFJSONRequestSerializer serializer];
            manager.requestSerializer = responseSerializer;
        }else {
            AFHTTPRequestSerializer *responseSerializer = [AFHTTPRequestSerializer serializer];
            manager.requestSerializer = responseSerializer;
        }
    }
}

+ (void)updateResponseSerializer:(SGTNetRequestType)type {
    kResponseSerializer = type;
    if (manager != nil) {
        if (type == SGTNetRequestTypeJSON) {
            AFHTTPResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializer];
            manager.responseSerializer = responseSerializer;
        }else {
            AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
            manager.responseSerializer = responseSerializer;
        }
    }
}

+ (void)enableInterfaceDebug:(BOOL)isDebug {
    kIsEnableInterfaceDebug = isDebug;
}

+ (BOOL)isDebug {
    return kIsEnableInterfaceDebug;
}

+ (void)shouldAutoEncodeUrl:(BOOL)shouldAutoEncode {
    kShouldAutoEncode = shouldAutoEncode;
}

+ (BOOL)shouldEncode {
    return kShouldAutoEncode;
}

+ (void)configCommonHttpHeaders:(NSDictionary *)httpHeaders {
    kHttpHeaders = httpHeaders;
}

+ (void)obtainDataFromLocalWhenNetworkUnconnected:(BOOL)shouldLoadCache {
    kShouldLoadCacheWhenNetUNAvaliable = shouldLoadCache;
    if (kShouldLoadCacheWhenNetUNAvaliable) {
        [self detectNetwork];
    }
}

#pragma mark - Function Method
//检查网络状态，当kShouldLoadCacheWhenNetUNAvaliable为true时开始检索
+ (void)detectNetwork {
    AFNetworkReachabilityManager *reachabilityManager = [AFNetworkReachabilityManager sharedManager];
    
    [reachabilityManager startMonitoring];
    [reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status == AFNetworkReachabilityStatusNotReachable){
            kNetworkStatus = SGTNetworkStatusNotReachable;
        } else if (status == AFNetworkReachabilityStatusUnknown){
            kNetworkStatus = SGTNetworkStatusUnknown;
        } else if (status == AFNetworkReachabilityStatusReachableViaWWAN){
            kNetworkStatus = SGTNetworkStatusReachableViaWWAN;
        } else if (status == AFNetworkReachabilityStatusReachableViaWiFi){
            kNetworkStatus = SGTNetworkStatusReachableViaWiFi;
        }
    }];
}

+ (void)cancelAllRequest {
    @synchronized(self) {
        [[self allTasks] enumerateObjectsUsingBlock:^(NSURLSessionTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task isKindOfClass:[NSURLSessionTask class]]) {
                [task cancel];
            }
        }];
        
        [[self allTasks] removeAllObjects];
    };
}

+ (void)cancelRequestWithURL:(NSString *)url {
    if (url == nil) {
        return;
    }
    NSString *requestURL = [self _requestURLFromUrl:url];
    @synchronized(self) {
        [[self allTasks] enumerateObjectsUsingBlock:^(NSURLSessionTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task isKindOfClass:[NSURLSessionTask class]]
                && [task.currentRequest.URL.absoluteString isEqualToString:requestURL]) {
                [task cancel];
                [[self allTasks] removeObject:task];
                return;
            }
        }];
    };
}

#pragma mark - Base Http Request

+ (SGTRequestOperation *)_requestURL:(NSString *)url
                              params:(id)params useCache:(BOOL)useCache
                             headers:(NSDictionary *)headers
                        refreshCache:(BOOL)refreshCache
                          httpMethod:(SGTNetRequestMethod) httpMethod
                            progress:(void (^)(NSProgress * _Nonnull))progress
                             success:(SGTResponseSuccess)success
                                fail:(SGTResponseFail)fail {
    SGTRequestOperation *operation = nil;
    AFHTTPSessionManager *manager = [self sessionManager];
    if ([self shouldEncode]) {
        url = [self encodeUrl:url];
    }
    NSString *requestURL = [self _requestURLFromUrl:url];
    if (useCache) {
        //        无网络时，读取缓存，直接返回
        if (kShouldLoadCacheWhenNetUNAvaliable) {
            if (kNetworkStatus == SGTNetworkStatusNotReachable) {
                id response = [SGTNetManager cahceResponseWithURL:requestURL
                                                       parameters:params];
                if (response) {
                    if (success) {
                        [self handleSuccessResponse:response callback:success];
                        
                        if ([self isDebug]) {
                            [self logWithSuccessResponse:response
                                                     url:requestURL
                                                  params:params];
                        }
                    }
                    return nil;
                }
            }
        }
        //        使用缓存，直接返回
        if (!refreshCache) {
            id response = [SGTNetManager cahceResponseWithURL:requestURL
                                                   parameters:params];
            if (response) {
                if (success) {
                    [self handleSuccessResponse:response callback:success];
                    
                    if ([self isDebug]) {
                        [self logWithSuccessResponse:response
                                                 url:requestURL
                                              params:params];
                    }
                }
                return nil;
            }
        }
    }
    void (^successHandle)(NSURLSessionDataTask * _Nonnull, id _Nullable) = ^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self handleSuccessResponse:responseObject callback:success];
        
        if (useCache) {
            [self cacheResponseObject:responseObject request:task.currentRequest parameters:params];
        }
        
        [[self allTasks] removeObject:task];
        
        if ([self isDebug]) {
            [self logWithSuccessResponse:responseObject
                                     url:requestURL
                                  params:params];
        }
    };
    void (^failureHandle)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull) = ^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[self allTasks] removeObject:task];
        
        if ([error code] < 0 && useCache && !refreshCache) {// 获取缓存
            id response = [SGTNetManager cahceResponseWithURL:requestURL
                                                   parameters:params];
            if (response) {
                if (success) {
                    [self handleSuccessResponse:response callback:success];
                    
                    if ([self isDebug]) {
                        [self logWithSuccessResponse:response
                                                 url:requestURL
                                              params:params];
                    }
                }
            } else {
                [self handleCallbackWithError:error fail:fail];
                
                if ([self isDebug]) {
                    [self logWithFailError:error url:requestURL params:params];
                }
            }
        } else {
            [self handleCallbackWithError:error fail:fail];
            
            if ([self isDebug]) {
                [self logWithFailError:error url:requestURL params:params];
            }
        }
    };
    if (httpMethod == SGTNetRequestMethodGET) {
        operation = [manager GET:url parameters:params progress:progress success:successHandle failure:failureHandle];
    }else if(httpMethod == SGTNetRequestMethodPOST){
        operation = [manager POST:url parameters:params progress:progress success:successHandle failure:failureHandle];
    }
    if (nil != operation) {
        [[self allTasks] addObject:operation];
    }
    return operation;
}

+ (id)tryToParseData:(id)responseData {
    if ([responseData isKindOfClass:[NSData class]]) {
        // 尝试解析成JSON
        if (responseData == nil) {
            return responseData;
        } else {
            NSError *error = nil;
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData
                                                                     options:NSJSONReadingMutableContainers
                                                                       error:&error];
            
            if (error != nil) {
                return responseData;
            } else {
                return response;
            }
        }
    } else {
        return responseData;
    }
}

+ (void)handleSuccessResponse:(id)responseData callback:(SGTResponseSuccess)success {
    if (success) {
        success([self tryToParseData:responseData]);
    }
}

+ (void)handleCallbackWithError:(NSError *)error fail:(SGTResponseFail)fail {
    if ([error code] == NSURLErrorCancelled) {
        if (kShouldLoadCacheWhenNetUNAvaliable) {
            if (fail) {
                fail(error);
            }
        }
    } else {
        if (fail) {
            fail(error);
        }
    }
}

#pragma mark - HTTP Get
+ (SGTRequestOperation *)getWithUrl:(NSString *)url
                            success:(SGTResponseSuccess)success
                               fail:(SGTResponseFail)fail {
    return [self getWithUrl:url params:nil headers:nil useCache:false refreshCache:false success:success fail:fail];
}

+ (SGTRequestOperation *)getWithUrl:(NSString *)url
                             params:(id)params
                            success:(SGTResponseSuccess)success
                               fail:(SGTResponseFail)fail {
    return [self getWithUrl:url params:params headers:nil useCache:false refreshCache:false success:success fail:fail];
}

+ (SGTRequestOperation *)getWithUrl:(NSString *)url
                           useCache:(BOOL)useCache
                       refreshCache:(BOOL)refreshCache
                            success:(SGTResponseSuccess)success
                               fail:(SGTResponseFail)fail {
    return [self getWithUrl:url params:nil headers:nil useCache:useCache refreshCache:refreshCache success:success fail:fail];
}

+ (SGTRequestOperation *)getWithUrl:(NSString *)url
                             params:(id)params
                           useCache:(BOOL)useCache
                       refreshCache:(BOOL)refreshCache
                            success:(SGTResponseSuccess)success
                               fail:(SGTResponseFail)fail {
    return [self getWithUrl:url params:params headers:nil useCache:useCache refreshCache:refreshCache success:success fail:fail];
}

+ (SGTRequestOperation *)getWithUrl:(NSString *)url
                             params:(id)params
                            headers:(NSDictionary *)headers
                           useCache:(BOOL)useCache
                       refreshCache:(BOOL)refreshCache
                            success:(SGTResponseSuccess)success
                               fail:(SGTResponseFail)fail {
    return [self _requestURL:url params:params useCache:useCache headers:headers refreshCache:refreshCache httpMethod:SGTNetRequestMethodGET progress:nil success:success fail:fail];
}

+ (SGTRequestOperation *)getWithUrl:(NSString *)url params:(id)params headers:(NSDictionary *)headers useCache:(BOOL)useCache refreshCache:(BOOL)refreshCache progress:(void (^)(NSProgress * _Nonnull))progress success:(SGTResponseSuccess)success fail:(SGTResponseFail)fail {
    return [self _requestURL:url params:params useCache:useCache headers:headers refreshCache:refreshCache httpMethod:SGTNetRequestMethodGET progress:progress success:success fail:fail];
}

#pragma mark - HTTP Post
+ (SGTRequestOperation *)postWithUrl:(NSString *)url
                              params:(id)params
                             success:(SGTResponseSuccess)success
                                fail:(SGTResponseFail)fail {
    return [self postWithUrl:url params:params headers:nil useCache:false refreshCache:false progress:nil success:success fail:fail];
}

+ (SGTRequestOperation *)postWithUrl:(NSString *)url params:(id)params useCache:(BOOL)useCache refreshCache:(BOOL)refreshCache success:(SGTResponseSuccess)success fail:(SGTResponseFail)fail {
    return [self postWithUrl:url params:params headers:nil useCache:useCache refreshCache:refreshCache progress:nil success:success fail:fail];
}

+ (SGTRequestOperation *)postWithUrl:(NSString *)url params:(id)params headers:(NSDictionary *)headers useCache:(BOOL)useCache refreshCache:(BOOL)refreshCache success:(SGTResponseSuccess)success fail:(SGTResponseFail)fail {
    return [self postWithUrl:url params:params headers:headers useCache:useCache refreshCache:refreshCache progress:nil success:success fail:fail];
}

+ (SGTRequestOperation *)postWithUrl:(NSString *)url params:(id)params headers:(NSDictionary *)headers useCache:(BOOL)useCache refreshCache:(BOOL)refreshCache progress:(void (^)(NSProgress * _Nonnull))progress success:(SGTResponseSuccess)success fail:(SGTResponseFail)fail {
    return [self _requestURL:url params:params useCache:useCache headers:headers refreshCache:refreshCache httpMethod:SGTNetRequestMethodPOST progress:progress success:success fail:fail];
}

#pragma mark - Image Upload

+ (SGTRequestOperation *)uploadWithImage:(UIImage *)image
                                     url:(NSString *)url
                                filename:(NSString *)filename
                                    name:(NSString *)name
                                  params:(id)params
                           ProgressBlock:(void (^)(NSProgress *uploadProgress))block
                                 success:(SGTResponseSuccess)success
                                    fail:(SGTResponseFail)fail {
    if ([self shouldEncode]) {
        url = [self encodeUrl:url];
    }
    
    AFHTTPSessionManager *manager = [self sessionManager];
    NSURLSessionDataTask *op = [manager POST:url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSData *imageData = UIImageJPEGRepresentation(image, 1);
        
        NSString *imageFileName = filename;
        if (filename == nil || ![filename isKindOfClass:[NSString class]] || filename.length == 0) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *str = [formatter stringFromDate:[NSDate date]];
            imageFileName = [NSString stringWithFormat:@"%@.jpg", str];
        }
        
        // 上传图片，以文件流的格式
        [formData appendPartWithFileData:imageData name:name fileName:imageFileName mimeType:@"image/jpeg"];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (block) {
            block(uploadProgress);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) {
            success(responseObject);
        }
        
        if ([self isDebug]) {
            [self logWithSuccessResponse:responseObject url:task.response.URL.absoluteString params:nil];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (fail) {
            fail(error);
        }
        
        if ([self isDebug]) {
            [self logWithFailError:error url:task.response.URL.absoluteString params:nil];
        }
    }];
    return op;
}

#pragma mark - DATA Stands

+ (BOOL)isCacheOutOfTimeForURL:(NSString *)url params:(id)params limitTime:(NSTimeInterval)time {
    NSString *path = [self cachePathForURL:url params:params];
    return [NSFileManager sgt_isTimeOutWithPath:path time:time];
}

+ (NSTimeInterval)cacheTimeIntervalForURL:(NSString *)url params:(id)params {
    NSString *path = [self cachePathForURL:url params:params];
    return [NSFileManager sgt_fileExistTime:path];
}

static inline NSString *cachePath() {
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/NetworkingCaches"];
}

+ (void)clearCaches {
    NSString *directoryPath = cachePath();
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:nil]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:directoryPath error:&error];
        
        if (error) {
            NSLog(@"SGTNetworking clear caches error: %@", error);
        } else {
            NSLog(@"SGTNetworking clear caches ok");
        }
    }
}

+ (unsigned long long)totalCacheSize {
    NSString *directoryPath = cachePath();
    BOOL isDir = NO;
    unsigned long long total = 0;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:&isDir]) {
        if (isDir) {
            NSError *error = nil;
            NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:&error];
            
            if (error == nil) {
                for (NSString *subpath in array) {
                    NSString *path = [directoryPath stringByAppendingPathComponent:subpath];
                    NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:path
                                                                                          error:&error];
                    if (!error) {
                        total += [dict[NSFileSize] unsignedIntegerValue];
                    }
                }
            }
        }
    }
    
    return total;
}

+ (id)cahceResponseWithURL:(NSString *)url parameters:(id)params {
    id cacheData = nil;
    if (url) {
        // Try to get datas from disk
        
        NSString *path = [self cachePathForURL:url params:params];
        NSData *data = [[NSFileManager defaultManager] contentsAtPath:path];
        if (data) {
            cacheData = data;
            DebugLog(@"Read data from cache for url: %@\n", url);
        }
    }
    return cacheData;
}

+ (NSString *)cachePathForURL:(NSString *)url params:(id)params {
    NSString *directoryPath = cachePath();
    NSString *absoluteURL = [self generateGETAbsoluteURL:url params:params];
    NSString *key = [self md5_string:absoluteURL];
    NSString *path = [directoryPath stringByAppendingPathComponent:key];
    return path;
}

+ (void)cacheResponseObject:(id)responseObject request:(NSURLRequest *)request parameters:params {
    if (request && responseObject && ![responseObject isKindOfClass:[NSNull class]]) {
        NSString *directoryPath = cachePath();
        
        NSError *error = nil;
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:nil]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:&error];
            if (error) {
                DebugLog(@"create cache dir error: %@\n", error);
                return;
            }
        }
        
        NSString *absoluteURL = [self generateGETAbsoluteURL:request.URL.absoluteString params:params];
        NSString *key = [self md5_string:absoluteURL];
        NSString *path = [directoryPath stringByAppendingPathComponent:key];
        NSDictionary *dict = (NSDictionary *)responseObject;
        
        NSData *data = nil;
        if ([dict isKindOfClass:[NSData class]]) {
            data = responseObject;
        } else {
            data = [NSJSONSerialization dataWithJSONObject:dict
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&error];
        }
        
        if (data && error == nil) {
            BOOL isOk = [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
            if (isOk) {
                DebugLog(@"cache file ok for request: %@\n", absoluteURL);
            } else {
                DebugLog(@"cache file error for request: %@\n", absoluteURL);
            }
        }
    }
}

#pragma mark - Private methord

+ (NSString *)_absoluteUrlWithPath:(NSString *)path {
    if (path == nil || path.length == 0) {
        return @"";
    }
    
    if ([self baseUrl] == nil || [[self baseUrl] length] == 0) {
        return path;
    }
    
    NSString *absoluteUrl = path;
    
    if (![path hasPrefix:@"http://"] && ![path hasPrefix:@"https://"]) {
        if ([[self baseUrl] hasSuffix:@"/"]) {
            if ([path hasPrefix:@"/"]) {
                NSMutableString * mutablePath = [NSMutableString stringWithString:path];
                [mutablePath deleteCharactersInRange:NSMakeRange(0, 1)];
                absoluteUrl = [NSString stringWithFormat:@"%@%@",
                               [self baseUrl], mutablePath];
            } else {
                absoluteUrl = [NSString stringWithFormat:@"%@%@",[self baseUrl], path];
            }
        } else {
            if ([path hasPrefix:@"/"]) {
                absoluteUrl = [NSString stringWithFormat:@"%@%@",[self baseUrl], path];
            } else {
                absoluteUrl = [NSString stringWithFormat:@"%@/%@",
                               [self baseUrl], path];
            }
        }
    }
    
    return absoluteUrl;
}

+ (NSString *)_requestURLFromUrl:(NSString *)url {
    NSString *requestURL = [self _absoluteUrlWithPath:url];
    
    if ([self baseUrl] == nil) {
        if ([NSURL URLWithString:url] == nil) {
            DebugLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL,URL:%@",url);
            return nil;
        }
    } else {
        NSURL *absoluteURL = [NSURL URLWithString:requestURL];
        
        if (absoluteURL == nil) {
            DebugLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode ,URL:%@",url);
            return nil;
        }
    }
    return requestURL;
}

+ (NSString *)md5_string:(NSString *)string {
    if (string == nil || [string length] == 0) {
        return nil;
    }
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH], i;
    CC_MD5([string UTF8String], (int)[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding], digest);
    NSMutableString *ms = [NSMutableString string];
    
    for (i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [ms appendFormat:@"%02x", (int)(digest[i])];
    }
    
    return [ms copy];
}

static NSArray<NSString *> *p_ignoreCacheHeaders ;
+ (void)updateIgnoreCachedParamKeys:(NSArray<NSString *> *)ignoreParams {
    p_ignoreCacheHeaders = ignoreParams;
}

+ (NSString *)generateGETAbsoluteURL:(NSString *)url params:(id)params {
    if (params == nil || ![params isKindOfClass:[NSDictionary class]] || [params count] == 0) {
        return url;
    }
    
    NSString *queries = @"";
    
    // 按照key的字符顺序对params进行排序
    NSArray <NSString *>*keys = ((NSDictionary *)params).allKeys;
    keys = [keys sortedArrayUsingComparator:^NSComparisonResult(NSString * obj1, NSString * obj2) {
        return [obj1 compare:obj2];
    }];
    
    for (NSString *key in keys) {
        id value = [params objectForKey:key];
        
        if ([value isKindOfClass:[NSDictionary class]]) {
            continue;
        } else if ([value isKindOfClass:[NSArray class]]) {
            continue;
        } else if ([value isKindOfClass:[NSSet class]]) {
            continue;
        } else if(p_ignoreCacheHeaders != nil && [p_ignoreCacheHeaders containsObject:key]){
            continue;
        }else {
            queries = [NSString stringWithFormat:@"%@%@=%@&",
                       (queries.length == 0 ? @"&" : queries),
                       key,
                       value];
        }
    }
    
    if (queries.length > 1) {
        queries = [queries substringToIndex:queries.length - 1];
    }
    
    if (([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"])) {
        if ([url rangeOfString:@"?"].location != NSNotFound
            || [url rangeOfString:@"#"].location != NSNotFound) {
            if (queries.length > 1) {
                queries = [queries substringFromIndex:1];
                url = [NSString stringWithFormat:@"%@?%@", [url componentsSeparatedByString:@"?"].firstObject, queries];
            }else {
                url = [url componentsSeparatedByString:@"?"].firstObject;
            }
        } else {
            if (queries.length > 1) {
                queries = [queries substringFromIndex:1];
                url = [NSString stringWithFormat:@"%@?%@", url, queries];
            }
        }
    }
    
    return url.length == 0 ? queries : url;
}

static AFHTTPSessionManager *manager = nil;
+ (AFHTTPSessionManager *)sessionManager {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 开启转圈圈
        [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
        NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0
                                                                diskCapacity:0
                                                                    diskPath:nil];
        [NSURLCache setSharedURLCache:sharedCache];
        
        manager = [[AFHTTPSessionManager alloc]
                   initWithBaseURL:[NSURL URLWithString:[self baseUrl]]];
        
        manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        
        if (kHeaderSerializer == SGTNetRequestTypeJSON) {
            AFJSONRequestSerializer *headSerializer = [AFJSONRequestSerializer serializer];
            [headSerializer setTimeoutInterval:10];
            manager.requestSerializer = headSerializer;
            manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
        }
        
        manager.responseSerializer = [AFJSONResponseSerializer serializer];
        
        for (NSString *key in kHttpHeaders.allKeys) {
            if (kHttpHeaders[key] != nil) {
                [manager.requestSerializer setValue:kHttpHeaders[key] forHTTPHeaderField:key];
            }
        }
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",
                                                                                  @"text/json",
                                                                                  @"text/plain",
                                                                                  @"text/javascript",
                                                                                  @"text/html"]];
        
        // 设置允许同时最大并发数量，过大容易出问题
        manager.operationQueue.maxConcurrentOperationCount = 5;
    });
    
    
    return manager;
}

+ (void)logWithSuccessResponse:(id)response url:(NSString *)url params:(NSDictionary *)params {
    DebugLog(@"\nabsoluteUrl: %@\n params:%@\n response:%@\n\n",
             url,
             params,
             response);
}

+ (void)logWithFailError:(NSError *)error url:(NSString *)url params:(NSDictionary *)params {
    DebugLog(@"\nabsoluteUrl: %@\n params:%@\n errorInfos:%@\n\n",
             url,
             params,
             [error localizedDescription]);
}

+ (NSString *)encodeUrl:(NSString *)url {
    return [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (NSMutableArray *)allTasks {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (allRequestTasks == nil) {
            allRequestTasks = [[NSMutableArray alloc] init];
        }
    });
    
    return allRequestTasks;
}

+ (void)autoToClearCacheWithLimitedToSize:(NSUInteger)mSize {
    kMaxCacheSize = mSize;
}

@end
