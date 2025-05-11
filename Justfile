default:
	just --list

changelog:
  git cliff --output CHANGELOG.md

publish:
	gleam publish
