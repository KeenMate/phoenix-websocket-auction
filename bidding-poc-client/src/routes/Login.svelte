<script>
  import {push, querystring} from "svelte-spa-router"
  import {parse} from "qs"
  import toastr from "../helpers/toastr-helpers"
  import {storeAuthToken, loginUser, authTokenStore, userStore} from "../providers/auth"
  import {UnauthorizedError} from "../providers/exceptions"
  import LoginForm from "../components/LoginForm.svelte"

  $: query = parse($querystring)

  let username = ""
  let password = ""

  let users = []
  
  for (let i = 0; i < 4; i++) {
  	const column = []
	  for (let j = 0; j < 10; j++)
	    column.push((i * 10) + j)
	  
	  users.push(column)
	}

  async function onLogin() {
	  if (!username || !password) {
		  toastr.warning("Username and password must be filled in")
		  return
	  }

	  try {
		  const {user, token} = await loginUser(username, password)
		  storeAuthToken(token)
		  authTokenStore.set(token)
		  userStore.set(user)

		  push(query.redirect || "/")
	  } catch (err) {
		  if (err instanceof UnauthorizedError) toastr.error("Incorrect credentials")
		  else {
			  console.error("Error occured while logging in user", err)
			  toastr.error("Could not authenticate user")
		  }

		  throw err
	  }
  }

  function padNumber(number) {
	  return number.toString().padStart(3, "0")
  }
  
  function setUser(postfix) {
  	username = `user${padNumber(postfix)}`
	  password = "1234"
  }
</script>

<div class="login-page">
	<div class="columns is-centered">
		<div class="column is-4">
			<h4 class="is-text-4">Login</h4>
			<LoginForm
				{username}
				{password}
				on:changeUsername={(ev) => (username = ev.detail)}
				on:changePassword={(ev) => (password = ev.detail)}
				on:login={onLogin}
			/>
			<p>
				<b>Username</b> is from user001 to user100. <br>
				First 10 users are admins. <br>
				<b>Password</b> is same for all: <i>1234</i>
			</p>
		</div>
		<div class="column is-6">
			<b>Implicit users</b>
			<div class="columns is-multiline">
				{#each users as usersColumn}
					<div class="column is-3">
						<table class="table is-bordered is-striped is-narrow">
							<thead>
							<tr>
								<th>Username</th>
								<th>Actions</th>
							</tr>
							</thead>
							<tbody>
							{#each usersColumn as i}
								<tr class:is-selected={i < 10}>
									<td>user{padNumber(i + 1)}</td>
									<td>
										<button
											class="button is-link is-small"
											on:click={() => setUser(i + 1)}
										>
											Copy
										</button>
									</td>
								</tr>
							{/each}
							</tbody>
						</table>
					</div>
				{/each}
			</div>
		</div>
	</div>
</div>
