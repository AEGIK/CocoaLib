//
//  AGK.m
//  CocoaLib
//
//  Created by Christoffer Lernö on 2011-11-06.
//  Copyright 2011 AEGIK AB. All rights reserved.
//

#import "AGK.h"

#import "AGK.h"
#import "NSFileManager+Extras.h"
#import <stdio.h>

static FILE *logFileHandle = NULL;
static int logRounds = -1;

void AGKLogRotate(void) {
    
    if (logRounds < 1) return;
    if (logFileHandle) {
        fclose(logFileHandle);
        logFileHandle = NULL;
    }
    
    NSString *logDirectory = [NSFileManager directory:@"logs" inUserDirectory:NSDocumentDirectory];
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSError *error = nil;
    [manager createDirectoryAtPath:logDirectory
       withIntermediateDirectories:YES
                        attributes:nil
                             error:&error];
    if (error) {
        NSLog(@"Failed to create %@: %@", logDirectory, error);
        return;
    }
    
    NSLog(@"Rotating logs.");
    
    for (int i = logRounds - 1; i >= 0; i--) {
        NSString *sourceLog = [logDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"standard.%d.log", i]];
        NSString *targetLog = [logDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"standard.%d.log", i + 1]];
        [manager removeItemAtPath:targetLog error:NULL];
        [manager moveItemAtPath:sourceLog toPath:targetLog error:NULL];
    }
    
    NSLog(@"Log rotation complete.");
    
    NSLog(@"Opening file.");
    
    logFileHandle = fopen([[logDirectory stringByAppendingPathComponent:@"standard.0.log"] fileSystemRepresentation], "w+");
    
    if (!logFileHandle) {
        NSLog(@"WARNING - failed to set up log.");
    }
    
    NSLog(@"Log file opened.");
}

void AGKInitLog(int startsToLog) {
    
    if (logFileHandle) return;
    
    logRounds = startsToLog;
    
    AGKLogRotate();    
    
    NSLog(@"Log Setup Complete");
    
}

void AGKLog(NSString *format, ...) {
    NSString *stringToLog;
    if (!format) {
        stringToLog = @"---";
    } else {
        va_list argList;
        va_start(argList, format);
        stringToLog = [[NSString alloc] initWithFormat:format arguments:argList];
        va_end(argList);
    }        
    
    if (logFileHandle) {
        static __strong NSDateFormatter* dateFormatter = nil;
        if (!dateFormatter) {
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
        }
        fprintf(logFileHandle, "[%s]: %s\n", [[dateFormatter stringFromDate:[NSDate date]] UTF8String], [stringToLog UTF8String]);        
        fflush(logFileHandle);
    }
    NSLog(@"%@", stringToLog);
}

NSArray *AGKLogs(void) {
    
    NSString *logDirectory = [NSFileManager directory:@"logs" inUserDirectory:NSDocumentDirectory];
    NSMutableArray *logs = [[NSMutableArray alloc] init];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    for (int i = 0;; i++) {
        NSString *file = [NSString stringWithFormat:@"standard.%d.log", i];
        NSString *filename = [logDirectory stringByAppendingPathComponent:file];
        if (![fileManager fileExistsAtPath:filename]) break;
        NSError *readError = nil;
        NSData *data = [NSData dataWithContentsOfFile:filename
                                              options:NSDataReadingUncached
                                                error:&readError];
        if (readError) continue;
        [logs addObject:data];
    }
    return logs;
}