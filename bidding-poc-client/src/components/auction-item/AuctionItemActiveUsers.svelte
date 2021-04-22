<script>
	import UserLink from "./UserLink.svelte"

	export let users = []

	$: involvedUsers = users && users.filter(x => userJoined(x)) || []
	$: watchingUsers = users && users.filter(x => !userJoined(x)) || []

	function userJoined(user) {
		return user.user_joined
	}
</script>

<aside class="menu">
	<p class="menu-label">
		Involved users ({involvedUsers.length})
	</p>
	<ul class="menu-list">
		{#each involvedUsers as user}
			<li>
				<UserLink {user} />
			</li>
		{/each}
	</ul>
	<p class="menu-label">
		Watching users ({watchingUsers.length})
	</p>
	<ul class="menu-list">
		{#each watchingUsers as user}
			<li>
				<UserLink {user} />
			</li>
		{/each}
	</ul>
</aside>
