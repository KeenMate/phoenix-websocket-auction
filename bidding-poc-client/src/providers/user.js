import {ApiUrl} from "../constants/urls"
import {makeRequest, parseResponse} from "./common"
import {UserExistsError, UserNotFoundError} from "./exceptions"

export async function registerUser(username, password) {
	const response = await makeRequest(`${ApiUrl}/user`, {
		method: "post",
		body: {username, password}
	}, false)

	console.log("User created response: ", response)
	if (response.status === 409)
		throw new UserExistsError()
	if (response.status !== 201)
		throw new Error("User not created")

	return parseResponse(response)
}

export async function getCurrentUser() {
	const response = await makeRequest(`${ApiUrl}/me`, {
		method: "get"
	})

	console.log("Get current user response: ", response)
	if (response.status === 404)
		throw new UserNotFoundError()
	if (response.status !== 200)
		throw new Error("Could not get current user")

	return parseResponse(response)
}
