<script>
	import {location} from "svelte-spa-router"
	import {Urls} from "../../routes"
	import UserProfileNavButton from "./UserProfileNavButton.svelte"
	import HamburgerButton from "./HamburgerButton.svelte"
	import BrandLogo from "./BrandLogo.svelte"
	// import NavigationNotifications from "./NavigationNotifications.svelte"
	import NavTabItem from "./NavTabItem.svelte"
	import Tabs from "../ui/Tabs.svelte"

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

		<div class="navbar-end">
			<Tabs isNavbar>
				{#if user}
					<NavTabItem link={Urls.MyAuctions}>
						My auctions
					</NavTabItem>
					<NavTabItem link={Urls.Auctions}>
						Auctions
					</NavTabItem>
					<NavTabItem link={Urls.NewAuctionItem}>
						New auction item
					</NavTabItem>
					{#if user.is_admin}
						<NavTabItem link={Urls.Users}>
							Users
						</NavTabItem>
					{/if}
					<UserProfileNavButton displayName={user.display_name} />
				{/if}
			</Tabs>
			<!--<NavigationNotifications />-->
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
				{/if}
			</div>
		</div>
	</div>
</nav>

