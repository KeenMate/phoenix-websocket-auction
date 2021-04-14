<script>
	import toastr from "../helpers/toastr-helpers"
	import {getUser, updateUser} from "../providers/socket/user"
	import UserDetailForm from "../components/user/UserDetailForm.svelte"
	import Notification from "../components/ui/Notification.svelte"

	export let params = {}

	let user = {}
	let loading = true

	$: id = params && params.id && Number(params.id)
	$: id && loadUser(id)

	function loadUser(userId) {
		if (isNaN(userId))
			return

		loading = true
		getUser(userId)
			.then(responseUser => {
				user = {
					...responseUser,
					new_password: ""
				}
			})
			.catch(error => {
				console.error("Error occured while getting user detail", error)
			})
			.finally(() => {
				loading = false
			})
	}

	function onSubmit() {
		if (loading) {
			toastr.warn("Another operation is currently running. Try it later")
			return
		}

		if (!id) {
			toastr.error("Cannot update user", "Missing required information")
			return
		}

		loading = true
		updateUser(id, user.username, user.new_password, user.is_admin)
			.then(result => {
				toastr.success("User updated!")
				console.log("Updated user: ", result)
			})
			.catch(error => {
				taostr.error("Could not update user!")
				console.error("Could not update user: ", error)
			})
		.finally(() => {
			loading = false
		})
	}
</script>

<div class="user-detail columns is-centered">
	<div class="column is-7">
		{#if loading}
			<Notification>
				Loading user...
			</Notification>
		{:else}
			<div class="actions"></div>
			<UserDetailForm
				username={user.username}
				newPassword={user.new_password || ""}
				isAdmin={user.is_admin}
				on:username={({detail: d}) => user.username = d}
				on:newPassword={({detail: d}) => user.new_password = d}
				on:isAdmin={({detail: d}) => user.is_admin = d}
				on:submit={onSubmit}
			/>
		{/if}
	</div>
</div>
