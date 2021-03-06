package cluster

// Copyright (c) Microsoft Corporation.
// Licensed under the Apache License 2.0.

import (
	"context"
	"encoding/json"
	"reflect"
	"runtime"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func (m *manager) gatherFailureLogs(ctx context.Context) {
	for _, f := range []func(context.Context) (interface{}, error){
		m.logClusterVersion,
		m.logClusterOperators,
	} {
		o, err := f(ctx)
		if err != nil {
			m.log.Error(err)
			continue
		}
		if o == nil {
			continue
		}

		b, err := json.Marshal(o)
		if err != nil {
			m.log.Error(err)
			continue
		}

		m.log.Printf("%s: %s", runtime.FuncForPC(reflect.ValueOf(f).Pointer()).Name(), string(b))
	}
}

func (m *manager) logClusterVersion(ctx context.Context) (interface{}, error) {
	if m.configcli == nil {
		return nil, nil
	}

	return m.configcli.ConfigV1().ClusterVersions().Get("version", metav1.GetOptions{})
}

func (m *manager) logClusterOperators(ctx context.Context) (interface{}, error) {
	if m.configcli == nil {
		return nil, nil
	}

	return m.configcli.ConfigV1().ClusterOperators().List(metav1.ListOptions{})
}
