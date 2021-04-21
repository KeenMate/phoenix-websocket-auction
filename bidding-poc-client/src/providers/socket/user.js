import {writable} from "svelte/store"
import {pushSocketMessage} from "./common"
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
		.then(x => {
			console.log("Users channel joined")
			return x
		})
		.catch(error => {
			console.error("Error occured while joining users channel", error)
			throw error
		})
}

export function initUserChannel(socket, userId) {
	const userChannel = socket.channel(`user:${userId}`, {})

	userChannel.on("place_bid_success", ctx => {
		eventBus.emit("place_bid_success", null, ctx)
	})
	userChannel.on("place_bid_error", ctx => {
		eventBus.emit("place_bid_error", null, ctx)
	})

	return joinChannel(userChannel)
		.then(x => {
			console.log("User channel joined")
			return x
		})
		.catch(error => {
			console.error("Error occured while joining user channel", error)
			throw error
		})
}

function joinChannel(channel) {
	return new Promise((resolve, reject) => {
		channel.join()
			.receive("ok", () => {
				resolve(channel)
			})
			.receive("error", ctx => {
				reject(ctx)
			})
	})
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
