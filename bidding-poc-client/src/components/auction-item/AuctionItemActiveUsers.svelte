<script>
	import UserLink from "./UserLink.svelte"

	export let users = []

	$: activeUserIds = users && users.filter(x => x.activeInstance).map(x => x.auctionUser.id)
	$: biddingUsers = users && users.filter(x => x.auctionUser.user_status === "joined") || []
	$: followingUsers = users && users.filter(x => x.auctionUser.user_status === "following") || []

	function userIsActive(user) {
		return !!activeUserIds.find(x => x === user.auctionUser.id)
	}
</script>

<aside class="menu">
	<p class="menu-label">
		Bidding users ({biddingUsers.length})
	</p>
	<ul class="menu-list">
		{#each biddingUsers as user}
			<li>
				<UserLink user={user.auctionUser} isActive={userIsActive(user)} />
			</li>
		{/each}
	</ul>
	<p class="menu-label">
		Following users ({followingUsers.length})
	</p>
	<ul class="menu-list">
		{#each followingUsers as user}
			<li>
				<UserLink user={user.auctionUser} isActive={userIsActive(user)} />
			</li>
		{/each}
	</ul>
</aside>
