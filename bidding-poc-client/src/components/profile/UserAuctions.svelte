<script>
	import {createEventDispatcher} from "svelte"
	import Tabs from "../ui/Tabs.svelte"
	import TabItem from "../ui/TabItem.svelte"
	import MyAuctionsList from "../auctions/MyAuctionsList.svelte"
	import Notification from "../ui/Notification.svelte"
	import lazyLoader from "../../helpers/lazy-loader"

	const dispatch = createEventDispatcher()

	export let categoriesTask = null
	export let selectedCategoryId = null
	export let auctionsTask = null

	let auctionsLoading = false
	let categoriesLoading = false

	$: lazyCategoriesTask = categoriesTask && lazyLoader(
		categoriesTask,
		toggleCategoriesLoading,
		toggleCategoriesLoading
	)
	$: lazyAuctionsTask = auctionsTask && lazyLoader(
		auctionsTask,
		toggleAuctionsLoading,
		toggleAuctionsLoading
	)

	function toggleAuctionsLoading() {
		auctionsLoading = !auctionsLoading
	}
	function toggleCategoriesLoading() {
		categoriesLoading = !categoriesLoading
	}

	function onSelectCategory(category) {
		if (selectedCategoryId === (category && category.id))
			return

		dispatch("selectCategory", category)
	}
</script>

<div class="columns is-justify-content-flex-end">
	<div class="column is-narrow">
		{#await lazyCategoriesTask}
			{#if categoriesLoading}
				<Notification>Loading categories</Notification>
			{/if}
		{:then categories}
			{#if categories && categories.length}
				<Tabs>
					<TabItem on:click={() => onSelectCategory(null)}>Clear</TabItem>
					{#each categories as category (category.id)}
						<TabItem
							isActive={category.id === selectedCategoryId}
							on:click={() => onSelectCategory(category)}
						>
							{category.title}
						</TabItem>
					{/each}
				</Tabs>
			{:else}
				<Notification>No categories available</Notification>
			{/if}
		{/await}
	</div>
</div>

{#await lazyAuctionsTask}
	{#if auctionsLoading}
		<Notification>
			Loading auctions {selectedCategoryId && "for category" || ""}
		</Notification>
	{/if}
{:then auctions}
	<MyAuctionsList {auctions} />
{/await}
