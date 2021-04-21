<script>
	import {getUserEditUrl} from "../../routes"
	import Notification from "../ui/Notification.svelte"
	import DeleteUserModal from "./DeleteUserModal.svelte"

	export let users = []
	export let page = 0
	export let pageSize = 10

	let userToDelete = null

	function onDeleteUser(user) {
		// todo: Show modal confirmation
		// toastr.warning("Not implemented")

		userToDelete = user
	}

	function deleteUser() {
		const callback = () => {
			userToDelete = null
		}
		dispatch("deleteUser", {user: userToDelete, callback})
	}
</script>

{#if users && users.length}
	<table class="table is-fullwidth">
		<thead>
		<tr>
			<th>Username</th>
			<th class="has-text-right">Actions</th>
		</tr>
		</thead>
		<tbody>
		{#each users as user (user.id)}
			<tr>
				<td>
					<a href="#{getUserEditUrl(user.id)}">
						{user.display_name}
					</a>
				</td>
				<td>
					<div class="columns is-multiline is-flex is-flex-direction-row is-justify-content-flex-end">
						<div class="column is-narrow">
							<button class="button is-small is-danger" on:click={() => onDeleteUser(user)}>
								Delete
							</button>
						</div>
					</div>
				</td>
			</tr>
		{/each}
		</tbody>
	</table>
{:else}
	<Notification>
		No users found
	</Notification>
{/if}

<DeleteUserModal
	{...userToDelete}
	on:close={() => userToDelete = null}
	on:confirm={deleteUser}
/>
