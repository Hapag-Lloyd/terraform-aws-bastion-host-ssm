# Contribution guide

We appreciate your thought to contribute to open source. :heart: We want to make contributing as easy as possible. You are welcome to:

- Report a bug
- Discuss the current state of the code
- Submit a fix
- Propose new features

We use [Github Flow](https://guides.github.com/introduction/flow/index.html), so all code changes happen through pull
requests. We actively welcome your pull requests:

1. Fork the repo and create your branch from `main`.
2. If you've added code, check one of the examples.
3. Make sure your code lints.
4. Raise a pull request.

## Terraform version

We support Terraform version 1 and above. All checks within the pipeline are usually done with the newest version.
If you need different versions of Terraform installed, check [tfenv](https://github.com/tfutils/tfenv).

## Coding Style

We use the [Terraform Style conventions](https://www.terraform.io/docs/configuration/style.html). They are enforced with CI scripts.

## Documentation

We use [pre-commit](https://pre-commit.com/) to update the Terraform inputs and outputs in the documentation via
[terraform-docs](https://github.com/terraform-docs/terraform-docs). Ensure you have installed those components
and to update the documentation of the module before raising the PR.

## Testing

No automated tests are available. The example directory takes care of a few scenario's.

## License

By contributing, you agree that your contributions will be licensed under its Apache 2.0 license.
