<script>
	import Router, {push} from "svelte-spa-router"
	import {stringify} from "qs"
	import toastr from "./helpers/toastr-helpers"
	import routes, {Urls} from "./routes"
	import {authTokenStore, userStore} from "./providers/auth"
	import {auctionChannel, initAuctionChannel} from "./providers/socket/auction"
	import {getCurrentUser} from "./providers/user"
	import {createSocket, socket} from "./providers/socket/common"
	import Navigation from "./components/navigatioin/Navigation.svelte"
	import {initUsersChannel, usersChannel} from "./providers/socket/user"

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
		initUser(token)
		initSocket(token)
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
	
	function dummyChannel(newSocket) {
		// const dummy1 = newSocket.channel("dummy:", {})
		// dummy1.on("tick", () => {
		// 	console.log("Dummy1 ticked")
		// })
		// dummy1.join()
		//
		// const dummy2 = newSocket.channel("dummy:blocking", {})
		// dummy2.join()
		// .receive("ok", () => {
		// 	setTimeout(() => {
		// 		console.log("Starting Req/Res")
		// 		dummy2.push("get", {})
		// 			.receive("ok", ctx => {
		// 				console.log("Response", ctx)
		// 			})
		// 		.receive("timeout", () => {
		// 			console.log("Timed out!")
		// 		})
		// 	}, 2000)
		// })
	}

	function initSocket(token) {
		try {
			const newSocket = createSocket(token)
			socket.set(newSocket)
			newSocket.connect()

			initAuctionChannel(newSocket).then(auctionChannel.set)
			initUsersChannel(newSocket).then(usersChannel.set)
			
			dummyChannel(newSocket)
		} catch (error) {
			console.error("Could not init socket: ", error)
			toastr.error("Could not initiate real-time connection to the server")
		}
	}
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
