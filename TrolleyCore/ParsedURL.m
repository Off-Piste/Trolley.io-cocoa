/////////////////////////////////////////////////////////////////////////////////
//
//  ParsedURL.m
//  TrolleyCore
//
//  Created by Harry Wright on 23.08.17.
//  Copyright © 2017 Off-Piste.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#import "ParsedURL.h"
#import "TRLNetworkInfo.h"
#import "TRLNetworkInfo_Internal.h"
#import "ParsedURL_Internal.h"
#import "TRLLogger.h"

@implementation ParsedURL {
    TRLNetworkInfo *_info;
}


- (NSURL *)url {
    return _info.url;
}

- (NSURL *)connectionURL {
    return _info.connectionURL;
}

- (instancetype)initWithNetworkInfo:(TRLNetworkInfo *)info {
    self = [super init];
    if (self) {
        self->_info = info;
    }
    return self;
}

- (ParsedURL *)addingPath:(NSString *)path {
    NSError *error;
    TRLNetworkInfo *newInfo = [_info addingPath:path error:&error];
    if (error) {
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:error.localizedDescription
                                     userInfo:NULL];
    }

    return [[ParsedURL alloc] initWithNetworkInfo:newInfo];
}

- (void)addPath:(NSString *)path {
    CoreLogger(TRLLoggerLevelInfo, @"Adding a path to ParsedURL is dangerous, please make sure it is definatly needed!")

    NSError *error;
    [_info addPath:path error:&error];

    if (error) {
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:error.localizedDescription
                                     userInfo:NULL];
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@", self.url.absoluteString];
}

@end
