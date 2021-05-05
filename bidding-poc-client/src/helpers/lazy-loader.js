import {leaveLoaderFor, waitForLoader} from "../constants/ui"

export default function lazyLoader(resourceTask, showLoader, hideLoader) {
	if (!(resourceTask instanceof Promise))
		return

	let loaderShowed = false
	const beforeShowTimer = setTimeout(() => {
		loaderShowed = new Date()
		showLoader()
	}, waitForLoader)

	return resourceTask
		.then(res => {
			if (!showLoader) {
				clearTimeout(beforeShowTimer)
				return res
			}

			if (new Date() - loaderShowed > leaveLoaderFor) {
				hideLoader()
				return res
			}

			return new Promise(resolve => {
				setTimeout(() => {
					hideLoader()
					resolve(res)
				}, leaveLoaderFor - (new Date() - loaderShowed))
			})
		})
}
