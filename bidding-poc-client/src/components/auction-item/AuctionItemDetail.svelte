<script>
	import {createEventDispatcher} from "svelte"
	import m from "moment"
	import Card from "../ui/Card.svelte"
	import TheButton from "../ui/TheButton.svelte"

	const dispatch = createEventDispatcher()
	export let title = ""
	export let category_id = 0
	export let category = ""
	export let description = ""
	export let inserted_at = null
	export let bidding_start = null
	export let bidding_end = null

	function reassignComputableProps() {
		inserted_at = inserted_at
		bidding_start = bidding_start
		bidding_end = bidding_end
	}

	function formatDateTime(val) {
		if (!val)
			return ""

		const date = new Date(val)

		return isNaN(date)
			? "Invalid date"
			: date.toLocaleString()
	}

	function getDateString(val) {
		const date = new Date(val)

		return isNaN(date)
			? "Invalid date"
			: date.toISOString().substr(0, 10)
	}

	function onDeleteClick() {
		if (!confirm("Do you really want to delete this auction?"))
			return

		dispatch("deleteAuction")
	}
</script>

<Card>
	{#if title || category_id}
		<div class="media">
			<div class="media-content">
				<div class="level">
					<div class="level-left is-block">
						{#if title}
							<p class="title is-4">{title}</p>
						{/if}
						{#if category_id}
							<p class="subtitle is-6">
								<span class="tag is-primary">{category}</span>
							</p>
						{/if}
					</div>
					<div class="level-right">
						<TheButton isDanger on:click={onDeleteClick}>
							Delete
						</TheButton>
						<!-- todo: Render `edit` button if user_id is same as owner id -->
					</div>
				</div>
			</div>
		</div>
	{/if}

	<div class="content">
		{#if bidding_start}
			<b>Bidding start: </b>
			{m(bidding_start).calendar()} <i>({m(bidding_start).fromNow()})</i>
			<br>
		{/if}
		{#if bidding_end}
			<b>Bidding end: </b>
			{m(bidding_end).calendar()} <i>({m(bidding_end).fromNow()})</i>
			<br>
		{/if}
		{#if description}
			<b>Description: </b>
			{description}
			<br>
		{/if}
		<b>Inserted at: </b>
		{#if inserted_at}
			<time datetime={getDateString(inserted_at)}>{formatDateTime(inserted_at)}</time>
		{:else}
			Not available
		{/if}
	</div>
</Card>
