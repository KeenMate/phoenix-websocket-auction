<script>
	import {Urls} from "../../routes"
	import NavTabItem from "./NavTabItem.svelte"

	export let displayName = ""
</script>

<NavTabItem link={Urls.Profile}>
	<span class="icon is-small mr-1">
	  <i class="fas fa-user"></i>
	</span>
	<span>{displayName}</span>
</NavTabItem>
