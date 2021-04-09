import {writable} from "svelte/store"
import {ApiUrl} from "../constants/urls"
import {makeRequest, parseResponse} from "./common"
import {UnauthorizedError, UserExistsError} from "./exceptions"

const authTokenKey = "AuthToken"

const existingAuthToken = getAuthToken()

export const authTokenStore = writable(existingAuthToken)
export const userStore = writable(null)

window.onstorage = ({key, newValue}) => {
	if (key !== authTokenKey)
		return

	authTokenStore.set(newValue)
}

export function storeAuthToken(token) {
	if (token)
		window.sessionStorage.setItem(authTokenKey, token)
	else
		window.sessionStorage.removeItem(authTokenKey)
}

export function getAuthToken() {
	return window.sessionStorage.getItem(authTokenKey)
}

export async function loginUser(username, password) {
	const response = await makeRequest(`${ApiUrl}/auth/login`, {
		method: "post",
		body: {
			username,
			password
		}
	}, false)

	if (response.status === 401)
		throw new UnauthorizedError()

	if (response.status !== 200)
		throw new Error("Not OK response received for login request")

	return parseResponse(response)
}

export async function registerUser(username, password) {
	const response = await makeRequest(`${ApiUrl}/auth/register`, {
		method: "post",
		body: {
			username,
			password
		}
	})

	if (response.status === 409)
		throw new UserExistsError()

	if (response.status !== 200)
		throw new Error("Not OK response received for login request")

	return parseResponse(response)
}

export function logout() {
	storeAuthToken(null)
	authTokenStore.set(null)
	userStore.set(null)
}

