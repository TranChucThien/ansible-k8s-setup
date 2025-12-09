# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2024-12-09

### Added
- Single master Kubernetes cluster setup (no HA)
- Multi-master Kubernetes cluster setup with HA
- Automated Ansible playbooks for cluster deployment
- Support for Ubuntu 24.04 LTS
- Comprehensive documentation:
  - Installation guide
  - Cluster connection guide
  - Troubleshooting guide
  - Node management guide
  - HA setup guide
  - Multi-master setup guide
  - HA cluster testing guide
- Inventory templates for both cluster types
- Automated join command generation
- Common setup playbook for all nodes
- Master and worker node specific playbooks

### Security
- Added security notices in README
- Documented best practices for production use
- Inventory templates with placeholder credentials
- Warnings about plaintext password usage

### Documentation
- Complete README with quick start guides
- Separate documentation for simple and HA clusters
- Validation and testing instructions
- Directory structure documentation
