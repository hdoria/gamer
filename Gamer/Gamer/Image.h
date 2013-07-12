//
//  Image.h
//  Gamer
//
//  Created by Caio Mello on 7/11/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Game;

@interface Image : NSManagedObject

@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSNumber * isDownloading;
@property (nonatomic, retain) NSData * thumbnail;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) Game *game;

@end