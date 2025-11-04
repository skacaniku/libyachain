package types

import (
	sdk "github.com/cosmos/cosmos-sdk/types"
)

const (
	// ModuleName defines the module name
	ModuleName = "bridge"

	// StoreKey defines the primary module store key
	StoreKey = ModuleName

	// RouterKey is the message route for bridge
	RouterKey = ModuleName

	// QuerierRoute defines the module's query routing key
	QuerierRoute = ModuleName
)

// Supported blockchain networks
const (
	ChainBitcoin  = "bitcoin"
	ChainEthereum = "ethereum"
	ChainSolana   = "solana"
	ChainBNB      = "bnb"
	ChainTron     = "tron"
	ChainDogecoin = "dogecoin"
)

// BridgeStatus represents the status of a bridge operation
type BridgeStatus string

const (
	StatusPending   BridgeStatus = "pending"
	StatusConfirmed BridgeStatus = "confirmed"
	StatusCompleted BridgeStatus = "completed"
	StatusFailed    BridgeStatus = "failed"
)

// CrossChainTransfer represents a cross-chain transfer
type CrossChainTransfer struct {
	ID              string       `json:"id"`
	SourceChain     string       `json:"source_chain"`
	DestChain       string       `json:"dest_chain"`
	SourceAddress   string       `json:"source_address"`
	DestAddress     string       `json:"dest_address"`
	Amount          sdk.Int      `json:"amount"`
	TokenSymbol     string       `json:"token_symbol"`
	Status          BridgeStatus `json:"status"`
	TxHash          string       `json:"tx_hash"`
	Confirmations   uint64       `json:"confirmations"`
	RequiredConfirms uint64       `json:"required_confirms"`
	Timestamp       int64        `json:"timestamp"`
}

// BridgeValidator represents a bridge validator/relayer
type BridgeValidator struct {
	Address     string `json:"address"`
	ChainID     string `json:"chain_id"`
	PubKey      string `json:"pub_key"`
	IsActive    bool   `json:"is_active"`
	TotalSigned uint64 `json:"total_signed"`
}

// ChainConfig represents configuration for a supported chain
type ChainConfig struct {
	ChainID              string  `json:"chain_id"`
	ChainName            string  `json:"chain_name"`
	Enabled              bool    `json:"enabled"`
	MinConfirmations     uint64  `json:"min_confirmations"`
	BridgeFeePercentage  sdk.Dec `json:"bridge_fee_percentage"`
	MinBridgeAmount      sdk.Int `json:"min_bridge_amount"`
	MaxBridgeAmount      sdk.Int `json:"max_bridge_amount"`
	SupportedTokens      []string `json:"supported_tokens"`
	ContractAddress      string  `json:"contract_address"`       // For EVM chains
	ProgramID            string  `json:"program_id"`             // For Solana
	MultisigThreshold    uint32  `json:"multisig_threshold"`
	RelayerEndpoint      string  `json:"relayer_endpoint"`
}

// BridgeParams defines the parameters for the bridge module
type BridgeParams struct {
	Enabled              bool                   `json:"enabled"`
	Chains               map[string]ChainConfig `json:"chains"`
	DefaultFeePercentage sdk.Dec                `json:"default_fee_percentage"`
	MaxPendingTransfers  uint64                 `json:"max_pending_transfers"`
}

// DefaultParams returns default bridge module parameters
func DefaultParams() BridgeParams {
	chains := make(map[string]ChainConfig)

	// Bitcoin configuration
	chains[ChainBitcoin] = ChainConfig{
		ChainID:             "bitcoin",
		ChainName:           "Bitcoin",
		Enabled:             true,
		MinConfirmations:    6,
		BridgeFeePercentage: sdk.MustNewDecFromStr("0.003"), // 0.3%
		MinBridgeAmount:     sdk.NewInt(100000),              // 0.001 BTC in satoshis
		MaxBridgeAmount:     sdk.NewInt(100000000000),        // 1000 BTC
		SupportedTokens:     []string{"BTC"},
		MultisigThreshold:   5,
	}

	// Ethereum configuration
	chains[ChainEthereum] = ChainConfig{
		ChainID:             "ethereum",
		ChainName:           "Ethereum",
		Enabled:             true,
		MinConfirmations:    12,
		BridgeFeePercentage: sdk.MustNewDecFromStr("0.002"), // 0.2%
		MinBridgeAmount:     sdk.NewInt(10000000000000000),  // 0.01 ETH in wei
		MaxBridgeAmount:     sdk.NewInt(1000000000000000000000), // 1000 ETH
		SupportedTokens:     []string{"ETH", "USDT", "USDC", "DAI"},
		ContractAddress:     "0x0000000000000000000000000000000000000000", // Placeholder
		MultisigThreshold:   5,
	}

	// Solana configuration
	chains[ChainSolana] = ChainConfig{
		ChainID:             "solana",
		ChainName:           "Solana",
		Enabled:             true,
		MinConfirmations:    32,
		BridgeFeePercentage: sdk.MustNewDecFromStr("0.001"), // 0.1%
		MinBridgeAmount:     sdk.NewInt(10000000),           // 0.01 SOL in lamports
		MaxBridgeAmount:     sdk.NewInt(100000000000000),    // 100,000 SOL
		SupportedTokens:     []string{"SOL", "USDC"},
		ProgramID:           "Bridge11111111111111111111111111111111111", // Placeholder
		MultisigThreshold:   5,
	}

	// BNB Smart Chain configuration
	chains[ChainBNB] = ChainConfig{
		ChainID:             "bnb",
		ChainName:           "BNB Chain",
		Enabled:             true,
		MinConfirmations:    15,
		BridgeFeePercentage: sdk.MustNewDecFromStr("0.002"), // 0.2%
		MinBridgeAmount:     sdk.NewInt(10000000000000000),  // 0.01 BNB in wei
		MaxBridgeAmount:     sdk.NewInt(1000000000000000000000), // 1000 BNB
		SupportedTokens:     []string{"BNB", "BUSD", "USDT"},
		ContractAddress:     "0x0000000000000000000000000000000000000000", // Placeholder
		MultisigThreshold:   5,
	}

	// TRON configuration
	chains[ChainTron] = ChainConfig{
		ChainID:             "tron",
		ChainName:           "TRON",
		Enabled:             true,
		MinConfirmations:    19,
		BridgeFeePercentage: sdk.MustNewDecFromStr("0.002"), // 0.2%
		MinBridgeAmount:     sdk.NewInt(10000000),           // 10 TRX in sun
		MaxBridgeAmount:     sdk.NewInt(1000000000000),      // 1,000,000 TRX
		SupportedTokens:     []string{"TRX", "USDT"},
		ContractAddress:     "T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb",     // Placeholder
		MultisigThreshold:   5,
	}

	// Dogecoin configuration
	chains[ChainDogecoin] = ChainConfig{
		ChainID:             "dogecoin",
		ChainName:           "Dogecoin",
		Enabled:             true,
		MinConfirmations:    40,
		BridgeFeePercentage: sdk.MustNewDecFromStr("0.003"), // 0.3%
		MinBridgeAmount:     sdk.NewInt(100000000),          // 1 DOGE in koinu
		MaxBridgeAmount:     sdk.NewInt(10000000000000),     // 100,000 DOGE
		SupportedTokens:     []string{"DOGE"},
		MultisigThreshold:   5,
	}

	return BridgeParams{
		Enabled:              true,
		Chains:               chains,
		DefaultFeePercentage: sdk.MustNewDecFromStr("0.002"),
		MaxPendingTransfers:  1000,
	}
}

// WrappedToken represents a wrapped version of an external token
type WrappedToken struct {
	Symbol          string `json:"symbol"`
	Name            string `json:"name"`
	OriginChain     string `json:"origin_chain"`
	OriginContract  string `json:"origin_contract"`
	LibyaChainDenom string `json:"libyachain_denom"`
	Decimals        uint8  `json:"decimals"`
	TotalSupply     sdk.Int `json:"total_supply"`
}

// GetWrappedTokenDenom returns the denom for a wrapped token
func GetWrappedTokenDenom(chain, symbol string) string {
	return fmt.Sprintf("ibc/%s/%s", chain, symbol)
}
