import {derived, readable} from "svelte/store"

export let secondeer = readable(new Date(), set => {
	const interval = setInterval(() => {
		set(new Date())
	}, 1000)

	return () => {
		clearInterval(interval)
	}
})

let secondsCounter = 0
export const minuteer = derived(secondeer, (date, set) => {
	if (secondsCounter++ === 60)
		set(date)

	return () => {}
}, new Date())
