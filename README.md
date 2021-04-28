# phoenix-websocket-auction

## Bidding channels

### Lobby
 

### Bidding
 - [FaF] place bid
 - bid placed

### Auctions
 - [RR] create auction
 - [RR] get auctions
 - [RR] get categories
 - [RR] update auction
 - [RR] delete auction
 - auction added (based on user's preference)
 - auction deleted (based on user's preference)

### Auction
 - [RR] get auction detail
 - [RR] join auction
 - [RR] leave auction
 - detail updated (optional - not yet mandatory)
 - bidding started
 - bidding ended
 - bid averaged
 - bid placed (only if user opts in for this)

### Auction presence
 - [FaF] toggle follow auction (Now, its [RR])
 - follow toggled (Not used now)
 - presence_sync/diff (user status changed: joined/followed/(nothing - just watching))

### User (for global presence as well - in future)
 - [FaF] friendify/unfriendify user
 - user user status changed
 - user auction status changed

```

 user status changed
 {
 	user_id: 123,
 	update_type: loggedin/idle/loggedout
 }

 user auction status changed
 {
 	auctionid: 1,
 	user_type: watcher/follower/bidder,
 	update_type: started/ended
 }

```