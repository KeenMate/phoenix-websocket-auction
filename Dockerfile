FROM elixir:1.11-alpine

ARG MIX_ENV
ENV MIX_ENV=${MIX_ENV}

WORKDIR /app
COPY ./bidding_poc/_build/${MIX_ENV}/rel/bidding_poc .

CMD ["./bin/bidding_poc", "start"]
