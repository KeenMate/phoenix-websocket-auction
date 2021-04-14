import {readable} from "svelte/store"
import {Presence} from "phoenix"
import {pushMessage} from "./common"

export function initBiddingChannel(socket, itemId, listeners = {}) {
	const channel = socket.channel(`bidding:${itemId}`, {})

	const users = readable([], set => {
		const presence = new Presence(channel)
		presence.onSync(() => {
			set(presence.list().map(presenceItem => {
				return presenceItem.metas.find(() => true)
			}))
		})

		return () => {
		}
	})

	// initial messages
	listeners.onAuctionItem && channel.on("auction_item", ctx => {
		listeners.onAuctionItem(ctx)
	})
	listeners.onBiddings && channel.on("biddings", ctx => {
		listeners.onBiddings(ctx)
	})

	// Regular messages
	listeners.onBidPlaced && channel.on("bid_placed", ctx => {
		listeners.onBidPlaced(ctx)
	})
	// User is now part of bidding
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

export function joinBidding(channel) {
	return pushMessage(channel, "join_bidding")
}

export function placeBid(channel, amount) {
	return pushMessage(channel, "place_bid", {amount})
}
