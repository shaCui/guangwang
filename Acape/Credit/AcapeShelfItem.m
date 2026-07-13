#import "AcapeShelfItem.h"

@implementation AcapeShelfItem

+ (instancetype)itemWithBatchRef:(NSString *)batchRef
                    creditAmount:(NSInteger)creditAmount
                      priceLabel:(NSString *)priceLabel {
    return [[self alloc] initWithBatchRef:batchRef creditAmount:creditAmount priceLabel:priceLabel];
}

+ (NSArray<AcapeShelfItem *> *)defaultCatalog {
    return @[
        [AcapeShelfItem itemWithBatchRef:@"lvbsvhxcgcrvesor" creditAmount:400 priceLabel:@"$ 0.99"],
        [AcapeShelfItem itemWithBatchRef:@"hvxjjrrxjvdmuani" creditAmount:800 priceLabel:@"$ 1.99"],
        [AcapeShelfItem itemWithBatchRef:@"dxismgcwewhrtezo" creditAmount:2450 priceLabel:@"$ 4.99"],
        [AcapeShelfItem itemWithBatchRef:@"khtxlcejaxmqcsra" creditAmount:5150 priceLabel:@"$ 9.99"],
        [AcapeShelfItem itemWithBatchRef:@"yadwwvxspgxwldnb" creditAmount:10800 priceLabel:@"$ 19.99"],
        [AcapeShelfItem itemWithBatchRef:@"mjkwpqxnbvrtfcdh" creditAmount:17400 priceLabel:@"$ 34.99"],
        [AcapeShelfItem itemWithBatchRef:@"qnrcuelbtiuflyky" creditAmount:29400 priceLabel:@"$ 49.99"],
        [AcapeShelfItem itemWithBatchRef:@"plqwsxhzkncvbfgr" creditAmount:34500 priceLabel:@"$ 69.99"],
        [AcapeShelfItem itemWithBatchRef:@"ytghbnmkloiuytre" creditAmount:44500 priceLabel:@"$ 89.99"],
        [AcapeShelfItem itemWithBatchRef:@"ymohxnvpkqxutvab" creditAmount:63700 priceLabel:@"$ 99.99"],
    ];
}

- (instancetype)initWithBatchRef:(NSString *)batchRef
                    creditAmount:(NSInteger)creditAmount
                      priceLabel:(NSString *)priceLabel {
    self = [super init];
    if (self) {
        _batchRef = [batchRef copy];
        _creditAmount = creditAmount;
        _priceLabel = [priceLabel copy];
    }
    return self;
}

@end
