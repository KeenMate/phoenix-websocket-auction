<script>
	import {logout} from "../providers/auth"
	import {push} from "svelte-spa-router"

	function logoutUser() {
		logout()

		push("/")
	}
</script>

<button class="button is-warning" on:click={logoutUser}>
	Logout
</button>
