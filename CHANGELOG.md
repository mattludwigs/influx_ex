# CHANGELOG

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.3.0] - 2022-06-13

### Breaking functional change

When calling `InfluxEx.Buckets.create/3` we would default shard group duration
values. In this release that no longer happens and you will to explicitly set
those values.

```elixir
InfluxEx.Buckets.create(client, "my-bucket", group_shard: true)
```

### Changes

- Now required to enabled group shards when creating buckets

### Added

- Added `:group_shard` option to `InfluxEx.Buckets.create_bucket_opt()`

### Fixed

- Typespec for `InfluxEx.Buckets.create/3`

## [v0.2.1] - 2022-05-27

### Added

- Support for integer, boolean, and string field types (@djcarpe)
- Support unix timestamp ranges in Flux query

### Misc

- Documentation fixes (@djcarpe)

## [v0.2.0] - 2022-05-23

Breaking change: Mojito library was deprecated, so we removed first class
support for it. This will effect your dependencies.

We have decided to use the [Req](https://hex.pm/packages/req) as it is built on
top of Finch and allows us to keep the default API simple.

To upgrade you will need to remove `:mojito` from you dependencies are replace
it with `{:req, "~> 0.2.2}`, if you are using the default HTTP client that
`InfluxEx` uses. If you're using a custom HTT client you can ignore this and
safely update.

### Changed

- Removed support for Mojito HTTP library
- The `InfluxEx.HTTP.Req` client is the default client used by InfluxEx

### Added

- `InfluxEx.HTTP.Req` client

### Removed

- `InfluxEx.HTTP.Mojito`

## [v0.1.1] - 2022-05-19

### Fixed

- `Influx.Flux.run_query/2` add query opts to type spec
- `InfluxEx.Flux.run_query/2` wrong return error type in spec

## v0.1.0 - 2022-05-12

Initial release!

[v0.3.0]: https://github.com/mattludwigs/influx_ex/compare/v0.2.1...v0.3.0
[v0.2.1]: https://github.com/mattludwigs/influx_ex/compare/v0.2.0...v0.2.1
[v0.2.0]: https://github.com/mattludwigs/influx_ex/compare/v0.1.1...v0.2.0
[v0.1.1]: https://github.com/mattludwigs/influx_ex/compare/v0.1.0...v0.1.1
