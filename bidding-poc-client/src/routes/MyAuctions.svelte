<script>
	import {parse, stringify} from "qs"
	import {location, push, querystring} from "svelte-spa-router"
	import {stringToNumber} from "../helpers/parser"
	import lazyLoader from "../helpers/lazy-loader"
	import {getAuctionCategories, getMyAuctions} from "../providers/socket/auctions"
	import {userStore} from "../providers/auth"
	import Notification from "../components/ui/Notification.svelte"
	import AuctionCategoriesMenu from "../components/auctions/AuctionCategoriesMenu.svelte"
	import AuctionItemsFilters from "../components/auctions/AuctionItemsFilters.svelte"
	import MyAuctionsList from "../components/auctions/MyAuctionsList.svelte"

	// let auction = {
	// 	title: "Dummy auction",
	// 	category: "Dummy category 1",
	// 	bidding_end: "2021-05-03T11:12:15Z"
	//  lastBid: {amount: 123}
	// }

	// let categories = []
	let ownerAuctions = []
	let joinedAuctions = []
	let followedAuctions = []
	let auctionsLoading = false

	let categoriesTask = getAuctionCategories()
	// .then(ctx => categories = ctx)
	// .catch(error => {
	// 	console.error("Could not load auction categories", error)
	// 	toastr.error("Could not load auction categories")
	// 	throw error
	// })

	$: parsedQuerystring = parse($querystring)
	$: searchText = parsedQuerystring.search || ""
	$: selectedCategory = Number(parsedQuerystring.category || "") || null
	$: page = stringToNumber(parsedQuerystring.page, 0)
	$: pageSize = stringToNumber(parsedQuerystring.pageSize, 10)
	$: auctionItemsTask = getMyAuctions(searchText, selectedCategory, page, pageSize)
		.then(bucketAuctions)
		.catch(error => {
			console.error("Could not load my auctions")
			throw error
		})
	$: lazyAuctionsTask = auctionItemsTask && lazyLoader(auctionItemsTask, toggleAuctionsLoading, toggleAuctionsLoading)

	function toggleAuctionsLoading() {
		auctionsLoading = !auctionsLoading
	}

	// todo: Init socket channels for each active, joined auction (with self-destruction :))

	function bucketAuctions(auctions) {
		const ownerAuctionsLocal = []
		const joinedAuctionsLocal = []
		const followedAuctionsLocal = []

		auctions.forEach(x => {
			if (x.user_id === $userStore.id)
				ownerAuctionsLocal.push(x)
			else if (x.user_status === "joined")
				joinedAuctionsLocal.push(x)
			else if (x.user_status === "following")
				followedAuctionsLocal.push(x)
			else
				console.warn("This auction is 'my auction' but it could not be categorized", x)
		})

		ownerAuctions = ownerAuctionsLocal
		joinedAuctions = joinedAuctionsLocal
		followedAuctions = followedAuctionsLocal
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
		{#await auctionItemsTask}
			{#if auctionsLoading}
				<Notification>Loading auction items</Notification>
			{/if}
		{:then _}
			<MyAuctionsList title="Your auctions" auctions={ownerAuctions} />
			<MyAuctionsList title="Joined auctions" auctions={joinedAuctions} />
			<MyAuctionsList title="Followed auctions" auctions={followedAuctions} />
		{:catch error}
			{@debug error}
			<h4 class="is-text-4">Could not load auction items</h4>
		{/await}
	</div>
</div>

