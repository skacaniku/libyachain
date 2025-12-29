package app

import (
	"context"

	storetypes "cosmossdk.io/store/types"
	upgradetypes "cosmossdk.io/x/upgrade/types"

	"github.com/cosmos/cosmos-sdk/types/module"

	launchpadtypes "github.com/skacaniku/libyachain/x/launchpad/types"
	lydextypes "github.com/skacaniku/libyachain/x/lydex/types"
)

const (
	// UpgradeName defines the on-chain upgrade name for the LibyaChain v2 upgrade
	UpgradeName = "v2-add-modules"
)

// RegisterUpgradeHandlers registers the upgrade handlers for the app
func (app *App) RegisterUpgradeHandlers() {
	// Set upgrade handler for v2-add-modules upgrade
	app.UpgradeKeeper.SetUpgradeHandler(
		UpgradeName,
		func(ctx context.Context, plan upgradetypes.Plan, fromVM module.VersionMap) (module.VersionMap, error) {
			app.Logger().Info("Starting upgrade", "upgrade", UpgradeName, "height", plan.Height)

			// Run migrations for all modules
			// This will initialize the new modules (lydex, launchpad, admin) with version 1
			// and run any migrations for existing modules
			toVM, err := app.ModuleManager.RunMigrations(ctx, app.Configurator(), fromVM)
			if err != nil {
				app.Logger().Error("Failed to run migrations", "error", err)
				return nil, err
			}

			app.Logger().Info("Upgrade complete", "upgrade", UpgradeName)
			return toVM, nil
		},
	)

	// Register store upgrades
	// This is called during app initialization to configure the store loader
	upgradeInfo, err := app.UpgradeKeeper.ReadUpgradeInfoFromDisk()
	if err != nil {
		panic(err)
	}

	if upgradeInfo.Name == UpgradeName && !app.UpgradeKeeper.IsSkipHeight(upgradeInfo.Height) {
		storeUpgrades := storetypes.StoreUpgrades{
			Added: []string{
				lydextypes.StoreKey,       // Add lydex store
				launchpadtypes.StoreKey,   // Add launchpad store
			},
		}

		// Configure the store loader to handle the store upgrades at the specified height
		app.SetStoreLoader(upgradetypes.UpgradeStoreLoader(upgradeInfo.Height, &storeUpgrades))

		app.Logger().Info(
			"Configured store upgrades",
			"upgrade", UpgradeName,
			"height", upgradeInfo.Height,
			"added_stores", storeUpgrades.Added,
		)
	}
}
