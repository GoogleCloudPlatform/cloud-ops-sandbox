module github.com/GoogleCloudPlatform/cloud-ops-sandbox/cli

go 1.19

require github.com/spf13/cobra v1.6.0

require (
	github.com/inconshreveable/mousetrap v1.0.1 // indirect
	github.com/spf13/pflag v1.0.5 // indirect
)

replace github.com/GoogleCloudPlatform/sandbox/pkg/commands => /workspaces/go/src/github.com/GoogleCloudPlatform/cloud-ops-sandbox/cli/pkg/commands
