import Home from "./routes/Home.svelte"
import Login from "./routes/Login.svelte"
import Register from "./routes/Register.svelte"
import Profile from "./routes/Profile.svelte"
import Auctions from "./routes/Auctions.svelte"
import Users from "./routes/Users.svelte"
import UserDetail from "./routes/UserDetail.svelte"
import NewAuctionItem from "./routes/NewAuctionItem.svelte"
import AuctionItem from "./routes/AuctionItem.svelte"
import NotFound from "./routes/NotFound.svelte"

export const Urls = {
	Home: "/",
	Login: "/login",
	Register: "/register",
	Profile: "/profile",
	Auctions: "/auctions",
	Users: "/users",
	UserDetail: "/user/:id",
	NewAuctionItem: "/new-auction-item",
	AuctionItem: "/auction/:id"
}

export function getAuctionItemUrl(id) {
	return `/auction/${id}`
}

export function getUserDetailUrl(id) {
	return `/user/${id}`
}

export default {
	[Urls.Home]: Home,
	[Urls.Login]: Login,
	[Urls.Register]: Register,
	[Urls.Profile]: Profile,
	[Urls.Auctions]: Auctions,
	[Urls.Users]: Users,
	[Urls.UserDetail]: UserDetail,
	[Urls.NewAuctionItem]: NewAuctionItem,
	[Urls.AuctionItem]: AuctionItem,
	// The catch-all route must always be last
	"*": NotFound
}
