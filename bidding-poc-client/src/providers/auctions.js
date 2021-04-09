import {makeRequest, parseResponse} from "./common"
import {ApiUrl} from "../constants/urls"


export async function createAuctionItem(title, category, startPrice, biddingEnd) {
	const response = await makeRequest(`${ApiUrl}/auctions`, {
		method: "post",
		body: {
			title,
			category,
			start_price: startPrice,
			bidding_end: biddingEnd
		}
	})

	if (response.status !== 201)
		throw new Error("Error occured while creating auction item")

	return parseResponse(response)
}

export async function getAuctionCategories() {
	const response = await makeRequest(`${ApiUrl}/auctions/categories`, {
		method: "get"
	})

	if (response.status !== 200)
		throw new Error()

	return response.json()
}

export async function getAuctionItems(search, category, page, pageSize) {
	const response = await makeRequest(`${ApiUrl}/auctions`, {})

	if (response.status !== 200)
		throw new Error()

	return response.json()
}

export async function getAuctionItem(itemId) {
	const response = await makeRequest(`${ApiUrl}/auction-item/${itemId}`)

	if (response.status !== 200)
		throw new Error("Not OK response received")

	return response.json()

	// return delayedResponse(() => dummyItems.find(x => x.id === itemId))
}

// export function getAuctionItemBiddings(itemId) {
// 	return delayedResponse(() => dummyBiddings
// 		.map(x => ({...x, itemId}))
// 		.sort((l, r) => l.amount > r.amount ? -1 : +1)
// 	)
// }
