import {readable} from "svelte/store"
import {Presence} from "phoenix"
import {joinChannel, pushSocketMessage} from "./common"
import eventBus from "../../helpers/event-bus"

export function initAuctionChannels(socket, auctionId) {
	return Promise.all([
		initAuctionChannel(socket, auctionId),
		initAuctionBiddingChannel(socket, auctionId),
		initAuctionPresenceChannel(socket, auctionId)
	]).then(([auction, bidding, presence]) => ({
		auction,
		bidding,
		presence
	}))
}

export function initAuctionChannel(socket, auctionId, includeBidPlaced = false) {
	const channel = socket.channel(`auction:${auctionId}`, {include_bid_placed: includeBidPlaced})

	listenAuctionItemData(channel, auctionId)
	listenAuctionDetailUpdated(channel, auctionId)
	listenBiddingStarted(channel, auctionId)
	listenBiddingEnded(channel, auctionId)
	listenBidAveraged(channel, auctionId)
	includeBidPlaced && listenBidPlaced(channel, auctionId)

	return joinChannel(channel)
}

export function initAuctionBiddingChannel(socket, auctionId) {
	const channel = socket.channel(`bidding:${auctionId}`, {})

	listenBidPlaced(channel, auctionId)

	return joinChannel(channel)
}

export function initAuctionPresenceChannel(socket, auctionId) {
	const channel = socket.channel(`auction_presence:${auctionId}`, {})

	const users = readable([], set => {
		const presence = new Presence(channel)
		presence.onSync(() => {
			set(presence.list().map(presenceItem => {
				return presenceItem.metas.find(() => true)
			}))
		})
	})

	return joinChannel(channel, {channel, users})
}

export function joinAuction(channel) {
	return pushSocketMessage(channel, "join_auction")
}

export function leaveAuction(channel) {
	return pushSocketMessage(channel, "leave_auction")
}

export async function toggleFollow(channel) {
	return pushSocketMessage(channel, "toggle_follow", {})
}

export function placeBid(channel, amount) {
	return pushSocketMessage(channel, "place_bid", {amount})
}

export function getAuctionBids(biddingChannel) {
	return pushSocketMessage(biddingChannel, "get_bids", {})
}

function listenBidPlaced(channel, auctionId) {
	channel.on("bid_placed", auctionBid => {
		eventBus.emit("bid_placed:" + auctionId, null, auctionBid)
	})
}

function listenBidAveraged(channel, auctionId) {
	channel.on("bid_averaged", averageBid => {
		eventBus.emit("bidding_started:" + auctionId, null, averageBid)
	})
}

function listenBiddingEnded(channel, auctionId) {
	channel.on("bidding_ended", () => {
		eventBus.emit("bidding_ended:" + auctionId, null, null)
	})
}

function listenBiddingStarted(channel, auctionId) {
	channel.on("bidding_started", () => {
		eventBus.emit("bidding_started:" + auctionId, null, null)
	})
}

function listenAuctionDetailUpdated(channel, auctionId) {
	channel.on("auction_detail_updated", auction => {
		eventBus.emit("auction_detail_updated:" + auctionId, null, auction)
	})
}

function listenAuctionItemData(channel, auctionId) {
	channel.on("auction_data", auction => {
		eventBus.emit("auction_data:" + auctionId, null, auction)
	})
}
