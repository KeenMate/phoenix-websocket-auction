export const debounceDelay = 300

// these constants are used for rendering loading notifications
// do not show loader if response arrives before `waitForLoader` time
// and do not hide loader, if the response arrives after `waitForLoader` and before `leaveLoaderFor`
export const waitForLoader = 50
export const leaveLoaderFor = 300
