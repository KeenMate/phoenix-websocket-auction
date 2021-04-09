<script>
	import {push, querystring, location} from "svelte-spa-router"
	import {parse, stringify} from "qs"
	import {getAuctionCategories} from "../providers/auctions"
	import {getAuctionItems} from "../providers/socket/auction"
	import {stringToNumber} from "../helpers/parser"
	import AuctionCategoriesMenu from "../components/auction/AuctionCategoriesMenu.svelte"
	import AuctionItemList from "../components/auction/AuctionItemList.svelte"
	import AuctionItemsFilters from "../components/auction/AuctionItemsFilters.svelte"
	import Notification from "../components/ui/Notification.svelte"

	$: parsedQuerystring = parse($querystring)
	$: searchText = parsedQuerystring.search || ""
	$: selectedCategory = parsedQuerystring.category || ""
	$: page = stringToNumber(parsedQuerystring.page, 1)
	$: pageSize = stringToNumber(parsedQuerystring.pageSize, 10)

	let categoriesTask = getAuctionCategories()
	$: auctionItemsTask = getAuctionItems(searchText, selectedCategory, page, pageSize)

	function onSelectCategory({detail: category}) {
		push(`${$location}?${stringify({...parsedQuerystring, category})}`)
	}

	function onUpdateSearchText({detail: search}) {
		push(`${$location}?${stringify({...parsedQuerystring, search})}`)
	}
</script>

<div class="columns">
	<div class="column is-2">
		{#await categoriesTask}
			<Notification>Loading categories</Notification>
		{:then categories}
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
				{page}
				{pageSize}
			/>
		{:catch error}
			{@debug error}
			<h4 class="is-text-4">Could not load auction items</h4>
		{/await}
	</div>
</div>
