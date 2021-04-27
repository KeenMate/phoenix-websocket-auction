<script>
	import {createEventDispatcher} from "svelte"
	import {Urls} from "../routes"
	import TextInput from "./forms/TextInput.svelte"

	export let username = ""
	export let password = ""

	const dispatch = createEventDispatcher()

	function onUsernameInput(ev) {
		dispatch("changeUsername", ev.detail)
	}

	function onPasswordInput(ev) {
		dispatch("changePassword", ev.detail)
	}

	function onLogin(ev) {
		ev.preventDefault()
		dispatch("login", ev.detail)
	}
</script>

<form class="login-form" on:submit={onLogin}>
	<TextInput
		value={username}
		on:input={onUsernameInput}
		label="Username"
	/>
	<TextInput
		value={password}
		on:input={onPasswordInput}
		label="Password"
		isPassword
	/>
	<div class="level">
		<div class="level-left"></div>
		<div class="level-right is-block">
			<p class="mb-2">
				Dont have an account? Register <a href="#{Urls.Register}">here</a>
			</p>
			<br>

			<button class="button is-pulled-right" type="submit">Login</button>
		</div>
	</div>
</form>
