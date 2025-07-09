Build and install dependencies:

```
docker compose build
docker compose run --rm app bundle install
```

Run rspec and rubocop:

```
docker compose run --rm app bundle exec rspec
docker compose run --rm app bundle exec rubocop
```

Run cli help to check commands:

```
docker compose run --rm app bitcoin-cli --help
```

Commands:

```
Commands:
  bitcoin-cli create-wallet WALLET_NAME                                              # Create a new wallet
  bitcoin-cli get-balance WALLET_NAME                                                # Get balance of a wallet
  bitcoin-cli send-to-address WALLET_NAME ADDRESS AMOUNT                             # Send to an address
  bitcoin-cli version                                                                # Print version
```

Examples:

```
docker compose run --rm app bitcoin-cli create-wallet my-cool-wallet
docker compose run --rm app bitcoin-cli get-balance my-cool-wallet
docker compose run --rm app bitcoin-cli send-to-address my-cool-wallet tb1qsge6nm4htef9fjsh4xhm67fcc6e0rjn5ns82zr 0.00001
```
