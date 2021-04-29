import {writable} from "svelte/store"
import {joinChannel, pushSocketMessage} from "./common"
import eventBus from "../../helpers/event-bus"

export const auctionChannel = writable(null)

const auctionChannelAwaiter = new Promise(resolve => {
	let unsubscribe
	unsubscribe = auctionChannel.subscribe(val => {
		if (!val)
			return

		resolve(val)
		unsubscribe()
	})
})

export function initAuctionsChannel(socket) {
	const channel = socket.channel("auctions", {})

	listenItemAdded(channel)
	listenItemRemoved(channel)
	listenAuctionStarted(channel)
	listenAuctionEnded(channel)

	return joinChannel(channel)
}

export async function createAuction(auction) {
	const channel = await auctionChannelAwaiter

	return pushSocketMessage(channel, "create_auction", {
		title: auction.title,
		category_id: auction.categoryId,
		start_price: auction.startPrice,
		bidding_start: auction.biddingStart,
		bidding_end: auction.biddingEnd,
		minimum_bid_step: auction.minimumBidStep
	})
}

export async function getAuctions(search, categoryId, page, pageSize) {
	const channel = await auctionChannelAwaiter

	return pushSocketMessage(channel, "get_auctions", {
		search: search || null,
		category_id: categoryId || null,
		skip: page * pageSize,
		take: pageSize
	})
}

export async function getAuctionCategories() {
	const channel = await auctionChannelAwaiter

	return pushSocketMessage(channel, "get_auction_categories")
}

function listenItemAdded(channel) {
	channel.on("auction_added", auction => {
		console.log("Auction added", auction)
		eventBus.emit("auction_added", null, auction)
	})
}

function listenItemRemoved(channel) {
	channel.on("auction_deleted", auction => {
		console.log("Auction deleted", auction)
		eventBus.emit("auction_deleted", null, auction)
	})
}

function listenAuctionStarted(channel) {
	channel.on("bidding_started", auction => {
		console.log("Auction started: ", auction)
		eventBus.emit("bidding_started", null, auction)
	})
}

function listenAuctionEnded(channel) {
	channel.on("bidding_ended", auction => {
		console.log("Auction ended: ", auction)
		eventBus.emit("bidding_ended", null, auction)
	})
}

export async function deleteAuction(auctionId) {
	const channel = await auctionChannelAwaiter
	return pushSocketMessage(channel, "delete_auction", {auction_id: auctionId})
}
