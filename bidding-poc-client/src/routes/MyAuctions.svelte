<script>
	import {push, querystring, location} from "svelte-spa-router"
	import {parse, stringify} from "qs"
	import {getAuctionCategories} from "../providers/socket/auctions"
	import {getAuctions} from "../providers/socket/auctions"
	import {stringToNumber} from "../helpers/parser"
	import AuctionCategoriesMenu from "../components/auctions/AuctionCategoriesMenu.svelte"
	import AuctionItemList from "../components/auctions/AuctionItemList.svelte"
	import AuctionItemsFilters from "../components/auctions/AuctionItemsFilters.svelte"
	import Notification from "../components/ui/Notification.svelte"

	let categories = []

	$: parsedQuerystring = parse($querystring)
	$: searchText = parsedQuerystring.search || ""
	$: selectedCategory = Number(parsedQuerystring.category || "") || null
	$: page = stringToNumber(parsedQuerystring.page, 0)
	$: pageSize = stringToNumber(parsedQuerystring.pageSize, 10)

	let categoriesTask = getAuctionCategories()
		.then(ctx => categories = ctx)
		.catch(error => {
			console.error("Could not load auction categories", error)
			toastr.error("Could not load auction categories")
		})
	$: auctionItemsTask = getAuctions(searchText, selectedCategory, page, pageSize)

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
		{#await categoriesTask}
			<Notification>Loading categories</Notification>
		{:then _}
			<AuctionCategoriesMenu
				{categories}
				{selectedCategory}
				on:selectCategory={onSelectCategory}
			/>
		{:catch error}
			{@debug error}
			<h4 class="is-text-4">Could not load categories</h4>
		{/await}
	</div>
	<div class="column">
		<AuctionItemsFilters
			{searchText}
			on:updateSearchText={onUpdateSearchText}
		/>

		{#await auctionItemsTask}
			<Notification>Loading auction items</Notification>
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
