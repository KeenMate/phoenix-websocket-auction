<script>
	import {createEventDispatcher} from "svelte"
	import Notification from "../ui/Notification.svelte"
	import lazyLoader from "../../helpers/lazy-loader"

	export let categoriesTask = null
	export let selectedCategory = null

	const dispatch = createEventDispatcher()

	let categoriesLoading = false

	$: lazyCategoriesTask = categoriesTask && lazyLoader(categoriesTask, toggleCategoriesLoading, toggleCategoriesLoading)

	function toggleCategoriesLoading() {
		toggleCategoriesLoading = !toggleCategoriesLoading
	}

	function onSelectCategory(category) {
		dispatch("selectCategory", category)
	}

	function clearSelection() {
		onSelectCategory(null)
	}
</script>

<aside class="menu">
	<p class="menu-label">
		Auction categories
	</p>
	<ul class="menu-list">
		<li on:click={clearSelection}>
			<a>
				Clear category filter
			</a>
		</li>
	</ul>
	<p class="menu-label">
		Categories
	</p>
	<ul class="menu-list">
		{#await lazyCategoriesTask}
			{#if categoriesLoading}
				<Notification>Loading categories</Notification>
			{/if}
		{:then categories}
			{#each categories as category (category.id)}
				<li on:click={() => onSelectCategory(category)}>
					<a class:is-active={category.id === selectedCategory}>
						{category.title || "Unknown category"}
					</a>
				</li>
			{:else}
				<Notification>
					No categories available
				</Notification>
			{/each}

		{:catch error}
			{@debug error}
			<h4 class="is-text-4">Could not load categories</h4>
		{/await}
	</ul>
</aside>
