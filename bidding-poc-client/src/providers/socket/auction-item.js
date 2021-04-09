import {get, readable, writable} from "svelte/store"
import {Presence} from "phoenix"

// export const auctionChannel = writable(null)
//
// const auctionChannelAwaiter = new Promise(resolve => {
// 	let unsubscribe
// 	unsubscribe = auctionChannel.subscribe(val => {
// 		if (!val)
// 			return
//
// 		resolve(val)
// 		unsubscribe()
// 	})
// })

export function initAuctionItemChannel(socket, itemId, listeners = {}) {
	const channel = socket.channel(`auction:${itemId}`, {})

	const users = writable([])
	const presence = new Presence(channel)
	presence.onSync(() => {
		users.set(presence.list())
	})

	// initial messages
	listeners.onAuctionItem && channel.on("auction_item", ctx => {
		listeners.onAuctionItem(ctx)
	})
	listeners.onBiddings && channel.on("biddings", ctx => {
		listeners.onBiddings(ctx)
	})

	// regular messages
	listeners.onBidPlaced && channel.on("bid_placed", ctx => {
		listeners.onBidPlaced(ctx)
	})
	listeners.onUserJoined && channel.on("user_joined", ctx => {
		listeners.onUserJoined(ctx)
	})

	return new Promise((resolve, reject) => {
		channel.join()
			.receive("ok", ctx => {
				console.log("Joined auction item channel", ctx)
				resolve({
					channel,
					users
				})
			})
			.receive("errpr", ctx => {
				console.error("Could not join auction item channel", ctx)
				reject(ctx)
			})
	})
}

export function getAuctionItem(channel) {
	return new Promise((resolve, reject) => {
		channel.push("get_data", {})
			.receive("ok", ctx => {
				console.log("Got auction item", ctx)
				resolve(ctx)
			})
			.receive("error", ctx => {
				console.error("Could not get auction item", ctx)
				reject(ctx)
			})
	})
}
