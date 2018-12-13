#!/bin/bash

echo "Using KUBECONFIG=$KUBECONFIG"

# create the namespace if it doesn't exist
oc get namespace automation-broker 2> /dev/null
if [ $? -eq 1 ]; then
    echo "Creating automation-broker namespace"
    oc create namespace automation-broker
    if [ $? -eq 0 ]; then
        echo "automation-broker created"
    else
        echo "ERROR: Unable to create automation-broker"
        exit 1
    fi
fi

# create the namespace if it doesn't exist
oc get namespace openshift-template-service-broker 2> /dev/null
if [ $? -eq 1 ]; then
    echo "Creating openshift-template-service-broker namespace"
    oc create namespace openshift-template-service-broker
    if [ $? -eq 0 ]; then
        echo "openshift-template-service-broker created"
    else
        echo "ERROR: Unable to create openshift-template-service-broker"
        exit 1
    fi
fi

# Bind automation-broker:automation-broker admin ClusterRole
# NOTE: This is a workaround until OLM supports creation of arbitrary resources.
oc create clusterrolebinding automation-broker-admin --clusterrole=admin --serviceaccount=automation-broker:automation-broker
if [ $? -eq 0 ]; then
    echo "clusterrolebinding created"
else
    echo "ERROR: Unable to create clusterrolebinding"
    exit 1
fi

# create configmap
#wget -O osb-configmap.yaml "https://raw.githubusercontent.com/djwhatle/stuff/master/olm-svcat-brokers-testing/osb-operators.configmap.upstream.yaml"
wget -O osb-configmap.yaml "https://raw.githubusercontent.com/djwhatle/stuff/master/olm-svcat-brokers-testing/osb-operators.configmap.upstream.4.0-fixed.yaml"
oc create -f osb-configmap.yaml
if [ $? -eq 0 ]; then
    echo "OSB configmap created"
else
    echo "ERROR: Unable to create OSB configmap"
    exit 1
fi

# create catalogsource
wget -O osb-catalogsource.yaml https://raw.githubusercontent.com/djwhatle/stuff/master/olm-svcat-brokers-testing/osb-operators.catalogsource.yaml
oc create -f osb-catalogsource.yaml
if [ $? -eq 0 ]; then
    echo "OSB catalogsource created"
else
    echo "ERROR: Unable to create OSB catalogsource"
    exit 1
fi

# create subscriptions for ASB & TSB
wget -O asb-subscription.yaml https://raw.githubusercontent.com/djwhatle/stuff/master/olm-svcat-brokers-testing/asb-subscription.yaml
oc create -f asb-subscription.yaml
if [ $? -eq 0 ]; then
    echo "ASB subscription created"
else
    echo "ERROR: Unable to create ASB subscription"
    exit 1
fi

wget -O tsb-subscription.yaml https://raw.githubusercontent.com/djwhatle/stuff/master/olm-svcat-brokers-testing/tsb-subscription.yaml
oc create -f tsb-subscription.yaml
if [ $? -eq 0 ]; then
    echo "TSB subscription created"
else
    echo "ERROR: Unable to create TSB subscription"
    exit 1
fi

# ASB CRs
wget -O asb-cr.yaml https://raw.githubusercontent.com/djwhatle/stuff/master/olm-svcat-brokers-testing/asb-cr.yaml
oc create -f asb-cr.yaml
if [ $? -eq 0 ]; then
    echo "ASB CR created"
else
    echo "ERROR: Unable to create ASB CR"
    exit 1
fi

# TSB CRs
wget -O tsb-cr.yaml https://raw.githubusercontent.com/djwhatle/stuff/master/olm-svcat-brokers-testing/tsb-cr.yaml
oc create -f tsb-cr.yaml
if [ $? -eq 0 ]; then
    echo "TSB CR created"
else
    echo "ERROR: Unable to create TSB CR"
    exit 1
fi
