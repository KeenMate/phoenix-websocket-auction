import {derived, readable} from "svelte/store"
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

	const activeUsers = readable([], set => {
		const presence = new Presence(channel)
		presence.onSync(() => {
			console.log("Presence synced")
			set(presence.list().map(presenceItem => {
				return presenceItem.metas.find(() => true)
			}))
		})

		return () => {}
	})

	const users = listenUsersChanged(channel, auctionId, activeUsers)

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

export function getAuctionBids(channel) {
	return pushSocketMessage(channel, "get_bids", {})
}

function listenUsersChanged(channel, auctionId, activeUsersStore) {
	const auctionUsersStore = readable([], set => {
		let state = []
		const setUsers = newUsers => {
			state = newUsers
			set(newUsers)
		}
		channel.on("auction_users", ({users}) => {
			setUsers(users)
		})
		channel.on("new_auction_user", newUser => {
			const foundIndex = state.findIndex(x => x.id === newUser.id)
			if (foundIndex === -1)
				setUsers([
					newUser,
					...state
				])
			else {
				setUsers(state.map((x, i) => i === foundIndex ? newUser : x))
			}
		})
		channel.on("auction_user_left", ({id: deletedUserId}) => {
			setUsers(state.filter(x => x.id !== deletedUserId))
		})

		return () => {
		}
	})

	return derived([activeUsersStore, auctionUsersStore], ([activeUsers, auctionUsers]) => {
		return auctionUsers.map(auctionUser => {
			const activeInstance = activeUsers.find(x => x.id === auctionUser.id)

			return {
				auctionUser: {
					user_status: activeInstance
						&& activeInstance.user_status
						|| auctionUser.user_status,
					...auctionUser
				},
				activeInstance
			}
		})

		// channel.on("user_status_changed", userStatus => {
		// 	// eventBus.emit("user_status_changed:" + auctionId, userStatus)
		//
		// })
	})
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
