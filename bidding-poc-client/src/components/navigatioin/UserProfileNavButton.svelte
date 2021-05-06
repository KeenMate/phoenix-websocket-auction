<script>
	import {Urls} from "../../routes"
	import NavTabItem from "./NavTabItem.svelte"
	import {socketConnected} from "../../providers/socket/common"

	export let displayName = ""
</script>

<NavTabItem link={Urls.Profile}>
	<span class="icon is-small mr-1">
		{#if $socketConnected}
		  <i class="fas fa-user"></i>
		{:else}
			<i
				class="fas fa-exclamation-triangle has-text-danger"
				title="Connection is not available"
			></i>
		{/if}
	</span>
	<span>{displayName}</span>
</NavTabItem>
