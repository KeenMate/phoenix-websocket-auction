<script>
	import {onMount} from "svelte"
	import Router, {push} from "svelte-spa-router"
	import {stringify} from "qs"
	import toastr from "./helpers/toastr-helpers"
	import routes, {Urls} from "./routes"
	import {authTokenStore, userStore} from "./providers/auth"
	import {auctionChannel, initAuctionChannel} from "./providers/socket/auction"
	import {getCurrentUser} from "./providers/user"
	import {createSocket, socket} from "./providers/socket/common"
	import {addFlash} from "./stores/flashes"
	import Navigation from "./components/navigatioin/Navigation.svelte"
	import {initUsersChannel, usersChannel} from "./providers/socket/user"

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

	async function loadUser() {
		if (!$authTokenStore)
			return

		try {
			const result = await getCurrentUser($authTokenStore)
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

	function initSocket() {
		const newSocket = createSocket($authTokenStore)
		socket.set(newSocket)
		newSocket.connect()

		initAuctionChannel(newSocket).then(auctionChannel.set)
		initUsersChannel(newSocket).then(usersChannel.set)
	}

	onMount(async () => {
		try {
			if (!$userStore)
				await loadUser()

			initSocket()
		} catch (error) {
			console.error("Could not init socket connection", error)
			addFlash("Could not initiate real-time connection")
		}
	})
</script>

<Navigation user={$userStore} />
<main>
	<div class="container is-fluid">
		<Router
			{routes}
			on:routeLoading={onRouteLoading}
		/>
	</div>
</main>
