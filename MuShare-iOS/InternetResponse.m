//
//  InternetResponse.m
//  MuShare-iOS
//
//  Created by 李大爷的电脑 on 7/13/16.
//  Copyright © 2016 limeng. All rights reserved.
//

#import "InternetResponse.h"

@implementation InternetResponse

- (instancetype) initWithResponseObject:(id)responseObject {
    if(DEBUG) {
        NSLog(@"Running %@ ''%@", self.class, NSStringFromSelector(_cmd));
    }
    self = [super init];
    if(self) {
        _data = [NSJSONSerialization JSONObjectWithData:responseObject
                                                options:NSJSONReadingAllowFragments
                                                  error:nil];
    }
    if(DEBUG) {
        NSLog(@"Get Message from server: %@", self.data);
    }
    return self;
}

- (instancetype)initWithError:(NSError *)error {
    if(DEBUG) {
        NSLog(@"Running %@ ''%@", self.class, NSStringFromSelector(_cmd));
    }
    self = [super init];
    if(self) {
        _data = [NSJSONSerialization JSONObjectWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]
                                                options:NSJSONReadingAllowFragments
                                                  error:nil];
        
    }
    if(DEBUG) {
        NSLog(@"Get Error from server: %@", self.data);
    }
    return self;
}

- (BOOL)status200 {
    if(DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    return [[self.data valueForKey:@"status"] intValue] == 200;
}

- (id)getResponseBody {
    if(DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    return [self.data valueForKey:@"body"];
}

- (int)errorCode {
    if(DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    return [[self.data valueForKey:@"error_code"] intValue];
}
@end
