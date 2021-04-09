<script>
	import {registerUser} from "../providers/user"
	import TextInput from "../components/forms/TextInput.svelte"
	import Notification from "../components/ui/Notification.svelte"
	import {UserExistsError} from "../providers/exceptions"

	let username = ""
	let password = ""
	let passwordAgain = ""
	let registrationTask = null
	let loading = false

	async function onRegister(ev) {
		ev.preventDefault()
		if (loading)
			return
		if (!username || !password || !passwordAgain || (password !== passwordAgain)) {
			alert("Registration form filled incorrectly")
			return
		}

		loading = true
		registrationTask = registerUser(username, password)
			.finally(() => {
				loading = false
			})
	}
</script>

<section class="register-page">
	<div class="columns is-centered">
		<div class="column is-4">
			<h4 class="is-text-4">
				Registration
			</h4>
			<form class="register-form" on:submit={onRegister}>
				<TextInput
					value={username}
					on:input={({detail}) => username = detail}
					label="Username"
				/>
				<TextInput
					value={password}
					on:input={({detail}) => password = detail}
					label="Password"
					isPassword
				/>
				<TextInput
					value={passwordAgain}
					on:input={({detail}) => passwordAgain = detail}
					label="Password again"
					isPassword
				/>
				<div class="is-clearfix">
					<button
						class="button is-pulled-right"
						type="submit"
						disabled={loading}
					>
						Register
					</button>
				</div>
				<br>
				{#if registrationTask}
					{#await registrationTask}
						<Notification>Registering user</Notification>
					{:then response}
						{@debug response}
						<Notification>User: {response.user.username} created!</Notification>
					{:catch error}
						{@debug error}
						{#if error instanceof UserExistsError}
							<Notification>Could not register because user with given username already exists!</Notification>
						{:else}
							<Notification>Error occured while creating user</Notification>
						{/if}
					{/await}
				{/if}
			</form>
		</div>
	</div>
</section>
