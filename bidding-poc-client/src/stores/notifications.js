import {writable} from "svelte/store"

let notificationId = 0
const notifications = writable([])

export default notifications

export function addNotification(eventType, msg) {
	notifications.update(notifications => [{
		id: notificationId++,
		eventType,
		msg
	}, ...notifications])
}

export function removeNotification(notification) {
	notifications.update(f => f.filter(x => x.id !== notification.id))
}
