# Changelog
_AMP - Angie Server, MariadDB, PHP, SSL_  
_http://github.com/gigamaster/amp_

## [1.11.3] – 2026-02-26

### Added

- Angie version updated
- Angie real-time server status per domain
- AMP-MANAGER conditional server .conf
- AMP-MANAGER pagination with selection
- Interactive sandbox @live-codes SDK

### Changed

- AMP-MANAGER workflow to improve performance
- Commented cache settings on default config
- Refactor LIST_TABLE with filtering (ALL, AMP_ONLY, EDIT)
- Documentation with code samples

### Removed

- Drop support of docker image `-template`

### Fixed

- AMP-MANAGER UI Menu navigation

## [1.11.2] – 2026-01-15

### Added

- Create-shortcut.bat
- Images, favicon
- Documentation for services

### Changed

- Samples for networking call/json
- Refactor AMP-MANAGER.bat UI 
- AMP-MANAGER UI encoded IBM850/iso 8859-13
- AMP-MANAGER UI align block per char
- AMP-MANAGER UI Knowledge Base 

### Removed

- **UTF-8** breaking Amp-Manager UI

### Fixed

- Clarify the sequential process
- Zone domain for Angie stats
- Custom 404/50x/maintenance

## [1.11.1] – 2025-12-30

### Added

- Support of custom PHP extensions
- Documentation for the PHP version

### Changed

- Timeout for user to read the status
- Refactor list of 'HOSTS' with flag/filter

### Fixed

- Amp-Manager menu loop to refresh domains list

## [1.10.3] – 2025-11-13

### Added

- Bind logs
- AmpManager UI checks
- DB root and user

### Changed

- Angie version updated
- Database version for legacy compatibility
- Refactor services and bridge network

### Removed

- Powershell UAC elevation causing mkcert errors
- Unused testing files

### Fixed

- CA/pem mismatch error

## [1.10.0] – 2025-07-27

### Added

- amp-manager.bat
- bind mount local.conf
- bind local.pem
- scaffolding
