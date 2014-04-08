//
//  Region.h
//  Gamer
//
//  Created by Caio Mello on 07/04/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Gamer, Release;

@interface Region : NSManagedObject

@property (nonatomic, retain) NSString * abbreviation;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * imageName;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) Gamer *gamer;
@property (nonatomic, retain) NSSet *releases;
@end

@interface Region (CoreDataGeneratedAccessors)

- (void)addReleasesObject:(Release *)value;
- (void)removeReleasesObject:(Release *)value;
- (void)addReleases:(NSSet *)values;
- (void)removeReleases:(NSSet *)values;

@end
