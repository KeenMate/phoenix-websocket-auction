# phoenix-websocket-auction



## Bidding channels

### Lobby
 

### Bidding
 - [FaF] place bid
 - bid placed

### Auctions
 - [RR] create auction
 - [RR] read auction detail
 - [RR] get auctions
 - [RR] get categories
 - [RR] update auction
 - [RR] delete auction
 - auction added (based on user's preference)
 - auction removed (based on user's preference)

### Auction
 - [RR] get detail
 - [RR] join auction
 - [RR] leave auction
 - detail updated (optional - not yet mandatory)
 - bidding started
 - bidding ended
 - bid averaged
 - bid placed (only if user opts in for this)

### User presence
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