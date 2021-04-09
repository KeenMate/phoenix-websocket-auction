<script>
	import flashes, {removeFlash} from "../../stores/flashes"
	import FlashIcon from "./FlashIcon.svelte"
	import NavButton from "./NavButton.svelte"

	function getFlashColor(flash) {
		switch (flash.type) {
			case "success":
				return "has-text-success"
			case "warning":
				return "has-text-warning"
			case "error":
				return "has-text-danger"
			case "info":
				return "has-text-link"
			default:
				return "has-text-black"
		}
	}
</script>

{#if !$flashes.length}
	<NavButton>
		System messages
	</NavButton>
{:else}
	<div class="navbar-item has-dropdown is-hoverable">
		<a class="navbar-link">
			System messages
		</a>

		<div class="navbar-dropdown">
			{#each $flashes as flash (flash.id)}
				<a class="navbar-item {getFlashColor(flash)}">
					<FlashIcon type={flash.type} />
					<button class="delete" on:click={() => removeFlash(flash)}></button>
					{flash.message}
				</a>
			{/each}
		</div>
	</div>
{/if}
