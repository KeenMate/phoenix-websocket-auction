import {Socket} from "phoenix"
import {writable} from "svelte/store"

export const socket = writable(null)

export function createSocket(token) {
	if (!token)
		throw new Error("Cannot create socket because token is missing")

	return new Socket("ws://localhost:4000/socket", {
		params: {
			token
		}
	})
}

export function pushMessage(channel, type, payload = {}) {
	return new Promise((resolve, reject) => {
		channel.push(type, payload)
			.receive("ok", ctx => {
				console.log(`Got success response from ${channel.topic} for "${type}" message`, ctx)
				resolve(ctx)
			})
			.receive("error", ctx => {
				console.log(`Got error response from ${channel.topic} for "${type}" message`, ctx)
				reject(ctx)
			})
	})
}
