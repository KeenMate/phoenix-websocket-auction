<script>
	import {push} from "svelte-spa-router"
	import {logout, userStore} from "../providers/auth"
	import {getUserAuctions, getUserAuctionsCategories} from "../providers/socket/auctions"
	import {getUser} from "../providers/socket/user"
	import ProfileInfo from "../components/profile/ProfileInfo.svelte"
	import UserAuctions from "../components/profile/UserAuctions.svelte"
	import Notification from "../components/ui/Notification.svelte"

	export let params = {}

	let selectedCategoryId = null

	$: parsedUserId = (params.userId && Number(params.userId))
	$: computedUserId = parsedUserId || ($userStore && $userStore.id)
	$: computedUserTask = (!params.userId && $userStore && Promise.resolve($userStore)) || (parsedUserId && getUser(parsedUserId))

	$: categoriesTask = computedUserId && getUserAuctionsCategories(computedUserId)
	$: auctionsTask = computedUserId && getUserAuctions(computedUserId, selectedCategoryId)

	function logoutUser() {
		logout()

		push("/")
	}

	function onSelectCategory({detail: category}) {
		selectedCategoryId = category && category.id
	}
</script>

<div class="columns">
	<div class="column is-4">
		{#await computedUserTask}
			<Notification>Loading user</Notification>
		{:then theUser}
			<ProfileInfo user={theUser} />
		{/await}

		<!-- todo: Render last user's actions (bids, new (-un-)follows etc..) only if user is friend -->
	</div>
	<div class="column">
		<div class="columns is-justify-content-flex-end">
			<div class="column is-narrow">
				<button class="button is-warning" on:click={logoutUser}>
					Logout
				</button>
			</div>
		</div>

		<UserAuctions
			{auctionsTask}
			{categoriesTask}
			{selectedCategoryId}
			on:selectCategory={onSelectCategory}
		/>
	</div>
</div>

