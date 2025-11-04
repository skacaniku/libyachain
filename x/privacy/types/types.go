package types

import (
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/x/auth/types"
)

const (
	// ModuleName defines the module name
	ModuleName = "privacy"

	// StoreKey defines the primary module store key
	StoreKey = ModuleName

	// RouterKey is the message route for slashing
	RouterKey = ModuleName

	// QuerierRoute defines the module's query routing key
	QuerierRoute = ModuleName

	// MemStoreKey defines the in-memory store key
	MemStoreKey = "mem_privacy"
)

var (
	// PrivateAccountPrefix is the prefix for private accounts
	PrivateAccountPrefix = []byte{0x01}

	// ShieldedPoolKey is the key for the shielded pool balance
	ShieldedPoolKey = []byte{0x02}

	// NullifierSetKey is the prefix for nullifier sets
	NullifierSetKey = []byte{0x03}

	// CommitmentTreeKey is the key for the merkle tree of commitments
	CommitmentTreeKey = []byte{0x04}
)

// PrivateAccount represents a privacy-enabled account
type PrivateAccount struct {
	Address        string `json:"address"`
	ViewingKey     string `json:"viewing_key"`
	ShieldedPubKey string `json:"shielded_pub_key"`
}

// ShieldedTransaction represents a private transaction
type ShieldedTransaction struct {
	Nullifiers  []string `json:"nullifiers"`   // Spent note nullifiers
	Commitments []string `json:"commitments"`  // New note commitments
	Proof       string   `json:"proof"`        // Zero-knowledge proof
	BindingSig  string   `json:"binding_sig"`  // Binding signature
	Memo        string   `json:"memo"`         // Encrypted memo
}

// Note represents a shielded note (UTXO-like construct)
type Note struct {
	Value      sdk.Int `json:"value"`
	Denom      string  `json:"denom"`
	Rcm        string  `json:"rcm"`        // Randomness commitment
	PubKey     string  `json:"pub_key"`    // Recipient's shielded public key
	Commitment string  `json:"commitment"` // Note commitment
}

// PrivacyParams defines the parameters for the privacy module
type PrivacyParams struct {
	// Enable or disable privacy features
	PrivacyEnabled bool `json:"privacy_enabled"`

	// Minimum shielded pool reserve
	MinShieldedReserve sdk.Int `json:"min_shielded_reserve"`

	// Maximum notes per transaction
	MaxNotesPerTx uint32 `json:"max_notes_per_tx"`

	// Proof verification gas cost
	ProofVerificationGas uint64 `json:"proof_verification_gas"`
}

// DefaultParams returns default privacy module parameters
func DefaultParams() PrivacyParams {
	return PrivacyParams{
		PrivacyEnabled:       true,
		MinShieldedReserve:   sdk.NewInt(1000000),
		MaxNotesPerTx:        4,
		ProofVerificationGas: 100000,
	}
}

// GetPrivateAccountKey returns the store key for a private account
func GetPrivateAccountKey(addr sdk.AccAddress) []byte {
	return append(PrivateAccountPrefix, addr.Bytes()...)
}

// GetNullifierKey returns the store key for a nullifier
func GetNullifierKey(nullifier []byte) []byte {
	return append(NullifierSetKey, nullifier...)
}
