import {writable} from "svelte/store"

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

	return new Promise((resolve, reject) => {
		channel
			.push("create_auction", {
				title: auction.title,
				category_id: auction.categoryId,
				start_price: auction.startPrice,
				bidding_start: auction.biddingStart,
				bidding_end: auction.biddingEnd,
				postponed_until: auction.postponedUntil
			})
			.receive("ok", ctx => {
				console.log("Auction item created", ctx)
				resolve(ctx)
			})
			.receive("error", ctx => {
				console.error("Received error when creating auction item", ctx)
				reject(ctx)
			})
	})
}

export async function getAuctionItems(search, categoryId, page, pageSize) {
	const channel = await auctionChannelAwaiter

	return new Promise((resolve, reject) => {
		channel
			.push("get_auction_items", {
				search,
				category_id: categoryId,
				skip: page * pageSize,
				take: pageSize
			})
			.receive("ok", ctx => {
				console.log("Got auction items", ctx)
				resolve(ctx)
			})
			.receive("error", ctx => {
				console.error("Received error when creating auction item", ctx)
				reject(ctx)
			})
	})
}

export async function getAuctionCategories() {
	const channel = await auctionChannelAwaiter

	return new Promise((resolve, reject) => {
		channel
			.push("get_auction_categories", {})
			.receive("ok", ctx => {
				console.log("Got auction categories", ctx)
				resolve(ctx)
			})
			.receive("error", ctx => {
				console.error("Received error when getting auction categories", ctx)
				reject(ctx)
			})
	})
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
		console.log("Item added", msg)
	})
}

function listenItemRemoved(channel) {
	channel.on("item_removed", msg => {
		console.log("Item removed", msg)
	})
}

function listenAuctionStarted(channel) {
	channel.on("auction_started", msg => {
		console.log("Auction started: ", msg)
	})
}

function listenAuctionEnded(channel) {
	channel.on("auction_ended", msg => {
		console.log("Auction ended: ", msg)
	})
}
