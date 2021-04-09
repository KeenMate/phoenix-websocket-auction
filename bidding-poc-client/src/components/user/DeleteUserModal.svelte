<script>
	import {createEventDispatcher} from "svelte"

	export let id = null
	export let username = "Unknown"

	const dispatch = createEventDispatcher()

	$: id && document.body.classList.toggle("is-clipped")

</script>

<div class="modal" class:is-active={!!id}>
	<div class="modal-background"></div>
	<div class="modal-card">
		<header class="modal-card-head">
			<p class="modal-card-title">Deleting user</p>
			<button class="delete" aria-label="close" on:click={() => dispatch("close")}></button>
		</header>
		<section class="modal-card-body">
			<div class="content">
				Do you really want to delete user: {username}?
			</div>
		</section>
		<footer class="modal-card-foot">
			<button class="button" on:click={() => dispatch("close")}>Cancel</button>
			<button class="button is-success" on:click={() => dispatch("confirm")}>Yes</button>
		</footer>
	</div>
</div>
