<script>
	import {get} from "svelte/store"
	import Router, {push} from "svelte-spa-router"
	import {stringify} from "qs"
	import toastr from "./helpers/toastr-helpers"
	import routes, {Urls} from "./routes"
	import {authTokenStore, userStore} from "./providers/auth"
	import {auctionsChannel, initAuctionsChannel} from "./providers/socket/auctions"
	import {initUserChannel, initUsersChannel, usersChannel} from "./providers/socket/user"
	import {getCurrentUser} from "./providers/user"
	import {createSocket, socket, socketConnected} from "./providers/socket/common"
	import Navigation from "./components/navigatioin/Navigation.svelte"
	import {onDestroy, onMount} from "svelte"
	import eventBus from "./helpers/event-bus"

	$: $authTokenStore && onAuthToken($authTokenStore)

	async function onRouteLoading(ev) {
		const {detail: route} = ev

		console.log("route: ", route)
		if ([Urls.Login, Urls.Register].includes(route.route))
			return

		if (!$authTokenStore) {
			const query = stringify({redirect: route.location})
			push(`${Urls.Login}?${query}`)
			return
		}
	}

	function onAuthToken(token) {
		initUser(token).then(() => {
			initSocket(token)
		})
	}

	async function initUser(token) {
		if (!$authTokenStore)
			return

		try {
			const result = await getCurrentUser(token)
			if (result instanceof Response) {
				toastr.error("Could not load current user info")
			} else {
				console.log("Current user: ", result)
				userStore.set(result)
			}
		} catch (error) {
			console.error("Could not load user", error)
			toastr.error("Could not load current profile")

			throw error
		}
	}

	function initSocket(token) {
		try {
			const newSocket = createSocket(token)
			socket.set(newSocket)
			newSocket.connect()

			initAuctionsChannel(newSocket).then(auctionsChannel.set)
			initUsersChannel(newSocket).then(usersChannel.set)
			console.log("User is", get(userStore))
			initUserChannel(
				newSocket,
				get(userStore).id
			)
		} catch (error) {
			console.error("Could not init socket: ", error)
			toastr.error("Could not initiate real-time connection to the server")
		}
	}

	function onBiddingStarted(auction) {

	}
	function onBiddingEnded(auction) {

	}
	function onBidOverbidded(auction) {

	}

	function eventBusListeners(add = false) {
		const fn = add && "on" || "detach"

		const action = (e, callback) =>
			eventBus[fn](e  + ":*", callback)

		action("bidding_started", onBiddingStarted)
		action("bidding_ended", onBiddingEnded)
		action("bid_overbidded", onBidOverbidded)
	}

	onMount(() => {
		eventBusListeners(true)
	})

	onDestroy(() => {
		eventBusListeners()
	})
</script>

<Navigation user={$userStore} />
<main class="mt-3">
	<div class="container is-fluid">
		<Router
			{routes}
			on:routeLoading={onRouteLoading}
		/>
	</div>
</main>
