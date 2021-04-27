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
		updateUser(id, user.username, user.display_name, user.new_password, user.is_admin)
			.then(result => {
				console.log("Updated user: ", result)
				toastr.success("User updated!")
			})
			.catch(error => {
				console.error("Could not update user: ", error)
				switch (error) {
					case "forbidden":
						toastr.error("You are not allowed to change this user")
						break
					default:
						toastr.error("Could not update user!")
						break
				}
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
				displayName={user.display_name}
				newPassword={user.new_password || ""}
				isAdmin={user.is_admin}
				on:username={({detail: d}) => user.username = d}
				on:displayName={({detail: d}) => user.display_name = d}
				on:newPassword={({detail: d}) => user.new_password = d}
				on:isAdmin={({detail: d}) => user.is_admin = d}
				on:submit={onSubmit}
			/>
		{/if}
	</div>
</div>
