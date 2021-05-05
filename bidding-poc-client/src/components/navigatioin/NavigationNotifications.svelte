<script>
	import notifications, {removeNotification} from "../../stores/notifications"
	import FlashIcon from "./FlashIcon.svelte"
	import NavButton from "./NavButton.svelte"
	import NavTabItem from "./NavTabItem.svelte"

	function getNotificationColor(notification) {
		switch (notification.type) {
			case "success":
				return "has-text-success"
			case "warning":
				return "has-text-warning"
			case "error":
				return "has-text-danger"
			case "info":
				return "has-text-link"
			default:
				return "has-text-black"
		}
	}

	function getNotificationMessage(notification) {
		switch (notification.eventType) {
			case "auction_added":
				return `Auction '${notification.msg.title}' has been added`
			case "auction_deleted":
				return `Auction '${notification.msg.title}' has been removed`
			case "bidding_started":
				return `Bidding for item '${notification.msg.title}' has started`
			case "bidding_ended":
				return `Bidding for item '${notification.msg.title}' has ended`
		}
	}
</script>

{#if !$notifications.length}
	<NavTabItem>
		Notifications
	</NavTabItem>
{:else}
	<div class="navbar-item has-dropdown is-hoverable">
		<a class="navbar-link">
			Notifications
		</a>

		<div class="navbar-dropdown">
			{#each $notifications as notification (notification.id)}
				<a class="navbar-item">
					<FlashIcon type={notification.type} />
					<button class="delete" on:click={() => removeNotification(notification)}></button>
					{getNotificationMessage(notification)}
				</a>
			{/each}
		</div>
	</div>
{/if}
