package keeper

import (
	"cosmossdk.io/log"
	storetypes "cosmossdk.io/store/types"
	"github.com/cosmos/cosmos-sdk/codec"
	sdk "github.com/cosmos/cosmos-sdk/types"

	"github.com/skacaniku/libyachain/x/privacy/types"
)

// Keeper of the privacy store
type Keeper struct {
	cdc        codec.BinaryCodec
	storeKey   storetypes.StoreKey
	memKey     storetypes.StoreKey
	bankKeeper types.BankKeeper
	authority  string
}

// NewKeeper creates a new privacy Keeper instance
func NewKeeper(
	cdc codec.BinaryCodec,
	storeKey storetypes.StoreKey,
	memKey storetypes.StoreKey,
	bankKeeper types.BankKeeper,
	authority string,
) Keeper {
	return Keeper{
		cdc:        cdc,
		storeKey:   storeKey,
		memKey:     memKey,
		bankKeeper: bankKeeper,
		authority:  authority,
	}
}

// Logger returns a module-specific logger
func (k Keeper) Logger(ctx sdk.Context) log.Logger {
	return ctx.Logger().With("module", "x/"+types.ModuleName)
}

// GetParams gets the privacy module parameters
func (k Keeper) GetParams(ctx sdk.Context) types.PrivacyParams {
	store := ctx.KVStore(k.storeKey)
	bz := store.Get([]byte("params"))
	if bz == nil {
		return types.DefaultParams()
	}

	var params types.PrivacyParams
	k.cdc.MustUnmarshal(bz, &params)
	return params
}

// SetParams sets the privacy module parameters
func (k Keeper) SetParams(ctx sdk.Context, params types.PrivacyParams) {
	store := ctx.KVStore(k.storeKey)
	bz := k.cdc.MustMarshal(&params)
	store.Set([]byte("params"), bz)
}

// CreatePrivateAccount creates a new privacy-enabled account
func (k Keeper) CreatePrivateAccount(ctx sdk.Context, addr sdk.AccAddress, viewingKey, shieldedPubKey string) error {
	store := ctx.KVStore(k.storeKey)

	// Check if account already exists
	key := types.GetPrivateAccountKey(addr)
	if store.Has(key) {
		return types.ErrPrivateAccountExists
	}

	// Create private account
	privateAcc := types.PrivateAccount{
		Address:        addr.String(),
		ViewingKey:     viewingKey,
		ShieldedPubKey: shieldedPubKey,
	}

	bz := k.cdc.MustMarshal(&privateAcc)
	store.Set(key, bz)

	return nil
}

// GetPrivateAccount retrieves a private account
func (k Keeper) GetPrivateAccount(ctx sdk.Context, addr sdk.AccAddress) (types.PrivateAccount, bool) {
	store := ctx.KVStore(k.storeKey)
	key := types.GetPrivateAccountKey(addr)

	bz := store.Get(key)
	if bz == nil {
		return types.PrivateAccount{}, false
	}

	var privateAcc types.PrivateAccount
	k.cdc.MustUnmarshal(bz, &privateAcc)
	return privateAcc, true
}

// Shield moves funds from transparent to shielded pool
func (k Keeper) Shield(ctx sdk.Context, from sdk.AccAddress, amount sdk.Coins, commitment string) error {
	// Transfer coins from user to module account (shielded pool)
	if err := k.bankKeeper.SendCoinsFromAccountToModule(ctx, from, types.ModuleName, amount); err != nil {
		return err
	}

	// Store the commitment in the merkle tree
	store := ctx.KVStore(k.storeKey)
	commitmentKey := append(types.CommitmentTreeKey, []byte(commitment)...)
	store.Set(commitmentKey, []byte{0x01})

	// Emit event
	ctx.EventManager().EmitEvent(
		sdk.NewEvent(
			"shield",
			sdk.NewAttribute("from", from.String()),
			sdk.NewAttribute("amount", amount.String()),
			sdk.NewAttribute("commitment", commitment),
		),
	)

	return nil
}

// Unshield moves funds from shielded to transparent pool
func (k Keeper) Unshield(ctx sdk.Context, to sdk.AccAddress, amount sdk.Coins, nullifier string, proof string) error {
	// Verify the nullifier hasn't been used
	if k.IsNullifierUsed(ctx, nullifier) {
		return types.ErrNullifierAlreadyUsed
	}

	// Verify zero-knowledge proof
	if !k.VerifyProof(ctx, proof) {
		return types.ErrInvalidProof
	}

	// Mark nullifier as used
	k.SetNullifier(ctx, nullifier)

	// Transfer coins from module account to user
	if err := k.bankKeeper.SendCoinsFromModuleToAccount(ctx, types.ModuleName, to, amount); err != nil {
		return err
	}

	// Emit event
	ctx.EventManager().EmitEvent(
		sdk.NewEvent(
			"unshield",
			sdk.NewAttribute("to", to.String()),
			sdk.NewAttribute("amount", amount.String()),
			sdk.NewAttribute("nullifier", nullifier),
		),
	)

	return nil
}

// ShieldedTransfer performs a private transfer within the shielded pool
func (k Keeper) ShieldedTransfer(ctx sdk.Context, tx types.ShieldedTransaction) error {
	// Verify all nullifiers are not used
	for _, nullifier := range tx.Nullifiers {
		if k.IsNullifierUsed(ctx, nullifier) {
			return types.ErrNullifierAlreadyUsed
		}
	}

	// Verify zero-knowledge proof
	if !k.VerifyProof(ctx, tx.Proof) {
		return types.ErrInvalidProof
	}

	// Mark all nullifiers as used
	for _, nullifier := range tx.Nullifiers {
		k.SetNullifier(ctx, nullifier)
	}

	// Add new commitments to the tree
	store := ctx.KVStore(k.storeKey)
	for _, commitment := range tx.Commitments {
		commitmentKey := append(types.CommitmentTreeKey, []byte(commitment)...)
		store.Set(commitmentKey, []byte{0x01})
	}

	// Emit event
	ctx.EventManager().EmitEvent(
		sdk.NewEvent(
			"shielded_transfer",
			sdk.NewAttribute("nullifiers", fmt.Sprintf("%v", tx.Nullifiers)),
			sdk.NewAttribute("commitments", fmt.Sprintf("%v", tx.Commitments)),
		),
	)

	return nil
}

// IsNullifierUsed checks if a nullifier has been used
func (k Keeper) IsNullifierUsed(ctx sdk.Context, nullifier string) bool {
	store := ctx.KVStore(k.storeKey)
	key := types.GetNullifierKey([]byte(nullifier))
	return store.Has(key)
}

// SetNullifier marks a nullifier as used
func (k Keeper) SetNullifier(ctx sdk.Context, nullifier string) {
	store := ctx.KVStore(k.storeKey)
	key := types.GetNullifierKey([]byte(nullifier))
	store.Set(key, []byte{0x01})
}

// VerifyProof verifies a zero-knowledge proof
// TODO: Implement actual zk-SNARK verification
func (k Keeper) VerifyProof(ctx sdk.Context, proof string) bool {
	// This is a placeholder - in production, this would use a library like
	// libsnark or bellman to verify the zk-SNARK proof
	if proof == "" {
		return false
	}

	// For now, we accept any non-empty proof
	// In production: verify using Groth16 or PLONK verification
	return true
}

// GetShieldedPoolBalance returns the total balance in the shielded pool
func (k Keeper) GetShieldedPoolBalance(ctx sdk.Context) sdk.Coins {
	moduleAddr := k.bankKeeper.GetModuleAddress(types.ModuleName)
	return k.bankKeeper.GetAllBalances(ctx, moduleAddr)
}
