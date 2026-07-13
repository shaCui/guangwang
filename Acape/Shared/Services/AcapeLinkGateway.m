#import "AcapeLinkGateway.h"
@import CoreTelephony;

static CTCellularData *sCellularProbe = nil;
static NSURLSession *sLinkSession = nil;

@implementation AcapeLinkGateway

+ (void)requestSystemLinkAccessIfNeeded {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (@available(iOS 9.0, *)) {
            if (!sCellularProbe) {
                sCellularProbe = [[CTCellularData alloc] init];
                sCellularProbe.cellularDataRestrictionDidUpdateNotifier = ^(__unused CTCellularDataRestrictedState state) {
                };
            }
            (void)sCellularProbe.restrictedState;
        }

        if (!sLinkSession) {
            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
            configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
            configuration.timeoutIntervalForRequest = 20.0;
            configuration.waitsForConnectivity = YES;
            sLinkSession = [NSURLSession sessionWithConfiguration:configuration];
        }

        NSArray<NSString *> *probeURLs = @[
            @"http://www.baidu.com",
            @"https://www.apple.com",
            @"https://www.baidu.com",
            @"https://captive.apple.com/hotspot-detect.html",
        ];
        for (NSString *probeURL in probeURLs) {
            NSURL *url = [NSURL URLWithString:probeURL];
            if (!url) {
                continue;
            }
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                                   cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                               timeoutInterval:20.0];
            NSURLSessionDataTask *task = [sLinkSession dataTaskWithRequest:request
                                                         completionHandler:^(__unused NSData *data,
                                                                             __unused NSURLResponse *response,
                                                                             __unused NSError *error) {
            }];
            [task resume];
        }
    });
}

@end
