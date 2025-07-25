# Check the Children’s Barred List

A service that allows employers and agencies to check whether someone appears on
the Children’s Barred List.

## Setup

### Dependencies

This project depends on:

- [Ruby](https://www.ruby-lang.org/)
- [Ruby on Rails](https://rubyonrails.org/)
- [NodeJS](https://nodejs.org/)
- [Yarn](https://yarnpkg.com/)
- [Postgres](https://www.postgresql.org/)
- [Redis](https://redis.io/)

Install dependencies using your preferred method, using `asdf` or `rbenv` or
`nvm`. Example with `asdf`:

```bash
# The first time
brew install asdf # Mac-specific
asdf plugin add ruby
asdf plugin add nodejs
asdf plugin add yarn
asdf plugin add postgres

# To install (or update, following a change to .tool-versions)
asdf install
```

#### Redis

You’ll need to install Redis. The way to do this is different on each operating system, but on macOS you can try the following:

```bash
brew install redis
brew services start redis
```

If installing Redis manually, you'll need to start it in a separate terminal:

```bash
redis-server
```


### Application

Setup the project (re-run after `Gemfile` or `package.json` updates, automatically restarts any running Rails server):

```bash
bin/setup
```

Run the application on `http://localhost:3000`:

```bash
bin/dev
```

### BigQuery

Edit `.env.development.local` and add a BigQuery key if you want to use BigQuery locally.

See [DfE Analytics](https://github.com/DFE-Digital/dfe-analytics#2-get-an-api-json-key-key) for information on how to get a key.

You also need to set `BIGQUERY_DISABLE` to `false` as it defaults to `true` in the development environment.

[Read more about setting up BigQuery](https://github.com/DFE-Digital/dfe-analytics/blob/main/docs/google_cloud_bigquery_setup.md).

### Linting

To run the linters:

```bash
bin/lint
```

### Testing

To run the tests:

```bash
bin/test
```

### Intellisense

[solargraph](https://github.com/castwide/solargraph) is bundled as part of the
development dependencies. You need to [set it up for your
editor](https://github.com/castwide/solargraph#using-solargraph), and then run
this command to index your local bundle (re-run if/when we install new
dependencies and you want completion):

```sh
bin/bundle exec yard gems
```

You’ll also need to configure your editor’s `solargraph` plugin to
`useBundler`:

```diff
+  "solargraph.useBundler": true,
```

## How the application works

We keep track of architecture decisions in [Architecture Decision Records
(ADRs)](/adr/).

We use `rladr` to generate the boilerplate for new records:

```bash
bin/bundle exec rladr new title
```
