# Changelog

## 0.3.0

- Change `AuthorizedTransaction.configure` to return self if there is no block
- Change `AuthorizedTransaction.configure` execution in context of the controller
- Change all settings `*_proc` execution in context of the controller
- Add `transaction_proc` to change how a transaction is created via configuration
- Add tests
- Add examples and configuration to README.md
- Add explicit notion of _not_ depending on `cancan(can)` to README.md
- Remove dependency on `activerecord`

## 0.2.0

- Allow for configuration via `AuthorizedTransaction.configure`

## 0.1.0

:baby: Initial version
