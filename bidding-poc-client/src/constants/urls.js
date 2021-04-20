const Production = process.env.SVELTE_APP_PRODUCTION === "true"
const ServerHostname = process.env.SVELTE_APP_SERVER_HOSTNAME

export const ApiUrl = Production ? "/api" : `http://${ServerHostname}/api`
export const SocketUrl = Production ? "/socket" : `ws://${ServerHostname}/socket`