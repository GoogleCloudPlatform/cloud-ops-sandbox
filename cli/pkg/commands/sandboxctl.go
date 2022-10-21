package commands

import (
	"fmt"
	"github.com/spf13/cobra"
	"os"
)

const (
	version = "0.0.1"
)

var rootCmd = &cobra.Command{
	Use:     "sandboxctl",
	Version: version,
	Short:   "Controls Cloud Ops Sandbox instances.",
	Long: `sandboxctl helps to provision CloudOps Sandbox and run observability recipes.

 Find more information at: https://github.com/GoogleCloudPlatform/cloud-ops-sandbox/`,
	Run: func(cmd *cobra.Command, args []string) {
		cmd.Help()
	},
}

// Execute runs Sandbox CLI
func Execute() {
	// disable auto-completion and distinct help command
	rootCmd.CompletionOptions.DisableDefaultCmd = true
	rootCmd.SetHelpCommand(&cobra.Command{Hidden: true})

	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "There was an error while executing Sandbox CLI: '%s'", err)
		os.Exit(1)
	}
}
