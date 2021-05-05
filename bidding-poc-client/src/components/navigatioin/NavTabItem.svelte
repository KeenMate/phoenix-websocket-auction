<script>
	import {location} from "svelte-spa-router"

	export let link = ""
</script>

<li class:is-active={$location === link}>
	<a href="{link && `#${link}` || 'javascript:void(0);'}">
		<slot />
	</a>
</li>
