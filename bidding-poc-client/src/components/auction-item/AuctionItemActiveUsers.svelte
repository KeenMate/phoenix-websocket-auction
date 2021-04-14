<script>
	import {getUserProfileUrl} from "../../routes"

	export let users = []

	$: involvedUsers = users && users.filter(x => userJoined(x)) || []
	$: watchingUsers = users && users.filter(x => !userJoined(x)) || []

	function userJoined(user) { return user.user_joined }
</script>

<aside class="menu">
	<p class="menu-label">
		Involved users ({involvedUsers.length})
	</p>
	<ul class="menu-list">
		{#each involvedUsers as user}
			<li>
				<a href="#{getUserProfileUrl(user.id)}">
					{user.username}
				</a>
			</li>
		{/each}
	</ul>
	<p class="menu-label">
		Watching users ({watchingUsers.length})
	</p>
	<ul class="menu-list">
		{#each watchingUsers as user}
			<li>
				<a href="#{getUserProfileUrl(user.id)}">
					{user.username}
				</a>
			</li>
		{/each}
	</ul>
</aside>
