<script>
	import UserLink from "./UserLink.svelte"

	export let users = []

	$: biddingUsers = users && users.filter(x => userJoined(x)) || []
	$: watchingUsers = users && users.filter(x => !userJoined(x)) || []

	function userJoined(user) {
		return user.user_status === "joined"
	}
</script>

<!--{@debug users}-->
<aside class="menu">
	<p class="menu-label">
		Bidding users ({biddingUsers.length})
	</p>
	<ul class="menu-list">
		{#each biddingUsers as user}
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
