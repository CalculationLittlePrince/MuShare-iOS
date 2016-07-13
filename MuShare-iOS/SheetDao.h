//
//  SheetDao.h
//  MuShare-iOS
//
//  Created by 李大爷的电脑 on 7/13/16.
//  Copyright © 2016 limeng. All rights reserved.
//

#import "DaoTemplate.h"

#define SheetEntityName @"Sheet"

@interface SheetDao : DaoTemplate

- (NSManagedObjectID *)savwWithName:(NSString *)name
                       andPrivilege:(NSString *)privilege
                             andSid:(NSNumber *)sid
                            forUser:(User *)user;

@end
