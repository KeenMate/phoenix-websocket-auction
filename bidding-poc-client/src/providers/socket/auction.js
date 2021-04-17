import {writable} from "svelte/store"
import {pushSocketMessage} from "./common"

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

export function initAuctionChannel(socket) {
	const channel = socket.channel("auction:lobby", {})

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
		bidding_end: auction.biddingEnd
	})
}

export async function getAuctionItems(search, categoryId, page, pageSize) {
	const channel = await auctionChannelAwaiter

	return pushSocketMessage(channel, "get_auction_items", {
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

function joinChannel(channel) {
	return new Promise((resolve, reject) => {
		channel.join()
			.receive("ok", ctx => {
				console.log("Joined auction lobby channel", ctx)
				resolve(channel)
			})
			.receive("error", ctx => {
				console.error("Could not join auction lobby", ctx)
				reject(ctx)
			})
	})
}

function listenItemAdded(channel) {
	channel.on("item_added", msg => {
		// todo: Send message to common EventBus
		console.log("Item added", msg)
	})
}

function listenItemRemoved(channel) {
	channel.on("item_removed", msg => {
		// todo: Send message to common EventBus
		console.log("Item removed", msg)
	})
}

function listenAuctionStarted(channel) {
	channel.on("auction_started", msg => {
		// todo: Send message to common EventBus
		console.log("Auction started: ", msg)
	})
}

function listenAuctionEnded(channel) {
	channel.on("auction_ended", msg => {
		// todo: Send message to common EventBus
		console.log("Auction ended: ", msg)
	})
}
