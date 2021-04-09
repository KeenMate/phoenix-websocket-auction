<script>
	import {createEventDispatcher} from "svelte"
	import Notification from "../ui/Notification.svelte"

	export let categories = []
	export let selectedCategory = null

	const dispatch = createEventDispatcher()

	function onSelectCategory(category) {
		dispatch("selectCategory", category)
	}

	function clearSelection() {
		onSelectCategory(null)
	}
</script>

<aside class="menu">
	<p class="menu-label">
		Categories actions
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
		{#each categories as category}
			<li on:click={() => onSelectCategory(category)}>
				<a class:is-active={category === selectedCategory}>
					{category || "Unknown category"}
				</a>
			</li>
		{:else}
			<Notification>
				No categories available
			</Notification>
		{/each}
	</ul>
</aside>
