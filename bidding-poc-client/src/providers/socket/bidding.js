import {readable} from "svelte/store"
import {Presence} from "phoenix"
import {pushSocketMessage} from "./common"
import eventBus from "../../helpers/event-bus"

export function initAuctionChannels(socket, itemId, listeners = {}) {
	const auctionChannel = socket.channel(`auction:${itemId}`, {})
	const auctionPresenceChannel = socket.channel(`auction_presence:${itemId}`, {})
	const biddingChannel = socket.channel(`bidding:${itemId}`, {})

	const users = readable([], set => {
		const presence = new Presence(biddingChannel)
		presence.onSync(() => {
			set(presence.list().map(presenceItem => {
				return presenceItem.metas.find(() => true)
			}))
		})

		return () => {
		}
	})

	// initial messages
	listeners.onAuctionItem && auctionChannel.on("auction_item", ctx => {
		listeners.onAuctionItem(ctx)
	})
	listeners.onBiddings && biddingChannel.on("biddings", ctx => {
		listeners.onBiddings(ctx)
	})

	// Regular messages
	biddingChannel.on("bid_placed", msg => {
		eventBus.emit("bid_placed", null, {itemId, msg})
	})
	// User is now part of bidding
	// biddingChannel.on("user_joined", msg => {
	// 	eventBus.emit("user_joined", null, {itemId, msg})
	// })
	auctionChannel.on("bidding_started", () => {
		eventBus.emit("bidding_started", null, itemId)
	})
	auctionChannel.on("bidding_ended", () => {
		eventBus.emit("bidding_ended", null, itemId)
	})

	const channelsJoined = Promise.all([
		auctionChannel,
		auctionPresenceChannel,
		biddingChannel
	].map(x => new Promise((resolve, reject) => {
			x.join()
				.receive("ok", ctx => {
					console.log("Joined one of auction's channel", ctx)
					resolve(x)
				})
				.receive("error", error => {
					console.error("Could not join auction item channel", error)
					reject({channel: x, error})
				})
		})
	))
	
	return channelsJoined
		.then(() => {
			return {
				channels: {
					auctionChannel,
					auctionPresenceChannel,
					biddingChannel
				},
				users
			}
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
