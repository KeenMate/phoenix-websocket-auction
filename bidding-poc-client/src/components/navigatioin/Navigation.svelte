<script>
	import {location} from "svelte-spa-router"
	import {Urls} from "../../routes"
	import NavButton from "./NavButton.svelte"
	import UserProfileNavButton from "./UserProfileNavButton.svelte"
	import HamburgerButton from "./HamburgerButton.svelte"
	import BrandLogo from "./BrandLogo.svelte"
	import NavigationNotifications from "./NavigationNotifications.svelte"

	export let user = {}

	let navExpanded = false

	$: hideLoginButton = $location === Urls.Login
	$: hideRegisterButton = $location === Urls.Register

	function toggleNav() {
		navExpanded = !navExpanded
	}
</script>

<nav class="navbar" role="navigation" aria-label="main navigation">
	<div class="navbar-brand">
		<BrandLogo />
		<HamburgerButton {navExpanded} on:click={toggleNav} />
	</div>

	<div id="navbarBasicExample" class="navbar-menu" class:is-active={navExpanded}>
		<div class="navbar-start">
			<NavButton link={Urls.Auctions}>
				Auctions
			</NavButton>

			{#if user}
				<NavButton link={Urls.NewAuctionItem}>
					New auction item
				</NavButton>
			{/if}

			{#if user && user.is_admin}
				<NavButton link={Urls.Users}>
					Users
				</NavButton>
			{/if}
		</div>

		<div class="navbar-end">
			<NavigationNotifications />
			<div class="navbar-item">
				{#if !user}
					<div class="buttons">
						{#if !hideRegisterButton}
							<a class="button is-primary" href="#/register">
								<strong>Sign up</strong>
							</a>
						{/if}
						{#if !hideLoginButton}
							<a class="button is-light" href="#/login">
								Log in
							</a>
						{/if}
					</div>
				{:else}
					<UserProfileNavButton displayName={user.display_name} />
				{/if}
			</div>
		</div>
	</div>
</nav>
