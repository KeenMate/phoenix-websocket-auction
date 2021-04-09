export class UnauthorizedError extends Error {
}

export class UserExistsError extends Error {
	constructor(message) {
		super(message)
	}
}

export class UserNotFoundError extends Error {
}
