<script>
	import {createEventDispatcher} from "svelte"
	import toastr from "../../helpers/toastr-helpers"
	import TextInput from "../forms/TextInput.svelte"
	import Checkbox from "../forms/Checkbox.svelte"

	const dispatch = createEventDispatcher()

	export let username = ""
	export let displayName = ""
	export let newPassword = ""
	export let isAdmin = false

	let confirmNewPassword = ""

	function onSubmit(ev) {
		ev.preventDefault()

		if (!username) {
			toastr.error("Username must be filled!")
			return
		}

		if (newPassword && newPassword !== confirmNewPassword) {
			toastr.error("New password and password confirmation must match")
			return
		}

		dispatch("submit")
	}
</script>

<form class="user-detail-form" on:submit={onSubmit}>
	<div class="columns">
		<div class="column">
			<TextInput label="Username" value={username} on:input={({detail: d}) => dispatch("username", d)} />
		</div>
		<div class="column">
			<TextInput label="Display name" value={displayName} on:input={({detail: d}) => dispatch("displayName", d)} />
		</div>
	</div>

	<div class="columns">
		<div class="column">
			<TextInput
				label="New password"
				value={newPassword}
				isPassword
				on:input={({detail: d}) => dispatch("newPassword", d)}
			/>
		</div>
		<div class="column">
			<TextInput
				label="Confirm new password"
				value={confirmNewPassword}
				isPassword
				on:input={({detail: d}) => confirmNewPassword = d}
			/>
		</div>
	</div>

	<div class="level">
		<div class="level-left">
			<Checkbox
				label="Is admin"
				checked={isAdmin} on:change={({detail: d}) => dispatch("isAdmin", d)}
			/>
		</div>
		<div class="level-right">
			<button class="button is-success">
				Save
			</button>
		</div>
	</div>
</form>
