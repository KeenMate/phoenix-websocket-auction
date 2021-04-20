<script>
  import { push, querystring } from "svelte-spa-router";
  import { parse } from "qs";
  import toastr from "../helpers/toastr-helpers";
  import { storeAuthToken, loginUser, authTokenStore, userStore } from "../providers/auth";
  import { UnauthorizedError } from "../providers/exceptions";
  import LoginForm from "../components/LoginForm.svelte";

  $: query = parse($querystring);

  let username = "";
  let password = "";

  async function onLogin() {
    if (!username || !password) {
      toastr.warning("Username and password must be filled in");
      return;
    }

    try {
      const { user, token } = await loginUser(username, password);
      storeAuthToken(token);
      authTokenStore.set(token);
      userStore.set(user);

      push(query.redirect || "/");
    } catch (err) {
      if (err instanceof UnauthorizedError) toastr.error("Incorrect credentials");
      else {
        console.error("Error occured while logging in user", err);
        toastr.error("Could not authenticate user");
      }

      throw err;
    }
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
        <b>Login names:</b><br />
        Richmond, Nash <br />
        Barron, Zephania <br />
        Banks, Hyatt <br />
        Murray, Christen <br />
        Adams, Xerxes <br />
        Oliver, Geoffrey <br />
        <b>Password: 1234</b>
      </p>
    </div>
  </div>
</div>
