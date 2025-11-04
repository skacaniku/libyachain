package bridge

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/codec"
	codectypes "github.com/cosmos/cosmos-sdk/codec/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/types/module"
	"github.com/grpc-ecosystem/grpc-gateway/runtime"

	"github.com/skacaniku/libyachain/x/bridge/keeper"
	"github.com/skacaniku/libyachain/x/bridge/types"
)

var (
	_ module.AppModuleBasic = AppModuleBasic{}
	_ module.HasName        = AppModuleBasic{}
)

// AppModuleBasic defines the basic application module used by the bridge module.
type AppModuleBasic struct{}

// Name returns the bridge module's name.
func (AppModuleBasic) Name() string {
	return types.ModuleName
}

// RegisterLegacyAminoCodec registers the bridge module's types on the given LegacyAmino codec.
func (AppModuleBasic) RegisterLegacyAminoCodec(cdc *codec.LegacyAmino) {}

// RegisterInterfaces registers the module's interface types
func (b AppModuleBasic) RegisterInterfaces(registry codectypes.InterfaceRegistry) {}

// RegisterGRPCGatewayRoutes registers the gRPC Gateway routes for the bridge module.
func (AppModuleBasic) RegisterGRPCGatewayRoutes(clientCtx client.Context, mux *runtime.ServeMux) {}

// AppModule implements an application module for the bridge module.
type AppModule struct {
	AppModuleBasic
	keeper keeper.Keeper
}

// NewAppModule creates a new AppModule object
func NewAppModule(keeper keeper.Keeper) AppModule {
	return AppModule{
		AppModuleBasic: AppModuleBasic{},
		keeper:         keeper,
	}
}

// Name returns the bridge module's name.
func (AppModule) Name() string {
	return types.ModuleName
}

// RegisterInvariants registers the bridge module invariants.
func (am AppModule) RegisterInvariants(ir sdk.InvariantRegistry) {}

// ConsensusVersion implements AppModule/ConsensusVersion.
func (AppModule) ConsensusVersion() uint64 { return 1 }

// BeginBlock returns the begin blocker for the bridge module.
func (am AppModule) BeginBlock(ctx context.Context) error {
	return nil
}

// EndBlock returns the end blocker for the bridge module.
func (am AppModule) EndBlock(ctx context.Context) error {
	return nil
}
