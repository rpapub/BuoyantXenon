# UiPath Studio template extraction

[![Subdir to Repository](https://github.com/rpapub/BuoyantXenon/actions/workflows/subdir_to_repository.yml/badge.svg)](https://github.com/rpapub/BuoyantXenon/actions/workflows/subdir_to_repository.yml) [![Update README with Release Branches](https://github.com/rpapub/BuoyantXenon/actions/workflows/update-readmes.yml/badge.svg)](https://github.com/rpapub/BuoyantXenon/actions/workflows/update-readmes.yml)

## Overview

The script in this repo extracts the UiPath Studio templates (for the Robotic Enterprise Framework (REFramework)) [from the vendor's monorepo](https://github.com/UiPath-Services/StudioTemplates/). Its primary function is to bring these essential templates into a version-controlled environment, facilitating seamless and efficient project initialization in UiPath Studio. The script efficiently extracts different versions tailored for legacy/Windows and VB/CSharp platforms. Users can conveniently fork these versioned templates into their own GitHub organization, transforming them into customizable GitHub templates, which streamlines project updates and management.

## Why is this important?

### CI/CD Preparedness

Each forked template repository can have its CI/CD configurations ready, ensuring that your projects based on these templates are set up for continuous integration and delivery right from the start.

### Centralized GitHub Organization

Creating forked template repositories helps maintain a clean and organized GitHub organization, as each organization can manage its own customized templates independently. Future updates to the templates can be easily managed by updating the forked template repositories.

### Do not start with a template in UiPath Studio

If a developer starts with a template in UiPath Studio, all hope for a standarized baseline is lost: Depending on the Studio version any (REFramework) version will be used.

## How to Use the Repositories Created by the Script

1. **Check the created repositories**: Navigate to the respective target repositories created by the script:

   - [REFramework-VB-legacy](https://github.com/rpapub/REFramework-VB-legacy.git)
   - [REFramework-CSharp-legacy](https://github.com/rpapub/REFramework-CSharp-legacy.git)
   - [REFramework-VB-Windows](https://github.com/rpapub/REFramework-VB-Windows.git)
   - [REFramework-CSharp-Windows](https://github.com/rpapub/REFramework-CSharp-Windows.git)

2. **Fork the Repository**: Click the "Fork" button on the top right of the repository page to create your own copy (fork) of the repository under your GitHub organization or user account.

3. **Customize the Forked Repository**: After forking, you can customize the forked repository as needed. You can modify code, update configurations, and make any changes specific to your use case.

4. **Use as a Template**: You can use the forked repository as a template for creating new projects. To do this:

   - Go to the forked repository's main page.
   - Click the "Use this template" button (usually located next to the "Clone or download" button).
   - Follow the prompts to create a new repository based on your forked template.

5. **Set Up CI/CD**: If you have configured CI/CD settings in the forked template repository, these settings will be inherited when you create new projects based on the template. You may need to adjust the settings to suit your specific project requirements.

6. **Customize and Develop**: Customize the forked template repository and develop your projects based on it. You can make changes, add code, and manage your project's development process.

7. **Pull in future changes**: If the created repositories are updated, you can pull in the changes to your forked repository. To do this:

   - Go to your forked repository's main page.
   - Click the "Fetch upstream" button (usually located next to the "Clone or download" button).
   - Follow the prompts to pull in the changes from the original template repository.

By following these steps, you can effectively use the repositories created by the script as templates for your projects, customize them to your needs, and ensure that CI/CD configurations are prepared for your projects from the beginning. This approach helps keep your GitHub organization clean and allows for easy management of customized templates.
