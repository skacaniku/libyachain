package keeper

import (
	"fmt"

	"cosmossdk.io/log"
	storetypes "cosmossdk.io/store/types"
	"github.com/cosmos/cosmos-sdk/codec"
	sdk "github.com/cosmos/cosmos-sdk/types"

	"github.com/skacaniku/libyachain/x/bridge/types"
)

// Keeper of the bridge store
type Keeper struct {
	cdc        codec.BinaryCodec
	storeKey   storetypes.StoreKey
	bankKeeper types.BankKeeper
	authority  string
}

// NewKeeper creates a new bridge Keeper instance
func NewKeeper(
	cdc codec.BinaryCodec,
	storeKey storetypes.StoreKey,
	bankKeeper types.BankKeeper,
	authority string,
) Keeper {
	return Keeper{
		cdc:        cdc,
		storeKey:   storeKey,
		bankKeeper: bankKeeper,
		authority:  authority,
	}
}

// Logger returns a module-specific logger
func (k Keeper) Logger(ctx sdk.Context) log.Logger {
	return ctx.Logger().With("module", "x/"+types.ModuleName)
}

// GetParams gets the bridge module parameters
func (k Keeper) GetParams(ctx sdk.Context) types.BridgeParams {
	store := ctx.KVStore(k.storeKey)
	bz := store.Get([]byte("params"))
	if bz == nil {
		return types.DefaultParams()
	}

	var params types.BridgeParams
	k.cdc.MustUnmarshal(bz, &params)
	return params
}

// SetParams sets the bridge module parameters
func (k Keeper) SetParams(ctx sdk.Context, params types.BridgeParams) {
	store := ctx.KVStore(k.storeKey)
	bz := k.cdc.MustMarshal(&params)
	store.Set([]byte("params"), bz)
}

// InitiateDeposit initiates a deposit from an external chain to LibyaChain
func (k Keeper) InitiateDeposit(
	ctx sdk.Context,
	sourceChain string,
	sourceTxHash string,
	destAddress sdk.AccAddress,
	amount sdk.Int,
	tokenSymbol string,
) (*types.CrossChainTransfer, error) {
	params := k.GetParams(ctx)

	// Verify chain is supported
	chainConfig, exists := params.Chains[sourceChain]
	if !exists || !chainConfig.Enabled {
		return nil, fmt.Errorf("chain %s not supported or disabled", sourceChain)
	}

	// Verify amount is within limits
	if amount.LT(chainConfig.MinBridgeAmount) {
		return nil, fmt.Errorf("amount below minimum: %s < %s", amount.String(), chainConfig.MinBridgeAmount.String())
	}
	if amount.GT(chainConfig.MaxBridgeAmount) {
		return nil, fmt.Errorf("amount above maximum: %s > %s", amount.String(), chainConfig.MaxBridgeAmount.String())
	}

	// Create transfer record
	transferID := fmt.Sprintf("%s-%s", sourceChain, sourceTxHash)
	transfer := &types.CrossChainTransfer{
		ID:               transferID,
		SourceChain:      sourceChain,
		DestChain:        "libyachain",
		SourceAddress:    "",
		DestAddress:      destAddress.String(),
		Amount:           amount,
		TokenSymbol:      tokenSymbol,
		Status:           types.StatusPending,
		TxHash:           sourceTxHash,
		Confirmations:    0,
		RequiredConfirms: chainConfig.MinConfirmations,
		Timestamp:        ctx.BlockTime().Unix(),
	}

	// Store the transfer
	k.SetTransfer(ctx, transfer)

	ctx.EventManager().EmitEvent(
		sdk.NewEvent(
			"bridge_deposit_initiated",
			sdk.NewAttribute("transfer_id", transferID),
			sdk.NewAttribute("source_chain", sourceChain),
			sdk.NewAttribute("dest_address", destAddress.String()),
			sdk.NewAttribute("amount", amount.String()),
			sdk.NewAttribute("token", tokenSymbol),
		),
	)

	return transfer, nil
}

// ConfirmDeposit confirms a deposit after required confirmations
func (k Keeper) ConfirmDeposit(ctx sdk.Context, transferID string, confirmations uint64) error {
	transfer, found := k.GetTransfer(ctx, transferID)
	if !found {
		return fmt.Errorf("transfer %s not found", transferID)
	}

	transfer.Confirmations = confirmations

	if confirmations >= transfer.RequiredConfirms {
		transfer.Status = types.StatusConfirmed

		// Calculate fee
		params := k.GetParams(ctx)
		chainConfig := params.Chains[transfer.SourceChain]
		feeAmount := chainConfig.BridgeFeePercentage.MulInt(transfer.Amount).TruncateInt()
		netAmount := transfer.Amount.Sub(feeAmount)

		// Mint wrapped tokens to user
		wrappedDenom := types.GetWrappedTokenDenom(transfer.SourceChain, transfer.TokenSymbol)
		coins := sdk.NewCoins(sdk.NewCoin(wrappedDenom, netAmount))

		destAddr, err := sdk.AccAddressFromBech32(transfer.DestAddress)
		if err != nil {
			return err
		}

		// Mint and send tokens
		if err := k.bankKeeper.MintCoins(ctx, types.ModuleName, coins); err != nil {
			return err
		}
		if err := k.bankKeeper.SendCoinsFromModuleToAccount(ctx, types.ModuleName, destAddr, coins); err != nil {
			return err
		}

		transfer.Status = types.StatusCompleted

		ctx.EventManager().EmitEvent(
			sdk.NewEvent(
				"bridge_deposit_completed",
				sdk.NewAttribute("transfer_id", transferID),
				sdk.NewAttribute("amount", netAmount.String()),
				sdk.NewAttribute("fee", feeAmount.String()),
			),
		)
	}

	k.SetTransfer(ctx, &transfer)
	return nil
}

// InitiateWithdrawal initiates a withdrawal from LibyaChain to external chain
func (k Keeper) InitiateWithdrawal(
	ctx sdk.Context,
	from sdk.AccAddress,
	destChain string,
	destAddress string,
	amount sdk.Int,
	tokenSymbol string,
) (*types.CrossChainTransfer, error) {
	params := k.GetParams(ctx)

	// Verify chain is supported
	chainConfig, exists := params.Chains[destChain]
	if !exists || !chainConfig.Enabled {
		return nil, fmt.Errorf("chain %s not supported or disabled", destChain)
	}

	// Verify amount is within limits
	if amount.LT(chainConfig.MinBridgeAmount) {
		return nil, fmt.Errorf("amount below minimum")
	}
	if amount.GT(chainConfig.MaxBridgeAmount) {
		return nil, fmt.Errorf("amount above maximum")
	}

	// Burn wrapped tokens from user
	wrappedDenom := types.GetWrappedTokenDenom(destChain, tokenSymbol)
	coins := sdk.NewCoins(sdk.NewCoin(wrappedDenom, amount))

	if err := k.bankKeeper.SendCoinsFromAccountToModule(ctx, from, types.ModuleName, coins); err != nil {
		return nil, err
	}
	if err := k.bankKeeper.BurnCoins(ctx, types.ModuleName, coins); err != nil {
		return nil, err
	}

	// Create transfer record
	transferID := fmt.Sprintf("withdrawal-%s-%d", destChain, ctx.BlockHeight())
	transfer := &types.CrossChainTransfer{
		ID:               transferID,
		SourceChain:      "libyachain",
		DestChain:        destChain,
		SourceAddress:    from.String(),
		DestAddress:      destAddress,
		Amount:           amount,
		TokenSymbol:      tokenSymbol,
		Status:           types.StatusPending,
		TxHash:           "",
		Confirmations:    0,
		RequiredConfirms: chainConfig.MinConfirmations,
		Timestamp:        ctx.BlockTime().Unix(),
	}

	k.SetTransfer(ctx, transfer)

	ctx.EventManager().EmitEvent(
		sdk.NewEvent(
			"bridge_withdrawal_initiated",
			sdk.NewAttribute("transfer_id", transferID),
			sdk.NewAttribute("dest_chain", destChain),
			sdk.NewAttribute("dest_address", destAddress),
			sdk.NewAttribute("amount", amount.String()),
			sdk.NewAttribute("token", tokenSymbol),
		),
	)

	return transfer, nil
}

// SetTransfer stores a cross-chain transfer
func (k Keeper) SetTransfer(ctx sdk.Context, transfer *types.CrossChainTransfer) {
	store := ctx.KVStore(k.storeKey)
	bz := k.cdc.MustMarshal(transfer)
	store.Set([]byte(transfer.ID), bz)
}

// GetTransfer retrieves a cross-chain transfer
func (k Keeper) GetTransfer(ctx sdk.Context, transferID string) (types.CrossChainTransfer, bool) {
	store := ctx.KVStore(k.storeKey)
	bz := store.Get([]byte(transferID))
	if bz == nil {
		return types.CrossChainTransfer{}, false
	}

	var transfer types.CrossChainTransfer
	k.cdc.MustUnmarshal(bz, &transfer)
	return transfer, true
}

// GetAllTransfers returns all cross-chain transfers
func (k Keeper) GetAllTransfers(ctx sdk.Context) []types.CrossChainTransfer {
	store := ctx.KVStore(k.storeKey)
	iterator := store.Iterator(nil, nil)
	defer iterator.Close()

	var transfers []types.CrossChainTransfer
	for ; iterator.Valid(); iterator.Next() {
		var transfer types.CrossChainTransfer
		k.cdc.MustUnmarshal(iterator.Value(), &transfer)
		transfers = append(transfers, transfer)
	}

	return transfers
}
