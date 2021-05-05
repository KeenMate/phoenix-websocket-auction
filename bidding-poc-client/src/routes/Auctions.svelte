<script>
	import {push, querystring, location} from "svelte-spa-router"
	import {parse, stringify} from "qs"
	import {getAuctionCategories} from "../providers/socket/auctions"
	import {getAuctions} from "../providers/socket/auctions"
	import lazyLoader from "../helpers/lazy-loader"
	import {stringToNumber} from "../helpers/parser"
	import AuctionCategoriesMenu from "../components/auctions/AuctionCategoriesMenu.svelte"
	import AuctionItemList from "../components/auctions/AuctionItemList.svelte"
	import AuctionItemsFilters from "../components/auctions/AuctionItemsFilters.svelte"
	import Notification from "../components/ui/Notification.svelte"

	let categories = []
	let auctionsLoading = false

	$: parsedQuerystring = parse($querystring)
	$: searchText = parsedQuerystring.search || ""
	$: selectedCategory = Number(parsedQuerystring.category || "") || null
	$: page = stringToNumber(parsedQuerystring.page, 0)
	$: pageSize = stringToNumber(parsedQuerystring.pageSize, 10)

	let categoriesTask = getAuctionCategories()
		.then(ctx => {
			categories = ctx
			return ctx
		})
		.catch(error => {
			console.error("Could not load auction categories", error)
			toastr.error("Could not load auction categories")
			throw error
		})

	$: auctionItemsTask = getAuctions(searchText, selectedCategory, page, pageSize)
	$: lazyAuctionsTask = auctionItemsTask && lazyLoader(auctionItemsTask, toggleAuctionsLoading, toggleAuctionsLoading)

	function toggleAuctionsLoading() {
		auctionsLoading = !auctionsLoading
	}

	function onSelectCategory({detail: category}) {
		const newPartial = {...parsedQuerystring, category: category && category.id || undefined}

		push(`${$location}?${stringify(newPartial)}`)
	}

	function onUpdateSearchText({detail: search}) {
		push(`${$location}?${stringify({...parsedQuerystring, search})}`)
	}
</script>

<div class="columns">
	<div class="column is-2">
		<AuctionCategoriesMenu
			{categoriesTask}
			{selectedCategory}
			on:selectCategory={onSelectCategory}
		/>
	</div>
	<div class="column">
		<AuctionItemsFilters
			{searchText}
			on:updateSearchText={onUpdateSearchText}
		/>

		{#await lazyAuctionsTask}
			{#if auctionsLoading}
				<Notification>Loading auction items</Notification>
			{/if}
		{:then auctionItems}
			<AuctionItemList
				{auctionItems}
				{categories}
				{page}
				{pageSize}
			/>
		{:catch error}
			{@debug error}
			<h4 class="is-text-4">Could not load auction items</h4>
		{/await}
	</div>
</div>
