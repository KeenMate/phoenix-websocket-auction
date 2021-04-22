<script>
	import {userStore} from "../../providers/auth"
	import {getUserProfileUrl} from "../../routes"

	export let user = {}

	$: currentUserId = $userStore && $userStore.id
	$: isCurrentUser = user.id === currentUserId
</script>

<a
	href="#{getUserProfileUrl(user.id)}"
	class:is-active={isCurrentUser}
>
	{user.display_name}
	{#if isCurrentUser}
		(You)
	{/if}
</a>
