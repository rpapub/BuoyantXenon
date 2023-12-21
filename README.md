# Git Subdirectory Migration Script README

## Overview

This script is designed to help create forked template repositories for specific subdirectories from a source Git repository. These forked repositories can be used as the basis for customization, and they are especially useful for setting up CI/CD configurations tailored to your needs. The primary use case is to allow other GitHub organizations to fork these template repositories, customize them, and create their own template repositories based on these forks.

## Why is this important?

### Template Customization

GitHub allows forking repositories, which is a powerful way to create a customized version of an existing repository. Forked template repositories can be tailored to specific use cases, making it easy to maintain templates without dealing with a large, monolithic repository.

### CI/CD Preparedness

Each forked template repository can have its CI/CD configurations ready, ensuring that your projects based on these templates are set up for continuous integration and delivery right from the start.

### Centralized GitHub Organization

Creating forked template repositories helps maintain a clean and organized GitHub organization, as each organization can manage its own customized templates independently.

## How to Use the Repositories Created by the Script

1. **Fork the Template Repositories**: If you are part of another GitHub organization or user account and want to use these templates, navigate to the respective target repositories created by the script:

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

By following these steps, you can effectively use the repositories created by the script as templates for your projects, customize them to your needs, and ensure that CI/CD configurations are prepared for your projects from the beginning. This approach helps keep your GitHub organization clean and allows for easy management of customized templates.
