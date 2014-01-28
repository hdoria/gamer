//
//  LibraryCollectionViewController.m
//  Gamer
//
//  Created by Caio Mello on 24/07/2013.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "LibraryViewController.h"
#import "LibraryCollectionCell.h"
#import "Game.h"
#import "Platform.h"
#import "CoverImage.h"
#import "Genre.h"
#import "Developer.h"
#import "Publisher.h"
#import "Franchise.h"
#import "Theme.h"
#import "SimilarGame.h"
#import "ReleaseDate.h"
#import "GameTableViewController.h"
#import "HeaderCollectionReusableView.h"
#import <AFNetworking/AFNetworking.h>
#import "SearchViewController.h"
#import "LibraryFilterView.h"

typedef NS_ENUM(NSInteger, LibraryFilter){
	LibraryFilterTitle,
	LibraryFilterPlatform,
	LibraryFilterReleaseYear,
	LibraryFilterMetascore
};

@interface LibraryViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, UIActionSheetDelegate, LibraryFilterViewDelegate>

@property (nonatomic, strong) UIBarButtonItem *refreshButton;
@property (nonatomic, strong) UIBarButtonItem *searchBarItem;

@property (nonatomic, strong) IBOutlet UIButton *sortButton;
@property (nonatomic, strong) IBOutlet UIButton *filterButton;

@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) UIView *guideView;

@property (nonatomic, strong) LibraryFilterView *filterView;

@property (nonatomic, assign) LibraryFilter filter;

@property (nonatomic, assign) NSInteger numberOfRunningTasks;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation LibraryViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	_refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshLibraryGames)];
	
	// UI setup
	if ([Tools deviceIsiPad]){
		UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 256, 44)];
		[searchBar setPlaceholder:@"Find Games"];
		[searchBar setDelegate:self];
		_searchBarItem = [[UIBarButtonItem alloc] initWithCustomView:searchBar];
		
		[self.navigationItem setRightBarButtonItems:@[_searchBarItem, _refreshButton] animated:NO];
		
		UIBarButtonItem *sortBarButton = [[UIBarButtonItem alloc] initWithTitle:@"  Sort  " style:UIBarButtonItemStylePlain target:self action:@selector(showSortOptions)];
		UIBarButtonItem *filterBarButton = [[UIBarButtonItem alloc] initWithTitle:@"      Filter     " style:UIBarButtonItemStylePlain target:self action:@selector(showFilterOptions)];
		
		[self.navigationItem setLeftBarButtonItems:@[sortBarButton, filterBarButton] animated:NO];
	}
	else{
		[self.navigationItem setRightBarButtonItem:_refreshButton animated:NO];
		
		_filterView = [[LibraryFilterView alloc] initWithFrame:CGRectMake(0, -50, 320, 50)];
		[_filterView setDelegate:self];
		[_collectionView addSubview:_filterView];
		
		[_collectionView setContentInset:UIEdgeInsetsMake(50, 0, 0, 0)];
	}
	
	// Other stuff
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coverImageDownloadedNotification:) name:@"CoverImageDownloaded" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLibraryNotification:) name:@"RefreshLibrary" object:nil];
	
	_context = [NSManagedObjectContext defaultContext];
	
	_filter = LibraryFilterPlatform;
	
	_fetchedResultsController = [Game fetchAllGroupedBy:@"libraryPlatform.index" withPredicate:[NSPredicate predicateWithFormat:@"owned = %@", @(YES)] sortedBy:@"libraryPlatform.index,title" ascending:YES inContext:_context];
	
	_guideView = [[NSBundle mainBundle] loadNibNamed:[Tools deviceIsiPad] ? @"iPad" : @"iPhone" owner:self options:nil][1];
	[self.view insertSubview:_guideView aboveSubview:_collectionView];
	[_guideView setFrame:self.view.frame];
	[_guideView setHidden:YES];
}

- (void)viewWillAppear:(BOOL)animated{
	if ([Tools deviceIsiPad])
		[(UISearchBar *)_searchBarItem.customView setText:[Session searchQuery]];
}

- (void)viewDidAppear:(BOOL)animated{
	[[Session tracker] set:kGAIScreenName value:@"Library"];
	[[Session tracker] send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewDidLayoutSubviews{
	if ([Tools deviceIsiPad])
		[_guideView setCenter:self.view.center];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - SearchBar

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar{
	SearchViewController *searchViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SearchViewController"];
	[self.navigationController pushViewController:searchViewController animated:NO];
	return NO;
}

#pragma mark - CollectionView

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
	[_guideView setHidden:([Game countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"owned = %@", @(YES)]] == 0) ? NO : YES];
	
	return _fetchedResultsController.sections.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
	NSString *sectionName = [_fetchedResultsController.sections[indexPath.section] name];
	
	Game *game = [_fetchedResultsController objectAtIndexPath:indexPath];
	
	NSString *headerTitle;
	
	switch (_filter) {
		case LibraryFilterTitle: headerTitle = sectionName; break;
		case LibraryFilterPlatform: headerTitle = game.libraryPlatform.name; break;
		case LibraryFilterReleaseYear: headerTitle = game.releaseDate.year.stringValue; break;
		case LibraryFilterMetascore: headerTitle = game.metascore.length > 0 ? game.metascore : @"Unavailable"; break;
		default: break;
	}
	
	if ([headerTitle isEqualToString:@"2050"])
		headerTitle = @"Unknown";
	
	HeaderCollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
	[headerView.titleLabel setText:headerTitle];
	[headerView.separator setHidden:indexPath.section == 0 ? YES : NO];
	return headerView;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
	return [_fetchedResultsController.sections[section] numberOfObjects];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
	switch ([Session gamer].librarySize.integerValue) {
		case 0: return [Tools deviceIsiPad] ? CGSizeMake(83, 91) : CGSizeMake(50, 63);
		case 1: return [Tools deviceIsiPad] ? CGSizeMake(115, 127) : CGSizeMake(66, 83);
		case 2: return [Tools deviceIsiPad] ? CGSizeMake(140, 176) : CGSizeMake(92, 116);
		default: return CGSizeZero;
	}
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
	Game *game = [_fetchedResultsController objectAtIndexPath:indexPath];
	UIImage *image = [UIImage imageWithData:game.thumbnailLibrary];
	
	LibraryCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
	[cell.coverImageView setImage:image];
	[cell.coverImageView setBackgroundColor:image ? [UIColor clearColor] : [UIColor darkGrayColor]];
	
	return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
	[self performSegueWithIdentifier:@"GameSegue" sender:indexPath];
}

#pragma mark - Networking

- (void)requestInformationForGame:(Game *)game{
	NSURLRequest *request = [Networking requestForGameWithIdentifier:game.identifier fields:@"deck,developers,expected_release_day,expected_release_month,expected_release_quarter,expected_release_year,franchises,genres,id,image,name,original_release_date,platforms,publishers,similar_games,themes"];
	
	NSURLSessionDataTask *dataTask = [[Networking manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
		if (error){
			if (((NSHTTPURLResponse *)response).statusCode != 0) NSLog(@"Failure in %@ - Status code: %d - Game", self, ((NSHTTPURLResponse *)response).statusCode);
			
			_numberOfRunningTasks--;
			
			if (_numberOfRunningTasks == 0)
				[_refreshButton setEnabled:YES];
		}
		else{
			NSLog(@"Success in %@ - Status code: %d - Game - Size: %lld bytes", self, ((NSHTTPURLResponse *)response).statusCode, response.expectedContentLength);
			
			_numberOfRunningTasks--;
			
			[Networking updateGame:game withDataFromJSON:responseObject context:_context];
			
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
				if (![responseObject[@"status_code"] isEqualToNumber:@(101)]){
					NSString *coverImageURL = (responseObject[@"results"][@"image"] != [NSNull null]) ? [Tools stringFromSourceIfNotNull:responseObject[@"results"][@"image"][@"super_url"]] : nil;
					
					UIImage *coverImage = [UIImage imageWithData:game.coverImage.data];
					CGSize optimalSize = [Session optimalCoverImageSizeForImage:coverImage];
					
					if (!game.thumbnailWishlist || !game.thumbnailLibrary || !game.coverImage.data || ![game.coverImage.url isEqualToString:coverImageURL] || (coverImage.size.width != optimalSize.width || coverImage.size.height != optimalSize.height)){
						[self downloadCoverImageForGame:game];
					}
				}
			});
			
			if (_numberOfRunningTasks == 0){
				[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
					[_refreshButton setEnabled:YES];
				}];
			}
		}
	}];
	[dataTask resume];
	_numberOfRunningTasks++;
}

- (void)downloadCoverImageForGame:(Game *)game{
	if (!game.coverImage.url) return;
	
	NSURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:game.coverImage.url]];
	
	NSURLSessionDownloadTask *downloadTask = [[Networking manager] downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
		return [NSURL fileURLWithPath:[NSString stringWithFormat:@"/tmp/%@", request.URL.lastPathComponent]];
	} completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
		if (error){
			
		}
		else{
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
				UIImage *downloadedImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:filePath]];
				[game.coverImage setData:UIImagePNGRepresentation([Session aspectFitImageWithImage:downloadedImage type:GameImageTypeCover])];
				[game setThumbnailWishlist:UIImagePNGRepresentation([Session aspectFitImageWithImage:downloadedImage type:GameImageTypeWishlist])];
				[game setThumbnailLibrary:UIImagePNGRepresentation([Session aspectFitImageWithImage:downloadedImage type:GameImageTypeLibrary])];
				
				[_context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
					dispatch_async(dispatch_get_main_queue(), ^{
						[_collectionView reloadData];
					});
				}];
			});
		}
	}];
	[downloadTask resume];
}

#pragma mark - LibraryFilterView

- (void)libraryFilterView:(LibraryFilterView *)filterView didPressSortButton:(UIButton *)button{
	[self showSortOptions];
}

- (void)libraryFilterView:(LibraryFilterView *)filterView didPressFilterButton:(UIButton *)button{
	[self showFilterOptions];
}

- (void)libraryFilterView:(LibraryFilterView *)filterView didPressCancelButton:(UIButton *)button{
	[_filterView resetAnimated:YES];
	
	_filter = LibraryFilterPlatform;
	
	_fetchedResultsController = nil;
	_fetchedResultsController = [Game fetchAllGroupedBy:@"libraryPlatform.index" withPredicate:[NSPredicate predicateWithFormat:@"owned = %@", @(YES)] sortedBy:@"libraryPlatform.index,title" ascending:YES inContext:_context];
	[_collectionView reloadData];
}

#pragma mark - ActionSheet

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (buttonIndex != actionSheet.cancelButtonIndex){
		if (actionSheet.tag == 1){
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"owned = %@", @(YES)];
			
			// Sort
			switch (buttonIndex) {
				case 0:
					// Title
					[self fetchGamesWithFilter:LibraryFilterTitle group:@"title.stringGroupByFirstInitial" predicate:predicate sort:@"title" ascending:YES];
					[_filterView showStatusWithTitle:@"Sorted by title" animated:YES];
					break;
				case 1:
					// Release year
					[self fetchGamesWithFilter:LibraryFilterReleaseYear group:@"releaseDate.year" predicate:predicate sort:@"releaseDate.year,title" ascending:NO];
					[_filterView showStatusWithTitle:@"Sorted by release year" animated:YES];
					break;
				case 2:
					// Metascore
					[self fetchGamesWithFilter:LibraryFilterMetascore group:@"metascore" predicate:predicate sort:@"metascore,title" ascending:NO];
					[_filterView showStatusWithTitle:@"Sorted by Metascore" animated:YES];
					break;
				case 3:
					// Platform (iPad)
					[self fetchGamesWithFilter:LibraryFilterPlatform group:@"libraryPlatform.index" predicate:predicate sort:@"libraryPlatform.index,title" ascending:YES];
					[_filterView showStatusWithTitle:@"Sorted by platform" animated:YES];
					break;
				default: break;
			}
		}
		else{
			// Filter
			switch (buttonIndex) {
				case 0:
					// Completed
					[self fetchGamesWithFilter:LibraryFilterPlatform group:@"libraryPlatform.index" predicate:[NSPredicate predicateWithFormat:@"owned = %@ AND completed = %@", @(YES), @(YES)] sort:@"libraryPlatform.index,title" ascending:YES];
					[_filterView showStatusWithTitle:@"Showing completed games" animated:YES];
					break;
				case 1:
					// Incomplete
					[self fetchGamesWithFilter:LibraryFilterPlatform group:@"libraryPlatform.index" predicate:[NSPredicate predicateWithFormat:@"owned = %@ AND completed = %@", @(YES), @(NO)] sort:@"libraryPlatform.index,title" ascending:YES];
					[_filterView showStatusWithTitle:@"Showing incomplete games" animated:YES];
					break;
				case 2:
					// Digital
					[self fetchGamesWithFilter:LibraryFilterPlatform group:@"libraryPlatform.index" predicate:[NSPredicate predicateWithFormat:@"owned = %@ AND digital = %@", @(YES), @(YES)] sort:@"libraryPlatform.index,title" ascending:YES];
					[_filterView showStatusWithTitle:@"Showing digital games" animated:YES];
					break;
				case 3:
					// Physical
					[self fetchGamesWithFilter:LibraryFilterPlatform group:@"libraryPlatform.index" predicate:[NSPredicate predicateWithFormat:@"owned = %@ AND digital = %@", @(YES), @(NO)] sort:@"libraryPlatform.index,title" ascending:YES];
					[_filterView showStatusWithTitle:@"Showing physical games" animated:YES];
					break;
				case 4:
					// Loaned
					[self fetchGamesWithFilter:LibraryFilterPlatform group:@"libraryPlatform.index" predicate:[NSPredicate predicateWithFormat:@"owned = %@ AND loaned = %@", @(YES), @(YES)] sort:@"libraryPlatform.index,title" ascending:YES];
					[_filterView showStatusWithTitle:@"Showing loaned games" animated:YES];
					break;
				default: break;
			}
		}
	}
	
	[self.navigationController.navigationBar setUserInteractionEnabled:YES];
}

#pragma mark - Custom

- (void)fetchGamesWithFilter:(LibraryFilter)filter group:(NSString *)group predicate:(NSPredicate *)predicate sort:(NSString *)sort ascending:(BOOL)ascending{
	_filter = filter;
	
	_fetchedResultsController = nil;
	_fetchedResultsController = [Game fetchAllGroupedBy:group withPredicate:predicate sortedBy:sort ascending:ascending inContext:_context];
	[_collectionView reloadData];
}

- (void)refreshLibraryGames{
	if (_fetchedResultsController.fetchedObjects.count > 0){
		[_refreshButton setEnabled:NO];
	}
	
	_numberOfRunningTasks = 0;
	
	// Request info for all games in the Wishlist
	for (NSInteger section = 0; section < _fetchedResultsController.sections.count; section++)
		for (NSInteger row = 0; row < ([_fetchedResultsController.sections[section] numberOfObjects]); row++)
			[self requestInformationForGame:[_fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]]];
}

- (void)showSortOptions{
	UIActionSheet *actionSheet;
	
	if ([Tools deviceIsiPhone]){
		actionSheet = [[UIActionSheet alloc] initWithTitle:@"Sort by" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Title", @"Release year", @"Metascore", nil];
		[actionSheet setTag:1];
		[actionSheet showInView:self.view.window];
	}
	else{
		actionSheet = [[UIActionSheet alloc] initWithTitle:@"Sort by" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Title", @"Release year", @"Metascore", @"Platform", nil];
		[actionSheet setTag:1];
		[actionSheet showFromBarButtonItem:self.navigationItem.leftBarButtonItems[0] animated:YES];
	}
	
	[self.navigationController.navigationBar setUserInteractionEnabled:NO];
}

- (void)showFilterOptions{
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Show only" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Completed", @"Incomplete", @"Digital", @"Physical", @"Loaned", nil];
	[actionSheet setTag:2];
	
	if ([Tools deviceIsiPhone])
		[actionSheet showInView:self.view.window];
	else
		[actionSheet showFromBarButtonItem:self.navigationItem.leftBarButtonItems[1] animated:YES];
	
	[self.navigationController.navigationBar setUserInteractionEnabled:NO];
}

#pragma mark - Actions

- (IBAction)refreshBarButtonAction:(UIBarButtonItem *)sender{
	[self refreshLibraryGames];
}

- (void)coverImageDownloadedNotification:(NSNotification *)notification{
	[_collectionView reloadData];
}

- (void)refreshLibraryNotification:(NSNotification *)notification{
	[_filterView resetAnimated:YES];
	
	_filter = LibraryFilterPlatform;
	
	_fetchedResultsController = nil;
	_fetchedResultsController = [Game fetchAllGroupedBy:@"libraryPlatform.index" withPredicate:[NSPredicate predicateWithFormat:@"owned = %@", @(YES)] sortedBy:@"libraryPlatform.index,title" ascending:YES inContext:_context];
	[_collectionView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"GameSegue"]){
		if ([Tools deviceIsiPad]){
			UINavigationController *navigationController = segue.destinationViewController;
			GameTableViewController *destination = (GameTableViewController *)navigationController.topViewController;
			[destination setGame:[_fetchedResultsController objectAtIndexPath:sender]];
		}
		else{
			// Pop other tabs when opening game details
			for (UIViewController *viewController in self.tabBarController.viewControllers){
				[((UINavigationController *)viewController) popToRootViewControllerAnimated:NO];
			}
			
			GameTableViewController *destination = segue.destinationViewController;
			[destination setGame:[_fetchedResultsController objectAtIndexPath:sender]];
		}
	}
}

@end
