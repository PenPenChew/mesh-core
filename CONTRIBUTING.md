# Contributing to Mesh Core

Thanks for your interest in contributing!

By participating in this project, you agree to abide by our
[Code of Conduct](CODE_OF_CONDUCT.md).

## Project structure

This is a Rust workspace comprised of multiple crates:
- `mesh-wire`, `mesh-session`, `mesh-storage`, `mesh-routing`, `mesh-topology`, `mesh-grpc`, and `mesh-bin`.

## Getting started

1. Fork the repository and create a feature branch:
   - `git checkout -b feature/your-change`
2. Build and test:
   - `cargo build` and `cargo test`
3. Lint locally:
   - `cargo fmt --check` and `cargo clippy --all-targets --all-features`
4. Commit with a clear message and include a DCO sign-off (see below).
5. Open a Pull Request against `main`.

## Development standards

- Rust 1.77+ recommended.
- Keep changes small and focused; add tests for new behavior.
- Follow existing style. Use `rustfmt` and fix all `clippy` warnings.
- Update docs and `CHANGELOG.md` when user-visible changes occur.

## Testing

- Unit tests should accompany significant changes.
- Use `cargo test -p <crate>` to focus on a single crate when applicable.

## DCO sign-off (required)

We use the Developer Certificate of Origin (DCO) 1.1 to certify contributions.
Each commit must include a Signed-off-by line with your real name and email:

```
Signed-off-by: Your Name <your.email@example.com>
```

You can sign-off automatically with:

```
git commit -s -m "your message"
```

See [DCO 1.1](DCO.md) for the full text.

## Licensing of contributions and dual-license notice

- This project is dual-licensed: AGPL-3.0 for open-source use, and a
  separate commercial license. See `LICENSE` and `LICENSE-COMMERCIAL.md`.
- By contributing, you agree that your contributions are licensed under the
  AGPL-3.0 and that the maintainers may include your contributions in
  commercially licensed distributions of this project.

If you cannot agree to this, please refrain from submitting contributions.

## Pull Request checklist

- [ ] Code compiles and tests pass locally
- [ ] Added/updated tests as needed
- [ ] Lints (`fmt`, `clippy`) pass
- [ ] Docs updated (README/CHANGELOG as needed)
- [ ] DCO sign-off on every commit
