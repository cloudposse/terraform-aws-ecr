package test

import (
	"math/rand"
	"strconv"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// randAttribute returns a per-test-run attribute suffix. The math/rand global
// source is auto-seeded since Go 1.20, and rand.Seed is a no-op since Go 1.24,
// so each `go test` invocation gets a fresh sequence without any Seed call.
// This keeps repository names unique across the terraform/opentofu CI matrix.
func randAttribute() string {
	return strconv.Itoa(rand.Intn(100000))
}

// Test the Terraform module in examples/complete using Terratest.
func TestExamplesComplete(t *testing.T) {

	randId := randAttribute()
	attributes := []string{randId}

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../examples/complete",
		Upgrade:      true,
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: []string{"fixtures.us-east-2.tfvars"},
		Vars: map[string]interface{}{
			"attributes": attributes,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	repositoryName := terraform.Output(t, terraformOptions, "repository_name")
	expectedRepositoryName := "eg-test-ecr-test-" + randId
	// Verify we're getting back the outputs we expect
	assert.Equal(t, expectedRepositoryName, repositoryName)
}

func TestExamplesCompleteImmutable(t *testing.T) {

	randId := randAttribute()
	attributes := []string{randId}

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../examples/complete",
		Upgrade:      true,
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: []string{"immutable.fixtures.us-east-2.tfvars"},
		Vars: map[string]interface{}{
			"attributes": attributes,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	repositoryName := terraform.Output(t, terraformOptions, "repository_name")
	expectedRepositoryName := "eg-test-ecr-test-" + randId
	// Verify we're getting back the outputs we expect
	assert.Equal(t, expectedRepositoryName, repositoryName)
}

func TestExamplesCompleteScanning(t *testing.T) {

	randId := randAttribute()
	attributes := []string{randId}

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../examples/complete",
		Upgrade:      true,
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: []string{"scanning.fixtures.us-east-2.tfvars"},
		Vars: map[string]interface{}{
			"attributes": attributes,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	repositoryName := terraform.Output(t, terraformOptions, "repository_name")
	expectedRepositoryName := "eg-test-ecr-test-" + randId
	// Verify we're getting back the outputs we expect
	assert.Equal(t, expectedRepositoryName, repositoryName)
}

// TestExamplesLifecyclePolicies exercises custom_lifecycle_rules end-to-end.
// Regression coverage for https://github.com/cloudposse/terraform-aws-ecr/issues/158:
// v1.0.1 injected `storageClass="standard"` into selection and `targetStorageClass=null`
// into action, which caused ECR to reject the policy. Applying against a real ECR
// repository here confirms ECR accepts the rendered policy, and the output-level
// assertions pin the specific regression to prevent re-occurrence.
func TestExamplesLifecyclePolicies(t *testing.T) {

	randId := randAttribute()
	attributes := []string{randId}

	terraformOptions := &terraform.Options{
		TerraformDir: "../../examples/lifecycle-policies",
		Upgrade:      true,
		VarFiles:     []string{"fixtures.us-east-2.tfvars"},
		Vars: map[string]interface{}{
			"attributes": attributes,
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	// InitAndApply will fail if ECR rejects the rendered lifecycle policy
	// (which is exactly how the v1.0.1 regression manifested).
	terraform.InitAndApply(t, terraformOptions)

	repositoryName := terraform.Output(t, terraformOptions, "repository_name")
	expectedRepositoryName := "eg-test-ecr-lifecycle-" + randId
	assert.Equal(t, expectedRepositoryName, repositoryName)

	policyJSON := terraform.Output(t, terraformOptions, "lifecycle_policy_json")
	assert.NotEmpty(t, policyJSON, "lifecycle_policy_json output should be non-empty")

	// Issue #158: action blocks without an explicit targetStorageClass must not
	// leak a `"targetStorageClass":null` into the rendered JSON.
	assert.NotContains(t, policyJSON, `"targetStorageClass":null`,
		"rendered policy must not contain targetStorageClass=null (issue #158)")

	// Issue #158: selections without an explicit storageClass must not have
	// `"storageClass":"standard"` injected by the module.
	assert.NotContains(t, policyJSON, `"storageClass":"standard"`,
		"rendered policy must not inject storageClass=standard (issue #158)")

	// Feature check (v1.0.1): transition-to-archive is preserved.
	assert.Contains(t, policyJSON, `"type":"transition"`,
		"rendered policy must include the transition action")
	assert.Contains(t, policyJSON, `"targetStorageClass":"archive"`,
		"rendered policy must include targetStorageClass=archive for the transition rule")

	// Feature check (v1.0.1): storageClass=archive filter is preserved when explicitly set.
	assert.Contains(t, policyJSON, `"storageClass":"archive"`,
		"rendered policy must include storageClass=archive for the archive-filter rule")

	// Sanity: tagPatternList from the regression case survives normalization.
	assert.True(t, strings.Contains(policyJSON, `"tagPatternList":["latest"]`) ||
		strings.Contains(policyJSON, `"tagPatternList": ["latest"]`),
		"rendered policy must include the tagPatternList=[latest] rule")
}
