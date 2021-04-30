<script>
	import {userStore} from "../../providers/auth"
	import {getUserProfileUrl} from "../../routes"

	export let user = {}
	export let isActive = false

	$: currentUserId = $userStore && $userStore.id
	$: isCurrentUser = user.id === currentUserId
</script>

<a href="#{getUserProfileUrl(user.id)}">
	{user.display_name}
	{#if isCurrentUser}
		(You)
	{/if}
	{#if isActive}
		<span class="tag is-rounded is-light is-success">
			Present
		</span>
	{/if}
</a>
