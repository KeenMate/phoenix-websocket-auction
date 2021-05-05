import {writable} from "svelte/store"
import {joinChannel, pushSocketMessage} from "./common"
import eventBus from "../../helpers/event-bus"

export const auctionsChannel = writable(null)

const auctionsChannelAwaiter = new Promise(resolve => {
	let unsubscribe
	unsubscribe = auctionsChannel.subscribe(val => {
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
	const channel = await auctionsChannelAwaiter

	return pushSocketMessage(channel, "create_auction", {
		title: auction.title,
		category_id: auction.categoryId,
		start_price: auction.startPrice,
		bidding_start: auction.biddingStart,
		bidding_end: auction.biddingEnd,
		minimum_bid_step: auction.minimumBidStep
	})
}

/**
 * @desc Lists all auctions
 * @param search
 * @param categoryId
 * @param page
 * @param pageSize
 * @returns {Promise<Array>}
 */
export async function getAuctions(search, categoryId, page, pageSize) {
	const channel = await auctionsChannelAwaiter

	return pushSocketMessage(channel, "get_auctions", {
		search: search || null,
		category_id: categoryId || null,
		skip: page * pageSize,
		take: pageSize
	})
}

/**
 * @desc Returns auctions for current user (that are owned, followed or joined)
 * @param search
 * @param categoryId
 * @param page
 * @param pageSize
 * @returns {Promise<Array>}
 */
export async function getMyAuctions(search, categoryId, page, pageSize) {
	const channel = await auctionsChannelAwaiter

	return pushSocketMessage(channel, "get_my_auctions", {
		search: search || null,
		category_id: categoryId || null,
		skip: page * pageSize,
		take: pageSize
	})
}

/**
 * @desc Returns user's auctions
 * @param userId
 * @param categoryId
 * @returns {Promise<unknown>}
 */
export async function getUserAuctions(userId, categoryId) {
	const channel = await auctionsChannelAwaiter

	return pushSocketMessage(
		channel,
		"get_user_auctions",
		{
			user_id: userId,
			category_id: categoryId
		}
	)
}

/**
 * @desc Returns categories that are used by user' auctions
 * @param userId
 * @returns {Promise<Array>}
 */
export async function getUserAuctionsCategories(userId) {
	const channel = await auctionsChannelAwaiter

	return pushSocketMessage(channel, "get_user_auctions_categories", {user_id: userId})
}

/**
 * @desc Returns all available categories
 * @returns {Promise<unknown>}
 */
export async function getAuctionCategories() {
	const channel = await auctionsChannelAwaiter

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
	const channel = await auctionsChannelAwaiter
	return pushSocketMessage(channel, "delete_auction", {auction_id: auctionId})
}
