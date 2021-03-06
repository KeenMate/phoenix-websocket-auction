import {writable} from "svelte/store"
import {joinChannel, pushSocketMessage} from "./common"
import eventBus from "../../helpers/event-bus"

export const usersChannel = writable(null)

const usersChannelAwaiter = new Promise(resolve => {
	let unsubscribe
	unsubscribe = usersChannel.subscribe(val => {
		if (!val)
			return

		resolve(val)
		unsubscribe()
	})
})

export function initUsersChannel(socket) {
	const channel = socket.channel("users:lobby", {})

	return joinChannel(channel)
}

export function initUserChannel(socket, userId) {
	const channel = socket.channel(`user:${userId}`, {})

	listenPlaceBidSuccess(channel)
	listenPlaceBidError(channel)
	listenBidOverbidded(channel)
	listenBiddingStarted(channel)
	listenBiddingEnded(channel)

	return joinChannel(channel)
}

export async function getUsers(search, page = 0, pageSize = 10) {
	const channel = await usersChannelAwaiter

	return pushSocketMessage(channel, "get_users", {search, page, page_size: pageSize})
}

export async function getUser(userId) {
	const channel = await usersChannelAwaiter

	return pushSocketMessage(channel, "get_user", {user_id: userId})
}

export async function updateUser(userId, username, displayName, password, isAdmin) {
	const channel = await usersChannelAwaiter

	return pushSocketMessage(
		channel,
		"update_user",
		{
			user_id: userId,
			username,
			display_name: displayName,
			password,
			is_admin: isAdmin
		}
	)
}

export async function deleteUser(userId) {
	const channel = await usersChannelAwaiter

	return pushSocketMessage(channel, "delete_user", {user_id: userId})
}

function listenBidOverbidded(channel) {
	channel.on("bid_overbidded", bid => {
		eventBus.emit("bid_overbidded:" + bid.auction_id, null, bid)
	})
}

function listenBiddingStarted(channel) {
	channel.on("bidding_started", auction => {
		console.log("bidding started", auction)
		eventBus.emit("bidding_started:" + auction.id, null, auction)
	})
}

function listenBiddingEnded(channel) {
	channel.on("bidding_ended", auction => {
		eventBus.emit("bidding_ended:" + auction.id, null, auction)
	})
}

function listenPlaceBidSuccess(channel) {
	channel.on("place_bid_success", msg => {
		eventBus.emit("place_bid_success", null, msg)
	})
}

function listenPlaceBidError(channel) {
	channel.on("place_bid_error", msg => {
		eventBus.emit("place_bid_error:" + msg.auction_id, null, msg)
	})
}
