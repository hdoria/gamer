//
//  Networking.h
//  Gamer
//
//  Created by Caio Mello on 13/10/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "Game.h"

@interface Networking : NSObject

+ (AFURLSessionManager *)manager;

+ (NSURLRequest *)requestForGamesWithTitle:(NSString *)title fields:(NSString *)fields platforms:(NSArray *)platforms;
+ (NSURLRequest *)requestForGameWithIdentifier:(NSNumber *)identifier fields:(NSString *)fields;
+ (NSURLRequest *)requestForVideoWithIdentifier:(NSNumber *)identifier fields:(NSString *)fields;
+ (NSURLRequest *)requestForReleaseWithIdentifier:(NSNumber *)identifier fields:(NSString *)fields;

+ (void)updateGame:(Game *)game withDataFromJSON:(NSDictionary *)JSON context:(NSManagedObjectContext *)context;
//+ (NSURLRequest *)requestForMetascoreForGameWithTitle:(NSString *)title platform:(Platform *)platform;

+ (void)setReleaseDateForGameOrRelease:(id)object dateString:(NSString *)date expectedReleaseDay:(NSInteger)day expectedReleaseMonth:(NSInteger)month expectedReleaseQuarter:(NSInteger)quarter expectedReleaseYear:(NSInteger)year;
+ (NSInteger)quarterForMonth:(NSInteger)month;
+ (ReleasePeriod *)releasePeriodForGame:(Game *)game context:(NSManagedObjectContext *)context;

+ (UIColor *)colorForMetascore:(NSString *)metascore;
//+ (NSString *)retrieveMetascoreFromHTML:(NSString *)HTML;

@end
