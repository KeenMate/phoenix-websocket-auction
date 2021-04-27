<script>
	import NavButton from "./NavButton.svelte"
	import {Urls} from "../../routes"

	export let displayName = ""
</script>

<NavButton link={Urls.Profile}>
	<span class="icon is-small mr-1">
	  <i class="fas fa-user"></i>
	</span>
	<span>{displayName}</span>
</NavButton>
