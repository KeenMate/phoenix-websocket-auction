<script>
	import {parse, stringify} from "qs"
	import {location, push, querystring} from "svelte-spa-router"
	import {socket} from "../providers/socket/common"
	import {getAuctionCategories, getMyAuctions} from "../providers/socket/auctions"
	import {userStore} from "../providers/auth"
	import {
		initAuctionBiddingChannel,
		initAuctionChannel,
		joinAuction,
		leaveAuction,
		placeBid, toggleFollow
	} from "../providers/socket/auction"
	import {stringToNumber} from "../helpers/parser"
	import lazyLoader from "../helpers/lazy-loader"
	import eventBus from "../helpers/event-bus"
	import toastr from "../helpers/toastr-helpers"
	import {
		toastAuctionJoined,
		toastBidRequested,
		toastCouldNotJoinAuction,
		toastCouldNotPlaceBid
	} from "../helpers/toastr-messages"
	import Notification from "../components/ui/Notification.svelte"
	import AuctionCategoriesMenu from "../components/auctions/AuctionCategoriesMenu.svelte"
	import AuctionItemsFilters from "../components/auctions/AuctionItemsFilters.svelte"
	import MyAuctionsList from "../components/auctions/MyAuctionsList.svelte"

	let auctions = []
	let auctionsChannels = {}
	let auctionsLoading = false
	let auctionsCounter = 1
	let categoriesTask = getAuctionCategories()

	$: parsedQuerystring = parse($querystring)
	$: searchText = parsedQuerystring.search || ""
	$: selectedCategory = Number(parsedQuerystring.category || "") || null
	$: page = stringToNumber(parsedQuerystring.page, 0)
	$: pageSize = stringToNumber(parsedQuerystring.pageSize, 10)
	$: auctionItemsTask = auctionsCounter && getMyAuctions(searchText, selectedCategory, page, pageSize)
		.then(gcExistingAuctionsResources)
		.then(initAuctionsResources)
		.then(storeCurrentAuctions)
		.catch(error => {
			console.error("Could not load my auctions")
			throw error
		})
	$: ownerAuctions = auctions && filterOwnerAuctions(auctions)
	$: joinedAuctions = auctions && filterJoinedAuctions(auctions)
	$: followedAuctions = auctions && filterFollowedAuctions(auctions)
	$: lazyAuctionsTask = auctionItemsTask && lazyLoader(
		auctionItemsTask,
		() => auctionsLoading = true,
		() => auctionsLoading = false
	)

	function storeCurrentAuctions(newAuctions) {
		auctions = newAuctions

		return newAuctions
	}

	function filterOwnerAuctions(auctions) {
		return auctions.filter(auction => auction.user_id === $userStore.id)
	}

	function filterJoinedAuctions(auctions) {
		return auctions.filter(auction => auction.user_status === "joined")
	}

	function filterFollowedAuctions(auctions) {
		return auctions.filter(auction => auction.user_status === "following" && auction.user_id !== $userStore.id)
	}

	function gcExistingAuctionsResources(newAuctions) {
		console.log("New auctions: ", newAuctions)

		auctions
			.filter(auction => !newAuctions.find(x => x.id === auction.id) && auctionsChannels[auction.id])
			.forEach(auction => {
				Object.values(auctionsChannels[auction.id].channels)
					.forEach(x => x.leave())

				auctionEventBusListeners(auction)

				delete auctionsChannels[auction.id]
			})

		return newAuctions
	}

	function initAuctionsResources(newAuctions) {
		newAuctions
			.forEach(auction => {
				auctionsChannels[auction.id] = auctionsChannels[auction.id] || {
					channels: {},
					onBidPlaced: bid => onAuctionBidPlaced(auction, bid),
					onBiddingStarted: reassignAuctions,
					onBiddingEnded: reassignAuctions,
				}

				const auctionJoined = auction.user_status === "joined"
				!auctionsChannels[auction.id].channels.auction
				&& initAuctionChannel($socket, auction.id, !auctionJoined)
					.then(channel => {
						auctionsChannels[auction.id].channels.auction = channel
					})
				auctionEventBusListeners(auction, true)

				// init bidding channel for joined auctions
				if (auctionJoined) {
					!auctionsChannels[auction.id].channels.bidding
					&& initAuctionBiddingChannel($socket, auction.id)
						.then(channel => {
							auctionsChannels[auction.id].channels.bidding = channel
						})
				}
			})

		return newAuctions
	}

	function auctionEventBusListeners(auction, add = false) {
		const fn = add && "on" || "detach"

		const action = (e, callback) =>
			eventBus[fn](e + ":" + auction.id, callback)

		action("bid_placed", auctionsChannels[auction.id].onBidPlaced)
		action("bidding_started", auctionsChannels[auction.id].onBiddingStarted)
		action("bidding_ended", auctionsChannels[auction.id].onBiddingEnded)
	}

	function reassignAuctions() {
		auctions = auctions
	}

	function onAuctionBidPlaced(auction, bid) {
		auctions = auctions.map(
			x => x.id === auction.id
				? {...x, last_bid: bid}
				: x
		)
	}

	function onSelectCategory({detail: category}) {
		const newPartial = {...parsedQuerystring, category: category && category.id || undefined}

		push(`${$location}?${stringify(newPartial)}`)
	}

	function onUpdateSearchText({detail: search}) {
		push(`${$location}?${stringify({...parsedQuerystring, search})}`)
	}

	function onPlaceBid({detail: {auction, amount}}) {
		const auctionChannels = auctionsChannels[auction.id].channels
		if (!auctionChannels || !auctionChannels.bidding) {
			console.error("Attempted to place bid for auction that does not have (bidding) channel(s)")
			return
		}

		placeBid(auctionChannels.bidding, amount)
			.then(() => {
				toastBidRequested()
			})
			.catch(error => {
				console.error("Could not place bid", error)
				toastCouldNotPlaceBid()
			})
	}

	function onJoinBidding({detail: auction}) {
		const auctionChannels = auctionsChannels[auction.id].channels
		if (!auctionChannels || !auctionChannels.auction) {
			console.error("Attempted to place bid for auction that does not have channel")
			return
		}

		// const foundIndex = currentAuctions.findIndex(x => x.id === auction.id)
		const setUserStatus = status => {
			// currentAuctions = currentAuctions
			// 	.map((x, i) => i === foundIndex ? {...x, user_status: status} : x)
			auctionsCounter++
		}
		joinAuction(auctionChannels.auction)
			.then(() => {
				toastAuctionJoined()
				console.log("Auction joined")

				setUserStatus("joined")
			})
			.catch(error => {
				console.error("Could not join auction", error)
				toastCouldNotJoinAuction()
			})
	}

	function onLeaveBidding({detail: auction}) {
		const auctionChannels = auctionsChannels[auction.id].channels
		if (!auctionChannels || !auctionChannels.auction) {
			console.error("Attempted to place bid for auction that does not have channel")
			return
		}

		// const foundIndex = currentAuctions.findIndex(x => x.id === auction.id)
		const setUserStatus = status => {
			// currentAuctions = currentAuctions
			// 	.map((x, i) => i === foundIndex ? {...x, user_status: status} : x)
			auctionsCounter++
		}

		leaveAuction(auctionChannels.auction)
			.then(result => {
				switch (result) {
					case "removed":
						toastr.success("Auction left!")
						console.log("Auction left")
						setUserStatus("nothing")
						break

					case "bidding_left":
						toastr.success("Auction is now just followed")
						console.log("Auction is now just followed")
						setUserStatus("following")
						break

					default:
						toastr.warning("Auction left (unexpected result)")
						console.log("Auction left but result is not known", result)
						setUserStatus("nothing")
						break
				}
			})
			.catch(error => {
				switch (error) {
					case "already_bidded":
						toastr.error("Could not leave auction because you have already placed bid")
						console.error("Could not leave auction because you have already placed bid")
						break

					case "not_found":
						console.error("Could not leave auction because you are not part of it")
						toastr.error("Could not leave auction because you are not part of it")
						break

					default:
						console.error("Could not leave auction", error)
						toastr.error("Could not leave auction")
						break
				}
			})
	}

	function onToggleFollow({detail: auction}) {
		const auctionChannels = auctionsChannels[auction.id].channels
		if (!auctionChannels || !auctionChannels.auction) {
			console.error("Attempted to place bid for auction that does not have channel")
			return
		}

		// const foundIndex = currentAuctions.findIndex(x => x.id === auction.id)
		const setUserStatus = status => {
			// currentAuctions = currentAuctions
			// 	.map((x, i) => i === foundIndex ? {...x, user_status: status} : x)
			auctionsCounter++
		}
		toggleFollow(auctionChannels.auction)
			.then(operation => {
				if (operation === "following") {
					toastr.success("Auction is now followed")
					// auctionItem.user_status = operation
				} else if (operation === "nothing") {
					toastr.success("Auction is not followed anymore!")
					// auctionItem.user_status = operation
				} else {
					console.warn("Received unknown result while toggle auction follow status")
					toastr.warning("Received unknown result")
				}

				setUserStatus("")
			})
			.catch(error => {
				console.error("Could not toggle watch", error)
				toastr.error("Could not toggle watch for this auction")
			})
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
		{:then _}
			<MyAuctionsList
				title="Your auctions"
				auctions={ownerAuctions}
				on:placeBid={onPlaceBid}
				on:joinBidding={onJoinBidding}
				on:leaveBidding={onLeaveBidding}
				on:toggleFollow={onToggleFollow}
			/>
			<MyAuctionsList
				title="Joined auctions"
				auctions={joinedAuctions}
				on:placeBid={onPlaceBid}
				on:joinBidding={onJoinBidding}
				on:leaveBidding={onLeaveBidding}
				on:toggleFollow={onToggleFollow}
			/>
			<MyAuctionsList
				title="Followed auctions"
				auctions={followedAuctions}
				on:placeBid={onPlaceBid}
				on:joinBidding={onJoinBidding}
				on:leaveBidding={onLeaveBidding}
				on:toggleFollow={onToggleFollow}
			/>
		{:catch error}
			{@debug error}
			<h4 class="is-text-4">Could not load auction items</h4>
		{/await}
	</div>
</div>

