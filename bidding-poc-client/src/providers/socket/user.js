import {writable} from "svelte/store"
import {pushMessage} from "./common"

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

function joinChannel(channel) {
	return new Promise((resolve, reject) => {
		channel.join()
			.receive("ok", ctx => {
				console.log("Users channel joined", ctx)
				resolve(channel)
			})
			.receive("error", ctx => {
				console.error("Error occured while joining users channel", ctx)
				reject(ctx)
			})
	})
}

export async function getUsers(search, page = 0, pageSize = 10) {
	const channel = await usersChannelAwaiter

	return pushMessage(channel, "get_users", {search, page, page_size: pageSize})
}

export async function getUser(userId) {
	const channel = await usersChannelAwaiter

	return pushMessage(channel, "get_user", {user_id: userId})
}

export async function updateUser(userId, username, password, isAdmin) {
	const channel = await usersChannelAwaiter

	return pushMessage(channel, "update_user", {user_id: userId, username, password, is_admin: isAdmin})
}

export async function deleteUser(userId) {
	const channel = await usersChannelAwaiter

	return pushMessage(channel, "delete_user", {user_id: userId})
}
