<script>
	import {push, querystring, location} from "svelte-spa-router"
	import {parse, stringify} from "qs"
	import {deleteUser, getUsers} from "../providers/socket/user"
	import {stringToNumber} from "../helpers/parser"
	import Notification from "../components/ui/Notification.svelte"
	import UsersFilters from "../components/user/UsersFilters.svelte"
	import UsersList from "../components/user/UsersList.svelte"

	$: parsedQuerystring = parse($querystring)
	$: searchText = parsedQuerystring.search || ""
	$: page = stringToNumber(parsedQuerystring.page, 0)
	$: pageSize = stringToNumber(parsedQuerystring.pageSize, 10)

	// var today = new Date()

	// $: usersTask = getUsers(searchText, page, pageSize)
	let usersTask
	$: (searchText || page || pageSize) ? loadUsers() : loadUsers()

	function loadUsers() {
		usersTask = getUsers(searchText, page, pageSize)
	}

	function onUpdateSearchText({detail: search}) {
		push(`${$location}?${stringify({...parsedQuerystring, search})}`)
	}

	function onDeleteUser({user, callback}) {
		deleteUser(user.id)
			.then(() => {
				callback()
				loadUsers()
			})
	}
</script>

<div class="columns is-centered">
	<div class="column is-7">
		<UsersFilters
			{searchText}
			on:updateSearchText={onUpdateSearchText}
		/>

		{#await usersTask}
			<Notification>Loading users</Notification>
		{:then users}
			<UsersList
				{users}
				{page}
				{pageSize}
				on:deleteUser={onDeleteUser}
			/>
		{:catch error}
			{@debug error}
			<h4 class="is-text-4">Could not load users</h4>
		{/await}
	</div>
</div>
