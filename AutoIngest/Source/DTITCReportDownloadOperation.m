//
//  DTITCReportDownloadOperation.m
//  AutoIngest
//
//  Created by Oliver Drobnik on 4/20/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTITCReportDownloadOperation.h"
#import "GenericAccount.h"
#import "DTZipArchive.h"
#import "ReportFolderClassifier.h"

@implementation DTITCReportDownloadOperation
{
	ITCReportType _reportType;
	ITCReportSubType _reportSubType;
	ITCReportDateType _reportDateType;
	GenericAccount *_account;
	NSString *_vendorID;
	NSString *_reportFolder;
	
	NSError *_error;
	
	DTITCReportDownloader *_downloader;
}


- (id)initForReportsOfType:(ITCReportType)reportType subType:(ITCReportSubType)reportSubType dateType:(ITCReportDateType)reportDateType fromAccount:(GenericAccount *)account vendorID:(NSString *)vendorID intoFolder:(NSString *)folder;
{
	self = [super init];
	
	if (self)
	{
		_reportType = reportType;
		_reportSubType = reportSubType;
		_reportDateType = reportDateType;
		
		_account = account;
		_vendorID = [vendorID copy];
		
		_reportFolder = [folder copy];
	}
	
	return self;
}


// determines if a report already exists in the download folder
- (BOOL)_alreadyDownloadedReportForDate:(NSDate *)reportDate reportType:(ITCReportType)reportType reportDateType:(ITCReportDateType)reportDateType reportSubType:(ITCReportSubType)reportSubType
{
	NSAssert(_downloader, @"Need a downloader set");

	NSString *predictedZippedName = [_downloader predictedFileNameForDate:reportDate
																		 reportType:_reportType
																	reportDateType:_reportDateType
																	 reportSubType:_reportSubType
																		 compressed:YES];
	
	NSString *predictedUnzippedName = [_downloader predictedFileNameForDate:reportDate
																				 reportType:_reportType
																			reportDateType:_reportDateType
																			 reportSubType:_reportSubType
																				 compressed:NO];
	NSString *folder = _reportFolder;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:AIUserDefaultsShouldAutoOrganizeReportsKey])
    {
        folder = [[[ReportFolderClassifier alloc] initWithBasePath:folder] pathForReportFileName:predictedZippedName];
    }

	NSString *predictedZippedOutputPath = [folder stringByAppendingPathComponent:predictedZippedName];
	NSString *predictedUnzippedOutputPath = [folder stringByAppendingPathComponent:predictedUnzippedName];

	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if ([fileManager fileExistsAtPath:predictedZippedOutputPath])
	{
		return YES;
	}
	
	if ([fileManager fileExistsAtPath:predictedUnzippedOutputPath])
	{
		return YES;
	}
	
	return NO;
}

- (void)main
{
	BOOL downloadAll = YES;
	
	// create a downloader
	_downloader = [[DTITCReportDownloader alloc] initWithUser:_account.account password:_account.password vendorIdentifier:_vendorID];
	
	// determine date to pass to download
	__block NSDate *reportDate;
	NSDate *today = [NSDate date];
	
	NSDateComponents *comps = [[NSDateComponents alloc] init];
	[comps setDay:-1];
	
	reportDate = [[NSCalendar currentCalendar] dateByAddingComponents:comps toDate:today options:0];
	
	// for weekly reports go back to previous Sunday
	if (_reportDateType == ITCReportDateTypeWeekly)
	{
		NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		
		NSDateComponents *comps = [gregorian components:NSWeekdayCalendarUnit fromDate:reportDate];
		
		if (comps.weekday!=1) // not a Sunday
		{
			comps.day = -(comps.weekday-1);
			comps.weekday = 0;
			
			reportDate = [gregorian dateByAddingComponents:comps toDate:reportDate options:0];
		}
	}
	
	__block NSUInteger downloadedFiles = 0;
	
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	NSString *dateFormat = NSStringWithDateFormatForITCReportDateType(_reportDateType);
	[formatter setDateFormat:dateFormat];
	
	do
	{
		if ([self isCancelled])
		{
			break;
		}
		
		if ([self _alreadyDownloadedReportForDate:reportDate reportType:_reportType reportDateType:_reportDateType reportSubType:_reportSubType])
		{
			NSLog(@"Skipping report %@, already downloaded", [_downloader predictedFileNameForDate:reportDate reportType:_reportType reportDateType:_reportDateType reportSubType:_reportSubType compressed:NO]);
			downloadedFiles++;
			
			if (!downloadAll)
			{
				break;
			}
		}
		else if ([_downloader downloadReportWithDate:reportDate
													reportType:_reportType
											  reportDateType:_reportDateType
												reportSubType:_reportSubType
										  completionHandler:^(NSString *fileName, NSData *data) {
											  
											  // cancel loop, synching has probably been cancelled
											  if ([self isCancelled])
											  {
												  reportDate = nil;
												  
												  return;
											  }
											  
											  NSString *baseName = [fileName stringByReplacingOccurrencesOfString:@".txt.gz" withString:@""];
											  
											  // update actual report date
											  NSString *dateFormat = NSStringWithDateFormatForITCReportDateType(_reportDateType);
											  
											  NSString *dateStringInName = [baseName substringWithRange:NSMakeRange([baseName length]-[dateFormat length], [dateFormat length])];
											  formatter.dateFormat = dateFormat;
											  NSDate *parsedDate = [formatter dateFromString:dateStringInName];
											  
											  if ([parsedDate compare:reportDate] == NSOrderedDescending)
											  {
												  // cancel loop, this file does not fit with what we requested
												  reportDate = nil;
												  
												  return;
											  }
											  else
											  {
												  reportDate = parsedDate;
											  }
											  
											  // check if we already had this one
											  if ([self _alreadyDownloadedReportForDate:reportDate reportType:_reportType reportDateType:_reportDateType reportSubType:_reportSubType])
											  {
													NSLog(@"Skipping report %@, already downloaded", [_downloader predictedFileNameForDate:reportDate reportType:_reportType reportDateType:_reportDateType reportSubType:_reportSubType compressed:NO]);
												  
												  downloadedFiles++;
												  
												  return;
											  }
											  
											  // get current working directory
											  NSString *outputPath = [_reportFolder stringByAppendingPathComponent:fileName];
											  
											  // write data to file
											  NSError *writeError = nil;
											  if ([data writeToFile:outputPath options:NSDataWritingAtomic error:&writeError])
											  {
												  NSLog(@"Downloaded Report %@", fileName);
												  downloadedFiles++;
												  
												  // optional uncompressing
												  if (self.uncompressFiles)
												  {
													  NSString *uncompressedFilePath = [outputPath stringByDeletingLastPathComponent];
													  
													  DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:outputPath];
													  
													  [zipArchive uncompressToPath:uncompressedFilePath completion:^(NSError *error) {
														  if (error)
														  {
															  NSLog(@"Unzipping Error: %@", [error localizedDescription]);
														  }
														  else
														  {
															  NSFileManager *fileManager = [[NSFileManager alloc] init];
															  
															  NSError *removeError = nil;
															  if (![fileManager removeItemAtPath:outputPath error:&removeError])
															  {
																  NSLog(@"Error removing file: %@", [removeError localizedDescription]);
															  }
														  }
													  }];
												  }
											  }
											  else
											  {
												  NSLog(@"%@", [writeError localizedDescription]);
											  }
										  }
					 
												 errorHandler:^(NSError *error) {
													 // if there is an URL connection error that is returned via this
													 NSError *networkError = [error userInfo][NSUnderlyingErrorKey];
													 
													 if (networkError)
													 {
														 _error = networkError; // network error, probably offline
													 }
													 else if ([[error localizedDescription] rangeOfString:@"Apple ID"].location != NSNotFound)
													 {
														 _error = error; // error message mentioning Apple ID probably means incorrect credentials
													 }
													 else if ([[error localizedDescription] rangeOfString:@"vendor number"].location != NSNotFound)
													 {
														 _error = error; // invalid vendor id
													 }
													 
													 if (_error && [_delegate respondsToSelector:@selector(operation:didFailWithError:)])
													 {
														 [_delegate operation:self didFailWithError:_error];
													 }
													 
													 NSLog(@"%@", [error localizedDescription]);
												 }])
		{
			// download succeeded for this date
			if (!downloadAll)
			{
				break;
			}
		}
		else
		{
			// download failed for this date
			if (!downloadAll)
			{
				// abort for single file
				break;
			}
			else
			{
				if (downloadedFiles>0)
				{
					// if we are downloading all the first failure means we end
					break;
				}
			}
		}
		
		if (downloadAll)
		{
			// move to one day/week/month/year earlier
			NSDateComponents *comps = [[NSDateComponents alloc] init];
			
			switch (_reportDateType)
			{
				case ITCReportDateTypeDaily:
				{
					[comps setDay:-1];
					break;
				}
					
				case ITCReportDateTypeWeekly:
				{
					[comps setDay:-7];
					break;
				}
					
				case ITCReportDateTypeMonthly:
				{
					[comps setMonth:-1];
					break;
				}
					
				case ITCReportDateTypeYearly:
				{
					[comps setYear:-1];
					break;
				}
					
				default:
				{
					break;
				}
			}
			
			if (!reportDate)
			{
				break;
			}
			
			reportDate = [[NSCalendar currentCalendar] dateByAddingComponents:comps toDate:reportDate options:0];
		}
		
	} while (!_error);
}

@end
