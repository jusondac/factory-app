# Factory Management System

A comprehensive Ruby on Rails application for managing factory operations, including production planning, ingredient preparation, machine operations, and quality control processes.

## Overview

The Factory Management System is designed to streamline manufacturing workflows from product planning to final packaging. It provides role-based access control and tracks the complete production lifecycle with automated batch code generation and machine allocation.

## Features

### 🏭 Production Management
- **Product Management**: Create and manage products with auto-generated product codes (PRD + 6 hex characters)
- **Unit Batch Processing**: Track production batches with automated batch code generation
- **Machine Operations**: Manage production, testing, and packaging machines with real-time status tracking
- **Quality Control**: Built-in machine checking and ingredient verification processes

### 📋 Workflow Stages
1. **Preparation**: Ingredient checking and preparation with notes
2. **Production**: Machine selection, production execution with quality checks
3. **Testing**: Quality assurance processes
4. **Packaging**: Final packaging with waste quantity tracking

### 👥 Role-Based Access Control
- **Worker**: Can check ingredients, operate machines, and perform production tasks
- **Tester**: Quality control and testing operations
- **Supervisor**: Can create preparation tasks and oversee operations
- **Manager**: Full product management and operational oversight
- **Head**: Complete administrative access

### 📊 Reporting & Analytics
- Comprehensive production reports with PDF generation
- Machine utilization tracking
- Ingredient usage monitoring
- Production timeline analysis

## Technology Stack

- **Framework**: Ruby on Rails 8.0.2+
- **Database**: SQLite3 (development), configurable for production
- **Frontend**: Turbo Rails + Stimulus with Tailwind CSS
- **Authentication**: Custom secure authentication system
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache
- **PDF Generation**: WickedPDF
- **Search**: Ransack gem
- **Pagination**: Kaminari

## System Requirements

- **Ruby**: 3.2.1+
- **Rails**: 8.0.2+
- **Node.js**: For asset compilation
- **SQLite3**: Development database

## Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd factory-app
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Setup the database**
   ```bash
   rails db:setup
   rails db:seed
   ```

4. **Install JavaScript dependencies**
   ```bash
   bin/setup
   ```

## Development Setup

1. **Start the development server**
   ```bash
   bin/dev
   ```
   This starts both the Rails server and Tailwind CSS compilation in watch mode.

2. **Access the application**
   - Open http://localhost:3000 in your browser

## Default User Accounts

The application comes with pre-seeded user accounts for testing:

| Role | Email | Password | Permissions |
|------|-------|----------|-------------|
| Worker | worker@factory.com | password123 | Machine operations, ingredient checking |
| Tester | tester@factory.com | password123 | Quality control processes |
| Supervisor | supervisor@factory.com | password123 | Create preparations, oversight |
| Manager | manager@factory.com | password123 | Product management, full operations |
| Head | head@factory.com | password123 | Complete administrative access |

## Application Structure

### Models & Relationships

```
User
├── Products (manager/head only)
│   ├── Ingredients
│   └── UnitBatches
│       ├── Prepare
│       │   └── PrepareIngredients
│       ├── Produce
│       │   └── ProduceMachineChecks
│       └── Package
│           └── PackageMachineChecks
└── Sessions

Machine
├── MachineCheckings
├── Produces
└── Packages
```

### Key Features

#### Automated Code Generation
- **Product Codes**: PRD + 6 random hex characters (e.g., `PRDAB5A7D`)
- **Batch Codes**: `[ProductCode]-[YYYYMMDD]-[Shift]-[Line]-[Seq]` (e.g., `PRDAB5A7D-20250828-M-L01-001`)
- **Machine Serial Numbers**: 10 character hex codes

#### Status Tracking
- **Unit Batches**: preparation → production → testing → packing → cancelled
- **Machines**: inactive → active → under_maintenance
- **Production**: unproduce → producing → produced
- **Packaging**: unpackage → packaging → packaged

#### Machine Allocation
- **Production**: Main manufacturing processes
- **Testing**: Quality control operations  
- **Packing**: Final packaging operations

## API Documentation

The application provides RESTful endpoints for all major resources:

- `/products` - Product management
- `/unit_batches` - Batch operations
- `/prepares` - Preparation workflow
- `/produces` - Production management
- `/packages` - Packaging operations
- `/machines` - Machine management
- `/reports` - Analytics and reporting

## Deployment

### Docker Deployment (Recommended)

The application includes Docker configuration for production deployment:

```bash
# Build the Docker image
docker build -t factory_app .

# Run the container
docker run -d -p 80:80 \
  -e RAILS_MASTER_KEY=$(cat config/master.key) \
  --name factory_app factory_app
```

### Kamal Deployment

The application is configured for deployment using Kamal:

1. **Configure deployment settings** in `config/deploy.yml`
2. **Deploy the application**:
   ```bash
   bin/kamal deploy
   ```

### Environment Configuration

Required environment variables for production:

- `RAILS_MASTER_KEY`: Rails application secret
- `DB_HOST`: Database host (if using external database)
- `RAILS_LOG_LEVEL`: Logging level (optional)

## Testing

Run the test suite:

```bash
rails test
rails test:system
```

## Development Tools

- **Linting**: RuboCop Rails Omakase
- **Security**: Brakeman static analysis
- **Debugging**: Debug gem, Byebug, AwesomePrint

## Contributing

We welcome contributions to the Factory Management System! Here's how you can contribute by submitting pull requests:

### 🚀 Getting Started

1. **Fork the Repository**
   - Click the "Fork" button on the GitHub repository page
   - This creates your own copy of the repository

2. **Clone Your Fork**
   ```bash
   git clone https://github.com/YOUR-USERNAME/factory-app.git
   cd factory-app
   ```

3. **Set Up the Development Environment**
   ```bash
   bundle install
   rails db:setup
   rails db:seed
   ```

### 🔧 Making Changes

1. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or for bug fixes:
   git checkout -b bugfix/issue-description
   ```

2. **Make Your Changes**
   - Write clean, well-documented code
   - Follow the existing code style and conventions
   - Add tests for new features or bug fixes
   - Update documentation if necessary

3. **Test Your Changes**
   ```bash
   # Run the test suite
   rails test
   rails test:system
   
   # Check code quality
   bin/rubocop
   bin/brakeman
   
   # Test the application manually
   bin/dev
   ```

### 📝 Commit Guidelines

1. **Write Clear Commit Messages**
   ```bash
   git add .
   git commit -m "Add batch code validation for production workflow"
   
   # For longer descriptions:
   git commit -m "Fix machine allocation bug
   
   - Resolve issue where machines weren't properly released after production
   - Add validation to prevent double allocation
   - Update tests to cover edge cases"
   ```

2. **Keep Commits Focused**
   - One logical change per commit
   - Avoid mixing feature additions with bug fixes

### 🚀 Submitting Your Pull Request

1. **Push Your Changes**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create the Pull Request**
   - Go to your fork on GitHub
   - Click "New Pull Request"
   - Select your feature branch
   - Fill out the PR template with:
     - **Description**: What changes you made and why
     - **Testing**: How you tested the changes
     - **Screenshots**: If UI changes are involved
     - **Breaking Changes**: If any exist

3. **Pull Request Checklist**
   - [ ] Code follows the project's style guidelines
   - [ ] Tests pass locally (`rails test`)
   - [ ] New features include appropriate tests
   - [ ] Documentation updated if needed
   - [ ] No merge conflicts with main branch
   - [ ] Descriptive commit messages
   - [ ] PR description explains the changes

### 📋 Pull Request Template

When creating a pull request, please include:

```markdown
## Description
Brief description of the changes and the problem they solve.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Tests pass locally with my changes
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes

## Screenshots (if applicable)
Add screenshots to help explain your changes.

## Additional Notes
Any additional information, configuration or data that might be necessary to reproduce the issue.
```

### 🔍 Code Review Process

1. **Automated Checks**: Your PR will run automated tests and code quality checks
2. **Peer Review**: Other contributors will review your code
3. **Feedback**: Address any feedback or requested changes
4. **Approval**: Once approved, your PR will be merged

### 💡 Contribution Ideas

Looking for ways to contribute? Consider:

- **Bug Fixes**: Check the Issues tab for reported bugs
- **Feature Enhancements**: Improve existing functionality
- **Documentation**: Improve code comments and README sections
- **Testing**: Add test coverage for untested code
- **Performance**: Optimize database queries or UI performance
- **UI/UX**: Improve the user interface and experience

### 🛠 Development Tips

- **Database Changes**: Always create migrations for schema changes
- **Styling**: Use Tailwind CSS classes consistently
- **JavaScript**: Follow Stimulus conventions for interactive elements
- **Testing**: Write both unit and system tests
- **Security**: Be mindful of authentication and authorization

### 📞 Getting Help

- **Questions**: Open a discussion or issue for clarification
- **Bugs**: Report bugs with reproduction steps
- **Features**: Discuss major features before implementation

Thank you for contributing to the Factory Management System! 🎉

## Time Zone

The application is configured for **Asia/Jakarta** timezone. Update `config/application.rb` to change this setting.

## Support

For support and questions, please refer to the application documentation or create an issue in the repository.
