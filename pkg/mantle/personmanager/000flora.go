package personmanager

import (
	"context"

	"ma.applysquare.net/eng/flora/pkg/core/server"
	// blank import here this flora module dependencies
	_ "ma.applysquare.net/eng/flora-base/pkg/mantle/fumi"
	_ "ma.applysquare.net/eng/flora-base/pkg/mantle/fumidash"
	_ "ma.applysquare.net/eng/flora-base/pkg/mantle/fumiextra"
	_ "ma.applysquare.net/eng/flora-base/pkg/mantle/fumirootredirect"
	_ "ma.applysquare.net/eng/flora-base/pkg/mantle/ide"
	_ "ma.applysquare.net/eng/flora-base/pkg/mantle/oauthclient"
	_ "ma.applysquare.net/eng/flora-base/pkg/mantle/recordrule"
	_ "ma.applysquare.net/eng/flora-base/pkg/mantle/tasks"
	_ "ma.applysquare.net/eng/flora-base/pkg/mantle/users"
)

// FloraModuleName is the name of the flora module.
// This line is critical for flora generator and it must
// not be modified.
const FloraModuleName string = "personmanager"

func init() {
	module := &server.Module{
		Name:        FloraModuleName,
		Description: "",
		Install: func(ctx context.Context, p *server.InstallParams) {
			p.SetOnInit(func(ctx context.Context) {})
		},
	}

	server.RegisterModule(module)
}
