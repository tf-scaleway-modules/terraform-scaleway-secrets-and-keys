## MODIFIED Requirements

### Requirement: Organization and project inputs
The module SHALL require `organization_id` (string, no default) and `project_name` (string, no default). It MUST reject an `organization_id` that is not a lowercase UUID and a `project_name` that is not 1 to 63 characters of lowercase letters, digits and hyphens, starting with a letter and ending with a letter or digit (a single letter is accepted).

#### Scenario: Invalid organization ID
- **WHEN** `organization_id = "not-a-uuid"`
- **THEN** the plan fails with "Organization ID must be a valid UUID format."

#### Scenario: Invalid project name
- **WHEN** `project_name = "Prod"`
- **THEN** the plan fails with "Project name must be lowercase alphanumeric with hyphens, start with a letter, and be 1-63 characters."

#### Scenario: Single character that is not a letter
- **WHEN** `project_name = "1"` or `project_name = "-"`
- **THEN** the plan fails with the same error

#### Scenario: Single letter project name
- **WHEN** `project_name = "a"`
- **THEN** no validation error is raised
