<script>
	import {location} from "svelte-spa-router"
	import {Urls} from "../../routes"
	import NavButton from "./NavButton.svelte"
	import UserProfileNavButton from "./UserProfileNavButton.svelte"
	import HamburgerButton from "./HamburgerButton.svelte"
	import BrandLogo from "./BrandLogo.svelte"
	import NavigationFlashes from "./NavigationFlashes.svelte"

	export let user = {}

	$: hideLoginButton = $location === Urls.Login
	$: hideRegisterButton = $location === Urls.Register

</script>

<nav class="navbar" role="navigation" aria-label="main navigation">
	<div class="navbar-brand">
		<BrandLogo />
		<HamburgerButton />
	</div>

	<div id="navbarBasicExample" class="navbar-menu">
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
			<NavigationFlashes />
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
