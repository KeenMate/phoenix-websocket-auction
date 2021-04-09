import {writable} from "svelte/store"

let flashId = 0
const flashes = writable([])

export default flashes

export function addFlash(message, type = "default") {
	flashes.update(flashes => [{
		id: flashId++,
		type,
		message
	}, ...flashes])
}

export function removeFlash(flash) {
	flashes.update(f => f.filter(x => x !== flash))
}
