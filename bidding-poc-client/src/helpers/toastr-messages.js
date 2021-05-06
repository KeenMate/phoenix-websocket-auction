import toastr from "./toastr-helpers"

export function toastBidRequested() {
	toastr.success("Bid place requested", {timeOut: "1000"})
}

export function toastCouldNotPlaceBid() {
	toastr.error("Could not place bid", {timeOut: "5000"})
}

export function toastAuctionJoined() {
	toastr.success("Auction joined!")
}

export function toastCouldNotJoinAuction() {
	toastr.error("Could not join auction")
}
