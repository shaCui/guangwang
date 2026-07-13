#import "AcapeVaultStore.h"
#import <UIKit/UIKit.h>
@import AVFoundation;

static NSString * const kAcapeLegacyMemberProfileStorageKey = @"AcapeMemberProfileStorageKey";
static NSString * const kAcapeMemberProfileStoragePrefix = @"AcapeMemberProfileStorage.";
static NSString * const kAcapeMemberSignedInKey = @"AcapeMemberSignedInKey";
static NSString * const kAcapeActiveMemberIdentityKey = @"AcapeActiveMemberIdentityKey";
static NSString * const kAcapeCreditBalancePrefix = @"AcapeCreditBalance.";
static NSString * const kAcapeBondingRosterPrefix = @"AcapeBondingRoster.";
static NSString * const kAcapeCurbedRosterPrefix = @"AcapeCurbedRoster.";
static NSString * const kAcapeSignalThreadStoragePrefix = @"AcapeSignalThreads.";
static NSString * const kAcapeMuseConversationStoragePrefix = @"AcapeMuseConversation.";
static NSString * const kAcapeChamberCreatedRoomsPrefix = @"AcapeChamberCreatedRooms.";
static NSString * const kAcapeEchoNotesStorageKey = @"AcapeEchoNotes.ByEntry";
static NSString * const kAcapeEchoNotesLegacyPrefix = @"AcapeEchoNotes.";
static NSString * const kAcapeEchoPrimaryResetKey = @"AcapeEchoPrimaryReset.v1";
static NSString * const kAcapeRemovedMemberIdentitiesKey = @"AcapeRemovedMemberIdentities";
static NSString * const kAcapeAccessCredentialRegistryKey = @"AcapeAccessCredentialRegistry";
static NSString * const kAcapeBuiltinAccessSeedKey = @"AcapeBuiltinAccessSeed.v2";
static NSString * const kAcapeBuiltinCreditSandboxClearKey = @"AcapeBuiltinCreditSandboxClear.v2";
static NSString * const kAcapeBuiltinAccessIdentity = @"acape1122@gmail.com";
static NSString * const kAcapeBuiltinAccessSecret = @"123456";
static NSString * const kAcapeBuiltinAccessPersonaName = @"Charles";
static NSString * const kAcapeBuiltinAccessPersonaAvatar = @"头像1";
static NSString * const kAcapeLocalPortraitAssetName = @"member_local_portrait";
static NSString * const kAcapeLocalPortraitFileName = @"member_local_portrait.png";
static NSString * const kAcapeLocalChamberCoverAssetName = @"chamber_local_cover";

NSNotificationName const AcapeSignalThreadDidUpdateNotification = @"AcapeSignalThreadDidUpdateNotification";

@interface AcapeVaultStore ()
@property (nonatomic, copy) NSString *activeMemberIdentity;
@property (nonatomic, strong) NSMutableArray<AcapeSignalThread *> *mutableSignalThreads;
@property (nonatomic, strong) NSMutableArray<AcapeSocialMember *> *mutableBondingRoster;
@property (nonatomic, strong) NSMutableArray<AcapeSocialMember *> *mutableAdmirerRoster;
@property (nonatomic, strong) NSMutableArray<AcapeSocialMember *> *mutableCurbedRoster;
@property (nonatomic, strong) NSMutableArray<AcapeChamberRoom *> *mutableChamberRooms;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<AcapeEchoComment *> *> *commentsByEntry;
@property (nonatomic, strong) NSCache<NSString *, UIImage *> *clipPreviewCache;
@property (nonatomic, copy) NSArray<AcapeFeedEntry *> *rawCuratedFeedEntries;
@end

@implementation AcapeVaultStore

+ (instancetype)shared {
    static AcapeVaultStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[AcapeVaultStore alloc] init];
        store.clipPreviewCache = [[NSCache alloc] init];
        [store loadInitialData];
    });
    return store;
}

- (void)loadInitialData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _isMemberSignedIn = [defaults boolForKey:kAcapeMemberSignedInKey];
    NSString *storedIdentity = [defaults stringForKey:kAcapeActiveMemberIdentityKey];
    if (_isMemberSignedIn && storedIdentity.length > 0) {
        self.activeMemberIdentity = [self normalizedMemberIdentity:storedIdentity];
        _currentMemberProfile = [self storedProfileForIdentity:self.activeMemberIdentity];
    } else {
        _isMemberSignedIn = NO;
        [defaults setBool:NO forKey:kAcapeMemberSignedInKey];
        _currentMemberProfile = [self starterMemberProfile];
    }

    _entertainmentMemberCount = 736;
    _bonderCount = 336;
    _bondingCount = 20;
    [self loadCuratedFeedEntries];

    [self loadSignalThreads];

    [self loadCreditBalanceForActiveIdentity];

    [self loadChamberRooms];
    [self loadComments];
    [self ensureBuiltinAccessAccounts];
    [self ensureBuiltinTestAccountCreditCleared];
}

- (AcapeMemberProfile *)starterMemberProfile {
    AcapeMemberProfile *profile = [AcapeMemberProfile profileWithMemberId:@"guest"
                                                               displayName:@"Guest"
                                                           avatarAssetName:@"member_default_mark"];
    profile.nickname = @"";
    profile.birthday = @"";
    profile.location = @"";
    profile.gender = @"male";
    profile.profileCompleted = NO;
    return profile;
}

- (AcapeMemberProfile *)freshProfileForIdentity:(NSString *)identity {
    AcapeMemberProfile *profile = [AcapeMemberProfile profileWithMemberId:identity
                                                               displayName:@"Guest"
                                                           avatarAssetName:@"member_default_mark"];
    profile.nickname = @"";
    profile.birthday = @"";
    profile.location = @"";
    profile.gender = @"male";
    profile.profileCompleted = NO;
    return profile;
}

- (NSString *)normalizedMemberIdentity:(NSString *)identity {
    NSString *trimmed = [identity stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].lowercaseString;
    return trimmed.length > 0 ? trimmed : @"guest";
}

- (NSString *)storageTokenForIdentity:(NSString *)identity {
    NSString *normalized = [self normalizedMemberIdentity:identity];
    NSCharacterSet *allowed = [NSCharacterSet alphanumericCharacterSet];
    NSString *encoded = [normalized stringByAddingPercentEncodingWithAllowedCharacters:allowed];
    return encoded.length > 0 ? encoded : @"guest";
}

- (NSString *)profileStorageKeyForIdentity:(NSString *)identity {
    return [kAcapeMemberProfileStoragePrefix stringByAppendingString:[self storageTokenForIdentity:identity]];
}

- (NSString *)creditStorageKeyForIdentity:(NSString *)identity {
    return [kAcapeCreditBalancePrefix stringByAppendingString:[self storageTokenForIdentity:identity]];
}

- (NSString *)bondingRosterStorageKeyForIdentity:(NSString *)identity {
    return [kAcapeBondingRosterPrefix stringByAppendingString:[self storageTokenForIdentity:identity ?: @"guest"]];
}

- (NSString *)activeBondingRosterStorageKey {
    NSString *identity = self.isMemberSignedIn ? self.activeMemberIdentity : @"guest";
    return [self bondingRosterStorageKeyForIdentity:identity];
}

- (NSString *)curbedRosterStorageKeyForIdentity:(NSString *)identity {
    return [kAcapeCurbedRosterPrefix stringByAppendingString:[self storageTokenForIdentity:identity ?: @"guest"]];
}

- (NSString *)activeCurbedRosterStorageKey {
    NSString *identity = self.isMemberSignedIn ? self.activeMemberIdentity : @"guest";
    return [self curbedRosterStorageKeyForIdentity:identity];
}

- (NSString *)signalThreadStorageKeyForIdentity:(NSString *)identity {
    return [kAcapeSignalThreadStoragePrefix stringByAppendingString:[self storageTokenForIdentity:identity ?: @"guest"]];
}

- (NSString *)activeSignalThreadStorageKey {
    NSString *identity = self.isMemberSignedIn ? self.activeMemberIdentity : @"guest";
    return [self signalThreadStorageKeyForIdentity:identity];
}

- (NSString *)museConversationStorageKeyForIdentity:(NSString *)identity {
    return [NSString stringWithFormat:@"%@%@", kAcapeMuseConversationStoragePrefix, [self storageTokenForIdentity:identity]];
}

- (NSString *)activeMuseConversationStorageKey {
    NSString *identity = self.isMemberSignedIn ? self.activeMemberIdentity : @"guest";
    return [self museConversationStorageKeyForIdentity:identity];
}

- (NSString *)chamberCreatedRoomsStorageKeyForIdentity:(NSString *)identity {
    return [kAcapeChamberCreatedRoomsPrefix stringByAppendingString:[self storageTokenForIdentity:identity ?: @"guest"]];
}

- (NSString *)activeChamberCreatedRoomsStorageKey {
    NSString *identity = self.isMemberSignedIn ? self.activeMemberIdentity : @"guest";
    return [self chamberCreatedRoomsStorageKeyForIdentity:identity];
}

- (NSString *)echoNotesStorageKeyForIdentity:(NSString *)identity {
    return [kAcapeEchoNotesLegacyPrefix stringByAppendingString:[self storageTokenForIdentity:identity]];
}

- (NSString *)activeEchoOwnerToken {
    NSString *identity = self.isMemberSignedIn ? self.activeMemberIdentity : @"guest";
    return [self normalizedMemberIdentity:identity];
}

- (AcapeMemberProfile *)storedProfileForIdentity:(NSString *)identity {
    NSString *normalized = [self normalizedMemberIdentity:identity];
    NSData *savedData = [[NSUserDefaults standardUserDefaults] objectForKey:[self profileStorageKeyForIdentity:normalized]];
    if (savedData.length > 0) {
        NSError *error = nil;
        NSSet *classes = [NSSet setWithObjects:AcapeMemberProfile.class, NSString.class, nil];
        AcapeMemberProfile *profile = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:savedData error:&error];
        if (profile && !error) {
            if (profile.memberId.length == 0 || [profile.memberId isEqualToString:@"10001"]) {
                profile.memberId = normalized;
            }
            return profile;
        }
    }
    return [self freshProfileForIdentity:normalized];
}

- (NSInteger)defaultCreditBalanceForIdentity:(NSString *)identity {
    NSString *normalized = [self normalizedMemberIdentity:identity];
    NSString *builtin = [self normalizedMemberIdentity:kAcapeBuiltinAccessIdentity];
    return [normalized isEqualToString:builtin] ? 0 : 500;
}

- (void)loadCreditBalanceForActiveIdentity {
    if (!self.isMemberSignedIn) {
        _creditBalance = 500;
        return;
    }
    NSNumber *storedCredit = [[NSUserDefaults standardUserDefaults] objectForKey:[self creditStorageKeyForIdentity:self.activeMemberIdentity]];
    _creditBalance = storedCredit ? storedCredit.integerValue : [self defaultCreditBalanceForIdentity:self.activeMemberIdentity];
}

- (void)loadCuratedFeedEntries {
    self.rawCuratedFeedEntries = @[
        [AcapeFeedEntry entryWithId:@"feed_1"
                         memberName:@"Charles"
                memberAvatarAssetName:@"头像1"
                         favorCount:(NSInteger)(arc4random_uniform(700) + 200)
               isFavoredByViewer:NO
                        captionText:@"Let me know which lyric hits you the most!"
                  coverImageAssetName:@"harbor_entry_cover_1"
           seekCoverImageAssetName:@"seek_entry_cover_1"
             localClipFileName:@"acapevdis1"
                      coverTopColor:[UIColor colorWithRed:0.45 green:0.28 blue:0.62 alpha:1.0]
                   coverBottomColor:[UIColor colorWithRed:0.18 green:0.12 blue:0.28 alpha:1.0]],
        [AcapeFeedEntry entryWithId:@"feed_2"
                         memberName:@"Kemp"
                memberAvatarAssetName:@"头像2"
                         favorCount:(NSInteger)(arc4random_uniform(700) + 200)
               isFavoredByViewer:NO
                        captionText:@"Woke up with this song stuck in my head, had to record a quick cover right now."
                  coverImageAssetName:@"harbor_entry_cover_2"
           seekCoverImageAssetName:@"harbor_entry_cover_2"
             localClipFileName:@"acapevdis2"
                      coverTopColor:[UIColor colorWithRed:0.18 green:0.30 blue:0.42 alpha:1.0]
                   coverBottomColor:[UIColor colorWithRed:0.05 green:0.08 blue:0.14 alpha:1.0]],
        [AcapeFeedEntry entryWithId:@"feed_3"
                         memberName:@"Shelton"
                memberAvatarAssetName:@"头像3"
                         favorCount:(NSInteger)(arc4random_uniform(700) + 200)
               isFavoredByViewer:NO
                        captionText:@"Random late-night singing session! Turn up your volume and vibe along with me"
                  coverImageAssetName:nil
           seekCoverImageAssetName:nil
             localClipFileName:@"acapevdis3"
                      coverTopColor:[UIColor colorWithRed:0.28 green:0.20 blue:0.38 alpha:1.0]
                   coverBottomColor:[UIColor colorWithRed:0.08 green:0.07 blue:0.13 alpha:1.0]],
        [AcapeFeedEntry entryWithId:@"feed_4"
                         memberName:@"Delia"
                memberAvatarAssetName:@"头像4"
                         favorCount:(NSInteger)(arc4random_uniform(700) + 200)
               isFavoredByViewer:NO
                        captionText:@"Quick little vocal cover for y'all"
                  coverImageAssetName:nil
           seekCoverImageAssetName:nil
             localClipFileName:@"acapevdis4"
                      coverTopColor:[UIColor colorWithRed:0.34 green:0.22 blue:0.30 alpha:1.0]
                   coverBottomColor:[UIColor colorWithRed:0.10 green:0.07 blue:0.10 alpha:1.0]],
        [AcapeFeedEntry entryWithId:@"feed_5"
                         memberName:@"Rosa"
                memberAvatarAssetName:@"头像5"
                         favorCount:(NSInteger)(arc4random_uniform(700) + 200)
               isFavoredByViewer:NO
                        captionText:@"Talking to the Moon"
                  coverImageAssetName:nil
           seekCoverImageAssetName:nil
             localClipFileName:@"acapevdis5"
                      coverTopColor:[UIColor colorWithRed:0.22 green:0.25 blue:0.42 alpha:1.0]
                   coverBottomColor:[UIColor colorWithRed:0.06 green:0.07 blue:0.14 alpha:1.0]],
        [AcapeFeedEntry entryWithId:@"feed_6"
                         memberName:@"Holly"
                memberAvatarAssetName:@"头像6"
                         favorCount:(NSInteger)(arc4random_uniform(700) + 200)
               isFavoredByViewer:NO
                        captionText:@"singing to pumpkin yet again"
                  coverImageAssetName:nil
           seekCoverImageAssetName:nil
             localClipFileName:@"acapevdis6"
                      coverTopColor:[UIColor colorWithRed:0.30 green:0.26 blue:0.18 alpha:1.0]
                   coverBottomColor:[UIColor colorWithRed:0.11 green:0.08 blue:0.05 alpha:1.0]],
    ];
}

- (NSArray<AcapeFeedEntry *> *)curatedFeedEntries {
    NSMutableArray<AcapeFeedEntry *> *visibleEntries = [NSMutableArray array];
    for (AcapeFeedEntry *entry in self.rawCuratedFeedEntries) {
        if (![self isMemberCurbedWithName:entry.memberName]) {
            [visibleEntries addObject:entry];
        }
    }
    return visibleEntries.copy;
}

- (AcapeEchoComment *)curatedEchoWithText:(NSString *)text excludingMemberName:(NSString *)memberName {
    NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *fixedEchoProfiles = @{
        @"charles": @{@"name": @"Rosa", @"avatar": @"头像5"},
        @"kemp": @{@"name": @"Delia", @"avatar": @"头像4"},
        @"shelton": @{@"name": @"Holly", @"avatar": @"头像6"},
        @"delia": @{@"name": @"Charles", @"avatar": @"头像1"},
        @"rosa": @{@"name": @"Kemp", @"avatar": @"头像2"},
        @"holly": @{@"name": @"Shelton", @"avatar": @"头像3"},
    };
    NSDictionary<NSString *, NSString *> *picked = fixedEchoProfiles[memberName.lowercaseString ?: @""];
    if (!picked) {
        picked = @{@"name": @"Charles", @"avatar": @"头像1"};
    }
    return [AcapeEchoComment commentWithAuthor:picked[@"name"] avatar:picked[@"avatar"] text:text];
}

- (void)loadComments {
    [self resetPrimaryEchoNotesIfNeeded];
    self.commentsByEntry = [NSMutableDictionary dictionary];
    for (AcapeFeedEntry *entry in self.rawCuratedFeedEntries) {
        self.commentsByEntry[entry.entryId] = [NSMutableArray array];
    }
    self.commentsByEntry[@"feed_1"] = [@[
        [self curatedEchoWithText:@"Raw vocals hit different" excludingMemberName:@"Charles"]
    ] mutableCopy];
    self.commentsByEntry[@"feed_2"] = [@[
        [self curatedEchoWithText:@"Your voice is literally heaven" excludingMemberName:@"Kemp"]
    ] mutableCopy];
    self.commentsByEntry[@"feed_3"] = [@[
        [self curatedEchoWithText:@"You've got such a memorable voice" excludingMemberName:@"Shelton"]
    ] mutableCopy];
    self.commentsByEntry[@"feed_4"] = [@[
        [self curatedEchoWithText:@"Short but absolutely stunning" excludingMemberName:@"Delia"]
    ] mutableCopy];
    self.commentsByEntry[@"feed_5"] = [@[
        [self curatedEchoWithText:@"This song hits so hard when sung with heart like yours" excludingMemberName:@"Rosa"]
    ] mutableCopy];
    self.commentsByEntry[@"feed_6"] = [@[
        [self curatedEchoWithText:@"Don't ever stop singing, you're insanely talented" excludingMemberName:@"Holly"]
    ] mutableCopy];
    [self restoreEchoNotes];
}

- (void)resetPrimaryEchoNotesIfNeeded {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:kAcapeEchoPrimaryResetKey]) {
        return;
    }
    NSMutableDictionary *storedMap = [[defaults dictionaryForKey:kAcapeEchoNotesStorageKey] mutableCopy];
    if (storedMap[@"feed_1"]) {
        [storedMap removeObjectForKey:@"feed_1"];
        [defaults setObject:storedMap.copy forKey:kAcapeEchoNotesStorageKey];
    }
    NSDictionary *allDefaults = defaults.dictionaryRepresentation;
    for (NSString *key in allDefaults.allKeys) {
        if (![key hasPrefix:kAcapeEchoNotesLegacyPrefix]) {
            continue;
        }
        NSMutableDictionary *legacyMap = [[defaults dictionaryForKey:key] mutableCopy];
        if (legacyMap[@"feed_1"]) {
            [legacyMap removeObjectForKey:@"feed_1"];
            if (legacyMap.count > 0) {
                [defaults setObject:legacyMap.copy forKey:key];
            } else {
                [defaults removeObjectForKey:key];
            }
        }
    }
    [defaults setBool:YES forKey:kAcapeEchoPrimaryResetKey];
    [defaults synchronize];
}

- (void)restoreEchoNotes {
    NSDictionary *storedMap = [self storedEchoNotesByEntry];
    if (![storedMap isKindOfClass:NSDictionary.class]) {
        return;
    }
    [storedMap enumerateKeysAndObjectsUsingBlock:^(NSString *entryId, NSArray *rows, BOOL *stop) {
        if (![entryId isKindOfClass:NSString.class] || ![rows isKindOfClass:NSArray.class]) {
            return;
        }
        NSMutableArray<AcapeEchoComment *> *list = self.commentsByEntry[entryId];
        if (!list) {
            list = [NSMutableArray array];
            self.commentsByEntry[entryId] = list;
        }
        for (NSDictionary *row in rows) {
            if (![row isKindOfClass:NSDictionary.class]) {
                continue;
            }
            NSString *author = [row[@"author"] isKindOfClass:NSString.class] ? row[@"author"] : @"Guest";
            NSString *avatar = [row[@"avatar"] isKindOfClass:NSString.class] ? row[@"avatar"] : nil;
            NSString *text = [row[@"text"] isKindOfClass:NSString.class] ? row[@"text"] : @"";
            if (text.length == 0) {
                continue;
            }
            [list addObject:[AcapeEchoComment commentWithAuthor:author avatar:avatar text:text]];
        }
    }];
}

- (NSDictionary *)storedEchoNotesByEntry {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *storedMap = [[defaults dictionaryForKey:kAcapeEchoNotesStorageKey] mutableCopy] ?: [NSMutableDictionary dictionary];
    NSString *legacyKey = [self echoNotesStorageKeyForIdentity:(self.isMemberSignedIn ? self.activeMemberIdentity : @"guest")];
    NSDictionary *legacyMap = [defaults dictionaryForKey:legacyKey];
    if (legacyMap.count > 0) {
        [legacyMap enumerateKeysAndObjectsUsingBlock:^(NSString *entryId, NSArray *rows, BOOL *stop) {
            if (![entryId isKindOfClass:NSString.class] || ![rows isKindOfClass:NSArray.class]) {
                return;
            }
            NSArray *existingRows = [storedMap[entryId] isKindOfClass:NSArray.class] ? storedMap[entryId] : @[];
            NSMutableArray *mergedRows = [existingRows mutableCopy];
            for (NSDictionary *row in rows) {
                if (![row isKindOfClass:NSDictionary.class]) {
                    continue;
                }
                if (![mergedRows containsObject:row]) {
                    [mergedRows addObject:row];
                }
            }
            storedMap[entryId] = mergedRows.copy;
        }];
        [defaults setObject:storedMap.copy forKey:kAcapeEchoNotesStorageKey];
        [defaults removeObjectForKey:legacyKey];
    }
    return storedMap.copy;
}

- (void)persistEchoNoteText:(NSString *)text entryId:(NSString *)entryId {
    if (text.length == 0 || entryId.length == 0) {
        return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *storedMap = [[defaults dictionaryForKey:kAcapeEchoNotesStorageKey] mutableCopy] ?: [NSMutableDictionary dictionary];
    NSArray *existingRows = [storedMap[entryId] isKindOfClass:NSArray.class] ? storedMap[entryId] : @[];
    NSMutableArray *rows = [existingRows mutableCopy];
    NSDictionary *row = @{
        @"owner": [self activeEchoOwnerToken],
        @"author": self.currentMemberProfile.displayName ?: @"Guest",
        @"avatar": self.currentMemberProfile.avatarAssetName ?: @"",
        @"text": text,
    };
    [rows addObject:row];
    storedMap[entryId] = rows;
    [defaults setObject:storedMap.copy forKey:kAcapeEchoNotesStorageKey];
    [defaults synchronize];
}

- (NSArray<AcapeEchoComment *> *)commentsForEntryId:(NSString *)entryId {
    NSMutableArray<AcapeEchoComment *> *list = self.commentsByEntry[entryId];
    if (!list) {
        list = [NSMutableArray array];
        self.commentsByEntry[entryId] = list;
    }
    NSMutableArray<AcapeEchoComment *> *visibleNotes = [NSMutableArray array];
    for (AcapeEchoComment *item in list) {
        if (![self isMemberCurbedWithName:item.authorName]) {
            [visibleNotes addObject:item];
        }
    }
    return visibleNotes.copy;
}

- (void)addComment:(NSString *)text toEntryId:(NSString *)entryId {
    NSString *trimmed = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmed.length == 0 || entryId.length == 0) {
        return;
    }
    NSMutableArray<AcapeEchoComment *> *list = self.commentsByEntry[entryId];
    if (!list) {
        list = [NSMutableArray array];
        self.commentsByEntry[entryId] = list;
    }
    AcapeEchoComment *comment = [AcapeEchoComment commentWithAuthor:self.currentMemberProfile.displayName
                                                            avatar:self.currentMemberProfile.avatarAssetName
                                                              text:trimmed];
    [list addObject:comment];
    [self persistEchoNoteText:trimmed entryId:entryId];
}

- (void)toggleFavorForEntry:(AcapeFeedEntry *)entry {
    if (!entry) {
        return;
    }
    if (entry.isFavoredByViewer) {
        entry.isFavoredByViewer = NO;
        entry.favorCount = MAX(0, entry.favorCount - 1);
    } else {
        entry.isFavoredByViewer = YES;
        entry.favorCount += 1;
    }
}

- (AcapeChamberRoom *)buildRoomTemplateWithId:(NSString *)roomId name:(NSString *)name cover:(NSString *)cover listeners:(NSInteger)listeners {
    NSInteger totalOccupants = [self chamberOccupantCountForRoomId:roomId];
    NSInteger guestCount = MAX(0, totalOccupants - 1);
    NSArray<NSDictionary *> *guests = [self chamberNpcGuestsForRoomId:roomId count:guestCount];
    NSString *authorName = [self chamberTemplateAuthorNameForRoomId:roomId];

    NSMutableArray<AcapeChamberSeat *> *seats = [NSMutableArray array];
    NSMutableArray<NSString *> *dotAssets = [NSMutableArray arrayWithObjects:cover, nil];

    [seats addObject:[AcapeChamberSeat seatWithName:authorName avatar:cover]];
    for (NSDictionary *guest in guests) {
        [seats addObject:[AcapeChamberSeat seatWithName:guest[@"name"] avatar:guest[@"avatar"]]];
        if (dotAssets.count < 3) {
            [dotAssets addObject:guest[@"avatar"]];
        }
    }
    while (seats.count < 6) {
        [seats addObject:[AcapeChamberSeat seatWithName:nil avatar:nil]];
    }
    return [AcapeChamberRoom roomWithId:roomId
                                  name:name
                        coverAssetName:cover
                         listenerCount:listeners
                       memberDotAssets:dotAssets
                                 seats:seats
                             chatLines:@[]];
}

- (NSArray<NSDictionary *> *)chamberNpcCatalog {
    static NSArray<NSDictionary *> *catalog = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        catalog = @[
            @{@"name": @"Kemp", @"avatar": @"chamber_seat_1"},
            @{@"name": @"Shelton", @"avatar": @"chamber_seat_2"},
            @{@"name": @"Delia", @"avatar": @"chamber_seat_3"},
            @{@"name": @"Rosa", @"avatar": @"chamber_seat_4"},
            @{@"name": @"Holly", @"avatar": @"chamber_seat_5"},
        ];
    });
    return catalog;
}

- (NSUInteger)chamberSeedForRoomId:(NSString *)roomId salt:(NSUInteger)salt {
    NSUInteger seed = salt;
    for (NSUInteger i = 0; i < roomId.length; i++) {
        seed = seed * 31u + [roomId characterAtIndex:i];
    }
    return seed;
}

- (NSInteger)chamberOccupantCountForRoomId:(NSString *)roomId {
    return 3 + (NSInteger)([self chamberSeedForRoomId:roomId salt:431u] % 3);
}

- (NSString *)chamberTemplateAuthorNameForRoomId:(NSString *)roomId {
    if ([roomId isEqualToString:@"room_1"]) {
        return @"Edwin";
    }
    if ([roomId isEqualToString:@"room_2"]) {
        return @"Decklan";
    }
    if ([roomId isEqualToString:@"room_3"]) {
        return @"Ruairi";
    }
    if ([roomId isEqualToString:@"room_4"]) {
        return @"Braydon";
    }
    return @"Garren";
}

- (NSArray<NSDictionary *> *)chamberNpcGuestsForRoomId:(NSString *)roomId count:(NSInteger)count {
    if (count <= 0) {
        return @[];
    }
    NSArray<NSDictionary *> *catalog = [self chamberNpcCatalog];
    NSInteger pickCount = MIN(count, (NSInteger)catalog.count);
    NSMutableIndexSet *usedIndexes = [NSMutableIndexSet indexSet];
    NSMutableArray<NSDictionary *> *guests = [NSMutableArray arrayWithCapacity:(NSUInteger)pickCount];
    for (NSInteger pickIndex = 0; pickIndex < pickCount; pickIndex++) {
        NSUInteger pickSeed = [self chamberSeedForRoomId:roomId salt:(NSUInteger)(911u + pickIndex)];
        NSInteger catalogIndex = (NSInteger)(pickSeed % catalog.count);
        while ([usedIndexes containsIndex:(NSUInteger)catalogIndex]) {
            catalogIndex = (catalogIndex + 1) % (NSInteger)catalog.count;
        }
        [usedIndexes addIndex:(NSUInteger)catalogIndex];
        [guests addObject:catalog[(NSUInteger)catalogIndex]];
    }
    return guests;
}

- (BOOL)isTemplateChamberRoomId:(NSString *)roomId {
    return [roomId isEqualToString:@"room_1"]
        || [roomId isEqualToString:@"room_2"]
        || [roomId isEqualToString:@"room_3"]
        || [roomId isEqualToString:@"room_4"];
}

- (NSDictionary *)serializedChamberRoom:(AcapeChamberRoom *)room {
    NSMutableArray *seatRows = [NSMutableArray arrayWithCapacity:room.seats.count];
    for (AcapeChamberSeat *seat in room.seats) {
        [seatRows addObject:@{
            @"name": seat.occupantName ?: @"",
            @"avatar": seat.avatarAssetName ?: @"",
            @"micLive": @(seat.micLive),
        }];
    }
    NSMutableArray *chatRows = [NSMutableArray arrayWithCapacity:room.chatLines.count];
    for (AcapeChamberChatLine *line in room.chatLines) {
        [chatRows addObject:@{
            @"speaker": line.speakerName ?: @"",
            @"avatar": line.avatarAssetName ?: @"",
            @"text": line.text ?: @"",
        }];
    }
    return @{
        @"id": room.roomId ?: @"",
        @"name": room.name ?: @"",
        @"cover": room.coverAssetName ?: @"",
        @"listeners": @(room.listenerCount),
        @"dots": room.memberDotAssets ?: @[],
        @"seats": seatRows,
        @"chat": chatRows,
    };
}

- (AcapeChamberRoom *)chamberRoomFromSerializedRow:(NSDictionary *)row {
    if (![row isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    NSString *roomId = row[@"id"];
    NSString *name = row[@"name"];
    if (roomId.length == 0 || name.length == 0) {
        return nil;
    }
    NSMutableArray<AcapeChamberSeat *> *seats = [NSMutableArray array];
    for (NSDictionary *seatRow in row[@"seats"]) {
        if (![seatRow isKindOfClass:NSDictionary.class]) {
            continue;
        }
        NSString *occupantName = seatRow[@"name"];
        NSString *avatar = seatRow[@"avatar"];
        if (occupantName.length == 0) {
            [seats addObject:[AcapeChamberSeat seatWithName:nil avatar:nil]];
        } else {
            AcapeChamberSeat *seat = [AcapeChamberSeat seatWithName:occupantName avatar:avatar.length > 0 ? avatar : nil];
            seat.micLive = [seatRow[@"micLive"] boolValue];
            [seats addObject:seat];
        }
    }
    while (seats.count < 6) {
        [seats addObject:[AcapeChamberSeat seatWithName:nil avatar:nil]];
    }
    NSMutableArray<AcapeChamberChatLine *> *chatLines = [NSMutableArray array];
    for (NSDictionary *chatRow in row[@"chat"]) {
        if (![chatRow isKindOfClass:NSDictionary.class]) {
            continue;
        }
        NSString *speaker = chatRow[@"speaker"];
        NSString *text = chatRow[@"text"];
        if (speaker.length == 0 || text.length == 0) {
            continue;
        }
        [chatLines addObject:[AcapeChamberChatLine lineWithSpeaker:speaker
                                                            avatar:chatRow[@"avatar"]
                                                              text:text]];
    }
    NSArray<NSString *> *dotAssets = row[@"dots"];
    if (![dotAssets isKindOfClass:NSArray.class]) {
        dotAssets = @[];
    }
    return [AcapeChamberRoom roomWithId:roomId
                                   name:name
                         coverAssetName:row[@"cover"]
                          listenerCount:[row[@"listeners"] integerValue]
                        memberDotAssets:dotAssets
                                  seats:seats
                              chatLines:chatLines];
}

- (NSArray<AcapeChamberRoom *> *)restoredMemberChamberRooms {
    NSArray *savedRows = [[NSUserDefaults standardUserDefaults] arrayForKey:[self activeChamberCreatedRoomsStorageKey]];
    if (savedRows.count == 0) {
        return @[];
    }
    NSMutableArray<AcapeChamberRoom *> *rooms = [NSMutableArray arrayWithCapacity:savedRows.count];
    for (NSDictionary *row in savedRows) {
        AcapeChamberRoom *room = [self chamberRoomFromSerializedRow:row];
        if (room && ![self isTemplateChamberRoomId:room.roomId]) {
            [rooms addObject:room];
        }
    }
    return rooms;
}

- (void)persistMemberChamberRooms {
    NSMutableArray *rows = [NSMutableArray array];
    for (AcapeChamberRoom *room in self.mutableChamberRooms) {
        if ([self isTemplateChamberRoomId:room.roomId]) {
            continue;
        }
        [rows addObject:[self serializedChamberRoom:room]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:rows.copy forKey:[self activeChamberCreatedRoomsStorageKey]];
}

- (void)removePersistedChamberRoomsForIdentity:(NSString *)identity {
    NSString *storageKey = [self chamberCreatedRoomsStorageKeyForIdentity:identity];
    NSArray *savedRows = [[NSUserDefaults standardUserDefaults] arrayForKey:storageKey];
    for (NSDictionary *row in savedRows) {
        NSString *roomId = row[@"id"];
        if (roomId.length > 0) {
            [[NSFileManager defaultManager] removeItemAtURL:[self localChamberCoverURLForRoomId:roomId] error:nil];
        }
    }
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:storageKey];
}

- (void)loadChamberRooms {
    NSMutableArray<AcapeChamberRoom *> *rooms = [NSMutableArray arrayWithArray:@[
        [self buildRoomTemplateWithId:@"room_1" name:@"Beat Hangout" cover:@"roma1" listeners:414],
        [self buildRoomTemplateWithId:@"room_2" name:@"Vibe Lounge" cover:@"roma2" listeners:286],
        [self buildRoomTemplateWithId:@"room_3" name:@"Audio Squad" cover:@"roma3" listeners:531],
        [self buildRoomTemplateWithId:@"room_4" name:@"Melody Crew" cover:@"roma4" listeners:178],
    ]];
    for (AcapeChamberRoom *room in [[self restoredMemberChamberRooms] reverseObjectEnumerator]) {
        [rooms insertObject:room atIndex:0];
    }
    self.mutableChamberRooms = rooms;
}

- (NSArray<AcapeChamberRoom *> *)chamberRooms {
    NSMutableArray<AcapeChamberRoom *> *visible = [NSMutableArray array];
    for (AcapeChamberRoom *room in self.mutableChamberRooms) {
        NSString *hostName = [self chamberHostNameForRoom:room];
        if (hostName.length > 0 && [self isMemberCurbedWithName:hostName]) {
            continue;
        }
        [visible addObject:room];
    }
    return visible.copy;
}

- (NSString *)chamberHostNameForRoom:(AcapeChamberRoom *)room {
    if (room.seats.count == 0) {
        return @"";
    }
    return room.seats.firstObject.occupantName ?: @"";
}

- (NSString *)chamberHostAvatarAssetNameForRoom:(AcapeChamberRoom *)room {
    if (room.seats.count == 0) {
        return room.coverAssetName ?: @"member_default_mark";
    }
    AcapeChamberSeat *hostSeat = room.seats.firstObject;
    if (hostSeat.avatarAssetName.length > 0) {
        return hostSeat.avatarAssetName;
    }
    return room.coverAssetName ?: @"member_default_mark";
}

- (BOOL)isMemberOwnedChamberRoom:(AcapeChamberRoom *)room {
    if (!room || [self isTemplateChamberRoomId:room.roomId]) {
        return NO;
    }
    NSString *hostName = [self chamberHostNameForRoom:room];
    NSString *memberName = self.currentMemberProfile.displayName;
    return hostName.length > 0 && memberName.length > 0 && [hostName isEqualToString:memberName];
}

- (AcapeChamberRoom *)createChamberRoomWithName:(NSString *)name {
    return [self createChamberRoomWithName:name coverAssetName:nil];
}

- (AcapeChamberRoom *)createChamberRoomWithName:(NSString *)name coverAssetName:(NSString *)coverAssetName {
    NSString *roomName = [name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (roomName.length == 0) {
        roomName = @"My Live Room";
    }
    NSString *roomId = [NSString stringWithFormat:@"room_%@", @([NSDate date].timeIntervalSince1970)];
    NSString *cover = coverAssetName.length > 0 ? coverAssetName : @"roma1";
    AcapeChamberRoom *room = [self buildRoomTemplateWithId:roomId name:roomName cover:cover listeners:1];
    // A freshly created room seats the host and starts with no guests.
    room.seats = [@[
        [AcapeChamberSeat seatWithName:self.currentMemberProfile.displayName avatar:self.currentMemberProfile.avatarAssetName],
        [AcapeChamberSeat seatWithName:nil avatar:nil],
        [AcapeChamberSeat seatWithName:nil avatar:nil],
        [AcapeChamberSeat seatWithName:nil avatar:nil],
        [AcapeChamberSeat seatWithName:nil avatar:nil],
        [AcapeChamberSeat seatWithName:nil avatar:nil],
    ] mutableCopy];
    room.memberDotAssets = @[[self resolvedAvatarAssetName:self.currentMemberProfile.avatarAssetName]];
    room.chatLines = [NSMutableArray array];
    [self.mutableChamberRooms insertObject:room atIndex:0];
    [self persistMemberChamberRooms];
    return room;
}

- (UIImage *)chamberCoverImageForRoom:(AcapeChamberRoom *)room {
    if (!room) {
        return [UIImage imageNamed:@"roma1"];
    }
    if ([room.coverAssetName isEqualToString:kAcapeLocalChamberCoverAssetName]) {
        UIImage *image = [UIImage imageWithContentsOfFile:[self localChamberCoverURLForRoomId:room.roomId].path];
        if (image) {
            return image;
        }
    }
    return [UIImage imageNamed:room.coverAssetName ?: @"roma1"];
}

- (BOOL)persistChamberCoverImage:(UIImage *)image forRoomId:(NSString *)roomId {
    if (!image || roomId.length == 0) {
        return NO;
    }
    NSData *data = UIImagePNGRepresentation(image);
    if (!data) {
        data = UIImageJPEGRepresentation(image, 0.88);
    }
    if (!data) {
        return NO;
    }
    NSURL *directoryURL = [self chamberCoverDirectoryURL];
    [[NSFileManager defaultManager] createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:nil];
    return [data writeToURL:[self localChamberCoverURLForRoomId:roomId] atomically:YES];
}

- (NSURL *)chamberCoverDirectoryURL {
    NSURL *documentsURL = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    return [documentsURL URLByAppendingPathComponent:@"ChamberCovers" isDirectory:YES];
}

- (NSURL *)localChamberCoverURLForRoomId:(NSString *)roomId {
    NSString *fileName = [NSString stringWithFormat:@"chamber_cover_%@.png", roomId];
    return [[self chamberCoverDirectoryURL] URLByAppendingPathComponent:fileName];
}

- (void)appendChatLine:(NSString *)text toRoom:(AcapeChamberRoom *)room {
    NSString *trimmed = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmed.length == 0 || !room) {
        return;
    }
    AcapeChamberChatLine *line = [AcapeChamberChatLine lineWithSpeaker:self.currentMemberProfile.displayName
                                                                avatar:self.currentMemberProfile.avatarAssetName
                                                                  text:trimmed];
    [room.chatLines addObject:line];
    if (![self isTemplateChamberRoomId:room.roomId]) {
        [self persistMemberChamberRooms];
    }
}

- (void)rechargeCredits:(NSInteger)amount {
    if (amount <= 0) {
        return;
    }
    [self syncCreditBalance:_creditBalance + amount];
}

- (void)syncCreditBalance:(NSInteger)balance {
    _creditBalance = MAX(0, balance);
    if (self.isMemberSignedIn) {
        [[NSUserDefaults standardUserDefaults] setInteger:_creditBalance forKey:[self creditStorageKeyForIdentity:self.activeMemberIdentity]];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (BOOL)canAffordCredits:(NSInteger)amount {
    return _creditBalance >= amount;
}

- (BOOL)spendCredits:(NSInteger)amount {
    if (amount <= 0 || _creditBalance < amount) {
        return NO;
    }
    [self syncCreditBalance:_creditBalance - amount];
    return YES;
}

- (void)loadSignalThreads {
    self.mutableSignalThreads = [NSMutableArray array];
    [self restoreSignalThreadsIfNeeded];
    [self loadSocialRosters];
}

- (void)loadSocialRosters {
    self.mutableBondingRoster = [NSMutableArray array];
    self.mutableAdmirerRoster = [NSMutableArray array];
    self.mutableCurbedRoster = [NSMutableArray array];
    [self restoreBondingRosterIfNeeded];
    [self restoreCurbedRosterIfNeeded];
    [self loadAdmirerRoster];
    _bondingCount = self.mutableBondingRoster.count;
    _bonderCount = self.mutableAdmirerRoster.count;
}

- (NSArray<AcapeSocialMember *> *)bondingRoster {
    return self.mutableBondingRoster.copy;
}

- (NSArray<AcapeSocialMember *> *)admirerRoster {
    NSMutableArray<AcapeSocialMember *> *visibleRoster = [NSMutableArray array];
    for (AcapeSocialMember *member in self.mutableAdmirerRoster) {
        if ([self isMemberCurbedWithName:member.displayName]) {
            continue;
        }
        member.bonded = [self hasBondWithMemberName:member.displayName];
        [visibleRoster addObject:member];
    }
    return visibleRoster.copy;
}

- (NSArray<AcapeSocialMember *> *)curbedRoster {
    return self.mutableCurbedRoster.copy;
}

- (void)loadAdmirerRoster {
    NSArray<NSDictionary<NSString *, NSString *> *> *rows = @[
        @{@"name": @"Charles", @"avatar": @"头像1"},
        @{@"name": @"Kemp", @"avatar": @"头像2"},
        @{@"name": @"Delia", @"avatar": @"头像4"},
        @{@"name": @"Rosa", @"avatar": @"头像5"},
    ];
    NSMutableArray<AcapeSocialMember *> *roster = [NSMutableArray arrayWithCapacity:rows.count];
    for (NSUInteger index = 0; index < rows.count; index++) {
        NSDictionary<NSString *, NSString *> *row = rows[index];
        NSString *name = row[@"name"];
        NSString *avatar = row[@"avatar"];
        if ([self isMemberCurbedWithName:name]) {
            continue;
        }
        NSString *memberId = [NSString stringWithFormat:@"m_admirer_%lu", (unsigned long)(index + 1)];
        [roster addObject:[AcapeSocialMember memberWithId:memberId
                                               displayName:name
                                           avatarAssetName:avatar
                                                    bonded:[self hasBondWithMemberName:name]]];
    }
    self.mutableAdmirerRoster = roster;
}

- (NSArray<AcapeSocialMember *> *)bondingRosterForMemberName:(NSString *)name {
    return [self derivedMemberRosterForName:name salt:17 bonded:YES];
}

- (NSArray<AcapeSocialMember *> *)bonderRosterForMemberName:(NSString *)name {
    return [self derivedMemberRosterForName:name salt:43 bonded:NO];
}

- (NSArray<AcapeSocialMember *> *)derivedMemberRosterForName:(NSString *)name salt:(NSUInteger)salt bonded:(BOOL)bonded {
    NSString *target = name.lowercaseString ?: @"";
    if (target.length == 0) {
        return @[];
    }

    NSMutableArray<AcapeFeedEntry *> *pool = [NSMutableArray array];
    NSMutableSet<NSString *> *seenNames = [NSMutableSet set];
    for (AcapeFeedEntry *entry in self.rawCuratedFeedEntries) {
        NSString *normalized = entry.memberName.lowercaseString ?: @"";
        if (normalized.length == 0 || [normalized isEqualToString:target] || [seenNames containsObject:normalized]) {
            continue;
        }
        if ([self isMemberCurbedWithName:entry.memberName]) {
            continue;
        }
        [seenNames addObject:normalized];
        [pool addObject:entry];
    }
    if (pool.count == 0) {
        return @[];
    }

    NSUInteger value = [self stableValueForText:target salt:salt];
    NSUInteger count = value % pool.count + 1;
    NSUInteger start = (value / 7) % pool.count;
    NSMutableArray<AcapeSocialMember *> *roster = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger index = 0; index < count; index++) {
        AcapeFeedEntry *entry = pool[(start + index) % pool.count];
        NSString *memberId = [NSString stringWithFormat:@"m_%lu_%@", (unsigned long)salt, entry.entryId ?: entry.memberName];
        [roster addObject:[AcapeSocialMember memberWithId:memberId
                                               displayName:entry.memberName
                                           avatarAssetName:entry.memberAvatarAssetName
                                                    bonded:bonded]];
    }
    return roster.copy;
}

- (NSUInteger)stableValueForText:(NSString *)text salt:(NSUInteger)salt {
    NSUInteger value = 2166136261u ^ salt;
    for (NSUInteger index = 0; index < text.length; index++) {
        value ^= [text characterAtIndex:index];
        value *= 16777619u;
    }
    return value;
}

- (BOOL)hasBondWithMemberName:(NSString *)name {
    if (name.length == 0) {
        return NO;
    }
    NSString *target = name.lowercaseString;
    for (AcapeSocialMember *item in self.mutableBondingRoster) {
        if (item.bonded && [item.displayName.lowercaseString isEqualToString:target]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)toggleBondWithMemberName:(NSString *)name avatarAssetName:(NSString *)avatar {
    if (name.length == 0) {
        return NO;
    }
    NSString *target = name.lowercaseString;
    for (AcapeSocialMember *item in self.mutableBondingRoster.copy) {
        if ([item.displayName.lowercaseString isEqualToString:target]) {
            [self.mutableBondingRoster removeObject:item];
            _bondingCount = self.mutableBondingRoster.count;
            [self persistBondingRoster];
            return NO;
        }
    }

    NSString *memberId = [NSString stringWithFormat:@"m_bond_%@", @((NSInteger)(NSDate.date.timeIntervalSince1970 * 1000.0))];
    AcapeSocialMember *member = [AcapeSocialMember memberWithId:memberId displayName:name avatarAssetName:avatar bonded:YES];
    [self.mutableBondingRoster insertObject:member atIndex:0];
    _bondingCount = self.mutableBondingRoster.count;
    [self persistBondingRoster];
    return YES;
}

- (void)toggleBondForMember:(AcapeSocialMember *)member {
    if (member.displayName.length == 0) {
        return;
    }
    NSString *target = member.displayName.lowercaseString;
    for (AcapeSocialMember *item in self.mutableBondingRoster.copy) {
        if ([item.displayName.lowercaseString isEqualToString:target]) {
            [self.mutableBondingRoster removeObject:item];
            member.bonded = NO;
            _bondingCount = self.mutableBondingRoster.count;
            [self persistBondingRoster];
            return;
        }
    }

    NSString *memberId = [NSString stringWithFormat:@"m_bond_%@", @((NSInteger)(NSDate.date.timeIntervalSince1970 * 1000.0))];
    AcapeSocialMember *savedMember = [AcapeSocialMember memberWithId:memberId
                                                         displayName:member.displayName
                                                     avatarAssetName:member.avatarAssetName
                                                              bonded:YES];
    [self.mutableBondingRoster insertObject:savedMember atIndex:0];
    member.bonded = YES;
    _bondingCount = self.mutableBondingRoster.count;
    [self persistBondingRoster];
}

- (void)removeCurbedMember:(AcapeSocialMember *)member {
    [self.mutableCurbedRoster removeObject:member];
    [self persistCurbedRoster];
}

- (void)addCurbedMemberWithName:(NSString *)name avatarAssetName:(NSString *)avatar {
    if (name.length == 0) {
        return;
    }
    for (AcapeSocialMember *existing in self.mutableCurbedRoster) {
        if ([existing.displayName.lowercaseString isEqualToString:name.lowercaseString]) {
            return;
        }
    }
    NSString *memberId = [NSString stringWithFormat:@"m_curb_%@", @((NSInteger)(NSDate.date.timeIntervalSince1970 * 1000.0))];
    AcapeSocialMember *member = [AcapeSocialMember memberWithId:memberId displayName:name avatarAssetName:avatar bonded:NO];
    [self.mutableCurbedRoster insertObject:member atIndex:0];
    [self persistCurbedRoster];
}

- (BOOL)isMemberCurbedWithName:(NSString *)name {
    if (name.length == 0) {
        return NO;
    }
    NSString *normalizedName = name.lowercaseString;
    for (AcapeSocialMember *item in self.mutableCurbedRoster) {
        if ([item.displayName.lowercaseString isEqualToString:normalizedName]) {
            return YES;
        }
    }
    return NO;
}

- (void)restoreBondingRosterIfNeeded {
    NSArray *savedRows = [[NSUserDefaults standardUserDefaults] arrayForKey:[self activeBondingRosterStorageKey]];
    if (![savedRows isKindOfClass:NSArray.class] || savedRows.count == 0) {
        return;
    }
    NSMutableArray<AcapeSocialMember *> *restored = [NSMutableArray array];
    for (NSDictionary *row in savedRows) {
        if (![row isKindOfClass:NSDictionary.class]) {
            continue;
        }
        NSString *memberId = [row[@"memberId"] isKindOfClass:NSString.class] ? row[@"memberId"] : @"m_bond_saved";
        NSString *name = [row[@"name"] isKindOfClass:NSString.class] ? row[@"name"] : @"";
        NSString *avatar = [row[@"avatar"] isKindOfClass:NSString.class] ? row[@"avatar"] : nil;
        NSNumber *bonded = [row[@"bonded"] isKindOfClass:NSNumber.class] ? row[@"bonded"] : @YES;
        if (name.length == 0) {
            continue;
        }
        if (![memberId hasPrefix:@"m_bond_"]) {
            continue;
        }
        [restored addObject:[AcapeSocialMember memberWithId:memberId displayName:name avatarAssetName:avatar bonded:bonded.boolValue]];
    }
    if (restored.count > 0) {
        self.mutableBondingRoster = restored;
    }
    _bondingCount = self.mutableBondingRoster.count;
}

- (void)persistBondingRoster {
    NSMutableArray *rows = [NSMutableArray array];
    for (AcapeSocialMember *item in self.mutableBondingRoster) {
        if (item.displayName.length == 0) {
            continue;
        }
        [rows addObject:@{
            @"memberId": item.memberId ?: @"",
            @"name": item.displayName ?: @"",
            @"avatar": item.avatarAssetName ?: @"",
            @"bonded": @(item.bonded),
        }];
    }
    [[NSUserDefaults standardUserDefaults] setObject:rows.copy forKey:[self activeBondingRosterStorageKey]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)restoreCurbedRosterIfNeeded {
    NSArray *savedRows = [[NSUserDefaults standardUserDefaults] arrayForKey:[self activeCurbedRosterStorageKey]];
    if (![savedRows isKindOfClass:NSArray.class] || savedRows.count == 0) {
        return;
    }
    NSMutableArray<AcapeSocialMember *> *restored = [NSMutableArray array];
    for (NSDictionary *row in savedRows) {
        if (![row isKindOfClass:NSDictionary.class]) {
            continue;
        }
        NSString *memberId = [row[@"memberId"] isKindOfClass:NSString.class] ? row[@"memberId"] : @"m_curb_saved";
        NSString *name = [row[@"name"] isKindOfClass:NSString.class] ? row[@"name"] : @"";
        NSString *avatar = [row[@"avatar"] isKindOfClass:NSString.class] ? row[@"avatar"] : nil;
        if (name.length == 0) {
            continue;
        }
        if (![memberId hasPrefix:@"m_curb_"]) {
            continue;
        }
        [restored addObject:[AcapeSocialMember memberWithId:memberId displayName:name avatarAssetName:avatar bonded:NO]];
    }
    if (restored.count > 0) {
        self.mutableCurbedRoster = restored;
    }
}

- (void)persistCurbedRoster {
    NSMutableArray *rows = [NSMutableArray array];
    for (AcapeSocialMember *item in self.mutableCurbedRoster) {
        if (item.displayName.length == 0) {
            continue;
        }
        [rows addObject:@{
            @"memberId": item.memberId ?: @"",
            @"name": item.displayName ?: @"",
            @"avatar": item.avatarAssetName ?: @"",
        }];
    }
    [[NSUserDefaults standardUserDefaults] setObject:rows.copy forKey:[self activeCurbedRosterStorageKey]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)restoreSignalThreadsIfNeeded {
    NSArray *rows = [[NSUserDefaults standardUserDefaults] arrayForKey:[self activeSignalThreadStorageKey]];
    if (![rows isKindOfClass:NSArray.class]) {
        return;
    }

    NSMutableArray<AcapeSignalThread *> *restored = [NSMutableArray array];
    for (NSDictionary *row in rows) {
        if (![row isKindOfClass:NSDictionary.class]) {
            continue;
        }
        NSString *threadId = [row[@"threadId"] isKindOfClass:NSString.class] ? row[@"threadId"] : nil;
        NSString *memberName = [row[@"memberName"] isKindOfClass:NSString.class] ? row[@"memberName"] : @"";
        NSString *avatar = [row[@"avatar"] isKindOfClass:NSString.class] ? row[@"avatar"] : nil;
        NSString *preview = [row[@"preview"] isKindOfClass:NSString.class] ? row[@"preview"] : @"";
        NSString *timeText = [row[@"time"] isKindOfClass:NSString.class] ? row[@"time"] : @"";
        NSNumber *unread = [row[@"unread"] isKindOfClass:NSNumber.class] ? row[@"unread"] : @0;
        NSArray *noteRows = [row[@"notes"] isKindOfClass:NSArray.class] ? row[@"notes"] : @[];
        if (threadId.length == 0 || memberName.length == 0) {
            continue;
        }

        NSMutableArray<AcapeSignalMessage *> *notes = [NSMutableArray array];
        for (NSDictionary *noteRow in noteRows) {
            if (![noteRow isKindOfClass:NSDictionary.class]) {
                continue;
            }
            NSString *noteId = [noteRow[@"noteId"] isKindOfClass:NSString.class] ? noteRow[@"noteId"] : @"";
            NSString *body = [noteRow[@"body"] isKindOfClass:NSString.class] ? noteRow[@"body"] : @"";
            NSString *noteTime = [noteRow[@"time"] isKindOfClass:NSString.class] ? noteRow[@"time"] : @"";
            NSNumber *kind = [noteRow[@"kind"] isKindOfClass:NSNumber.class] ? noteRow[@"kind"] : @0;
            NSNumber *viewer = [noteRow[@"viewer"] isKindOfClass:NSNumber.class] ? noteRow[@"viewer"] : @NO;
            NSNumber *seconds = [noteRow[@"seconds"] isKindOfClass:NSNumber.class] ? noteRow[@"seconds"] : @0;
            NSString *voiceFile = [noteRow[@"voiceFile"] isKindOfClass:NSString.class] ? noteRow[@"voiceFile"] : nil;
            AcapeSignalMessage *note = nil;
            if (kind.unsignedIntegerValue == AcapeSignalMessageKindVoice) {
                note = [AcapeSignalMessage voiceMessageWithId:noteId seconds:seconds.integerValue fromViewer:viewer.boolValue timeText:noteTime];
                note.voiceFileName = voiceFile;
            } else {
                note = [AcapeSignalMessage textMessageWithId:noteId body:body fromViewer:viewer.boolValue timeText:noteTime];
            }
            if (note) {
                [notes addObject:note];
            }
        }

        AcapeSignalThread *thread = [AcapeSignalThread threadWithId:threadId
                                                         memberName:memberName
                                                    avatarAssetName:avatar
                                                        previewText:preview
                                                           timeText:timeText
                                                        unreadCount:unread.integerValue
                                                           messages:notes];
        [restored addObject:thread];
    }
    self.mutableSignalThreads = restored;
}

- (void)persistSignalThreads {
    NSMutableArray *rows = [NSMutableArray array];
    for (AcapeSignalThread *thread in self.mutableSignalThreads) {
        if (thread.threadId.length == 0 || thread.memberName.length == 0 || thread.messages.count == 0) {
            continue;
        }
        NSMutableArray *noteRows = [NSMutableArray array];
        for (AcapeSignalMessage *note in thread.messages) {
            [noteRows addObject:@{
                @"noteId": note.messageId ?: @"",
                @"kind": @(note.kind),
                @"body": note.body ?: @"",
                @"viewer": @(note.fromViewer),
                @"time": note.timeText ?: @"",
                @"seconds": @(note.voiceSeconds),
                @"voiceFile": note.voiceFileName ?: @"",
            }];
        }
        [rows addObject:@{
            @"threadId": thread.threadId ?: @"",
            @"memberName": thread.memberName ?: @"",
            @"avatar": thread.avatarAssetName ?: @"",
            @"preview": thread.previewText ?: @"",
            @"time": thread.timeText ?: @"",
            @"unread": @(thread.unreadCount),
            @"notes": noteRows.copy,
        }];
    }
    [[NSUserDefaults standardUserDefaults] setObject:rows.copy forKey:[self activeSignalThreadStorageKey]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray<AcapeSignalMessage *> *)museConversationMessages {
    NSDictionary *stored = [[NSUserDefaults standardUserDefaults] dictionaryForKey:[self activeMuseConversationStorageKey]];
    if (![stored isKindOfClass:NSDictionary.class]) {
        return @[];
    }
    NSArray *noteRows = [stored[@"notes"] isKindOfClass:NSArray.class] ? stored[@"notes"] : @[];
    NSMutableArray<AcapeSignalMessage *> *messages = [NSMutableArray array];
    for (NSDictionary *noteRow in noteRows) {
        if (![noteRow isKindOfClass:NSDictionary.class]) {
            continue;
        }
        NSString *noteId = [noteRow[@"noteId"] isKindOfClass:NSString.class] ? noteRow[@"noteId"] : @"";
        NSString *body = [noteRow[@"body"] isKindOfClass:NSString.class] ? noteRow[@"body"] : @"";
        NSString *noteTime = [noteRow[@"time"] isKindOfClass:NSString.class] ? noteRow[@"time"] : @"";
        NSNumber *viewer = [noteRow[@"viewer"] isKindOfClass:NSNumber.class] ? noteRow[@"viewer"] : @NO;
        if (noteId.length == 0) {
            continue;
        }
        AcapeSignalMessage *message = [AcapeSignalMessage textMessageWithId:noteId body:body fromViewer:viewer.boolValue timeText:noteTime];
        [messages addObject:message];
    }
    return messages.copy;
}

- (NSInteger)museConversationReplyCursor {
    NSDictionary *stored = [[NSUserDefaults standardUserDefaults] dictionaryForKey:[self activeMuseConversationStorageKey]];
    if (![stored isKindOfClass:NSDictionary.class]) {
        return 0;
    }
    NSNumber *cursor = [stored[@"replyCursor"] isKindOfClass:NSNumber.class] ? stored[@"replyCursor"] : @0;
    return cursor.integerValue;
}

- (BOOL)museConversationSessionPaid {
    NSDictionary *stored = [[NSUserDefaults standardUserDefaults] dictionaryForKey:[self activeMuseConversationStorageKey]];
    if (![stored isKindOfClass:NSDictionary.class]) {
        return NO;
    }
    NSNumber *paid = [stored[@"sessionPaid"] isKindOfClass:NSNumber.class] ? stored[@"sessionPaid"] : @NO;
    return paid.boolValue;
}

- (void)persistMuseConversationMessages:(NSArray<AcapeSignalMessage *> *)messages
                            replyCursor:(NSInteger)replyCursor
                            sessionPaid:(BOOL)sessionPaid {
    NSMutableArray *noteRows = [NSMutableArray array];
    for (AcapeSignalMessage *note in messages) {
        if (note.messageId.length == 0) {
            continue;
        }
        [noteRows addObject:@{
            @"noteId": note.messageId ?: @"",
            @"body": note.body ?: @"",
            @"viewer": @(note.fromViewer),
            @"time": note.timeText ?: @"",
        }];
    }
    NSDictionary *payload = @{
        @"notes": noteRows.copy,
        @"replyCursor": @(replyCursor),
        @"sessionPaid": @(sessionPaid),
    };
    [[NSUserDefaults standardUserDefaults] setObject:payload forKey:[self activeMuseConversationStorageKey]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)resetMuseSessionUnlock {
    [self clearMuseConversation];
}

- (void)clearMuseConversation {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[self activeMuseConversationStorageKey]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)bringSignalThreadForward:(AcapeSignalThread *)thread {
    if (!thread) {
        return;
    }
    NSUInteger foundIndex = NSNotFound;
    for (NSUInteger index = 0; index < self.mutableSignalThreads.count; index++) {
        AcapeSignalThread *item = self.mutableSignalThreads[index];
        if (item == thread || [item.threadId isEqualToString:thread.threadId]) {
            foundIndex = index;
            break;
        }
    }
    if (foundIndex != NSNotFound) {
        [self.mutableSignalThreads removeObjectAtIndex:foundIndex];
    }
    [self.mutableSignalThreads insertObject:thread atIndex:0];
}

- (void)emitSignalThreadDidUpdate:(AcapeSignalThread *)thread {
    [[NSNotificationCenter defaultCenter] postNotificationName:AcapeSignalThreadDidUpdateNotification object:thread];
}

- (NSArray<AcapeSignalThread *> *)signalThreads {
    return self.mutableSignalThreads.copy;
}

- (void)appendViewerText:(NSString *)text toThread:(AcapeSignalThread *)thread {
    NSString *trimmed = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmed.length == 0 || !thread) {
        return;
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"h:mm a";
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    NSString *stamp = [formatter stringFromDate:[NSDate date]];
    NSString *messageId = [NSString stringWithFormat:@"%@_%@", thread.threadId, @([NSDate date].timeIntervalSince1970)];
    AcapeSignalMessage *message = [AcapeSignalMessage textMessageWithId:messageId body:trimmed fromViewer:YES timeText:stamp];
    [thread.messages addObject:message];
    thread.previewText = trimmed;
    thread.timeText = stamp;
    [self bringSignalThreadForward:thread];
    [self persistSignalThreads];
    [self emitSignalThreadDidUpdate:thread];
}

- (void)appendViewerVoiceSeconds:(NSInteger)seconds toThread:(AcapeSignalThread *)thread {
    [self appendViewerVoiceSeconds:seconds fileName:nil toThread:thread];
}

- (void)appendViewerVoiceSeconds:(NSInteger)seconds fileName:(NSString *)fileName toThread:(AcapeSignalThread *)thread {
    if (seconds <= 0 || !thread) {
        return;
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"h:mm a";
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    NSString *stamp = [formatter stringFromDate:[NSDate date]];
    NSString *messageId = [NSString stringWithFormat:@"%@_v%@", thread.threadId, @([NSDate date].timeIntervalSince1970)];
    AcapeSignalMessage *message = [AcapeSignalMessage voiceMessageWithId:messageId seconds:seconds fromViewer:YES timeText:stamp];
    message.voiceFileName = fileName;
    [thread.messages addObject:message];
    thread.previewText = [NSString stringWithFormat:@"[Voice] 0:%02ld", (long)seconds];
    thread.timeText = stamp;
    [self bringSignalThreadForward:thread];
    [self persistSignalThreads];
    [self emitSignalThreadDidUpdate:thread];
}

- (void)markThreadRead:(AcapeSignalThread *)thread {
    thread.unreadCount = 0;
    [self persistSignalThreads];
    [self emitSignalThreadDidUpdate:thread];
}

- (AcapeSignalThread *)signalThreadForMemberName:(NSString *)name avatarAssetName:(NSString *)avatar {
    NSString *trimmed = [name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmed.length == 0) {
        trimmed = @"Member";
    }
    NSString *target = trimmed.lowercaseString;
    for (AcapeSignalThread *thread in self.mutableSignalThreads) {
        if ([thread.memberName.lowercaseString isEqualToString:target]) {
            return thread;
        }
    }

    NSString *threadId = [NSString stringWithFormat:@"thread_%lu", (unsigned long)[self stableValueForText:target salt:79]];
    AcapeSignalThread *thread = [AcapeSignalThread threadWithId:threadId
                                                     memberName:trimmed
                                                avatarAssetName:avatar
                                                    previewText:@""
                                                       timeText:@""
                                                    unreadCount:0
                                                       messages:@[]];
    [self.mutableSignalThreads insertObject:thread atIndex:0];
    return thread;
}

- (void)markMemberSignedIn {
    [self markMemberSignedInWithIdentity:self.activeMemberIdentity ?: self.currentMemberProfile.memberId];
}

- (void)markMemberSignedInWithIdentity:(NSString *)identity {
    NSString *normalizedIdentity = [self normalizedMemberIdentity:identity];
    if ([self isIdentityAccessRevoked:normalizedIdentity]) {
        return;
    }
    self.activeMemberIdentity = normalizedIdentity;
    _isMemberSignedIn = YES;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:kAcapeMemberSignedInKey];
    [defaults setObject:self.activeMemberIdentity forKey:kAcapeActiveMemberIdentityKey];
    _currentMemberProfile = [self storedProfileForIdentity:self.activeMemberIdentity];
    [self loadCreditBalanceForActiveIdentity];
    [self loadCuratedFeedEntries];
    [self loadSignalThreads];
    [self loadChamberRooms];
    [self loadComments];
}

- (void)clearMemberSession {
    _isMemberSignedIn = NO;
    self.activeMemberIdentity = nil;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:NO forKey:kAcapeMemberSignedInKey];
    [defaults removeObjectForKey:kAcapeActiveMemberIdentityKey];
    _currentMemberProfile = [self starterMemberProfile];
    _creditBalance = 500;
    _entertainmentMemberCount = 736;
    _bonderCount = 0;
    _bondingCount = 0;
    [self loadCuratedFeedEntries];
    [self loadSignalThreads];
    [self loadChamberRooms];
    [self loadComments];
}

- (void)removeMemberAccount {
    NSString *identityToRemove = [self normalizedMemberIdentity:self.activeMemberIdentity];
    NSString *displayName = self.currentMemberProfile.displayName.lowercaseString ?: @"";
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kAcapeMemberSignedInKey];
    [defaults removeObjectForKey:kAcapeActiveMemberIdentityKey];
    [defaults removeObjectForKey:[self profileStorageKeyForIdentity:identityToRemove]];
    [defaults removeObjectForKey:[self creditStorageKeyForIdentity:identityToRemove]];
    [defaults removeObjectForKey:[self bondingRosterStorageKeyForIdentity:identityToRemove]];
    [defaults removeObjectForKey:[self curbedRosterStorageKeyForIdentity:identityToRemove]];
    [defaults removeObjectForKey:[self signalThreadStorageKeyForIdentity:identityToRemove]];
    [defaults removeObjectForKey:[self museConversationStorageKeyForIdentity:identityToRemove]];
    [self removePersistedChamberRoomsForIdentity:identityToRemove];
    [defaults removeObjectForKey:[self echoNotesStorageKeyForIdentity:identityToRemove]];
    [defaults removeObjectForKey:[NSString stringWithFormat:@"%@%@", kAcapeEchoNotesLegacyPrefix, [self storageTokenForIdentity:identityToRemove]]];
    [self removeEchoNotesForOwner:identityToRemove];
    [self markIdentityAccessRevoked:identityToRemove];
    [self removeAccessCredentialForIdentity:identityToRemove];
    [defaults removeObjectForKey:kAcapeLegacyMemberProfileStorageKey];
    [defaults removeObjectForKey:@"AcapeCreditBalanceKey"];

    [[NSFileManager defaultManager] removeItemAtURL:[self localPortraitURLForIdentity:identityToRemove] error:nil];
    [[NSFileManager defaultManager] removeItemAtURL:[self legacyLocalPortraitURL] error:nil];
    [[NSFileManager defaultManager] removeItemAtURL:[self localVoiceFolderURLForIdentity:identityToRemove] error:nil];

    _isMemberSignedIn = NO;
    self.activeMemberIdentity = nil;
    _currentMemberProfile = [self starterMemberProfile];
    _creditBalance = 500;
    _entertainmentMemberCount = 736;
    _bonderCount = 0;
    _bondingCount = 0;
    self.mutableBondingRoster = [NSMutableArray array];
    self.mutableCurbedRoster = [NSMutableArray array];
    self.mutableSignalThreads = [NSMutableArray array];
    [self.clipPreviewCache removeAllObjects];

    [self loadCuratedFeedEntries];
    if (displayName.length > 0) {
        NSMutableArray<AcapeFeedEntry *> *remainingEntries = [NSMutableArray array];
        for (AcapeFeedEntry *entry in self.rawCuratedFeedEntries) {
            if (![entry.memberName.lowercaseString isEqualToString:displayName]) {
                [remainingEntries addObject:entry];
            }
        }
        self.rawCuratedFeedEntries = remainingEntries.copy;
    }
    [self loadSignalThreads];
    [self loadChamberRooms];
    [self loadComments];
    [defaults synchronize];
}

- (BOOL)isIdentityAccessRevoked:(NSString *)identity {
    NSString *normalizedIdentity = [self normalizedMemberIdentity:identity];
    NSArray *revokedIdentities = [[NSUserDefaults standardUserDefaults] arrayForKey:kAcapeRemovedMemberIdentitiesKey];
    if (![revokedIdentities isKindOfClass:NSArray.class]) {
        return NO;
    }
    for (id item in revokedIdentities) {
        if ([item isKindOfClass:NSString.class] && [[self normalizedMemberIdentity:item] isEqualToString:normalizedIdentity]) {
            return YES;
        }
    }
    return NO;
}

- (void)markIdentityAccessRevoked:(NSString *)identity {
    NSString *normalizedIdentity = [self normalizedMemberIdentity:identity];
    if (normalizedIdentity.length == 0 || [normalizedIdentity isEqualToString:@"guest"]) {
        return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *revokedIdentities = [[defaults arrayForKey:kAcapeRemovedMemberIdentitiesKey] mutableCopy] ?: [NSMutableArray array];
    if ([self isIdentityAccessRevoked:normalizedIdentity]) {
        return;
    }
    [revokedIdentities addObject:normalizedIdentity];
    [defaults setObject:revokedIdentities.copy forKey:kAcapeRemovedMemberIdentitiesKey];
}

- (NSMutableDictionary<NSString *, NSString *> *)accessCredentialRegistry {
    NSDictionary *stored = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kAcapeAccessCredentialRegistryKey];
    if (![stored isKindOfClass:NSDictionary.class]) {
        return [NSMutableDictionary dictionary];
    }
    return [stored mutableCopy];
}

- (void)persistAccessCredentialRegistry:(NSDictionary<NSString *, NSString *> *)registry {
    [[NSUserDefaults standardUserDefaults] setObject:registry forKey:kAcapeAccessCredentialRegistryKey];
}

- (void)ensureBuiltinAccessAccounts {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:kAcapeBuiltinAccessSeedKey]) {
        return;
    }

    [self registerAccessCredentialWithIdentity:kAcapeBuiltinAccessIdentity secret:kAcapeBuiltinAccessSecret];

    NSString *identity = [self normalizedMemberIdentity:kAcapeBuiltinAccessIdentity];
    AcapeMemberProfile *profile = [AcapeMemberProfile profileWithMemberId:identity
                                                               displayName:kAcapeBuiltinAccessPersonaName
                                                           avatarAssetName:kAcapeBuiltinAccessPersonaAvatar];
    profile.nickname = kAcapeBuiltinAccessPersonaName;
    profile.birthday = @"1998-06-12";
    profile.location = @"Harbor";
    profile.gender = @"male";
    profile.profileCompleted = YES;

    NSError *error = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:profile requiringSecureCoding:YES error:&error];
    if (data && !error) {
        [defaults setObject:data forKey:[self profileStorageKeyForIdentity:identity]];
    }

    [defaults setInteger:0 forKey:[self creditStorageKeyForIdentity:identity]];
    [defaults setBool:YES forKey:kAcapeBuiltinAccessSeedKey];
    [defaults synchronize];
}

- (void)ensureBuiltinTestAccountCreditCleared {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:kAcapeBuiltinCreditSandboxClearKey]) {
        return;
    }
    NSString *identity = [self normalizedMemberIdentity:kAcapeBuiltinAccessIdentity];
    [defaults setInteger:0 forKey:[self creditStorageKeyForIdentity:identity]];
    [defaults setBool:YES forKey:kAcapeBuiltinCreditSandboxClearKey];
    [defaults synchronize];
    if (self.isMemberSignedIn && [self.activeMemberIdentity isEqualToString:identity]) {
        _creditBalance = 0;
    }
}

- (BOOL)hasAccessCredentialForIdentity:(NSString *)identity {
    NSString *normalizedIdentity = [self normalizedMemberIdentity:identity];
    NSString *storedSecret = [self accessCredentialRegistry][normalizedIdentity];
    return storedSecret.length > 0;
}

- (BOOL)registerAccessCredentialWithIdentity:(NSString *)identity secret:(NSString *)secret {
    NSString *normalizedIdentity = [self normalizedMemberIdentity:identity];
    NSString *trimmedSecret = [secret stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (normalizedIdentity.length == 0 || [normalizedIdentity isEqualToString:@"guest"] || trimmedSecret.length == 0) {
        return NO;
    }
    if ([self isIdentityAccessRevoked:normalizedIdentity]) {
        return NO;
    }

    NSMutableDictionary<NSString *, NSString *> *registry = [self accessCredentialRegistry];
    registry[normalizedIdentity] = trimmedSecret;
    [self persistAccessCredentialRegistry:registry.copy];

    if (![[NSUserDefaults standardUserDefaults] objectForKey:[self profileStorageKeyForIdentity:normalizedIdentity]]) {
        AcapeMemberProfile *profile = [self freshProfileForIdentity:normalizedIdentity];
        profile.memberId = normalizedIdentity;
        NSError *error = nil;
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:profile requiringSecureCoding:YES error:&error];
        if (data && !error) {
            [[NSUserDefaults standardUserDefaults] setObject:data forKey:[self profileStorageKeyForIdentity:normalizedIdentity]];
        }
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    return YES;
}

- (BOOL)validateAccessWithIdentity:(NSString *)identity secret:(NSString *)secret {
    NSString *normalizedIdentity = [self normalizedMemberIdentity:identity];
    NSString *trimmedSecret = [secret stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([self isIdentityAccessRevoked:normalizedIdentity]) {
        return NO;
    }
    NSString *storedSecret = [self accessCredentialRegistry][normalizedIdentity];
    return storedSecret.length > 0 && [storedSecret isEqualToString:trimmedSecret];
}

- (void)removeAccessCredentialForIdentity:(NSString *)identity {
    NSString *normalizedIdentity = [self normalizedMemberIdentity:identity];
    NSMutableDictionary<NSString *, NSString *> *registry = [self accessCredentialRegistry];
    if (!registry[normalizedIdentity]) {
        return;
    }
    [registry removeObjectForKey:normalizedIdentity];
    [self persistAccessCredentialRegistry:registry.copy];
}

- (void)removeEchoNotesForOwner:(NSString *)identity {
    NSString *owner = [self normalizedMemberIdentity:identity];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *storedMap = [[defaults dictionaryForKey:kAcapeEchoNotesStorageKey] mutableCopy];
    if (storedMap.count == 0) {
        return;
    }
    NSArray *entryIds = storedMap.allKeys;
    for (NSString *entryId in entryIds) {
        NSArray *rows = [storedMap[entryId] isKindOfClass:NSArray.class] ? storedMap[entryId] : @[];
        NSMutableArray *keptRows = [NSMutableArray array];
        for (NSDictionary *row in rows) {
            if (![row isKindOfClass:NSDictionary.class]) {
                continue;
            }
            NSString *rowOwner = [row[@"owner"] isKindOfClass:NSString.class] ? row[@"owner"] : @"";
            if (![rowOwner isEqualToString:owner]) {
                [keptRows addObject:row];
            }
        }
        if (keptRows.count > 0) {
            storedMap[entryId] = keptRows.copy;
        } else {
            [storedMap removeObjectForKey:entryId];
        }
    }
    [defaults setObject:storedMap.copy forKey:kAcapeEchoNotesStorageKey];
    [defaults synchronize];
}

- (void)updateCurrentMemberProfile:(AcapeMemberProfile *)profile {
    if (!profile) {
        return;
    }
    _currentMemberProfile = profile;
    [self persistCurrentMemberProfile];
}

- (NSArray<AcapeFeedEntry *> *)memberWorksEntries {
    NSString *displayName = self.currentMemberProfile.displayName.lowercaseString ?: @"";
    NSMutableArray<AcapeFeedEntry *> *works = [NSMutableArray array];
    for (AcapeFeedEntry *entry in self.curatedFeedEntries) {
        if ([entry.memberName.lowercaseString isEqualToString:displayName]) {
            [works addObject:entry];
        }
    }
    return works.copy;
}

- (void)persistCurrentMemberProfile {
    if (!self.isMemberSignedIn) {
        return;
    }
    NSString *identity = [self normalizedMemberIdentity:self.activeMemberIdentity ?: self.currentMemberProfile.memberId];
    NSError *error = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.currentMemberProfile requiringSecureCoding:YES error:&error];
    if (data && !error) {
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:[self profileStorageKeyForIdentity:identity]];
    }
}

- (NSString *)resolvedAvatarAssetName:(NSString *)assetName {
    return assetName.length > 0 ? assetName : @"member_default_mark";
}

- (UIImage *)avatarImageForAssetName:(NSString *)assetName {
    NSString *resolvedName = [self resolvedAvatarAssetName:assetName];
    if ([resolvedName isEqualToString:kAcapeLocalPortraitAssetName]) {
        UIImage *image = [UIImage imageWithContentsOfFile:self.localPortraitURL.path];
        if (!image) {
            image = [UIImage imageWithContentsOfFile:self.legacyLocalPortraitURL.path];
        }
        return image ?: [UIImage imageNamed:@"member_default_mark"];
    }
    return [UIImage imageNamed:resolvedName];
}

- (UIImage *)clipPreviewImageForEntry:(AcapeFeedEntry *)entry {
    if (entry.localClipFileName.length == 0) {
        return nil;
    }
    UIImage *cachedImage = [self.clipPreviewCache objectForKey:entry.localClipFileName];
    if (cachedImage) {
        return cachedImage;
    }

    NSURL *clipURL = [self localClipURLForFileName:entry.localClipFileName];
    if (!clipURL) {
        return nil;
    }

    AVAsset *asset = [AVAsset assetWithURL:clipURL];
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    generator.maximumSize = CGSizeMake(720.0, 1280.0);
    NSError *error = nil;
    CGImageRef imageRef = [generator copyCGImageAtTime:CMTimeMakeWithSeconds(0.1, 600)
                                            actualTime:nil
                                                 error:&error];
    if (!imageRef || error) {
        return nil;
    }
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    if (image) {
        [self.clipPreviewCache setObject:image forKey:entry.localClipFileName];
    }
    return image;
}

- (NSURL *)localClipURLForFileName:(NSString *)fileName {
    if (fileName.length == 0) {
        return nil;
    }
    NSString *extension = fileName.pathExtension.length > 0 ? fileName.pathExtension : @"mp4";
    NSString *stem = fileName.pathExtension.length > 0 ? fileName.stringByDeletingPathExtension : fileName;
    NSBundle *bundle = NSBundle.mainBundle;
    NSURL *url = [bundle URLForResource:stem withExtension:extension subdirectory:@"Resources/vsets"];
    if (!url) {
        url = [bundle URLForResource:stem withExtension:extension subdirectory:@"vsets"];
    }
    if (!url) {
        url = [bundle URLForResource:stem withExtension:extension];
    }
    return url;
}

- (NSURL *)localVoiceURLForFileName:(NSString *)fileName {
    if (fileName.length == 0) {
        return nil;
    }
    NSString *identity = self.isMemberSignedIn ? self.activeMemberIdentity : @"guest";
    NSURL *voiceFolderURL = [self localVoiceFolderURLForIdentity:identity];
    [[NSFileManager defaultManager] createDirectoryAtURL:voiceFolderURL withIntermediateDirectories:YES attributes:nil error:nil];
    return [voiceFolderURL URLByAppendingPathComponent:fileName];
}

- (NSURL *)localVoiceFolderURLForIdentity:(NSString *)identity {
    NSURL *documentsURL = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    NSString *folderName = [NSString stringWithFormat:@"voice_notes_%@", [self storageTokenForIdentity:identity ?: @"guest"]];
    return [documentsURL URLByAppendingPathComponent:folderName isDirectory:YES];
}

- (void)appendPublishedEntryWithCaption:(NSString *)captionText
                    coverImageAssetName:(NSString *)coverImageAssetName
                       localClipFileName:(NSString *)localClipFileName {
    NSString *trimmedCaption = [captionText stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmedCaption.length == 0) {
        trimmedCaption = @"New acoustic moment";
    }

    AcapeMemberProfile *profile = self.currentMemberProfile;
    AcapeFeedEntry *entry = [AcapeFeedEntry entryWithId:[NSString stringWithFormat:@"entry_%@", @([NSDate date].timeIntervalSince1970)]
                                             memberName:profile.displayName.length > 0 ? profile.displayName : @"Guest"
                                  memberAvatarAssetName:profile.avatarAssetName
                                             favorCount:0
                                       isFavoredByViewer:NO
                                            captionText:trimmedCaption
                                    coverImageAssetName:coverImageAssetName
                                 seekCoverImageAssetName:coverImageAssetName
                                      localClipFileName:localClipFileName
                                           coverTopColor:[UIColor colorWithRed:0.19 green:0.36 blue:0.42 alpha:1.0]
                                        coverBottomColor:[UIColor colorWithRed:0.06 green:0.11 blue:0.13 alpha:1.0]];
    NSMutableArray<AcapeFeedEntry *> *entries = [self.rawCuratedFeedEntries mutableCopy] ?: [NSMutableArray array];
    [entries insertObject:entry atIndex:0];
    self.rawCuratedFeedEntries = entries.copy;
    self.commentsByEntry[entry.entryId] = [NSMutableArray array];
}

- (NSURL *)localPortraitURL {
    return [self localPortraitURLForIdentity:self.activeMemberIdentity];
}

- (NSURL *)localPortraitURLForIdentity:(NSString *)identity {
    NSURL *documentsURL = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    NSString *fileName = [NSString stringWithFormat:@"%@_%@", [self storageTokenForIdentity:identity], kAcapeLocalPortraitFileName];
    return [documentsURL URLByAppendingPathComponent:fileName];
}

- (NSURL *)legacyLocalPortraitURL {
    NSURL *documentsURL = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    return [documentsURL URLByAppendingPathComponent:kAcapeLocalPortraitFileName];
}

- (NSArray<AcapeFeedEntry *> *)curatedEntriesMatchingQuery:(NSString *)query {
    NSString *trimmedQuery = [query stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmedQuery.length == 0) {
        return @[];
    }

    NSString *normalizedQuery = trimmedQuery.lowercaseString;
    NSMutableArray<AcapeFeedEntry *> *matches = [NSMutableArray array];
    for (AcapeFeedEntry *entry in self.curatedFeedEntries) {
        NSString *memberName = entry.memberName.lowercaseString ?: @"";
        if ([memberName containsString:normalizedQuery]) {
            [matches addObject:entry];
            continue;
        }

        for (NSString *token in [memberName componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]) {
            if (token.length > 0 && [token hasPrefix:normalizedQuery]) {
                [matches addObject:entry];
                break;
            }
        }
    }
    return matches.copy;
}

@end
