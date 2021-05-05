<script>
	export let href = null
	export let isActive = false
</script>

<li class:is-active={isActive} on:click>
	<a {href}>
		<slot />
	</a>
</li>
