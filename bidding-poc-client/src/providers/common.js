import {authTokenStore} from "./auth"
import {ApplicationJson} from "../constants/headers"
import {get} from "svelte/store"

export async function makeRequest(url, options, requireAuthToken = true) {
	let currentToken = get(authTokenStore)
	if (requireAuthToken && !currentToken)
		currentToken = await waitForToken()

	const combinedHeaders = new Headers({
		"Content-Type": ApplicationJson,
		"Authorization": `Bearer ${currentToken}`,
		...(options.headers || {})
	})

	let body = options.body
	if (bodyIsForm(options))
		combinedHeaders.delete("Content-Type")
	else
		body = JSON.stringify(body)

	return fetch(url, {
		headers: combinedHeaders,
		...options,
		body
	})
}

/**
 * Parses the response as json if possible or returns response otherwise
 * @param response {Response}
 * @returns {Response | Promise<any>}
 */
export function parseResponse(response) {
	if (response.status >= 200 && response.status < 300) {
		if (getContentTypeHeader(response).indexOf(ApplicationJson) === -1)
			return response

		return response.json()
	}

	return response
}

export function delayedResponse(result) {
	return new Promise(resolve => {
		setTimeout(() => {
			resolve(newResult)
		}, 300)
		const newResult = (typeof result === "function") ? result() : result
	})
}

function bodyIsForm(request) {
	return request.body instanceof FormData
}

function getContentTypeHeader(response) {
	return response.headers.get("content-type")
}

function waitForToken() {
	return new Promise(resolve => {
		let subscription
		subscription = authTokenStore.subscribe(token => {
			if (!token)
				return

			subscription()
			resolve(token)
		})
	})
}
