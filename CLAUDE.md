# AI-Assisted Helm Chart Testing Guide

Instructions for Claude to systematically test and validate Helm charts using standard CLI tools.

## Core Principle

**Every configuration value should measurably affect rendered Kubernetes manifests.**

Test by comparing `helm template` output before and after changing values, not by parsing raw template files.

## Test Result Categories

| Status | Symbol | Meaning | Action |
|--------|---------|---------|---------|
| **SUCCESS** | ✅ | Test value appears in rendered output | Working correctly |
| **VISIBLE_CHANGE** | 🔄 | Output changes, test value visible | Working correctly |
| **INVISIBLE_CHANGE** | ⚠️ | Output changes, test value not visible | Investigate transformation |
| **UNUSED** | ❌ | No effect on rendered output | Remove or fix |
| **RENDER_FAILED** | 💥 | Causes template errors | Fix validation |

## Simple Testing Workflow

### 1. Environment Check
Verify these tools are available: `helm`, `diff`, `grep`, `wc`, `yq`, `jq`, `git`, `helm-values-schema-json`

To generate `values.schema.json`, inside chart folder run
`helm-values-schema-json -input values.yaml -output values.schema.json`

Run `helm lint .` to check for basic chart issues

### 2. Create Baseline
Render chart with default values to create comparison baseline:
- Create temp folder for test artifacts (e.g. `helm_test_temp/`)
- Use `helm template` with default values
- Save output to baseline file in temp folder

### 3. Test Individual Values
For each configuration value to test:
- Render chart with test value using `helm template --set` (simple values) or `helm template -f` (complex values)
- Use `diff` to compare baseline vs test output
- Use `grep` on diff results to find if test value appears
- Filter out noise (name changes, metadata) with `grep -v`

**Simple values:** Use `--set path.to.value=test-value`
**Complex values:** Create test values file and use `-f test-values.yaml`

### 4. Test Schema Validation
Test that invalid values are properly rejected:
- Try invalid enum values (should fail)
- Try invalid formats (should fail)
- Check error messages with `grep -i error`

### 5. Analyze Results
- **SUCCESS**: Test value found in diff output
- **UNUSED**: No diff between baseline and test
- **RENDER_FAILED**: Schema validation working or chart bug

## Key Test Cases

### Configuration Paths
Test these high-priority paths first:
- Replica counts (`replicaCount`, `controlPlaneNumber`, `workersNumber`)
- Resource settings (`cpu`, `memory`, `resources.*`)
- Images (`image.repository`, `image.tag`, `*.image`)
- Enable/disable flags (`*.enabled`)
- Enum values (test valid + invalid values)
- Get paths from values file and go over them
  (Threat commented out paths as not commented out)

### Schema Validation Tests
If chart has schema annotations:
- Generate schema using `helm-values-schema-json` (if available)
- Test enum constraints with invalid values
- Test format validation with malformed inputs

### Edge Cases
Test boundary conditions:
- Empty string values
- Extreme numeric values
- Invalid format strings

## Common Issues to Identify

### 1. Missing Validation
**Problem**: Invalid values accepted, causing runtime failures
**Test**: Try invalid formats, check if they're rejected
**Fix**: Add schema patterns or template validation

### 2. Unused Values
**Problem**: Configuration values that don't affect output
**Test**: Change value, check if output changes
**Fix**: Remove unused values or fix template references

### 3. Inconsistent Defaults
**Problem**: Similar components have different default behaviors
**Test**: Compare related configuration sections
**Fix**: Standardize defaults or document differences

### 4. Missing Required Fields
**Problem**: Templates reference undefined values
**Test**: Render with minimal values, check for errors
**Fix**: Add default values or conditional logic

## Quick Health Check

For rapid chart assessment:
1. **Render Test**: Use `helm template` with default values, count lines and resources with `wc` and `grep`
2. **Value Test**: Change a key value, use `diff` to check for changes, `grep` to find test value in diff
3. **Validation Test**: Try invalid enum/format, check if error appears with `grep -i error`

## Workflow for Committed Code

When working with code that has already been committed, follow these steps to ensure chart integrity:

1. **Check for Chart Modifications**: Use `git diff` to identify any changes in the `charts/` directory.
2. **Review Changes**: If there are modifications, review them first.
3. **User Confirmation**: After reviewing the specific changes, ask the user if a full check of all values in the modified chart is needed.

## Reporting Results

Document only broken things that need fixing:
- ❌ **Unused Values**: List paths with no effect (candidates for removal)
- 💥 **Broken Values**: List paths that cause render failures
- ⚠️ **Lint Issues**: Problems found by `helm lint`
- 🔧 **Fixed Issues**: Document any improvements made

If no issues found, report: "No broken configuration found"

## Success Criteria

A well-tested chart should have:
- No unused configuration paths
- Invalid values rejected (schema validation + `helm lint` pass)
- No template rendering failures
- Consistent behavior across similar components
- Clear documentation for unusual defaults
