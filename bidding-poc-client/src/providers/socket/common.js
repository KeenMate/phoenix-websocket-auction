import {Socket} from "phoenix"
import {writable} from "svelte/store"

export const socket = writable(null)

export function createSocket(token) {
	if (!token) {
		console.error("Cannot create socket because token is missing")
		return
	}

	return new Socket("ws://localhost:4000/socket", {
		params: {
			token
		}
	})
}
