<script>
	import AuctionQuickCard from "../components/auction-item/AuctionQuickCard.svelte"
	import {parse, stringify} from "qs"
	import {location, push, querystring} from "svelte-spa-router"
	import {stringToNumber} from "../helpers/parser"
	import {getAuctionCategories, getMyAuctions} from "../providers/socket/auctions"
	import Notification from "../components/ui/Notification.svelte"
	import AuctionCategoriesMenu from "../components/auctions/AuctionCategoriesMenu.svelte"
	import AuctionItemsFilters from "../components/auctions/AuctionItemsFilters.svelte"

	// let auction = {
	// 	title: "Dummy auction",
	// 	category: "Dummy category 1",
	// 	bidding_end: "2021-05-03T11:12:15Z"
	//  lastBid: {amount: 123}
	// }

	let categories = []

	let categoriesTask = getAuctionCategories()
		.then(ctx => categories = ctx)
		.catch(error => {
			console.error("Could not load auction categories", error)
			toastr.error("Could not load auction categories")
			throw error
		})

	$: parsedQuerystring = parse($querystring)
	$: searchText = parsedQuerystring.search || ""
	$: selectedCategory = Number(parsedQuerystring.category || "") || null
	$: page = stringToNumber(parsedQuerystring.page, 0)
	$: pageSize = stringToNumber(parsedQuerystring.pageSize, 10)
	$: auctionItemsTask = getMyAuctions(searchText, selectedCategory, page, pageSize)
	// todo: Init socket channels for each active, joined auction (with self-destruction :))

	// $: auctionsWithCategoriesTask = auctionItemsTask && categoriesTask && Promise.all([auctionItemsTask, categoriesTask])
	// 	.then(([auctions, cats]) => {
	// 		return auctions.map(x => {
	// 			return {
	// 				...x,
	// 				category: cats.find(c => c.id === x.category_id)
	// 			}
	// 		})
	// 	})

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
			<div class="columns is-multiline">
				{#each auctionItems as auction}
					<div class="column is-3">
						<!-- todo: Add event listeners -->
						<AuctionQuickCard
							{auction}
							lastBid={auction.lastBid}
						/>
					</div>
				{/each}
			</div>
		{:catch error}
			{@debug error}
			<h4 class="is-text-4">Could not load auction items</h4>
		{/await}
	</div>
</div>

