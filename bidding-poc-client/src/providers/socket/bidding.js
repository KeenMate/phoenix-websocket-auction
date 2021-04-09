/**
 * @typedef AuctionItemEventHandlers
 * @property {Function} placedBid
 * @property {Function} userJoined
 */

/**
 * @param socket {Socket}
 * @param auctionItemId {number}
 * @param eventHandlers {AuctionItemEventHandlers}
 * @returns {*}
 */
export function initAuctionItemChannel(socket, auctionItemId, eventHandlers) {
	const channel = socket.channel(`auction_item:${auctionItemId}`)

	initPlacedBid(channel, eventHandlers.placedBid)
	initUserJoined(channel, eventHandlers.userJoined)

	return channel
}

export function placeBid(channel, amount, onSuccess, onError) {
	channel.push("place_bid", {amount})
		.receive("ok", function () {
			console.log("Bid placed", arguments)
			onSuccess.apply(this, arguments)
		})
		.receive("error", msg => {
			console.log("Error placing bid", msg)
			onError(msg)
		})
		.receive("timeout", () => {
			console.log("Place bid timed out")
		})
}

function initPlacedBid(channel, handler) {
	channel.on("bid_placed", msg => {
		console.log("Bid placed: ", msg)
		handler(msg)
	})
}

function initUserJoined(channel, handler) {
	channel.on("user_joined", msg => {
		console.log("User joined", msg)
		handler(msg)
	})
}
