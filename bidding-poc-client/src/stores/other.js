import {readable} from "svelte/store"

export const minuteer = readable(null, set => {
	const interval = setInterval(() => {
		set(new Date())
	}, 5000)

	return () => {
		clearInterval(interval)
	}
})
