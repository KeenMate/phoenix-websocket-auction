import {readable} from "svelte/store"
import {Presence} from "phoenix"
import {pushSocketMessage} from "./common"
import eventBus from "../../helpers/event-bus"

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
	channel.on("bid_placed", msg => {
		eventBus.emit("bid_placed", null, {itemId, msg})
	})
	// User is now part of bidding
	channel.on("user_joined", msg => {
		eventBus.emit("user_joined", null, {itemId, msg})
	})
	channel.on("bidding_started", () => {
		eventBus.emit("bidding_started", null, itemId)
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
			.receive("error", error => {
				console.error("Could not join auction item channel", error)
				reject({channel, error})
			})
	})
}

export function joinBidding(channel) {
	return pushSocketMessage(channel, "join_bidding")
}

export function leaveBidding(channel) {
	return pushSocketMessage(channel, "leave_bidding")
}

export async function toggleWatch(channel) {
	return pushSocketMessage(channel, "toggle_watch", {})
}

export function placeBid(channel, amount) {
	return pushSocketMessage(channel, "place_bid", {amount})
}
