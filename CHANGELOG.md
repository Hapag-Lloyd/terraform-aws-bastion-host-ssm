# Changelog

## [2.5.1](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/compare/2.5.0...v2.5.1) (2024-04-10)


### Bug Fixes

* allow panic lambdas to modify autoscaling schedule ([#284](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/issues/284)) ([b48c5db](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/commit/b48c5db9c0c2eed4cfacfc1e821b9c033e840290))
* terminate the instances instead of stopping them ([#287](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/issues/287)) ([fc2e708](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/commit/fc2e7083d5d9d9adaccfa1e1b8d9319a5fcd9fe2))

## [2.5.0](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/compare/2.4.1...2.5.0) (2023-11-30)


### Features

* add `var.ami_id` to fix the AMI used for the Bastion ([#199](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/issues/199)) ([d86a898](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/commit/d86a8985cc116d5ed24c5317f35baaed65d602bd))

## [2.4.1](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/compare/2.4.0...2.4.1) (2023-05-08)


### Bug Fixes

* scale spot instances down if a schedule exists ([#170](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/issues/170)) ([f9b9d5b](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/commit/f9b9d5bd4341913692610389fa47abdcf0d9e6cd))

## [2.4.0](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/compare/2.3.0...2.4.0) (2023-02-16)


### Features

* add panic switch (on/off) ([#148](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/issues/148)) ([a9b709d](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/commit/a9b709d3a0e09cd4d4b1c97d52fe9a924b2a14ce))

## [2.3.0](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/compare/2.2.2...2.3.0) (2023-01-31)


### Features

* allow mixture of on-demand and spot instances ([#140](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/issues/140)) ([6df557a](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/commit/6df557ac14a2602254c19d83393d87116a99765e))


### Bug Fixes

* **deps:** bump terraform-aws-modules/iam/aws from 5.10.0 to 5.11.1 ([#138](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/issues/138)) ([4083f95](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/commit/4083f9551e2f3de519bdea50fd04bb66a1f07562))

## [2.2.2](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/compare/2.2.1...2.2.2) (2023-01-17)


### Bug Fixes

* set token hop_limit to 1 ([#134](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/issues/134)) ([9b94074](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/commit/9b940747f7d0c036c9c37965cea5e046a07a7a8d))

## [2.2.1](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/compare/2.2.0...2.2.1) (2023-01-10)


### Bug Fixes

* create instance profile if no profile specified ([#127](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/issues/127)) ([68f5088](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/commit/68f50880e999abebc5b393d1ed6bcdf94fa21817))
* **deps:** bump terraform-aws-modules/iam/aws from 5.9.2 to 5.10.0 ([#126](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/issues/126)) ([e265d3b](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/commit/e265d3b44876372795a7803f5658d2c35f8da672))

## [2.2.0](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/compare/2.1.0...2.2.0) (2023-01-02)


### Features

* allow user defined instance profile ([#123](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/issues/123)) ([b179562](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/commit/b17956271c45fd4731847dc1bd4b5c9b775bfb82))
* search for AMIs in current account ([#118](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/issues/118)) ([19da04f](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/commit/19da04fa30e9d05a09e5e4436820b4060676f294))

## [2.1.0](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/compare/2.0.16...2.1.0) (2023-01-02)


### Features

* add filter for AMI name ([#113](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/issues/113)) ([b82560a](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/commit/b82560a1e8180d3bd4555963aa1e3e8b3d22f0ef))
* dummy
