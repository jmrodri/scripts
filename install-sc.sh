#!/bin/bash

echo "Using KUBECONFIG=$KUBECONFIG"

# create subscription
cat << EOF > svcat-subscription.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  generateName: svcat-
  namespace: kube-service-catalog
spec:
  channel: alpha
  name: svcat
  source: rh-operators
  startingCSV: svcat.v0.1.34
EOF

cat << EOF > sc-rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:service-catalog:aggregate-to-admin
  labels:
    rbac.authorization.k8s.io/aggregate-to-admin: "true"
rules:
- apiGroups:
  - "servicecatalog.k8s.io"
  attributeRestrictions: null
  resources:
  - servicebrokers
  - serviceclasses
  - serviceplans
  - serviceinstances
  - servicebindings
  verbs:
  - create
  - update
  - delete
  - get
  - list
  - watch
  - patch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:service-catalog:aggregate-to-edit
  labels:
    rbac.authorization.k8s.io/aggregate-to-edit: "true"
rules:
- apiGroups:
  - "servicecatalog.k8s.io"
  attributeRestrictions: null
  resources:
  - servicebrokers
  - serviceclasses
  - serviceplans
  - serviceinstances
  - servicebindings
  verbs:
  - create
  - update
  - delete
  - get
  - list
  - watch
  - patch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:service-catalog:aggregate-to-view
  labels:
    rbac.authorization.k8s.io/aggregate-to-view: "true"
rules:
- apiGroups:
  - "servicecatalog.k8s.io"
  attributeRestrictions: null
  resources:
  - servicebrokers
  - serviceclasses
  - serviceplans
  - serviceinstances
  - servicebindings
  verbs:
  - get
  - list
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: servicecatalog-serviceclass-viewer
rules:
- apiGroups:
  - servicecatalog.k8s.io
  resources:
  - clusterserviceclasses
  - clusterserviceplans
  verbs:
  - list
  - watch
  - get
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: servicecatalog-serviceclass-viewer-binding
roleRef:
  kind: ClusterRole
  name: servicecatalog-serviceclass-viewer
subjects:
- kind: Group
  name: system:authenticated
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:auth-delegator-binding
roleRef:
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: service-catalog-apiserver
  namespace: kube-service-catalog
EOF

# create the namespace if it doesn't exist
oc get namespace kube-service-catalog
if [ $? -eq 1 ]; then
    echo "Creating kube-service-catalog namespace"
    oc create namespace kube-service-catalog
    if [ $? -eq 0 ]; then
        echo "kube-service-catalog created"
    else
        echo "ERROR: Unable to create kube-service-catalog"
        exit 1
    fi
fi

# create subscription
oc create -f svcat-subscription.yaml
if [ $? -eq 0 ]; then
    echo "Service catalog subscription created"
else
    echo "ERROR: Unable to create service catalog subscription"
    exit 1
fi

# add scc to user
oc adm policy add-scc-to-user  hostmount-anyuid "system:serviceaccount:kube-service-catalog:service-catalog-apiserver"
if [ $? -eq 0 ]; then
    echo "scc added to user"
else
    echo "ERROR: Unable to add scc to user"
    exit 1
fi

# add cluster role to user
oc adm policy add-cluster-role-to-user  admin "system:serviceaccount:kube-service-catalog:default" -n kube-service-catalog
if [ $? -eq 0 ]; then
    echo "cluster role added to admin user"
else
    echo "ERROR: Unable to add cluster role to admin user"
    exit 1
fi

# setup the rbac for the service catalog
oc create -f sc-rbac.yaml
if [ $? -eq 0 ]; then
    echo "service catalog rbac created"
else
    echo "ERROR: Unable to setup rbac for service catalog"
    exit 1
fi
