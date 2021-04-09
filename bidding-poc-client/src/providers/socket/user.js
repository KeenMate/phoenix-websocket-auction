import {writable} from "svelte/store"

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

	return new Promise((resolve, reject) => {
		channel
			.push("get_users", {search, page, page_size: pageSize})
			.receive("ok", ctx => {
				console.log("Received ok status when getting users", ctx)
				resolve(ctx)
			})
			.receive("error", ctx => {
				console.log("Received error status when getting users", ctx)
				reject(ctx)
			})
	})
}

export async function getUser(userId) {
	const channel = await usersChannelAwaiter

	return new Promise((resolve, reject) => {
		channel
			.push("get_user", {user_id: userId})
			.receive("ok", ctx => {
				console.log("Received ok status when getting user", ctx)
				resolve(ctx)
			})
			.receive("error", ctx => {
				console.log("Received error status when getting user", ctx)
				reject(ctx)
			})
	})
}

export async function updateUser(userId, username, password, isAdmin) {
	const channel = await usersChannelAwaiter

	return new Promise((resolve, reject) => {
		channel
			.push("update_user", {user_id: userId, username, password, is_admin: isAdmin})
			.receive("ok", ctx => {
				console.log("Received ok status when updating user", ctx)
				resolve(ctx)
			})
			.receive("error", ctx => {
				console.log("Received error status when updating user", ctx)
				reject(ctx)
			})
	})
}

export async function deleteUser(userId) {
	const channel = await usersChannelAwaiter

	return new Promise((resolve, reject) => {
		channel
			.push("delete_user", {user_id: userId})
			.receive("ok", ctx => {
				console.log("Received ok status when deleting user", ctx)
				resolve(ctx)
			})
			.receive("error", ctx => {
				console.log("Received error status when deleting user", ctx)
				reject(ctx)
			})
	})
}
