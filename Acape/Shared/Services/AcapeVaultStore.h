#import <Foundation/Foundation.h>
#import "AcapeMemberProfile.h"
#import "AcapeFeedEntry.h"
#import "AcapeSignalThread.h"
#import "AcapeSocialMember.h"
#import "AcapeChamberRoom.h"
#import "AcapeEchoComment.h"
#import "AcapeSignalMessage.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const AcapeSignalThreadDidUpdateNotification;

@interface AcapeVaultStore : NSObject

@property (nonatomic, strong, readonly) AcapeMemberProfile *currentMemberProfile;
@property (nonatomic, copy, readonly) NSArray<AcapeFeedEntry *> *curatedFeedEntries;
@property (nonatomic, copy, readonly) NSArray<AcapeSignalThread *> *signalThreads;
@property (nonatomic, assign, readonly) NSInteger entertainmentMemberCount;
@property (nonatomic, assign, readonly) NSInteger bonderCount;
@property (nonatomic, assign, readonly) NSInteger bondingCount;
@property (nonatomic, assign, readonly) NSInteger creditBalance;
@property (nonatomic, assign, readonly) BOOL isMemberSignedIn;

+ (instancetype)shared;

- (void)markMemberSignedIn;
- (void)markMemberSignedInWithIdentity:(NSString *)identity;
- (void)clearMemberSession;
- (void)removeMemberAccount;
- (BOOL)isIdentityAccessRevoked:(NSString *)identity;
- (BOOL)hasAccessCredentialForIdentity:(NSString *)identity;
- (BOOL)registerAccessCredentialWithIdentity:(NSString *)identity secret:(NSString *)secret;
- (BOOL)validateAccessWithIdentity:(NSString *)identity secret:(NSString *)secret;
- (void)updateCurrentMemberProfile:(AcapeMemberProfile *)profile;
- (NSURL *)localPortraitURL;

- (UIImage *)avatarImageForAssetName:(nullable NSString *)assetName;
- (UIImage *_Nullable)clipPreviewImageForEntry:(AcapeFeedEntry *)entry;
- (NSURL *_Nullable)localClipURLForFileName:(nullable NSString *)fileName;
- (NSURL *_Nullable)localVoiceURLForFileName:(nullable NSString *)fileName;
- (void)appendPublishedEntryWithCaption:(NSString *)captionText
                    coverImageAssetName:(nullable NSString *)coverImageAssetName
                       localClipFileName:(nullable NSString *)localClipFileName;
- (NSString *)resolvedAvatarAssetName:(nullable NSString *)assetName;
- (NSArray<AcapeFeedEntry *> *)curatedEntriesMatchingQuery:(NSString *)query;
- (NSArray<AcapeFeedEntry *> *)memberWorksEntries;

- (void)appendViewerText:(NSString *)text toThread:(AcapeSignalThread *)thread;
- (void)appendViewerVoiceSeconds:(NSInteger)seconds toThread:(AcapeSignalThread *)thread;
- (void)appendViewerVoiceSeconds:(NSInteger)seconds fileName:(nullable NSString *)fileName toThread:(AcapeSignalThread *)thread;
- (void)markThreadRead:(AcapeSignalThread *)thread;
- (AcapeSignalThread *)signalThreadForMemberName:(NSString *)name avatarAssetName:(nullable NSString *)avatar;

- (NSArray<AcapeSocialMember *> *)bondingRoster;
- (NSArray<AcapeSocialMember *> *)admirerRoster;
- (NSArray<AcapeSocialMember *> *)curbedRoster;
- (NSArray<AcapeSocialMember *> *)bondingRosterForMemberName:(NSString *)name;
- (NSArray<AcapeSocialMember *> *)bonderRosterForMemberName:(NSString *)name;
- (BOOL)hasBondWithMemberName:(NSString *)name;
- (BOOL)toggleBondWithMemberName:(NSString *)name avatarAssetName:(nullable NSString *)avatar;
- (void)toggleBondForMember:(AcapeSocialMember *)member;
- (void)removeCurbedMember:(AcapeSocialMember *)member;
- (void)addCurbedMemberWithName:(NSString *)name avatarAssetName:(nullable NSString *)avatar;
- (BOOL)isMemberCurbedWithName:(NSString *)name;

// Credit balance
- (void)rechargeCredits:(NSInteger)amount;
- (void)syncCreditBalance:(NSInteger)balance;
- (BOOL)canAffordCredits:(NSInteger)amount;
- (BOOL)spendCredits:(NSInteger)amount;

// Chamber (live rooms)
- (NSArray<AcapeChamberRoom *> *)chamberRooms;
- (BOOL)isTemplateChamberRoomId:(NSString *)roomId;
- (BOOL)isMemberOwnedChamberRoom:(AcapeChamberRoom *)room;
- (NSString *)chamberHostNameForRoom:(AcapeChamberRoom *)room;
- (NSString *)chamberHostAvatarAssetNameForRoom:(AcapeChamberRoom *)room;
- (AcapeChamberRoom *)createChamberRoomWithName:(NSString *)name;
- (AcapeChamberRoom *)createChamberRoomWithName:(NSString *)name coverAssetName:(nullable NSString *)coverAssetName;
- (void)persistMemberChamberRooms;
- (UIImage *)chamberCoverImageForRoom:(AcapeChamberRoom *)room;
- (BOOL)persistChamberCoverImage:(UIImage *)image forRoomId:(NSString *)roomId;
- (void)appendChatLine:(NSString *)text toRoom:(AcapeChamberRoom *)room;

// Reel / Echo (video feed comments + favor)
- (NSArray<AcapeEchoComment *> *)commentsForEntryId:(NSString *)entryId;
- (void)addComment:(NSString *)text toEntryId:(NSString *)entryId;
- (void)toggleFavorForEntry:(AcapeFeedEntry *)entry;

- (NSArray<AcapeSignalMessage *> *)museConversationMessages;
- (NSInteger)museConversationReplyCursor;
- (BOOL)museConversationSessionPaid;
- (void)persistMuseConversationMessages:(NSArray<AcapeSignalMessage *> *)messages
                              replyCursor:(NSInteger)replyCursor
                              sessionPaid:(BOOL)sessionPaid;
- (void)clearMuseConversation;
- (void)resetMuseSessionUnlock;

@end

NS_ASSUME_NONNULL_END
