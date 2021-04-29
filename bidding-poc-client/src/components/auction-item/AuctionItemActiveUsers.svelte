<script>
	import UserLink from "./UserLink.svelte"

	export let users = []

	$: biddingUsers = users && users.filter(x => x.user_status === "joined") || []
	$: followingUsers = users && users.filter(x => x.user_status === "following") || []
</script>

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
		Following users ({followingUsers.length})
	</p>
	<ul class="menu-list">
		{#each followingUsers as user}
			<li>
				<UserLink {user} />
			</li>
		{/each}
	</ul>
</aside>
