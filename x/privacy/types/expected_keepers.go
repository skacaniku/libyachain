package types

import (
	sdk "github.com/cosmos/cosmos-sdk/types"
	sdkerrors "github.com/cosmos/cosmos-sdk/types/errors"
)

// Privacy module error codes
var (
	ErrPrivateAccountExists  = sdkerrors.Register(ModuleName, 2, "private account already exists")
	ErrPrivateAccountNotFound = sdkerrors.Register(ModuleName, 3, "private account not found")
	ErrNullifierAlreadyUsed   = sdkerrors.Register(ModuleName, 4, "nullifier already used")
	ErrInvalidProof          = sdkerrors.Register(ModuleName, 5, "invalid zero-knowledge proof")
	ErrInvalidCommitment     = sdkerrors.Register(ModuleName, 6, "invalid commitment")
	ErrInsufficientBalance   = sdkerrors.Register(ModuleName, 7, "insufficient shielded balance")
	ErrMaxNotesExceeded      = sdkerrors.Register(ModuleName, 8, "maximum notes per transaction exceeded")
)

// BankKeeper defines the expected bank keeper
type BankKeeper interface {
	SendCoinsFromAccountToModule(ctx sdk.Context, senderAddr sdk.AccAddress, recipientModule string, amt sdk.Coins) error
	SendCoinsFromModuleToAccount(ctx sdk.Context, senderModule string, recipientAddr sdk.AccAddress, amt sdk.Coins) error
	GetModuleAddress(moduleName string) sdk.AccAddress
	GetAllBalances(ctx sdk.Context, addr sdk.AccAddress) sdk.Coins
}
