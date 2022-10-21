package commands

import (
	"os"

	"github.com/spf13/cobra"
)

const (
	ProjectIDFlag = "project_id"
	AppIDFlag     = "app_id"
)

var createCmd = &cobra.Command{
	Use:   "create",
	Short: "Provision Sandbox artifacts based on configuration.",
	Run: func(cmd *cobra.Command, args []string) {
	},
}

func init() {
	createCmd.Flags().StringP(ProjectIDFlag, "p", os.Getenv("GOOGLE_CLOUD_PROJECT"), "destination Google Cloud project id")
	createCmd.Flags().StringP(AppIDFlag, "app", "", "Application configuration id")
	//	createCmd.Flags().StringP("app_id", "app", "", "Application configuration id")
	createCmd.MarkFlagRequired(AppIDFlag)
	createCmd.MarkFlagRequired(ProjectIDFlag)
	rootCmd.AddCommand(createCmd)
}
