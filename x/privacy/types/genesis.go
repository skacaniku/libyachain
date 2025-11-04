package types

// GenesisState defines the privacy module's genesis state
type GenesisState struct {
	Params           PrivacyParams      `json:"params"`
	PrivateAccounts  []PrivateAccount   `json:"private_accounts"`
	Nullifiers       []string           `json:"nullifiers"`
	Commitments      []string           `json:"commitments"`
}

// DefaultGenesisState returns the default genesis state
func DefaultGenesisState() *GenesisState {
	return &GenesisState{
		Params:          DefaultParams(),
		PrivateAccounts: []PrivateAccount{},
		Nullifiers:      []string{},
		Commitments:     []string{},
	}
}

// ValidateGenesis validates the genesis state
func ValidateGenesis(data GenesisState) error {
	// Validate params
	if data.Params.MaxNotesPerTx == 0 {
		return fmt.Errorf("max notes per tx must be positive")
	}

	if data.Params.ProofVerificationGas == 0 {
		return fmt.Errorf("proof verification gas must be positive")
	}

	return nil
}
